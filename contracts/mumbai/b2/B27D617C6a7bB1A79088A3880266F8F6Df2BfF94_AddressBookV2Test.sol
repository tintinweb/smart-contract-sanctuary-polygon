// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
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
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeable is Initializable, ERC721Upgradeable, PausableUpgradeable {
    function __ERC721Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC721Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

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
library StorageSlotUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x5c8a32c1(bytes32 c__0x5c8a32c1) pure {}


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./WheelcoinRoles.sol";

contract AddressBook is Initializable, WheelcoinRoles {
function c_0xbeaa3155(bytes32 c__0xbeaa3155) internal pure {}

    mapping(string => address) private _contracts;

    event AddressSet(string contractName, address addr);

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __AddressBook_init() public initializer {c_0xbeaa3155(0xfea35eec5429a910c90229eac246d0939296d80867b0e5ea4af37007918320e6); /* function */ 

c_0xbeaa3155(0x0d7c360de55be1df70ead0420916e4f0d0e13fd2e3634453f3d3c737fb3631ac); /* line */ 
        c_0xbeaa3155(0xa30be8a7d6e4d1a987370e3a859aef8846131c07f3d857f5be6100d91c99634b); /* statement */ 
WheelcoinRoles.__WheelcoinRoles_init();
    }

    function setAddress(string calldata _contractName, address _addr) public onlyRole(ADMIN_ROLE) {c_0xbeaa3155(0xf9c7f0e169e41b1ebf0f305a5e8b40b10912fc1d782c97fe01a8089a17c36582); /* function */ 

c_0xbeaa3155(0x9657cddf3ec21718883384df57e48f339526ae66be5b166934f794d6d039652f); /* line */ 
        c_0xbeaa3155(0x0fe69ad9b2db72fcfbcdae0bdbc804d0c4284986ec88e6e727748d72ff595c53); /* statement */ 
_contracts[_contractName] = _addr;
c_0xbeaa3155(0x0c800534cf5397c2d11a224f2cfacfc905d11d13220328598d1941e3af02dd11); /* line */ 
        c_0xbeaa3155(0xc54f9d90dba94f8c4c25e1e1641df2007a7e73aafda4ee4b2fbdaed862f833e3); /* statement */ 
emit AddressSet(_contractName, _addr);
    }

    function removeAddress(string calldata _contractName) public onlyRole(ADMIN_ROLE) {c_0xbeaa3155(0xd6b442391b6733e58345389765eca12b4516fac407eb3e484d3e92f172c06039); /* function */ 

c_0xbeaa3155(0x07bf38e32a65d6be09d5cb46847189440400fd7eba4a8ef821480e1240dd6a97); /* line */ 
        delete _contracts[_contractName];
c_0xbeaa3155(0x11304919eefe875415bad00b9a0b7446574f93e485adbafe4762481664a1fa8f); /* line */ 
        c_0xbeaa3155(0xaec12f4eed0d894f6d28a7494f0978e9cd291d384b706c821f6ebb2c88ccde47); /* statement */ 
emit AddressSet(_contractName, address(0));
    }

    function getAddress(string calldata _contractName) public view returns (address _addr) {c_0xbeaa3155(0xe4d7b85f4d78854ac00abf2fe652f82292803f892f887ebe455fce8b3c536615); /* function */ 

c_0xbeaa3155(0x0e1866976bb3ef9afa3551e4477d70423e870fa8bd10b3f9e73355139067d90e); /* line */ 
        c_0xbeaa3155(0x3561bbcb88ff396c7790b372f844e881bf8e843df0838967c04abd78b1fc70e6); /* statement */ 
return _contracts[_contractName];
    }

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __AddressBook_init_unchained() internal onlyInitializing {c_0xbeaa3155(0xfb60144c0f51a0c0f25949f3d3d18bf0a6ffca07cad8e60bc7a7f7ad78e71a5b); /* function */ 

c_0xbeaa3155(0x1afa0e4646d34b7cbaaee16a7dffef925a5456f6323d55300d89c6c60b9a3c33); /* line */ 
        c_0xbeaa3155(0xda7d3fa4e832fdbf8d272bed96924f3fa46c031fa0a937a58e086a500cf47ec2); /* statement */ 
WheelcoinRoles.__WheelcoinRoles_init();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0xfa25477f(bytes32 c__0xfa25477f) pure {}


import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


//This contract is only required to make able retrieving Proxy contract ABI
contract ProxyContract is Initializable, ERC1967UpgradeUpgradeable {
function c_0xa8ce712e(bytes32 c__0xa8ce712e) internal pure {}

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __ProxyContract_init() public initializer {c_0xa8ce712e(0x5bff2896e4a8d1e6c9f406c980f2c10b7cd99403746f7d69cf4407c84780783f); /* function */ 

c_0xa8ce712e(0x0835d509285d2c812ba425a995edf1bac70128464fcd513b6713eb2b4571eadf); /* line */ 
        c_0xa8ce712e(0xe24725524232611346aabe9ebd05ecd5de5165a6f38018bc6e943ba584722b47); /* statement */ 
ERC1967UpgradeUpgradeable.__ERC1967Upgrade_init();
    }

    function getAdmin() public view returns (address) {c_0xa8ce712e(0x3896c2a00e5bde35a3fcaa5a0058f78bb1cc29f9f2898c77eabcfa829ed67efc); /* function */ 

c_0xa8ce712e(0xd8aeaf539dfd04b6e367a44c1d8d9e5c75c5fb7d894c7063ca813a58e728b47f); /* line */ 
        c_0xa8ce712e(0xd785d3c5df26ef0e0c77e8fdfb90b96f83775a652b1085633ed11838172643fa); /* statement */ 
return _getAdmin();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x6f6a52f1(bytes32 c__0x6f6a52f1) pure {}


import "../AddressBook.sol";

contract AddressBookV2Test is AddressBook {
function c_0x7c0bb62f(bytes32 c__0x7c0bb62f) internal pure {}

    mapping(string => address) public someNewMapping;

    event SomeNewMappingSet(string al, address addr);

    // solhint-disable-next-line  func-name-mixedcase, no-empty-blocks, private-vars-leading-underscore
    function __AddressBookV2Test_init() public initializer {c_0x7c0bb62f(0x77ba6e632ce9f35cc32d33ebc65cc7fbfa82dab82cce2b1e3bd65e442fb59541); /* function */ 

c_0x7c0bb62f(0xaeeac8f461fa6dabd50fa2bc69108b5a7570862aa422a1ad85281161f9a72d43); /* line */ 
        c_0x7c0bb62f(0x41fe1632ab9fb26e3825c59e1b11a9aed1ae2f9e35fd81e51fe2211593aa05b6); /* statement */ 
AddressBook.__AddressBook_init_unchained();
    }

    function setToSomeNewMapping(string calldata _alias, address _addr) public onlyRole(ADMIN_ROLE) {c_0x7c0bb62f(0xaaa07f16beca4b094c245e69ca5f130c964654ba370e5a24521ff30e1235a653); /* function */ 

c_0x7c0bb62f(0x69279d3888ffcdd06aed2821865e1e813dc396e70adac289c957aad0b85063d5); /* line */ 
        c_0x7c0bb62f(0xcd1b318f64cf1a1843491784179991fad0030f7856d457d7ed7b211460c8fce9); /* statement */ 
someNewMapping[_alias] = _addr;
c_0x7c0bb62f(0xe649a4dbe7a8b8480fbac116bc219faf4ee61c060e8d25fd6ffb53cbaf7b937d); /* line */ 
        c_0x7c0bb62f(0x5aeffa7f8b4e4620de9844ed7fc9d4c3d73a0a4e0bafb93c65513b1f91a51a3a); /* statement */ 
emit SomeNewMappingSet(_alias, _addr);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0xf5a6c179(bytes32 c__0xf5a6c179) pure {}


import "../tokens/OpenSeaCollection.sol";

contract OpenSeaCollectionChild is Initializable, OpenSeaCollection {
function c_0xd4f6911f(bytes32 c__0xd4f6911f) internal pure {}

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __OpenSeaCollectionChild_init(ContractParams memory _params) public initializer {c_0xd4f6911f(0x31712264abde2b1bc3e151bb14e1ee91918c20960586b440acf30824c050aa00); /* function */ 

c_0xd4f6911f(0xe6c8a750e9c7d8a1c48c2ba83f74fc0867483c99cb266318e20f66ecf42387ff); /* line */ 
        c_0xd4f6911f(0x9a33b5b794cb868641d6a3cdd70971a834ad4c675b0dba905c1aa39020b56a5a); /* statement */ 
OpenSeaCollection.__OpenSeaCollection_init(_params);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x48ec99e2(bytes32 c__0x48ec99e2) pure {}


import "../WheelcoinPausable.sol";

contract WheelcoinPausableChild is Initializable, WheelcoinPausable {
function c_0x65b2e4c5(bytes32 c__0x65b2e4c5) internal pure {}

    function initialize() public initializer {c_0x65b2e4c5(0x9fde6303071bbaf6f7e475df1f4e1bec9aa3ff7b666adab1f3f5931ca2f9ae3f); /* function */ 

c_0x65b2e4c5(0x3372070b1e86b738b4b9eb1f50abbda613220d8742c0077521f8cce805e934d9); /* line */ 
        c_0x65b2e4c5(0x8c8f7e69907f14c997b57c2849980d08d88e3293a2358c07c5d43220ac51e816); /* statement */ 
WheelcoinPausable.__WheelcoinPausable_init();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x547649d2(bytes32 c__0x547649d2) pure {}


import "../WheelcoinProxyAdmin.sol";

contract WheelcoinProxyAdminChild is Initializable, WheelcoinProxyAdmin {
function c_0x3584abd6(bytes32 c__0x3584abd6) internal pure {}

    // solhint-disable-next-line  func-name-mixedcase,  private-vars-leading-underscore
    function __WheelcoinProxyAdminChild_init() public initializer {c_0x3584abd6(0x519d21538218cff0d29980e1aad61528948968b6dc862f124bf150e1e97b56ce); /* function */ 

c_0x3584abd6(0x6b9b28bf3a44cab981ca9b4243545cc1d24930966760d152f15587ca2c017e03); /* line */ 
        c_0x3584abd6(0x10ccf2e23cfe40aa74b186ee24150d6d1906ea9682a0d1f1f09e28e05a71930b); /* statement */ 
WheelcoinProxyAdmin.__WheelcoinProxyAdmin_init_unchained();
    }

    function msgSender() public view returns (address) {c_0x3584abd6(0x4f89a7ea6cc98ef54fa7ec0e09e9b0c75a5e78779d0ab05f0ef63a664e706ddb); /* function */ 

c_0x3584abd6(0xd4495d29ec3bfa02508af86df6fdb7ba2afa6664c0e896f006f9645557364ddf); /* line */ 
        c_0x3584abd6(0xbdc61cade9a0d713653b8c150c25a4d59d477a26b59ba4c90f2ac8d59720f778); /* statement */ 
return _msgSender();
    }
    /*solhint-disable no-unused-vars */
    function msgDataTester(string memory a, uint b, address c) public view returns (bytes calldata) {c_0x3584abd6(0x2bf7abd4ac62cb0b0240300589de1684d5f1defe2cd4f8372f976cbf8e1d2290); /* function */ 

c_0x3584abd6(0x9656a074156ae17e63e5c6b62d2b7200048c1a5a07714f4da84becc35f825746); /* line */ 
        c_0x3584abd6(0x8694bdc559881587d934f7ca1a8103dcff96605212a839208b1c805cec503a08); /* statement */ 
return _msgData();
    }
    /*solhint-enable no-unused-vars */

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0xc07e6219(bytes32 c__0xc07e6219) pure {}


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../WheelcoinRequestsLimits.sol";

contract WheelcoinRequestsLimitsChild is Initializable, WheelcoinRequestsLimits {
function c_0x48eb5ec2(bytes32 c__0x48eb5ec2) internal pure {}


    function initialize() public initializer {c_0x48eb5ec2(0xd50c8ef7f2a8b048b5dac8ae42154265f16290230c9ccd8e652b5cf696006aba); /* function */ 

c_0x48eb5ec2(0xbffd3c335b21d1c75053aff9564c9640ed42dcd993b92787331374690b6fad07); /* line */ 
        c_0x48eb5ec2(0xab45ab49a95053d4c288dfffcda4d0051061637bcaf996b289c8ec96d982ed96); /* statement */ 
__WheelcoinRequestsLimits_init();
    }

    // solhint-disable no-empty-blocks
    function funcA() public checkLimit(msg.sig) {c_0x48eb5ec2(0x82e83a1ef862c0b4ffa782b3eaa91f6082c3563e58b3ea8b276965017ca67848); /* function */ 

    }

    function funcB() public checkLimit(msg.sig) {c_0x48eb5ec2(0x9910caf6baeb14dbe99a2eb323c7f310aadc175b306193abd583c16b63e94780); /* function */ 

    }
    // solhint-enable no-empty-blocks
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x393140f7(bytes32 c__0x393140f7) pure {}


import "../WheelcoinRoles.sol";

contract WheelcoinRolesChild is Initializable, WheelcoinRoles {
function c_0x1a667126(bytes32 c__0x1a667126) internal pure {}

    function initialize() public initializer {c_0x1a667126(0xdbdca5977ab2daf81b8ed932b9b9766fceaebc9fa4b48fffad618422531c9987); /* function */ 

c_0x1a667126(0xa45b1e47c70bd12fbaa9c9045ac71c3caac3d5f21e8076d4ce516d80c791bec6); /* line */ 
        c_0x1a667126(0x6d3a42a3eae7bbbd774cb87478574355e46c5550cde0e355476201f33facd183); /* statement */ 
WheelcoinRoles.__WheelcoinRoles_init();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x6f7a20ca(bytes32 c__0x6f7a20ca) pure {}


import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/* solhint-disable indent */
struct ContractParams {
    string name;
    string description;
    string imageURL;
    address feeRecipient;
    uint256 sellerFeeBasisPoints;
}
/* solhint-enable indent */

library ContractMetadataGenerator {
function c_0xb71a23d4(bytes32 c__0xb71a23d4) internal pure {}

    using Strings for uint256;
    using Strings for address;

    function contractURI(ContractParams memory _params) internal pure returns (string memory) {c_0xb71a23d4(0x06ec864f0b7f76312abaa3c98606c8b5cdb380f9eb7666d7d811a50d731e00b4); /* function */ 

c_0xb71a23d4(0xf87fa8732ce53e72a080318959c198eca04a2b5cfd891e3cb09268a00331f4cd); /* line */ 
        c_0xb71a23d4(0x50e67b421e429b4a07a0d57b5471ba6da575b46ddc4e94372eb1df765ef8623f); /* statement */ 
return _webURIData(_contractMetadata(_params));
    }

    function valid(ContractParams memory _params) internal pure {c_0xb71a23d4(0x39264d50e7b50f407db119a99efdbf210d4da0fb8db2b7dbd85270149b3c6ea3); /* function */ 

c_0xb71a23d4(0x9ebdb21e729dc6d6bc190365e56cb8234ee6b292fcba2ba96f7816e8013f1e0a); /* line */ 
        c_0xb71a23d4(0x12e2b3e326e9dba8ed2f716364507e7e9d3d54eacb94a5098c610542b4329ba5); /* requirePre */ 
c_0xb71a23d4(0xcef1007b447ad92228600d80fa9dd67ac2481f42edff6592020b7a42e71cb79d); /* statement */ 
require(bytes(_params.name).length != 0, "ContractParams: empty name");c_0xb71a23d4(0xb830caae35291e33575315ae10c26a8a342e532a6c3698d74bba78f3db160c5e); /* requirePost */ 

c_0xb71a23d4(0x3863ac7d5f444c60583e4301198639c87cdcab83d7395449684b6f7e087e4f48); /* line */ 
        c_0xb71a23d4(0xf1d57bb2e55cd4ca8f5edf1b3f8cfe09ab07563d47ffdb74c58a4d6a807b3611); /* requirePre */ 
c_0xb71a23d4(0x03d231882f647c992309cb90aa15d7c6977db2120cebcf72f71531034ba6e37e); /* statement */ 
require(bytes(_params.description).length != 0, "ContractParams: empty description");c_0xb71a23d4(0x7011c2391f2837f381ca38e414deb0f7d0a64352d689ad4a0e66d8cb39190d70); /* requirePost */ 

c_0xb71a23d4(0x49a16b88d371e33956ff954f2b605d5521c824e9c7151908a50818a59b16d957); /* line */ 
        c_0xb71a23d4(0x0cbda55ae2a191609c451f4c4c5eafca8728af1c8d27a572207195dcb8b75f1f); /* requirePre */ 
c_0xb71a23d4(0x99bb1063ce01aa4920d7170889a29ad11cd2c752396e77999feccb0b0c1099c4); /* statement */ 
require(bytes(_params.imageURL).length != 0, "ContractParams: empty image");c_0xb71a23d4(0x234619c543816467238014f08aa8fad6a6b37701cb1c95e683f87ce1d1a0600d); /* requirePost */ 

c_0xb71a23d4(0x6478cd8498f0db446ab89f930902d80706100608153cb022cd10c2410909f411); /* line */ 
        c_0xb71a23d4(0x38d1f930935f90967cd744984e1a336e1dce439e91b01acd300c09b4c38ef161); /* requirePre */ 
c_0xb71a23d4(0x92b7c0b1656de30b502a67988f179dfc2f6217572fa54e80b58087d11623e3bc); /* statement */ 
require(_params.sellerFeeBasisPoints <= 2000, "ContractParams: seller fee > 2000");c_0xb71a23d4(0x6da43d0d85aa478eb673d76023e31eb24c36b70a554f842ef6498106ab270ac8); /* requirePost */ 

c_0xb71a23d4(0xeadc12428c3a557e12f5acbd5ad7bead70fb9c8214870ca38e9eb6b98b55c395); /* line */ 
        c_0xb71a23d4(0xa3876d47003a257aae0e73431c80d3bed08562de71feed2ac95ed9bcb71cf846); /* statement */ 
if (_params.sellerFeeBasisPoints > 0) {c_0xb71a23d4(0xeed260d9cf89547d5ed231469130b1af453759c3df93c686dda60d431dc5415a); /* branch */ 

c_0xb71a23d4(0x7a836587773b7692524bd3a62fc49ca49b42dc45fad9ea6746b385172b0ca58e); /* line */ 
            c_0xb71a23d4(0xc3ecd0311024a2f371725ceb3d380b042aca91b6c2aaaa7ed6c11912c70d6d47); /* requirePre */ 
c_0xb71a23d4(0xe662965a561738833ca2262f1357e116b3c72c61832c6f39d381ee448b58ce9d); /* statement */ 
require(_params.feeRecipient != address(0), "ContractParams: empty recipient");c_0xb71a23d4(0x2b2cfb7a59bd2cd2fe1eac770ee316be8f5a20ee886994d26637f57a68011c13); /* requirePost */ 

        }else { c_0xb71a23d4(0xc87313553bdf62daf45cfc4428c104eef990cff7b1453bb25c2b6ca7ced32375); /* branch */ 
}
    }

    function _webURIData(bytes memory _json) private pure returns (string memory) {c_0xb71a23d4(0x1f8a9ff932d16610ab26eaf0617dcf1a6a3e94f94d32e6e3b86a98cc8dc3a3d3); /* function */ 

c_0xb71a23d4(0x77c68d13222560b3ba849294fc58815c9df0fb646a9f42ac165a21cb49468991); /* line */ 
        c_0xb71a23d4(0xd3c8d0f931f1f4a73de430f2797589add8971f7a4ec476cfb29c415bfdb0882a); /* statement */ 
return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_json)));
    }

    function _contractMetadata(ContractParams memory params) private pure returns (bytes memory) {c_0xb71a23d4(0x57ab3449d71f56eea07bf1f94e226f0ddd3285d951dc38ba8cb34054fbcc350c); /* function */ 

c_0xb71a23d4(0xf759458fa44eebe98ef5ef8d60aa2494f907e1dee52685deed6f93e8d3d31d7e); /* line */ 
        c_0xb71a23d4(0x7bf4af3a317831f0f27f60062cc69809cc1ff14ca77a66fe8d4732858ce1205c); /* statement */ 
bytes memory _json = abi.encodePacked(
            "{",
            '"name":"',
            params.name,
            '",',
            '"description":"',
            params.description,
            '",',
            '"image":"',
            params.imageURL,
            '",',
            '"fee_recipient":"',
            params.feeRecipient.toHexString(),
            '",',
            '"seller_fee_basis_points":',
            params.sellerFeeBasisPoints.toString(),
            "}"
        );
c_0xb71a23d4(0xf21c613d0a93b303bc1fbbc65e3a63f575299f34b38b3a3f5015fb3647517b22); /* line */ 
        c_0xb71a23d4(0x11337314f466bdc49a0f637f716a35271e43cf5e5ab6e5bab9847b494da4524a); /* statement */ 
return _json;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0xf7db6fb5(bytes32 c__0xf7db6fb5) pure {}


import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/* solhint-disable indent */
struct MetadataProps {
    string country;
    string city;
}

struct MetadataParams {
    string name;
    string description;
    string imageURL;
    MetadataProps props;
}
/* solhint-enable indent */

library StationsMetadataGenerator {
function c_0x51c6a551(bytes32 c__0x51c6a551) internal pure {}

    using Strings for uint256;

    function tokenURI(MetadataParams memory params) internal pure returns (string memory) {c_0x51c6a551(0x40793838227a8731ce69d05cf26a5c3f92b4526269392afabc282661c0bebdf1); /* function */ 

c_0x51c6a551(0xf1048cccde77aaef5da380356519268d5343f6f706b017d0a4557cc17f5e65b3); /* line */ 
        c_0x51c6a551(0x73dd011d56e0d7bbc603de9125071d88e0a26297036cdc287edd2cd68b927bcf); /* statement */ 
return _webURIData(_jsonMetadata(params));
    }

    function valid(MetadataParams memory params) internal pure returns (bool) {c_0x51c6a551(0xcc3869cf6428c783f9226348211a4095cb8fff8515b00456327875507ba7e4cd); /* function */ 

c_0x51c6a551(0x5722b8e62f1252d38deb97f28c0b21f1b06699327dc535d52c725436b0b10143); /* line */ 
        c_0x51c6a551(0xa1b7dee575c5c60f615958e59b1fdab971d820ea2f7cad5cce8e90c53c06a305); /* statement */ 
if (bytes(params.name).length == 0) {c_0x51c6a551(0x8a034fbe34777d00306edd6c4f1a54584433d45a223943ffcba5b85b57c56be4); /* branch */ 

c_0x51c6a551(0x8660c7a6223dcaef95117779bc4cb85e5cca4f3003019a9a6fff781683f3416e); /* line */ 
            c_0x51c6a551(0xd72932cc0d041ff03f118bd956bb99cda80223e1a12d0a9cbb8afc8931e1839d); /* statement */ 
return false;
        }else { c_0x51c6a551(0x5b4b5da2bc406479e30efdead053106dddadef1c18623f500a1090c2b6040725); /* branch */ 
}
c_0x51c6a551(0x87a16cfc3ad146fdbd01877f33df9c4b7f43ac1d8dc9619eb2a40cbd9caf1d14); /* line */ 
        c_0x51c6a551(0xd21a53dd9e640c476605501f68d55535f63fe711b0b08949b81e32a1c041f5af); /* statement */ 
if (bytes(params.description).length == 0) {c_0x51c6a551(0x855893ef17e38213003fb2570b43ce4c1b2028d95013686a6757c1409b04ab56); /* branch */ 

c_0x51c6a551(0xeca4bc5829ed958ebc285d52ec387435763d452235520ae229063b8fd93489e0); /* line */ 
            c_0x51c6a551(0x1cc507cd8ef9bf2536c5fd001c09fede00497612a13369d6474bdddf85374a84); /* statement */ 
return false;
        }else { c_0x51c6a551(0xebd5618366d365dc016b95a59d57c91e88f32d9b4b1a5d1a5189efea33afe472); /* branch */ 
}
c_0x51c6a551(0xf3c98a426d7a7fff6c4de4d4647a220dcdf519de76e7e78e9c14a4432bc76abd); /* line */ 
        c_0x51c6a551(0x248e858a8d954b5119ac6cb1f377fe2c1e178a12418bfc96649c89bda0d49605); /* statement */ 
if (bytes(params.imageURL).length == 0) {c_0x51c6a551(0x0f1e50ce3f654929392025c29826fd4a30cc9d190abadf3d055315a4ce36b918); /* branch */ 

c_0x51c6a551(0x4ba998b40e7bab7d0434606e042446fa13980a149101d79b075d32f74062eaf2); /* line */ 
            c_0x51c6a551(0x4897d0236b846c4081dd923888dfc8fdd3f9dd62eb1028a61e6d0b6e3e9e1b4f); /* statement */ 
return false;
        }else { c_0x51c6a551(0x0d70025324c51c9ea494815fb89e002795e26db1b9c63b485e657f0d70eed170); /* branch */ 
}
c_0x51c6a551(0x975940e36353fe305e0bd0008ac4da7cb964a5ad9212b468de0b112dca74961b); /* line */ 
        c_0x51c6a551(0x3d69173a1c4287b78cb39c3658a0050d7180d9b655378935745fde90beac84e0); /* statement */ 
if (bytes(params.props.country).length == 0) {c_0x51c6a551(0xac325c854b1d387d298e6fb57fcefea760a1e07875355c3dc3b5910bcbc47323); /* branch */ 

c_0x51c6a551(0x64968c628ffe85a6c47449d5fb8cef87e74acd39309c0cce387aa465a8f125bb); /* line */ 
            c_0x51c6a551(0x2c102194b62dadefb5411537044136f5712e2b851898c4da8a5abb179bc8e466); /* statement */ 
return false;
        }else { c_0x51c6a551(0xee099e81fc4a7987aca2c5a5a47995a9fbcca7f204c53a3950b7c25ef113c599); /* branch */ 
}
c_0x51c6a551(0xa2390fb8e29453cc7a99bbc6f66f41d5b2b48bc0911a433571e33769f398a8f9); /* line */ 
        c_0x51c6a551(0x05b54c5abf3db617ad702eb84cb1706754ef3a910145559d76e060e5a372ba24); /* statement */ 
if (bytes(params.props.city).length == 0) {c_0x51c6a551(0xfa081bbfa945ea7762731a8d1e0002672e31293b44957cd69e4c2d6714b908b5); /* branch */ 

c_0x51c6a551(0x0c46c443e2f30e235768c66672d6bacb6249fbe68907ddf71668e8e296ccff18); /* line */ 
            c_0x51c6a551(0x0a986d7dafb0421479f6677d622ff0dddb2b9ac3c2acebc69d61c8a54d85bc42); /* statement */ 
return false;
        }else { c_0x51c6a551(0x5dc554cdcc931ab866dda39c653203bd4c9acd9306d46845e431e8d802e4770f); /* branch */ 
}
c_0x51c6a551(0x7b31acc81ce4791bb40c7088fea7238cafa0d7d81595ac8aa828575422b6e3cf); /* line */ 
        c_0x51c6a551(0x68f2875b197933e3d9dbb3e49626325393dcb4cace16048ed2f6d142824ff3c7); /* statement */ 
return true;
    }

    function _webURIData(bytes memory _json) private pure returns (string memory) {c_0x51c6a551(0xd619c7521759ea4fd8d7e34397f59eea130eee6b2d6e6ff14738959a263d1bda); /* function */ 

c_0x51c6a551(0xfc0f8663d00d826db5c26c83bd4bb02f8b016eb1cea3a7bb75d9bb6b9563b8ce); /* line */ 
        c_0x51c6a551(0xb43f06515eedfda685eef083ed307a8ca99c94a50ff0c007c8f2aa8e7e5f789a); /* statement */ 
return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_json)));
    }

    function _jsonMetadata(MetadataParams memory params) private pure returns (bytes memory) {c_0x51c6a551(0x6fa7763c4683b447484d90eac3951379c6e1c93faf387f944828107b29d02a95); /* function */ 

c_0x51c6a551(0x1f3cdadae5828f965d6074cd59699a1ca0d666695bc489fa5e202e449a4624b1); /* line */ 
        c_0x51c6a551(0x1a19f6fd2bc59a96f101b1e30435cc4a2d219cbfd2e878539340f8d3b0fb8863); /* statement */ 
bytes memory _json = abi.encodePacked(
            "{",
            '"name":"',
            params.name,
            '",',
            '"description":"',
            params.description,
            '",',
            '"image":"',
            params.imageURL,
            '",',
            '"properties":',
            _propertiesString(params.props),
            "}"
        );
c_0x51c6a551(0x71955899502eed5a936d589513f79c85b0f5fcb75bc38d2033cc7285ab5418d3); /* line */ 
        c_0x51c6a551(0xdaeaffc5ef3c29031db7e8bd6ca8797c285f7ae02474a8de90d2c3056e64e2f2); /* statement */ 
return _json;
    }

    function _propertiesString(MetadataProps memory props) private pure returns (string memory) {c_0x51c6a551(0x3d785f0e0fc2ba0c7128cfca5b54b274bb6404dc3d6da0ed43285216ae10d651); /* function */ 

c_0x51c6a551(0x362f8b1be04d1772d0e315f53cd6d0579a9ef333d8101c635d90c9f80c526d9d); /* line */ 
        c_0x51c6a551(0x96ba60b1862ec8bb2550ba63fb030c526074ac5a85e744ae3ebc33769501d80e); /* statement */ 
bytes memory _props = abi.encodePacked(
            "{",
            '"country":"',
            props.country,
            '",',
            '"city":"',
            props.city,
            '"',
            "}"
        );
c_0x51c6a551(0x9043ebb9bf2e8ccf04119ad82d03bafdc82350f389166812bac6178b909fc98e); /* line */ 
        c_0x51c6a551(0x55893358b781350587b6cc812eff3c2f4e362e95e903b766eba47f72c426f9f6); /* statement */ 
return string(_props);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x87ea8cdb(bytes32 c__0x87ea8cdb) pure {}


import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/* solhint-disable indent */
struct MetadataProps {
    string vehicleType;
    string rarity;
    uint8 level;
}

struct MetadataParams {
    uint256 tokenId;
    string imageURL;
    MetadataProps props;
}
/* solhint-enable indent */

library VehicleMetadataGenerator {
function c_0x93269273(bytes32 c__0x93269273) internal pure {}

    using Strings for uint256;
    using Strings for uint8;
    using Strings for address;

    function tokenURI(MetadataParams memory params) internal pure returns (string memory) {c_0x93269273(0xcb58eba88cb553ba292be074621331ae936b17040c33503986aecd20ab22ebe4); /* function */ 

c_0x93269273(0x686694391520aab5d6ba2b0ee7b74d825e1cd933954223d75a3b959f2be19fb3); /* line */ 
        c_0x93269273(0xf61d8f7912727f84b85aa05d7d2018b3ec7c4da69986ddb141e595cf5b5b00ec); /* statement */ 
return _webURIData(_jsonMetadata(params));
    }

    function _webURIData(bytes memory _json) private pure returns (string memory) {c_0x93269273(0x0761103dceeb855e143eb29f8757c24a782c0b78f3823ea70f9602e0c02a13b2); /* function */ 

c_0x93269273(0x65e86e9b4276376efe5870c7f48d2285292845aafca4845f1f7aa059822f28b9); /* line */ 
        c_0x93269273(0xda922b99bd245761b6e00493334764ec709f75384614a297cb0bc82d2d7b2c25); /* statement */ 
return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_json)));
    }

    function _jsonMetadata(MetadataParams memory params) private pure returns (bytes memory) {c_0x93269273(0xff2036148ef006a611c770dc307418180274db4f424f5d85196372de816e16f3); /* function */ 

c_0x93269273(0x3c782de10826e6c1059f723b5c32d32bf4a5ffbb0e3777911d2a2285abbb355f); /* line */ 
        c_0x93269273(0x5b0611336a1ee12ccf1480f085f959ff32a6c0a9f7bd76b3e2bbc1a163e195c8); /* statement */ 
string memory name = string(abi.encodePacked("Wheelcoin Vehicle #", params.tokenId.toString()));
c_0x93269273(0xe35cb759f71258afc759df7b4f5adeef9deed3e8282d62f82228b1dba51dbe5f); /* line */ 
        c_0x93269273(0x3c065ea084f4963bd8c79f383d12c1d570adadf4b709173128ea30311c52e39d); /* statement */ 
string memory description = "Wheelcoin vehicles item";

c_0x93269273(0x223a28e42ab5131eb2fe8db1b8b5972e2570cdb2151d508b5858a90b74f386ff); /* line */ 
        c_0x93269273(0xc4e4cb726726a465698749f8e195bc4c541ecd6904c9a705f4727e3734a584af); /* statement */ 
bytes memory _json = abi.encodePacked(
            "{",
            '"name":"',
            name,
            '",',
            '"description":"',
            description,
            '",',
            '"image":"',
            params.imageURL,
            '",',
            '"properties":',
            _propertiesString(params.props),
            "}"
        );
c_0x93269273(0xf805b5bf3fa0896c2fda8ca76690ad450a585fc628781aa82ba0aab5f1991465); /* line */ 
        c_0x93269273(0x912f15074609b7a7d3f016c9148b5e1bfe9169ac786dec2cc293d545d79a087d); /* statement */ 
return _json;
    }

    function _propertiesString(MetadataProps memory props) private pure returns (string memory) {c_0x93269273(0x69dce19cdce88def12be41d71dcbf3edcc6237c3ab2ba0328bd6b89f87bab91a); /* function */ 

c_0x93269273(0x47797c3f022be78fb9db0d7ee239f184611809651724790fc0f9d98ab692c817); /* line */ 
        c_0x93269273(0x2ca4321f02582301bc2618b7d381d2f77f94ba2ce2f62b2a96dc94e7323c0128); /* statement */ 
bytes memory _props = abi.encodePacked(
            "{",
            '"level":',
            props.level.toString(),
            ",",
            '"type":"',
            props.vehicleType,
            '",',
            '"rarity":"',
            props.rarity,
            '"',
            "}"
        );
c_0x93269273(0x3038d358775f63e95c763dbeb4945d6dfc0ad84176ebd4380cb4b522130076fa); /* line */ 
        c_0x93269273(0x781d755c00320b20ac294f4c949feca9a283b9d1d4b8fac4c912cd6afc044604); /* statement */ 
return string(_props);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x96bbe5eb(bytes32 c__0x96bbe5eb) pure {}


import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../WheelcoinRoles.sol";
import "./MetadataGenerator/ContractMetadataGenerator.sol";

contract OpenSeaCollection is Initializable, OwnableUpgradeable, WheelcoinRoles, IERC2981Upgradeable {
function c_0x35b8d1ad(bytes32 c__0x35b8d1ad) internal pure {}

    using ContractMetadataGenerator for ContractParams;

    ContractParams public contractMetadata;

    modifier nonEmptyString(string memory _name, string memory _input) {c_0x35b8d1ad(0x17e84c14ffbf81803b96975ccb2eb7c5457084a6e4c0b750eeba4d6500db7a6d); /* function */ 

c_0x35b8d1ad(0x8d07b7b05f3d9c629d412820515fae7d6bb066361432b1644ee8165a75de8b83); /* line */ 
        c_0x35b8d1ad(0x6802a5ede35daa012363e12ed57e60844693b9222f4c944cf41749ebbefc89bf); /* statement */ 
string memory _revertReason = string(abi.encodePacked("OpenSeaCollection: empty ", _name));
c_0x35b8d1ad(0xf9391f497ac525e40561970e6df3e0a852f8607af3bfa9dbf71d4c547b4ed62b); /* line */ 
        c_0x35b8d1ad(0xe1be5f361d4fa1bb912227924d12fb479cdb4c4cf6dbbc2fac2e3a8d039aea3a); /* requirePre */ 
c_0x35b8d1ad(0xe4702108b2506a6e67a1df6514ceab079a04a8fbff592a59ce1ed733cf268462); /* statement */ 
require(bytes(_input).length != 0, _revertReason);c_0x35b8d1ad(0x5903d017340caf5ad75e7cb28336b85c7cfea5ebbc7df04e2ad8d0e378edabbb); /* requirePost */ 

c_0x35b8d1ad(0x24f2f97afe09d6e7c9045f8c508c7189a3ebee396287e9495aec0f7185d0e364); /* line */ 
        _;
    }

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __OpenSeaCollection_init(ContractParams memory _params) public onlyInitializing {c_0x35b8d1ad(0xcb0b6c9ab633c9562c2ca15e09496f38b576f27e1ad1ba8bfa4c61751abd67bf); /* function */ 

c_0x35b8d1ad(0x2f430021efbfd27d82db1ab680565d09159153dcfcfb2df95e2f15d94eff4e9e); /* line */ 
        c_0x35b8d1ad(0xd68b8e1bd2b7b1bbbccbe790ecda5efb73c9d0c3e1ec2426f1aed5b098a56ad0); /* statement */ 
OwnableUpgradeable.__Ownable_init();
c_0x35b8d1ad(0xd526a8a8645aa9d5ec94570e14b2d0b6b626129a9e04ef7bbe3fb7205ee3de50); /* line */ 
        c_0x35b8d1ad(0xbbdc424e3fbb463af75938c79e4381f0102d3b914b97e3fda5d58c3370419a84); /* statement */ 
WheelcoinRoles.__WheelcoinRoles_init();

c_0x35b8d1ad(0xbda2a37c8559d65edcf28d404dfe4201a1aa126c68a443702a55de148e12b392); /* line */ 
        c_0x35b8d1ad(0xb8d525ebba0ca91b656c1341fda7ce2a9419e3d8f8d2c844713fb804eebb3a32); /* statement */ 
if (_params.feeRecipient == address(0)) {c_0x35b8d1ad(0x49128bc8930042aa91dcf356413350667b4fd274fefa1127e0c59d77de6aecd4); /* branch */ 

c_0x35b8d1ad(0x24ff3494505d18a46e8d932e541b43bf7f5578b27ed556d6c8b33b2b34091867); /* line */ 
            c_0x35b8d1ad(0x66aaeadf7be713158aeb3553a9f48519b765d2d7dd3ef79fa4be9a2a335aa165); /* statement */ 
_params.feeRecipient = _msgSender();
        }else { c_0x35b8d1ad(0xf86e7b1172b2018092b2592046be1ec14c4b54541f2b5b00508e6e0e8ae0112e); /* branch */ 
}

c_0x35b8d1ad(0x8980f4a3b7f5188e5a688caf45f59daeff81231079b066a687795e6eb3a6f7cd); /* line */ 
        c_0x35b8d1ad(0x5b1bcb670d267bbb890a40d3127214b99ff1903004c360b9b71b72174ba78f2c); /* statement */ 
_params.valid();
c_0x35b8d1ad(0xfef3a376f5d48c376ea016bdddef2f1bca40212939370b3d04b1744fb44ba000); /* line */ 
        c_0x35b8d1ad(0x7b7e2ef84587ec78f9e8cfaa69561e3ece04003c815299e112ea9b5842eea19b); /* statement */ 
contractMetadata = _params;
    }

    /* @dev Setters*/

    function setName(string memory _name) public onlyRole(ADMIN_ROLE) nonEmptyString("name", _name) {c_0x35b8d1ad(0xf9ac01d469fa675c5013d49f27f48318c9d81d56d8a884703a751b06b039f547); /* function */ 

c_0x35b8d1ad(0xc962cf000b7872991187dc06b5c5a6341a7363c1ee4ecbc07feb4f8127b856b4); /* line */ 
        c_0x35b8d1ad(0x61a003627796cc18f8ae17e71d3935861a5ed92fe380d02abeca6b10fc23dae8); /* statement */ 
contractMetadata.name = _name;
c_0x35b8d1ad(0x288c32ca50cba9c82b99e7f0c574fd79aba276aba75a3c4d95894c15c54fb77c); /* line */ 
        c_0x35b8d1ad(0x2016d39b10ffe255a033dd7bb4b7816a001c582c7c6cbdefacd118287d6d4a9f); /* statement */ 
_afterMetadataChange();
    }

    function setDescription(string memory _description) public onlyRole(ADMIN_ROLE) nonEmptyString("description", _description) {c_0x35b8d1ad(0x856d9e9cd151aa0d616e008d472166ca48e3d005a15f6a42c7f89ca2194381a3); /* function */ 

c_0x35b8d1ad(0xc2cd2c480f15f648357d3922fe8f0783cc49f6905391902b01af0c00be1b8b22); /* line */ 
        c_0x35b8d1ad(0x762243a8ecc5eb666bbd4994138048e7144e300d6ea12c52370cbe54f369dfc7); /* statement */ 
contractMetadata.description = _description;
c_0x35b8d1ad(0xfae2bca883559d47b981e2d23261890a3e68b4d0190e52b42ba1aa7055ef8019); /* line */ 
        c_0x35b8d1ad(0x7f1a6b04e00ac1b0ff7f6374e0d47e7a25b691b82ac8b72151b6b6cd90db3d3e); /* statement */ 
_afterMetadataChange();
    }

    function setImage(string memory _image) public onlyRole(ADMIN_ROLE) nonEmptyString("image", _image) {c_0x35b8d1ad(0x5d84973dee9e80a511460df895cf4a0fac5dd8957b1145ab51b9203a02e96bac); /* function */ 

c_0x35b8d1ad(0x5e642d05faf71ff062af33a94c7d6a84f903203b28f62b584fd938078911ed7d); /* line */ 
        c_0x35b8d1ad(0x01a4b367c4a10e542aee815e0f249726c05bd42784d367362fb63ab162e1acf9); /* statement */ 
contractMetadata.imageURL = _image;
c_0x35b8d1ad(0xbd798b23e3bd55c7d7575b80cad962354085bdb4446f6f475d04c07cbcf2ce2c); /* line */ 
        c_0x35b8d1ad(0xbb3c1810b20a62254ed7c4c0151063f66ce9d880032e7c4045520c6901ad45de); /* statement */ 
_afterMetadataChange();
    }

    function setFeeRecipient(address _recipient) public onlyRole(ADMIN_ROLE) {c_0x35b8d1ad(0x11f6e0a36b975868b0bbede0cab325bee4030aeeaff1d3ed35de69a1cdc62e18); /* function */ 

c_0x35b8d1ad(0x84e1825ddfd63ce917d81a6ec92d114a4040be65a1e3ccc7a88a23d2b261e924); /* line */ 
        c_0x35b8d1ad(0x6d57fb1be4c9f0bb9fbbad97045946dcc397822dc76100f81bc416b15b660f5c); /* statement */ 
contractMetadata.feeRecipient = _recipient;
c_0x35b8d1ad(0xb93129268c903354634cfdfd83bbc0f5a377c9347efd72671a253450339863c9); /* line */ 
        c_0x35b8d1ad(0x1abbc8276cfa67f231ada0aaaab957702a57d02e4f4602b19690b4b755c5fd75); /* statement */ 
_afterMetadataChange();
    }

    function setSellerFeeBasisPoints(uint256 _fee) public onlyRole(ADMIN_ROLE) {c_0x35b8d1ad(0x2a081b4382a82b39941d1a69510e7057b42cead49bc3027f157c0e5fe071d2fb); /* function */ 

c_0x35b8d1ad(0xcd522f031fb9ea4c898ce5ccb868e9e7b6a52a86a46883e9190a5df44f15ce4e); /* line */ 
        c_0x35b8d1ad(0xeac8832956013e5d7db6516f8b4846d68cfdbe884cac2ecf82d65999a03c80e5); /* statement */ 
contractMetadata.sellerFeeBasisPoints = _fee;
c_0x35b8d1ad(0xfe6b16662e2ab9c59c02e30e402f29125ca239e8f0e0ef50b6b3c3a04ed89702); /* line */ 
        c_0x35b8d1ad(0xc90d2682806f8d1a71794f31d6f43ff9f7977dc6d2edd79eca1153a4dca8116c); /* statement */ 
_afterMetadataChange();
    }

    function _afterMetadataChange() internal {c_0x35b8d1ad(0x7d0cecbbceffebc6fafb200e96d0c6309c8dbc9a602783c7b35998d1a234a23c); /* function */ 

c_0x35b8d1ad(0xe7576af970f81a83bf2ba98a384c76f182bdede37706fdc280d93e773726e67c); /* line */ 
        c_0x35b8d1ad(0x2057290cb1c4cab40b3f0cc9083b404e970c91b021d526e7a00cd5b520658542); /* statement */ 
contractMetadata.valid();
    }

    // solhint-disable ordering
    /** @dev EIP2981 royalties implementation. */

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, IERC165Upgradeable) returns (bool) {c_0x35b8d1ad(0xb679947762f91cef055ee7c99073d6a4af7975ffe023569b4e88001ec8e66cb8); /* function */ 

c_0x35b8d1ad(0x8f6b55b6834e4bdfb8a712209f0f95358587e7ee7aa6eb85204ed565d3a77e06); /* line */ 
        c_0x35b8d1ad(0x91453adeeb91b7006920cf599a9cb2fe2905e5378b4663486e778938f55e4925); /* statement */ 
bool a = interfaceId == type(IERC2981Upgradeable).interfaceId;
c_0x35b8d1ad(0x829adec5a037ef5d132d8e3a1dd115896e2109c6dc3840dd3b5e3a37db027566); /* line */ 
        c_0x35b8d1ad(0x4193859f33fca192aaae5285fcc6ee229f2ffbfb56303fd85b0914e7430e4f5e); /* statement */ 
bool b = super.supportsInterface(interfaceId);

c_0x35b8d1ad(0xe254b446fbb636e30572b3b86201ae4d7f9b7844476c37dc499421a6cf73b98e); /* line */ 
        c_0x35b8d1ad(0xa46e5847aaf90f725d61583cab9dfc7f17f4b770da973ad4834bb4a4bd9d6748); /* statement */ 
return (a || b);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(
    // solhint-disable-next-line  no-unused-vars
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {c_0x35b8d1ad(0x7a33db6cab82688ba27adf2c3cc05237a291486a9643b610aa8402b22770a214); /* function */ 

c_0x35b8d1ad(0x5e057dd9c7d698f2400a38471b0d64de9c5f4dad98ab1e18a8666ee81b51dbf3); /* line */ 
        c_0x35b8d1ad(0xa696cc3c66ee0f542008bea86f496660dc2a89be21134cab57e708ed3eec78e9); /* statement */ 
return (contractMetadata.feeRecipient, (_salePrice * contractMetadata.sellerFeeBasisPoints) / 10000);
    }

    /** @dev Contract-level metadata for OpenSea. */
    // Update for collection-specific metadata.
    function contractURI() public view returns (string memory) {c_0x35b8d1ad(0x0ede475c252c95ccb03005451e224b13e748090cca7ce37861ce7862078146e7); /* function */ 

c_0x35b8d1ad(0x2faa40e2c9a55166ef0581d3c5930b96feddd89516b71ef65c711fbae59cbd0f); /* line */ 
        c_0x35b8d1ad(0x3579a419229c6e3ea189c4ac44610b48a0a8727ac7c602534d8cec6854bac072); /* statement */ 
return contractMetadata.contractURI();
    }
    // solhint-enable ordering

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x19e98bfa(bytes32 c__0x19e98bfa) pure {}


import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../WheelcoinPausable.sol";
import "./OpenSeaCollection.sol";
import "./MetadataGenerator/StationsMetadataGenerator.sol";

/* solhint-disable indent*/
struct TokenBalanceEntry {
    uint256 tokenId;
    uint256 balance;
}

struct BalanceByCountryEntry {
    string city;
    TokenBalanceEntry[] balances;
}
/* solhint-enable indent*/


contract Stations is Initializable, OpenSeaCollection, ERC1155PausableUpgradeable, WheelcoinPausable {
function c_0x80051bd1(bytes32 c__0x80051bd1) internal pure {}

    using StationsMetadataGenerator for MetadataParams;

    // ID ==> Token Metadata
    mapping(uint256 => MetadataParams) public metadata;
    // Countries list
    string[] public countries;
    // COUNTRY ==> Cities of Country
    mapping(string => string[]) public countryToCities;
    // CITY ==> Tokens(city==CITY)
    mapping(string => uint256[]) public cityToTokens;

    uint256 public nextTokenId;

    event NewToken(uint256 indexed id, string country, string city);
    event NewCountry(string country);
    event NewCity(string city);

    modifier requireValidMetadata(MetadataParams memory _params) {c_0x80051bd1(0x2ad45a216b96905228279e759ac1238bbc64ff49d3bfcf64611e7ce03f5fab2d); /* function */ 

c_0x80051bd1(0x8070e5a854f59419aba04b6fe6431639b1fe42dddd22e123087daabbef5c9ac4); /* line */ 
        c_0x80051bd1(0x0e72742090434564448c1684c4d863aeada049505a159a490fc277bd909a110d); /* requirePre */ 
c_0x80051bd1(0x9adde874a6c53d7c933bea1aa315652a9e646b648132c9819f0b2ae43806501b); /* statement */ 
require(_params.valid(), "Stations: invalid metadata");c_0x80051bd1(0xf0a58fc13251cf2ea420014b2ee078d5ccc3736fbbe1e7e8108e062da6e27e0a); /* requirePost */ 

c_0x80051bd1(0x280f2086c42d4a6b117872e400f657ba5e936ea3d5f261bc53e110f10ab0bfd7); /* line */ 
        _;
    }

    modifier requireExist(uint256 _id) {c_0x80051bd1(0x25aaa9877e4b1ac7289158b1eea95fc5171594d7de0240ba424ecf52a3937ae5); /* function */ 

c_0x80051bd1(0x297a3ad0a9f314bf8b03932b435af3abee08f4c7dff2d9ca8f060053200ff105); /* line */ 
        c_0x80051bd1(0x170a893eb6d8060bc6a1336c7e4d44b9ba72b3de0852a53e06ea70a7cc5569fb); /* requirePre */ 
c_0x80051bd1(0xc4c7e7f6673af6c09ae017148738cafb2504186c827ee38a0602a3979f097213); /* statement */ 
require(exist(_id), "Stations: token doesn't exists");c_0x80051bd1(0x2326888a8f58f481774e4a87ab6546dda85dc23643fa07b25465c9dc1d4332db); /* requirePost */ 

c_0x80051bd1(0xc12da7e4e7882481ff58f1f682331a3dfe675f4c67e8d8bfbd349724f10fbda1); /* line */ 
        _;
    }

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __Stations_init(ContractParams memory _contractParams) public initializer onlyInitializing {c_0x80051bd1(0x19830357faa6a67d3f92b96bf2bed6550986ca0f090ac0a56e69d22f857feb60); /* function */ 

c_0x80051bd1(0x4d159ec08376d8515599fd62218296673a26e8a76bf77031243ab42ea9d460d7); /* line */ 
        c_0x80051bd1(0xee412030f37304f05e46a784ad52813176f18a6fe986f3dd56830303a49f718b); /* statement */ 
OpenSeaCollection.__OpenSeaCollection_init(_contractParams);
c_0x80051bd1(0x25808b75526b08ae3bfe6cb781634437599cd81a717d5593e0acd73cb7f581ae); /* line */ 
        c_0x80051bd1(0x1895f1c938c08ce0bfd2d214c699785c6ce33814e868372d0f8b7ea81a08e173); /* statement */ 
WheelcoinPausable.__WheelcoinPausable_init();
c_0x80051bd1(0xa39084b0c6964c4d867e6436f806d91fd61bdd01634489b28380ecdd0d57a112); /* line */ 
        c_0x80051bd1(0x4b175be2555cfc106662efba73b149d18dd2db56a58d586dca73bee92ec5c398); /* statement */ 
ERC1155Upgradeable.__ERC1155_init("");
c_0x80051bd1(0x99fa8a8ae2da59034999bda486dec43607e573ab2e534114ec74439f907d35c7); /* line */ 
        c_0x80051bd1(0xf78913ad0e417cb775c88962691a01e262d7bb85a1815996fc027d0e406a186a); /* statement */ 
ERC1155PausableUpgradeable.__ERC1155Pausable_init();

c_0x80051bd1(0x5aba5418815cac2412f6dc7c8ab05ef7a679da13471bf668f404dc3485059abc); /* line */ 
        c_0x80051bd1(0xc66fd7ddfecb795b262ad1477322dda77fd5864db3ee4dfda2faeba3db23e9ec); /* statement */ 
nextTokenId = 1;
    }

    function registerToken(
        MetadataParams memory _md
    ) public onlyRole(ADMIN_ROLE) requireValidMetadata(_md) whenNotPaused {c_0x80051bd1(0x38ae70b5f92fda06f0d1b0b686a7c4ab2dd7e10c65316d71bd42bd98ee387727); /* function */ 

c_0x80051bd1(0x1a5f05f4f9c076e979b2e1fa472eaa5b8d1a573d57207a2bef643af8f15e18e6); /* line */ 
        c_0x80051bd1(0xb19e1df1727d56339c4b01be557d2ceaeb9462991290c43f08c0c527aa4c08e4); /* statement */ 
uint256 _id = nextTokenId;

c_0x80051bd1(0xffd6ec819f8cd0ef90625edf63f8466f31807694936f3687536b15b5f6258eda); /* line */ 
        c_0x80051bd1(0x51b7631ee0ae755d1fc077c8ebe32162e8b4fc418f490921e1b93be7478c7530); /* statement */ 
metadata[_id] = _md;
c_0x80051bd1(0xfdf6273bafe6258c3587cc4b56f509f8cd9f5b3e6b82195539530a467e3ccdfb); /* line */ 
        c_0x80051bd1(0x8f09c8f97cc9d10fced6ec652f8b2cf028c6ea9ac89a905292dfe31eb325e67f); /* statement */ 
_appendCountry(_md.props.country);
c_0x80051bd1(0x9151dc098e24286b68ad2e05cd4edbf64fd62efdc3f0a7b937cdb0e3e831c271); /* line */ 
        c_0x80051bd1(0x65168fae84b1555c15e2c7b9aa66ac65820adbb88eb84b9a566e1c06423e4e68); /* statement */ 
_appendCity(_md.props.country, _md.props.city);
c_0x80051bd1(0xdd7cccea751e1a4d385269d681a06c2cb6ca686c982af5fe02f54af70e99b64b); /* line */ 
        c_0x80051bd1(0x323184046c5534d1411810b3d59df02a58d1b3ad880c21d31dc495cb5265eb35); /* statement */ 
cityToTokens[_md.props.city].push(_id);

c_0x80051bd1(0xfa10103c9858fff9a30b5d2cf303e06a7e4ab46943a3d397a7a12c53236f75c1); /* line */ 
        nextTokenId++;
c_0x80051bd1(0x2945e658011f0e8258786aa6f7895e157002a30de4356b9a897169f431b8920b); /* line */ 
        c_0x80051bd1(0xd14676d018df182d2825faedb17577f718d22937858fb2fc27744912b77e6dae); /* statement */ 
emit NewToken(_id, _md.props.country, _md.props.city);
    }

    function mint(address _to, uint256 _tokenId) public onlyRole(MINTER_ROLE) requireExist(_tokenId) whenNotPaused {c_0x80051bd1(0x66ecda494004e66d513fa549a1d450fd08ec58e90aa4183a0c028eda625209f4); /* function */ 

c_0x80051bd1(0x7dc95bea0c547e9bb6402f7150dab1d379c98a229affcdbab249c187fc6a996a); /* line */ 
        c_0x80051bd1(0xd13aa75c42ffb23a6211a904076d1bbd301de274aa2a39b64b7104aaeceb21a0); /* statement */ 
_mint(_to, _tokenId, 1, "");
    }

    // @return returns Cities array and Array of [tokenId,balance] for this cities
    function balanceByCountry(
        address _account,
        string memory _country
    ) public view returns (BalanceByCountryEntry[] memory) {c_0x80051bd1(0xc18f2b5d65943e7816f3e986ed6f8b249159f52e0bc488d180974e3fbf1d6de9); /* function */ 

c_0x80051bd1(0xaa520c0b977e7a68bfd2ddb138cb3c79dfcd9d233c0a6aed0686ed086650802b); /* line */ 
        c_0x80051bd1(0xdb04c1fa4ddbb516b4f4dc3be3b8b1357c86dfb70795c6803d7acc4c9894c929); /* statement */ 
string[] memory _cities = countryToCities[_country];
c_0x80051bd1(0x942671e68909d53735e1c6860fe51310b0b6e5c6eaac75054ceb907538dc2729); /* line */ 
        c_0x80051bd1(0x0806a56ca23ba4d1a41b69f68d3c4cdc59d593e2056f66dea2a3063f1a049852); /* statement */ 
uint256 _citiesCount = _cities.length;
c_0x80051bd1(0x5532d5bcd3b88a3e70dc658c64a32fdbda6bd59a2c5e1d90f1f8e8408886747b); /* line */ 
        c_0x80051bd1(0xa5657e8818145671af9934d38d95b14b811b6a0adc9f5036f49111d3874d3198); /* requirePre */ 
c_0x80051bd1(0x1cd1e61a77758feba552e66046c75a19631ab3c5892b6b6e5b8086e3966b08df); /* statement */ 
require(_citiesCount != 0, "Stations: no cities found");c_0x80051bd1(0x0020afba8698f40359d50119874d292f4dcd16eba661b3c8159b00445ac12649); /* requirePost */ 


c_0x80051bd1(0x4b061914b75a87003b127615bbc2d8730b4acc64b4eba9c07f51bf170f320b3f); /* line */ 
        c_0x80051bd1(0x73eb4c1576a6f1d8b29db73fe57cb411fec7d934deea43d5b06393c1bffd71d3); /* statement */ 
BalanceByCountryEntry[] memory resp = new BalanceByCountryEntry[](_citiesCount);

c_0x80051bd1(0xa3945938cfccee04aef58c9e399f934d68d6f29d822930bd0cce7ab3e65e9dc9); /* line */ 
        c_0x80051bd1(0x65d8c561d28447a14e2a7c7cef476dd5c6c9c4ebc0cb16db725bdebe45618d67); /* statement */ 
for (uint i = 0; i < _cities.length; i++) {
c_0x80051bd1(0x597ae359a923a628e40efe774d6860fda11f58a799e7a42f0b0c27c812b629d8); /* line */ 
            c_0x80051bd1(0x673fa6d8a3c32885229c5a1287c88fc19902db269e1cd2a1ec10d0af4e088911); /* statement */ 
string memory _city = _cities[i];
c_0x80051bd1(0x1f8150edc243daf45c77fb51fd0607b3736f0db3de6b5b37fa3be23c641d8885); /* line */ 
            c_0x80051bd1(0xcad81f10c062644826ea56af4a1084c3591b5e583238cc7175a9fcae49263bb1); /* statement */ 
TokenBalanceEntry[] memory _balances = balanceByCity(_account, _city);
c_0x80051bd1(0x344abce7044b6cf7864ce69efc796e86aa8587eeafba6eec4b62fa3f6d31666e); /* line */ 
            c_0x80051bd1(0xcb1a7dd8649a570ce88f2741e427b97bc92765846e49a55cf750c2051d1e5d07); /* statement */ 
resp[i] = BalanceByCountryEntry(_city, _balances);
        }

c_0x80051bd1(0x6bfd34d90a993f81dbc8187ec15242c830854fdb1051ab9d545b0c0c7b7784a9); /* line */ 
        c_0x80051bd1(0xff9eca47f20f609900b19a76647722a40f9ea77281356eed9228b7c0a9ec97ec); /* statement */ 
return resp;
    }

    // @return returns array containing tokenIds of this city and relative balances
    function balanceByCity(address _account, string memory _city) public view returns (TokenBalanceEntry[] memory) {c_0x80051bd1(0xad910f3053924ef2cfbdf2609dd75a0ef712338a2862a6bc371e8a2c567b65aa); /* function */ 

c_0x80051bd1(0x8e2cb59b3136b055cf1b91e265c49a0f56ed5448f90a57f865318a0e3441698b); /* line */ 
        c_0x80051bd1(0xd9bc5aa5330e56e47d66563d6d0a16d42ba28eaec09824b146818d3643efd21e); /* statement */ 
uint256[] memory _ids = cityToTokens[_city];
c_0x80051bd1(0x53f9d5f8272d52a3fae7359df87a5b5231c6f16c97ebccc1dc712d42e283d000); /* line */ 
        c_0x80051bd1(0x8c80fb3ec73395eb2b0f93d87ef324d223579447d40dbf6addc604eca4fa50b0); /* requirePre */ 
c_0x80051bd1(0x8eae86cf08098519fc6e9de31a3eca91b3b67b0ce286990d3a21bb2cd7427992); /* statement */ 
require(_ids.length != 0, "Stations: no tokens found");c_0x80051bd1(0x6bae80b5030f80a34cd3fa29ce5976b52751c715117c0537bba25559b246a400); /* requirePost */ 


c_0x80051bd1(0x2ca8c296f778a9bd415f8e40b26e038ea171a3c5b4cf9401d39fabe90418537d); /* line */ 
        c_0x80051bd1(0x3ab7b6d2bdadd06658132ad0b33fea035e0ec262161a2962b7228c9b52e91d0c); /* statement */ 
return _balanceByAccountBatch(_account, _ids);
    }

    function uri(uint256 id) public view override requireExist(id) returns (string memory) {c_0x80051bd1(0x7f74ba6b3c232c20e908bb955123c4fe75b1893db744a4ac49845808f4bc270e); /* function */ 

c_0x80051bd1(0x1afc6d0ba11440edd6ba32547f6987b9ebd563e4db6f4270eafe0a419482e7f5); /* line */ 
        c_0x80051bd1(0x4d501e032e8ebd679bc3ac41073fe8b981dc8b7d979e69fc617ad04eac87d7b1); /* statement */ 
MetadataParams memory _params = metadata[id];
c_0x80051bd1(0x215c37a3eac69a780e341e86c0592541cb5592411c9d6368a18090e1c7fca6d7); /* line */ 
        c_0x80051bd1(0x2fe798aefe9ab8002e153aacb3a937071128866f65e8a08c51dd8bf853e1ce12); /* statement */ 
return _params.tokenURI();
    }

    function exist(uint256 _tokenId) public view returns (bool) {c_0x80051bd1(0x03ad97abb59bf9df34b4121fe31a713a23aa954290e8fb835237c21031e04a49); /* function */ 

c_0x80051bd1(0x81eb0a1697233f8ef73977b2b61aa0e8741bb15f6b33231fe51280bdf86e0781); /* line */ 
        c_0x80051bd1(0xf8edfdcdf95a0a371ad0a05cae82e6e6fb11ac35af155765882e4d88446ef858); /* statement */ 
return bytes(metadata[_tokenId].name).length != 0;
    }

    //TODO: Figure out how to to avoid this
    //This was required due to compilation errors
    function supportsInterface(
    // solhint-disable-next-line  no-unused-vars
        bytes4 interfaceId
    ) public view virtual override(OpenSeaCollection, AccessControlUpgradeable, ERC1155Upgradeable) returns (bool) {c_0x80051bd1(0x7055677045dfbfc112faf9dd5122a5b2caf6b058b43cd0a101a5d9d9ba0c1cb1); /* function */ 

c_0x80051bd1(0x81a950af085dc75a2c04e711b58978cca8bd444b202ebe6d422d3d7dd45c09a0); /* line */ 
        c_0x80051bd1(0x92ba923b446a98e0c5cc13a958f56a6ec92bcd2e2e03fa24287c811dc24fa82a); /* statement */ 
return true;
    }

    function _appendCountry(string memory _country) internal {c_0x80051bd1(0xea2782a02850cbc0a04662850ad6b0d6fb3c1de704ed0c814049ba6eeedb26df); /* function */ 

c_0x80051bd1(0x1644f9f1c906cc475fa42f3ab7d19f9af8a108d60baaa6b1607760273e1da5ff); /* line */ 
        c_0x80051bd1(0x77781562acaf716005481996a988da012993729af002a329c4b285c731079a97); /* statement */ 
for (uint256 i = 0; i < countries.length; i++) {
c_0x80051bd1(0x2347e1680891864bfba819c0dffb8f24d461acae02037324ef7ba78f5fb6f7ad); /* line */ 
            c_0x80051bd1(0x43b835aea457b3780ab85fbc398dbf213bc89d4e9c257b76f972ec8b6f1c84be); /* statement */ 
string memory _current = countries[i];
c_0x80051bd1(0xf2e238588bb0b95f82d3c9d1c7f229e93125cc79e086d22675cad0850b1af63d); /* line */ 
            c_0x80051bd1(0x54b33a5ab21fe63efe9cd4a202bfbf75740c8e01016f38e5fc202c2311089e8f); /* statement */ 
if (keccak256(bytes(_current)) == keccak256(bytes(_country))) {c_0x80051bd1(0x71a57769276d38d229896c617ce487092edb3e44ca3cacfb6fd32d6ce6ef82ea); /* branch */ 

c_0x80051bd1(0x4f2967b1b4f0204c48e0d3ec99b5425b2a4b31540461bde60862e5a6dd0ab76f); /* line */ 
                c_0x80051bd1(0xf997d1b9cb9f4927ac26f075cd4ed6a81457545bc013b4db2f0097f2f583bdd9); /* statement */ 
return;
            }else { c_0x80051bd1(0xe0138fd459a9bd92912333ea97508e6ce587486f4cef9fc34f57da2700fd2d64); /* branch */ 
}
        }
c_0x80051bd1(0x54003a498df3851526083129850d4c2f506a9d73aa7e1d08e40c540b6d83bb45); /* line */ 
        c_0x80051bd1(0x097c1a0d05f9fb5b37e5527663cba8f8d04ad066a5004ca832b5ecb83de2ddf4); /* statement */ 
countries.push(_country);
c_0x80051bd1(0x0f1c730dccc19935b0392ef5ceb0a969095ba049b12265e254d6ec1778e4e79a); /* line */ 
        c_0x80051bd1(0x8b395ec0ffcadf040f97377958d578da11d9ae6a4a3b3b08e4d77cf668cf229f); /* statement */ 
emit NewCountry(_country);
    }

    function _appendCity(string memory _country, string memory _city) internal {c_0x80051bd1(0x2f942151929d7c4413a535b8ca501b34a3b9e1d3c4b9439ebee334a55c321ce0); /* function */ 

c_0x80051bd1(0xc55cc707bc1419f33b2cec025b1e052a8b3b82fdbc37969d8f61fa6fb0d7d706); /* line */ 
        c_0x80051bd1(0x9e2b5080339c40667c1abd1be37ca860c724d6246f17c65f2415f62530447903); /* statement */ 
string[] memory _cities = countryToCities[_country];

c_0x80051bd1(0x2031da74a4152e639d3c738b3a770e4db4246133b6049311ea858a64f26c550c); /* line */ 
        c_0x80051bd1(0xea70b097bd706e2ca08ec5d2bab705f53e2aae4e5204d382a86baf1b1fc9e61d); /* statement */ 
for (uint256 i = 0; i < _cities.length; i++) {
c_0x80051bd1(0x9d03f000bd667b68ebdd8c525a1d4e238243e0b5ef16dfd1b17f5537b57af29c); /* line */ 
            c_0x80051bd1(0x4a1ded0e043b5616d6ce957ccf297b1c170310288ee7e3fe356acc00d29c1a07); /* statement */ 
string memory _current = _cities[i];
c_0x80051bd1(0xdfeb104c0ebdf344f304f39052c0d93df0ea16b93af0cf6484fdd6309eaf1911); /* line */ 
            c_0x80051bd1(0x0f7b196b43f1b10126739f34405fe7ac57d0a4dbe3b1ceed63e4660a126dd645); /* statement */ 
if (keccak256(bytes(_current)) == keccak256(bytes(_city))) {c_0x80051bd1(0x1eafff5f71550267b5bb495b49bb214b2931c3e75b4280d865faecfcaf817451); /* branch */ 

c_0x80051bd1(0xb802c6c5f2f29d4a1668c89b369ba6bdfbfdc6447620e3354851abd1f40f2ea7); /* line */ 
                c_0x80051bd1(0x9b17a92d6f5e350ce22eda3b9c0ccb6aa0e6c9faa64a37bd91759a42d3006795); /* statement */ 
return;
            }else { c_0x80051bd1(0xe5cfe40e3e92224264c281f469e445563c1e4bedd5a45dba2c37660ab7dcb61e); /* branch */ 
}
        }
c_0x80051bd1(0xdf60b6a703c1d8730a9d2c9a8257bc940239ae0324b72d755d7a93ad1c616ede); /* line */ 
        c_0x80051bd1(0xa38f47737bf35cb3ad867bde6dabd8df5a183fa973401baa26d11275f909e791); /* statement */ 
countryToCities[_country].push(_city);
c_0x80051bd1(0xc86f19218b27213ad1b7edc194a319ee99ae7f2301f1702c612617ee68d5b5b0); /* line */ 
        c_0x80051bd1(0x2aef65e6f8259bc1c5b5bbcc7752dacc047276dd7f87fe6aa3ccc3829d7b5768); /* statement */ 
emit NewCity(_city);
    }

    function _balanceByAccountBatch(
        address _account,
        uint256[] memory _ids
    ) internal view returns (TokenBalanceEntry[] memory) {c_0x80051bd1(0x05c62e4326ae930d8539daf2fbc3eba66e52082d849533a94dd1f51bafd7e4c2); /* function */ 

c_0x80051bd1(0xd5c5ac0e9a3e01907b0e691bb660deaebe72a8ea7550bedea74d2535f437c29e); /* line */ 
        c_0x80051bd1(0xa7515a921f81a46c5e77f2623d2ce6d125ccc6a07d9ecfff09193186754ba3df); /* statement */ 
uint256 _idsCount = _ids.length;
c_0x80051bd1(0x9e616a562993bc84a858712a92e37118f58421be594960945b151a00cc395d7c); /* line */ 
        c_0x80051bd1(0x880fdd49a68b56b566105e52594a38bda2ab2cde5664381cfc756dec833924d9); /* statement */ 
TokenBalanceEntry[] memory resp = new TokenBalanceEntry[](_idsCount);

c_0x80051bd1(0x271da92d5fbc206e65e48026a9dc294716050471770a90be8a68fd3e7e1652b8); /* line */ 
        c_0x80051bd1(0x33e8f2ede4a3f6b164f451a85847252087f348a49f6f836713fa525613c5a37f); /* statement */ 
for (uint i = 0; i < _idsCount; i++) {
c_0x80051bd1(0x88bed0d3f98148389ad5f399d0187c67831cafbd0897b63a18b427778657ff67); /* line */ 
            c_0x80051bd1(0x6b76400c0a4141c36d97d9be360e7be739325942e61c8c6a8e140aeddea78e06); /* statement */ 
uint256 _id = _ids[i];
c_0x80051bd1(0x10440a9379bb786e10a01067875933c60e7feb48b538f9faeff9088aea49b81d); /* line */ 
            c_0x80051bd1(0x928597a210853f1c95fb9b0ccbce9ee57e39c76fc80f10d8105369ab1402249b); /* statement */ 
uint256 balance = balanceOf(_account, _id);
c_0x80051bd1(0x109e94eeeff2062f3b1f4fbcf95392b8e5efd45ee91a6c7e56ca6fd25ddb790d); /* line */ 
            c_0x80051bd1(0xc139bcbac65c0df56bea3343dbc9c4ce796b2b38145052abc5578a579beed508); /* statement */ 
resp[i] = TokenBalanceEntry(_id, balance);
        }

c_0x80051bd1(0x3dc1e55602069389d8edd833b42fddf12caf435144439e509db08f5b4c7f0957); /* line */ 
        c_0x80051bd1(0x828758182ab263783ce3d20a98d6100c305683e49c0f148134e917564787846b); /* statement */ 
return resp;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0xf439fe2c(bytes32 c__0xf439fe2c) pure {}


import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../WheelcoinPausable.sol";
import "./OpenSeaCollection.sol";
import "./MetadataGenerator/VehiclesMetadataGenerator.sol";

contract Vehicles is Initializable, OpenSeaCollection, ERC721PausableUpgradeable, WheelcoinPausable {
function c_0x878a4f31(bytes32 c__0x878a4f31) internal pure {}

    using Strings for uint256;
    using VehicleMetadataGenerator for MetadataParams;

    uint256 public nextTokenId;

    // TOKEN_ID ==> DATA

    string public constant DEFAULT_EXO_SKELETON_IMAGE_URL =
        "ipfs://bafkreibanuc3chorpquq7awy2azytwlp6hn64sqvn5koreia24hul76mdi";

    event SetMetadata(uint256 indexed tokenId, string uri);
    event Minted(uint256 id, uint256 timestamp);

    modifier requireMinted(uint256 _tokenId) {c_0x878a4f31(0x43ae6ac8d615ec93cb9e6834eff27bba1ee646b2b2f1847e747656bf81e81bfb); /* function */ 

c_0x878a4f31(0xd8d5cb3d39b62a1adf22df864fe66af156abc99369989d696acdd8d577ef3b7a); /* line */ 
        c_0x878a4f31(0xcd4d5e6070a51ac4fc5a21f1c832e4517edd7e6def4e1b944fc17b3fbe9efaff); /* requirePre */ 
c_0x878a4f31(0x191f259f6a74f6e63e37529891afd157153039a9d8998912e1ca2aa43a5040ba); /* statement */ 
require(exists(_tokenId), "ERC721: invalid token ID");c_0x878a4f31(0x03fea60da29d35d0228aad723d631615b7d850d52bd773a0e3f9517c7dfb0904); /* requirePost */ 

c_0x878a4f31(0x41b6a86e8206b2d14f8e3c92ead2344b96b2fab75e30ddcc9d0cd1594722c692); /* line */ 
        _;
    }
    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __Vehicles_init(
        string memory name_,
        string memory symbol_,
        ContractParams memory _contractParams
    ) public initializer onlyInitializing {c_0x878a4f31(0x2c023bd9334fac0062a61bec1cbdff6ec95932c81d9e5347eb1ba6ee33d8b56f); /* function */ 

c_0x878a4f31(0x9e851e49d7196e810dc4aaa26c9fc9511bff07a825607518f72de75fd4d970b6); /* line */ 
        c_0x878a4f31(0x72689de8fe78e2c6fff055df5139ec535e8273bbff7359305aaf2cef0ce5ed8d); /* statement */ 
OpenSeaCollection.__OpenSeaCollection_init(_contractParams);
c_0x878a4f31(0x7d6223f2f1e4c5c85879cf964df2b17abc10533dcec590a08364f7bda17364c8); /* line */ 
        c_0x878a4f31(0xe460ae0e243303151631664f6b23544634e8cfebaa2de3e214eb614a15672a92); /* statement */ 
WheelcoinPausable.__WheelcoinPausable_init();
c_0x878a4f31(0x69f84a553b5ec565d58c4b347b3c3cf5d60db670ed31771fad5a77d8a3ce9d95); /* line */ 
        c_0x878a4f31(0x7710f849491f90d6d569e08e45e2af82909a6bbd87ab06c5cf1803990c7bf597); /* statement */ 
ERC721Upgradeable.__ERC721_init(name_, symbol_);
c_0x878a4f31(0xa6b204aaac38babc5f1983100774c5d2eedd87125df0ca0e14a236d365993b57); /* line */ 
        c_0x878a4f31(0x1d0ac5ecc6aac75ca57c6b4e6cede5d29c4e08694245252b32f0b1d2a725da98); /* statement */ 
ERC721PausableUpgradeable.__ERC721Pausable_init();

c_0x878a4f31(0x8a2452b7758407f492dcc11300d31a36fbb90057e451bf3f324db293a3abf7a8); /* line */ 
        c_0x878a4f31(0xbc9315904a2d36fda1f057a2c2c8b37dbedfe7f156e01e00c4c321eb13dfc266); /* statement */ 
nextTokenId = 1;
    }

    function mintExoSkeleton(address receiver) public onlyRole(MINTER_ROLE) whenNotPaused returns (uint256) {c_0x878a4f31(0xaba5c10a3664e409dc6c131386e365a18b4e29722aa4f2ce641488947de8b844); /* function */ 

c_0x878a4f31(0xa98b23b0f68976cb3827d7c74973bbfd9ac0bf51b6fc3efb64fbf20b751bf3ec); /* line */ 
        c_0x878a4f31(0xf171fa000083f85a9e2fc500bf42d436ddd7f924d63ff0e249a3c8ba44893488); /* requirePre */ 
c_0x878a4f31(0x4b8b728aae460ca1b6ad975ce07e5b315244e7a073eb0228ee8f3fdc6426cd7a); /* statement */ 
require(receiver != address(0), "receiver must exist");c_0x878a4f31(0xcd709cbc8f7aa8624b44bbf0ea243ca877d0ee248697c2286701934379a86c48); /* requirePost */ 


c_0x878a4f31(0xa221fe3a7eda634f33041ba5facaa307ae2afd5d49b01a9ee32a53ba58a9167d); /* line */ 
        c_0x878a4f31(0xca95a8414abbce11ab97e6bb5f49fef9d0025c4047f5e6af4ef8a992df9e8520); /* statement */ 
uint256 tokenId = nextTokenId;
c_0x878a4f31(0xa8dc0a065f8c6cd61af1b36c5aadd5f4e3d3597195f8b3b2ec0cc75286e6afd3); /* line */ 
        nextTokenId++;

c_0x878a4f31(0x4cf27d40c814188c83db54665025d30782922e29bd0451ab0dbc7d1d331a4f66); /* line */ 
        c_0x878a4f31(0xddac71e5f0918411f970c6f4f2911171bfcf38475fd657ed9a62781b8abdbf02); /* statement */ 
_safeMint(receiver, tokenId);

        //solhint-disable-next-line not-rely-on-time
c_0x878a4f31(0xe9fdd9f6b9ccdeedf65a459972b2400a3c7bdfc7c41901a897a3a3cf561e2db7); /* line */ 
        c_0x878a4f31(0x75a88ffd3d895c543dcdd9b65a8bc5196a3e62b50d930418949d6b13ce62f505); /* statement */ 
emit Minted(tokenId, block.timestamp);
c_0x878a4f31(0x7f348d68ddfbb06f6cca630b3cd410ee4bb07df568dc9f5a891a83d447a3c333); /* line */ 
        c_0x878a4f31(0xdcc80fb5578688e2b089d8a52c1156bed9a89e9371a665130eedfd7b1c27a74e); /* statement */ 
return tokenId;
    }

    function tokenURI(uint256 _tokenId) public view override requireMinted(_tokenId) returns (string memory) {c_0x878a4f31(0x966453daa63b3a05378747144aea1fd59198f1f78c7c11b976ca7c47884658e1); /* function */ 

c_0x878a4f31(0x2c5beecf15a09fe52ac45b09582907ab30f13ea0642b0c5213abdba6fb0a6bf4); /* line */ 
        c_0x878a4f31(0xd21ba24aeee1c0e4e8bf024823a45255cf8e2a992261f1566fddc79b170b2f5f); /* statement */ 
MetadataProps memory props = MetadataProps("exoskeleton", "futuristic", 1);
c_0x878a4f31(0xa6b484d3b78dfd875e362e27a7806e57979f0623392dfa310b7b7915503c1f32); /* line */ 
        c_0x878a4f31(0x676538f96318fcb0b464f06261cad19777c95c3b2ba8428ec2908545171c57e8); /* statement */ 
MetadataParams memory params = MetadataParams(_tokenId, DEFAULT_EXO_SKELETON_IMAGE_URL, props);
c_0x878a4f31(0x6de3c0097d78dec86908ffb9d6283d494d43acbf6858cbf27e07b25dfeb34127); /* line */ 
        c_0x878a4f31(0xc16bdef0aac9cda9acd7ef22ca9ce8360f9bbf685753e4a3110dc2c711ae063f); /* statement */ 
return params.tokenURI();
    }

    function exists(uint256 _tokenId) public view returns (bool) {c_0x878a4f31(0x3a7b2fc8ace2e8fefc54392166167f97bb825c5fa8035a9c22170083defcd838); /* function */ 

c_0x878a4f31(0x3aa6c3554105726047788b119ce236b7660f02c053d19c7cb9312ab2fbcb813f); /* line */ 
        c_0x878a4f31(0x87944b8fb876275ef5643624b80028f9e9b027b00007ff4a17fb8a5bb42c4956); /* statement */ 
return _exists(_tokenId);
    }

    //TODO: Figure out how to to avoid this
    //This was required due to compilation errors
    function supportsInterface(
        // solhint-disable-next-line  no-unused-vars
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, OpenSeaCollection, ERC721Upgradeable) returns (bool) {c_0x878a4f31(0xcd50f1c1e7e37e43b8a3e3a3fd5379f61759d95fb386ade36beac08df9c41345); /* function */ 

c_0x878a4f31(0xc7a6378df217e149bff1089e4aa9f3ea0fd7f858095b2f067e1acea6d5fdef6c); /* line */ 
        c_0x878a4f31(0xc98146c409e99bce40e85d3f70404354ab82aa06411300211b7d2a3a7c72ffad); /* statement */ 
return true;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x82e72137(bytes32 c__0x82e72137) pure {}


import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./WheelcoinRoles.sol";

contract WheelcoinPausable is Initializable, WheelcoinRoles, PausableUpgradeable {
function c_0x20190320(bytes32 c__0x20190320) internal pure {}

    function pause() public onlyRole(ADMIN_ROLE) {c_0x20190320(0xe2d0f593f6744301d17622fcf7b61a3fc72ce0421dfa26886a638c06b1cfa25c); /* function */ 

c_0x20190320(0x86fa4ccabff7e10c4c9b9ef297291d42cea2d7d234f35adfc603446c705c4971); /* line */ 
        c_0x20190320(0x4da28de241642232d1c5b6a46b9712f84f474ad3a58494465cf36d7936afadaa); /* statement */ 
_pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {c_0x20190320(0xfc58de4986d41c0cfd9a0a6a5b6b26c3b94ce0a57d37fbc0e159f4f4117da033); /* function */ 

c_0x20190320(0x42c7a5842e46cde3b7da4a71d782b2c3c4bb46c9d7d5fa083c5efc37e2eeead7); /* line */ 
        c_0x20190320(0xb02d2d0a2bfd83a2d97b4a3de2437f8d59814ac3cd3fb558a543969df4792b9d); /* statement */ 
_unpause();
    }

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __WheelcoinPausable_init() internal onlyInitializing {c_0x20190320(0x9e7db3f5382bf7f34fb630ac3d72b1a46d09494148fbb9c0df681d1048eadc8b); /* function */ 

c_0x20190320(0xf0d31436fe70a284ccece66d97f87dac5b094d1c2d427b7db4d5524df35e52e2); /* line */ 
        c_0x20190320(0x1c96ca787037cf608efd8e4e7b2a212cdb2dfa8c3cb943eea4509d0674581108); /* statement */ 
WheelcoinRoles.__WheelcoinRoles_init();
c_0x20190320(0x28e475e1e580b42fd2b5fde35a65aad82888b8c92c559af4ed01eb4afd229637); /* line */ 
        c_0x20190320(0x7b0638ecfa14d19b71283cc53e4233c2d77ecd2016bfe5a909d41d4f5d2f714b); /* statement */ 
PausableUpgradeable.__Pausable_init();
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0xecbc4180(bytes32 c__0xecbc4180) pure {}


import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./WheelcoinRoles.sol";


contract WheelcoinProxyAdmin is Initializable, WheelcoinRoles, ProxyAdmin {
function c_0xaf2d6efc(bytes32 c__0xaf2d6efc) internal pure {}

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __WheelcoinProxyAdmin_init() public initializer {c_0xaf2d6efc(0xe85df8fc6c033d71119c35dd3750dd64eaa2a68c2705d97be6f049602ae677a8); /* function */ 

c_0xaf2d6efc(0xeb417fa5a542b085ad40ead77fb5ee0f4f79eda8f41280a18fdd6caf0e834d53); /* line */ 
        c_0xaf2d6efc(0xdcc97f9fd5f00a3e8662daceda9ca0ae18cd96b0d138e5b8ddf445f1721d6dfa); /* statement */ 
WheelcoinRoles.__WheelcoinRoles_init();
    }

    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public override onlyRole(ADMIN_ROLE) {c_0xaf2d6efc(0xf2acd6c5062a5e88e036ca434e37f17be40dce83003bca08718382113a44c215); /* function */ 

c_0xaf2d6efc(0x073d33f72a6d5c5b5a0d2da26c604593b1f76c66bbba4fb784912e03381d9b0f); /* line */ 
        c_0xaf2d6efc(0x14425ecff16adb726db3d266ab5d9d08e6e25f6ce11a74a596808855de9b18f0); /* statement */ 
proxy.changeAdmin(newAdmin);
    }

    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public override onlyRole(UPGRADER_ROLE) {c_0xaf2d6efc(0xf1db15b9fd49c3f1258f259b15408e4cc7a810d242af6bdb479cf8fdb3d44320); /* function */ 

c_0xaf2d6efc(0x8e2aa0f3ead099358fc3dc773b57c08736c18e02a1ee179a410cf7390c4128b4); /* line */ 
        c_0xaf2d6efc(0x9b9a5a13197c4293ae661b085f893b0ce1b9e800957669bd914cec746bcdaa21); /* statement */ 
proxy.upgradeTo(implementation);
    }
    /* solhint-disable indent, bracket-align,  no-unused-vars*/
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable override onlyRole(UPGRADER_ROLE) {c_0xaf2d6efc(0xa21ac1dd52790951ffa2b15e354de90c6c14f4a0d1333fd7a2476a8311718027); /* function */ 

c_0xaf2d6efc(0xe67bb7cfa5f164d3fbe8bb6ea8a5bc7e39415543d03ed39f125aeea106764720); /* line */ 
        c_0xaf2d6efc(0x0574155dbd1ec783cd94233ce977f6aaf7a55cac732b514ce9d6b9b3dba3e85a); /* statement */ 
proxy.upgradeToAndCall{value : msg.value}(implementation, data);
    }
    /* solhint-enable indent, bracket-align,  no-unused-vars*/

    // solhint-disable-next-line  func-name-mixedcase, private-vars-leading-underscore
    function __WheelcoinProxyAdmin_init_unchained() internal onlyInitializing {c_0xaf2d6efc(0x419e5b722a2c7fd3b64ccf0792059c04317d95c65d475e0c0388e76559eb8b7a); /* function */ 

c_0xaf2d6efc(0xf35a5c1f44be54b5b8c8fee4fdfab83defea97e95a72f6ec0fd15251991ec420); /* line */ 
        c_0xaf2d6efc(0x5c86a57ab48c6695fa8a530d613322ef6f6c55a433db45ff89fa0144ee4915a5); /* statement */ 
WheelcoinRoles.__WheelcoinRoles_init();
    }

    function _msgSender() internal view override(Context, ContextUpgradeable)
    returns (address sender) {c_0xaf2d6efc(0x95c9a11fbd1eeb37bb3896fa43fefcb1b22b17a3756d33815389c133af353365); /* function */ 

c_0xaf2d6efc(0x5e7e95400e0cf4e001ec5e11484f915d3faba28353855cf854a9a281c8d4e73e); /* line */ 
        c_0xaf2d6efc(0xbc665feda81813b4dd1d2ba3cc03a20dd683242f33b416c5ae355e6ac9f86c94); /* statement */ 
sender = super._msgSender();
    }

    function _msgData() internal view override(Context, ContextUpgradeable)
    returns (bytes calldata) {c_0xaf2d6efc(0x0423318f8823b4b617bc2f555b97d721503bbdd5c74c2e011e500765352c666c); /* function */ 

c_0xaf2d6efc(0x299a6078519a9e1e3a609366f34d2c304e5077aa474e1f148c709fe19ae9da15); /* line */ 
        c_0xaf2d6efc(0x1387ef8dfcaff17d0b08fbf1a0639a44200a70f8359fcc3e062e19945314f867); /* statement */ 
return super._msgData();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0xefce924b(bytes32 c__0xefce924b) pure {}


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./WheelcoinRoles.sol";

contract WheelcoinRequestsLimits is Initializable, WheelcoinRoles {
function c_0x483b3c84(bytes32 c__0x483b3c84) internal pure {}

    struct UsedLimitEntry {
        uint256 lastUpdate;
        uint256 usedLimit;
    }

    uint256 constant internal _DEFAULT_UPDATE_PERIOD = 24 hours;

    uint256 public updatePeriod = _DEFAULT_UPDATE_PERIOD;

    // ROLE ==> FUNC_SIG ==> LIMIT
    mapping(bytes32 => mapping(bytes4 => uint256)) public limits;
    // USER ==> FUNC_SIG ==> USED
    mapping(address => mapping(bytes4 => UsedLimitEntry)) internal _usedLimits;


    event LimitSet(bytes32 indexed role, bytes4 indexed funcSig, uint256 limit);
    event UpdatePeriodSet(uint256 newPeriod);

    modifier checkLimit(bytes4 _msgSig) {c_0x483b3c84(0x73a758fe66967e5cb32f7264eed9151fc02de36133453dc504b9df03efaaaca3); /* function */ 

c_0x483b3c84(0xa7c0c2d5c04a34af0de70124983eb33368a412e3ce6c9a5c500f429b664f1ec2); /* line */ 
        c_0x483b3c84(0xb565b329eac9e85bd694788c4d5fbcc4a93ff0963a59c58dc1bbd56a5c3d015a); /* statement */ 
bytes32 _role = getHighestRole();

c_0x483b3c84(0x3e2369f99f5884c8e454fdf170a77d0e4df56d6c7ea8dcd1de82aeb04edea624); /* line */ 
        c_0x483b3c84(0x98adb80bada25b9fd093cc355f6a36abc20c71a22040e903fb2b587e0df25dab); /* statement */ 
uint256 _limit = limits[_role][_msgSig];
c_0x483b3c84(0xd5cc4594db8ed19fecd106c33f790c3a5a1749653016bac073f85aef55edec14); /* line */ 
        c_0x483b3c84(0x86c83978d46ee0c1c651196becfd76871023ab396192cb08319040501dfe2d3f); /* statement */ 
if (_limit == 0) {c_0x483b3c84(0xc71ae05fc0db2d27aeb4b66b388aa6cbca05476d709000d2385511affb1800f1); /* branch */ 

c_0x483b3c84(0x80f05c12d2021c25fa4553be809c3001b94318be6f1e1854bf04bfe631f3c559); /* line */ 
            _;
c_0x483b3c84(0xd443c0346434ae4bd663ae261ccbc778b58c963ceaddebbf3bbf74bef162bb88); /* line */ 
            c_0x483b3c84(0xb15cc7da77c70ebacae313ffa695b75d489de55f49da86d1b5a3422d866f3c60); /* statement */ 
return;
        }else { c_0x483b3c84(0x3ed1d928e30b412d3839cd14854805199561678aabb28bb1634b6250a7d9f1ef); /* branch */ 
}
c_0x483b3c84(0x870a30ea0385ef6fd98c31e16ec8efbe2618fa7cad2248c8fc1656044ca0ba36); /* line */ 
        c_0x483b3c84(0xcc07a17d839a0bd5848f13b59faea186a05179ca68eaf6e3b98b6d93dcb47178); /* statement */ 
UsedLimitEntry storage _used = _usedLimits[_msgSender()][_msgSig];
c_0x483b3c84(0x52a7b4b281291cece88b72fd19837e8f357d7e3a98c2094dd390344c447f2eed); /* line */ 
        c_0x483b3c84(0x835f801e27c003a48a5ee21cc2da5ff444a99fb30d4c7ab9b158c9c2bd07272c); /* statement */ 
if (_used.lastUpdate == 0) {c_0x483b3c84(0x397e15bee7a818e6d7b0455aa0c428661b78013000f8f5cd07fc2f1822b68071); /* branch */ 

c_0x483b3c84(0xcdc6f1274f56cf8d1900f4ae313af588a554e8539da78e8eb108b33f66270305); /* line */ 
            c_0x483b3c84(0x08bccaddc57572c6a4fecd7a1f4643ff3dadd1b9c622e2f933ce03644f2fe90b); /* statement */ 
_used.lastUpdate = block.timestamp;
        }else { c_0x483b3c84(0xa40c100a026e0feb9d67ab10596d72d7e7aa417ad4b765270765a6e760a445c9); /* branch */ 
}

c_0x483b3c84(0x74db5c5439c1822bca7a3a78be9f70c2ec00026f2fb4c69898b49ceff35d3804); /* line */ 
        c_0x483b3c84(0x8b501c804e9cb6fb3f7c1c9da94e0bdcc54272b5726b73643329f57a3cc63aa9); /* statement */ 
if (_used.lastUpdate + updatePeriod <= block.timestamp) {c_0x483b3c84(0x76e488d98ba6547d353f0841c5cd0d66c09ea6e775fd9705ad302862e6c62118); /* branch */ 

c_0x483b3c84(0x7bc09294aca332998da392eed4d611fe544a65feed0731fd79e1b33c7317d442); /* line */ 
            c_0x483b3c84(0xc96421394738a502b2662df39802692b3729875f7dda350ac6ef74fc0f1ff288); /* statement */ 
_used.usedLimit = 0;
c_0x483b3c84(0xc6f4e0bbd315c9d2b4000b4e4dc044d162a1b1060d005109d6bd303ffb4e7982); /* line */ 
            c_0x483b3c84(0xcd0390d645964b185e27c3e0ae6c3eb84d30b1a02c59f319d099907cfb01715f); /* statement */ 
_used.lastUpdate = block.timestamp;
        }else { c_0x483b3c84(0xb9fb840bfef7100efe6089276591b7865c7f2c7b8b3e22a5aaf71b76fe93ca91); /* branch */ 
}

c_0x483b3c84(0x8229c3a115cb6e70dafebb2f30c212593c16a1cc57386b88460cf83c14525a94); /* line */ 
        c_0x483b3c84(0x8c85d4547c2833f829db72ff0a178b236470d11d0b4b11ff26babb3e3e27f0c1); /* requirePre */ 
c_0x483b3c84(0x175e09f79232d107919050ebafd371b6b9dc2f94f43c1a5a30857ccc95ed85ed); /* statement */ 
require(_limit > _used.usedLimit, 'WHL-RequestsLimits: too many calls');c_0x483b3c84(0x07332dc5d6638aa030f94f7777fdf18d127f329cc283b5f059016a3a59863ce4); /* requirePost */ 

c_0x483b3c84(0x89fbcf1c9876ce209dedd6857a135428269ae0f33ae01a390169ccfc165e8027); /* line */ 
        _;
c_0x483b3c84(0x7d9033fbe7db913f2affe46d256d8abc2f782f32e080f1c90be5bc21f13d38f7); /* line */ 
        _used.usedLimit++;
c_0x483b3c84(0x09d569acf7fb7562900c6cb36b4b347adba4360ecf838e0b0149865579a012b3); /* line */ 
        c_0x483b3c84(0x2339c24793402e5c67905a703d9b7ffba3f08f0bf164269d761654bae11c48a2); /* statement */ 
_usedLimits[_msgSender()][_msgSig] = _used;
    }


    function setLimit(bytes32 _role, bytes4 _funcSig, uint256 _limit) public onlyRole(ADMIN_ROLE) {c_0x483b3c84(0xf04465577eff6df47ddbc036d876e935e9c1f9b2be563b2626edba64b390ba07); /* function */ 

c_0x483b3c84(0x15e0f999f056a162804e9f585cfbd80a33d0f325f662d491dcf046ad74d636b8); /* line */ 
        c_0x483b3c84(0x8d7dd9073ae509d1973ce8fa5e3c830aaed61269a582f8b518a69c9867699543); /* statement */ 
limits[_role][_funcSig] = _limit;
c_0x483b3c84(0x63a549fefcf17c6592ab2d34823bd2e9306f11f28dc32c9d82b9adaa9fbe8f8a); /* line */ 
        c_0x483b3c84(0x754efb0dbd9bd36a1b46b04df1890f69f496f994b55a50174c9d0094bf0b7829); /* statement */ 
emit LimitSet(_role, _funcSig, _limit);
    }

    function setUpdatePeriod(uint256 _newPeriod) public onlyRole(ADMIN_ROLE) {c_0x483b3c84(0x6d2421a05395684870f9156589733300bfff2c8f162a4387bf5be2ebd1b89ca3); /* function */ 

c_0x483b3c84(0xdb501e1a562c52a046d634802cb7c712f65f57e5e735c23cf48dcb1cdf7d7c73); /* line */ 
        c_0x483b3c84(0xb55079c6fb53b1fe7d7c72f9919630104f8a4c1eb458b382199b7e3f59684fd6); /* statement */ 
_setUpdatePeriod(_newPeriod);
    }

    function getUsedLimitByFunction(bytes4 _msgSig) public view returns (UsedLimitEntry memory) {c_0x483b3c84(0xbd776e9bcbd7b29b3846116b82ea27c598aec39aacbf17d7c79b987a2304e6de); /* function */ 

c_0x483b3c84(0xc7e86aea30c01a4e2333eb5581803acd927447aca494ebc6d5c80a4bdac1ab47); /* line */ 
        c_0x483b3c84(0x9b81872f70eba903409cc677084f89f0637f987ed053ae9070df3b7cd3e6d457); /* statement */ 
return _usedLimits[_msgSender()][_msgSig];
    }


    // solhint-disable-next-line  func-name-mixedcase
    function __WheelcoinRequestsLimits_init() internal onlyInitializing {c_0x483b3c84(0x81ebfe8dc8916622f9574e670340633e99fc27137f7e96e23b592b1f8786c84b); /* function */ 

c_0x483b3c84(0x3052ddd54a127c993ed4bdbd36a5b503f7df803184eecd7178be3a661d7a670a); /* line */ 
        c_0x483b3c84(0x2ad94ea189b12a9bd1c3f8c9cc2f63a9bb2d708dd561bb40a30b2708a2b650bf); /* statement */ 
__WheelcoinRoles_init();
    }

    function _setUpdatePeriod(uint256 _newPeriod) internal {c_0x483b3c84(0x62f65a58c65a9b995b9c09d7b215fea9bf5ec5e10bd15d0214ffe8c63af5de13); /* function */ 

c_0x483b3c84(0x579d572781bcdc84d7c2d4491c817634708966451101be303f141a88309b2f55); /* line */ 
        c_0x483b3c84(0x4005470e633301a5ee829b88fdbfc04c64a6917707f24cdc3d403eef3fa7ead0); /* requirePre */ 
c_0x483b3c84(0x1296ca1f3750dbcff151259ca7e9c602b78e17812ddee97e361b410f21697298); /* statement */ 
require(_newPeriod > 0, "update period can't be 0");c_0x483b3c84(0x8fbe8d0bf83280e71a907cfa06e13cc075548402cdbdb2ee7747b3917f4c6da7); /* requirePost */ 

c_0x483b3c84(0x3660a92a4a22760774de1bdd4b8e6154b867d03590a62f547b6051823e96f5d2); /* line */ 
        c_0x483b3c84(0xf9faaaaf142fc2b8f23cb257d8868c717e0569d687c8ac2f011ba548d31daf75); /* statement */ 
updatePeriod = _newPeriod;
c_0x483b3c84(0x1225befbce100dec63aabe77b1fb4ed928011e169bc5194670a638542c174956); /* line */ 
        c_0x483b3c84(0xcf2542b29104ddbf1ce4003d36bf04f274f4f14d9a0b838665edf31051f5513d); /* statement */ 
emit UpdatePeriodSet(_newPeriod);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
function c_0x8685f702(bytes32 c__0x8685f702) pure {}


import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract WheelcoinRoles is Initializable, AccessControlUpgradeable {
function c_0x4d79a62a(bytes32 c__0x4d79a62a) internal pure {}

    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant NO_ROLE = keccak256("NO_ROLE");

    function getHighestRole() public view returns (bytes32) {c_0x4d79a62a(0x321aae2745e9c5031d7d917f241ad65a6c1f407ee3183875853eb6cbe45b0d1b); /* function */ 

c_0x4d79a62a(0x3cbe46158f921057c9a448ef5f4776e8e2786131d5940d01aab2ee7b2030e0bf); /* line */ 
        c_0x4d79a62a(0x9bbbcbf6a8d33d39fe5f45c63247e99318d6b784adfcadde1eb882bc8124408f); /* statement */ 
if (hasRole(ADMIN_ROLE, _msgSender())) {c_0x4d79a62a(0xc8b79b7c2ef070fd50d3f4a1f2f627d3eceaf0e0d392a474250a9eeeaf8644ce); /* branch */ 

c_0x4d79a62a(0xb28b782e5786101976706719fa30a1f6ca8ad0e7faa08cb086315e32637fa787); /* line */ 
            c_0x4d79a62a(0x78617a961d59f41ebe7aff88114258a37b28c3513d050fe015c564417ef0750a); /* statement */ 
return ADMIN_ROLE;
        }else { c_0x4d79a62a(0x1711187703ee9c984f1f1898f4713f3a0106f7c42ce0b69b7286a25e9efa695b); /* branch */ 
}
c_0x4d79a62a(0xe6e7172976c6f65c991712813d041052a1a23a57e7f88713b946b3df9475e3fb); /* line */ 
        c_0x4d79a62a(0x2308e968be5e2b8126143d70512df4aac3a77a5c601be47e312a4fd6407a6ab8); /* statement */ 
if (hasRole(UPGRADER_ROLE, _msgSender())) {c_0x4d79a62a(0x0dfb7cbf6ae03e33dc2cceb9e9441c8a8a88c90814f3b66e3fee8d9d4ef3f7e3); /* branch */ 

c_0x4d79a62a(0xc9b8772840a498d88e2becae68de6a87a9f21a48affe75de486cc3f216a2f2b8); /* line */ 
            c_0x4d79a62a(0x8b30bc8041687373acc05aa48b542cb2df6264d50f3eec4f837f5d6cece64cb6); /* statement */ 
return UPGRADER_ROLE;
        }else { c_0x4d79a62a(0x1cf2c0c50cfb2b81cee4d5b32f4846bb59b214e706ad8a39753095cb495bc54c); /* branch */ 
}
c_0x4d79a62a(0x882e725447846a3dc2d8c4cd88e71be3f894a37a9bddfab0ae215dda12ee1ca5); /* line */ 
        c_0x4d79a62a(0xd64f6a31b7e5d822adabee29722776931b5d4bbcfb4848eaf6d2396720eaaefa); /* statement */ 
if (hasRole(MINTER_ROLE, _msgSender())) {c_0x4d79a62a(0x21fa19e491358d3ce885a1027cdd1dc70b83ca5b525b8c3fb0b9a431ba4eb299); /* branch */ 

c_0x4d79a62a(0x28c272a14850ff31707e59155dbb58565e5b8f5fc78873b29a6a9c15d00795b5); /* line */ 
            c_0x4d79a62a(0x478180e74c1c7084795a872b429e1df1fed355ca802fd59a6748adb56a8f62b4); /* statement */ 
return MINTER_ROLE;
        }else { c_0x4d79a62a(0x7d642ac0343e1b0c6e7e5617f82bddaede5e84405ad9cc8c91ac57b12789baf9); /* branch */ 
}
c_0x4d79a62a(0xcaf7acf90dbd00c075a94cbaccc9542e3f4cee14c260625e9fbad480de4cf155); /* line */ 
        c_0x4d79a62a(0x3d6f47999790f7ef5b1714dbff6c7506cd64ebb6cbdb0f2e0ba7404732118bfa); /* statement */ 
return NO_ROLE;
    }

    // solhint-disable-next-line  func-name-mixedcase
    function __WheelcoinRoles_init() internal onlyInitializing {c_0x4d79a62a(0x21a5ea49757731a966087e04ed7666cc0c02757247b338eaf3f69fd2a8541916); /* function */ 

c_0x4d79a62a(0x137ded5521d72920bca369c635190a9c042f5aa797d24ce2b0df8e653a035c84); /* line */ 
        c_0x4d79a62a(0x313956b3ac75c2b0fdf6fcb724ca4d1ebb4603bf57635e9f2faa42dd176f4c4a); /* statement */ 
AccessControlUpgradeable.__AccessControl_init();

c_0x4d79a62a(0x245fb2ade94cc536ce4249cbf865423e85b17a23cef9ab028caf6b9583ace314); /* line */ 
        c_0x4d79a62a(0x662a23ba4740542a3e6b07a2a7ee0de7f2bab5454e25719e2ee71b767c5019ed); /* statement */ 
_setupRole(ADMIN_ROLE, _msgSender());
c_0x4d79a62a(0xc5a55fa0feab62cfe7bf4b13dddd3ad84c78cc555db056f847cadde85c37df3f); /* line */ 
        c_0x4d79a62a(0x0ca4d88e79bbbf392b1303649af616a45d6142a74bb85a0914e75dd2aac17df7); /* statement */ 
_setupRole(MINTER_ROLE, _msgSender());
c_0x4d79a62a(0xa9f43779ad981841f089f59bc690e7e370144e1e79321390b8e8a8471976baa0); /* line */ 
        c_0x4d79a62a(0x4db2f6813aa02ec206df989bba7fedcce53f17806bbd5c8d5bdc43c78a0e7ae2); /* statement */ 
_setupRole(UPGRADER_ROLE, _msgSender());
    }

}