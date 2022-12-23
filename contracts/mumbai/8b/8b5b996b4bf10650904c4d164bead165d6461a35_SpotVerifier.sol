// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SpotRegistry.sol";
import "./SpotResolver.sol";

contract SpotVerifier is Initializable, UUPSUpgradeable, Ownable {
    // ================================================================
    //  variables
    // ================================================================
    address private _visitedByAddress;

    bytes7 private constant _MSG_SALT = 0x18434d4d4e1310; // "\x18CMMN\x13\x10"

    // ================================================================
    //  modifiers
    // ================================================================
    modifier onlyVisitedByContract() {
        require(_visitedByAddress == msg.sender, "Not visitedBy contract.");
        _;
    }

    // ================================================================
    //  initializer
    // ================================================================
    function initialize(address visitedByAddress) public initializer {
        _transferOwnership(_msgSender());
        _visitedByAddress = visitedByAddress;
    }

    // ================================================================
    //  User functions
    // ================================================================
    /**
     * @dev verify Proof of Visit NFT
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     * @param spotSignature bytes, spot signature for PoV
     * @return address, spot address for PoV. If not found, return address(0).
     */
    function verify(address visitor, bytes calldata spotSignature) public view onlyVisitedByContract returns (address) {
        return _recoverSpotAddress(visitor, spotSignature);
    }

    /**
     * @dev verify Proof of Visit NFT
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @return address, spot address for PoV. If not found, return address(0).
     */
    function verify(
        address visitor,
        bytes calldata spotSignature,
        bytes32 extended
    ) public view onlyVisitedByContract returns (address) {
        return _recoverSpotAddress(visitor, spotSignature, extended);
    }

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev recover spot address from signature
     * @notice msg.sender should be contract owner.
     * @param minter address, minter wallet address
     * @param signature bytes, spot signature for PoV
     * @return address, spot address
     */
    function _recoverSpotAddress(address minter, bytes calldata signature) internal pure returns (address) {
        return _recoverSigner(sha256(abi.encodePacked(_MSG_SALT, minter, bytes32(0x0000000000000000000000000000000000000000000000000000000000000000))), signature);
    }

    /**
     * @dev recover spot address from signature with extended data
     * @notice msg.sender should be contract owner.
     * @param minter address, minter wallet address
     * @param signature bytes, spot signature for PoV
     * @return extended bytes32, extended data
     */
    function _recoverSpotAddress(
        address minter,
        bytes calldata signature,
        bytes32 extended
    ) internal pure returns (address) {
        return _recoverSigner(sha256(abi.encodePacked(_MSG_SALT, minter, extended)), signature);
    }

    /// _recoverSigner
    function _recoverSigner(bytes32 msgHash, bytes calldata sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);
        return ecrecover(msgHash, v, r, s);
    }

    /// _splitSignature is signature methods.
    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65, "signature length must be 65");

        /* solhint-disable no-inline-assembly */
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        /* solhint-enable no-inline-assembly */

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "parameter v must be 27 or 28");

        return (v, r, s);
    }

    // ================================================================
    //  override functions
    // ================================================================
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
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

        bool isTopLevelCall = !_initializing; // cache sload
        uint8 currentVersion = _initialized; // cache sload

        require(
            (isTopLevelCall && version > currentVersion) || // not nested with increasing version or
                (!Address.isContract(address(this)) && (version == 1 || version == type(uint8).max)), // contract being constructed
            "Initializable: contract is already initialized"
        );

        if (isTopLevelCall) {
            _initialized = version;
        }

        return isTopLevelCall;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./SpotResolver.sol";
import "./lib/VisitedByTypes.sol";

contract SpotRegistry is Initializable, UUPSUpgradeable, Ownable, VisitedByTypes {
    // ================================================================
    //  usings
    // ================================================================
    using Counters for Counters.Counter;
    using Address for address;

    // ================================================================
    //  structs
    // ================================================================

    /**
     * @dev Spot record
     * @param resolver address of resolver
     * @param spotOwner address of spot owner
     * @param isPaused is paused
     */
    struct SpotRecord {
        address resolver;
        address spotOwner;
        bool isPaused;
    }

    // total spot count
    Counters.Counter private _totalSpotCount;

    // ================================================================
    //  events
    // ================================================================

    event Register(address indexed spotAddress, address indexed resolver, address indexed spotOwner);

    event Pause(address indexed spotAddress, bool indexed paused);

    event ChangeSpotOwner(address indexed oldOwner, address indexed newOwner);

    event ChangeContractOwner(address indexed oldOwner, address indexed newOwner);

    // ================================================================
    //  variables
    // ================================================================
    address private _visitedByAddress;
    address private _poVFactoryAddress;

    // ================================================================
    //  mappings
    // ================================================================

    // spot address(wallet address) -> SpotRecord
    mapping(address => SpotRecord) private spotMapping;

    // spot owner(wallet address) -> spots
    mapping(address => address[]) private ownSpotsMapping;

    // resolver address -> is registered
    mapping(address => bool) private resolversMapping;

    // ================================================================
    //  modifiers
    // ================================================================

    modifier isRegstered(address spotAddress) {
        require(address(0) != spotMapping[spotAddress].resolver, "spot is not registerd.");
        _;
    }

    modifier isNotRegstered(address spotAddress) {
        require(address(0) == spotMapping[spotAddress].resolver, "spot is already registerd.");

        _;
    }

    modifier onlySpotOwner(address spotAddress) {
        SpotRecord memory _spotInfo = spotMapping[spotAddress];

        // Check if the spot is owned by the sender
        require(msg.sender == _spotInfo.spotOwner, "sender is not the spot owner.");
        _;
    }

    // ================================================================
    //  initializer
    // ================================================================
    function initialize(address visitedByAddress, address poVFactoryAddress) public initializer {
        _transferOwnership(_msgSender());
        _visitedByAddress = visitedByAddress;
        _poVFactoryAddress = poVFactoryAddress;
    }

    // ================================================================
    //  User functions
    // ================================================================
    /**
     * @dev total spot count
     * @return uint256, total spot count
     */
    function totalSpot() public view returns (uint256) {
        return _totalSpotCount.current();
    }

    /**
     * @dev get resolver address
     * @notice return is 0x0 if spot is not registered.
     * @param spotAddress address, spot address provided by spot device
     * @return address, resolver address
     */
    function getResolver(address spotAddress) public view returns (address) {
        return spotMapping[spotAddress].resolver;
    }

    /**
     * @dev get spot owner address
     * @notice return is 0x0 if spot is not registered.
     * @param spotOwner address, spot owner address
     * @return address, spot owner address
     */
    function getOwnSpots(address spotOwner) public view returns (address[] memory) {
        return ownSpotsMapping[spotOwner];
    }

    /**
     * @dev resolver is registered or not
     * @param resolverAddress address, resolver address
     * @return bool, is registered
     */
    function isResolver(address resolverAddress) public view returns (bool) {
        return resolversMapping[resolverAddress];
    }

    /**
     * @dev get spot pause/unpaused status
     * @notice return is false if spot is not registered.
     * @param spotAddress address, spot address provided by spot device
     */
    function isPaused(address spotAddress) public view returns (bool) {
        return spotMapping[spotAddress].isPaused;
    }

    // ================================================================
    //  Owner functions
    // ================================================================
    /**
     * @dev Register new spot to registry
     * @notice msg.sender should be contract owner.
     * @param spotOwner address, spot owner address( who is the owner of spot device )
     * @param spotAddress address, spot address provided by spot device
     * @param spotInfo SpotInfo, spot info
     */
    function register(
        address spotOwner,
        address spotAddress,
        SpotInfo memory spotInfo
    ) public isNotRegstered(spotAddress) onlyOwner returns (address) {
        address _spotOwner = spotOwner;
        if (_spotOwner == address(0)) {
            _spotOwner = msg.sender;
        }
        SpotResolver spotResolver = new SpotResolver(msg.sender, spotOwner, spotAddress, _visitedByAddress, _poVFactoryAddress, spotInfo);

        _register(_spotOwner, spotAddress, address(spotResolver));

        return address(spotResolver);
    }

    /**
     * @dev Register new spot to registry for Custom Resolver
     * @notice msg.sender should be contract owner.
     * @param spotOwner address, spot owner address( who is the owner of spot device )
     * @param spotAddress address, spot address provided by spot device
     * @param spotResolver address, spot resolver address
     */
    function register(
        address spotOwner,
        address spotAddress,
        address spotResolver
    ) public isNotRegstered(spotAddress) onlyOwner {
        if (Address.isContract(spotResolver) == false) revert("Invalid address");
        address _spotOwner = spotOwner;
        if (_spotOwner == address(0)) {
            _spotOwner = msg.sender;
        }
        _register(_spotOwner, spotAddress, spotResolver);
    }

    /**
     * @dev pause spot
     * @notice msg.sender should be contract owner.
     * @param spotAddress address, spot address provided by spot device
     */
    function pauseMint(address spotAddress) public isRegstered(spotAddress) onlyOwner {
        spotMapping[spotAddress].isPaused = true;

        emit Pause(spotAddress, true);
    }

    /**
     * @dev unpause spot
     * @notice msg.sender should be contract owner.
     * @param spotAddress address, spot address provided by spot device
     */
    function unpauseMint(address spotAddress) public isRegstered(spotAddress) onlyOwner {
        spotMapping[spotAddress].isPaused = false;

        emit Pause(spotAddress, false);
    }

    /**
     * @dev change spot owner
     * @notice msg.sender should be contract owner.
     * @param spotAddress address, spot address provided by spot device
     * @param newSpotOwner address, new spot owner address
     */
    function changeSpotOwner(address spotAddress, address newSpotOwner) public onlyOwner {
        address _oldOwner = spotMapping[spotAddress].spotOwner;
        _deleteOwnSpotElement(_oldOwner, spotAddress);
        ownSpotsMapping[newSpotOwner].push(spotAddress);
        spotMapping[spotAddress].spotOwner = newSpotOwner;

        emit ChangeSpotOwner(_oldOwner, newSpotOwner);
    }

    /**
     * @dev change contract owner
     * @notice msg.sender should be contract owner.
     * @param owner address, new owner address
     */
    function changeContractAdministrator(address owner) public onlyOwner {
        transferOwnership(owner);

        emit ChangeContractOwner(msg.sender, owner);
    }

    // ================================================================
    //  override functions
    // ================================================================
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev Register new spot to registry
     * @notice msg.sender should be contract owner.
     * @param spotOwner address, spot owner address( who is the owner of spot device )
     * @param spotAddress address, spot address provided by spot device
     * @param resolverAddress address, resolver address
     */
    function _register(
        address spotOwner,
        address spotAddress,
        address resolverAddress
    ) internal {
        spotMapping[spotAddress] = SpotRecord({ resolver: resolverAddress, spotOwner: spotOwner, isPaused: false });
        resolversMapping[resolverAddress] = true;
        ownSpotsMapping[spotOwner].push(spotAddress);
        _totalSpotCount.increment();

        emit Register(spotAddress, resolverAddress, spotOwner);
    }

    function _deleteOwnSpotElement(address owner, address spot) internal {
        for (uint256 i = 0; i < ownSpotsMapping[owner].length; i++) {
            if (spot == ownSpotsMapping[owner][i]) {
                _deleteArrayElement(owner, i);
                break;
            }
        }
    }

    function _deleteArrayElement(address owner, uint256 index) internal {
        if (index >= ownSpotsMapping[owner].length) return;

        for (uint256 i = index; i < ownSpotsMapping[owner].length - 1; i++) {
            ownSpotsMapping[owner][i] = ownSpotsMapping[owner][i + 1];
        }
        ownSpotsMapping[owner].pop();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./lib/VisitedByTypes.sol";
import "./lib/PoVBase.sol";
import "./lib/IPoVFactory.sol";
import "./VisitedBy.sol";
import "./lib/RoleControl.sol";

contract SpotResolver is RoleControl, Ownable, VisitedByTypes {
    // ================================================================
    //  usings
    // ================================================================
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address;

    // ================================================================
    //  events
    // ================================================================

    event AddPoV(uint256 indexed povId, address indexed povAddress);

    event ChangePosition(uint256 indexed povId, int256 indexed latitude, int256 indexed longitude);
    event ChangeBaseURI(string indexed baseURI);

    // ================================================================
    //  variables
    // ================================================================

    /// spot address
    address private _spotAddress;

    // Contract address
    // To restrict minting function to this address
    address private _spotOwner;

    // Contract address
    // To restrict minting function to this address
    address private _visitedByContractAddress;

    /// PoV ID array
    uint256[] private _povIdArray;

    /// count of pov
    Counters.Counter private _povCount;

    /// latitude and longitude precision
    int256 public constant POSITION_PRECISION = 100000000;

    /// invalid latitude and longitude
    int256 public constant INVALID_POSITION = 100000000000;

    SpotInfo private _spotInfo;

    address[] private _povFactoryAddressArray;

    // ================================================================
    //  mappings
    // ================================================================

    /// pov mapping
    mapping(uint256 => address) private _povAddressOf;

    // visitor address to experience of spot
    mapping(address => uint256) private _spotExperienceOf;

    // ================================================================
    //  modifiers
    // ================================================================
    modifier onlyAdminOrSpotOwner() {
        require(_spotOwner == msg.sender || isAdmin(msg.sender), "SpotResolver: only admin or spot owner");
        _;
    }

    modifier onlySpotOwner() {
        require(_spotOwner == msg.sender, "SpotResolver: only spot owner");
        _;
    }

    modifier onlyVisitedByContract() {
        require(_visitedByContractAddress == msg.sender, "SpotResolver: only visitedBy");
        _;
    }

    // ================================================================
    //  constructors
    // ================================================================

    /**
     * @dev constructor
     * @notice create special PoV contract for each spot
     * @param admin address,  address of admin
     * @param spotOwner address,  address of spot owner
     * @param visitedByContractAddress address,  address of visitedBy contract
     */
    constructor(
        address admin,
        address spotOwner,
        address spotAddress,
        address visitedByContractAddress,
        address poVFactoryAddress,
        SpotInfo memory spotInfo
    ) RoleControl(admin) {
        _spotOwner = spotOwner;
        _spotAddress = spotAddress;
        _visitedByContractAddress = visitedByContractAddress;
        _povFactoryAddressArray.push(poVFactoryAddress);

        _spotInfo = spotInfo;

        address _povAddress = IPoVFactory(_povFactoryAddressArray[0]).createNewPoV(
            _spotOwner,
            address(this),
            PoVInfo({
                name: "No Name",
                description: [bytes32("Put any text"), bytes32(""), bytes32(""), bytes32("")],
                imageUrl: [bytes32("https://"), bytes32(""), bytes32(""), bytes32("")],
                url: [bytes32("https://"), bytes32("")],
                provider: spotInfo.provider,
                latitude: INVALID_POSITION,
                longitude: INVALID_POSITION,
                extra: bytes32("put any data")
            })
        );
        if (address(0) == _povAddress) revert("failure create PoV contract");

        _addCustomPoV(_povAddress, 0);
    }

    // ================================================================
    //  User functions
    // ================================================================
    /**
     * @dev get PoV address
     * @notice return is 0x0 if PoV is not added.
     * @param povId uint256, PoV id
     * @return address, PoV address
     */
    function getPovAddress(uint256 povId) public view returns (address) {
        return _povAddressOf[povId];
    }

    /**
     * @dev get experience of spot
     * @notice return is 0x0 if PoV is not added.
     * @param visitor address, caller of this function
     * @return uint256, spot experience
     */
    function spotExperienceOf(address visitor) public view returns (uint256) {
        return _spotExperienceOf[visitor];
    }

    /**
     * @dev Returns PoV address array
     * @return PoVs array address[], address array of PoVs
     */
    function getPoVIDs() public view returns (uint256[] memory) {
        return _povIdArray;
    }

    /**
     * @dev Returns spot address
     * @return spotOwner address, spot owner address
     */
    function spotOwnerOf() public view returns (address) {
        return _spotOwner;
    }

    /**
     * @dev Returns the spot metadata
     * @return metadata string, metadata of spot
     */
    function getMetadataAsBase64() public view returns (string memory) {
        bytes memory spotMetadata1 = abi.encodePacked(
            '{"name":"',
            string(abi.encodePacked(_spotInfo.name)),
            '",',
            '"description":"',
            string(abi.encodePacked(_spotInfo.description)),
            '",',
            '"image":"',
            string(abi.encodePacked(_spotInfo.imageUrl)),
            '",'
        );
        bytes memory spotMetadata2 = abi.encodePacked(
            '"url":"',
            string(abi.encodePacked(_spotInfo.url)),
            '",',
            '"provider":"',
            string(abi.encodePacked(_spotInfo.provider)),
            '",',
            '"extra":"',
            string(abi.encodePacked(_spotInfo.extra)),
            '"}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(abi.encodePacked(spotMetadata1, spotMetadata2))));
    }

    /**
     * @dev Returns the factory address array
     * @return factory address array
     */
    function getPovFactoryArray() public view returns (address[] memory) {
        return _povFactoryAddressArray;
    }

    // ================================================================
    //  visited contract functions
    // ================================================================
    /**
     * @dev mint new PoV with povId
     * @notice msg.sender should be visited contract.
     * @param to address, minter address
     * @param povId uint256, PoV id
     * @param tokenId uint256, PoV token id
     * @param userData bytes, user data
     */
    function mint(
        address to,
        uint256 povId,
        uint256 tokenId,
        bytes32 userData
    ) public onlyVisitedByContract returns (address) {
        if (address(0) == _povAddressOf[povId]) revert("Not available PoV ID");

        PoVBase pov = PoVBase(_povAddressOf[povId]);
        pov.mint(to, tokenId, userData);

        _spotExperienceOf[to]++;

        return _povAddressOf[povId];
    }

    // ================================================================
    //  admin or spot owner functions
    // ================================================================
    /**
     * @dev Add new pov
     * @notice msg.sender should be spot owner or admin.
     * @param povFactoryID uint256, PoV factory ID
     * @param povInfo PoVInfo, PoV info
     * @return uint256, PoV id
     */
    function add(uint256 povFactoryID, PoVInfo memory povInfo) public onlyAdminOrSpotOwner returns (uint256) {
        return _add(povFactoryID, povInfo);
    }

    /**
     * @dev Add new pov for custom PoV contract
     * @notice msg.sender should be spot owner or admin.
     * @param povAddress address, address of pov
     * @param povId uint256, PoV id(0 is auto generated)
     */
    function addCustomPoV(address povAddress, uint256 povId) public onlyAdminOrSpotOwner returns (uint256) {
        if (0 == povId) {
            povId = uint256(keccak256(abi.encodePacked(povAddress, block.number)));
        }
        return _addCustomPoV(povAddress, povId);
    }

    /**
     * @dev Burn PoV token
     * @notice msg.sender should be spot owner or admin.
     * @param povId uint256, PoV id
     * @param tokenId uint256, PoV token id
     */
    function burn(uint256 povId, uint256 tokenId) public onlyAdminOrSpotOwner {
        if (address(0) == _povAddressOf[povId]) revert("Not available PoV ID");

        PoVBase pov = PoVBase(_povAddressOf[povId]);
        address visitor = pov.ownerOf(tokenId);
        pov.burn(tokenId);

        // save log as complaint for the visitor
        VisitedBy _visitedBy = VisitedBy(_visitedByContractAddress);
        _visitedBy.setComplaint(visitor);

        // deprivation experience point for the visitor
        delete _spotExperienceOf[visitor];
    }

    // ================================================================
    //  spot owner functions
    // ================================================================

    /**
     * @dev set Name of spot
     * @notice msg.sender should be spot owner or admin.
     * @param name bytes32, name of spot
     */
    function setName(bytes32 name) public onlySpotOwner {
        _spotInfo.name = name;
    }

    /**
     * @dev set Description of spot
     * @notice msg.sender should be spot owner or admin.
     * @param description bytes32[4] memory, description of spot
     */
    function setDescription(bytes32[4] memory description) public onlySpotOwner {
        _spotInfo.description = description;
    }

    /**
     * @dev set Image Url of spot
     * @notice msg.sender should be spot owner or admin.
     * @param imageUrl bytes32[4] memory, image of spot
     */
    function setImage(bytes32[4] memory imageUrl) public onlySpotOwner {
        _spotInfo.imageUrl = imageUrl;
    }

    /**
     * @dev set Url of spot
     * @notice msg.sender should be spot owner or admin.
     * @param url bytes32[2] memory, url of spot
     */
    function setUrl(bytes32[2] memory url) public onlySpotOwner {
        _spotInfo.url = url;
    }

    /**
     * @dev set provider of spot
     * @notice msg.sender should be spot owner or admin.
     * @param provider bytes32, provider of spot
     */
    function setProvider(bytes32 provider) public onlySpotOwner {
        _spotInfo.provider = provider;
    }

    /**
     * @dev set Extra of spot
     * @notice msg.sender should be spot owner or admin.
     * @param extra bytes32 memory, extra of spot
     */
    function setExtra(bytes32 extra) public onlySpotOwner {
        _spotInfo.extra = extra;
    }

    /**
     * @dev clear experience of visitor
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     */
    function clearExperience(address visitor) public onlySpotOwner {
        _clearExperience(visitor);
    }

    // ================================================================
    //  admin functions
    // ================================================================
    /**
     * @dev add factory address
     * @notice msg.sender should be contract owner.
     * @param factoryAddress address, factory address
     * @return uint256, factory id
     */
    function addPovFactory(address factoryAddress) public onlyAdmin returns (uint256) {
        if (address(0) == factoryAddress) revert("Invalid factory address");
        _povFactoryAddressArray.push(factoryAddress);
        return (_povFactoryAddressArray.length - 1);
    }

    /**
     * @dev Sets the contract address to allow it to mint token
     * @param resolver address, resolver contract address
     */
    function setResolver(address resolver) external onlyAdmin {
        for (uint256 i = 0; i < _povIdArray.length; i++) {
            PoVBase pov = PoVBase(_povAddressOf[_povIdArray[i]]);
            pov.setResolver(resolver);
        }
    }

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev Add new pov(internal)
     * @param povFactoryID uint256, PoV factory id
     * @param povInfo PoVInfo, PoV info
     * @return povId uint256, PoV id
     */
    function _add(uint256 povFactoryID, PoVInfo memory povInfo) internal returns (uint256) {
        if (_povFactoryAddressArray.length <= povFactoryID) revert("Not available PoV factory ID");

        uint256 povId = uint256(keccak256(abi.encodePacked(povInfo.name, povInfo.description, povInfo.imageUrl, povInfo.url, povInfo.provider, povInfo.extra, block.number)));
        if (address(0) != _povAddressOf[povId]) revert("Already added PoV ID");

        address _povAddress = IPoVFactory(_povFactoryAddressArray[povFactoryID]).createNewPoV(_spotOwner, address(this), povInfo);
        if (address(0) == _povAddress) revert("failure create PoV contract");

        _povAddressOf[povId] = _povAddress;
        _povIdArray.push(povId);

        emit AddPoV(povId, _povAddress);

        return povId;
    }

    /**
     * @dev Add new pov for custom PoV contract (internal)
     * @notice msg.sender should be spot owner or admin.
     * @param povAddress address, address of pov
     * @return povId uint256, PoV id
     */
    function _addCustomPoV(address povAddress, uint256 povId) internal returns (uint256) {
        if (address(0) != _povAddressOf[povId]) revert("Already added PoV ID");
        if (address(0) == povAddress) revert("Invalid pov address");
        if (Address.isContract(povAddress) == false) revert("Invalid pov address");

        _povAddressOf[povId] = povAddress;
        _povIdArray.push(povId);

        emit AddPoV(povId, povAddress);

        return povId;
    }

    /**
     * @dev clear experience of visitor(internal)
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     */
    function _clearExperience(address visitor) internal {
        if (0 == _spotExperienceOf[visitor]) revert("visitor has no experience.");

        _spotExperienceOf[visitor] = 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface VisitedByTypes {
    /**
     * @dev Spot Information
     * @param name bytes32, name of pov
     * @param detail bytes32[4], detail of pov
     * @param image bytes32[4], image of pov
     * @param url bytes32[2], url of pov
     * @param provider bytes32, owner of pov
     * @param extra bytes32, extra of pov
     */
    struct SpotInfo {
        bytes32 name;
        bytes32[4] description;
        bytes32[4] imageUrl;
        bytes32[2] url;
        bytes32 provider;
        bytes32 extra;
    }

    /**
     * @dev PoV Information
     * @param name bytes32, name of pov
     * @param detail bytes32[4], detail of pov
     * @param image bytes32[4], image of pov
     * @param url bytes32[2], url of pov
     * @param provider bytes32, owner of pov
     * @param latitude int256, latitude of pov
     * @param longitude int256, longitude of pov
     * @param extra bytes32, extra of pov
     */
    struct PoVInfo {
        bytes32 name;
        bytes32[4] description;
        bytes32[4] imageUrl;
        bytes32[2] url;
        bytes32 provider;
        int256 latitude;
        int256 longitude;
        bytes32 extra;
    }

    /**
     * @dev User Information
     * @param data1 bytes32, data1
     * @param data2 bytes24, data2(unused for now)
     * @param mintUnixTimeMsec uint64, mint unix time msec
     *
     */
    struct UserInfo {
        bytes32 data1;
        bytes24 data2;
        uint64 mintUnixTimeMsec;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./VisitedByTypes.sol";

abstract contract PoVBase is Context, ERC165, IERC721Metadata, VisitedByTypes {
    // ================================================================
    //  events
    // ================================================================

    // ================================================================
    //  variables
    // ================================================================
    /// IERC721Metadata - name
    string private _name;

    /// IERC721Metadata - symbol
    string private _symbol;

    /// Contract address
    /// To restrict minting function to this address
    address private _resolverContractAddress;

    // ================================================================
    //  mappings
    // ================================================================

    /// holder address to token id list
    mapping(address => uint256[]) private _holderToTokenIds;

    /// ownerOf mapping
    mapping(uint256 => address) private _ownerOf;

    /// PoV - userdata
    mapping(uint256 => bytes32) private _userData;

    // ================================================================
    //  modifiers
    // ================================================================

    modifier onlyFromResolverContract() {
        require(_resolverContractAddress == msg.sender, "PoV: only from resolver contract");
        _;
    }

    // ================================================================
    //  initializer
    // ================================================================

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * @param resolverContractAddress address, resolver contract address
     */
    function _povInit(address resolverContractAddress) internal virtual {
        _name = _initialName();
        _symbol = _initialSymbol();
        _resolverContractAddress = resolverContractAddress;
    }

    // ================================================================
    //  resolver functions
    // ================================================================

    /**
     * @dev Mint token
     * @param to address, holder address
     * @param tokenId uint256, token id
     * @param userData bytes, user data
     */
    function mint(
        address to,
        uint256 tokenId,
        bytes32 userData
    ) external virtual;

    /**
     * @dev Burn token
     * @param tokenId uint256, token id
     */
    function burn(uint256 tokenId) external virtual;

    // ================================================================
    //  internal functions
    // ================================================================

    /**
     * @dev Sets the contract address to allow it to mint token
     * @param resolver address, resolver contract address
     */
    function setResolver(address resolver) external onlyFromResolverContract {
        _resolverContractAddress = resolver;
    }

    // ================================================================
    //  user functions
    // ================================================================

    /**
     * @dev Returns holder address to tokenID array
     * @param owner address, holder address
     * @return tokenIds array uint256[], tokenId
     */
    function getOwnerTokens(address owner) external view returns (uint256[] memory) {
        return _holderToTokenIds[owner];
    }

    /**
     * @dev See {IERC4973-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf[tokenId];
        return owner;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _holderToTokenIds[owner].length;
    }

    /**
     * @dev Returns user data
     * @param tokenId uint256, token id
     * @return userData bytes32, user data
     */
    function getUserData(uint256 tokenId) public view returns (bytes32) {
        return _userData[tokenId];
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
     * @dev Returns resolver contract address
     */
    function getResolver() public view returns (address) {
        return _resolverContractAddress;
    }

    // ================================================================
    //  override functions
    // ================================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev mint token (internal)
     * @param to address, holder address
     * @param tokenId uint256, token id
     * @param userData bytes, user data
     */
    function _mint(
        address to,
        uint256 tokenId,
        bytes32 userData
    ) internal virtual onlyFromResolverContract {
        if (address(0) != _ownerOf[tokenId]) revert("PoV: Token already minted");

        _ownerOf[tokenId] = to;
        _userData[tokenId] = userData;
        _holderToTokenIds[to].push(tokenId);
    }

    /**
     * @dev burn token (internal)
     * @param tokenId uint256, token id
     */
    function _burn(uint256 tokenId) internal virtual onlyFromResolverContract {
        if (address(0) == _ownerOf[tokenId]) revert("PoV: burn of nonexistent token");

        _deleteTokenIdsElement(_ownerOf[tokenId], tokenId);
        delete _ownerOf[tokenId];
        delete _userData[tokenId];
    }

    function _deleteTokenIdsElement(address owner, uint256 tokenId) internal {
        for (uint256 i = 0; i < _holderToTokenIds[owner].length; i++) {
            if (tokenId == _holderToTokenIds[owner][i]) {
                _deleteArrayElement(owner, i);
                break;
            }
        }
    }

    function _deleteArrayElement(address owner, uint256 index) internal {
        if (_holderToTokenIds[owner].length <= index) return;

        for (uint256 i = index; i < _holderToTokenIds[owner].length - 1; i++) {
            _holderToTokenIds[owner][i] = _holderToTokenIds[owner][i + 1];
        }
        _holderToTokenIds[owner].pop();
    }

    /**
     * @dev Returns initial name
     */
    function _initialName() internal pure virtual returns (string memory) {
        return "ProofOfVisit";
    }

    /**
     * @dev Returns initial symbol
     */
    function _initialSymbol() internal pure virtual returns (string memory) {
        return "POV";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./VisitedByTypes.sol";

interface IPoVFactory is VisitedByTypes {
    // ================================================================
    //  events
    // ================================================================

    event CreatePoV(address indexed povAddress, address indexed owner);

    // ================================================================
    //  user functions
    // ================================================================
    /**
     * @dev create new pov
     * @notice msg.sender should be spot owner or admin.
     * @param povOwner address, pov owner
     * @param resolver address, resolver address
     * @param poVInfo pov info
     * @return address, new pov address
     */
    function createNewPoV(
        address povOwner,
        address resolver,
        PoVInfo memory poVInfo
    ) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ViSItedToken.sol";
import "./SpotRegistry.sol";
import "./SpotVerifier.sol";
import "./SpotResolver.sol";
import "./lib/PoVBase.sol";

contract VisitedBy is Initializable, UUPSUpgradeable, Ownable, AccessControl {
    // ================================================================
    //  events
    // ================================================================

    event Visited(address indexed visitor, address indexed resolver, address indexed pov, uint256 tokenId);

    // ================================================================
    //  mappings
    // ================================================================

    // visitor address to experience
    mapping(address => uint256) private _experienceOf;

    // visitor address to complaint array
    mapping(address => address[]) private _complaintOf;

    // ================================================================
    //  variables
    // ================================================================
    SpotRegistry private _spotRegistry;
    SpotVerifier private _spotVerifier;
    ViSItedToken private _vsit;

    uint256 public constant COMPLAIN_LIMIT = 5;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // ================================================================
    //  modifiers
    // ================================================================
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minter");
        _;
    }

    // ================================================================
    //  initializer
    // ================================================================
    function initialize(address spotRegistryAddress, address spotVerifierAddress) public initializer {
        _transferOwnership(_msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _spotRegistry = SpotRegistry(spotRegistryAddress);
        _spotVerifier = SpotVerifier(spotVerifierAddress);
        _vsit = new ViSItedToken(5000000);
    }

    // ================================================================
    //  User functions
    // ================================================================
    /**
     * @dev mint Proof of Visit NFT
     * @notice msg.sender should be contract owner.
     * @param spotSignature bytes, spot signature for PoV
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function mint(bytes calldata spotSignature, bytes32 userData) public returns (address) {
        address spotAddress = _spotVerifier.verify(msg.sender, spotSignature);

        return _mint(msg.sender, spotAddress, _tokenIdOf(spotSignature), userData);
    }

    /**
     * @dev mint Proof of Visit NFT with custom extended data
     * @notice msg.sender should be contract owner.
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function mint(
        bytes calldata spotSignature,
        bytes32 extended,
        bytes32 userData
    ) public returns (address) {
        address spotAddress = _spotVerifier.verify(msg.sender, spotSignature, extended);

        return _mint(msg.sender, spotAddress, uint256(extended), _tokenIdOf(spotSignature), userData);
    }

    /**
     * @dev mint Proof of Visit NFT
     * @notice msg.sender should be minter.
     * @param to address, address to mint
     * @param spotSignature bytes, spot signature for PoV
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function mint(
        address to,
        bytes calldata spotSignature,
        bytes32 userData
    ) public onlyMinter returns (address) {
        address spotAddress = _spotVerifier.verify(to, spotSignature);

        return _mint(to, spotAddress, _tokenIdOf(spotSignature), userData);
    }

    /**
     * @dev mint Proof of Visit NFT with custom extended data
     * @notice msg.sender should be minter.
     * @param to address, address to mint
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function mint(
        address to,
        bytes calldata spotSignature,
        bytes32 extended,
        bytes32 userData
    ) public onlyMinter returns (address) {
        address spotAddress = _spotVerifier.verify(to, spotSignature, extended);

        return _mint(to, spotAddress, uint256(extended), _tokenIdOf(spotSignature), userData);
    }

    /**
     * @dev verify Proof of Visit NFT
     * @param visitor address, visitor address
     * @param spotSignature bytes, spot signature for PoV
     * @return resolver address, resolvers address
     */
    function verify(address visitor, bytes calldata spotSignature) external view returns (address) {
        address spotAddress = _spotVerifier.verify(visitor, spotSignature);
        address resolverAddress = _spotRegistry.getResolver(spotAddress);

        return resolverAddress;
    }

    /**
     * @dev verify Proof of Visit NFT with custom extended data
     * @param visitor address, visitor address
     * @param spotSignature bytes, spot signature for PoV
     * @param extended bytes32, extended data
     * @return resolver address, resolvers address
     */
    function verify(
        address visitor,
        bytes calldata spotSignature,
        bytes32 extended
    ) external view returns (address) {
        address spotAddress = _spotVerifier.verify(visitor, spotSignature, extended);
        address resolverAddress = _spotRegistry.getResolver(spotAddress);

        return resolverAddress;
    }

    /**
     * @dev Returns VSIT token contract address

     * @return vsitAddress address, Token contract address
     */
    function vsitContract() external view returns (address) {
        return address(_vsit);
    }

    /**
     * @dev Returns the experience of `account`.
     * @return PoVs array address[], address array of PoVs
     */
    function experienceOf(address visitor) external view returns (uint256) {
        return _experienceOf[visitor];
    }

    /**
     * @dev Returns the complainers of `account`.
     * @param visitor address, visitor address
     * @return complainers count array address[], complainers count array of PoV
     */
    function complaintOf(address visitor) external view returns (address[] memory) {
        return _complaintOf[visitor];
    }

    /**
     * @dev Returns the complainers of `account`.
     * @param minter address, minter address
     * @return bool, true if visitor is user wallet
     */
    function isMinter(address minter) external view returns (bool) {
        return hasRole(MINTER_ROLE, minter);
    }

    // ================================================================
    //  Owner functions
    // ================================================================
    /**
     * @dev add minter account wallet
     * @notice msg.sender should be contract owner.
     * @param minter address, visitor address
     */
    function addMinter(address minter) public onlyOwner {
        grantRole(MINTER_ROLE, minter);
    }

    /**
     * @dev clear experience of visitor
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     */
    function clearExperience(address visitor) public onlyOwner {
        _clearExperience(visitor);
    }

    // ================================================================
    //  Resolver functions
    // ================================================================
    /**
     * @dev Returns the complainers of `account`.
     * @param visitor address, visitor address
     */
    function setComplaint(address visitor) external {
        if (false == _spotRegistry.isResolver(msg.sender)) revert("is not Resolver.");

        _complaintOf[visitor].push(msg.sender);
        if (_complaintOf[visitor].length >= COMPLAIN_LIMIT) {
            // deprivation experience of `visitor`
            _clearExperience(visitor);
            delete _complaintOf[visitor];
            // burn VSIT
            _vsit.burnAll(visitor);
        } else {
            // burn VSIT
            _vsit.burn(visitor, 20 * 10**uint256(_vsit.decimals()));
        }
    }

    // ================================================================
    //  override functions
    // ================================================================
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ================================================================
    //  internal functions
    // ================================================================
    /**
     * @dev mint (internal)
     * @param spotAddress address, spot address(from SpotVerifier)
     * @param to address, receiver address
     * @param tokenId uint256, PoV token id
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function _mint(
        address to,
        address spotAddress,
        uint256 tokenId,
        bytes32 userData
    ) internal returns (address) {
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0) == resolverAddress) revert("invalid signature or caller.");
        if (_spotRegistry.isPaused(spotAddress)) revert("spot is paused.");

        SpotResolver resolver = SpotResolver(resolverAddress);
        address _pov = resolver.mint(to, 0, tokenId, userData);

        emit Visited(to, resolverAddress, _pov, tokenId);

        _distributeRewards(to, resolverAddress, _pov);

        return resolverAddress;
    }

    /**
     * @dev mint (internal)
     * @param spotAddress address, spot address(from SpotVerifier)
     * @param to address, receiver address
     * @param eventId uint256, PoV id
     * @param tokenId uint256, PoV token id
     * @param userData bytes, user data
     * @return resolver address, resolvers address
     */
    function _mint(
        address to,
        address spotAddress,
        uint256 eventId,
        uint256 tokenId,
        bytes32 userData
    ) internal returns (address) {
        address resolverAddress = _spotRegistry.getResolver(spotAddress);
        if (address(0) == resolverAddress) revert("invalid signature or caller.");
        if (_spotRegistry.isPaused(spotAddress)) revert("spot is paused.");

        SpotResolver resolver = SpotResolver(resolverAddress);
        address _pov = resolver.mint(to, eventId, tokenId, userData);

        emit Visited(to, resolverAddress, _pov, tokenId);

        _distributeRewards(to, resolverAddress, _pov);

        return resolverAddress;
    }

    function _distributeRewards(
        address to,
        address resolverAddress,
        address povAddress
    ) internal {
        // exchange reward
        _experienceOf[to] += 1;

        uint256 _reward = _calcReward(to, resolverAddress, povAddress);

        // mint VSIT
        if (0 != _reward) _vsit.mint(to, _reward);
    }

    function _calcReward(
        address to,
        address resolverAddress,
        address povAddress
    ) internal view returns (uint256) {
        uint256 reward = 0;

        SpotResolver resolver = SpotResolver(resolverAddress);
        PoVBase pov = PoVBase(povAddress);
        uint256 _visitedExperience = _experienceOf[to];
        uint256 _spotExperience = resolver.spotExperienceOf(to);
        uint256 _povExperience = pov.balanceOf(to);

        if (1 == _visitedExperience) {
            // reward of first visit
            reward = reward + 10;
        }
        if (1 == _spotExperience) {
            // reward of first visit spot
            reward = reward + 10;
        }
        if (1 == _povExperience) {
            // reward of first visit PoV
            reward = reward + 10;
        }
        if (_spotExperience % 10 == 0) {
            // reward of 10th visit spot
            reward = reward + 10;
        }
        if (_visitedExperience % 10 == 0) {
            // reward of every 10th visit
            reward = reward + 10;
        }
        if (_povExperience % 10 == 0) {
            // reward of every 10th visit PoV
            reward = reward + 10;
        }
        if (0 == reward) {
            // reward of luck
            reward = 1;
        }
        return reward * 10**uint256(_vsit.decimals());
    }

    /**
     * @dev mint (internal)
     * @param spotSignature bytes calldata, spot signature from Spot device(as random k value)
     * @return tokenId uint256, PoV token id
     */
    function _tokenIdOf(bytes calldata spotSignature) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(spotSignature)));
    }

    /**
     * @dev clear experience of visitor(internal)
     * @notice msg.sender should be contract owner.
     * @param visitor address, visitor address
     */
    function _clearExperience(address visitor) internal {
        _experienceOf[visitor] = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Import the OpenZeppelin AccessControl contract
import "@openzeppelin/contracts/access/AccessControl.sol";

// create a contract that extends the OpenZeppelin AccessControl contract
contract RoleControl is AccessControl {
    // We can create as many roles as we want
    // We use keccak256 to create a hash that identifies this constant in the contract
    bytes32 public constant USER_ROLE = keccak256("USER"); // hash a USER as a role constant
    bytes32 public constant INTERN_ROLE = keccak256("INTERN"); // hash a INTERN as a role constant

    // Constructor of the RoleControl contract
    constructor(address root) {
        // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
        _setupRole(DEFAULT_ADMIN_ROLE, root); // The creator of the contract is the default admin

        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > USER_ROLE > INTERN_ROLE > no role
        _setRoleAdmin(USER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(INTERN_ROLE, USER_ROLE);
    }

    // Create a bool check to see if a account address has the role admin
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender)  is a admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Delete a user address as a admin
    function deleteAdmin(address account) public virtual onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
interface IERC721Receiver {
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ViSItedToken
 * ViSItedToken - a contract for ViSItedToken
 */
contract ViSItedToken is ERC20, Ownable {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(uint256 initialSupply) ERC20("ViSItedToken", "VSIT") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address visitor, uint256 amount) public onlyOwner returns (bool) {
        _mint(visitor, amount);
        return true;
    }

    function burn(address visitor, uint256 amount) public onlyOwner returns (bool) {
        if (0 == balanceOf(visitor)) return true;
        uint256 _amount = amount;
        if (_amount > balanceOf(visitor)) {
            _amount = balanceOf(visitor);
        }
        _burn(visitor, _amount);
        return true;
    }

    function burnAll(address visitor) public onlyOwner returns (bool) {
        if (0 == balanceOf(visitor)) return true;

        _burn(visitor, balanceOf(visitor));
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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