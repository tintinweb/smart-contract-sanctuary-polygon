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
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
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
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
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
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ALVA is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("ALVA", "ALVA");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _mint(msg.sender, 200000000 * 1e18);
    }

    // function to view balance of a user
    function balanceOfUser(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ALVA.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

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

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract veALVA is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for ERC20;

    /// @notice Emitted when a lockup is created
    event LockupCreated(
        address indexed provider,
        int128 amount,
        uint256 end,
        uint256 ts
    );

    /// @notice Emitted when an existing lockup is changed
    event LockupUpdated(
        address indexed provider,
        int128 oldAmount,
        uint256 oldEnd,
        int128 amount,
        uint256 end,
        uint256 ts
    );

    /// @notice Emitted when an existing lockup's lock time increased
    event LockupTimeUpdated(
        address indexed provider,
        int128 amount,
        uint256 end,
        uint256 ts
    );

    /// @notice Emitted when an infinite locking takes place
    event LockupInfinite(address indexed provider, int128 amount, uint256 ts);

    /// @notice Emitted when a user withdraws from an expired lockup
    event Withdraw(address indexed provider, uint256 value, uint256 ts);

    /// @notice ERC20 parameters
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /// @notice Definition of a week
    uint256 private constant WEEK = 7 days;

    /// @notice Maximum lock time
    uint256 public constant MAX_LOCK_TIME = 4 * 365 * 86400; // 4 years

    /// @notice Per user Checkpoints defining voting power of each user
    mapping(address => Checkpoint[]) private _userCheckpoints;

    /// @notice userEpoch important for fetching previous block per user voting power
    mapping(address => uint256) public userEpoch;

    /// @notice userEpochI important for fetching previous block per user voting power for infinite locking
    mapping(address => uint256) public userEpochI;

    /// @notice Global Checkpoints part of the equation to define combined voting power of all users.
    Checkpoint[] private _globalCheckpoints;

    /// @notice globalEpoch important for fetching previous block combined voting power
    uint256 public globalEpoch;

    /// @notice globalEpoch important for fetching previous block combined voting power for infinite locking
    uint256 public globalEpochI;

    /// @notice Total number of users who locked alva tokens
    uint256 private count;

    /// @notice Lockup mapping for each user
    mapping(address => Lockup) public lockups;

    /**
     * @notice slopeChanges part of the equation to define combined voting power of
     * all users. Slope changes always complement only the latest global Checkpoint and are
     * not used when fetching combined voting power of previous blocks.
     */
    mapping(uint256 => int128) public slopeChanges;

    /// @notice Token that is locked up in return for vote escrowed token
    ERC20 stakingToken;

    /// @notice Checkpoint structure representing linear voting power decay
    struct Checkpoint {
        int128 bias;
        int128 slope;
        uint256 ts;
        uint256 blk;
    }

    /// @notice Stores token lockup details
    struct Lockup {
        int128 amount;
        uint256 end;
    }

    /// @notice Store details for the amount sum of non-decaying veALVA for the user till block number
    struct NonDecayCheckpoint {
        uint256 blockNumber;
        int128 sum;
    }

    mapping(address => NonDecayCheckpoint[]) private _userNonDecayCheckpoints;

    NonDecayCheckpoint[] private _allUsersNonDecayCheckpoints;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _stakingToken) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        stakingToken = ERC20(_stakingToken);

        // Derive the name from the staking token
        _name = string(
            bytes.concat(bytes("Vote Escrow"), " ", bytes(stakingToken.name()))
        );

        // Derive the symbol from the staking token
        _symbol = string(
            bytes.concat(bytes("ve"), bytes(stakingToken.symbol()))
        );

        // Use the same decimals as the staking token
        _decimals = stakingToken.decimals();

        _allUsersNonDecayCheckpoints.push(
            NonDecayCheckpoint({blockNumber: block.number, sum: 0})
        );

        globalEpochI = 0;

        // Push an initial global checkpoint
        _globalCheckpoints.push(
            Checkpoint({
                bias: 0,
                slope: 0,
                ts: block.timestamp,
                blk: block.number
            })
        );
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    // Total supply for a single user
    function balanceOf(address _account) public view returns (uint256) {
        // Defining two variable to store the voting power of the user
        uint256 finiteBias;
        uint256 infiniteBias;

        // Code for finite bias for the user
        uint256 currentUserEpoch = userEpoch[_account];
        if (currentUserEpoch == 0) {
            finiteBias = 0;
        } else {
            Checkpoint memory lastCheckpoint = _userCheckpoints[_account][
                currentUserEpoch
            ];

            // Calculate the bias based on the last bias and the slope over the difference
            // in time between the last checkpoint timestamp and the current block timestamp;
            lastCheckpoint.bias -= (lastCheckpoint.slope *
                SafeCast.toInt128(int256(block.timestamp - lastCheckpoint.ts)));

            finiteBias = SafeCast.toUint256(max(lastCheckpoint.bias, 0));
        }

        // Code for the infinite bias for the user
        // Get the current block
        uint256 currentUserEpochI = userEpochI[_account];

        // Check if the currentUserEpochI is zero
        if (currentUserEpochI == 0) {
            infiniteBias = 0;
        } else {
            NonDecayCheckpoint
                memory lastCheckpointI = _userNonDecayCheckpoints[_account][
                    currentUserEpochI
                ];

            infiniteBias = SafeCast.toUint256(lastCheckpointI.sum);
        }

        return (finiteBias + infiniteBias);
    }

    // Total supply of the veAlva
    function totalSupply() public view returns (uint256) {
        // Defining two variables for the finite and infinite voting power supply
        uint256 finiteSupply;
        uint256 infiniteSupply;

        // Code for finite voting power supply
        if (_globalCheckpoints.length == 0) {
            finiteSupply = 0;
        } else {
            Checkpoint memory lastCheckpoint = _globalCheckpoints[globalEpoch];
            finiteSupply = _supplyAtFinite(lastCheckpoint, block.timestamp);
        }

        // Code for infinite voting power supply
        if (_allUsersNonDecayCheckpoints.length == 0) {
            infiniteSupply = 0;
        } else {
            NonDecayCheckpoint
                memory lastCheckpointI = _allUsersNonDecayCheckpoints[
                    globalEpochI
                ];

            infiniteSupply = SafeCast.toUint256(lastCheckpointI.sum);
        }

        return (finiteSupply + infiniteSupply);
    }

    function checkpoints(
        address _account,
        uint32 _pos
    ) public view virtual returns (Checkpoint memory) {
        return _userCheckpoints[_account][_pos];
    }

    function checkpointsInfinite(
        address _account,
        uint32 _pos
    ) public view virtual returns (NonDecayCheckpoint memory) {
        return _userNonDecayCheckpoints[_account][_pos];
    }

    function numCheckpoints(
        address _account
    ) public view virtual returns (uint256) {
        return _userCheckpoints[_account].length;
    }

    function numCheckpointsInfinite(
        address _account
    ) public view virtual returns (uint256) {
        return _userNonDecayCheckpoints[_account].length;
    }

    function getLastCheckpoint(
        address _account
    ) public view returns (Checkpoint memory) {
        return
            _userCheckpoints[_account][_userCheckpoints[_account].length - 1];
    }

    function getLastCheckpointInfinite(
        address _account
    ) public view returns (NonDecayCheckpoint memory) {
        return
            _userNonDecayCheckpoints[_account][
                _userNonDecayCheckpoints[_account].length - 1
            ];
    }

    function globalCheckpoints(
        uint32 pos
    ) public view returns (Checkpoint memory) {
        return _globalCheckpoints[pos];
    }

    function globalCheckpointsInfinite(
        uint32 pos
    ) public view returns (NonDecayCheckpoint memory) {
        return _allUsersNonDecayCheckpoints[pos];
    }

    function numGlobalCheckpoints() public view returns (uint256) {
        return _globalCheckpoints.length;
    }

    function numGlobalCheckpointsInfinite() public view returns (uint256) {
        return _allUsersNonDecayCheckpoints.length;
    }

    function getLastGlobalCheckpoint() public view returns (Checkpoint memory) {
        return _globalCheckpoints[_globalCheckpoints.length - 1];
    }

    function getLastGlobalCheckpointInfinite()
        public
        view
        returns (NonDecayCheckpoint memory)
    {
        return
            _allUsersNonDecayCheckpoints[
                _allUsersNonDecayCheckpoints.length - 1
            ];
    }

    function getVotes(address _account) public view returns (uint256) {
        return balanceOf(_account);
    }

    /// @dev Gets the current lockup for `_account`
    function getLockup(address _account) public view returns (Lockup memory) {
        return lockups[_account];
    }

    function getNumOfAlvaLockers() public view returns (uint256) {
        return count;
    }

    /// @dev Get the address `_account` is currently delegating to.
    function delegates(address _account) public view virtual returns (address) {
        revert("Delegation is not supported");
    }

    /// @dev Delegate votes from the sender to `delegatee`.
    function delegate(address delegatee) public virtual {
        // TODO a future upgrade may support delegation
        revert("Delegation is not supported");
    }

    /// @dev Delegates votes from signer to `delegatee`
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 end,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        revert("Delegation by signature is not supported");
    }

    /**
     * @dev Deposits staking token and mints new veTokens according to the lockup length
     * @param _amount Amount of staking token to deposit
     * @param _end Lockup end time
     * @param _account Account for which lockup is created
     * @param _isInfinite True for infinite lockup and False for finite lockup
     */
    function lockup(
        address _account,
        uint256 _amount,
        uint256 _end,
        bool _isInfinite
    ) public virtual {
        if (_isInfinite == false) {
            // end is rounded down to week time resolution
            _end = _floorToWeek(_end);
            Lockup memory oldLockup = lockups[_account];

            // Check to confirm the new user lockup to increase the count
            if (oldLockup.end == 0 && oldLockup.amount == 0) {
                if (_userNonDecayCheckpoints[_account].length == 0) count++;
            }

            // Check end w.r.t. current block timestamp
            require(
                _end > block.timestamp,
                "End must be greater than the current block timestamp"
            );

            // Check end w.r.t. current end
            if (oldLockup.end > 0 && _end >= oldLockup.end) {
                revert("End must be greater than or equal to the current end");
            }

            // Validate end
            require(
                _end - block.timestamp <= MAX_LOCK_TIME,
                "End must be before maximum lockup time"
            );

            int128 amount = SafeCast.toInt128(int256(_amount));

            // Check amount is greater than or equal to current amount
            require(
                amount >= oldLockup.amount,
                "Amount must be greater than or equal to current amount"
            );

            // Old lockup amount will be 0 if no existing lockup, if this is an increase of the
            // lockup amount, then _amount can be 0
            Lockup memory newLockup = Lockup({amount: amount, end: _end});
            lockups[_account] = newLockup;

            // Transfer amount from the user to this contract
            stakingToken.transferFrom(
                msg.sender,
                address(this),
                SafeCast.toUint256(int256(amount))
            );

            if (oldLockup.end > 0) {
                // This is an extension of an existing lockup
                emit LockupUpdated(
                    _account,
                    oldLockup.amount,
                    oldLockup.end,
                    newLockup.amount,
                    newLockup.end,
                    block.timestamp
                );
            } else {
                emit LockupCreated(
                    _account,
                    newLockup.amount,
                    newLockup.end,
                    block.timestamp
                );
            }

            _writeUserCheckpoint(_account, oldLockup, newLockup);
        } else {
            int128 amount = SafeCast.toInt128(int256(_amount));
            uint256 blockNumber = block.number;

            // Update checkpoint
            if (_userNonDecayCheckpoints[_account].length > 0) {
                // Amount extensions
                require(amount > 0, "Amount must be greater than zero.");

                // Checkpoint for the user and allUser of infinite locking
                NonDecayCheckpoint memory _userNonDecayCheckpoint1;
                NonDecayCheckpoint memory _allUsersNonDecayCheckpoint1;

                // Update checkpoint for the user
                _userNonDecayCheckpoint1.blockNumber = blockNumber;
                _userNonDecayCheckpoint1.sum =
                    _userNonDecayCheckpoints[_account][
                        _userNonDecayCheckpoints[_account].length - 1
                    ].sum +
                    (2 * amount);

                // Push the user checkpoint to the user infinite locking checkpoint array
                _userNonDecayCheckpoints[_account].push(
                    _userNonDecayCheckpoint1
                );

                // Increase user epoch value by one each time new infinite deposit is done by user
                userEpochI[_account] = userEpochI[_account] + 1;

                // Add new all user checkpoint for the recent global epoch for the infinite locking
                _allUsersNonDecayCheckpoint1.blockNumber = blockNumber;
                _allUsersNonDecayCheckpoint1.sum =
                    _allUsersNonDecayCheckpoints[
                        _allUsersNonDecayCheckpoints.length - 1
                    ].sum +
                    (2 * amount);

                // Push the allUser checkpoint to the all user infinite locking checkpoint array
                _allUsersNonDecayCheckpoints.push(_allUsersNonDecayCheckpoint1);

                // Increase user epoch value by one each time new infinite deposit is done by corresponding user
                globalEpochI = globalEpochI + 1;

                // Event for infinite locking
                emit LockupInfinite(
                    _account,
                    _userNonDecayCheckpoints[_account][
                        _userNonDecayCheckpoints[_account].length - 1
                    ].sum,
                    block.timestamp
                );
            } else {
                Lockup memory oldLockup2 = lockups[_account];

                // Check to confirm the new user lockup to increase the count - both finite and infinite lockups are checked
                if (oldLockup2.end == 0 && oldLockup2.amount == 0) {
                    if (_userNonDecayCheckpoints[_account].length == 0) count++;
                }

                // Checkpoints for the user and allUser of infinite locking
                NonDecayCheckpoint memory _userNonDecayCheckpoint2;
                NonDecayCheckpoint memory _allUsersNonDecayCheckpoint2;

                // Update checkpoint for the user
                _userNonDecayCheckpoint2.blockNumber = blockNumber;
                _userNonDecayCheckpoint2.sum = (2 * amount); // For the first time, we do not have a previous checkpoint to retrieve any value

                uint256 userCurrentEpoch = userEpochI[_account];
                if (userCurrentEpoch == 0) {
                    _userNonDecayCheckpoints[_account].push(
                        NonDecayCheckpoint({
                            blockNumber: blockNumber - 5,
                            sum: 0
                        })
                    );
                }

                // Push the initial user checkpoint for the particular user checkpoint array
                _userNonDecayCheckpoints[_account].push(
                    _userNonDecayCheckpoint2
                );

                // Increase user epoch value by one each time new infinite deposit is done by user
                userEpochI[_account] = userCurrentEpoch + 1;

                // Checkpoint for all users (block number and sum entries)
                _allUsersNonDecayCheckpoint2.blockNumber = blockNumber;

                // For consecutive checkpoint, for the all users checkpoint for the infinite locking
                _allUsersNonDecayCheckpoint2.sum =
                    _allUsersNonDecayCheckpoints[
                        _allUsersNonDecayCheckpoints.length - 1
                    ].sum +
                    (2 * amount);

                // Push this checkpoint to all user non-decay checkpoint array
                _allUsersNonDecayCheckpoints.push(_allUsersNonDecayCheckpoint2);

                // Increase user epoch value by one each time new infinite deposit is done by any user
                globalEpochI = globalEpochI + 1;

                // Event for infinite locking
                emit LockupInfinite(
                    _account,
                    _userNonDecayCheckpoints[_account][
                        _userNonDecayCheckpoints[_account].length - 1
                    ].sum,
                    block.timestamp
                );
            }

            // Transfer the amount from user to 'DEAD' address
            stakingToken.transferFrom(
                msg.sender,
                0x000000000000000000000000000000000000dEaD,
                SafeCast.toUint256(int256(amount))
            );
        }
    }

    /// @dev increase unlock time function for user's lockup
    function increase_unlock_time(uint256 _end) public {
        // Rounded 'unlock_time' in the form of weeks
        _end = _floorToWeek(_end);

        address _addr = msg.sender;

        // Check if sender is not a contract
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        require(size == 0, "Caller is smart contract.");

        // Get lock for the user
        Lockup memory oldLockup = lockups[_addr];

        // Lock expired
        require(oldLockup.end > block.timestamp, "Lock expired.");

        // Nothing is locked
        require(oldLockup.amount > 0, "Nothing is locked.");

        // Can only increase lock duration
        require(_end > oldLockup.end, "Can only increase lock duration.");

        // Voting lock can be 4 years max
        require(
            _end <= block.timestamp + MAX_LOCK_TIME,
            "Voting lock can be 4 years max"
        );

        // Increase the amount of the lock time for the user: Assign oldLockup to newLockup and update newLockup.end with new 'end'
        Lockup memory newLockup = oldLockup;
        if (_end != 0) {
            newLockup.end = _end;
        }

        lockups[_addr] = newLockup;

        // Call for the write user checkpoint
        _writeUserCheckpoint(_addr, oldLockup, newLockup);

        // Event
        emit LockupTimeUpdated(
            _addr,
            newLockup.amount,
            newLockup.end,
            block.timestamp
        );
    }

    /// @dev Withdraw all tokens from an expired lockup.
    function withdraw() public {
        Lockup memory oldLockup = Lockup({
            end: lockups[msg.sender].end,
            amount: lockups[msg.sender].amount
        });

        // Check for the expiration time
        require(block.timestamp >= oldLockup.end, "Lockup must be expired");

        // Check for the locking amount
        require(oldLockup.amount > 0, "Lockup has no tokens");

        // Reduce the expiration time and amount of the user to zero
        Lockup memory newLockup = Lockup({end: 0, amount: 0});

        // Assign above lockup to the users lockup
        lockups[msg.sender] = newLockup;

        // Check of NonDecayCheckpoint for user for decreasing count
        if (_userNonDecayCheckpoints[msg.sender].length == 0) count--;

        // Transfer amount of finite locking for the user
        uint256 amount = SafeCast.toUint256(oldLockup.amount);
        stakingToken.safeTransfer(msg.sender, amount);

        // Write checkpoint after transfering locking amount to the user
        _writeUserCheckpoint(msg.sender, oldLockup, newLockup);

        // Emit event for the withdraw
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    /// @dev Public function to trigger global checkpoint: Fill in the missing global checkpoints using slopeChanges -
    //  which always pertain only to the latest global checkpoint.
    function checkpoint() external {
        _writeGlobalCheckpoint(0, 0);
    }

    /**
     * @dev Write user checkpoint. User checkpoints are used to calculate the users vote balance for current and historical blocks.
     * @param _oldLockup Users lockup prior to the change that triggered the checkpoint
     * @param _newLockup Users new lockup
     */
    function _writeUserCheckpoint(
        address _account,
        Lockup memory _oldLockup,
        Lockup memory _newLockup
    ) private {
        Checkpoint memory oldCheckpoint;
        Checkpoint memory newCheckpoint;

        int128 oldSlopeDelta = 0;
        int128 newSlopeDelta = 0;

        if (_oldLockup.end > block.timestamp && _oldLockup.amount > 0) {
            // Old checkpoint still active, calculates its slope and bias
            oldCheckpoint.slope =
                _oldLockup.amount /
                SafeCast.toInt128(int256(MAX_LOCK_TIME));
            oldCheckpoint.bias =
                oldCheckpoint.slope *
                SafeCast.toInt128(int256(_oldLockup.end - block.timestamp));
        }

        if (_newLockup.end > block.timestamp && _newLockup.amount > 0) {
            // New lockup also active, calculate its slope and bias
            newCheckpoint.slope =
                _newLockup.amount /
                SafeCast.toInt128(int256(MAX_LOCK_TIME));
            newCheckpoint.bias =
                newCheckpoint.slope *
                SafeCast.toInt128(int256(_newLockup.end - block.timestamp));
        }

        uint256 userCurrentEpoch = userEpoch[_account];
        if (userCurrentEpoch == 0) {
            // First user epoch, push first checkpoint
            _userCheckpoints[_account].push(oldCheckpoint);
        }

        newCheckpoint.ts = block.timestamp;
        newCheckpoint.blk = block.number;
        userEpoch[_account] = userCurrentEpoch + 1;

        // Push second checkpoint
        _userCheckpoints[_account].push(newCheckpoint);

        oldSlopeDelta = slopeChanges[_oldLockup.end];
        if (_newLockup.end != 0) {
            if (_newLockup.end == _oldLockup.end) {
                // Lockup dates are the same end time, slope delta is the same
                newSlopeDelta = oldSlopeDelta;
            } else {
                newSlopeDelta = slopeChanges[_newLockup.end];
            }
        }

        _writeGlobalCheckpoint(
            newCheckpoint.slope - oldCheckpoint.slope,
            newCheckpoint.bias - oldCheckpoint.bias
        );

        /**
         * Schedule the slope changes. There is a possible code simplification where
         * we always undo the old checkpoint slope change and always apply the new
         * checkpoint slope change. In the interest of gas optimization the code is
         * slightly more complicated.
         */
        // old lockup still active and needs slope change adjustment: First part of the gas optimization
        if (_oldLockup.end > block.timestamp) {
            // This is an adjustment of the slope: oldSlopeDelta was <something> - oldCheckpoint.slope,
            // so we cancel/undo that
            oldSlopeDelta = oldSlopeDelta + oldCheckpoint.slope;

            // Gas optimize it so another storage access for _newLockup is not required
            if (_newLockup.end == _oldLockup.end) {
                // It was a new deposit, not extension
                oldSlopeDelta = oldSlopeDelta - newCheckpoint.slope;
            }
            slopeChanges[_oldLockup.end] = oldSlopeDelta;
        }

        if (_newLockup.end > block.timestamp) {
            // (Second part of gas optimization): it was an extension
            if (_newLockup.end > _oldLockup.end) {
                newSlopeDelta = newSlopeDelta - newCheckpoint.slope;
                slopeChanges[_newLockup.end] = newSlopeDelta;
            }
        }
    }

    /**
     * @dev Write a global checkpoints. Global checkpoints are used to calculate the total supply for current and historical blocks.
     * @param userSlopeDelta Change in slope that triggered this checkpoint
     * @param userBiasDelta Change in bias that triggered this checkpoint
     */
    function _writeGlobalCheckpoint(
        int128 userSlopeDelta,
        int128 userBiasDelta
    ) private {
        Checkpoint memory lastCheckpoint;
        if (globalEpoch > 0) {
            lastCheckpoint = _globalCheckpoints[globalEpoch];
        } else {
            lastCheckpoint = Checkpoint({
                bias: 0,
                slope: 0,
                ts: block.timestamp,
                blk: block.number
            });
        }

        Checkpoint memory initialLastCheckpoint = Checkpoint({
            bias: 0,
            slope: 0,
            ts: lastCheckpoint.ts,
            blk: lastCheckpoint.blk
        });

        uint256 blockSlope = 0; // dblock/dt
        if (block.timestamp > lastCheckpoint.ts) {
            // Scaled up
            blockSlope =
                ((block.number - lastCheckpoint.blk) * 1e18) /
                (block.timestamp - lastCheckpoint.ts);
        }

        uint256 lastCheckpointTimestamp = lastCheckpoint.ts;
        uint256 iterativeTime = _floorToWeek(lastCheckpointTimestamp);

        /* Iterate from last global checkpoint in one week interval steps until present
         * time is reached. Fill in the missing global checkpoints using slopeChanges - which
         * always pertain only to the latest global checkpoint.
         */
        for (uint256 i = 0; i < 255; i++) {
            // 5 years
            iterativeTime = iterativeTime + WEEK;

            int128 slopeDelta = 0;
            if (iterativeTime > block.timestamp) {
                // Current epoch
                iterativeTime = block.timestamp;
            } else {
                slopeDelta = slopeChanges[iterativeTime];
            }

            // Calculate the change in bias for the current epoch
            int128 biasDelta = lastCheckpoint.slope *
                SafeCast.toInt128(
                    int256((iterativeTime - lastCheckpointTimestamp))
                );

            // The bias can be below 0
            lastCheckpoint.bias = max(lastCheckpoint.bias - biasDelta, 0);

            // The slope should never be below 0 but added for safety
            lastCheckpoint.slope = max(lastCheckpoint.slope + slopeDelta, 0);
            lastCheckpoint.ts = iterativeTime;
            lastCheckpointTimestamp = iterativeTime;
            lastCheckpoint.blk =
                initialLastCheckpoint.blk +
                ((blockSlope * (iterativeTime - initialLastCheckpoint.ts)) /
                    1e18); // Scale back down

            globalEpoch += 1;

            if (iterativeTime == block.timestamp) {
                lastCheckpoint.blk = block.number;

                // Adjust the last checkpoint for any delta from the user
                lastCheckpoint.slope = max(
                    lastCheckpoint.slope + userSlopeDelta,
                    0
                );

                lastCheckpoint.bias = max(
                    lastCheckpoint.bias + userBiasDelta,
                    0
                );

                _globalCheckpoints.push(lastCheckpoint);
                break;
            } else {
                _globalCheckpoints.push(lastCheckpoint);
            }
        }
    }

    /**
     * @dev Binary search (bisection) to find epoch closest to block.
     * @param _block Find the most recent point history before this block
     * @param _maxEpoch Maximum epoch
     * @return uint256 The most recent epoch before the block
     */
    function _findEpoch(
        Checkpoint[] memory _checkpoints,
        uint256 _block,
        uint256 _maxEpoch
    ) internal pure returns (uint256) {
        uint256 minEpoch = 0;
        uint256 maxEpoch = _maxEpoch;
        for (uint256 i = 0; i < 128; i++) {
            if (minEpoch >= maxEpoch) break;
            uint256 mid = (minEpoch + maxEpoch + 1) / 2;
            if (_checkpoints[mid].blk <= _block) {
                minEpoch = mid;
            } else {
                maxEpoch = mid - 1;
            }
        }
        return minEpoch;
    }

    /**
     * @dev Binary search (bisection) to find epoch closest to block.
     * @param _block Find the most recent point history before this block
     * @param _maxEpoch Maximum epoch
     * @return uint256 The most recent epoch before the block
     */
    function _findEpochI(
        NonDecayCheckpoint[] memory _checkpoints,
        uint256 _block,
        uint256 _maxEpoch
    ) internal pure returns (uint256) {
        uint256 minEpoch = 0;
        uint256 maxEpoch = _maxEpoch;
        for (uint256 i = 0; i < 128; i++) {
            if (minEpoch >= maxEpoch) break;
            uint256 mid = (minEpoch + maxEpoch + 1) / 2;
            if (_checkpoints[mid].blockNumber <= _block) {
                minEpoch = mid;
            } else {
                maxEpoch = mid - 1;
            }
        }
        return minEpoch;
    }

    /**
     * @dev Retrieve the number of votes for `_account` at the end of `_blockNumber`.
     * This method is required for compatibility with the OpenZeppelin governance ERC20Votes.
     * Requirements:
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(
        address _account,
        uint256 _blockNumber
    ) external view returns (uint256) {
        uint256 finiteSupply = balanceOfAtFinite(_account, _blockNumber);
        uint256 infiniteSupply = balanceOfAtInfinite(_account, _blockNumber);

        return (finiteSupply + infiniteSupply);
    }

    /**
     * @dev Gets a users votingWeight at a given blockNumber for infinite locking
     * @param _account User for which to return the balance
     * @param _blockNumber Block at which to calculate balance
     * @return uint256 Balance of user voting power.
     */
    function balanceOfAtInfinite(
        address _account,
        uint256 _blockNumber
    ) public view returns (uint256) {
        require(_blockNumber <= block.number, "Block number is in the future");

        // Get most recent user Checkpoint to block
        uint256 recentUserEpochI = _findEpochI(
            _userNonDecayCheckpoints[_account],
            _blockNumber,
            userEpochI[_account] // Max epoch
        );

        if (recentUserEpochI == 0) {
            return 0;
        }

        NonDecayCheckpoint memory checkpoint0 = _userNonDecayCheckpoints[
            _account
        ][recentUserEpochI];

        return SafeCast.toUint256(checkpoint0.sum);
    }

    /**
     * @dev Gets a users votingWeight at a given blockNumber
     * @param _account User for which to return the balance
     * @param _blockNumber Block at which to calculate balance
     * @return uint256 Balance of user voting power.
     */
    function balanceOfAtFinite(
        address _account,
        uint256 _blockNumber
    ) public view returns (uint256) {
        require(_blockNumber <= block.number, "Block number is in the future");

        // Get most recent user Checkpoint to block
        uint256 recentUserEpoch = _findEpoch(
            _userCheckpoints[_account],
            _blockNumber,
            userEpoch[_account] // Max epoch
        );

        if (recentUserEpoch == 0) {
            return 0;
        }

        Checkpoint memory userPoint = _userCheckpoints[_account][
            recentUserEpoch
        ];

        // Get most recent global Checkpoint to block
        uint256 recentGlobalEpoch = _findEpoch(
            _globalCheckpoints,
            _blockNumber,
            globalEpoch // Max epoch
        );

        Checkpoint memory checkpoint0 = _globalCheckpoints[recentGlobalEpoch];

        // Calculate delta (block & time) between checkpoint and target block
        // Allowing us to calculate the average seconds per block between
        // the two points
        uint256 dBlock = 0;
        uint256 dTime = 0;
        if (recentGlobalEpoch < globalEpoch) {
            Checkpoint memory checkpoint1 = _globalCheckpoints[
                recentGlobalEpoch + 1
            ];
            dBlock = checkpoint1.blk - checkpoint0.blk;
            dTime = checkpoint1.ts - checkpoint0.ts;
        } else {
            dBlock = block.number - checkpoint0.blk;
            dTime = block.timestamp - checkpoint0.ts;
        }

        // (Deterministically) Estimate the time at which block _blockNumber was mined
        uint256 blockTime = checkpoint0.ts;

        if (dBlock != 0) {
            blockTime += (dTime * (_blockNumber - checkpoint0.blk)) / dBlock;
        }

        // Current Bias = most recent bias - (slope * time since update)
        userPoint.bias -= (userPoint.slope *
            SafeCast.toInt128(int256(blockTime - userPoint.ts)));
        if (userPoint.bias >= 0) {
            return SafeCast.toUint256(userPoint.bias);
        } else {
            return 0;
        }
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`.
     * This method is required for compatibility with the OpenZeppelin governance ERC20Votes.
     * Requirements:
     * - `_blockNumber` must have been already mined
     * @param _blockNumber Block at which to calculate total supply
     * @return uint256 Total supply at the given block
     */
    function getPastTotalSupply(
        uint256 _blockNumber
    ) external view returns (uint256) {
        uint256 finiteSupply = totalSupplyAtFinite(_blockNumber);
        uint256 infiniteSupply = totalSupplyAtInfinite(_blockNumber);

        return (finiteSupply + infiniteSupply);
    }

    /**
     * @dev Calculates total supply of votingWeight at a given blockNumber
     * @param _blockNumber Block number at which to calculate total supply
     * @return totalSupply of voting token weight at the given blockNumber for infinite locking
     */
    function totalSupplyAtInfinite(
        uint256 _blockNumber
    ) public view returns (uint256) {
        require(_blockNumber <= block.number, "Block number is in the future");

        // Get most recent global Checkpoint to block
        uint256 recentGlobalEpochI = _findEpochI(
            _allUsersNonDecayCheckpoints,
            _blockNumber,
            globalEpochI // Max epoch
        );

        if (recentGlobalEpochI == 0) {
            return 0;
        }

        NonDecayCheckpoint memory checkpoint0 = _allUsersNonDecayCheckpoints[
            recentGlobalEpochI
        ];

        return SafeCast.toUint256(checkpoint0.sum);
    }

    /**
     * @dev Calculates total supply of votingWeight at a given blockNumber
     * @param _blockNumber Block number at which to calculate total supply
     * @return totalSupply of voting token weight at the given blockNumber
     */
    function totalSupplyAtFinite(
        uint256 _blockNumber
    ) public view returns (uint256) {
        require(_blockNumber <= block.number, "Block number is in the future");

        // Get most recent global Checkpoint to block
        uint256 recentGlobalEpoch = _findEpoch(
            _globalCheckpoints,
            _blockNumber,
            globalEpoch // Max epoch
        );

        Checkpoint memory checkpoint0 = _globalCheckpoints[recentGlobalEpoch];

        if (checkpoint0.blk > _blockNumber) {
            return 0;
        }

        uint256 dTime = 0;
        if (recentGlobalEpoch < globalEpoch) {
            Checkpoint memory checkpoint1 = _globalCheckpoints[
                recentGlobalEpoch + 1
            ];
            if (checkpoint0.blk != checkpoint1.blk) {
                /* To estimate how much time has passed since the last checkpoint get the number
                 * of blocks since the last checkpoint. And multiply that by the average time per
                 * block of the 2 neighboring checkpoints of said _blockNumber
                 */
                dTime =
                    ((_blockNumber - checkpoint0.blk) *
                        (checkpoint1.ts - checkpoint0.ts)) /
                    (checkpoint1.blk - checkpoint0.blk);
            }
        } else if (checkpoint0.blk != block.number) {
            /* To estimate how much time has passed since the last checkpoint get the number
             * of blocks since the last checkpoint. And multiply that by the average time per
             * block since the last checkpoint and present blockchain state.
             */
            dTime =
                ((_blockNumber - checkpoint0.blk) *
                    (block.timestamp - checkpoint0.ts)) /
                (block.number - checkpoint0.blk);
        }
        // If code doesn't enter any of the above if conditions latest _blockNumber was passed
        // to the function and dTime is correctly set to 0

        // Now dTime contains info on how far are we beyond point
        return _supplyAtFinite(checkpoint0, checkpoint0.ts + dTime);
    }

    /**
     * @dev Calculates total supply of votingWeight at a given time _t
     * @param _checkpoint Most recent point before time _t
     * @param _time Time at which to calculate supply
     * @return totalSupply at given time
     */
    function _supplyAtFinite(
        Checkpoint memory _checkpoint,
        uint256 _time
    ) internal view returns (uint256) {
        Checkpoint memory lastCheckpoint = _checkpoint;

        // Floor the timestamp to weekly interval
        uint256 iterativeTime = _floorToWeek(lastCheckpoint.ts);

        // Iterate through all weeks between _checkpoint & _time to account for slope changes
        for (uint256 i = 0; i < 255; i++) {
            iterativeTime = iterativeTime + WEEK;
            int128 dSlope = 0;
            // If week end is after timestamp, then truncate & leave dSlope to 0
            if (iterativeTime > _time) {
                iterativeTime = _time;
            }
            // Else get most recent slope change
            else {
                dSlope = slopeChanges[iterativeTime];
            }

            lastCheckpoint.bias =
                lastCheckpoint.bias -
                (lastCheckpoint.slope *
                    SafeCast.toInt128(
                        int256(iterativeTime - lastCheckpoint.ts)
                    ));

            if (iterativeTime == _time) {
                break;
            }

            lastCheckpoint.slope = lastCheckpoint.slope + dSlope;
            lastCheckpoint.ts = iterativeTime;
        }

        return SafeCast.toUint256(max(lastCheckpoint.bias, 0));
    }

    /**
     * @dev Floors a timestamp to the nearest weekly increment
     * @param _t Timestamp to floor
     * @return Timestamp floored to nearest weekly increment
     */
    function _floorToWeek(uint256 _t) public pure returns (uint256) {
        return (_t / WEEK) * WEEK;
    }

    /**
     * @dev Returns the largest of two numbers.
     * @param _a First number
     * @param _b Second number
     * @return Largest of _a and _b
     */
    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a >= _b ? _a : _b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     * @param _a First number
     * @param _b Second number
     * @return Smallest of _a and _b
     */
    function max(int128 _a, int128 _b) internal pure returns (int128) {
        return _a >= _b ? _a : _b;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}