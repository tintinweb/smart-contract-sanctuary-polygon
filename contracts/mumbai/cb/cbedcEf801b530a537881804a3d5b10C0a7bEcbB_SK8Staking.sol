// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @dev
 * DOCS OF THIS STAKING CONTRACT
 *
 * Here you will find how this Smart Contract Works.
 * You can use your SK8 Tokens to stake and increase the max probability of landing tricks with your SK8r and earn Interest rate over your amount staked.
 * So when staking, you also have to inform which SK8r are you staking at.
 *
 * About the Staking Format and Interest Rates:
 *  This contract has a FIXED interest rate, that can be changed by the owner.
 *  There are different available Lock periods, each one with your own APY
 *  You can verify if a Lock Period exists and its interest rates calling the function {interestRateOfMonths(uint months)}
 *  which returns the interest rate of the period selected. (If period not set, the returning will be zero)
 *
 *  **You can see the initial Lock Periods and its Interest rates in the Constructor of this Contract.
 *
 * As user, you can do these functions:
 * 1) Stake: First time you stake in a Sk8r (passing the amount you wnat to stake, the tokenId, and the Lock Period)
 * 2) IncreaseAmountStaked: If you want to deposit more tokens in a SK8r Staking, you can, just call this function
 * 3) Withdraw: You can withdraw your staked token after the Lock period ends. Your rewards are calculated based on the amount staked.
 * 4) Claim Reward: You call this function to transfer the amount you have of rewards to your account. Can be called after lock period to.
 * 5) Increase Staking Lock Period: Calling this function you can increase the time your assets will be locked, and you will increase you interest rate as well.
 *
 * So after Lock Period, you can Withdraw and Claim reward whenever you want, but remember, the interest rate is base on the Lock Period selected,
 * then if you leave your amount staked more time than the lock period, the interst rate will stay the same.
 *
 */

error StakingTransferFailed();
error WithdrawTransferFailed();
error WithdrawingMoreThanTotalAvailable();
error AmountMustBeGratherThanZero();

contract SK8Staking is Pausable, Ownable {
    // STRUCTS
    struct StakeDetails {
        uint256 stakedAmount; // Amount staked for this NFT
        uint256 totalRewarded; // Amount of rewards available to Claim
        uint256 stakedAt; // When it was staked, in seconds
        uint256 lockDurationInSeconds; // Duration it will be locked (In seconds)
        uint256 lastRewardUpdate; // Last time the the totalRewarded was updated
    }

    uint256 public constant secondsInDay = 24 * 60 * 60;

    //VARIABLES
    uint256 private _totalStaked;
    uint256 private _totalRewarded;
    mapping(uint256 => uint256) private _lockedDaysToInterestRate; // Qtt of days and their interest rate per year

    mapping(address => uint256[]) private _addressToStakedTokenIds;
    mapping(address => mapping(uint256 => StakeDetails)) private _stakeBalance;

    IERC20 private immutable _sk8Token;

    //EVENTS
    event Staked(address who, uint256 amount, uint256 tokenId);
    event RewardClaimed(address who, uint256 amountClaimed);
    event Withdraw(address who, uint256 amountWithdrawn);
    event LockPeriodIncreased(address who, uint256 newPeriod);

    //CONSTRUCTOR
    constructor(address sk8TokenAddress) {
        _sk8Token = IERC20(sk8TokenAddress);
    }

    /**=============================================== */
    // Modifiers

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) revert AmountMustBeGratherThanZero();
        _;
    }

    modifier lockPeriodNotFinished(address account, uint256 tokenId) {
        require(
            block.timestamp >
                _stakeBalance[account][tokenId].stakedAt +
                    _stakeBalance[account][tokenId].lockDurationInSeconds,
            "Lock period not finished. Withdraw blocked."
        );
        _;
    }

    /**
     * @dev This modifier is responsible to update the total rewarded of an NFT
     */
    modifier updateReward(address account, uint256 tokenId) {
        _stakeBalance[msg.sender][tokenId].totalRewarded = earned(
            account,
            tokenId
        );
        _stakeBalance[msg.sender][tokenId].lastRewardUpdate = block.timestamp;
        _;
    }

    /**=============================================== */
    // Functions

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function annualInterestRate(uint pDays) external view returns (uint256) {
        return _lockedDaysToInterestRate[pDays];
    }

    function setInterestRate(
        uint pDays,
        uint256 newValue
    ) external onlyOwner whenNotPaused {
        require(
            newValue < 100 && newValue > 0,
            "New value must be greater than 0 and less than 100"
        );
        _lockedDaysToInterestRate[pDays] = newValue;
    }

    function addressTokenIdStakedDetails(
        address staker,
        uint256 tokenId
    ) external view returns (StakeDetails memory) {
        return _stakeBalance[staker][tokenId];
    }

    function addressStakedTokenIds(
        address account
    ) external view returns (uint256[] memory) {
        return _addressToStakedTokenIds[account];
    }

    /**
     * @dev Function to calc how much tokens a user won as reward since last time his {totalRewarded} was updated
     */
    function earned(
        address account,
        uint256 tokenId
    ) public view returns (uint256) {
        StakeDetails memory mStake = _stakeBalance[account][tokenId];

        uint256 secondsSinceRewardUpdate = block.timestamp -
            mStake.lastRewardUpdate;

        uint256 interestPerYear = _lockedDaysToInterestRate[
            mStake.lockDurationInSeconds / secondsInDay
        ];

        return
            ((mStake.stakedAmount / 100 / (secondsInDay * 360)) *
                secondsSinceRewardUpdate *
                interestPerYear) + mStake.totalRewarded;
    }

    /**
     * @dev Function to Stake SK8 Tokens in an Sk8r for the first Time
     *
     * @param tokenId tokenId of the NFT
     * @param amount amount of SK8 tokens to stake
     * @param periodInDays time that you will let the amount staked, in days
     */
    function stake(
        uint256 tokenId,
        uint256 amount,
        uint256 periodInDays
    ) external whenNotPaused moreThanZero(amount) {
        require(
            _lockedDaysToInterestRate[periodInDays] > 0,
            "Period selected not available"
        );

        StakeDetails memory stakeDetails = StakeDetails(
            amount,
            0,
            block.timestamp,
            periodInDays * secondsInDay,
            block.timestamp
        );

        _stakeBalance[msg.sender][tokenId] = stakeDetails;
        _addressToStakedTokenIds[msg.sender].push(tokenId);
        _totalStaked += amount;
        emit Staked(msg.sender, amount, tokenId);
        bool success = _sk8Token.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert StakingTransferFailed();
        }
    }

    /**
     * @dev Function to Stake More SK8 Tokens in an Sk8r
     *
     * @param tokenId tokenId of the NFT
     * @param amount amount of SK8 tokens to stake
     */
    function increaseAmountStaked(
        uint256 tokenId,
        uint256 amount
    )
        external
        whenNotPaused
        moreThanZero(amount)
        updateReward(msg.sender, tokenId)
    {
        require(
            _stakeBalance[msg.sender][tokenId].stakedAmount > 0,
            "TokenId doenst have any staking running"
        );

        _stakeBalance[msg.sender][tokenId].stakedAmount += amount;
        _totalStaked += amount;
        emit Staked(msg.sender, amount, tokenId);

        bool success = _sk8Token.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert StakingTransferFailed();
        }
    }

    /**
     * @dev Function to Withdraw the Staked tokens
     *
     * @param tokenId tokenId of the NFT
     */
    function withdraw(
        uint256 tokenId,
        uint256 amount
    )
        external
        whenNotPaused
        moreThanZero(amount)
        lockPeriodNotFinished(msg.sender, tokenId)
        updateReward(msg.sender, tokenId)
    {
        StakeDetails memory mStake = _stakeBalance[msg.sender][tokenId];

        if (mStake.stakedAmount < amount) {
            revert WithdrawingMoreThanTotalAvailable();
        }

        _totalStaked -= amount;
        mStake.stakedAmount -= amount;

        emit Withdraw(msg.sender, amount);
        bool success = _sk8Token.transfer(msg.sender, amount);

        // Deleting tokenId from Array {_addressToStakedTokenIds} and also the stake details from {_stakeBalance}
        delete _stakeBalance[msg.sender][tokenId];
        for (uint i = 0; i < _addressToStakedTokenIds[msg.sender].length; i++) {
            if (_addressToStakedTokenIds[msg.sender][i] == tokenId) {
                _addressToStakedTokenIds[msg.sender][
                    i
                ] = _addressToStakedTokenIds[msg.sender][
                    _addressToStakedTokenIds[msg.sender].length - 1
                ];
                _addressToStakedTokenIds[msg.sender].pop();
                break;
            }
        }

        if (!success) {
            revert WithdrawTransferFailed();
        }
    }

    /**
     * @dev Function to Claim (Transfer) total SK8 Tokens you have as reward from the Staked SK8r
     *
     * @param tokenId tokenId of the NFT/SK8r
     */
    function claimReward(
        uint256 tokenId,
        uint256 amount
    )
        external
        whenNotPaused
        moreThanZero(amount)
        lockPeriodNotFinished(msg.sender, tokenId)
        updateReward(msg.sender, tokenId)
    {
        require(
            _stakeBalance[msg.sender][tokenId].totalRewarded > amount,
            "Trying to claim more than available rewards"
        );

        _stakeBalance[msg.sender][tokenId].totalRewarded -= amount;

        emit RewardClaimed(msg.sender, amount);
        bool success = _sk8Token.transfer(msg.sender, amount);

        if (!success) {
            revert StakingTransferFailed();
        }
    }

    /**
     * @dev Function to increase the locked time a selected stake has.
     *  Requirements:
     *  - {periodInDays} must be a valid key in {_lockedDaysToInterestRate}
     *  - {periodInDays} must be greater tha current {stake.lockDurationInSeconds}
     *
     * @param tokenId TokenId of SK8
     * @param periodInDays new period selected for the staking
     */
    function increaseLockPeriod(
        uint256 tokenId,
        uint256 periodInDays
    ) external whenNotPaused updateReward(msg.sender, tokenId) {
        require(
            _lockedDaysToInterestRate[periodInDays] > 0,
            "Period selected not available"
        );

        require(
            periodInDays * secondsInDay >
                _stakeBalance[msg.sender][tokenId].lockDurationInSeconds,
            "Period selected must be greater than current staking period"
        );

        require(
            _stakeBalance[msg.sender][tokenId].lockDurationInSeconds > 0,
            "No staking with this TokenId yet"
        );

        _stakeBalance[msg.sender][tokenId].lockDurationInSeconds =
            periodInDays *
            secondsInDay;

        emit LockPeriodIncreased(msg.sender, periodInDays);
    }
}