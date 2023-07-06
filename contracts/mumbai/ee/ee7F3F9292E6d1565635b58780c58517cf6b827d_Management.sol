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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../token/draft-IERC1822.sol";
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
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

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
        require(
            Address.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
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
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (
                bytes32 slot
            ) {
                require(
                    slot == _IMPLEMENTATION_SLOT,
                    "ERC1967Upgrade: unsupported proxiableUUID"
                );
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
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

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
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
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
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
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
            Address.functionDelegateCall(
                IBeacon(newBeacon).implementation(),
                data
            );
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
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../upgradeable/utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../token/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
        require(
            address(this) != __self,
            "Function must be called through delegatecall"
        );
        require(
            _getImplementation() == __self,
            "Function must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(
            address(this) == __self,
            "UUPSUpgradeable: must not be called through delegatecall"
        );
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
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../../proxy/utils/Initializable.sol";

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
import "../../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Escrow contract for CreatorsPRO */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces.
import {IEscrow} from "./interfaces/IEscrow.sol";
import {IManagement} from "./interfaces/IManagement.sol";
import {IERC721ArtHandle} from "./interfaces/IERC721ArtHandle.sol";

///@dev security settings.
import {Security} from "./Security.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract Escrow is IEscrow, Security {
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    ///@dev next deposit ID
    uint256 private s_nextDepositId;

    ///@dev last deposit ID withdrawn
    uint256 private s_nextDepositIdToWithdraw;

    ///@dev mapping from deposit Id to Deposit struct. See {struct IEscrow.Deposit}
    mapping(uint256 depositId => Deposit info) private s_deposits;

    //constants
    uint256 private constant SEVEN_DAYS = 7 days;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    /** @dev constructor for the Escrow contract
        @param creator: creator address */
    constructor(address creator) Security(msg.sender) {
        _transferOwnership(creator);
        s_nextDepositId = 1;
        s_nextDepositIdToWithdraw = 1;
    }

    /// -----------------------------------------------------------------------
    /// Implemented functions
    /// -----------------------------------------------------------------------

    /** @dev added whenNotPaused modifier. It wsill rever if caller is not manager or
    if given coin is ETH */
    /// @inheritdoc IEscrow
    function deposit(
        uint256 amount,
        address payer,
        IManagement.Coin coin
    ) public virtual override(IEscrow) {
        _whenNotPaused();
        _nonReentrant();
        _isAllowedCreator();
        _onlyManagers();
        _notCorrupted();
        _onlyValidCoin(coin);

        unchecked {
            s_deposits[s_nextDepositId] = Deposit(
                amount,
                block.timestamp + SEVEN_DAYS,
                coin
            );
            s_nextDepositId++;
        }

        _transferERC20To(coin, payer, address(this), amount);

        emit Deposited(msg.sender, payer, amount, block.timestamp + SEVEN_DAYS);
    }

    /// @dev added whenNotPaused, onlyOwner, and nonReentrant modifiers.
    /// @inheritdoc IEscrow
    function withdraw() public virtual override(IEscrow) onlyOwner {
        _whenNotPaused();
        _nonReentrant();
        _isAllowedCreator();
        _notCorrupted();

        uint256 nextDepositIdToWithdraw = s_nextDepositIdToWithdraw;
        uint256 nextDepositId = s_nextDepositId;
        uint256 lastIteration = nextDepositIdToWithdraw;
        address owner_ = owner();
        for (uint256 ii = nextDepositIdToWithdraw; ii < nextDepositId; ++ii) {
            Deposit memory payment = s_deposits[ii];

            if (block.timestamp < payment.endTimestamp) {
                break;
            } else if (payment.amount == 0) {
                continue;
            }

            lastIteration = ii;

            _transferERC20To(
                payment.coin,
                address(this),
                owner_,
                payment.amount
            );
        }

        s_nextDepositIdToWithdraw = lastIteration + 1;

        emit Withdrawn(nextDepositIdToWithdraw, nextDepositId - 1);
    }

    /// @dev added whenNotPaused and nonReentrant modifiers.
    /// @inheritdoc IEscrow
    function withdrawByManager() external override(IEscrow) {
        _whenNotPaused();
        _nonReentrant();
        _onlyManagers();

        address multiSig = i_management.getMultiSig();

        _transferTo(multiSig, address(this).balance);

        _transferERC20To(
            IManagement.Coin.USD_TOKEN,
            address(this),
            multiSig,
            i_management.getTokenContract(IManagement.Coin.USD_TOKEN).balanceOf(
                address(this)
            )
        );

        _transferERC20To(
            IManagement.Coin.CREATORS_TOKEN,
            address(this),
            multiSig,
            i_management
                .getTokenContract(IManagement.Coin.CREATORS_TOKEN)
                .balanceOf(address(this))
        );

        uint256 nextDepositIdToWithdraw = s_nextDepositIdToWithdraw;
        uint256 nextDepositId = s_nextDepositId;
        for (uint256 ii = nextDepositIdToWithdraw; ii < nextDepositId; ++ii) {
            delete s_deposits[ii];
        }

        s_nextDepositId = nextDepositIdToWithdraw;

        emit WithdrawnByManager(msg.sender, 0, IManagement.Coin.ETH_COIN, true);
    }

    /// @dev added whenNotPaused and nonReentrant modifiers.
    /// @inheritdoc IEscrow
    function withdrawByManager(
        uint256 depositId,
        uint256 amount
    ) public override(IEscrow) {
        _whenNotPaused();
        _nonReentrant();
        _onlyManagers();

        Deposit memory deposit_ = s_deposits[depositId];
        if (amount > deposit_.amount) {
            revert Escrow__AmountGreaterThanDeposited();
        } else if (amount == deposit_.amount) {
            delete s_deposits[depositId];
        } else {
            s_deposits[depositId].amount -= amount;
        }

        _transferERC20To(
            deposit_.coin,
            address(this),
            i_management.getMultiSig(),
            amount
        );

        emit WithdrawnByManager(msg.sender, amount, deposit_.coin, false);
    }

    /// @dev added whenNotPaused and nonReentrant modifiers.
    /// @inheritdoc IEscrow
    function refundNFT(
        address collection,
        uint256 tokenId,
        uint256 depositId,
        uint256 amount
    ) external override(IEscrow) {
        _whenNotPaused();
        _nonReentrant();
        _onlyManagers();

        if (!i_management.getCollections(collection)) {
            revert Escrow__InvalidCollectionAddress();
        }

        IERC721ArtHandle collectionContract = IERC721ArtHandle(collection);
        if (
            block.timestamp >
            collectionContract.getLastTransfer(tokenId) + SEVEN_DAYS
        ) {
            revert Escrow__NFTRefundNotPossible();
        }

        collectionContract.safeTransferFrom(
            collectionContract.ownerOf(tokenId),
            collectionContract.owner(),
            tokenId
        );

        withdrawByManager(depositId, amount);

        emit NFTRefunded(msg.sender, collection, tokenId);
    }

    // --- Pause and Unpause functions ---

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. */
    /// @inheritdoc Security
    function pause() public override(Security) {
        _onlyAuthorized();

        Security.pause();
    }

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. */
    /// @inheritdoc Security
    function unpause() public override(Security) {
        _onlyAuthorized();

        Security.unpause();
    }

    /// @inheritdoc IEscrow
    function getNextDepositId()
        external
        view
        override(IEscrow)
        returns (uint256)
    {
        return s_nextDepositId;
    }

    /// @inheritdoc IEscrow
    function getNextDepositIdToWithdraw()
        external
        view
        override(IEscrow)
        returns (uint256)
    {
        return s_nextDepositIdToWithdraw;
    }

    /// @inheritdoc IEscrow
    function depositOf(
        uint256 depositId
    ) public view override(IEscrow) returns (Deposit memory) {
        return s_deposits[depositId];
    }

    /// @inheritdoc IEscrow
    function getAllAvailableDeposits()
        external
        view
        override(IEscrow)
        returns (Deposit[] memory)
    {
        uint256 nextDepositIdToWithdraw = s_nextDepositIdToWithdraw;
        uint256 nextDepositId = s_nextDepositId;

        Deposit[] memory _depArr = new Deposit[](
            nextDepositId - nextDepositIdToWithdraw
        );

        uint256 jj;
        for (uint256 ii = nextDepositIdToWithdraw; ii < nextDepositId; ++ii) {
            _depArr[jj] = s_deposits[ii];
            jj++;
        }

        return _depArr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the reward contract of CreatorsPRO NFTs */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface ICRPReward {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error CRPReward__NotAllowed();

    ///@dev error for when the input arrays have not the same length
    error CRPReward__InputArraysNotSameLength();

    ///@dev error for when time unit is zero
    error CRPReward__TimeUnitZero();

    ///@dev error for when there are no rewards
    error CRPReward__NoRewards();

    ///@dev error for when an invalid coin is given
    error CRPReward__InvalidCoin();

    ///@dev error for when an invalid collection is calling a function
    error CRPReward__InvalidCollection();

    ///@dev error for when new interaction points precision is 0
    error CRPReward__InteracPointsPrecisionIsZero();

    ///@dev error for when new max reward claim value is 0
    error CRPReward__InvalidMaxRewardClaimValue();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev struct to store important token infos
        @param index: index of the token ID in the tokenIdsPerUser mapping
        @param hashpower: CreatorsPRO hashpower
        @param characteristId: CreatorsPRO characterist ID */
    struct TokenInfo {
        uint256 index; // 0 is for no longer listed
        uint256 hashpower;
        uint256 characteristId;
    }

    /** @dev struct to store user's info
        @param index: user index in usersArray storage array
        @param score: sum of the hashpowers from the NFTs owned by the user
        @param points: sum of interactions points done by the user
        @param timeOfLastUpdate: timestamp for the last information update
        @param unclaimedRewards: total amount of rewards still unclaimed
        @param conditionIdOflastUpdate: condition ID for the last update 
        @param collections: array of collection addresses of the user's NFTs */
    struct User {
        uint256 index; // 0 is for address no longer a user
        uint256 score;
        uint256 points;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 conditionIdOflastUpdate;
        address[] collections;
    }

    /** @dev struct for staking condition
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: array of rewards per time unit (timeUnit)
        @param startTimestamp: timestamp for when the condition begins
        @param endTimestamp: timestamp for when the condition ends */
    struct RewardCondition {
        uint256 timeUnit;
        uint256 rewardsPerUnitTime;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when points are added/increased
        @param user: user address
        @param tokenId: ID of the token
        @param points: amount of points increased
        @param value: value added/subtracted */
    event PointsSet(
        address indexed user,
        uint256 indexed tokenId,
        uint256 points,
        uint256 value
    );

    /** @dev event for when a token has been removed from tokenInfo mapping for
    the given user address
        @param user: user address
        @param tokenId: ID of the token */
    event TokenRemoved(address indexed user, uint256 indexed tokenId);

    /** @dev event for when rewards are claimed
        @param caller: address of the function caller (user)
        @param amount: amount of reward tokens claimed */
    event RewardsClaimed(address indexed caller, uint256 amount);

    /** @dev event for when the hash object for the tokenId is set.
        @param manager: address of the manager that has set the hash object
        @param collection: address of the collection
        @param tokenId: array of IDs of ERC721 token
        @param hashpower: array of hashpowers set by manager
        @param characteristId: array of IDs of the characterist */
    event HashObjectSet(
        address indexed manager,
        address indexed collection,
        uint256[] indexed tokenId,
        uint256[] hashpower,
        uint256[] characteristId
    );

    /** @dev event for when a new reward condition is set
        @param caller: function caller address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    event NewRewardCondition(
        address indexed caller,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    );

    /** @dev event for when new interacion points precision is set
        @param manager: manager address
        @param precision: array of precision values */
    event InteracPointsPrecisionSet(
        address indexed manager,
        uint256[3] precision
    );

    /** @dev event for when new max reward claim value is set
        @param manager: manager address
        @param maxRewardClaim: value for maximum reward claim */
    event MaxRewardClaimSet(address indexed manager, uint256 maxRewardClaim);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param management: Management contract address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time
        @param interacPoints: array of interaction points for each interaction (0: min, 1: send transfer, 2: receive transfer)
        @param maxRewardClaim:  maximum amount of claimable rewards */
    function initialize(
        address management,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime,
        uint256[3] calldata interacPoints,
        uint256 maxRewardClaim
    ) external;

    /** @notice increases the user score by the given amount
        @param user: user address
        @param tokenId: ID of the token 
        @param value: value added/subtracted
        @param coin: coin of transfer
        @param isSell: bool that specifies if is selling (true) or not (false) */
    function setPoints(
        address user,
        uint256 tokenId,
        uint256 value,
        uint8 coin,
        bool isSell
    ) external;

    /** @notice removes given token ID from given user address
        @param user: user address
        @param tokenId: token ID to be removed 
        @param emitEvent: true to emit event (external call), false otherwise (internal call)*/
    function removeToken(
        address user,
        uint256 tokenId,
        bool emitEvent
    ) external;

    /** @notice claims rewards to the caller wallet */
    function claimRewards() external;

    /** @notice sets hashpower and characterist ID for the given token ID
        @param collection: collection address
        @param tokenId: array of token IDs
        @param hashPower: array of hashpowers for the token ID
        @param characteristId: array of characterit IDs */
    function setHashObject(
        address collection,
        uint256[] memory tokenId,
        uint256[] memory hashPower,
        uint256[] memory characteristId
    ) external;

    /** @notice sets new reward condition
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    function setRewardCondition(
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    ) external;

    /** @notice sets new interaction points precision
        @param precision: array of new precision values */
    function setInteracPointsPrecision(uint256[3] calldata precision) external;

    /** @notice sets new maximum value for rewards claim
        @param maxRewardClaim: value for maximum reward claim */
    function setMaxRewardClaim(uint256 maxRewardClaim) external;

    // --- From storage variables ---

    /** @notice reads nextConditionId public storage variable 
        @return uint256 value for the next condition ID */
    function getNextConditionId() external view returns (uint256);

    // /** @notice reads totalScore public storage variable
    //     @return uint256 value for the sum of scores from all CreatorsPRO users */
    // function totalScore() external view returns (uint256);

    /** @notice reads usersArray public storage array 
        @param index: index of the array
        @return address of a user */
    function getUsersArray(uint256 index) external view returns (address);

    /** @notice reads collectionIndex public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @return uint256 value for the collection index in User struct */
    function getCollectionIndex(
        address user,
        address collection
    ) external view returns (uint256);

    /** @notice reads tokenIdsPerUser public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @param index: index value for token IDs array
        @return uint256 value for the token ID  */
    function getTokenIdsPerUser(
        address user,
        address collection,
        uint256 index
    ) external view returns (uint256);

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads hashObjects public storage mapping
        @param collection: address of an CreatorsPRO collection (ERC721)
        @param tokenId: ID of the token from the given collection
        @return uint256 values for hashpower and characterist ID */
    function getHashObject(
        address collection,
        uint256 tokenId
    ) external view returns (uint256, uint256);

    /** @notice reads tokenInfo public storage mapping
        @param collection: address of an CreatorsPRO collection (ERC721)
        @param tokenId: ID of the token from the given collection 
        @return TokenInfo struct with token infos */
    function getTokenInfo(
        address collection,
        uint256 tokenId
    ) external view returns (TokenInfo memory);

    /** @notice reads users public storage mapping 
        @param user: CreatorsPRO user address
        @return User struct with user's info */
    function getUser(address user) external view returns (User memory);

    /** @notice reads users public storage mapping, but the values are updated
        @param user: CreatorsPRO user address
        @return User struct with user's info */
    function getUserUpdated(address user) external view returns (User memory);

    /** @notice reads rewardCondition public storage mapping 
        @return RewardCondition struct with current reward condition info */
    function getCurrentRewardCondition()
        external
        view
        returns (RewardCondition memory);

    /** @notice reads rewardCondition public storage mapping 
        @param conditionId: condition ID
        @return RewardCondition struct with reward condition info */
    function getRewardCondition(
        uint256 conditionId
    ) external view returns (RewardCondition memory);

    /** @notice reads all token IDs from the array of tokenIdsPerUser public storage mapping
        @param user: user address
        @param collection: ERC721Art collection address
        @return uint256 array for the token IDs  */
    function getAllTokenIdsPerUser(
        address user,
        address collection
    ) external view returns (uint256[] memory);

    /** @notice reads interacPointsPrecision storage variable
        @return uint256[3] array with interaction points precision values */
    function getInteracPointsPrecision()
        external
        view
        returns (uint256[3] memory);

    /** @notice reads maxRewardClaim storage variable
        @return uint256 value for maximum allowed rewards claim */
    function getMaxRewardClaim() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC20 burnable contract */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC20Metadata} from "../@openzeppelin/token/IERC20Metadata.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC20Burnable is IERC20Metadata {
    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    /** @notice mints given amount of tokens to given address.       
        @param to: address for which tokens will be minted.
        @param amount: amount of tokens to mint .
        @return bool that specifies if mint was successful (true) or not (false). */
    function mint(address to, uint256 amount) external returns (bool);

    /** @notice burns given amount tokens from given account address.      
        @param account: account address from which tokens will be burned
        @param amount: amount of tokens to burn
        @return bool that specifies if tokens burn was successful (true) or not (false) */
    function burn(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC721 contract for artistic workpieces from allowed 
    artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC721Art {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when the collection max supply is reached (when maxSupply > 0)
    error ERC721Art__MaxSupplyReached();

    ///@dev error for when the value sent or the allowance is not enough to mint/buy token
    error ERC721Art__NotEnoughValueOrAllowance();

    ///@dev error for when caller is neighter manager nor collection creator
    error ERC721Art__NotAllowed();

    ///@dev error for when caller is not token owner
    error ERC721Art__NotTokenOwner();

    ///@dev error for when collection is for a crowdfund
    error ERC721Art__CollectionForFund();

    ///@dev error for when an invalid crowdfund address is set
    error ERC721Art__InvalidCrowdFund();

    ///@dev error for when the caller is not the crowdfund contract
    error ERC721Art__CallerNotCrowdfund();

    ///@dev error for when a crowfund address is already set
    error ERC721Art__CrodFundIsSet();

    ///@dev error for when input arrays don't have same length
    error ERC721Art__ArraysDoNotMatch();

    ///@dev error for when an invalid ERC20 contract address is given
    error ERC721Art__InvalidAddress();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new mint price is set.
        @param newPrice: new mint price 
        @param coin: token/coin of transfer */
    event PriceSet(uint256 indexed newPrice, IManagement.Coin indexed coin);

    /** @dev event for when owner sets new price for his/her token.
        @param tokenId: ID of ERC721 token
        @param price: new token price
        @param coin: token/coin of transfer */
    event TokenPriceSet(
        uint256 indexed tokenId,
        uint256 price,
        IManagement.Coin indexed coin
    );

    /** @dev event for when royalties transfers are done (mint).
        @param tokenId: ID of ERC721 token
        @param creatorsProRoyalty: royalty to CreatorsPRO
        @param creatorRoyalty: royalty to collection creator 
        @param fromWallet: address from which the payments was made */
    event RoyaltiesTransferred(
        uint256 indexed tokenId,
        uint256 creatorsProRoyalty,
        uint256 creatorRoyalty,
        address fromWallet
    );

    /** @dev event for when owner payments are done (creatorsProSafeTransferFrom).
        @param tokenId: ID of ERC721 token
        @param owner: owner address
        @param amount: amount transferred */
    event OwnerPaymentDone(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 amount
    );

    /** @dev event for when a new royalty fee is set
        @param _royalty: new royalty fee value */
    event RoyaltySet(uint256 _royalty);

    /** @dev event for when a new crowdfund address is set
        @param _crowdfund: address from crowdfund */
    event CrowdfundSet(address indexed _crowdfund);

    /** @dev event for when a new max discount for an ERC20 contract is set
        @param token: ERC20 contract address
        @param discount: discount value */
    event MaxDiscountSet(address indexed token, uint256 discount);

    /** @notice event for when a manager withdraws funds to address
        @param manager: manager address
        @param receiver: withdrawn fund receiver address
        @param amount: amount withdrawn */
    event WithdrawnToAddress(
        address indexed manager,
        address indexed receiver,
        uint256 amount
    );

    /** @notice event for when a new coreSFT address is set
        @param caller: function's caller address
        @param _coreSFT: new address for the SFT protocol */
    event NewCoreSFTSet(address indexed caller, address _coreSFT);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param name_: name of the NFT collection
        @param symbol_: symbol of the NFT collection
        @param owner_: collection owner/creator
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price_: mint price of a single NFT
        @param priceInUSD: mint price of a single NFT
        @param priceInCreatorsCoin: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner 
            (final value = _royalty / 10000 (ERC2981Upgradeable._feeDenominator())) */
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 maxSupply,
        uint256 price_,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) external;

    /** @notice mints given the NFT of given tokenId, using the given coin for transfer. Payable function.
        @param tokenId: tokenId to be minted 
        @param coin: token/coin of transfer 
        @param discount: discount given for NFT mint */
    function mint(
        uint256 tokenId,
        IManagement.Coin coin,
        uint256 discount
    ) external payable;

    /** @notice mints NFT of the given tokenId to the given address
        @param to: address to which the ticket is going to be minted
        @param tokenId: tokenId (batch) of the ticket to be minted */
    function mintToAddress(address to, uint256 tokenId) external;

    /** @notice mints token for crowdfunding        
        @param tokenIds: array of token IDs to mint
        @param classes: array of classes 
        @param to: address from tokens owner */
    function mintForCrowdfund(
        uint256[] memory tokenIds,
        uint8[] memory classes,
        address to
    ) external;

    /** @notice burns NFT of the given tokenId.
        @param tokenId: token ID to be burned */
    function burn(uint256 tokenId) external;

    /** @notice safeTransferFrom function especifically for CreatorPRO. It enforces (onchain) the transfer of the 
        correct token price. Payable function.
        @param coin: which coin to use (0 => ETH, 1 => USD, 2 => CreatorsCoin)
        The other parameters are the same from safeTransferFrom function. */
    function creatorsProSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        IManagement.Coin coin
    ) external payable;

    /** @notice sets NFT mint price.
        @param price: new NFT mint price 
        @param coin: coin/token to be set */
    function setPrice(uint256 price, IManagement.Coin coin) external;

    /** @notice sets the price of the ginve token ID.
        @param tokenId: ID of token
        @param price: new price to be set 
        @param coin: coin/token to be set */
    function setTokenPrice(
        uint256 tokenId,
        uint256 price,
        IManagement.Coin coin
    ) external;

    /** @notice sets new base URI for the collection.
        @param uri: new base URI to be set */
    function setBaseURI(string memory uri) external;

    /** @notice sets new royaly value for NFT transfer
        @param royalty: new value for royalty */
    function setRoyalty(uint256 royalty) external;

    /** @notice sets the crowdfund address 
        @param crowdfund: crowdfund contract address */
    function setCrowdfund(address crowdfund) external;

    /** @notice sets maxDiscount mapping for given ERC20 address
        @param token: ERC20 contract address
        @param maxDiscount_: max discount value */
    function setMaxDiscount(address token, uint256 maxDiscount_) external;

    /** @notice sets new coreSFT address
        @param coreSFT_: new address for the SFT protocol */
    function setCoreSFT(address coreSFT_) external;

    /** @notice gets the price of mint for the given address
        @param token: ERC20 token contract address 
        @return uint256 price value in the given ERC20 token */
    function price(address token) external view returns (uint256);

    /** @notice withdraws funds to given address
        @param receiver: fund receiver address
        @param amount: amount to withdraw */
    function withdrawToAddress(address receiver, uint256 amount) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    // --- From storage variables ---

    /** @notice reads maxSupply public storage variable
        @return uint256 value of maximum supply */
    function getMaxSupply() external view returns (uint256);

    /** @notice reads baseURI public storage variable 
        @return string of the base URI */
    function getBaseURI() external view returns (string memory);

    /** @notice reads price public storage mapping
        @param coin: coin/token for price
        @return uint256 value for price */
    function getPricePerCoin(
        IManagement.Coin coin
    ) external view returns (uint256);

    /** @notice reads lastTransfer public storage mapping 
        @param tokenId: ID of the token
        @return uint256 value for last trasfer of the given token ID */
    function getLastTransfer(uint256 tokenId) external view returns (uint256);

    /** @notice reads tokenPrice public storage mapping 
        @param tokenId: ID of the token
        @param coin: coin/token for specific token price 
        @return uint256 value for price of specific token */
    function getTokenPrice(
        uint256 tokenId,
        IManagement.Coin coin
    ) external view returns (uint256);

    /** @notice reads crowdfund public storage variable 
        @return address of the set crowdfund contract */
    function getCrowdfund() external view returns (address);

    /** @notice reads maxDiscountPerCoin public storage mapping by address
        @param token: ERC20 contract address
        @return uint256 for the max discount of the SFTRec protocol */
    function maxDiscount(address token) external view returns (uint256);

    /** @notice gets the royalty info (address and value) from ERC2981
        @return royalty receiver address and value */
    function getRoyalty() external view returns (address, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the ERC721 contract for artistic workpieces from allowed 
    artists/content creators */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IERC721ArtHandle {
    // ---- From IERC721 (OpenZeppelin) ----

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

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

    // ---- From OwnableUpgradeable (OpenZeppelin) ----

    function owner() external view returns (address);

    // ---- Owned implemented logic ----

    /** @notice reads crowdfund public storage variable 
        @return address of the set crowdfund contract */
    function getCrowdfund() external view returns (address);

    /** @notice reads lastTransfer public storage mapping 
        @param tokenId: ID of the token
        @return uint256 value for last trasfer of the given token ID */
    function getLastTransfer(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the escrow contract from CreatorsPRO */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IManagement} from "./IManagement.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IEscrow {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when it is attempted to withdraw more than deposited
    error Escrow__AmountGreaterThanDeposited();

    ///@dev error for when it has past more than 7 days after NFT mint/transfer
    error Escrow__NFTRefundNotPossible();

    ///@dev error for when an invalid collection address is given (refundNFT)
    error Escrow__InvalidCollectionAddress();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev struct for deposits
        @param amount: amount deposited
        @param endTimestamp: timestamp for withdraw
        @param coin: coin of deposit */
    struct Deposit {
        uint256 amount;
        uint256 endTimestamp;
        IManagement.Coin coin;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a deposit is made
        @param manager: manager address
        @param payer: payer address
        @param weiAmount: amount deposited in wei
        @param endTimestamp: end timestamp */
    event Deposited(
        address indexed manager,
        address indexed payer,
        uint256 weiAmount,
        uint256 endTimestamp
    );

    /** @dev event for when an withdraw is made
        @param startDepositId: start deposit ID comprised in the withdraw
        @param endDepositId: end deposit ID comprised in the withdraw */
    event Withdrawn(
        uint256 indexed startDepositId,
        uint256 indexed endDepositId
    );

    /** @dev event for when a manager withdraws contract funds of specific block number
        @param manager: manager address
        @param amount: amount withdrawn 
        @param coin: coin for withdrawal
        @param withdrawnAll: specifies if all balance was withdrawn (true) or not (false) */
    event WithdrawnByManager(
        address indexed manager,
        uint256 amount,
        IManagement.Coin coin,
        bool indexed withdrawnAll
    );

    /** @dev event for when an NFT is refunded
        @param caller: funtion caller
        @param collection: NFT collection address
        @param tokenId: ID of the token */
    event NFTRefunded(
        address indexed caller,
        address indexed collection,
        uint256 indexed tokenId
    );

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    /** @notice deposits given amount of the given coin from the given payer address
        @param _amount: amount to be deposited
        @param _payer: payer address from which the deposit will be made
        @param _coin: token of deposit */
    function deposit(
        uint256 _amount,
        address _payer,
        IManagement.Coin _coin
    ) external;

    /** @notice withdraws from the escrow */
    function withdraw() external;

    /** @notice withdraws all contract funds. Only managers can call thi function. */
    function withdrawByManager() external;

    /** @notice withdraws contract funds of specific block number. Only managers can call thi function.
        @param _depositId: deposit ID
        @param _amount: amount to be withdrawn */
    function withdrawByManager(uint256 _depositId, uint256 _amount) external;

    /** @notice refunds NFT from the given collection
        @param _collection: NFT collection address
        @param _tokenId: ID of the token to be refunded
        @param _depositId: deposit ID
        @param _amount: amount to be withdrawn */
    function refundNFT(
        address _collection,
        uint256 _tokenId,
        uint256 _depositId,
        uint256 _amount
    ) external;

    /** @notice reads nextDepositId public storage variable 
        @return uint256 value for the next deposit ID */
    function getNextDepositId() external view returns (uint256);

    /** @notice reads nextDepositIdToWithdraw public storage variable 
        @return uint256 value for the next deposit ID to be withdrawn by the creator */
    function getNextDepositIdToWithdraw() external view returns (uint256);

    /** @notice reads _deposits private storage variable 
        @param depositId: ID of the deposit
        @return Deposit struct with the deposit info */
    function depositOf(
        uint256 depositId
    ) external view returns (Deposit memory);

    /** @notice reads the current withdraw amount available 
        @return Deposit struct array with the avaliable deposits info */
    function getAllAvailableDeposits() external view returns (Deposit[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Interface for the management contract from CreatorsPRO */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

import {IERC20Burnable} from "./IERC20Burnable.sol";
import {ICRPReward} from "./ICRPReward.sol";

/// -----------------------------------------------------------------------
/// Interface
/// -----------------------------------------------------------------------

interface IManagement {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error Management__NotAllowed();

    ///@dev error for when collection name is invalid
    error Management__InvalidName();

    ///@dev error for when collection symbol is invalid
    error Management__InvalidSymbol();

    ///@dev error for when the input is an invalid address
    error Management__InvalidAddress();

    ///@dev error for when the resulting max supply is 0
    error Management__FundMaxSupplyIs0();

    ///@dev error for when a token contract address is set for ETH/MATIC
    error Management__CannotSetAddressForETH();

    ///@dev error for when creator is corrupted
    error Management__CreatorCorrupted();

    ///@dev error for when an invalid collection address is given
    error Management__InvalidCollection();

    ///@dev error for when not the collection creator address calls function
    error Management__NotCollectionCreator();

    ///@dev error for when given address is not allowed creator
    error Management__AddressNotCreator();

    /// -----------------------------------------------------------------------
    /// Type declarations (structs and enums)
    /// -----------------------------------------------------------------------

    /** @dev enum to specify the coin/token of transfer 
        @param ETH_COIN: ETH
        @param USD_TOKEN: a US dollar stablecoin        
        @param CREATORS_TOKEN: ERC20 token from CreatorsPRO
        @param REPUTATION_TOKEN: ERC20 token for reputation */
    enum Coin {
        ETH_COIN,
        USD_TOKEN,
        CREATORS_TOKEN,
        REPUTATION_TOKEN
    }

    /** @dev struct to be used as imput parameter that comprises with values for
    setting the crowdfunding contract   
        @param valuesLowQuota: array of values for the low class quota in ETH, USD token, and CreatorsPRO token
        @param valuesRegQuota: array of values for the regular class quota in ETH, USD token, and CreatorsPRO token 
        @param valuesHighQuota: array of values for the high class quota in ETH, USD token, and CreatorsPRO token 
        @param amountLowQuota: amount of low class quotas available 
        @param amountRegQuota: amount of low regular quotas available
        @param amountHighQuota: amount of low high quotas available 
        @param donationReceiver: address for the donation receiver 
        @param donationFee: fee value for the donation
        @param minSoldRate: minimum rate of sold quotas */
    struct CrowdFundParams {
        uint256[3] valuesLowQuota;
        uint256[3] valuesRegQuota;
        uint256[3] valuesHighQuota;
        uint256 amountLowQuota;
        uint256 amountRegQuota;
        uint256 amountHighQuota;
        address donationReceiver;
        uint256 donationFee;
        uint256 minSoldRate;
    }

    /** @dev struct used for store creators info
        @param escrow: escrow address for a creator
        @param isAllowed: defines if address is an allowed creator (true) or not (false) */
    struct Creator {
        address escrow;
        bool isAllowed;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new ERC721 art collection is instantiated
        @param collection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event ArtCollection(
        address indexed collection,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a new ERC721 crowdfund collection is instantiated
        @param fundCollection: new ERC721 crowdfund collection address
        @param artCollection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event Crowdfund(
        address indexed fundCollection,
        address indexed artCollection,
        address indexed creator,
        address caller
    );

    /** @dev event for when a new ERC721 collection from CreatorsPRO staff is instantiated
        @param collection: new ERC721 address
        @param creator: creator address of the ERC721 collection */
    event CreatorsCollection(
        address indexed collection,
        address indexed creator
    );

    /** @dev event for when a creator address is set
        @param creator: the creator address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event CreatorSet(
        address indexed creator,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new beacon admin address for ERC721 art collection contract is set
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminArt(address indexed beacon, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 crowdfund collection contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminFund(address indexed beacon, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 CreatorsPRO collection contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminCreators(
        address indexed beacon,
        address indexed manager
    );

    /** @dev event for when a new multisig wallet address is set
        @param multisig: new multisig wallet address
        @param manager: the manager address that has done the setting */
    event NewMultiSig(address indexed multisig, address indexed manager);

    /** @dev event for when a new royalty fee is set
        @param newFee: new royalty fee
        @param manager: the manager address that has done the setting */
    event NewFee(uint256 indexed newFee, address indexed manager);

    /** @dev event for when a creator address is set
        @param setManager: the manager address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event ManagerSet(
        address indexed setManager,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new token contract address is set
        @param manager: address of the manager that has set the hash object
        @param token: address of the token contract 
        @param coin: coin/token of the contract */
    event TokenContractSet(
        address indexed manager,
        address indexed token,
        Coin coin
    );

    /** @dev event for when a new ERC721 staking contract is instantiated
        @param staking: new ERC721 staking contract address
        @param creator: contract creator address 
        @param caller: caller address of the function */
    event CRPStaking(
        address indexed staking,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a creator's address is set to corrupted (true) or not (false) 
        @param manager: maanger's address
        @param creator: creator's address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    event CorruptedAddressSet(
        address indexed manager,
        address indexed creator,
        bool corrupted
    );

    /** @dev event for when a new beacon admin address for ERC721 staking contract is set 
        @param beacon: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminStaking(
        address indexed beacon,
        address indexed manager
    );

    /** @dev event for when a new proxy address for reward contract is set 
        @param proxy: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewProxyReward(address indexed proxy, address indexed manager);

    /** @dev event for when a CreatorsPRO collection is set
        @param collection: collection address
        @param set: true if collection is from CreatorsPRO, false otherwise */
    event CollectionSet(address indexed collection, bool set);

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- Implemented functions ---

    /** @dev smart contract's initializer/constructor.
        @param beaconAdminArt: address of the beacon admin for the creators ERC721 art smart contract 
        @param beaconAdminFund: address of the beacon admin for the creators ERC721 fund smart contract
        @param beaconAdminCreators: address of the beacon admin for the CreatorPRO ERC721 smart contract 
        @param erc20USD: address of a stablecoin contract (USDC/USDT/DAI)
        @param multiSig: address of the Multisig smart contract
        @param fee: royalty fee */
    function initialize(
        address beaconAdminArt,
        address beaconAdminFund,
        address beaconAdminCreators,
        address erc20USD,
        address multiSig,
        uint256 fee
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner */
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata 
        @param royalty: royalty payment to owner 
        @param owner: owner address of the collection */
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty,
        address owner
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param baseURI: base URI for the collection's metadata
        @param cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        CrowdFundParams memory cfParams
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param baseURI: base URI for the collection's metadata
        @param owner: owner address of the collection
        @param cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        address owner,
        CrowdFundParams memory cfParams
    ) external;

    /** @notice instantiates/deploys new CreatorPRO NFT art collection smart contract.
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection
        @param maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param price: mint price of a single NFT
        @param baseURI: base URI for the collection's metadata */
    function newCreatorsCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSDC,
        uint256 priceInCreatorsCoin,
        string memory baseURI
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward */
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param stakingToken: crowdfunding contract NFTArt address
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: stipulated time reward
        @param owner: owner address of the collection */
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime,
        address owner
    ) external;

    // --- Setter functions ---

    /** @notice sets creator permission.
        @param creator: creator address
        @param allowed: boolean that specifies if creator address has permission (true) or not (false) */
    function setCreator(address creator, bool allowed) external;

    /** @notice sets manager permission.
        @param manager: manager address
        @param allowed: boolean that specifies if manager address has permission (true) or not (false) */
    function setManager(address manager, bool allowed) external;

    /** @notice sets new beacon admin address for the creators ERC721 art smart contract.
        @param beacon: new address */
    function setBeaconAdminArt(address beacon) external;

    /** @notice sets new beacon admin address for the creators ERC721 fund smart contract.
        @param beacon: new address */
    function setBeaconAdminFund(address beacon) external;

    /** @notice sets new beacon admin address for the CreatorPRO ERC721 smart contract.
        @param beacon: new address */
    function setBeaconAdminCreators(address beacon) external;

    /** @notice sets new address for the Multisig smart contract.
        @param multisig: new address */
    function setMultiSig(address multisig) external;

    /** @notice sets new fee for NFT minting.
        @param fee: new fee */
    function setFee(uint256 fee) external;

    /** @notice sets new contract address for the given token 
        @param coin: coin/token for the given contract address
        @param token: new address of the token contract */
    function setTokenContract(Coin coin, address token) external;

    /** @notice sets given creator address to corrupted (true) or not (false)
        @param creator: creator address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    function setCorrupted(address creator, bool corrupted) external;

    /** @notice sets new beacon admin address for the ERC721 staking smart contract.
        @param beacon: new address */
    function setBeaconAdminStaking(address beacon) external;

    /** @notice sets new proxy address for the reward smart contract.
        @param proxy: new address */
    function setProxyReward(address proxy) external;

    /** @notice sets new collection address
        @param collection: collection address
        @param set: true (collection from CreatorsPRO) or false */
    function setCollections(address collection, bool set) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    // --- Getter functions ---

    // --- From storage variables ---

    /** @notice reads beaconAdminArt storage variable
        @return address of the beacon admin for the art collection (ERC721) contract */
    function getBeaconAdminArt() external view returns (address);

    /** @notice reads beaconAdminFund storage variable
        @return address of the beacon admin for the crowdfund (ERC721) contract */
    function getBeaconAdminFund() external view returns (address);

    /** @notice reads beaconAdminCreators storage variable
        @return address of the beacon admin for the CreatorsPRO collection (ERC721) contract */
    function getBeaconAdminCreators() external view returns (address);

    /** @notice reads beaconAdminStaking storage variable
        @return address of the beacon admin for staking contract */
    function getBeaconAdminStaking() external view returns (address);

    /** @notice reads proxyReward storage variable
        @return address of the beacon admin for staking contract */
    function getProxyReward() external view returns (ICRPReward);

    /** @notice reads multiSig storage variable 
        @return address of the multisig wallet */
    function getMultiSig() external view returns (address);

    /** @notice reads fee storage variable 
        @return the royalty fee */
    function getFee() external view returns (uint256);

    /** @notice reads managers storage mapping
        @param caller: address to check if is manager
        @return boolean if the given address is a manager */
    function getManagers(address caller) external view returns (bool);

    /** @notice reads tokenContract storage mapping
        @param coin: coin/token for the contract address
        @return IERC20 instance for the given coin/token */
    function getTokenContract(Coin coin) external view returns (IERC20Burnable);

    /** @notice reads isCorrupted storage mapping 
        @param creator: creator address
        @return bool that sepcifies if creator is corrupted (true) or not (false) */
    function getIsCorrupted(address creator) external view returns (bool);

    /** @notice reads collections storage mapping 
        @param collection: collection address
        @return bool that sepcifies if collection is from CreatorsPRO (true) or not (false)  */
    function getCollections(address collection) external view returns (bool);

    /** @notice reads stakingCollections storage mapping 
        @param collection: collection address
        @return bool that sepcifies if staking collection is from CreatorsPRO (true) or not (false)  */
    function getStakingCollections(
        address collection
    ) external view returns (bool);

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads creators storage mapping
        @param caller: address to check if is allowed creator
        @return Creator struct with creator info */
    function getCreator(address caller) external view returns (Creator memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Management contract for CreatorsPRO project */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces
import {IManagement, IERC20Burnable} from "./interfaces/IManagement.sol";
import {ICRPReward} from "./interfaces/ICRPReward.sol";
import {IERC721Art} from "./interfaces/IERC721Art.sol";
import {IERC721ArtHandle} from "./interfaces/IERC721ArtHandle.sol";
import {Escrow} from "./Escrow.sol";

///@dev beacon proxy smart contract
import {BeaconProxy} from "./@openzeppelin/proxy/beacon/BeaconProxy.sol";

///@dev UUPS smart contract
import {UUPSUpgradeable, ERC1967Upgrade} from "./@openzeppelin/proxy/utils/UUPSUpgradeable.sol";

///@dev security settings.
import {Initializable} from "./@openzeppelin/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "./@openzeppelin/upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "./@openzeppelin/upgradeable/security/PausableUpgradeable.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract Management is
    IManagement,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    // Beacon admins addresses
    address private s_beaconAdminArt;
    address private s_beaconAdminFund;
    address private s_beaconAdminCreators;
    address private s_beaconAdminStaking;
    ICRPReward private s_proxyReward;

    // Multisig address
    address private s_multiSig;

    // Creators royalty fee
    uint256 private s_fee; // over 10000

    ///@dev mapping from user address to Creator struct. See {struct IManagement.Creator}
    mapping(address user => Creator info) private s_creators;

    ///@dev mapping that specifies if address is a manager (true) or not (false)
    mapping(address account => bool isManager) private s_managers;

    ///@dev mapping for the token contract
    mapping(Coin coin => IERC20Burnable contractInstance)
        private s_tokenContract;

    ///@dev mapping that checks if creator/artist is corrupted
    mapping(address creator => bool isCorrupted) private s_isCorrupted;

    ///@dev mapping of collection addresses generated by CreatorsPro
    mapping(address collection => bool isFromCreatorsPRO) private s_collections;

    ///@dev mapping of staking collection addresses generated by CreatorsPro
    mapping(address stakingContractAddress => bool isFromCreatorsPRO)
        private s_stakingCollections;

    //constants
    uint256 private constant MAX_UINT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// -----------------------------------------------------------------------
    /// Permissions and Restrictions (private functions as modifiers)
    /// -----------------------------------------------------------------------

    /** @dev only allowed creator addresses can call function.
        @param creator: address to be checked */
    function __onlyCreators(address creator) private view {
        if (!s_creators[creator].isAllowed) {
            revert Management__NotAllowed();
        }
    }

    ///@dev only allowed CreatorsPRO manager addresses can call function.
    function __onlyManagers() private view {
        if (!s_managers[msg.sender]) {
            revert Management__NotAllowed();
        }
    }

    ///@dev only allowed CreatorsPRO manager addresses can call function.
    function __onlyAuthorized() private view {
        if (!s_managers[msg.sender] && !s_creators[msg.sender].isAllowed) {
            revert Management__NotAllowed();
        }
    }

    /** @dev validates name and symbol parameters before creating NFT collection smart contract. 
        @param name: name of the NFT collection
        @param symbol: symbol of the NFT collection */
    function __validateCollectionParams(
        string memory name,
        string memory symbol
    ) private pure {
        if (!(bytes(name).length > 0)) {
            revert Management__InvalidName();
        }
        if (!(bytes(symbol).length > 0)) {
            revert Management__InvalidSymbol();
        }
    }

    /** @dev checks if given address is not the zero address.
        @param add: given address */
    function __validateAddress(address add) private pure {
        if (add == address(0)) {
            revert Management__InvalidAddress();
        }
    }

    /** @dev checks if caller is corrupted. 
        @param creator: address to be checked */
    function __notCorrupted(address creator) private view {
        if (s_isCorrupted[creator]) {
            revert Management__CreatorCorrupted();
        }
    }

    ///@dev private function for whenNotPaused modifier
    function __whenNotPaused() private view whenNotPaused {}

    ///@dev private function for nonReentrant modifier
    function __nonReentrant() private nonReentrant {}

    /// -----------------------------------------------------------------------
    /// Initializer
    /// -----------------------------------------------------------------------

    /// @dev initializer modifier added.
    /// @inheritdoc IManagement
    function initialize(
        address beaconAdminArt,
        address beaconAdminFund,
        address beaconAdminCreators,
        address erc20USD,
        address multiSig,
        uint256 fee
    ) external override(IManagement) initializer {
        __ReentrancyGuard_init();
        __Pausable_init();

        s_beaconAdminArt = beaconAdminArt;
        s_beaconAdminFund = beaconAdminFund;
        s_beaconAdminCreators = beaconAdminCreators;
        s_tokenContract[Coin.USD_TOKEN] = IERC20Burnable(erc20USD);
        s_multiSig = multiSig;
        s_fee = fee;
        s_managers[tx.origin] = true;
        // managers[address(this)] = true;
    }

    /// -----------------------------------------------------------------------
    /// New collection functions
    /// -----------------------------------------------------------------------

    /** @dev function to be used by the creator. Same rules for the newArtCollection public function (below) */
    /// @inheritdoc IManagement
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty
    ) external override(IManagement) {
        newArtCollection(
            name,
            symbol,
            maxSupply,
            price,
            priceInUSD,
            priceInCreatorsCoin,
            baseURI,
            royalty,
            msg.sender
        );
    }

    /** @dev only allowed creators. name and symbol must not be empty ("").
    s_beaconAdminArt must not be zero address. */
    /// @inheritdoc IManagement
    function newArtCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSD,
        uint256 priceInCreatorsCoin,
        string memory baseURI,
        uint256 royalty,
        address owner
    ) public override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyAuthorized();
        __validateCollectionParams(name, symbol);
        __validateAddress(s_beaconAdminArt);
        __onlyCreators(owner);
        __notCorrupted(owner);

        if (royalty > 600) {
            royalty = 600;
        }

        bytes memory ERC721initialize = abi.encodeWithSignature(
            "initialize(string,string,address,uint256,uint256,uint256,uint256,string,uint256)",
            name,
            symbol,
            owner,
            maxSupply,
            price,
            priceInUSD,
            priceInCreatorsCoin,
            baseURI,
            royalty
        );

        BeaconProxy newCollectionProxy = new BeaconProxy(
            s_beaconAdminArt,
            ERC721initialize
        );

        s_collections[address(newCollectionProxy)] = true;

        emit ArtCollection(address(newCollectionProxy), owner, msg.sender);
    }

    /** @dev function to be used by the creator. Same rules for the newCrowdfund public function (below) */
    /// @inheritdoc IManagement
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        CrowdFundParams memory cfParams
    ) external override(IManagement) {
        newCrowdfund(name, symbol, baseURI, royalty, msg.sender, cfParams);
    }

    /** @dev only allowed creators. name and symbol must not be empty.
    s_beaconAdminFund must not be zero address. */
    /// @inheritdoc IManagement
    function newCrowdfund(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 royalty,
        address owner,
        CrowdFundParams memory cfParams
    ) public override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyAuthorized();
        __validateCollectionParams(name, symbol);
        __validateAddress(s_beaconAdminFund);
        __onlyCreators(owner);
        __notCorrupted(owner);

        if (
            cfParams.amountLowQuota +
                cfParams.amountRegQuota +
                cfParams.amountHighQuota ==
            0
        ) {
            revert Management__FundMaxSupplyIs0();
        }

        if (royalty > 600) {
            royalty = 600;
        }

        bytes memory ERC721ArtInitialize = abi.encodeWithSignature(
            "initialize(string,string,address,uint256,uint256,uint256,uint256,string,uint256)",
            name,
            symbol,
            owner,
            cfParams.amountLowQuota +
                cfParams.amountRegQuota +
                cfParams.amountHighQuota,
            MAX_UINT,
            MAX_UINT,
            MAX_UINT,
            baseURI,
            royalty
        );

        BeaconProxy newArtCollectionProxy = new BeaconProxy(
            s_beaconAdminArt,
            ERC721ArtInitialize
        );

        bytes memory ERC721FundInitialize = abi.encodeWithSignature(
            "initialize(uint256[3],uint256[3],uint256[3],uint256,uint256,uint256,address,uint256,uint256,address)",
            cfParams.valuesLowQuota,
            cfParams.valuesRegQuota,
            cfParams.valuesHighQuota,
            cfParams.amountLowQuota,
            cfParams.amountRegQuota,
            cfParams.amountHighQuota,
            cfParams.donationReceiver,
            cfParams.donationFee,
            cfParams.minSoldRate,
            address(newArtCollectionProxy)
        );

        BeaconProxy newFundCollectionProxy = new BeaconProxy(
            s_beaconAdminFund,
            ERC721FundInitialize
        );

        IERC721Art(address(newArtCollectionProxy)).setCrowdfund(
            address(newFundCollectionProxy)
        );

        s_collections[address(newArtCollectionProxy)] = true;

        emit Crowdfund(
            address(newFundCollectionProxy),
            address(newArtCollectionProxy),
            owner,
            msg.sender
        );
    }

    /** @dev only allowed managers. name and symbol must not be empty.
    s_beaconAdminCreators must not be zero address. */
    /// @inheritdoc IManagement
    function newCreatorsCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price,
        uint256 priceInUSDC,
        uint256 priceInCreatorsCoin,
        string memory baseURI
    ) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateCollectionParams(name, symbol);
        __validateAddress(s_beaconAdminCreators);

        bytes memory ERC721initialize = abi.encodeWithSignature(
            "initialize(string,string,address,uint256,uint256,uint256,uint256,string,uint256)",
            name,
            symbol,
            msg.sender,
            maxSupply,
            price,
            priceInUSDC,
            priceInCreatorsCoin,
            baseURI,
            0
        );

        BeaconProxy newCollectionProxy = new BeaconProxy(
            s_beaconAdminCreators,
            ERC721initialize
        );

        s_collections[address(newCollectionProxy)] = true;

        emit CreatorsCollection(address(newCollectionProxy), msg.sender);
    }

    /** @dev function to be used by the creator. Same rules for the newCRPStaking public function (below) */
    /// @inheritdoc IManagement
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime
    ) external override(IManagement) {
        newCRPStaking(stakingToken, timeUnit, rewardsPerUnitTime, msg.sender);
    }

    /** @dev only allowed creators. s_beaconAdminStaking must not be zero address. */
    /// @inheritdoc IManagement
    function newCRPStaking(
        address stakingToken,
        uint256 timeUnit,
        uint256[3] calldata rewardsPerUnitTime,
        address owner
    ) public override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyAuthorized();
        __validateAddress(s_beaconAdminStaking);
        __onlyCreators(owner);
        __notCorrupted(owner);

        if (!s_collections[stakingToken]) {
            revert Management__InvalidCollection();
        }
        if (IERC721ArtHandle(stakingToken).owner() != owner) {
            revert Management__NotCollectionCreator();
        }

        bytes memory CRPStakingInitialize = abi.encodeWithSignature(
            "initialize(address,uint256,uint256[3])",
            stakingToken,
            timeUnit,
            rewardsPerUnitTime
        );

        BeaconProxy newStakingProxy = new BeaconProxy(
            s_beaconAdminStaking,
            CRPStakingInitialize
        );

        s_collections[address(newStakingProxy)] = true;
        s_stakingCollections[address(newStakingProxy)] = true;

        emit CRPStaking(address(newStakingProxy), owner, msg.sender);
    }

    /// -----------------------------------------------------------------------
    /// Setter functions
    /// -----------------------------------------------------------------------

    /** @dev only managers allowed to call this function. creator must
    not be zero address. */
    /// @inheritdoc IManagement
    function setCreator(
        address creator,
        bool allowed
    ) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(creator);

        if (allowed && s_creators[creator].escrow == address(0)) {
            Escrow escrow = new Escrow(creator);
            s_creators[creator].escrow = address(escrow);
        }

        s_creators[creator].isAllowed = allowed;

        emit CreatorSet(creator, allowed, msg.sender);
    }

    /** @dev only managers allowed to call this function. manager must
    not be zero address. */
    /// @inheritdoc IManagement
    function setManager(
        address manager,
        bool allowed
    ) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(manager);

        s_managers[manager] = allowed;

        emit ManagerSet(manager, allowed, msg.sender);
    }

    /** @dev only managers allowed to call this function. beacon must
    not be zero address. */
    /// @inheritdoc IManagement
    function setBeaconAdminArt(address beacon) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(beacon);

        s_beaconAdminArt = beacon;

        emit NewBeaconAdminArt(beacon, msg.sender);
    }

    /** @dev only managers allowed to call this function. beacon must
    not be zero address. */
    /// @inheritdoc IManagement
    function setBeaconAdminFund(address beacon) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(beacon);

        s_beaconAdminFund = beacon;

        emit NewBeaconAdminFund(beacon, msg.sender);
    }

    /** @dev only managers allowed to call this function. beacon must
    not be zero address. */
    /// @inheritdoc IManagement
    function setBeaconAdminCreators(
        address beacon
    ) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(beacon);

        s_beaconAdminCreators = beacon;

        emit NewBeaconAdminCreators(beacon, msg.sender);
    }

    /** @dev only managers allowed to call this function. multisig must
    not be zero address. */
    /// @inheritdoc IManagement
    function setMultiSig(address multisig) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(multisig);

        s_multiSig = multisig;

        emit NewMultiSig(multisig, msg.sender);
    }

    /** @dev only managers allowed to call this function. */
    /// @inheritdoc IManagement
    function setFee(uint256 fee) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();

        s_fee = fee;

        emit NewFee(fee, msg.sender);
    }

    /** @dev only managers allowed to call this function */
    /// @inheritdoc IManagement
    function setTokenContract(
        Coin coin,
        address token
    ) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(token);
        if (coin == Coin.ETH_COIN) {
            revert Management__CannotSetAddressForETH();
        }

        /**@dev Mumbai address = 0xA02f6adc7926efeBBd59Fd43A84f4E0c0c91e832
            Polygon mainnet address = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F
            Goerli address = 0x509Ee0d083DdF8AC028f2a56731412edD63223B9
            Ethereum mainnet address = 0xdAC17F958D2ee523a2206206994597C13D831ec7 */
        s_tokenContract[coin] = IERC20Burnable(token);

        emit TokenContractSet(msg.sender, token, coin);
    }

    /** @dev only managers allowed to call this function */
    /// @inheritdoc IManagement
    function setCorrupted(address creator, bool corrupted) external {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(creator);
        if (!s_creators[creator].isAllowed) {
            revert Management__AddressNotCreator();
        }

        s_isCorrupted[creator] = corrupted;

        emit CorruptedAddressSet(msg.sender, creator, corrupted);
    }

    /** @dev only managers allowed to call this function. beacon must
    not be zero address. */
    /// @inheritdoc IManagement
    function setBeaconAdminStaking(
        address beacon
    ) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(beacon);

        s_beaconAdminStaking = beacon;

        emit NewBeaconAdminStaking(beacon, msg.sender);
    }

    /** @dev only managers allowed to call this function. proxy must
    not be zero address. */
    /// @inheritdoc IManagement
    function setProxyReward(address proxy) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        __validateAddress(proxy);

        s_proxyReward = ICRPReward(proxy);

        emit NewProxyReward(proxy, msg.sender);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only management contract
    is allowed to call this function. */
    /// @inheritdoc IManagement
    function setCollections(
        address collection,
        bool set
    ) external override(IManagement) {
        __nonReentrant();
        __whenNotPaused();
        __onlyManagers();
        if (
            collection.code.length == 0 ||
            !s_creators[IERC721ArtHandle(collection).owner()].isAllowed
        ) {
            revert Management__InvalidAddress();
        }

        s_collections[collection] = set;

        emit CollectionSet(collection, set);
    }

    // --- Pause and Unpause functions ---

    /** @dev only managers allowed to call this function. Uses _pause internal function from PausableUpgradeable. */
    /// @inheritdoc IManagement
    function pause() external override(IManagement) {
        __nonReentrant();
        __onlyManagers();

        _pause();
    }

    /** @dev only managers allowed to call this function. Uses _pause internal function from PausableUpgradeable. */
    /// @inheritdoc IManagement
    function unpause() external override(IManagement) {
        __nonReentrant();
        __onlyManagers();

        _unpause();
    }

    /// -----------------------------------------------------------------------
    /// Getter functions
    /// -----------------------------------------------------------------------

    /// @inheritdoc IManagement
    function getBeaconAdminArt()
        external
        view
        override(IManagement)
        returns (address)
    {
        return s_beaconAdminArt;
    }

    /// @inheritdoc IManagement
    function getBeaconAdminFund()
        external
        view
        override(IManagement)
        returns (address)
    {
        return s_beaconAdminFund;
    }

    /// @inheritdoc IManagement
    function getBeaconAdminCreators()
        external
        view
        override(IManagement)
        returns (address)
    {
        return s_beaconAdminCreators;
    }

    /// @inheritdoc IManagement
    function getBeaconAdminStaking()
        external
        view
        override(IManagement)
        returns (address)
    {
        return s_beaconAdminStaking;
    }

    /// @inheritdoc IManagement
    function getProxyReward()
        external
        view
        override(IManagement)
        returns (ICRPReward)
    {
        return s_proxyReward;
    }

    /// @inheritdoc IManagement
    function getMultiSig()
        external
        view
        override(IManagement)
        returns (address)
    {
        return s_multiSig;
    }

    /// @inheritdoc IManagement
    function getFee() external view override(IManagement) returns (uint256) {
        return s_fee;
    }

    /// @inheritdoc IManagement
    function getManagers(
        address caller
    ) external view override(IManagement) returns (bool) {
        return s_managers[caller];
    }

    /// @inheritdoc IManagement
    function getTokenContract(
        Coin coin
    ) external view override(IManagement) returns (IERC20Burnable) {
        return s_tokenContract[coin];
    }

    /// @inheritdoc IManagement
    function getIsCorrupted(
        address creator
    ) external view override(IManagement) returns (bool) {
        return s_isCorrupted[creator];
    }

    /// @inheritdoc IManagement
    function getCollections(
        address collection
    ) external view override(IManagement) returns (bool) {
        return s_collections[collection];
    }

    /// @inheritdoc IManagement
    function getStakingCollections(
        address collection
    ) external view override(IManagement) returns (bool) {
        return s_stakingCollections[collection];
    }

    /// @inheritdoc IManagement
    function getImplementation()
        external
        view
        override(IManagement)
        returns (address)
    {
        return ERC1967Upgrade._getImplementation();
    }

    /// @inheritdoc IManagement
    function getCreator(
        address creator
    ) external view override(IManagement) returns (Creator memory) {
        return s_creators[creator];
    }

    /// -----------------------------------------------------------------------
    /// Overriden functions
    /// -----------------------------------------------------------------------

    /** @dev only managers are allowed to call this function. */
    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(
        address
    ) internal view override(UUPSUpgradeable) {
        __onlyManagers();
    }

    /// -----------------------------------------------------------------------
    /// Storage space for upgrades
    /// -----------------------------------------------------------------------

    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/** @author Omnes Blockchain team (@EWCunha and @Afonsodalvi)
    @title Security settings for non-upgradeable smart contracts */

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

///@dev inhouse implemented smart contracts and interfaces.
import {IManagement} from "./interfaces/IManagement.sol";

///@dev security settings.
import {Ownable} from "./@openzeppelin/access/Ownable.sol";
import {Pausable} from "./@openzeppelin/utils/Pausable.sol";
import {ReentrancyGuard} from "./@openzeppelin/security/ReentrancyGuard.sol";

/// -----------------------------------------------------------------------
/// Errors
/// -----------------------------------------------------------------------

///@dev error for when the crowdfund has past due data
error Security__NotAllowed();

///@dev error for when the collection/creator has been corrupted
error Security__CollectionOrCreatorCorrupted();

///@dev error for when ETH/MATIC transfer fails
error Security__TransferFailed();

///@dev error for when ERC20 transfer fails
error Security__ERC20TransferFailed();

///@dev error for when an invalid coin is used
error Security__InvalidCoin();

///@dev error for when given coin is ETH or REPUTATION_TOKEN
error Security__CreatorNotAllowed();

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

contract Security is Ownable, ReentrancyGuard, Pausable {
    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    ///@dev Management contract
    IManagement internal immutable i_management;

    /// -----------------------------------------------------------------------
    /// Permissions and Restrictions (private functions as modifiers)
    /// -----------------------------------------------------------------------

    ///@dev internal function for whenNotPaused modifier
    function _whenNotPaused() internal view whenNotPaused {}

    ///@dev internal function for nonReentrant modifier
    function _nonReentrant() internal nonReentrant {}

    ///@dev internal function for onlyOwner modifier
    function _onlyOwner() internal view onlyOwner {}

    ///@dev only allowed CreatorsPRO manager addresses can call function.
    function _onlyManagers() internal view {
        if (!i_management.getManagers(msg.sender)) {
            revert Security__NotAllowed();
        }
    }

    ///@dev checks if caller is authorized
    function _onlyAuthorized() internal view virtual {
        if (!i_management.getIsCorrupted(owner())) {
            if (
                !(i_management.getManagers(msg.sender) ||
                    msg.sender == address(i_management) ||
                    msg.sender == owner())
            ) {
                revert Security__NotAllowed();
            }
        } else {
            if (
                !(i_management.getManagers(msg.sender) ||
                    msg.sender == address(i_management))
            ) {
                revert Security__NotAllowed();
            }
        }
    }

    ///@dev checks if collection/creator is corrupted
    function _notCorrupted() internal view virtual {
        if (i_management.getIsCorrupted(owner())) {
            revert Security__CollectionOrCreatorCorrupted();
        }
    }

    ///@dev checks if used coin is valid
    function _onlyValidCoin(IManagement.Coin coin) internal pure {
        if (
            coin == IManagement.Coin.ETH_COIN ||
            coin == IManagement.Coin.REPUTATION_TOKEN
        ) {
            revert Security__InvalidCoin();
        }
    }

    /// @dev checks if creator is still allowed
    function _isAllowedCreator() internal view virtual {
        if (!i_management.getCreator(owner()).isAllowed) {
            revert Security__CreatorNotAllowed();
        }
    }

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    constructor(address management) {
        i_management = IManagement(management);
    }

    // --- Pause and Unpause functions ---

    /** @notice pauses the contract so that functions cannot be executed.
        Uses _pause internal function from PausableUpgradeable. */
    function pause() public virtual {
        _nonReentrant();

        _pause();
    }

    /** @notice unpauses the contract so that functions can be executed        
        Uses _pause internal function from PausableUpgradeable. */
    function unpause() public virtual {
        _nonReentrant();

        _unpause();
    }

    // --- Implemented functions ---

    /** @notice performs ETH/MATIC transfer using the call low-level function. It reverts if
        transfer fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param to: transfer receiver address
        @param amount: amount to transfer */
    function _transferTo(address to, uint256 amount) internal virtual {
        (bool success, ) = payable(to).call{value: amount}("");

        if (!success) {
            revert Security__TransferFailed();
        }
    }

    /** @notice performs ETH/MATIC transfer using the call low-level function. It reverts if
        transfer fails. 
        @dev >>IMPORTANT<< [SECURITY] this function does NOT use any modifier!
        @dev >>IMPORTANT<< this function does NOT use nonReentrant modifier or the _nonReentrant internal
        function. Be sure to use one of those in the function that calls this function.
        @param coin: ERC20 coin to transfer
        @param from: transfer sender address
        @param to: transfer receiver address
        @param amount: amount to transfer */
    function _transferERC20To(
        IManagement.Coin coin,
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (coin == IManagement.Coin.ETH_COIN) {
            revert Security__InvalidCoin();
        }

        bool success;
        if (from == address(this)) {
            success = i_management.getTokenContract(coin).transfer(to, amount);
        } else {
            success = i_management.getTokenContract(coin).transferFrom(
                from,
                to,
                amount
            );
        }

        if (!success) {
            revert Security__ERC20TransferFailed();
        }
    }

    /** @notice reads management public storage variable 
        @return IManagement instance of Management interface */
    function getManagement() external view returns (IManagement) {
        return i_management;
    }
}