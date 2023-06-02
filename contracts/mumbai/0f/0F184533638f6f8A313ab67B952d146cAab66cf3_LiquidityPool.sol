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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
   */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

interface IERC20General {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
   */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../storage/LiquidStorage.sol";
import "../storage/LiquidTypes.sol";
import "../storage/LiquidEvents.sol";
import "./interfaces/IERC20General.sol";
import "./SafeERC20.sol";

// import "../GMTManipulator.sol";
contract LiquidCalculate is
    Ownable,
    AccessControl,
    ReentrancyGuard,
    LiquidStorage
{
    using LiquidTypes for *;
    using LiquidEvents for *;
    using SafeMath for uint256;

    /**
     * @notice Function used by admin for initial deposit
     * @param _poolID The id of the pool to deposit to
     * @param _amountGMT The amount of GMT Tokens to deposit.
     * @param _amountLiquid The amount of liquid tokens to deposit
     * @dev This function is mainly used for testing purposes, as it does not invoke the transfer or transferFrom methods. It is useful for
     * @dev setting state of the Contract for testing calculations and rewards.
     */
    function adminDeposit(
        uint256 _poolID,
        uint256 _amountGMT,
        uint256 _amountLiquid
    ) internal {
        // Get pairs
        LiquidTypes.PoolPair storage pairs = LiquidStorage.poolPairs[_poolID];

        // Increment total gmt and LP and overall liquidity.
        pairs.totalGMT += _amountGMT;
        pairs.totalLiquidity += _amountGMT;
        pairs.totalLiquidityToken += _amountLiquid;
        pairs.totalLiquidity += _amountLiquid;
        depositPriceCalculate(_poolID);
    }

    /**
     * @notice Main user deposit method
     * @param _poolID The id of the pool to deposit to
     * @param _amountGMT The amount of tokens to deposit (Can be 0 as single token is supported)
     * @param _amountLiquid The amoun of tokens to deposit (Can be 0 as single token is supported)
     */

    function poolDeposit(
        uint256 _poolID,
        uint256 _amountGMT,
        uint256 _amountLiquid,
        uint256 _taxPercentage
    ) internal {
        // Get Pool pairs
        LiquidTypes.PoolPair storage pairs = LiquidStorage.poolPairs[_poolID];

        // Check if the amount attempting to deposit is greater than 0 and if the sender has balance
        if (_amountGMT > 0 && pairs.GMTToken.balanceOf(msg.sender) > 0) {
            // Increment total GMT
            // Increment total Liquidity
            pairs.totalGMT += _amountGMT;
            pairs.totalLiquidity += _amountGMT;
            taxAmount(_amountGMT, _taxPercentage, _poolID);
            // Calculate share of rewards for sender user.
            calculateUserRewardShare(_poolID, _amountGMT, true);
        }
        if (
            _amountLiquid > 0 && pairs.LiquidityToken.balanceOf(msg.sender) > 0
        ) {
            // Call transfer from for the LP token
            // Will stop execution if transfer doesn't go through, calculations do not happen.
            require(
                pairs.LiquidityToken.transferFrom(
                    msg.sender,
                    LiquidStorage.ownerAddress,
                    _amountLiquid
                ),
                "Failed transfering funds!"
            );
            taxAmount(_amountLiquid, _taxPercentage, _poolID);
            // Increment total LP Token amount
            // Increment total Liquidity for the pool
            pairs.totalLiquidityToken += _amountLiquid;
            pairs.totalLiquidity += _amountLiquid;

            // Start calculation process
            calculateUserRewardShare(_poolID, _amountLiquid, false);
        }
        depositPriceCalculate(_poolID);
    }

    /**
     * @notice Starts the setup and calculation process for calculating users rewards (Is called automatically on deposit, can be changed )
     * @param _poolID The id of the pool for which to start calculating rewards for
     * @param _amountContributed The amount of tokens user has contributed (Is called seperately for GMT and LP token)
     * @param _isGMT A boolean which decides whether logic for GMT or LP will be used (It is slightly different)
     */

    function calculateUserRewardShare(
        uint256 _poolID,
        uint256 _amountContributed,
        bool _isGMT
    ) internal {
        // Setup user storage
        LiquidTypes.UserInfo storage user = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];

        // Setup Pool pairs
        LiquidTypes.PoolPair storage pairs = LiquidStorage.poolPairs[_poolID];

        // Set the principal amount
        uint256 startAmount = _amountContributed;

        // A componding period must exists, I've set it as 12, as in compounds 12 times a year
        // This can be changed, can be anywhere from 1 to 365.

        // Calls the calculateAPY method
        uint256 apy = calculateAPY(startAmount, pairs.poolAPY, 12);

        // Increment useres reward Debt by the apy (If amount is 0, will receive 0 so no harms done)
        user.rewardDebt += apy;

        // Check for GMT
        if (_isGMT) {
            // Check users balance of GMT
            if (pairs.GMTToken.balanceOf(msg.sender) < _amountContributed) {
                // Increment gmt contributions of the sender user
                // Transfer method is called separately
                user.gmtContributed += _amountContributed;
            } else {
                revert("Insufficient GMT for transfer.");
            }
        } else {
            // Increment LP contributions of the sender user
            user.amount += _amountContributed;

            emit LiquidEvents.Deposit(msg.sender, _poolID, _amountContributed);
        }
    }

    /**
     * @notice Distributes rewards for the user, based on the pool ID
     * @param _poolID The id of the pool from which to distribute
     * @dev Does not go through all users, only for the callee, when user wishes to payout it will call it from their account
     */
    function distributeRewards(uint256 _poolID) internal {
        LiquidTypes.PoolPair storage pairs = LiquidStorage.poolPairs[_poolID];
        LiquidTypes.UserInfo storage users = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];

        // Check if user actually has any rewards
        if (users.rewardDebt < 1) revert("Insufficient rewards!");
        // Transfer from the LP to user
        pairs.LiquidityToken.transferFrom(
            LiquidStorage.ownerAddress,
            msg.sender,
            users.rewardDebt
        );

        // Check if user has GMTs Contributed and remove them (Another method is used for transfering GMTs)
        if (users.gmtContributed != 0) {
            users.gmtContributed -= users.gmtContributed;
        }
        emit LiquidEvents.Withdraw(msg.sender, _poolID, users.rewardDebt);
    }

    /**
     * @notice Calculates APY for the user, based on the percentage, time held and compounding period
     * @param _principalAmount Principal amount represents the users invested tokens.
     * @param _apy The percentage used for compounding
     * @param _compoundingPeriod The number of times the principal amount should be compounded
     * @return Compounded amount, returns both the principal amount whith the interest already applied.
     *
     * @dev If you only want to return the interest amount without principal attached, set `uint256 compoundInterest = 0`
     */
    function calculateAPY(
        uint256 _principalAmount,
        uint256 _apy,
        uint256 _compoundingPeriod
    ) internal pure returns (uint256) {
        uint256 timeInMonths = _compoundingPeriod;
        uint256 rateMultiplier = 10000; // Multiply rate by 10,000 to handle decimal places

        uint256 compoundInterest = _principalAmount;
        for (uint256 i = 0; i < timeInMonths; i++) {
            compoundInterest =
                (compoundInterest * (rateMultiplier + _apy)) /
                rateMultiplier;
        }

        return compoundInterest;
    }

    /**
     * @notice Used for setup of main storages and calling the calculation function
     * @param _poolID The id of pool for which to calculate daily rewards
     * @param _dailyLiquidity The total daily liquidity for today
     * @dev Also increments the users daily tokens reward.
     */
    function settleUserDailyRewards(
        uint256 _poolID,
        uint256 _dailyLiquidity
    ) internal {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        LiquidTypes.UserInfo storage user = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];

        uint256 amount = calculateTotalHeld(
            pair.totalLiquidity,
            user.amount,
            pair.dailyFeePercentage,
            _dailyLiquidity
        );
        user.dailyTokensReward += amount;
    }

    /**
     * @notice Calculates how much tokens users should receive based on their equitiy in the LP
     * @param _totalLiquidity The total liquidity of the pool, both GMT and LP token and sums them
     * @param _userAmountHeld The total amount of tokens user holds in the pool, both GMT and LP token
     * @param _dailyFee The daily percentage of tokens that is allocated as a reward pool from the daily liquidity
     * @param _dailyLiquidity The amount of tokens that was invested in the LP today
     * @dev The function calculates how much of tokens go to daily reward pool, and based on the users equity returns the rewards.
     * @dev E.G, user holds 10% of LP, and reward pool is 5000 tokens, user will receive 500 tokens as a reward.
     */
    function calculateTotalHeld(
        uint256 _totalLiquidity,
        uint256 _userAmountHeld,
        uint256 _dailyFee,
        uint256 _dailyLiquidity
    ) internal pure returns (uint256) {
        // Calculates the number of tokens which users will receive as rewards
        uint256 percentOfDailyRewards = (_dailyLiquidity * _dailyFee) / 100;

        // Calculates the percentage of LP that the user holds
        uint256 userPercentage = ((_userAmountHeld *
            LiquidStorage.ACC_REWARD_PRECISION) / _totalLiquidity);

        // Calculates how much tokens user is entitled to from the rewards pool.
        uint256 userClaimableRewards = ((userPercentage) *
            percentOfDailyRewards) / 100;

        return userClaimableRewards / LiquidStorage.ACC_REWARD_PRECISION;
    }

    /**
     * @notice Internal function used by the main LiquidityPool contract to set users lock time period
     * @param _poolID The id of the pool user is locking their funds to
     * @param _timePeriod The time period user is locking their funds for
     * @dev Used by the main contract, can be used to update anything.
     */
    function setUserDepositData(uint256 _poolID, uint256 _timePeriod) internal {
        LiquidTypes.UserInfo storage user = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];
        user.timePeriod = _timePeriod;
    }

    /**
     * @notice Calculates the tax rate based on the amount, can be called by either deposit or withdraw.
     * @param _amount The principal amount
     * @param _taxPercent The percentage of tax that is going from the amount
     * @param _poolID The id of the pool, used to transfer tokens only.
     */
    function taxAmount(
        uint256 _amount,
        uint256 _taxPercent,
        uint256 _poolID
    ) internal {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];

        uint256 taxedAmount = (_amount * _taxPercent) / 100;

        pair.LiquidityToken.transferFrom(
            msg.sender,
            LiquidStorage.rewardWallet,
            taxedAmount
        );
    }

    /**
     * @notice Calculates constant product market maker (n = x * y)
     * @param _token1Supply The total supply of first token
     * @param _token2Supply The total supply of second token
     * @param _poolID The id of the pool for which to return CPMM for
     */
    function calculateCPMM(
        uint256 _token1Supply,
        uint256 _token2Supply,
        uint256 _poolID
    ) internal {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];

        pair.constantProductMarketMaker = _token1Supply * _token2Supply;
    }

    /**
     * @notice Calculates token price on a regular deposit
     * @param _poolID The id of pool whos price gets updated
     * @dev This only calcuates price and sets it, doesn't update the supply as it gets updated in poolDeposit or Swaptokens or sellMethod who are the only callers.
     */
    function depositPriceCalculate(uint256 _poolID) internal {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        uint256 amountLeft = pair.totalGMT;
        uint256 amountRight = pair.totalLiquidityToken;

        uint256 priceLeft = pair.GMTPrice;
        uint256 priceRight = pair.liquidityTokenPrice;

        uint256 totalWorthLeft = (amountLeft * priceLeft) / 1e4;
        uint256 totalWorthRight = (amountRight * priceRight) / 1e4;

        uint256 priceDiffFactor = (((totalWorthRight *
            LiquidStorage.ACC_REWARD_PRECISION) / totalWorthLeft) *
            LiquidStorage.ACC_REWARD_PRECISION) /
            LiquidStorage.ACC_REWARD_PRECISION;
        uint256 priceRatio = (priceDiffFactor * priceLeft) / 1e4;
        pair.GMTPrice = priceRatio;
    }

    /**
     * @notice Swaps tokens, calculates price accodringly
     * @param _poolID The id of pool to calculate the prices for
     * @param _purchaseAmount The amount of tokens to purchase
     */
    function swapTokens(uint256 _poolID, uint256 _purchaseAmount) internal {
        LiquidTypes.UserInfo storage users = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        LiquidTypes.TaxInfo storage tax = LiquidStorage.taxWalletInfo[_poolID];

        // Slippage percent
        uint256 deductableToken2 = calculateSlippage(_poolID, _purchaseAmount);
        //

        if (_purchaseAmount > pair.totalGMT)
            revert("Insufficient funds in LP, please try again");

        uint256 taxAmount = calculateTaxPercent(_poolID, _purchaseAmount, true);
        // Tax based on purchase

        // Tax the deductable here (Removed the taxing temporarily, testing out calculations.)

        // How much tokens user is to pay (W/O taxes).
        uint256 deductableToken2New = calculatePayoutTokens(
            _poolID,
            _purchaseAmount
        );

        uint256 totalUserShareToPay = deductableToken2New + taxAmount;
        // Add GMT Transfer, can't for the life of me figure out why it will not allow transfer RN.

        // Transfer here before any state changes
        if (pair.LiquidityToken.balanceOf(msg.sender) < totalUserShareToPay)
            revert("Insufficient funds");

        pair.LiquidityToken.transferFrom(
            msg.sender,
            LiquidStorage.ownerAddress,
            totalUserShareToPay
        );
        users.amount += _purchaseAmount;
        tax.rewardWalletBalance += taxAmount;

        uint256 amountLeft = pair.totalGMT - _purchaseAmount;
        uint256 amountRight = pair.totalLiquidityToken + deductableToken2New;

        uint256 totalWorthLeft = (amountLeft * pair.GMTPrice) / 1e4;
        uint256 totalWorthRight = (amountRight * pair.liquidityTokenPrice) /
            1e4;
        uint256 priceDiffFactor = (((totalWorthRight *
            LiquidStorage.ACC_REWARD_PRECISION) / totalWorthLeft) *
            LiquidStorage.ACC_REWARD_PRECISION) /
            LiquidStorage.ACC_REWARD_PRECISION;
        uint256 priceRatio = (priceDiffFactor * pair.GMTPrice) / 1e4;
        pair.GMTPrice = priceRatio;
        pair.totalLiquidityToken += totalUserShareToPay;
        pair.totalGMT -= _purchaseAmount;
        depositPriceCalculate(_poolID);
    }

    /**
     * @notice Calculates what the possible price of token will be based on purchase / Sell amount
     * @param _poolID The id of pool where transaction is occuring at
     * @param _purchaseAmount The amount of purchasable / sellable token
     * @return The calculated amount representing the new token price
     */
    function getPossibleTokenPrice(
        uint256 _poolID,
        uint256 _purchaseAmount
    ) internal view returns (uint256) {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        uint256 deductableToken2 = calculateSlippage(_poolID, _purchaseAmount);

        uint256 amountLeft = pair.totalGMT - _purchaseAmount;
        uint256 amountRight = pair.totalLiquidityToken + deductableToken2;

        uint256 priceLeft = pair.GMTPrice;
        uint256 priceRight = pair.liquidityTokenPrice;

        uint256 totalWorthLeft = (amountLeft * priceLeft) / 1e4;
        uint256 totalWorthRight = (amountRight * priceRight) / 1e4;
        uint256 priceDiffFactor = (((totalWorthRight *
            LiquidStorage.ACC_REWARD_PRECISION) / totalWorthLeft) *
            LiquidStorage.ACC_REWARD_PRECISION) /
            LiquidStorage.ACC_REWARD_PRECISION;
        uint256 priceRatio = (priceDiffFactor * priceLeft) / 1e4;

        return priceRatio;
    }

    function sellTokens(
        uint256 _poolID,
        uint256 _sellAmount,
        bool _sellAll
    ) internal {
        LiquidTypes.UserInfo storage users = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        LiquidTypes.TaxInfo storage tax = LiquidStorage.taxWalletInfo[_poolID];
        if (_sellAll) {
            uint256 userBalance = pair.GMTToken.balanceOf(msg.sender);
            uint256 payoutAmount = calculatePayoutTokens(_poolID, userBalance);
            pair.totalGMT += _sellAmount;
            pair.totalLiquidityToken -= payoutAmount;
            depositPriceCalculate(_poolID);
            // CURRENTLY DOESN'T ALLOW GMT TO TRANSFER,IDK WHY
            // pair.GMTToken.transferFrom(msg.sender, LiquidStorage.ownerAddress, userBalance);
        } else {
            // Fetch user balance and compare to sell amount
            uint256 feeForWallet = returnImpactBasedFee(_poolID, _sellAmount);

            // Transfer fee first.

            // I am not adding impact based fee yet, until it is decided will it or will it not be added.
            // Impact fee can rack up huge costs for the users if they make a huge shift in the market, unsure whether it will be implemented
            // tax.rewardWalletBalance += feeForWallet;

            tax.rewardWalletBalance += calculateTaxPercent(
                _poolID,
                _sellAmount,
                false
            );
            uint256 payoutAmount = calculatePayoutTokens(_poolID, _sellAmount);

            // NOTE, WHEN TRANSFERING ADD FEE TO AMOUNT.
            // Transfer from user back to pool
            // Transfer USDT from pool back to user
            // Sell amount is how many GMTs one sells
            pair.totalGMT += _sellAmount;
            pair.totalLiquidityToken -= payoutAmount;
            depositPriceCalculate(_poolID);
        }
    }

    /**
     * @notice Calculates how many tokens user is eligble to receive based on the current price of tokens.
     * @param _poolID The id of the pool from which to payout tokens
     * @param _amount The amount of tokens user is swapping
     * @dev If they are purchasing GMT, use that price for convert,if they are selling use different logic
     * @dev If purchasing gmt, transfer USDT from user then transfer gmt from owner, when selling transfer GMT from user and usdt from owner
     * @return Tokens to payout
     */
    function calculatePayoutTokens(
        uint256 _poolID,
        uint256 _amount
    ) internal view returns (uint256) {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        uint256 priceOfGmt = pair.GMTPrice;
        uint256 userEligbleTokens;
        userEligbleTokens = (
            (_amount).mul(priceOfGmt).div(LiquidStorage.ACC_REWARD_PRECISION)
        );
        return userEligbleTokens;
    }

    // Slippage formula ( (Bid Price – Ask Price) / Quantity ) * 100
    /**
     * @notice Calculates slippage percente on a sell, used for giving user a fair price.
     * @param _poolID The id of pool where transaction is taking place
     * @param _amount The amount of tokens user is transacting.
     * @return The slippage amount (Not slippage percent, full amount.)
     */
    function calculateSlippage(
        uint256 _poolID,
        uint256 _amount
    ) internal view returns (uint256) {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];

        uint256 newTokenASupply = pair.totalGMT - _amount;

        uint256 newTokenBSupply = pair.totalLiquidityToken +
            (_amount * pair.GMTPrice) /
            pair.liquidityTokenPrice;

        return (newTokenBSupply * pair.liquidityTokenPrice) / newTokenASupply;
    }

    /**
     * @notice Returns impact based fee, when user is selling a huge amount of tokens, will calculate what that purchase will do to the market, and give them an updated price
     * @param _poolID The id of pool for which to calculate impact fee.
     * @param _amount The amount of tokens user is transacting
     * @return Impac fee (Not percent, actual deductable amount).
     */
    function returnImpactBasedFee(
        uint256 _poolID,
        uint256 _amount
    ) internal view returns (uint256) {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];

        uint256 priceDifference = 1 ether -
            (pair.GMTPrice.mul(LiquidStorage.ACC_REWARD_PRECISION) /
                getPossibleTokenPrice(_poolID, _amount));
        uint256 impactFee = (
            _amount.mul(priceDifference).div(LiquidStorage.ACC_REWARD_PRECISION)
        );
        return impactFee;
    }

    /**
     * @notice Calculates tax percent for a liquidty pool and a given amont
     * @param _poolID The id of pool where the transaction is occuring at
     * @param _amount The amount of tokens user is purchasing
     * @param _withdraw Boolean stating whether the transaciton is withdraw or deposit
     * @return Taxable amount which gets deducted
     */
    function calculateTaxPercent(
        uint256 _poolID,
        uint256 _amount,
        bool _withdraw
    ) internal returns (uint256) {
        LiquidTypes.TaxInfo storage taxPairs = LiquidStorage.taxWalletInfo[
            _poolID
        ];
        uint256 taxableAmount;
        if (_withdraw) {
            taxableAmount = (_amount.mul(taxPairs.withdrawTax).div(100));
            return taxableAmount;
        } else {
            taxableAmount = (_amount.mul(taxPairs.depositTax).div(100));
            return taxableAmount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IBEP20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
   * {IBEP20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
        token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
        address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IERC20General.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20General token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20General token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
    function safeApprove(
        IERC20General token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20General token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20General token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
        token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
    function _callOptionalReturn(IERC20General token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
        address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./storage/LiquidStorage.sol";
import "./storage/LiquidTypes.sol";
import "./storage/LiquidEvents.sol";
import "./libs/LiquidCalculate.sol";
import "./Tokens/GMT/IERC20.sol";
import "./libs/interfaces/IBEP20.sol";
import "./libs/SafeBEP20.sol";

/**
 * @title GMT | GMT DAO AG
 * @author Beyondi 
 * @dev GMT Liquidity Pool | Contract used as a Liquidity Pool implementation
 */

contract LiquidityPool is
    Ownable,
    AccessControl,
    ReentrancyGuard,
    LiquidStorage,
    LiquidCalculate
{
    using LiquidTypes for *;
    using LiquidEvents for *;
    // using LiquidCalculate for *;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    // Tax percentage, must be 0 because constants HAVE TO be initialized, on contract construct is changed.
    // The reason this is the only variable not set in the LiquidStorage is that due to the nature of immutable
    // Variables, they must be set at deployment time, and LiquidStorage deployes before LiquidityPool.
    uint256 public immutable taxPercentage; 
    
    
    /**
     * @notice Constructs the Liquidity portal
     * @param _gmtToken Instance of the Green Mining DAO Token
     * @param _rewardWallet Address of the wallet which will hold all rewards
     * @param _taxPercentage Percentage of taxes for transaction (For now will use one value for deposit and withdraw just for test purposes)
     */

    constructor(IERC20 _gmtToken, address _rewardWallet, uint256 _taxPercentage) {
        LiquidStorage.GMT = _gmtToken;
        _setupRole(OWNER, msg.sender);
        LiquidStorage.ownerAddress = msg.sender;
        LiquidStorage.rewardWallet = _rewardWallet;
        taxPercentage = _taxPercentage;
    }

    /**
     * @notice modifier which checks if sender has Whitelisted role
     */
    modifier onlyWhitelisted() {
        if (!hasRole(WHITELISTED, msg.sender)) {
            revert("Only whitelisted wallets can call this method!");
        }
        _;
    }
    /**
     * @notice modifier which checks if sender has Owner role
     */
    modifier onlyOwnerr() {
        if (!hasRole(OWNER, msg.sender)) {
            revert("Only owner can call this method!");
        }
        _;
    }

    /**
     * @notice Adds an account to Whitelisted role
     * @param wallet Account at which to give out Whitelisted role
     */
    function addWhitelist(address wallet) external onlyOwnerr() {
        _setupRole(WHITELISTED, wallet);
    }

    /**
     * @notice Returns the number of the Liquidity pools.
     */

    function poolLength() public view returns (uint256 pools) {
        pools = LiquidStorage.poolPairs.length;
    }

    /**
     * @notice Returns the instance of Green Mining DAO Token
     */
    function gmtInstance() public view returns (IERC20) {
        return LiquidStorage.GMT;
    }

    /**
     * @notice Creates a new pool
     * @param _allocationPointsLpToken Allocation points for the ratio of token1 x token2
     * @param _lpToken Instance of the IBEP20 Token used as a Contributing mechanism
     * @param _poolAPY Percentage by which to calculate the APY 
     * @param _dailyPercentageOfFees Percentage of total daily Liquidity which goes to reward pool.
     * @param _gmtPrice Starting price of 1 GMT Token (Will be recalculated later)
     * @param _liquidityPrice Starting price of 2nd token (Will be recalculated later if not stable.)
     * @dev The pool only takes in one token, the other is GMT by default, supplies are set to 0 and are later on set.  Can only be invoked by owner.
     */
    
    function addPool(
        uint256 _allocationPointsLpToken,
        IERC20 _lpToken,
        uint256 _poolAPY,
        uint256 _dailyPercentageOfFees,
        uint256 _gmtPrice,
        uint256 _liquidityPrice,
        uint256 _acceptedSlippagePercent
    ) external onlyOwnerr {
        // Check if token being added to pool is GMT
        if (address(_lpToken) == address(GMT)) revert("Can't add GMT and GMT");
        
        // Increment total allocation points
        LiquidStorage.totalRegularAllocPoint += _allocationPointsLpToken;
        
        // Create a new Pool 
        LiquidStorage.poolPairs.push(
            LiquidTypes.PoolPair({
                GMTToken: LiquidStorage.GMT,
                LiquidityToken: _lpToken,
                totalGMT: 0,
                totalLiquidityToken: 0,
                totalLiquidity: 0,
                poolAPY: _poolAPY,
                dailyFeePercentage: _dailyPercentageOfFees,
                constantProductMarketMaker: 0,
                GMTPrice: _gmtPrice,
                liquidityTokenPrice: _liquidityPrice,
                acceptedSlippagePercent: _acceptedSlippagePercent
            })
        );

        // Create a new allocation pool pair
        LiquidStorage.allocPairs.push(
            LiquidTypes.AllocationPointsPerPair({
                allocationPointGMT: 0,
                allocationPointLiquid: 0
            })
        );
        // Create a new tax pool for the LP
        LiquidStorage.taxWalletInfo.push(
            LiquidTypes.TaxInfo({
                depositTax: 0,
                withdrawTax: 0,
                rewardWalletBalance: 0,
                payoutWallet: ownerAddress
            })
        );

        // Emit an event for adding of pool
        emit LiquidEvents.AddPool(
            LiquidStorage.numberOfPools,
            _allocationPointsLpToken,
            _lpToken
        );

        // Increment the total number of pools. (Used for fact-checking) 
        LiquidStorage.numberOfPools += 1;
    }
    /**
     * @notice Changes default reward wallet for the pool, by default it sets owners wallet as reward.
     * @param _poolID The id of pool that reward wallet belongs to
     * @param _newWallet The address of the new wallet to set as a reward wallet
     */
    function changeRewardWallet(uint256 _poolID, address _newWallet) external onlyOwner {
        
        if(_newWallet == address(0)) revert ("Reward wallet can't be null address");

        LiquidTypes.TaxInfo storage taxInfo = LiquidStorage.taxWalletInfo[_poolID];

        taxInfo.payoutWallet = _newWallet;
    }
    /**
     * @notice Updates allocation point for a pool
     * 
     * @param _poolID The id of the pool that is being updated
     * @param _allocationPoints the number of allocation points to set to the token
     * @param _isGMT Boolean representing whether the updated token is GMT
     */
    function setAllocationPoints(
        uint256 _poolID,
        uint256 _allocationPoints,
        bool _isGMT
    ) external onlyOwnerr {
        // Get allocation pairs
        LiquidTypes.AllocationPointsPerPair memory alloc = LiquidStorage.allocPairs[_poolID];
        
        // Check if the token is GMT and set alloc points
        if (_isGMT) {
            alloc.allocationPointGMT = _allocationPoints;
        } else {
            alloc.allocationPointLiquid = _allocationPoints;
        }

        // Emit event
        emit LiquidEvents.SetPool(_poolID, _allocationPoints);
    }

    /**
    * @notice Used by admins to deposit to pool, does not calculate rewards. Used mainily for setting initial state.
    * @param _poolID The id of the pool that is being liquidated 
    * @param _amountGMT The amount of GMT tokens to invest into the pool (Can be 0)
    * @param _amountLiquid The amount of LP tokens to invest into the pool (Can be 0)
    * @dev Used mainly for testing purposes, but can be used by admins for lower costs, doesn't do extra calculations
     */
    function adminDeposits(
        uint256 _poolID,
        uint256 _amountGMT,
        uint256 _amountLiquid
    ) external onlyOwnerr nonReentrant {
        LiquidCalculate.adminDeposit(_poolID, _amountGMT, _amountLiquid);
    }

    /**
     * @notice Used by end users to deposit to the Liquidity pool, calculates rewards based on either APY, percent of LP Held or can be both
     * @param _poolID The Id of the Liquidity pool to invest in
     * @param _amountGMT The Amount of GMT tokens to Invest (Can be 0)
     * @param _amountLiquid The Amount of LP tokens to Invest (Can be 0)
     * @param _months The Amount of months to lock the funds for (Can NOT be 0) (Atleast 1)
     */
    function deposit(
        uint256 _poolID,
        uint256 _amountGMT,
        uint256 _amountLiquid,
        uint256 _months
    ) external onlyWhitelisted nonReentrant {
        // Call user deposit data update method
        LiquidCalculate.setUserDepositData(_poolID, _months);
        
        // Call the poolDeposit function
        LiquidCalculate.poolDeposit(_poolID, _amountGMT, _amountLiquid, taxPercentage);
    }

    /**
     * @notice Returns the rewards user is entitled to
     * @param _poolID the ID of the pool user is trying to see rewards from
     * @return The number of reward token user is entitled to
     */

    function getUserRewards(uint256 _poolID) external view returns (uint256) {
        LiquidTypes.UserInfo storage user = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];

        return user.rewardDebt;
    }

    /**
     * @notice Returns the number of users contributed GMT in a pool
     * @param _poolID the ID of the pools user is trying to see GMT tokens from
     * @return The number of GMT contributed
     */
    function getUserContributedGMT(
        uint256 _poolID
    ) external view returns (uint256) {
        LiquidTypes.UserInfo storage user = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];
        return user.gmtContributed;
    }

    /**
     * @notice Returns the number of users LP tokens in a pool
     * @param _poolID the ID of the pools user is trying to see LP tokens from
     * @return The number of LP tokens contributed
     */
    function getUserContributedLiquid(
        uint256 _poolID
    ) external view returns (uint256) {
        LiquidTypes.UserInfo storage user = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];

        return user.amount;
    }
    
    /**
     * @notice Distributes tokens to user based on their previously earned rewards.
     * @param _poolID The id of the pool that user is trying to claim funds from
     */
    function airdrop(uint256 _poolID) external payable nonReentrant {
        LiquidCalculate.distributeRewards(_poolID);
    }

    /**
     * @notice Calls calculation for settling how much tokens user is allocated to receive based on % of LP held
     * @param _poolID The id of the pool that user is trying to receive reward for
     * @param _dailyLiquidity The number of tokens in daily Liquidity, should receive it from an Oracle or API
     * @dev Daily liquidity is too expensive to be held on the Chain and hosts a lot of logic which incerease costs.
     */
    function settleUserPercentHeldReward(
        uint256 _poolID,
        uint256 _dailyLiquidity
    ) external {
        LiquidCalculate.settleUserDailyRewards(_poolID, _dailyLiquidity);
    }

    /**
     * @notice Returns the number of user daily rewards they are entitle to
     * @param _poolID the Id of the pool user is trying to see their rewards from
     * @return The number of tokens user should receive as a reward. 
     */
    function getUserDailyRewards(
        uint256 _poolID
    ) external view returns (uint256) {
        LiquidTypes.UserInfo storage user = LiquidStorage.userInfo[_poolID][
            msg.sender
        ];
        return user.dailyTokensReward;
    }
   
    /**
     * @notice Swaps token from one to another
     * @param _poolID The id of the pool
     * @param _purchaseAmount The amount of tokens user is trying to swap 
     * @dev Automatically calculates the price of token being swapped
     * 
     */
    function tokenSwap(uint256 _poolID, uint256 _purchaseAmount) external onlyWhitelisted() {
        LiquidCalculate.swapTokens(_poolID, _purchaseAmount);
    }

    function sellToken(uint256 _poolID, uint256 _sellAmount, bool _sellAll) external onlyWhitelisted() {
        LiquidCalculate.sellTokens(_poolID, _sellAmount, _sellAll);
    }

    /**
     * @notice Returns the supply of second token 
     * @param _poolID The id of the pool for which to return token supply
     */
    function getLiquidTokenSupply(uint256 _poolID) external view returns(uint256) {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        
        return pair.totalLiquidityToken;
    }
    /**
     * @notice Returns the supply of first Token 
     * @param _poolID The id of the pool for which to return token supply
     */
    function getGMTTokenSupply(uint256 _poolID) external view returns(uint256) {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        
        return pair.totalGMT;
    }
    /**
     * @notice Returns the price per token of the second token
     * @param _poolID The id of the pool for which to return price per token
     */
    function getLiquidTokenPrice(uint256 _poolID) external view returns(uint256) {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        
        return pair.liquidityTokenPrice;
    }
    /**
     * @notice Returns the price per token of the first token
     * @param _poolID The id of the pool for which to return price per token
     */

    function getGMTTokenPrice(uint256 _poolID) external view returns(uint256) {
        LiquidTypes.PoolPair storage pair = LiquidStorage.poolPairs[_poolID];
        
        return pair.GMTPrice;
    } 
    /**
     * @notice Returns the number of tokens that are being held in the rewards wallet
     * @param _poolID The id of the pool, reward Wallet is same for all pools 
     * @return uint256 Representing the amount of tokens being held
     */
    function getRewardWalletBalance(uint256 _poolID) external view returns(uint256) {
        LiquidTypes.TaxInfo memory tax = LiquidStorage.taxWalletInfo[_poolID];
        return tax.rewardWalletBalance;
    }
    function updateDepositTax(uint256 _poolID, uint256 _depositTax) external {
        LiquidTypes.TaxInfo storage tax = LiquidStorage.taxWalletInfo[_poolID];

        tax.depositTax = _depositTax;

        emit LiquidEvents.DepositTax(_poolID, _depositTax);
    }
    function updateWithdrawTax(uint256 _poolID, uint256 _withdrawTax) external {
        LiquidTypes.TaxInfo storage tax = LiquidStorage.taxWalletInfo[_poolID];

        tax.withdrawTax = _withdrawTax;

        emit LiquidEvents.WithdrawTax(_poolID, _withdrawTax);
    }
    function updateSlippagePercent(uint256 _poolID, uint256 _newSlippagePercent) external {
        LiquidTypes.PoolPair storage pairs = LiquidStorage.poolPairs[_poolID];

        pairs.acceptedSlippagePercent = _newSlippagePercent;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "../libs/interfaces/IBEP20.sol";
import "../Tokens/GMT/IERC20.sol";


library LiquidEvents { 

    // Event for creating new pool
    event AddPool(uint256 indexed pid, uint256 allocPoint, IERC20 lpToken);
    
    // Event for updating existing pool
    event UpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accCakePerShare);
    
    // Event for user deposit to an existing pool
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    
    // Event for user withdraw from an existing pool
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
    // Event for setting allocation points 
    event SetPool(uint256 indexed pid, uint256 allocPoint);

    event DepositTax(uint256 indexed pid, uint256 newTax);

    event WithdrawTax(uint256 indexed pid, uint256 newTax);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./LiquidTypes.sol";
import "../Tokens/GMT/IERC20.sol";
import "../libs/interfaces/IBEP20.sol";
import "../libs/SafeBEP20.sol";

contract LiquidStorage {

    // Keccaks of different roles.
    bytes32 internal constant OWNER = keccak256("OWNER");
    bytes32 internal constant BURNER = keccak256("BURNER");
    bytes32 internal constant WHITELISTED = keccak256("WHITELISTED");
    
    // Mapping of user contributors to any LP, used to describe necesarry information about each user.
    mapping(uint256 => mapping(address => LiquidTypes.UserInfo))
        public userInfo;


    // Array of Pools used to describe additional information about each pool. (Each poolInfo has a poolPair)
    LiquidTypes.PoolInfo[] public poolInfo;
    
    // Array of Pool Pair types hosting pairs of tokens used in a single LP(E.G GMT/USDT)
    LiquidTypes.PoolPair[] public poolPairs;
    
    // Array of Allocation points per Pair per pool 
    LiquidTypes.AllocationPointsPerPair[] public allocPairs;
    
    // Array of wallets used for taxing purposes of a Pool
    LiquidTypes.TaxInfo[] public taxWalletInfo;

    // Array hosting all liquidity pool tokens
    IERC20[] public lpTokens;

    // Uint256 representing precise rounding. It is mainly used on dividing and multiplications with percentages for accuracy of data.
    uint256 public constant ACC_REWARD_PRECISION = 1e18;


    // Used for when precision is needed but not up to (decimals + ACC_REWARD_PRECISION).
    uint256 public constant ACC_REWARD_SMALL_PRECISION = 1e6;

    // Total allocation points, can be used for custom rewards
    uint256 public totalRegularAllocPoint;

    // Total number of pools existing, 0 on the start 
    uint256 public numberOfPools = 0;

    // IERC20 instance of the GMT Token
    IERC20 public GMT;

    // IERC20 instance of any token that is used in LP
    IERC20 public token;

    // Address of the owner, mainly used for testing purposes.
    address public ownerAddress;

    // Address of the wallet where rewards will be payed out from
    address public rewardWallet;

    uint256 public constantProductMarketMaker;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "../libs/interfaces/IBEP20.sol";
import "../Tokens/GMT/IERC20.sol";

library LiquidTypes {
    struct PoolPair {
        IERC20  GMTToken;
        IERC20  LiquidityToken;
        uint256 totalGMT;
        uint256 totalLiquidityToken;
        uint256 totalLiquidity;
        uint256 poolAPY;
        uint256 dailyFeePercentage;
        uint256 constantProductMarketMaker;
        uint256 GMTPrice;
        uint256 liquidityTokenPrice;
        uint256 acceptedSlippagePercent;
    }
    struct AllocationPointsPerPair {
        uint256 allocationPointGMT;
        uint256 allocationPointLiquid;
    }
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 boostMultiplier;
        uint256 timePeriod;
        uint256 gmtContributed;
        uint256 dailyTokensReward;
    }

    struct PoolInfo {
        uint256 accRewardPerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
    }

    struct TaxInfo {
        uint256 depositTax;
        uint256 withdrawTax;
        uint256 rewardWalletBalance;
        address payoutWallet;
    }

    struct TaxPayout {
        uint256 timeStamp;
        address payoutWallet;
        uint256 totalTaxes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <=0.8.9;


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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