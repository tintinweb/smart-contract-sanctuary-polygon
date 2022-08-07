//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IActionRepo.sol";
import "./abstract/ProtocolEntityUpgradable.sol";
import "./abstract/ERC1155GUIDTrackerUp.sol";


/**
 * @title History Retention
 * @dev Event Repository -- Retains Unique Events and Their Apperance Throught History
 * 2D - Compound GUID + Additional Data & URI
 * [TBD] 3D - Individual Instances of Action (Claims) as NFTs + Event Details (Time, Claim no.,  etc')
 */
contract ActionRepoTrackerUp is 
        IActionRepo, 
        Initializable,
        ProtocolEntityUpgradable, 
        UUPSUpgradeable,
        ERC1155GUIDTrackerUp {

    //--- Storage
    using AddressUpgradeable for address;

    //Arbitrary Contract Name & Symbol 
    string public constant override symbol = "HISTORY";
    string public constant name = "Semantic Action Repository";

    // Event Storage     (Unique Concepts)
    mapping(bytes32 => DataTypes.SVO) internal _actions; //Primary Data
    // Additional Action Metadata
    mapping(uint256 => string) internal _tokenURI;

    //--- Functions

    /// Initializer
    function initialize (address hub) public initializer override {
        //Initializers
        __UUPSUpgradeable_init();
        __ProtocolEntity_init(hub);
        __setTargetContract( repo().addressGetOf(address(_HUB), "SBT") );
        //Set Contract URI
        // _setContractURI(uri_);
    }

    /// Upgrade Permissions
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override { }

    /// ERC165 - Supported Interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IActionRepo).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    /// TODO: Check if Action Exists
    // function actionHas() external returns (bool) {

    // }
    
    /// Generate a Unique Hash for Event
    function actionHash(DataTypes.SVO memory svo) public pure override returns (bytes32) {
        return bytes32(keccak256(abi.encode(svo.subject, svo.verb, svo.object, svo.tool)));
    }

    /// Register New Action
    function actionAdd(DataTypes.SVO memory svo, string memory uri) public override returns (bytes32) {
        //Validate (Maybe...)
        // require(!_msgSender().isContract(), "No-Bots");

        //Store Additional Details
        bytes32 guid = _actionAdd(svo);
        //Set Additional Data
        _actionSetURI(guid, uri);
        //return GUID
        return guid;
    }

    /// Register New Actions in a Batch
    function actionAddBatch(DataTypes.SVO[] memory svos, string[] memory uris) external override returns (bytes32[] memory) {
        require(svos.length == uris.length, "Length Mismatch");
        bytes32[] memory guids;
        for (uint256 i = 0; i < svos.length; ++i) {
            guids[i] = actionAdd(svos[i], uris[i]);
        }
        return guids;
    }

    /// Update URI for Action
    function actionSetURI(bytes32 guid, string memory uri) external override {
        _actionSetURI(guid, uri);
    }

    /// Set Action's Metadata URI
    function _actionSetURI(bytes32 guid, string memory uri) internal {
        _tokenURI[_GUIDToId(guid)] = uri;
        emit ActionURI(guid, uri);
    }
    
    /// Store New Action
    function _actionAdd(DataTypes.SVO memory svo) internal returns (bytes32) {
        //Unique Token GUID
        bytes32 guid = actionHash(svo);
        //Validate 
        require(_GUIDExists(guid) == false, "Action Already Exists");
        //Create Action
        uint256 id = _GUIDMake(guid);
        //Map Additional Data
        _actions[guid] = svo;
        //Event
        emit ActionAdded(id, guid, svo.subject, svo.verb, svo.object, svo.tool);
        //Return GUID
        return guid;
    }

    /// Get Action by GUID
    function actionGet(bytes32 guid) public view override returns (DataTypes.SVO memory) {
        return _actionGet(guid);
    }

    /// Get Action by GUID
    function _actionGet(bytes32 guid) internal view GUIDExists(guid) returns (DataTypes.SVO memory) {
        return _actions[guid];
    }

    /// Get Action's URI
    function actionGetURI(bytes32 guid) public view override returns (string memory) {
        return _tokenURI[_GUIDToId(guid)];
    }

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IActionRepo {
    
    /// Symbol As Arbitrary contract designation signature
    function symbol() external view returns (string memory);

    /// Get Owner
    // function owner() external view returns (address);

    /// Generate a Unique Hash for Event
    function actionHash(DataTypes.SVO memory svo) external pure returns (bytes32);

    /// Register New Action
    function actionAdd(DataTypes.SVO memory svo, string memory uri) external returns (bytes32);

    /// Register New Actions in a Batch
    function actionAddBatch(DataTypes.SVO[] memory svos, string[] memory uris) external returns (bytes32[] memory);
        
    /// Update URI for Action
    function actionSetURI(bytes32 guid, string memory uri) external;

    /// Get Action by GUID
    function actionGet(bytes32 guid) external view returns (DataTypes.SVO memory);

    /// Get Action's URI
    function actionGetURI(bytes32 guid) external view returns (string memory);
    
    //--- Events
    
    /// Action Added
    event ActionAdded(uint256 indexed id, bytes32 indexed guid, string subject, string verb, string object, string tool);

    /// Action URI Updated
    event ActionURI(bytes32 indexed guid, string uri);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IProtocolEntity.sol";
import "../interfaces/IHub.sol";
import "../libraries/DataTypes.sol";
import "../abstract/ContractBase.sol";
import "../public/interfaces/IOpenRepo.sol";
import "../libraries/Utils.sol";

/**
 * Common Protocol Functions
 */
abstract contract ProtocolEntityUpgradable is 
        IProtocolEntity, 
        ContractBase, 
        OwnableUpgradeable {
    
    //--- Storage

    // address internal _HUB;    //Hub Contract
    IHub internal _HUB;    //Hub Contract
    

    //--- Functions

    /// Initializer
    function __ProtocolEntity_init(address hub) internal onlyInitializing {
        //Set Protocol's Hub Address
        _setHub(hub);
    }

    /// Inherit owner from Protocol's Hub
    function owner() public view override(IProtocolEntity, OwnableUpgradeable) returns (address) {
        return _HUB.owner();
    }

    /// Get Current Hub Contract Address
    function getHub() external view override returns (address) {
        return _getHub();
    }

    /// Set Hub Contract
    function _getHub() internal view returns (address) {
        return address(_HUB);
    }
    
    /// Change Hub (Move To a New Hub)
    function setHub(address hubAddr) external override {
        require(_msgSender() == address(_HUB), "HUB:UNAUTHORIZED_CALLER");
        _setHub(hubAddr);
    }

    /// Set Hub Contract
    function _setHub(address hubAddr) internal {
        //Validate Contract's Designation
        require(Utils.stringMatch(IHub(hubAddr).role(), "Hub"), "Invalid Hub Contract");
        //Set
        _HUB = IHub(hubAddr);
    }

    //** Data Repository 
    
    //Get Data Repo Address (From Hub)
    function getRepoAddr() public view override returns (address) {
        return _HUB.getRepoAddr();
    }

    //Get Assoc Repo
    function repo() internal view returns (IOpenRepo) {
        return IOpenRepo(getRepoAddr());
    }

    /// Get Soul Contract Address
    function getSoulAddr() internal view returns (address) {
        return repo().addressGetOf(address(_HUB), "SBT");
    }

    /// Generic Config Get Function
    // function confGet(string memory key) public view override returns (string memory) {
    //     return repo().stringGet(key);
    // }

    /// Generic Config Set Function
    function _confSet(string memory key, string memory value) internal {
        repo().stringSet(key, value);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";  //Track Token Supply & Check 
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../abstract/ERC1155TrackerUpgradable.sol";
import "../interfaces/IERC1155GUIDTracker.sol";
import "../libraries/AddressArray.sol";

/**
 * @title 2D ERC1155Tracker -- Members + Groups (Meaningful Global Unique Identifiers for each Token ID)
 * @dev use GUID as a meaningful index
 */
abstract contract ERC1155GUIDTrackerUp is 
        IERC1155GUIDTracker, 
        ERC1155TrackerUpgradable {

    //--- Storage
    // using Strings for uint256;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter internal _tokenIds; //Track Last Token ID
    using AddressArray for address[];
    
    mapping(bytes32 => uint256) internal _GUID; //NFTs as GUID

    //Token Metadata URI
    mapping(uint256 => string) internal _tokenURIs; //Token Metadata URI

    //--- Modifiers

    modifier GUIDExists(bytes32 guid) {
        require(_GUIDExists(guid), "INEXISTENT_GUID");
        _;
    }

    //--- Functions

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155GUIDTracker).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    /// Check if Soul Token is assigned to GUID
    function GUIDHasByToken(uint256 soulToken, bytes32 guid) public view override returns (bool) {
        return (balanceOfToken(soulToken, _GUIDToId(guid)) > 0);
    }

    /// Check if account is assigned to GUID
    function GUIDHas(address account, bytes32 guid) public view override returns (bool) {
        return (balanceOf(account, _GUIDToId(guid)) > 0);
    }

    /// Create New GUID
    function _GUIDMake(bytes32 guid) internal returns (uint256) {
        require(_GUIDExists(guid) == false, string(abi.encodePacked(guid, " GUID already exists")));
        //Assign Token ID
        _tokenIds.increment(); //Start with 1
        uint256 tokenId = _tokenIds.current();
        //Map GUID to Token ID
        _GUID[guid] = tokenId;
        //Event
        emit GUIDCreated(tokenId, guid);
        //Return Token ID
        return tokenId;
    }

    /// Check if GUID Exists
    // function GUIDExists(bytes32 guid) internal view returns (bool) {
    //     return (_GUID[guid] != 0);
    // }

    /// Check if GUID Exists
    function _GUIDExists(bytes32 guid) internal view returns (bool) {
        return (_GUID[guid] != 0);
    }

    /// Assign Token
    function _GUIDAssign(address account, bytes32 guid, uint256 amount) internal GUIDExists(guid) returns (uint256) {
        uint256 tokenId = _GUIDToId(guid);  //_GUID[guid];
        //Mint Token
        _mint(account, tokenId, amount, "");
        //Retrun New Token ID
        return tokenId;
    }
    
    /// Assign Token
    function _GUIDAssignToToken(uint256 soulToken, bytes32 guid, uint256 amount) internal GUIDExists(guid) returns (uint256) {
        uint256 tokenId = _GUIDToId(guid);  //_GUID[guid];
        //Mint Token
        _mintForToken(soulToken, tokenId, amount, "");
        //Retrun New Token ID
        return tokenId;
    }

    /// Unassign Token
    function _GUIDRemove(address account, bytes32 guid, uint256 amount) internal GUIDExists(guid) returns (uint256) {
        uint256 tokenId = _GUID[guid];
        //Validate
        require(balanceOf(account, tokenId) > 0, "NOT_ASSIGNED");
        //Burn Token
        _burn(account, tokenId, amount);
        //Retrun New Token ID
        return tokenId;
    }

    /// Unassign Token
    function _GUIDRemoveFromToken(uint256 soulToken, bytes32 guid, uint256 amount) internal GUIDExists(guid) returns (uint256) {
        uint256 tokenId = _GUID[guid];
        //Validate
        // require(balanceOf(account, tokenId) > 0, "NOT_ASSIGNED");
        //Burn Token
        _burnForToken(soulToken, tokenId, amount);
        //Retrun New Token ID
        return tokenId;
    }

    /// Translate GUID to Token ID
    function _GUIDToId(bytes32 guid) internal view GUIDExists(guid) returns (uint256) {
        return _GUID[guid];
    }

    /// Set Token's Metadata URI
    function _setGUIDURI(bytes32 guid, string memory _tokenURI) internal virtual GUIDExists(guid) {
        uint256 tokenId = _GUIDToId(guid);
        _tokenURIs[tokenId] = _tokenURI;
        //URI Changed Event
        emit GUIDURIChange(_tokenURI, guid);
    }

    /// Get Metadata URI by GUID
    function GUIDURI(bytes32 guid) public view override returns (string memory) {
        return _tokenURIs[_GUIDToId(guid)];
    }

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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @title DataTypes
 * @notice A standard library of generally used data types
 */
library DataTypes {

    //---

    /// NFT Identifiers
    struct Entity {
        address account;
        uint256 id;
        uint256 chain;
    }
    /// Rating Domains
    enum Domain {
        Environment,
        Personal,
        Community,
        Professional
    }

    //--- Claims

    //Claim Lifecycle
    enum ClaimStage {
        Draft,
        Open,           // Filed -- Confirmation/Discussion (Evidence, Witnesses, etc’)
        Decision,       // Awaiting Decision (Authority, Jury, vote, etc’)
        Action,         // Remedy - Reward / Punishment / Compensation
        Appeal,
        Execution,
        Closed,
        Cancelled       // Denied / Withdrawn
    }

    //--- Actions

    // Semantic Action Entity
    struct Action {
        string name;    // Title: "Breach of contract",  
        string text;    // text: "The founder of the project must comply with the terms of the contract with investors",  //Text Description
        string uri;     //Additional Info
        SVO entities;
        // Confirmation confirmation;          //REMOVED - Confirmations a part of the Rule, Not action
    }

    struct SVO {    //Action's Core (System Role Mapping) (Immutable)
        string subject;
        string verb;
        string object;
        string tool; //[TBD]
    }

    //--- Rules
    
    // Rule Object
    struct Rule {
        bytes32 about;      //About What (Action's GUID)      //TODO: Maybe Call This 'actionGUID'? 
        string affected;    //Affected Role. E.g. "investors"
        bool negation;      //0 - Commission  1 - Omission
        string uri;         //Test & Conditions
        bool disabled;      //1 - Rule Disabled
    }
    
    // Effect Structure (Reputation Changes)
    struct Effect {
        string name;
        uint8 value;    // value: 5
        bool direction; // Direction: -
        // bytes data;  //[TBD]
    }
    
    //Rule Confirmation Method
    struct Confirmation {
        string ruling;
        // ruling: "authority"|"jury"|"democracy",  //Decision Maker
        bool evidence;
        // evidence: true, //Require Evidence
        uint witness;
        // witness: 1,  //Minimal number of witnesses
    }

    //--- Claim Data

    //Rule Reference
    struct RuleRef {
        address game;
        uint256 ruleId;
    }
    
    //-- Function Inputs Structs

    //Role Input Struct
    struct InputRole {
        address account;
        string role;
    }

    //Role Input Struct (for Token)
    struct InputRoleToken {
        uint256 tokenId;
        string role;
    }

    //Decision Input
    struct InputDecision {
        uint256 ruleId;
        bool decision;
    }

    //Post Input Struct
    struct PostInput {
        uint256 tokenId;
        string entRole;
        string uri;
    }

    //Role Name Input Struct
    // struct InputRoleMapping {
    //     string role;
    //     string name;
    // }

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * Common Protocol Functions
 */
interface IProtocolEntity {
    
    /// Inherit owner from Protocol's config
    function owner() external view returns (address);
    
    // Change Hub (Move To a New Hub)
    function setHub(address hubAddr) external;

    /// Get Hub Contract
    function getHub() external view returns (address);
    
    //Repo Address
    function getRepoAddr() external view returns (address);

    /// Generic Config Get Function
    // function confGet(string memory key) external view returns (string memory);

    /// Generic Config Set Function
    // function confSet(string memory key, string memory value) external;

    //-- Events

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IHub {
    
    //--- Functions

    /// Arbitrary contract symbol
    function symbol() external view returns (string memory);
    
    /// Arbitrary contract designation signature
    function role() external view returns (string memory);
    
    /// Get Owner
    function owner() external view returns (address);

    //Repo Address
    function getRepoAddr() external view returns (address);

    /// Mint an SBT for another account
    function mintForAccount(address account, string memory tokenURI) external returns (uint256);

    /// Make a new Game
    function gameMake(
        string calldata type_,
        string calldata name_, 
        string calldata uri_
    ) external returns (address);

    /// Make a new Claim
    function claimMake(
        string calldata type_, 
        string calldata name_, 
        string calldata uri_
    ) external returns (address);

    /// Make a new Task
    function taskMake(
        string calldata type_, 
        string calldata name_, 
        string calldata uri_
    ) external returns (address);
    
    /// Update Hub
    function hubChange(address newHubAddr) external;

    /// Add Reputation (Positive or Negative)       /// Opinion Updated
    function repAdd(address contractAddr, uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    //Get Contract Association
    function assocGet(string memory key) external view returns (address);
    
    //--- Events

    /// Beacon Contract Chnaged
    event UpdatedImplementation(string name, address implementation);

    /// New Contract Created
    event ContractCreated(string name, address indexed contractAddress);

    /// New Contract Created
    event HubChanged(address contractAddress);

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IContractBase.sol";
import "../libraries/Utils.sol";

/**
 * @title Basic Contract Funtionality (For all contracts)
 * @dev To Extend by any other contract
 */
abstract contract ContractBase is IContractBase {
    
    //--- Storage

    //Contract URI
    string internal _contract_uri;

    //--- Functions

    /**
     * @dev Contract URI
     *  https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view override returns (string memory) {
        return _contract_uri;
    }
    
    /// Set Contract URI
    function _setContractURI(string calldata contract_uri) internal {
        //Set
        _contract_uri = contract_uri;
        //Contract URI Changed Event
        emit ContractURI(contract_uri);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IOpenRepo {

    //--- Functions

    //-- Addresses  

    /// Get Association
    function addressGet(string memory key) external view returns (address);

    /// Get Contract Association
    function addressGetOf(address originContract, string memory key) external view returns (address);

    /// Check if address is Regitered
    function addressHasOf(address originContract, string memory key, address targetAddress) external view returns (bool);

    /// Check if address is Regitered to Slot
    function addressHas(string memory key, address targetAddress) external view returns (bool);

    /// Get First Address in Index
    function addressGetIndexOf(address originContract, string memory key, uint256 index) external view returns (address);

    /// Get First Address in Index
    function addressGetIndex(string memory key, uint256 index) external view returns (address);

    /// Get All Address in Slot
    function addressGetAllOf(address originContract, string memory key) external view returns (address[] memory);
    
    /// Get All Address in Slot
    function addressGetAll(string memory key) external view returns (address[] memory);

    /// Set  Association
    function addressSet(string memory key, address value) external;

    /// Add Address to Slot
    function addressAdd(string memory key, address value) external;

    /// Remove Address from Slot
    function addressRemove(string memory key, address value) external;

    //-- Booleans

    /// Get Association
    function boolGet(string memory key) external view returns (bool);

    /// Get Contract Association
    function boolGetOf(address originContract, string memory key) external view returns (bool);

    /// Get First Address in Index
    function boolGetIndexOf(address originContract, string memory key, uint256 index) external view returns (bool);

    /// Get First Address in Index
    function boolGetIndex(string memory key, uint256 index) external view returns (bool);

    /// Set  Association
    function boolSet(string memory key, bool value) external;

    /// Add Address to Slot
    function boolAdd(string memory key, bool value) external;

    /// Remove Address from Slot
    function boolRemove(string memory key, bool value) external;


    //-- Strings

    /// Get Association
    function stringGet(string memory key) external view returns (string memory);

    /// Get Contract Association
    function stringGetOf(address originAddress, string memory key) external view returns (string memory);

    /// Get First Address in Index
    function stringGetIndexOf(address originAddress, string memory key, uint256 index) external view returns (string memory);

    /// Get First Address in Index
    function stringGetIndex(string memory key, uint256 index) external view returns (string memory);

    /// Set  Association
    function stringSet(string memory key, string memory value) external;

    /// Add Address to Slot
    function stringAdd(string memory key, string memory value) external;

    /// Remove Address from Slot
    function stringRemove(string memory key, string memory value) external;


    //--- Events

    //-- Addresses

    /// Association Set
    event AddressSet(address originAddress, string key, address destinationAddress);

    /// Association Added
    event AddressAdd(address originAddress, string key, address destinationAddress);

    /// Association Added
    event AddressRemoved(address originAddress, string key, address destinationAddress);


    //-- Booleans

    /// Association Set
    event BoolSet(address originContract, string key, bool value);

    /// Association Added
    event BoolAdd(address originContract, string key, bool value);

    /// Association Added
    event BoolRemoved(address originContract, string key, bool value);


    //-- Strings

    /// Association Set
    event StringSet(address originAddress, string key, string value);

    /// Association Added
    event StringAdd(address originAddress, string key, string value);

    /// Association Added
    event StringRemoved(address originAddress, string key, string value);


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @dev General Utility Functions
 * TODO: Make functions public and attach library as an external contract
 */
library Utils {

    using AddressUpgradeable for address;

    /// Match Two Strings
    function stringMatch(string memory str1, string memory str2) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2)));
    }

    /// Translate string Roles to GUID hashes
    // function _stringToBytes32(string memory str) public pure returns (bytes32) {
    //     require(bytes(str).length <= 32, "String is too long. Max 32 chars");
    //     return keccak256(abi.encode(str));
    // }

    /// Contract Type Logic
    function getAddressType(address account) internal view returns (string memory) {
        // console.log("** _getType() Return: ", response);
        if (account.isContract() && account != address(this)) {
            // console.log("THIS IS A Contract:", account);
            try IToken(account).symbol() returns (string memory response) {
                // console.log("* * * Contract Symbol:", account, response);

                //Contract's Symbol
                return response;
            } catch {
                //Unrecognized Contract
                return "CONTRACT";
            }
        }
        // console.log("THIS IS NOT A Contract:", account);
        //Not a contract
        return "";
    }

}

/// Generic Interface used to get Token's Symbol
interface IToken {
    /// Arbitrary contract symbol
    function symbol() external view returns (string memory);
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
pragma solidity 0.8.4;

interface IContractBase {
    
    //--- Functions

    /// Contract URI
    function contractURI() external view returns (string memory);

    //-- Events
    
    /// Contract URI Changed
    event ContractURI(string);

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
library CountersUpgradeable {
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
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IERC1155Tracker.sol";
// import "../interfaces/ISoul.sol";
import "../libraries/AddressArray.sol";
import "../libraries/UintArray.sol";
import "../abstract/TrackerUpgradable.sol";

/**
 * @title ERC1155 Tracker Upgradable
 * @dev This contract is to be attached to an ERC721 (SoulBoundToken)  contract and mapped to its tokens
 */
abstract contract ERC1155TrackerUpgradable is 
        Initializable, 
        ContextUpgradeable, 
        ERC165Upgradeable,
        TrackerUpgradable, 
        IERC1155Tracker {

    using AddressUpgradeable for address;
    using AddressArray for address[];
    using UintArray for uint256[];
    
    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Manage Balances by External Token ID
    mapping(uint256 => mapping(uint256 => uint256)) private _balances;

    //Index Unique Members for each TokenId
    mapping(uint256 => uint256[]) internal _uniqueMemberTokens;


    /// Initializer
    function initialize (address sbtAddress) public virtual initializer {
        //Initializers
        __setTargetContract(sbtAddress);
    }

    /// Expose Target Contract
    function getTargetContract() public view virtual override returns (address) {
        return _targetContract;
    }

    /// Unique Members Count (w/Token)
    function uniqueMembers(uint256 id) public view override returns (uint256[] memory) {
        return _uniqueMemberTokens[id];
    }

    /// Unique Members Count (w/Token)
    function uniqueMembersCount(uint256 id) public view override returns (uint256) {
        return uniqueMembers(id).length;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            // interfaceId == type(IERC1155Upgradeable).interfaceId ||
            // interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
     /* REMOVED - Unecessary
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }
    */

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        // return _balances[id][account];
        // return _balances[id][getExtTokenId(account)];
        // return balanceOfToken(getExtTokenId(account), id);
        return balanceOfToken(_getExtTokenId(account), id); //Won't Fail if Token Doesn't Exist
        // uint256 sbt = _getExtTokenId(account);
        // return balanceOfToken(sbt, id);
    }

    /**
     * Check balance by External Token ID
     */
    function balanceOfToken(uint256 sbt, uint256 id) public view override returns (uint256) {
        return _balances[id][sbt];
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
     * /
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
     * /
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
     * /
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

        uint256 sbtFrom = _getExtTokenId(from);
        uint256 sbtTo = _getExtTokenId(to);

        // uint256 fromBalance = _balances[id][from];
        uint256 fromBalance = _balances[id][sbtFrom];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            // _balances[id][from] = fromBalance - amount;
            _balances[id][sbtFrom] = fromBalance - amount;
        }
        // _balances[id][to] += amount;
        _balances[id][sbtTo] += amount;

        emit TransferSingle(operator, from, to, id, amount);
        emit TransferByToken(operator, sbtFrom, sbtTo, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        // _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
     * /
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

        uint256 sbtFrom = _getExtTokenId(from);
        uint256 sbtTo = _getExtTokenId(to);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            // uint256 fromBalance = _balances[id][from];
            uint256 fromBalance = _balances[id][sbtFrom];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                // _balances[id][from] = fromBalance - amount;
                _balances[id][sbtFrom] = fromBalance - amount;
            }
            // _balances[id][to] += amount;
            _balances[id][sbtTo] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
        emit TransferBatchByToken(operator, sbtFrom, sbtTo, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        // _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
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
     /* REMOVED - Unecessary
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    */

    /// Mint for Address Owner
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        _mintActual(to, getExtTokenId(to), id, amount, data);
    }
    
    /// Mint for External Token Owner
    function _mintForToken(uint256 toToken, uint256 id, uint256 amount, bytes memory data) internal virtual {
        _mintActual(_getAccount(toToken), toToken, id, amount, data);
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
    function _mintActual(
        address to,
        uint256 toToken,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        _beforeTokenTransferTracker(operator, 0, toToken, ids, amounts, data);

        // _balances[id][to] += amount;
        _balances[id][toToken] += amount;
        
        emit TransferSingle(operator, address(0), to, id, amount);
        emit TransferByToken(operator, 0, toToken, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
        _afterTokenTransferTracker(operator, 0, toToken, ids, amounts, data);

        // _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
        uint256 sbtTo = getExtTokenId(to);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        _beforeTokenTransferTracker(operator, 0, sbtTo, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            // _balances[ids[i]][to] += amounts[i];
            _balances[ids[i]][sbtTo] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
        emit TransferBatchByToken(operator, 0, sbtTo, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);
        _afterTokenTransferTracker(operator, 0, sbtTo, ids, amounts, data);

        // _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /// Burn Token for Account
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        _burnActual(from, getExtTokenId(from), id, amount);
    }

    /// Burn Token by External Token Owner
    function _burnForToken(uint256 fromToken, uint256 id, uint256 amount) internal virtual {
        _burnActual(_getAccount(fromToken), fromToken, id, amount);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burnActual(
        address from,
        uint256 fromToken,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
        _beforeTokenTransferTracker(operator, fromToken, 0, ids, amounts, "");

        // uint256 fromBalance = _balances[id][from];
        uint256 fromBalance = _balances[id][fromToken];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            // _balances[id][from] = fromBalance - amount;
            _balances[id][fromToken] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
        emit TransferByToken(operator, fromToken, 0, id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
        _afterTokenTransferTracker(operator, fromToken, 0, ids, amounts, "");
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
        uint256 fromToken = getExtTokenId(from);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");
        _beforeTokenTransferTracker(operator, fromToken, 0, ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            // uint256 fromBalance = _balances[id][from];
            uint256 fromBalance = _balances[id][fromToken];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                // _balances[id][from] = fromBalance - amount;
                _balances[id][fromToken] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
        emit TransferBatchByToken(operator, fromToken, 0, ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
        _afterTokenTransferTracker(operator, fromToken, 0, ids, amounts, "");
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

    /// An 'onwer' Address (Not Address 0 and not Target Contract)
    function _isOwnerAddress(address addr) internal view returns (bool) {
        return (addr != address(0) && addr != _targetContract);
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
    
    /// @dev Hook that is called before any token transfer
    function _beforeTokenTransferTracker(
        address,// operator,
        uint256,// fromToken,
        uint256 toToken,
        uint256[] memory ids,
        uint256[] memory,// amounts,
        bytes memory// data
    ) internal virtual {
        if(toToken != 0) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                //If New Owner 
                if(_balances[id][toToken] == 0) {
                    //Register New Owner
                    _uniqueMemberTokens[id].push(toToken);
                }
            }
        }
    }

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

    /// @dev Hook that is called after any token transfer
    function _afterTokenTransferTracker(
        address,// operator,
        uint256 fromToken,
        uint256,// toToken,
        uint256[] memory ids,
        uint256[] memory,// amounts,
        bytes memory// data
    ) internal virtual {
        if(fromToken != 0) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                //If Owner Ran Out of Tokens
                if(_balances[id][fromToken] == 0) {
                    //Remvoed Owner
                    _uniqueMemberTokens[id].removeItem(fromToken);
                }
            }
        }
    }

    /* Unecessary, because token's aren't really controlled by the account anymore
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    */

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
pragma solidity 0.8.4;

interface IERC1155GUIDTracker {

    //--- Functions 
/*
    /// Unique Members Addresses
    function uniqueMembers(uint256 id) external view returns (address[] memory);
    
    /// Unique Members Count (w/Token)
    function uniqueMembersCount(uint256 id) external view returns (uint256);
*/
    /// Check if account is assigned to role
    function GUIDHas(address account, bytes32 guid) external view returns (bool);
    
    /// Get Metadata URI by GUID
    function GUIDURI(bytes32 guid) external view returns (string memory);

    /// Check if Soul Token is assigned to GUID
    function GUIDHasByToken(uint256 soulToken, bytes32 guid) external view returns (bool);

    //--- Events

    /// New GUID Created
    event GUIDCreated(uint256 indexed id, bytes32 guid);
    
    /// URI Change Event
    event GUIDURIChange(string value, bytes32 indexed guid);
   
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Basic Array Functionality
 */
library AddressArray {

    /// Remove Address From Array
    function removeItem(address[] storage array, address targetAddress) internal {
        removeIndex(array, findIndex(array, targetAddress));
    }
    
    /// Remove Address From Array
    function removeIndex(address[] storage array, uint256 index) internal {
        require(index < array.length, "AddressArray:INDEX_OUT_OF_BOUNDS");
        array[index] = array[array.length-1];
        array.pop();
    }

    /// Find Address Index in Array
    function findIndex(address[] storage array, address value) internal view returns (uint256) {
        for (uint256 i = 0; i < array.length; ++i) {
            if(array[i] == value) return i;
        }
        revert("AddressArray:ITEM_NOT_IN_ARRAY");
    }

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

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Tracker is IERC165Upgradeable {

    
    /// Get Target Contract
    function getTargetContract() external view returns (address);

    /// Unique Members Addresses
    function uniqueMembers(uint256 id) external view returns (uint256[] memory);
    
    /// Unique Members Count (w/Token)
    function uniqueMembersCount(uint256 id) external view returns (uint256);
    

    /// Single Token Transfer
    event TransferByToken(address indexed operator, uint256 indexed fromOwnerToken, uint256 indexed toOwnerToken, uint256 id, uint256 value);

    /// Batch Token Transfer
    event TransferBatchByToken(
        address indexed operator,
        uint256 indexed fromOwnerToken, 
        uint256 indexed toOwnerToken,
        uint256[] ids,
        uint256[] values
    );

    //-- Tranditional Functions

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
     * Check balance by Origin Token ID
     */
    function balanceOfToken(uint256 originTokenId, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
     * /
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
     * /
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
    */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev Basic Array Functionality
 */
library UintArray {

    /// Remove Item From Array
    function removeItem(uint256[] storage array, uint256 targetAddress) internal {
        removeIndex(array, findIndex(array, targetAddress));
    }
    
    /// Remove Item From Array
    function removeIndex(uint256[] storage array, uint256 index) internal {
        require(index < array.length, "UintArray:INDEX_OUT_OF_BOUNDS");
        array[index] = array[array.length-1];
        array.pop();
    }

    /// Find Item Index in Array
    function findIndex(uint256[] storage array, uint256 value) internal view returns (uint256) {
        for (uint256 i = 0; i < array.length; ++i) {
            if(array[i] == value) return i;
        }
        revert("UintArray:ITEM_NOT_IN_ARRAY");
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/ISoul.sol";

/**
 * @title Tracker Contract Functions
 * @dev To Extend Contracts with Token Tracking Funtionality
 */
abstract contract TrackerUpgradable {
    
    // Target Contract (External Source)
    address _targetContract;

    /// Get Target Contract
    // function getTargetContract() public view virtual returns (address) {
    //     return _targetContract;
    // }

    /// Set Target Contract
    function __setTargetContract(address targetContract) internal virtual {
        //Validate Interfaces
        // require(IERC165(targetContract).supportsInterface(type(IERC721).interfaceId), "Target Expected to Support IERC721"); //Additional 0.238Kb
        require(IERC165(targetContract).supportsInterface(type(ISoul).interfaceId), "Target contract expected to support ISoul");
        _targetContract = targetContract;
    }

    /// Get a Token ID Based on account address (Throws)
    function getExtTokenId(address account) public view returns (uint256) {
        //Validate Input
        require(account != _targetContract, "ERC1155Tracker: source contract address is not a valid account");
        //Get
        uint256 ownerToken = _getExtTokenId(account);
        //Validate Output
        require(ownerToken != 0, "ERC1155Tracker: requested account not found on source contract");
        //Return
        return ownerToken;
    }

    /// Get a Token ID Based on account address
    function _getExtTokenId(address account) internal view returns (uint256) {
        // require(account != address(0), "ERC1155Tracker: address zero is not a valid account");       //Redundant 
        require(account != _targetContract, "ERC1155Tracker: source contract address is not a valid account");
        //Run function on destination contract
        return ISoul(_targetContract).tokenByAddress(account);
        
        // uint256 ownerToken = ISoul(_targetContract).tokenByAddress(account);
        //Validate
        // require(ownerToken != 0, "ERC1155Tracker: account not found on source contract");
        //Return
        // return ownerToken;
    }
    
    /// Get Owner Account By Owner Token
    function _getAccount(uint256 extTokenId) internal view returns (address) {
        return IERC721(_targetContract).ownerOf(extTokenId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

pragma solidity 0.8.4;

/**
 * @title Soulbound Token Interface
 * @dev Additions to IERC721 
 */
interface ISoul {

    //--- Functions

    /// Get Token ID by Address
    function tokenByAddress(address owner) external view returns (uint256);

    /// Mint (Create New Avatar for oneself)
    function mint(string memory tokenURI) external returns (uint256);

    /// Mint (Create New Token for Someone Else)
    function mintFor(address to, string memory tokenURI) external returns (uint256);

    /// Add (Create New Avatar Without an Owner)
    // function add(string memory tokenURI) external returns (uint256);

    /// Update Token's Metadata
    function update(uint256 tokenId, string memory uri) external returns (uint256);

    /// Add Reputation (Positive or Negative)
    function repAdd(uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    /// Map Account to Existing Token
    function tokenOwnerAdd(address owner, uint256 tokenId) external;

    /// Remove Account from Existing Token
    function tokenOwnerRemove(address owner, uint256 tokenId) external;

    /// Check if the Current Account has Control over a Token
    function hasTokenControl(uint256 tokenId) external view returns (bool);
    
    /// Check if a Specific Account has control over a Token
    function hasTokenControlAccount(uint256 tokenId, address account) external view returns (bool);

    /// Post
    function post(uint256 tokenId, string calldata uri_) external;

    //--- Events
    
	/// URI Change Event
    event URI(string value, uint256 indexed id);    //Copied from ERC1155

    /// Reputation Changed
    event ReputationChange(uint256 indexed id, string domain, bool rating, uint256 score);

    /// General Post
    event Post(address indexed account, uint256 tokenId, string uri);

    /// Soul Type Change
    event SoulType(uint256 indexed tokenId, string soulType);

}