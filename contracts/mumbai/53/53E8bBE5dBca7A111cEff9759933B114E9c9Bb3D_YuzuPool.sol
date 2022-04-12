// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./OrumMath.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./IOrumToken.sol";
import "./ILPTokenWrapper.sol";
import "./IYuzuPool.sol";


// Adapted from: https://github.com/Synthetixio/Unipool/blob/master/contracts/Unipool.sol
// Some more useful references:
// Synthetix proposal: https://sips.synthetix.io/sips/sip-31
// Original audit: https://github.com/sigp/public-audits/blob/master/synthetix/unipool/review.pdf
// Incremental changes (commit by commit) from the original to this version: https://github.com/liquity/dev/pull/271

// LPTokenWrapper contains the basic staking functionality
contract LPTokenWrapper is ILPTokenWrapper {
    using SafeMath for uint256;

    IERC20 public yuzuToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual override {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        yuzuToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual override {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        yuzuToken.transfer(msg.sender, amount);
    }
}

/*
 * On deployment a new Yuzuswap pool will be created for the pair OSD/ROSE and its token will be set here.
 * Essentially the way it works is:
 * - Liquidity providers add funds to the Yuzuswap pool, and get Yuzu LP tokens in exchange
 * - Liquidity providers stake those Yuzu LP tokens into Yuzupool rewards contract
 * - Liquidity providers accrue rewards, proportional to the amount of staked tokens and staking time
 * - Liquidity providers can claim their rewards when they want
 * - Liquidity providers can unstake Yuzu LP tokens to exit the program (i.e., stop earning rewards) when they want
 * Funds for rewards will only be added once, on deployment of Orum token,
 * which will happen after this contract is deployed and before this `setParams` in this contract is called.
 * If at some point the total amount of staked tokens is zero, the clock will be “stopped”,
 * so the period will be extended by the time during which the staking pool is empty,
 * in order to avoid getting Orum tokens locked.
 * That also means that the start time for the program will be the event that occurs first:
 * either Orum token contract is deployed, and therefore Orum tokens are minted to YuzuPool contract,
 * or first liquidity provider stakes Yuzu LP tokens into it.
 */
contract YuzuPool is LPTokenWrapper, Ownable, CheckContract, IYuzuPool {
    string constant public NAME = "YuzuPool";

    uint256 public duration;
    IOrumToken public orumToken;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // initialization function
    function setParams(
        address _orumTokenAddress,
        address _yuzuTokenAddress,
        uint _duration
    )
        external
        override
        onlyOwner
    {
        checkContract(_orumTokenAddress);
        checkContract(_yuzuTokenAddress);

        yuzuToken = IERC20(_yuzuTokenAddress);
        orumToken = IOrumToken(_orumTokenAddress);
        duration = _duration;

        _notifyRewardAmount(orumToken.getLpRewardsEntitlement(), _duration);

        emit OrumTokenAddressChanged(_orumTokenAddress);
        emit YuzuTokenAddressChanged(_yuzuTokenAddress);
    }

    // Returns current timestamp if the rewards program has not finished yet, end time otherwise
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return OrumMath._min(block.timestamp, periodFinish);
    }

    // Returns the amount of rewards that correspond to each staked token
    function rewardPerToken() public view override returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply();
    }

    // Returns the amount that an account can claim
    function earned(address account) public view override returns (uint256) {
        return
            balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override {
        require(amount > 0, "Cannot stake 0");
        require(address(yuzuToken) != address(0), "Liquidity Pool Token has not been set yet");

        _updatePeriodFinish();
        _updateAccountReward(msg.sender);

        super.stake(amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        require(address(yuzuToken) != address(0), "Liquidity Pool Token has not been set yet");

        _updateAccountReward(msg.sender);

        super.withdraw(amount);

        emit Withdrawn(msg.sender, amount);
    }

    // Shortcut to be able to unstake tokens and claim rewards in one transaction
    function withdrawAndClaim() external override {
        withdraw(balanceOf(msg.sender));
        claimReward();
    }

    function claimReward() public override {
        require(address(yuzuToken) != address(0), "Liquidity Pool Token has not been set yet");

        _updatePeriodFinish();
        _updateAccountReward(msg.sender);

        uint256 reward = earned(msg.sender);

        require(reward > 0, "Nothing to claim");

        rewards[msg.sender] = 0;
        orumToken.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    // Used only on initialization, sets the reward rate and the end time for the program
    function _notifyRewardAmount(uint256 _reward, uint256 _duration) internal {
        assert(_reward > 0);
        assert(_reward == orumToken.balanceOf(address(this)));
        assert(periodFinish == 0);

        _updateReward();

        rewardRate = _reward / _duration;

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + _duration;
        emit RewardAdded(_reward);
    }

    // Adjusts end time for the program after periods of zero total supply
    function _updatePeriodFinish() internal {
        if (totalSupply() == 0) {
            assert(periodFinish > 0);
            /*
             * If the finish period has been reached (but there are remaining rewards due to zero stake),
             * to get the new finish date we must add to the current timestamp the difference between
             * the original finish time and the last update, i.e.:
             *
             * periodFinish = block.timestamp.add(periodFinish.sub(lastUpdateTime));
             *
             * If we have not reached the end yet, we must extend it by adding to it the difference between
             * the current timestamp and the last update (the period where the supply has been empty), i.e.:
             *
             * periodFinish = periodFinish.add(block.timestamp.sub(lastUpdateTime));
             *
             * Both formulas are equivalent.
             */
            periodFinish = periodFinish + block.timestamp - lastUpdateTime;
        }
    }

    function _updateReward() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
    }

    function _updateAccountReward(address account) internal {
        _updateReward();

        assert(account != address(0));

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
}