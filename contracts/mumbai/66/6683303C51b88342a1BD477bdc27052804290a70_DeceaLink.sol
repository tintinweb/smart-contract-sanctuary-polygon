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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    function _daysToDate(
        uint256 _days
    ) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(
        uint256 timestamp
    ) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(
        uint256 timestamp
    )
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(
        uint256 timestamp
    ) internal pure returns (bool leapYear) {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(
        uint256 timestamp
    ) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month, ) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(
        uint256 year,
        uint256 month
    ) internal pure returns (uint256 daysInMonth) {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    function getDayOfWeek(
        uint256 timestamp
    ) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(
        uint256 timestamp
    ) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(
        uint256 timestamp
    ) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(
        uint256 timestamp,
        uint256 _years
    ) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(
        uint256 timestamp,
        uint256 _months
    ) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(
        uint256 timestamp,
        uint256 _days
    ) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(
        uint256 timestamp,
        uint256 _hours
    ) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(
        uint256 timestamp,
        uint256 _minutes
    ) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(
        uint256 timestamp,
        uint256 _seconds
    ) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(
        uint256 timestamp,
        uint256 _years
    ) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(
        uint256 timestamp,
        uint256 _months
    ) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(
        uint256 timestamp,
        uint256 _days
    ) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(
        uint256 timestamp,
        uint256 _hours
    ) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(
        uint256 timestamp,
        uint256 _minutes
    ) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(
        uint256 timestamp,
        uint256 _seconds
    ) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (uint256 toYear, uint256 toMonth, ) = _daysToDate(
            toTimestamp / SECONDS_PER_DAY
        );
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

contract DeceaLink is Ownable {
    uint8 counter = 1;
    uint8 totalBot = 0;
    uint8 totalPaymentToken = 0;
    uint8 totalLicense = 0;
    uint256 licenseTimerAddDays = 30;
    uint256 USDTPaymentValue = 10 * 10 ** 6;
    uint256 USDCPaymentValue = 10 * 10 ** 6;
    uint256 BUSDPaymentValue = 10 * 10 ** 18;
    uint256 DAIPaymentValue = 10 * 10 ** 18;
    uint8 totalDefPaymentERC20 = 0;
    address immutable ownerMe;
    address payable ownerAddress;

    function equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function random() internal returns (uint256) {
        counter++;

        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, counter)
                )
            );
    }

    enum isActivated {
        YES,
        NO
    }
    enum allTypeData {
        ADDLISTBOT,
        UPDATELISTBOT,
        ACTIVATEDLISTBOT,
        DEACTIVATEDLISTBOT,
        NEWLICENSE,
        RENEWLICENSE,
        CHANGELICENSETIME,
        ADDPAYMENTERC20TOKEN,
        UPDATEPAYMENTERC20TOKEN,
        ACTIVEPAYMENTERC20TOKEN,
        DEACTIVEPAYMENTERC20TOKEN,
        CHANGEDEFAULTPRICELICENSESTABLECOINS
    }

    enum resStatusEnum {
        YES,
        NO
    }

    struct botData {
        uint8 id;
        string botId;
        string botName;
        uint256 botLicensePay;
        string botDetail;
        isActivated botActivated;
    }
    botData[] listBotData;
    mapping(uint8 => bool) botExists;
    mapping(uint8 => uint8) botIndexs;

    event botDataEvent(
        allTypeData typeData,
        uint8 id,
        string botId,
        string botName,
        uint256 botLicensePay,
        string botDetail,
        isActivated botActivated
    );

    event responseErrorEvent(
        resStatusEnum resStatus,
        allTypeData typeData,
        string errorDetail
    );

    event responseSuccessEvent(
        resStatusEnum resStatus,
        allTypeData typeData,
        string successDetail
    );

    struct licenseData {
        uint8 id;
        uint8 botId;
        string deviceId;
        uint256 licenseId;
        isActivated licenseActivated;
        uint256 licenseExpired;
    }

    struct licenseDataRes {
        uint8 botId;
        string deviceId;
        isActivated licenseActivated;
        uint256 licenseExpired;
        uint256 licenseExpiredYear;
        uint256 licenseExpiredMonth;
        uint256 licenseExpiredDay;
        uint256 licenseExpiredHour;
        uint256 licenseExpiredMinute;
        uint256 licenseExpiredSecond;
    }

    event licenseDataEvent(
        allTypeData typeData,
        uint8 botId,
        string deviceId,
        uint256 licenseId,
        isActivated licenseActivated,
        uint256 licenseExpired
    );

    mapping(string => licenseData[]) licenseDataList;

    struct allowedERC20TokenData {
        uint8 idERC20Token;
        address addressERC20Token;
        string nameERC20Token;
        string symbolERC20Token;
        uint8 decimalERC20Token;
        isActivated paymentActivated;
    }

    struct ERC20TokenDataMinPayment {
        uint8 botId;
        uint256 botLicensePay;
    }

    struct ERC20TokenDataMinPaymentBot {
        string symbolERC20Token;
        address addressERC20Token;
        uint256 botLicensePay;
    }
    ERC20TokenDataMinPayment[] dtump;
    mapping(address => mapping(uint8 => bool)) botMinPaymentERC20TokenExist;
    mapping(address => mapping(uint8 => uint8)) botMinPaymentERC20TokenIndex;
    allowedERC20TokenData[] allowedERC20TokenDataList;
    mapping(address => bool) allowedERC20TokenExist;
    mapping(address => uint8) allowedERC20TokenIndex;
    mapping(address => ERC20TokenDataMinPayment[]) payMinimumERC20Token;
    event allowedERC20TokenDataEvent(
        allTypeData typeData,
        uint8 idERC20Token,
        address addressERC20Token,
        string nameERC20Token,
        string symbolERC20Token,
        uint8 decimalERC20Token,
        isActivated licenseActivated
    );

    function addBot(
        string memory botId,
        string memory botName,
        uint256 botLicensePay,
        string memory botDetail
    ) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(bytes(botId).length > 0);
        require(bytes(botName).length > 0);
        require(bytes(botDetail).length > 0);
        require(botLicensePay > 0);
        totalBot++;
        listBotData.push(
            botData(
                totalBot,
                botId,
                botName,
                botLicensePay,
                botDetail,
                isActivated.YES
            )
        );
        botExists[totalBot] = true;
        botIndexs[totalBot] = uint8(listBotData.length) - 1;
        for (
            uint cntdefpay = 0;
            cntdefpay < totalDefPaymentERC20 - 1;
            cntdefpay++
        ) {
            if (
                botMinPaymentERC20TokenExist[
                    allowedERC20TokenDataList[cntdefpay].addressERC20Token
                ][totalBot] == false
            ) {
                uint256 defbotLicensePay = BUSDPaymentValue;
                if (
                    equal(
                        allowedERC20TokenDataList[cntdefpay].symbolERC20Token,
                        string("USDT")
                    )
                ) {
                    defbotLicensePay = USDTPaymentValue;
                }
                if (
                    equal(
                        allowedERC20TokenDataList[cntdefpay].symbolERC20Token,
                        string("USDC")
                    )
                ) {
                    defbotLicensePay = USDCPaymentValue;
                }
                if (
                    equal(
                        allowedERC20TokenDataList[cntdefpay].symbolERC20Token,
                        string("DAI")
                    )
                ) {
                    defbotLicensePay = DAIPaymentValue;
                }
                payMinimumERC20Token[
                    allowedERC20TokenDataList[cntdefpay].addressERC20Token
                ].push(ERC20TokenDataMinPayment(totalBot, defbotLicensePay));
                botMinPaymentERC20TokenExist[
                    allowedERC20TokenDataList[cntdefpay].addressERC20Token
                ][totalBot] = true;
                botMinPaymentERC20TokenIndex[
                    allowedERC20TokenDataList[cntdefpay].addressERC20Token
                ][totalBot] =
                    uint8(
                        payMinimumERC20Token[
                            allowedERC20TokenDataList[cntdefpay]
                                .addressERC20Token
                        ].length
                    ) -
                    1;
            }
        }

        emit botDataEvent(
            allTypeData.ADDLISTBOT,
            totalBot,
            botId,
            botName,
            botLicensePay,
            botDetail,
            isActivated.YES
        );
        return true;
    }

    function updateBot(
        uint8 id,
        string memory botId,
        string memory botName,
        uint256 botLicensePay,
        string memory botDetail
    ) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(botExists[id]);
        require(botIndexs[id] >= 0);
        isActivated botActivated = isActivated.NO;
        uint8 i = botIndexs[id];
        if (bytes(botId).length > 0) {
            listBotData[i].botId = botId;
        } else {
            botId = listBotData[i].botId;
        }
        if (bytes(botName).length > 0) {
            listBotData[i].botName = botName;
        } else {
            botName = listBotData[i].botName;
        }
        if (botLicensePay > 0) {
            listBotData[i].botLicensePay = botLicensePay;
        } else {
            botLicensePay = listBotData[i].botLicensePay;
        }
        if (bytes(botDetail).length > 0) {
            listBotData[i].botDetail = botDetail;
        } else {
            botDetail = listBotData[i].botDetail;
        }
        botActivated = listBotData[i].botActivated;
        emit botDataEvent(
            allTypeData.UPDATELISTBOT,
            id,
            botId,
            botName,
            botLicensePay,
            botDetail,
            botActivated
        );
        return true;
    }

    function activatedBot(uint8 id) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(botExists[id]);
        require(botIndexs[id] >= 0);
        uint8 currentid = botIndexs[id];
        if (listBotData[currentid].botActivated == isActivated.NO) {
            listBotData[currentid].botActivated = isActivated.YES;
            emit botDataEvent(
                allTypeData.ACTIVATEDLISTBOT,
                currentid,
                listBotData[currentid].botId,
                "",
                0,
                "",
                isActivated.YES
            );
        } else {
            emit responseErrorEvent(
                resStatusEnum.NO,
                allTypeData.ACTIVATEDLISTBOT,
                "Bot Not Exist"
            );
        }
        return true;
    }

    function deactivatedBot(uint8 id) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(botExists[id]);
        require(botIndexs[id] >= 0);
        uint8 currentid = botIndexs[id];
        if (listBotData[currentid].botActivated == isActivated.YES) {
            listBotData[currentid].botActivated = isActivated.NO;
            emit botDataEvent(
                allTypeData.DEACTIVATEDLISTBOT,
                currentid,
                listBotData[currentid].botId,
                "",
                0,
                "",
                isActivated.YES
            );
        } else {
            emit responseErrorEvent(
                resStatusEnum.NO,
                allTypeData.DEACTIVATEDLISTBOT,
                "Bot Not Exist"
            );
        }
        return true;
    }

    function showBot(
        uint8 id
    ) external view returns (botData[] memory, botData memory) {
        require(botExists[id]);
        require(botIndexs[id] >= 0);
        botData memory res;
        if (id == 0) {
            return (listBotData, res);
        } else {
            return (listBotData, listBotData[botIndexs[id]]);
        }
    }

    function withdrawToken(address _tokenContract) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 _amount = tokenContract.balanceOf(address(this));
        tokenContract.approve(address(this), _amount);
        tokenContract.transferFrom(address(this), ownerMe, _amount);
    }

    function payLicense(
        uint8 idBot,
        string memory deviceId
    ) public payable returns (bool) {
        require(bytes(deviceId).length > 0);
        require(botExists[idBot]);
        require(botIndexs[idBot] >= 0);
        botData memory bot = listBotData[botIndexs[idBot]];
        if (msg.value >= bot.botLicensePay) {
            uint256 payment = msg.value;
            payTo(ownerMe, payment);
            bool isLicenseExist = false;
            licenseData memory insertLicenseData;
            if (licenseDataList[deviceId].length > 0) {
                for (
                    uint256 ic = 0;
                    ic < licenseDataList[deviceId].length;
                    ic++
                ) {
                    if (licenseDataList[deviceId][ic].id == idBot) {
                        isLicenseExist = true;
                        if (
                            block.timestamp >
                            licenseDataList[deviceId][ic].licenseExpired
                        ) {
                            uint256 newlicdate = DateTime.addDays(
                                block.timestamp,
                                licenseTimerAddDays
                            );
                            licenseDataList[deviceId][ic]
                                .licenseExpired = newlicdate;
                        } else {
                            uint256 newlicdate = DateTime.addDays(
                                licenseDataList[deviceId][ic].licenseExpired,
                                licenseTimerAddDays
                            );
                            licenseDataList[deviceId][ic]
                                .licenseExpired = newlicdate;
                        }

                        licenseDataList[deviceId][ic]
                            .licenseActivated = isActivated.YES;
                        insertLicenseData = licenseDataList[deviceId][ic];
                        break;
                    }
                }
            }
            uint256 licExpired = 0;
            uint256 licId;
            if (isLicenseExist == true) {
                licExpired = insertLicenseData.licenseExpired;
                licId = insertLicenseData.licenseId;
            } else {
                uint256 hashedWord = random();
                licId = hashedWord;
                totalLicense++;
                licExpired = DateTime.addDays(
                    block.timestamp,
                    licenseTimerAddDays
                );

                insertLicenseData = licenseData(
                    totalLicense,
                    bot.id,
                    deviceId,
                    licId,
                    isActivated.YES,
                    licExpired
                );
                licenseDataList[deviceId].push(insertLicenseData);
            }
            emit licenseDataEvent(
                allTypeData.NEWLICENSE,
                bot.id,
                deviceId,
                licId,
                isActivated.YES,
                licExpired
            );
            return true;
        } else {
            return false;
        }
    }

    function payTo(address to, uint256 amount) internal returns (bool) {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }

    function payToERC20(
        address addressSender,
        address addressERC20Token,
        uint256 amount
    ) internal returns (bool) {
        IERC20 token = IERC20(addressERC20Token);
        bool success = token.transferFrom(addressSender, ownerMe, amount);
        require(success, "Payment failed");
        return true;
    }

    function changeLicenseTime(
        uint256 licenseTime
    ) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(licenseTime > 0);
        licenseTimerAddDays = licenseTime;
        emit responseSuccessEvent(
            resStatusEnum.YES,
            allTypeData.CHANGELICENSETIME,
            "license Time Changed"
        );
        return true;
    }

    function checkLicense(
        uint8 idBot,
        string memory deviceId
    ) external view returns (licenseDataRes memory) {
        require(botExists[idBot]);
        require(botIndexs[idBot] >= 0);
        require(bytes(deviceId).length > 0);
        licenseData memory existLicenseData;
        licenseDataRes memory resLicenseData;
        bool licensevalid = false;
        if (licenseDataList[deviceId].length > 0) {
            for (uint256 ic = 0; ic < licenseDataList[deviceId].length; ic++) {
                if (licenseDataList[deviceId][ic].id == idBot) {
                    uint256 sccvalidate = 0;
                    if (
                        block.timestamp <=
                        licenseDataList[deviceId][ic].licenseExpired
                    ) {
                        sccvalidate++;
                    }
                    if (
                        licenseDataList[deviceId][ic].licenseActivated ==
                        isActivated.YES
                    ) {
                        sccvalidate++;
                    }
                    if (sccvalidate == 2) {
                        existLicenseData = licenseDataList[deviceId][ic];
                        licensevalid = true;
                        break;
                    }
                }
            }
        }
        if (licensevalid == true) {
            (
                uint256 year,
                uint256 month,
                uint256 day,
                uint256 hour,
                uint256 minute,
                uint256 second
            ) = DateTime.timestampToDateTime(existLicenseData.licenseExpired);
            return
                licenseDataRes(
                    existLicenseData.botId,
                    existLicenseData.deviceId,
                    existLicenseData.licenseActivated,
                    existLicenseData.licenseExpired,
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second
                );
        } else {
            return resLicenseData;
        }
    }

    function checkLicenses(
        string memory deviceId
    ) external view returns (licenseDataRes[] memory) {
        require(bytes(deviceId).length > 0);
        licenseDataRes[] memory resdtt;
        if (licenseDataList[deviceId].length > 0) {
            resdtt = new licenseDataRes[](licenseDataList[deviceId].length);
            for (uint256 i = 0; i < licenseDataList[deviceId].length; i++) {
                (
                    uint256 year,
                    uint256 month,
                    uint256 day,
                    uint256 hour,
                    uint256 minute,
                    uint256 second
                ) = DateTime.timestampToDateTime(
                        licenseDataList[deviceId][i].licenseExpired
                    );
                licenseDataRes memory inputdtres;
                inputdtres.botId = licenseDataList[deviceId][i].botId;
                inputdtres.deviceId = licenseDataList[deviceId][i].deviceId;
                inputdtres.licenseActivated = licenseDataList[deviceId][i]
                    .licenseActivated;
                inputdtres.licenseExpired = licenseDataList[deviceId][i]
                    .licenseExpired;
                inputdtres.licenseExpiredYear = year;
                inputdtres.licenseExpiredMonth = month;
                inputdtres.licenseExpiredDay = day;
                inputdtres.licenseExpiredHour = hour;
                inputdtres.licenseExpiredMinute = minute;
                inputdtres.licenseExpiredSecond = second;
                resdtt[i] = inputdtres;
            }
        }
        return resdtt;
    }

    function emergencyWithdrawAll() external onlyOwner {
        (bool success, ) = ownerAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed!");
    }

    function addPaymentToken(
        address addressERC20Token
    ) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(allowedERC20TokenExist[addressERC20Token] == false);
        string memory nameERC20Token = IERC20Metadata(addressERC20Token).name();
        uint8 decimalERC20Token = IERC20Metadata(addressERC20Token).decimals();
        string memory symbolERC20Token = IERC20Metadata(addressERC20Token)
            .symbol();
        totalPaymentToken++;
        allowedERC20TokenDataList.push(
            allowedERC20TokenData(
                totalPaymentToken,
                addressERC20Token,
                nameERC20Token,
                symbolERC20Token,
                decimalERC20Token,
                isActivated.YES
            )
        );
        allowedERC20TokenExist[addressERC20Token] = true;
        allowedERC20TokenIndex[addressERC20Token] =
            uint8(allowedERC20TokenDataList.length) -
            1;
        payMinimumERC20Token[addressERC20Token] = dtump;
        emit allowedERC20TokenDataEvent(
            allTypeData.ADDPAYMENTERC20TOKEN,
            totalPaymentToken,
            addressERC20Token,
            nameERC20Token,
            symbolERC20Token,
            decimalERC20Token,
            isActivated.YES
        );
        return true;
    }

    function addPaymentTokenBotPrice(
        address addressERC20Token,
        uint8 botId,
        uint256 payMinimumERC20TokenPrice
    ) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(botExists[botId]);
        require(allowedERC20TokenExist[addressERC20Token]);
        require(
            botMinPaymentERC20TokenExist[addressERC20Token][botId] == false
        );
        require(payMinimumERC20TokenPrice > 0);
        uint8 idAddressContract = allowedERC20TokenIndex[addressERC20Token];

        payMinimumERC20Token[addressERC20Token].push(
            ERC20TokenDataMinPayment(botId, payMinimumERC20TokenPrice)
        );
        botMinPaymentERC20TokenExist[addressERC20Token][botId] = true;
        botMinPaymentERC20TokenIndex[addressERC20Token][botId] =
            uint8(payMinimumERC20Token[addressERC20Token].length) -
            1;
        emit allowedERC20TokenDataEvent(
            allTypeData.UPDATEPAYMENTERC20TOKEN,
            allowedERC20TokenDataList[idAddressContract].idERC20Token,
            allowedERC20TokenDataList[idAddressContract].addressERC20Token,
            allowedERC20TokenDataList[idAddressContract].nameERC20Token,
            allowedERC20TokenDataList[idAddressContract].symbolERC20Token,
            allowedERC20TokenDataList[idAddressContract].decimalERC20Token,
            isActivated.YES
        );
        return true;
    }

    function updatePaymentTokenBotPrice(
        address addressERC20Token,
        uint8 botId,
        uint256 payMinimumERC20TokenPrice
    ) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(botExists[botId]);
        require(allowedERC20TokenExist[addressERC20Token]);
        require(botMinPaymentERC20TokenExist[addressERC20Token][botId]);
        require(payMinimumERC20TokenPrice > 0);
        uint8 idAddressContract = allowedERC20TokenIndex[addressERC20Token];
        uint8 idAddressContractBotPrice = botMinPaymentERC20TokenIndex[
            addressERC20Token
        ][botId];
        payMinimumERC20Token[addressERC20Token][idAddressContractBotPrice]
            .botLicensePay = payMinimumERC20TokenPrice;
        emit allowedERC20TokenDataEvent(
            allTypeData.UPDATEPAYMENTERC20TOKEN,
            allowedERC20TokenDataList[idAddressContract].idERC20Token,
            allowedERC20TokenDataList[idAddressContract].addressERC20Token,
            allowedERC20TokenDataList[idAddressContract].nameERC20Token,
            allowedERC20TokenDataList[idAddressContract].symbolERC20Token,
            allowedERC20TokenDataList[idAddressContract].decimalERC20Token,
            isActivated.YES
        );
        return true;
    }

    function activatedDeactivatedPaymentToken(
        address addressERC20Token,
        bool activatedThisToken
    ) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(allowedERC20TokenExist[addressERC20Token]);
        uint8 idAddressContract = allowedERC20TokenIndex[addressERC20Token];
        isActivated chgStateToken;
        allTypeData chgStateTokenType;
        if (activatedThisToken) {
            chgStateToken = isActivated.YES;
            chgStateTokenType = allTypeData.ACTIVEPAYMENTERC20TOKEN;
        } else {
            chgStateToken = isActivated.NO;
            chgStateTokenType = allTypeData.DEACTIVEPAYMENTERC20TOKEN;
        }
        if (
            allowedERC20TokenDataList[idAddressContract].paymentActivated ==
            chgStateToken
        ) {} else {
            allowedERC20TokenDataList[idAddressContract]
                .paymentActivated = chgStateToken;
            emit allowedERC20TokenDataEvent(
                chgStateTokenType,
                allowedERC20TokenDataList[idAddressContract].idERC20Token,
                allowedERC20TokenDataList[idAddressContract].addressERC20Token,
                allowedERC20TokenDataList[idAddressContract].nameERC20Token,
                allowedERC20TokenDataList[idAddressContract].symbolERC20Token,
                allowedERC20TokenDataList[idAddressContract].decimalERC20Token,
                chgStateToken
            );
        }

        return true;
    }

    function changeDefaultValueStableCoinPaymentToken(
        uint256 defaultValueStableCoinInDollar
    ) external onlyOwner returns (bool) {
        require(msg.sender == ownerAddress);
        require(defaultValueStableCoinInDollar > 0);
        USDTPaymentValue = defaultValueStableCoinInDollar * 10 ** 6;
        USDCPaymentValue = defaultValueStableCoinInDollar * 10 ** 6;
        BUSDPaymentValue = defaultValueStableCoinInDollar * 10 ** 18;
        DAIPaymentValue = defaultValueStableCoinInDollar * 10 ** 18;
        emit responseSuccessEvent(
            resStatusEnum.YES,
            allTypeData.CHANGEDEFAULTPRICELICENSESTABLECOINS,
            "CHANGE DEFAULT PRICE LICENSE STABLE COINS"
        );

        return true;
    }

    function listPaymentTokens()
        external
        view
        returns (allowedERC20TokenData[] memory)
    {
        return allowedERC20TokenDataList;
    }

    function listPaymentToken(
        address addressERC20Token
    ) external view returns (allowedERC20TokenData memory) {
        require(allowedERC20TokenExist[addressERC20Token]);
        return
            allowedERC20TokenDataList[
                allowedERC20TokenIndex[addressERC20Token]
            ];
    }

    function listBotPayment(
        uint8 botId,
        address addressERC20Token
    )
        public
        view
        returns (uint256 nativeMinPayment, ERC20TokenDataMinPaymentBot[] memory)
    {
        require(botExists[botId]);
        botData memory bot = listBotData[botIndexs[botId]];
        ERC20TokenDataMinPaymentBot[]
            memory erc20MinPayment = new ERC20TokenDataMinPaymentBot[](0);
        if (
            (addressERC20Token ==
                address(0x000000000000000000000000000000000000dEaD)) ||
            (addressERC20Token == address(0))
        ) {
            uint8 indexercpay = 0;
            for (uint256 i = 0; i < allowedERC20TokenDataList.length; i++) {
                if (
                    botMinPaymentERC20TokenExist[
                        allowedERC20TokenDataList[i].addressERC20Token
                    ][botId]
                ) {
                    if (
                        allowedERC20TokenDataList[i].paymentActivated ==
                        isActivated.YES
                    ) {
                        uint8 indexbotinercpay = botMinPaymentERC20TokenIndex[
                            allowedERC20TokenDataList[i].addressERC20Token
                        ][botId];
                        ERC20TokenDataMinPaymentBot
                            memory DTToken = ERC20TokenDataMinPaymentBot(
                                allowedERC20TokenDataList[i].symbolERC20Token,
                                allowedERC20TokenDataList[i].addressERC20Token,
                                payMinimumERC20Token[
                                    allowedERC20TokenDataList[i]
                                        .addressERC20Token
                                ][indexbotinercpay].botLicensePay
                            );
                        erc20MinPayment[indexercpay] = DTToken;
                        indexercpay++;
                    }
                }
            }
        } else {
            if (allowedERC20TokenExist[addressERC20Token]) {
                uint256 i = allowedERC20TokenIndex[addressERC20Token];
                if (
                    botMinPaymentERC20TokenExist[
                        allowedERC20TokenDataList[i].addressERC20Token
                    ][botId]
                ) {
                    if (
                        allowedERC20TokenDataList[i].paymentActivated ==
                        isActivated.YES
                    ) {
                        uint8 indexbotinercpay = botMinPaymentERC20TokenIndex[
                            allowedERC20TokenDataList[i].addressERC20Token
                        ][botId];
                        ERC20TokenDataMinPaymentBot
                            memory DTToken = ERC20TokenDataMinPaymentBot(
                                allowedERC20TokenDataList[i].symbolERC20Token,
                                allowedERC20TokenDataList[i].addressERC20Token,
                                payMinimumERC20Token[
                                    allowedERC20TokenDataList[i]
                                        .addressERC20Token
                                ][indexbotinercpay].botLicensePay
                            );
                        erc20MinPayment[0] = DTToken;
                    }
                }
            }
        }

        return (bot.botLicensePay, erc20MinPayment);
    }

    function approvePaymentTokens(
        address addressERC20Token,
        uint256 _tokenamount
    ) public returns (bool) {
        require(addressERC20Token != address(0));
        require(allowedERC20TokenExist[addressERC20Token]);
        require(_tokenamount > 0);
        IERC20 token = IERC20(addressERC20Token);
        token.approve(address(this), _tokenamount);
        return true;
    }

    function getAllowancePaymentTokens(
        address addressERC20Token,
        address checkAddress
    ) public view returns (uint256) {
        require(addressERC20Token != address(0));
        require(allowedERC20TokenExist[addressERC20Token]);
        require(isContract(checkAddress) == false);
        IERC20 token = IERC20(addressERC20Token);
        address chkaddrs;
        if (checkAddress == address(0)) {
            chkaddrs = msg.sender;
        } else {
            chkaddrs = checkAddress;
        }
        return token.allowance(msg.sender, address(this));
    }

    function isContract(address a) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(a)
        }
        return (size > 0);
    }

    function payLicenseWithToken(
        uint8 botId,
        string memory deviceId,
        address addressERC20Token,
        uint256 _tokenamount
    ) public returns (bool) {
        require(bytes(deviceId).length > 0);
        require(botId >= 0);
        require(botExists[botId]);
        require(addressERC20Token != address(0));
        require(allowedERC20TokenExist[addressERC20Token]);
        require(
            _tokenamount >
                getAllowancePaymentTokens(addressERC20Token, msg.sender)
        );
        require(botMinPaymentERC20TokenExist[addressERC20Token][botId]);
        (
            ,
            ERC20TokenDataMinPaymentBot[] memory listDataMinPaymentBotERC
        ) = listBotPayment(botId, addressERC20Token);
        if (listDataMinPaymentBotERC.length > 0) {
            uint256 botLicensePay;
            bool botLicensePayExist = false;
            for (uint256 xc = 0; xc < listDataMinPaymentBotERC.length; xc++) {
                if (
                    listDataMinPaymentBotERC[xc].addressERC20Token ==
                    addressERC20Token
                ) {
                    botLicensePay = listDataMinPaymentBotERC[xc].botLicensePay;
                    botLicensePayExist = true;
                    break;
                }
            }
            if (botLicensePayExist) {
                botData memory bot = listBotData[botId - 1];
                if (_tokenamount >= botLicensePay) {
                    uint256 payment = _tokenamount;
                    payToERC20(address(msg.sender), addressERC20Token, payment);
                    bool isLicenseExist = false;
                    licenseData memory insertLicenseData;
                    if (licenseDataList[deviceId].length > 0) {
                        for (
                            uint256 ic = 0;
                            ic < licenseDataList[deviceId].length;
                            ic++
                        ) {
                            if (licenseDataList[deviceId][ic].id == botId) {
                                isLicenseExist = true;
                                if (
                                    block.timestamp >
                                    licenseDataList[deviceId][ic].licenseExpired
                                ) {
                                    uint256 newlicdate = DateTime.addDays(
                                        block.timestamp,
                                        licenseTimerAddDays
                                    );
                                    licenseDataList[deviceId][ic]
                                        .licenseExpired = newlicdate;
                                } else {
                                    uint256 newlicdate = DateTime.addDays(
                                        licenseDataList[deviceId][ic]
                                            .licenseExpired,
                                        licenseTimerAddDays
                                    );
                                    licenseDataList[deviceId][ic]
                                        .licenseExpired = newlicdate;
                                }

                                licenseDataList[deviceId][ic]
                                    .licenseActivated = isActivated.YES;
                                insertLicenseData = licenseDataList[deviceId][
                                    ic
                                ];
                                break;
                            }
                        }
                    }
                    uint256 licExpired = 0;
                    uint256 licId;
                    if (isLicenseExist == true) {
                        licExpired = insertLicenseData.licenseExpired;
                        licId = insertLicenseData.licenseId;
                    } else {
                        uint256 hashedWord = random();
                        licId = hashedWord;
                        totalLicense++;
                        licExpired = DateTime.addDays(
                            block.timestamp,
                            licenseTimerAddDays
                        );

                        insertLicenseData = licenseData(
                            totalLicense,
                            bot.id,
                            deviceId,
                            licId,
                            isActivated.YES,
                            licExpired
                        );
                        licenseDataList[deviceId].push(insertLicenseData);
                    }
                    emit licenseDataEvent(
                        allTypeData.NEWLICENSE,
                        bot.id,
                        deviceId,
                        licId,
                        isActivated.YES,
                        licExpired
                    );
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    constructor() {
        ownerMe = msg.sender;
        ownerAddress = payable(msg.sender);
        dtump.push(ERC20TokenDataMinPayment(0, 0));
        address defaultaddressTokenUSDT = address(
            0xc2132D05D31c914a87C6611C10748AEb04B58e8F
        );
        allowedERC20TokenData memory defaultTokenUSDT = allowedERC20TokenData(
            totalPaymentToken++,
            defaultaddressTokenUSDT,
            "Tether USD",
            "USDT",
            uint8(6),
            isActivated.YES
        );
        allowedERC20TokenDataList.push(defaultTokenUSDT);
        allowedERC20TokenExist[defaultaddressTokenUSDT] = true;
        allowedERC20TokenIndex[defaultaddressTokenUSDT] =
            uint8(allowedERC20TokenDataList.length) -
            1;
        payMinimumERC20Token[defaultaddressTokenUSDT] = dtump;
        totalDefPaymentERC20++;
        address defaultaddressTokenUSDC = address(
            0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
        );
        allowedERC20TokenData memory defaultTokenUSDC = allowedERC20TokenData(
            totalPaymentToken++,
            defaultaddressTokenUSDC,
            "USD Coin",
            "USDC",
            uint8(6),
            isActivated.YES
        );
        allowedERC20TokenDataList.push(defaultTokenUSDC);
        allowedERC20TokenExist[defaultaddressTokenUSDC] = true;
        allowedERC20TokenIndex[defaultaddressTokenUSDC] =
            uint8(allowedERC20TokenDataList.length) -
            1;
        payMinimumERC20Token[defaultaddressTokenUSDC] = dtump;
        totalDefPaymentERC20++;
        address defaultaddressTokenBUSD = address(
            0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39
        );
        allowedERC20TokenData memory defaultTokenBUSD = allowedERC20TokenData(
            totalPaymentToken++,
            defaultaddressTokenBUSD,
            "BUSD Token",
            "BUSD",
            uint8(18),
            isActivated.YES
        );
        allowedERC20TokenDataList.push(defaultTokenBUSD);
        allowedERC20TokenExist[defaultaddressTokenBUSD] = true;
        allowedERC20TokenIndex[defaultaddressTokenBUSD] =
            uint8(allowedERC20TokenDataList.length) -
            1;
        payMinimumERC20Token[defaultaddressTokenBUSD] = dtump;
        totalDefPaymentERC20++;
        address defaultaddressTokenDAI = address(
            0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
        );
        allowedERC20TokenData memory defaultTokenDAI = allowedERC20TokenData(
            totalPaymentToken++,
            defaultaddressTokenDAI,
            "Dai Stablecoin",
            "DAI",
            uint8(18),
            isActivated.YES
        );
        allowedERC20TokenDataList.push(defaultTokenDAI);
        allowedERC20TokenExist[defaultaddressTokenDAI] = true;
        allowedERC20TokenIndex[defaultaddressTokenDAI] =
            uint8(allowedERC20TokenDataList.length) -
            1;
        payMinimumERC20Token[defaultaddressTokenDAI] = dtump;
        totalDefPaymentERC20++;
    }
}