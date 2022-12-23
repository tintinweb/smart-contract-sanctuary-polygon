/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// SPDX-License-Identifier: None
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: RockStake.sol


pragma solidity ^0.8.0;



contract StakeToken is Ownable {
    struct Stake {
        address owner;
        uint256 amount;
        uint256 time;
        uint256 endsAt;
        uint256 dailyReward;
        uint256 daysToReward;
        uint256 lastRewardClaimAt;
    }

    struct Reward {
        uint256 oneMonth;
        uint256 threeMonth;
        uint256 sixMonth;
        uint256 oneYear;
    }
    Reward public tokenRewards;

    // Time durations multiply by seconds
    uint256 oneMonth;
    uint256 threeMonths;
    uint256 sixMonths;
    uint256 oneYear;

    // State level variables for the contract
    IERC20 public token;
    address public rewardsWallet;
    address public stakesWallet;
    bool public initialized;
    uint256 public minimumStakingAmount;
    uint256 public totalStaked;
    uint256 public currentlyStaked;

    // Stakes by the user indexed by address
    mapping(bytes32 => Stake) public stakes;
    mapping(address => uint256) public totalUserStakes;
    mapping(address => bytes32[]) public userStakes;

    event Staked(
        address indexed staker,
        bytes32 stakeId,
        uint256 amount,
        uint256 endsAt
    );

    event Unstaked(address indexed staker, bytes32 stakeId, uint256 amount);

    constructor(IERC20 _token) {
        initialized = false;
        token = _token;
    }

    function setRewardsWallet(address newWallet) public onlyOwner {
        rewardsWallet = newWallet;
    }

    function setStakesWallet(address newWallet) public onlyOwner {
        stakesWallet = newWallet;
    }

    /**
     * Set up the staking smart contract
     *
     * @param _amount Initial amount how many tokens are staked at once
     * @param _oneMonth initial One Month staking Reward
     * @param _threeMonth initial three Months staking Reward
     * @param _sixMonth initial six Months staking Reward
     * @param _oneYear initial One Year staking Reward
     */
    function initializeStakingContract(
        uint256 _amount,
        uint256 _oneMonth,
        uint256 _threeMonth,
        uint256 _sixMonth,
        uint256 _oneYear,
        uint256 _oneMonthTime
    ) external onlyOwner {
        require(initialized == false, "Contract initialized already");
        setMinimumStakingAmount(_amount);
        setRewardParameters(_oneMonth, _threeMonth, _sixMonth, _oneYear);
        initialized = true;

        oneMonth = _oneMonthTime;
        threeMonths = _oneMonthTime * 3;
        sixMonths = _oneMonthTime * 6;
        oneYear = _oneMonthTime * 12;
    }

    function changeTimeLimits(uint256 _oneMonth) public onlyOwner {
        oneMonth = _oneMonth;
        threeMonths = _oneMonth * 3;
        sixMonths = _oneMonth * 6;
        oneYear = _oneMonth * 12;
    }

    function setRewardParameters(
        uint256 _oneMonth,
        uint256 _threeMonth,
        uint256 _sixMonth,
        uint256 _oneYear
    ) public onlyOwner {
        require(
            _oneMonth > 0 && _threeMonth > 0 && _sixMonth > 0 && _oneYear > 0,
            "One of the Rewards is zero"
        );
        tokenRewards.oneMonth = _oneMonth;
        tokenRewards.threeMonth = _threeMonth;
        tokenRewards.sixMonth = _sixMonth;
        tokenRewards.oneYear = _oneYear;
    }

    /**
     * owner can adjust required stake amount and duration.
     */
    function setMinimumStakingAmount(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount cannot be zero, please input valid amount");
        minimumStakingAmount = _amount;
    }

    /**
     * Stake tokens sent on the contract.
     *
     * @param stakeId bytes32 Id generated from amount and address of staker
     * @param staker On whose behalf we are staking
     * @param amount Amount of tokens to stake
     */
    function _stakeInternal(
        bytes32 stakeId,
        address staker,
        uint256 amount,
        uint256 _stakingTime
    ) internal {
        uint256 endsAt = block.timestamp + _stakingTime;

        uint256 dailyReward = 0;
        if (_stakingTime == oneMonth) {
            dailyReward = amount * tokenRewards.oneMonth / 100 / (30 * 1);
        } else if (_stakingTime == threeMonths) {
            dailyReward = amount * tokenRewards.threeMonth / 100 / (30 * 3);
        } else if (_stakingTime == sixMonths) {
            dailyReward = amount * tokenRewards.sixMonth / 100 / (30 * 6);
        } else if (_stakingTime == oneYear) {
            dailyReward = amount * tokenRewards.oneYear / 100 / (30 * 12);
        }

        stakes[stakeId] = Stake(
            staker,
            amount,
            _stakingTime,
            endsAt,
            dailyReward,
            _stakingTime / oneMonth * 30,
            block.timestamp
        );
        userStakes[staker].push(stakeId);
        totalUserStakes[staker]++;
        totalStaked += amount;
        currentlyStaked += amount;

        emit Staked(staker, stakeId, amount, endsAt);
    }

    /**
     * Return data for a single stake.
     */
    function getStakeInformation(bytes32 stakeId)
        public
        view
        returns (
            address staker,
            uint256 amount,
            uint256 stakingPeriod,
            uint256 endsAt,
            uint256 dailyReward,
            uint256 remainingDailyRewards,
            uint256 lastRewardClaimTime
        )
    {
        Stake memory s = stakes[stakeId];
        return (s.owner, s.amount, s.time, s.endsAt, s.dailyReward, s.daysToReward, s.lastRewardClaimAt);
    }

    /**
     * Check if a stakeId has been allocated
     */
    function isStake(bytes32 stakeId) public view returns (bool) {
        return stakes[stakeId].owner != address(0x0);
    }

    /**
     * Return true if the user has still tokens in the staking contract for a previous stake.
     */
    function isStillStaked(bytes32 stakeId) public view returns (bool) {
        return stakes[stakeId].endsAt != 0;
    }

    /**
     * Send tokens back to the staker.
     *@param stakeId bytes32 Id of Stake recieved on staking
     */
    function unstake(bytes32 stakeId) public {
        Stake memory s = stakes[stakeId];

        require(s.endsAt != 0, "Already unstaked");
        require(_msgSender() == s.owner, "Only owner can unstake");
        require(s.endsAt <= block.timestamp, "Cannot unstake before maturity");

        if (s.daysToReward > 0) {
            claimRewards(stakeId);
        }

        // Mark the stake released
        stakes[stakeId].endsAt = 0;
        stakes[stakeId].amount = 0;
        stakes[stakeId].time = 0;
        stakes[stakeId].daysToReward = 0;
        currentlyStaked -= s.amount;
        totalUserStakes[msg.sender]--;

        emit Unstaked(s.owner, stakeId, s.amount);

        // Use ERC-20 to transfer tokens to the wallet of the owner
        token.transferFrom(stakesWallet, s.owner, s.amount);
    }

    /**
     * Allow staker to cash out their daily rewards
     *@param stakeId bytes32 Id of Stake recieved on staking
     */
    function claimRewards(bytes32 stakeId) public {
        Stake memory s = stakes[stakeId];

        require(s.endsAt != 0, "Already unstaked");
        require(_msgSender() == s.owner, "Only owner can claim");
        require(s.daysToReward > 0, "You have already claimed all the daily rewards in this stake");

        uint256 daysUnclaimed = (block.timestamp - s.lastRewardClaimAt) /
            (oneMonth / 30);

        if (s.daysToReward < daysUnclaimed) {
            daysUnclaimed = s.daysToReward;
        }

        require(daysUnclaimed > 0, "Wait at least 1 day to claim rewards");

        // Use ERC-20 to transfer reward tokens to the wallet of the owner
        token.transferFrom(rewardsWallet, s.owner, daysUnclaimed * s.dailyReward);
        stakes[stakeId].lastRewardClaimAt = s.lastRewardClaimAt + daysUnclaimed * (oneMonth / 30);
        stakes[stakeId].daysToReward -= daysUnclaimed;
    }

    function _keyGen(address sender, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        bytes32 uid = keccak256(abi.encodePacked(sender, amount));
        return uid;
    }

    function stake(uint256 amount, uint256 _time) public {
        require(
            _time == oneMonth ||
                _time == threeMonths ||
                _time == sixMonths ||
                _time == oneYear,
            "Staking Time should be in time limits defined"
        );
        require(
            amount >= minimumStakingAmount,
            "Staking must be greater then or equal to Minimum Staking Amount"
        );
        require(
            token.allowance(msg.sender, address(this)) != amount,
            " Staking amount not approved "
        );

        token.transferFrom(msg.sender, stakesWallet, amount);
        bytes32 stakeId = _keyGen(msg.sender, block.timestamp);
        _stakeInternal(stakeId, msg.sender, amount, _time);
    }
}