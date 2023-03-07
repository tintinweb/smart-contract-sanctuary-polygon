/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.8.12;


// 
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)
/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// 
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)
/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)
/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)
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
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)
/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// 
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)
/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)
/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)
/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)
/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)
/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// 
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// 
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)
/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// 
contract ValidatorUpgradeable is Initializable {
    function __ValidatorUpgradeable_init() internal onlyInitializing {
        __ValidatorUpgradeable_init_unchained();
    }

    function __ValidatorUpgradeable_init_unchained()
        internal
        onlyInitializing
    {}

    function validate(
        bytes32 hash,
        address signer,
        bytes memory signature
    ) internal pure {
        require(
            ECDSAUpgradeable.recover(
                ECDSAUpgradeable.toEthSignedMessageHash(hash),
                signature
            ) == signer,
            "Validator: failure to validate the signature"
        );
    }
}

// 
interface IHookManager {
    enum Action {
        create,
        post,
        follow,
        unfollow,
        collect,
        transfer,
        superFollow,
        postAlbum,
        albumCollect
    }

    function onAction(Action action, bytes calldata data) external payable;

    function onAction(
        uint256 calleeId,
        Action action,
        bytes calldata data
    ) external payable;


    function onAction(
        uint256 calleeId,
        Action action,
        uint256 bindingId,
        bytes calldata data
    ) external payable;



    function setProfileHook(
        address sender,
        uint256 senderId,
        Action action,
        address hook,
        bytes memory extraData,
        bytes memory initializeData
    ) external;

    function setProfileHook(
        address sender,
        uint256 senderId,
        Action action,
        uint256 bindingId,
        address hook,
        bytes memory extraData,
        bytes memory initializeData
    ) external;
}

// 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// 
interface IProfile is IERC721EnumerableUpgradeable {
    function tokenOf(address owner) external view returns (uint256);
    function setTokenURI(uint256 tokenId, string calldata tokenURI) external;
    function mint(address to, string calldata tokenURI) external returns (uint256);
}

// 
interface INFTFactory {
    enum ProxyMode {
        none,
        clone,
        beacon,
        erc1967
    }

    function deploy(
        bytes32 tag,
        ProxyMode mode,
        bytes memory initializeData
    ) external returns (address);

    function lookup(address addr) external view returns (bool);
}

// 
interface IContent is IERC721EnumerableUpgradeable {
    function initialize(
        address ACL,
        address profile,
        address controller,
        string calldata name,
        string calldata symbol
    ) external;

    function mint(address to, string memory uri) external returns (uint256);
}

// 
interface ICollect is IERC721EnumerableUpgradeable {
    function initialize(
        address ACL,
        address profile,
        address controller,
        string calldata name,
        string calldata symbol
    ) external;

    function mint(address to) external returns (uint256);
    function setTokenURI(string memory tokenURI) external;
}

// 
interface IController {
    event Post(
        address indexed poster,
        uint256 posterId,
        address contentToken,
        uint256 contentId,
        string contentIdURI,
        address collectHook,
        bytes collectHookInitializeData
    );
    event Create(address indexed creator, uint256 creatorId, string tokenURI);

    event Collect(
        address indexed collector,
        uint256 collectorId,
        uint256 collectedId,
        address contentToken,
        uint256 contentId,
        address collectToken,
        uint256 collectId,
        bytes collectHookData
    );

    event SuperFollow(
        address indexed follower,
        uint256 followerId,
        uint256 followedId,
        address superFollowToken,
        uint256 superFollowId,
        bytes superFollowHookData
    );

    event PostAlbum(
        address indexed sender,
        uint256 senderId,
        address albumToken,
        uint256 albumId,
        address albumCollectToken,
        address albumCollectHook,
        bytes albumCollectHookInitializeData
    );

    event AlbumCollect(
        address indexed collector,
        uint256 collectorId,
        uint256 collectedId,
        address albumToken,
        uint256 albumId,
        address albumCollectToken,
        uint256 albumCollectId,
        bytes albumCollectHookData
    );

    event SetCollectHook(
        address indexed sender,
        uint256 senderId,
        address contentToken,
        uint256 contentId,
        address collectToken,
        address collectHook,
        bytes collectHookInitializeData
    );

    event SetCollectURI(
        address indexed sender,
        uint256 senderId,
        uint256 contentId,
        string followURI
    );

    event SetProfileURI(
        address indexed sender,
        uint256 senderId,
        string tokenURI
    );

    event SetAlbumURI(
        address indexed sender,
        uint256 senderId,
        uint256 albumId,
        string albumURI
    );

    event CreateSuperFollowHook(
        address indexed sender,
        uint256 senderId,
        address superFollowToken,
        address superFollowHook,
        bytes superFollowTokenInitializeData
    );

    event SetSuperFollowURI(
        address indexed sender,
        uint256 senderId,
        string superFollowURI
    );

    event OnNFTTransfer(
        bytes32 indexed tag,
        address indexed nftAddress,
        address from,
        uint256 fromProfileId,
        address to,
        uint256 toProfileId,
        uint256 tokenId
    );

    function onNFTTransfer(
        bytes32 tag,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getFollowToken(uint256 profileId) external view returns (address);

    function getSuperFollowToken(uint256 profileId)
        external
        view
        returns (address);

    // function getCollectToken(uint256 profileId) external view returns (address);
    // function getContentToken(uint256 profileId) external view returns (address);
    function getProfileTokenOf(address owner) external view returns (uint256);

    function getProfileOwnerOf(uint256 profileId)
        external
        view
        returns (address);
}

// 
interface ISuperFollow is IERC721EnumerableUpgradeable {
    function initialize(
        address ACL,
        address profile,
        address controller,
        string calldata name,
        string calldata symbol
    ) external;

    function mint(address to) external returns (uint256);
    function setTokenURI(string memory tokenURI) external;
}

// 
interface IAlbum is IERC721EnumerableUpgradeable {
    function initialize(
        address ACL,
        address profile,
        address controller,
        string calldata name,
        string calldata symbol
    ) external;

    function mint(
        address to,
        string calldata albumURI
    ) external returns (uint256);

    function setTokenURI(uint256 albumId, string memory albumURI) external;
}

// 
interface IAlbumCollect is IERC721EnumerableUpgradeable {
    function initialize(
        address ACL,
        address profile,
        address controller,
        string calldata name,
        string calldata symbol
    ) external;

    function mint(address to) external returns (uint256);
    function setTokenURI(string memory tokenURI) external;
}

// 
library constants {
    string public constant DEFAULT_PROFILE_TOKEN_URI = "https://ipfs.moralis.io:2053/ipfs/QmYJtNam2TeHtWZkeKcoWXpmE3WvqEUoZHojFR2jw4788b/bc8ffd05e032f3b086b73ebe288682f8";
    string public constant DEFAULT_FOLLOW_TOKEN_URI = "https://ipfs.moralis.io:2053/ipfs/QmSuVC2TGGiJGFrxJyTrPxm8D2m2xb1qgoFX9SoqWEabau/5194031148734c4e4fea4491bcdb1bf3";
    string public constant LUMINER_PREFIX = "Luminer ";
    // Luminer 1-Follower
    string public constant FOLLOW_NFT_NAME_SUFFIX = "-Follower";
    // Luminer 1-Fl
    string public constant FOLLOW_NFT_SYMBOL_SUFFIX = "-Fl";
    // Luminer 1-Content
    string public constant CONTENT_NFT_NAME_SUFFIX = "-Content";
    // Luminer 1-Cnt
    string public constant CONTENT_NFT_SYMBOL_SUFFIX = "-Cnt";
    // Luminer 1-Collect-1
    string public constant COLLECT_NFT_NAME_INFIX = "-Collect-";
    // Luminer 1-Cl-1
    string public constant COLLECT_NFT_SYMBOL_INFIX = "-Cl-";

    //Luminer 1-SuperFollow
    string public constant SUPER_FOLLOW_NFT_NAME_SUFFIX = "-SuperFollow";
    string public constant SUPER_FOLLOW_NFT_SYMBOL_SUFFIX = "-Sfl";

    string public constant ALBUM_NFT_NAME_SUFFIX = "-Album";
    string public constant ALBUM_NFT_SYMBOL_SUFFIX = "-Al";

    string public constant ALBUM_COLLECT_NFT_NAME_INFIX = "-AlbumCollect-";
    string public constant ALBUM_COLLECT_NFT_SYMBOL_INFIX = "-Acl-";

    //TAGS

    bytes32 public constant TAG_ERC721_CONTENT =
        keccak256("TAG_ERC721_CONTENT");
    bytes32 public constant TAG_ERC721_COLLECT =
        keccak256("TAG_ERC721_COLLECT");
    bytes32 public constant TAG_ERC721_FOLLOW = keccak256("TAG_ERC721_FOLLOW");
    bytes32 public constant TAG_ERC721_SUPER_FOLLOW = keccak256("TAG_ERC721_SUPER_FOLLOW");
    bytes32 public constant TAG_ERC721_ALBUM = keccak256("TAG_ERC721_ALBUM"); 
    bytes32 public constant TAG_ERC721_ALBUM_COLLECT = keccak256("TAG_ERC721_ALBUM_COLLECT");

    //ROLES

    bytes32 public constant ROLE_CONTROLLER = keccak256("CONTROLLER");
    bytes32 public constant ROLE_OWNER = keccak256("OWNER");

    //ERRORS

    string public constant ERR_INITIALIZE_WITH_ZERO_ADDRESS =
        "ERR_INITIALIZE_WITH_ZERO_ADDRESS";
    string public constant ERR_NO_PROFILE_FOUND_OR_BLACKLISTED =
        "ERR_NO_PROFILE_FOUND_OR_BLACKLISTED";
    string public constant ERR_TRANSFER_UNKNOWN_NFT =
        "ERR_TRANSFER_UNKNOWN_NFT";
    string public constant ERR_ARRAY_LENGTH_MISMATCH =
        "ERR_ARRAY_LENGTH_MISMATCH";
    string public constant ERR_FOLLOW_INVALID_PROFILE =
        "ERR_FOLLOW_INVALID_PROFILE";
    string public constant ERR_UNFOLLOW_INVALID_PROFILE =
        "ERR_UNFOLLOW_INVALID_PROFILE";
    string public constant ERR_ALREADY_FOLLOWING = "ERR_ALREADY_FOLLOWING";
    string public constant ERR_NOT_FOLLOWING = "ERR_NOT_FOLLOWING";
    string public constant ERR_COLLECT_NOT_ENABLED = "ERR_COLLECT_NOT_ENABLED";
    string public constant ERR_PERMISSION_DENIED = "ERR_PERMISSION_DENIED";
    string public constant ERR_NO_FOLLOWERS = "ERR_NO_FOLLOWERS";
    string public constant ERR_NO_COLLECTORS = "ERR_NO_COLLECTORS";
    string public constant ERR_NOT_FOUND_IMPL = "ERR_NOT_FOUND_IMPL";
    string public constant ERR_NOT_FOUND_BEACON = "ERR_NOT_FOUND_BEACON";
    string public constant ERR_UNSUPPORT_PROXY_MODE =
        "ERR_UNSUPPORT_PROXY_MODE";
    string public constant ERR_INVALID_INPUT = "ERR_INVALID_INPUT";
    string public constant ERR_HOOK_ALREADY_REGISTERED = "ERR_HOOK_ALREADY_REGISTERED";
    string public constant ERR_HOOK_NOT_REGISTERED = "ERR_HOOK_NOT_REGISTERED";
    string public constant ERR_SIGNATURE_IS_EXPIRED = "ERR_SIGNATURE_IS_EXPIRED";
    string public constant ERR_NOT_FOUND_FOLLOW_TOKEN = "ERR_NOT_FOUND_FOLLOW_TOKEN";
    string public constant ERR_NOT_FOUND_COLLECT_TOKEN = "ERR_NOT_FOUND_COLLECT_TOKEN";
    string public constant ERR_NOT_FOUND_CONTENT_TOKEN = "ERR_NOT_FOUND_CONTENT_TOKEN";
    string public constant ERR_NOT_FOUND_ALBUM_TOKEN = "ERR_NOT_FOUND_ALBUM_TOKEN";
    string public constant ERR_COLLECT_TOKEN_EXISTED = "ERR_COLLECT_TOKEN_EXISTED";
    string public constant ERR_DEPRECATED = "ERR_DEPRECATED";
    string public constant ERR_SUPER_FOLLOW_TOKEN_EXISTED = "ERR_SUPER_FOLLOW_TOKEN_EXISTED";
    string public constant ERR_SUPER_FOLLOW_NOT_ENABLED = "ERR_SUPER_FOLLOW_NOT_ENABLED";
    string public constant ERR_ALBUM_COLLECT_TOKEN_EXISTED = "ERR_ALBUM_COLLECT_TOKEN_EXISTED";
    string public constant ERR_ALBUM_COLLECT_NOT_ENABLED = "ERR_ALBUM_COLLECT_NOT_ENABLED"; 
}

// 
contract Controller is
    IController,
    PausableUpgradeable,
    ValidatorUpgradeable,
    ReentrancyGuardUpgradeable
{
    IAccessControlEnumerableUpgradeable public ACL;
    address public profile;
    address public hookManager;
    address public nftFactory;

    mapping(uint256 => address) private _follows; // Profile Id => follow NFT
    mapping(uint256 => address) private _contents; // Profile Id => Content NFT
    mapping(uint256 => mapping(uint256 => address)) private _collects; //Profile Id => Content Id => Collect NFT
    mapping(uint256 => address) private _superFollows; //Profile Id => super follow NFT;
    mapping(uint256 => address) private _albums; //profile Id => album NFT
    mapping(uint256 => mapping(uint256 => address)) private _albumCollects; //Profile Id => Album Id => Album Collect NFT

    function initialize(
        address _ACL,
        address _profile,
        address _hookManager,
        address _nftFactory
    ) external initializer {
        require(
            _ACL != address(0) &&
                _profile != address(0) &&
                _hookManager != address(0) &&
                _nftFactory != address(0),
            constants.ERR_INITIALIZE_WITH_ZERO_ADDRESS
        );

        PausableUpgradeable.__Pausable_init();
        ACL = IAccessControlEnumerableUpgradeable(_ACL);
        profile = _profile;
        hookManager = _hookManager;
        nftFactory = _nftFactory;
    }

    function create(string memory profileURI)
        external
        whenNotPaused
        nonReentrant
    {
        _create(msg.sender, profileURI);
    }

    function post(
        string memory contentURI,
        address collectHook,
        bytes memory collectHookInitializeData,
        string memory collectURI
    ) external whenNotPaused nonReentrant {
        uint256 posterId = IProfile(profile).tokenOf(msg.sender);
        require(posterId != 0, constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED);
        _post(
            msg.sender,
            posterId,
            contentURI,
            collectHook,
            collectHookInitializeData,
            collectURI
        );
    }

    function collect(
        uint256 collectedId,
        uint256 contentId,
        bytes memory collectHookData
    ) external payable whenNotPaused nonReentrant {
        uint256 collectorId = IProfile(profile).tokenOf(msg.sender);
        require(
            collectorId != 0,
            constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED
        );
        _collect(
            msg.sender,
            collectorId,
            collectedId,
            _contents[collectedId],
            contentId,
            collectHookData
        );
    }

    function superFollow(uint256 followedId, bytes calldata superFollowHookData)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 followerId = IProfile(profile).tokenOf(msg.sender);
        require(followerId != 0, constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED);
        _superfollow(msg.sender, followerId, followedId, superFollowHookData);
    }

    function postAlbum(
        string calldata albumURI,
        address albumCollectHook,
        bytes calldata albumCollectHookData,
        string calldata albumCollectURI
    ) external whenNotPaused nonReentrant {
        uint256 senderId = IProfile(profile).tokenOf(msg.sender);
        require(senderId != 0, constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED);
        _postAlbum(
            msg.sender,
            senderId,
            albumURI,
            albumCollectHook,
            albumCollectHookData,
            albumCollectURI
        );
    }

    function albumCollect(
        uint256 collectedId,
        uint256 albumId,
        bytes memory albumCollectHookData
    ) external payable whenNotPaused nonReentrant {
        uint256 collectorId = IProfile(profile).tokenOf(msg.sender);
        require(
            collectorId != 0,
            constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED
        );
        _albumCollect(
            msg.sender,
            collectorId,
            collectedId,
            _albums[collectedId],
            albumId,
            albumCollectHookData
        );
    }

    function createSuperFollow(
        address superFollowHook,
        bytes calldata superFollowtHookInitializeData,
        string calldata superFollowURI
    ) external whenNotPaused nonReentrant {
        uint256 senderId = IProfile(profile).tokenOf(msg.sender);
        require(senderId != 0, constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED);
        _createSuperFollow(
            msg.sender,
            senderId,
            superFollowHook,
            superFollowtHookInitializeData,
            superFollowURI
        );
    }

    function setCollectHook(
        uint256 contentId,
        address collectHook,
        bytes memory collectHookInitializeData
    ) external whenNotPaused nonReentrant {
        uint256 senderId = IProfile(profile).tokenOf(msg.sender);
        require(senderId != 0, constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED);
        _setCollectHook(
            msg.sender,
            senderId,
            contentId,
            collectHook,
            collectHookInitializeData
        );
    }

    function setSuperFollowURI(string calldata superFollowURI)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 senderId = IProfile(profile).tokenOf(msg.sender);
        require(senderId != 0, constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED);
        _setSuperFollowURI(msg.sender, senderId, superFollowURI);
    }

    function setCollectURI(uint256 contentId, string calldata collectURI)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 senderId = IProfile(profile).tokenOf(msg.sender);
        require(senderId != 0, constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED);
        _setCollectURI(msg.sender, senderId, contentId, collectURI);
    }

    function setProfileURI(string memory tokenURI)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 senderId = IProfile(profile).tokenOf(msg.sender);
        require(senderId != 0, constants.ERR_NO_PROFILE_FOUND_OR_BLACKLISTED);
        _setProfileURI(msg.sender, senderId, tokenURI);
    }

    function getFollowToken(uint256 profileId) external view returns (address) {
        return _follows[profileId];
    }

    function getSuperFollowToken(uint256 profileid)
        external
        view
        returns (address)
    {
        return _superFollows[profileid];
    }

    function getContentToken(uint256 profileId)
        external
        view
        returns (address)
    {
        return _contents[profileId];
    }

    function getCollectToken(uint256 profileId, uint256 contentId)
        external
        view
        returns (address)
    {
        return _collects[profileId][contentId];
    }

    function getAlbumToken(uint256 profileId) external view returns (address) {
        return _albums[profileId];
    }

    function getAlbumCollectToken(uint256 profileId, uint256 albumId)
        external
        view
        returns (address)
    {
        return _albumCollects[profileId][albumId];
    }

    function getProfileTokenOf(address owner) external view returns (uint256) {
        return IProfile(profile).tokenOf(owner);
    }

    function getProfileOwnerOf(uint256 profileId)
        external
        view
        returns (address)
    {
        return IProfile(profile).ownerOf(profileId);
    }

    function onNFTTransfer(
        bytes32 tag,
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(
            INFTFactory(nftFactory).lookup(msg.sender),
            constants.ERR_TRANSFER_UNKNOWN_NFT
        );
        bool isBurn = to == address(0);
        bool isMint = from == address(0);
        uint256 fromId = isMint ? 0 : IProfile(profile).tokenOf(from);
        uint256 toId = isBurn ? 0 : IProfile(profile).tokenOf(to);

        IHookManager(hookManager).onAction(
            IHookManager.Action.transfer,
            abi.encode(msg.sender, from, fromId, to, toId, tokenId)
        );

        if (!isBurn && toId == 0) {
            toId = _create(to, constants.DEFAULT_PROFILE_TOKEN_URI);
        }
        emit OnNFTTransfer(tag, msg.sender, from, fromId, to, toId, tokenId);
    }

    function createSigned(
        address creator,
        string calldata profileURI,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        validate(
            keccak256(
                abi.encodePacked(
                    creator,
                    keccak256(bytes(profileURI)),
                    deadline,
                    nonce
                )
            ),
            creator,
            signature
        );
        _create(creator, profileURI);
    }

    function postSigned(
        uint256 posterId,
        string calldata contentURI,
        address collectHook,
        bytes calldata collectHookInitializeData,
        string calldata collectURI,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        address poster = IProfile(profile).ownerOf(posterId);
        validate(
            keccak256(
                abi.encodePacked(
                    posterId,
                    keccak256(bytes(contentURI)),
                    collectHook,
                    keccak256(collectHookInitializeData),
                    keccak256(bytes(collectURI)),
                    deadline,
                    nonce
                )
            ),
            poster,
            signature
        );
        _post(
            poster,
            posterId,
            contentURI,
            collectHook,
            collectHookInitializeData,
            collectURI
        );
    }

    struct PostAlbumParams {
        uint256 posterId;
        string albumURI;
        address albumCollectHook;
        bytes albumCollectHookInitializeData;
        string albumCollectURI;
    }

    function postAlbumSigned(
        PostAlbumParams calldata postAlbumParams,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        address poster = IProfile(profile).ownerOf(postAlbumParams.posterId);
        validate(
            keccak256(
                abi.encodePacked(
                    postAlbumParams.posterId,
                    keccak256(bytes(postAlbumParams.albumURI)),
                    postAlbumParams.albumCollectHook,
                    keccak256(postAlbumParams.albumCollectHookInitializeData),
                    keccak256(bytes(postAlbumParams.albumCollectURI)),
                    deadline,
                    nonce
                )
            ),
            poster,
            signature
        );

        _postAlbum(
            poster,
            postAlbumParams.posterId,
            postAlbumParams.albumURI,
            postAlbumParams.albumCollectHook,
            postAlbumParams.albumCollectHookInitializeData,
            postAlbumParams.albumCollectURI
        );
    }

    function createSuperFollowSigned(
        uint256 ownerId,
        address superFollowHook,
        bytes calldata superFollowtHookInitializeData,
        string calldata superFollowURI,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        address owner = IProfile(profile).ownerOf(ownerId);
        validate(
            keccak256(
                abi.encodePacked(
                    superFollowHook,
                    keccak256(superFollowtHookInitializeData),
                    keccak256(bytes(superFollowURI)),
                    deadline,
                    nonce
                )
            ),
            owner,
            signature
        );
        _createSuperFollow(
            owner,
            ownerId,
            superFollowHook,
            superFollowtHookInitializeData,
            superFollowURI
        );
    }

    function setCollectHookSigned(
        uint256 senderId,
        uint256 contentId,
        address collectHook,
        bytes calldata collectHookInitializeData,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        address sender = IProfile(profile).ownerOf(senderId);
        validate(
            keccak256(
                abi.encodePacked(
                    senderId,
                    contentId,
                    collectHook,
                    keccak256(collectHookInitializeData),
                    deadline,
                    nonce
                )
            ),
            sender,
            signature
        );
        _setCollectHook(
            sender,
            senderId,
            contentId,
            collectHook,
            collectHookInitializeData
        );
    }

    function setCollectURISigned(
        uint256 senderId,
        uint256 contentId,
        string calldata collectURI,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        address sender = IProfile(profile).ownerOf(senderId);
        validate(
            keccak256(
                abi.encodePacked(
                    senderId,
                    contentId,
                    keccak256(bytes(collectURI)),
                    deadline,
                    nonce
                )
            ),
            sender,
            signature
        );
        _setCollectURI(sender, senderId, contentId, collectURI);
    }

    function setSuperFollowURISigned(
        uint256 senderId,
        string calldata superFollowURI,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        address sender = IProfile(profile).ownerOf(senderId);
        validate(
            keccak256(
                abi.encodePacked(
                    senderId,
                    keccak256(bytes(superFollowURI)),
                    deadline,
                    nonce
                )
            ),
            sender,
            signature
        );
        _setSuperFollowURI(sender, senderId, superFollowURI);
    }

    function setProfileURISigned(
        uint256 senderId,
        string calldata tokenURI,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        address sender = IProfile(profile).ownerOf(senderId);
        validate(
            keccak256(
                abi.encodePacked(
                    senderId,
                    keccak256(bytes(tokenURI)),
                    deadline,
                    nonce
                )
            ),
            sender,
            signature
        );
        _setProfileURI(sender, senderId, tokenURI);
    }

    function setAlbumURISigned(
        uint256 senderId,
        uint256 albumId,
        string calldata albumURI,
        bytes calldata signature,
        uint256 deadline,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(
            deadline >= block.timestamp,
            constants.ERR_SIGNATURE_IS_EXPIRED
        );
        address sender = IProfile(profile).ownerOf(senderId);
        validate(
            keccak256(
                abi.encodePacked(
                    senderId,
                    albumId,
                    keccak256(bytes(albumURI)),
                    deadline,
                    nonce
                )
            ),
            sender,
            signature
        );
        _setAlbumURI(sender, senderId, albumId, albumURI);
    }

    function _create(address creator, string memory profileURI)
        internal
        returns (uint256)
    {
        uint256 creatorId = IProfile(profile).mint(creator, profileURI);
        IHookManager(hookManager).onAction(
            IHookManager.Action.create,
            abi.encode(msg.sender, creator, creatorId)
        );
        emit Create(creator, creatorId, profileURI);
        return creatorId;
    }

    function _post(
        address poster,
        uint256 posterId,
        string memory contentURI,
        address collectHook,
        bytes memory collectHookInitializeData,
        string memory collectURI
    ) internal {
        address contentToken = _contents[posterId];
        if (contentToken == address(0)) {
            bytes memory contentTokenInitializeData = abi.encodeWithSelector(
                IContent.initialize.selector,
                ACL,
                profile,
                address(this),
                string(
                    abi.encodePacked(
                        constants.LUMINER_PREFIX,
                        StringsUpgradeable.toString(posterId),
                        constants.CONTENT_NFT_NAME_SUFFIX
                    )
                ),
                string(
                    abi.encodePacked(
                        constants.LUMINER_PREFIX,
                        StringsUpgradeable.toString(posterId),
                        constants.CONTENT_NFT_SYMBOL_SUFFIX
                    )
                )
            );
            contentToken = INFTFactory(nftFactory).deploy(
                constants.TAG_ERC721_CONTENT,
                INFTFactory.ProxyMode.beacon,
                contentTokenInitializeData
            );
            _contents[posterId] = contentToken;
        }
        uint256 contentId = IContent(contentToken).mint(poster, contentURI);

        require(
            _collects[posterId][contentId] == address(0),
            constants.ERR_COLLECT_TOKEN_EXISTED
        );

        bytes memory collectTokenInitializeData = abi.encodeWithSelector(
            ICollect.initialize.selector,
            ACL,
            profile,
            address(this),
            string(
                abi.encodePacked(
                    constants.LUMINER_PREFIX,
                    StringsUpgradeable.toString(posterId),
                    constants.COLLECT_NFT_SYMBOL_INFIX,
                    StringsUpgradeable.toString(contentId)
                )
            ),
            string(
                abi.encodePacked(
                    constants.LUMINER_PREFIX,
                    StringsUpgradeable.toString(posterId),
                    constants.COLLECT_NFT_NAME_INFIX,
                    StringsUpgradeable.toString(contentId)
                )
            )
        );
        address collectToken = INFTFactory(nftFactory).deploy(
            constants.TAG_ERC721_COLLECT,
            INFTFactory.ProxyMode.beacon,
            collectTokenInitializeData
        );
        _collects[posterId][contentId] = collectToken;

        ICollect(collectToken).setTokenURI(collectURI);

        if (collectHook != address(0)) {
            _setCollectHook(
                poster,
                posterId,
                contentId,
                collectHook,
                collectHookInitializeData
            );
        }
        IHookManager(hookManager).onAction(
            IHookManager.Action.post,
            abi.encode(poster, posterId, contentToken, contentId)
        );
        emit Post(
            poster,
            posterId,
            contentToken,
            contentId,
            contentURI,
            collectHook,
            collectHookInitializeData
        );
    }

    function _collect(
        address collector,
        uint256 collectorId,
        uint256 collectedId,
        address contentToken,
        uint256 contentId,
        bytes memory collectHookData
    ) internal {
        require(
            contentToken != address(0),
            constants.ERR_NOT_FOUND_CONTENT_TOKEN
        );
        address collectToken = _collects[collectedId][contentId];
        require(collectToken != address(0), constants.ERR_COLLECT_NOT_ENABLED);
        uint256 collectId = ICollect(collectToken).mint(collector);

        IHookManager(hookManager).onAction{value: msg.value}(
            collectedId,
            IHookManager.Action.collect,
            contentId,
            abi.encode(
                collector,
                collectorId,
                collectedId,
                contentToken,
                contentId,
                collectToken,
                collectId,
                collectHookData
            )
        );
        emit Collect(
            collector,
            collectorId,
            collectedId,
            contentToken,
            contentId,
            collectToken,
            collectId,
            collectHookData
        );
    }

    function _superfollow(
        address follower,
        uint256 followerId,
        uint256 followedId,
        bytes calldata superFollowHookData
    ) internal {
        address superFollowToken = _superFollows[followedId];
        require(
            superFollowToken != address(0),
            constants.ERR_SUPER_FOLLOW_NOT_ENABLED
        );
        uint256 superFollowId = ISuperFollow(superFollowToken).mint(follower);
        IHookManager(hookManager).onAction{value: msg.value}(
            followedId,
            IHookManager.Action.superFollow,
            abi.encode(
                follower,
                followerId,
                followedId,
                superFollowToken,
                superFollowId,
                superFollowHookData
            )
        );
        emit SuperFollow(
            follower,
            followerId,
            followedId,
            superFollowToken,
            superFollowId,
            superFollowHookData
        );
    }

    function _postAlbum(
        address sender,
        uint256 senderId,
        string calldata albumURI,
        address albumCollectHook,
        bytes calldata albumCollectHookInitializeData,
        string calldata albumCollectURI
    ) internal {
        address albumToken = _albums[senderId];
        if (albumToken == address(0)) {
            albumToken = _initAlbumToken(senderId);
        }
        uint256 albumId = IAlbum(albumToken).mint(sender, albumURI);
        address albumCollectToken = _initAlbumCollect(
            senderId,
            albumId,
            albumCollectURI
        );

        IHookManager(hookManager).setProfileHook(
            sender,
            senderId,
            IHookManager.Action.albumCollect,
            albumId,
            albumCollectHook,
            abi.encode(albumId),
            albumCollectHookInitializeData
        );

        emit PostAlbum(
            sender,
            senderId,
            albumToken,
            albumId,
            albumCollectToken,
            albumCollectHook,
            albumCollectHookInitializeData
        );
    }

    function _albumCollect(
        address collector,
        uint256 collectorId,
        uint256 collectedId,
        address albumToken,
        uint256 albumId,
        bytes memory albumCollectHookData
    ) internal {
        address albumCollectToken = _albumCollects[collectedId][albumId];
        require(
            albumCollectToken != address(0),
            constants.ERR_ALBUM_COLLECT_NOT_ENABLED
        );
        uint256 albumCollectId = IAlbumCollect(albumCollectToken).mint(
            collector
        );

        IHookManager(hookManager).onAction{value: msg.value}(
            collectedId,
            IHookManager.Action.albumCollect,
            albumId,
            abi.encode(
                collector,
                collectorId,
                collectedId,
                albumToken,
                albumId,
                albumCollectToken,
                albumCollectId,
                albumCollectHookData
            )
        );
        emit AlbumCollect(
            collector,
            collectorId,
            collectedId,
            albumToken,
            albumId,
            albumCollectToken,
            albumCollectId,
            albumCollectHookData
        );
    }

    function _createSuperFollow(
        address sender,
        uint256 senderId,
        address superFollowHook,
        bytes calldata superFollowHookInitializeData,
        string calldata superFollowURI
    ) internal {
        address superFollowToken = _superFollows[senderId];

        require(
            superFollowToken == address(0),
            constants.ERR_SUPER_FOLLOW_TOKEN_EXISTED
        );

        bytes memory superFollowTokenInitializeData = abi.encodeWithSelector(
            ISuperFollow.initialize.selector,
            ACL,
            profile,
            address(this),
            string(
                abi.encodePacked(
                    constants.LUMINER_PREFIX,
                    StringsUpgradeable.toString(senderId),
                    constants.SUPER_FOLLOW_NFT_SYMBOL_SUFFIX
                )
            ),
            string(
                abi.encodePacked(
                    constants.LUMINER_PREFIX,
                    StringsUpgradeable.toString(senderId),
                    constants.SUPER_FOLLOW_NFT_NAME_SUFFIX
                )
            )
        );
        superFollowToken = INFTFactory(nftFactory).deploy(
            constants.TAG_ERC721_SUPER_FOLLOW,
            INFTFactory.ProxyMode.beacon,
            superFollowTokenInitializeData
        );
        _superFollows[senderId] = superFollowToken;
        ISuperFollow(superFollowToken).setTokenURI(superFollowURI);

        IHookManager(hookManager).setProfileHook(
            sender,
            senderId,
            IHookManager.Action.superFollow,
            superFollowHook,
            new bytes(0),
            superFollowHookInitializeData
        );
        emit CreateSuperFollowHook(
            sender,
            senderId,
            superFollowToken,
            superFollowHook,
            superFollowTokenInitializeData
        );
    }

    function _setCollectHook(
        address poster,
        uint256 posterId,
        uint256 contentId,
        address collectHook,
        bytes memory collectHookInitializeData
    ) internal {
        address contentToken = _contents[posterId];
        require(
            contentToken != address(0),
            constants.ERR_NOT_FOUND_CONTENT_TOKEN
        );
        require(
            IContent(contentToken).ownerOf(contentId) == poster,
            constants.ERR_PERMISSION_DENIED
        );
        address collectToken = _collects[posterId][contentId];

        require(
            collectToken != address(0),
            constants.ERR_NOT_FOUND_COLLECT_TOKEN
        );

        IHookManager(hookManager).setProfileHook(
            poster,
            posterId,
            IHookManager.Action.collect,
            contentId,
            collectHook,
            abi.encode(contentId),
            collectHookInitializeData
        );
        emit SetCollectHook(
            poster,
            posterId,
            contentToken,
            contentId,
            collectToken,
            collectHook,
            collectHookInitializeData
        );
    }

    function _setCollectURI(
        address sender,
        uint256 senderId,
        uint256 contentId,
        string memory collectURI
    ) internal {
        require(
            _collects[senderId][contentId] != address(0),
            constants.ERR_NO_COLLECTORS
        );
        ICollect(_collects[senderId][contentId]).setTokenURI(collectURI);
        emit SetCollectURI(sender, senderId, contentId, collectURI);
    }

    function _setProfileURI(
        address sender,
        uint256 senderId,
        string memory tokenURI
    ) internal {
        IProfile(profile).setTokenURI(senderId, tokenURI);
        emit SetProfileURI(sender, senderId, tokenURI);
    }

    function _setSuperFollowURI(
        address sender,
        uint256 senderId,
        string calldata superFollowURI
    ) internal {
        address superFollowToken = _superFollows[senderId];
        require(
            superFollowToken != address(0),
            constants.ERR_SUPER_FOLLOW_NOT_ENABLED
        );
        ISuperFollow(superFollowToken).setTokenURI(superFollowURI);
        emit SetSuperFollowURI(sender, senderId, superFollowURI);
    }

    function _setAlbumURI(
        address sender,
        uint256 senderId,
        uint256 albumId,
        string memory albumURI
    ) internal {
        address albumToken = _albums[senderId];
        require(albumToken != address(0), constants.ERR_NOT_FOUND_ALBUM_TOKEN);
        IAlbum(profile).setTokenURI(albumId, albumURI);
        emit SetAlbumURI(sender, senderId, albumId, albumURI);
    }

    function _initAlbumToken(uint256 senderId) internal returns (address) {
        bytes memory albumTokenInitializeData = abi.encodeWithSelector(
            IContent.initialize.selector,
            ACL,
            profile,
            address(this),
            string(
                abi.encodePacked(
                    constants.LUMINER_PREFIX,
                    StringsUpgradeable.toString(senderId),
                    constants.ALBUM_NFT_NAME_SUFFIX
                )
            ),
            string(
                abi.encodePacked(
                    constants.LUMINER_PREFIX,
                    StringsUpgradeable.toString(senderId),
                    constants.ALBUM_NFT_SYMBOL_SUFFIX
                )
            )
        );
        address albumToken = INFTFactory(nftFactory).deploy(
            constants.TAG_ERC721_ALBUM,
            INFTFactory.ProxyMode.beacon,
            albumTokenInitializeData
        );
        _albums[senderId] = albumToken;
        return albumToken;
    }

    function _initAlbumCollect(
        uint256 senderId,
        uint256 albumId,
        string calldata albumCollectURI
    ) internal returns (address) {
        require(
            _albumCollects[senderId][albumId] == address(0),
            constants.ERR_ALBUM_COLLECT_TOKEN_EXISTED
        );

        bytes memory albumCollectTokenInitializeData = abi.encodeWithSelector(
            ICollect.initialize.selector,
            ACL,
            profile,
            address(this),
            string(
                abi.encodePacked(
                    constants.LUMINER_PREFIX,
                    StringsUpgradeable.toString(senderId),
                    constants.ALBUM_COLLECT_NFT_SYMBOL_INFIX,
                    StringsUpgradeable.toString(albumId)
                )
            ),
            string(
                abi.encodePacked(
                    constants.LUMINER_PREFIX,
                    StringsUpgradeable.toString(senderId),
                    constants.ALBUM_COLLECT_NFT_NAME_INFIX,
                    StringsUpgradeable.toString(albumId)
                )
            )
        );
        address albumCollectToken = INFTFactory(nftFactory).deploy(
            constants.TAG_ERC721_ALBUM_COLLECT,
            INFTFactory.ProxyMode.beacon,
            albumCollectTokenInitializeData
        );
        _albumCollects[senderId][albumId] = albumCollectToken;
        IAlbumCollect(albumCollectToken).setTokenURI(albumCollectURI);

        return albumCollectToken;
    }
}