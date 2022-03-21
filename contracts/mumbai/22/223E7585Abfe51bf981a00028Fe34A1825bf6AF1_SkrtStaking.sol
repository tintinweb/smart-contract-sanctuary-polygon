/**
 *Submitted for verification at polygonscan.com on 2022-03-20
*/

// File: Documents/sekuritance/crypto/skrt/contracts/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: Documents/sekuritance/crypto/skrt/contracts/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: Documents/sekuritance/crypto/skrt/contracts/ERC20Interface.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: Documents/sekuritance/crypto/skrt/contracts/SkrtStaking.sol



pragma solidity ^0.8.0;



contract SkrtStaking is Ownable {

    IERC20 public token;
    address public rewardsAddress;
    uint256 public minimumStakingAmount;
    uint256 public stakingPoolSize;
    uint256 public annualMintPercentage;
    uint256 public threeMonthsUnStakePenalty;
    uint256 public sixMonthsUnStakePenalty;
    uint256 public lateUnStakePenalty;
    uint256 public totalStakedTokens;
    uint256 public unStakeStartSeconds;
    uint256 public withdrawStartSeconds;
    uint256 public lateUnStakeSeconds;

    mapping(address => uint256) public stakeBalance;
    mapping(address => uint256) public lastStakeClaimed;

    event Stake(
        uint256 indexed _stakeTimestamp,
        address indexed _whom,
        uint256 _amount
    );

    event StakeClaimed(
        uint256 indexed _stakeClaimedTimestamp,
        address indexed _whom,
        uint256 _amount
    );

    event UnStake(
        uint256 indexed _unstakeTimestamp,
        address indexed _whom,
        uint256 _amount,
        uint256 _rewards
    );

    constructor(address _token, address _rewardsAddress, uint256 _annualMintPercentage, uint256 _minimumStakingAmount, uint256 _stakingPoolSize, uint256 _unStakeStartSeconds, 
    uint256 _withdrawStartSeconds, uint256 _threeMonthsUnStakePenalty, uint256 _sixMonthsUnStakePenalty, uint256 _lateUnStakePenalty, uint256 _lateUnStakeSeconds) {
        token = IERC20(_token);
        rewardsAddress = _rewardsAddress;
        annualMintPercentage = _annualMintPercentage;
        minimumStakingAmount = _minimumStakingAmount;
        stakingPoolSize = _stakingPoolSize;
        unStakeStartSeconds = _unStakeStartSeconds;
        withdrawStartSeconds = _withdrawStartSeconds;
        threeMonthsUnStakePenalty = _threeMonthsUnStakePenalty;
        sixMonthsUnStakePenalty = _sixMonthsUnStakePenalty;
        lateUnStakePenalty = _lateUnStakePenalty;
        lateUnStakeSeconds = _lateUnStakeSeconds;
    }

    /**
    * @dev stake token
    **/
    function stake(uint256 _amount)
    _correctStakingAmount(_amount)
    external 
    returns (bool) {
        uint256 _stakeReward = 0;
        if (lastStakeClaimed[msg.sender] == 0) {
            //first time staking.
            require((_amount + totalStakedTokens) <= stakingPoolSize, "Staking Pool Limit reached");
            lastStakeClaimed[msg.sender] = block.timestamp;
        } else {
            //user already staked - so make sure we add up the accrued rewards
            _stakeReward = _calculateStake(msg.sender);
            require((_amount + _stakeReward + totalStakedTokens) <= stakingPoolSize, "Staking Pool Limit reached");
            lastStakeClaimed[msg.sender] = block.timestamp;
            stakeBalance[msg.sender] = stakeBalance[msg.sender] + _stakeReward;
        }

        //add the new amount to stake plus any accrued rewards to the totalStakedTokens bucket.
        totalStakedTokens = totalStakedTokens +  _amount + _stakeReward;
        stakeBalance[msg.sender] = stakeBalance[msg.sender] + _amount;

        //transfer tokens to this contract
        require(token.transferFrom(msg.sender, address(this), _amount), "[Deposit] Something went wrong while transferring your deposit");

        emit Stake(block.timestamp, msg.sender, _amount);
        return true;
    }

    /**
     * @dev unstake token
     **/
    function unStake()
    external 
    returns (bool){
        require(lastStakeClaimed[msg.sender] != 0, "[UnStake] No tokens to unstake");
        uint256 totalStakeSeconds = (block.timestamp - lastStakeClaimed[msg.sender]);
        require(totalStakeSeconds >= unStakeStartSeconds, "[UnStake] Cannot unstake tokens too early");
        //check for early/late unstake

        uint256 _stakeReward = _calculateStake(msg.sender);
        uint256 percentagePenalty = _checkForUnStakePenalties(totalStakeSeconds);
        if (percentagePenalty > 0) {
            //give only such percentage in rewards!
            _stakeReward = _stakeReward  * (percentagePenalty / 100);
        }
        
        //transfer tokens 
        uint256 userTokenBalance = stakeBalance[msg.sender];
        require(token.transfer(msg.sender, userTokenBalance), "[UnStake] Something went wrong while transferring your initial deposit");

        if (_stakeReward > 0) {
            //transfer rewards tokens 
            require(token.transferFrom(rewardsAddress, msg.sender, _stakeReward), "[UnStake] Something went wrong while transferring your reward");
        }

        totalStakedTokens = totalStakedTokens - userTokenBalance;
        stakeBalance[msg.sender] = 0;
        lastStakeClaimed[msg.sender] = 0;

        emit UnStake(block.timestamp, msg.sender, userTokenBalance, _stakeReward);
        return true;
    }

    /**
     * @dev withdraw token
     **/
    function withdraw() external returns (bool){
        require(lastStakeClaimed[msg.sender] != 0, "[Withdraw] No tokens staked");
        uint256 totalStakeSeconds = (block.timestamp - lastStakeClaimed[msg.sender]);
        require(totalStakeSeconds >= withdrawStartSeconds, "[Withdraw] Cannot withdraw tokens too early");

        uint256 userTokenBalance = stakeBalance[msg.sender];
        require(userTokenBalance > 0, "[Withdraw] Nothing to withdraw");

        //transfer tokens
        require(token.transfer(msg.sender, userTokenBalance), "[Withdraw] Something went wrong while transferring your tokens");
        stakeBalance[msg.sender] = 0;
        lastStakeClaimed[msg.sender] = 0;
        totalStakedTokens = totalStakedTokens - userTokenBalance;

        return true;
    }

    /**
     * @dev withdraw token by owner
     **/
    function withdrawTokens(uint256 _amount) external onlyOwner() returns (bool) {
        require(_amount <= totalStakedTokens, "[Withdraw] Amount is invalid");
        require(token.transfer(msg.sender, _amount), "[Withdraw] Something went wrong while transferring your tokens");
        return true;
    }

    /**
     * @dev transfer tokens to contract
     **/
    function transferTokens(uint256 _amount) external onlyOwner() returns (bool) {
        require(token.transferFrom(msg.sender, address(this), _amount), "[Transfer] Something went wrong while transferring tokens");
        return true;
    }

    // we calculate daily basis stake amount
    function _calculateStake(address _whom) internal view returns (uint256) {
        uint256 _lastRound = lastStakeClaimed[_whom];
        uint256 totalStakeDays = (block.timestamp - _lastRound) / 86400;
        uint256 userTokenBalance = stakeBalance[_whom];
        if (totalStakeDays > 0) {
            return ((userTokenBalance * annualMintPercentage) * totalStakeDays) / 3650000;
        }
        return 0;
    }

    // show stake balance and rewards
    function balanceOf(address _whom) external view returns (uint256) {
        uint256 _stakeReward = _calculateStake(_whom);
        return stakeBalance[_whom] + _stakeReward;
    }

    // show rewards
    function getOnlyRewards(address _whom) external view returns (uint256) {
        return _calculateStake(_whom);
    }

    // claim only rewards and withdraw it
    function claimRewards() external returns (bool) {
        require(lastStakeClaimed[msg.sender] != 0, "[Withdraw] No tokens staked");
        uint256 _stakeReward = _calculateStake(msg.sender);
        token.transfer(msg.sender, _stakeReward);
        lastStakeClaimed[msg.sender] = block.timestamp;
        emit StakeClaimed(block.timestamp, msg.sender, _stakeReward);
        return true;
    }

    // claim only rewards and restake it
    function claimRewardsAndStake() external returns (bool) {
        require(lastStakeClaimed[msg.sender] != 0, "[Withdraw] No tokens staked");
        uint256 _stakeReward = _calculateStake(msg.sender);
        //check that claim and restake is allowed due to pool size
        require((stakeBalance[msg.sender]  + _stakeReward) <= stakingPoolSize, "Staking Pool Limit reached, failed to restake");

        lastStakeClaimed[msg.sender] = block.timestamp;
        stakeBalance[msg.sender] = stakeBalance[msg.sender] + _stakeReward;
        emit StakeClaimed(block.timestamp, msg.sender, _stakeReward);
        emit Stake(block.timestamp, msg.sender, stakeBalance[msg.sender]);
        return true;
    }

    // _percent should be mulitplied by 100
    function setAnnualMintPercentage(uint256 _percent) public onlyOwner() returns (bool) {
        annualMintPercentage = _percent;
        return true;
    }

    // set the rewards wallet address 
    function setRewardsAddress(address _rewardsAddress) public onlyOwner() returns (bool) {
        rewardsAddress = _rewardsAddress;
        return true;
    }

    // set the minimum staking amount
    function setMinimumStakingAmount(uint256 _amount) public onlyOwner() returns (bool) {
        minimumStakingAmount = _amount;
        return true;
    }

    // set the staking CAP
    function setStakingPoolSize(uint256  _stakingPoolSize) public onlyOwner() returns (bool) {
        require(_stakingPoolSize > 0, "stakingPoolSize must be a valid number");
        stakingPoolSize =  _stakingPoolSize;
        return true;
    }

    // set the unstake start in seconds
    function setUnStakeStartSeconds(uint256 _unStakeStartSeconds) public onlyOwner() returns (bool) {
        unStakeStartSeconds = _unStakeStartSeconds;
        return true;
    }

    // set the withdraw start in seconds
    function setWithdrawStartSeconds(uint256 _withdrawStartSeconds) public onlyOwner() returns (bool) {
        withdrawStartSeconds = _withdrawStartSeconds;
        return true;
    }

    // set the token address
    function setTokenAddress(address _token) public onlyOwner() returns (bool) {
        require(_token != address(0),"[Validation] Invalid token address");
        token = IERC20(_token);
        return true;
    }

    // set the 3 months early unstake penalty (percentage)
    function setThreeMonthsUnStakePenalty(uint256 _percent) public onlyOwner() returns (bool) {
        threeMonthsUnStakePenalty = _percent;
        return true;
    }

    // set the 6 months early unstake penalty (percentage)
    function setSixMonthsUnStakePenalty(uint256 _percent) public onlyOwner() returns (bool) {
        sixMonthsUnStakePenalty = _percent;
        return true;
    }

    // set late unstake penalty (percentage)
    function setLateUnStakePenalty(uint256 _percent) public onlyOwner() returns (bool) {
        lateUnStakePenalty = _percent;
        return true;
    }

    // set late unstake period in seconds
    function setLateUnStakeSeconds(uint256 _seconds) public onlyOwner() returns (bool) {
        lateUnStakeSeconds = _seconds;
        return true;
    }

    modifier _correctStakingAmount(uint256 amount) {
        require(amount >= minimumStakingAmount, "Staking amount is invalid");
        _;
    }
    
    /**
     * @dev checks for any penalties and returns the percentage to deduct from the rewards if any otherwise 0
     **/
    function _checkForUnStakePenalties(uint256 _totalStakeSeconds) internal view returns (uint256) {
        uint256 _stakeReward = _calculateStake(msg.sender);
        if (_stakeReward == 0) {
            return 0;
        }

        if (_totalStakeSeconds <= 15780000) {
            //first 6 months
            return threeMonthsUnStakePenalty;
        } else if (_totalStakeSeconds > 15780000 && _totalStakeSeconds <= 31560000) {
            //between 6 - 12 months
            return sixMonthsUnStakePenalty;
        } else if ((block.timestamp - _totalStakeSeconds) >= lateUnStakeSeconds) {
            //check for late unstake penalty ie. unstaking after the x month!
            return lateUnStakePenalty;
        } else {
            return 0;
        }
    }

}