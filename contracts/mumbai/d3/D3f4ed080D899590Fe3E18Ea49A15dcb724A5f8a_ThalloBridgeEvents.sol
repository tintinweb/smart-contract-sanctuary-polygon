//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ITCC.sol";
import "./interfaces/ITPR.sol";
import {ActionTypes, RegistryBlockType, RegistryBlock, RetirementBlock, CustodyBlock, BridgeEvent, EventEdit, TCCInfo} from "./ThalloStructs.sol";

/*
.___________..______    _______ 
|           ||   _  \  |   ____|
`---|  |----`|  |_)  | |  |__   
    |  |     |   _  <  |   __|  
    |  |     |  |_)  | |  |____ 
    |__|     |______/  |_______|
*/

/**
 *@title ThalloBridgeEvents
 *@notice Contract for issuing, retiring, uncustodying, and splitting tokenized carbon credit blocks
 */
contract ThalloBridgeEvents is UUPSUpgradeable, OwnableUpgradeable {
    address public thalloProofOfRetirement;
    address public thalloBridgeRegistry;
    /**
     *@notice bridgeEvents is meant to be a record per vintage of all the issuance, retirement, uncustody, 
        and splits of carbon credit blocks by Thallo
     *@dev The bytes32 key is the keccak256 of the projectId (uint24) and vintage (uint16)
    */
    mapping(bytes32 => uint256) public eventsLength;
    mapping(bytes32 => mapping(uint256 => BridgeEvent)) public bridgeEvents;

    ///@notice custodyBlocks is used to keep track of the "live" blocks currently backing the on chain credits
    mapping(bytes32 => uint256) public numCustodyBlocks;
    mapping(bytes32 => mapping(uint256 => CustodyBlock)) public custodyBlocks;

    ///@notice eventEdits tracks any edits made to the events. Used as an audit tool. Should be sparsely populated.
    mapping(bytes32 => EventEdit[]) public eventEdits;

    ///@notice Tracks tccAddress, issuance, retirement, and uncustody amounts for each vintage
    mapping(bytes32 => TCCInfo) public tccInfo;

    ///@notice Custodians are trusted addresses to interact with the bridge
    mapping(address => bool) public custodians;

    ///@dev Enforces idempotency for token issuance
    mapping(uint256 => bool) public requestIdProcessed;

    event TokensIssued(
        address indexed tcc,
        address indexed to,
        uint256 quantity,
        uint256 eventIndex,
        uint256 custodyIndex
    );
    event TokensRetired(
        address indexed tcc,
        address indexed to,
        uint256 quantity,
        uint256 eventIndex,
        uint256 indexed retirementId
    );
    event TokensUncustodied(address indexed tcc, address indexed requestor, uint256 quantity, uint256 eventIndex);
    event ReturnUncustody(address indexed tcc, address indexed requestor);
    event EventEdited(
        uint24 indexed projectId,
        uint16 vintage,
        uint256 eventIndex,
        EventEdit edit,
        uint256[] custodyIndices
    );
    event CustodianAdded(address indexed custodian);
    event CustodianRemoved(address indexed who);
    event BlockSplit(uint24 indexed projectId, uint16 vintage, uint256 sourceCustodyIndex, uint256 eventIndex);

    /**
     *@dev This prevents initialization on the implementation contract itself.
     *If left uninitialized, the implementation contract could be initialized by anyone.
     */
    ///@custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) external initializer {
        __Ownable_init();
        transferOwnership(_owner);
        custodians[_owner] = true;
    }

    //solhint-disable-next-line
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlyCustodian() {
        require(custodians[msg.sender], "TBE:NC");
        _;
    }

    function addCustodian(address _who) external onlyOwner {
        custodians[_who] = true;
        emit CustodianAdded(_who);
    }

    function removeCustodian(address _who) external onlyOwner {
        custodians[_who] = false;
        emit CustodianRemoved(_who);
    }

    /**
     *@notice Sets the external addresses for the registry and proof of retirement contracts
     *@dev Currently can be called more than one time exclusively by the owner, but ideally should be set only once
     */
    function setExternals(address _registry, address _proofOfRetirement) external onlyOwner {
        thalloBridgeRegistry = _registry;
        thalloProofOfRetirement = _proofOfRetirement;
    }

    /**
     *@notice Mints tokens for a project vintage on-chain to a Thallo Custodian address
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@param _registryBlock The issuance block for the vintage. See ThalloStructs.sol for details.
     *@param _to The address to mint tokens to
     *@param _memo Any notes about the issuance event relevant to store on chain. Should be very short.
     *@param _requestId Enforces idempotency to avoid duplicate token issuance.
     */
    function issueVintageTokens(
        uint24 _projectId,
        uint16 _vintage,
        RegistryBlock calldata _registryBlock,
        address _to,
        string calldata _memo,
        uint256 _requestId
    ) external onlyCustodian {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        address tccAddress = tccInfo[vintageKey].tccAddress;
        require(!requestIdProcessed[_requestId], "TBE:IVT:RI");
        require(tccAddress != address(0), "TBE:IVT:TCC DNE");
        require(_registryBlock.blockType == RegistryBlockType.CUSTODIED, "TBE:IVT:NCB");
        tccInfo[vintageKey].totalIssuance += _registryBlock.quantity;
        //slither-disable-next-line reentrancy-no-eth
        ITCC(tccAddress).issueTokens(_to, _registryBlock.quantity);

        uint256 numEvents = ++eventsLength[vintageKey];

        BridgeEvent storage custody = bridgeEvents[vintageKey][numEvents];
        custody.actionType = ActionTypes.CUSTODY;
        custody.finalized = true;
        custody.registryBlocks.push(_registryBlock);
        custody.timestamp = block.timestamp;
        custody.memo = _memo;
        uint256 custodyIndex = ++numCustodyBlocks[vintageKey];
        custodyBlocks[vintageKey][custodyIndex] = CustodyBlock(
            _registryBlock.serialNumber,
            _registryBlock.quantity,
            true
        );
        requestIdProcessed[_requestId] = true;
        emit TokensIssued(tccAddress, _to, _registryBlock.quantity, numEvents, custodyIndex);
    }

    /**
     *@notice Retire vintage token on-chain and mint a proof of retirement NFT
     *@param _projectId The id of the project
     *@param _registry The registry the project and vintage credits is custodied on
     *@param _vintage The vintage year of the credits
     *@param _quantity The number of tokens to retire
     *@param _to The address to mint the proof of retirement NFT to
     *@dev This function is called from the associated TCC contract for a specific project/vintage
     */
    function retireVintageTokens(
        uint24 _projectId,
        uint16 _registry,
        uint16 _vintage,
        uint256 _quantity,
        address _to
    ) external {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        address tccAddress = tccInfo[vintageKey].tccAddress;
        require(msg.sender == tccAddress, "TBE:RVT:TCC");

        //slither-disable-next-line reentrancy-no-eth
        uint256 retirementId = ITPR(thalloProofOfRetirement).mintProof(
            _projectId,
            _registry,
            _vintage,
            tccAddress,
            _to
        );

        uint256 numEvents = ++eventsLength[vintageKey];

        BridgeEvent storage retirement = bridgeEvents[vintageKey][numEvents];
        retirement.actionType = ActionTypes.RETIREMENT;
        retirement.timestamp = block.timestamp;
        tccInfo[vintageKey].totalRetirement += _quantity;
        emit TokensRetired(tccAddress, _to, _quantity, numEvents, retirementId);
    }

    /**
     *@notice Finalize the proof of retirement NFT and bridge event with registry information
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@param _eventIndex The index of the retirement event in the bridgeEvents array. This is emitted in the retireVintageTokens function as numEvents.
     *@param _registryBlocks Array of registry blocks associated with the retirement event. See ThalloStructs.sol for details.
     *@param _retirementBlocks Array of retirement blocks associated with the retirement event. See ThalloStructs.sol for details.
     *@param _custodyIndices The indices of the custody blocks in custodyBlocks associated with the retirement event.
     *@param _custodyBlocks Array of custody blocks associated with the retirement event. See ThalloStructs.sol for details.
     *@param _memo Any notes about the retirement event relevant to store on chain. Should be very short.
     *@param _tokenId The ID of the proof of retirement NFT to update.
     *@param _tokenURI The URI for the proof of retirment. Links to branding/artwork/metadata for the NFT.
     *@dev If a custody block is fully retired, the quantity will be 0 and the active flag will be false. Passed in the params.
     */
    function finalizeRetirement(
        uint24 _projectId,
        uint16 _vintage,
        uint256 _eventIndex,
        RegistryBlock[] calldata _registryBlocks,
        RetirementBlock[] calldata _retirementBlocks,
        uint256[] memory _custodyIndices,
        CustodyBlock[] memory _custodyBlocks,
        string memory _memo,
        uint256 _tokenId,
        string memory _tokenURI
    ) external onlyCustodian {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        require(!bridgeEvents[vintageKey][_eventIndex].finalized, "TBE:FR:F");
        //slither-disable-next-line reentrancy-no-eth
        ITPR(thalloProofOfRetirement).issueFinalProof(_tokenId, _retirementBlocks, _tokenURI);
        BridgeEvent storage retirement = bridgeEvents[vintageKey][_eventIndex];
        retirement.finalized = true;

        //This will almost always be of length 2, and very rarely of length 4,6,8,etc. when retiring from multiple blocks in the edge case
        for (uint256 i = 0; i < _registryBlocks.length; i++) {
            retirement.registryBlocks.push(_registryBlocks[i]);
        }

        //Very likely to be of length 1, could be 2. If the block is fully retired, we still pass a custody block with a quantity of 0
        //and an active flag of false
        for (uint256 i = 0; i < _custodyIndices.length; i++) {
            custodyBlocks[vintageKey][_custodyIndices[i]] = _custodyBlocks[i];
        }

        retirement.memo = _memo;
    }

    /**
     *@notice Supports arbitrary split of a registry block into multiple custody blocks
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@param _registryBlocks The registry blocks after the split has been performed on the registry
     *@param _sourceCustodyIndex The index of the custody block in custodyBlocks that is being split
     *@param _splitMemo Any notes about the split event relevant to store on chain. Should be very short.
     *@dev The first registry block (index 0) will maintain the current index of the custody block.
     */
    function splitBlock(
        uint24 _projectId,
        uint16 _vintage,
        RegistryBlock[] calldata _registryBlocks,
        uint256 _sourceCustodyIndex,
        string calldata _splitMemo
    ) external onlyCustodian {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        eventsLength[vintageKey]++;
        BridgeEvent storage split = bridgeEvents[vintageKey][eventsLength[vintageKey]];
        split.actionType = ActionTypes.SPLIT;
        split.finalized = true;
        split.timestamp = block.timestamp;
        split.memo = _splitMemo;

        custodyBlocks[vintageKey][_sourceCustodyIndex] = CustodyBlock(
            _registryBlocks[0].serialNumber,
            _registryBlocks[0].quantity,
            true
        );
        split.registryBlocks.push(_registryBlocks[0]);

        //for an arb split, the number of live blocks should increase by the length of the registry blocks - 1
        for (uint256 i = 1; i < _registryBlocks.length; i++) {
            uint256 custodyIndex = ++numCustodyBlocks[vintageKey];
            custodyBlocks[vintageKey][custodyIndex] = CustodyBlock(
                _registryBlocks[i].serialNumber,
                _registryBlocks[i].quantity,
                true
            );
            split.registryBlocks.push(_registryBlocks[i]);
        }
        emit BlockSplit(_projectId, _vintage, _sourceCustodyIndex, eventsLength[vintageKey]);
    }

    /**
     *@notice Finalizes the uncustody request of tokens
     *@param _projectId  The id of the project
     *@param _vintage The vintage year
     *@param _requestor The address of the account that originally requested the uncustody
     *@param _quantity The quantity of tokens to uncustody
     *@param _registryBlocks The new reflected registry blocks on the underlying registry
     *@param _custodyIndices The indices of the custody blocks in custodyBlocks associated with the uncustody event.
     *@param _custodyBlocks The custody blocks now reflecting the backed tokens on the blockchain
     *@param _uncustodyMemo The memo for the uncustody event. Should be very short.
     *@dev Calls the corresponding TCC contract to burn the tokens requested to be uncustodied
     */
    function finalizeUncustody(
        uint24 _projectId,
        uint16 _vintage,
        address _requestor,
        uint256 _quantity,
        RegistryBlock[] calldata _registryBlocks,
        uint256[] calldata _custodyIndices,
        CustodyBlock[] calldata _custodyBlocks,
        string memory _uncustodyMemo
    ) external onlyCustodian {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));

        uint256 numEvents = ++eventsLength[vintageKey];
        BridgeEvent storage uncustody = bridgeEvents[vintageKey][numEvents];
        uncustody.actionType = ActionTypes.UNCUSTODY;
        uncustody.finalized = true;
        uncustody.timestamp = block.timestamp;
        uncustody.memo = _uncustodyMemo;
        //Very likely to be of length 2 --- the edited active custody block and the block of uncustodied credits
        for (uint256 i = 0; i < _registryBlocks.length; i++) {
            uncustody.registryBlocks.push(_registryBlocks[i]);
        }
        //Very likely to be of length 1, could be 2
        for (uint256 i = 0; i < _custodyIndices.length; i++) {
            custodyBlocks[vintageKey][_custodyIndices[i]] = _custodyBlocks[i];
        }
        address tccAddress = tccInfo[vintageKey].tccAddress;
        //slither-disable-next-line reentrancy-no-eth
        ITCC(tccAddress).finalizeUncustody(_requestor, _quantity);
        tccInfo[vintageKey].totalUncustody += _quantity;
        emit TokensUncustodied(tccAddress, _requestor, _quantity, numEvents);
    }

    /**
     *@notice Returns carbon credits on chain to the requesting party
     *@dev This function will be called when the requesting address does not have an external registry account
     */
    function returnUncustody(address _tcc, address _requestor) external onlyCustodian {
        ITCC(_tcc).returnUncustody(_requestor);
        emit ReturnUncustody(_tcc, _requestor);
    }

    /**
     *@notice Edits any event data and custody blocks
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@param _index The index of the event to edit
     *@param _custodyIndices The indices of the custody blocks to edit
     *@param _custodyBlocks The custody blocks to edit
     *@param _editMemo A short memo outlining the reason for the edit
     *@param _editedEvent The event block data for the edited event
     *@dev Should only be used in case of mistake or emergency when data was passed inaccurately
     */
    function editEvent(
        uint24 _projectId,
        uint16 _vintage,
        uint256 _index,
        uint256[] calldata _custodyIndices,
        CustodyBlock[] calldata _custodyBlocks,
        string memory _editMemo,
        BridgeEvent calldata _editedEvent
    ) external onlyCustodian {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        bridgeEvents[vintageKey][_index] = _editedEvent;
        EventEdit memory newEdit = EventEdit(_index, block.timestamp, _editMemo);
        eventEdits[vintageKey].push(newEdit);
        for (uint256 i = 0; i < _custodyIndices.length; i++) {
            custodyBlocks[vintageKey][_custodyIndices[i]] = _custodyBlocks[i];
        }
        emit EventEdited(_projectId, _vintage, _index, newEdit, _custodyIndices);
    }

    /**
     *@notice Sets the metadata for a vintage
     *@param _vintageKey 32 byte hash of the projectId and vintage year
     *@param _metadata The metadata for the vintage -- points to ipfs or s3
     */
    function setVintageMetadata(bytes32 _vintageKey, string calldata _metadata) external {
        require(msg.sender == thalloBridgeRegistry || custodians[msg.sender], "TBE:SVM:TBR||CUST");
        tccInfo[_vintageKey].metadata = _metadata;
    }

    /**
     *@notice Registers a TCC vintage contract address
     *@param _vintageKey 32 byte hash of the projectId and vintage year
     *@param _tccAddress The TCC contract address
     *@dev Can only be called by the registry upon the deployment of a new TCC vintage contract
     */
    function setVintageAddress(bytes32 _vintageKey, address _tccAddress) external {
        require(msg.sender == thalloBridgeRegistry, "TBE:SVA:TBR");
        tccInfo[_vintageKey].tccAddress = _tccAddress;
    }

    function getVintageAddress(bytes32 _vintageKey) external view returns (address) {
        return tccInfo[_vintageKey].tccAddress;
    }

    function getBridgeEvent(bytes32 _vintageKey, uint256 _index) external view returns (BridgeEvent memory) {
        return bridgeEvents[_vintageKey][_index];
    }

    /**
     *@notice Provides a trace of all events, edits, and active custody blocks for a vintage under a project
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@return BridgeEvent[] The sequential list of events for the vintage
     *@return EventEdit[] The sequential list of edits made to the events
     *@return CustodyBlock[] The sequential list of custody blocks for the vintage
     *@return bool A boolean indicating whether the total token supply for the vintage matches both the total custody block quantity
     and the tracked total issuance, retirement, and uncustody quantities 
     */
    function audit(uint24 _projectId, uint16 _vintage)
        external
        view
        returns (
            BridgeEvent[] memory,
            EventEdit[] memory,
            CustodyBlock[] memory,
            bool
        )
    {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        uint256 length = eventsLength[vintageKey];
        BridgeEvent[] memory events = new BridgeEvent[](length);
        for (uint256 i = 0; i < length; i++) {
            events[i] = bridgeEvents[vintageKey][i + 1];
        }
        EventEdit[] memory edits = eventEdits[vintageKey];
        uint256 tokenSupply = ITCC(tccInfo[vintageKey].tccAddress).totalSupply();
        bool tokenIntegrityOne = tokenSupply ==
            tccInfo[vintageKey].totalIssuance -
                tccInfo[vintageKey].totalRetirement -
                tccInfo[vintageKey].totalUncustody;

        uint256 custodyBlocksLen = numCustodyBlocks[vintageKey];
        uint256 totalCustodyTokens = 0;
        CustodyBlock[] memory cBlocks = new CustodyBlock[](custodyBlocksLen);
        for (uint256 i = 1; i <= custodyBlocksLen; i++) {
            if (custodyBlocks[vintageKey][i].active) {
                totalCustodyTokens += custodyBlocks[vintageKey][i].quantity;
                cBlocks[i - 1] = custodyBlocks[vintageKey][i];
            }
        }

        bool tokenIntegrityTwo = totalCustodyTokens == tokenSupply;

        return (events, edits, cBlocks, tokenIntegrityOne && tokenIntegrityTwo);
    }

    /**
     *@notice Returns bridge events from _start to _end for a given project and vintage
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@param _start The index of the first event to return
     *@param _end One more than the index of the last event to return (non-inclusive)
     *@return BridgeEvent[] The sequential list of events for the vintage
     */
    function paginateBridgeEvents(
        uint24 _projectId,
        uint16 _vintage,
        uint256 _start,
        uint256 _end
    ) external view returns (BridgeEvent[] memory) {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        BridgeEvent[] memory events = new BridgeEvent[](_end - _start);
        for (uint256 i = 0; i < _end - _start; i++) {
            events[i] = bridgeEvents[vintageKey][i + _start];
        }
        return events;
    }

    /**
     *@notice Returns event edits from _start to _end for a given project and vintage
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@param _start The index of the first edit to return
     *@param _end One more than the index of the last edit to return (non-inclusive)
     *@return EventEdit[] The sequential list of edits for the vintage
     */
    function paginateEditEvents(
        uint24 _projectId,
        uint16 _vintage,
        uint256 _start,
        uint256 _end
    ) external view returns (EventEdit[] memory) {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        EventEdit[] memory edits = new EventEdit[](_end - _start);
        for (uint256 i = 0; i < _end - _start; i++) {
            edits[i] = eventEdits[vintageKey][i + _start];
        }
        return edits;
    }

    /**
     *@notice Returns custody blocks from _start to _end for a given project and vintage
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@param _start The index of the first custody block to return
     *@param _end One more than the index of the last custody block to return (non-inclusive)
     *@return CustodyBlock[] The sequential list of custody blocks for the vintage
     */
    function paginateCustodyBlocks(
        uint24 _projectId,
        uint16 _vintage,
        uint256 _start,
        uint256 _end
    ) external view returns (CustodyBlock[] memory) {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        CustodyBlock[] memory cBlocks = new CustodyBlock[](_end - _start);
        for (uint256 i = 0; i <= _end - _start; i++) {
            CustodyBlock memory cBlock = custodyBlocks[vintageKey][i + _start];
            if (cBlock.active) {
                cBlocks[i] = cBlock;
            }
        }
        return cBlocks;
    }

    /**
     *@notice Checks the outstanding token supply versus tracked bridge events
     *@param _projectId The id of the project
     *@param _vintage The vintage year
     *@return bool A boolean indicating whether the total token supply for the vintage matches both the total custody block quantity
       and the tracked total issuance, retirement, and uncustody quantities 
     */
    function tokenIntegrity(uint24 _projectId, uint16 _vintage) external view returns (bool) {
        bytes32 vintageKey = keccak256(abi.encodePacked(_projectId, _vintage));
        uint256 tokenSupply = ITCC(tccInfo[vintageKey].tccAddress).totalSupply();
        bool tokenIntegrityOne = tokenSupply ==
            tccInfo[vintageKey].totalIssuance -
                tccInfo[vintageKey].totalRetirement -
                tccInfo[vintageKey].totalUncustody;

        uint256 custodyBlocksLen = numCustodyBlocks[vintageKey];
        uint256 totalCustodyTokens = 0;

        for (uint256 i = 1; i <= custodyBlocksLen; i++) {
            if (custodyBlocks[vintageKey][i].active) {
                totalCustodyTokens += custodyBlocks[vintageKey][i].quantity;
            }
        }

        bool tokenIntegrityTwo = totalCustodyTokens == tokenSupply;

        return tokenIntegrityOne && tokenIntegrityTwo;
    }

    function version() external pure returns (string memory) {
        return "v1";
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface ITCC {
    function issueTokens(address _to, uint256 _quantity) external;

    function finalizeUncustody(address _requestor, uint256 _quantity) external;

    function returnUncustody(address _requestor) external;

    function totalSupply() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import {RetirementBlock} from "../ThalloStructs.sol";

interface ITPR {
    function mintProof(
        uint24 _projectId,
        uint16 _registry,
        uint16 _vintage,
        address _tccAddress,
        address _to
    ) external returns (uint256);

    function issueFinalProof(
        uint256 _tokenId,
        RetirementBlock[] calldata _retirementBlocks,
        string calldata _tokenURI
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

/**
 *@notice Denotes the action type for an event on the Thallo bridge
 *@notice Supports custodying credits, retiring credits, uncustodying credits, and arbitrary splits of carbon credit blocks
 */
enum ActionTypes {
    CUSTODY,
    RETIREMENT,
    UNCUSTODY,
    SPLIT
}

/**
 *@notice Denotes the type of a carbon credit block on the registry in relation to Thallo
 */
enum RegistryBlockType {
    CUSTODIED,
    RETIRED,
    UNCUSTODIED
}

/**
 *@notice Struct that stores data for a carbon restoration or removal project
 *@member id The id of the project. This is set automatically when the project is created
 *@member sdgs The SDGs of the project. Stored as a bitmap
 *@member projectType The type of project. Stored as a number that maps to the type. (Biogas, Energy Efficiency, Clean Water Access, etc.)
 *@member location The location of the project. Numerical representing the country in alphabetical order
 *@member registryProjectId Registry the carbon credits are custodied on. Number maps to a registry. (Gold Standard, Verra, etc.)
 *@member name Name of the project
 *@member url The URL that links to the details on of the project on the registry
 *@member metadata Any additional metadata about the project
 */
struct Project {
    uint24 id;
    uint128 sdgs;
    uint8 projectType;
    uint8 location;
    uint16 registry;
    string registryProjectId;
    string name;
    string url;
    string metadata;
}

/**
 *@notice Struct that stores details about a specific carbon credit block on the registry
 *@member blockType The type of the block. CUSTODIED, RETIRED, or UNCUSTODIED
 *@member sourceSerialNumber The previous serial number this block was derived from. If this is an issuance block, this will be blank
 *@member serialNumber The registry serial number of the carbon credit block
 *@member quantity The amount of carbon credits in this block
 *@member retirementProofId The id of any associated proof of retirement NFT. If there is no associated NFT, the id will be 0
 *@dev quantity will always be a whole number (quantity >= 1e18 && quantity % 1e18 == 0)
 */
struct RegistryBlock {
    RegistryBlockType blockType;
    string sourceSerialNumber;
    string serialNumber;
    uint256 quantity;
    uint256 retirementProofId;
}

/**
 *@notice Struct that stores data representing an event on the Thallo bridge
 *@member actionType The type of action for the event. CUSTODY, RETIREMENT, UNCUSTODY, or SPLIT
 *@member finalized Represents whether the event has been finalized or not. Non-finalized events like uncustody or retirement
  are pending finalization with registry serial numbers. Any finalized event that needs to be altered will require an edit event.
 *@member registryBlocks The registry blocks resulting from the event
 *@member timestamp The on-chain timestamp of when the event occurred
 *@member memo An optional short description or notes of the event
 */
struct BridgeEvent {
    ActionTypes actionType;
    bool finalized;
    RegistryBlock[] registryBlocks;
    uint256 timestamp;
    string memo;
}

/**
 *@notice Struct that stores data representing any edits made to a project vintage's events
 *@member eventIndex The array index of the event that was edited
 *@member timestamp The timestamp of when the edit occurred
 *@member memo An optional short description or notes of why the edit was necessary
 */
struct EventEdit {
    uint256 eventIndex;
    uint256 timestamp;
    string memo;
}

/**
 *@notice Struct that stores data about a custodied block on the registry
 *@member serialNumber The registry serial number of the carbon credit block
 *@member quantity The amount of carbon credits in this block
 *@member active Whether the block is still actively custodied or not
 *@dev This is a data structure used to help keep track of the "active state" of a vintage of on-chain carbon credits.
 The sum of the quantities of the active CustodyBlocks should be equal to the total supply of the on-chain TCC tokens for a specific vintage.
 */
struct CustodyBlock {
    string serialNumber;
    uint256 quantity;
    bool active;
}

/**
 *@notice A struct that stores data about a retirement block on the registry
 *@member serialNumber The registry serial number of the carbon credit block
 *@member quantity The amount of carbon credits in this block
 */
struct RetirementBlock {
    string serialNumber;
    uint256 quantity;
}

/**
 *@notice Struct that stores data for the Proof of Retirement NFT
 *@member registry The registry the carbon credits were retired on
 *@member projectId The id of the project the carbon credits were issued under
 *@member vintage The vintage of the carbon credits
 *@member tccAddress The address of the associated on chain TCC contract
 *@member retirementBlocks Registry data of blocks of carbon credits that were retired
 *@member tokenURI The URI linking to any extra data of retirement. Artwork, branding, etc.
 */
struct ProofOfRetirementData {
    uint16 registry;
    uint24 projectId;
    uint16 vintage;
    bool locked;
    address tccAddress;
    RetirementBlock[] retirementBlocks;
    string tokenURI;
}

/**
 *@notice Struct that stores data about each Thallo Carbon Credit (TCC)
 *@member address The address of the TCC contract
 *@member totalIssuance The total amount of carbon credits issued (minted) on chain
 *member totalRetirement The total amount of carbon credits retired (burned) on chain
 *member totalUncustody The total amount of carbon credits uncustodied (burned) on chain
 *@dev totalSupply should equal totalIssuance - totalRetirement - totalUncustody
 */
struct TCCInfo {
    address tccAddress;
    uint256 totalIssuance;
    uint256 totalRetirement;
    uint256 totalUncustody;
    string metadata;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
                version == 1 && !AddressUpgradeable.isContract(address(this)),
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