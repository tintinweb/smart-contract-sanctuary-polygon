// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/**
 * @title The main interface to calculate all formulas related to Invoice
 * @author Polytrade.Finance
 * @dev Collection of all functions related to Invoice formulas
 */
interface IFormulas {
    /**
     * @dev Calculate the advanced amount: (amount * Advance Ratio)
     * @return uint Advanced Amount
     * @param _amount, uint input from user
     * @param _advanceFeePercentage, uint input from user
     */
    function advanceAmountCalculation(
        uint _amount,
        uint _advanceFeePercentage
    ) external pure returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "dual-layer-token/contracts/DLT/interface/IDLT.sol";

interface IInvoice is IDLT {
    /**
     * @title A new struct to define the metadata structure
     * @dev Defining a new type of struct called Metadata to store the asset metadata
     * @param lateFeePercentage, is a uint24 will have 2 decimals
     * @param gracePeriod, is a uint16 will have 2 decimals
     * @param dueDate, is a uint48 will have 2 decimals
     * @param invoiceDate, is a uint48 will have 2 decimals
     * @param fundsAdvancedDate, is a uint48 will have 2 decimals
     * @param invoiceAmount, is a uint will have 2 decimals
     */
    struct InitialMainMetadata {
        uint24 lateFeePercentage; // %
        uint16 gracePeriod; // days
        uint48 dueDate;
        uint48 invoiceDate;
        uint48 fundsAdvancedDate;
        uint256 invoiceAmount;
    }

    /**
     * @title A new struct to define the sub metadata structure
     * @dev Defining a new type of struct called Metadata to store the asset metadata
     * @param factoringFeePercentage, is a uint24 will have 2 decimals
     * @param discountFeePercentage, is a uint24 will have 2 decimals
     * @param bankChargesFeeAmount, is a uint24 will have 2 decimals
     * @param additionalFeeAmount, is a uint24 will have 2 decimals
     * @param advanceFeePercentage, is a uint16 will have 2 decimals
     */
    struct InitialSubMetadata {
        uint24 discountFeePercentage; // %
        uint24 factoringFeePercentage; // %
        uint24 additionalFeeAmount; // it's an amount
        uint24 bankChargesFeeAmount; // it's an amount
        uint16 advanceFeePercentage; // % advance ratio
    }

    /**
     * @dev Emitted when `newURI` is set to the Invoice category instead of `oldURI` by `mainId`
     * @param oldInvoiceBaseURI, Old Base URI for the Invoice category
     * @param newInvoiceBaseURI, New Base URI for the Invoice category
     */
    event InvoiceBaseURISet(string oldInvoiceBaseURI, string newInvoiceBaseURI);

    /**
     * @dev Emitted when `assetNumber` token with `metadata` is minted from the `creator` to the `owner`
     * @param creator, Address of the contract that minted
     * @param owner, Address of the receiver of this token
     * @param mainId, mainId of the newly minted token
     */
    event InvoiceCreated(
        address indexed creator,
        address indexed owner,
        uint indexed mainId
    );

    /**
     * @dev Calculate the advanced amount
     * @return uint Advanced Amount
     * @param mainId, Unique uint Invoice Number
     * @param subId, Unique subId
     */
    function calculateAdvanceAmount(
        uint mainId,
        uint subId,
        uint amount
    ) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "dual-layer-token/contracts/DLT/DLT.sol";
import "./interface/IInvoice.sol";
import "../Formulas/interface/IFormulas.sol";

contract Invoice is IInvoice, DLT, AccessControl {
    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IFormulas private _formulas;
    string private _invoiceBaseURI = "https://ipfs.io/ipfs";

    /**
     * @dev Mapping will be indexing the InitialMainMetadata for each Invoice category by its mainId
     */
    mapping(uint => InitialMainMetadata) private _mainMetadata;

    /**
     * @dev Mapping will be indexing the InitialSubMetadata for each Invoice category by its mainId and subId
     */
    mapping(uint => mapping(uint => InitialSubMetadata)) private _subMetadata;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        address formulas_
    ) DLT(name, symbol) {
        _setBaseURI(baseURI_);

        // TODO: create setter
        _formulas = IFormulas(formulas_);

        // Grant the minter role to a specified account
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function createInvoice(
        address owner,
        uint256 mainId,
        InitialMainMetadata calldata initialMainMetadata,
        InitialSubMetadata calldata initialSubMetadata
    ) external onlyRole(MINTER_ROLE) {
        require(mainTotalSupply(mainId) == 0, "Invoice: Already minted");
        _mainMetadata[mainId] = initialMainMetadata;
        _subMetadata[mainId][1] = initialSubMetadata;

        _mint(owner, mainId, 1, initialMainMetadata.invoiceAmount);

        emit InvoiceCreated(msg.sender, owner, mainId);
    }

    /**
     * @dev Implementation of a setter for the asset base URI
     * @param newBaseURI, String of the asset base URI
     */
    function setBaseURI(
        string calldata newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI);
    }

    /**
     * @dev Calculate the advanced amount
     * @return uint Advance Amount
     * @param mainId, Unique uint Invoice Number
     */
    function calculateAdvanceAmount(
        uint mainId,
        uint subId,
        uint amount
    ) external view returns (uint) {
        InitialSubMetadata memory initialSubMetadata = _subMetadata[mainId][
            subId
        ];

        return
            _formulas.advanceAmountCalculation(
                amount,
                initialSubMetadata.advanceFeePercentage
            );
    }

    /**
     * @dev Implementation of a getter for mainId URI
     * @return string URI for the invoice
     * @param mainId, Unique uint Invoice Number
     */
    function tokenURI(uint mainId) public view virtual returns (string memory) {
        string memory stringInvoiceNumber = Strings.toString(mainId);

        return string.concat(_invoiceBaseURI, stringInvoiceNumber);
    }

    /**
     * @dev Implementation of a setter for the asset base URI
     * @param newBaseURI, String of the asset base URI
     */
    function _setBaseURI(string memory newBaseURI) private {
        string memory oldBaseURI = _invoiceBaseURI;
        _invoiceBaseURI = newBaseURI;
        emit InvoiceBaseURISet(oldBaseURI, newBaseURI);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IDLT } from "./interface/IDLT.sol";
import { IDLTReceiver } from "./interface/IDLTReceiver.sol";

contract DLT is IDLT {
    using Address for address;

    string private _name;
    string private _symbol;

    // Count
    uint256 private _totalMainIds;
    mapping(uint256 => uint256) private _totalSubIds;

    // Supply
    uint256 private _totalSupply;
    mapping(uint256 => uint256) private _mainTotalSupply;
    mapping(uint256 => mapping(uint256 => uint256)) private _subTotalSupply;

    // Balances
    mapping(uint256 => mapping(address => Balance)) private _balances;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => uint256))))
        private _allowances;

    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
    }

    function approve(
        address spender,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) public returns (bool) {
        address owner = msg.sender;
        require(spender != owner, "DLT: approval to current owner");
        _approve(owner, spender, mainId, subId, amount);
        return true;
    }

    /**
     * @dev See {DLT-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IDLT-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least `amount`.
     */
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) public returns (bool) {
        _safeTransferFrom(sender, recipient, mainId, subId, amount, "");
        return true;
    }

    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) public returns (bool) {
        _safeTransferFrom(sender, recipient, mainId, subId, amount, data);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) public returns (bool) {
        _safeTransferFrom(sender, recipient, mainId, subId, amount, "");
        return true;
    }

    function totalMainIds() public view returns (uint256) {
        return _totalMainIds;
    }

    function mainBalanceOf(
        address account,
        uint256 mainId
    ) public view returns (uint256) {
        return _balances[mainId][account].mainBalance;
    }

    function subBalanceOf(
        address account,
        uint256 mainId,
        uint256 subId
    ) public view returns (uint256) {
        return _balances[mainId][account].subBalances[subId];
    }

    function allowance(
        address owner,
        address spender,
        uint256 mainId,
        uint256 subId
    ) public view returns (uint256) {
        return _allowance(owner, spender, mainId, subId);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mainTotalSupply(uint256 mainId) public view returns (uint256) {
        return _mainTotalSupply[mainId];
    }

    function subTotalSupply(
        uint256 mainId,
        uint256 subId
    ) public view returns (uint256) {
        return _subTotalSupply[mainId][subId];
    }

    function totalSubIds(uint256 mainId) public view returns (uint256) {
        return _totalSubIds[mainId];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Safely mints `amount` in specific `subId` in specific `mainId` and transfers it to `recipient`.
     *
     * Requirements:
     *
     * - If `recipient` refers to a smart contract, it must implement {IDLTReceiver-onDLTReceived},
     *   which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        _safeMint(recipient, mainId, subId, amount, "");
    }

    /**
     * @dev Same as [`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IDLTReceiver-onDLTReceived} to contract recipients.
     */
    function _safeMint(
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(recipient, mainId, subId, amount);
        require(
            _checkOnDLTReceived(
                address(0),
                recipient,
                mainId,
                subId,
                amount,
                data
            ),
            "DLT: transfer to non DLTReceiver implementer"
        );
    }

    /**
     * @dev Safely transfers `amount` from `subId` in specific `mainId from `sender` to `recipient`,
     * checking first that contract recipients
     * are aware of the DLT standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `recipient`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `amount` sender can transfer at least his balance.
     * - If `recipient` refers to a smart contract, it must implement {IDLTReceiver-onDLTReceived},
     *    which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(sender, recipient, mainId, subId, amount);
        require(
            _checkOnDLTReceived(sender, recipient, mainId, subId, amount, data),
            "DLT: transfer to non DLTReceiver implementer"
        );
    }

    function _safeTransferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        address spender = msg.sender;

        if (!_isApprovedOrOwner(sender, spender)) {
            _spendAllowance(sender, spender, mainId, subId, amount);
        }

        _safeTransfer(sender, recipient, mainId, subId, amount, data);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = _allowance(owner, spender, mainId, subId);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "DLT: insufficient allowance");
            unchecked {
                _approve(
                    owner,
                    spender,
                    mainId,
                    subId,
                    currentAllowance - amount
                );
            }
        }
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
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "DLT: approve from the zero address");
        require(spender != address(0), "DLT: approve to the zero address");

        _allowances[owner][spender][mainId][subId] = amount;
        emit Approval(owner, spender, mainId, subId, amount);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "DLT: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "DLT: transfer from the zero address");
        require(recipient != address(0), "DLT: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, mainId, subId, amount, "");

        Balance storage senderBalance = _balances[mainId][sender];
        Balance storage recipientBalance = _balances[mainId][recipient];

        require(
            senderBalance.subBalances[subId] >= amount,
            "DLT: insufficient balance for transfer"
        );
        unchecked {
            senderBalance.mainBalance -= amount;
            senderBalance.subBalances[subId] -= amount;
        }

        recipientBalance.mainBalance += amount;
        recipientBalance.subBalances[subId] += amount;

        emit Transfer(sender, recipient, mainId, subId, amount);

        _afterTokenTransfer(sender, recipient, mainId, subId, amount, "");
    }

    /** @dev Creates `amount` tokens and assigns them to `account`
     *
     * Emits a {Transfer} event with `sender` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `amount` cannot be zero .
     */
    function _mint(
        address account,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "DLT: mint to the zero address");
        require(amount != 0, "DLT: mint zero amount");

        _beforeTokenTransfer(address(0), account, mainId, subId, amount, "");

        if (_subTotalSupply[mainId][subId] == 0) {
            ++_totalMainIds;
            ++_totalSubIds[mainId];
        }

        unchecked {
            _totalSupply += amount;
            _mainTotalSupply[mainId] += amount;
            _subTotalSupply[mainId][subId] += amount;

            _balances[mainId][account].mainBalance += amount;
            _balances[mainId][account].subBalances[subId] += amount;
        }

        emit Transfer(address(0), account, mainId, subId, amount);

        _afterTokenTransfer(address(0), account, mainId, subId, amount, "");
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
    function _burn(
        address account,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "DLT: burn from the zero address");
        require(amount != 0, "DLT: burn zero amount");

        uint256 fromBalanceSub = _balances[mainId][account].subBalances[subId];
        require(fromBalanceSub >= amount, "DLT: insufficient balance");

        _beforeTokenTransfer(account, address(0), mainId, subId, amount, "");

        unchecked {
            _totalSupply -= amount;
            _mainTotalSupply[mainId] -= amount;
            _subTotalSupply[mainId][subId] -= amount;

            _balances[mainId][account].mainBalance -= amount;
            _balances[mainId][account].subBalances[subId] -= amount;

            // Overflow not possible: amount <= fromBalanceMain <= totalSupply.
        }

        if (_subTotalSupply[mainId][subId] == 0) {
            --_totalMainIds;
            --_totalSubIds[mainId];
        }

        emit Transfer(account, address(0), mainId, subId, amount);

        _afterTokenTransfer(account, address(0), mainId, subId, amount, "");
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `sender` and `recipient` are both non-zero, `amount` of ``sender``'s tokens
     * will be transferred to `recipient`.
     * - when `sender` is zero, `amount` tokens will be minted for `recipient`.
     * - when `recipient` is zero, `amount` of ``sender``'s tokens will be burned.
     * - `sender` and `recipient` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `sender` and `recipient` are both non-zero, `amount` of ``sender``'s tokens
     * has been transferred to `recipient`.
     * - when `sender` is zero, `amount` tokens have been minted for `recipient`.
     * - when `recipient` is zero, `amount` of ``sender``'s tokens have been burned.
     * - `sender` and `recipient` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    function _allowance(
        address owner,
        address spender,
        uint256 mainId,
        uint256 subId
    ) internal view returns (uint256) {
        return _allowances[owner][spender][mainId][subId];
    }

    function _isApprovedOrOwner(
        address sender,
        address spender
    ) internal view virtual returns (bool) {
        return (sender == spender || isApprovedForAll(sender, spender));
    }

    /**
     * @dev Internal function to invoke {IDLTReceiver-onDLTReceived} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param sender address representing the previous owner of the given token ID
     * @param recipient target address that will receive the tokens
     * @param mainId target address that will receive the tokens
     * @param subId target address that will receive the tokens
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnDLTReceived(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes memory data
    ) private returns (bool) {
        if (recipient.isContract()) {
            try
                IDLTReceiver(recipient).onDLTReceived(
                    msg.sender,
                    sender,
                    mainId,
                    subId,
                    amount,
                    data
                )
            returns (bytes4 retval) {
                return retval == IDLTReceiver.onDLTReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("DLT: transfer to non DLTReceiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDLT {
    struct Balance {
        uint256 mainBalance;
        mapping(uint256 => uint256) subBalances;
    }

    /**
     * @dev Emitted when `subId` token is transferred from `sender` to `recipient`.
     */
    event Transfer(
        address indexed sender,
        address indexed recipient,
        uint256 indexed mainId,
        uint256 subId,
        uint256 amount
    );

    /**
     * @dev Emitted when `owner` enables `spender` to manage the `subId` token.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    );

    /**
     * @dev Emitted when `spender` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed spender,
        address indexed operator,
        bool approved
    );

    event URI(string oldValue, string newValue, uint256 indexed mainId);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any subId owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    function approve(
        address spender,
        uint256 mainId,
        uint256 subId,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the amount of whole tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns The total supply of all tokens of a given mainId.
     */
    function mainTotalSupply(uint256 mainId) external view returns (uint256);

    /**
     * @dev Returns The total supply of tokens with a given mainId and subId
     */
    function subTotalSupply(
        uint256 mainId,
        uint256 subId
    ) external view returns (uint256);

    /**
     * @dev Returns Total number of unique mainId value.
     */
    function totalMainIds() external view returns (uint256);

    /**
     * @dev Returns Total number of unique subId values that have been  given for a mainId.
     */
    function totalSubIds(uint256 mainId) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account` in mainId.
     */
    function mainBalanceOf(
        address account,
        uint256 mainId
    ) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account` in subId.
     */
    function subBalanceOf(
        address account,
        uint256 mainId,
        uint256 subId
    ) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender,
        uint256 mainId,
        uint256 subId
    ) external view returns (uint256);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title DLT token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from DLT asset contracts.
 */
interface IDLTReceiver {
    /**
     * @dev Whenever an {DLT} `subId` token is transferred to this contract via {IDLT-safeTransferFrom}
     * by `operator` from `sender`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient,
     *  the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IDLTReceiver.onDLTReceived.selector`.
     */
    function onDLTReceived(
        address operator,
        address from,
        uint256 mainId,
        uint256 subId,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}