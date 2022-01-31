/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.5.0 https://hardhat.org

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

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// License: MIT

pragma solidity ^0.8.0;

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
    function getTokenIndexFromOriginalTokens(address token) external view returns (uint256);
    function getTokenAmountOut(address token, uint256 amount) external view returns (uint256);
    function getOriginTokenAmountOut(address token, uint256 amount) external view returns (uint256);

    function depositToByOriginToken(address originTokenAddress, uint256 originTokenAmount, address userAddress, uint minReceive) external;
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

// File @openzeppelin/contracts/utils/[email protected]

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File @openzeppelin/contracts/utils/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// File @openzeppelin/contracts/utils/introspection/[email protected]

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
interface IERC165 {
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

// File @openzeppelin/contracts/utils/introspection/[email protected]

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File @openzeppelin/contracts/access/[email protected]

// License: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// File contracts/grow/GrowToken.sol

// License: MIT
pragma solidity 0.8.6;

contract GrowToken is ERC20, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address admin) ERC20("Ploygon GROW Token", "PLOW") {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn() external {
        _burn(address(this), balanceOf(address(this)));
    }

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

// File contracts/grow/GrowRewarder.sol

// License: MIT
pragma solidity 0.8.6;

interface IUniv2RouterLike {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata, address to, uint256 deadline) external;
}

contract GrowRewarder is IGrowUpgradeableImplementation, IGrowRewarder, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for GrowToken;

    bytes32 override public constant CONTRACT_IDENTIFIER = keccak256("GrowRewarder");

    uint256 public constant _DECIMAL = 1e18;
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    // --------------------------------------------------------------
    // Struct
    // --------------------------------------------------------------

    struct UserInfo {
        // block reward
        uint256 blockRewardDebt;

        // deposit reward
        uint256 lockedRewards;
        uint256 lockedRewardsUnlockedAt;

        // pending
        uint256 pendingRewards;
    }

    struct StrategyInfo {
        uint256 id;
        bool isActive;
        bool isVault;
        uint256 lockedRewardLockedTime;

        // block reward
        uint256 blockRewardAllocPoint;
        uint256 blockRewardLastRewardTimestamp;
        uint256 blockRewardAccGrowPerShare;

        // deposit reward
        uint256 depositRewardMultiplier;
        uint256 depositRewardMembershipMultiplier;
    }

    // --------------------------------------------------------------
    // State variables
    // --------------------------------------------------------------

    /// @notice Address of GROW Token Contract
    GrowToken public GROW;

    /// @dev grow STAKING_POOL
    address public _DEPRECATED_1_;

    /// @notice Address of each strategy
    address[] public strategyAddresses;

    /// @notice Info of each strategy
    mapping(address => StrategyInfo) public strategies;

    /// @notice Info of each user
    mapping(address => mapping (address => UserInfo)) public strategyUsers;

    /// @dev grow membership controller
    address public _DEPRECATED_2_;

    /// @notice reward start block
    uint256 public blockRewardStartTimestamp;

    /// @notice grow reward per block
    uint256 public blockRewardGrowPerSecond;

    /// @notice total alloc point of all vaults
    uint256 public blockRewardTotalAllocPoint;

    /// @dev profitReward for contribution rate in base point (100 == 1%), should be 5000 == 50%
    uint256 public profitRewardForContributionRate;

    // --------------------------------------------------------------
    // State variables upgrade
    // --------------------------------------------------------------

    // --------------------------------------------------------------
    // Initialize
    // --------------------------------------------------------------

    function initialize(GrowToken tokenAddress) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONFIGURATOR_ROLE, msg.sender);

        GROW = tokenAddress;
    }

    // --------------------------------------------------------------
    // Misc
    // --------------------------------------------------------------

    modifier onlyActiveStrategy() {
        require(strategies[msg.sender].isActive, "GR: not active strategy");
        _;
    }

    modifier onlyVault() {
        require(strategies[msg.sender].isVault, "GR: not vault");
        _;
    }

    function mintForReward(uint256 amount) private {
        if (amount <= 0) return; // nothing happened

        GROW.mint(address(this), amount);

        uint256 amountForDev = amount.mul(15).div(100);
        GROW.mint(GrowRegister.get.PlatformTreasureAddress(), amountForDev);

        emit LogGrowMint(address(this), amount, amountForDev);
    }

    // --------------------------------------------------------------
    // utils
    // --------------------------------------------------------------

    function approveToken(address token, address to, uint256 amount) private {
        if (IERC20(token).allowance(address(this), to) < amount) {
            IERC20(token).safeApprove(to, 0);
            IERC20(token).safeApprove(to, type(uint256).max);
        }
    }

    // --------------------------------------------------------------
    // User interface
    // --------------------------------------------------------------

    function getRewardsFromPools(address[] memory poolAddresses) external {
        uint256 length = poolAddresses.length;
        uint256 rewardAmount;
        for (uint256 index = 0; index < length; ++index) {
            rewardAmount = rewardAmount + settleAndGetRewards(poolAddresses[index], msg.sender, false);
        }
        address stakingPool = GrowRegister.get.GrowStakingPoolAddress();
        approveToken(address(GROW), stakingPool, rewardAmount);
        IGrowStakingPool(stakingPool).depositTo(rewardAmount, msg.sender);
    }

    // --------------------------------------------------------------
    // Membership
    // --------------------------------------------------------------

    function hasMembership(address userAddress) public view returns (bool) {
        if (address(0) == GrowRegister.get.GrowMembershipPoolAddress()) return false;
        return IGrowMembershipController(GrowRegister.get.GrowMembershipPoolAddress()).hasMembership(userAddress);
    }

    // --------------------------------------------------------------
    // Strategy Manage
    // --------------------------------------------------------------

    function addStrategy(
        address strategyAddress,
        bool isActive,
        bool isVault,
        uint256 lockedRewardLockedTime,
        uint256 blockRewardAllocPoint,
        uint256 depositRewardMultiplier,
        uint256 depositRewardMembershipMultiplier
    ) external onlyRole(CONFIGURATOR_ROLE) {
        require(strategies[strategyAddress].id == 0, "GR: strategy_exist");

        uint256 lastRewardTimestamp = block.timestamp > blockRewardStartTimestamp ? block.timestamp : blockRewardStartTimestamp;

        StrategyInfo storage strategy = strategies[strategyAddress];

        strategy.isActive = isActive;
        strategy.isVault = isVault;
        strategy.lockedRewardLockedTime = lockedRewardLockedTime;

        strategy.blockRewardLastRewardTimestamp = lastRewardTimestamp;
        strategy.blockRewardAllocPoint = blockRewardAllocPoint;
        blockRewardTotalAllocPoint = blockRewardTotalAllocPoint.add(blockRewardAllocPoint);

        strategy.depositRewardMultiplier = depositRewardMultiplier;
        strategy.depositRewardMembershipMultiplier = depositRewardMembershipMultiplier;

        strategyAddresses.push(strategyAddress);
        strategy.id = strategyAddresses.length;
    }

    function updateStrategy(
        address strategyAddress,
        bool isActive,
        uint256 lockedRewardLockedTime,
        uint256 blockRewardAllocPoint,
        uint256 depositRewardMultiplier,
        uint256 depositRewardMembershipMultiplier
    ) external onlyRole(CONFIGURATOR_ROLE) {
        require(strategies[strategyAddress].id != 0, "GR: strategy_not_found");

        StrategyInfo storage strategy = strategies[strategyAddress];

        strategy.isActive = isActive;
        strategy.lockedRewardLockedTime = lockedRewardLockedTime;

        strategy.blockRewardAllocPoint = blockRewardAllocPoint;
        blockRewardTotalAllocPoint = blockRewardTotalAllocPoint.sub(strategy.blockRewardAllocPoint).add(blockRewardAllocPoint);

        strategy.depositRewardMultiplier = depositRewardMultiplier;
        strategy.depositRewardMembershipMultiplier = depositRewardMembershipMultiplier;
    }

    function strategiesLength() external view returns(uint256) {
        return strategyAddresses.length;
    }

    // --------------------------------------------------------------
    // Reward Utils
    // --------------------------------------------------------------

    function addLockedRewards(address strategyAddress, address userAddress, uint256 amount) private {
        UserInfo storage user = strategyUsers[strategyAddress][userAddress];
        user.lockedRewards = user.lockedRewards.add(amount);
        user.lockedRewardsUnlockedAt = block.timestamp + strategies[strategyAddress].lockedRewardLockedTime;
    }

    function checkNeedResetLockedRewards(address strategyAddress, address userAddress) private {
        UserInfo storage user = strategyUsers[strategyAddress][userAddress];
        if (user.lockedRewards > 0 && user.lockedRewardsUnlockedAt > block.timestamp) {
            user.lockedRewards = 0;
            user.lockedRewardsUnlockedAt = 0;
        }
    }

    function unlockLockedRewards(address strategyAddress, address userAddress, bool unlockInEmegency) private {
        UserInfo storage user = strategyUsers[strategyAddress][userAddress];
        if (user.lockedRewards > 0 && (user.lockedRewardsUnlockedAt < block.timestamp || unlockInEmegency)) {
            uint256 amount = user.lockedRewards;
            user.pendingRewards = user.pendingRewards.add(user.lockedRewards);
            user.lockedRewards = 0;
            user.lockedRewardsUnlockedAt = 0;
            mintForReward(amount);
        }
    }

    function addPendingRewards(address strategyAddress, address userAddress, uint256 amount) private {
        UserInfo storage user = strategyUsers[strategyAddress][userAddress];
        user.pendingRewards = user.pendingRewards.add(amount);
    }

    // function transferPendingGrow(address strategyAddress, address userAddress) private {
    //     // 1. reset pending rewards
    //     UserInfo storage user = strategyUsers[strategyAddress][userAddress];
    //     uint256 rewardPending = user.pendingRewards;
    //     user.pendingRewards = 0;

    //     // 2. transfer
    //     GROW.safeTransfer(userAddress, rewardPending);
    // }

    // --------------------------------------------------------------
    // Block Reward (MasterChef-Like)
    // --------------------------------------------------------------

    function blockRewardUpdateGrowPerSecond(uint256 amount) external onlyRole(CONFIGURATOR_ROLE) {
        blockRewardGrowPerSecond = amount;
    }

    function blockRewardUpdateStartTimestamp(uint256 timestamp) external onlyRole(CONFIGURATOR_ROLE) {
        blockRewardStartTimestamp = timestamp;
    }

    function blockRewardUpdateRewards(address strategyAddress) private {
        if (strategies[strategyAddress].isVault) return;

        uint256 allocPoint = strategies[strategyAddress].blockRewardAllocPoint;
        uint256 lastRewardTimestamp = strategies[strategyAddress].blockRewardLastRewardTimestamp;
        uint256 accGrowPerShare = strategies[strategyAddress].blockRewardAccGrowPerShare;

        if (block.timestamp <= lastRewardTimestamp) return;

        uint256 totalShares = IGrowStrategy(strategyAddress).totalShares();

        if (totalShares == 0 || blockRewardTotalAllocPoint == 0 || blockRewardGrowPerSecond == 0) {
            strategies[strategyAddress].blockRewardLastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 multiplier = block.timestamp.sub(lastRewardTimestamp);

        uint256 growReward = multiplier
            .mul(blockRewardGrowPerSecond)
            .mul(allocPoint)
            .div(blockRewardTotalAllocPoint);

        strategies[strategyAddress].blockRewardLastRewardTimestamp = block.timestamp;

        if (growReward > 0) {
            mintForReward(growReward);

            // = accGrowPerShare + (growReward × REWARD_DECIMAL / totalSupply)
            strategies[strategyAddress].blockRewardAccGrowPerShare = accGrowPerShare.add(
                growReward
                    .mul(_DECIMAL)
                    .div(totalShares)
            );
        }
    }

    function calculatePendingBlockRewards(address strategyAddress, address userAddress) internal view returns (uint256) {
        uint256 userShares = IGrowStrategy(strategyAddress).sharesOf(userAddress);
        uint256 totalShares = IGrowStrategy(strategyAddress).totalShares();

        UserInfo storage user = strategyUsers[strategyAddress][userAddress];
        StrategyInfo storage strategy = strategies[strategyAddress];

        if (!strategy.isVault && totalShares > 0 && blockRewardTotalAllocPoint > 0 && blockRewardGrowPerSecond > 0) {
            uint256 blockRewardGrow = block.timestamp.sub(strategy.blockRewardLastRewardTimestamp).mul(blockRewardGrowPerSecond);
            uint256 totalGrowReward = blockRewardGrow.mul(strategy.blockRewardAllocPoint).div(blockRewardTotalAllocPoint);
            uint256 accGrowRewardPerShare = strategy.blockRewardAccGrowPerShare.add(totalGrowReward.mul(_DECIMAL).div(totalShares));
            if (userShares > 0) {
                return userShares.mul(accGrowRewardPerShare).div(_DECIMAL).sub(user.blockRewardDebt);
            }
        }

        return 0;
    }

    // --------------------------------------------------------------
    // Deposit Reward (Directly set by strategy with timelock)
    // --------------------------------------------------------------

    function depositRewardAddReward(address userAddress, uint256 amountIn1e6USDC) override external onlyActiveStrategy {
        if (amountIn1e6USDC <= 0) return; // nothing happened
        address strategyAddress = msg.sender;

        uint256 multiplier = strategies[strategyAddress].depositRewardMultiplier;
        uint256 membershipMultiplier = strategies[strategyAddress].depositRewardMembershipMultiplier;

        if (hasMembership(userAddress)) multiplier = membershipMultiplier;
        if (multiplier <= 0) return; // nothing happened

        uint256 amount = amountIn1e6USDC.mul(multiplier).div(1e6);
        addLockedRewards(strategyAddress, userAddress, amount);
        emit LogAddLockedRewards(strategyAddress, userAddress, amount, amountIn1e6USDC);
    }

    // --------------------------------------------------------------
    // Profit Reward (reward GROW for profits contribution)
    // --------------------------------------------------------------

    /// @dev update profitRewardForContributionRate
    function updateProfitRewardForContributionRate(uint256 _profitRewardForContributionRate) external onlyRole(CONFIGURATOR_ROLE) {
        profitRewardForContributionRate = _profitRewardForContributionRate;
    }

    function profitRewardByContribution(uint256 profitGrowAmount) override external onlyActiveStrategy {
        if (profitGrowAmount <= 0) return; // nothing happened
        address strategyAddress = msg.sender;

        uint256 profitRewardForContributionGrowAmount = profitGrowAmount.mul(profitRewardForContributionRate).div(10000);

        // 1. add profitRewardForContributionGrowAmount to pendingRewards
        mintForReward(profitRewardForContributionGrowAmount);

        // 2. add to strategy
        approveToken(address(GROW), strategyAddress, profitRewardForContributionGrowAmount);
        IGrowRewardReceiver(strategyAddress).addReward(profitRewardForContributionGrowAmount);
    }

    // --------------------------------------------------------------
    // Reward Manage
    // --------------------------------------------------------------

    function settleAndGetRewards(address strategyAddress, address userAddress, bool sendToUser) private returns (uint256 rewardPending) {
        // 1. settlement current rewards
        settleRewards(strategyAddress, userAddress);
        // 2.reset pending rewards
        UserInfo storage user = strategyUsers[strategyAddress][userAddress];
        rewardPending = user.pendingRewards;
        user.pendingRewards = 0;
        // 3. transfer if need
        if (sendToUser && rewardPending > 0) {
            GROW.safeTransfer(userAddress, rewardPending);
        }

        emit LogGetRewards(strategyAddress, userAddress, rewardPending);
    }

    function settleRewards(address strategyAddress, address userAddress) private {
        uint256 currentUserShares = IGrowStrategy(strategyAddress).sharesOf(userAddress);

        UserInfo storage user = strategyUsers[strategyAddress][userAddress];

        if (!strategies[strategyAddress].isVault) {
            // 1. update reward data
            blockRewardUpdateRewards(strategyAddress);

            uint256 accGrowPerShare = strategies[strategyAddress].blockRewardAccGrowPerShare;
            uint256 blockRewardDebt = user.blockRewardDebt;

            // reward by shares (Block reward)
            if (currentUserShares > 0) {
                // Block reward
                uint256 pendingBlockReward = currentUserShares
                    .mul(accGrowPerShare)
                    .div(_DECIMAL)
                    .sub(blockRewardDebt);

                user.blockRewardDebt =
                    currentUserShares
                        .mul(accGrowPerShare)
                        .div(_DECIMAL);

                addPendingRewards(strategyAddress, userAddress, pendingBlockReward);
                emit LogAddPendingRewards(strategyAddress, userAddress, pendingBlockReward);
            }
        }

        // deposit reward
        unlockLockedRewards(strategyAddress, userAddress, false);

        emit LogSettleRewards(strategyAddress, userAddress, user.pendingRewards);
    }

    // --------------------------------------------------------------
    // Reward Manage Interface
    // --------------------------------------------------------------

    function calculatePendingRewards(address strategyAddress, address userAddress) override external view returns (uint256) {
        UserInfo storage user = strategyUsers[strategyAddress][userAddress];
        StrategyInfo storage strategy = strategies[strategyAddress];

        uint256 pendingRewards = user.pendingRewards;
        if (!strategy.isVault && strategy.blockRewardLastRewardTimestamp < block.timestamp && strategy.blockRewardAllocPoint > 0) {
            pendingRewards = pendingRewards.add(calculatePendingBlockRewards(strategyAddress, userAddress));
        }
        return pendingRewards;
    }

    function calculatePendingVaultRewards(address strategyAddress) override external view returns (uint256) {
        StrategyInfo storage strategy = strategies[strategyAddress];
        if (!strategy.isVault) return 0;

        uint256 allocPoint = strategy.blockRewardAllocPoint;
        uint256 lastRewardTimestamp = strategy.blockRewardLastRewardTimestamp;

        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp <= lastRewardTimestamp || blockRewardTotalAllocPoint == 0 || blockRewardGrowPerSecond == 0) return 0;

        uint256 multiplier = currentTimestamp.sub(lastRewardTimestamp);

        uint256 growReward = multiplier
            .mul(blockRewardGrowPerSecond)
            .mul(allocPoint)
            .div(blockRewardTotalAllocPoint);

        return growReward;
    }

    function getRewards(address userAddress) override external onlyActiveStrategy {
        settleAndGetRewards(msg.sender, userAddress, true);
    }

    function getVaultReward() override external onlyActiveStrategy onlyVault {
        address vaultAddress = msg.sender;

        uint256 allocPoint = strategies[vaultAddress].blockRewardAllocPoint;
        uint256 lastRewardTimestamp = strategies[vaultAddress].blockRewardLastRewardTimestamp;

        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp <= lastRewardTimestamp) return;

        if (blockRewardTotalAllocPoint == 0 || blockRewardGrowPerSecond == 0) {
            strategies[vaultAddress].blockRewardLastRewardTimestamp = currentTimestamp;
            return;
        }

        uint256 multiplier = currentTimestamp.sub(lastRewardTimestamp);

        uint256 growReward = multiplier
            .mul(blockRewardGrowPerSecond)
            .mul(allocPoint)
            .div(blockRewardTotalAllocPoint);

        strategies[vaultAddress].blockRewardLastRewardTimestamp = currentTimestamp;

        if (growReward > 0) {
            mintForReward(growReward);
            GROW.safeTransfer(vaultAddress, growReward);
        }
    }

    // --------------------------------------------------------------
    // Share manage
    // --------------------------------------------------------------

    function notifyUserSharesUpdate(address userAddress, uint256 sharesUpdateTo, bool isWithdraw) override external onlyActiveStrategy {
        address strategyAddress = msg.sender;

        // 0. if strategyAddress is EMERGENCY_MODE
        if (IGrowStrategy(strategyAddress).IS_EMERGENCY_MODE()) {
            unlockLockedRewards(strategyAddress, userAddress, true);
        }

        // 1. check if need revert deposit reward
        if (isWithdraw) {
            checkNeedResetLockedRewards(strategyAddress, userAddress);
        }

        // 2. settlement current rewards
        settleRewards(strategyAddress, userAddress);

        if (!strategies[strategyAddress].isVault) {
            // 3. reset reward debt base on current shares
            strategyUsers[strategyAddress][userAddress].blockRewardDebt =
                sharesUpdateTo
                    .mul(strategies[strategyAddress].blockRewardAccGrowPerShare)
                    .div(_DECIMAL);
        }

        emit LogSharesUpdate(strategyAddress, userAddress, sharesUpdateTo);
    }

    // --------------------------------------------------------------
    // User Write Interface
    // --------------------------------------------------------------

    function getSelfRewards(address strategyAddress) external nonReentrant {
        settleAndGetRewards(strategyAddress, msg.sender, true);
    }

    // --------------------------------------------------------------
    // Events
    // --------------------------------------------------------------

    event LogGrowMint(address to, uint256 amount, uint256 forDevAmount);
    event LogSharesUpdate(address strategyAddress, address user, uint256 shares);
    event LogSettleRewards(address strategyAddress, address user, uint256 amount);
    event LogGetRewards(address strategyAddress, address user, uint256 amount);
    event LogAddLockedRewards(address strategyAddress, address user, uint256 amount, uint256 amountInNativeToken);
    event LogAddPendingRewards(address strategyAddress, address user, uint256 amount);

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

// File contracts/utils/Zap.sol

// License: MIT
pragma solidity 0.8.6;

interface IWETH {
    function deposit() external payable;
}

interface IWNativeRelayer {
    function withdraw(uint256 _amount, address _to) external;
}

interface ICurveStrategy {
    function CURVE_ADAPTER() external view returns(address);
}

contract Zap is IZAP, Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IGrowUpgradeableImplementation {
    using SafeERC20 for IERC20;

    bytes32 override public constant CONTRACT_IDENTIFIER = keccak256("Zap");

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    address public constant WRAPPED_NATIVE_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // Wrapped Matic (WMATIC)
    address public constant USDC_TOKEN = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant wNativeRelayer = 0x1a285c7b4BD4A665dbE37A08a09C1ed5F3537317;

    struct TokenPairInfo {
        // ROUTER
        address ROUTER;

        // swap path
        address[] path;
    }

    /// @notice Info of each TokenPair
    mapping(uint => TokenPairInfo) public pairRouter;

    /// @notice accepted token, value is token ROUTER or token address
    mapping(address => address) public tokenRouter;

    function initialize() external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONFIGURATOR_ROLE, msg.sender);
    }

    // --------------------------------------------------------------
    // ROUTER Manage
    // --------------------------------------------------------------

    function updatePairRouter(address ROUTER, address[] calldata path) external onlyRole(CONFIGURATOR_ROLE) {
        uint pairKey = uint(uint160(path[0])) + uint(uint160(path[path.length - 1]));
        TokenPairInfo storage pairInfo = pairRouter[pairKey];

        pairInfo.ROUTER = ROUTER;
        pairInfo.path = path;
    }

    function updateTokenRouter(address token, address ROUTER) external onlyRole(CONFIGURATOR_ROLE) {
        tokenRouter[token] = ROUTER;
    }

    // --------------------------------------------------------------
    // Misc
    // --------------------------------------------------------------

    function approveToken(address token, address to, uint amount) internal {
        if (IERC20(token).allowance(address(this), to) < amount) {
            IERC20(token).safeApprove(to, 0);
            IERC20(token).safeApprove(to, amount);
        }
    }

    modifier receiveToken(address token, uint amount) {
        if (token == WRAPPED_NATIVE_TOKEN) {
            if (msg.value != 0) {
                require(amount == msg.value, "value != msg.value");
                IWETH(WRAPPED_NATIVE_TOKEN).deposit{value: msg.value}();
            } else {
                IERC20(WRAPPED_NATIVE_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
            }
        } else {
            require(msg.value == 0, "Not MATIC");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
        _;
    }

    modifier onlyHumanOrWhitelisted {
        require(tx.origin == msg.sender || IGrowWhitelist(GrowRegister.get.GrowWhitelistAddress()).isWhitelist(msg.sender), "Whitelist: caller is not on the whitelist");
        _;
    }

    /// @dev Fallback function to accept ETH.
    receive() external payable {}

    // --------------------------------------------------------------
    // User Write Interface
    // --------------------------------------------------------------

    function zapAndDepositTo(address fromToken, uint amount, address poolAddress, uint minReceive) external payable onlyHumanOrWhitelisted receiveToken(fromToken, amount) {
        GrowRewarder rewarder = GrowRewarder(GrowRegister.get.GrowRewarderAddress());
        (,bool activeStrategy,,,,,,,) = rewarder.strategies(poolAddress);

        require(activeStrategy, "poolAddress invalid");

        address wantToken = fromToken;
        uint wantTokenAmount = amount;

        if (
            IGrowUpgradeableImplementation(poolAddress).CONTRACT_IDENTIFIER() == keccak256("GrowStrategySwampCurveV3")
        ) {
            address pairToken = IGrowStrategy(poolAddress).STAKING_TOKEN();
            address curveAdapter = ICurveStrategy(poolAddress).CURVE_ADAPTER();
            // if fromToken not in ORIGINAL_TOKENS
            if (CurveAdapter(curveAdapter).getTokenIndexFromOriginalTokens(pairToken, fromToken) == type(uint256).max) {
                // USDC must in OriginalTokens
                require(CurveAdapter(curveAdapter).getTokenIndexFromOriginalTokens(pairToken, USDC_TOKEN) < type(uint256).max, "pool invalid");
                wantToken = USDC_TOKEN;
                wantTokenAmount = _swap(fromToken, USDC_TOKEN, amount, address(this));
            }
            approveToken(wantToken, poolAddress, wantTokenAmount);
            IGrowStrategyCurve(poolAddress).depositToByOriginToken(wantToken, wantTokenAmount, msg.sender, minReceive);
        } else {
            wantToken = IGrowStrategy(poolAddress).STAKING_TOKEN();

            if (fromToken != wantToken) {
                require(tokenRouter[fromToken] == fromToken , "fromToken invalid");
                require(tokenRouter[wantToken] != address(0) , "wantToken invalid");

                if (tokenRouter[wantToken] == wantToken) {
                    // wantToken is normal token
                    wantTokenAmount = _swap(fromToken, wantToken, amount, address(this), minReceive);
                } else {
                    // wantToken is lp token
                    wantTokenAmount = _zapTokenToLP(fromToken, amount, wantToken, address(this), minReceive);
                }
            }

            approveToken(wantToken, poolAddress, wantTokenAmount);
            IGrowStrategy(poolAddress).depositTo(wantTokenAmount, msg.sender);
        }
    }

    function zapOut(address fromToken, address toToken, uint amount, address receiver, uint minReceive) override external payable receiveToken(fromToken, amount) {
        require(tokenRouter[fromToken] != address(0) , "fromToken invalid");

        bool withdarwAsNative = toToken == address(0);
        if (withdarwAsNative) toToken = WRAPPED_NATIVE_TOKEN;

        uint toTokenBefore = IERC20(toToken).balanceOf(address(this));
        uint toTokenAmount = 0;

        if (fromToken != toToken) {
            require(tokenRouter[toToken] == toToken, "toToken invalid");
            if (tokenRouter[fromToken] == fromToken) {
                // fromToken is normal token
                _swap(fromToken, toToken, amount, address(this), minReceive);
            } else {
                // fromToken is lp token
                _zapOutLpToToken(fromToken, amount, toToken, address(this), minReceive);
            }
            toTokenAmount = IERC20(toToken).balanceOf(address(this)) - toTokenBefore;
        } else {
            toTokenAmount = amount;
        }

        if (withdarwAsNative) {
            IERC20(toToken).safeApprove(wNativeRelayer, toTokenAmount);
            IWNativeRelayer(wNativeRelayer).withdraw(toTokenAmount, receiver);
        } else {
            IERC20(toToken).safeTransfer(receiver, toTokenAmount);
        }
    }

    // --------------------------------------------------------------
    // User View Interface
    // --------------------------------------------------------------

    function getZapAmountOut(address fromToken, uint amount, address poolAddress) external view returns (uint wantTokenAmount) {
        GrowRewarder rewarder = GrowRewarder(GrowRegister.get.GrowRewarderAddress());
        (,bool activeStrategy,,,,,,,) = rewarder.strategies(poolAddress);

        require(activeStrategy, "poolAddress invalid");

        wantTokenAmount = amount;

        if (IGrowUpgradeableImplementation(poolAddress).CONTRACT_IDENTIFIER() == keccak256("GrowStrategyAutoCurveV3") ) {
            address originToken = fromToken;
            uint256 originTokenAmount = amount;
            // if fromToken not in ORIGINAL_TOKENS
            if (IGrowStrategyCurve(poolAddress).getTokenIndexFromOriginalTokens(fromToken) == type(uint256).max) {
                // USDC must in OriginalTokens
                require(IGrowStrategyCurve(poolAddress).getTokenIndexFromOriginalTokens(USDC_TOKEN) < type(uint256).max, "pool invalid");
                originToken = USDC_TOKEN;
                originTokenAmount = _getSwapAmountOut(fromToken, USDC_TOKEN, amount);
            }
            wantTokenAmount = IGrowStrategyCurve(poolAddress).getTokenAmountOut(originToken, originTokenAmount);
        } else if (IGrowUpgradeableImplementation(poolAddress).CONTRACT_IDENTIFIER() == keccak256("GrowStrategySwampCurveV3")) {
            address pairToken = IGrowStrategy(poolAddress).STAKING_TOKEN();
            address curveAdapter = ICurveStrategy(poolAddress).CURVE_ADAPTER();
            address originToken = fromToken;
            uint256 originTokenAmount = amount;
            // if fromToken not in ORIGINAL_TOKENS
            if (CurveAdapter(curveAdapter).getTokenIndexFromOriginalTokens(pairToken, fromToken) == type(uint256).max) {
                // USDC must in OriginalTokens
                require(CurveAdapter(curveAdapter).getTokenIndexFromOriginalTokens(pairToken, USDC_TOKEN) < type(uint256).max, "pool invalid");
                originToken = USDC_TOKEN;
                originTokenAmount = _getSwapAmountOut(fromToken, USDC_TOKEN, amount);
            }
            wantTokenAmount = CurveAdapter(curveAdapter).getTokenAmountOut(pairToken, originToken, originTokenAmount);
        } else {
            address wantToken = IGrowStrategy(poolAddress).STAKING_TOKEN();
            if (fromToken != wantToken) {
                require(tokenRouter[fromToken] == fromToken , "fromToken invalid");
                require(tokenRouter[wantToken] != address(0) , "wantToken invalid");

                if (tokenRouter[wantToken] == wantToken) {
                    // wantToken is normal token
                    wantTokenAmount = _getSwapAmountOut(fromToken, wantToken, amount);
                } else {
                    // wantToken is lp token
                    wantTokenAmount = _getZapLpAmountOut(fromToken, amount, wantToken);
                }
            }
        }
        return wantTokenAmount;
    }

    function getZapOutAmountOut(address wantToken, uint amount, address poolAddress) external view returns (uint wantTokenAmount) {
        GrowRewarder rewarder = GrowRewarder(GrowRegister.get.GrowRewarderAddress());
        (,bool activeStrategy,,,,,,,) = rewarder.strategies(poolAddress);

        require(activeStrategy, "poolAddress invalid");

        wantTokenAmount = amount;

        if (IGrowUpgradeableImplementation(poolAddress).CONTRACT_IDENTIFIER() == keccak256("GrowStrategyAutoCurveV3") ) {
            // see GrowStrategyAutoCurveV3._withdrawAs(...)
            if (IGrowStrategyCurve(poolAddress).getTokenIndexFromOriginalTokens(wantToken) < type(uint256).max) {
                wantTokenAmount = IGrowStrategyCurve(poolAddress).getOriginTokenAmountOut(wantToken, amount);
            } else {
                uint256 usdcTokenAmount = IGrowStrategyCurve(poolAddress).getOriginTokenAmountOut(USDC_TOKEN, amount);
                wantTokenAmount = _getSwapAmountOut(USDC_TOKEN, wantToken, usdcTokenAmount);
            }
        } else if (IGrowUpgradeableImplementation(poolAddress).CONTRACT_IDENTIFIER() == keccak256("GrowStrategySwampCurveV3")) {
            address pairToken = IGrowStrategy(poolAddress).STAKING_TOKEN();
            address curveAdapter = ICurveStrategy(poolAddress).CURVE_ADAPTER();
            if (CurveAdapter(curveAdapter).getTokenIndexFromOriginalTokens(pairToken, wantToken) < type(uint256).max) {
                wantTokenAmount = CurveAdapter(curveAdapter).getOriginTokenAmountOut(pairToken, wantToken, amount);
            } else {
                uint256 usdcTokenAmount = CurveAdapter(curveAdapter).getOriginTokenAmountOut(pairToken, USDC_TOKEN, amount);
                wantTokenAmount = _getSwapAmountOut(USDC_TOKEN, wantToken, usdcTokenAmount);
            }
        } else {
            address fromToken = IGrowStrategy(poolAddress).STAKING_TOKEN();
            if (fromToken != wantToken) {
                require(tokenRouter[fromToken] != address(0) , "fromToken invalid");
                if (tokenRouter[fromToken] == fromToken) {
                    // fromToken is normal token
                    wantTokenAmount = _getSwapAmountOut(fromToken, wantToken, amount);
                } else {
                    // fromToken is lp token
                    IUniv2LikePair pair = IUniv2LikePair(fromToken);
                    address token0 = pair.token0();
                    address token1 = pair.token1();
                    (uint amount0, uint amount1) = _getBurnLiquidityAmountOut(fromToken, amount);
                    uint wantTokenAmount0 = _getSwapAmountOut(token0, wantToken, amount0);
                    uint wantTokenAmount1 = _getSwapAmountOut(token1, wantToken, amount1);
                    wantTokenAmount = wantTokenAmount0 + wantTokenAmount1;
                }
            }
        }
    }

    // --------------------------------------------------------------
    // Utils for contract
    // --------------------------------------------------------------

    function swap(address fromToken, address wantToken, uint amount, address receiver) external payable receiveToken(fromToken, amount) returns (uint) {
        require(tokenRouter[fromToken] == fromToken, "fromToken invalid");

        return _swap(fromToken, wantToken, amount, receiver);
    }

    function swap(address fromToken, address wantToken, uint amount, address receiver, uint minTokenReceive) external payable receiveToken(fromToken, amount) returns (uint) {
        require(tokenRouter[fromToken] == fromToken, "fromToken invalid");

        return _swap(fromToken, wantToken, amount, receiver, minTokenReceive);
    }

    function swap(address[] memory tokens, uint amount, address receiver, uint minTokenReceive) override external payable receiveToken(tokens[0], amount) returns (uint) {
        uint len = tokens.length;
        uint swapAmount = amount;
        for (uint i = 0; i < len - 1; ++i) {
            uint amountBefore = IERC20(tokens[i + 1]).balanceOf(address(this));

            if (tokenRouter[tokens[i]] == tokens[i]) {
                // fromToken is normal token
                _swap(tokens[i], tokens[i + 1], swapAmount, address(this));
            } else {
                // fromToken is lp token
                _zapOutLpToToken(tokens[i], swapAmount, tokens[i + 1], address(this), 0);
            }

            swapAmount = IERC20(tokens[i + 1]).balanceOf(address(this)) - amountBefore;
        }
        require(swapAmount >= minTokenReceive);
        IERC20(tokens[len - 1]).safeTransfer(receiver, swapAmount);

        return swapAmount;
    }

    function zapTokenToLP(address fromToken, uint amount, address lpToken, address receiver) override external payable receiveToken(fromToken, amount) returns (uint) {
        require(tokenRouter[fromToken] == fromToken, "fromToken invalid");

        return _zapTokenToLP(fromToken, amount, lpToken, receiver);
    }

    function zapTokenToLP(address fromToken, uint amount, address lpToken, address receiver, uint minLPReceive) override external payable receiveToken(fromToken, amount) returns (uint) {
        require(tokenRouter[fromToken] == fromToken, "fromToken invalid");

        return _zapTokenToLP(fromToken, amount, lpToken, receiver, minLPReceive);
    }

    function tokenPriceIn1e6USDC(address fromToken) external view returns(uint) {
        return tokenPriceIn1e6USDC(fromToken, 10 ** IERC20Metadata(fromToken).decimals());
    }

    function tokenPriceIn1e6USDC(address fromToken, uint amount) public view returns(uint) {
        require(tokenRouter[fromToken] == fromToken, "fromToken invalid");

        (address router, address[] memory path) = getRouterAndPath(fromToken, USDC_TOKEN);

        uint[] memory amounts = IUniv2LikeRouter01(router).getAmountsOut(amount, path);

        return amounts[amounts.length - 1];
    }

    // --------------------------------------------------------------
    // Internal
    // --------------------------------------------------------------

    function getRouterAndPath(address fromToken, address toToken) private view returns (address router, address[] memory path) {
        uint pairKey = uint(uint160(fromToken)) + uint(uint160(toToken));
        TokenPairInfo storage pairInfo = pairRouter[pairKey];

        require(pairInfo.ROUTER != address(0), "router not set");

        router = pairInfo.ROUTER;

        path = new address[](pairInfo.path.length);
        if (pairInfo.path[0] == fromToken) {
            path = pairInfo.path;
        } else {
            for (uint index = 0; index < pairInfo.path.length; index++) {
                path[index] = (pairInfo.path[pairInfo.path.length - 1 - index]);
            }
        }
    }

    function _swap(address fromToken, address wantToken, uint amount, address receiver) private returns (uint) {
        return _swap(fromToken, wantToken, amount, receiver, 0);
    }

    function _swap(address fromToken, address wantToken, uint amount, address receiver, uint minTokenReceive) private returns (uint) {
        if (fromToken == wantToken) {
            if (receiver !=  address(this)) {
                IERC20(wantToken).transfer(receiver, amount);
            }
            return amount;
        }

        (address router, address[] memory path) = getRouterAndPath(fromToken, wantToken);

        approveToken(fromToken, router, amount);
        uint wantTokenAmountBefore = IERC20(wantToken).balanceOf(address(this));
        IUniv2LikeRouter02(router).swapExactTokensForTokens(amount, minTokenReceive, path, receiver, block.timestamp);
        uint wantTokenAmountAfter = IERC20(wantToken).balanceOf(address(this));

        require(wantTokenAmountAfter - wantTokenAmountBefore >= minTokenReceive, "out of range");

        return wantTokenAmountAfter - wantTokenAmountBefore;
    }

    function _getSwapAmountOut(address fromToken, address wantToken, uint amount) private view returns (uint) {
        if (fromToken == wantToken) {
            return amount;
        }
        (address router, address[] memory path) = getRouterAndPath(fromToken, wantToken);

        uint[] memory amounts =  IUniv2LikeRouter02(router).getAmountsOut(amount, path);
        return amounts[amounts.length - 1];
    }

    function _zapTokenToLP(address fromToken, uint amount, address lpToken, address receiver) private returns (uint liquidity) {
        return _zapTokenToLP(fromToken, amount, lpToken, receiver, 0);
    }

    function _zapTokenToLP(address fromToken, uint amount, address lpToken, address receiver, uint minLPReceive) private returns (uint liquidity) {
        require(tokenRouter[fromToken] == fromToken, "fromToken invalid");

        IUniv2LikePair pair = IUniv2LikePair(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();

        uint lpTokenAmountBefore = IERC20(lpToken).balanceOf(address(this));

        // swap fromToken to token0 & token1
        uint token0Amount = _swap(fromToken, token0, amount / 2, address(this));
        uint token1Amount = _swap(fromToken, token1, amount / 2, address(this));

        approveToken(token0, tokenRouter[lpToken], token0Amount);
        approveToken(token1, tokenRouter[lpToken], token1Amount);

        (,,liquidity) = IUniv2LikeRouter02(tokenRouter[lpToken]).addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, address(this), block.timestamp);

        liquidity = IERC20(lpToken).balanceOf(address(this)) - lpTokenAmountBefore;

        require(liquidity >= minLPReceive, "out of range");

        uint token0AmountDust = IERC20(token0).balanceOf(address(this));
        uint token1AmountDust = IERC20(token1).balanceOf(address(this));

        // send rest token back to user
        if (token0AmountDust > 0) IERC20(token0).safeTransfer(msg.sender, token0AmountDust);
        if (token1AmountDust > 0) IERC20(token1).safeTransfer(msg.sender, token1AmountDust);

        if (receiver != address(this)) {
            IERC20(lpToken).safeTransfer(receiver, liquidity);
        }
    }

    function _getZapLpAmountOut(address fromToken, uint amount, address lpToken) private view returns (uint liquidity) {
        require(tokenRouter[fromToken] == fromToken, "fromToken invalid");

        IUniv2LikePair pair = IUniv2LikePair(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();

        uint amount0 = _getSwapAmountOut(fromToken, token0, amount / 2);
        uint amount1 = _getSwapAmountOut(fromToken, token1, amount / 2);
        liquidity = _getMintLiquidityAmountOut(amount0, amount1, lpToken);
    }

    function _getMintLiquidityAmountOut(uint amount0, uint amount1, address lpToken) private view returns (uint liquidity) {
        uint _totalSupply = IUniv2LikePair(lpToken).totalSupply();
        (uint112 _reserve0, uint112 _reserve1,) = IUniv2LikePair(lpToken).getReserves();

        liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
    }

    function _getBurnLiquidityAmountOut(address lpToken, uint liquidity) private view returns (uint amount0, uint amount1) {
        IUniv2LikePair pair = IUniv2LikePair(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();

        uint balance0 = IERC20(token0).balanceOf(lpToken);
        uint balance1 = IERC20(token1).balanceOf(lpToken);

        uint _totalSupply = IUniv2LikePair(lpToken).totalSupply();
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
    }

    function _zapOutLpToToken(address lpToken, uint amount, address toToken, address receiver, uint minReceive) private {
        IUniv2LikePair pair = IUniv2LikePair(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();

        approveToken(lpToken, tokenRouter[lpToken], amount);

        (uint amount0, uint amount1) = IUniv2LikeRouter02(tokenRouter[lpToken]).removeLiquidity(token0, token1, amount, 0, 0, address(this), block.timestamp);

        uint toTokenAmount0 = _swap(token0, toToken, amount0, address(this));
        uint toTokenAmount1 = _swap(token1, toToken, amount1, address(this));

        require(toTokenAmount0 + toTokenAmount1 >= minReceive, "out of range");
        if (receiver != address(this)) {
            IERC20(toToken).safeTransfer(receiver, toTokenAmount0 + toTokenAmount1);
        }
    }
}