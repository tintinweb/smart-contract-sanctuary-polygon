/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// 
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// 
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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


// File @openzeppelin/contracts/utils/[email protected].3

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts/access/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




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


// File @openzeppelin/contracts/access/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}


// File @openzeppelin/contracts/utils/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/IERC721.sol

// 

pragma solidity ^0.8.1;
/**
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721 is IERC165 {
    /**
     * @dev This emits when ownership of any NFT changes by any mechanism.
     *  This event emits when NFTs are created (`from` == 0) and destroyed
     *  (`to` == 0). Exception: during contract creation, any number of NFTs
     *  may be created and assigned without emitting Transfer. At the time of
     *  any transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or
     *  reaffirmed. The zero address indicates there is no approved address.
     *  When a Transfer event emits, this also indicates that the approved
     *  address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner.
     *  The operator can manage all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *  function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     *  about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter,
     *  except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *  Throws unless `msg.sender` is the current NFT owner, or an authorized
     *  operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external payable;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *  multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) external view returns (address);

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


// File contracts/extensions/IERC721Metadata.sol

// 

pragma solidity ^0.8.1;
/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
 */
interface IERC721Metadata is IERC721 {
    /**
     * @notice A descriptive name for a collection of NFTs in this contract
     */
    function name() external view returns (string memory);

    /**
     * @notice An abbreviated name for NFTs in this contract
     */
    function symbol() external view returns (string memory);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     *  3986. The URI may point to a JSON file that conforms to the "ERC721
     *  Metadata JSON Schema".
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}


// File contracts/IERC3525.sol

// 

pragma solidity ^0.8.0;
/**
 * @title ERC-3525 Semi-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xd5358140.
 */
interface IERC3525 is IERC165, IERC721 {
    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 _value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, address indexed _operator, uint256 _value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param _tokenId The token of which slot is set or changed
     * @param _oldSlot The previous slot of the token
     * @param _newSlot The updated slot of the token
     */
    event SlotChanged(uint256 indexed _tokenId, uint256 indexed _oldSlot, uint256 indexed _newSlot);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */
    function valueDecimals() external view returns (uint8);

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */
    function balanceOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the slot of a token.
     * @param _tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(uint256 _tokenId, address _operator, uint256 _value) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, address _operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param _fromTokenId The token to transfer value from
     * @param _toTokenId The token to transfer value to
     * @param _value The transferred value
     */
    function transferFrom(uint256 _fromTokenId, uint256 _toTokenId, uint256 _value) external payable;

    /**
     * @notice Transfer value from a specified token to an address. The caller should confirm that
     *  `_to` is capable of receiving ERC3525 tokens.
     * @dev This function MUST create a new ERC3525 token with the same slot for `_to` to receive
     *  the transferred value.
     *  MUST revert if `_fromTokenId` is zero token id or does not exist.
     *  MUST revert if `_to` is zero address.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `Transfer` and `TransferValue` events.
     * @param _fromTokenId The token to transfer value from
     * @param _to The address to transfer value to
     * @param _value The transferred value
     * @return ID of the new token created for `_to` which receives the transferred value
     */
    function transferFrom(uint256 _fromTokenId, address _to, uint256 _value) external payable returns (uint256);
}


// File contracts/extensions/IERC3525Metadata.sol

// 

pragma solidity ^0.8.1;
/**
 * @title ERC-3525 Semi-Fungible Token Standard, optional extension for metadata
 * @dev Interfaces for any contract that wants to support query of the Uniform Resource Identifier
 *  (URI) for the ERC3525 contract as well as a specified slot.
 *  Because of the higher reliability of data stored in smart contracts compared to data stored in
 *  centralized systems, it is recommended that metadata, including `contractURI`, `slotURI` and
 *  `tokenURI`, be directly returned in JSON format, instead of being returned with a url pointing
 *  to any resource stored in a centralized system.
 *  See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xe1600902.
 */
interface IERC3525Metadata is IERC3525, IERC721Metadata {
    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the current ERC3525 contract.
     * @dev This function SHOULD return the URI for this contract in JSON format, starting with
     *  header `data:application/json;`.
     *  See https://eips.ethereum.org/EIPS/eip-3525 for the JSON schema for contract URI.
     * @return The JSON formatted URI of the current ERC3525 contract
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the specified slot.
     * @dev This function SHOULD return the URI for `_slot` in JSON format, starting with header
     *  `data:application/json;`.
     *  See https://eips.ethereum.org/EIPS/eip-3525 for the JSON schema for slot URI.
     * @return The JSON formatted URI of `_slot`
     */
    function slotURI(uint256 _slot) external view returns (string memory);
}


// File contracts/extensions/IERC721Enumerable.sol

// 

pragma solidity ^0.8.1;
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x780e9d63.
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @notice Count NFTs tracked by this contract
     * @return A count of valid NFTs tracked by this contract, where each one of
     *  them has an assigned and queryable owner not equal to the zero address
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Enumerate valid NFTs
     * @dev Throws if `_index` >= `totalSupply()`.
     * @param _index A counter less than `totalSupply()`
     * @return The token identifier for the `_index`th NFT,
     *  (sort order not specified)
     */
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /**
     * @notice Enumerate NFTs assigned to an owner
     * @dev Throws if `_index` >= `balanceOf(_owner)` or if
     *  `_owner` is the zero address, representing invalid NFTs.
     * @param _owner An address where we are interested in NFTs owned by them
     * @param _index A counter less than `balanceOf(_owner)`
     * @return The token identifier for the `_index`th NFT assigned to `_owner`,
     *  (sort order not specified)
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


// File contracts/IERC3525Receiver.sol

// 

pragma solidity ^0.8.1;

/**
 * @title EIP-3525 token receiver interface
 * @dev Interface for a smart contract that wants to be informed by EIP-3525 contracts when
 *  receiving values from ANY addresses or EIP-3525 tokens.
 * Note: the EIP-165 identifier for this interface is 0x009ce20b.
 */
interface IERC3525Receiver {
    /**
     * @notice Handle the receipt of an EIP-3525 token value.
     * @dev An EIP-3525 smart contract MUST check whether this function is implemented by the
     *  recipient contract, if the recipient contract implements this function, the EIP-3525
     *  contract MUST call this function after a value transfer (i.e. `transferFrom(uint256,
     *  uint256,uint256,bytes)`).
     *  MUST return 0x009ce20b (i.e. `bytes4(keccak256('onERC3525Received(address,uint256,uint256,
     *  uint256,bytes)'))`) if the transfer is accepted.
     *  MUST revert or return any value other than 0x009ce20b if the transfer is rejected.
     * @param _operator The address which triggered the transfer
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256('onERC3525Received(address,uint256,uint256,uint256,bytes)'))`
     *  unless the transfer is rejected.
     */
    function onERC3525Received(
        address _operator,
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);
}


// File contracts/IERC721Receiver.sol

// 

pragma solidity ^0.8.1;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 *  Note: the ERC-165 identifier for this interface is 0x150b7a02.
 */
interface IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a `transfer`. This function MAY throw to revert and reject the
     *  transfer. Return of other than the magic value MUST result in the
     *  transaction being reverted.
     *  Note: the contract address is always the message sender.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transferred
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
        external
        returns (bytes4);
}


// File contracts/periphery/interface/IERC3525MetadataDescriptor.sol

// 

pragma solidity ^0.8.0;

interface IERC3525MetadataDescriptor {
    function constructContractURI() external view returns (string memory);

    function constructSlotURI(uint256 slot) external view returns (string memory);

    function constructTokenURI(uint256 tokenId) external view returns (string memory);
}


// File contracts/ERC3525.sol

// 

pragma solidity ^0.8.0;
contract ERC3525 is Context, IERC3525Metadata, IERC721Enumerable {
    using Strings for address;
    using Strings for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    event SetMetadataDescriptor(address indexed metadataDescriptor);

    struct TokenData {
        uint256 id;
        uint256 slot;
        uint256 balance;
        address owner;
        address approved;
        address[] valueApprovals;
    }

    struct AddressData {
        uint256[] ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(address => bool) approvals;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    Counters.Counter private _tokenIdGenerator;

    // id => (approval => allowance)
    // @dev _approvedValues cannot be defined within TokenData, cause struct containing mappings cannot be constructed.
    mapping(uint256 => mapping(address => uint256)) private _approvedValues;

    TokenData[] private _allTokens;

    // key: id
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => AddressData) private _addressData;

    IERC3525MetadataDescriptor public metadataDescriptor;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC3525).interfaceId
            || interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC3525Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals the token uses for value.
     */
    function valueDecimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].balance;
    }

    function ownerOf(uint256 tokenId_) public view virtual override returns (address owner_) {
        _requireMinted(tokenId_);
        owner_ = _allTokens[_allTokensIndex[tokenId_]].owner;
        require(owner_ != address(0), "ERC3525: invalid token ID");
    }

    function slotOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].slot;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function contractURI() public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return address(metadataDescriptor) != address(0)
            ? metadataDescriptor.constructContractURI()
            : bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "contract/", Strings.toHexString(address(this))))
                : "";
    }

    function slotURI(uint256 slot_) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return address(metadataDescriptor) != address(0)
            ? metadataDescriptor.constructSlotURI(slot_)
            : bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "slot/", slot_.toString())) : "";
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        string memory baseURI = _baseURI();
        return address(metadataDescriptor) != address(0)
            ? metadataDescriptor.constructTokenURI(tokenId_)
            : bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId_.toString())) : "";
    }

    function approve(uint256 tokenId_, address to_, uint256 value_) public payable virtual override {
        address owner = ERC3525.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: approve caller is not owner nor approved");

        _approveValue(tokenId_, to_, value_);
    }

    function allowance(uint256 tokenId_, address operator_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _approvedValues[tokenId_][operator_];
    }

    function transferFrom(uint256 fromTokenId_, address to_, uint256 value_)
        public
        payable
        virtual
        override
        returns (uint256 newTokenId)
    {
        _spendAllowance(_msgSender(), fromTokenId_, value_);

        newTokenId = _createDerivedTokenId(fromTokenId_);
        _mint(to_, newTokenId, ERC3525.slotOf(fromTokenId_), 0);
        _transferValue(fromTokenId_, newTokenId, value_);
    }

    function transferFrom(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) public payable virtual override {
        _spendAllowance(_msgSender(), fromTokenId_, value_);
        _transferValue(fromTokenId_, toTokenId_, value_);
    }

    function balanceOf(address owner_) public view virtual override returns (uint256 balance) {
        require(owner_ != address(0), "ERC3525: balance query for the zero address");
        return _addressData[owner_].ownedTokens.length;
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public payable virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _transferTokenId(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_)
        public
        payable
        virtual
        override
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _safeTransferTokenId(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public payable virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function approve(address to_, uint256 tokenId_) public payable virtual override {
        address owner = ERC3525.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(
            _msgSender() == owner || ERC3525.isApprovedForAll(owner, _msgSender()),
            "ERC3525: approve caller is not owner nor approved for all"
        );

        _approve(to_, tokenId_);
    }

    function getApproved(uint256 tokenId_) public view virtual override returns (address) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].approved;
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual override {
        _setApprovalForAll(_msgSender(), operator_, approved_);
    }

    function isApprovedForAll(address owner_, address operator_) public view virtual override returns (bool) {
        return _addressData[owner_].approvals[operator_];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525.totalSupply(), "ERC3525: global index out of bounds");
        return _allTokens[index_].id;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525.balanceOf(owner_), "ERC3525: owner index out of bounds");
        return _addressData[owner_].ownedTokens[index_];
    }

    function _setApprovalForAll(address owner_, address operator_, bool approved_) internal virtual {
        require(owner_ != operator_, "ERC3525: approve to caller");

        _addressData[owner_].approvals[operator_] = approved_;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual returns (bool) {
        address owner = ERC3525.ownerOf(tokenId_);
        return (
            operator_ == owner || ERC3525.isApprovedForAll(owner, operator_)
                || ERC3525.getApproved(tokenId_) == operator_
        );
    }

    function _spendAllowance(address operator_, uint256 tokenId_, uint256 value_) internal virtual {
        uint256 currentAllowance = ERC3525.allowance(tokenId_, operator_);
        if (!_isApprovedOrOwner(operator_, tokenId_) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= value_, "ERC3525: insufficient allowance");
            _approveValue(tokenId_, operator_, currentAllowance - value_);
        }
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[tokenId_]].id == tokenId_;
    }

    function _requireMinted(uint256 tokenId_) internal view virtual {
        require(_exists(tokenId_), "ERC3525: invalid token ID");
    }

    function _mint(address to_, uint256 slot_, uint256 value_) internal virtual returns (uint256 tokenId) {
        tokenId = _createOriginalTokenId();
        _mint(to_, tokenId, slot_, value_);
    }

    function _mint(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual {
        require(to_ != address(0), "ERC3525: mint to the zero address");
        require(tokenId_ != 0, "ERC3525: cannot mint zero tokenId");
        require(!_exists(tokenId_), "ERC3525: token already minted");

        _beforeValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
        __mintToken(to_, tokenId_, slot_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
    }

    function _mintValue(uint256 tokenId_, uint256 value_) internal virtual {
        address owner = ERC3525.ownerOf(tokenId_);
        uint256 slot = ERC3525.slotOf(tokenId_);
        _beforeValueTransfer(address(0), owner, 0, tokenId_, slot, value_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), owner, 0, tokenId_, slot, value_);
    }

    function __mintValue(uint256 tokenId_, uint256 value_) private {
        _allTokens[_allTokensIndex[tokenId_]].balance += value_;
        emit TransferValue(0, tokenId_, value_);
    }

    function __mintToken(address to_, uint256 tokenId_, uint256 slot_) private {
        TokenData memory tokenData = TokenData({
            id: tokenId_,
            slot: slot_,
            balance: 0,
            owner: to_,
            approved: address(0),
            valueApprovals: new address[](0)
        });

        _addTokenToAllTokensEnumeration(tokenData);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(address(0), to_, tokenId_);
        emit SlotChanged(tokenId_, 0, slot_);
    }

    function _burn(uint256 tokenId_) internal virtual {
        _requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, value);

        _clearApprovedValues(tokenId_);
        _removeTokenFromOwnerEnumeration(owner, tokenId_);
        _removeTokenFromAllTokensEnumeration(tokenId_);

        emit TransferValue(tokenId_, 0, value);
        emit SlotChanged(tokenId_, slot, 0);
        emit Transfer(owner, address(0), tokenId_);

        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, value);
    }

    function _burnValue(uint256 tokenId_, uint256 burnValue_) internal virtual {
        _requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        require(value >= burnValue_, "ERC3525: burn value exceeds balance");

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, burnValue_);

        tokenData.balance -= burnValue_;
        emit TransferValue(tokenId_, 0, burnValue_);

        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, burnValue_);
    }

    function _addTokenToOwnerEnumeration(address to_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = to_;

        _addressData[to_].ownedTokensIndex[tokenId_] = _addressData[to_].ownedTokens.length;
        _addressData[to_].ownedTokens.push(tokenId_);
    }

    function _removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = address(0);

        AddressData storage ownerData = _addressData[from_];
        uint256 lastTokenIndex = ownerData.ownedTokens.length - 1;
        uint256 lastTokenId = ownerData.ownedTokens[lastTokenIndex];
        uint256 tokenIndex = ownerData.ownedTokensIndex[tokenId_];

        ownerData.ownedTokens[tokenIndex] = lastTokenId;
        ownerData.ownedTokensIndex[lastTokenId] = tokenIndex;

        delete ownerData.ownedTokensIndex[tokenId_];
        ownerData.ownedTokens.pop();
    }

    function _addTokenToAllTokensEnumeration(TokenData memory tokenData_) private {
        _allTokensIndex[tokenData_.id] = _allTokens.length;
        _allTokens.push(tokenData_);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId_) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId_];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        TokenData memory lastTokenData = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenData; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenData.id] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId_];
        _allTokens.pop();
    }

    function _approve(address to_, uint256 tokenId_) internal virtual {
        _allTokens[_allTokensIndex[tokenId_]].approved = to_;
        emit Approval(ERC3525.ownerOf(tokenId_), to_, tokenId_);
    }

    function _approveValue(uint256 tokenId_, address to_, uint256 value_) internal virtual {
        require(to_ != address(0), "ERC3525: approve value to the zero address");
        if (!_existApproveValue(to_, tokenId_)) {
            _allTokens[_allTokensIndex[tokenId_]].valueApprovals.push(to_);
        }
        _approvedValues[tokenId_][to_] = value_;

        emit ApprovalValue(tokenId_, to_, value_);
    }

    function _clearApprovedValues(uint256 tokenId_) internal virtual {
        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        uint256 length = tokenData.valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            address approval = tokenData.valueApprovals[i];
            delete _approvedValues[tokenId_][approval];
        }
        delete tokenData.valueApprovals;
    }

    function _existApproveValue(address to_, uint256 tokenId_) internal view virtual returns (bool) {
        uint256 length = _allTokens[_allTokensIndex[tokenId_]].valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_allTokens[_allTokensIndex[tokenId_]].valueApprovals[i] == to_) {
                return true;
            }
        }
        return false;
    }

    function _transferValue(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_) internal virtual {
        require(_exists(fromTokenId_), "ERC3525: transfer from invalid token ID");
        require(_exists(toTokenId_), "ERC3525: transfer to invalid token ID");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[fromTokenId_]];
        TokenData storage toTokenData = _allTokens[_allTokensIndex[toTokenId_]];

        require(fromTokenData.balance >= value_, "ERC3525: insufficient balance for transfer");
        require(fromTokenData.slot == toTokenData.slot, "ERC3525: transfer to token with different slot");

        _beforeValueTransfer(
            fromTokenData.owner, toTokenData.owner, fromTokenId_, toTokenId_, fromTokenData.slot, value_
        );

        fromTokenData.balance -= value_;
        toTokenData.balance += value_;

        emit TransferValue(fromTokenId_, toTokenId_, value_);

        _afterValueTransfer(
            fromTokenData.owner, toTokenData.owner, fromTokenId_, toTokenId_, fromTokenData.slot, value_
        );

        require(
            _checkOnERC3525Received(fromTokenId_, toTokenId_, value_, ""),
            "ERC3525: transfer rejected by ERC3525Receiver"
        );
    }

    function _transferTokenId(address from_, address to_, uint256 tokenId_) internal virtual {
        require(ERC3525.ownerOf(tokenId_) == from_, "ERC3525: transfer from invalid owner");
        require(to_ != address(0), "ERC3525: transfer to the zero address");

        uint256 slot = ERC3525.slotOf(tokenId_);
        uint256 value = ERC3525.balanceOf(tokenId_);

        _beforeValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);

        _approve(address(0), tokenId_);
        _clearApprovedValues(tokenId_);

        _removeTokenFromOwnerEnumeration(from_, tokenId_);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(from_, to_, tokenId_);

        _afterValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);
    }

    function _safeTransferTokenId(address from_, address to_, uint256 tokenId_, bytes memory data_) internal virtual {
        _transferTokenId(from_, to_, tokenId_);
        require(_checkOnERC721Received(from_, to_, tokenId_, data_), "ERC3525: transfer to non ERC721Receiver");
    }

    function _checkOnERC3525Received(uint256 fromTokenId_, uint256 toTokenId_, uint256 value_, bytes memory data_)
        private
        returns (bool)
    {
        address to = ERC3525.ownerOf(toTokenId_);
        if (to.isContract() && IERC165(to).supportsInterface(type(IERC3525Receiver).interfaceId)) {
            bytes4 retval =
                IERC3525Receiver(to).onERC3525Received(_msgSender(), fromTokenId_, toTokenId_, value_, data_);
            return retval == IERC3525Receiver.onERC3525Received.selector;
        } else {
            return true;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from_ address representing the previous owner of the given token ID
     * @param to_ target address that will receive the tokens
     * @param tokenId_ uint256 ID of the token to be transferred
     * @param data_ bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from_, address to_, uint256 tokenId_, bytes memory data_)
        private
        returns (bool)
    {
        if (to_.isContract()) {
            try IERC721Receiver(to_).onERC721Received(_msgSender(), from_, tokenId_, data_) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    /* solhint-disable */
    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}
    /* solhint-enable */

    function _setMetadataDescriptor(address metadataDescriptor_) internal virtual {
        metadataDescriptor = IERC3525MetadataDescriptor(metadataDescriptor_);
        emit SetMetadataDescriptor(metadataDescriptor_);
    }

    function _createOriginalTokenId() internal virtual returns (uint256) {
        _tokenIdGenerator.increment();
        return _tokenIdGenerator.current();
    }

    function _createDerivedTokenId(uint256 fromTokenId_) internal virtual returns (uint256) {
        fromTokenId_;
        return _createOriginalTokenId();
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// 
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


// File contracts/IPlatformSFT.sol

//

pragma solidity ^0.8.0;

interface IPlatformSFT {
    function mint(address mintTo_, uint256 slot_, uint256 value_) external returns (uint256);

    function mintValue(uint256 tokenId_, uint256 value_) external;

    // function burn(uint256 tokenId_) external; // to avoid exceed size

    function burnValue(uint256 tokenId_, uint256 burnValue_) external;
}


// File contracts/pools/Pool.sol

// 
pragma solidity ^0.8.0;
abstract contract Pool {
    address public platform;

    // Processing second bookkeeping and sub-ledgers
    function distributeFT(address ft, uint64 mainType, uint64 subType, address player, uint256 amount)
        external
        virtual;

    modifier onlyPlatform() {
        require(msg.sender == platform, "Not granted");
        _;
    }
}


// File contracts/Roles.sol

// 
pragma solidity >0.8.0;
contract Roles is AccessControl {
    error NotAuthorizedError(address sender);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(address _owner) {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            revert NotAuthorizedError(_msgSender());
        }
        _;
    }

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, _msgSender())) {
            revert NotAuthorizedError(_msgSender());
        }
        _;
    }
}


// File contracts/PlatformSFT.sol

//

pragma solidity ^0.8.0;
interface IPayment {
    function payment(uint64 mainType) external view returns (address);
}

// Ownable is designed to conform to OpenSea's presentation standards and facilitate the import
contract PlatformSFT is IPlatformSFT, ERC3525, Pool, Ownable {
    // slot => totalSupply
    mapping(uint256 => uint256) public totalShare; // share

    mapping(uint64 => uint256) public totalFT; // USDT

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address platform_)
        ERC3525(name_, symbol_, decimals_)
    {
        platform = platform_;
    }

    function mint(address mintTo_, uint256 slot_, uint256 value_) external onlyPlatform returns (uint256) {
        uint256 tokenId_ = _createOriginalTokenId();
        ERC3525._mint(mintTo_, tokenId_, slot_, value_);
        totalShare[slot_] += value_;
        return tokenId_;
    }

    function mintValue(uint256 tokenId_, uint256 value_) external onlyPlatform {
        uint256 slot = ERC3525.slotOf(tokenId_);
        totalShare[slot] += value_;
        ERC3525._mintValue(tokenId_, value_);
    }

    function burnValue(uint256 tokenId_, uint256 burnValue_) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: caller is not token owner nor approved");
        ERC3525._burnValue(tokenId_, burnValue_);
        // platformSFT itself is a sharePool for all kind (mainType) of games
        // query FT of this slot, than transfer FT.
        // FT transfer to ownerOf tokenId_ ??? or to approved msg.sender ???
        uint64 slot = uint64(ERC3525.slotOf(tokenId_));

        IERC20 FT = IERC20(IPayment(platform).payment(slot));
        // FT.transfer(_msgSender(), FT.balanceOf(address(this)) * burnValue_ / totalSupply[slot]);
        uint256 ftAmount = totalFT[slot] * burnValue_ / totalShare[slot];
        FT.transfer(_msgSender(), ftAmount);
        totalFT[slot] -= ftAmount;
        totalShare[slot] -= burnValue_;
    }

    // mainType => distributeImpl
    mapping(uint64 => address) public distributeImpls;

    event ConfigDistributeImpl(uint64 mainType, address impl);

    function configDistributeImpl(uint64 mainType, address impl) external onlyOwner {
        // require(distributeImpls[mainType] == address(0), "Already Configured"); // comment out to avoid mistake
        // require(impl != address(0), "Zero address"); // comment out to allow zero address
        distributeImpls[mainType] = impl;
        emit ConfigDistributeImpl(mainType, impl);
    }

    function distributeFT(address FT, uint64 mainType, uint64 subType, address player, uint256 amount)
        external
        override
        onlyPlatform
    {
        totalFT[mainType] += amount;

        address impl = distributeImpls[mainType];
        if (impl != address(0)) {
            Pool(impl).distributeFT(FT, mainType, subType, player, amount);
        }
    }

    function setMetadataDescriptor(address _descriptor) external onlyOwner {
        ERC3525._setMetadataDescriptor(_descriptor);
    }

    mapping(address => bool) public allowedApprove;

    event ConfigAllowedApprove(address addr, bool approved);

    function configAllowedApprove(address addr, bool approved) external onlyOwner {
        allowedApprove[addr] = approved;
        emit ConfigAllowedApprove(addr, approved);
    }

    function _approve(address to_, uint256 tokenId_) internal override {
        require(allowedApprove[to_], "Forbidden to approve");
        ERC3525._approve(to_, tokenId_);
    }
}