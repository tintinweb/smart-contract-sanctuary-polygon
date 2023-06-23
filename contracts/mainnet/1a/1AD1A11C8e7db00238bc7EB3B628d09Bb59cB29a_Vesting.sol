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
pragma solidity ^0.8.9;

/// @dev Interface of Vesting contract
interface IVesting {
    /**
     * @notice Beneficiary struct includes address of beneficiary, claimedTokens by beneficiary and
     * lastClaim timestamp of beneficiary
     */
    struct Beneficiary {
        address receiver;
        uint256 claimedTokens;
        uint256 lastClaim;
    }

    /// @notice Period struct includes start date timestamp, rate in tokens and period duration in seconds
    struct Period {
        uint256 start;
        uint256 rate;
        uint256 period;
    }

    /// @dev Emitted when the parameters of next Period changes
    event BeneficiaryChanged(
        address indexed oldBeneficiary,
        address indexed newBeneficiary
    );

    /// @dev Emitted when the parameters of next Period changes
    event PeriodUpdated(
        uint256 newDuration,
        uint256 newRate,
        uint256 startDate
    );

    /// @dev Emitted when the Beneficiary claim payment rate
    event Claimed(address indexed beneficiary, uint256 paymentAmount);

    /// @dev updates the address of beneficiary
    /// @dev updateBeneficiary emits BeneficiaryChanged Event
    function updateBeneficiary(address newBeneficiary_) external;

    /// @dev updatePeriod emits PeriodUpdated Event
    /// @dev can only change next period once in each different period
    function updatePeriod(
        uint256 periodDuration_,
        uint256 periodRate_
    ) external;

    /**
     * @dev The payment rate is determined by all the unclaimed period rates that can be modified by contract owner.
     * @dev The payment can only be claimed once per period, and the beneficiary must wait
     * until the end of the next period to claim again.
     * @dev claim function emits Claimed Event
     * @dev claim function just check if there is any payment available to claim
     */
    function claim() external;

    /**
     * @dev sendRemaining tokens in vesting period to Beneficiary
     * @dev If fisrt act like a claim function and claim until divisible period then calculates the remaining
     * tokens till vestingEndDate
     * @dev claim function emits Claimed Event
     * @dev only callable by contract owner
     * @dev only callable after vestingEndDate
     * @dev sendRemaining tokens in vesting period to Beneficiary
     */
    function sendRemaining() external;

    /// @dev getRemaining tokens from lastClaim timestamp to vestingEndDate
    function getRemaining() external view returns (uint256);

    /// @dev Returns address of current Beneficiary
    function getBeneficiary() external view returns (address);

    /// @dev Returns amount of all claimed tokens by Beneficiary
    function getTotalClaimed() external view returns (uint256);

    /// @dev Returns rate of current period that beneficiary will receive after ending period duration
    /// @dev If the next period is updated it returns the current one
    function getTokenRate() external view returns (uint256);

    /// @dev Returns duration of current period in days, Beneficiary can claim after ending this duration from lastClaim
    function getDurationRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface/IVesting.sol";

/**
 * @title Vesting contract
 * @author Mohammad Z. Rad
 * @notice You can use this contract to send Beneficiary payments.
 * There is a Vesting Period and Period for each payment which can be modified.
 * @dev The contract is in development stage
 */
contract Vesting is IVesting, Ownable {
    uint256 public periodCount = 1;
    uint256 public immutable vestingEndDate;

    IERC20 private _token;
    Beneficiary private _beneficiary;

    mapping(uint256 => Period) private _periods;

    /**
     * @dev Sets the values for {beneficiary_}, {tokenAddress_}, {vestingDays_},
     * {periodRate_} and {periodDuration_}.
     * @dev The {periodDuration_} can not be more than {vestingDays_}
     * @param beneficiary_ is the address of Beneficiary
     * @param tokenAddress_ is immutable address of token that used for payments
     * @param vestingDays_ is days of vesting period and can't be changed
     * @param periodRate_ is the starting payment rate in tokens for first period
     * @param periodDuration_ is the period duration in days for first period
     */
    constructor(
        address beneficiary_,
        address tokenAddress_,
        uint256 vestingDays_,
        uint256 periodRate_,
        uint256 periodDuration_
    ) {
        require(
            vestingDays_ >= periodDuration_,
            "Period should not be > vesting"
        );
        _beneficiary = Beneficiary(beneficiary_, 0, block.timestamp);
        _token = IERC20(tokenAddress_);
        vestingEndDate = (vestingDays_ * 1 days) + block.timestamp;
        _periods[periodCount] = Period(
            block.timestamp,
            periodRate_,
            periodDuration_ * 1 days
        );
    }

    /// @notice updateBeneficiary changes Beneficiary address to {newBeneficiary_}
    /// @notice Only callable by admin of vesting contract
    /// @dev See {IVesting-updateBeneficiary}.
    /// @param newBeneficiary_ is the address of new Beneficiary and is not null
    function updateBeneficiary(address newBeneficiary_) external onlyOwner {
        require(newBeneficiary_ != address(0), "Send a valid address");
        address oldBeneficiary_ = _beneficiary.receiver;
        _beneficiary.receiver = newBeneficiary_;
        emit BeneficiaryChanged(oldBeneficiary_, newBeneficiary_);
    }

    /// @notice updatePeriod update next Period parameters and apply after current period
    /// @notice Only callable by admin of vesting contract
    /// @dev See {IVesting-updatePeriod}.
    /// @param periodDuration_ is the next period duration in days and is >0
    /// @param periodRate_ is the next period rate in tokens and is >0
    function updatePeriod(
        uint256 periodDuration_,
        uint256 periodRate_
    ) external onlyOwner {
        require(periodDuration_ > 0, "Entered duration is invalid");
        require(periodRate_ > 0, "Entered rate is invalid");
        require(vestingEndDate > block.timestamp, "Vesting period ended");
        require(
            _periods[periodCount].start < block.timestamp,
            "Already modified next period"
        );
        uint256 nextPeriodStart_ = _nextPeriodStart();
        require(nextPeriodStart_ < vestingEndDate, "There is no next period");
        periodCount++;
        _periods[periodCount] = Period(
            nextPeriodStart_,
            periodRate_,
            periodDuration_ * 1 days
        );
        emit PeriodUpdated(
            _periods[periodCount].period,
            _periods[periodCount].rate,
            _periods[periodCount].start
        );
    }

    /// @notice claim tokens calculated by period rate and only callable by beneficiary
    /// @notice Claims payment for the current period at the specified rate.
    /// @dev See {IVesting-claim}.
    function claim() external {
        require(_beneficiary.receiver == msg.sender, "You are not beneficiary");
        uint256 endPoint = block.timestamp >= vestingEndDate
            ? vestingEndDate
            : block.timestamp;
        (uint256 _paymentAmount, uint256 _periodDuration) = _calculatePayment(
            endPoint
        );
        require(_paymentAmount > 0, "Nothing to claim");

        _beneficiary.lastClaim += _periodDuration;
        _beneficiary.claimedTokens += _paymentAmount;
        _token.transfer(_beneficiary.receiver, _paymentAmount);
        emit Claimed(_beneficiary.receiver, _paymentAmount);
    }

    /// @notice sendRemaining tokens to beneficiary after vesting period
    /// @dev See {IVesting-sendRemaining}.
    function sendRemaining() external onlyOwner {
        require(
            block.timestamp > vestingEndDate,
            "Vesting period has not ended"
        );
        require(vestingEndDate > _beneficiary.lastClaim, "No remaining token");
        uint256 paymentAmount = getRemaining();
        _beneficiary.lastClaim = vestingEndDate;
        _beneficiary.claimedTokens += paymentAmount;
        _token.transfer(_beneficiary.receiver, paymentAmount);
        emit Claimed(_beneficiary.receiver, paymentAmount);
    }

    /// @dev See {IVesting-getBeneficiary}.
    /// @return address of last Beneficiary
    function getBeneficiary() external view returns (address) {
        return _beneficiary.receiver;
    }

    /// @dev See {IVesting-getTotalClaimed}.
    /// @return claimedTokens of Beneficiary
    function getTotalClaimed() external view returns (uint256) {
        return _beneficiary.claimedTokens;
    }

    /// @dev See {IVesting-getTokenRate}.
    /// @return rate of current period
    function getTokenRate() external view returns (uint256) {
        return
            block.timestamp > _periods[periodCount].start
                ? _periods[periodCount].rate
                : _periods[periodCount - 1].rate;
    }

    /// @dev See {IVesting-getDurationRate}.
    /// @return duration of current period
    function getDurationRate() external view returns (uint256) {
        return
            block.timestamp > _periods[periodCount].start
                ? _periods[periodCount].period
                : _periods[periodCount - 1].period;
    }

    /// @notice getRemaining tokens calculated with current period parameters till vestingEndDate
    /// @dev See {IVesting-getRemaining}.
    /// @return remainingTokens until vestingEndDate
    function getRemaining() public view returns (uint256) {
        (uint256 paymentAmount, uint256 periodDuration) = _calculatePayment(
            vestingEndDate
        );
        paymentAmount +=
            (_periods[periodCount].rate *
                (vestingEndDate - _beneficiary.lastClaim - periodDuration)) /
            _periods[periodCount].period;
        return paymentAmount;
    }

    /// @dev Calculates next period timestamp by start date of prev period
    /// @return timestamp of next period start date
    function _nextPeriodStart() private view returns (uint256) {
        uint256 prevPeriod = _periods[periodCount].period;
        uint256 multiple = (block.timestamp - _periods[periodCount].start) /
            prevPeriod;
        multiple++;
        return _periods[periodCount].start + (multiple * prevPeriod);
    }

    /**
     * @notice calculates 2 parameters and loop through all periods
     * @dev only callable by sendRemaining and claim functions and looping backwards from newest to oldest
     * @param endPoint_ represents the starting of the loop and goes backwards and after each period,
     *  will be the end of previous period to reach lastClaim of beneficiary and break the loop
     *  @return paymentPeriod that represents claimable token to lastClaim timestamp
     *  @return periodDuration that represents sum of all claimable period durations
     */
    function _calculatePayment(
        uint256 endPoint_
    ) private view returns (uint256, uint256) {
        uint256 paymentAmount;
        uint256 periodDuration;
        uint256 _startPoint;
        for (uint256 i = periodCount; i > 0; i--) {
            if (endPoint_ > _periods[i].start) {
                _startPoint = _max(_beneficiary.lastClaim, _periods[i].start);
                uint256 unpaidPeriods = (endPoint_ - _startPoint) /
                    _periods[i].period;
                paymentAmount += _periods[i].rate * unpaidPeriods;
                periodDuration += _periods[i].period * unpaidPeriods;
                endPoint_ = _startPoint;
                if (_beneficiary.lastClaim == endPoint_) {
                    break;
                }
            }
        }
        return (paymentAmount, periodDuration);
    }

    /// @return maximum between 2 given uint256 {a} and {b}
    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? a : b;
    }
}