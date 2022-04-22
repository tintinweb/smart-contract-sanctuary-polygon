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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./CraftingSettings.sol";

contract Crafting is Initializable, CraftingSettings {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        CraftingSettings.__CraftingSettings_init();
    }

    function startOrEndCrafting(
        uint256[] calldata _craftingIdsToEnd,
        StartCraftingParams[] calldata _startCraftingParams)
    external
    whenNotPaused
    contractsAreSet
    onlyEOA
    {
        require(_craftingIdsToEnd.length > 0 || _startCraftingParams.length > 0, "No inputs provided");

        for(uint256 i = 0; i < _craftingIdsToEnd.length; i++) {
            _endCrafting(_craftingIdsToEnd[i]);
        }

        for(uint256 i = 0; i < _startCraftingParams.length; i++) {
            (uint256 _craftingId, bool _isRecipeInstant) = _startCrafting(_startCraftingParams[i]);
            if(_isRecipeInstant) {
                // No random is required if _isRecipeInstant == true.
                // Safe to pass in 0.
                _endCraftingPostValidation(_craftingId, 0);
            }
        }
    }

    // Verifies recipe info, inputs, and transfers those inputs.
    // Returns if this recipe can be completed instantly
    function _startCrafting(
        StartCraftingParams calldata _craftingParams)
    private
    returns(uint256, bool)
    {
        require(isValidRecipeId(_craftingParams.recipeId), "Unknown recipe");

        CraftingRecipe storage _craftingRecipe = recipeIdToRecipe[_craftingParams.recipeId];
        require(block.timestamp >= _craftingRecipe.recipeStartTime &&
            (_craftingRecipe.recipeStopTime == 0
            || _craftingRecipe.recipeStopTime > block.timestamp), "Recipe has not started or stopped");
        require(!_craftingRecipe.requires721 || _craftingParams.tokenId > 0, "Recipe requires token");

        CraftingRecipeInfo storage _craftingRecipeInfo = recipeIdToInfo[_craftingParams.recipeId];
        require(_craftingRecipe.maxCraftsGlobally == 0
            || _craftingRecipe.maxCraftsGlobally > _craftingRecipeInfo.currentCraftsGlobally,
            "Recipe has reached max number of crafts");

        _craftingRecipeInfo.currentCraftsGlobally++;

        require(_craftingParams.inputs.length == _craftingRecipe.inputs.length,
            "Recipe and passed in input lengths do not match");

        uint256 _craftingId = craftingIdCur;
        craftingIdCur++;

        uint64 _totalTimeReduction;
        uint256 _totalZugReduction;
        uint256 _totalBoneShardReduction;
        (_totalTimeReduction,
            _totalZugReduction,
            _totalBoneShardReduction) = _validateAndTransferInputs(
                _craftingRecipe,
                _craftingParams,
                _craftingId
            );

        _burnERC20s(_craftingRecipe, _totalZugReduction, _totalBoneShardReduction);

        _validateAndTransferNFT(_craftingParams.tokenId, _craftingRecipe.minimumLevelRequired);

        UserCraftingInfo storage _userCrafting = craftingIdToUserCraftingInfo[_craftingId];

        if(_craftingRecipe.timeToComplete > _totalTimeReduction) {
            _userCrafting.timeOfCompletion
                = uint128(block.timestamp + _craftingRecipe.timeToComplete - _totalTimeReduction);
        }

        if(_craftingRecipeInfo.isRandomRequired) {
            _userCrafting.randomRequestKey = randomizer.request();
        }

        _userCrafting.recipeId = _craftingParams.recipeId;
        _userCrafting.tokenId = _craftingParams.tokenId;

        // Indicates if this recipe will complete in the same txn as the startCrafting txn.
        bool _isRecipeInstant = !_craftingRecipeInfo.isRandomRequired && _userCrafting.timeOfCompletion == 0;

        if(!_isRecipeInstant) {
            userToCraftsInProgress[msg.sender].add(_craftingId);
        }

        _emitCraftingStartedEvent(_craftingId);

        return (_craftingId, _isRecipeInstant);
    }

    function _emitCraftingStartedEvent(uint256 _craftingId) private {
        emit CraftingStarted(
            msg.sender,
            _craftingId,
            craftingIdToUserCraftingInfo[_craftingId].timeOfCompletion,
            craftingIdToUserCraftingInfo[_craftingId].recipeId,
            craftingIdToUserCraftingInfo[_craftingId].randomRequestKey,
            craftingIdToUserCraftingInfo[_craftingId].tokenId,
            craftingIdToUserCraftingInfo[_craftingId].suppliedInputs);
    }

    function _validateAndTransferNFT(uint64 _tokenId, uint16 _minimumLevelRequired) private {
        if(_tokenId == 0) {
            return;
        }
        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = _tokenId;

        uint16 _curLevel;

        if(_tokenId < 5051) {
            (,,,,_curLevel,,) = orcs.orcs(_tokenId);
            orcs.pull(msg.sender, _tokenIds);
        } else {
            (,_curLevel,,,,) = allies.allies(_tokenId);
            allies.pull(msg.sender, _tokenIds);
        }

        require(_curLevel >= _minimumLevelRequired, "Haven't reached min level");
    }

    function _burnERC20s(
        CraftingRecipe storage _craftingRecipe,
        uint256 _totalZugReduction,
        uint256 _totalBoneShardReduction)
    private
    {
        uint256 _totalZug;
        if(_craftingRecipe.zugCost > _totalZugReduction) {
            _totalZug = _craftingRecipe.zugCost - _totalZugReduction;
        }

        uint256 _totalBoneShard;
        if(_craftingRecipe.boneShardCost > _totalBoneShardReduction) {
            _totalBoneShard = _craftingRecipe.boneShardCost - _totalBoneShardReduction;
        }

        if(_totalZug > 0) {
            zug.burn(msg.sender, _totalZug);
        }
        if(_totalBoneShard > 0) {
            boneShards.burn(msg.sender, _totalBoneShard);
        }
    }

    // Ensures all inputs are valid and provided if required.
    function _validateAndTransferInputs(
        CraftingRecipe storage _craftingRecipe,
        StartCraftingParams calldata _craftingParams,
        uint256 _craftingId)
    private
    returns(uint64, uint256, uint256)
    {
        uint64 _totalTimeReduction;
        uint256 _totalZugReduction;
        uint256 _totalBoneShardReduction;

        for(uint256 i = 0; i < _craftingRecipe.inputs.length; i++) {
            ItemInfo calldata _startCraftingItemInfo = _craftingParams.inputs[i];
            RecipeInput storage _recipeInput = _craftingRecipe.inputs[i];
            if(_startCraftingItemInfo.collection == address(0) && !_recipeInput.isRequired) {
                continue;
            } else if(_startCraftingItemInfo.collection == address(0)) {
                revert("Supplied no input to required input");
            } else {
                uint256 _optionIndex = recipeIdToInputIndexToCollectionToItemIdToOptionIndex[_craftingParams.recipeId][i][_startCraftingItemInfo.collection][_startCraftingItemInfo.itemId];
                RecipeInputOption storage _inputOption = _recipeInput.inputOptions[_optionIndex];

                require(_inputOption.itemInfo.amount > 0
                    && _inputOption.itemInfo.amount == _startCraftingItemInfo.amount
                    && _inputOption.itemInfo.itemId == _startCraftingItemInfo.itemId
                    && _inputOption.itemInfo.collection == _startCraftingItemInfo.collection, "Bad item input given");

                // Add to reductions
                _totalTimeReduction += _inputOption.timeReduction;
                _totalZugReduction += _inputOption.zugReduction;
                _totalBoneShardReduction += _inputOption.boneShardReduction;

                craftingIdToUserCraftingInfo[_craftingId]
                    .inputCollectionToItemIdToInput[_inputOption.itemInfo.collection][_inputOption.itemInfo.itemId] =
                    UserCraftingInput(
                        _inputOption.itemInfo.amount,
                        _inputOption.isBurned
                    );

                craftingIdToUserCraftingInfo[_craftingId].suppliedInputs.push(_inputOption.itemInfo);

                _transferOrBurnItem(
                    _inputOption.itemInfo,
                    msg.sender,
                    address(this),
                    _inputOption.isBurned);
            }
        }

        return (_totalTimeReduction, _totalZugReduction, _totalBoneShardReduction);
    }

    function _endCrafting(uint256 _craftingId) private {
        require(userToCraftsInProgress[msg.sender].contains(_craftingId), "Invalid crafting id for user");

        // Remove crafting from users in progress crafts.
        userToCraftsInProgress[msg.sender].remove(_craftingId);

        UserCraftingInfo storage _userCraftingInfo = craftingIdToUserCraftingInfo[_craftingId];
        require(block.timestamp >= _userCraftingInfo.timeOfCompletion, "Crafting is not complete");

        uint256 _randomNumber;
        if(_userCraftingInfo.randomRequestKey > 0) {
            _randomNumber = randomizer.getRandom(_userCraftingInfo.randomRequestKey);
            require(_randomNumber > 0, "Random has not been set");
        }

        _endCraftingPostValidation(_craftingId, _randomNumber);
    }

    function _endCraftingPostValidation(uint256 _craftingId, uint256 _randomNumber) private {
        UserCraftingInfo storage _userCraftingInfo = craftingIdToUserCraftingInfo[_craftingId];
        CraftingRecipe storage _craftingRecipe = recipeIdToRecipe[_userCraftingInfo.recipeId];

        uint256 _zugRewarded;
        uint256 _boneShardRewarded;

        CraftingItemOutcome[] memory _itemOutcomes = new CraftingItemOutcome[](_craftingRecipe.outputs.length);

        for(uint256 i = 0; i < _craftingRecipe.outputs.length; i++) {
            // If needed, get a fresh random for the next output decision.
            if(i != 0 && _randomNumber != 0) {
                _randomNumber = uint256(keccak256(abi.encodePacked(_randomNumber, _randomNumber)));
            }

            (uint256 _zugForOutput, uint256 _boneShardForOutput, CraftingItemOutcome memory _outcome) = _determineAndMintOutputs(
                _craftingRecipe.outputs[i],
                _userCraftingInfo,
                _randomNumber);

            _zugRewarded += _zugForOutput;
            _boneShardRewarded += _boneShardForOutput;
            _itemOutcomes[i] = _outcome;
        }

        for(uint256 i = 0; i < _userCraftingInfo.suppliedInputs.length; i++) {
            ItemInfo storage _userCraftingInput = _userCraftingInfo.suppliedInputs[i];
            bool _wasBurned = _userCraftingInfo
                .inputCollectionToItemIdToInput[_userCraftingInput.collection][_userCraftingInput.itemId].wasBurned;

            if(_wasBurned) {
                continue;
            }

            _transferOrBurnItem(
                _userCraftingInput,
                address(this),
                msg.sender,
                false);
        }

        if(_userCraftingInfo.tokenId > 0) {
            if(_userCraftingInfo.tokenId < 5051) {
                orcs.safeTransferFrom(address(this), msg.sender, _userCraftingInfo.tokenId);
            } else {
                orcs.safeTransferFrom(address(this), msg.sender, _userCraftingInfo.tokenId);
            }
        }

        emit CraftingEnded(_craftingId, _zugRewarded, _boneShardRewarded, _itemOutcomes);
    }

    function _determineAndMintOutputs(
        RecipeOutput storage _recipeOutput,
        UserCraftingInfo storage _userCraftingInfo,
        uint256 _randomNumber)
    private
    returns(uint256 _zugForOutput, uint256 _boneShardForOutput, CraftingItemOutcome memory _outcome)
    {
        uint8 _outputAmount = _determineOutputAmount(
            _recipeOutput,
            _userCraftingInfo,
            _randomNumber);

        // Just in case the output amount needed a random. Only would need 16 bits (one random roll).
        _randomNumber >>= 16;

        uint64[] memory _itemIds = new uint64[](_outputAmount);
        uint64[] memory _itemAmounts = new uint64[](_outputAmount);

        for(uint256 i = 0; i < _outputAmount; i++) {
            if(i != 0 && _randomNumber != 0) {
                _randomNumber = uint256(keccak256(abi.encodePacked(_randomNumber, _randomNumber)));
            }

            RecipeOutputOption memory _selectedOption = _determineOutputOption(
                _recipeOutput,
                _userCraftingInfo,
                _randomNumber);
            _randomNumber >>= 16;

            uint64 _itemAmount;
            if(_selectedOption.itemAmountMin == _selectedOption.itemAmountMax) {
                _itemAmount = _selectedOption.itemAmountMax;
            } else {
                uint64 _rangeSelection = uint64(_randomNumber
                    % (_selectedOption.itemAmountMax - _selectedOption.itemAmountMin + 1));

                _itemAmount = _selectedOption.itemAmountMin + _rangeSelection;
            }

            _zugForOutput += _selectedOption.zugAmount;
            _boneShardForOutput += _selectedOption.boneShardAmount;
            _itemIds[i] = _selectedOption.itemId;
            _itemAmounts[i] = _itemAmount;

            _mintOutputOption(_selectedOption, _itemAmount);
        }

        _outcome.itemIds = _itemIds;
        _outcome.itemAmounts = _itemAmounts;
    }

    function _determineOutputOption(
        RecipeOutput storage _recipeOutput,
        UserCraftingInfo storage _userCraftingInfo,
        uint256 _randomNumber)
    private
    view
    returns(RecipeOutputOption memory)
    {
        RecipeOutputOption memory _selectedOption;
        if(_recipeOutput.outputOptions.length == 1) {
            _selectedOption = _recipeOutput.outputOptions[0];
        } else {
            uint256 _outputOptionResult = _randomNumber % MAX_UINT16_PLUS_ONE;
            uint16 _topRange = 0;
            for(uint256 j = 0; j < _recipeOutput.outputOptions.length; j++) {
                RecipeOutputOption storage _outputOption = _recipeOutput.outputOptions[j];
                uint16 _adjustedOdds = _adjustOutputOdds(_outputOption.optionOdds, _userCraftingInfo);
                _topRange += _adjustedOdds;
                if(_outputOptionResult < _topRange) {
                    _selectedOption = _outputOption;
                    break;
                }
            }
        }

        return _selectedOption;
    }

    // Determines how many "rolls" the user has for the passed in output.
    function _determineOutputAmount(
        RecipeOutput storage _recipeOutput,
        UserCraftingInfo storage _userCraftingInfo,
        uint256 _randomNumber
    ) private view returns(uint8) {
        uint8 _outputAmount;
        if(_recipeOutput.outputAmount.length == 1) {
            _outputAmount = _recipeOutput.outputAmount[0];
        } else {
            uint256 _outputResult = _randomNumber % MAX_UINT16_PLUS_ONE;
            uint16 _topRange = 0;

            for(uint256 i = 0; i < _recipeOutput.outputAmount.length; i++) {
                uint16 _adjustedOdds = _adjustOutputOdds(_recipeOutput.outputOdds[i], _userCraftingInfo);
                _topRange += _adjustedOdds;
                if(_outputResult < _topRange) {
                    _outputAmount = _recipeOutput.outputAmount[i];
                    break;
                }
            }
        }
        return _outputAmount;
    }

    function _mintOutputOption(
        RecipeOutputOption memory _selectedOption,
        uint256 _itemAmount)
    private
    {
        if(_itemAmount > 0 && _selectedOption.itemId > 0) {
            dungeonCrawlingItem.mint(
                msg.sender,
                _selectedOption.itemId,
                _itemAmount);
        }
        if(_selectedOption.zugAmount > 0) {
            zug.mint(
                msg.sender,
                _selectedOption.zugAmount);
        }
        if(_selectedOption.boneShardAmount > 0) {
            boneShards.mint(
                msg.sender,
                _selectedOption.boneShardAmount);
        }
    }

    function _adjustOutputOdds(
        OutputOdds storage _outputOdds,
        UserCraftingInfo storage _userCraftingInfo)
    private
    view
    returns(uint16)
    {
        // No boost or didn't use the boost item as an input.
        if(_outputOdds.boostItemId == 0
            || _userCraftingInfo.inputCollectionToItemIdToInput[_outputOdds.boostItemCollection][_outputOdds.boostItemId].itemAmount == 0) {
            return _outputOdds.baseOdds;
        } else {
            return _outputOdds.boostOdds;
        }
    }

    function _transferOrBurnItem(
        ItemInfo memory _itemInfo,
        address _from,
        address _to,
        bool _burn)
    private
    {
        if(_itemInfo.collection == address(etherOrcsItems)) {
            // EOIs have a decimal system. Adjust here.
            uint256 _trueAmount = _itemInfo.amount * 1 ether;
            if(_burn) {
                etherOrcsItems.burn(_from, _itemInfo.itemId, _trueAmount);
            } else {
                etherOrcsItems.safeTransferFrom(
                    _from,
                    _to,
                    _itemInfo.itemId,
                    _trueAmount,
                    "");
            }
        } else if(_itemInfo.collection == address(dungeonCrawlingItem)) {
            if(_burn) {
                dungeonCrawlingItem.burn(_from, _itemInfo.itemId, _itemInfo.amount);
            } else {
                dungeonCrawlingItem.noApprovalSafeTransferFrom(
                    _from,
                    _to,
                    _itemInfo.itemId,
                    _itemInfo.amount);
            }
        } else {
            revert("Unknown item collection");
        }
    }

    function craftingsInProgressForUser(address _user) external view returns(uint256[] memory) {
        return userToCraftsInProgress[_user].values();
    }
}

struct StartCraftingParams {
    uint64 tokenId;
    uint64 recipeId;
    ItemInfo[] inputs;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./CraftingState.sol";

abstract contract CraftingContracts is Initializable, CraftingState {

    function __CraftingContracts_init() internal initializer {
        CraftingState.__CraftingState_init();
    }

    function setContracts(
        address _zugAddress,
        address _dungeonCrawlingItemAddress,
        address _etherOrcsItemsAddress,
        address _boneShardsAddress,
        address _randomizerAddress,
        address _orcsAddress,
        address _alliesAddress)
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE)
    {
        zug = IZug(_zugAddress);
        dungeonCrawlingItem = IDungeonCrawlingItem(_dungeonCrawlingItemAddress);
        etherOrcsItems = IEtherOrcsItems(_etherOrcsItemsAddress);
        boneShards = IBoneShards(_boneShardsAddress);
        randomizer = IRandomizer(_randomizerAddress);
        orcs = IOrcs(_orcsAddress);
        allies = IAllies(_alliesAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(zug) != address(0)
            && address(dungeonCrawlingItem) != address(0)
            && address(etherOrcsItems) != address(0)
            && address(boneShards) != address(0)
            && address(randomizer) != address(0)
            && address(orcs) != address(0)
            && address(allies) != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./CraftingContracts.sol";

abstract contract CraftingSettings is Initializable, CraftingContracts {

    function __CraftingSettings_init() internal initializer {
        CraftingContracts.__CraftingContracts_init();
    }

    function addCraftingRecipe(
        CraftingRecipe calldata _craftingRecipe)
    external
    requiresEitherRole(ADMIN_ROLE, OWNER_ROLE)
    {
        require(_craftingRecipe.recipeStartTime > 0 &&
            (_craftingRecipe.recipeStopTime == 0  || _craftingRecipe.recipeStopTime > _craftingRecipe.recipeStartTime),
            "Bad start or stop time");
        require(recipeNameToRecipeId[_craftingRecipe.recipeName] == 0, "Recipe with name exists");

        uint64 _recipeId = recipeIdCur;
        recipeIdCur++;

        recipeNameToRecipeId[_craftingRecipe.recipeName] = _recipeId;

        // Input validation.
        for(uint256 i = 0; i < _craftingRecipe.inputs.length; i++) {
            RecipeInput calldata _input = _craftingRecipe.inputs[i];

            require(_input.inputOptions.length > 0, "Input must have options");

            for(uint256 j = 0; j < _input.inputOptions.length; j++) {
                RecipeInputOption calldata _inputOption = _input.inputOptions[j];

                require((_inputOption.itemInfo.collection == address(etherOrcsItems)
                    || _inputOption.itemInfo.collection == address(dungeonCrawlingItem))
                    && _inputOption.itemInfo.amount > 0,
                    "Bad collection or amount");

                recipeIdToInputIndexToCollectionToItemIdToOptionIndex[_recipeId][i][_inputOption.itemInfo.collection][_inputOption.itemInfo.itemId] = j;
            }
        }

        // Output validation.
        require(_craftingRecipe.outputs.length > 0, "Recipe requires outputs");

        bool _isRandomRequiredForRecipe;
        for(uint256 i = 0; i < _craftingRecipe.outputs.length; i++) {
            RecipeOutput calldata _output = _craftingRecipe.outputs[i];

            require(_output.outputAmount.length > 0
                && _output.outputAmount.length == _output.outputOdds.length,
                "Bad output amount array lengths");

            // If there is a variable amount for this RecipeOutput or multiple options,
            // a random is required.
            _isRandomRequiredForRecipe = _isRandomRequiredForRecipe
                || _output.outputAmount.length > 1
                || _output.outputOptions.length > 1;

            require(_output.outputOptions.length > 0, "Output must have options");
            for(uint256 j = 0; j < _output.outputOptions.length; j++) {
                RecipeOutputOption calldata _outputOption = _output.outputOptions[j];

                // If there is an amount range, a random is required.
                _isRandomRequiredForRecipe = _isRandomRequiredForRecipe
                    || _outputOption.itemAmountMin != _outputOption.itemAmountMax;
            }
        }

        recipeIdToRecipe[_recipeId] = _craftingRecipe;
        recipeIdToInfo[_recipeId].isRandomRequired = _isRandomRequiredForRecipe;

        emit RecipeAdded(_recipeId, _craftingRecipe);
    }

    function deleteRecipe(
        uint64 _recipeId)
    external
    requiresEitherRole(ADMIN_ROLE, OWNER_ROLE)
    {
        require(isValidRecipeId(_recipeId), "Unknown recipe Id");
        recipeIdToRecipe[_recipeId].recipeStopTime = block.timestamp;

        emit RecipeDeleted(_recipeId);
    }

    function isValidRecipeId(uint64 _recipeId) public view returns(bool) {
        return recipeIdToRecipe[_recipeId].recipeStartTime > 0;
    }

    function recipeIdForName(string calldata _recipeName) external view returns(uint64) {
        return recipeNameToRecipeId[_recipeName];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "./ICrafting.sol";
import "../dungeoncrawlingitem/IDungeonCrawlingItem.sol";
import "../external/IZug.sol";
import "../external/IEtherOrcsItems.sol";
import "../external/IBoneShards.sol";
import "../external/IRandomizer.sol";
import "../external/IOrcs.sol";
import "../external/IAllies.sol";
import "../../shared/UtilitiesUpgradeable.sol";

abstract contract CraftingState is ICrafting, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, UtilitiesUpgradeable {

    event RecipeAdded(uint64 indexed _recipeId, CraftingRecipe _craftingRecipe);
    event RecipeDeleted(uint64 indexed _recipeId);

    event CraftingStarted(
        address indexed _user,
        uint256 indexed _craftingId,
        uint128 _timeOfCompletion,
        uint64 _recipeId,
        uint64 _randomRequestKey,
        uint64 _tokenId,
        ItemInfo[] suppliedInputs);
    event CraftingEnded(
        uint256 _craftingId,
        uint256 _zugRewarded,
        uint256 _boneShardRewarded,
        CraftingItemOutcome[] _itemOutcomes
    );

    uint256 constant MAX_UINT16_PLUS_ONE = 65536;

    IZug public zug;
    IBoneShards public boneShards;
    IDungeonCrawlingItem public dungeonCrawlingItem;
    IEtherOrcsItems public etherOrcsItems;
    IRandomizer public randomizer;
    IOrcs public orcs;
    IAllies public allies;

    uint64 public recipeIdCur;

    mapping(string => uint64) public recipeNameToRecipeId;

    mapping(uint64 => CraftingRecipe) public recipeIdToRecipe;
    mapping(uint64 => CraftingRecipeInfo) public recipeIdToInfo;
    // Ugly type signature.
    // This allows an O(1) lookup if a given combination is an option for an input and the exact amount and index of that option.
    mapping(uint64 => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) internal recipeIdToInputIndexToCollectionToItemIdToOptionIndex;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal userToCraftsInProgress;

    uint256 public craftingIdCur;
    mapping(uint256 => UserCraftingInfo) internal craftingIdToUserCraftingInfo;

    function __CraftingState_init() internal initializer {
        UtilitiesUpgradeable.__Utilities_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();

        craftingIdCur = 1;
        recipeIdCur = 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155ReceiverUpgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

struct UserCraftingInfo {
    uint128 timeOfCompletion;
    uint64 recipeId;
    uint64 randomRequestKey;
    uint64 tokenId;
    ItemInfo[] suppliedInputs;
    mapping(address => mapping(uint256 => UserCraftingInput)) inputCollectionToItemIdToInput;
}

struct UserCraftingInput {
    uint64 itemAmount;
    bool wasBurned;
}

struct CraftingRecipe {
    string recipeName;
    // The time at which this recipe becomes available. Must be greater than 0.
    //
    uint256 recipeStartTime;
    // The time at which this recipe ends. If 0, there is no end.
    //
    uint256 recipeStopTime;
    // The cost of zug, if any, to craft this recipe.
    //
    uint256 zugCost;
    // The cost of bone shard, if any, to craft this recipe.
    //
    uint256 boneShardCost;
    // The number of times this recipe can be crafted globally.
    //
    uint64 maxCraftsGlobally;
    // The amount of time this recipe takes to complete. May be 0, in which case the recipe could be instant (if it does not require a random).
    //
    uint64 timeToComplete;
    // If _requires721, this is the minimum level required to be able to perform this
    //
    uint16 minimumLevelRequired;
    // If this requires an orc or ally.
    //
    bool requires721;
    // The inputs for this recipe.
    //
    RecipeInput[] inputs;
    // The outputs for this recipe.
    //
    RecipeOutput[] outputs;
}

// The info stored in the following struct is either:
// - Calculated at the time of recipe creation
// - Modified as the recipe is crafted over time
//
struct CraftingRecipeInfo {
    // The number of times this recipe has been crafted.
    //
    uint64 currentCraftsGlobally;
    // Indicates if the crafting recipe requires a random number. If it does, it will
    // be split into two transactions. The recipe may still be split into two txns if the crafting recipe takes time.
    //
    bool isRandomRequired;
}

// This struct represents a single input requirement for a recipe.
// This may have multiple inputs that can satisfy the "input".
//
struct RecipeInput {
    RecipeInputOption[] inputOptions;
    // Indicates if this input MUST be satisifed.
    //
    bool isRequired;
}

// This struct represents a single option for a given input requirement for a recipe.
//
struct RecipeInputOption {
    // Either EtherOrcItems or DungeonCrawlingItems.
    //
    ItemInfo itemInfo;
    // Indicates if this input is burned or not.
    //
    bool isBurned;
    // The amount of time using this input will reduce the recipe time by.
    //
    uint64 timeReduction;
    // The amount of zug using this input will reduce the cost by.
    //
    uint256 zugReduction;
    // The amount of bone shard using this input will reduce the cost by.
    //
    uint256 boneShardReduction;
}

// Represents an output of a recipe. This output may have multiple options within it.
// It also may have a chance associated with it.
//
struct RecipeOutput {
    RecipeOutputOption[] outputOptions;
    // This array will indicate how many times the outputOptions are rolled.
    // This may have 0, indicating that this RecipeOutput may not be received.
    //
    uint8[] outputAmount;
    // This array will indicate the odds for each individual outputAmount.
    //
    OutputOdds[] outputOdds;
}

// An individual option within a given output.
//
struct RecipeOutputOption {
    // Dungeon Crawling Item ONLY. May be 0.
    //
    uint64 itemId;
    // The min and max for item amount, if different, is a linear odd with no boosting.
    //
    uint64 itemAmountMin;
    uint64 itemAmountMax;
    uint128 zugAmount;
    uint128 boneShardAmount;
    // The odds this option is picked out of the RecipeOutput group.
    //
    OutputOdds optionOdds;
}

// This is a generic struct to represent the odds for any output. This could be the odds of how many outputs would be rolled,
// or the odds for a given option.
//
struct OutputOdds {
    uint16 baseOdds;
    address boostItemCollection;
    // The itemId to boost these odds. If this shows up ANYWHERE in the inputs, it will be boosted.
    //
    uint64 boostItemId;
    // The odds if the boost collection/item is supplied as an input.
    //
    uint16 boostOdds;
}

struct ItemInfo {
    address collection;
    uint64 itemId;
    uint64 amount;
}

// For event
struct CraftingItemOutcome {
    uint64[] itemIds;
    uint64[] itemAmounts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICrafting {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../shared/IERC1155OnChainUpgradeable.sol";

interface IDungeonCrawlingItem is IERC1155OnChainUpgradeable {
    function mint(address _to, uint256 _id, uint256 _amount) external;

    function mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;

    function burn(address _from, uint256 _id, uint256 _amount) external;

    function burnBatch(address _from, uint256[] calldata _ids, uint256[] calldata _amount) external;

    function noApprovalSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;

    function noApprovalSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAllies {
    // Pulls the given allies to the calling address.
    function pull(address owner, uint256[] calldata ids) external;

    function transfer(address _to, uint256 _tokenId) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function allies(uint256 id)
        external
        view
        returns (
            uint8 class,
            uint16 level,
            uint32 lvlProgress,
            uint16 modF,
            uint8 skillCredits,
            bytes22 details
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBoneShards is IERC20Upgradeable {
    function burn(address _from, uint256 _amount) external;
    function mint(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IEtherOrcsItems {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function burn(address _from, uint256 _id, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOrcs {
    // Pulls the given orcs to the calling address.
    function pull(address _owner, uint256[] calldata _ids) external;

    function transfer(address _to, uint256 _tokenId) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    function orcs(uint256 id)
        external
        view
        returns (
            uint8 body,
            uint8 helm,
            uint8 mainhand,
            uint8 offhand,
            uint16 level,
            uint16 zugModifier,
            uint32 lvlProgress
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRandomizer {
    function request() external returns (uint64 _randomKey);
    function getRandom(uint64 _randomKey) external view returns(uint256 _randomNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IZug is IERC20Upgradeable {
    function burn(address _from, uint256 _amount) external;
    function mint(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155OnChainUpgradeable is IERC1155Upgradeable {
    function propertyValueForToken(uint256 _tokenId, string calldata _propertyName) external view returns(string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// A base class for all contracts.
// Includes basic utility functions, access control, and the ability to pause the contract.
contract UtilitiesUpgradeable is Initializable, AccessControlEnumerableUpgradeable, PausableUpgradeable {

    bytes32 constant OWNER_ROLE = keccak256("OWNER");
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 constant ROLE_GRANTER_ROLE = keccak256("ROLE_GRANTER");

    function __Utilities_init() internal onlyInitializing {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        PausableUpgradeable.__Pausable_init();

        __Utilities_init_unchained();
    }

    function __Utilities_init_unchained() internal onlyInitializing {
        _pause();

        _grantRole(OWNER_ROLE, msg.sender);
    }

    function setPause(bool _shouldPause) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function grantRole(bytes32 _role, address _account) public override requiresEitherRole(ROLE_GRANTER_ROLE, OWNER_ROLE) {
        require(_role != OWNER_ROLE, "Cannot change owner role through grantRole");
        _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) public override requiresEitherRole(ROLE_GRANTER_ROLE, OWNER_ROLE) {
        require(_role != OWNER_ROLE, "Cannot change owner role through grantRole");
        _revokeRole(_role, _account);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    modifier requiresRole(bytes32 _role) {
        require(hasRole(_role, msg.sender), "Does not have required role");
        _;
    }

    modifier requiresEitherRole(bytes32 _roleOption1, bytes32 _roleOption2) {
        require(hasRole(_roleOption1, msg.sender) || hasRole(_roleOption2, msg.sender), "Does not have required role");

        _;
    }
}