/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// created by cryptodo.app

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Wassd is Ownable {
    IERC20 public stakingToken;
    uint256 public rewardRate; // annual reward rate in %
    uint256 public lockPeriod; // staking period in seconds
    uint256 public earlyWithdrawalPenalty; // early withdrawal penalty in %
    uint256 public minStake;
    uint256 public maxStake;
    bool public isEarlyWithdrawal;

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake[]) public stakes;

    constructor(address _stakingToken, uint256 _minStake, uint256 _maxStake, bool _isEarlyWithdrawal, uint256 
        _earlyWithdrawalPenalty, uint256 _lockPeriod, uint256 _rewardRate
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
        lockPeriod = _lockPeriod;
        earlyWithdrawalPenalty = _earlyWithdrawalPenalty;
        minStake = _minStake;
        maxStake = _maxStake;
        isEarlyWithdrawal = _isEarlyWithdrawal;
    }

    function stake(uint256 _amount) public {
        require(_amount >= minStake, string.concat("The amount must be greater than minimum"));
        require(_amount <= maxStake, string.concat("The amount must be lower than maximum"));
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        stakes[msg.sender].push(Stake(_amount, block.timestamp));
    }

    function claimReward(uint256 stakeIndex) public {
        Stake storage userStake = stakes[msg.sender][stakeIndex];
        uint256 elapsedSeconds = block.timestamp - userStake.startTime;
        uint256 rewardAmount = (userStake.amount * elapsedSeconds * rewardRate) / (100 * 365 days);
        require(stakingToken.transfer(msg.sender, rewardAmount), "Token transfer failed");
    }

    function withdraw(uint256 stakeIndex) public {
        Stake storage userStake = stakes[msg.sender][stakeIndex];
        uint256 elapsedSeconds = block.timestamp - userStake.startTime;

        require(elapsedSeconds < lockPeriod || isEarlyWithdrawal, "Early withdrawal is not allowed");

        if (elapsedSeconds < lockPeriod) {
            uint256 penaltyAmount = (userStake.amount * earlyWithdrawalPenalty) / 100;
            userStake.amount -= penaltyAmount;
        }

        require(stakingToken.transfer(msg.sender, userStake.amount), "Token transfer failed");
        userStake.amount = 0;
    }

    function setLockPeriod(uint256 newLockPeriod) public onlyOwner {
        lockPeriod = newLockPeriod;
    }

    function setMinStake(uint256 newMinStake) public onlyOwner {
        minStake = newMinStake;
    }

    function setMaxStake(uint256 newMaxStake) public onlyOwner {
        maxStake = newMaxStake;
    }

    function setEarlyWithdrawalPenalty(uint256 newPenaltyPercent) public onlyOwner {
        require(newPenaltyPercent <= 100, "Penalty cannot be more than 100%");
        earlyWithdrawalPenalty = newPenaltyPercent;
    }
}