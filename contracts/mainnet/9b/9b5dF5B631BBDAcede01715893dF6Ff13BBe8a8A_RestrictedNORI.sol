// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155PausableUpgradeable is Initializable, ERC1155Upgradeable, PausableUpgradeable {
    function __ERC1155Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC1155Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

/**
 * @title A preset contract that enables pausable access control.
 * @author Nori Inc.
 * @notice This preset contract affords an inheriting contract a set of standard functionality that allows role-based
 * access control and pausable functions.
 * @dev This contract is inherited by most of the other contracts in this project.
 *
 * ##### Inherits:
 *
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](
 * https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 */
abstract contract AccessPresetPausable is
  PausableUpgradeable,
  AccessControlEnumerableUpgradeable
{
  /**
   * @notice Role conferring pausing and unpausing of this contract.
   */
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @notice Pauses all functions that can mutate state.
   * @dev Used to effectively freeze a contract so that no state updates can occur.
   *
   * ##### Requirements:
   *
   * - The caller must have the `PAUSER_ROLE` role.
   */
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @notice Unpauses all token transfers.
   * @dev Re-enables functionality that was paused by `pause`.
   *
   * ##### Requirements:
   *
   * - The caller must have the `PAUSER_ROLE` role.
   */
  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @notice Grants a role to an account.
   * @dev This function allows the role's admin to grant the role to other accounts.
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * @param role The role to grant.
   * @param account The account to grant the role to.
   */
  function _grantRole(bytes32 role, address account)
    internal
    virtual
    override
    whenNotPaused
  {
    super._grantRole({role: role, account: account});
  }

  /**
   * @notice Revokes a role from an account.
   * @dev This function allows the role's admin to revoke the role from other accounts.
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * @param role The role to revoke.
   * @param account The account to revoke the role from.
   */
  function _revokeRole(bytes32 role, address account)
    internal
    virtual
    override
    whenNotPaused
  {
    super._revokeRole({role: role, account: account});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

/**
 * @notice Thrown when two arrays are not of equal length.
 * @param array1Name The name of the first array variable.
 * @param array2Name The name of the second array variable.
 */
error ArrayLengthMismatch(string array1Name, string array2Name);
/**
 * @notice Thrown when an unsupported function is called.
 */
error FunctionDisabled();
/**
 * @notice Thrown when a function that can only be called by the Removal contract is called by any address other than
 * the Removal contract.
 */
error SenderNotRemovalContract();
/**
 * @notice Thrown when a function that can only be called by the Market contract is called by any address other than
 * the Market contract.
 */
error SenderNotMarketContract();
/**
 * @notice Thrown when a non-existent rNORI schedule is requested.
 * @param scheduleId The schedule ID that does not exist.
 */
error NonexistentSchedule(uint256 scheduleId);
/**
 * @notice Thrown when an rNORI schedule already exists for the given `scheduleId`.
 * @param scheduleId The schedule ID that already exists.
 */
error ScheduleExists(uint256 scheduleId);
/**
 * @notice Thrown when rNORI does not have enough unreleased tokens to fulfill a request.
 * @param scheduleId The schedule ID that does not have enough unreleased tokens.
 */
error InsufficientUnreleasedTokens(uint256 scheduleId);
/**
 * @notice Thrown when rNORI does not have enough claimable tokens to fulfill a withdrawal.
 * @param account The account that does not have enough claimable tokens.
 * @param scheduleId The schedule ID that does not have enough claimable tokens.
 */
error InsufficientClaimableBalance(address account, uint256 scheduleId);
/**
 * @notice Thrown when the caller does not have the role required to mint the tokens.
 * @param account the account that does not have the role.
 */
error InvalidMinter(address account);
/**
 * @notice Thrown when the rNORI duration provides is zero.
 */
error InvalidZeroDuration();
/**
 * @notice Thrown when a `removalId` does not have removals for the specified `year`.
 * @param removalId The removal ID that does not have removals for the specified `year`.
 * @param year The year that does not have removals for the specified `removalId`.
 */
error RemovalNotFoundInYear(uint256 removalId, uint256 year);
/**
 * @notice Thrown when the bytes contain unexpected uncapitalized characters.
 * @param country the country that contains unexpected uncapitalized characters.
 * @param subdivision the subdivision that contains unexpected uncapitalized characters.
 */
error UncapitalizedString(bytes2 country, bytes2 subdivision);
/**
 * @notice Thrown when a methodology is greater than the maximum allowed value.
 * @param methodology the methodology that is greater than the maximum allowed value.
 */
error MethodologyTooLarge(uint8 methodology);
/**
 * @notice Thrown when a methodology version is greater than the maximum allowed value.
 * @param methodologyVersion the methodology version that is greater than the maximum allowed value.
 */
error MethodologyVersionTooLarge(uint8 methodologyVersion);
/**
 * @notice Thrown when a removal ID uses an unsupported version.
 * @param idVersion the removal ID version that is not supported.
 */
error UnsupportedIdVersion(uint8 idVersion);
/**
 * @notice Thrown when a caller attempts to transfer a certificate.
 */
error ForbiddenTransferAfterMinting();
/**
 * @notice Thrown when there is insufficient supply in the market.
 */
error InsufficientSupply();
/**
 * @notice Thrown when the caller is not authorized to withdraw.
 */
error UnauthorizedWithdrawal();
/**
 * @notice Thrown when the supply of the market is too low to fulfill a request and the caller is not authorized to
 * access the reserve supply.
 */
error LowSupplyAllowlistRequired();
/**
 * @notice Thrown when the caller is not authorized to perform the action.
 */
error Unauthorized();
/**
 * @notice Thrown when transaction data contains invalid data.
 */
error InvalidData();
/**
 * @notice Thrown when the token specified by `tokenId` is transferred, but the type of transfer is unsupported.
 * @param tokenId The token ID that is used in the invalid transfer.
 */
error InvalidTokenTransfer(uint256 tokenId);
/**
 * @notice Thrown when the specified fee percentage is not a valid value.
 */
error InvalidNoriFeePercentage();
/**
 * @notice Thrown when a token is transferred, but the type of transfer is unsupported.
 */
error ForbiddenTransfer();
/**
 * @notice Thrown when the removal specified by `tokenId` has not been minted yet.
 * @param tokenId The removal token ID that is not minted yet.
 */
error RemovalNotYetMinted(uint256 tokenId);
/**
 * @notice Thrown when the caller specifies the zero address for the Nori fee wallet.
 */
error NoriFeeWalletZeroAddress();
/**
 * @notice Thrown when a holdback percentage greater than 100 is submitted to `mintBatch`.
 */
error InvalidHoldbackPercentage(uint8 holdbackPercentage);
/**
 * @notice Thrown when attempting to list for sale a removal that already belongs to the Certificate or Market
 * contracts.
 */
error RemovalAlreadySoldOrConsigned(uint256 tokenId);
/**
 * @notice Thrown when replacement removal amounts do not sum to the specified total amount being replaced.
 */
error ReplacementAmountMismatch();
/**
 * @notice Thrown when attempting to replace more removals than the size of the deficit.
 */
error ReplacementAmountExceedsNrtDeficit();
/**
 * @notice Thrown when attempting to replace removals on behalf of a certificate that has not been minted yet.
 */
error CertificateNotYetMinted(uint256 tokenId);
/**
 * @notice Thrown when an ERC20 token transfer fails.
 */
error ERC20TransferFailed();

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";

interface IERC20WithPermit is IERC20Upgradeable, IERC20PermitUpgradeable {}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IMarket {
  /**
   * @notice Releases a removal from the market.
   * @dev This function is called by the Removal contract when releasing removals.
   * @param removalId The ID of the removal to release.
   */
  function release(uint256 removalId) external;

  /**
   * @notice Get the RestrictedNORI contract address.
   * @return Returns the address of the RestrictedNORI contract.
   */
  function getRestrictedNoriAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IRemoval {
  /**
   * @notice Get the project ID (which is the removal's schedule ID in RestrictedNORI) for a given removal ID.
   * @param id The removal token ID for which to retrieve the project ID.
   * @return The project ID for the removal token ID.
   */
  function getProjectId(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IRestrictedNORI {
  /**
   * @notice Sets up a restriction schedule with parameters determined from the project ID.
   * @dev Create a schedule for a project ID and set the parameters of the schedule.
   * @param projectId The ID that will be used as this schedule's token ID
   * @param startTime The schedule's start time in seconds since the unix epoch
   * @param methodology The methodology of this project, used to look up correct schedule duration
   * @param methodologyVersion The methodology version, used to look up correct schedule duration
   */
  function createSchedule(
    uint256 projectId,
    uint256 startTime,
    uint8 methodology,
    uint8 methodologyVersion
  ) external;

  /**
   * @notice Check the existence of a schedule.
   * @param scheduleId The token ID of the schedule for which to check existence.
   * @return Returns a boolean indicating whether or not the schedule exists.
   */
  function scheduleExists(uint256 scheduleId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import {UnsupportedIdVersion, MethodologyVersionTooLarge, MethodologyTooLarge, UncapitalizedString} from "./Errors.sol";

/**
 * @notice Decoded removal data.
 * @dev Every removal is minted using this struct. The struct then undergoes bit-packing to create the removal ID.
 * @param idVersion The removal ID version.
 * @param methodology The removal's methodology type.
 * @param methodologyVersion The removal methodology type's version.
 * @param vintage The vintage of the removal.
 * @param country The country that the removal occurred in.
 * @param subdivision The subdivision of the country that the removal occurred in.
 * @param supplierAddress The supplier's original wallet address.
 * @param subIdentifier A unique sub-identifier (e.g., the parcel/field identifier).
 */
struct DecodedRemovalIdV0 {
  uint8 idVersion;
  uint8 methodology;
  uint8 methodologyVersion;
  uint16 vintage;
  bytes2 country;
  bytes2 subdivision;
  address supplierAddress;
  uint32 subIdentifier;
}

/**
 * @title A library for working with Removal IDs.
 * @author Nori Inc.
 * @notice Library encapsulating the logic around encoding and decoding removal IDs.
 * @dev The token IDs used for a given ERC1155 token in Removal encode information about the carbon removal in the
 * following format(s), where the first byte encodes the format version:
 *
 * ##### Removal ID Version 0:
 *
 * | Bytes Label | Description                                                 |
 * | ----------- | ----------------------------------------------------------- |
 * | tokIdV      | The token/removal ID version.                               |
 * | meth&v      | The removal's methodology version.                          |
 * | vintage     | The vintage of the removal.                                 |
 * | country     | The country that the removal occurred in.                   |
 * | subdiv      | The subdivision of the country that the removal occurred in.|
 * | supplier    | The supplier's original wallet address.                     |
 * | subid       | A unique sub-identifier (e.g., the parcel/field identifier).|
 *
 * | tokIdV | meth&v | vintage | country | subdiv  | supplier | subid   |
 * | ------ | ------ | ------- | ------- | ------- | -------- | ------- |
 * | 1 byte | 1 byte | 2 bytes | 2 bytes | 2 bytes | 20 bytes | 4 bytes |
 */
library RemovalIdLib {
  using RemovalIdLib for DecodedRemovalIdV0;

  /**
   * @notice The number of bits per byte.
   */
  uint256 public constant BITS_PER_BYTE = 8;
  /**
   * @notice The number of bytes allocated to the token/removal ID version.
   */
  uint256 public constant ID_VERSION_FIELD_LENGTH = 1;
  /**
   * @notice The number of bytes allocated to the methodology version.
   */
  uint256 public constant METHODOLOGY_DATA_FIELD_LENGTH = 1;
  /**
   * @notice The number of bytes allocated to the vintage.
   */
  uint256 public constant VINTAGE_FIELD_LENGTH = 2;
  /**
   * @notice The number of bytes allocated to the ISO 3166-2 country code.
   */
  uint256 public constant COUNTRY_CODE_FIELD_LENGTH = 2;
  /**
   * @notice The number of bytes allocated to the administrative region of the ISO 3166-2 subdivision.
   */
  uint256 public constant ADMIN1_CODE_FIELD_LENGTH = 2;
  /**
   * @notice The number of bytes allocated to the supplier's original wallet address.
   */
  uint256 public constant ADDRESS_FIELD_LENGTH = 20;
  /**
   * @notice The number of bytes allocated to the sub-identifier.
   */
  uint256 public constant SUBID_FIELD_LENGTH = 4;
  /**
   * @notice The bit offset of the ID version.
   */
  uint256 public constant ID_VERSION_OFFSET = 31;
  /**
   * @notice The bit offset of the methodology data.
   */
  uint256 public constant METHODOLOGY_DATA_OFFSET = 30;
  /**
   * @notice The bit offset of the vintage.
   */
  uint256 public constant VINTAGE_OFFSET = 28;
  /**
   * @notice The bit offset of the country code.
   */
  uint256 public constant COUNTRY_CODE_OFFSET = 26;
  /**
   * @notice The bit offset of the administrative region code.
   */
  uint256 public constant ADMIN1_CODE_OFFSET = 24;
  /**
   * @notice The bit offset of the original supplier wallet address.
   */
  uint256 public constant ADDRESS_OFFSET = 4;
  /**
   * @notice The bit offset of the sub-identifier.
   */
  uint256 public constant SUBID_OFFSET = 0;

  /**
   * @notice Check whether the provided character bytes are capitalized.
   * @param characters the character bytes to check.
   * @return valid True if the provided character bytes are capitalized, false otherwise.
   */
  function isCapitalized(bytes2 characters) internal pure returns (bool valid) {
    assembly {
      let firstCharacter := byte(0, characters)
      let secondCharacter := byte(1, characters)
      valid := and(
        and(lt(firstCharacter, 0x5B), gt(firstCharacter, 0x40)),
        and(lt(secondCharacter, 0x5B), gt(secondCharacter, 0x40))
      )
    }
  }

  /**
   * @notice Validate the removal struct.
   * @param removal The removal struct to validate.
   */
  function validate(DecodedRemovalIdV0 memory removal) internal pure {
    if (removal.idVersion != 0) {
      revert UnsupportedIdVersion({idVersion: removal.idVersion});
    }
    if (removal.methodologyVersion > 15) {
      revert MethodologyVersionTooLarge({
        methodologyVersion: removal.methodologyVersion
      });
    }
    if (removal.methodology > 15) {
      revert MethodologyTooLarge({methodology: removal.methodology});
    }
    if (
      !(isCapitalized({characters: removal.country}) &&
        isCapitalized({characters: removal.subdivision}))
    ) {
      revert UncapitalizedString({
        country: removal.country,
        subdivision: removal.subdivision
      });
    }
  }

  /**
   * @notice Packs data about a removal into a 256-bit removal ID for the removal.
   * @dev Performs some possible validations on the data before attempting to create the ID.
   * @param removal A removal in `DecodedRemovalIdV0` notation.
   * @return The removal ID.
   */
  function createRemovalId(
    DecodedRemovalIdV0 memory removal // todo rename create
  ) internal pure returns (uint256) {
    removal.validate();
    uint256 methodologyData = (removal.methodology << 4) |
      removal.methodologyVersion;
    return
      (uint256(removal.idVersion) << (ID_VERSION_OFFSET * BITS_PER_BYTE)) |
      (uint256(methodologyData) << (METHODOLOGY_DATA_OFFSET * BITS_PER_BYTE)) |
      (uint256(removal.vintage) << (VINTAGE_OFFSET * BITS_PER_BYTE)) |
      (uint256(uint16(removal.country)) <<
        (COUNTRY_CODE_OFFSET * BITS_PER_BYTE)) |
      (uint256(uint16(removal.subdivision)) <<
        (ADMIN1_CODE_OFFSET * BITS_PER_BYTE)) |
      (uint256(uint160(removal.supplierAddress)) <<
        (ADDRESS_OFFSET * BITS_PER_BYTE)) |
      (uint256(removal.subIdentifier) << (SUBID_OFFSET * BITS_PER_BYTE));
  }

  /**
   * @notice Unpacks a V0 removal ID into its component data.
   * @param removalId The removal ID to unpack.
   * @return The removal ID in `DecodedRemovalIdV0` notation.
   */
  function decodeRemovalIdV0(uint256 removalId)
    internal
    pure
    returns (DecodedRemovalIdV0 memory)
  {
    return
      DecodedRemovalIdV0(
        version({removalId: removalId}),
        methodology({removalId: removalId}),
        methodologyVersion({removalId: removalId}),
        vintage({removalId: removalId}),
        countryCode({removalId: removalId}),
        subdivisionCode({removalId: removalId}),
        supplierAddress({removalId: removalId}),
        subIdentifier({removalId: removalId})
      );
  }

  /**
   * @notice Extracts and returns the version field of a removal ID.
   * @param removalId The removal ID to extract the version field from.
   * @return The version field of the removal ID.
   */
  function version(uint256 removalId) internal pure returns (uint8) {
    return
      uint8(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: ID_VERSION_FIELD_LENGTH,
          numBytesOffsetFromRight: ID_VERSION_OFFSET
        })
      );
  }

  /**
   * @notice Extracts and returns the methodology field of a removal ID.
   * @param removalId The removal ID to extract the methodology field from.
   * @return The methodology field of the removal ID.
   */
  function methodology(uint256 removalId) internal pure returns (uint8) {
    return
      uint8(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: METHODOLOGY_DATA_FIELD_LENGTH,
          numBytesOffsetFromRight: METHODOLOGY_DATA_OFFSET
        }) >> 4
      ); // methodology encoded in the first nibble
  }

  /**
   * @notice Extracts and returns the methodology version field of a removal ID.
   * @param removalId The removal ID to extract the methodology version field from.
   * @return The methodology version field of the removal ID.
   */
  function methodologyVersion(uint256 removalId) internal pure returns (uint8) {
    return
      uint8(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: METHODOLOGY_DATA_FIELD_LENGTH,
          numBytesOffsetFromRight: METHODOLOGY_DATA_OFFSET
        }) & (2**4 - 1)
      ); // methodology version encoded in the second nibble
  }

  /**
   * @notice Extracts and returns the vintage field of a removal ID.
   * @param removalId The removal ID to extract the vintage field from.
   * @return The vintage field of the removal ID.
   */
  function vintage(uint256 removalId) internal pure returns (uint16) {
    return
      uint16(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: VINTAGE_FIELD_LENGTH,
          numBytesOffsetFromRight: VINTAGE_OFFSET
        })
      );
  }

  /**
   * @notice Extracts and returns the country code field of a removal ID.
   * @param removalId The removal ID to extract the country code field from.
   * @return The country code field of the removal ID.
   */
  function countryCode(uint256 removalId) internal pure returns (bytes2) {
    return
      bytes2(
        uint16(
          _extractValue({
            removalId: removalId,
            numBytesFieldLength: COUNTRY_CODE_FIELD_LENGTH,
            numBytesOffsetFromRight: COUNTRY_CODE_OFFSET
          })
        )
      );
  }

  /**
   * @notice Extracts and returns the subdivision field of a removal ID.
   * @param removalId The removal ID to extract the subdivision field from.
   * @return The subdivision field of the removal ID.
   */
  function subdivisionCode(uint256 removalId) internal pure returns (bytes2) {
    return
      bytes2(
        uint16(
          _extractValue({
            removalId: removalId,
            numBytesFieldLength: ADMIN1_CODE_FIELD_LENGTH,
            numBytesOffsetFromRight: ADMIN1_CODE_OFFSET
          })
        )
      );
  }

  /**
   * @notice Extracts and returns the supplier address field of a removal ID.
   * @param removalId The removal ID to extract the supplier address field from.
   * @return The supplier address field of the removal ID.
   */
  function supplierAddress(uint256 removalId) internal pure returns (address) {
    return
      address(
        uint160(
          _extractValue({
            removalId: removalId,
            numBytesFieldLength: ADDRESS_FIELD_LENGTH,
            numBytesOffsetFromRight: ADDRESS_OFFSET
          })
        )
      );
  }

  /**
   * @notice Extract and returns the `subIdentifier` field of a removal ID.
   * @param removalId The removal ID to extract the sub-identifier field from.
   * @return The sub-identifier field of the removal ID.
   */
  function subIdentifier(uint256 removalId) internal pure returns (uint32) {
    return
      uint32(
        _extractValue({
          removalId: removalId,
          numBytesFieldLength: SUBID_FIELD_LENGTH,
          numBytesOffsetFromRight: SUBID_OFFSET
        })
      );
  }

  /**
   * @notice Extract a field of the specified length in bytes, at the specified location, from a removal ID.
   * @param removalId The removal ID to extract the field from.
   * @param numBytesFieldLength The number of bytes in the field to extract.
   * @param numBytesOffsetFromRight The number of bytes to offset the field from the right.
   * @return The extracted field value.
   */
  function _extractValue(
    uint256 removalId,
    uint256 numBytesFieldLength,
    uint256 numBytesOffsetFromRight
  ) private pure returns (uint256) {
    bytes32 mask = bytes32(2**(numBytesFieldLength * BITS_PER_BYTE) - 1) <<
      (numBytesOffsetFromRight * BITS_PER_BYTE);
    bytes32 maskedValue = bytes32(removalId) & mask;
    return uint256(maskedValue >> (numBytesOffsetFromRight * BITS_PER_BYTE));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "./AccessPresetPausable.sol";
import "./Errors.sol";
import "./IERC20WithPermit.sol";
import "./IRemoval.sol";
import "./IMarket.sol";
import "./IRestrictedNORI.sol";
import {RestrictedNORILib, Schedule} from "./RestrictedNORILib.sol";
import {RemovalIdLib} from "./RemovalIdLib.sol";

/**
 * @notice View information for the current state of one schedule.
 * @param scheduleTokenId The schedule token ID.
 * @param startTime The start time of the schedule.
 * @param endTime The end time of the schedule.
 * @param totalSupply The total supply of the schedule.
 * @param totalClaimableAmount The total amount that can be claimed from the schedule.
 * @param totalClaimedAmount The total amount that has been claimed from the schedule.
 * @param totalQuantityRevoked The total quantity that has been revoked from the schedule.
 * @param tokenHolders The holders of the schedule.
 */
struct ScheduleSummary {
  uint256 scheduleTokenId;
  uint256 startTime;
  uint256 endTime;
  uint256 totalSupply;
  uint256 totalClaimableAmount;
  uint256 totalClaimedAmount;
  uint256 totalQuantityRevoked;
  address[] tokenHolders;
}

/**
 * @notice View information for one account's ownership of a schedule.
 * @param tokenHolder The token holder.
 * @param scheduleTokenId The schedule token ID.
 * @param balance The balance of the token holder.
 * @param claimableAmount The amount that can be claimed from the schedule by the token holder.
 * @param claimedAmount The amount that has been claimed from the schedule by the token holder.
 * @param quantityRevoked The quantity that has been revoked from the schedule by the token holder.
 */
struct ScheduleDetailForAddress {
  address tokenHolder;
  uint256 scheduleTokenId;
  uint256 balance;
  uint256 claimableAmount;
  uint256 claimedAmount;
  uint256 quantityRevoked;
}

/**
 * @title A wrapped ERC20 token contract for restricting the release of tokens for use as insurance
 * collateral.
 * @author Nori Inc.
 * @notice Based on the mechanics of a wrapped ERC-20 token, this contract layers schedules over the withdrawal
 * functionality to implement _restriction_, a time-based release of tokens that, until released, can be reclaimed
 * by Nori to enforce the permanence guarantee of carbon removals.
 *
 * ##### Behaviors and features:
 *
 * ###### Schedules
 *
 * - _Schedules_ define the release timeline for restricted tokens.
 * - A specific schedule is associated with one ERC1155 token ID and can have multiple token holders.
 *
 * ###### Restricting
 *
 * - _Restricting_ is the process of gradually releasing tokens that may need to be recaptured by Nori in the event
 * that the sequestered carbon for which the tokens were exchanged is found to violate its permanence guarantee.
 * In this case, tokens need to be recaptured to mitigate the loss and make the original buyer whole by using them to
 * purchase new NRTs on their behalf.
 * - Tokens are released linearly from the schedule's start time until its end time. As NRTs are sold, proceeds may
 * be routed to a restriction schedule at any point in the schedule's timeline, thus increasing the total balance of
 * the schedule as well as the released amount at the current timestamp (assuming it's after the schedule start time).
 *
 * ###### Transferring
 *
 * - A given schedule is a logical overlay to a specific 1155 token. This token can have any number of token holders
 * if restricted tokens for a given schedule are minted to multiple addresses, but RestrictedNORI cannot be transferred
 * between addresses. Ownership percentages are relevant and enforced during withdrawal and revocation.
 *
 * ###### Withdrawal
 *
 * - _Withdrawal_ is the process of a token holder claiming the tokens that have been released by the restriction
 * schedule. When tokens are withdrawn, the 1155 schedule token is burned, and the underlying ERC20 token being held
 * by this contract is sent to the address specified by the token holder performing the withdrawal.
 * Tokens are released by a schedule based on the linear release of the schedule's `totalSupply`, but a token holder
 * can only withdraw released tokens in proportion to their percentage ownership of the schedule tokens.
 *
 * ###### Revocation
 *
 * - _Revocation_ is the process of tokens being recaptured by Nori to enforce carbon permanence guarantees.
 * Only unreleased tokens can ever be revoked. When tokens are revoked from a schedule, the current number of released
 * tokens does not decrease, even as the schedule's total supply decreases through revocation (a floor is enforced).
 * When these tokens are revoked, the 1155 schedule token is burned, and the underlying ERC20 token held by this
 * contract is sent to the address specified by Nori. If a schedule has multiple token holders, tokens are burned from
 * each holder in proportion to their total percentage ownership of the schedule.
 *
 * ###### Additional behaviors and features
 *
 * - [Upgradeable](https://docs.openzeppelin.com/contracts/4.x/upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/upgradeable#multiple-inheritance)
 * - [Pausable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable): all functions that mutate state are
 * pausable.
 * - [Role-based access control](https://docs.openzeppelin.com/contracts/4.x/access-control)
 * - `SCHEDULE_CREATOR_ROLE`: Can create restriction schedules without sending the underlying tokens to the contract.
 * The market contract has this role and sets up relevant schedules as removal tokens are minted.
 * - `MINTER_ROLE`: Can call `mint` on this contract, which mints tokens of the correct schedule ID (token ID) for a
 * given removal. The market contract has this role and can mint RestrictedNORI while routing sale proceeds to this
 * contract.
 * - `TOKEN_REVOKER_ROLE`: Can revoke unreleased tokens from a schedule. Only Nori admin wallet should have this role.
 * - `PAUSER_ROLE`: Can pause and unpause the contract.
 * - `DEFAULT_ADMIN_ROLE`: This is the only role that can add/revoke other accounts to any of the roles.
 *
 * ##### Inherits:
 *
 * - [ERC1155Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155)
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/access)
 * - [ContextUpgradeable](https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable)
 * - [Initializable](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable)
 * - [ERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#ERC165)
 *
 * ##### Implements:
 *
 * - [IERC1155Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155)
 * - [IAccessControlEnumerable](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 * - [IERC165Upgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165)
 *
 * ##### Uses:
 *
 * - [RestrictedNORILib](./RestrictedNORILib.md) for `Schedule`.
 * - [EnumerableSetUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet) for
 * `EnumerableSetUpgradeable.UintSet` and `EnumerableSetUpgradeable.AddressSet`.
 * - [MathUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#Math)
 */
contract RestrictedNORI is
  IRestrictedNORI,
  ERC1155SupplyUpgradeable,
  AccessPresetPausable,
  MulticallUpgradeable
{
  using RestrictedNORILib for Schedule;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  /**
   * @notice Role conferring creation of schedules.
   * @dev The Market contract is granted this role after deployments.
   */
  bytes32 public constant SCHEDULE_CREATOR_ROLE =
    keccak256("SCHEDULE_CREATOR_ROLE");

  /**
   * @notice Role conferring sending of underlying ERC20 token to this contract for wrapping.
   * @dev The Market contract is granted this role after deployments.
   */
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @notice Role conferring revocation of restricted tokens.
   * @dev Only Nori admin addresses should have this role.
   */
  bytes32 public constant TOKEN_REVOKER_ROLE = keccak256("TOKEN_REVOKER_ROLE");

  /**
   * @notice Accounting for the per-address current deficit of RestrictedNORI that should be manually minted
   * by a Nori admin to a new, ERC1155-compatible wallet on behalf of the original supplier.
   * @dev In the case of a non-ERC1155-compatible supplier wallet address, minting RestrictedNORI during a
   * purchase will fail and cause an event to be emitted. This data structure tracks the maximum amount
   * of RestrictedNORI that should be remedially minted to a supplier's compatible address to avoid over-
   * minting the wrapper token and failing to have enough RestrictedNORI backed by wrapped NORI.
   * TODO This variable should be used to enforce the maximum number of tokens that can ever be minted manually
   * on behalf of a given address, and should be decremented when this occurs, which is not yet implemented.
   */
  mapping(address => uint256) private _supplierToDeficit;

  /**
   * @notice A mapping of methodology to version to schedule duration.
   */
  mapping(uint256 => mapping(uint256 => uint256))
    private _methodologyAndVersionToScheduleDuration;

  /**
   * @notice A mapping of schedule ID to schedule.
   */
  mapping(uint256 => Schedule) private _scheduleIdToScheduleStruct;

  /**
   * @notice An enumerable set containing all schedule IDs.
   */
  EnumerableSetUpgradeable.UintSet private _allScheduleIds;

  /**
   * @notice The underlying ERC20 token contract for which this contract wraps tokens.
   */
  IERC20WithPermit private _underlyingToken;

  /**
   * @notice The Removal contract that accounts for carbon removal supply.
   */
  IRemoval private _removal;

  /**
   * @notice The Market contract that sells carbon removals.
   */
  IMarket private _market;

  /**
   * @notice Emitted on successful creation of a new schedule.
   * @param projectId The ID of the project for which the schedule was created.
   * @param startTime The start time of the schedule.
   * @param endTime The end time of the schedule.
   */
  event ScheduleCreated(
    uint256 indexed projectId,
    uint256 startTime,
    uint256 endTime
  );

  /**
   * @notice Emitted when unreleased tokens of an active schedule are revoked.
   * @param atTime The time at which the revocation occurred.
   * @param scheduleId The ID of the schedule from which tokens were revoked.
   * @param removalId The ID of the released removal for which tokens were revoked.
   * @param quantity The quantity of tokens revoked.
   * @param scheduleOwners The addresses of the schedule owners from which tokens were revoked.
   * @param quantitiesBurned The quantities of tokens burned from each schedule owner.
   */
  event RevokeTokens(
    uint256 indexed atTime,
    uint256 indexed scheduleId,
    uint256 indexed removalId,
    uint256 quantity,
    address[] scheduleOwners,
    uint256[] quantitiesBurned
  );

  /**
   * @notice Emitted on withdrawal of released tokens.
   * @param from The address from which tokens were withdrawn.
   * @param to The address to which tokens were withdrawn.
   * @param scheduleId The ID of the schedule from which tokens were withdrawn.
   * @param quantity The quantity of tokens withdrawn.
   */
  event ClaimTokens(
    address indexed from,
    address indexed to,
    uint256 indexed scheduleId,
    uint256 quantity
  );

  /**
   * @notice Locks the contract, preventing any future re-initialization.
   * @dev See more [here](https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--).
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initialize the RestrictedNORI contract.
   */
  function initialize() external initializer {
    __ERC1155_init_unchained({
      uri_: "https://nori.com/api/restrictionschedule/{id}.json"
    });
    __Context_init_unchained();
    __ERC165_init_unchained();
    __AccessControl_init_unchained();
    __AccessControlEnumerable_init_unchained();
    __Pausable_init_unchained();
    __ERC1155Supply_init_unchained();
    __Multicall_init_unchained();
    _grantRole({role: DEFAULT_ADMIN_ROLE, account: _msgSender()});
    _grantRole({role: PAUSER_ROLE, account: _msgSender()});
    _grantRole({role: SCHEDULE_CREATOR_ROLE, account: _msgSender()});
    _grantRole({role: TOKEN_REVOKER_ROLE, account: _msgSender()});
    setRestrictionDurationForMethodologyAndVersion({
      methodology: 1,
      methodologyVersion: 0,
      durationInSeconds: 315_569_520 // Seconds in 10 years (accounts for leap years)
    });
  }

  /**
   * @notice Increments the value of `_supplierToDeficit[originalSupplier]` by `amount`.
   * @dev This function is only callable by the Market contract, and is used to account for the number
   * of RestrictedNORI tokens that have failed to be minted to the specified non-ERC1155-compatible wallet
   * during a purchase.
   * @param originalSupplier The original intended recipient of failed RestrictedNORI mint(s).
   * @param amount The amount to increment `_supplierToDeficit` by.
   */
  function incrementDeficitForSupplier(address originalSupplier, uint256 amount)
    external
  {
    if (_msgSender() != address(_market)) {
      revert SenderNotMarketContract();
    }
    _supplierToDeficit[originalSupplier] += amount;
  }

  /**
   * @notice Revokes `amount` of tokens from the project (schedule) associated with the specificed
   * `removalId` and transfers them to `toAccount`.
   * @dev The behavior of this function can be used in two specific ways:
   * 1. To revoke a specific number of tokens as specified by the `amount` parameter.
   * 2. To revoke all remaining revokable tokens in a schedule by specifying 0 as the `amount`.
   *
   * Transfers unreleased tokens in the removal's project's schedule and reduces the total supply
   * of that token. Only unreleased tokens can be revoked from a schedule and no change is made to
   * balances that have released but not yet been claimed.
   * If a token has multiple owners, balances are burned proportionally to ownership percentage,
   * summing to the total amount being revoked.
   * Once the tokens have been revoked, the current released amount can never fall below
   * its current level, even if the linear release schedule of the new amount would cause
   * the released amount to be lowered at the current timestamp (a floor is established).
   *
   * Unlike in the `withdrawFromSchedule` function, here we burn RestrictedNORI
   * from the schedule owner but send that underlying ERC20 token back to Nori's
   * treasury or an address of Nori's choosing (the `toAccount` address).
   * The `claimedAmount` is not changed because this is not a claim operation.
   *
   * Emits a `RevokeTokens` event.
   *
   * ##### Requirements:
   *
   * - Can only be used when the caller has the `TOKEN_REVOKER_ROLE` role.
   * - The requirements of `_beforeTokenTransfer` apply to this function.
   * @param removalId The removal ID that was released and on account of which tokens are being revoked.
   * @param amount The amount to revoke.
   * @param toAccount The account to which the underlying ERC20 token should be sent.
   */
  function revokeUnreleasedTokens(
    uint256 removalId,
    uint256 amount,
    address toAccount
  ) external onlyRole(TOKEN_REVOKER_ROLE) {
    uint256 projectId = _removal.getProjectId({id: removalId});
    Schedule storage schedule = _scheduleIdToScheduleStruct[projectId];
    if (!schedule.doesExist()) {
      revert NonexistentSchedule({scheduleId: projectId});
    }
    uint256 quantityRevocable = schedule.revocableQuantityForSchedule({
      scheduleId: projectId,
      totalSupply: totalSupply(projectId)
    });
    if (!(amount <= quantityRevocable)) {
      revert InsufficientUnreleasedTokens({scheduleId: projectId});
    }
    // amount of zero indicates revocation of all remaining tokens.
    uint256 quantityToRevoke = amount > 0 ? amount : quantityRevocable;
    // burn correct proportion from each token holder
    address[] memory tokenHoldersLocal = schedule.tokenHolders.values();
    uint256[] memory accountBalances = new uint256[](tokenHoldersLocal.length);
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < tokenHoldersLocal.length; ++i) {
        accountBalances[i] = balanceOf({
          account: tokenHoldersLocal[i],
          id: projectId
        });
      }
    }
    uint256[] memory quantitiesToBurnForHolders = new uint256[](
      tokenHoldersLocal.length
    );
    /**
     * Calculate the final holder's quantity to revoke by subtracting the sum of other quantities
     * from the desired total to revoke, thus avoiding any precision rounding errors from affecting
     * the total quantity revoked by up to several wei.
     */
    uint256 cumulativeQuantityToBurn = 0;
    for (uint256 i = 0; i < (tokenHoldersLocal.length - 1); ++i) {
      uint256 quantityToBurnForHolder = _quantityToRevokeForTokenHolder({
        totalQuantityToRevoke: quantityToRevoke,
        scheduleId: projectId,
        schedule: schedule,
        account: tokenHoldersLocal[i],
        balanceOfAccount: accountBalances[i]
      });
      quantitiesToBurnForHolders[i] = quantityToBurnForHolder;
      cumulativeQuantityToBurn += quantityToBurnForHolder;
    }
    quantitiesToBurnForHolders[tokenHoldersLocal.length - 1] =
      quantityToRevoke -
      cumulativeQuantityToBurn;
    for (uint256 i = 0; i < (tokenHoldersLocal.length); ++i) {
      super._burn({
        from: tokenHoldersLocal[i],
        id: projectId,
        amount: quantitiesToBurnForHolders[i]
      });
      schedule.quantitiesRevokedByAddress[
        tokenHoldersLocal[i]
      ] += quantitiesToBurnForHolders[i];
    }
    schedule.totalQuantityRevoked += quantityToRevoke;
    emit RevokeTokens({
      atTime: block.timestamp, // solhint-disable-line not-rely-on-time, this is time-dependent
      removalId: removalId,
      scheduleId: projectId,
      quantity: quantityToRevoke,
      scheduleOwners: tokenHoldersLocal,
      quantitiesBurned: quantitiesToBurnForHolders
    });
    _underlyingToken.transfer({to: toAccount, amount: quantityToRevoke});
  }

  /**
   * @notice Register the underlying assets used by this contract.
   * @dev Register the addresses of the Market, underlying ERC20, and Removal contracts in this contract.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * - Can only be used when the caller has the `DEFAULT_ADMIN_ROLE` role.
   * @param wrappedToken The address of the underlying ERC20 contract for which this contract wraps tokens.
   * @param removal The address of the Removal contract that accounts for Nori's issued carbon removals.
   * @param market The address of the Market contract that sells Nori's issued carbon removals.
   */
  function registerContractAddresses(
    IERC20WithPermit wrappedToken,
    IRemoval removal,
    IMarket market
  ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
    _underlyingToken = IERC20WithPermit(wrappedToken);
    _removal = IRemoval(removal);
    _market = IMarket(market);
  }

  /**
   * @notice Sets up a restriction schedule with parameters determined from the project ID.
   * @dev Create a schedule for a project ID and set the parameters of the schedule.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * - Can only be used when the caller has the `SCHEDULE_CREATOR_ROLE` role.
   * @param projectId The ID that will be used as this schedule's token ID
   * @param startTime The schedule's start time in seconds since the unix epoch
   * @param methodology The methodology of this project, used to look up correct schedule duration
   * @param methodologyVersion The methodology version, used to look up correct schedule duration
   */
  function createSchedule(
    uint256 projectId,
    uint256 startTime,
    uint8 methodology,
    uint8 methodologyVersion
  ) external override whenNotPaused onlyRole(SCHEDULE_CREATOR_ROLE) {
    if (this.scheduleExists({scheduleId: projectId})) {
      revert ScheduleExists({scheduleId: projectId});
    }
    uint256 restrictionDuration = getRestrictionDurationForMethodologyAndVersion({
        methodology: methodology,
        methodologyVersion: methodologyVersion
      });
    _validateSchedule({
      startTime: startTime,
      restrictionDuration: restrictionDuration
    });
    _createSchedule({
      projectId: projectId,
      startTime: startTime,
      restrictionDuration: restrictionDuration
    });
  }

  /**
   * @notice Mint RestrictedNORI tokens for a schedule.
   * @dev Mint `amount` of RestrictedNORI to the schedule ID that corresponds to the provided `removalId`.
   * The schedule ID for this removal is looked up in the Removal contract. The underlying ERC20 asset is
   *  sent to this contract from the buyer by the Market contract during a purchase, so this function only concerns
   * itself with minting the RestrictedNORI token for the correct token ID.
   *
   * ##### Requirements:
   *
   * - Can only be used if the caller has the `MINTER_ROLE` role.
   * - The rules of `_beforeTokenTransfer` apply.
   * @param amount The amount of RestrictedNORI to mint.
   * @param removalId The removal token ID for which proceeds are being restricted.
   */
  function mint(uint256 amount, uint256 removalId) external {
    if (!hasRole({role: MINTER_ROLE, account: _msgSender()})) {
      revert InvalidMinter({account: _msgSender()});
    }
    uint256 projectId = _removal.getProjectId({id: removalId});
    address supplierAddress = RemovalIdLib.supplierAddress({
      removalId: removalId
    });
    super._mint({to: supplierAddress, id: projectId, amount: amount, data: ""});
    _scheduleIdToScheduleStruct[projectId].tokenHolders.add({
      value: supplierAddress
    });
  }

  /**
   * @notice Claim sender's released tokens and withdraw them to `recipient` address.
   *
   * @dev This function burns `amount` of RestrictedNORI for the given schedule ID
   * and transfers `amount` of underlying ERC20 token from the RestrictedNORI contract's
   * balance to `recipient`'s balance.
   * Enforcement of the availability of claimable tokens for the `_burn` call happens in `_beforeTokenTransfer`.
   *
   * Emits a `ClaimTokens` event.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * @param recipient The address receiving the unwrapped underlying ERC20 token.
   * @param scheduleId The schedule from which to withdraw.
   * @param amount The amount to withdraw.
   * @return Whether or not the tokens were successfully withdrawn.
   */
  function withdrawFromSchedule(
    address recipient,
    uint256 scheduleId,
    uint256 amount
  ) external returns (bool) {
    super._burn({from: _msgSender(), id: scheduleId, amount: amount});
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    schedule.totalClaimedAmount += amount;
    schedule.claimedAmountsByAddress[_msgSender()] += amount;
    emit ClaimTokens({
      from: _msgSender(),
      to: recipient,
      scheduleId: scheduleId,
      quantity: amount
    });
    _underlyingToken.transfer({to: recipient, amount: amount});
    return true;
  }

  /**
   * @notice Returns the current deficit of RestrictedNORI tokens that failed to be minted to
   * the given non-ERC1155-compatible wallet and have not yet been replaced manually on behalf
   * of the original supplier.
   * @param originalSupplier The original supplier address for which to retrieve the deficit.
   */
  function getDeficitForAddress(address originalSupplier)
    external
    view
    returns (uint256)
  {
    return _supplierToDeficit[originalSupplier];
  }

  /**
   * @notice Get all schedule IDs.
   * @return Returns an array of all existing schedule IDs, regardless of the status of the schedule.
   */
  function getAllScheduleIds() external view returns (uint256[] memory) {
    uint256[] memory allScheduleIdsArray = new uint256[](
      _allScheduleIds.length()
    );
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < allScheduleIdsArray.length; ++i) {
        allScheduleIdsArray[i] = _allScheduleIds.at({index: i});
      }
    }
    return allScheduleIdsArray;
  }

  /**
   * @notice Returns an account-specific view of the details of a specific schedule.
   * @param account The account for which to provide schedule details.
   * @param scheduleId The token ID of the schedule for which to retrieve details.
   * @return Returns a `ScheduleDetails` struct containing the details of the schedule.
   */
  function getScheduleDetailForAccount(address account, uint256 scheduleId)
    external
    view
    returns (ScheduleDetailForAddress memory)
  {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    return
      ScheduleDetailForAddress({
        tokenHolder: account,
        scheduleTokenId: scheduleId,
        balance: balanceOf({account: account, id: scheduleId}),
        claimableAmount: schedule.claimableBalanceForScheduleForAccount({
          account: account,
          totalSupply: totalSupply({id: scheduleId}),
          balanceOfAccount: balanceOf({account: account, id: scheduleId})
        }),
        claimedAmount: schedule.claimedAmountsByAddress[account],
        quantityRevoked: schedule.quantitiesRevokedByAddress[account]
      });
  }

  /**
   * @notice Batch version of `getScheduleDetailForAccount`.
   * @param account The account for which to provide schedule details.
   * @param scheduleIds The token IDs of the schedules for which to retrieve details.
   * @return Returns an array of `ScheduleDetails` structs containing the details of the schedules
   */
  function batchGetScheduleDetailsForAccount(
    address account,
    uint256[] memory scheduleIds
  ) external view returns (ScheduleDetailForAddress[] memory) {
    ScheduleDetailForAddress[]
      memory scheduleDetails = new ScheduleDetailForAddress[](
        scheduleIds.length
      );
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < scheduleIds.length; ++i) {
        if (_scheduleIdToScheduleStruct[scheduleIds[i]].doesExist()) {
          scheduleDetails[i] = this.getScheduleDetailForAccount({
            account: account,
            scheduleId: scheduleIds[i]
          });
        }
      }
    }
    return scheduleDetails;
  }

  /**
   * @notice Check the existence of a schedule.
   * @param scheduleId The token ID of the schedule for which to check existence.
   * @return Returns a boolean indicating whether or not the schedule exists.
   */
  function scheduleExists(uint256 scheduleId)
    external
    view
    override
    returns (bool)
  {
    return _scheduleIdToScheduleStruct[scheduleId].doesExist();
  }

  /**
   * @notice Returns an array of summary structs for the specified schedules.
   * @param scheduleIds The token IDs of the schedules for which to retrieve details.
   * @return Returns an array of `ScheduleSummary` structs containing the summary of the schedules.
   */
  function batchGetScheduleSummaries(uint256[] calldata scheduleIds)
    external
    view
    returns (ScheduleSummary[] memory)
  {
    ScheduleSummary[] memory scheduleSummaries = new ScheduleSummary[](
      scheduleIds.length
    );
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < scheduleIds.length; ++i) {
        scheduleSummaries[i] = getScheduleSummary({scheduleId: scheduleIds[i]});
      }
    }
    return scheduleSummaries;
  }

  /**
   * @notice Released balance less the total claimed amount at current block timestamp for a schedule.
   * @param scheduleId The token ID of the schedule for which to retrieve details.
   * @return Returns the claimable amount for the schedule.
   */
  function claimableBalanceForSchedule(uint256 scheduleId)
    external
    view
    returns (uint256)
  {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    return
      schedule.claimableBalanceForSchedule({
        scheduleId: scheduleId,
        totalSupply: totalSupply({id: scheduleId})
      });
  }

  /**
   * @notice A single account's claimable balance at current block timestamp for a schedule.
   * @dev Calculations have to consider an account's total proportional claim to the schedule's released tokens,
   * using totals constructed from current balances and claimed amounts, and then subtract anything that
   * account has already claimed.
   * @param scheduleId The token ID of the schedule for which to retrieve details.
   * @param account The account for which to retrieve details.
   * @return Returns the claimable amount for an account's schedule.
   */
  function claimableBalanceForScheduleForAccount(
    uint256 scheduleId,
    address account
  ) external view returns (uint256) {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    return
      schedule.claimableBalanceForScheduleForAccount({
        account: account,
        totalSupply: totalSupply({id: scheduleId}),
        balanceOfAccount: balanceOf({account: account, id: scheduleId})
      });
  }

  /**
   * @notice Get the current number of revocable tokens for a given schedule at the current block timestamp.
   * @param scheduleId The schedule ID for which to revoke tokens.
   * @return Returns the number of revocable tokens for a given schedule at the current block timestamp.
   */
  function revocableQuantityForSchedule(uint256 scheduleId)
    external
    view
    returns (uint256)
  {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    return
      schedule.revocableQuantityForSchedule({
        scheduleId: scheduleId,
        totalSupply: totalSupply({id: scheduleId})
      });
  }

  /**
   * @notice Set the restriction duration for a methodology and version.
   * @dev Set the duration in seconds that should be applied to schedules created on behalf of removals
   * originating from the given methodology and methodology version.
   *
   * ##### Requirements:
   *
   * - Can only be used when the contract is not paused.
   * - Can only be used when the caller has the `DEFAULT_ADMIN_ROLE` role.
   * @param methodology The methodology of carbon removal.
   * @param methodologyVersion The version of the methodology.
   * @param durationInSeconds The duration in seconds that insurance funds should be restricted for this
   * methodology and version.
   */
  function setRestrictionDurationForMethodologyAndVersion(
    uint256 methodology,
    uint256 methodologyVersion,
    uint256 durationInSeconds
  ) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
    if (durationInSeconds == 0) {
      revert InvalidZeroDuration();
    }
    _methodologyAndVersionToScheduleDuration[methodology][
      methodologyVersion
    ] = durationInSeconds;
  }

  /**
   * @notice Get the address of the underlying ERC20 token being wrapped by this contract.
   * @return The address of the underlying ERC20 token being wrapped by this contract.
   */
  function getUnderlyingTokenAddress() public view returns (address) {
    return address(_underlyingToken);
  }

  /**
   * @notice Get a summary for a schedule.
   * @param scheduleId The token ID of the schedule for which to retrieve details.
   * @return Returns the schedule summary.
   */
  function getScheduleSummary(uint256 scheduleId)
    public
    view
    returns (ScheduleSummary memory)
  {
    Schedule storage schedule = _scheduleIdToScheduleStruct[scheduleId];
    uint256 numberOfTokenHolders = schedule.tokenHolders.length();
    address[] memory tokenHoldersArray = new address[](numberOfTokenHolders);
    uint256[] memory scheduleIdArray = new uint256[](numberOfTokenHolders);
    // Skip overflow check as for loop is indexed starting at zero.
    unchecked {
      for (uint256 i = 0; i < numberOfTokenHolders; ++i) {
        tokenHoldersArray[i] = schedule.tokenHolders.at({index: i});
        scheduleIdArray[i] = scheduleId;
      }
    }
    uint256 supply = totalSupply({id: scheduleId});
    return
      ScheduleSummary({
        scheduleTokenId: scheduleId,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        totalSupply: supply,
        totalClaimableAmount: schedule.claimableBalanceForSchedule({
          scheduleId: scheduleId,
          totalSupply: supply
        }),
        totalClaimedAmount: schedule.totalClaimedAmount,
        totalQuantityRevoked: schedule.totalQuantityRevoked,
        tokenHolders: tokenHoldersArray
      });
  }

  /**
   * @dev See [IERC165.supportsInterface](
   * https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165-supportsInterface-bytes4-) for more.
   * @param interfaceId The interface ID to check for support.
   * @return Returns true if the interface is supported, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface({interfaceId: interfaceId});
  }

  /**
   * @notice Get the schedule duration (in seconds) that has been set for a given methodology and methodology version.
   * @param methodology The methodology of carbon removal.
   * @param methodologyVersion The version of the methodology.
   * @return Returns the schedule duration in seconds.
   */
  function getRestrictionDurationForMethodologyAndVersion(
    uint256 methodology,
    uint256 methodologyVersion
  ) public view returns (uint256) {
    return
      _methodologyAndVersionToScheduleDuration[methodology][methodologyVersion];
  }

  /**
   * @notice Token transfers are disabled.
   * @dev Transfer is disabled because keeping track of claimable amounts as tokens are
   * claimed and transferred requires more bookkeeping infrastructure that we don't currently
   * have time to write but may implement in the future.
   */
  function safeTransferFrom(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public pure override {
    revert FunctionDisabled();
  }

  /**
   * @notice Token transfers are disabled.
   * @dev Transfer is disabled because keeping track of claimable amounts as tokens are
   * claimed and transferred requires more bookkeeping infrastructure that we don't currently
   * have time to write but may implement in the future.
   */
  function safeBatchTransferFrom(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public pure override {
    revert FunctionDisabled();
  }

  /**
   * @notice Sets up a schedule for the specified project.
   * @dev Schedules are created when removal tokens are listed for sale in the market contract,
   * so this should only be invoked during `tokensReceived` in the exceptional case that
   * tokens were sent to this contract without a schedule set up.
   *
   * Revert strings are used instead of custom errors here for proper surfacing
   * from within the market contract `onERC1155BatchReceived` hook.
   *
   * Emits a `ScheduleCreated` event.
   * @param projectId The ID that will be used as the new schedule's ID.
   * @param startTime The schedule start time in seconds since the unix epoch.
   * @param restrictionDuration The duration of the schedule in seconds since the unix epoch.
   */
  function _createSchedule(
    uint256 projectId,
    uint256 startTime,
    uint256 restrictionDuration
  ) internal {
    Schedule storage schedule = _scheduleIdToScheduleStruct[projectId];
    schedule.startTime = startTime;
    schedule.endTime = startTime + restrictionDuration;
    _allScheduleIds.add({value: projectId});
    emit ScheduleCreated({
      projectId: projectId,
      startTime: startTime,
      endTime: schedule.endTime
    });
  }

  /**
   * @notice Hook that is called before any token transfer. This includes minting and burning, as well as batched
   * variants.
   * @dev Follows the rules of hooks defined [here](
   * https://docs.openzeppelin.com/contracts/4.x/extending-contracts#rules_of_hooks)
   *
   * See the ERC1155 specific version [here](https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155).
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   * - One of the following must be true:
   *    - The operation is a mint.
   *    - The operation is a burn, which only happens during revocation and withdrawal:
   *      - If the operation is a revocation, that permission is enforced by the `TOKEN_REVOKER_ROLE`.
   *      - If the operation is a withdrawal the burn amount must be <= the sender's claimable balance.
   * @param operator The address which initiated the transfer (i.e. msg.sender).
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param ids The token IDs to transfer.
   * @param amounts The amounts of the token `id`s to transfer.
   * @param data The data to pass to the receiver contract.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155SupplyUpgradeable) whenNotPaused {
    bool isBurning = to == address(0);
    bool isWithdrawing = isBurning && from == operator;
    if (isBurning) {
      // Skip overflow check as for loop is indexed starting at zero.
      unchecked {
        for (uint256 i = 0; i < ids.length; ++i) {
          uint256 id = ids[i];
          Schedule storage schedule = _scheduleIdToScheduleStruct[id];
          if (isWithdrawing) {
            if (
              amounts[i] >
              schedule.claimableBalanceForScheduleForAccount({
                account: from,
                totalSupply: totalSupply({id: id}),
                balanceOfAccount: balanceOf({account: from, id: id})
              })
            ) {
              revert InsufficientClaimableBalance({
                account: from,
                scheduleId: id
              });
            }
          }
          schedule.releasedAmountFloor = schedule
            .releasedBalanceOfSingleSchedule({
              totalSupply: totalSupply({id: id})
            });
        }
      }
    }
    return
      super._beforeTokenTransfer({
        operator: operator,
        from: from,
        to: to,
        ids: ids,
        amounts: amounts,
        data: data
      });
  }

  /**
   * @notice Validates that the schedule start time and duration are non-zero.
   * @param startTime The schedule start time in seconds since the unix epoch.
   * @param restrictionDuration The duration of the schedule in seconds since the unix epoch.
   */
  function _validateSchedule(uint256 startTime, uint256 restrictionDuration)
    internal
    pure
  {
    require(startTime != 0, "rNORI: Invalid start time");
    require(restrictionDuration != 0, "rNORI: duration not set");
  }

  /**
   * @notice Calculates the quantity that should be revoked from a given token holder and schedule based on their
   * proportion of ownership of the schedule's tokens and the total number of tokens being revoked.
   * @param totalQuantityToRevoke The total quantity of tokens being revoked from this schedule.
   * @param scheduleId The schedule (token ID) from which tokens are being revoked.
   * @param schedule The schedule (struct) from which tokens are being revoked.
   * @param account The token holder for which to calculate the quantity that should be revoked.
   * @param balanceOfAccount The total balance of this token ID owned by `account`.
   * @return The quantity of tokens that should be revoked from `account` for the given schedule.
   */
  function _quantityToRevokeForTokenHolder(
    uint256 totalQuantityToRevoke,
    uint256 scheduleId,
    Schedule storage schedule,
    address account,
    uint256 balanceOfAccount
  ) private view returns (uint256) {
    uint256 scheduleTrueTotal = schedule.scheduleTrueTotal({
      totalSupply: totalSupply({id: scheduleId})
    });
    uint256 quantityToRevokeForAccount;
    // avoid division by or of 0
    if (scheduleTrueTotal == 0 || totalQuantityToRevoke == 0) {
      quantityToRevokeForAccount = 0;
    } else {
      uint256 claimedAmountForAccount = schedule.claimedAmountsByAddress[
        account
      ];
      quantityToRevokeForAccount =
        ((claimedAmountForAccount + balanceOfAccount) *
          (totalQuantityToRevoke)) /
        scheduleTrueTotal;
    }
    return quantityToRevokeForAccount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Errors.sol";

/**
 * @notice The internal governing parameters and data for a RestrictedNORI schedule.
 */
struct Schedule {
  uint256 startTime;
  uint256 endTime;
  uint256 totalClaimedAmount;
  uint256 totalQuantityRevoked;
  uint256 releasedAmountFloor;
  EnumerableSetUpgradeable.AddressSet tokenHolders;
  mapping(address => uint256) claimedAmountsByAddress;
  mapping(address => uint256) quantitiesRevokedByAddress;
}

/**
 * @title Library encapsulating the logic around restriction schedules.
 * @author Nori Inc.
 * @notice This library contains logic for restriction schedules used by the RestrictedNORI contract.
 *
 * ##### Behaviors and features:
 *
 * ###### Time
 *
 * All time parameters are in unix time for ease of comparison with `block.timestamp`.
 *
 * ##### Uses:
 *
 * - [EnumerableSetUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet)
 * for `EnumerableSetUpgradeable.UintSet`
 * - RestrictedNORILib for `Schedule`
 */
library RestrictedNORILib {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
  using RestrictedNORILib for Schedule;

  /**
   * @notice Get the total amount of released tokens available at the current block timestamp for the schedule.
   * @dev Takes the maximum of either the calculated linearly released amount based on the schedule parameters,
   * or the released amount floor, which is set at the current released amount whenever the balance of a
   * schedule is decreased through revocation or withdrawal.
   * @param schedule The schedule to calculate the released amount for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The total amount of released tokens available at the current block timestamp for the schedule.
   */
  function releasedBalanceOfSingleSchedule(
    Schedule storage schedule,
    uint256 totalSupply
  ) internal view returns (uint256) {
    return
      MathUpgradeable.max({
        a: schedule.linearReleaseAmountAvailable({totalSupply: totalSupply}),
        b: schedule.releasedAmountFloor
      });
  }

  /**
   * @notice Get the linearly released balance for a single schedule at the current block timestamp, ignoring any
   * released amount floor that has been set for the schedule.
   * @param schedule The schedule to calculate the released amount for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The total amount of released tokens available at the current block timestamp for the schedule.
   */
  function linearReleaseAmountAvailable(
    Schedule storage schedule,
    uint256 totalSupply
  ) internal view returns (uint256) {
    uint256 linearAmountAvailable;
    /* solhint-disable not-rely-on-time, this is time-dependent */
    if (block.timestamp >= schedule.endTime) {
      linearAmountAvailable = schedule.scheduleTrueTotal({
        totalSupply: totalSupply
      });
    } else {
      uint256 rampTotalTime = schedule.endTime - schedule.startTime;
      linearAmountAvailable = block.timestamp < schedule.startTime
        ? 0
        : (schedule.scheduleTrueTotal({totalSupply: totalSupply}) *
          (block.timestamp - schedule.startTime)) / rampTotalTime;
    }
    /* solhint-enable not-rely-on-time */
    return linearAmountAvailable;
  }

  /**
   * @notice Reconstruct a schedule's true total based on claimed and unclaimed tokens.
   * @dev Claiming burns the ERC1155 token, so the true total of a schedule has to be reconstructed
   * from the `totalSupply` and any claimed amount.
   * @param schedule The schedule to calculate the true total for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The true total of the schedule.
   */
  function scheduleTrueTotal(Schedule storage schedule, uint256 totalSupply)
    internal
    view
    returns (uint256)
  {
    return schedule.totalClaimedAmount + totalSupply;
  }

  /**
   * @notice Get the released balance less the total claimed amount at current block timestamp for a schedule.
   * @param schedule The schedule to calculate the claimable amount for.
   * @param schedule The schedule ID to calculate the claimable amount for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The released balance less the total claimed amount at current block timestamp for a schedule.
   */
  function claimableBalanceForSchedule(
    Schedule storage schedule,
    uint256 scheduleId,
    uint256 totalSupply
  ) internal view returns (uint256) {
    if (!schedule.doesExist()) {
      revert NonexistentSchedule({scheduleId: scheduleId});
    }
    return
      schedule.releasedBalanceOfSingleSchedule({totalSupply: totalSupply}) -
      schedule.totalClaimedAmount;
  }

  /**
   * @notice A single account's claimable balance at current `block.timestamp` for a schedule.
   * @dev Calculations have to consider an account's total proportional claim to the schedule's released tokens,
   * using totals constructed from current balances and claimed amounts, and then subtract anything that
   * account has already claimed.
   * @param schedule The schedule to calculate the claimable amount for.
   * @param account The account to calculate the claimable amount for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @param balanceOfAccount The current balance of the account for the schedule.
   * @return The claimable balance for the account at current `block.timestamp` for a schedule.
   */
  function claimableBalanceForScheduleForAccount(
    Schedule storage schedule,
    address account,
    uint256 totalSupply,
    uint256 balanceOfAccount
  ) internal view returns (uint256) {
    uint256 scheduleTotal = schedule.scheduleTrueTotal({
      totalSupply: totalSupply
    });
    uint256 claimableForAccount;
    // avoid division by or of 0
    if (scheduleTotal == 0 || balanceOfAccount == 0) {
      claimableForAccount = 0;
    } else {
      uint256 claimedAmountForAccount = schedule.claimedAmountsByAddress[
        account
      ];
      uint256 linearReleasedAmountFullSchedule = schedule
        .releasedBalanceOfSingleSchedule({totalSupply: totalSupply});
      uint256 accountTrueTotal = balanceOfAccount + claimedAmountForAccount;
      uint256 theoreticalMaxClaimableForAccount = ((linearReleasedAmountFullSchedule *
          accountTrueTotal) / scheduleTotal);
      claimableForAccount =
        theoreticalMaxClaimableForAccount -
        claimedAmountForAccount;
    }
    return claimableForAccount;
  }

  /**
   * @notice Check the revocable balance of a schedule.
   * @param schedule The schedule to check the revocable balance for.
   * @param scheduleId The schedule ID to check the revocable balance for.
   * @param totalSupply The total supply of tokens for the schedule.
   * @return The current number of revocable tokens for a given schedule at the current block timestamp.
   */
  function revocableQuantityForSchedule(
    Schedule storage schedule,
    uint256 scheduleId,
    uint256 totalSupply
  ) internal view returns (uint256) {
    if (!schedule.doesExist()) {
      revert NonexistentSchedule({scheduleId: scheduleId});
    }
    return
      schedule.scheduleTrueTotal({totalSupply: totalSupply}) -
      schedule.releasedBalanceOfSingleSchedule({totalSupply: totalSupply});
  }

  /**
   * @notice Check if a schedule exists.
   * @param schedule The schedule to check.
   * @return True if the schedule exists, false otherwise.
   */
  function doesExist(Schedule storage schedule) internal view returns (bool) {
    return schedule.endTime != 0;
  }
}