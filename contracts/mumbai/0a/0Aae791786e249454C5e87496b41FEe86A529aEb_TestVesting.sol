/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
// File: IFloyx.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IFloyx {
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

    function mint(address to, uint256 amount) external;
}

// File: FloyxTokenVesting.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;





error AllTokensAreReleleased(address _beneficiary);
contract TestVesting is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    IFloyx private immutable token;
    uint256 private totalReleasedAmount;
    uint256 private totalVestedAmount;
    uint256 private seedStartTime;
    uint256 private privateStartTime;
    uint256 private testStartTime;

    struct VestingSchedule {
        bool initialized;
        // cliff period in seconds
        uint256 cliff;
        // start time of the vesting period
        uint256 startTime;
        // duration of the vesting period in seconds
        uint256 duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodInDays;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
        // released % for each slice period and it should be in multiple of 10
        uint256 releasedPercent;
        // tgeAmount which will be released at start
        uint256 tgePercent;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

   
    constructor(address _token) {
        token = IFloyx(_token);
    }

    // Events
    event addVesting(
        address indexed beneficiary,
        uint256 cliff,
        uint256 startTime,
        uint256 duration,
        uint256 slicePeriod,
        uint256 amountTotal,
        uint256 releasedPercent,
        uint256 tgePercent
    );
    event withdraw(address indexed beneficiary, uint256 amount);

    modifier onlyIfVestingScheduleInitialized(address _beneficiary) {
        require(
            vestingSchedules[_beneficiary].initialized,
            "Vesting schedule not initialized"
        );
        _;
    }

    function SeedVestingSchedule(
        address _beneficiary,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_beneficiary != address(0), "Beneficiary is zero address.");
        require(
            _amount <= getUnallocatedFundsAmount(),
            "Insufficient funds available"
        );
        require(
            !vestingSchedules[_beneficiary].initialized,
            "Vesting schedule for this beneficiary already exists"
        );

        uint256 _start = seedStartTime;
        uint256 _cliff = _start.add(60 days);
        uint256 _duration = _start.add(660);
        uint256 _slicePeriod = 30 days;
        uint256 _releasedPercent = 500;

        VestingSchedule memory vestingSchedule = VestingSchedule({
            initialized: true,
            startTime: _start,
            cliff: _cliff,
            duration: _duration,
            slicePeriodInDays: _slicePeriod,
            amountTotal: _amount,
            released: 0,
            releasedPercent: _releasedPercent,
            tgePercent: 0
        });

        vestingSchedules[_beneficiary] = vestingSchedule;
        totalVestedAmount = totalVestedAmount.add(_amount);
        emit addVesting(
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriod,
            _amount,
            _releasedPercent,
            0
        );
    }


    function PrivateSaleVestingSchedule(
        address _beneficiary,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_beneficiary != address(0), "Beneficiary is zero address.");
        require(
            _amount <= getUnallocatedFundsAmount(),
            "Insufficient funds available"
        );
        require(
            !vestingSchedules[_beneficiary].initialized,
            "Vesting schedule for this beneficiary already exists"
        );

        uint256 _start = privateStartTime;
        uint256 _cliff = _start.add(60 days);
        uint256 _duration = _start.add(600 days);
        uint256 _slicePeriod = 30 days;
        uint256 _releasedPercent = 528;
        uint256 _tgePercent = 500;

        VestingSchedule memory vestingSchedule = VestingSchedule({
            initialized: true,
            startTime: _start,
            cliff: _cliff,
            duration: _duration,
            slicePeriodInDays: _slicePeriod,
            amountTotal: _amount,
            released: 0,
            releasedPercent: _releasedPercent,
            tgePercent: _tgePercent
        });

        vestingSchedules[_beneficiary] = vestingSchedule;
        totalVestedAmount = totalVestedAmount.add(_amount);
        emit addVesting(
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriod,
            _amount,
            _tgePercent,
            0
        );
    }


    function PrivateVestingTest(
        address _beneficiary,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_beneficiary != address(0), "Beneficiary is zero address.");
        require(
            _amount <= getUnallocatedFundsAmount(),
            "Insufficient funds available"
        );
        require(
            !vestingSchedules[_beneficiary].initialized,
            "Vesting schedule for this beneficiary already exists"
        );

        uint256 _start = privateStartTime;
        uint256 _cliff = _start.add(1200);
        uint256 _duration = _start.add(30 days);
        uint256 _slicePeriod = 600;
        uint256 _releasedPercent = 1000;

        VestingSchedule memory vestingSchedule = VestingSchedule({
            initialized: true,
            startTime: _start,
            cliff: _cliff,
            duration: _duration,
            slicePeriodInDays: _slicePeriod,
            amountTotal: _amount,
            released: 0,
            releasedPercent: _releasedPercent,
            tgePercent: 0
        });

        vestingSchedules[_beneficiary] = vestingSchedule;
        totalVestedAmount = totalVestedAmount.add(_amount);
        emit addVesting(
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriod,
            _amount,
            0,
            0
        );
    }


    function SeedVestingTest(
        address _beneficiary,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_beneficiary != address(0), "Beneficiary is zero address.");
        require(
            _amount <= getUnallocatedFundsAmount(),
            "Insufficient funds available"
        );
        require(
            !vestingSchedules[_beneficiary].initialized,
            "Vesting schedule for this beneficiary already exists"
        );

        uint256 _start = seedStartTime;
        uint256 _cliff = _start.add(900);
        uint256 _duration = _start.add(30 days);
        uint256 _slicePeriod = 300;
        uint256 _releasedPercent = 1000;
        uint256 _tgePercent = 5000;

        VestingSchedule memory vestingSchedule = VestingSchedule({
            initialized: true,
            startTime: _start,
            cliff: _cliff,
            duration: _duration,
            slicePeriodInDays: _slicePeriod,
            amountTotal: _amount,
            released: 0,
            releasedPercent: _releasedPercent,
            tgePercent: _tgePercent
        });

        vestingSchedules[_beneficiary] = vestingSchedule;
        totalVestedAmount = totalVestedAmount.add(_amount);
        emit addVesting(
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriod,
            _amount,
            _tgePercent,
            0
        );
    }


     function Test3VestingSchedule(
        address _beneficiary,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_beneficiary != address(0), "Beneficiary is zero address.");
        require(
            _amount <= getUnallocatedFundsAmount(),
            "Insufficient funds available"
        );
        require(
            !vestingSchedules[_beneficiary].initialized,
            "Vesting schedule for this beneficiary already exists"
        );

        uint256 _start = testStartTime;
        uint256 _cliff = _start.add(300);
        uint256 _duration = _start.add(30 days);
        uint256 _slicePeriod = 120;
        uint256 _tgePercent = 2000;
        uint256 _releasedPercent = 1000;

        VestingSchedule memory vestingSchedule = VestingSchedule({
            initialized: true,
            startTime: _start,
            cliff: _cliff,
            duration: _duration,
            slicePeriodInDays: _slicePeriod,
            amountTotal: _amount,
            released: 0,
            releasedPercent: _releasedPercent,
            tgePercent: _tgePercent
        });

        vestingSchedules[_beneficiary] = vestingSchedule;
        totalVestedAmount = totalVestedAmount.add(_amount);
        emit addVesting(
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriod,
            _amount,
            _tgePercent,
            0
        );
    }

    function getClaimableAmount(address _beneficiary) external view onlyIfVestingScheduleInitialized(_beneficiary) returns(uint256)
     {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            _beneficiary
        ];
        uint256 currentTime = getCurrentTime();
        require(currentTime >= vestingSchedule.startTime,"vesting not started yet");
        uint256 releaseAmount = _getClaimableAmount(_beneficiary);
        if (releaseAmount.add(vestingSchedule.released) > vestingSchedule.amountTotal) {
        releaseAmount = vestingSchedule.amountTotal.sub(vestingSchedule.released);
        }
        return releaseAmount;
    }

    function getTotalVestingAmount() public view returns (uint256) {
        return totalVestedAmount;
    }

    function getTotalReleasedAmount() external view returns (uint256) {
        return totalReleasedAmount;
    }


    function getUnallocatedFundsAmount() public view returns (uint256) {
        return token.balanceOf(address(this)).sub(totalVestedAmount);
    }


    function getAvailableFunds() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getToken() external view returns (address) {
        return address(token);
    }

    function claimVestedToken(
        address _beneficiary
    ) public nonReentrant onlyIfVestingScheduleInitialized(_beneficiary)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            _beneficiary
        ];
        uint256 currentTime = getCurrentTime();
        require(currentTime > vestingSchedule.startTime,"vesting not started yet");
        if (vestingSchedule.amountTotal == vestingSchedule.released) {
            revert AllTokensAreReleleased(_beneficiary);
        }
        uint256 releaseAmount = _getClaimableAmount(_beneficiary);
        require(releaseAmount > 0,"there no token to release");
        if (releaseAmount.add(vestingSchedule.released) > vestingSchedule.amountTotal) {
        releaseAmount = vestingSchedule.amountTotal.sub(vestingSchedule.released);
        }
        vestingSchedule.released = vestingSchedule.released.add(releaseAmount);
        totalVestedAmount = totalVestedAmount.sub (releaseAmount);
        totalReleasedAmount = totalReleasedAmount.add(releaseAmount);
        require
        (token.approve(address(this), releaseAmount),
        "token transfer not apporoved");
        require(
            token.transfer(_beneficiary, releaseAmount),
            "Token withdrawal failed."
        );
        emit withdraw(_beneficiary, releaseAmount);
    }

    function withdrawUnallocatedFunds(
        address _receiver,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_receiver != address(0), "Receiver is the zero address.");
        require(
            _amount > 0 && _amount <= getUnallocatedFundsAmount(),
            "Invalid amount of unallocated funds."
        );

        require(
            token.transfer(_receiver, _amount),
            "Unallocated funds withdrawal failed."
        );
        emit withdraw(_receiver, _amount);
    }

    function initializeSeedVesting(uint256 _startTime) external onlyOwner {
        seedStartTime = _startTime;
    }

    function initializePrivateSaleVesting(uint256 _startTime) external onlyOwner {
        privateStartTime = _startTime;
    }

    function initializeTestVesting(uint256 _startTime) external onlyOwner {
        testStartTime = _startTime;
    }

    function _getClaimableAmount(
        address _beneficiary
    ) internal view onlyIfVestingScheduleInitialized(_beneficiary) returns (uint256) {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            _beneficiary
        ];
        if (vestingSchedule.released >= vestingSchedule.amountTotal) {
            revert AllTokensAreReleleased(_beneficiary);
        }
        uint256 tgeAmount = _getTgeAmount(vestingSchedule);
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        uint256 releaseableAmount = tgeAmount.add(vestedAmount);
        return releaseableAmount.sub(vestingSchedule.released);
    }

    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if(currentTime < vestingSchedule.cliff) {
            return 0;
        } else if (
            currentTime >= vestingSchedule.duration.add(vestingSchedule.startTime)
        ) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingSchedule.cliff);
            uint256 secondsPerSlice = vestingSchedule.slicePeriodInDays;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedAmountPerSlice = _calculateReleasableAmount(
                vestingSchedule
            );
            uint256 vestedAmount = vestedAmountPerSlice.mul(vestedSlicePeriods);
            return vestedAmount;
        }
    }
    

    function _calculateReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal pure returns (uint256) {
        uint256 totalAmount = vestingSchedule.amountTotal;
        uint256 releasedPercent = uint256(vestingSchedule.releasedPercent);
        return totalAmount.mul(releasedPercent).div(10000);
    }

  
    function _getTgeAmount(
    VestingSchedule memory vestingSchedule
    ) internal pure  returns (uint256) {
    uint256 totalAmount = vestingSchedule.amountTotal;
    uint256 _tgePercent = uint256(vestingSchedule.tgePercent);
    return ((totalAmount.mul(_tgePercent)).div(10000));
   }


    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }
}