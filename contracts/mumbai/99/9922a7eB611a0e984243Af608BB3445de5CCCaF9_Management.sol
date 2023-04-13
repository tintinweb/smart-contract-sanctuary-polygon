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
pragma solidity ^0.8.9;

import "./IManagement.sol";
import "../@openzeppelin/token/IERC20.sol";

/** @author Omnes Blockchain team (@EWCunha, @Afonsodalvi, and @G-Deps)
    @title Interface for the ERC721 contract for artistic workpieces from allowed 
    artists/content creators */
interface IERC721Art {
    /// -----------------------------------------------------------------------
    /// Structs and Enums
    /// -----------------------------------------------------------------------

    ///@dev enum to specify the coin/token of transfer
    enum Coin {
        ETH_COIN,
        USDT_TOKEN,
        CREATORS_TOKEN
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new mint price is set.
        @param newPrice: new mint price 
        @param coin: token/coin of transfer */
    event PriceSet(uint256 indexed newPrice, Coin indexed coin);

    /** @dev event for when owner sets new price for his/her token.
        @param tokenId: ID of ERC721 token
        @param price: new token price
        @param coin: token/coin of transfer */
    event TokenPriceSet(
        uint256 indexed tokenId,
        uint256 price,
        Coin indexed coin
    );

    /** @dev event for when royalties transfers are done (mint).
        @param tokenId: ID of ERC721 token
        @param creatorsProRoyalty: royalty to CreatorsPRO
        @param creatorRoyalty: royalty to collection creator */
    event RoyaltiesTransferred(
        uint256 indexed tokenId,
        uint256 creatorsProRoyalty,
        uint256 creatorRoyalty
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

    /** @dev event for when the collection/creator corruption is set
        @param manager: manager address that has set corruption
        @param _corrupted: if it is corrupted (true) or not (false) */
    event CorruptedSet(address indexed manager, bool _corrupted);

    /** @dev event for when a new crowdfund address is set
        @param _crowdfund: address from crowdfund */
    event CrowdfundSet(address indexed _crowdfund);

    /// -----------------------------------------------------------------------
    /// Custom errors
    /// -----------------------------------------------------------------------

    ///@dev error for when the collection max supply is reached (when maxSupply > 0)
    error ERC721ArtMaxSupplyReached();

    ///@dev error for when the value sent or the allowance is not enough to mint/buy token
    error ERC721ArtNotEnoughValueOrAllowance();

    ///@dev error for when caller is neighter manager nor collection creator
    error ERC721ArtNotAllowed();

    ///@dev error for when caller is not token owner
    error ERC721ArtNotTokenOwner();

    ///@dev error for when a transfer is made before the 30 days deadline
    error ERC721ArtTrasnferDeadlineOngoing();

    ///@dev error for when the collection/creator has been corrupted
    error ERC721ArtCollectionOrCreatorCorrupted();

    ///@dev error for when caller is not manager
    error ERC721ArtNotManager();

    ///@dev error for when collection is for a crowdfund
    error ERC721ArtCollectionForFund();

    ///@dev error for when an invalid crowdfund address is set
    error ERC721ArtInvalidCrowdFund();

    ///@dev error for when the caller is not the crowdfund contract
    error ERC721ArtCallerNotCrowdfund();

    ///@dev error for when a crowfund address is already set
    error ERC721ArtCrodFundIsSet();

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- From storage variables ---

    /** @notice reads management public storage variable
        @return IManagement interface instance for the Management contract */
    function management() external view returns (IManagement);

    /** @notice reads maxSupply public storage variable
        @return uint256 value of maximum supply */
    function maxSupply() external view returns (uint256);

    /** @notice reads baseURI public storage variable 
        @return string of the base URI */
    function baseURI() external view returns (string memory);

    /** @notice reads price public storage mapping
        @param _coin: coin/token for price
        @return uint256 value for price */
    function price(Coin _coin) external view returns (uint256);

    /** @notice reads lastTransfer public storage mapping 
        @param _tokenId: ID of the token
        @return uint256 value for last trasfer of the given token ID */
    function lastTransfer(uint256 _tokenId) external view returns (uint256);

    /** @notice reads tokenPrice public storage mapping 
        @param _tokenId: ID of the token
        @param _coin: coin/token for specific token price 
        @return uint256 value for price of specific token */
    function tokenPrice(
        uint256 _tokenId,
        Coin _coin
    ) external view returns (uint256);

    /** @notice reads tokenContract public storage mapping 
        @param _coin: coin/token for specific token contract
        @return IERC20 interface instance for the given coin */
    function tokenContract(Coin _coin) external view returns (IERC20);

    /** @notice reads corrupted public storage variable 
        @return boolean if creator/collection is corrupted (true) or not (false) */
    function corrupted() external view returns (bool);

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _owner: collection owner/creator
        @param _maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param _price: mint price of a single NFT
        @param _priceInUSD: mint price of a single NFT
        @param _priceInCreatorsCoin: mint price of a single NFT
        @param baseURI_: base URI for the collection's metadata 
        @param _royalty: royalty payment to owner 
            (final value = _royalty / 10000 (ERC2981Upgradeable._feeDenominator())) */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSD,
        uint256 _priceInCreatorsCoin,
        string memory baseURI_,
        uint256 _royalty
    ) external;

    /** @notice mints given the NFT of given tokenId, using the given coin for transfer. Payable function.
        @param _tokenId: tokenId to be minted 
        @param _coin: token/coin of transfer */
    function mint(uint256 _tokenId, Coin _coin) external payable;

    /** @notice mints NFT of the given tokenId to the given address
        @param _to: address to which the ticket is going to be minted
        @param _tokenId: tokenId (batch) of the ticket to be minted */
    function mintToAddress(address _to, uint256 _tokenId) external;

    /** @notice mints token for crowdfunding        
        @param _tokenIds: array of token IDs to mint
        @param _to: address from tokens owner */
    function mintForCrowdfund(uint256[] memory _tokenIds, address _to) external;

    /** @notice burns NFT of the given tokenId.
        @param _tokenId: token ID to be burned */
    function burn(uint256 _tokenId) external;

    /** @notice safeTransferFrom function especifically for CreatorPRO. It enforces (onchain) the transfer of the 
        correct token price. Payable function.
        @param coin: which coin to use (0 => ETH, 1 => USD, 2 => CreatorsCoin)
        The other parameters are the same from safeTransferFrom function. */
    function creatorsProSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        Coin coin
    ) external payable;

    /** @notice sets NFT mint price.
        @param _price: new NFT mint price 
        @param _coin: coin/token to be set */
    function setPrice(uint256 _price, Coin _coin) external;

    /** @notice sets the price of the ginve token ID.
        @param _tokenId: ID of token
        @param _price: new price to be set 
        @param _coin: coin/token to be set */
    function setTokenPrice(
        uint256 _tokenId,
        uint256 _price,
        Coin _coin
    ) external;

    /** @notice sets new base URI for the collection.
        @param _uri: new base URI to be set */
    function setBaseURI(string memory _uri) external;

    /** @notice sets new royaly value for NFT transfer
        @param _royalty: new value for royalty */
    function setRoyalty(uint256 _royalty) external;

    /** @notice sets if collection/creator is corrupted
        @param _corrupted: boolean that specifices if collection/creator is corrupted (true)
        or not (false) */
    function setCorrupted(bool _corrupted) external;

    /** @notice sets the crowdfund address 
        @param _crowdfund: crowdfund contract address */
    function setCrowdfund(address _crowdfund) external;

    /** @notice gets the royalty info (address and value) from ERC2981
        @return royalty receiver address and value */
    function getRoyalty() external view returns (address, uint);

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/** @author Omnes Blockchain team (@EWCunha, @Afonsodalvi, and @G-Deps)
    @title Interface for the management contract from CreatorsPRO */
interface IManagement {
    /// -----------------------------------------------------------------------
    /// Structs and Enums
    /// -----------------------------------------------------------------------

    ///@dev struct for the hash object with hashpower and characterist ID fields
    struct HashObject {
        uint256 hashpower;
        uint256 characteristId;
    }

    /** @dev struct to be used as imput parameter that comprises with values for
    setting the crowdfunding contract */
    struct CrowdFundParams {
        uint256 _valueLowQuota;
        uint256 _valueRegQuota;
        uint256 _valueHighQuota;
        uint256 _amountLowQuota;
        uint256 _amountRegQuota;
        uint256 _amountHighQuota;
        address _donationReceiver;
        uint256 _donationFee;
        uint256 _minSoldRate;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new ERC721 art collection is instantiated
        @param collection: new ERC721 art collection address
        @param creator: collection creator address */
    event ArtCollection(address indexed collection, address indexed creator);

    /** @dev event for when a new ERC721 crowdfund collection is instantiated
        @param fundCollection: new ERC721 crowdfund collection address
        @param artCollection: new ERC721 art collection address
        @param creator: collection creator address */
    event Crowdfund(
        address indexed fundCollection,
        address indexed artCollection,
        address indexed creator
    );

    /** @dev event for when a new ERC721 collection from CreatorsPRO staff is instantiated
        @param collection: new ERC721 address
        @param creator: creator address of the ERC721 collection */
    event CreatorsCollection(
        address indexed collection,
        address indexed creator
    );

    /** @dev event for when a new ERC1155 ticket collection is instantiated
        @param collection: new ERC1155 ticket collection address
        @param creator: ERC1155 ticket collection creator address */
    event TicketCollection(address indexed collection, address indexed creator);

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
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminArt(address indexed _new, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 crowdfund collection contract is set 
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminFund(address indexed _new, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 CreatorsPRO collection contract is set 
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminCreators(address indexed _new, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC1155 ticket collection contract is set 
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminTickets(address indexed _new, address indexed manager);

    /** @dev event for when a new multisig wallet address is set
        @param _new: new multisig wallet address
        @param manager: the manager address that has done the setting */
    event NewMultiSig(address indexed _new, address indexed manager);

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

    /** @dev event for when a new ERC20 CreatorsCoin address is set
        @param _new: new ERC20 CreatorsCoin address
        @param manager: the manager address that has done the setting */
    event NewCreatorsCoinConctractSet(
        address indexed _new,
        address indexed manager
    );

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

    /// -----------------------------------------------------------------------
    /// Custom errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error ManagementNotAllowed();

    ///@dev error for when collection name is invalid
    error ManagementInvalidName();

    ///@dev error for when collection symbol is invalid
    error ManagementInvalidSymbol();

    ///@dev error for when the input is an invalid address
    error ManagementInvalidAddress();

    ///@dev error for when the input arrays have not the same length
    error ManagementInputArraysNotSameLength();

    ///@dev error for when a value in batch supplies input array is 0
    error ManagementBatchMaxSupplyCannotBe0();

    ///@dev error for when the resulting max supply is 0
    error ManagementFundMaxSupplyIs0();

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- From storage variables ---

    /** @notice reads beaconAdminArt public storage variable
        @return address of the beacon admin for the art collection (ERC721) contract */
    function beaconAdminArt() external view returns (address);

    /** @notice reads beaconAdminFund public storage variable
        @return address of the beacon admin for the crowdfund (ERC721) contract */
    function beaconAdminFund() external view returns (address);

    /** @notice reads beaconAdminCreators public storage variable
        @return address of the beacon admin for the CreatorsPRO collection (ERC721) contract */
    function beaconAdminCreators() external view returns (address);

    /** @notice reads creatorsCoin public storage variable
        @return address of the CreatorsCoin (ERC20) contract */
    function creatorsCoin() external view returns (address);

    /** @notice reads beaconAdminTickets public storage variable
        @return address of the beacdon admin for the tickets (ERC1155) contract */
    function beaconAdminTickets() external view returns (address);

    /** @notice reads multiSig public storage variable 
        @return address of the multisig wallet */
    function multiSig() external view returns (address);

    /** @notice reads fee public storage variable 
        @return the royalty fee */
    function fee() external view returns (uint256);

    /** @notice reads allowedCreators public storage mapping
        @param _caller: address to check if is allowed creator
        @return boolean if the given address is an allowed creator */
    function allowedCreators(address _caller) external view returns (bool);

    /** @notice reads managers public storage mapping
        @param _caller: address to check if is manager
        @return boolean if the given address is a manager */
    function managers(address _caller) external view returns (bool);

    // --- Implemented functions ---

    /** @dev smart contract's initializer/constructor.
        @param _beaconAdminArt: address of the beacon admin for the creators ERC721 art smart contract 
        @param _beaconAdminFund: address of the beacon admin for the creators ERC721 fund smart contract
        @param _beaconAdminCreators: address of the beacon admin for the CreatorPRO ERC721 smart contract 
        @param _multiSig: address of the Multisig smart contract
        @param _fee: royalty fee */
    function initialize(
        address _beaconAdminArt,
        address _beaconAdminFund,
        address _beaconAdminCreators,
        address _beaconAdminTickets,
        address _creatorsCoin,
        address _multiSig,
        uint256 _fee
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param _price: mint price of a single NFT
        @param _baseURI: base URI for the collection's metadata 
        @param _royalty: royalty payment to owner */
    function newArtCollection(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSD,
        uint256 _priceInCreatorsCoin,
        string memory _baseURI,
        uint256 _royalty
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _baseURI: base URI for the collection's metadata
        @param _cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _royalty,
        CrowdFundParams memory _cfParams
    ) external;

    /** @notice instantiates/deploys new CreatorPRO NFT art collection smart contract.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param _price: mint price of a single NFT
        @param _baseURI: base URI for the collection's metadata */
    function newCreatorsCollection(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSDC,
        uint256 _priceInCreatorsCoin,
        string memory _baseURI
    ) external;

    /** @notice instantiates/deploys new ticket collection smart contract. 
        @param _name: name of the ticket collection
        @param _symbol: symbol of the ticket collection  
        @param _maxSupply: array of maximum ticket supplies for each batch.
        @param _price: array of mint price of a single ticket for each batch
        @param _priceUSD: array of mint price of a single ticket for each batch, is USDC
        @param _priceCreatorsCoin: array of mint price of a single ticket for each batch, in CreatorsCoin
        @param _baseURI: base URI for the collection's metadata */
    function newTicketsCollection(
        string memory _name,
        string memory _symbol,
        uint256[] memory _maxSupply,
        uint256[] memory _price,
        uint256[] memory _priceUSD,
        uint256[] memory _priceCreatorsCoin,
        string memory _baseURI
    ) external;

    // --- Setter functions ---

    /** @notice sets hashpower and characterist ID for the given token ID
        @param _collection: collection address
        @param _tokenId: array of token IDs
        @param _hashPower: array of hashpowers for the token ID
        @param _characteristId: array of characterit IDs */
    function setHashObject(
        address _collection,
        uint256[] memory _tokenId,
        uint256[] memory _hashPower,
        uint256[] memory _characteristId
    ) external;

    /** @notice sets creator permission.
        @param _creator: creator address
        @param _allowed: boolean that specifies if creator address has permission (true) or not (false) */
    function setCreator(address _creator, bool _allowed) external;

    /** @notice sets manager permission.
        @param _manager: manager address
        @param _allowed: boolean that specifies if manager address has permission (true) or not (false) */
    function setManager(address _manager, bool _allowed) external;

    /** @notice sets new beacon admin address for the creators ERC721 art smart contract.
        @param _new: new address */
    function setBeaconAdminArt(address _new) external;

    /** @notice sets new beacon admin address for the creators ERC721 fund smart contract.
        @param _new: new address */
    function setBeaconAdminFund(address _new) external;

    /** @notice sets new beacon admin address for the CreatorPRO ERC721 smart contract.
        @param _new: new address */
    function setBeaconAdminCreators(address _new) external;

    /** @notice sets new address for the Multisig smart contract.
        @param _new: new address */
    function setMultiSig(address _new) external;

    /** @notice sets new fee for NFT minting.
        @param _fee: new fee */
    function setFee(uint256 _fee) external;

    /** @notice sets CreatorsCoin ERC20 smart contract address
        @param _contract: address from CreatorsCoin ERC20 smart contract */
    function setCreatorsCoinContract(address _contract) external;

    /** @notice sets Beacon admin contract address for tickets
        @param _contract: new address */
    function setBeaconAdminTickets(address _contract) external;

    // --- Getter functions ---

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads hashObjects public storage mapping
        @param _collection: address of an CreatorsPRO collection (ERC721)
        @param _tokenId: ID of the token from the given collection
        @return HashObject struct for the given collection and toeken ID */
    function getHashObject(
        address _collection,
        uint256 _tokenId
    ) external view returns (HashObject memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

///@dev inhouse implemented smart contracts and interfaces
import "./interfaces/IManagement.sol";
import "./interfaces/IERC721Art.sol";

///@dev beacon proxy smart contract
import "./@openzeppelin/proxy/beacon/BeaconProxy.sol";

///@dev UUPS smart contract
import "./@openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import "./@openzeppelin/proxy/utils/Initializable.sol";

/** @author Omnes Blockchain team (@EWCunha, @Afonsodalvi, and @G-Deps)
    @title Management contract for CreatorsPRO project */
contract Management is IManagement, Initializable, UUPSUpgradeable {
    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    // Beacon admins addresses
    address public beaconAdminArt;
    address public beaconAdminFund;
    address public beaconAdminCreators;
    address public beaconAdminTickets;

    // CreatorsCoin ERC20 contract address
    address public creatorsCoin;

    // Multisig address
    address public multiSig;

    // Creators royalty fee
    uint256 public fee; // over 10000

    ///@dev mapping that specifies if an address is an allowed creator (true) or not (false)
    mapping(address => bool) public allowedCreators;

    ///@dev mapping that specifies if address is a manager (true) or not (false)
    mapping(address => bool) public managers;

    ///@dev mapping of hash objects (ERC721 collection address => tokenId => hashObject)
    mapping(address => mapping(uint256 => HashObject)) private hashObjects;

    /// -----------------------------------------------------------------------
    /// Initializer
    /// -----------------------------------------------------------------------

    /// @dev initializer modifier added.
    /// @inheritdoc IManagement
    function initialize(
        address _beaconAdminArt,
        address _beaconAdminFund,
        address _beaconAdminCreators,
        address _beaconAdminTickets,
        address _creatorsCoin,
        address _multiSig,
        uint256 _fee
    ) external override(IManagement) initializer {
        beaconAdminArt = _beaconAdminArt;
        beaconAdminFund = _beaconAdminFund;
        beaconAdminCreators = _beaconAdminCreators;
        beaconAdminTickets = _beaconAdminTickets;
        creatorsCoin = _creatorsCoin;
        multiSig = _multiSig;
        fee = _fee;
        managers[tx.origin] = true;
    }

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    ///@dev only allowed creator addresses can call function.
    modifier onlyCreators() {
        if (!allowedCreators[msg.sender]) {
            revert ManagementNotAllowed();
        }
        _;
    }

    ///@dev only allowed CreatorsPRO manager addresses can call function.
    modifier onlyManagers() {
        if (!managers[msg.sender]) {
            revert ManagementNotAllowed();
        }
        _;
    }

    /** @dev validates name and symbol parameters before creating NFT collection smart contract. 
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection */
    modifier validateCollectionParams(
        string memory _name,
        string memory _symbol
    ) {
        if (!(bytes(_name).length > 0)) {
            revert ManagementInvalidName();
        }
        if (!(bytes(_symbol).length > 0)) {
            revert ManagementInvalidSymbol();
        }
        _;
    }

    /** @dev checks if given address is not the zero address.
        @param _add: given address */
    modifier validateAddress(address _add) {
        if (_add == address(0)) {
            revert ManagementInvalidAddress();
        }
        _;
    }

    /// -----------------------------------------------------------------------
    /// New collection functions
    /// -----------------------------------------------------------------------

    /** @dev only allowed creators. _name and _symbol must not be empty ("").
    beaconAdminArt must not be zero address. */
    /// @inheritdoc IManagement
    function newArtCollection(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSD,
        uint256 _priceInCreatorsCoin,
        string memory _baseURI,
        uint256 _royalty
    )
        external
        override(IManagement)
        onlyCreators
        validateCollectionParams(_name, _symbol)
        validateAddress(beaconAdminArt)
    {
        bytes memory ERC721initialize = abi.encodeWithSignature(
            "initialize(string,string,address,uint256,uint256,uint256,uint256,string,uint256)",
            _name,
            _symbol,
            msg.sender,
            _maxSupply,
            _price,
            _priceInUSD,
            _priceInCreatorsCoin,
            _baseURI,
            _royalty
        );

        BeaconProxy newCollectionProxy = new BeaconProxy(
            beaconAdminArt,
            ERC721initialize
        );

        emit ArtCollection(address(newCollectionProxy), msg.sender);
    }

    /** @dev only allowed creators. _name and _symbol must not be empty.
    beaconAdminFund must not be zero address. */
    /// @inheritdoc IManagement
    function newCrowdfund(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _royalty,
        CrowdFundParams memory _cfParams
    )
        external
        override(IManagement)
        onlyCreators
        validateCollectionParams(_name, _symbol)
        validateAddress(beaconAdminFund)
    {
        if (
            _cfParams._amountLowQuota +
                _cfParams._amountRegQuota +
                _cfParams._amountHighQuota ==
            0
        ) {
            revert ManagementFundMaxSupplyIs0();
        }

        bytes memory ERC721ArtInitialize = abi.encodeWithSignature(
            "initialize(string,string,address,uint256,uint256,uint256,uint256,string,uint256)",
            _name,
            _symbol,
            msg.sender,
            _cfParams._amountLowQuota +
                _cfParams._amountRegQuota +
                _cfParams._amountHighQuota,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
            _baseURI,
            _royalty
        );

        BeaconProxy newArtCollectionProxy = new BeaconProxy(
            beaconAdminArt,
            ERC721ArtInitialize
        );

        bytes memory ERC721FundInitialize = abi.encodeWithSignature(
            "initialize(uint256,uint256,uint256,uint256,uint256,uint256,address,uint256,uint256,address,address)",
            _cfParams._valueLowQuota,
            _cfParams._valueRegQuota,
            _cfParams._valueHighQuota,
            _cfParams._amountLowQuota,
            _cfParams._amountRegQuota,
            _cfParams._amountHighQuota,
            _cfParams._donationReceiver,
            _cfParams._donationFee,
            _cfParams._minSoldRate,
            address(newArtCollectionProxy),
            msg.sender
        );

        BeaconProxy newFundCollectionProxy = new BeaconProxy(
            beaconAdminFund,
            ERC721FundInitialize
        );

        IERC721Art(address(newArtCollectionProxy)).setCrowdfund(
            address(newFundCollectionProxy)
        );

        emit Crowdfund(
            address(newFundCollectionProxy),
            address(newArtCollectionProxy),
            msg.sender
        );
    }

    /** @dev only allowed creators. _name and _symbol must not be empty.
    beaconAdminCreators must not be zero address. */
    /// @inheritdoc IManagement
    function newCreatorsCollection(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSDC,
        uint256 _priceInCreatorsCoin,
        string memory _baseURI
    )
        external
        override(IManagement)
        onlyManagers
        validateCollectionParams(_name, _symbol)
        validateAddress(beaconAdminCreators)
    {
        bytes memory ERC721initialize = abi.encodeWithSignature(
            "initialize(string,string,address,uint256,uint256,uint256,uint256,string,uint256)",
            _name,
            _symbol,
            msg.sender,
            _maxSupply,
            _price,
            _priceInUSDC,
            _priceInCreatorsCoin,
            _baseURI,
            0
        );

        BeaconProxy newCollectionProxy = new BeaconProxy(
            beaconAdminCreators,
            ERC721initialize
        );

        emit CreatorsCollection(address(newCollectionProxy), msg.sender);
    }

    /** @dev only allowed creators. _name and _symbol must not be empty.
    beaconAdminTickets must not be zero address. */
    /// @inheritdoc IManagement
    function newTicketsCollection(
        string memory _name,
        string memory _symbol,
        uint256[] memory _maxSupply,
        uint256[] memory _price,
        uint256[] memory _priceUSD,
        uint256[] memory _priceCreatorsCoin,
        string memory _baseURI
    )
        external
        override(IManagement)
        onlyCreators
        validateCollectionParams(_name, _symbol)
        validateAddress(beaconAdminTickets)
    {
        if (
            !(_price.length == _priceUSD.length &&
                _price.length == _priceCreatorsCoin.length &&
                _price.length == _maxSupply.length)
        ) {
            revert ManagementInputArraysNotSameLength();
        }

        for (uint256 ii; ii < _maxSupply.length; ++ii) {
            if (!(_maxSupply[ii] > 0)) {
                revert ManagementBatchMaxSupplyCannotBe0();
            }
        }

        bytes memory ERC1155initialize = abi.encodeWithSignature(
            "initialize(string,string,address,uint256[],uint256[],uint256[],uint256[],string)",
            _name,
            _symbol,
            msg.sender,
            _maxSupply,
            _price,
            _priceUSD,
            _priceCreatorsCoin,
            _baseURI
        );

        BeaconProxy newCollectionProxy = new BeaconProxy(
            beaconAdminTickets,
            ERC1155initialize
        );

        emit TicketCollection(address(newCollectionProxy), msg.sender);
    }

    /// -----------------------------------------------------------------------
    /// Setter functions
    /// -----------------------------------------------------------------------

    /// @dev only managers allowed to call this function. Input arrays must have same size.
    /// @inheritdoc IManagement
    function setHashObject(
        address _collection,
        uint256[] memory _tokenId,
        uint256[] memory _hashPower,
        uint256[] memory _characteristId
    ) external override(IManagement) onlyManagers {
        if (
            !(_tokenId.length == _hashPower.length &&
                _tokenId.length == _characteristId.length)
        ) {
            revert ManagementInputArraysNotSameLength();
        }

        for (uint256 ii = 0; ii < _tokenId.length; ++ii) {
            hashObjects[_collection][_tokenId[ii]].hashpower = _hashPower[ii];
            hashObjects[_collection][_tokenId[ii]]
                .characteristId = _characteristId[ii];
        }

        emit HashObjectSet(
            msg.sender,
            _collection,
            _tokenId,
            _hashPower,
            _characteristId
        );
    }

    /** @dev only managers allowed to call this function. _creator must
    not be zero address. */
    /// @inheritdoc IManagement
    function setCreator(
        address _creator,
        bool _allowed
    ) external override(IManagement) onlyManagers validateAddress(_creator) {
        allowedCreators[_creator] = _allowed;

        emit CreatorSet(_creator, _allowed, msg.sender);
    }

    /** @dev only managers allowed to call this function. _manager must
    not be zero address. */
    /// @inheritdoc IManagement
    function setManager(
        address _manager,
        bool _allowed
    ) external override(IManagement) onlyManagers validateAddress(_manager) {
        managers[_manager] = _allowed;

        emit ManagerSet(_manager, _allowed, msg.sender);
    }

    /** @dev only managers allowed to call this function. _new must
    not be zero address. */
    /// @inheritdoc IManagement
    function setBeaconAdminArt(
        address _new
    ) external override(IManagement) onlyManagers validateAddress(_new) {
        beaconAdminArt = _new;

        emit NewBeaconAdminArt(_new, msg.sender);
    }

    /** @dev only managers allowed to call this function. _new must
    not be zero address. */
    /// @inheritdoc IManagement
    function setBeaconAdminFund(
        address _new
    ) external override(IManagement) onlyManagers validateAddress(_new) {
        beaconAdminFund = _new;

        emit NewBeaconAdminFund(_new, msg.sender);
    }

    /** @dev only managers allowed to call this function. _new must
    not be zero address. */
    /// @inheritdoc IManagement
    function setBeaconAdminCreators(
        address _new
    ) external override(IManagement) onlyManagers validateAddress(_new) {
        beaconAdminCreators = _new;

        emit NewBeaconAdminCreators(_new, msg.sender);
    }

    /** @dev only managers allowed to call this function. _new must
    not be zero address. */
    /// @inheritdoc IManagement
    function setMultiSig(
        address _new
    ) external override(IManagement) onlyManagers validateAddress(_new) {
        multiSig = _new;

        emit NewMultiSig(_new, msg.sender);
    }

    /** @dev only managers allowed to call this function. */
    /// @inheritdoc IManagement
    function setFee(uint256 _fee) external override(IManagement) onlyManagers {
        fee = _fee;

        emit NewFee(_fee, msg.sender);
    }

    /** @dev only managers allowed to call this function. _contract must
    not be zero address. */
    /// @inheritdoc IManagement
    function setCreatorsCoinContract(
        address _contract
    ) external override(IManagement) onlyManagers validateAddress(_contract) {
        creatorsCoin = _contract;

        emit NewCreatorsCoinConctractSet(_contract, msg.sender);
    }

    /** @dev only managers allowed to call this function. _contract must
    not be zero address. */
    /// @inheritdoc IManagement
    function setBeaconAdminTickets(
        address _contract
    ) external override(IManagement) onlyManagers validateAddress(_contract) {
        beaconAdminTickets = _contract;

        emit NewBeaconAdminTickets(_contract, msg.sender);
    }

    /// -----------------------------------------------------------------------
    /// Getter functions
    /// -----------------------------------------------------------------------

    /** @dev only managers allowed to call this function. */
    /// @inheritdoc IManagement
    function getImplementation()
        external
        view
        override(IManagement)
        onlyManagers
        returns (address)
    {
        return ERC1967Upgrade._getImplementation();
    }

    /// @inheritdoc IManagement
    function getHashObject(
        address _collection,
        uint256 _tokenId
    ) external view override(IManagement) returns (HashObject memory) {
        return hashObjects[_collection][_tokenId];
    }

    /// -----------------------------------------------------------------------
    /// Overriden functions
    /// -----------------------------------------------------------------------

    /** @dev only managers are allowed to call this function. */
    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(
        address newImplementation
    ) internal override(UUPSUpgradeable) onlyManagers {}
}