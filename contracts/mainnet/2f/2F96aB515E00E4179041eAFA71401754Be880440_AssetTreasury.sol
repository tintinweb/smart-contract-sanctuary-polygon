// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
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
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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
     * Emits a {ApprovalForAll} event.
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
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

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

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./BruPool.sol";

/**
 * @title Asset Treasury contract
 * @author Bru-finance team
 * @dev This contract is used to mint the Assets as NFT.
 */
contract AssetTreasury is ERC1155 {
    uint256 internal tokenId;
    address internal poolAddress;
    address internal adminAddress;
    /**
     * @notice mint wallet address which only has access to mint nfts
     */
    address public mintWalletAddress;

    /**
     * @notice Emitted after changeMintWalletAddress function executed successfully
     * @param _newAddress The new mint wallet address
     */
    event MintWalletChanged(address _newAddress);

    /**
     * @dev Only admin can call functions marked by this modifier.
     */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Can be used only by admin");
        _;
    }

    /**
     * @dev functions marked with this modifier can only be called by mint wallet address
     */
    modifier onlyMintWalletAddress() {
        require(msg.sender == mintWalletAddress, "Can be used only by mint wallet address");
        _;
    }

    /**
     * @notice Initializes the poolAddress, mintWalletAddress and adminAddress
     * @param _poolAddress The address of the pool
     * @param _mintWalletAddress The address which is allowed to mint NFTs in the contract
     * @param _adminAddress The address of the admin
     */
    constructor(
        address _poolAddress,
        address _mintWalletAddress,
        address _adminAddress
    ) ERC1155("") {
        require(
            _poolAddress != address(0) && _mintWalletAddress != address(0) && _adminAddress != address(0),
            "zero address not allowed"
        );
        adminAddress = _adminAddress;
        poolAddress = _poolAddress;
        mintWalletAddress = _mintWalletAddress;
    }

    /**
     * @notice Add a commodities as NFT on the blockchain.
     * @dev Mint the nft and stores the data's in the BruPool nft mapping.
     * @param _userAddress The account address of the a commodity owner.
     * @param _nftId The unique Id of the particular NFT
     * @param _commodityId The Id of the commodity.
     * @param _quantity The amount of the commodity
     * @param _value The value of the commodity.
     * @param _dataHash The hash encrypted by sha256 which has all the data of nft.
     * @param _data The original data of nft which combines its price and quantity and other details.
     */
    // function mintNft(
    //     address _userAddress,
    //     string memory _nftId,
    //     string memory _commodityId,
    //     uint256 _quantity,
    //     uint256 _value,
    //     string memory _dataHash,
    //     string memory _data
    // ) external onlyMintWalletAddress {
    //     tokenId++;
    //     _mint(_userAddress, tokenId, _quantity, bytes(_data));
    //     BruPool(poolAddress).mintNft(tokenId, _nftId, _commodityId, _quantity, _value, _dataHash, _data);
    // }
    function mintNft(
        address _userAddress,
        string memory _nftId,
        string memory _commodityId,
        uint256 _quantity,
        uint256 _value,
        string memory _dataHash,
        string memory _data
    ) external  {
        tokenId++;
        _mint(_userAddress, tokenId, _quantity, bytes(_data));
        BruPool(poolAddress).mintNft(tokenId, _nftId, _commodityId, _quantity, _value, _dataHash, _data);
    }

    /**
     * @notice Changes The mintWallet address
     * @param _newAddress The new address of mintWallet
     *
     */
    function changeMintWalletAddress(address _newAddress) external onlyAdmin {
        require(_newAddress != address(0), "invalid address");
        mintWalletAddress = _newAddress;
        emit MintWalletChanged(_newAddress);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./../vesting/Token.sol";

/**
 * @title BruAdmin contract
 * @author Bru-finance team
 * @dev This contract is used to access admin level functionalities in the pool.
 */
contract BruAdmin {
    //value of pool Rewards APY
    uint256 internal poolRewardAPY;

    // determines the lending rate
    uint256 public spread;

    uint256 public lockPeriod; // lock period for deposited funds

    uint256 internal maxFeeRate; // Maxium fees charged by platform

    uint256 public maxAllowedTokenAddresses; // maximum number of allowed tokens
    /**
     * @notice Admin address
     */
    address public admin;
    /**
     * @notice owner address which can trigger owner only functions
     */
    address internal owner;

    //address of bruRewards Contract
    address internal bruRewardsAddress;

    //address of bruPrice Contract
    address internal bruPriceAddress;

    // address of router contract;
    address internal routerAddress;

    //address of treasury Contract
    address internal treasuryAddress;

    //indicates if asset/NFT is available for borrowing
    mapping(string => bool) public assetLocked;

    /**
     * @notice Array of tokens which can be used in this pool
     */
    address[] public tokenAddresses;
    bool public corePause; // it is used for pause functionality in the pool contracts

    Rates public rates; // interest rates for borrow and lend for the pool.

    PlatformFees public platformFees; // platform fees for borrow and lend functionality
    //Pool Limits
    struct Rates {
        uint256 borrow;
        uint256 lend;
    }

    //Platform Fees
    struct PlatformFees {
        uint256 borrow;
        uint256 lend;
    }

    /// @notice Mapping for maintaing addresses of stablecoins allowed by the admin
    mapping(address => bool) public allowedTokenAddresses;

    /// @notice a mapping that stores the index of the _tokenAddress in tokenAddresses array
    mapping(address => uint256) internal tokenAddressIndex;

    /**
     * @notice emitted during spread change action.
     * @param _spread the new spread value in the pool
     */
    event SpreadChanged(uint256 _spread);

    /**
     * @notice emitted during change lock period action in the pool.
     * @param _lockPeriod the new lock period for deposits in the pool
     */
    event LockPeriodChanged(uint256 _lockPeriod);

    /**
     * @notice Emitted when new token address added to the pool
     * @param _tokenAddress The address of the newly added token
     */
    event TokenAddressAllowed(address _tokenAddress);

    /**
     * @notice Emited when allowed token address removed from the contract
     * @param _tokenAddress The address of the removed token
     */
    event TokenAddressDisabled(address _tokenAddress);

    /**
     * @notice Emitted when pool borrow interest rate changed_
     * @param _rate The number of newly changed_ pool borrow interest rate
     */
    event BorrowRateChanged(uint256 _rate);

    /**
     * @notice Emitted when borrow platform fee changed_
     * @param _fee The number of newly changed platform fee
     */
    event BorrowPlatformFeeChanged(uint256 _fee);

    /**
     * @notice Emitted when max allowed addresses changed_
     * @param _maxAllowedAddresses The number of max addresses allowed
     */
    event MaxAddressesAllowedChanged(uint256 _maxAllowedAddresses);
    /**
     * @notice Emitted when lending platform fee changed
     * @param _fee The number of newly changed platform fee
     */
    event LendPlatformFeeChanged(uint256 _fee);

    /**
     * @notice Emitted when rewardAPY increased
     * @param _apy The amount of the increased APY
     */
    event PoolRewardsStarted(uint256 _apy);

    /**
     * @notice Emitted after pool reward stopped
     */
    event PoolRewardsStopped();

    /**
     * @notice Emitted when the status of the pool changed
     * @param _status the newly changed status
     */
    event CoreFunctionalityAvailabilityStatus(bool _status);

    /**
     * @notice Emitted when NFT is locked
     * @param _nftId the ID of the NFT
     */
    event AssetLocked(string _nftId);

    /**
     * @notice Emitted when NFT is unlocked
     * @param _nftId the ID of the NFT
     */
    event AssetUnlocked(string _nftId);

    /**
     * @dev Checks the availability of the core functionality in the pool
     */
    modifier checkCorePauseStatus() {
        require(!corePause, "Core functionalities disabled");
        _;
    }

    /**
     * @dev Only Asset treasury contract can call functions marked by this modifier.
     */
    modifier onlyAssetTreasury() {
        require(treasuryAddress == msg.sender, "only treasury allowed");
        _;
    }

    /**
     * @notice Used to check the accessibility and only allows the admin to access the functions.
     */

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    /**
     * @notice Used to check the accessibility and only allows the router to access the functions.
     */
    modifier onlyRouter() {
        _onlyRouter();
        _;
    }

    /**
     * @notice Used to check the new fee value is less than a max value.
     * @param _fee new fee value
     */
    modifier checkFeeValue(uint256 _fee) {
        _checkFeeValue(_fee);
        _;
    }

    /**
     * @notice Used to check the accessibility and only allows the owner to access the functions.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner is authorized");
        _;
    }

    /**
     * @notice Gives a list of token addresses which are supported by the pool
     * @return array of addresses with list of token addresses supported by the pool
     */
    function getAllowedTokenAddressesArray() public view virtual returns (address[] memory) {
        return tokenAddresses;
    }

    /**
     * @notice Used to add a new token address which can be used in the pool
     * @param _tokenAddress the new token address which can be used in the pool
     */
    function allowTokenAddress(address _tokenAddress) external virtual onlyAdmin {
        require(_tokenAddress != address(0), "Invalid Address");
        require(tokenAddresses.length + 1 < maxAllowedTokenAddresses, "Max limit reached");
        require(!allowedTokenAddresses[_tokenAddress], "Already allowed by admin");
        allowedTokenAddresses[_tokenAddress] = true;
        tokenAddresses.push(_tokenAddress);
        tokenAddressIndex[_tokenAddress] = tokenAddresses.length;
        emit TokenAddressAllowed(_tokenAddress);
    }

    /**
     * @notice Disables specified token for use in the pool.
     * @param _tokenAddress the new token address which is removed from the pool
     */
    function removeTokenAddress(address _tokenAddress) external virtual onlyAdmin {
        require(allowedTokenAddresses[_tokenAddress], "Not allowed by the admin");
        allowedTokenAddresses[_tokenAddress] = false;

        uint256 index = tokenAddressIndex[_tokenAddress];
        tokenAddresses[index - 1] = tokenAddresses[tokenAddresses.length - 1];
        tokenAddressIndex[tokenAddresses[tokenAddresses.length - 1]] = index;
        delete tokenAddressIndex[_tokenAddress];
        tokenAddresses.pop();
        emit TokenAddressDisabled(_tokenAddress);
    }

    /**
     * @notice changes the borrow interest rate in the pool
     * @param _interestRate the new borrow interest rate
     */
    function changeBorrowInterestRate(uint256 _interestRate) external virtual onlyAdmin checkFeeValue(_interestRate) {
        rates.borrow = (_interestRate * (10**18)) / (10000);
        emit BorrowRateChanged(_interestRate);
    }

    /**
     * @notice changes the borrowing platform fees in the pool
     * @param _fee the new borrowing platform fees
     */
    function changeBorrowPlatformFee(uint256 _fee) external virtual onlyAdmin checkFeeValue(_fee) {
        platformFees.borrow = (_fee * (10**18)) / (10000);
        emit BorrowPlatformFeeChanged(_fee);
    }

    /**
     * @notice changes the max allowed addresses for a pool
     * @param _maxValue new max value allowed address
     */
    function changeMaxAddresses(uint256 _maxValue) external virtual onlyAdmin {
        maxAllowedTokenAddresses = _maxValue;
        emit MaxAddressesAllowedChanged(_maxValue);
    }

    /**
     * @notice changes the lending platform fees in the pool
     * @param _fee the new lending platform fees
     */
    function changeLendPlatformFee(uint256 _fee) external virtual onlyAdmin checkFeeValue(_fee) {
        platformFees.lend = _fee * 10000;
        emit LendPlatformFeeChanged(_fee);
    }

    /**
     * @notice changes the time for which the deposits in the pool are locked
     * @param _time the time for which deposits are locked
     */
    function changeLockPeriod(uint256 _time) external virtual onlyAdmin {
        require(_time > 0, "time should be greater than zero");
        lockPeriod = _time;
        emit LockPeriodChanged(_time);
    }

    /**
     * @notice changes the spread which affects the lending rates in the pool
     * @param _spread the value which affects the lending rate in the pool
     */

    function changeSpread(uint256 _spread) external virtual onlyAdmin {
        spread = _spread;
        rates.lend = rates.borrow - spread;
        emit SpreadChanged(spread);
    }

    /**
     * @notice used to enable / disable core functionalities like borrow ,repay , deposit , withdraw
     */
    function changeCoreFunctionalityStatus() external virtual onlyAdmin {
        corePause = !corePause;
        emit CoreFunctionalityAvailabilityStatus(corePause);
    }

    /**
     * @notice used by rewards contract to increase rates during rewards period
     * @param _rewardAPY The of value of new rewardAPY that increases the rates in the pool by this variable
     */
    function startRewards(uint256 _rewardAPY) external virtual {
        checkRewardsAddress();
        rates.lend += _rewardAPY;
        rates.borrow -= _rewardAPY;
        poolRewardAPY = _rewardAPY;
        emit PoolRewardsStarted(_rewardAPY);
    }

    /**
     * @notice used by rewards contract to reset pool rates after rewards period is completed
     */
    function stopRewards() external virtual {
        checkRewardsAddress();
        rates.lend -= poolRewardAPY;
        rates.borrow += poolRewardAPY;
        poolRewardAPY = 0;
        emit PoolRewardsStopped();
    }

    /**
     * @notice Used to check the that the given call is done by admin.
     */
    function _onlyAdmin() internal view virtual {
        require(msg.sender == admin, "Can be used only by admin");
    }

    /**
     * @notice Used to check the that the given call is done by router.
     */
    function _onlyRouter() internal view {
        require(routerAddress == msg.sender, "only router contract can accesss this");
    }

    /**
     * @notice Used to check the new fee value is less than max_fee_rates.
     * @param _fee new fee value
     */
    function _checkFeeValue(uint256 _fee) internal view {
        require(_fee <= maxFeeRate, "fee should be less than max fees");
    }

    /**
     * @notice Used to check the accessibility and only allows the Bru rewards contract to access the functions
     */
    function checkRewardsAddress() internal view virtual {
        require(bruRewardsAddress == msg.sender, "only rewards contract can access");
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

struct PoolDetails {
    string poolName;
    address poolTokenAddress;
    address interestTokenAddress;
    address proxyPoolAddress;
    address implementationPoolAddress;
    address treasuryAddress;
}

/**
 * @title Bru Factory contract
 * @author Bru-finance team
 * @notice Used for storage and retrieval of addresses of Brufinance pools.
 **/
contract BruFactory is Initializable, UUPSUpgradeable {
    // @dev the address of bru token.
    address public bruTokenAddress;
    address internal admin; //The address of multisig wallet
    PoolDetails[] internal poolDetails; //the array which contains the details of pools in the Bru Ecosystem
    uint256 public maxPool; //maximum number of allowed pools
    /**
     * @notice Emitted when the pool is successfully deployed.
     * @param _poolName The name of the pool
     * @param _poolTokenAddress The address of the pool token
     * @param _interestTokenAddress The address of the interest token
     * @param _proxyPoolAddress The address of proxy pool
     * @param _implementationAddress The address of the pool implementation contract
     * @param _treasuryAddress The address of treasury contract
     */
    event PoolDeployed(
        string _poolName,
        address _poolTokenAddress,
        address _interestTokenAddress,
        address _proxyPoolAddress,
        address _implementationAddress,
        address _treasuryAddress
    );

    /**
     * @notice Emitted when max pool changed_
     * @param  _maxPool The number of max pool allowed
     */
    event MaxPoolChanged(uint256 _maxPool);
    /**
     * @dev Only admin can call functions marked by this modifier.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Can be used only by admin");
        _;
    }

    /**
     * @notice Initializes the required addresses needed for the functioning of this contract
     * @param _multiSigAddress The address of multisig wallet
     * @param _bruTokenAddress Address of the Bru token
     **/
    function initialize(address _multiSigAddress, address _bruTokenAddress) external virtual initializer {
        require(_multiSigAddress != address(0) && _bruTokenAddress != address(0), "zero address not allowed");
        admin = _multiSigAddress;
        bruTokenAddress = _bruTokenAddress;
        maxPool = 99;
    }

    /**
     * @notice Stores addreses related to the pool in the  poolDetails array
     * @dev only called by the admin
     * @param _poolName The name of the pool
     * @param _proxyPoolAddress The address of proxy pool
     * @param _implementationAddress TThe address of the pool implementation contract
     * @param _poolTokenAddress The address of the pool token
     * @param _interestTokenAddress The address of the interest token
     * @param _treasuryAddress The address of treasury contract
     */
    function addPoolDetails(
        string memory _poolName,
        address _proxyPoolAddress,
        address _implementationAddress,
        address _poolTokenAddress,
        address _interestTokenAddress,
        address _treasuryAddress
    ) external onlyAdmin {
        require(
            _proxyPoolAddress != address(0) &&
                _implementationAddress != address(0) &&
                _poolTokenAddress != address(0) &&
                _interestTokenAddress != address(0) &&
                _treasuryAddress != address(0),
            "incorrect address"
        );
        require(poolDetails.length + 1 < maxPool, "Max pool limit reached");
        poolDetails.push(
            PoolDetails(
                _poolName,
                _poolTokenAddress,
                _interestTokenAddress,
                _proxyPoolAddress,
                _implementationAddress,
                _treasuryAddress
            )
        );
        emit PoolDeployed(
            _poolName,
            _poolTokenAddress,
            _interestTokenAddress,
            _proxyPoolAddress,
            _implementationAddress,
            _treasuryAddress
        );
    }

    /**
     * @notice changes the max allowed addresses for a pool
     * @param _maxValue new max value of allowed pools
     */
    function changeMaxPool(uint256 _maxValue) external virtual onlyAdmin {
        maxPool = _maxValue;
        emit MaxPoolChanged(_maxValue);
    }

    /**
     * @notice Used to get the pool address by using poolIndex as a param
     * @param _poolIndex the index of the pool
     * @return The address of pool assocatied with pool index
     */
    function getPoolAddress(uint256 _poolIndex) external view virtual returns (address) {
        require(_poolIndex <= poolDetails.length - 1, "Pool does not exist");
        return poolDetails[_poolIndex].proxyPoolAddress;
    }

    /**
     * @notice Used to get pool details by using poolIndex as param
     * @param _poolIndex the index of the pool
     * @return The details of a pool associated with the pool index.
     */
    function getPoolDetails(uint256 _poolIndex) external view virtual returns (PoolDetails memory) {
        return poolDetails[_poolIndex];
    }

    /**
     * @notice Used to get all pools related addresses
     * @return Array of all pools related addresses
     */
    function getAllPoolDetails() external view virtual returns (PoolDetails[] memory) {
        return poolDetails;
    }

    /**
     * @dev Checks the wallet address which initiates the upgrade transaction for BruFactory contract
     * @param _newImplementation Address of the new implementation contract which is used for upgradation.
     */
    function _authorizeUpgrade(address _newImplementation) internal view override onlyAdmin {}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/**
 * @title Bru Oracle contract
 * @author Bru-finance team
 * @notice This is used to get price of Bru Token
 **/
contract BruOracle is Initializable, UUPSUpgradeable {
    address internal adminAddress; // The address of multisig wallet
    uint256 internal bruTokenPrice; // The price of Bru token

    /**
     * @notice Mapping that store pricefeed address for tokens
     */
    mapping(address => address) public priceFeeds;
    /**
     * @notice Emitted during set rewardAPY action
     * @param _bruTokenPrice The updated bru token price
     **/
    event BruTokenPriceChanged(uint256 _bruTokenPrice);

    /**
     * @notice Emitted when pricefeed set for a token
     * @param _tokenAddress The address of token address to fetch price from oracle
     * @param _oracleAddress The address of oracle contract for given token address
     **/
    event TokenOracleChanged(address _tokenAddress, address _oracleAddress);

    /**
     * @dev Only admin can call functions marked by this modifier.
     **/
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Can be used only by admin");
        _;
    }

    /**
     * @notice Initializes the required addresses needed for the functioning of this contract
     * @param _adminAddress The address of multisig wallet
     **/
    function initialize(address _adminAddress) external initializer {
        require(_adminAddress != address(0), "zero address not allowed");
        adminAddress = _adminAddress;
        bruTokenPrice = 1000000000000000000;
    }

    /**
     * @notice function to set the oracle contaract for particular token
     * @param _tokenAddress The address of token address to fetch price from oracle
     * @param _priceFeed The address of oracle contract for given token address
     **/
    function setPriceFeedForToken(address _tokenAddress, address _priceFeed) external virtual onlyAdmin {
        priceFeeds[_tokenAddress] = _priceFeed;
        emit TokenOracleChanged(_tokenAddress, _priceFeed);
    }

    /**
     * @notice function to get the value of given token address in USD
     * @param _tokenAddress The address of token address to fetch price from oracle
     * @return returns price of Token/USD
     **/
    function getLatestPriceOfTokenInUSD(address _tokenAddress) public view returns (uint256) {
        int256 answer;
        (, answer, , , ) = AggregatorV2V3Interface(priceFeeds[_tokenAddress]).latestRoundData();
        return uint256(answer);
    }

    /**
     * @notice function to get the decimal point of price feed for given token address
     * @param _tokenAddress The address of token address to fetch decimal of price feed from oracle
     * @return returns decimal of price feed
     **/
    function getPriceFeedDecimal(address _tokenAddress) public view returns (uint256) {
        uint8 decimals = AggregatorV2V3Interface(priceFeeds[_tokenAddress]).decimals();
        return uint256(decimals);
    }

    /**
     * @notice Sets the price of the Bru token
     * @dev Only called by the admin
     * @param _bruTokenPrice The bru token price value
     **/
    function setBruTokenPrice(uint256 _bruTokenPrice) external virtual onlyAdmin {
        bruTokenPrice = _bruTokenPrice;
        emit BruTokenPriceChanged(bruTokenPrice);
    }

    /**
     * @notice Used to get the price of the Bru token
     * @return The current price of the Bru token
     **/
    function getBruTokenPrice() external view virtual returns (uint256) {
        return bruTokenPrice;
    }

    /**
     * @dev Checks the wallet address which initiates the upgrade transaction for the BruOracle contract
     * @param _newImplementation Address of the new implementation contract which is used for upgradation.
     **/
    function _authorizeUpgrade(address _newImplementation) internal view override onlyAdmin {}
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../tokens/PoolToken.sol";
import "../tokens/InterestToken.sol";
import "../wallets/NIIMargin.sol";
import "./BruAdmin.sol";
import "./BruRewards.sol";
import "./AssetTreasury.sol";
import "./BruPrice.sol";

/**
 * @title Bru Pool contract
 * @author Bru-finance team
 * @notice Is a contract that is responsible for the main functionality of the platform
 */
contract BruPool is BruAdmin, Initializable, ReentrancyGuard, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    /**
     * @notice name of the pool
     */
    string public name;

    uint256 internal poolIndex;

    //for handling ID of btoken and nft
    //important addresses
    address internal poolTokenAddress; // The address of pool token
    address internal interestTokenAddress; // The address of interest token
    address internal interestWalletAddress; // The address of NIImargin contract

    address internal factory; // The address of BruFactory contract

    struct BondDetails {
        address tokenAddress;
        uint256 bondTimestamp;
        uint256 interest;
        uint256 bondAmount;
        uint256 lockTimePeriod;
        uint256 claimedDay;
        bool withdrawn;
    }

    //Struct used for storing NFT Data
    struct NFT {
        uint256 tokenId;
        string commodityId;
        uint256 quantity;
        uint256 value;
        bool borrowed;
        string dataHash;
        string data;
    }

    //Struct for other expenses
    struct BorrowDetails {
        uint256 borrowedAmount;
        uint256 time;
        address tokenBorrowedAddress;
    }

    struct Expenses {
        uint256 otherexpenses;
        uint256 interest;
    }
    /**
     * @notice Mapping which stores nft data
     */
    mapping(string => NFT) public nft;

    /**
     * @notice Mapping for storing borrow details of NFT
     */
    mapping(string => BorrowDetails) public borrowedNft;

    /**
     * @notice Mapping for storing expenses
     */
    mapping(string => Expenses) public totalExpense;

    mapping(address => uint256) public userBondIds;
    mapping(address => mapping(uint256 => BondDetails)) public userBonds;
    mapping(address => mapping(uint256 => bool)) public bondInterestClaimed;

    /**
     * @notice Emitted when a user deposits funds into the pool
     * @param _userAddress The address of the usersbr
     * @param _bondId The ID of the newly created bond
     * @param _timestamp The time at which the deposit function was executed
     * @param _tokenAddress The address of the token deposited in the pool by te user.
     * @param _tokenAmount the amount of token deposited by the user
     */
    event BondCreated(
        address indexed _userAddress,
        uint256 _bondId,
        uint256 indexed _timestamp,
        address _tokenAddress,
        uint256 _tokenAmount
    );

    /**
     * @notice Emitted when a bond which has matured has been withdrawn by the user.
     * @param _userAddress The address of the user
     * @param _bondId The matured bond which is withdrawn by the user
     * @param _timestamp The time at which the bond was withdrawn by the user
     */
    event BondWithdrawn(
        address indexed _userAddress,
        uint256 _bondId,
        uint256 indexed _timestamp,
        address _tokenAddress,
        uint256 _tokenAmount
    );

    /**
     * @notice Emitted when the interest on a bond is claimed by the user.
     * @param _userAddress The address of the user
     * @param _bondId The matured bond which is withdrawn by the user
     * @param _timestamp The time at which the bond was withdrawn by the user
     * @param _tokenAmount Amount of interest claimed on the bond
     */
    event BondInterestClaimed(address indexed _userAddress, uint256 _bondId, uint256 _timestamp, uint256 _tokenAmount);

    /**
     * @notice Emitted after user repays
     * @param _amount amount repaid
     * @param _nftId Id of the NFT
     * @param _userAddress address of the user who repaid
     * @param _tokenAddress address of token used to pay
     */
    event Repaid(
        uint256 _amount,
        string _nftId,
        uint256 indexed _timestamp,
        address indexed _userAddress,
        address _tokenAddress
    );

    /**
     * @notice Emitted after user borrows
     * @param _amount amount repaid
     * @param _nftId Id of the NFT
     * @param _userAddress address of the user who repaid
     * @param _tokenAddress address of token used to pay
     */
    event Borrowed(
        uint256 _amount,
        string _nftId,
        uint256 indexed _timestamp,
        address indexed _userAddress,
        address _tokenAddress
    );
    /**
     * @notice Emitted an nft is minted
     * @param _tokenId  Token ID of the SFT minted in asset treasury for the user
     * @param _nftId NftID from the data of the nft
     * @param _commodityId The Id of the commodity
     * @param _quantity The amount of the commodity
     * @param _value The total valuation of the commodity deposited
     * @param _dataHash The hash encrypted by sha256 which has all the data of nft
     * @param _data The original data of nft which combines its price and quantity and other details
     */
    event NFTMinted(
        uint256 _tokenId,
        string _nftId,
        string _commodityId,
        uint256 _quantity,
        uint256 _value,
        string _dataHash,
        string _data
    );

    /**
     * @notice Initializes necessary contract addresses
     * @param _multiSigAddress The address of multi sign wallet
     * @param _factoryAddress The address of factory contract
     * @param _poolTokenAddress The address of pool token
     * @param _interestTokenAddress The address of interest token
     * @param _treasuryAddress The address of asset treasury contract
     * @param _poolName The name of the pool
     * @param _interestWalletAddress The address of NIImargin contract
     * @param _bruRewardsAddress The address of bruReward contract
     * @param _bruPriceAddress The address of BruPrice contract
     */
    function initialize(
        uint256 _poolIndex,
        address _routerAddress,
        address _multiSigAddress,
        address _factoryAddress,
        address _poolTokenAddress,
        address _interestTokenAddress,
        address _treasuryAddress,
        string memory _poolName,
        address _interestWalletAddress,
        address _bruRewardsAddress,
        address _bruPriceAddress
    ) external virtual initializer {
        require(
            _routerAddress != address(0) &&
                _multiSigAddress != address(0) &&
                _factoryAddress != address(0) &&
                _poolTokenAddress != address(0) &&
                _interestTokenAddress != address(0) &&
                _treasuryAddress != address(0) &&
                _interestWalletAddress != address(0) &&
                _bruRewardsAddress != address(0) &&
                _bruPriceAddress != address(0),
            "Invalid Address"
        );

        poolIndex = _poolIndex;
        routerAddress = _routerAddress;
        admin = _multiSigAddress;
        owner = msg.sender;
        factory = _factoryAddress;
        name = _poolName;
        maxFeeRate = 10000;
        maxAllowedTokenAddresses = 99;
        rates.borrow = (uint256(1000) * (10**18)) / (maxFeeRate);
        platformFees.borrow = (uint256(1) * (10**18)) / (maxFeeRate);
        platformFees.lend = (uint256(1) * (10**18)) / (maxFeeRate);
        spread = (uint256(300) * (10**18)) / (maxFeeRate);
        rates.lend = rates.borrow - spread;
        poolTokenAddress = _poolTokenAddress;
        interestTokenAddress = _interestTokenAddress;
        interestWalletAddress = _interestWalletAddress;
        treasuryAddress = _treasuryAddress;
        bruRewardsAddress = _bruRewardsAddress;
        bruPriceAddress = _bruPriceAddress;
        lockPeriod = 180;
    }

    /**
     * @notice Store's NFT's detailed information in the nft mapping by using nftID
     * @param _tokenId  Token ID of the SFT minted in asset treasury for the user
     * @param _nftId NftID from the data of the nft
     * @param _commodityId The Id of the commodity
     * @param _quantity The amount of the commodity
     * @param _value The total valuation of the commodity deposited
     * @param _dataHash The hash encrypted by sha256 which has all the data of nft
     * @param _data The original data of nft which combines its price and quantity and other details
     */
    function mintNft(
        uint256 _tokenId,
        string memory _nftId,
        string memory _commodityId,
        uint256 _quantity,
        uint256 _value,
        string memory _dataHash,
        string memory _data
    ) external virtual onlyAssetTreasury {
        require(nft[_nftId].quantity == 0, "minted already");
        nft[_nftId] = NFT(_tokenId, _commodityId, _quantity, _value, false, _dataHash, _data);
        emit NFTMinted(_tokenId, _nftId, _commodityId, _quantity, _value, _dataHash, _data);
    }

    /**
     * @notice Used to borrow tokens / stablecoins from the contract
     * @dev tranfers allowed tokens from contract to the user accounts.
     * @param _userAddress The address of the borrower
     * @param _nftId The Id of the nft borrower can used as collateral
     * @param _tokenAddress the address of the token borrower can borrow
     * @param _tokenAmount the amount of token borrower wants to borrow
     */
    function borrow(
        address _userAddress,
        string memory _nftId,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external virtual checkCorePauseStatus onlyRouter {
        require(AssetTreasury(treasuryAddress).balanceOf(_userAddress, nft[_nftId].tokenId) > 0, "NFT does not exist");
        require(!assetLocked[_nftId] && !nft[_nftId].borrowed, "Already borrowed on this NFT");
        require(allowedTokenAddresses[_tokenAddress], "Token Address not allowed");
        require(IERC20(_tokenAddress).balanceOf(address(this)) > _tokenAmount, "Pool does not have enough liquidity");
        uint256 totalAssetValue;
        uint256 assetValuePerKG = BruPrice(bruPriceAddress).asset(nft[_nftId].commodityId);
        if (assetValuePerKG > 0) {
            totalAssetValue = nft[_nftId].quantity * assetValuePerKG;
        } else {
            totalAssetValue = nft[_nftId].value;
        }
        require(_tokenAmount <= (totalAssetValue * 7) / 10, "Collateral provided is less for specified token amount");
        nft[_nftId].borrowed = true;
        assetLocked[_nftId] = true;
        borrowedNft[_nftId] = BorrowDetails(_tokenAmount, block.timestamp, _tokenAddress);
        if (BruRewards(bruRewardsAddress).getRewardStatusForPool(poolIndex)) {
            BruRewards(bruRewardsAddress).updateBorrowAmountInRewardsInterval(poolIndex, _userAddress, _tokenAmount);
        }
        IERC20(_tokenAddress).safeTransfer(_userAddress, _tokenAmount);
        emit Borrowed(_tokenAmount, _nftId, block.timestamp, _userAddress, _tokenAddress);
    }

    /**
     * @notice Used to repay the borrowed amount
     * @param _userAddress The address of the borrower
     * @param _nftId The Id of the nft borrower used as collateral
     * @param _tokenAmount the amount of token borrower want to repay
     * @param _tokenAddress the address of the token borrower has borrowed
     */
    function repay(
        address _userAddress,
        string memory _nftId,
        uint256 _tokenAmount,
        address _tokenAddress
    ) external virtual nonReentrant checkCorePauseStatus onlyRouter {
        uint256 interestCollected = 0;
        require(AssetTreasury(treasuryAddress).balanceOf(_userAddress, nft[_nftId].tokenId) > 0, "NFT does not exist");
        require(nft[_nftId].borrowed, "This NFT is not borrowed");
        require(_tokenAddress == borrowedNft[_nftId].tokenBorrowedAddress, "token does not match the token borrowed");
        borrowInterest(_nftId);
        uint256 amount = (_tokenAmount * (10**18)) / ((10**18) + platformFees.borrow);

        uint256 totalPayablePrice = borrowedNft[_nftId].borrowedAmount + totalExpense[_nftId].interest;

        require(totalPayablePrice >= amount, "amount greater than borrowed");

        if (amount >= totalExpense[_nftId].interest) {
            interestCollected += totalExpense[_nftId].interest;

            totalExpense[_nftId].interest = 0;

            borrowedNft[_nftId].borrowedAmount -= amount - interestCollected;
        } else {
            totalExpense[_nftId].interest -= amount;
            interestCollected += amount;
        }
        borrowedNft[_nftId].time = block.timestamp;

        if (borrowedNft[_nftId].borrowedAmount <= 1) {
            nft[_nftId].borrowed = false;
            assetLocked[_nftId] = false;
            borrowedNft[_nftId] = BorrowDetails(0, 0, address(0));
        }

        IERC20(_tokenAddress).safeTransferFrom(_userAddress, address(this), _tokenAmount);

        IERC20(_tokenAddress).safeTransfer(interestWalletAddress, interestCollected + _tokenAmount - amount);
        emit Repaid(_tokenAmount, _nftId, block.timestamp, _userAddress, _tokenAddress);
    }

    /**
     * @notice Deposits user's tokens in the pool contract
     * @param _userAddress The address of the user who deposits his tokens
     * @param _tokenAddress The address of the token user wants to deposit
     * @param _tokenAmount The amount of token user wants to deposit
     */
    function deposit(
        address _userAddress,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external virtual nonReentrant checkCorePauseStatus onlyRouter {
        require(allowedTokenAddresses[_tokenAddress], "Token Address not allowed");
        require(_tokenAmount > 0, "Token Amount less than one");
        require(IERC20(_tokenAddress).balanceOf(_userAddress) >= _tokenAmount, "Insufficient Token Amount");
        uint256 amount = (_tokenAmount * (10**18)) / ((10**18) + platformFees.lend);

        uint256 bondId = userBondIds[_userAddress];
        userBonds[_userAddress][bondId] = BondDetails(
            _tokenAddress,
            block.timestamp,
            rates.lend,
            amount,
            lockPeriod,
            0,
            false
        );
        userBondIds[_userAddress]++;
        IERC20(_tokenAddress).safeTransferFrom(_userAddress, address(this), _tokenAmount);
        IERC20(_tokenAddress).safeTransfer(interestWalletAddress, _tokenAmount - amount);

        if (BruRewards(bruRewardsAddress).getRewardStatusForPool(poolIndex)) {
            BruRewards(bruRewardsAddress).updateLendAmountInRewardsInterval(poolIndex, _userAddress, _tokenAmount);
        }
        PoolToken(poolTokenAddress).mint(_userAddress, amount);
        emit BondCreated(_userAddress, bondId, block.timestamp, _tokenAddress, _tokenAmount);
    }

    /**
     * @notice Withdraws user's withdrawable balance from pool and transfers it to a user's wallet address
     * @param _userAddress The account address of the user
     * @param _bondId The ID of the bond which is to be withdrawn
     */
    function withdraw(address _userAddress, uint256 _bondId)
        external
        virtual
        nonReentrant
        checkCorePauseStatus
        onlyRouter
    {
        BondDetails memory userBond = userBonds[_userAddress][_bondId];
        require(userBond.bondTimestamp > 0, "Bond does not exist");
        require(!userBond.withdrawn, "Bond already withdrawn");
        require(withdrawable(userBond.bondTimestamp, userBond.lockTimePeriod), "Bond has not matured yet");
        userBonds[_userAddress][_bondId].withdrawn = true;
        PoolToken(poolTokenAddress).burn(_userAddress, userBond.bondAmount);
        IERC20(userBond.tokenAddress).safeTransfer(_userAddress, userBond.bondAmount);
        emit BondWithdrawn(_userAddress, _bondId, block.timestamp, userBond.tokenAddress, userBond.bondAmount);
    }

    /**
     * @notice Used to exchange interest token with tokens / stablecoins supported by the pool
     * @param _requiredTokenAddress The address of token to be redeem
     * @param _tokenAmount The amount of token to redeem
     */
    function redeemInterestToken(address _requiredTokenAddress, uint256 _tokenAmount) external virtual {
        address userAddress = msg.sender;
        require(allowedTokenAddresses[_requiredTokenAddress], "Token address not allowed for redeeming");
        require(
            IERC20(interestTokenAddress).balanceOf(userAddress) >= _tokenAmount && _tokenAmount > 0,
            "Insufficient interest tokens to redeem"
        );
        InterestToken(interestTokenAddress).burn(userAddress, _tokenAmount);
        NIIMargin(interestWalletAddress).sendAmount(_tokenAmount, _requiredTokenAddress, userAddress);
    }

    /**
     * @notice Calculates the accumulated interest
     * @param _nftId the Id of the NFT
     * @return _interest the total accumulated interest
     */
    function borrowInterest(string memory _nftId) internal returns (uint256) {
        totalExpense[_nftId].interest += calculateBorrowInterest(_nftId);

        return totalExpense[_nftId].interest;
    }

    /**
     * @notice It is used to claim the interest amount on a bond based on the time the bond was created / the last time the interest was claimed on the bond
     * @param _bondId The ID of bond which the user wants to claim the interest for.
     */
    function claimInterestOnBond(uint256 _bondId) external {
        BondDetails memory userBond = userBonds[msg.sender][_bondId];
        require(userBond.bondTimestamp > 0, "Bond does not exist");
        require(!bondInterestClaimed[msg.sender][_bondId], "Bond interest already claimed");
        uint256 currentTime;
        uint256 depositedTimeInSeconds;
        uint256 bondMaturityPeriod = userBond.bondTimestamp + userBond.lockTimePeriod;
        if (block.timestamp >= bondMaturityPeriod) {
            bondInterestClaimed[msg.sender][_bondId] = true;
        }
        if (bondMaturityPeriod < block.timestamp) {
            currentTime = bondMaturityPeriod;
        } else {
            currentTime = block.timestamp;
        }
        if (userBond.claimedDay == 0) {
            depositedTimeInSeconds = ((currentTime - userBond.bondTimestamp));
        } else {
            depositedTimeInSeconds = ((currentTime - userBond.claimedDay));
        }
        uint256 interestTokenAmount = (userBond.bondAmount * userBond.interest * depositedTimeInSeconds) /
            (31536000 * (10**18));
        userBonds[msg.sender][_bondId].claimedDay = block.timestamp;
        InterestToken(interestTokenAddress).mint(msg.sender, interestTokenAmount);
        emit BondInterestClaimed(msg.sender, _bondId, block.timestamp, interestTokenAmount);
    }

    /**
     * @notice Locks the NFT and prevents user from borrowing on it
     * @param _userAddress The account address of the user
     * @param _nftId the ID of the NFT
     */
    function lockAsset(address _userAddress, string calldata _nftId) external onlyOwner {
        require(AssetTreasury(treasuryAddress).balanceOf(_userAddress, nft[_nftId].tokenId) > 0, "NFT does not exist");
        assetLocked[_nftId] = true;
        emit AssetLocked(_nftId);
    }

    /**
     * @notice Unlocks the NFT and allows the user to borrow on the NFT
     * @param _userAddress The account address of the user
     * @param _nftId the ID of the NFT
     */
    function unlockAsset(address _userAddress, string calldata _nftId) external onlyOwner {
        require(AssetTreasury(treasuryAddress).balanceOf(_userAddress, nft[_nftId].tokenId) > 0, "NFT does not exist");
        assetLocked[_nftId] = false;
        emit AssetUnlocked(_nftId);
    }

    /**
     * @notice It helps to get the amount for complete repayment for an NFT
     * @param _nftId the ID of the NFT
     */
    function getRepaymentAmount(string memory _nftId) external view returns (uint256) {
        uint256 interestAmountAccumulated = calculateBorrowInterest(_nftId);
        uint256 totalPayablePrice = borrowedNft[_nftId].borrowedAmount +
            totalExpense[_nftId].interest +
            interestAmountAccumulated;
        totalPayablePrice += (platformFees.borrow * totalPayablePrice) / 10**18;
        return totalPayablePrice;
    }

    /**
     * @notice It calculates the interest amount for the NFT
     * @param _nftId the ID of the NFT
     */
    function calculateBorrowInterest(string memory _nftId) internal view returns (uint256) {
        uint256 borrowedDays = (block.timestamp - borrowedNft[_nftId].time) / 86400;
        uint256 interestAmountAccumulated = (borrowedNft[_nftId].borrowedAmount * rates.borrow * borrowedDays) /
            (365 * (10**18));
        return interestAmountAccumulated;
    }

    /**
     * @notice Checks whether the bond is withdrawable or not
     * @param _bondCreationTime The timestamp at which bond is created
     * @param _bondLockPeriod The duration of the lock-in period
     */
    function withdrawable(uint256 _bondCreationTime, uint256 _bondLockPeriod) internal view returns (bool) {
        uint256 currentTime = block.timestamp;
        uint256 timePassedFromDeposit = currentTime - _bondCreationTime;
        return timePassedFromDeposit >= _bondLockPeriod;
    }

    /**
     * @dev Checks the wallet address which initiates the upgrade transaction for BruPool contract
     * @param _newImplementation Address of the new implementation contract which is used for upgradation.
     */
    function _authorizeUpgrade(address _newImplementation) internal view override {
        require(msg.sender == admin, "Only called by admin");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Bru Price contract
 * @author Bru-finance team
 * @notice Contract that is used to get assets prices which is used in BruPool contract
 */
contract BruPrice is Initializable, UUPSUpgradeable {
    address internal adminAddress; // The address of Multisig wallet
    address internal owner; // The address of deployer.
    /**
     * @notice a mapping that stores assets name with respect to price
     */
    mapping(string => uint256) public asset;

    /**
     * @notice Emitted when commodity price updated
     * @param _id The id of the asset
     * @param _value The newly updated price
     */
    event CommodityPriceUpdated(string _id, uint256 _value);

    /**
     * @dev Only admin can call functions marked by this modifier.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner address is allowed");
        _;
    }

    /**
     * @notice Initializes admin address
     * @param _adminAddress The address of Multisig wallet
     */
    function initialize(address _adminAddress) external virtual initializer {
        require(_adminAddress != address(0), "incorrect address");
        adminAddress = _adminAddress;
        owner = msg.sender;
    }

    /**
     * @notice Updates the Price of the asset
     * @param _id The Id of the asset
     * @param _price The price of the asset
     */
    function updatePrice(string memory _id, uint256 _price) external virtual onlyOwner {
        asset[_id] = _price;
        emit CommodityPriceUpdated(_id, _price);
    }

    /**
     * @dev Checks the wallet address which initiates the upgrade transaction for BruPrice contract
     * @param _newImplementation Address of the new implementation contract which is used for upgradation.
     */
    function _authorizeUpgrade(address _newImplementation) internal view override {
        require(msg.sender == adminAddress, "Only admin allowed");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./BruPool.sol";
import "./BruFactory.sol";
import "./BruOracle.sol";
import "../vesting/TokenVestingBru.sol";

/**
 * @title BruRewards contract
 * @author Bru-finance team
 * @dev This contract is used to contains rewards logic
 */
contract BruRewards is Initializable, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    uint256 public emission; // number of tokens emitted per interval
    uint256 internal secondsPerYear; // seconds in a year

    address internal adminAddress; // address of Multisig wallet
    address internal factoryAddress; // address of BruFactory contract
    address internal bruToken; // address of Bru token
    address internal bruOracleAddress; // address of BruOracle contract
    address internal tokenVestingAddress; // address of TokenVestingBru contract
    //struct which is used to store reward details per interval
    struct RewardDetails {
        uint256 rewardTokens;
        uint256 startTime;
        uint256 endTime;
        uint256 totalLendAmount;
        uint256 totalBorrowedAmount;
        bool isActive;
    }
    // struct which is used to store the balance of user per interval
    struct UserBalance {
        uint256 lendAmount;
        uint256 borrowedAmount;
    }

    mapping(uint256 => uint256) internal rewardIntervalIds; // used to store reward interval id for pool
    mapping(uint256 => mapping(uint256 => RewardDetails)) internal rewardDetails; //used to store reward details for pool
    mapping(uint256 => mapping(uint256 => mapping(address => UserBalance))) internal userBalance; // used to store user balance
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) internal userClaims; // to check if the reward is claimed by user for an interval
    /**
     * @notice emitted during emission change action in the contract
     * @param _emission the new emission value in the contract
     */
    event EmissionChanged(uint256 _emission);
    /**
     * @notice emitted during reward interval started
     * @param _poolIndex the pool index for which the reward interval is started
     * @param _rewardAPY The number of reward APY
     */
    event PoolRewardsStarted(uint256 _poolIndex, uint256 _rewardAPY);
    /**
     * @notice emitted when pool reward stopped
     * @param _poolIndex the pool index for which the reward interval is stopped
     */
    event PoolRewardsStopped(uint256 _poolIndex);
    /**
     * @notice emitted when user lent amount updated during reward interval
     * @param _poolIndex The pool index for which the amount added
     * @param _userAddress The user address for which the lend amount updated
     * @param _amount The amount of tokens deposited during a reward interval
     */
    event LendAmountUpdated(uint256 _poolIndex, address _userAddress, uint256 _amount);
    /**
     * @notice emitted when user borrow amount updated during reward interval
     * @param _poolIndex The pool index for which the amount updated
     * @param _userAddress The user address for which the borrow amount updated
     * @param _amount The amount of tokens borrowed during a reward interval
     */
    event BorrowAmountUpdated(uint256 _poolIndex, address _userAddress, uint256 _amount);

    /**
     * @notice emitted when user claims reward tokens for a particulat interval of a pool
     * @param _rewardIntervalId The pool index for which the amount updated
     * @param _poolIndex The user address for which the borrow amount updated
     * @param _userAddress The amount of tokens borrowed during a reward interval
     */
    event RewardsClaimed(uint256 _rewardIntervalId, uint256 _poolIndex, address _userAddress);
    /**
     * @dev Only admin can call functions marked by this modifier.
     */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Can be used only by admin");
        _;
    }

    /**
     * @dev Only pool can call functions marked by this modifier.
     */
    modifier onlyPool(uint256 _poolIndex) {
        PoolDetails memory poolDetails = BruFactory(factoryAddress).getPoolDetails(_poolIndex);
        require(poolDetails.proxyPoolAddress == msg.sender, "Only pools can access");
        _;
    }

    /**
     * @notice Initializes necessary contract addresses
     * @param _adminAddress The address of multisig wallet
     * @param _factoryAddress The address of factory contract
     * @param _bruToken address of bru token
     * @param _tokenVestingAddress The address of token vesting contract
     * @param _bruOracleAddress The address of bru oracle contract
     */
    function initialize(
        address _adminAddress,
        address _factoryAddress,
        address _bruToken,
        address _tokenVestingAddress,
        address _bruOracleAddress
    ) external virtual initializer {
        require(
            _adminAddress != address(0) &&
                _factoryAddress != address(0) &&
                _bruToken != address(0) &&
                _tokenVestingAddress != address(0) &&
                _bruOracleAddress != address(0),
            "Invalid Address"
        );
        adminAddress = _adminAddress;
        factoryAddress = _factoryAddress;
        bruToken = _bruToken;
        tokenVestingAddress = _tokenVestingAddress;
        bruOracleAddress = _bruOracleAddress;
        emission = 1000000000000000000000;
        secondsPerYear = 31536000;
    }

    /**
     * @notice gets latest reward interval for a pool index
     * @param _poolIndex the pool index for which the status of the reward interval is to checked
     */
    function getLatestRewardIntervalForPool(uint256 _poolIndex) public view virtual returns (RewardDetails memory) {
        return rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]];
    }

    /**
     * @notice used to calculate rewardAPY which is used while rewards distribution
     */
    function getRewardAPY() public view virtual returns (uint256) {
        uint256 tokenPrice = BruOracle(bruOracleAddress).getBruTokenPrice();
        uint256 numerator = emission * tokenPrice * secondsPerYear;
        uint256 tokenSupply = Token(BruFactory(factoryAddress).bruTokenAddress()).initialTokenSupply();
        uint256 denominator = tokenSupply * 1440 * 10;
        uint256 rewardAPY = numerator / denominator;
        return rewardAPY;
    }

    /**
     * @notice used to changes the amount of emitted tokens during reward interval
     * @param _emission the new emission value in the contract
     */
    function changeEmission(uint256 _emission) external virtual onlyAdmin {
        emission = _emission;
        emit EmissionChanged(emission);
    }

    /**
     * @notice starts rewards interval for pool
     * @param _poolIndex the pool index for which the reward interval is to be started
     * @param _durationInDays The duration for which the reward interval will be active
     */
    function startRewardsForPool(uint256 _poolIndex, uint256 _durationInDays) external virtual onlyAdmin {
        require(!rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]].isActive, "An interval is already active");
        rewardIntervalIds[_poolIndex] += 1;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _durationInDays * 86400;
        PoolDetails[] memory allPoolDetails = BruFactory(factoryAddress).getAllPoolDetails();
        uint256 poolTokenAmount = emission / allPoolDetails.length;
        rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]] = RewardDetails(
            poolTokenAmount,
            block.timestamp,
            endTime,
            0,
            0,
            true
        );
        PoolDetails memory poolDetails = BruFactory(factoryAddress).getPoolDetails(_poolIndex);
        uint256 rewardAPY = getRewardAPY();
        BruPool(poolDetails.proxyPoolAddress).startRewards(rewardAPY);
        TokenVestingBru(tokenVestingAddress).distributeRewards(emission);
        emit PoolRewardsStarted(_poolIndex, rewardAPY);
    }

    /**
     * @notice stops rewards interval for pool
     * @param _poolIndex the pool index for which the reward interval is to be stopped
     */
    function stopRewardsForPool(uint256 _poolIndex) external virtual onlyAdmin {
        require(rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]].isActive, "rewards should be active");
        require(
            block.timestamp > rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]].endTime,
            "Rewards duration not completed"
        );
        rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]].isActive = false;
        PoolDetails memory poolDetails = BruFactory(factoryAddress).getPoolDetails(_poolIndex);
        BruPool(poolDetails.proxyPoolAddress).stopRewards();
        emit PoolRewardsStopped(_poolIndex);
    }

    /**
     * @notice checks if reward interval is active for a pool index
     * @param _poolIndex the pool index for which the status of the reward interval is to checked
     */
    function getRewardStatusForPool(uint256 _poolIndex) external view virtual returns (bool) {
        return
            rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]].isActive &&
            (rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]].endTime >= block.timestamp);
    }

    /**
     * @notice updates user's lent amount when a reward interval is active for a particular pool
     * @param _poolIndex the pool index for which the amount is to be added
     * @param _userAddress The user address for which the lend amount is to be updated
     * @param _amount The amount of tokens deposited during a reward interval
     */
    function updateLendAmountInRewardsInterval(
        uint256 _poolIndex,
        address _userAddress,
        uint256 _amount
    ) external virtual onlyPool(_poolIndex) {
        uint256 id = rewardIntervalIds[_poolIndex];
        userBalance[_poolIndex][id][_userAddress].lendAmount += _amount;
        rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]].totalLendAmount += _amount;
        emit LendAmountUpdated(_poolIndex, _userAddress, _amount);
    }

    /**
     * @notice updates user's borrowed amount when a reward interval is active for a particular pool
     * @param _poolIndex the pool index for which the amount is to be added
     * @param _userAddress The user address for which the borrowed amount is to be updated
     * @param _amount The amount of tokens borrowed by user during a reward interval
     */
    function updateBorrowAmountInRewardsInterval(
        uint256 _poolIndex,
        address _userAddress,
        uint256 _amount
    ) external virtual onlyPool(_poolIndex) {
        uint256 id = rewardIntervalIds[_poolIndex];
        userBalance[_poolIndex][id][_userAddress].borrowedAmount += _amount;
        rewardDetails[_poolIndex][rewardIntervalIds[_poolIndex]].totalBorrowedAmount += _amount;
        emit BorrowAmountUpdated(_poolIndex, _userAddress, _amount);
    }

    /**
     * @notice It is used by users to claim their reward bru tokens from the reward contracts.
     * @param _poolIndex the pool index for which the users want to claim tokens
     * @param _rewardIntervalId The reward interval from which the users want to claim tokens.
     */

    function claimRewards(uint256 _poolIndex, uint256 _rewardIntervalId) external virtual {
        require(rewardDetails[_poolIndex][_rewardIntervalId].startTime > 0, "Rewards interval does not exist");

        require(!userClaims[_poolIndex][_rewardIntervalId][msg.sender], "Rewards has already been claimed");
        RewardDetails memory rewardDetailsForPool = rewardDetails[_poolIndex][_rewardIntervalId];

        require(
            block.timestamp > rewardDetails[_poolIndex][_rewardIntervalId].endTime,
            "Rewards duration not completed"
        );
        uint256 bruTokenAmountForLend;
        uint256 bruTokenAmountForBorrow;

        if (rewardDetailsForPool.totalLendAmount > 0) {
            uint256 userPercentageInLend = ((userBalance[_poolIndex][_rewardIntervalId][msg.sender].lendAmount) *
                10**18) / (rewardDetailsForPool.totalLendAmount);

            bruTokenAmountForLend = (userPercentageInLend * (rewardDetailsForPool.rewardTokens / 2)) / 10**18;
        }

        if (rewardDetailsForPool.totalBorrowedAmount > 0) {
            uint256 userPercentageInBorrow = (userBalance[_poolIndex][_rewardIntervalId][msg.sender].borrowedAmount *
                10**18) / (rewardDetailsForPool.totalBorrowedAmount);
            bruTokenAmountForBorrow = (userPercentageInBorrow * (rewardDetailsForPool.rewardTokens / 2)) / 10**18;
        }

        uint256 totalAmount = bruTokenAmountForBorrow + bruTokenAmountForLend;

        userClaims[_poolIndex][_rewardIntervalId][msg.sender] = true;
        IERC20(bruToken).safeTransfer(msg.sender, totalAmount);
        emit RewardsClaimed(_rewardIntervalId, _poolIndex, msg.sender);
    }

    /**
     * @dev Checks the wallet address which initiates the upgrade transaction for BruRewards contract
     * @param _newImplementation Address of the new implementation contract which is used for upgradation.
     */
    function _authorizeUpgrade(address _newImplementation) internal view override {
        require(msg.sender == adminAddress, "Only admin allowed");
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Interest token contract
 * @author Bru-finance team
 * @notice It is an ERC20 token used to show users how much interest they have accured which can be redeemed later.
 */
contract InterestToken is ERC20 {
    address internal poolAddress; //address of the pool
    address internal admin; // address of Multisig wallet
    string private tokenName; // name of token
    /**
     * @notice Emmitted after changeName function executed successfully
     * @param _newName The new changed name
     * @param _by The account address of the user who changed the name
     */
    event TokenNameChanged(string _newName, address _by);
    /**
     * @notice Emmitted after setPoolAddress function executed successfully
     * @param _poolAddress The address of the pool
     */
    event PoolAddressUpdated(address _poolAddress);

    /**
     * @dev Only admin can call functions marked by this modifier.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    /**
     * @dev Only pool can call functions marked by this modifier.
     */
    modifier onlyPool() {
        require(msg.sender == poolAddress, "Only Pool");
        _;
    }

    /**
     * @notice a constructor used to initailize the necessary variables
     * @param _tokenName The name of the token
     * @param _symbol  The symbol of the token
     * @param _adminAddress address of Multisig wallet
     */
    constructor(
        string memory _tokenName,
        string memory _symbol,
        address _adminAddress
    ) ERC20(_tokenName, _symbol) {
        require(_adminAddress != address(0), "Invalid address");
        tokenName = _tokenName;
        admin = _adminAddress;
    }

    /**
     * @notice Used to get the name of the token
     * @return The name of the token
     */
    function name() public view override returns (string memory) {
        return tokenName;
    }

    /**
     * @notice Changes the name of the token
     * @dev only called by the admin
     * @param _tokenName The new name of the token
     */
    function changeName(string memory _tokenName) external onlyAdmin {
        tokenName = _tokenName;
        emit TokenNameChanged(_tokenName, msg.sender);
    }

    /**
     * @notice Mints specified amount of tokens
     * @dev only called from the Pool contract
     * @param _userAddress The address of the user
     * @param _mintAmount The amount of token to mint
     */
    function mint(address _userAddress, uint256 _mintAmount) external onlyPool {
        _mint(_userAddress, _mintAmount);
    }

    /**_
     * @notice Sets the pool address
     * @dev only called by the admin
     * @param _poolAddress The address of the pool contract
     */
    function setPoolAddress(address _poolAddress) external onlyAdmin {
        require(_poolAddress != address(0), "Invalid address");
        poolAddress = _poolAddress;
        emit PoolAddressUpdated(poolAddress);
    }

    /**
     * @notice Burns specified amount of tokens
     * @dev only called from the pool contract
     * @param _userAddress The address of the user
     * @param _burnAmount The amount of token to be burned
     */
    function burn(address _userAddress, uint256 _burnAmount) external onlyPool {
        _burn(_userAddress, _burnAmount);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Pool Token contract
 * @author Bru-finance team
 * @notice This contract is ERC20 standard token contract that are given for liquidity providers in the pool.
 *            This token act as receipt, allowing user to claim their original stake and interest earned.
 */
contract PoolToken is ERC20 {
    address internal poolAddress; // address of pool address
    address internal admin; // address of Multisig wallet
    string private name_; // name of token

    /**
     * @notice Emmitted after changeName function executed successfully
     * @param _newName The new changed name
     * @param _by The account address of the user who changed the name
     */
    event NameChanged(string _newName, address _by);
    /**
     * @notice Emmitted after setPoolAddress function executed successfully
     * @param _poolAddress The address of the pool
     */
    event PoolAddressUpdated(address _poolAddress);

    /**
     * @dev Only admin can call functions marked by this modifier.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    /**
     * @dev Only pool can call functions marked by this modifier.
     */
    modifier onlyPool() {
        require(msg.sender == poolAddress, "Only Pool");
        _;
    }

    /**
     * @notice a constructor used to initailize the necessary variables in the contract
     * @param _tokenName The name of the token
     * @param _symbol  The symbol of the token
     * @param _adminAddress The address of the admin
     */
    constructor(
        string memory _tokenName,
        string memory _symbol,
        address _adminAddress
    ) ERC20(_tokenName, _symbol) {
        require(_adminAddress != address(0), "Invalid address");
        admin = _adminAddress;
        name_ = _tokenName;
    }

    /**
     * @notice Used to get the name of the token
     * @return The name of the token
     */
    function name() public view override returns (string memory) {
        return name_;
    }

    /**
     * @notice Changes the name of the token
     * @dev only called by the admin
     * @param _tokenName The new name of the token
     */
    function changeName(string memory _tokenName) external onlyAdmin {
        name_ = _tokenName;
        emit NameChanged(_tokenName, msg.sender);
    }

    /**
     * @notice Mints specified amount of tokens
     * @dev only called from the Pool contract
     * @param _userAddress The address of the user
     * @param _mintAmount The amount of token to mint
     */
    function mint(address _userAddress, uint256 _mintAmount) external onlyPool {
        _mint(_userAddress, _mintAmount);
    }

    /**
     * @notice Burns specified amount of tokens
     * @dev only called from the pool contract
     * @param _userAddress The address of the user
     * @param _burnAmount The amount of token to be burned
     */
    function burn(address _userAddress, uint256 _burnAmount) external onlyPool {
        _burn(_userAddress, _burnAmount);
    }

    /**
     * @notice Sets the pool address
     * @dev only called by the admin
     * @param _poolAddress The address of the pool contract
     */
    function setPoolAddress(address _poolAddress) external onlyAdmin {
        require(_poolAddress != address(0), "Invalid address");
        poolAddress = _poolAddress;
        emit PoolAddressUpdated(poolAddress);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

/**
 * @title Bru Token contract
 * @author Bru-finance team
 * @notice ERC20 standard token
 */
contract Token is ERC20Snapshot {
    uint256 public initialTokenSupply; // initial total supply of the tokens
    address internal vestingContractAddress; // contract address (vesting)
    address internal NIIWalletAddress; // contract address (NIIwallet)
    address internal admin; //address of admin
    mapping(address => bool) public enableMint; // mapping of addresses those are allowed to mint
    mapping(uint256 => uint256) public snapshotIds; // mapping to store id of the snapshot

    /**
     * @dev Only admin can call functions marked by this modifier.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Can be used only by adminAddress");
        _;
    }

    /**
     * @dev Only NIIwallet or admin or vestingContract can call functions marked by this modifier.
     */
    modifier checkAddress() {
        require(
            msg.sender == admin || msg.sender == NIIWalletAddress || msg.sender == vestingContractAddress,
            "usage restricted"
        );
        _;
    }

    /**
     * @notice It is use to initialize teh required values to the contract
     * @param _name name of token
     * @param _symbol symbol of token
     * @param _initialSupply initial supply of token
     * @param _vestingContractAddress address of vesting contract
     * @param _multisigAddress address of multisig address
     * @param _NIIWalletAddress address of NIIMargin contract
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _vestingContractAddress,
        address _multisigAddress,
        address _NIIWalletAddress
    ) ERC20(_name, _symbol) {
        require(
            _vestingContractAddress != address(0) && _multisigAddress != address(0) && _NIIWalletAddress != address(0),
            "Invalid address"
        );
        initialTokenSupply = _initialSupply;
        _mint(_vestingContractAddress, _initialSupply);
        vestingContractAddress = _vestingContractAddress;
        enableMint[_vestingContractAddress] = true;
        NIIWalletAddress = _NIIWalletAddress;
        admin = _multisigAddress;
    }

    /**
     * @notice returns initial supply of tokens
     */
    function getInitialSupply() external view returns (uint256) {
        return initialTokenSupply;
    }

    /**
     * @notice The function is used to mint new tokens to a specific address.
     * @param _userAddress Address of the user whom we have to transfer the new minted tokens
     * @param _mintamount The amount of new tokens to be minted
     */
    function mintNew(address _userAddress, uint256 _mintamount) external {
        require(enableMint[msg.sender], "not allowed to mint");
        _mint(_userAddress, _mintamount);
    }

    /**
     * @notice The function is used to burn tokens to a specific address.
     * @param _userAddress Address of the user whom we have to transfer the new minted tokens
     * @param _burnAmount The amount of tokens to be burned
     */
    function burn(address _userAddress, uint256 _burnAmount) external {
        require(enableMint[msg.sender], "not allowed to burn");
        _burn(_userAddress, _burnAmount);
    }

    /**
     * @notice enables minting for given address
     * @param _userAddress Address of the user
     */
    function enableMinting(address _userAddress) external onlyAdmin {
        enableMint[_userAddress] = true;
    }

    /**
     * @notice disables minting for given address
     * @param _userAddress Address of the user
     */
    function disableMinting(address _userAddress) external onlyAdmin {
        enableMint[_userAddress] = false;
    }

    /**
     * @notice creates snapshot which can be used later to make some decisions
     */
    function createSnapshot() external checkAddress returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 date = currentTime - (currentTime % 86400);
        uint256 snapshotId = _snapshot();
        snapshotIds[date] = snapshotId;
        return date;
    }

    /**
     * @notice returns balance of user at given date
     * @param _userAddress address of the user
     * @param _date date for snapshot mapping key
     * @return balance of the user from the snapshot
     */
    function balanceOfAtDate(address _userAddress, uint256 _date) external view returns (uint256) {
        return balanceOfAt(_userAddress, snapshotIds[_date]);
    }

    /**
     * @notice returns total supply at a given date
     * @param _date date for snapshot mapping key
     * @return total supply from the snapshot
     */
    function totalSupplyOfAtDate(uint256 _date) external view returns (uint256) {
        return totalSupplyAt(snapshotIds[_date]);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";
import "../core/BruPool.sol";
import "../core/BruFactory.sol";
import "../core/BruOracle.sol";

/**
 * @title TokenVestingBur contract
 * @author Bru-finance team
 * @notice Is a contract that locks and distributes purchased tokens within a time frame(vesting period).
 *		   And it delays access to the asset being offered.
 */

contract TokenVestingBru is Ownable, ReentrancyGuard, Initializable, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    uint256 private constant QUARTER_TIME = 7889229; // quarter of 3 months in seconds
    uint256 private constant MINIMUM_POOL_TVL = 10**8; // minimum TVL amount above which new tokens can be minted
    uint256 public maxVestingSchedules; // per address max allowed vesting schedules
    uint256 public maxCategories; // max categories

    uint256 public totalPercentageUsed; // total % used <=100
    uint256 internal lastStarted; // last time the quarter started
    uint256 private vestingSchedulesTotalAmount; // total amount vested
    uint256 internal categoryId; //category Id counter
    uint256 public quarterId; // quarterId counter
    address internal adminAddress; //address of admin
    address internal NIIWalletAddress; // address of NIIwallet
    address internal bruRewardsAddress; // address of Rewards wallet
    address internal factoryAddress; // address of factory contract
    address internal bruOracleAddress; // address of bruOracle
    address internal deployer; // address of the owner who deploys the contract
    bool internal pause; // pause boolean for major functionalities
    Token public token; // bru token contract
    bytes32[] private vestingSchedulesIds; // array of vesting schedule Ids created till time

    struct VestingSchedule {
        bool initialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // cliff period in seconds
        uint256 cliff;
        // start time of the vesting period
        uint256 start;
        // duration of the vesting period in seconds
        uint256 duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodSeconds;
        // whether or not the vesting is revocable
        bool revocable;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
        // whether or not the vesting has been revoked
        bool revoked;
    }

    struct TokenDistribution {
        uint256 tokenAmountleft;
        uint256 tokenPercentage;
    }

    struct Records {
        uint256 initialQuarterBalance;
        uint256 finalQuarterBalance;
        uint256 timeStamp;
    }

    struct Categories {
        string categoryName;
        address[] memberAddresses;
        uint256 cliff;
        // duration of the vesting period in seconds
        uint256 duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodSeconds;
        // whether or not the vesting is revocable
        bool revocable;
    }

    mapping(uint256 => uint256) internal tokensBurnedPerQuarter; // amount of token burned in a quarter
    mapping(uint256 => Records) public quarterTVLMapping; //mapping for TVL of every quarter
    mapping(bytes32 => VestingSchedule) private vestingSchedules; // mapping of vesting schedule Id to the details of the vesting schedule
    mapping(address => uint256) private holdersVestingCount; // total vestin count of a given holder
    mapping(uint256 => Categories) public categoryMapping; // category Id to description mapping
    mapping(uint256 => TokenDistribution) public distributionMapping; // category Id to its token distribution mapping
    mapping(uint256 => bool) public existsMapping; // to confirm is cateogry Id mapping exists or not .
    mapping(uint256 => uint256) QuarterBalanceForIssuance; // amount issued for 3 categories
    mapping(address => uint256[]) internal memberCategoryMapping; // member belonging to a particular category mapping
    mapping(bytes32 => uint256) public vestingScheduleCategoryMapping; // vesting schedules to category Mapping
    /**
     * @notice Emitted after a category is added
     * @param _memberAddress address of the new member in category
     * @param _categoryID Id oof the category
     */
    event AddAddressForCategory(address _memberAddress, uint256 _categoryID);
    /**
     * @notice Emitted after a category is created
     * @param _categoryName name of category
     * @param _memberAddresses array of member addresses to be added
     * @param _cliff of the vesting schedule for category
     * @param _duration of vesting schedule for category
     * @param _slicePeriodSeconds slice period in seconds
     * @param _revocable category vesting schedules revokable or not bool.
     * @param _categoryId category Id
     */
    event CategoryCreated(
        string _categoryName,
        address[] _memberAddresses,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _categoryId
    );
    /**
     * @notice Emitted after new tokens are issues
     * @param _amount number of tokens added
     * @param _sentAddress address where the new tokens are added
     */
    event TokensIssued(uint256 _amount, address _sentAddress);
    /**
     * @notice Emitted when vesting schedule is created
     * @param _vestingSchedule vesting schedule details
     * @param _categoryId Id of category
     */
    event VestingScheduleCreation(VestingSchedule _vestingSchedule, uint256 _categoryId);
    /**
     * @notice Emitted when vesting schedule is revoked
     * @param _vestingSchedule vesting schedule details
     * @param _revoked bool
     */
    event RevokedSchedule(VestingSchedule _vestingSchedule, bool _revoked);
    /**
     * @notice Emitted when pause status is changed
     * @param _status value of new status
     */
    event PauseStatusChanged(bool _status);
    /**
     * @notice Emitted when new token distribution is added
     * @param _distribution new token distribution
     */
    event TokenDistributionAdded(TokenDistribution _distribution);
    /**
     * @notice Emitted TVL is recorded
     * @param _quarterId Id of the quarter
     * @param _time  when tvl was recorded
     * @param _amount tvl amount
     */
    event RecordedTVL(uint256 _quarterId, uint256 _time, uint256 _amount);
    /**
     * @notice Emitted when quarter starts
     * @param _quarterId Id of the quarter
     * @param _timestamp  when quarter started
     */
    event QuarterStart(uint256 _quarterId, uint256 _timestamp);
    /**
     * @notice Emitted when max schedules allowed value changed
     * @param _maxschedules new value of max schedules
     */
    event VestingScheduleMaxChanged(uint256 _maxschedules);
    /**
     * @notice Emitted when max categories allowed value changed
     * @param _maxcategories new value of max categories
     */
    event CategoriesMaxChanged(uint256 _maxcategories);

    event Released(uint256 _amount); // event fo amount released
    /**
     * @notice Emitted a BruRewards contract start a rewards interval for a pool
     * @param _emissionAmount new value of max categories
     */
    event RewardsDistributed(uint256 _emissionAmount);

    /**
     * @dev Only owner can call functions marked by this modifier.
     *
     */
    modifier onlyDeployer() {
        require(msg.sender == deployer, "only deployer allowed");
        _;
    }

    /**
     * @dev Only admin can call functions marked by this modifier.
     *
     */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "only admin allowed");
        _;
    }

    /**
     * @dev checks the pause condition for functions .
     *
     */
    modifier checkPauseStatus() {
        require(!pause, "Core functionalities disabled");
        _;
    }

    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     */
    modifier onlyIfVestingScheduleNotRevoked(bytes32 _vestingScheduleId) {
        require(vestingSchedules[_vestingScheduleId].initialized);
        require(!vestingSchedules[_vestingScheduleId].revoked);
        _;
    }

    /**
     * @notice Initializes the deployed contract with given parameters
     * @param _token The address of the token
     * @param _adminAddress The address of admin
     * @param _NIIWalletAddress The address of NII Wallet contract
     * @param _bruRewardsAddress The address of BruReward contract
     * @param _factoryAddress The address of Factory contract
     * @param _bruOracleAddress The address of BruOracle contract
     */
    function initialize(
        address _token,
        address _adminAddress,
        address _NIIWalletAddress,
        address _bruRewardsAddress,
        address _factoryAddress,
        address _bruOracleAddress
    ) external virtual initializer {
        require(
            _token != address(0) &&
                _adminAddress != address(0) &&
                _NIIWalletAddress != address(0) &&
                _bruRewardsAddress != address(0) &&
                _factoryAddress != address(0) &&
                _bruOracleAddress != address(0),
            "Invalid Address"
        );
        token = Token(_token);
        adminAddress = _adminAddress;
        categoryId = 1;
        maxVestingSchedules = 5;
        maxCategories = 10;
        NIIWalletAddress = _NIIWalletAddress;
        bruRewardsAddress = _bruRewardsAddress;
        factoryAddress = _factoryAddress;
        bruOracleAddress = _bruOracleAddress;
        deployer = msg.sender;
    }

    /**
     * @notice Release vested amount of tokens.
     * @param _vestingScheduleId the vesting schedule identifier
     * @param _amount the amount to release
     */
    function release(bytes32 _vestingScheduleId, uint256 _amount)
        public
        onlyIfVestingScheduleNotRevoked(_vestingScheduleId)
        checkPauseStatus
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == deployer;
        require(isBeneficiary || isOwner, "TokenVesting: only beneficiary and owner can release vested tokens");
        uint256 vestedAmount = computeReleasableAmount(vestingSchedule);

        require(vestedAmount >= _amount, "TokenVesting: cannot release tokens, not enough vested tokens");
        vestingSchedule.released = vestingSchedule.released + _amount;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - _amount;
        IERC20(address(token)).safeTransfer(vestingSchedule.beneficiary, _amount);
        emit Released(_amount);
    }

    /**
     * @dev Returns the number of vesting schedules managed by this contract.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(bytes32 _vestingScheduleId) public view returns (VestingSchedule memory) {
        return vestingSchedules[_vestingScheduleId];
    }

    /**
     * @dev Computes the vesting schedule identifier for an address and an index.
     * @param _holder address of the holder
     * @param _index index in array
     * @return vesting schedule Id
     */
    function computeVestingScheduleIdForAddressAndIndex(address _holder, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_holder, _index));
    }

    /**
     * @dev Returns the number of vesting schedules associated to a beneficiary.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }

    /**
     * @dev Returns the vesting schedule id at the given index.
     * @return the vesting id
     */
    function getVestingIdAtIndex(uint256 _index) external view returns (bytes32) {
        require(_index < getVestingSchedulesCount(), "TokenVesting: index out of bounds");
        return vestingSchedulesIds[_index];
    }

    /**
     * @notice Returns the vesting schedule information for a given holder and index.
     * @return the vesting schedule structure information
     */
    function getVestingScheduleByAddressAndIndex(address _holder, uint256 _index)
        external
        view
        returns (VestingSchedule memory)
    {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(_holder, _index));
    }

    /**
     * @notice Returns the vesting schedule total amount noted.
     * @return the vesting schedule total amount
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @notice Returns the token contract address
     * @return token contract address of bru token
     */
    function getToken() external view returns (address) {
        return address(token);
    }

    /**
     * @notice sets the paramters of the category for the given categoryID
     * @param _categoryName name of category
     * @param _memberAddresses the array of address of the members of category
     * @param _cliff Cliff for the category
     * @param _duration duration for the category
     * @param _slicePeriodSeconds slice period of the category
     * @param _revocable property of category
     */
    function setCategoryParams(
        string memory _categoryName,
        address[] memory _memberAddresses,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable
    ) external onlyDeployer {
        require(categoryId < maxCategories + 1, "max categories reaches");
        categoryMapping[categoryId] = Categories(
            _categoryName,
            _memberAddresses,
            _cliff,
            _duration,
            _slicePeriodSeconds,
            _revocable
        );
        existsMapping[categoryId] = true;
        for (uint256 i = 0; i < _memberAddresses.length; i++) {
            memberCategoryMapping[_memberAddresses[i]].push(categoryId);
            emit AddAddressForCategory(_memberAddresses[i], categoryId);
        }
        categoryId++;
        emit CategoryCreated(
            _categoryName,
            _memberAddresses,
            _cliff,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            categoryId
        );
    }

    /**
     * @notice Returns the category parameters
     * @return returns struct of category params
     */
    function getCategoryParams(uint256 _categoryId) external view returns (Categories memory) {
        return categoryMapping[_categoryId];
    }

    /**
     * @notice add member address to a category
     * @param _walletAddress address of the member
     * @param _categoryId category Id of the category
     */

    function addAddressToCategory(address _walletAddress, uint256 _categoryId) external onlyDeployer {
        require(_walletAddress != address(0), "zero address not allowed");
        categoryMapping[_categoryId].memberAddresses.push(_walletAddress);
        memberCategoryMapping[_walletAddress].push(categoryId);
        emit AddAddressForCategory(_walletAddress, _categoryId);
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start start time of the vesting
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function createVestingScheduleForCategory(
        uint256 _amount,
        uint256 _start,
        address _beneficiary,
        uint256 _categoryId
    ) external onlyDeployer checkPauseStatus {
        bool _temp = false;
        for (uint256 j = 0; j < memberCategoryMapping[_beneficiary].length; j++) {
            if (memberCategoryMapping[_beneficiary][j] == _categoryId) _temp = true;
        }
        if (_categoryId != 0 && _temp) {
            vestingInternal(
                _amount,
                categoryMapping[_categoryId].duration,
                categoryMapping[_categoryId].slicePeriodSeconds,
                _categoryId,
                _beneficiary,
                categoryMapping[_categoryId].cliff,
                _start,
                categoryMapping[_categoryId].revocable
            );
        } else {
            revert("category passed as 0 or beneficiary does not belong to this category");
        }
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start start time of the vesting period
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
     * @param _revocable whether the vesting is revocable or not
     * @param _amount total amount of tokens to be released at the end of the vesting
     * @param _categoryId Id of the category to which it belongs
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount,
        uint8 _categoryId
    ) external onlyDeployer checkPauseStatus nonReentrant {
        categoryMapping[_categoryId].memberAddresses.push(_beneficiary);
        memberCategoryMapping[_beneficiary].push(_categoryId);
        vestingInternal(_amount, _duration, _slicePeriodSeconds, _categoryId, _beneficiary, _cliff, _start, _revocable);
    }

    /**
     * @notice changes the max allowed vesting schedules for single address
     * @param _newMaxSchedule new value for  max allowed vesting schedules
     */
    function changeMaxVestingSchedules(uint256 _newMaxSchedule) external virtual onlyAdmin {
        maxVestingSchedules = _newMaxSchedule;
        emit VestingScheduleMaxChanged(_newMaxSchedule);
    }

    /**
     * @notice changes the max allowed categories
     * @param _newMaxCategories new value for max allowed categories
     */
    function changeMaxCategories(uint256 _newMaxCategories) external virtual onlyAdmin {
        maxCategories = _newMaxCategories;
        emit CategoriesMaxChanged(_newMaxCategories);
    }

    /**
     * @notice Revokes the vesting schedule for given identifier.
     * @param _vestingScheduleId the vesting schedule identifier
     */
    function revoke(bytes32 _vestingScheduleId, uint256 _categoryId)
        external
        onlyDeployer
        onlyIfVestingScheduleNotRevoked(_vestingScheduleId)
        checkPauseStatus
    {
        require(
            vestingScheduleCategoryMapping[_vestingScheduleId] == _categoryId,
            "vesting schedule does not belong to this category"
        );
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingScheduleId];
        require(vestingSchedule.revocable, "TokenVesting: vesting is not revocable");
        uint256 vestedAmount = computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
            release(_vestingScheduleId, vestedAmount);
        }
        uint256 unreleased = vestingSchedule.amountTotal - vestingSchedule.released;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - unreleased;

        for (uint256 j = 0; j < memberCategoryMapping[vestingSchedule.beneficiary].length; j++) {
            distributionMapping[_categoryId].tokenAmountleft += unreleased;
        }
        vestingSchedule.revoked = true;
        emit RevokedSchedule(vestingSchedule, vestingSchedule.revoked);
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param _amount the amount to withdraw
     */
    function withdraw(uint256 _amount) external onlyDeployer {
        require(this.getWithdrawableAmount() >= _amount, "TokenVesting: not enough withdrawable funds");
        IERC20(address(token)).safeTransfer(deployer, _amount);
    }

    /**
     * @notice change the pause status of the contract
     */
    function changePauseStatus() external onlyAdmin {
        pause = !pause;
        emit PauseStatusChanged(pause);
    }

    /**
     * @notice adding the token distribution of a given category.
     * @param _categoryId category Id for adding distribution.
     * @param _tokenPercentage the token percentage of a given category
     */
    function addTokenDistribution(uint256 _categoryId, uint256 _tokenPercentage) external onlyAdmin nonReentrant {
        require(distributionMapping[_categoryId].tokenPercentage == 0, "distribution already added");
        require(totalPercentageUsed + _tokenPercentage <= 100, "percentage not allowed");
        distributionMapping[_categoryId] = TokenDistribution(
            (token.getInitialSupply() * (_tokenPercentage)) / (100),
            _tokenPercentage
        );
        totalPercentageUsed += _tokenPercentage;
        emit TokenDistributionAdded(distributionMapping[_categoryId]);
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @param _vestingScheduleId schedule Id of the vesting schedule
     * @return the vested amount
     */
    function computeReleasableAmount(bytes32 _vestingScheduleId)
        external
        view
        onlyIfVestingScheduleNotRevoked(_vestingScheduleId)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingScheduleId];
        return computeReleasableAmount(vestingSchedule);
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() external view returns (uint256) {
        return token.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    /**
     * @dev Computes the next vesting schedule identifier for a given holder address.
     * _holder address of the vesting schedule holder
     */
    function computeNextVestingScheduleIdForHolder(address _holder) external view returns (bytes32) {
        return computeVestingScheduleIdForAddressAndIndex(_holder, holdersVestingCount[_holder]);
    }

    /**
     * @notice records TVL for a given time and quarter
     */
    function recordTVL() external onlyDeployer {
        require(
            block.timestamp - quarterTVLMapping[quarterId].timeStamp >= QUARTER_TIME,
            "3 months have not passed yet"
        );
        if (quarterTVLMapping[quarterId].initialQuarterBalance == 0) {
            quarterTVLMapping[quarterId].initialQuarterBalance = calculateSum();
            emit RecordedTVL(
                quarterId,
                quarterTVLMapping[quarterId].timeStamp,
                quarterTVLMapping[quarterId].initialQuarterBalance
            );
        } else if (quarterTVLMapping[quarterId].finalQuarterBalance == 0) {
            quarterTVLMapping[quarterId].finalQuarterBalance = calculateSum();

            if (
                quarterTVLMapping[quarterId].initialQuarterBalance > MINIMUM_POOL_TVL &&
                quarterTVLMapping[quarterId].finalQuarterBalance > MINIMUM_POOL_TVL &&
                quarterTVLMapping[quarterId].finalQuarterBalance > quarterTVLMapping[quarterId].initialQuarterBalance
            ) {
                uint256 temp = quarterTVLMapping[quarterId].finalQuarterBalance -
                    quarterTVLMapping[quarterId].initialQuarterBalance;
                uint256 percentage = ((temp) * (10**20)) / (quarterTVLMapping[quarterId].initialQuarterBalance);
                issueTokens(percentage);
            }
            emit RecordedTVL(
                quarterId,
                quarterTVLMapping[quarterId].timeStamp,
                quarterTVLMapping[quarterId].finalQuarterBalance
            );
        } else {
            revert("TVL already recorded for this quater");
        }
        quarterTVLMapping[quarterId].timeStamp = block.timestamp;
    }

    /**
     * @notice starts quarter
     */
    function startQuarter() external onlyDeployer {
        require(block.timestamp - lastStarted >= QUARTER_TIME);
        quarterId++;
        lastStarted = block.timestamp;
        emit QuarterStart(quarterId, lastStarted);
    }

    /**
     * @notice it is used to transfer token to the BruRewards contract
     * @param _emissionAmount the amount of token to be emmited during a reward interval
     */
    function distributeRewards(uint256 _emissionAmount) external {
        require(msg.sender == bruRewardsAddress, "only BruRewards can access this");
        distributionMapping[1].tokenAmountleft -= _emissionAmount;
        IERC20(address(token)).safeTransfer(bruRewardsAddress, _emissionAmount);
        emit RewardsDistributed(_emissionAmount);
    }

    /*
     * @notice issues new token according to last quarter TVL.
     * @param _risePercentage percentage growth in last quarter.
     */
    function issueTokens(uint256 _risePercentage) internal {
        uint256 totalAmount;
        uint256 toMint;

        totalAmount = QuarterBalanceForIssuance[quarterId];

        uint256 calculateTVLamount = (totalAmount * (_risePercentage)) / (10**20);
        uint256 burntAmount = (tokensBurnedPerQuarter[quarterId] * (995)) / (1000);
        if (calculateTVLamount < burntAmount) {
            toMint += calculateTVLamount;
        } else {
            toMint += burntAmount;
        }
        token.mintNew(address(this), toMint);
        emit TokensIssued(toMint, address(this));
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @param _vestingSchedule vesting scheudle structure to calculate amount .
     * @return the amount of releasable tokens
     */
    function computeReleasableAmount(VestingSchedule memory _vestingSchedule) internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if ((currentTime < _vestingSchedule.cliff) || _vestingSchedule.revoked) {
            return 0;
        } else if (currentTime >= _vestingSchedule.start + _vestingSchedule.duration) {
            return _vestingSchedule.amountTotal - _vestingSchedule.released;
        } else {
            uint256 timeFromStart = currentTime - _vestingSchedule.start;
            uint256 secondsPerSlice = _vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / (secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods * (secondsPerSlice);
            uint256 vestedAmount = (_vestingSchedule.amountTotal * (vestedSeconds)) / (_vestingSchedule.duration);
            vestedAmount = vestedAmount - _vestingSchedule.released;
            return vestedAmount;
        }
    }

    /**
     * @notice used to create the vesting schedules with the given info
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _start start time of the vesting period
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
     * @param _revocable whether the vesting is revocable or not
     * @param _amount total amount of tokens to be released at the end of the vesting
     * @param _categoryId Id of the category to which it belongs
     */
    function vestingInternal(
        uint256 _amount,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _categoryId,
        address _beneficiary,
        uint256 _cliff,
        uint256 _start,
        bool _revocable
    ) internal {
        require(existsMapping[_categoryId] && _beneficiary != address(0), "incorrect category/address");
        require(holdersVestingCount[_beneficiary] <= maxVestingSchedules, "max limit for schedules reached");
        require(
            this.getWithdrawableAmount() >= _amount,
            "TokenVesting: cannot create vesting schedule because not sufficient tokens"
        );
        require(distributionMapping[_categoryId].tokenAmountleft >= _amount, "insufficient balance");
        require(_duration > 0, "TokenVesting: duration must be > 0");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(_slicePeriodSeconds >= 1, "TokenVesting: slicePeriodSeconds must be >= 1");
        bytes32 _vestingScheduleId = this.computeNextVestingScheduleIdForHolder(_beneficiary);
        uint256 cliff = _start + _cliff;
        vestingSchedules[_vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            0,
            false
        );
        distributionMapping[_categoryId].tokenAmountleft -= _amount;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + _amount;
        vestingSchedulesIds.push(_vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount + 1;
        vestingScheduleCategoryMapping[_vestingScheduleId] = _categoryId;

        if (_categoryId == 2 || _categoryId == 3 || _categoryId == 4) {
            QuarterBalanceForIssuance[quarterId] += _amount;
        }
        emit VestingScheduleCreation(vestingSchedules[_vestingScheduleId], _categoryId);
    }

    /**
     * @notice calculates sum of TVL of all the pools when called .
     */
    function calculateSum() internal view returns (uint256) {
        PoolDetails[] memory tempPoolDetailsArray = BruFactory(factoryAddress).getAllPoolDetails();
        uint256 sum = 0;
        for (uint32 i = 0; i < tempPoolDetailsArray.length; i++) {
            address[] memory tokenAddressArray = BruPool(tempPoolDetailsArray[i].proxyPoolAddress)
                .getAllowedTokenAddressesArray();
            for (uint8 j = 0; j < tokenAddressArray.length; j++) {
                //fetch the conversion value from oracle according to token address

                uint256 tokenPriceinUSD = uint256(
                    BruOracle(bruOracleAddress).getLatestPriceOfTokenInUSD(tokenAddressArray[j])
                );
                uint256 priceFeedDecimals = BruOracle(bruOracleAddress).getPriceFeedDecimal(tokenAddressArray[j]);
                uint256 temp = IERC20(tokenAddressArray[i]).balanceOf(tempPoolDetailsArray[i].proxyPoolAddress);
                uint256 decimal = ERC20(tokenAddressArray[i]).decimals();
                if (decimal < 18) {
                    temp = temp * 10**(18 - decimal);
                } else if (decimal > 18) {
                    temp = temp / 10**(decimal - 18);
                }
                temp = (temp * tokenPriceinUSD) / 10**(priceFeedDecimals);
                sum += temp;
            }
        }

        return sum / 10**18;
    }

    /**
     * @dev Checks the wallet address which initiates the upgrade transaction for TokenVesting contract
     * @param _newImplementation Address of the new implementation contract which is used for upgradation.
     */
    function _authorizeUpgrade(address _newImplementation) internal view override {
        require(msg.sender == adminAddress, "Only admin allowed");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../vesting/Token.sol";
import "./ReserveWallet.sol";

struct CashFlowDetails {
    uint256 starttime;
    uint256 amountLeft;
    uint256 totalAmountToDistribute;
    address tokenAddress;
    bool status;
}

/**
 * @title NII margin contract
 * @author Bru-finance team
 * @notice Store funds received from fees and interest. The interest expense and other company expenses are given from this wallet
 */
contract NIIMargin is Initializable, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    uint256 public claimId = 0; // claim id
    // @notice The address of Multisig wallet
    address public adminAddress;
    address internal reserveWalletAddress; // address of reserve Wallet
    address internal poolAddress; // address of oool
    address internal owner; // address of owner
    address internal burnContractAddress; // address of Vesting burn contract
    address internal bruTokenAddress; // address of bru token contract
    address internal tokenAddressForCashflow; // address of token in which cashflow will be distributed
    address internal unClaimedWalletAddress; // address of unclaimed Wallet
    mapping(address => mapping(uint256 => bool)) public cashFlowClaimMapping; // mapping to check if the user has claimed their part for a given claimId
    mapping(uint256 => CashFlowDetails) public cashFlowDetailsMapping; // mapping of cashflow details for a given claim Id

    /**
     * @notice Emitted when claim period started
     * @param _claimId claim id
     * @param _tokenAddress address of the token of which we want to divide the cashflow
     */
    event ClaimPeriodStarted(uint256 _claimId, address _tokenAddress);
    /**
     * @notice Emitted when claim period stopped
     * @param _claimId claim id
     */
    event ClaimPeriodStopped(uint256 _claimId);
    /**
     * @notice Emitted when cashflow details are set for a given claimId
     * @param _claimId claim id
     * @param _cashFlowDetails Cashflowdetails structure
     */
    event SetCashflowDetails(uint256 _claimId, CashFlowDetails _cashFlowDetails);
    /**
     * @notice Emitted when user claims a dividend and mapping is updated
     * @param _claimId claim id
     * @param _ownerAddress address Of the owner who claims the dividend
     * @param _claimed boolean for confirming the user has claimed the dividend for given claimId
     */
    event SetCashflowClaimed(bool _claimed, address _ownerAddress, uint256 _claimId);
    /**
     * @dev Only admin can call functions marked by this modifier.
     *
     */

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Can be used only by adminAddress");
        _;
    }

    /**
     * @dev Only unClaimedWalletAddress can call functions marked by this modifier.
     *
     */
    modifier onlyUnClaimedWallet() {
        require(msg.sender == unClaimedWalletAddress, "Only called by unclaimed wallet address");
        _;
    }

    /**
     * @dev Only admin, pool and burn wallet can call functions marked by this modifier.
     *
     */
    modifier onlyPoolOrAdminOrBurnContract() {
        require(
            msg.sender == adminAddress || msg.sender == poolAddress || msg.sender == burnContractAddress,
            "Only allowed by admin or pool or burn contract"
        );
        _;
    }

    /**
     * @notice Initializes the neccessary variables for the contract
     * @param _reserveWalletAddress The address of ReserveWallet contract
     * @param _adminAddress The address of Multisig wallet
     * @param _poolAddress The address of the pool
     * @param _burnContractAddress The address of burnWallet contract address
     * @param _bruTokenAddress The address of the bru token
     * @param _tokenAddressForCashflow The address of the token in which cashflow is distributed
     * @param _unClaimedWalletAddress The address of the unclaimed wallet contract
     */
    function initialize(
        address _reserveWalletAddress,
        address _adminAddress,
        address _poolAddress,
        address _burnContractAddress,
        address _bruTokenAddress,
        address _tokenAddressForCashflow,
        address _unClaimedWalletAddress
    ) external initializer {
        require(
            _reserveWalletAddress != address(0) &&
                _adminAddress != address(0) &&
                _poolAddress != address(0) &&
                _burnContractAddress != address(0) &&
                _bruTokenAddress != address(0) &&
                _tokenAddressForCashflow != address(0) &&
                _unClaimedWalletAddress != address(0),
            "Invalid Address"
        );

        adminAddress = _adminAddress;
        reserveWalletAddress = _reserveWalletAddress;
        poolAddress = _poolAddress;
        burnContractAddress = _burnContractAddress;
        owner = msg.sender;
        bruTokenAddress = _bruTokenAddress;
        tokenAddressForCashflow = _tokenAddressForCashflow;
        unClaimedWalletAddress = _unClaimedWalletAddress;
    }

    /**
     * @notice To pay expenses or other parts from this wallet.
     * @dev Only called by admin or pool or Burn contract
     * @param _amount The amount of token to safeTransfer
     * @param _tokenAddress The address of the token
     * @param _receiverAddress The address of the receiver
     */
    function sendAmount(
        uint256 _amount,
        address _tokenAddress,
        address _receiverAddress
    ) public onlyPoolOrAdminOrBurnContract {
        if (
            IERC20(_tokenAddress).balanceOf(address(this)) + IERC20(_tokenAddress).balanceOf(reserveWalletAddress) >=
            _amount
        ) {
            if (_amount > IERC20(_tokenAddress).balanceOf(address(this))) {
                _amount -= IERC20(_tokenAddress).balanceOf(address(this));
                IERC20(_tokenAddress).safeTransfer(_receiverAddress, IERC20(_tokenAddress).balanceOf(address(this)));
                transferFromReserve(_amount, _tokenAddress, _receiverAddress);
            } else {
                IERC20(_tokenAddress).safeTransfer(_receiverAddress, _amount);
            }
        } else {
            revert("currently we do not have enough balance");
        }
    }

    /**
     * @notice This function is get cashflow details of a given claimId
     * @param  _claimId claim Id
     * @return CashFlowDetails object of a given claim Id
     */
    function getCashFlowDetailsOfClaimId(uint256 _claimId) public view returns (CashFlowDetails memory) {
        return cashFlowDetailsMapping[_claimId];
    }

    /**
     * @notice Used to get the available wallet balance
     * @param _tokenAddress The address of the token
     * @return Returns amount of balance available
     */
    function getBalance(address _tokenAddress) external view returns (uint256) {
        IERC20 tokenContract = IERC20(_tokenAddress);
        return tokenContract.balanceOf(address(this));
    }

    /**
     * @notice This function allows the user to claim the dividend for current claimId.
     */
    function claimDividend() external {
        require(cashFlowDetailsMapping[claimId].status, "claim period ended try from different place");
        if (!cashFlowClaimMapping[msg.sender][claimId]) {
            uint256 balance = Token(bruTokenAddress).balanceOfAtDate(
                msg.sender,
                cashFlowDetailsMapping[claimId].starttime
            );
            uint256 amountTotransfer = (balance * (cashFlowDetailsMapping[claimId].totalAmountToDistribute)) /
                (Token(bruTokenAddress).totalSupplyOfAtDate(cashFlowDetailsMapping[claimId].starttime));
            if (amountTotransfer > 0 && cashFlowDetailsMapping[claimId].amountLeft > amountTotransfer) {
                cashFlowDetailsMapping[claimId].amountLeft -= amountTotransfer;
                cashFlowClaimMapping[msg.sender][claimId] = true;
                IERC20(tokenAddressForCashflow).safeTransfer(msg.sender, amountTotransfer);
            }
        } else {
            revert("already claimed");
        }
    }

    /**
     * @notice This function is used to start claim Period
     * @param _tokenAddress address of the token of which we want to divide the cashflow although for now this tokenAddress is not used as currently we are giving the cashflow in a fixed token
     */
    function startClaimPeriod(address _tokenAddress) external onlyAdmin {
        uint256 amount = (IERC20(_tokenAddress).balanceOf(address(this)) * (16)) / (100);
        uint256 time = Token(bruTokenAddress).createSnapshot();
        cashFlowDetailsMapping[claimId] = CashFlowDetails(time, amount, amount, _tokenAddress, true);
        emit ClaimPeriodStarted(claimId, _tokenAddress);
    }

    /**
     * @notice This function is used to stop claim Period
     */
    function stopClaimPeriod() external onlyAdmin {
        cashFlowDetailsMapping[claimId].status = false;
        claimId++;
        IERC20(tokenAddressForCashflow).transfer(
            unClaimedWalletAddress,
            cashFlowDetailsMapping[claimId - 1].amountLeft
        );
        emit ClaimPeriodStopped(claimId - 1);
    }

    /**
     * @notice Used to set cashflow details of a given claimId
     * @param  _cashflowDetails details to update
     * @param _claimId claim Id
     */
    function setCashFlowDetailsOfClaimId(CashFlowDetails memory _cashflowDetails, uint256 _claimId)
        external
        onlyUnClaimedWallet
    {
        cashFlowDetailsMapping[_claimId] = _cashflowDetails;
        emit SetCashflowDetails(_claimId, _cashflowDetails);
    }

    /**
     * @notice Used to set cashflow claimed mapping of a given claimId for a given owner
     * @param  _claimId claim Id
     * @param _owner address of the user to update the claimed bool
     * @param _result value to update
     */
    function setCashFlowClaimedMapping(
        uint256 _claimId,
        address _owner,
        bool _result
    ) external onlyUnClaimedWallet {
        cashFlowClaimMapping[_owner][_claimId] = _result;
        emit SetCashflowClaimed(_result, _owner, _claimId);
    }

    /**
     * @notice Transfer tokens from the reserve in case the contract has insufficient balance
     * @dev Only called if reserver wallet is set
     * @param _amount The amount of token to be transferred
     * @param _tokenAddress The address of the token
     * @param _receiverAddress The address of token receiver
     */
    function transferFromReserve(
        uint256 _amount,
        address _tokenAddress,
        address _receiverAddress
    ) internal {
        ReserveWallet(reserveWalletAddress).transferTo(_receiverAddress, _amount, _tokenAddress);
    }

    /**
     *  @dev Checks if the wallet initiating the upgrade transaction for a pool is the admin or not
     *  @param _newImplementation Address of the new implementation contract for upgradation.
     */
    function _authorizeUpgrade(address _newImplementation) internal view override {
        require(msg.sender == adminAddress, "Only admin allowed");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Reserve Wallet contract
 * @author Bru-finance team
 * @notice Stores some amount as reserve incase expense is greater than the balance of NIImargin wallet
 */
contract ReserveWallet is Initializable, UUPSUpgradeable {
    using SafeERC20 for IERC20;
    /// @notice The address of the admin
    address public adminAddress; // The address of Multisig wallet
    address internal NIIWalletAddress;

    /**
     * @dev Only NII wallet and admin address can call functions marked by this modifier
     */
    modifier onlyNIIWalletOrAdmin() {
        require(msg.sender == NIIWalletAddress || msg.sender == adminAddress, "Can be used only by NIIwallet");
        _;
    }

    /**
     * @notice Initializes the neccessary variables for the contract
     * @param _adminAddress The address of Multisig wallet
     * @param _NIIWalletAddress The address the NIIWallet contract
     */
    function initialize(address _adminAddress, address _NIIWalletAddress) external initializer {
        require(_adminAddress != address(0) && _NIIWalletAddress != address(0), "Invalid Address");
        adminAddress = _adminAddress;
        NIIWalletAddress = _NIIWalletAddress;
    }

    /**
     * @notice Used to get wallet's available balance
     * @param _tokenAddress The address of the token
     * @return Returns caller's balance
     */
    function getBalance(address _tokenAddress) external view returns (uint256) {
        IERC20 tokenContract = IERC20(_tokenAddress);
        return tokenContract.balanceOf(address(this));
    }

    /**
     * @notice Transfer funds from reserve wallet to NII wallet.
     * @dev Only called by NIIWallet address or admin
     * @param _receiverAddress The address of token receiver
     * @param _amount The amount of token to be transferred
     * @param _tokenAddress The address of the token
     */
    function transferTo(
        address _receiverAddress,
        uint256 _amount,
        address _tokenAddress
    ) external onlyNIIWalletOrAdmin {
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "reserve does not have enough liquidity");
        IERC20(_tokenAddress).safeTransfer(_receiverAddress, _amount);
    }

    /**
     * @dev Checks the wallet address which initiates the upgrade transaction for ReserveWallet contract
     * @param _newImplementation Address of the new implementation contract which is used for upgradation.
     */
    function _authorizeUpgrade(address _newImplementation) internal view override {
        require(msg.sender == adminAddress, "Only admin allowed");
    }
}