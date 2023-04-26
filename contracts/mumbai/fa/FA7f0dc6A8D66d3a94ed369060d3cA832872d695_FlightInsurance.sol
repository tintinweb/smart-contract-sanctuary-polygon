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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
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
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
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
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallUUPS(newImplementation, data, true);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IFlightStatusOracle.sol";
import "./interfaces/IProduct.sol";
import "./PredictionMarket.sol";

contract FlightDelayMarket is PredictionMarket {
    event FlightCompleted(
        string indexed flightName,
        uint64 indexed departureDate,
        bytes1 status,
        uint32 delay
    );

    struct FlightInfo {
        string flightName;
        uint64 departureDate;
        uint32 delay;
    }

    struct Outcome {
        bytes1 status;
        uint32 delay;
    }

    FlightInfo private _flightInfo;
    Outcome private _outcome;

    constructor(
        FlightInfo memory flightInfo_,
        Config memory config_,
        uint256 uniqueId_,
        bytes32 marketId_,
        ITokensRepository tokensRepo_,
        address payable feeCollector_,
        IProduct product_,
        address trustedForwarder_
    ) PredictionMarket(config_, uniqueId_, marketId_, tokensRepo_, feeCollector_, product_, trustedForwarder_) {
        _flightInfo = flightInfo_;
    }

    function flightInfo() external view returns (FlightInfo memory) {
        return _flightInfo;
    }

    function outcome() external view returns (Outcome memory) {
        return _outcome;
    }

    function _trySettle() internal override {
        IFlightStatusOracle(_config.oracle).requestFlightStatus(
            _flightInfo.flightName,
            _flightInfo.departureDate,
            this.recordDecision.selector
        );
    }

    function _renderDecision(
        bytes calldata payload
    ) internal override returns (DecisionState state, Result result) {
        (bytes1 status, uint32 delay) = abi.decode(payload, (bytes1, uint32));

        // TODO: carefully check other statuses
        if (status != "L") {
            // not arrived yet
            // will have to reschedule the check
            state = DecisionState.DECISION_NEEDED;
            // TODO: also add a cooldown mechanism
        } else if (status == "C" || delay >= _flightInfo.delay) {
            // YES wins
            state = DecisionState.DECISION_RENDERED;
            result = Result.YES;
        } else {
            // NO wins
            state = DecisionState.DECISION_RENDERED;
            result = Result.NO;
        }

        if (state == DecisionState.DECISION_RENDERED) {
            _outcome = Outcome(status, delay);
            emit FlightCompleted(_flightInfo.flightName, _flightInfo.departureDate, status, delay);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/ITokensRepository.sol";
import "./interfaces/IProduct.sol";
import "./interfaces/IRegistry.sol";
import "./utils/RegistryMixin.sol";
import "./FlightDelayMarket.sol";

contract FlightDelayMarketFactory is RegistryMixin {
    constructor(IRegistry registry_) {
        _setRegistry(registry_);
    }

    function createMarket(
        uint256 uniqueId,
        bytes32 marketId,
        PredictionMarket.Config calldata config,
        FlightDelayMarket.FlightInfo calldata flightInfo
    ) external onlyProduct returns (FlightDelayMarket) {
        FlightDelayMarket market = new FlightDelayMarket(
            flightInfo,
            config,
            uniqueId,
            marketId,
            ITokensRepository(_registry.getAddress(2)) /* tokens repo */,
            payable(_registry.getAddress(100)) /* fee collector */,
            IProduct(msg.sender),
            _registry.getAddress(101) /* trusted forwarder */
        );
        return market;
    }

    function getMarketId(
        string calldata flightName,
        uint64 departureDate,
        uint32 delay
    ) external pure returns (bytes32) {
        return keccak256(abi.encode(flightName, departureDate, delay));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Trustus.sol";
import "./LPWallet.sol";

import "./interfaces/IFlightStatusOracle.sol";
import "./interfaces/ITokensRepository.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IProduct.sol";
import "./interfaces/IRegistry.sol";
import "./utils/RegistryMixin.sol";
import "./FlightDelayMarketFactory.sol";
import "./FlightDelayMarket.sol";

contract FlightInsurance is
    IProduct,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    Trustus,
    RegistryMixinUpgradeable,
    UUPSUpgradeable
{
    event FlightDelayMarketCreated(
        bytes32 indexed marketId,
        uint256 indexed uniqueId,
        address indexed creator
    );

    event FlightDelayMarketLiquidityProvided(
        bytes32 indexed marketId,
        address indexed provider,
        uint256 value
    );

    event FlightDelayMarketParticipated(
        bytes32 indexed marketId,
        address indexed participant,
        uint256 value,
        bool betYes,
        uint256 amount
    );

    event FlightDelayMarketWithdrawn(
        bytes32 indexed marketId,
        address indexed participant,
        uint256 amount,
        bool betYes,
        uint256 value
    );

    event FlightDelayMarketSettled(bytes32 indexed marketId, bool yesWin, bytes outcome);

    event FlightDelayMarketClaimed(
        bytes32 indexed marketId,
        address indexed participant,
        uint256 value
    );

    error ZeroAddress();

    bytes32 private constant TRUSTUS_REQUEST_MARKET =
        0x416d5838653a925e2c4ccf0b43e376ad31434b2095ec358fe6b0519c1e2f2bbe;

    /// @dev Stores the next value to use
    uint256 private _marketUniqueIdCounter;

    /// @notice Markets storage
    mapping(bytes32 => FlightDelayMarket) private _markets;

    /// @notice Holds LP funds
    LPWallet private _lpWallet;

    function initialize(IRegistry registry_) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Trustus_init();
        __RegistryMixin_init(registry_);
        __UUPSUpgradeable_init();

        _marketUniqueIdCounter = 10;
    }

    function getMarket(bytes32 marketId) external view override returns (address) {
        return address(_markets[marketId]);
    }

    function findMarket(
        string calldata flightName,
        uint64 departureDate,
        uint32 delay
    ) external view returns (bytes32, FlightDelayMarket) {
        FlightDelayMarketFactory factory = FlightDelayMarketFactory(_registry.getAddress(1));
        bytes32 marketId = factory.getMarketId(flightName, departureDate, delay);
        return (marketId, _markets[marketId]);
    }

    function createMarket(
        bool betYes,
        TrustusPacket calldata packet
    ) external payable nonReentrant verifyPacket(TRUSTUS_REQUEST_MARKET, packet) {
        // TODO: extract config
        (
            IMarket.Config memory config,
            string memory flightName,
            uint64 departureDate,
            uint32 delay
        ) = abi.decode(packet.payload, (IMarket.Config, string, uint64, uint32));

        // TODO: add "private market"
        require(config.cutoffTime > block.timestamp, "Cannot create closed market");

        FlightDelayMarketFactory factory = FlightDelayMarketFactory(_registry.getAddress(1));

        bytes32 marketId = factory.getMarketId(flightName, departureDate, delay);
        require(address(_markets[marketId]) == address(0), "Market already exists");

        uint256 uniqueId = _marketUniqueIdCounter;
        FlightDelayMarket market = factory.createMarket(
            uniqueId,
            marketId,
            config,
            FlightDelayMarket.FlightInfo(flightName, departureDate, delay)
        );
        _markets[marketId] = market;
        _lpWallet.provideLiquidity(market, config.lpBid);

        market.registerParticipant{value: msg.value}(_msgSender(), betYes);

        _marketUniqueIdCounter += market.tokenSlots();

        emit FlightDelayMarketCreated(marketId, uniqueId, _msgSender());
    }

    /// @notice Sets the trusted signer of Trustus package
    function setIsTrusted(address account_, bool trusted_) external onlyOwner {
        if (account_ == address(0)) {
            revert ZeroAddress();
        }

        _setIsTrusted(account_, trusted_);
    }

    function setWallet(LPWallet lpWallet_) external onlyOwner {
        _lpWallet = lpWallet_;
    }

    function wallet() external view returns (address) {
        return address(_lpWallet);
    }

    // hooks
    function onMarketLiquidity(
        bytes32 marketId,
        address provider,
        uint256 value
    ) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketLiquidityProvided(marketId, provider, value);
    }

    function onMarketParticipate(
        bytes32 marketId,
        address account,
        uint256 value,
        bool betYes,
        uint256 amount
    ) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketParticipated(marketId, account, value, betYes, amount);
    }

    function onMarketWithdraw(
        bytes32 marketId,
        address account,
        uint256 amount,
        bool betYes,
        uint256 value
    ) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketWithdrawn(marketId, account, amount, betYes, value);
    }

    function onMarketSettle(
        bytes32 marketId,
        bool yesWin,
        bytes calldata outcome
    ) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketSettled(marketId, yesWin, outcome);
    }

    function onMarketClaim(bytes32 marketId, address account, uint256 value) external override {
        require(msg.sender == address(_markets[marketId]), "Invalid market");
        emit FlightDelayMarketClaimed(marketId, account, value);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev As we didn't initially inherit from ERC2771Upgradeable, we will provide the functionality manually
    // import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _registry.getAddress(101);
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IFlightStatusOracle {
    function requestFlightStatus(
        string calldata flightName,
        uint64 departureDate,
        bytes4 callback
    ) external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IMarket.sol";

interface ILPWallet {
    function provideLiquidity(IMarket market, uint256 amount) external;

    function withdraw(address to, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMarket {
    enum DecisionState {
        NO_DECISION,
        DECISION_NEEDED,
        DECISION_LOADING,
        DECISION_RENDERED
    }

    enum Result {
        UNDEFINED,
        YES,
        NO
    }

    enum Mode {
        BURN,
        BUYER
    }

    struct FinalBalance {
        uint256 bank;
        uint256 yes;
        uint256 no;
    }

    struct Config {
        uint64 cutoffTime;
        uint64 closingTime;
        uint256 lpBid;
        uint256 minBid;
        uint256 maxBid;
        uint16 initP;
        uint16 fee;
        Mode mode;
        address oracle;
    }

    function provideLiquidity() external payable returns (bool success);

    function product() external view returns (address);

    function marketId() external view returns (bytes32);

    function tokenIds() external view returns (uint256 tokenIdYes, uint256 tokenIdNo);

    function finalBalance() external view returns (FinalBalance memory);

    function decisionState() external view returns (DecisionState);

    function config() external view returns (Config memory);

    function tvl() external view returns (uint256);

    function result() external view returns (Result);

    function currentDistribution() external view returns (uint256);

    function canBeSettled() external view returns (bool);

    function trySettle() external;

    function priceETHToYesNo(uint256 amountIn) external view returns (uint256, uint256);

    function priceETHForYesNoMarket(uint256 amountOut) external view returns (uint256, uint256);

    function priceETHForYesNo(
        uint256 amountOut,
        address account
    ) external view returns (uint256, uint256);

    function participate(bool betYes) external payable;

    function withdrawBet(uint256 amount, bool betYes) external;

    function claim() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IProduct {
    function getMarket(bytes32 marketId) external view returns (address);

    // hooks
    function onMarketLiquidity(bytes32 marketId, address provider, uint256 value) external;

    function onMarketParticipate(
        bytes32 marketId,
        address account,
        uint256 value,
        bool betYes,
        uint256 amount
    ) external;

    function onMarketWithdraw(
        bytes32 marketId,
        address account,
        uint256 amount,
        bool betYes,
        uint256 value
    ) external;

    function onMarketSettle(bytes32 marketId, bool yesWin, bytes calldata outcome) external;

    function onMarketClaim(bytes32 marketId, address account, uint256 value) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRegistry {
    function getAddress(uint64 id) external view returns (address);

    function getId(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITokensRepository {
    function totalSupply(uint256 tokenId) external view returns (uint256);

    function mint(address to, uint256 tokenId, uint256 amount) external;

    function burn(address holder, uint256 tokenId, uint256 amount) external;

    function balanceOf(address holder, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./interfaces/ILPWallet.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IRegistry.sol";
import "./utils/RegistryMixin.sol";

contract LPWallet is
    ILPWallet,
    ERC1155ReceiverUpgradeable,
    OwnableUpgradeable,
    RegistryMixinUpgradeable,
    UUPSUpgradeable
{
    function initialize(IRegistry registry_) public initializer {
        __Ownable_init();
        __ERC1155Receiver_init();
        __RegistryMixin_init(registry_);
        __UUPSUpgradeable_init();
    }

    function provideLiquidity(IMarket market, uint256 amount) external override onlyProduct {
        bool success = market.provideLiquidity{value: amount}();
        require(success, "Can't provide liquidity");
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        (bool sent, ) = payable(to).call{value: amount}("");
        require(sent, "Can't withdraw");
    }

    function onERC1155Received(
        address operator,
        address,
        uint256 tokenId,
        uint256,
        bytes calldata
    ) external view onlyMarketTokens(operator, tokenId) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata tokenIds,
        uint256[] calldata,
        bytes calldata
    ) external view onlyMarketTokensMultiple(operator, tokenIds) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "./interfaces/ITokensRepository.sol";
import "./interfaces/IMarket.sol";
import "./interfaces/IProduct.sol";

abstract contract PredictionMarket is IMarket, IERC165, ReentrancyGuard, ERC2771Context {
    event DecisionRendered(Result result);
    event DecisionPostponed();
    event LiquidityProvided(address provider, uint256 amount);
    event ParticipatedInMarket(address indexed participant, uint256 amount, bool betYes);
    event BetWithdrawn(address indexed participant, uint256 amount, bool betYes);
    event RewardWithdrawn(address indexed participant, uint256 amount);

    bytes32 _marketId;
    uint256 _uniqueId;
    DecisionState _decisionState;
    Result _result;
    uint256 _ammConst;

    ITokensRepository _tokensRepo;
    FinalBalance _finalBalance;
    address payable _liquidityProvider;
    address payable _feeCollector;
    address private _createdBy;
    IProduct _product;

    Config _config;

    mapping(address => uint256) _bets;
    uint256 _tvl;

    uint256 private immutable _tokensBase = 10000;

    constructor(
        Config memory config_,
        uint256 uniqueId_,
        bytes32 marketId_,
        ITokensRepository tokensRepo_,
        address payable feeCollector_,
        IProduct product_,
        address trustedForwarder_
    )
        ERC2771Context(trustedForwarder_)
    {
        _config = config_;
        _uniqueId = uniqueId_;
        _marketId = marketId_;
        _tokensRepo = tokensRepo_;
        _feeCollector = feeCollector_;
        _product = product_;

        _createdBy = msg.sender;
    }

    function product() external view returns (address) {
        return address(_product);
    }

    function marketId() external view returns (bytes32) {
        return _marketId;
    }

    function createdBy() external view returns (address) {
        return _createdBy;
    }

    function tokenSlots() external pure returns (uint8) {
        return 2;
    }

    function finalBalance() external view returns (FinalBalance memory) {
        return _finalBalance;
    }

    function decisionState() external view returns (DecisionState) {
        return _decisionState;
    }

    function config() external view returns (Config memory) {
        return _config;
    }

    function tvl() external view returns (uint256) {
        return _tvl;
    }

    function result() external view returns (Result) {
        return _result;
    }

    function tokenIds() external view returns (uint256 tokenIdYes, uint256 tokenIdNo) {
        tokenIdYes = _tokenIdYes();
        tokenIdNo = _tokenIdNo();
    }

    /// @dev Returns the current distribution of tokens in the market. 2439 = 2.439%
    function currentDistribution() external view returns (uint256) {
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes()); // 250
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo()); // 10240

        uint256 grandTotal = totalYes + totalNo; // 10290
        return (totalYes * _tokensBase) / grandTotal; // 250 * 10000 / 10290 = 2439
    }

    function canBeSettled() external view returns (bool) {
        bool stateCheck = _decisionState == DecisionState.NO_DECISION ||
            _decisionState == DecisionState.DECISION_NEEDED;
        bool timeCheck = _config.closingTime < block.timestamp;
        return stateCheck && timeCheck;
    }

    function trySettle() external {
        require(block.timestamp > _config.cutoffTime, "Market is not closed yet");
        require(
            _decisionState == DecisionState.NO_DECISION ||
                _decisionState == DecisionState.DECISION_NEEDED,
            "Wrong market state"
        );

        _trySettle();

        _decisionState = DecisionState.DECISION_LOADING;

        _finalBalance = FinalBalance(
            _tvl,
            _tokensRepo.totalSupply(_tokenIdYes()),
            _tokensRepo.totalSupply(_tokenIdNo())
        );
    }

    function recordDecision(bytes calldata payload) external {
        require(msg.sender == address(_config.oracle), "Unauthorized sender");
        require(_decisionState == DecisionState.DECISION_LOADING, "Wrong state");

        (_decisionState, _result) = _renderDecision(payload);

        if (_decisionState == DecisionState.DECISION_RENDERED) {
            _claim(_liquidityProvider, true);
            emit DecisionRendered(_result);
            _product.onMarketSettle(_marketId, _result == Result.YES, payload);
        } else if (_decisionState == DecisionState.DECISION_NEEDED) {
            emit DecisionPostponed();
        }
    }

    function priceETHToYesNo(uint256 amountIn) external view returns (uint256, uint256) {
        // adjusts the fee
        amountIn -= _calculateFees(amountIn);

        return _priceETHToYesNo(amountIn);
    }

    function priceETHForYesNoMarket(uint256 amountOut) external view returns (uint256, uint256) {
        return _priceETHForYesNo(amountOut);
    }

    function priceETHForYesNo(
        uint256 amountOut,
        address account
    ) external view returns (uint256, uint256) {
        return _priceETHForYesNoWithdrawal(amountOut, account);
    }

    function priceETHForPayout(
        uint256 amountOut,
        address account,
        bool isYes
    ) external view returns (uint256) {
        return _priceETHForPayout(amountOut, account, isYes);
    }

    function provideLiquidity() external payable override returns (bool) {
        require(_liquidityProvider == address(0), "Already provided");
        require(msg.value == _config.lpBid, "Not enough to init");

        uint256 amountLPYes = (_tokensBase * (10 ** 18) * uint256(_config.initP)) / 10000;
        uint256 amountLPNo = (_tokensBase * (10 ** 18) * (10000 - uint256(_config.initP))) / 10000;

        _ammConst = amountLPYes * amountLPNo;
        _liquidityProvider = payable(msg.sender);
        _tvl += msg.value;

        _tokensRepo.mint(_liquidityProvider, _tokenIdYes(), amountLPYes);
        _tokensRepo.mint(_liquidityProvider, _tokenIdNo(), amountLPNo);

        emit LiquidityProvided(_liquidityProvider, msg.value);

        _product.onMarketLiquidity(_marketId, msg.sender, msg.value);

        return true;
    }

    function participate(bool betYes) external payable nonReentrant {
        // TODO: add slippage guard
        _beforeAddBet(_msgSender(), msg.value);
        _addBet(_msgSender(), betYes, msg.value);
    }

    function registerParticipant(address account, bool betYes) external payable nonReentrant {
        require(msg.sender == address(_product), "Unknown caller");

        _beforeAddBet(account, msg.value);
        _addBet(account, betYes, msg.value);
    }

    function withdrawBet(uint256 amount, bool betYes) external nonReentrant {
        require(_decisionState == DecisionState.NO_DECISION, "Wrong state");
        require(_config.cutoffTime > block.timestamp, "Market is closed");

        _withdrawBet(_msgSender(), betYes, amount);
    }

    function claim() external nonReentrant {
        require(_decisionState == DecisionState.DECISION_RENDERED);
        require(_result != Result.UNDEFINED);

        _claim(_msgSender(), false);
    }

    function _priceETHToYesNo(
        uint256 amountIn
    ) internal view returns (uint256 amountOutYes, uint256 amountOutNo) {
        uint256 amountBank = _tvl;
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo());

        amountOutYes = (amountIn * totalYes) / amountBank;
        amountOutNo = (amountIn * totalNo) / amountBank;
    }

    function _priceETHForYesNo(
        uint256 amountOut
    ) internal view returns (uint256 amountInYes, uint256 amountInNo) {
        uint256 amountBank = _tvl;
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo());

        amountInYes = (amountOut * amountBank) / totalYes;
        amountInNo = (amountOut * amountBank) / totalNo;
    }

    /**
     * Calculates the amount of ETH that needs to be sent to the contract to withdraw a given amount of YES/NO tokens
     * Compares existing market price with the price of the account's position (existing account's bank / account's YES/NO tokens)
     * The lesser of the two is used to calculate the amount of ETH that needs to be sent to the contract
     * @param amountOut - amount of YES/NO tokens to withdraw
     * @param account - account to withdraw from
     * @return amountInYes - amount of ETH to send to the contract for YES tokens
     * @return amountInNo - amount of ETH to send to the contract for NO tokens
     */
    function _priceETHForYesNoWithdrawal(
        uint256 amountOut,
        address account
    ) internal view returns (uint256 amountInYes, uint256 amountInNo) {
        uint256 amountBank = _tvl;
        uint256 totalYes = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 totalNo = _tokensRepo.totalSupply(_tokenIdNo());

        uint256 marketAmountInYes = (amountOut * amountBank) / totalYes;
        uint256 marketAmountInNo = (amountOut * amountBank) / totalNo;

        uint256 accountBankAmount = _bets[account];
        uint256 accountTotalYes = _tokensRepo.balanceOf(account, _tokenIdYes());
        uint256 accountTotalNo = _tokensRepo.balanceOf(account, _tokenIdNo());

        uint256 accountAmountInYes = accountTotalYes == 0
            ? 0
            : (amountOut * accountBankAmount) / accountTotalYes;
        uint256 accountAmountInNo = accountTotalNo == 0
            ? 0
            : (amountOut * accountBankAmount) / accountTotalNo;

        amountInYes = marketAmountInYes > accountAmountInYes
            ? accountAmountInYes
            : marketAmountInYes;
        amountInNo = marketAmountInNo > accountAmountInNo ? accountAmountInNo : marketAmountInNo;
    }

    /**
     * Calculates the amount of ETH that could be paid out to the account if the market is resolved with a given result
     * and the account's position is YES/NO + amount of ETH sent to the contract
     * @param amountIn - amount of ETH potentially sent to the contract
     * @param account - account to calculate payout for
     * @param resultYes - potential result of the market
     */
    function _priceETHForPayout(
        uint256 amountIn,
        address account,
        bool resultYes
    ) internal view returns (uint256 payout) {
        // 1. Calculate the amount of ETH that the account has in the market + current total supply of YES/NO tokens
        uint256 accountTotalYes = _tokensRepo.balanceOf(account, _tokenIdYes());
        uint256 accountTotalNo = _tokensRepo.balanceOf(account, _tokenIdNo());

        uint256 amountLPYes = _tokensRepo.balanceOf(_liquidityProvider, _tokenIdYes());
        uint256 amountLPNo = _tokensRepo.balanceOf(_liquidityProvider, _tokenIdNo());

        uint256 finalYesSupply = _tokensRepo.totalSupply(_tokenIdYes());
        uint256 finalNoSupply = _tokensRepo.totalSupply(_tokenIdNo());

        // 2. Adjust with the amount of fees that the account could paid
        amountIn -= _calculateFees(amountIn);

        // 3. Calculate the amount of ETH that the market could have + YES/NO tokens that the account could get for amountIn
        uint256 finalBankAmount = _tvl + amountIn;

        uint256 userPurchaseYes;
        uint256 userPurchaseNo;
        (userPurchaseYes, userPurchaseNo) = _priceETHToYesNo(amountIn);

        if (resultYes) {
            // 5. Calculate the amount of ETH that the account could get for the final YES tokens
            accountTotalYes += userPurchaseYes;
            finalYesSupply += userPurchaseYes;
            amountLPNo += userPurchaseNo;
            finalNoSupply += userPurchaseNo;

            uint256 toBurn;
            uint256 toMint;
            (toBurn, toMint) = _calculateLPBalanceChange(resultYes, amountLPYes, amountLPNo);
            finalYesSupply = toBurn > 0 ? finalYesSupply - toBurn : finalYesSupply + toMint;
            // for buyer mode, we need to add the burned tokens back to the account and final supply
            if (toBurn > 0 && _config.mode == Mode.BUYER) {
                accountTotalYes += toBurn;
                finalYesSupply += toBurn;
            }
            payout = (accountTotalYes * finalBankAmount) / finalYesSupply;
        } else {
            // 5. Calculate the amount of ETH that the account could get for the final NO tokens
            accountTotalNo += userPurchaseNo;
            finalNoSupply += userPurchaseNo;
            amountLPYes += userPurchaseYes;
            finalYesSupply += userPurchaseYes;

            uint256 toBurn;
            uint256 toMint;
            (toBurn, toMint) = _calculateLPBalanceChange(resultYes, amountLPYes, amountLPNo);
            finalNoSupply = toBurn > 0 ? finalNoSupply - toBurn : finalNoSupply + toMint;
            // for buyer mode, we need to add the burned tokens back to the account and final supply
            if (toBurn > 0 && _config.mode == Mode.BUYER) {
                accountTotalNo += toBurn;
                finalNoSupply += toBurn;
            }
            payout = (accountTotalNo * finalBankAmount) / finalNoSupply;
        }
    }

    function _addBet(address account, bool betYes, uint256 value) internal {
        uint256 fee = _calculateFees(value);
        value -= fee;

        uint256 userPurchaseYes;
        uint256 userPurchaseNo;
        (userPurchaseYes, userPurchaseNo) = _priceETHToYesNo(value);

        // 4. Mint for user and for DFI
        // 5. Also balance out DFI
        uint256 userPurchase;
        if (betYes) {
            userPurchase = userPurchaseYes;
            _tokensRepo.mint(account, _tokenIdYes(), userPurchaseYes);
            _tokensRepo.mint(_liquidityProvider, _tokenIdNo(), userPurchaseNo);
        } else {
            userPurchase = userPurchaseNo;
            _tokensRepo.mint(account, _tokenIdNo(), userPurchaseNo);
            _tokensRepo.mint(_liquidityProvider, _tokenIdYes(), userPurchaseYes);
        }

        _balanceLPTokens(account, betYes, false);

        _bets[account] += value;
        _tvl += value;

        (bool sent, ) = _feeCollector.call{value: fee}("");
        require(sent, "Cannot distribute the fee");

        // Check in AMM product is the same
        // FIXME: will never be the same because of rounding
        // amountLPYes = balanceOf(address(_lpWallet), tokenIdYes);
        // amountLPNo = balanceOf(address(_lpWallet), tokenIdNo);
        // require(ammConst == amountDfiYes * amountDfiNo, "AMM const is wrong");

        emit ParticipatedInMarket(account, value, betYes);
        _product.onMarketParticipate(_marketId, account, value, betYes, userPurchase);
    }

    function _withdrawBet(address account, bool betYes, uint256 amount) internal {
        uint256 userRefundYes;
        uint256 userRefundNo;
        (userRefundYes, userRefundNo) = _priceETHForYesNoWithdrawal(amount, account);

        uint256 userRefund;
        if (betYes) {
            userRefund = userRefundYes;

            _tokensRepo.burn(account, _tokenIdYes(), amount);
            _tokensRepo.mint(_liquidityProvider, _tokenIdYes(), amount);
        } else {
            userRefund = userRefundNo;

            _tokensRepo.burn(account, _tokenIdNo(), amount);
            _tokensRepo.mint(_liquidityProvider, _tokenIdNo(), amount);
        }

        _balanceLPTokens(account, !betYes, true);

        // 6. Check in AMM product is the same
        // FIXME: will never be the same because of rounding
        // amountLpYes = balanceOf(address(_lpWallet), tokenIdYes);
        // amountLpNo = balanceOf(address(_lpWallet), tokenIdNo);
        // require(ammConst == amountLpYes * amountLpNo, "AMM const is wrong");

        if (userRefund > _bets[account]) {
            _bets[account] = 0;
        } else {
            _bets[account] -= userRefund;
        }
        _tvl -= userRefund;

        // TODO: add a fee or something
        (bool sent, ) = payable(account).call{value: userRefund}("");
        require(sent, "Cannot withdraw");

        emit BetWithdrawn(account, userRefund, betYes);
        _product.onMarketWithdraw(_marketId, account, amount, betYes, userRefund);
    }

    function _balanceLPTokens(address account, bool fixYes, bool isWithdraw) internal {
        uint256 tokenIdYes = _tokenIdYes();
        uint256 tokenIdNo = _tokenIdNo();

        uint256 amountLPYes = _tokensRepo.balanceOf(_liquidityProvider, tokenIdYes);
        uint256 amountLPNo = _tokensRepo.balanceOf(_liquidityProvider, tokenIdNo);

        // Pre-calculate the amount of tokens to burn/mint for the LP balance
        uint256 toBurn;
        uint256 toMint;
        (toBurn, toMint) = _calculateLPBalanceChange(fixYes, amountLPYes, amountLPNo);

        if (fixYes) {
            if (toBurn > 0) {
                if (_config.mode == Mode.BUYER && !isWithdraw) {
                    _tokensRepo.burn(_liquidityProvider, tokenIdYes, toBurn);
                    _tokensRepo.mint(account, tokenIdYes, toBurn);
                } else {
                    _tokensRepo.burn(_liquidityProvider, tokenIdYes, toBurn);
                }
            } else {
                _tokensRepo.mint(_liquidityProvider, tokenIdYes, toMint);
            }
        } else {
            if (toBurn > 0) {
                if (_config.mode == Mode.BUYER && !isWithdraw) {
                    _tokensRepo.burn(_liquidityProvider, tokenIdNo, toBurn);
                    _tokensRepo.mint(account, tokenIdNo, toBurn);
                } else {
                    _tokensRepo.burn(_liquidityProvider, tokenIdNo, toBurn);
                }
            } else {
                _tokensRepo.mint(_liquidityProvider, tokenIdNo, toMint);
            }
        }
    }

    function _claim(address account, bool silent) internal {
        bool yesWins = _result == Result.YES;

        uint256 reward;
        // TODO: if Yes wins and you had NoTokens - it will never be burned
        if (yesWins) {
            uint256 balance = _tokensRepo.balanceOf(account, _tokenIdYes());
            if (!silent) {
                require(balance > 0, "Nothing to withdraw");
            }

            reward = (balance * _finalBalance.bank) / _finalBalance.yes;

            _tokensRepo.burn(account, _tokenIdYes(), balance);
        } else {
            uint256 balance = _tokensRepo.balanceOf(account, _tokenIdNo());
            if (!silent) {
                require(balance > 0, "Nothing to withdraw");
            }

            reward = (balance * _finalBalance.bank) / _finalBalance.no;

            _tokensRepo.burn(account, _tokenIdNo(), balance);
        }

        if (reward > 0) {
            (bool sent, ) = payable(account).call{value: reward}("");
            require(sent, "Cannot withdraw");

            emit RewardWithdrawn(account, reward);
            _product.onMarketClaim(_marketId, account, reward);
        }
    }

    /**
     * Based on the existing balances of the LP tokens, calculate the amount of tokens to burn OR mint
     * In order to keep the AMM constant stable
     * @param fixYes - if true, fix the Yes token, otherwise fix the No token
     * @param amountLPYes - actual amount of Yes tokens in the LP wallet
     * @param amountLPNo - actual amount of No tokens in the LP wallet
     * @return amountToBurn - amount of tokens to burn to fix the AMM
     * @return amountToMint - amount of tokens to mint to fix the AMM
     */
    function _calculateLPBalanceChange(
        bool fixYes,
        uint256 amountLPYes,
        uint256 amountLPNo
    ) internal view returns (uint256 amountToBurn, uint256 amountToMint) {
        if (fixYes) {
            uint256 newAmountYes = _ammConst / (amountLPNo);
            amountToBurn = amountLPYes > newAmountYes ? amountLPYes - newAmountYes : 0;
            amountToMint = amountLPYes > newAmountYes ? 0 : newAmountYes - amountLPYes;
            return (amountToBurn, amountToMint);
        } else {
            uint256 newAmountNo = _ammConst / (amountLPYes);
            amountToBurn = amountLPNo > newAmountNo ? amountLPNo - newAmountNo : 0;
            amountToMint = amountLPNo > newAmountNo ? 0 : newAmountNo - amountLPNo;
            return (amountToBurn, amountToMint);
        }
    }

    /**
     * Calculate the value of the fees to hold from the given amountIn
     * @param amount - amountIn from which to calculate the fees
     */
    function _calculateFees(uint256 amount) internal view returns (uint256) {
        return (amount * uint256(_config.fee)) / 10000;
    }

    function _tokenIdYes() internal view returns (uint256) {
        return _uniqueId;
    }

    function _tokenIdNo() internal view returns (uint256) {
        return _uniqueId + 1;
    }

    function _beforeAddBet(address account, uint256 amount) internal view virtual {
        require(_config.cutoffTime > block.timestamp, "Market is closed");
        require(_decisionState == DecisionState.NO_DECISION, "Wrong state");
        require(amount >= _config.minBid, "Value included is less than min-bid");

        uint256 balance = _bets[account];
        require(balance + amount <= _config.maxBid, "Exceeded max bid");
    }

    function _trySettle() internal virtual;

    function _renderDecision(bytes calldata) internal virtual returns (DecisionState, Result);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IMarket).interfaceId;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Trustus
/// @author zefram.eth
/// @notice Trust-minimized method for accessing offchain data onchain
abstract contract Trustus is Initializable {
    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param v Part of the ECDSA signature
    /// @param r Part of the ECDSA signature
    /// @param s Part of the ECDSA signature
    /// @param request Identifier for verifying the packet is what is desired
    /// , rather than a packet for some other function/contract
    /// @param deadline The Unix timestamp (in seconds) after which the packet
    /// should be rejected by the contract
    /// @param payload The payload of the packet
    struct TrustusPacket {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 request;
        uint256 deadline;
        bytes payload;
    }

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Trustus__InvalidPacket();

    /// @notice The chain ID used by EIP-712
    uint256 internal INITIAL_CHAIN_ID;

    /// @notice The domain separator used by EIP-712
    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Records whether an address is trusted as a packet provider
    /// @dev provider => value
    mapping(address => bool) internal isTrusted;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    /// @notice Verifies whether a packet is valid and returns the result.
    /// Will revert if the packet is invalid.
    /// @dev The deadline, request, and signature are verified.
    /// @param request The identifier for the requested payload
    /// @param packet The packet provided by the offchain data provider
    modifier verifyPacket(bytes32 request, TrustusPacket calldata packet) {
        if (!_verifyPacket(request, packet)) revert Trustus__InvalidPacket();
        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    function __Trustus_init() public onlyInitializing {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// -----------------------------------------------------------------------
    /// Packet verification
    /// -----------------------------------------------------------------------

    /// @notice Verifies whether a packet is valid and returns the result.
    /// @dev The deadline, request, and signature are verified.
    /// @param request The identifier for the requested payload
    /// @param packet The packet provided by the offchain data provider
    /// @return success True if the packet is valid, false otherwise
    function _verifyPacket(
        bytes32 request,
        TrustusPacket calldata packet
    ) internal virtual returns (bool success) {
        // verify deadline
        if (block.timestamp > packet.deadline) return false;

        // verify request
        if (request != packet.request) return false;

        // verify signature
        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "VerifyPacket(bytes32 request,uint256 deadline,bytes payload)"
                            ),
                            packet.request,
                            packet.deadline,
                            keccak256(packet.payload)
                        )
                    )
                )
            ),
            packet.v,
            packet.r,
            packet.s
        );
        return (recoveredAddress != address(0)) && isTrusted[recoveredAddress];
    }

    /// @notice Sets the trusted status of an offchain data provider.
    /// @param signer The data provider's ECDSA public key as an Ethereum address
    /// @param isTrusted_ The desired trusted status to set
    function _setIsTrusted(address signer, bool isTrusted_) internal virtual {
        isTrusted[signer] = isTrusted_;
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 compliance
    /// -----------------------------------------------------------------------

    /// @notice The domain separator used by EIP-712
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : _computeDomainSeparator();
    }

    /// @notice Computes the domain separator used by EIP-712
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256("Trustus"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IProduct.sol";
import "../interfaces/IRegistry.sol";

abstract contract RegistryMixin {
    IRegistry _registry;

    function isValidMarket(address operator) internal view returns (bool) {
        // check if it's even a market
        bool isMarket = IERC165(operator).supportsInterface(type(IMarket).interfaceId);
        require(isMarket);

        // get the product market claims it belongs to
        IMarket market = IMarket(operator);
        address productAddr = market.product();
        // check if the product is registered
        require(_registry.getId(productAddr) != 0, "Unknown product");

        // check that product has the market with the same address
        IProduct product = IProduct(productAddr);
        require(product.getMarket(market.marketId()) == operator, "Unknown market");

        return true;
    }

    modifier onlyMarket(address operator) {
        require(isValidMarket(operator));
        _;
    }

    modifier onlyMarketTokens(address operator, uint256 tokenId) {
        require(isValidMarket(operator));

        IMarket market = IMarket(operator);

        // check that market is modifying the tokens it controls
        (uint256 tokenIdYes, uint256 tokenIdNo) = market.tokenIds();
        require(tokenId == tokenIdYes || tokenId == tokenIdNo, "Wrong tokens");

        _;
    }

    modifier onlyMarketTokensMultiple(address operator, uint256[] calldata tokenIds) {
        require(isValidMarket(operator));

        IMarket market = IMarket(operator);

        // check that market is modifying the tokens it controls
        (uint256 tokenIdYes, uint256 tokenIdNo) = market.tokenIds();
        for (uint32 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] == tokenIdYes || tokenIds[i] == tokenIdNo, "Wrong tokens");
        }

        _;
    }

    modifier onlyProduct() {
        require(_registry.getId(msg.sender) != 0, "Unknown product");
        _;
    }

    function _setRegistry(IRegistry registry_) internal {
        _registry = registry_;
    }
}

abstract contract RegistryMixinUpgradeable is Initializable, RegistryMixin {
    function __RegistryMixin_init(IRegistry registry_) internal onlyInitializing {
        _setRegistry(registry_);
    }
}