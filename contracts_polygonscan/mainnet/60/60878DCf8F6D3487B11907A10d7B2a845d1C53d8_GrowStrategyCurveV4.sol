/**
 *Submitted for verification at polygonscan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// License: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File @openzeppelin/contracts/utils/[email protected]

// License: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File @openzeppelin/contracts/utils/math/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File @openzeppelin/contracts/utils/math/[email protected]

// License: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File @openzeppelin/contracts-upgradeable/security/[email protected]

// License: MIT

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// File contracts/grow/GrowRegister.sol

// License: MIT
pragma solidity 0.8.6;

// PLEASE ONLY WRITE CONSTANT VARIABLE HERE
contract GrowRegisterStorage {
    bytes32 public constant CONTRACT_IDENTIFIER = keccak256("GrowRegisterStorage");

    address public constant PlatformTreasureAddress = 0x41A7aC2f77e952316dCe7f4c8Cd2FEb18f896F58;
    address public constant ZapAddress = 0x092b9E2cCf536C93aE5896A0f308D03Cc56D5394;

    address public constant GrowRewarderAddress = 0x9fdf7D06546c09f1ad5737a3c3461C9A28991291;
    address public constant GrowStakingPoolAddress = 0x678662cF7857d3c4e24637B37b0aF9AdE7308CB5;

    address public constant GrowTokenAddress = 0x8dE77A8C221AaFF72872408d635B8072600aB80d;

    address public constant PriceCalculatorAddress = 0x3Fa849CBf0d57Fa28F777cF34430858E12532eEe;
    address public constant WNativeRelayerAddress = 0xCF726054E667E441F116B86Ff8Bb915629E8F586;

    address public constant GrowMembershipPoolAddress = 0xf5B430bac42d282e1F2151E3e2C397254895e361;
    address public constant GrowTestPilotAddress = 0x3b60D071eB259046a312eC31B12FBA5c7B1FE013;
    address public constant GrowWhitelistAddress = 0x19334C05672bca95Cc22B794287c6D3D76C5DFca;

    uint public constant TestFlightEndTime = 1629172800;
}

library GrowRegister {
    /// @notice Config save in register
    GrowRegisterStorage internal constant get = GrowRegisterStorage(0x8C8Df7EB538947DbC569a13801c489Cc9d1dfd7C);
}

// File contracts/interfaces/IUniv2LikePair.sol

// License: MIT
pragma solidity 0.8.6;

interface IUniv2LikePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File contracts/interfaces/IUniv2LikeRouter01.sol

// License: MIT
pragma solidity 0.8.6;

interface IUniv2LikeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File contracts/interfaces/IUniv2LikeRouter02.sol

// License: MIT
pragma solidity 0.8.6;

interface IUniv2LikeRouter02 is IUniv2LikeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File contracts/interfaces/IProxyFactory.sol

// License: MIT
pragma solidity 0.8.6;

interface IGrowUpgradeableImplementation {
    function CONTRACT_IDENTIFIER() external view returns (bytes32);
}

// File contracts/interfaces/IGrow.sol

// License: MIT
pragma solidity 0.8.6;

interface IGrowRewardReceiver {
    function addReward(uint256 reward) external;
}

interface IGrowRewarder {
    function notifyUserSharesUpdate(address userAddress, uint256 sharesUpdateTo, bool isWithdraw) external;
    function depositRewardAddReward(address userAddress, uint256 amountInNativeToken) external;
    function profitRewardByContribution(uint256 profitGrowAmount) external;
    function getRewards(address userAddress) external;
    function getVaultReward() external;
    function calculatePendingRewards(address strategyAddress, address userAddress) external view returns (uint256);
    function calculatePendingVaultRewards(address strategyAddress) external view returns (uint256);
}

interface IGrowStakingPool {
    function depositTo(uint256 amount, address userAddress) external;
}

interface IGrowProfitReceiver {
    function pump(uint256 amount) external;
}

interface IGrowMembershipController {
    function hasMembership(address userAddress) external view returns (bool);
}

interface IGrowStrategy {
    function STAKING_TOKEN() view external returns (address);
    function depositTo(uint wantTokenAmount, address userAddress) external;

    function totalShares() external view returns (uint256);
    function sharesOf(address userAddress) external view returns (uint256);

    function IS_EMERGENCY_MODE() external returns (bool);
}

interface IGrowStrategyCurve is IGrowStrategy {
    function getTokenAmountOut(address token, uint256 amount) external view returns (uint256);
    function getOriginTokenAmountOut(address token, uint256 amount) external view returns (uint256);

    function depositToByOriginToken(address originTokenAddress, uint256 originTokenAmount, address userAddress, uint minReceive) external;
    function CURVE_ADAPTER() view external returns (address);
}

interface IPriceCalculator {
    function tokenPriceIn1e6USDC(address tokenAddress, uint amount) view external returns (uint256 price);
}

interface IZAP {
    function swap(address[] memory tokens, uint amount, address receiver, uint) external payable returns (uint);
    function zapOut(address fromToken, address toToken, uint amount, address receiver, uint minReceive) external payable;
    function zapTokenToLP(address fromToken, uint amount, address lpToken, address receiver) external payable returns (uint);
    function zapTokenToLP(address fromToken, uint amount, address lpToken, address receiver, uint minLPReceive) external payable returns (uint);
}

interface IGrowTestPilot {
    function isTestPilot(address userAddress) external view returns (bool);
}

interface IGrowWhitelist {
    function isWhitelist(address userAddress) external view returns (bool);
}

// File contracts/strategies/BaseGrowStrategyV4.sol

// License: MIT
pragma solidity 0.8.6;

abstract contract BaseGrowStrategyV4 is  IGrowStrategy, Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant _DECIMAL = 1e18;

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    // --------------------------------------------------------------
    // State variables
    // --------------------------------------------------------------

    /// @dev total shares of this strategy
    uint256 override public totalShares;

    /// @dev Threshold for withdraw performanceFee
    uint256 public performanceFeeThreshold;

    /// @dev Performance fee rate in base point (100 == 1%)
    uint256 public performanceFeeRate;

    /// @dev platform fee rate in base point (100 == 1%)
    uint256 public platformFeeRate;

    /// @notice rewards release duration
    uint256 public rewardDurationSeconds;

    /// @notice last rewards update block
    uint256 public lastRewardTimestamp;

    /// @notice remaining rewards
    uint256 public remainingRewardTokenAmount;

    /// @notice reward per share
    uint256 public rewardPerShareStored;

    /// @dev user share
    mapping (address => uint256) internal userShares;

    /// @notice user reward per share Paid
    mapping(address => uint256) public userRewardPerSharePaid;

    /// @dev Threshold for swap reward token to staking token for save gas fee
    uint256 public rewardTokenSwapThreshold;

    /// @dev For reduce amount which is toooooooo small
    uint256 constant DUST = 1000;

    /// @dev Mark is emergency mode
    bool override public IS_EMERGENCY_MODE;

    /// @dev Is rewarder enable
    bool public rewarderEnabled;

    /// @dev Staking token
    address override public STAKING_TOKEN;

    /// @dev withdraw fee rate in base point (100 == 1%)
    uint256 public withdrawFeeRate;

    /// @dev contract paused status
    bool public _paused;

    /// @dev contract paused until timestamp
    uint256 public _pauseUntil;

    // --------------------------------------------------------------
    // State variables upgrade
    // --------------------------------------------------------------

    // Reserved storage space to allow for layout changes in the future.
    uint256[46] private ______gap;

    // --------------------------------------------------------------
    // Initialize
    // --------------------------------------------------------------

    function __base_initialize(
        address _STAKING_TOKEN,
        uint256 _withdrawFeeRate
    ) internal initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        rewardDurationSeconds = 64000;
        performanceFeeRate = 1500;
        platformFeeRate = 500;
        performanceFeeThreshold = DUST;

        rewardTokenSwapThreshold = 1e16;
        STAKING_TOKEN = _STAKING_TOKEN;
        withdrawFeeRate = _withdrawFeeRate;
    }

    // --------------------------------------------------------------
    // Config Interface
    // --------------------------------------------------------------

    function updatePlatformFeeRate(uint256 _platformFeeRate) external onlyRole(CONFIGURATOR_ROLE) {
        require(_platformFeeRate < 1500, "rate invalid");
        platformFeeRate = _platformFeeRate;
    }

    function updatePerformanceFeeThreshold(uint256 _performanceFeeThreshold) external onlyRole(CONFIGURATOR_ROLE) {
        performanceFeeThreshold = _performanceFeeThreshold;
    }

    function updateWithdrawFeeRate(uint256 _withdrawFeeRate) external onlyRole(CONFIGURATOR_ROLE) {
        require(_withdrawFeeRate <= 100, "rate invalid");
        withdrawFeeRate = _withdrawFeeRate;
    }

    function updateThresholds(uint256 _rewardTokenSwapThreshold) external onlyRole(CONFIGURATOR_ROLE) {
        rewardTokenSwapThreshold = _rewardTokenSwapThreshold;
    }

    function setRewardDurationSeconds(uint256 _rewardsDurationSeconds) external onlyRole(CONFIGURATOR_ROLE) {
        require(_rewardsDurationSeconds > 0, "_rewardsDurationSeconds invalid");
        updateReward();
        rewardDurationSeconds = _rewardsDurationSeconds;
    }

    function setStakingToken(address _STAKING_TOKEN) external onlyRole(CONFIGURATOR_ROLE) {
        STAKING_TOKEN = _STAKING_TOKEN;
    }

    function enableRewarder(bool status) external onlyRole(CONFIGURATOR_ROLE) {
        rewarderEnabled = status;
    }

    // --------------------------------------------------------------
    // Misc
    // --------------------------------------------------------------

    function approveToken(address token, address to, uint256 amount) internal {
        if (IERC20(token).allowance(address(this), to) < amount) {
            IERC20(token).safeApprove(to, 0);
            IERC20(token).safeIncreaseAllowance(to, amount);
        }
    }

    modifier onlyHumanOrWhitelisted {
        require(tx.origin == msg.sender || IGrowWhitelist(GrowRegister.get.GrowWhitelistAddress()).isWhitelist(msg.sender), "Whitelist: caller is not on the whitelist");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "paused");
        _;
    }

    // --------------------------------------------------------------
    // Reward
    // --------------------------------------------------------------

    function rewardPerShare() public view returns (uint256) {
        if (totalShares == 0) {
            return rewardPerShareStored;
        }
        return rewardPerShareStored.add(pendingRewardsPerShare());
    }

    function pendingRewardsPerShare() public view returns(uint256) {
        if (block.timestamp <= lastRewardTimestamp || totalShares == 0) {
            return 0;
        }

        uint256 totalPendingRewards = Math.min(
            remainingRewardTokenAmount,
            remainingRewardTokenAmount
                .mul(block.timestamp.sub(lastRewardTimestamp))
                .div(rewardDurationSeconds)
        );
        return totalPendingRewards.mul(_DECIMAL).div(totalShares);
    }

    function rewardsPerSharePerSecond() public view returns(uint256) {
        if (totalShares == 0) {
            return 0;
        } else {
            return remainingRewardTokenAmount
                .mul(_DECIMAL)
                .div(rewardDurationSeconds).div(totalShares);
        }
    }

    function updateReward() internal {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }
        uint256 reward = remainingRewardTokenAmount.mul(block.timestamp.sub(lastRewardTimestamp)).div(rewardDurationSeconds);

        rewardPerShareStored = rewardPerShare();
        remainingRewardTokenAmount = remainingRewardTokenAmount.sub(Math.min(remainingRewardTokenAmount, reward));
        lastRewardTimestamp = block.timestamp;
    }

    function addReward(uint256 reward) public whenNotPaused {
        // 1. update remaining reward
        updateReward();

        // 2. transfer reward
        IERC20(GrowRegister.get.GrowTokenAddress()).safeTransferFrom(msg.sender, address(this), reward);

        // 3. update remaining reward
        remainingRewardTokenAmount = remainingRewardTokenAmount.add(reward);

        emit LogRewardAdded(reward);
    }

    function settlementReward(address userAddress) internal {
        uint256 _rewardPerShare = rewardPerShare();
        if (_rewardPerShare > 0) {
            // get reward token
            uint256 rewardAmount = userShares[userAddress].mul(_rewardPerShare.sub(userRewardPerSharePaid[userAddress])).div(_DECIMAL);
            // pay reward
            if ( rewardAmount > DUST) {
                IERC20(GrowRegister.get.GrowTokenAddress()).safeTransfer(userAddress, rewardAmount);
            }
            userRewardPerSharePaid[userAddress] = _rewardPerShare;
        }
    }

    // base on tokenAddress and
    function _chargePerformanceFee(address performanceTokenAddress, uint256 performanceTokenAmount) internal {
        address growToken = GrowRegister.get.GrowTokenAddress();
        address growStakingPool = GrowRegister.get.GrowStakingPoolAddress();

        // swap underlying reward token to grow token
        approveToken(performanceTokenAddress, GrowRegister.get.ZapAddress(), performanceTokenAmount);
        address[] memory tokens = new address[](3);
        tokens[0] = performanceTokenAddress;
        tokens[1] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC
        tokens[2] = growToken;
        uint256 growTokenAmount = IZAP(GrowRegister.get.ZapAddress()).swap(tokens, performanceTokenAmount, address(this), 0);

        approveToken(growToken, growStakingPool, growTokenAmount);
        IGrowRewardReceiver(growStakingPool).addReward(growTokenAmount);

        // get profitRewardByContribution base on rewardFeeAmount
        _profitRewardByContribution(growTokenAmount);

        emit LogPerformanceFee(growTokenAmount, growTokenAmount);
    }

    // --------------------------------------------------------------
    // User Read interface
    // --------------------------------------------------------------

    function sharesOf(address account) override public view returns (uint256) {
        return userShares[account];
    }

    function totalBalance() public view returns(uint256) {
        return _underlyingWantTokenAmount();
    }

    function balanceOf(address account) public view returns(uint256) {
        if (totalShares == 0) return 0;
        if (sharesOf(account) == 0) return 0;

        uint256 underlyingWantTokenAmount = _underlyingWantTokenAmount();

        return underlyingWantTokenAmount.mul(sharesOf(account)).div(totalShares);
    }

    // --------------------------------------------------------------
    // Keeper Interface
    // --------------------------------------------------------------

    function harvest(bool harvestFromUnderlying) external whenNotPaused onlyRole(KEEPER_ROLE) {
      _harvest(harvestFromUnderlying, true);
    }

    // --------------------------------------------------------------
    // User Write Interface
    // --------------------------------------------------------------

    function withdraw(uint256 wantTokenAmount) external virtual whenNotPaused nonEmergency nonReentrant {
        _getRewards(msg.sender);
        uint256 withdrawnWantTokenAmount = _withdraw(wantTokenAmount);

        _sendToken(msg.sender, withdrawnWantTokenAmount);
    }

    function withdrawAs(uint256 wantTokenAmount, address tokenAddress, uint minReceive) external virtual whenNotPaused nonEmergency nonReentrant {
        _withdrawAs(wantTokenAmount, tokenAddress, minReceive);
    }

    function withdrawAll() external virtual whenNotPaused nonEmergency nonReentrant {
        _getRewards(msg.sender);
        uint256 withdrawnWantTokenAmount = _withdraw(balanceOf(msg.sender));
        _sendToken(msg.sender, withdrawnWantTokenAmount);
    }

    function withdrawAllAs(address tokenAddress, uint minReceive) external virtual whenNotPaused nonEmergency nonReentrant {
        _withdrawAs(balanceOf(msg.sender), tokenAddress, minReceive);
    }

    function getRewards() external virtual whenNotPaused nonEmergency nonReentrant {
        _getRewards(msg.sender);
    }

    function deposit(uint256 wantTokenAmount) external virtual whenNotPaused onlyHumanOrWhitelisted nonEmergency nonReentrant {
        _getRewards(msg.sender);

        // get wantTokenAmount from msg sender
        _receiveToken(msg.sender, wantTokenAmount);

        _deposit(wantTokenAmount, msg.sender);
    }

    function depositTo(uint256 wantTokenAmount, address userAddress) override external whenNotPaused onlyRole(CONTROLLER_ROLE) {
        _getRewards(userAddress);

        // get wantTokenAmount from msg sender
        _receiveToken(msg.sender, wantTokenAmount);

        _deposit(wantTokenAmount, userAddress);
    }

    // --------------------------------------------------------------
    // Deposit and withdraw
    // --------------------------------------------------------------

    function _deposit(uint256 wantTokenAmount, address userAddress) internal {
        require(wantTokenAmount > DUST, "GrowStrategy: amount toooooo small");

        // save current underlying want token amount for caluclate shares
        uint underlyingWantTokenAmountBeforeEnter = _underlyingWantTokenAmount();

        // receive token and deposit into underlying contract
        uint256 wantTokenAdded = _depositUnderlying(wantTokenAmount);

        // calculate shares
        uint256 sharesAdded = 0;
        if (totalShares == 0) {
            sharesAdded = wantTokenAdded;
        } else {
            sharesAdded = totalShares
                .mul(wantTokenAdded).mul(_DECIMAL)
                .div(underlyingWantTokenAmountBeforeEnter).div(_DECIMAL);
        }

        // notice shares change for rewarder
        _notifyUserSharesUpdate(userAddress, userShares[userAddress].add(sharesAdded), false);

        // add our shares
        totalShares = totalShares.add(sharesAdded);
        userShares[userAddress] = userShares[userAddress].add(sharesAdded);

        if (rewarderEnabled) {
            // notice rewarder add deposit reward
            _depositRewardAddReward(
                userAddress,
                _wantTokenPriceIn1e6USDC(wantTokenAdded)
            );
        }

        emit LogDeposit(userAddress, wantTokenAmount, wantTokenAdded, sharesAdded);
    }

    function _withdraw(uint256 wantTokenAmount) internal returns (uint256) {
        require(userShares[msg.sender] > 0, "GrowStrategy: user without shares");

        uint underlyingWantTokenAmountBefore = _underlyingWantTokenAmount();

        // calculate shares
        uint256 shareRemoved = Math.min(
            userShares[msg.sender],
            wantTokenAmount
                .mul(totalShares).mul(_DECIMAL)
                .div(underlyingWantTokenAmountBefore).div(_DECIMAL)
        );

        // reduce share dust
        if (userShares[msg.sender].sub(shareRemoved) < DUST) {
            shareRemoved = userShares[msg.sender];
        }

        // notice shares change for rewarder
        _notifyUserSharesUpdate(msg.sender, userShares[msg.sender].sub(shareRemoved), true);

        // remove our shares
        totalShares = totalShares.sub(shareRemoved);
        userShares[msg.sender] = userShares[msg.sender].sub(shareRemoved);

        // withdraw from under contract
        uint256 withdrawnWantTokenAmount = _withdrawUnderlying(wantTokenAmount);

        // charge withdraw fee if not pro
        bool isPro = IGrowMembershipController(GrowRegister.get.GrowMembershipPoolAddress()).hasMembership(msg.sender);
        if (!isPro) {
            // send withdraw fee to PLATFORM_TREASURE
            uint256 withdrawFeeAmount = withdrawnWantTokenAmount.mul(withdrawFeeRate).div(10000);
            IERC20(STAKING_TOKEN).safeTransfer(GrowRegister.get.PlatformTreasureAddress(), withdrawFeeAmount);
            withdrawnWantTokenAmount = withdrawnWantTokenAmount.sub(withdrawFeeAmount);
        }

        emit LogWithdraw(msg.sender, wantTokenAmount, withdrawnWantTokenAmount, shareRemoved);

        return withdrawnWantTokenAmount;
    }

    function _withdrawAs(uint256 wantTokenAmount, address tokenAddress, uint minReceive) internal virtual {
        _getRewards(msg.sender);
        uint256 withdrawnWantTokenAmount = _withdraw(wantTokenAmount);

        approveToken(STAKING_TOKEN, GrowRegister.get.ZapAddress(), withdrawnWantTokenAmount);

        IZAP(GrowRegister.get.ZapAddress()).zapOut(STAKING_TOKEN, tokenAddress, withdrawnWantTokenAmount, msg.sender, minReceive);
    }

    function _getRewards(address userAddress) internal {
        updateReward();

        // get GROWs :P
        _getGrowRewards(userAddress);

        // get reward token
        settlementReward(userAddress);

        // is STAKING_TOKEN is one of UNDERLYING_REWARD_TOKENS, must run _harvest make sure withdraw right amount
        if (totalShares > 0) {
            _harvest(true, false);
        }
    }

    // --------------------------------------------------------------
    // Interactive with under contract
    // --------------------------------------------------------------

    function _wantTokenPriceIn1e6USDC(uint256 amount) public view virtual returns (uint256);
    function _underlyingWantTokenAmount() public virtual view returns (uint256);
    function _receiveToken(address sender, uint256 amount) internal virtual;
    function _sendToken(address receiver, uint256 amount) internal virtual;
    function _depositUnderlying(uint256 wantTokenAmount) internal virtual returns (uint256);
    function _withdrawUnderlying(uint256 wantTokenAmount) internal virtual returns (uint256);
    function _trySwapUnderlyingRewardToRewardToken() internal virtual;
    function _harvest(bool harvestFromUnderlying, bool swapUnderlyingReward) internal virtual;

    // function depositByOriginToken(uint256 originTokenAmount) external virtual;
    // function withdrawAsOriginToken(uint256 underlyingWantTokenAmount) external virtual;
    // function withdrawAllAsOriginToken() external virtual;

    // --------------------------------------------------------------
    // Call rewarder
    // --------------------------------------------------------------

    modifier onlyRewarderEnabled {
        if (rewarderEnabled) {
            _;
        }
    }

    function _depositRewardAddReward(address userAddress, uint256 amountInNativeToken) internal onlyRewarderEnabled {
        IGrowRewarder(GrowRegister.get.GrowRewarderAddress()).depositRewardAddReward(userAddress, amountInNativeToken);
    }

    function _notifyUserSharesUpdate(address userAddress, uint256 shares, bool isWithdraw) internal onlyRewarderEnabled {
        IGrowRewarder(GrowRegister.get.GrowRewarderAddress()).notifyUserSharesUpdate(userAddress, shares, isWithdraw);
    }

    function _getGrowRewards(address userAddress) internal onlyRewarderEnabled {
        IGrowRewarder(GrowRegister.get.GrowRewarderAddress()).getRewards(userAddress);
    }

    function _profitRewardByContribution(uint256 profitGrowAmount) internal onlyRewarderEnabled {
        IGrowRewarder(GrowRegister.get.GrowRewarderAddress()).profitRewardByContribution(profitGrowAmount);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */
    // @dev stakingToken must not remain balance in this contract. So dev should salvage staking token transferred by mistake.
    function recoverToken(address token, uint amount) external onlyRole(CONFIGURATOR_ROLE) {
        require(token != GrowRegister.get.GrowTokenAddress(), "GrowStrategy: no grow.");
        IERC20(token).safeTransfer(GrowRegister.get.PlatformTreasureAddress(), amount);
        emit LogRecovered(token, amount);
    }

    // --------------------------------------------------------------
    // !! Pause !!
    // --------------------------------------------------------------

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused && _pauseUntil > block.timestamp;
    }

    function setPaused(bool _pausedStatus, uint256 _pauseUntilTimestamp) external onlyRole(CONTROLLER_ROLE) {
        _paused = _pausedStatus;
        if (_paused) {
            _pauseUntil = _pauseUntilTimestamp;
        }

        emit LogPaused(_paused, msg.sender, _pauseUntil);
    }

    function pause() external whenNotPaused onlyRole(CONTROLLER_ROLE) {
        _paused = true;
        _pauseUntil = block.timestamp + 10 minutes;
        emit LogPaused(_paused, msg.sender, _pauseUntil);
    }

    // --------------------------------------------------------------
    // !! Emergency !!
    // --------------------------------------------------------------

    modifier nonEmergency() {
        require(IS_EMERGENCY_MODE == false, "GrowStrategy: emergency mode.");
        _;
    }

    modifier onlyEmergency() {
        require(IS_EMERGENCY_MODE == true, "GrowStrategy: not emergency mode.");
        _;
    }

    function emergencyExit() external virtual;
    function emergencyWithdraw() external virtual;

    // --------------------------------------------------------------
    // Events
    // --------------------------------------------------------------
    event LogDeposit(address user, uint256 wantTokenAmount, uint wantTokenAdded, uint256 shares);
    event LogWithdraw(address user, uint256 wantTokenAmount, uint withdrawWantTokenAmount, uint256 shares);
    event LogReinvest(uint256 amount);
    event LogPaused(bool paused, address account, uint256 pauseUntil);
    event LogRewardAdded(uint256 amount);
    event LogRecovered(address token, uint256 amount);
    event LogPerformanceFee(uint256 amount, uint256 rewardFeeAmount);

}

// File contracts/utils/CurveAdapter.sol

// License: MIT
pragma solidity 0.8.6;

interface ICurveCryptoSwap{
    function token() external view returns (address);
    function coins(uint256 i) external view returns (address);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
}

interface ICurveCryptoSwap3 is ICurveCryptoSwap{
    function calc_token_amount(uint256[3] calldata amounts, bool is_deposit) external view returns (uint256);
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount, bool _use_underlying) external returns (uint256);
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount, bool _use_underlying) external returns (uint256);
    function calc_withdraw_one_coin(uint256 token_amount, int128 i) external view returns (uint256);
}

interface ICurveCryptoSwap5 is ICurveCryptoSwap{
    function calc_token_amount(uint256[5] calldata amounts, bool is_deposit) external view returns (uint256);
    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external;
    function calc_withdraw_one_coin(uint256 token_amount, uint256 i) external view returns (uint256);
}

contract CurveAdapter is Initializable {
    using SafeERC20 for IERC20;

    struct CurveConfig {
        address pair;
        address minter;
        address[] tokens;
        mapping(address => uint256) tokenIndex;
    }

    address public constant USDC_TOKEN = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant USD_BTC_ETH = 0x8096ac61db23291252574D49f036f0f9ed8ab390;
    address public constant DAI_USDC_USDT = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;

    mapping(address => CurveConfig) public config;

    function initialize() public initializer {
        config[USD_BTC_ETH].pair = USD_BTC_ETH;
        config[USD_BTC_ETH].minter = 0x3FCD5De6A9fC8A99995c406c77DDa3eD7E406f81;
        config[USD_BTC_ETH].tokens = [
            0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
            0xc2132D05D31c914a87C6611C10748AEb04B58e8F,
            0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6,
            0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
        ];

        uint i;
        for (i = 0; i < config[USD_BTC_ETH].tokens.length; ++i) {
            config[USD_BTC_ETH].tokenIndex[config[USD_BTC_ETH].tokens[i]] = i;
        }

        config[DAI_USDC_USDT].pair = DAI_USDC_USDT;
        config[DAI_USDC_USDT].minter = 0x445FE580eF8d70FF569aB36e80c647af338db351;
        config[DAI_USDC_USDT].tokens = [
            0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
            0xc2132D05D31c914a87C6611C10748AEb04B58e8F
        ];

        for (i = 0; i < config[DAI_USDC_USDT].tokens.length; ++i) {
            config[DAI_USDC_USDT].tokenIndex[config[DAI_USDC_USDT].tokens[i]] = i;
        }
    }

    // --------------------------------------------------------------
    // User Read Interface
    // --------------------------------------------------------------

    function getTokenIndexFromOriginalTokens(address pair, address token) public view returns (uint256) {
        uint256 index = config[pair].tokenIndex[token];
        if (config[pair].tokens[index] == token) {
            return index;
        }
        return type(uint256).max;
    }

    function getTokenAmountOut(address pair, address token, uint256 amount) public view returns (uint256) {
        uint256 tokenIndex = getTokenIndexFromOriginalTokens(pair, token);

        if (pair == DAI_USDC_USDT) {
            uint256[3] memory amounts;
            amounts[tokenIndex] = amount;
            return ICurveCryptoSwap3(config[pair].minter).calc_token_amount(amounts, true);
        }

        if (pair == USD_BTC_ETH) {
            uint256[5] memory amounts;
            amounts[tokenIndex] = amount;
            return ICurveCryptoSwap5(config[pair].minter).calc_token_amount(amounts, true);
        }

        revert("pair unsupport");
    }

    function getOriginTokenAmountOut(address pair, address token, uint256 amount) public view returns (uint256) {
        uint256 tokenIndex = getTokenIndexFromOriginalTokens(pair, token);

        if (pair == DAI_USDC_USDT) {
            return ICurveCryptoSwap3(config[pair].minter).calc_withdraw_one_coin(amount, int128(uint128(tokenIndex)));
        }

        if (pair == USD_BTC_ETH) {
            return ICurveCryptoSwap5(config[pair].minter).calc_withdraw_one_coin(amount, tokenIndex);
        }

        revert("pair unsupport");
    }

    function _wantTokenPriceIn1e6USDC(address pair, uint256 amount) public view returns (uint256) {
        return getOriginTokenAmountOut(pair, USDC_TOKEN, amount);
    }

    function deposit(address pair, address fromToken, uint256 fromTokenAmount, uint256 minReceive) external returns (uint256) {
        require(config[pair].pair == pair, "pair unsupport");

        uint256 tokenIndex = getTokenIndexFromOriginalTokens(pair, fromToken);
        require(tokenIndex != type(uint256).max, "token unsupport");

        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), fromTokenAmount);
        IERC20(fromToken).safeIncreaseAllowance(config[pair].minter, fromTokenAmount);

        uint256 wantTokenBefore = IERC20(pair).balanceOf(address(this));

        if (pair == DAI_USDC_USDT) {
            uint256[3] memory amounts;
            amounts[tokenIndex] = fromTokenAmount;
            ICurveCryptoSwap3(config[pair].minter).add_liquidity(amounts, minReceive, true);
        } else if (pair == USD_BTC_ETH) {
            uint256[5] memory amounts;
            amounts[tokenIndex] = fromTokenAmount;
            ICurveCryptoSwap5(config[pair].minter).add_liquidity(amounts, minReceive);
        } else {
            revert("pair unsupport");
        }

        uint256 receivedAmount = IERC20(pair).balanceOf(address(this)) - wantTokenBefore;
        IERC20(pair).safeTransfer(msg.sender, receivedAmount);

        return receivedAmount;
    }

    function withdraw(address pair, uint256 withdrawAmount, address toToken, uint256 minReceive) external returns (uint256) {
        require(config[pair].pair == pair, "pair unsupport");

        uint256 tokenIndex = getTokenIndexFromOriginalTokens(pair, toToken);
        require(tokenIndex != type(uint256).max, "token unsupport");

        IERC20(pair).safeTransferFrom(msg.sender, address(this), withdrawAmount);

        uint256 wantTokenBefore = IERC20(toToken).balanceOf(address(this));

        IERC20(pair).safeIncreaseAllowance(config[pair].minter, withdrawAmount);
        if (pair == DAI_USDC_USDT) {
            ICurveCryptoSwap3(config[pair].minter).remove_liquidity_one_coin(withdrawAmount, int128(uint128(tokenIndex)), minReceive, true);
        } else if (pair == USD_BTC_ETH) {
            ICurveCryptoSwap5(config[pair].minter).remove_liquidity_one_coin(withdrawAmount, tokenIndex, minReceive);
        } else {
            revert("pair unsupport");
        }

        uint256 receivedAmount = IERC20(toToken).balanceOf(address(this)) - wantTokenBefore;
        IERC20(toToken).safeTransfer(msg.sender, receivedAmount);

        return receivedAmount;
    }

}

// File contracts/strategies/GrowStrategyCurveV4.sol

// License: MIT
pragma solidity 0.8.6;

interface IGauge {
    function balanceOf(address) external view returns (uint256);
    function claim_rewards() external;
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function lp_token() external view returns (address);
    function reward_tokens(uint256 index) external view returns (address);
}

contract GrowStrategyCurveV4 is IGrowUpgradeableImplementation, BaseGrowStrategyV4 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 override public constant CONTRACT_IDENTIFIER = keccak256("GrowStrategyCurveV4");
    address public constant USDC_TOKEN = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    // --------------------------------------------------------------
    // Address
    // --------------------------------------------------------------

    /// @dev GAUGE address, for interactive underlying contract
    address public GAUGE;

    /// @dev Underlying reward tokens, pAUTO + WMATIC
    address[] public UNDERLYING_REWARD_TOKENS;

    /// @dev Underlying reward tokens amount
    mapping(address => uint256) public underlyingRewardTokensAmount;

    /// @dev Underlying reward tokens swap threshold amount
    mapping(address => uint256) public underlyingRewardTokensSwapThreshold;

    address public CURVE_ADAPTER;

    function initialize(
        address _GAUGE,
        uint256 _WITHDRAW_FEE_RATE,
        address _CURVE_ADAPTER
    ) public initializer {
        GAUGE = _GAUGE;

        // most reward_tokens.length is 2 
        for (uint256 i = 0; i < 2; ++i) {
            address token = IGauge(_GAUGE).reward_tokens(i);
            if (token != address(0)) {
                UNDERLYING_REWARD_TOKENS.push(token);
            }
        }

        address _STAKING_TOKEN = IGauge(_GAUGE).lp_token();

        __base_initialize(
            _STAKING_TOKEN,
            _WITHDRAW_FEE_RATE
        );

        CURVE_ADAPTER = _CURVE_ADAPTER;
    }

    // --------------------------------------------------------------
    // Config Interface
    // --------------------------------------------------------------

    function updateRewardTokenThreshold(address token, uint256 _rewardTokenSwapThreshold) external onlyRole(CONFIGURATOR_ROLE) {
        underlyingRewardTokensSwapThreshold[token] = _rewardTokenSwapThreshold;
    }

    // --------------------------------------------------------------
    // Current strategy info in under contract
    // --------------------------------------------------------------

    function _underlyingWantTokenAmount() public override view returns (uint256) {
        return IGauge(GAUGE).balanceOf(address(this));
    }

   function _trySwapUnderlyingRewardToRewardToken() internal override {
        for (uint256 i = 0; i < UNDERLYING_REWARD_TOKENS.length; ++i) {
            address underlyingRewardToken = UNDERLYING_REWARD_TOKENS[i];
            uint256 underlyingRewardTokenAmount = underlyingRewardTokensAmount[underlyingRewardToken];
            // get current reward token amount
            uint256 rewardTokenAmountBefore = IERC20(underlyingRewardToken).balanceOf(address(this));

            // if token amount too small, wait for save gas fee
            if (underlyingRewardTokenAmount < underlyingRewardTokensSwapThreshold[underlyingRewardToken]) return;

             // send platform fee to PLATFORM_TREASURE
            uint256 platformFeeAmount = underlyingRewardTokenAmount.mul(platformFeeRate).div(10000);
            IERC20(underlyingRewardToken).safeTransfer(GrowRegister.get.PlatformTreasureAddress(), platformFeeAmount);

            // charge PerformanceFee
            uint256 performanceFeeAmount = underlyingRewardTokenAmount.mul(performanceFeeRate).div(10000);
            _chargePerformanceFee(underlyingRewardToken, performanceFeeAmount);

            // reinvest
            _reinvest(underlyingRewardToken, underlyingRewardTokenAmount.sub(performanceFeeAmount).sub(platformFeeAmount));

            uint256 underlyingRewardAmountAfter = IERC20(underlyingRewardToken).balanceOf(address(this));
            // set underlyingRewardTokensAmount
            underlyingRewardTokensAmount[underlyingRewardToken] = underlyingRewardTokenAmount.sub(rewardTokenAmountBefore.sub(underlyingRewardAmountAfter));
        }
    }

    function _reinvest(address tokenAddress, uint256 tokenAmount) internal {
        // swap token to USDC
        approveToken(tokenAddress, GrowRegister.get.ZapAddress(), tokenAmount);

        address[] memory tokens = new address[](2);
        tokens[0] = tokenAddress;
        tokens[1] = USDC_TOKEN;
        uint256 usdcTokenAmount = IZAP(GrowRegister.get.ZapAddress()).swap(tokens, tokenAmount, address(this), 0);

        // swap USDC to stakingToken

        uint256 tokenIndex = CurveAdapter(CURVE_ADAPTER).getTokenIndexFromOriginalTokens(STAKING_TOKEN, USDC_TOKEN);
        require(tokenIndex < type(uint256).max, "not originToken");

        approveToken(USDC_TOKEN, CURVE_ADAPTER, usdcTokenAmount);

        uint256 stakingTokenAmount = CurveAdapter(CURVE_ADAPTER).deposit(STAKING_TOKEN, USDC_TOKEN, usdcTokenAmount, 0);

        // deposit to underlying
        uint256 wantTokenAdded = _depositUnderlying(stakingTokenAmount);

        emit LogReinvest(wantTokenAdded);
    }

    // --------------------------------------------------------------
    // User Write Interface
    // --------------------------------------------------------------

    function _withdrawAs(uint256 wantTokenAmount, address tokenAddress, uint minReceive) override virtual internal {
        _getRewards(msg.sender);
        uint256 withdrawnWantTokenAmount = _withdraw(wantTokenAmount);

        if (tokenAddress == STAKING_TOKEN) {
            IERC20(tokenAddress).safeTransfer(msg.sender, withdrawnWantTokenAmount);
            return;
        }

        uint256 tokenIndex = CurveAdapter(CURVE_ADAPTER).getTokenIndexFromOriginalTokens(STAKING_TOKEN, tokenAddress);
        approveToken(STAKING_TOKEN, CURVE_ADAPTER, withdrawnWantTokenAmount);

        if (tokenIndex < type(uint256).max) {
            // get OriginToken and transfer
            uint256 tokenAmount = CurveAdapter(CURVE_ADAPTER).withdraw(STAKING_TOKEN, withdrawnWantTokenAmount, tokenAddress, minReceive);
            IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        } else {
            // covert to USDC and zap out
            uint256 tokenAmount = CurveAdapter(CURVE_ADAPTER).withdraw(STAKING_TOKEN, withdrawnWantTokenAmount, USDC_TOKEN, 0);
            approveToken(USDC_TOKEN, GrowRegister.get.ZapAddress(), tokenAmount);
            IZAP(GrowRegister.get.ZapAddress()).zapOut(USDC_TOKEN, tokenAddress, tokenAmount, msg.sender, minReceive);
        }
    }

    function depositToByOriginToken(address originTokenAddress, uint256 originTokenAmount, address userAddress, uint minReceive) external onlyRole(CONTROLLER_ROLE) {
        _getRewards(userAddress);

        uint256 tokenIndex = CurveAdapter(CURVE_ADAPTER).getTokenIndexFromOriginalTokens(STAKING_TOKEN, originTokenAddress);
        require(tokenIndex < type(uint256).max, "not originToken");

        IERC20(originTokenAddress).safeTransferFrom(msg.sender, address(this), originTokenAmount);
        approveToken(originTokenAddress, CURVE_ADAPTER, originTokenAmount);

        uint256 wantTokenAmount = CurveAdapter(CURVE_ADAPTER).deposit(STAKING_TOKEN, originTokenAddress, originTokenAmount, minReceive);

        _deposit(wantTokenAmount, userAddress);
    }

    // --------------------------------------------------------------
    // Interactive with under contract
    // --------------------------------------------------------------

    
    function _depositUnderlying(uint256 amount) internal override updateUnderlyingRewardTokensAmount(amount) returns (uint256) {
        uint256 underlyingWantTokenAmountBefore = _underlyingWantTokenAmount();

        approveToken(STAKING_TOKEN, GAUGE, amount);
        IGauge(GAUGE).deposit(amount);

        return _underlyingWantTokenAmount().sub(underlyingWantTokenAmountBefore);
    }

    // user _withdrawUnderlying MUST after _harvest
    function _withdrawUnderlying(uint256 amount) internal override returns (uint256) {
        uint256 _before = IERC20(STAKING_TOKEN).balanceOf(address(this));

        IGauge(GAUGE).withdraw(amount);

        return IERC20(STAKING_TOKEN).balanceOf(address(this)).sub(_before);
    }

    function _wantTokenPriceIn1e6USDC(uint256 amount) public view override returns (uint256) {
        return CurveAdapter(CURVE_ADAPTER)._wantTokenPriceIn1e6USDC(STAKING_TOKEN, amount);
    }

    function _receiveToken(address sender, uint256 amount) internal override {
        IERC20(STAKING_TOKEN).safeTransferFrom(sender, address(this), amount);
    }

    function _sendToken(address receiver, uint256 amount) internal override {
        IERC20(STAKING_TOKEN).safeTransfer(receiver, amount);
    }

    function _harvestFromUnderlying() internal updateUnderlyingRewardTokensAmount(0) {
        IGauge(GAUGE).claim_rewards();
    }

    function _harvest(bool harvestFromUnderlying, bool swapUnderlyingReward) internal override {
        // update remainingRewardTokenAmount & lastRewardBlock
        updateReward();

        // harvest underlying
        if (harvestFromUnderlying || swapUnderlyingReward) {
            _harvestFromUnderlying();
        }

        // if underlying reward token: AUTO over threshold then swap to reward token: grow
        if (swapUnderlyingReward) {
            _trySwapUnderlyingRewardToRewardToken();
        }
    }

    // --------------------------------------------------------------
    // Modifier
    // --------------------------------------------------------------

    modifier updateUnderlyingRewardTokensAmount(uint256 depositAmount) {
        uint256[] memory underlyingRewardTokensAmountBefore = new uint256[](UNDERLYING_REWARD_TOKENS.length);
        for (uint256 i = 0; i < UNDERLYING_REWARD_TOKENS.length; ++i) {
            underlyingRewardTokensAmountBefore[i] = IERC20(UNDERLYING_REWARD_TOKENS[i]).balanceOf(address(this));
            // if UNDERLYING_REWARD_TOKEN == STAKING_TOKEN, underlyingRewardAmountBefore has include amount
            if (UNDERLYING_REWARD_TOKENS[i] == STAKING_TOKEN) {
                underlyingRewardTokensAmountBefore[i] = underlyingRewardTokensAmountBefore[i].sub(depositAmount);
            }
        }

        _;

        for (uint256 i = 0; i < UNDERLYING_REWARD_TOKENS.length; ++i) {
            uint256 underlyingRewardAmountAfter = IERC20(UNDERLYING_REWARD_TOKENS[i]).balanceOf(address(this));
            underlyingRewardTokensAmount[UNDERLYING_REWARD_TOKENS[i]] += underlyingRewardAmountAfter.sub(underlyingRewardTokensAmountBefore[i]);
        }
    }

    // --------------------------------------------------------------
    // !! Emergency !!
    // --------------------------------------------------------------

    function emergencyExit() external override onlyRole(CONFIGURATOR_ROLE) {
        uint256 underlyingWantTokenAmount = _underlyingWantTokenAmount();
        IGauge(GAUGE).withdraw(underlyingWantTokenAmount);
        IS_EMERGENCY_MODE = true;
    }

    function emergencyWithdraw() external override onlyEmergency nonReentrant {
        uint256 shares = userShares[msg.sender];

        _notifyUserSharesUpdate(msg.sender, 0, false);
        userShares[msg.sender] = 0;

        // withdraw from under contract
        uint256 currentBalance = IERC20(STAKING_TOKEN).balanceOf(address(this));
        uint256 amount = currentBalance.mul(shares).div(totalShares);
        totalShares = totalShares.sub(shares);

        _getGrowRewards(msg.sender);
        IERC20(STAKING_TOKEN).safeTransfer(msg.sender, amount);
    }

}