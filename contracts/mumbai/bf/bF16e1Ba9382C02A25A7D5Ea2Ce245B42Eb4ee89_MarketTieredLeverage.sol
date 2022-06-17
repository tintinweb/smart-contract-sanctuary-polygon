// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
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
        __ERC1967Upgrade_init_unchained();
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./abstract/AccessControlledAndUpgradeable.sol";

/** Contract giving user GEMS*/

// Inspired by https://github.com/andrecronje/rarity/blob/main/rarity.sol

/** @title GEMS */
contract GEMS is AccessControlledAndUpgradeable {
  bytes32 public constant GEM_ROLE = keccak256("GEM_ROLE");

  uint200 constant gems_per_day = 250e18;
  uint40 constant DAY = 1 days;

  mapping(address => uint256) public gems_deprecated;
  mapping(address => uint256) public streak_deprecated;
  mapping(address => uint256) public lastActionTimestamp_deprecated;

  // Pack all this data into a single struct.
  struct UserGemData {
    uint16 streak; // max 179 years - if someone reaches this streack, go them 🚀
    uint40 lastActionTimestamp; // will run out on February 20, 36812 (yes, the year 36812 - btw uint32 lasts untill the year 2106)
    uint200 gems; // this is big enough to last 6.4277522e+39 (=2^200/250e18) days 😆
  }
  mapping(address => UserGemData) userGemData;

  event GemsCollected(address user, uint256 gems, uint256 streak);

  function initialize(
    address _admin,
    address _longShort,
    address _staker
  ) public {
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(_admin);
    _setupRole(DEFAULT_ADMIN_ROLE, _longShort);
    _setupRole(GEM_ROLE, _longShort);
    _setupRole(GEM_ROLE, _staker);
  }

  // Only called once per user
  function attemptUserUpgrade(address user)
    internal
    returns (UserGemData memory transferedUserGemData)
  {
    uint256 usersCurrentGems = gems_deprecated[user];
    if (usersCurrentGems > 0) {
      transferedUserGemData = UserGemData(
        uint16(streak_deprecated[user]),
        uint40(lastActionTimestamp_deprecated[user]),
        uint200(usersCurrentGems)
      );

      // resut old data (save some gas 😇)
      streak_deprecated[user] = 0;
      lastActionTimestamp_deprecated[user] = 0;
      gems_deprecated[user] = 0;
    }
  }

  // Say gm and get gems_deprecated by performing an action in LongShort or Staker
  function gm(address user) external {
    UserGemData memory userData = userGemData[user];
    uint256 userslastActionTimestamp = uint256(userData.lastActionTimestamp);
    if (userslastActionTimestamp == 0) {
      // this is either a user migrating to the more efficient struct OR a brand new user.
      //      in both cases, this branch will only ever execute once!
      userData = attemptUserUpgrade(user);
      userslastActionTimestamp = uint256(userData.lastActionTimestamp);
    }

    uint256 blocktimestamp = block.timestamp;

    unchecked {
      if (blocktimestamp - userslastActionTimestamp >= DAY) {
        if (hasRole(GEM_ROLE, msg.sender)) {
          // Award gems_deprecated
          userData.gems += gems_per_day;

          // Increment streak_deprecated
          if (blocktimestamp - userslastActionTimestamp < 2 * DAY) {
            userData.streak += 1;
          } else {
            userData.streak = 1; // reset streak_deprecated to 1
          }

          userData.lastActionTimestamp = uint40(blocktimestamp);
          userGemData[user] = userData; // update storage once all updates are complete!

          emit GemsCollected(user, uint256(userData.gems), uint256(userData.streak));
        }
      }
    }
  }

  function balanceOf(address account) public view returns (uint256 balance) {
    balance = uint256(userGemData[account].gems);
    if (balance == 0) {
      balance = gems_deprecated[account];
    }
  }

  function getGemData(address account) public view returns (UserGemData memory gemData) {
    gemData = userGemData[account];
    if (gemData.gems == 0) {
      gemData = UserGemData(
        uint16(streak_deprecated[account]),
        uint40(lastActionTimestamp_deprecated[account]),
        uint200(gems_deprecated[account])
      );
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "hardhat/console.sol";

abstract contract AccessControlledAndUpgradeable is
  Initializable,
  AccessControlUpgradeable,
  UUPSUpgradeable
{
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  /// @notice Initializes the contract when called by parent initializers.
  /// @param initialAdmin The initial admin who will hold all roles.
  function _AccessControlledAndUpgradeable_init(address initialAdmin) internal initializer {
    __AccessControl_init();
    __UUPSUpgradeable_init();
    _AccessControlledAndUpgradeable_init_unchained(initialAdmin);
  }

  /// @notice Initializes the contract for contracts that already call both __AccessControl_init
  ///         and _UUPSUpgradeable_init when initializing.
  /// @param initialAdmin The initial admin who will hold all roles.
  function _AccessControlledAndUpgradeable_init_unchained(address initialAdmin) internal {
    require(initialAdmin != address(0));
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);
    _setupRole(ADMIN_ROLE, initialAdmin);
    _setupRole(UPGRADER_ROLE, initialAdmin);
  }

  /// @notice Authorizes an upgrade to a new address.
  /// @dev Can only be called by addresses wih UPGRADER_ROLE
  function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface ILongShort {
  /*╔════════════════════════════╗
    ║           EVENTS           ║
    ╚════════════════════════════╝*/

  event Upgrade(uint256 version);
  event LongShortV1(address admin, address tokenFactory, address staker);

  event SystemStateUpdated(
    uint32 marketIndex,
    uint256 updateIndex,
    int256 underlyingAssetPrice,
    uint256 longValue,
    uint256 shortValue,
    uint256 longPrice,
    uint256 shortPrice
  );

  event SyntheticMarketCreated(
    uint32 marketIndex,
    address longTokenAddress,
    address shortTokenAddress,
    address paymentToken,
    int256 initialAssetPrice,
    string name,
    string symbol,
    address oracleAddress,
    address yieldManagerAddress
  );

  event NextPriceRedeem(
    uint32 marketIndex,
    bool isLong,
    uint256 synthRedeemed,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceSyntheticPositionShift(
    uint32 marketIndex,
    bool isShiftFromLong,
    uint256 synthShifted,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceDeposit(
    uint32 marketIndex,
    bool isLong,
    uint256 depositAdded,
    address user,
    uint256 oracleUpdateIndex
  );

  event NextPriceDepositAndStake(
    uint32 marketIndex,
    bool isLong,
    uint256 amountToStake,
    address user,
    uint256 oracleUpdateIndex
  );

  event OracleUpdated(uint32 marketIndex, address oldOracleAddress, address newOracleAddress);

  event NewMarketLaunchedAndSeeded(uint32 marketIndex, uint256 initialSeed, uint256 marketLeverage);

  event ExecuteNextPriceSettlementsUser(address user, uint32 marketIndex);

  event MarketFundingRateMultiplerChanged(uint32 marketIndex, uint256 fundingRateMultiplier_e18);

  event SeparateMarketCreated(string name, string symbol, address market, uint32 marketIndex);

  function syntheticTokens(uint32, bool) external view returns (address);

  function assetPrice(uint32) external view returns (int256);

  function oracleManagers(uint32) external view returns (address);

  function latestMarket() external view returns (uint32);

  function marketUpdateIndex(uint32) external view returns (uint256);

  function batched_amountPaymentToken_deposit(uint32, bool) external view returns (uint256);

  function batched_amountSyntheticToken_redeem(uint32, bool) external view returns (uint256);

  function batched_amountSyntheticToken_toShiftAwayFrom_marketSide(uint32, bool)
    external
    view
    returns (uint256);

  function get_syntheticToken_priceSnapshot(uint32, uint256)
    external
    view
    returns (uint256, uint256);

  function get_syntheticToken_priceSnapshot_side(
    uint32,
    bool,
    uint256
  ) external view returns (uint256);

  function marketSideValueInPaymentToken(uint32 marketIndex)
    external
    view
    returns (uint128 marketSideValueInPaymentTokenLong, uint128 marketSideValueInPaymentTokenShort);

  function checkIfUserIsEligibleToSendSynth(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external;

  function updateSystemState(uint32 marketIndex) external;

  function updateSystemStateMulti(uint32[] calldata marketIndex) external;

  function getUsersConfirmedButNotSettledSynthBalance(
    address user,
    uint32 marketIndex,
    bool isLong
  ) external view returns (uint256 confirmedButNotSettledBalance);

  function executeOutstandingNextPriceSettlementsUser(address user, uint32 marketIndex) external;

  function shiftPositionNextPrice(
    uint32 marketIndex,
    uint256 amountSyntheticTokensToShift,
    bool isShiftFromLong
  ) external;

  function shiftPositionFromLongNextPrice(uint32 marketIndex, uint256 amountSyntheticTokensToShift)
    external;

  function shiftPositionFromShortNextPrice(uint32 marketIndex, uint256 amountSyntheticTokensToShift)
    external;

  function getAmountSyntheticTokenToMintOnTargetSide(
    uint32 marketIndex,
    uint256 amountSyntheticTokenShiftedFromOneSide,
    bool isShiftFromLong,
    uint256 priceSnapshotIndex
  ) external view returns (uint256 amountSynthShiftedToOtherSide);

  function mintLongNextPrice(uint32 marketIndex, uint256 amount) external;

  function mintShortNextPrice(uint32 marketIndex, uint256 amount) external;

  function redeemLongNextPrice(uint32 marketIndex, uint256 amount) external;

  function redeemShortNextPrice(uint32 marketIndex, uint256 amount) external;

  /* ══════ User specific ══════ */
  function userNextPrice_currentUpdateIndex(uint32 marketIndex, address user)
    external
    view
    returns (uint256);

  function userLastInteractionTimestamp(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint32 timestamp, uint224 effectiveAmountMinted);

  function userNextPrice_paymentToken_depositAmount(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function userNextPrice_syntheticToken_redeemAmount(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);

  function userNextPrice_syntheticToken_toShiftAwayFrom_marketSide(
    uint32 marketIndex,
    bool isLong,
    address user
  ) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

/*
 * Manages price feeds from different oracle implementations.
 */
interface IOracleManagerBasicFollowingPriceMock {
  struct PriceData {
    uint128 previousPrice;
    uint128 currentPrice;
    bool wasIntermediatePrice;
  }

  function initializeOracle() external returns (uint128 initialPrice);

  function updatePrice() external returns (PriceData memory);

  /*
   * Returns the latest price from the oracle feed.
   */
  function latestPrice() external view returns (uint128);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

/**
@title SyntheticToken
@notice An ERC20 token that tracks or inversely tracks the price of an
        underlying asset with floating exposure.
*/
interface ISyntheticToken {
  // function MINTER_ROLE() external returns (bytes32);

  function mint(address, uint256) external;

  function totalSupply() external returns (uint256);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

/// @notice Manages yield accumulation for the LongShort contract. Each market is deployed with its own yield manager to simplify the bookkeeping, as different markets may share a payment token and yield pool.
abstract contract IYieldManager {
  event ClaimAaveRewardTokenToTreasury(uint256 amount);

  event YieldDistributed(uint256 unrealizedYield, uint256 treasuryYieldPercent_e18);

  /// @dev This is purely saving some gas, but the subgraph will know how much is due for the treasury at all times - no need to include in event.
  event WithdrawTreasuryFunds();

  /// @notice distributed yield not yet transferred to the treasury
  function totalReservedForTreasury() external virtual returns (uint256);

  /// @notice Deposits the given amount of payment tokens into this yield manager.
  /// @param amount Amount of payment token to deposit
  function depositPaymentToken(uint256 amount) external virtual;

  /// @notice Allows the LongShort pay out a user from tokens already withdrawn from Aave
  /// @param user User to recieve the payout
  /// @param amount Amount of payment token to pay to user
  function transferPaymentTokensToUser(address user, uint256 amount) external virtual;

  /// @notice Withdraws the given amount of tokens from this yield manager.
  /// @param amount Amount of payment token to withdraw
  function removePaymentTokenFromMarket(uint256 amount) external virtual;

  /**    
    @notice Calculates and updates the yield allocation to the treasury and the market
    @dev treasuryPercent = 1 - marketPercent
    @param totalValueRealizedForMarket total value of long and short side of the market
    @param treasuryYieldPercent_e18 Percentage of yield in base 1e18 that is allocated to the treasury
    @return amountForMarketIncentives The market allocation of the yield
  */
  function distributeYieldForTreasuryAndReturnMarketAllocation(
    uint256 totalValueRealizedForMarket,
    uint256 treasuryYieldPercent_e18
  ) external virtual returns (uint256 amountForMarketIncentives);

  /// @notice Withdraw treasury allocated accrued yield from the lending pool to the treasury contract
  function withdrawTreasuryFunds() external virtual;

  /// @notice Initializes a specific yield manager to a given market
  function initializeForMarket() external virtual;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../interfaces/ISyntheticToken.sol";
import "../interfaces/ILongShort.sol";
import "../interfaces/IYieldManager.sol";
import "../interfaces/IOracleManagerBasicFollowingPriceMock.sol";
import "../abstract/AccessControlledAndUpgradeable.sol";
import "../GEMS.sol";

/**
 **** visit https://float.capital *****
 */

/// @title Core logic of Float Protocal markets
/// @author float.capital
/// @notice visit https://float.capital for more info
/// @dev All functions in this file are currently `virtual`. This is NOT to encourage inheritance.
/// It is merely for convenince when unit testing.
/// @custom:auditors This contract balances long and short sides.
contract Market is AccessControlledAndUpgradeable {
  //Using Open Zeppelin safe transfer library for token transfers
  using SafeERC20 for IERC20;

  event NthPriceDeposit(
    bool indexed isLong,
    uint256 depositAdded,
    address indexed user,
    uint32 indexed oracleUpdateIndex
  );

  event NthPriceRedeem(
    bool indexed isLong,
    uint256 synthRedeemed,
    address indexed user,
    uint32 indexed oracleUpdateIndex
  );

  event NthPriceSyntheticPositionShift(
    bool indexed isShiftFromLong,
    uint256 synthShifted,
    address indexed user,
    uint32 indexed oracleUpdateIndex
  );

  event ExecuteNextPriceSettlementsUserSeparateMarket(
    address indexed user,
    uint256 indexed updateIndex
  );

  event SeparateMarketLaunchedAndSeeded(
    uint32 marketIndex,
    uint256 initialSeed,
    uint256 marketLeverage,
    address admin,
    address oracleManager,
    address paymentToken,
    address longTokenAddress,
    address shortTokenAddress,
    int256 initialAssetPrice
  );

  event SystemStateUpdatedSeparateMarket(
    uint32 indexed updateIndex,
    int256 underlyingAssetPrice,
    uint256 longValue,
    uint256 shortValue,
    uint256 longPrice,
    uint256 shortPrice
  );

  /*╔═════════════════════════════╗
    ║          VARIABLES          ║
    ╚═════════════════════════════╝*/

  /* ══════ Fixed-precision constants ══════ */
  /// @notice this is the address that permanently locked initial liquidity for markets is held by.
  /// These tokens will never move so market can never have zero liquidity on a side.
  /// @dev f10a7 spells float in hex - for fun - important part is that the private key for this address in not known.
  address constant PERMANENT_INITIAL_LIQUIDITY_HOLDER =
    0xf10A7_F10A7_f10A7_F10a7_F10A7_f10a7_F10A7_f10a7;

  uint256 private constant SECONDS_IN_A_YEAR_e18 = 315576e20;

  uint32 private constant marketsfuturePriceIndexLength_UNUSED = 2;

  /// @dev an empty allocation of storage for use in future upgrades - inspiration from OZ:
  ///      https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/10f0f1a95b1b0fd5520351886bae7a03490f1056/contracts/token/ERC20/ERC20Upgradeable.sol#L361
  uint256[45] private __constantsGap;

  /* ══════ Global state ══════ */
  uint32 public marketIndex;

  address public immutable longShort; // original core contract
  address public immutable gems;
  uint256 public immutable marketTreasurySplitGradient_e18;
  uint256 public immutable marketLeverage_e18;
  address public immutable paymentToken;
  address public yieldManager;
  address public oracleManager;

  uint256[45] private __globalStateGap;

  /* ══════ Market specific ══════ */

  uint32 public marketUpdateIndex;

  uint256[44] private __marketStateGap;

  /* ══════ Market + position (long/short) specific ══════ */
  mapping(bool => address) public syntheticTokens;

  struct MarketSideValueInPaymentToken {
    // this has a maximum size of `2^128=3.4028237e+38` units of payment token which is amply sufficient for our markets
    uint128 value_long;
    uint128 value_short;
  }
  MarketSideValueInPaymentToken public marketSideValueInPaymentToken;

  struct SynthPriceInPaymentToken {
    // this has a maximum size of `2^128=3.4028237e+38` units of payment token which is amply sufficient for our markets
    uint128 price_long;
    uint128 price_short;
  }
  mapping(uint256 => SynthPriceInPaymentToken) public syntheticToken_priceSnapshot;

  uint256[43] private __marketPositonStateGap;

  /* ══════ User specific ══════ */
  mapping(address => uint32[16]) /* eg. 2 storage slots used for followingPrice */
    public userNextPrice_updateIndexes;

  mapping(bool => mapping(address => uint256[16])) public userNextPrice_paymentToken_depositAmount;
  mapping(bool => mapping(address => uint256[16])) public userNextPrice_syntheticToken_redeemAmount;
  mapping(bool => mapping(address => uint256[16]))
    public userNextPrice_syntheticToken_toShiftAwayFrom_marketSide;

  mapping(bool => uint256[16]) public batched_amountPaymentToken_deposit;
  mapping(bool => uint256[16]) public batched_amountSyntheticToken_redeem;
  mapping(bool => uint256[16]) public batched_amountSyntheticToken_toShiftAwayFrom_marketSide;

  constructor(
    uint256 _marketTreasurySplitGradient_e18,
    uint256 _marketLeverage_e18,
    address _paymentToken,
    address _gems,
    address _longShort
  ) {
    require(_marketLeverage_e18 <= 50e18 && _marketLeverage_e18 >= 1e17, "Incorrect leverage");
    marketTreasurySplitGradient_e18 = _marketTreasurySplitGradient_e18;
    marketLeverage_e18 = _marketLeverage_e18;
    paymentToken = _paymentToken;

    longShort = _longShort; // original core contract
    gems = _gems;
  }

  event ConfigChange(uint256 configChangeType, uint256 value1, uint256 value2);

  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  // This is used for testing (as opposed to onlyRole)
  function adminOnlyModifierLogic() internal virtual {
    _checkRole(ADMIN_ROLE, msg.sender);
  }

  modifier adminOnly() {
    adminOnlyModifierLogic();
    _;
  }

  modifier longShortOnly() {
    require(msg.sender == longShort, "Not longshort");
    _;
  }

  modifier updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(address user) {
    _updateSystemStateInternal();
    _executeOutstandingNextPriceSettlements(user);
    _;
  }

  function gemCollectingModifierLogic(address user) internal virtual {
    GEMS(gems).gm(user);
  }

  modifier gemCollecting(address user) {
    gemCollectingModifierLogic(user);
    _;
  }

  /*╔═══════════════════╗
    ║       ADMIN       ║
    ╚═══════════════════╝*/

  /// @notice Update oracle for a market
  /// @dev Can only be called by the current admin.
  /// @param _newOracleManager Address of the replacement oracle manager.
  function updateMarketOracle(address _newOracleManager) external adminOnly {
    // NOTE: we could also upgrade this contract to reference the new oracle potentially and have it as immutable
    // If not a oracle contract this would break things.. Test's arn't validating this
    // Ie require isOracle interface - ERC165
    address previousOracleManager = oracleManager;
    oracleManager = _newOracleManager;
    emit ConfigChange(
      100,
      uint256(uint160(previousOracleManager)),
      uint256(uint160(_newOracleManager))
    );
  }

  /*╔═════════════════════════════╗
    ║       CONTRACT SET-UP       ║
    ╚═════════════════════════════╝*/

  /// @notice Sets a market as active once it has already been setup by createNewSyntheticMarket.
  /// @dev Seperated from createNewSyntheticMarket due to gas considerations.
  /// @param initialMarketSeedForEachMarketSide Amount of payment token that will be deposited in each market side to seed the market.
  /// for market sides in unbalanced markets. See Staker.sol
  function initialize(
    uint256 initialMarketSeedForEachMarketSide,
    address seederAndAdmin,
    uint32 _marketIndex,
    address _oracleManager,
    address _yieldManager,
    address syntheticTokenLong,
    address syntheticTokenShort
  ) external longShortOnly returns (bool initializationSuccess) {
    require(
      // You require at least 1e12 (1 payment token with 18 decimal places) of the underlying payment token to seed the market.
      initialMarketSeedForEachMarketSide >= 1e12,
      "Insufficient market seed"
    );
    require(
      seederAndAdmin != address(0) &&
        _oracleManager != address(0) &&
        _yieldManager != address(0) &&
        syntheticTokenLong != address(0) &&
        syntheticTokenShort != address(0)
    );
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(seederAndAdmin);

    oracleManager = _oracleManager;
    yieldManager = _yieldManager;

    marketIndex = _marketIndex;

    // Set this value to one initially - 0 is a null value and thus potentially bug prone.
    marketUpdateIndex = 1;

    syntheticTokens[true] = syntheticTokenLong;
    syntheticTokens[false] = syntheticTokenShort;

    uint256 amountToLockInYieldManager = initialMarketSeedForEachMarketSide * 2;
    IERC20(paymentToken).safeTransferFrom(seederAndAdmin, yieldManager, amountToLockInYieldManager);
    IYieldManager(yieldManager).depositPaymentToken(amountToLockInYieldManager);
    ISyntheticToken(syntheticTokens[true]).mint(
      PERMANENT_INITIAL_LIQUIDITY_HOLDER,
      initialMarketSeedForEachMarketSide
    );
    ISyntheticToken(syntheticTokens[false]).mint(
      PERMANENT_INITIAL_LIQUIDITY_HOLDER,
      initialMarketSeedForEachMarketSide
    );
    marketSideValueInPaymentToken = MarketSideValueInPaymentToken(
      SafeCast.toUint128(initialMarketSeedForEachMarketSide),
      SafeCast.toUint128(initialMarketSeedForEachMarketSide)
    );

    IOracleManagerBasicFollowingPriceMock.PriceData
      memory oracleUpdates = IOracleManagerBasicFollowingPriceMock(oracleManager).updatePrice();

    emit SeparateMarketLaunchedAndSeeded(
      marketIndex,
      initialMarketSeedForEachMarketSide,
      marketLeverage_e18,
      seederAndAdmin,
      _oracleManager,
      paymentToken,
      syntheticTokenLong,
      syntheticTokenShort,
      int256(int128(oracleUpdates.currentPrice))
    );

    // Return true to drastically reduce chance of making mistakes with this.
    return true;
  }

  /*╔══════════════════════════════╗
    ║       GETTER FUNCTIONS       ║
    ╚══════════════════════════════╝*/

  /// @notice Calculates the conversion rate from synthetic tokens to payment tokens.
  /// @dev Synth tokens have a fixed 18 decimals.
  /// @param amountPaymentTokenBackingSynth Amount of payment tokens in that token's lowest denomination.
  /// @param amountSyntheticToken Amount of synth token in wei.
  /// @return syntheticTokenPrice The calculated conversion rate in base 1e18.
  function _getSyntheticTokenPrice(
    uint256 amountPaymentTokenBackingSynth,
    uint256 amountSyntheticToken
  ) internal pure virtual returns (uint256 syntheticTokenPrice) {
    return (amountPaymentTokenBackingSynth * 1e18) / amountSyntheticToken;
  }

  /// @notice Converts synth token amounts to payment token amounts at a synth token price.
  /// @dev Price assumed base 1e18.
  /// @param amountSyntheticToken Amount of synth token in wei.
  /// @param syntheticTokenPriceInPaymentTokens The conversion rate from synth to payment tokens in base 1e18.
  /// @return amountPaymentToken The calculated amount of payment tokens in token's lowest denomination.
  function _getAmountPaymentToken(
    uint256 amountSyntheticToken,
    uint256 syntheticTokenPriceInPaymentTokens
  ) internal pure virtual returns (uint256 amountPaymentToken) {
    return (amountSyntheticToken * syntheticTokenPriceInPaymentTokens) / 1e18;
  }

  /// @notice Converts payment token amounts to synth token amounts at a synth token price.
  /// @dev  Price assumed base 1e18.
  /// @param amountPaymentTokenBackingSynth Amount of payment tokens in that token's lowest denomination.
  /// @param syntheticTokenPriceInPaymentTokens The conversion rate from synth to payment tokens in base 1e18.
  /// @return amountSyntheticToken The calculated amount of synthetic token in wei.
  function _getAmountSyntheticToken(
    uint256 amountPaymentTokenBackingSynth,
    uint256 syntheticTokenPriceInPaymentTokens
  ) internal pure virtual returns (uint256 amountSyntheticToken) {
    return (amountPaymentTokenBackingSynth * 1e18) / syntheticTokenPriceInPaymentTokens;
  }

  /**
  @notice Calculate the amount of target side synthetic tokens that are worth the same
          amount of payment tokens as X many synthetic tokens on origin side.
          The resulting equation comes from simplifying this function

            _getAmountSyntheticToken(
              _getAmountPaymentToken(
                amountOriginSynth,
                priceOriginSynth
              ),
              priceTargetSynth)

            Unpacking the function we get:
            ((amountOriginSynth * priceOriginSynth) / 1e18) * 1e18 / priceTargetSynth
              And simplifying this we get:
            (amountOriginSynth * priceOriginSynth) / priceTargetSynth
  @param amountSyntheticTokens_originSide Amount of synthetic tokens on origin side
  @param syntheticTokenPrice_originSide Price of origin side's synthetic token
  @param syntheticTokenPrice_targetSide Price of target side's synthetic token
  @return equivalentAmountSyntheticTokensOnTargetSide Amount of synthetic token on target side
  */
  function _getEquivalentAmountSyntheticTokensOnTargetSide(
    uint256 amountSyntheticTokens_originSide,
    uint256 syntheticTokenPrice_originSide,
    uint256 syntheticTokenPrice_targetSide
  ) internal pure virtual returns (uint256 equivalentAmountSyntheticTokensOnTargetSide) {
    equivalentAmountSyntheticTokensOnTargetSide =
      (amountSyntheticTokens_originSide * syntheticTokenPrice_originSide) /
      syntheticTokenPrice_targetSide;
  }

  function get_syntheticToken_priceSnapshot_side(bool isLong, uint256 priceSnapshotIndex)
    public
    view
    returns (uint256 price)
  {
    if (isLong) {
      price = uint256(syntheticToken_priceSnapshot[priceSnapshotIndex].price_long);
    } else {
      price = uint256(syntheticToken_priceSnapshot[priceSnapshotIndex].price_short);
    }
  }

  /// @notice Given an executed next price shift from tokens on one market side to the other,
  /// determines how many other side tokens the shift was worth.
  /// @dev Intended for use primarily by Staker.sol
  /// @param amountSyntheticToken_redeemOnOriginSide Amount of synth token in wei.
  /// @param isShiftFromLong Whether the token shift is from long to short (true), or short to long (false).
  /// @param priceSnapshotIndex Index which identifies which synth prices to use.
  /// @return amountSyntheticTokensToMintOnTargetSide The amount in wei of tokens for the other side that the shift was worth.
  function getAmountSyntheticTokenToMintOnTargetSide(
    uint256 amountSyntheticToken_redeemOnOriginSide,
    bool isShiftFromLong,
    uint256 priceSnapshotIndex
  ) public view virtual returns (uint256 amountSyntheticTokensToMintOnTargetSide) {
    SynthPriceInPaymentToken memory priceSnapshot = syntheticToken_priceSnapshot[
      priceSnapshotIndex
    ];

    if (isShiftFromLong) {
      amountSyntheticTokensToMintOnTargetSide = _getEquivalentAmountSyntheticTokensOnTargetSide(
        amountSyntheticToken_redeemOnOriginSide,
        uint256(priceSnapshot.price_long),
        uint256(priceSnapshot.price_short)
      );
    } else {
      amountSyntheticTokensToMintOnTargetSide = _getEquivalentAmountSyntheticTokensOnTargetSide(
        amountSyntheticToken_redeemOnOriginSide,
        uint256(priceSnapshot.price_short),
        uint256(priceSnapshot.price_long)
      );
    }
  }

  /**
  @notice The amount of a synth token a user is owed following a batch execution.
    4 possible states for next price actions:
        - "Pending" - means the next price update hasn't happened or been enacted on by the updateSystemState function.
        - "Confirmed" - means the next price has been updated by the updateSystemState function. There is still
        -               outstanding (lazy) computation that needs to be executed per user in the batch.
        - "Settled" - there is no more computation left for the user.
        - "Non-existent" - user has no next price actions.
    This function returns a calculated value only in the case of 'confirmed' next price actions.
    It should return zero for all other types of next price actions.
  @dev Used in SyntheticToken.sol balanceOf to allow for automatic reflection of next price actions.
  @param user The address of the user for whom to execute the function for.
  @param isLong Whether it is for the long synthetic asset or the short synthetic asset.
  @return confirmedButNotSettledBalance The amount in wei of tokens that the user is owed.
  */
  /// TODO: NthPriceExec
  function getUsersConfirmedButNotSettledSynthBalance(address user, bool isLong)
    external
    view
    virtual
    returns (uint256 confirmedButNotSettledBalance)
  {
    uint32 currentMarketUpdateIndex = marketUpdateIndex;

    uint256 index = 0;
    uint32 userCurrentUpdateIndex = userNextPrice_updateIndexes[user][index];

    while (userCurrentUpdateIndex != 0 && userCurrentUpdateIndex <= currentMarketUpdateIndex) {
      uint256 updateSlot = userCurrentUpdateIndex % marketsfuturePriceIndexLength_UNUSED;
      uint256 userNextPrice_currentUpdateIndex = userNextPrice_updateIndexes[user][updateSlot];
      if (
        userNextPrice_currentUpdateIndex != 0 &&
        userNextPrice_currentUpdateIndex <= currentMarketUpdateIndex
      ) {
        uint256 amountPaymentTokenDeposited = userNextPrice_paymentToken_depositAmount[isLong][
          user
        ][updateSlot];

        uint256 syntheticTokenPrice;
        uint256 syntheticTokenPriceOnOriginSideOfShift;

        if (isLong) {
          syntheticTokenPrice = uint256(
            syntheticToken_priceSnapshot[userNextPrice_currentUpdateIndex].price_long
          );
          syntheticTokenPriceOnOriginSideOfShift = uint256(
            syntheticToken_priceSnapshot[userNextPrice_currentUpdateIndex].price_short
          );
        } else {
          syntheticTokenPriceOnOriginSideOfShift = uint256(
            syntheticToken_priceSnapshot[userNextPrice_currentUpdateIndex].price_long
          );
          syntheticTokenPrice = uint256(
            syntheticToken_priceSnapshot[userNextPrice_currentUpdateIndex].price_short
          );
        }

        if (amountPaymentTokenDeposited > 0) {
          confirmedButNotSettledBalance = _getAmountSyntheticToken(
            amountPaymentTokenDeposited,
            syntheticTokenPrice
          );
        }

        uint256 amountSyntheticTokensToBeShiftedAwayFromOriginSide = userNextPrice_syntheticToken_toShiftAwayFrom_marketSide[
            !isLong
          ][user][updateSlot];

        if (amountSyntheticTokensToBeShiftedAwayFromOriginSide > 0) {
          confirmedButNotSettledBalance += _getEquivalentAmountSyntheticTokensOnTargetSide(
            amountSyntheticTokensToBeShiftedAwayFromOriginSide,
            syntheticTokenPriceOnOriginSideOfShift,
            syntheticTokenPrice
          );
        }
      }
      ++index;
      userCurrentUpdateIndex = userNextPrice_updateIndexes[user][index];
    }
  }

  /**
   @notice Calculates the percentage in base 1e18 of how much of the accrued yield
   for a market should be allocated to treasury.
   @dev For gas considerations also returns whether the long side is imbalanced.
   @dev For gas considerations totalValueLockedInMarket is passed as a parameter as the function
   calling this function has pre calculated the value
   @param longValue The current total payment token value of the long side of the market.
   @param shortValue The current total payment token value of the short side of the market.
   @param totalValueLockedInMarket Total payment token value of both sides of the market.
   @return isLongSideUnderbalanced Whether the long side initially had less value than the short side.
   @return treasuryYieldPercent_e18 The percentage in base 1e18 of how much of the accrued yield
   for a market should be allocated to treasury.
   */
  function _getYieldSplit(
    uint256 longValue,
    uint256 shortValue,
    uint256 totalValueLockedInMarket
  ) internal view virtual returns (bool isLongSideUnderbalanced, uint256 treasuryYieldPercent_e18) {
    isLongSideUnderbalanced = longValue < shortValue;
    uint256 imbalance;

    unchecked {
      if (isLongSideUnderbalanced) {
        imbalance = shortValue - longValue;
      } else {
        imbalance = longValue - shortValue;
      }
    }
    // marketTreasurySplitGradient_e18 may be adjusted to ensure yield is given
    // to the market at a desired rate e.g. if a market tends to become imbalanced
    // frequently then the gradient can be increased to funnel yield to the market
    // quicker.
    // See this equation in latex: https://ipfs.io/ipfs/QmXsW4cHtxpJ5BFwRcMSUw7s5G11Qkte13NTEfPLTKEx4x
    // Interact with this equation: https://www.desmos.com/calculator/pnl43tfv5b
    uint256 marketPercentCalculated_e18 = (imbalance * marketTreasurySplitGradient_e18) /
      totalValueLockedInMarket;

    uint256 marketPercent_e18 = Math.min(marketPercentCalculated_e18, 1e18);

    unchecked {
      treasuryYieldPercent_e18 = 1e18 - marketPercent_e18;
    }
  }

  /*╔══════════════════════════════╗
    ║       HELPER FUNCTIONS       ║
    ╚══════════════════════════════╝*/

  function _claimAndDistributeYield()
    internal
    virtual
    returns (MarketSideValueInPaymentToken memory currentMarketSideValueInPaymentToken)
  {
    currentMarketSideValueInPaymentToken = marketSideValueInPaymentToken;
    // Claiming and distributing the yield

    uint256 totalValueLockedInMarket = currentMarketSideValueInPaymentToken.value_long +
      currentMarketSideValueInPaymentToken.value_short;

    (bool isLongSideUnderbalanced, uint256 treasuryYieldPercent_e18) = _getYieldSplit(
      currentMarketSideValueInPaymentToken.value_long,
      currentMarketSideValueInPaymentToken.value_short,
      totalValueLockedInMarket
    );

    uint256 marketAmount = IYieldManager(yieldManager)
      .distributeYieldForTreasuryAndReturnMarketAllocation(
        totalValueLockedInMarket,
        treasuryYieldPercent_e18
      );

    // Take fee as simply 1% of notional over 1 year.
    // Value leaving long and short to treasury, this should be done carefully in yield manager!
    // order of where this is done is important.
    // This amount also potentially lumped together with funding rate fee + exposure fee ?
    // See what is simple and makes sense on the bottom line.

    if (marketAmount > 0) {
      if (isLongSideUnderbalanced) {
        currentMarketSideValueInPaymentToken.value_long += uint128(marketAmount);
      } else {
        currentMarketSideValueInPaymentToken.value_short += uint128(marketAmount);
      }
    }
  }

  /*╔══════════════════════════════╗
    ║       HELPER FUNCTIONS       ║
    ╚══════════════════════════════╝*/

  function _getValueChange(
    MarketSideValueInPaymentToken memory currentMarketSideValueInPaymentToken,
    uint128 previousPrice,
    uint128 currentPrice,
    uint256 marketsLeverage
  ) internal pure returns (int256 valueChange) {
    // Adjusting value of long and short pool based on price movement
    // The side/position with less liquidity has 100% percent exposure to the price movement.
    // The side/position with more liquidity will have exposure < 100% to the price movement.
    // I.e. Imagine $100 in longValue and $50 shortValue
    // long side would have $50/$100 = 50% exposure to price movements based on the liquidity imbalance.
    // min(longValue, shortValue) = $50 , therefore if the price change was -10% then
    // $50 * 10% = $5 gained for short side and conversely $5 lost for long side.
    int256 underbalancedSideValue = int256(
      Math.min(
        currentMarketSideValueInPaymentToken.value_long,
        currentMarketSideValueInPaymentToken.value_short
      )
    );

    // send a piece of value change to the treasury?
    // Again this reduces the value of totalValueLockedInMarket which means yield manager needs to be alerted.
    // See this equation in latex: https://ipfs.io/ipfs/QmPeJ3SZdn1GfxqCD4GDYyWTJGPMSHkjPJaxrzk2qTTPSE
    // Interact with this equation: https://www.desmos.com/calculator/t8gr6j5vsq
    valueChange =
      (int256(int128(currentPrice) - int256(int128(previousPrice))) *
        underbalancedSideValue *
        int256(marketsLeverage)) /
      (int256(int128(previousPrice)) * 1e18);

    /////// TODO add funding rates back - think how we want to structure them.

    // uint256 fundingRateMultiplier = fundingRateMultiplier_e18[marketIndex];
    // if (fundingRateMultiplier > 0) {
    //   //  slow drip interest funding payment here.
    //   //  recheck yield hasn't tipped the market.
    //   if (
    //     currentMarketSideValueInPaymentToken.value_long <
    //     currentMarketSideValueInPaymentToken.value_short
    //   ) {
    //     valueChange += int256(
    //       _calculateFundingAmount(
    //         marketIndex,
    //         fundingRateMultiplier,
    //         currentMarketSideValueInPaymentToken.currentMarketSideValueInPaymentToken.value_short,
    //         currentMarketSideValueInPaymentToken.currentMarketSideValueInPaymentToken.value_long
    //       )
    //     );
    //   } else {
    //     valueChange -= int256(
    //       _calculateFundingAmount(
    //         marketIndex,
    //         fundingRateMultiplier,
    //         currentMarketSideValueInPaymentToken.currentMarketSideValueInPaymentToken.value_long,
    //         currentMarketSideValueInPaymentToken.currentMarketSideValueInPaymentToken.value_short
    //       )
    //     );
    //   }
    // }
  }

  /// @notice First gets yield from the yield manager and allocates it to market and treasury.
  /// It then allocates the full market yield portion to the underbalanced side of the market.
  /// NB this function also adjusts the value of the long and short side based on the latest
  /// price of the underlying asset received from the oracle. This function should ideally be
  /// called everytime there is an price update from the oracle. We have built a bot that does this.
  /// The system is still perectly safe if not called every price update, the synthetic will just
  /// less closely track the underlying asset.
  /// @dev In one function as yield should be allocated before rebalancing.
  /// This prevents an attack whereby the user imbalances a side to capture all accrued yield.
  /// @param oracleUpdates Object representing latest oracle changes.
  function _rebalanceMarkets(
    IOracleManagerBasicFollowingPriceMock.PriceData memory oracleUpdates,
    MarketSideValueInPaymentToken memory currentMarketSideValueInPaymentToken
  ) internal virtual {
    uint128 previousPrice = oracleUpdates.previousPrice;

    if (oracleUpdates.currentPrice != 0) {
      uint32 currentUpdateIndex = marketUpdateIndex + 1;

      int256 valueChange = _getValueChange(
        currentMarketSideValueInPaymentToken,
        previousPrice,
        oracleUpdates.currentPrice,
        marketLeverage_e18
      );
      currentMarketSideValueInPaymentToken = _rebalanceMarket(
        valueChange,
        currentMarketSideValueInPaymentToken,
        currentUpdateIndex
      );
      /*
      //// TODO: add this back potentially? This code must also run the `_batchConfirmOutstandingPendingActions` function
      if (oracleUpdates.wasIntermediatePrice) {
        /// As a gas saving shortcut, use the same price for the previous update too.
        //     This shouldn't happen in usual operation of the system with oracles
        syntheticToken_priceSnapshot[marketIndex][
          currentUpdateIndex + 1
        ] = syntheticToken_priceSnapshot[marketIndex][currentUpdateIndex];
        marketUpdateIndex[marketIndex] = currentUpdateIndex + 1;
      } else {
        marketUpdateIndex[marketIndex] = currentUpdateIndex;
      } */
      marketUpdateIndex = currentUpdateIndex;

      marketSideValueInPaymentToken = currentMarketSideValueInPaymentToken;
    }
  }

  function _rebalanceMarket(
    int256 valueChange,
    MarketSideValueInPaymentToken memory currentMarketSideValueInPaymentToken,
    uint32 currentMarketIndex
  ) internal virtual returns (MarketSideValueInPaymentToken memory) {
    if (valueChange < 0) {
      valueChange = -valueChange; // make value change positive

      // handle 'impossible' edge case where underlying price feed changes more than 100% downwards gracefully.
      if (uint256(valueChange) > currentMarketSideValueInPaymentToken.value_long) {
        valueChange =
          (int256(uint256(currentMarketSideValueInPaymentToken.value_long)) * 99999) /
          100000;
      }
      currentMarketSideValueInPaymentToken.value_long -= uint128(int128(valueChange));
      currentMarketSideValueInPaymentToken.value_short += uint128(int128(valueChange));
    } else {
      // handle 'impossible' edge case where underlying price feed changes more than 100% upwards gracefully.
      if (uint256(valueChange) > currentMarketSideValueInPaymentToken.value_short) {
        valueChange =
          (int256(uint256(currentMarketSideValueInPaymentToken.value_short)) * 99999) /
          100000;
      }
      currentMarketSideValueInPaymentToken.value_long += uint128(int128(valueChange));
      currentMarketSideValueInPaymentToken.value_short -= uint128(int128(valueChange));
    }

    SynthPriceInPaymentToken memory syntheticTokenPrice_inPaymentTokens = SynthPriceInPaymentToken(
      SafeCast.toUint128(
        _getSyntheticTokenPrice(
          currentMarketSideValueInPaymentToken.value_long,
          ISyntheticToken(syntheticTokens[true]).totalSupply()
        )
      ),
      SafeCast.toUint128(
        _getSyntheticTokenPrice(
          currentMarketSideValueInPaymentToken.value_short,
          ISyntheticToken(syntheticTokens[false]).totalSupply()
        )
      )
    );

    syntheticToken_priceSnapshot[currentMarketIndex] = syntheticTokenPrice_inPaymentTokens;

    (
      int256 long_changeInMarketValue_inPaymentToken,
      int256 short_changeInMarketValue_inPaymentToken
    ) = _batchConfirmOutstandingPendingActions(
        syntheticTokenPrice_inPaymentTokens,
        currentMarketIndex
      );

    currentMarketSideValueInPaymentToken.value_long = uint128(
      uint256(
        int128(currentMarketSideValueInPaymentToken.value_long) +
          long_changeInMarketValue_inPaymentToken
      )
    );
    currentMarketSideValueInPaymentToken.value_short = uint128(
      uint256(
        int128(currentMarketSideValueInPaymentToken.value_short) +
          short_changeInMarketValue_inPaymentToken
      )
    );

    return currentMarketSideValueInPaymentToken;
  }

  /*╔═══════════════════════════════╗
    ║     UPDATING SYSTEM STATE     ║
    ╚═══════════════════════════════╝*/

  /// @notice Updates the value of the long and short sides to account for latest oracle price updates
  /// and batches all next price actions.
  /// @dev To prevent front-running only executes on price change from an oracle.
  /// We assume the function will be called for each market at least once per price update.
  /// Note Even if not called on every price update, this won't affect security, it will only affect how closely
  /// the synthetic asset actually tracks the underlying asset.
  function _updateSystemStateInternal() internal virtual {
    // (uint32[] memory relevantIndexes, bool[] memory isRelevant) = _getRequieredUpdateIndexes(
    //   marketIndex
    // );
    // If a negative int is return this should fail.
    IOracleManagerBasicFollowingPriceMock.PriceData
      memory oracleUpdates = IOracleManagerBasicFollowingPriceMock(oracleManager).updatePrice();

    // uint256 currentMarketUpdateIndex = marketUpdateIndex[marketIndex];

    if (
      oracleUpdates.currentPrice > 0 /* need to make it part of oracle spec that it returns 0 if no updates */
    ) {
      MarketSideValueInPaymentToken memory newSideValues = _claimAndDistributeYield();

      _rebalanceMarkets(oracleUpdates, newSideValues);

      emit SystemStateUpdatedSeparateMarket(
        marketUpdateIndex,
        int256(int128(oracleUpdates.currentPrice)),
        marketSideValueInPaymentToken.value_long,
        marketSideValueInPaymentToken.value_short,
        syntheticToken_priceSnapshot[marketUpdateIndex].price_long,
        syntheticToken_priceSnapshot[marketUpdateIndex].price_short
      );
    }
  }

  /// @notice Updates the state of a market to account for the latest oracle price update.
  function updateSystemState() external {
    _updateSystemStateInternal();
  }

  /*╔══════════════════════════════════════╗
    ║       Nth Price Action Helpers       ║
    ╚══════════════════════════════════════╝*/

  function _setNew_userNextPrice_updateIndex(
    address user,
    uint256 nextUpdateIndex // TODO: should pass this in as a uint32 - didn't want to upset the rest of the code for now...
  ) internal {
    uint256 index = 0;
    uint32[16] memory updateIndexes = userNextPrice_updateIndexes[user];

    // TODO: logically verify and prove that this can't go out of range...
    while (updateIndexes[index] != 0 && updateIndexes[index] != nextUpdateIndex) {
      ++index;
    }

    userNextPrice_updateIndexes[user][index] = uint32(nextUpdateIndex);
  }

  /*╔═══════════════════════════╗
    ║       MINT POSITION       ║
    ╚═══════════════════════════╝*/

  /// @notice Allows users to mint synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @dev Called by external functions to mint either long or short. If a user mints multiple times before a price update, these are treated as a single mint.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  /// @param isLong Whether the mint is for a long or short synth.
  function _mintNextPrice(
    uint256 amount,
    address user,
    bool isLong
  )
    internal
    virtual
    updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(user)
    gemCollecting(user)
  {
    require(amount > 0, "Mint amount == 0");
    IERC20(paymentToken).safeTransferFrom(user, yieldManager, amount);

    uint32 nextUpdateIndex = marketUpdateIndex + 2;
    uint256 updateSlot = nextUpdateIndex % marketsfuturePriceIndexLength_UNUSED;
    batched_amountPaymentToken_deposit[isLong][updateSlot] += amount;
    userNextPrice_paymentToken_depositAmount[isLong][user][updateSlot] += amount;
    _setNew_userNextPrice_updateIndex(user, nextUpdateIndex);

    emit NthPriceDeposit(isLong, amount, user, nextUpdateIndex);
  }

  /// @notice Allows users to mint long synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  function mintLongNextPrice(uint256 amount) external {
    _mintNextPrice(amount, msg.sender, true);
  }

  /// @notice Allows users to mint short synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  function mintShortNextPrice(uint256 amount) external {
    _mintNextPrice(amount, msg.sender, false);
  }

  function mintNextPriceFor(
    uint256 amount,
    address user,
    bool isLong
  ) external virtual longShortOnly {
    _mintNextPrice(amount, user, isLong);
  }

  /*╔═══════════════════════════╗
    ║      REDEEM POSITION      ║
    ╚═══════════════════════════╝*/

  /// @notice Allows users to redeem their synthetic tokens for payment tokens. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @dev Called by external functions to redeem either long or short. Payment tokens are actually transferred to the user when executeOutstandingNextPriceSettlements is called from a function call by the user.
  /// @param tokens_redeem Amount in wei of synth tokens to redeem.
  /// @param isLong Whether this redeem is for a long or short synth.
  function _redeemNextPrice(
    uint256 tokens_redeem,
    address user,
    bool isLong
  )
    internal
    virtual
    updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(user)
    gemCollecting(user)
  {
    require(tokens_redeem > 0, "Redeem amount == 0");
    ISyntheticToken(syntheticTokens[isLong]).transferFrom(user, address(this), tokens_redeem);

    uint32 nextUpdateIndex = marketUpdateIndex + 2;
    uint256 updateSlot = nextUpdateIndex % marketsfuturePriceIndexLength_UNUSED;
    batched_amountSyntheticToken_redeem[isLong][updateSlot] += tokens_redeem;
    userNextPrice_syntheticToken_redeemAmount[isLong][user][updateSlot] += tokens_redeem;
    _setNew_userNextPrice_updateIndex(user, nextUpdateIndex);

    // marketRequiresPriceUpdates_UNUSED[
    //   nextUpdateIndex % marketsfuturePriceIndexLength_UNUSED
    // ] = true;

    emit NthPriceRedeem(isLong, tokens_redeem, user, nextUpdateIndex);
  }

  /// @notice  Allows users to redeem long synthetic assets for a market. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @param tokens_redeem Amount in wei of synth tokens to redeem at the next oracle price.
  function redeemLongNextPrice(uint256 tokens_redeem) external {
    _redeemNextPrice(tokens_redeem, msg.sender, true);
  }

  /// @notice  Allows users to redeem short synthetic assets for a market. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @param tokens_redeem Amount in wei of synth tokens to redeem at the next oracle price.
  function redeemShortNextPrice(uint256 tokens_redeem) external {
    _redeemNextPrice(tokens_redeem, msg.sender, false);
  }

  function redeemNextPriceFor(
    uint256 tokens_redeem,
    address user,
    bool isLong
  ) external virtual longShortOnly {
    _redeemNextPrice(tokens_redeem, user, isLong);
  }

  /*╔═══════════════════════════╗
    ║       SHIFT POSITION      ║
    ╚═══════════════════════════╝*/

  /// @notice  Allows users to shift their position from one side of the market to the other in a single transaction. To prevent front-running these shifts are executed on the next price update from the oracle.
  /// @dev Called by external functions to shift either way. Intended for primary use by Staker.sol
  /// @param amountSyntheticTokensToShift Amount in wei of synthetic tokens to shift from the one side to the other at the next oracle price update.
  /// @param isShiftFromLong Whether the token shift is from long to short (true), or short to long (false).
  function _shiftPositionNextPrice(
    uint256 amountSyntheticTokensToShift,
    address user,
    bool isShiftFromLong
  )
    internal
    virtual
    updateSystemStateMarketAndExecuteOutstandingNextPriceSettlements(user)
    gemCollecting(user)
  {
    require(amountSyntheticTokensToShift > 0, "Shift amount == 0");

    ISyntheticToken(syntheticTokens[isShiftFromLong]).transferFrom(
      user,
      address(this),
      amountSyntheticTokensToShift
    );

    uint32 nextUpdateIndex = marketUpdateIndex + marketsfuturePriceIndexLength_UNUSED;
    uint256 updateSlot = nextUpdateIndex % marketsfuturePriceIndexLength_UNUSED;
    batched_amountSyntheticToken_toShiftAwayFrom_marketSide[isShiftFromLong][
      updateSlot
    ] += amountSyntheticTokensToShift;

    userNextPrice_syntheticToken_toShiftAwayFrom_marketSide[isShiftFromLong][user][
      updateSlot
    ] += amountSyntheticTokensToShift;
    _setNew_userNextPrice_updateIndex(user, nextUpdateIndex);

    // marketRequiresPriceUpdates_UNUSED[marketIndex][
    //   nextUpdateIndex % marketsfuturePriceIndexLength_UNUSED
    // ] = true;

    emit NthPriceSyntheticPositionShift(
      isShiftFromLong,
      amountSyntheticTokensToShift,
      user,
      nextUpdateIndex
    );
  }

  /// @notice Allows users to shift their position from long to short in a single transaction. To prevent front-running these shifts are executed on the next price update from the oracle.
  /// @param amountSyntheticTokensToShift Amount in wei of synthetic tokens to shift from long to short the next oracle price update.
  function shiftPositionFromLongNextPrice(uint256 amountSyntheticTokensToShift) external {
    _shiftPositionNextPrice(amountSyntheticTokensToShift, msg.sender, true);
  }

  /// @notice Allows users to shift their position from short to long in a single transaction. To prevent front-running these shifts are executed on the next price update from the oracle.
  /// @param amountSyntheticTokensToShift Amount in wei of synthetic tokens to shift from the short to long at the next oracle price update.
  function shiftPositionFromShortNextPrice(uint256 amountSyntheticTokensToShift) external {
    _shiftPositionNextPrice(amountSyntheticTokensToShift, msg.sender, false);
  }

  function shiftPositionNextPriceFor(
    uint256 amountSyntheticTokensToShift,
    address user,
    bool isShiftFromLong
  ) external virtual longShortOnly {
    _shiftPositionNextPrice(amountSyntheticTokensToShift, user, isShiftFromLong);
  }

  /*╔════════════════════════════════╗
    ║     NEXT PRICE SETTLEMENTS     ║
    ╚════════════════════════════════╝*/

  /// @notice Transfers outstanding synth tokens from a next price mint to the user.
  /// @dev The outstanding synths should already be reflected for the user due to balanceOf in SyntheticToken.sol, this just does the accounting.
  /// @param user The address of the user for whom to execute the function for.
  /// @param isLong Whether this is for the long or short synth for the market.
  function _executeOutstandingNextPriceMints(
    address user,
    uint32 updateIndex,
    bool isLong
  ) internal virtual {
    uint256 updateSlot = updateIndex % marketsfuturePriceIndexLength_UNUSED;

    uint256 currentPaymentTokenDepositAmount = userNextPrice_paymentToken_depositAmount[isLong][
      user
    ][updateSlot];
    if (currentPaymentTokenDepositAmount > 0) {
      userNextPrice_paymentToken_depositAmount[isLong][user][updateSlot] = 0;
      uint256 amountSyntheticTokensToTransferToUser = _getAmountSyntheticToken(
        currentPaymentTokenDepositAmount,
        get_syntheticToken_priceSnapshot_side(isLong, updateIndex)
      );
      ISyntheticToken(syntheticTokens[isLong]).transfer(
        user,
        amountSyntheticTokensToTransferToUser
      );
    }
  }

  /// @notice Transfers outstanding payment tokens from a next price redemption to the user.
  /// @param user The address of the user for whom to execute the function for.
  /// @param isLong Whether this is for the long or short synth for the market.
  function _executeOutstandingNextPriceRedeems(
    address user,
    uint32 updateIndex,
    bool isLong
  ) internal virtual {
    uint256 updateSlot = updateIndex % marketsfuturePriceIndexLength_UNUSED;
    uint256 currentSyntheticTokenRedemptions = userNextPrice_syntheticToken_redeemAmount[isLong][
      user
    ][updateSlot];
    if (currentSyntheticTokenRedemptions > 0) {
      userNextPrice_syntheticToken_redeemAmount[isLong][user][updateSlot] = 0;
      uint256 amountPaymentToken_toRedeem = _getAmountPaymentToken(
        currentSyntheticTokenRedemptions,
        get_syntheticToken_priceSnapshot_side(isLong, updateIndex)
      );

      IYieldManager(yieldManager).transferPaymentTokensToUser(user, amountPaymentToken_toRedeem);
    }
  }

  /// @notice Transfers outstanding synth tokens from a next price position shift to the user.
  /// @dev The outstanding synths should already be reflected for the user due to balanceOf in SyntheticToken.sol, this just does the accounting.
  /// @param user The address of the user for whom to execute the function for.
  /// @param isShiftFromLong Whether the token shift was from long to short (true), or short to long (false).
  function _executeOutstandingNextPriceTokenShifts(
    address user,
    uint32 updateIndex,
    bool isShiftFromLong
  ) internal virtual {
    uint256 updateSlot = updateIndex % marketsfuturePriceIndexLength_UNUSED;

    uint256 syntheticToken_toShiftAwayFrom_marketSide = userNextPrice_syntheticToken_toShiftAwayFrom_marketSide[
        isShiftFromLong
      ][user][updateSlot];
    if (syntheticToken_toShiftAwayFrom_marketSide > 0) {
      uint256 syntheticToken_toShiftTowardsTargetSide = getAmountSyntheticTokenToMintOnTargetSide(
        syntheticToken_toShiftAwayFrom_marketSide,
        isShiftFromLong,
        updateIndex
      );

      userNextPrice_syntheticToken_toShiftAwayFrom_marketSide[isShiftFromLong][user][
        updateSlot
      ] = 0;

      require(
        ISyntheticToken(syntheticTokens[!isShiftFromLong]).transfer(
          user,
          syntheticToken_toShiftTowardsTargetSide
        )
      );
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their next price actions for that update to that user.
  /// @dev Once the market has updated for the next price, should be guaranteed (through modifiers) to execute for a user before user initiation of new next price actions.
  /// @param user The address of the user for whom to execute the function.
  function _executeOutstandingNextPriceSettlements(address user) internal virtual {
    // TODO:
    //      - optimize
    //      - think of using a for loop with a break
    //      - think through out of bounds errors
    //      - make update index always uint32 (not uint256)
    uint256 index = 0;
    uint256 userCurrentUpdateIndex = userNextPrice_updateIndexes[user][index];

    while (userCurrentUpdateIndex != 0 && userCurrentUpdateIndex <= marketUpdateIndex) {
      _executeOutstandingNextPriceMints(user, uint32(userCurrentUpdateIndex), true);
      _executeOutstandingNextPriceMints(user, uint32(userCurrentUpdateIndex), false);
      _executeOutstandingNextPriceRedeems(user, uint32(userCurrentUpdateIndex), true);
      _executeOutstandingNextPriceRedeems(user, uint32(userCurrentUpdateIndex), false);
      _executeOutstandingNextPriceTokenShifts(user, uint32(userCurrentUpdateIndex), true);
      _executeOutstandingNextPriceTokenShifts(user, uint32(userCurrentUpdateIndex), false);

      userNextPrice_updateIndexes[user][index] = 0;

      emit ExecuteNextPriceSettlementsUserSeparateMarket(user, userCurrentUpdateIndex);
      ++index;
      userCurrentUpdateIndex = userNextPrice_updateIndexes[user][index];
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their next price actions for that update to that user.
  /// @param user The address of the user for whom to execute the function.
  function executeOutstandingNextPriceSettlementsUser(address user) external {
    _executeOutstandingNextPriceSettlements(user);
  }

  /*╔═══════════════════════════════════════════╗
    ║   BATCHED NEXT PRICE SETTLEMENT ACTIONS   ║
    ╚═══════════════════════════════════════════╝*/

  /// @notice Either transfers funds from the yield manager to this contract if redeems > deposits,
  /// and vice versa. The yield manager handles depositing and withdrawing the funds from a yield market.
  /// @dev When all batched next price actions are handled the total value in the market can either increase or decrease based on the value of mints and redeems.
  /// @param totalPaymentTokenValueChangeForMarket An int256 which indicates the magnitude and direction of the change in market value.
  function _handleTotalPaymentTokenValueChangeForMarketWithYieldManager(
    int256 totalPaymentTokenValueChangeForMarket
  ) internal virtual {
    if (totalPaymentTokenValueChangeForMarket > 0) {
      IYieldManager(yieldManager).depositPaymentToken(
        uint256(totalPaymentTokenValueChangeForMarket)
      );
    } else if (totalPaymentTokenValueChangeForMarket < 0) {
      // NB there will be issues here if not enough liquidity exists to withdraw
      // Boolean should be returned from yield manager and think how to appropriately handle this
      IYieldManager(yieldManager).removePaymentTokenFromMarket(
        uint256(-totalPaymentTokenValueChangeForMarket)
      );
    }
  }

  /// @notice Given a desired change in synth token supply, either mints or burns tokens to achieve that desired change.
  /// @dev When all batched next price actions are executed total supply for a synth can either increase or decrease.
  /// @param isLong Whether this function should execute for the long or short synth for the market.
  /// @param changeInSyntheticTokensTotalSupply The amount in wei by which synth token supply should change.
  function _handleChangeInSyntheticTokensTotalSupply(
    bool isLong,
    int256 changeInSyntheticTokensTotalSupply
  ) internal virtual {
    if (changeInSyntheticTokensTotalSupply > 0) {
      ISyntheticToken(syntheticTokens[isLong]).mint(
        address(this),
        uint256(changeInSyntheticTokensTotalSupply)
      );
    } else if (changeInSyntheticTokensTotalSupply < 0) {
      ISyntheticToken(syntheticTokens[isLong]).burn(uint256(-changeInSyntheticTokensTotalSupply));
    }
  }

  /**
  @notice Performs all batched next price actions on an oracle price update.
  @dev Mints or burns all synthetic tokens for this contract.

    After this function is executed all user actions in that batch are confirmed and can be settled individually by
      calling _executeOutstandingNexPriceSettlements for a given user.

    The maths here is safe from rounding errors since it always over estimates on the batch with division.
      (as an example (5/3) + (5/3) = 2 but (5+5)/3 = 10/3 = 3, so the batched action would mint one more)
  @param syntheticTokenPrice_inPaymentTokens The long+short synthetic token price for this oracle price update.
  @return long_changeInMarketValue_inPaymentToken The total value change for the long side after all batched actions are executed.
  @return short_changeInMarketValue_inPaymentToken The total value change for the short side after all batched actions are executed.
  */
  function _batchConfirmOutstandingPendingActions(
    SynthPriceInPaymentToken memory syntheticTokenPrice_inPaymentTokens,
    uint32 currentUpdateIndex
  )
    internal
    virtual
    returns (
      int128 long_changeInMarketValue_inPaymentToken,
      int128 short_changeInMarketValue_inPaymentToken
    )
  {
    int256 changeInSupply_syntheticToken_long;
    int256 changeInSupply_syntheticToken_short;
    uint256 updateSlot = currentUpdateIndex % marketsfuturePriceIndexLength_UNUSED;

    // NOTE: the only reason we are reusing amountForCurrentAction_workingVariable for all actions (redeemLong, redeemShort, mintLong, mintShort, shiftFromLong, shiftFromShort) is to reduce stack usage
    uint256 amountForCurrentAction_workingVariable = batched_amountPaymentToken_deposit[true][
      updateSlot
    ];

    // Handle batched deposits LONG
    if (amountForCurrentAction_workingVariable > 0) {
      long_changeInMarketValue_inPaymentToken = int128(
        uint128(amountForCurrentAction_workingVariable)
      );

      batched_amountPaymentToken_deposit[true][updateSlot] = 0;

      changeInSupply_syntheticToken_long = int256(
        _getAmountSyntheticToken(
          amountForCurrentAction_workingVariable,
          uint256(syntheticTokenPrice_inPaymentTokens.price_long)
        )
      );
    }

    // Handle batched deposits SHORT
    amountForCurrentAction_workingVariable = batched_amountPaymentToken_deposit[false][updateSlot];
    if (amountForCurrentAction_workingVariable > 0) {
      short_changeInMarketValue_inPaymentToken = int128(
        uint128(amountForCurrentAction_workingVariable)
      );

      batched_amountPaymentToken_deposit[false][updateSlot] = 0;

      changeInSupply_syntheticToken_short = int256(
        _getAmountSyntheticToken(
          amountForCurrentAction_workingVariable,
          uint256(syntheticTokenPrice_inPaymentTokens.price_short)
        )
      );
    }

    // Handle shift tokens from LONG to SHORT
    amountForCurrentAction_workingVariable = batched_amountSyntheticToken_toShiftAwayFrom_marketSide[
      true
    ][updateSlot];
    if (amountForCurrentAction_workingVariable > 0) {
      int256 paymentTokenValueChangeForShiftToShort = int256(
        _getAmountPaymentToken(
          amountForCurrentAction_workingVariable,
          uint256(syntheticTokenPrice_inPaymentTokens.price_long)
        )
      );

      long_changeInMarketValue_inPaymentToken -= int128(paymentTokenValueChangeForShiftToShort);
      short_changeInMarketValue_inPaymentToken += int128(paymentTokenValueChangeForShiftToShort);

      changeInSupply_syntheticToken_long -= int256(amountForCurrentAction_workingVariable);
      changeInSupply_syntheticToken_short += int256(
        _getEquivalentAmountSyntheticTokensOnTargetSide(
          amountForCurrentAction_workingVariable,
          uint256(syntheticTokenPrice_inPaymentTokens.price_long),
          uint256(syntheticTokenPrice_inPaymentTokens.price_short)
        )
      );

      batched_amountSyntheticToken_toShiftAwayFrom_marketSide[true][updateSlot] = 0;
    }

    // Handle shift tokens from SHORT to LONG
    amountForCurrentAction_workingVariable = batched_amountSyntheticToken_toShiftAwayFrom_marketSide[
      false
    ][updateSlot];
    if (amountForCurrentAction_workingVariable > 0) {
      int256 paymentTokenValueChangeForShiftToLong = int256(
        _getAmountPaymentToken(
          amountForCurrentAction_workingVariable,
          uint256(syntheticTokenPrice_inPaymentTokens.price_short)
        )
      );

      short_changeInMarketValue_inPaymentToken -= int128(paymentTokenValueChangeForShiftToLong);
      long_changeInMarketValue_inPaymentToken += int128(paymentTokenValueChangeForShiftToLong);

      changeInSupply_syntheticToken_short -= int256(amountForCurrentAction_workingVariable);
      changeInSupply_syntheticToken_long += int256(
        _getEquivalentAmountSyntheticTokensOnTargetSide(
          amountForCurrentAction_workingVariable,
          uint256(syntheticTokenPrice_inPaymentTokens.price_long),
          uint256(syntheticTokenPrice_inPaymentTokens.price_short)
        )
      );

      batched_amountSyntheticToken_toShiftAwayFrom_marketSide[false][updateSlot] = 0;
    }

    // Handle batched redeems LONG
    amountForCurrentAction_workingVariable = batched_amountSyntheticToken_redeem[true][updateSlot];
    if (amountForCurrentAction_workingVariable > 0) {
      long_changeInMarketValue_inPaymentToken -= int128(
        int256(
          _getAmountPaymentToken(
            amountForCurrentAction_workingVariable,
            uint256(syntheticTokenPrice_inPaymentTokens.price_long)
          )
        )
      );
      changeInSupply_syntheticToken_long -= int256(amountForCurrentAction_workingVariable);

      batched_amountSyntheticToken_redeem[true][updateSlot] = 0;
    }

    // Handle batched redeems SHORT
    amountForCurrentAction_workingVariable = batched_amountSyntheticToken_redeem[false][updateSlot];
    if (amountForCurrentAction_workingVariable > 0) {
      short_changeInMarketValue_inPaymentToken -= int128(
        int256(
          _getAmountPaymentToken(
            amountForCurrentAction_workingVariable,
            uint256(syntheticTokenPrice_inPaymentTokens.price_short)
          )
        )
      );
      changeInSupply_syntheticToken_short -= int256(amountForCurrentAction_workingVariable);

      batched_amountSyntheticToken_redeem[false][updateSlot] = 0;
    }

    // Batch settle payment tokens
    _handleTotalPaymentTokenValueChangeForMarketWithYieldManager(
      long_changeInMarketValue_inPaymentToken + short_changeInMarketValue_inPaymentToken
    );
    // Batch settle synthetic tokens
    _handleChangeInSyntheticTokensTotalSupply(true, changeInSupply_syntheticToken_long);
    _handleChangeInSyntheticTokensTotalSupply(false, changeInSupply_syntheticToken_short);
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./Market.sol";
//TODO remove after dev
import "hardhat/console.sol";
import "../oracles/template/OracleManagerFixedEpoch.sol";

contract MarketTieredLeverage is AccessControlledAndUpgradeable {
  using SafeERC20 for IERC20;

  enum PoolType {
    SHORT,
    LONG
  }

  struct PoolId {
    // TODO: move to use an enum rather than a bool for the pool type (long/short and future pool types)
    PoolType poolType;
    uint8 index;
  }

  event Deposit(
    PoolId indexed poodId,
    uint256 depositAdded,
    address indexed user,
    uint32 indexed epoch
  );

  event Redeem(
    PoolId indexed poodId,
    uint256 synthRedeemed,
    address indexed user,
    uint32 indexed epoch
  );

  /*
  // TODO: think through this more, unimplemented
  struct Shift {
    PoolId fromPool;
    PoolId toPool;
  }
  event SyntheticPositionShift(
    Shift indexed shiftedPools,
    uint256 synthShifted,
    address indexed user,
    uint32 indexed oracleUpdateIndex
  );
  */

  // TODO: think of edge-case where this is in EWT. Maybe just handled by the backend.
  event ExecuteEpochSettlementMintUser(
    PoolId indexed poodId,
    address indexed user,
    uint256 indexed epoch
  );
  event ExecuteEpochSettlementRedeemUser(
    PoolId indexed poodId,
    address indexed user,
    uint256 indexed epoch
  );

  struct PoolInfo {
    PoolType poolType;
    address token;
    uint256 leverage;
  }
  event SeparateMarketLaunchedAndSeeded(
    uint32 marketIndex,
    PoolInfo[] marketTiers,
    uint256 initialSeed,
    address admin,
    address oracleManager,
    address paymentToken,
    int256 initialAssetPrice
  );

  // Currently unused.
  event TierAdded(PoolInfo newTier, uint256 initialSeed);

  /// TODO: check gas implications of emitting a single event vs emitting many.
  // struct SystemUpdateInfo {
  //   uint32 epoch;
  //   uint128 underlyingAssetPrice;
  //   uint256 effectiveValueLongValue;
  //   uint256 effectiveValueShortValue;
  //   uint256 basePricelongPrice;
  //   uint256 basePriceshortPrice;
  // }
  // event SystemStateUpdatedSeparateMarket(
  //   // TODO: think how this event can be thinned
  //   SystemUpdateInfo[] systemUpdateInfo
  // );
  event SystemUpdateInfo(
    uint32 epoch,
    uint256 underlyingAssetPrice,
    int256 effectiveLiquidityValueChange
    // TODO: probably need the price
  );

  /* ══════ Fixed-precision constants ══════ */
  /// @notice this is the address that permanently locked initial liquidity for markets is held by.
  /// These tokens will never move so market can never have zero liquidity on a side.
  /// @dev f10a7 spells float in hex - for fun - important part is that the private key for this address in not known.
  address constant PERMANENT_INITIAL_LIQUIDITY_HOLDER =
    0xf10A7_F10A7_f10A7_F10a7_F10A7_f10a7_F10A7_f10a7;

  uint256 private constant SECONDS_IN_A_YEAR_e18 = 315576e20;

  uint32 private constant marketsFuturePriceIndexLength_UNUSED = 2;

  /// @dev an empty allocation of storage for use in future upgrades - inspiration from OZ:
  ///      https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/10f0f1a95b1b0fd5520351886bae7a03490f1056/contracts/token/ERC20/ERC20Upgradeable.sol#L361
  uint256[45] private __constantsGap;

  /* ══════ Global state ══════ */
  uint32 public marketIndex;
  uint32 public initialEpochStartTimestamp;

  address public immutable longShort; // original core contract
  address public immutable gems;
  address public immutable paymentToken;
  address public yieldManager;
  OracleManagerFixedEpoch public oracleManager;

  uint256[45] private __globalStateGap;

  /* ══════ Market specific ══════ */

  struct EpochInfo {
    // this is the index of the previous epoch that has finished
    uint32 epochIndex;
    uint32 epochTimestamp;
    uint32 latestExecutedEpochIndex;
    // Reference to Chainlink Index
    uint80 latestOraclePriceIdentifier;
  }

  EpochInfo public epochInfo;

  uint256[44] private __marketStateGap;

  // mapping from epoch number -> pooltype -> array of price snapshot
  // TODO - experiment with `uint128[8]` and check gas efficiency.
  mapping(uint256 => mapping(PoolType => uint256[8])) public syntheticToken_priceSnapshot;

  uint256[43] private __marketPositonStateGap;

  /* ══════ User specific ══════ */

  struct UserAction {
    uint32 correspondingEpoch;
    uint224 amount;
    // TODO: think how to pack this.
    uint256 nextEpochAmount;
  }

  //User Address => PoolType => UserAction Array
  mapping(address => mapping(PoolType => UserAction[8])) public user_paymentToken_depositAction;
  //User Address => PoolType => UserAction Array
  mapping(address => mapping(PoolType => UserAction[8])) public user_syntheticToken_redeemAction;

  //TODO implement shifting
  struct Pool {
    address token;
    uint256 value;
    uint256 leverage;
    uint256 batched_amountPaymentToken_deposit;
    uint256 batched_amountSyntheticToken_redeem;
    uint256 nextEpoch_batched_amountPaymentToken_deposit;
    uint256 nextEpoch_batched_amountSyntheticToken_redeem;
  }

  mapping(PoolType => Pool[8]) public pools;
  uint256[32] public numberOfPoolsOfType;

  /*╔═════════════════════════════╗
    ║          MODIFIERS          ║
    ╚═════════════════════════════╝*/

  // This is used for testing (as opposed to onlyRole)
  function adminOnlyModifierLogic() internal virtual {
    _checkRole(ADMIN_ROLE, msg.sender);
  }

  modifier adminOnly() {
    adminOnlyModifierLogic();
    _;
  }

  modifier longShortOnly() {
    require(msg.sender == longShort, "Not longshort");
    _;
  }

  function gemCollectingModifierLogic(address user) internal virtual {
    // TODO: fix me - on market deploy, make new market have GEM minter role.
    // GEMS(gems).gm(user);
  }

  modifier gemCollecting(address user) {
    gemCollectingModifierLogic(user);
    _;
  }

  constructor(
    address _paymentToken,
    address _gems,
    address _longShort
  ) {
    require(_paymentToken != address(0) && _gems != address(0) && _longShort != address(0));
    paymentToken = _paymentToken;

    longShort = _longShort; // original core contract
    gems = _gems;
  }

  function initializePools(
    Pool[] memory _longPools,
    Pool[] memory _shortPools,
    uint256 initialMarketSeedForEachPool,
    address seederAndAdmin,
    uint32 _marketIndex,
    address _oracleManager,
    address _yieldManager
  ) external longShortOnly returns (bool initializationSuccess) {
    require(
      // You require at least 1e12 (1 payment token with 12 decimal places) of the underlying payment token to seed the market.
      initialMarketSeedForEachPool >= 1e12,
      "Insufficient market seed"
    );
    require(
      seederAndAdmin != address(0) && _oracleManager != address(0) && _yieldManager != address(0)
    );
    // The below function ensures that this contract can't be re-initialized!
    _AccessControlledAndUpgradeable_init(seederAndAdmin);

    oracleManager = OracleManagerFixedEpoch(_oracleManager);
    yieldManager = _yieldManager;

    marketIndex = _marketIndex;

    // Set this value to one initially - 0 is a null value and thus potentially bug prone.
    epochInfo.epochIndex = uint32(oracleManager.getLatestEpochIndex());
    epochInfo.epochTimestamp = uint32(oracleManager.getEpochStartTimestamp());
    epochInfo.latestExecutedEpochIndex = epochInfo.epochIndex;
    (uint80 latestRoundId, int256 initialAssetPrice, , , ) = oracleManager.latestRoundData();
    epochInfo.latestOraclePriceIdentifier = latestRoundId;

    uint256 amountToLockInYieldManager = initialMarketSeedForEachPool *
      (_shortPools.length + _longPools.length);
    //TODO May only require seeding one tier on long and short sides
    IERC20(paymentToken).safeTransferFrom(seederAndAdmin, yieldManager, amountToLockInYieldManager);
    IYieldManager(yieldManager).depositPaymentToken(amountToLockInYieldManager);

    PoolInfo[] memory poolInfo = new PoolInfo[](_longPools.length + _shortPools.length);

    numberOfPoolsOfType[uint8(PoolType.LONG)] = uint8(_longPools.length);

    for (uint256 i = 0; i < _longPools.length; i++) {
      require(
        _longPools[i].token != address(0) &&
          _longPools[i].value == 0 &&
          _longPools[i].leverage >= 1 &&
          _longPools[i].batched_amountPaymentToken_deposit == 0 &&
          _longPools[i].batched_amountSyntheticToken_redeem == 0,
        "Pool values incorrect"
      );

      ISyntheticToken(_longPools[i].token).mint(
        PERMANENT_INITIAL_LIQUIDITY_HOLDER,
        initialMarketSeedForEachPool
      );
      _longPools[i].value = initialMarketSeedForEachPool;
      pools[PoolType.LONG][i] = _longPools[i];

      poolInfo[i] = PoolInfo({
        poolType: PoolType.LONG,
        token: _longPools[i].token,
        leverage: _longPools[i].leverage
      });
    }

    numberOfPoolsOfType[uint8(PoolType.SHORT)] = uint8(_shortPools.length);

    for (uint256 i = 0; i < _shortPools.length; i++) {
      require(
        _shortPools[i].token != address(0) &&
          _shortPools[i].value == 0 &&
          _shortPools[i].leverage >= 1 &&
          _shortPools[i].batched_amountPaymentToken_deposit == 0 &&
          _shortPools[i].batched_amountSyntheticToken_redeem == 0,
        "Pool values incorrect"
      );

      ISyntheticToken(_shortPools[i].token).mint(
        PERMANENT_INITIAL_LIQUIDITY_HOLDER,
        initialMarketSeedForEachPool
      );
      _shortPools[i].value = initialMarketSeedForEachPool;
      pools[PoolType.SHORT][i] = _shortPools[i];

      poolInfo[_longPools.length + i] = PoolInfo({
        poolType: PoolType.SHORT,
        token: _longPools[i].token,
        leverage: _longPools[i].leverage
      });
    }

    emit SeparateMarketLaunchedAndSeeded(
      marketIndex,
      poolInfo,
      initialMarketSeedForEachPool,
      seederAndAdmin,
      address(oracleManager),
      paymentToken,
      initialAssetPrice
    );

    // Return true to drastically reduce chance of making mistakes with this.
    return true;
  }

  /*╔══════════════════════════════╗
    ║       GETTER FUNCTIONS       ║
    ╚══════════════════════════════╝*/

  function get_batched_amountPaymentToken_deposit(PoolType poolType, uint256 pool)
    external
    view
    returns (uint256)
  {
    return uint256(pools[poolType][pool].batched_amountPaymentToken_deposit);
  }

  function get_batched_amountSyntheticToken_redeem(PoolType poolType, uint256 pool)
    external
    view
    returns (uint256)
  {
    return uint256(pools[poolType][pool].batched_amountSyntheticToken_redeem);
  }

  function get_pool_value(PoolType poolType, uint256 pool) external view returns (uint256) {
    return uint256(pools[poolType][pool].value);
  }

  /// @notice Calculates the conversion rate from synthetic tokens to payment tokens.
  /// @dev Synth tokens have a fixed 18 decimals.
  /// @param amountPaymentTokenBackingSynth Amount of payment tokens in that token's lowest denomination.
  /// @param amountSyntheticToken Amount of synth token in wei.
  /// @return syntheticTokenPrice The calculated conversion rate in base 1e18.
  function _getSyntheticTokenPrice(
    uint256 amountPaymentTokenBackingSynth,
    uint256 amountSyntheticToken
  ) internal pure virtual returns (uint256 syntheticTokenPrice) {
    return (amountPaymentTokenBackingSynth * 1e18) / amountSyntheticToken;
  }

  /// @notice Converts synth token amounts to payment token amounts at a synth token price.
  /// @dev Price assumed base 1e18.
  /// @param amountSyntheticToken Amount of synth token in wei.
  /// @param syntheticTokenPriceInPaymentTokens The conversion rate from synth to payment tokens in base 1e18.
  /// @return amountPaymentToken The calculated amount of payment tokens in token's lowest denomination.
  function _getAmountPaymentToken(
    uint256 amountSyntheticToken,
    uint256 syntheticTokenPriceInPaymentTokens
  ) internal pure virtual returns (uint256 amountPaymentToken) {
    return (amountSyntheticToken * syntheticTokenPriceInPaymentTokens) / 1e18;
  }

  /// @notice Converts payment token amounts to synth token amounts at a synth token price.
  /// @dev  Price assumed base 1e18.
  /// @param amountPaymentTokenBackingSynth Amount of payment tokens in that token's lowest denomination.
  /// @param syntheticTokenPriceInPaymentTokens The conversion rate from synth to payment tokens in base 1e18.
  /// @return amountSyntheticToken The calculated amount of synthetic token in wei.
  function _getAmountSyntheticToken(
    uint256 amountPaymentTokenBackingSynth,
    uint256 syntheticTokenPriceInPaymentTokens
  ) internal pure virtual returns (uint256 amountSyntheticToken) {
    return (amountPaymentTokenBackingSynth * 1e18) / syntheticTokenPriceInPaymentTokens;
  }

  function _calculateEffectiveLiquidityForPool(uint256 value, uint256 leverage)
    internal
    pure
    returns (uint256 effectiveLiquidity)
  {
    return (value * leverage) / 1e18;
  }

  function _calculateEffectiveLiquidity()
    internal
    view
    returns (uint256[2] memory effectiveLiquidityPoolType)
  {
    for (uint8 poolType = uint8(PoolType.SHORT); poolType <= uint8(PoolType.LONG); poolType++) {
      uint256 maxPoolIndex = numberOfPoolsOfType[poolType];
      for (uint256 poolIndex = 0; poolIndex < maxPoolIndex; poolIndex++) {
        effectiveLiquidityPoolType[poolType] += _calculateEffectiveLiquidityForPool(
          pools[PoolType(poolType)][poolIndex].value,
          pools[PoolType(poolType)][poolIndex].leverage
        );
      }
    }
  }

  /*╔═══════════════════════════════╗
    ║     UPDATING SYSTEM STATE     ║
    ╚═══════════════════════════════╝*/

  /// @dev gets the value transfer from short to long (possitive is a gain for long, negative is a gain for short)
  function _getValueChange(
    uint256[2] memory totalEffectiveLiquidityPoolType,
    int256 previousPrice,
    int256 currentPrice
  ) internal pure virtual returns (int256 valueChange) {
    // Adjusting value of long and short pool based on price movement
    // The side/position with less liquidity has 100% percent exposure to the price movement.
    // The side/position with more liquidity will have exposure < 100% to the price movement.
    // I.e. Imagine $100 in longValue and $50 shortValue
    // long side would have $50/$100 = 50% exposure to price movements based on the liquidity imbalance.
    // min(longValue, shortValue) = $50 , therefore if the price change was -10% then
    // $50 * 10% = $5 gained for short side and conversely $5 lost for long side.
    int256 underbalancedSideValue = int256(
      Math.min(
        totalEffectiveLiquidityPoolType[uint256(PoolType.LONG)],
        totalEffectiveLiquidityPoolType[uint256(PoolType.SHORT)]
      )
    );

    // send a piece of value change to the treasury?
    // Again this reduces the value of totalValueLockedInMarket which means yield manager needs to be alerted.
    // See this equation in latex: https://ipfs.io/ipfs/QmPeJ3SZdn1GfxqCD4GDYyWTJGPMSHkjPJaxrzk2qTTPSE
    // Interact with this equation: https://www.desmos.com/calculator/t8gr6j5vsq
    valueChange = ((currentPrice - previousPrice) * int256(underbalancedSideValue)) / previousPrice;

    // TODO: check value change is less than the highest percentage change.
  }

  // // TODO: this is an example struct that we could use for later optimization
  // struct IntermediateEpochState {
  //   uint256[8] longPoolValues;
  //   uint256[8] shortPoolValues;
  // }

  /// TODO: optimise, we don't need to save prices and execute batches if no transactions occured.
  /// TODO: pass in the timestamps - rebalancing should happen as at epoch end timestamps
  function _rebalanceMarketPoolsCalculatePriceAndExecuteBatches(
    int256 previousPrice,
    OracleManagerFixedEpoch.MissedEpochExecutionInfo memory epochToExecute
  ) internal {
    uint256[2] memory totalEffectiveLiquidityPoolType = _calculateEffectiveLiquidity();

    int256 valueChange = _getValueChange(
      totalEffectiveLiquidityPoolType,
      // this is the previous execution price, not the previous oracle update price
      previousPrice,
      epochToExecute.oraclePrice
    );

    // calculate how much to distribute to winning side and extract from losing side (and do save result)
    // IntermediateEpochState memory intermediateEpochState;
    for (uint8 poolType = uint8(PoolType.SHORT); poolType <= uint8(PoolType.LONG); poolType++) {
      int256 directionScalar = 1;
      if (PoolType(poolType) == PoolType.SHORT) {
        directionScalar = -1;
      }

      uint256 maxPoolIndex = numberOfPoolsOfType[poolType];
      for (uint8 poolIndex = 0; poolIndex < maxPoolIndex; poolIndex++) {
        uint256 percentOfPool = (_calculateEffectiveLiquidityForPool(
          pools[PoolType(poolType)][poolIndex].value,
          pools[PoolType(poolType)][poolIndex].leverage
        ) * 1e18) / totalEffectiveLiquidityPoolType[uint256(PoolType(poolType))];

        pools[PoolType(poolType)][poolIndex].value = uint256(
          int256(pools[PoolType(poolType)][poolIndex].value) +
            (directionScalar * int256(percentOfPool) * valueChange) /
            1e18
        );

        uint256 tokenSupply = ISyntheticToken(pools[PoolType(poolType)][poolIndex].token)
          .totalSupply();
        uint256 price = _getSyntheticTokenPrice(
          pools[PoolType(poolType)][poolIndex].value,
          tokenSupply
        );

        //TODO - settle this pools batches here, save price if necessary
        syntheticToken_priceSnapshot[epochInfo.epochIndex][PoolType(poolType)][poolIndex] = price;

        _batchConfirmOutstandingPendingActionsPool(
          epochInfo.epochIndex,
          PoolType(poolType),
          poolIndex,
          price
        );
      }
    }

    epochInfo.latestExecutedEpochIndex = epochInfo.epochIndex;
    epochInfo.latestOraclePriceIdentifier = epochToExecute.oracleUpdateIndex;

    emit SystemUpdateInfo(epochInfo.epochIndex, uint256(epochToExecute.oraclePrice), valueChange);
  }

  /// @notice Updates the value of the long and short sides to account for latest oracle price updates
  /// and batches all next price actions.
  /// @dev To prevent front-running only executes on price change from an oracle.
  /// We assume the function will be called for each market at least once per price update.
  /// Note Even if not called on every price update, this won't affect security, it will only affect how closely
  /// the synthetic asset actually tracks the underlying asset.
  //// TODO: make this work if multiple epochs don't have prices yet.
  function _updateSystemStateInternal() internal virtual {
    (
      uint32 currentEpochTimestamp,
      uint32 numberOfEpochsSinceLastEpoch,
      int256 previousPrice,
      OracleManagerFixedEpoch.MissedEpochExecutionInfo[] memory epochsToExecute
    ) = oracleManager.getCompleteOracleInfoForSystemStateUpdate(
        epochInfo.latestExecutedEpochIndex,
        epochInfo.latestOraclePriceIdentifier,
        epochInfo.epochTimestamp
      );

    epochInfo.epochTimestamp = currentEpochTimestamp;
    epochInfo.epochIndex += numberOfEpochsSinceLastEpoch;

    // The for loop won't execute if no epochs available for execution.
    uint256 epochLength = epochsToExecute.length;
    for (
      uint256 epochToExecuteIndex = 0;
      epochToExecuteIndex < epochLength;
      epochToExecuteIndex++
    ) {
      OracleManagerFixedEpoch.MissedEpochExecutionInfo memory epochToExecute = epochsToExecute[
        epochToExecuteIndex
      ];

      _rebalanceMarketPoolsCalculatePriceAndExecuteBatches(previousPrice, epochToExecute);

      previousPrice = epochToExecute.oraclePrice;
    }
  }

  /// @notice Updates the state of a market to account for the latest oracle price update.
  function updateSystemState() external {
    _updateSystemStateInternal();
  }

  /*╔═══════════════════════════╗
    ║       MINT POSITION       ║
    ╚═══════════════════════════╝*/

  /// @notice Allows users to mint synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @dev Called by external functions to mint either long or short. If a user mints multiple times before a price update, these are treated as a single mint.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  /// @param poolType an enum representing the type of pool for eg. LONG or SHORT.
  /// @param pool leveraged pool index
  function _mint(
    uint224 amount,
    address user,
    PoolType poolType,
    uint256 pool
  ) internal virtual gemCollecting(user) {
    // TODO: should this be a modifier?
    _updateSystemStateInternal();
    (uint32 epochIndex, bool isNextEpochAmount) = _executePoolOutstandingUserMints(
      user,
      pool,
      poolType
    );

    require(amount > 0, "Mint amount == 0");
    IERC20(paymentToken).safeTransferFrom(user, yieldManager, amount);

    uint32 nextEpoch = epochIndex + 1;

    pools[poolType][pool].batched_amountPaymentToken_deposit += amount;
    // TODO: handle edge case where existing deposit exists in pool for users and it is currently the EWT: if (isNextEpochAmount) {
    user_paymentToken_depositAction[user][poolType][pool].amount += amount;
    user_paymentToken_depositAction[user][poolType][pool].correspondingEpoch = nextEpoch;

    emit Deposit(
      PoolId({poolType: poolType, index: uint8(pool)}),
      uint256(amount),
      user,
      nextEpoch
    );
  }

  /// @notice Allows users to mint long synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param pool leveraged pool index
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  function mintLong(uint256 pool, uint224 amount) external {
    _mint(amount, msg.sender, PoolType.LONG, pool);
  }

  /// @notice Allows users to mint short synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param pool leveraged pool index
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  function mintShort(uint256 pool, uint224 amount) external {
    _mint(amount, msg.sender, PoolType.SHORT, pool);
  }

  /*╔═══════════════════════════╗
    ║       REDEEM POSITION     ║
    ╚═══════════════════════════╝*/

  /// @notice Allows users to mint synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @dev Called by external functions to mint either long or short. If a user mints multiple times before a price update, these are treated as a single mint.
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  /// @param poolType an enum representing the type of pool for eg. LONG or SHORT.
  /// @param pool leveraged pool index
  function _redeem(
    uint224 amount,
    address user,
    PoolType poolType,
    uint256 pool
  ) internal virtual gemCollecting(user) {
    // TODO: should this be a modifier?
    _updateSystemStateInternal();
    (uint32 epochIndex, bool isNextEpochAmount) = _executePoolOutstandingUserRedeems(
      user,
      pool,
      poolType
    );
    require(amount > 0, "Redeem amount == 0");

    ISyntheticToken(pools[poolType][pool].token).transferFrom(user, address(this), amount);

    uint32 nextEpoch = epochIndex + 1;

    pools[poolType][pool].batched_amountSyntheticToken_redeem += amount;
    // TODO: handle edge case where existing deposit exists in pool for users and it is currently the EWT: if (isNextEpochAmount) {
    user_syntheticToken_redeemAction[user][poolType][pool].amount += amount;
    user_syntheticToken_redeemAction[user][poolType][pool].correspondingEpoch = nextEpoch;

    emit Redeem(PoolId({poolType: poolType, index: uint8(pool)}), uint256(amount), user, nextEpoch);
  }

  /// @notice Allows users to mint long synthetic assets for a market. To prevent front-running these mints are executed on the next price update from the oracle.
  /// @param pool leveraged pool index
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to mint synthetic assets at next price.
  function redeemLong(uint256 pool, uint224 amount) external {
    _redeem(amount, msg.sender, PoolType.LONG, pool);
  }

  /// @notice Allows users to redeem short synthetic assets for a market. To prevent front-running these redeems are executed on the next price update from the oracle.
  /// @param pool leveraged pool index
  /// @param amount Amount of payment tokens in that token's lowest denominationfor which to redeem synthetic assets at next price.
  function redeemShort(uint256 pool, uint224 amount) external {
    _redeem(amount, msg.sender, PoolType.SHORT, pool);
  }

  /*╔══════════════════════╗
    ║  EPOCH SETTLEMENTS   ║
    ╚══════════════════════╝*/

  /*╔═════════════════════════════════╗
    ║ BATCHED EPOCH SETTLEMENT ACTION ║
    ╚═════════════════════════════════╝*/

  function _executePoolOutstandingUserMints(
    address user,
    uint256 pool,
    PoolType poolType
  ) internal virtual returns (uint32 epochIndex, bool isNextEpochAmount) {
    UserAction storage currentUserAction;
    currentUserAction = user_paymentToken_depositAction[user][poolType][pool];

    (uint32 epochIndexTimestamp, uint32 numberOfEpochsSinceLastEpoch) = oracleManager
      .updateCurrentEpochTimestamp(epochInfo.epochTimestamp);

    epochInfo.epochTimestamp = epochIndexTimestamp;
    epochInfo.epochIndex += numberOfEpochsSinceLastEpoch;
    epochIndex = epochInfo.epochIndex;

    if (currentUserAction.amount > 0 && currentUserAction.correspondingEpoch <= epochIndex) {
      // user has outstanding mints that are ready to be actioned

      if (currentUserAction.correspondingEpoch > epochInfo.latestExecutedEpochIndex) {
        _updateSystemStateInternal();
        bool isCurrentEpochPriceUpdated = epochInfo.epochIndex ==
          epochInfo.latestExecutedEpochIndex;

        if (!isCurrentEpochPriceUpdated) {
          revert("Wait until EWT has passed (WIP, will fix) - 1");
          // TODO: we would need to add the users action to the `nextEpochAmount`
        }
      }

      uint256 syntheticToken_price = syntheticToken_priceSnapshot[
        currentUserAction.correspondingEpoch
      ][poolType][pool];

      address syntheticToken = pools[poolType][pool].token;

      uint256 amountSyntheticTokenToMint = _getAmountSyntheticToken(
        uint256(currentUserAction.amount),
        syntheticToken_price
      );

      currentUserAction.amount = 0;

      ISyntheticToken(syntheticToken).transfer(user, amountSyntheticTokenToMint);

      if (currentUserAction.nextEpochAmount > 0) {
        // TODO: handle this edge case!
        revert("Wait until EWT has passed (WIP, will fix) - 2");
      }
    }
  }

  function _executePoolOutstandingUserRedeems(
    address user,
    uint256 pool,
    PoolType poolType
  ) internal virtual returns (uint32 epochIndex, bool isNextEpochAmount) {
    UserAction storage currentUserAction;
    currentUserAction = user_syntheticToken_redeemAction[user][poolType][pool];

    (uint32 epochIndexTimestamp, uint32 numberOfEpochsSinceLastEpoch) = oracleManager
      .updateCurrentEpochTimestamp(epochInfo.epochTimestamp);

    epochInfo.epochIndex += numberOfEpochsSinceLastEpoch;
    epochIndex = epochInfo.epochIndex;

    if (currentUserAction.amount > 0 && currentUserAction.correspondingEpoch <= epochIndex) {
      // user has outstanding mints that are ready to be actioned

      if (currentUserAction.correspondingEpoch > epochInfo.latestExecutedEpochIndex) {
        _updateSystemStateInternal();
        bool isCurrentEpochPriceUpdated = epochInfo.epochIndex ==
          epochInfo.latestExecutedEpochIndex;

        if (!isCurrentEpochPriceUpdated) {
          revert("Wait until EWT has passed (WIP, will fix)");
        }
      }

      uint256 syntheticToken_price = syntheticToken_priceSnapshot[
        currentUserAction.correspondingEpoch
      ][poolType][pool];
      address syntheticToken = pools[poolType][pool].token;

      uint256 amountPaymentTokenToSend = _getAmountPaymentToken(
        uint256(currentUserAction.amount),
        syntheticToken_price
      );

      currentUserAction.amount = 0;

      if (currentUserAction.nextEpochAmount > 0) {
        // TODO: handle this edge case!
        revert("Wait until EWT has passed (WIP, will fix)");
      }

      IYieldManager(yieldManager).transferPaymentTokensToUser(user, amountPaymentTokenToSend);

      emit ExecuteEpochSettlementRedeemUser(
        PoolId({poolType: poolType, index: uint8(pool)}),
        user,
        currentUserAction.correspondingEpoch
      );
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their next price actions for that update to that user.
  /// @dev Once the market has updated for the next price, should be guaranteed (through modifiers) to execute for a user before user initiation of new next price actions.
  /// @param user The address of the user for whom to execute the function.
  function _executeOutstandingNextPriceSettlements(address user) internal virtual {
    for (uint8 poolType = uint8(PoolType.SHORT); poolType <= uint8(PoolType.LONG); poolType++) {
      uint256 maxPoolIndex = numberOfPoolsOfType[poolType];
      for (uint8 poolIndex = 0; poolIndex < maxPoolIndex; poolIndex++) {
        _executePoolOutstandingUserMints(user, poolIndex, PoolType(poolType));
        _executePoolOutstandingUserRedeems(user, poolIndex, PoolType(poolType));
      }
    }
  }

  /// @notice After markets have been batched updated on a new oracle price, transfers any owed tokens to a user from their next price actions for that update to that user.
  /// @param user The address of the user for whom to execute the function.
  function executeOutstandingNextPriceSettlementsUser(address user) external {
    _executeOutstandingNextPriceSettlements(user);
  }

  /*╔═══════════════════════════════════════════╗
    ║   BATCHED NEXT PRICE SETTLEMENT ACTIONS   ║
    ╚═══════════════════════════════════════════╝*/

  /// @notice Either transfers funds from the yield manager to this contract if redeems > deposits,
  /// and vice versa. The yield manager handles depositing and withdrawing the funds from a yield market.
  /// @dev When all batched next price actions are handled the total value in the market can either increase or decrease based on the value of mints and redeems.
  /// @param totalPaymentTokenValueChangeForMarket An int256 which indicates the magnitude and direction of the change in market value.
  function _handleTotalPaymentTokenValueChangeForMarketWithYieldManager(
    int256 totalPaymentTokenValueChangeForMarket
  ) internal virtual {
    if (totalPaymentTokenValueChangeForMarket > 0) {
      IYieldManager(yieldManager).depositPaymentToken(
        uint256(totalPaymentTokenValueChangeForMarket)
      );
    } else if (totalPaymentTokenValueChangeForMarket < 0) {
      // NB there will be issues here if not enough liquidity exists to withdraw
      // Boolean should be returned from yield manager and think how to appropriately handle this
      IYieldManager(yieldManager).removePaymentTokenFromMarket(
        uint256(-totalPaymentTokenValueChangeForMarket)
      );
    }
  }

  function _handleChangeInSyntheticTokensTotalSupply(
    address synthToken,
    int256 changeInSyntheticTokensTotalSupply
  ) internal virtual {
    if (changeInSyntheticTokensTotalSupply > 0) {
      ISyntheticToken(synthToken).mint(address(this), uint256(changeInSyntheticTokensTotalSupply));
    } else if (changeInSyntheticTokensTotalSupply < 0) {
      ISyntheticToken(synthToken).burn(uint256(-changeInSyntheticTokensTotalSupply));
    }
  }

  function _batchConfirmOutstandingPendingActionsPool(
    uint32 epochIndex,
    PoolType poolType,
    uint256 poolIndex,
    uint256 price
  ) internal virtual {
    uint256 amountForCurrentAction_workingVariable;
    int256 changeInSupply_syntheticToken;
    int256 changeInMarketValue_inPaymentToken;

    Pool storage pool = pools[poolType][poolIndex];
    changeInSupply_syntheticToken = 0;
    changeInMarketValue_inPaymentToken = 0;

    // Handle batched deposits
    amountForCurrentAction_workingVariable = pool.batched_amountPaymentToken_deposit;
    if (amountForCurrentAction_workingVariable > 0) {
      changeInMarketValue_inPaymentToken += int256(amountForCurrentAction_workingVariable);

      pool.batched_amountPaymentToken_deposit = pool.nextEpoch_batched_amountPaymentToken_deposit;
      pool.nextEpoch_batched_amountPaymentToken_deposit = 0;

      changeInSupply_syntheticToken += int256(
        _getAmountSyntheticToken(amountForCurrentAction_workingVariable, price)
      );
      syntheticToken_priceSnapshot[epochIndex][PoolType(poolType)][poolIndex] = price;
    }

    // Handle batched redeems
    amountForCurrentAction_workingVariable = pool.batched_amountSyntheticToken_redeem;
    if (amountForCurrentAction_workingVariable > 0) {
      changeInMarketValue_inPaymentToken -= int256(
        _getAmountPaymentToken(amountForCurrentAction_workingVariable, price)
      );
      changeInSupply_syntheticToken -= int256(amountForCurrentAction_workingVariable);

      pool.batched_amountSyntheticToken_redeem = pool.nextEpoch_batched_amountSyntheticToken_redeem;
      pool.nextEpoch_batched_amountSyntheticToken_redeem = 0;
      syntheticToken_priceSnapshot[epochIndex][PoolType(poolType)][poolIndex] = price;
    }

    // Batch settle synthetic tokens
    _handleChangeInSyntheticTokensTotalSupply(pool.token, changeInSupply_syntheticToken);

    // Batch settle payment tokens
    _handleTotalPaymentTokenValueChangeForMarketWithYieldManager(
      changeInMarketValue_inPaymentToken
    );

    pools[PoolType(poolType)][poolIndex].value = uint256(
      int256(pools[PoolType(poolType)][poolIndex].value) + changeInMarketValue_inPaymentToken
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "hardhat/console.sol";

/*
 * Implementation of an OracleManager that fetches prices from a Chainlink aggregate price feed.
 */
contract OracleManagerFixedEpoch {
  // Global state.
  AggregatorV3Interface public immutable chainlinkOracle;
  uint8 public immutable oracleDecimals;
  uint256 public immutable initialEpochStartTimestamp;
  uint256 public immutable MINIMUM_EXECUTION_WAIT_THRESHOLD;
  uint256 public immutable EPOCH_LENGTH;

  ////////////////////////////////////
  /////////// MODIFIERS //////////////
  ////////////////////////////////////

  ////////////////////////////////////
  ///// CONTRACT SET-UP //////////////
  ////////////////////////////////////
  constructor(
    address _chainlinkOracle,
    uint256 epochLength,
    uint256 minimumExecutionWaitThreshold
  ) {
    chainlinkOracle = AggregatorV3Interface(_chainlinkOracle);
    oracleDecimals = chainlinkOracle.decimals();
    // NOTE: Start the epoch at index 1 rather (this is to prevent edge cases that occur if epoch is ever 1).
    initialEpochStartTimestamp = block.timestamp - epochLength;
    MINIMUM_EXECUTION_WAIT_THRESHOLD = minimumExecutionWaitThreshold;
    EPOCH_LENGTH = epochLength;
  }

  ////////////////////////////////////
  /// MULTISIG ADMIN FUNCTIONS ///////
  ////////////////////////////////////

  ////////////////////////////////////
  ///// IMPLEMENTATION ///////////////
  ////////////////////////////////////
  function getEpochStartTimestamp() public view returns (uint256) {
    //Eg. If EPOCH_LENGTH is 10min, then the epoch will change at 11:00, 11:10, 11:20 etc.
    return (block.timestamp / EPOCH_LENGTH) * EPOCH_LENGTH;
  }

  /// @notice Returns index of the current epoch based on block.timestamp
  /// @dev Called by internal functions to get current epoch index
  function getLatestEpochIndex() public view returns (uint256) {
    return (getEpochStartTimestamp() - initialEpochStartTimestamp) / EPOCH_LENGTH;
  }

  function updateCurrentEpochTimestamp(uint32 lastEpochTimestamp)
    public
    view
    returns (uint32, uint32)
  {
    uint32 currentEpochTimestamp = uint32(getEpochStartTimestamp());
    uint32 numberOfEpochsSinceLastEpoch = uint32(
      (currentEpochTimestamp - lastEpochTimestamp) / EPOCH_LENGTH
    );

    return (currentEpochTimestamp, numberOfEpochsSinceLastEpoch);
  }

  function updatePriceWithIndex(uint32 timestampOfLastEpoch, uint80 oracleUpdateIndex)
    public
    view
    returns (
      int256 price,
      // TODO: we likely don't need both of these timestamps in the market. Clean them up.
      uint256 oracleUpdateTimestamp,
      uint256 currentEpochStartTime
    )
  {
    (, , uint256 startedAtPrev, , ) = chainlinkOracle.getRoundData(oracleUpdateIndex - 1);
    (, int256 oraclePrice, uint256 timstampPriceUpdated, , ) = chainlinkOracle.getRoundData(
      oracleUpdateIndex
    );

    currentEpochStartTime = getEpochStartTimestamp();
    require(timestampOfLastEpoch < currentEpochStartTime);

    require(startedAtPrev < currentEpochStartTime + MINIMUM_EXECUTION_WAIT_THRESHOLD);
    require(timstampPriceUpdated >= currentEpochStartTime + MINIMUM_EXECUTION_WAIT_THRESHOLD);
    price = oraclePrice;
    oracleUpdateTimestamp = timstampPriceUpdated;
  }

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return chainlinkOracle.latestRoundData();
  }

  // Do not assume this function works after price is updated
  // This function only works in the time between epoch start and previous epoch price update
  function shouldUpdatePrice(uint32 epochTimestamp) public view returns (bool) {
    (, , uint256 timestampPriceUpdated, , ) = chainlinkOracle.latestRoundData();

    return !_priceUpdateIsBeforeMinExecutionWaitThreshold(epochTimestamp, timestampPriceUpdated);
  }

  /// @notice Checks for whether the oracle price update should be used for executing the epoch
  /// @dev Called by internal functions to check whether oracle price update should be used for executing the epoch
  /// @param currentEpochStartTimestamp start timestamp of current epoch
  /// @param previousOracleUpdateTimestamp timestamp of previous oracle price update
  /// @param currentOracleUpdateTimestamp timestamp of current oracle price update
  function _shouldCurrentPriceUpdateExecuteEpoch(
    uint256 currentEpochStartTimestamp,
    uint256 previousOracleUpdateTimestamp,
    uint256 currentOracleUpdateTimestamp
  ) private view returns (bool) {
    //Don't use price for execution because MEWT has not expired yet
    //current price update epoch is ahead of MEWT so we check if the previous value
    //occurred before MEWT to validate that this is the correct price update to use
    return
      _priceUpdateIsBeforeMinExecutionWaitThreshold(
        currentEpochStartTimestamp,
        previousOracleUpdateTimestamp
      ) &&
      !_priceUpdateIsBeforeMinExecutionWaitThreshold(
        currentEpochStartTimestamp,
        currentOracleUpdateTimestamp
      );
  }

  /// @notice Checks for whether the oracle price update occurs before Minimum Execution Wait Threshold is expired.
  /// @dev Called by internal functions to check whether system state should be update on oracle price update
  /// @param epochTimestamp end timestamp of previous epoch
  /// @param priceUpdateTimestamp timestamp of oracle price update
  function _priceUpdateIsBeforeMinExecutionWaitThreshold(
    uint256 epochTimestamp,
    uint256 priceUpdateTimestamp
  ) private view returns (bool) {
    return priceUpdateTimestamp < epochTimestamp + MINIMUM_EXECUTION_WAIT_THRESHOLD;
  }

  function priceAtIndex(uint80 index) public view returns (int256 price) {
    (, int256 oraclePricePrev, , , ) = chainlinkOracle.getRoundData(index);
    return oraclePricePrev;
  }

  // NOTE: this function is innefficient and unoptimised
  function updatePriceNoIndex()
    public
    view
    returns (
      int256 newPrice,
      // TODO: we likely don't need both of these timestamps in the market. Clean them up.
      uint256 oracleUpdateTimestamp,
      uint256 currentEpochStartTime,
      uint80 newOracleUpdateIndex
    )
  {
    (
      uint80 oracleUpdateIndex,
      int256 oraclePrice,
      uint256 timstampPriceUpdated,
      ,

    ) = chainlinkOracle.latestRoundData();
    currentEpochStartTime = getEpochStartTimestamp();

    if (timstampPriceUpdated < currentEpochStartTime + MINIMUM_EXECUTION_WAIT_THRESHOLD) {
      // TODO: return the price from the previous epoch
      return (0, 0, 0, 0);
    } else {
      while (true) {
        oracleUpdateIndex -= 1;
        (
          uint80 oracleUpdateIndexPrev,
          int256 oraclePricePrev,
          uint256 startedAtPrev,
          ,

        ) = chainlinkOracle.getRoundData(oracleUpdateIndex);
        if (startedAtPrev < currentEpochStartTime + MINIMUM_EXECUTION_WAIT_THRESHOLD) {
          return (oraclePrice, timstampPriceUpdated, currentEpochStartTime, oracleUpdateIndex);
        } else {
          timstampPriceUpdated = startedAtPrev;
          oraclePrice = oraclePricePrev;
          oracleUpdateIndex = oracleUpdateIndexPrev;
        }
      }
    }
  }

  /// @notice Calculates number of epochs which have missed system state update, due to bot failing
  /// @dev Called by internal function to decide how many epoch execution info (oracle price update details) should be returned
  /// @param _latestExecutedEpochIndex index of the most recently executed epoch
  function _getNumberOfMissedEpochs(uint256 _latestExecutedEpochIndex)
    private
    view
    returns (uint256)
  {
    uint256 _latestEpochIndex = getLatestEpochIndex();

    uint256 _numberOfMissedEpochs = _latestEpochIndex - _latestExecutedEpochIndex;

    //Does this contribute gas and is it necessary?
    if (_numberOfMissedEpochs <= 0) {
      return _numberOfMissedEpochs;
    }

    (, , uint256 _timstampPriceUpdated, , ) = chainlinkOracle.latestRoundData();

    // allowing for cases where system state update is called before EWT has expired in the current epoch
    // therefore the previous epoch should not be executed just yet
    if (
      _priceUpdateIsBeforeMinExecutionWaitThreshold(getEpochStartTimestamp(), _timstampPriceUpdated)
    ) {
      _numberOfMissedEpochs -= 1;
    }

    // DO analysis on actual hard cap of epochs that can fit in say 80% of block space
    return _numberOfMissedEpochs;
  }

  struct MissedEpochExecutionInfo {
    uint80 oracleUpdateIndex;
    int256 oraclePrice;
    uint256 timestampPriceUpdated;
    uint32 associatedEpochIndex;
  }

  /**
	@notice returns an array of info on each epoch price update that was missed
	@dev This function gets executed in a system update on the market contract
	@param _latestExecutedEpochIndex the most epoch index in which a price update has been executed
	@param _latestOraclePriceIdentifier the "roundId" used to reference the most recently executed oracle price on chainlink
	 */
  function getMissedEpochPriceUpdates(
    uint32 _latestExecutedEpochIndex,
    uint80 _latestOraclePriceIdentifier
  ) public view returns (MissedEpochExecutionInfo[] memory) {
    uint256 _numberOfMissedEpochs = _getNumberOfMissedEpochs(_latestExecutedEpochIndex);
    MissedEpochExecutionInfo[] memory _missedEpochPriceUpdates = new MissedEpochExecutionInfo[](
      _numberOfMissedEpochs
    );

    if (_numberOfMissedEpochs == 0) {
      return _missedEpochPriceUpdates;
    }

    // While loop boolean
    bool _isSearchingForMissedEpochExecutionInfo = true;

    uint80 _currentOracleIndex = _latestOraclePriceIdentifier + 1;

    //Start at the timestamp of the first epoch index after the latest executed epoch index
    uint256 _currentEpochStartTimestamp = (uint256(_latestExecutedEpochIndex) + 1) *
      EPOCH_LENGTH +
      initialEpochStartTimestamp;

    //The targeted array slot for the missed price update search
    uint32 _currentMissedEpochPriceUpdatesArrayIndex = 0;

    // Called outside of the loop and then updated on each iteration within the loop
    (, , uint256 _previousOracleUpdateTimestamp, , ) = chainlinkOracle.getRoundData(
      _currentOracleIndex - 1
    );

    while (_isSearchingForMissedEpochExecutionInfo) {
      (, int256 _currentOraclePrice, uint256 _currentOracleUpdateTimestamp, , ) = chainlinkOracle
        .getRoundData(_currentOracleIndex);
      if (
        _shouldCurrentPriceUpdateExecuteEpoch(
          _currentEpochStartTimestamp,
          _previousOracleUpdateTimestamp,
          _currentOracleUpdateTimestamp
        )
      ) {
        _missedEpochPriceUpdates[
          _currentMissedEpochPriceUpdatesArrayIndex
        ] = MissedEpochExecutionInfo({
          oracleUpdateIndex: _currentOracleIndex,
          oraclePrice: _currentOraclePrice,
          timestampPriceUpdated: _currentOracleUpdateTimestamp,
          associatedEpochIndex: _latestExecutedEpochIndex +
            1 +
            _currentMissedEpochPriceUpdatesArrayIndex
        });

        // Increment to the next array index and the correct timestamp
        _currentMissedEpochPriceUpdatesArrayIndex += 1;
        _currentEpochStartTimestamp += uint32(EPOCH_LENGTH);

        // Check that we have retrieved all the missed epoch updates that we are searching
        // for and end the while loop
        if (_currentMissedEpochPriceUpdatesArrayIndex == _numberOfMissedEpochs) {
          _isSearchingForMissedEpochExecutionInfo = false;
        }
      }

      //Previous oracle update timestamp can be reassigned to the current for the next iteration
      _previousOracleUpdateTimestamp = _currentOracleUpdateTimestamp;
      _currentOracleIndex++;
    }

    return _missedEpochPriceUpdates;
  }

  function getCompleteOracleInfoForSystemStateUpdate(
    uint32 _latestExecutedEpochIndex,
    uint80 _latestOraclePriceIdentifier,
    uint32 _epochTimestamp
  )
    public
    view
    returns (
      uint32 currentEpochTimestamp,
      uint32 numberOfEpochsSinceLastEpoch,
      int256 previousPrice,
      MissedEpochExecutionInfo[] memory _missedEpochPriceUpdates
    )
  {
    (currentEpochTimestamp, numberOfEpochsSinceLastEpoch) = updateCurrentEpochTimestamp(
      _epochTimestamp
    );

    // TODO possibly (may be worse) optimize by saving as state variable in epochInfo
    previousPrice = priceAtIndex(_latestOraclePriceIdentifier);

    _missedEpochPriceUpdates = getMissedEpochPriceUpdates(
      _latestExecutedEpochIndex,
      _latestOraclePriceIdentifier
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}