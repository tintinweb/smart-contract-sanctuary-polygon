// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './interfaces/IIndexerRegistry.sol';
import './interfaces/IStaking.sol';
import './interfaces/ISettings.sol';
import './interfaces/IQueryRegistry.sol';
import './interfaces/IServiceAgreementRegistry.sol';

/**
 * @title Query Registry Contract
 * @notice ### Overview
 * This contract tracks all query projects and their deployments. At the beginning of the network,
 * we will start with the restrict mode which only allow permissioned account to create and update query project.
 * Indexers are able to start and stop indexing with a specific deployment from this conttact. Also Indexers can update and report
 * their indexing status from this contarct.
 */
contract QueryRegistry is Initializable, OwnableUpgradeable, IQueryRegistry {
    /// @notice query project information
    struct QueryInfo {
        uint256 queryId;
        address owner;
        bytes32 latestVersion;
        bytes32 latestDeploymentId;
        bytes32 metadata;
    }

    /// @notice indexing status for an indexer
    struct IndexingStatus {
        bytes32 deploymentId;
        uint256 timestamp;
        uint256 blockHeight;
        IndexingServiceStatus status;
    }

    /// @dev ### STATES
    /// @notice ISettings contract which stores SubQuery network contracts address
    ISettings public settings;

    /// @notice next query project id
    uint256 public nextQueryId;

    /// @notice is the contract run in creator restrict mode. If in creator restrict mode, only permissioned account allowed to create and update query project
    bool public creatorRestricted;

    /// @notice Threshold to calculate is indexer offline
    uint256 private offlineCalcThreshold;

    /// @notice query project ids -> QueryInfo
    mapping(uint256 => QueryInfo) public queryInfos;

    /// @notice account address -> is creator
    mapping(address => bool) public creatorWhitelist;

    /// @notice deployment id -> indexer -> IndexingStatus
    mapping(bytes32 => mapping(address => IndexingStatus)) public deploymentStatusByIndexer;

    /// @notice indexer -> deployment numbers
    mapping(address => uint256) public numberOfIndexingDeployments;

    /// @notice is the id a deployment
    mapping(bytes32 => bool) private deploymentIds;

    /// @dev EVENTS
    /// @notice Emitted when query project created.
    event CreateQuery(uint256 indexed queryId, address indexed creator, bytes32 metadata, bytes32 deploymentId, bytes32 version);

    /// @notice Emitted when the metadata of the query project updated.
    event UpdateQueryMetadata(address indexed owner, uint256 indexed queryId, bytes32 metadata);

    /// @notice Emitted when the latestDeploymentId of the query project updated.
    event UpdateQueryDeployment(address indexed owner, uint256 indexed queryId, bytes32 deploymentId, bytes32 version);

    /// @notice Emitted when indexers start indexing.
    event StartIndexing(address indexed indexer, bytes32 indexed deploymentId);

    /// @notice Emitted when indexers report their indexing Status
    event UpdateDeploymentStatus(address indexed indexer, bytes32 indexed deploymentId, uint256 blockheight, bytes32 mmrRoot, uint256 timestamp);

    /// @notice Emitted when indexers update their indexing Status to ready
    event UpdateIndexingStatusToReady(address indexed indexer, bytes32 indexed deploymentId);

    /// @notice Emitted when indexers stop indexing
    event StopIndexing(address indexed indexer, bytes32 indexed deploymentId);

    /// @dev MODIFIER
    /// @notice only indexer can call
    modifier onlyIndexer() {
        require(IIndexerRegistry(settings.getIndexerRegistry()).isIndexer(msg.sender), 'G002');
        _;
    }

    /// @notice only creator can call if it is creatorRestricted
    modifier onlyCreator() {
        if (creatorRestricted) {
            require(creatorWhitelist[msg.sender], 'QR001');
        }
        _;
    }

    /**
     * @dev ### FUNCTIONS
     * @notice Initialize the contract
     * @param _settings ISettings contract
     */
    function initialize(ISettings _settings) external initializer {
        __Ownable_init();

        settings = _settings;
        offlineCalcThreshold = 1 days;
        creatorRestricted = true;
        creatorWhitelist[msg.sender] = true;
    }

    function setSettings(ISettings _settings) external onlyOwner {
        settings = _settings;
    }
    /**
     * @notice set the mode to restrict or not
     * restrict mode -- only permissioned accounts allowed to create query project
     */
    function setCreatorRestricted(bool _creatorRestricted) external onlyOwner {
        creatorRestricted = _creatorRestricted;
    }
    /**
     * @notice set account to creator account that allow to create query project
     */
    function addCreator(address creator) external onlyOwner {
        creatorWhitelist[creator] = true;
    }
    /**
     * @notice remove creator account
     */
    function removeCreator(address creator) external onlyOwner {
        creatorWhitelist[creator] = false;
    }
    /**
     * @notice set the threshold to calculate whether the indexer is offline
     */
    function setOfflineCalcThreshold(uint256 _offlineCalcThreshold) external onlyOwner {
        offlineCalcThreshold = _offlineCalcThreshold;
    }

    /**
     * @notice check if the IndexingStatus available to update ststus
     */
    function canModifyStatus(IndexingStatus memory currentStatus, uint256 _timestamp) private view {
        require(currentStatus.status != IndexingServiceStatus.NOTINDEXING, 'QR002');
        require(currentStatus.timestamp < _timestamp, 'QR003');
        require(_timestamp <= block.timestamp, 'QR004');
    }
    /**
     * @notice check if the IndexingStatus available to update BlockHeight
     */
    function canModifyBlockHeight(IndexingStatus memory currentStatus, uint256 blockheight) private pure {
        require(blockheight >= currentStatus.blockHeight, 'QR005');
    }

    /**
     * @notice create a QueryProject, if in the restrict mode, only creator allowed to call this function
     */
    function createQueryProject(bytes32 metadata, bytes32 version, bytes32 deploymentId) external onlyCreator {
        require(!deploymentIds[deploymentId], 'QR006');

        uint256 queryId = nextQueryId;
        queryInfos[queryId] = QueryInfo(queryId, msg.sender, version, deploymentId, metadata);
        nextQueryId++;
        deploymentIds[deploymentId] = true;

        emit CreateQuery(queryId, msg.sender, metadata, deploymentId, version);
    }

    /**
     * @notice update the Metadata of a QueryProject, if in the restrict mode, only creator allowed call this function
     */
    function updateQueryProjectMetadata(uint256 queryId, bytes32 metadata) external onlyCreator {
        address queryOwner = queryInfos[queryId].owner;
        require(queryOwner == msg.sender, 'QR007');

        queryInfos[queryId].metadata = metadata;

        emit UpdateQueryMetadata(queryOwner, queryId, metadata);
    }

    /**
     * @notice update the deployment of a QueryProject, if in the restrict mode, only creator allowed call this function
     */
    function updateDeployment(uint256 queryId, bytes32 deploymentId, bytes32 version) external onlyCreator {
        address queryOwner = queryInfos[queryId].owner;
        require(queryOwner == msg.sender, 'QR008');
        require(!deploymentIds[deploymentId], 'QR006');

        queryInfos[queryId].latestDeploymentId = deploymentId;
        queryInfos[queryId].latestVersion = version;
        deploymentIds[deploymentId] = true;

        emit UpdateQueryDeployment(queryOwner, queryId, deploymentId, version);
    }

    /**
     * @notice Indexer start indexing with a specific deploymentId
     */
    function startIndexing(bytes32 deploymentId) external onlyIndexer {
        IndexingServiceStatus currentStatus = deploymentStatusByIndexer[deploymentId][msg.sender].status;
        require(currentStatus == IndexingServiceStatus.NOTINDEXING, 'QR009');
        require(deploymentIds[deploymentId], 'QR006');

        deploymentStatusByIndexer[deploymentId][msg.sender] = IndexingStatus(
            deploymentId,
            0,
            0,
            IndexingServiceStatus.INDEXING
        );
        numberOfIndexingDeployments[msg.sender]++;

        emit StartIndexing(msg.sender, deploymentId);
    }

    /**
     * @notice Indexer update its indexing status to ready with a specific deploymentId
     */
    function updateIndexingStatusToReady(bytes32 deploymentId) external onlyIndexer {
        address indexer = msg.sender;
        uint256 timestamp = block.timestamp;

        IndexingStatus storage currentStatus = deploymentStatusByIndexer[deploymentId][indexer];
        canModifyStatus(currentStatus, timestamp);

        currentStatus.status = IndexingServiceStatus.READY;
        currentStatus.timestamp = timestamp;

        emit UpdateIndexingStatusToReady(indexer, deploymentId);
    }

    /**
     * @notice Indexer report its indexing status with a specific deploymentId
     */
    function reportIndexingStatus(address indexer, bytes32 deploymentId, uint256 blockheight, bytes32 mmrRoot, uint256 timestamp) external {
        require(indexer == msg.sender || IIndexerRegistry(settings.getIndexerRegistry()).getController(indexer) == msg.sender, 'IR007');

        IndexingStatus storage currentStatus = deploymentStatusByIndexer[deploymentId][indexer];
        canModifyStatus(currentStatus, timestamp);
        canModifyBlockHeight(currentStatus, blockheight);

        currentStatus.timestamp = timestamp;
        currentStatus.blockHeight = blockheight;

        emit UpdateDeploymentStatus(indexer, deploymentId, blockheight, mmrRoot, timestamp);
    }

    /**
     * @notice Indexer stop indexing with a specific deploymentId
     */
    function stopIndexing(bytes32 deploymentId) external onlyIndexer {
        IndexingServiceStatus currentStatus = deploymentStatusByIndexer[deploymentId][msg.sender].status;

        require(currentStatus != IndexingServiceStatus.NOTINDEXING, 'QR010');
        require(
            !IServiceAgreementRegistry(settings.getServiceAgreementRegistry()).hasOngoingClosedServiceAgreement(
                msg.sender,
                deploymentId
            ),
            'QR011'
        );

        deploymentStatusByIndexer[deploymentId][msg.sender].status = IndexingServiceStatus.NOTINDEXING;
        numberOfIndexingDeployments[msg.sender]--;
        emit StopIndexing(msg.sender, deploymentId);
    }

    /**
     * @notice is the indexer available to indexing with a specific deploymentId
     */
    function isIndexingAvailable(bytes32 deploymentId, address indexer) external view returns (bool) {
        return deploymentStatusByIndexer[deploymentId][indexer].status == IndexingServiceStatus.READY;
    }

    /**
     * @notice is the indexer offline on a specific deploymentId
     */
    function isOffline(bytes32 deploymentId, address indexer) external view returns (bool) {
        IndexingServiceStatus currentStatus = deploymentStatusByIndexer[deploymentId][indexer].status;
        if (currentStatus == IndexingServiceStatus.NOTINDEXING) {
            return false;
        }

        return deploymentStatusByIndexer[deploymentId][indexer].timestamp + offlineCalcThreshold < block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IIndexerRegistry {
    function isIndexer(address _address) external view returns (bool);

    function getController(address indexer) external view returns (address);

    function minimumStakingAmount() external view returns (uint256);

    function getCommissionRate(address indexer) external view returns (uint256);

    function setInitialCommissionRate(address indexer, uint256 rate) external;

    function setCommissionRate(uint256 rate) external;
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

/**
 * @dev Total staking amount information. One per Indexer.
 * Stake amount change need to be applied at next Era.
 */
struct StakingAmount {
    uint256 era;         // last update era
    uint256 valueAt;     // value at the era
    uint256 valueAfter;  // value to be refreshed from next era
}

/**
 * @dev Unbond amount information. One per request per Delegator.
 * Delegator can withdraw the unbond amount after the lockPeriod.
 */
struct UnbondAmount {
    address indexer;   // the indexer before delegate.
    uint256 amount;    // pending unbonding amount
    uint256 startTime; // unbond start time
}

enum UnbondType {
    Undelegation,
    Unstake,
    Commission,
    Merge
}

interface IStaking {
    function lockedAmount(address _delegator) external view returns (uint256);

    function unbondCommission(address _indexer, uint256 _amount) external;
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface ISettings {
    function setProjectAddresses(
        address _indexerRegistry,
        address _queryRegistry,
        address _eraManager,
        address _planManager,
        address _serviceAgreementRegistry,
        address _disputeManager,
        address _stateChannel
    ) external;

    function setTokenAddresses(
        address _sqToken,
        address _staking,
        address _stakingManager,
        address _rewardsDistributer,
        address _rewardsPool,
        address _rewardsStaking,
        address _rewardsHelper,
        address _inflationController,
        address _vesting,
        address _permissionedExchange
    ) external;

    function setSQToken(address _sqToken) external;

    function getSQToken() external view returns (address);

    function setStaking(address _staking) external;

    function getStaking() external view returns (address);

    function setStakingManager(address _stakingManager) external;

    function getStakingManager() external view returns (address);

    function setIndexerRegistry(address _indexerRegistry) external;

    function getIndexerRegistry() external view returns (address);

    function setQueryRegistry(address _queryRegistry) external;

    function getQueryRegistry() external view returns (address);

    function setEraManager(address _eraManager) external;

    function getEraManager() external view returns (address);

    function setPlanManager(address _planManager) external;

    function getPlanManager() external view returns (address);

    function setServiceAgreementRegistry(address _serviceAgreementRegistry) external;

    function getServiceAgreementRegistry() external view returns (address);

    function setRewardsDistributer(address _rewardsDistributer) external;

    function getRewardsDistributer() external view returns (address);

    function setRewardsPool(address _rewardsPool) external;

    function getRewardsPool() external view returns (address);

    function setRewardsStaking(address _rewardsStaking) external;

    function getRewardsStaking() external view returns (address);

    function setRewardsHelper(address _rewardsHelper) external;

    function getRewardsHelper() external view returns (address);

    function setInflationController(address _inflationController) external;

    function getInflationController() external view returns (address);

    function setVesting(address _vesting) external;

    function getVesting() external view returns (address);

    function setPermissionedExchange(address _permissionedExchange) external;

    function getPermissionedExchange() external view returns (address);

    function setDisputeManager(address _disputeManager) external;

    function getDisputeManager() external view returns (address);

    function setStateChannel(address _stateChannel) external;

    function getStateChannel() external view returns (address);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

enum IndexingServiceStatus {
    NOTINDEXING,
    INDEXING,
    READY
}

interface IQueryRegistry {

    function numberOfIndexingDeployments(address _address) external view returns (uint256);

    function isIndexingAvailable(bytes32 deploymentId, address indexer) external view returns (bool);

    function createQueryProject(
        bytes32 metadata,
        bytes32 version,
        bytes32 deploymentId
    ) external;

    function updateQueryProjectMetadata(uint256 queryId, bytes32 metadata) external;

    function updateDeployment(
        uint256 queryId,
        bytes32 deploymentId,
        bytes32 version
    ) external;

    function startIndexing(bytes32 deploymentId) external;

    function updateIndexingStatusToReady(bytes32 deploymentId) external;

    function reportIndexingStatus(
        address indexer,
        bytes32 deploymentId,
        uint256 _blockheight,
        bytes32 _mmrRoot,
        uint256 _timestamp
    ) external;

    function stopIndexing(bytes32 deploymentId) external;

    function isOffline(bytes32 deploymentId, address indexer) external view returns (bool);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

// -- Data --

/**
 * @dev closed service agreement information
 */
struct ClosedServiceAgreementInfo {
    address consumer;
    address indexer;
    bytes32 deploymentId;
    uint256 lockedAmount;
    uint256 startDate;
    uint256 period;
    uint256 planId;
    uint256 planTemplateId;
}

interface IServiceAgreementRegistry {
    function establishServiceAgreement(uint256 agreementId) external;

    function hasOngoingClosedServiceAgreement(address indexer, bytes32 deploymentId) external view returns (bool);

    function addUser(address consumer, address user) external;

    function removeUser(address consumer, address user) external;

    function getClosedServiceAgreement(uint256 agreementId) external view returns (ClosedServiceAgreementInfo memory);

    function nextServiceAgreementId() external view returns (uint256);

    function createClosedServiceAgreement(ClosedServiceAgreementInfo memory agreement) external returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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