// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";
import "./interfaces/IArcana.sol";
import "./interfaces/IDID.sol";
import "./interfaces/IFactoryArcana.sol";
import "./RoleLib.sol";

/**
 * @title Arcana ACL
 * @dev Manages the ACL of the files uploaded to Arcana network
 */
contract Arcana is ERC2771ContextUpgradeable, OwnableUpgradeable, IArcana {
    using RoleLib for uint8;
    bool private active;

    enum WalletMode {
        NoUI,
        Full
    }

    /// @dev Wallet mode type - NoUI or Full
    WalletMode public walletType;

    //Compulsary access given to app
    uint8 public appLevelControl;
    //Delegators (app provided)
    ///@dev
    /*
        Download = 1; //001
        UpdateRuleSet = 2; //010
        Remove = 4;//100
        Transfer = 8;//1000
    */
    mapping(address => uint8) public delegators;

    mapping(address => uint8) public userAppPermission;
    //maintain user re-version
    mapping(bytes32 => FileInfo) public appFiles;

    mapping(address => uint256) public userVersion;

    /// @dev Mapping user => Limit (i.e, storage and bandwidth)
    mapping(address => Limit) public limit;
    /// @dev Resource consumption
    mapping(address => Limit) public consumption;

    /// @dev keeps track of transactionHashs used for download
    mapping(bytes32 => bool) public txCounter;

    /// @dev If this is true then DKG will generate same key for all the oAuth providers
    bool public aggregateLogin;

    /// @dev App config is hash of json string which has the app configuration like app name, client id, etc.
    bytes32 private _appConfig;

    /// @dev Factory contract address
    address internal factory;

    /// @dev File struct
    struct FileInfo {
        address owner;
        uint256 userVersion;
    }

    /* solhint-disable */
    /// @dev Default limit i.e, storage and bandwidth
    Limit public defaultLimit;
    /// @dev DID Interface contract
    IDID private didContract;
    /* solhint-enable */
    struct Limit {
        uint256 store;
        uint256 bandwidth;
    }

    /// @dev Checks if the caller is file owner before calling a function
    modifier onlyFileOwner(bytes32 _did) {
        require(_msgSender() == didContract.getFileOwner(_did), "only_file_owner");
        _;
    }
    /// @dev Only Factory contract can call the function when this modifier is used
    modifier onlyFactoryContract() {
        require(isFactoryContract(), "only_factory_contract");
        _;
    }

    /// @dev Checks upload limit while uploading a new file with new file size.
    modifier checkUploadLimit(uint256 _fileSize) {
        require(
            consumption[_msgSender()].store + _fileSize <= max(limit[_msgSender()].store, defaultLimit.store),
            "no_user_space"
        );
        require(consumption[address(0)].store + _fileSize <= limit[address(0)].store, "No space left for app");
        _;
    }

    event DownloadViaRuleSet(bytes32 did, address user);

    event DeleteApp(address owner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Act like an constructor for Initializable contract
     * Sets app and owner of the app
     * @param factoryAddress factory contract address
     * @param relayer forwarder contract address
     * @param aggregateLoginValue if true, then DKG will generate same key for all OAuth providers
     * @param did DID contract address
     * @param appConfigValue  app config hash
     */
    function initialize(
        address factoryAddress,
        address relayer,
        bool aggregateLoginValue,
        address did,
        bytes32 appConfigValue
    ) external initializer {
        require(factoryAddress != address(0), "zero address");
        factory = factoryAddress;
        aggregateLogin = aggregateLoginValue;
        OwnableUpgradeable.__Ownable_init();
        ERC2771ContextUpgradeable.__ERC2771Context_init(relayer);
        didContract = IDID(did);
        _appConfig = appConfigValue;
        walletType = WalletMode.Full;
        active = true;
    }

    // @dev to check whether the contract is active or not
    function isActive() external view returns (bool) {
        return active;
    }

    /// @dev End user agreeing to app permission
    function grantAppPermission() external {
        require(userAppPermission[_msgSender()] != appLevelControl, "user_permission_already_granted");
        userAppPermission[_msgSender()] = appLevelControl;
    }

    /// @dev Used for exiting the app
    function revokeApp() external {
        userVersion[_msgSender()] += 1;
        userAppPermission[_msgSender()] = 0;
    }

    /**
     * @dev App owner will use this to edit app level permission
     * @param appPermission New permission
     * @param add Specifies whether above permission is added or removed
     */
    function editAppPermission(uint8 appPermission, bool add) external onlyOwner {
        if (add) {
            appLevelControl = appLevelControl.grantRole(appPermission);
        } else {
            appLevelControl = appLevelControl.revokeRole(appPermission);
        }
    }

    /**
     * @dev Add/Remove/Update a new delegator to app
     * @param delegator Address of the new/existing delegator
     * @param control Control for delegator
     * @param add Specifies whether above control is added or removed
     */
    function updateDelegator(
        address delegator,
        uint8 control,
        bool add
    ) external onlyOwner {
        //check if permission is added to app level
        if (add) {
            require(appLevelControl.hasRole(control), "app_level_permission_not_found");
            delegators[delegator] = delegators[delegator].grantRole(control);
        } else {
            delegators[delegator] = delegators[delegator].revokeRole(control);
        }
    }

    /// @return uint256 Maximum of two numbers
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @dev Checks if msg.sender is Factory contract
    function isFactoryContract() internal view returns (bool) {
        return msg.sender == address(factory);
    }

    /**
     * @dev overrides msg.sender with the original sender, since it is proxy call. Implemented from ERC2771.
     * @return sender end user who initiated the meta transaction
     */
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            require(isFactoryContract(), "non_trusted_forwarder_or_factory");
            return super._msgSender();
        }
    }

    /**
     * @dev To add already uploaded file to this app
     * @param did Did of the file that is getting added
     */
    function addFile(bytes32 did) external onlyFileOwner(did) {
        address _fileOwner = didContract.getFileOwner(did);
        (uint256 _fileSize, bool _uploaded, , , ) = didContract.getFile(did);
        require(_uploaded, "file_not_uploaded_yet");
        require(appFiles[did].userVersion == userVersion[_fileOwner], "file_already_added");
        consumption[_fileOwner].store += _fileSize;
        consumption[address(0)].store += _fileSize;
        appFiles[did] = FileInfo(_fileOwner, userVersion[_fileOwner]);
        (bool status, string memory err) = didContract.checkPermission(did, 0, _msgSender());
        require(status, err);
    }

    /**
     * @dev remove user file via owner or delegator from the app
     * @param did did of the file to be removed
     */
    function removeUserFile(bytes32 did) external {
        (bool status, string memory err) = didContract.checkPermission(did, 4, _msgSender());
        require(status, err);
        appFiles[did] = FileInfo(address(0), 0);
    }

    /**
     * @dev Executed before uploading the file. This function will be called by the client
     * @param did DID of the file which is unique identifier to a file
     * @param fileSize Size of the file
     * @param name file name hash, value stored in db
     * @param fileHash file hash
     * @param storageNode Storage Node address
     * @param ephemeralAddress This address is used to sign the message in upload transaction
     */

    function uploadInit(
        bytes32 did,
        uint256 fileSize,
        bytes32 name,
        bytes32 fileHash,
        address storageNode, // solhint-disable-next-line
        address ephemeralAddress
    ) external checkUploadLimit(fileSize) {
        uint8 _userPerm = userAppPermission[_msgSender()];
        require(_userPerm.hasRole(appLevelControl), "permission_not_granted");
        require(didContract.getFileOwner(did) == address(0), "owner_already_exists");
        require(fileSize != 0, "zero_file_size");
        appFiles[did] = FileInfo(_msgSender(), userVersion[_msgSender()]);
        didContract.setFile(did, _msgSender(), fileSize, false, name, fileHash, storageNode);
        //check if storageNode is registered with factory
        require(IFactoryArcana(factory).isNode(storageNode), "storage_node_not_found");
    }

    /**
     * @dev Executed after uploading the file
     * If the function fails then uploaded must be deleted from the arcana network
     * @param did DID of the file which is unique identifier to a file
     */
    function uploadClose(bytes32 did) external {
        (uint256 _fileSize, bool _uploaded, , , address _storageNode) = didContract.getFile(did);
        // As this function is called directly by storage node there is no need of meta tx(_msgSender)
        require(msg.sender == _storageNode, "only_storage_node");
        require(!_uploaded, "file_already_uploaded");
        consumption[didContract.getFileOwner(did)].store += _fileSize;
        consumption[address(0)].store += _fileSize;
        didContract.completeUpload(did);
        (bool status, string memory err) = didContract.checkPermission(did, 0, didContract.getFileOwner(did));
        require(status, err);
    }

    /**
     * @dev download file by delegator or owner
     * @param did file to be downloaded
     * @param ephemeralWallet This address is used to sign the message in upload transaction
     */
    function download(bytes32 did, address ephemeralWallet) external {
        (uint256 _fileSize, bool _uploaded, , , ) = didContract.getFile(did);
        require(_uploaded, "file_not_found");
        require(
            max(defaultLimit.bandwidth, limit[_msgSender()].bandwidth) >=
                consumption[_msgSender()].bandwidth + _fileSize,
            "user_bandwidth_limit_reached"
        );
        require(
            limit[address(0)].bandwidth >= consumption[address(0)].bandwidth + _fileSize,
            "app_bandwidth_limit_reached"
        );

        consumption[_msgSender()].bandwidth += _fileSize;
        (bool status, ) = didContract.checkPermission(did, 1, _msgSender());
        if (!status) {
            emit DownloadViaRuleSet(did, _msgSender());
            consumption[address(0)].bandwidth += _fileSize;
        }
    }

    /**
     * @dev download closure for bandwidth computation by storage nodes
     * @param did file that being downloaded
     * @param txHash tx hash that used for downlaoding file
     */
    function downloadClose(bytes32 did, bytes32 txHash) external {
        (uint256 _fileSize, , , , ) = didContract.getFile(did);
        //check if transaction hash already there
        require(!txCounter[txHash], "tx_hash_already_used");
        txCounter[txHash] = true;
        consumption[address(0)].bandwidth += _fileSize;
        //check if caller is storage node
        require(IFactoryArcana(factory).isNode(msg.sender), "only_storage_node");
    }

    /**
     * @dev This used for sharing and revoking
     * @param did did of the file
     * @param ruleHash updated rule set
     */
    function updateRuleSet(bytes32 did, bytes32 ruleHash) external {
        (bool status, string memory err) = didContract.checkPermission(did, 2, _msgSender());
        require(status, err);
        didContract.updateRuleSet(did, ruleHash);
    }

    /**
     * @dev This used for changing file owner
     * @param did did of the file
     * @param newOwner new file owner
     */
    function changeFileOwner(bytes32 did, address newOwner) external {
        (bool status, string memory err) = didContract.checkPermission(did, 8, _msgSender());
        require(status, err);
        didContract.changeFileOwner(did, newOwner);
    }

    /**
     * @dev sets app level storage and bandwidth limit
     * @param store storage limit
     * @param bandwidth bandwidth limit
     */
    function setAppLimit(uint256 store, uint256 bandwidth) external onlyFactoryContract {
        limit[address(0)] = Limit(store, bandwidth);
    }

    /**
     * @dev sets user level storage and bandwidth limit
     * @param user user address
     * @param store storage limit
     * @param bandwidth bandwidth limit
     */
    function setUserLevelLimit(
        address user,
        uint256 store,
        uint256 bandwidth
    ) external onlyOwner {
        limit[user] = Limit(store, bandwidth);
    }

    /**
     * @dev sets app level storage and bandwidth limit with default values
     * @param store storage limit
     * @param bandwidth bandwidth limit
     */
    function setDefaultLimit(uint256 store, uint256 bandwidth) external onlyOwner {
        defaultLimit = Limit(store, bandwidth);
    }

    /**
     * @dev Links NFT to the DID
     * @param did DID of the file which is unique identifier to a file
     * @param tokenId tokenId of the NFT
     * @param nftContract NFT contract address
     * @param chainId chainId of the chain where the NFTs are deployed on
     */
    function linkNFT(
        bytes32 did,
        uint256 tokenId,
        address nftContract,
        uint256 chainId
    ) external onlyFileOwner(did) {
        didContract.linkNFT(did, tokenId, nftContract, chainId);
    }

    /**
     * @dev Fetch app configuration
     */
    function getAppConfig() external view returns (bytes32) {
        return _appConfig;
    }

    /**
     * @dev Set app configuration
     * @param appConfig app configuration
     */
    function setAppConfig(bytes32 appConfig) external onlyOwner {
        _appConfig = appConfig;
    }

    /**
     @dev Toggle wallet type
     */
    function toggleWalletType() external onlyFactoryContract {
        if (walletType == WalletMode.Full) {
            walletType = WalletMode.NoUI;
        } else {
            walletType = WalletMode.Full;
        }
    }

    /**
     @dev Destroy's the App from blockchain
     */
    function deleteApp() external onlyOwner {
        active = false;
        emit DeleteApp(_msgSender());
    }
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
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity 0.8.8;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    // solhint-disable-next-line
    function __ERC2771Context_init(address trustedForwarder) internal onlyInitializing {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    // solhint-disable-next-line
    function __ERC2771Context_init_unchained(address trustedForwarder) internal onlyInitializing {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// import "./IArcanaDID.sol";
// import "./IArcanaFactory.sol";
// import "./IArcanaForwarder.sol";

/// @dev Interface for Arcana logic contract
interface IArcana {
    /**
     * @dev Act like an constructor for Initializable contract
     * Sets app and owner of the app
     * @param factoryAddress factory contract address
     * @param relayer forwarder contract address
     * @param aggregateLoginValue if true, then DKG will generate same key for all OAuth providers
     * @param did DID contract address
     * @param appConfigValue  app config hash
     */
    function initialize(
        address factoryAddress,
        address relayer,
        bool aggregateLoginValue,
        address did,
        bytes32 appConfigValue
    ) external;

    /// @dev If this is true then DKG will generate same key for all the oAuth providers
    function aggregateLogin() external returns (bool);

    /**
     * @dev Set app configuration
     * @param appConfig app configuration
     */
    function setAppConfig(bytes32 appConfig) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

/// @dev Interface for DID contract
interface IDID {
    // Contains file meta data
    struct File {
        address owner;
        uint256 fileSize;
        bool uploaded;
        bytes32 name;
        bytes32 fileHash;
        // Download 1; //001
        // Delete = 2; //010
        // Transfer = 4; //100
        address storageNode;
        NFTInfo nftDetails;
        mapping(uint8 => bytes32) controlRules; // Only Download is enabled for now, rest of them are for future profing
    }

    struct NFTInfo {
        uint256 chainId;
        uint256 tokenId;
        address contractAddress;
    }

    function linkNFT(
        bytes32 _did,
        uint256 _tokenId,
        address _nftContract,
        uint256 _chainId
    ) external;

    /**
     * @param _did DID of the file
     * @return _owner owner of the file.
     */
    function getFileOwner(bytes32 _did) external view returns (address);

    /**
     * @dev   sets file data
     * @param _did DID of the file
     * @param _owner owner of the file
     * @param _fileSize size of the file
     * @param _uploaded bool whether file is uploaded or not
     * @param _storageNode Storage Node address
     */
    function setFile(
        bytes32 _did,
        address _owner,
        uint256 _fileSize,
        bool _uploaded,
        bytes32 _name,
        bytes32 _fileHash,
        address _storageNode
    ) external;

    /* *
     * @param _did DID of the file
     * @return _File file data
     */
    function getFile(bytes32 _did)
        external
        view
        returns (
            uint256 fileSize,
            bool uploaded,
            bytes32 _name,
            bytes32 _fileHash,
            address storageNode
        );

    /**
     * @dev Delete file from the files
     * @param _did DID of the file
     */
    function deleteFile(bytes32 _did) external;

    /**
     * @dev Sets uploaded bool to true
     * @param _did DID of the file
     */
    function completeUpload(bytes32 _did) external;

    /**
     * @dev Transfers the ownership of the file
     * @param _did DID of the file
     * @param _owner new owner of the file
     */
    function changeFileOwner(bytes32 _did, address _owner) external;

    function checkPermission(
        bytes32 _did,
        uint8 _control,
        address _requester
    ) external returns (bool, string memory);

    function updateRuleSet(bytes32 _did, bytes32 _ruleHash) external;

    function getRuleSet(bytes32 _did) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

interface IFactoryArcana {
    function isNode(address _node) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// uint8 public Download = 1; //001
// uint8 public UpdateRuleSet = 2; //010
// uint8 public Delete = 4;//100
// uint8 public Transfer = 8;//1000

library RoleLib {
    function hasRole(uint8 role, uint8 testRole) public pure returns (bool) {
        return ((role & testRole) == testRole);
    }

    function grantRole(uint8 currRole, uint8 role) external pure returns (uint8) {
        require(!hasRole(currRole, role), "role_already_applied");
        return currRole | role;
    }

    function revokeRole(uint8 currRole, uint8 role) external pure returns (uint8) {
        require(hasRole(currRole, role), "role_not_found");
        return currRole ^ role;
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