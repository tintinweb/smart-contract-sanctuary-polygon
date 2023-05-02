/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity 0.8.19;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: Projects/PolyKick/Contracts/DateTimeLibrary.sol




pragma solidity 0.8.19;

library DateTimeLibrary {
    using SafeMath for uint256;

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_YEAR = SECONDS_PER_DAY * 365;
    uint256 constant SECONDS_PER_LEAP_YEAR = SECONDS_PER_DAY * 366;

    function isLeapYear(uint256 year) internal pure returns (bool) {
        return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    }

    function daysInMonth(uint256 month, bool leap)
        internal
        pure
        returns (uint16)
    {
        if (month == 2 && leap) {
            return 29;
        } else if (month == 2) {
            return 28;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else {
            return 31;
        }
    }

    function getYear(uint256 timestamp) internal pure returns (uint256) {
        uint256 year = 1970;
        uint256 secondsAccountedFor = 0;
        uint256 remainingSeconds = timestamp;

        while (remainingSeconds >= SECONDS_PER_YEAR) {
            secondsAccountedFor += SECONDS_PER_YEAR;
            remainingSeconds -= SECONDS_PER_YEAR;
            year += 1;
        }

        return year;
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256) {
        uint256 year = getYear(timestamp);
        uint256 leapYears = (year - 1970) /
            4 -
            (year - 1970) /
            100 +
            (year - 1970) /
            400;
        uint256 totalLeapYearSeconds = leapYears * SECONDS_PER_LEAP_YEAR;
        uint256 totalRegularYearSeconds = (year - 1970 - leapYears) *
            SECONDS_PER_YEAR;
        uint256 secondsAccountedFor = totalRegularYearSeconds +
            totalLeapYearSeconds;
        uint256 remainingSeconds = timestamp - secondsAccountedFor;
        uint256 month = 1;
        uint256 _days;

        while (
            remainingSeconds >=
            SECONDS_PER_DAY * daysInMonth(month, isLeapYear(year))
        ) {
            _days = daysInMonth(month, isLeapYear(year));
            remainingSeconds -= SECONDS_PER_DAY * _days;
            month += 1;
        }

        return month;
    }

    function getDay(uint256 timestamp) internal pure returns (uint256) {
        uint256 year = getYear(timestamp);
        uint256 leapYears = (year - 1970) /
            4 -
            (year - 1970) /
            100 +
            (year - 1970) /
            400;
        uint256 totalLeapYearSeconds = leapYears * SECONDS_PER_LEAP_YEAR;
        uint256 totalRegularYearSeconds = (year - 1970 - leapYears) *
            SECONDS_PER_YEAR;
        uint256 secondsAccountedFor = totalRegularYearSeconds +
            totalLeapYearSeconds;
        uint256 remainingSeconds = timestamp - secondsAccountedFor;
        uint256 month = 1;
        uint256 _days;

        while (
            remainingSeconds >=
            SECONDS_PER_DAY * daysInMonth(month, isLeapYear(year))
        ) {
            _days = daysInMonth(month, isLeapYear(year));
            remainingSeconds -= SECONDS_PER_DAY * _days;
            month += 1;
        }

        uint256 day = remainingSeconds / SECONDS_PER_DAY + 1;
        return day;
    }

    function formatDate(uint256 timestamp)
        internal
        pure
        returns (string memory)
    {
        uint256 year = getYear(timestamp);
        uint256 month = getMonth(timestamp);
        uint256 day = getDay(timestamp);
        string[12] memory months = [
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December"
        ];
        string memory monthStr = months[month - 1];
        return
            string(
                abi.encodePacked(
                    monthStr,
                    " ",
                    uintToString(day),
                    ", ",
                    uintToString(year)
                )
            );
    }

    function uintToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

                /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.19;

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.19;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.19;

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

// File: Projects/PolyKick/Contracts/ummaVesting.sol



// Total token amount = 290000000000000000000000000  // 290 Million * 1e18

pragma solidity 0.8.19;




contract Vesting is Ownable {
    using SafeMath for uint256;

    address public marketingPartnerships; // 1 0x067094141F62BC7050eeAa854Dc073e3d22eF608
    address public exchangeListingLiquidity; // 2 0x30d10659F2C2E4E19aE7BB7024269959Ae9f5a9E
    address public researchDevelopment; // 3 0x4586d9FdF82108Fc192a68537f43e23f574F22C3
    address public teamAdvisors; // 4 0xB3cE9CAF4F9e6Ae33A8D66934F14fa7Ccc177690
    address public treasury; // 5 0xb0EF1e58F98A038Fb2923eD4fA9439C9983b7bFA
    address public usersCommunityRewards; // 6 0xfB8b280eeDeF147c4dfca551a94D232a7fe41CAc

    IERC20 public token; // 0x36596A1dC57c695Bed1A063470a7802797Dca133 UMMA Token
    uint256 private constant DECIMALS_MULTIPLIER = 1e18;
    uint256 private constant Millions = 1e6;

    bool public isVestingWalletsSet = false;

    struct VestingSchedule {
        uint256[] _years;
        mapping(uint256 => mapping(uint256 => uint256)) yearToClaimDatesToAmounts;
    }

    mapping(address => VestingSchedule) private schedules;

    constructor(IERC20 _token) {
        token = _token;
    }

    function claim() external {
        VestingSchedule storage schedule = schedules[msg.sender];
        require(schedule._years.length > 0, "No vesting schedule found");

        uint256 totalClaimable = 0;
        uint256 currentYear = _getCurrentYear();
        uint256 currentMonth = _getCurrentMonth();

        for (uint256 i = 0; i < schedule._years.length; i++) {
            uint256 year = schedule._years[i];
            if (year <= currentYear) {
                for (uint256 month = 1; month <= 12; month++) {
                    uint256 claimable = schedule.yearToClaimDatesToAmounts[
                        year
                    ][month];

                    if (
                        claimable > 0 &&
                        (year < currentYear ||
                            (year == currentYear && month <= currentMonth))
                    ) {
                        totalClaimable += claimable;
                        schedule.yearToClaimDatesToAmounts[year][month] = 0;
                    }
                }
            }
        }

        require(totalClaimable > 0, "No claimable tokens found");
        token.transfer(msg.sender, totalClaimable);
    }

    function _getCurrentYear() private view returns (uint256) {
        return DateTimeLibrary.getYear(block.timestamp);
    }

    function _getCurrentMonth() private view returns (uint256) {
        return DateTimeLibrary.getMonth(block.timestamp);
    }

    function getFormattedDate() public view returns (string memory) {
        return DateTimeLibrary.formatDate(block.timestamp);
    }

    function getClaimableAmount(address _beneficiary)
        public
        view
        returns (uint256)
    {
        VestingSchedule storage schedule = schedules[_beneficiary];
        uint256 totalClaimableAmount = 0;
        uint256 currentYear = _getCurrentYear();
        uint256 currentMonth = _getCurrentMonth();

        for (uint256 i = 0; i < schedule._years.length; i++) {
            uint256 year = schedule._years[i];

            if (year < currentYear) {
                // If the year is in the past, add all amounts for that year
                for (uint256 month = 1; month <= 12; month++) {
                    totalClaimableAmount += schedule.yearToClaimDatesToAmounts[
                        year
                    ][month];
                }
            } else if (year == currentYear) {
                // If the year is the current year, add all amounts up to the current month
                for (uint256 month = 1; month <= currentMonth; month++) {
                    totalClaimableAmount += schedule.yearToClaimDatesToAmounts[
                        year
                    ][month];
                }
            } else {
                // If the year is in the future, do not add any amounts
                break;
            }
        }

        return totalClaimableAmount;
    }

    function setVestingWallets(
        address _mP,
        address _eL,
        address _rD,
        address _tA,
        address _t,
        address _uCR
    ) external onlyOwner {
        require(isVestingWalletsSet == false, "Vesting is set already");
        require(
            _mP != address(0x0) ||
                _eL != address(0x0) ||
                _rD != address(0x0) ||
                _tA != address(0x0) ||
                _t != address(0x0) ||
                _uCR != address(0x0),
            "Address zero!"
        );

        marketingPartnerships = _mP;
        exchangeListingLiquidity = _eL;
        researchDevelopment = _rD;
        teamAdvisors = _tA;
        treasury = _t;
        usersCommunityRewards = _uCR;
        isVestingWalletsSet = true;
        setSchedules();
    }

    function setSchedules() private {
        // marketingPartnerships

        schedules[marketingPartnerships]._years.push(2023);
        schedules[marketingPartnerships]._years.push(2024);
        schedules[marketingPartnerships]._years.push(2025);
        schedules[marketingPartnerships]._years.push(2026);
        schedules[marketingPartnerships]._years.push(2027);
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2023][1] =
            11 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2024][1] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2024][7] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2025][1] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2025][7] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2026][1] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2026][7] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2027][1] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[marketingPartnerships].yearToClaimDatesToAmounts[2027][7] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;

        // exchangeListingLiquidity

        schedules[exchangeListingLiquidity]._years.push(2023);
        schedules[exchangeListingLiquidity]._years.push(2024);
        schedules[exchangeListingLiquidity]._years.push(2025);
        schedules[exchangeListingLiquidity]._years.push(2026);
        schedules[exchangeListingLiquidity].yearToClaimDatesToAmounts[2023][1] =
            20 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[exchangeListingLiquidity].yearToClaimDatesToAmounts[2024][7] =
            10 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[exchangeListingLiquidity].yearToClaimDatesToAmounts[2025][7] =
            10 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[exchangeListingLiquidity].yearToClaimDatesToAmounts[2026][7] =
            10 *
            Millions *
            DECIMALS_MULTIPLIER;

        // researchDevelopment

        schedules[researchDevelopment]._years.push(2024);
        schedules[researchDevelopment]._years.push(2025);
        schedules[researchDevelopment]._years.push(2026);
        schedules[researchDevelopment]._years.push(2027);
        schedules[researchDevelopment].yearToClaimDatesToAmounts[2024][7] =
            13 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[researchDevelopment].yearToClaimDatesToAmounts[2025][7] =
            13 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[researchDevelopment].yearToClaimDatesToAmounts[2026][7] =
            12 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[researchDevelopment].yearToClaimDatesToAmounts[2027][7] =
            12 *
            Millions *
            DECIMALS_MULTIPLIER;

        // teamAdvisors

        schedules[teamAdvisors]._years.push(2024);
        schedules[teamAdvisors]._years.push(2025);
        schedules[teamAdvisors]._years.push(2026);
        schedules[teamAdvisors]._years.push(2027);
        schedules[teamAdvisors].yearToClaimDatesToAmounts[2024][1] =
            4 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[teamAdvisors].yearToClaimDatesToAmounts[2024][7] =
            4 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[teamAdvisors].yearToClaimDatesToAmounts[2025][1] =
            6 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[teamAdvisors].yearToClaimDatesToAmounts[2025][7] =
            6 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[teamAdvisors].yearToClaimDatesToAmounts[2026][1] =
            7 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[teamAdvisors].yearToClaimDatesToAmounts[2026][7] =
            7 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[teamAdvisors].yearToClaimDatesToAmounts[2027][1] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[teamAdvisors].yearToClaimDatesToAmounts[2027][7] =
            8 *
            Millions *
            DECIMALS_MULTIPLIER;

        // treasury

        schedules[treasury]._years.push(2025);
        schedules[treasury]._years.push(2026);
        schedules[treasury]._years.push(2027);
        schedules[treasury].yearToClaimDatesToAmounts[2025][7] =
            5 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[treasury].yearToClaimDatesToAmounts[2026][7] =
            10 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[treasury].yearToClaimDatesToAmounts[2027][7] =
            25 *
            Millions *
            DECIMALS_MULTIPLIER;

        // usersCommunityRewards

        schedules[usersCommunityRewards]._years.push(2023);
        schedules[usersCommunityRewards]._years.push(2024);
        schedules[usersCommunityRewards]._years.push(2025);
        schedules[usersCommunityRewards]._years.push(2026);
        schedules[usersCommunityRewards]._years.push(2027);
        schedules[usersCommunityRewards].yearToClaimDatesToAmounts[2023][1] =
            5 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[usersCommunityRewards].yearToClaimDatesToAmounts[2024][7] =
            5 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[usersCommunityRewards].yearToClaimDatesToAmounts[2025][7] =
            5 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[usersCommunityRewards].yearToClaimDatesToAmounts[2026][7] =
            5 *
            Millions *
            DECIMALS_MULTIPLIER;
        schedules[usersCommunityRewards].yearToClaimDatesToAmounts[2027][7] =
            5 *
            Millions *
            DECIMALS_MULTIPLIER;
    }
}


                /*********************************************************
                  Proudly Developed by MetaIdentity ltd. Copyright 2023
                **********************************************************/