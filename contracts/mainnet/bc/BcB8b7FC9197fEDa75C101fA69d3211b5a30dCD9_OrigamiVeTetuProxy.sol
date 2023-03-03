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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/access/GovernableBase.sol)

import {CommonEventsAndErrors} from "contracts/common/CommonEventsAndErrors.sol";

/// @notice Base contract to enable a contract to be governable (eg by a Timelock contract)
/// @dev Either implement a constructor or initializer (upgradable proxy) to set the 
abstract contract GovernableBase {
    address internal _gov;
    address internal _proposedNewGov;

    event NewGovernorProposed(address indexed previousGov, address indexed previousProposedGov, address indexed newProposedGov);
    event NewGovernorAccepted(address indexed previousGov, address indexed newGov);

    error NotGovernor();

    function _init(address initialGovernor) internal {
        if (_gov != address(0)) revert NotGovernor();
        if (initialGovernor == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        _gov = initialGovernor;
    }

    /**
     * @dev Returns the address of the current governor.
     */
    function gov() external view returns (address) {
        return _gov;
    }

    /**
     * @dev Proposes a new Governor.
     * Can only be called by the current governor.
     */
    function proposeNewGov(address newProposedGov) external onlyGov {
        if (newProposedGov == address(0)) revert CommonEventsAndErrors.InvalidAddress(newProposedGov);
        emit NewGovernorProposed(_gov, _proposedNewGov, newProposedGov);
        _proposedNewGov = newProposedGov;
    }

    /**
     * @dev Caller accepts the role as new Governor.
     * Can only be called by the proposed governor
     */
    function acceptGov() external {
        if (msg.sender != _proposedNewGov) revert CommonEventsAndErrors.InvalidAddress(msg.sender);
        emit NewGovernorAccepted(_gov, msg.sender);
        _gov = msg.sender;
        delete _proposedNewGov;
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGov() {
        if (msg.sender != _gov) revert NotGovernor();
        _;
    }

}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/access/GovernableUpgradeable.sol)

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {GovernableBase} from "contracts/common/access/GovernableBase.sol";

/// @notice Enable a contract to be governable (eg by a Timelock contract) -- for upgradeable proxies
abstract contract GovernableUpgradeable is GovernableBase, Initializable {

    function __Governable_init(address initialGovernor) internal onlyInitializing {
        __Governable_init_unchained(initialGovernor);
    }

    function __Governable_init_unchained(address initialGovernor) internal onlyInitializing {
        _init(initialGovernor);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) internal _operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function operators(address _account) external view returns (bool) {
        return _operators[_account];
    }

    function _addOperator(address _account) internal {
        emit AddedOperator(_account);
        _operators[_account] = true;
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        emit RemovedOperator(_account);
        delete _operators[_account];
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!_operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
    }
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the Origami contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();
    error Slippage(uint256 minAmountExpected, uint256 acutalAmount);
    error IsPaused();
    error UnknownExecuteError(bytes returndata);
    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/snapshot/ISnapshotDelegator.sol)

interface ISnapshotDelegator {
    function setDelegate(bytes32 id, address delegate) external;
    function clearDelegate(bytes32 id) external;
    function delegation(address from, bytes32 id) external view returns (address);
}

// SPDX-License-Identifier: MIT
// Origami (interfaces/external/tetu/IPlatformVoter.sol)

pragma solidity 0.8.17;

interface ITetuPlatformVoter {

    enum AttributeType {
        UNKNOWN,
        INVEST_FUND_RATIO,
        GAUGE_RATIO,
        STRATEGY_COMPOUND
    }

    struct Vote {
        AttributeType _type;
        address target;
        uint weight;
        uint weightedValue;
        uint timestamp;
    }

    function poke(uint tokenId) external;
    function voteBatch(
        uint tokenId,
        AttributeType[] memory types,
        uint[] memory values,
        address[] memory targets
    ) external; 
    function vote(uint tokenId, AttributeType _type, uint value, address target) external;
    function reset(uint tokenId, uint[] memory types, address[] memory targets) external;
    
    // Views
    function veVotes(uint veId) external view returns (Vote[] memory);
    function veVotesLength(uint veId) external view returns (uint);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/tetu/ITetuRewardsDistributor.sol)

interface ITetuRewardsDistributor {
    function claim(uint256 _tokenId) external returns (uint256);  
    function claimable(uint256 _tokenId) external view returns (uint256);
    function claimMany(uint256[] memory _tokenIds) external returns (bool);

    function checkpoint() external;
    function checkpointTotalSupply() external;

    /// @dev Tokens per week stored on checkpoint call. Predefined array size = max weeks size
    function tokensPerWeek(uint256 week) external view returns (uint256);

    /// @dev Last checkpoint time
    function lastTokenTime() external view returns (uint256);

    /// @dev Ve supply checkpoint time cursor
    function timeCursor() external view returns (uint256);

    /// @dev Timestamp when this contract was inited
    function startTime() external view returns (uint256);

    /// @dev veID => week cursor stored on the claim action
    function timeCursorOf(uint256 id) external view returns (uint256);

    /// @dev veID => epoch stored on the claim action
    function userEpochOf(uint256 id) external view returns (uint256);

    /// @dev Search in the loop given timestamp through ve user points history.
    ///      Return minimal possible epoch.
    function findTimestampUserEpoch(
        address _ve,
        uint256 tokenId,
        uint256 _timestamp,
        uint256 maxUserEpoch
    ) external view returns (uint256);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/tetu/ITetuVoter.sol)

interface ITetuVoter {
    /// @dev Remove all votes for given tokenId.
    ///      Ve token should be able to remove votes on transfer/withdraw
    function reset(uint256 tokenId) external;

    /// @dev Vote for given pools using a vote power of given tokenId. Reset previous votes.
    function vote(uint256 tokenId, address[] calldata _vaultVotes, int256[] calldata _weights) external;

    function validVaultsLength() external view returns (uint256);
    function validVaults(uint256 id) external view returns (address);

    /// @dev veID => Last vote timestamp
    function lastVote(uint256 id) external view returns (uint256);

    /// @dev nft => vault => votes
    function votes(uint256 id, address vault) external view returns (int256);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/external/tetu/IVeTetu.sol)

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVeTetu is IERC721 {
    // Lock
    function createLock(address _token, uint256 _value, uint256 _lockDuration) external returns (uint256);
    function increaseAmount(address _token, uint256 _tokenId, uint256 _value) external;
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external;
    function merge(uint256 _from, uint256 _to) external;
    function split(uint256 _tokenId, uint256 percent) external;
    function withdraw(address stakingToken, uint256 _tokenId) external;
    function withdrawAll(uint256 _tokenId) external;

    // Voting
    function voting(uint256 _tokenId) external;
    function abstain(uint256 _tokenId) external;

    /// @dev Current count of token
    function tokenId() external view returns (uint256);

    /// @dev veId => stakingToken => Locked amount
    function lockedAmounts(uint256 _tokenId, address _stakingToken) external view returns (uint256);

    /// @dev veId => Amount based on weights aka power
    function lockedDerivedAmount(uint256 _tokenId) external view returns (uint256);

    /// @dev veId => Lock end timestamp
    function lockedEnd(uint256 _tokenId) external view returns (uint256);

    /// @notice Get the current voting power for `_tokenId`
    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256);

    /// @notice Calculate total voting power
    function totalSupplyAtT(uint256 t) external view returns (uint256);

    /// @dev Get token by index
    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex) external view returns (uint256);

    /// @dev Whitelist address for transfers. Removing from whitelist should be forbidden.
    function whitelistTransferFor(address value) external;

    enum TimeLockType {
        UNKNOWN,
        ADD_TOKEN,
        WHITELIST_TRANSFER
    }
    function announceAction(TimeLockType _type) external;

    /// @dev Underlying staking tokens
    function tokens(uint256 i) external returns (address);

    /// @dev Return length of staking tokens.
    function tokensLength() external view returns (uint256);

    function isApprovedOrOwner(address _spender, uint _tokenId) external view returns (bool);

    function userPointEpoch(uint256 _tokenId) external view returns (uint256);

    /// @notice Record global data to checkpoint
    function checkpoint() external;

    /// @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
    function userPointHistoryTs(uint _tokenId, uint _idx) external view returns (uint256);

}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (investments/vetetu/OrigamiVeTetuProxy.sol)

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IVeTetu} from "contracts/interfaces/external/tetu/IVeTetu.sol";
import {ITetuVoter} from "contracts/interfaces/external/tetu/ITetuVoter.sol";
import {ITetuPlatformVoter} from "contracts/interfaces/external/tetu/ITetuPlatformVoter.sol";
import {ITetuRewardsDistributor} from "contracts/interfaces/external/tetu/ITetuRewardsDistributor.sol";
import {ISnapshotDelegator} from "contracts/interfaces/external/snapshot/ISnapshotDelegator.sol";

import {Operators} from "contracts/common/access/Operators.sol";
import {CommonEventsAndErrors} from "contracts/common/CommonEventsAndErrors.sol";
import {GovernableUpgradeable} from "../../common/access/GovernableUpgradeable.sol";

/**
  * @title Origami veTETU Proxy
  * @notice 
  *    - Lock tokens to veTetu contract (which mints a veTetu NFT)
  *    - Claim rewards from veTetu (which compounds into veTetu)
  *    - Vote for Tetu vaults
  *    - Delegate snapshot voting for governance
  */
contract OrigamiVeTetuProxy is Initializable, GovernableUpgradeable, Operators, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The underlying veTetu contract is locking into
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IVeTetu public immutable veTetu;

    /// @dev Claim locked veTetu yield
    ITetuRewardsDistributor public tetuRewardsDistributor;

    /// @dev Ability to delegate veTetu snapshot voting to an eoa
    ISnapshotDelegator public snapshotDelegator;

    /// @dev Use voting power to vote for vaults
    ITetuVoter public tetuVoter;

    /// @dev Use the voting power for tetu platform votes.
    ITetuPlatformVoter public tetuPlatformVoter;

    event SnapshotDelegatorSet(address indexed _delegator);
    event TetuRewardsDistributorSet(address indexed _distributor);
    event TetuVoterSet(address indexed _voter);
    event TetuPlatformVoterSet(address indexed _platformVoter);
    event CreatedLock(address indexed _token, uint256 _value, uint256 _lockDuration);
    event IncreaseAmount(address indexed _token, uint256 indexed _tokenId, uint256 _value);
    event IncreaseUnlockTime(uint256 indexed _tokenId, uint256 _lockDuration);
    event Withdraw(address indexed _stakingToken, uint256 indexed _tokenId, uint256 _amount, address indexed _receiver);
    event WithdrawAll(uint256 indexed _tokenId, address indexed _receiver);
    event Merge(uint256 indexed _id1, uint256 indexed _id2);
    event Split(uint256 indexed _tokenId, uint256 _percent);
    event ClaimVeTetuRewards(uint256 indexed _tokenId, uint256 _amount);
    event ClaimManyVeTetuRewards(uint256[] _tokenIds);
    event VeTetuNFTReceived(uint256 indexed _tokenId);   
    event SetDelegate(address indexed _delegate);
    event ClearDelegate();
    event TokenTransferred(address indexed token, address indexed to, uint256 amount);
    event VeTetuTransferred(address indexed to, uint256 indexed tokenId);
    event Voted(uint256 indexed _tokenId);
    event ResetVote(uint256 indexed _tokenId);
    event PlatformVote(uint256 indexed _tokenId);
    event PlatformVoteBatch(uint256 indexed _tokenId);
    event PlatformVoteReset(uint256 indexed _tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _veTetu
    ) {
        _disableInitializers();
        
        veTetu = IVeTetu(_veTetu);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyGov
        override
    {}

    function initialize(
        address _initialGov, 
        address _tetuRewardsDistributor,
        address _snapshotDelegator,
        address _tetuVoter,
        address _tetuPlatformVoter
    ) public initializer {
        __Governable_init(_initialGov);
        __UUPSUpgradeable_init();

        tetuRewardsDistributor = ITetuRewardsDistributor(_tetuRewardsDistributor);
        snapshotDelegator = ISnapshotDelegator(_snapshotDelegator);
        tetuVoter = ITetuVoter(_tetuVoter);
        tetuPlatformVoter = ITetuPlatformVoter(_tetuPlatformVoter);
    }

    // **************** //
    // Setter Functions //
    // **************** //

    /// @notice Set the snapshot delegate registry address
    function setSnapshotDelegator(address _delegator) external onlyGov {
        if (_delegator == address(0)) revert CommonEventsAndErrors.InvalidAddress(_delegator);
        snapshotDelegator = ISnapshotDelegator(_delegator);
        emit SnapshotDelegatorSet(_delegator);
    }

    /// @notice Set the TETU rewards distributor address
    function setTetuRewardsDistributor(address _distributor) external onlyGov {
        if (_distributor == address(0)) revert CommonEventsAndErrors.InvalidAddress(_distributor);
        tetuRewardsDistributor = ITetuRewardsDistributor(_distributor);
        emit TetuRewardsDistributorSet(_distributor);
    }

    /// @notice Set the TETU Voter address
    function setTetuVoter(address _tetuVoter) external onlyGov {
        if (_tetuVoter == address(0)) revert CommonEventsAndErrors.InvalidAddress(_tetuVoter);
        tetuVoter = ITetuVoter(_tetuVoter);
        emit TetuVoterSet(_tetuVoter);
    }

    /// @notice Set the TETU Platform Voter address
    function setTetuPlatformVoter(address _tetuPlatformVoter) external onlyGov {
        if (_tetuPlatformVoter == address(0)) revert CommonEventsAndErrors.InvalidAddress(_tetuPlatformVoter);
        tetuPlatformVoter = ITetuPlatformVoter(_tetuPlatformVoter);
        emit TetuPlatformVoterSet(_tetuPlatformVoter);
    }

    function addOperator(address _address) external override onlyGov {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyGov {
        _removeOperator(_address);
    }

    // *********** //
    //    veTetu   //
    // *********** // 

    /// @notice Deposit tokens into veTetu and receive an NFT
    /// @dev Staking tokens should first be sent to this address
    function createLock(address _token, uint256 _value, uint256 _lockDuration) external onlyOperators returns (uint256) {
        emit CreatedLock(_token, _value, _lockDuration);
        IERC20Upgradeable(_token).safeIncreaseAllowance(address(veTetu), _value);
        return veTetu.createLock(_token, _value, _lockDuration);
    }

    /// @notice Increase the staked tokens for a given veTetu id
    /// @dev Staking tokens should first be sent to this address
    function increaseAmount(address _token, uint256 _tokenId, uint256 _value) external onlyOperators {
        emit IncreaseAmount(_token, _tokenId, _value);
        IERC20Upgradeable(_token).safeIncreaseAllowance(address(veTetu), _value);
        veTetu.increaseAmount(_token, _tokenId, _value);
    }

    /// @notice Increase the unlock time for a given veTetu. 
    /// @dev This will increase voting power
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external onlyOperators {
        emit IncreaseUnlockTime(_tokenId, _lockDuration);
        veTetu.increaseUnlockTime(_tokenId, _lockDuration);
    }

    /// @notice Withdraw staking tokens from an expired veTetu token
    /// @dev Sends the tokens to receiver
    function withdraw(address _stakingToken, uint256 _tokenId, address _receiver) external onlyOperators returns (uint256) {
        uint256 lockedAmount = veTetu.lockedAmounts(_tokenId, _stakingToken);
        emit Withdraw(_stakingToken, _tokenId, lockedAmount, _receiver);
        veTetu.withdraw(_stakingToken, _tokenId);

        if (_receiver != address(this)) {
            IERC20Upgradeable(_stakingToken).safeTransfer(_receiver, lockedAmount);
        }

        return lockedAmount;
    }

    /// @notice Withdraw all staking tokens from an expired veTetu token
    /// @dev Sends the tokens to receiver
    function withdrawAll(uint256 _tokenId, address _receiver) external onlyOperators returns (uint256[] memory) {
        emit WithdrawAll(_tokenId, _receiver);

        // Get the balances of the existing locks
        uint256 tokensLength = veTetu.tokensLength();
        uint256[] memory lockedAmounts = new uint256[](tokensLength);
        address[] memory tokens = new address[](tokensLength);
        uint256 i;
        for (; i < tokensLength; ++i) {
            tokens[i] = veTetu.tokens(i);
            lockedAmounts[i] = veTetu.lockedAmounts(_tokenId, tokens[i]);
        }

        // Do the withdrawal
        veTetu.withdrawAll(_tokenId);

        // Send to the receiver
        if (_receiver != address(this)) {
            for (i=0; i < tokensLength; ++i) {
                IERC20Upgradeable(tokens[i]).safeTransfer(_receiver, lockedAmounts[i]);
            }
        }

        return lockedAmounts;
    }

    /// @notice Merge `_id1` veTetu NFT into `_id2`
    function merge(uint256 _id1, uint256 _id2) external onlyOperators {
        emit Merge(_id1, _id2);
        veTetu.merge(_id1, _id2);
    }

    /// @notice Split a veTetu into two
    function split(uint256 _tokenId, uint256 _percent) external onlyOperators {
        emit Split(_tokenId, _percent);
        veTetu.split(_tokenId, _percent);
    }

    /// @notice The amount locked of `_stakingToken` for a given `_tokenId`
    function veTetuLockedAmountOf(uint256 _tokenId, address _stakingToken) external view returns (uint256) {
        return veTetu.lockedAmounts(_tokenId, _stakingToken);
    }
    
    /// @notice Get the current total locked amount across all veTetu tokens this proxy owns
    function veTetuLockedAmount(address _stakingToken) external view returns (uint256) {
        uint256 amount;
        uint256 numTokens = IERC20Upgradeable(address(veTetu)).balanceOf(address(this));
        uint256 tokenId;
        for (uint256 i; i < numTokens; ++i) {
            tokenId = veTetu.tokenOfOwnerByIndex(address(this), i);
            amount += veTetu.lockedAmounts(tokenId, _stakingToken);
        }

        return amount;
    }

    /// @notice The unlock date for a `_tokenId`
    function veTetuLockedEnd(uint256 _tokenId) external view returns (uint256) {
        return veTetu.lockedEnd(_tokenId);
    }

    /// @notice Get the current veTetu voting balance across a particular token id
    function veTetuVotingBalanceOf(uint256 _tokenId) external view returns (uint256) {
        return veTetu.balanceOfNFTAt(_tokenId, block.timestamp);
    }

    /// @notice Get the current total veTetu voting balance across all NFS this proxy owns
    function veTetuVotingBalance() external view returns (uint256) {
        uint256 totalVotingPower;
        uint256 numTokens = IERC20Upgradeable(address(veTetu)).balanceOf(address(this));
        uint256 tokenId;
        for (uint256 i; i < numTokens; ++i) {
            tokenId = veTetu.tokenOfOwnerByIndex(address(this), i);
            totalVotingPower += veTetu.balanceOfNFTAt(tokenId, block.timestamp);
        }

        return totalVotingPower;
    }

    /// @notice Calculate total veTetu voting supply, as of now.
    function totalVeTetuVotingSupply() external view returns (uint256) {
        return veTetu.totalSupplyAtT(block.timestamp);
    }

    // ************** //
    // veTetu Rewards //
    // ************** //

    /// @notice Claim rewards for a veTetu token. 
    /// @dev Reward tokens are automatically staked back into the veTetu
    function claimVeTetuRewards(uint256 _tokenId) external onlyOperators returns (uint256 amount) {
        amount = tetuRewardsDistributor.claim(_tokenId);
        emit ClaimVeTetuRewards(_tokenId, amount);
    }

    /// @notice Claim rewards for a set of veTetu tokens. 
    /// @dev Reward tokens are automatically staked back into the veTetu
    function claimManyVeTetuRewards(uint256[] memory _tokenIds) external onlyOperators returns (bool) {
        emit ClaimManyVeTetuRewards(_tokenIds);
        return tetuRewardsDistributor.claimMany(_tokenIds);
    }

    /// @notice The current claimable rewards from a veTetu token
    /// @dev Note may be stale if vetetu.checkpoint() hasn't been called recently.
    function claimableVeTetuRewards(uint256 _tokenId) external view returns (uint256) {
        return tetuRewardsDistributor.claimable(_tokenId);
    }

    // ****************** //
    //   veTetu Voting   //
    // ***************** //

    /// @notice Set the delegate for snapshot governance voting.
    /// @dev Governance voting happens on snapshot offchain, which can be delegated to another contract/EOA
    function setDelegate(bytes32 _id, address _delegate) external onlyOperators {
        emit SetDelegate(_delegate);
        snapshotDelegator.setDelegate(_id, _delegate);
    }

    /// @notice Clear the delegate for snapshot governance voting.
    function clearDelegate(bytes32 _id) external onlyOperators {
        emit ClearDelegate();
        snapshotDelegator.clearDelegate(_id);
    } 

    /// @notice Use voting power to vote for a particular TETU vault
    function vote(uint256 tokenId, address[] calldata _vaultVotes, int256[] calldata _weights) external onlyOperators {
        emit Voted(tokenId);
        tetuVoter.vote(tokenId, _vaultVotes, _weights);
    }

    /// @notice Revoke the vote for a particular veTetu token.
    function resetVote(uint256 tokenId) external onlyOperators {
        emit ResetVote(tokenId);
        tetuVoter.reset(tokenId);
    }

    // ********************* //
    // veTetu Platform Voter //
    // ********************* //

    /// @dev Vote for multiple attributes in one call.
    function platformVoteBatch(
        uint256 _tokenId,
        ITetuPlatformVoter.AttributeType[] calldata _types,
        uint256[] calldata _values,
        address[] calldata _targets
    ) external onlyOperators {
        emit PlatformVoteBatch(_tokenId);
        tetuPlatformVoter.voteBatch(
            _tokenId,
            _types,
            _values,
            _targets
        );
    }

    /// @dev Vote for given parameter using a vote power of given tokenId. Reset previous vote.
    function platformVote(uint256 _tokenId, ITetuPlatformVoter.AttributeType _type, uint256 _value, address _target) external onlyOperators {
        emit PlatformVote(_tokenId);
        tetuPlatformVoter.vote(_tokenId, _type, _value, _target);
    }

    /// @dev Remove all votes for given tokenId.
    function platformResetVote(uint256 _tokenId, uint256[] memory _types, address[] memory _targets) external onlyOperators {
        emit PlatformVoteReset(_tokenId);
        tetuPlatformVoter.reset(_tokenId, _types, _targets);
    }

    // **************** //
    //   Admin Control  //
    // **************** //

    /// @notice Transfer a token to a designated address.
    /// @dev This can be used to recover tokens, but also to transfer staked $sdToken gauge tokens, reward tokens to the DAO/another address/HW/etc
    function transferToken(address _token, address _to, uint256 _amount) external onlyOperators {
        emit TokenTransferred(_token, _to, _amount);
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    /// @notice Increase an allowance such that a spender can pull a token. 
    /// @dev Required for future integration such that contracts can pull the staked $sdToken gauge tokens, reward tokens, etc.
    function increaseTokenAllowance(address _token, address _spender, uint256 _amount) external onlyOperators {
        IERC20Upgradeable(_token).safeIncreaseAllowance(_spender, _amount);
    }

    /// @notice Decrease an allowance.
    function decreaseTokenAllowance(address _token, address _spender, uint256 _amount) external onlyOperators {
        IERC20Upgradeable(_token).safeDecreaseAllowance(_spender, _amount);
    }

    /// @notice Transfer an NFT tokenId to a designated address.
    /// @dev Required to transfer veTetu NFTs DAO/another address/HW/etc
    function transferVeTetu(address _to, uint256 _tokenId) external onlyOperators {
        emit VeTetuTransferred(_to, _tokenId);
        veTetu.safeTransferFrom(address(this), _to, _tokenId);
    }

    /// @notice Gives permission to to to transfer tokenId NFT to another account. The approval is cleared when the token is transferred.
    /// @dev Required for future integration such that contracts can pull the veTetu NFTs
    function approveVeTetu(address _spender, uint256 _tokenId) external onlyOperators {
        veTetu.approve(_spender, _tokenId);
    }

    /// @notice Approve or remove operator as an operator for the caller for all token id's
    /// @dev Required for future integration such that contracts can pull the veTetu NFTs
    function setVeTetuApprovalForAll(address _spender, bool _approved) external onlyOperators {
        veTetu.setApprovalForAll(_spender, _approved);
    }

    /// @notice Callback to receive veTETU ERC721's
    /// @dev Will reject any other ERC721's
    function onERC721Received(address /*operator*/, address /*from*/, uint256 tokenId, bytes calldata /*data*/) external returns (bytes4) {
        if (msg.sender != address(veTetu)) revert CommonEventsAndErrors.InvalidToken(msg.sender);
        emit VeTetuNFTReceived(tokenId);
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}