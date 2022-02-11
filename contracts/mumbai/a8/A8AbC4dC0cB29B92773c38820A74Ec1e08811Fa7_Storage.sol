// SPDX-License-Identifier: BUSL-1.1
// License details specified at address returned by calling the function: license()
pragma solidity =0.8.11;

/**
 @title Main Storage of the Living Assets Platform
 @author Freeverse.io, www.freeverse.io
 @dev Responsible for all storage, including upgrade of addresses
 @dev to external contracts that manage updates/challenges 
*/

import "../interfaces/IStorage.sol";
import "../storage/RolesSetters.sol";

contract Storage is IStorage, RolesSetters {
    constructor(address company, address superUser) {
        _license = "ipfs://QmSiTS1wfYqwjoU8coz6U327AEsJ6iSVSccUdz7MJapA7C";

        // Setup main roles:
        _company = company;
        _superUser = superUser;

        // Setup main global variables:
        _nLevelsPerChallengeNextVerses = 4;
        _maxTimeWithoutVerseProduction = 604800; // 1 week

        // Setup TXBatchReference variables:
        _referenceVerse = 1;
        _verseInterval = 15 * 60;
        _referenceTime =
            block.timestamp +
            _verseInterval -
            (block.timestamp % _verseInterval);

        // Initialize with null TXBatch and null Ownership Root
        _txBatches.push(TXBatch(bytes32(0x0), 0, 0, 3, 4, 0));
        _ownerships.push(Ownership(bytes32(0x0), 1));
        _challenges.push(
            Challenge(bytes32(0x0), bytes32(0x0), bytes32(0x0), 0)
        );
    }

    /**
     * @notice Sets further details of the code license
     * @param newPath The new path where details can be obtained
     */
    function setLicense(string memory newPath) external onlySuperUser {
        _license = newPath;
        emit NewLicense(newPath);
    }

    /**
     * @notice Sets max time period for new verse production.
     * Beyond this deadline several functions can be activated.
     * @param time The time period
     */
    function setTimeWithoutVerseProduction(uint256 time)
        external
        onlySuperUser
    {
        require(
            time < 2592000,
            "setTimeWithoutVerseProduction: cannot set a time larger than 1 month"
        );
        _maxTimeWithoutVerseProduction = time;
        emit TimeWithoutVerseProduction(time);
    }

    /**
     * @notice Sets default num of levels per challenge to be used for new verses
     * @param value The value for num of levels
     */
    function setLevelsPerChallengeNextVerses(uint8 value)
        external
        onlySuperUser
    {
        _nLevelsPerChallengeNextVerses = value;
        emit LevelsPerChallengeNextVerses(value);
    }

    /**
     * @notice Sets the default challenge window, in secs, that affects new verses
     * @param newTime The new default time
     */
    function setChallengeWindowNextVerses(uint256 newTime)
        external
        onlySuperUser
    {
        _challengeWindowNextVerses = newTime;
        emit ChallengeWindow(newTime);
    }

    /**
     * @notice Sets the reference values used to compute the expected time
     * of production for new TX verses
     * @param refVerse The reference verse
     * @param refTime The timestamp of the reference verse
     * @param vInterval The seconds between txVerses
     */
    function setTXBatchReference(
        uint256 refVerse,
        uint256 refTime,
        uint256 vInterval
    ) external onlySuperUser {
        _referenceVerse = refVerse;
        _verseInterval = vInterval;
        _referenceTime = refTime;
        emit TXBatchReference(refVerse, refTime, vInterval);
    }

    /**
     * @notice Creates a new universe controlled by owner
     * @param universeIdx The idx of the Universe, forced to be provided
     * as input as a redundancy check and to avoid replay-attacks.
     * @param owner The address of the owner of the universe
     * @param authorizesRelay Whether owner of the universe authorizes the default relayer
     * @param name The name of the universe
     */
    function createUniverse(
        uint256 universeIdx,
        address owner,
        bool authorizesRelay,
        string calldata name
    ) external onlySuperUser {
        require(
            nUniverses() == universeIdx,
            "createUniverse: universeIdx does not equal nUniverses"
        );

        // Prepare init arrays
        bytes32[] memory initRootArray = new bytes32[](1);
        initRootArray[0] = bytes32(0);
        uint256[] memory initRootTimeStamp = new uint256[](1);
        initRootTimeStamp[0] = block.timestamp;

        // Create and emit event
        _universes.push(
            Universe(
                owner,
                name,
                authorizesRelay,
                initRootArray,
                initRootTimeStamp,
                false,
                false
            )
        );
        emit CreateUniverse(universeIdx, owner, name, authorizesRelay);
    }

    /// @inheritdoc IStorage
    function changeUniverseClosure(
        uint256 universeIdx,
        bool closureRequested,
        bool closureConfirmed
    ) external onlyWriterContract {
        _universes[universeIdx].closureRequested = closureRequested;
        _universes[universeIdx].closureConfirmed = closureConfirmed;
        emit UniverseClosure(universeIdx, closureRequested, closureConfirmed);
    }

    /**
     * @notice Changes name of a universe
     * @param universeIdx The idx of the Universe
     * @param name The new name of the Universe
     */
    function changeUniverseName(uint256 universeIdx, string calldata name)
        external
        onlySuperUser
    {
        require(universeIdx < nUniverses(), "universeIdx does not exist");
        _universes[universeIdx].name = name;
        emit UniverseName(universeIdx, name);
    }

    /**
     * @notice Sets whether owner of a universe authorizes the default relayer
     * @param universeIdx The idx of the Universe
     * @param authorizesRelay Whether owner of the universe authorizes the default relayer
     */
    function setUniverseAuthorizesRelay(
        uint256 universeIdx,
        bool authorizesRelay
    ) external onlySuperUser {
        require(universeIdx < nUniverses(), "universeIdx does not exist");
        require(
            authorizesRelay != _universes[universeIdx].authorizesRelay,
            "universe auth relay value already as provided"
        );
        _universes[universeIdx].authorizesRelay = authorizesRelay;
        emit UniverseAuthorizesRelay(universeIdx, authorizesRelay);
    }

    /// @inheritdoc IStorage
    function pushUniverseRoot(
        uint256 universeIdx,
        bytes32 newRoot,
        uint256 submissionTime
    ) external onlyWriterContract returns (uint256 verse) {
        _universes[universeIdx].roots.push(newRoot);
        _universes[universeIdx].rootsSubmissionTimes.push(submissionTime);
        return _universes[universeIdx].roots.length - 1;
    }

    /// @inheritdoc IStorage
    function setLastOwnershipRoot(bytes32 newRoot) external onlyWriterContract {
        _ownerships[_ownerships.length - 1].root = newRoot;
    }

    /// @inheritdoc IStorage
    function setLastOwnershipSubmissionTime(uint256 newTime)
        external
        onlyWriterContract
    {
        _ownerships[_ownerships.length - 1].submissionTime = newTime;
    }

    /// @inheritdoc IStorage
    function deleteChallenges() external onlyWriterContract {
        delete _challenges;
    }

    /// @inheritdoc IStorage
    function pushTXRoot(
        bytes32 newTXsRoot,
        uint256 submissionTime,
        uint256 nTXs,
        uint8 levelVeriableByBC
    ) external onlyWriterContract returns (uint256 txVerse) {
        _txBatches.push(
            TXBatch(
                newTXsRoot,
                submissionTime,
                nTXs,
                levelVeriableByBC,
                _nLevelsPerChallengeNextVerses,
                _challengeWindowNextVerses
            )
        );
        return _txBatches.length - 1;
    }

    /// @inheritdoc IStorage
    function pushOwnershipRoot(bytes32 newOwnershipRoot, uint256 submissionTime)
        external
        onlyWriterContract
        returns (uint256 ownVerse)
    {
        _ownerships.push(Ownership(newOwnershipRoot, submissionTime));
        return _ownerships.length - 1;
    }

    /// @inheritdoc IStorage
    function pushChallenge(
        bytes32 ownershipRoot,
        bytes32 transitionsRoot,
        bytes32 rootAtEdge,
        uint256 pos
    ) external onlyWriterContract {
        _challenges.push(
            Challenge(ownershipRoot, transitionsRoot, rootAtEdge, pos)
        );
    }

    /// @inheritdoc IStorage
    function popUniverseRoot(uint256 universeId)
        external
        onlyWriterContract
        returns (uint256 verse)
    {
        _universes[universeId].roots.pop();
        _universes[universeId].rootsSubmissionTimes.pop();
        return _universes[universeId].roots.length - 1;
    }

    /// @inheritdoc IStorage
    function popChallenge() external onlyWriterContract {
        _challenges.pop();
    }

    /// @inheritdoc IStorage
    function setExportInfo(
        uint256 assetId,
        address owner,
        uint256 requestVerse,
        uint256 completedVerse
    ) external onlyAssetExporterContract {
        _exportInfo[assetId] = ExportInfo(owner, requestVerse, completedVerse);
    }

    /**
     * @notice Pushes an entry at the end of the claims array
     */
    function addClaim() external onlySuperUser {
        _claims.push();
    }

    /// @inheritdoc IStorage
    function setClaim(
        uint256 claimIdx,
        uint256 key,
        uint256 verse,
        string memory value
    ) external onlyWriterContract {
        Claim memory c = Claim(verse, value);
        _claims[claimIdx][key] = c;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.11;

/**
 @title Getters for storage data
 @author Freeverse.io, www.freeverse.io
 @dev Main storage getters
*/

import "../storage/StorageBase.sol";
import "../interfaces/IStorageGetters.sol";

contract StorageGetters is IStorageGetters, StorageBase {
    modifier onlyCompany() {
        require(msg.sender == _company, "Only company is authorized.");
        _;
    }

    modifier onlySuperUser() {
        require(msg.sender == _superUser, "Only superUser is authorized.");
        _;
    }

    modifier onlyUniversesRelayer() {
        require(
            msg.sender == _universesRelayer,
            "Only relayer of universes is authorized."
        );
        _;
    }

    modifier onlyTXRelayer() {
        require(msg.sender == _txRelayer, "Only relayer of TXs is authorized.");
        _;
    }

    modifier onlyWriterContract() {
        require(msg.sender == _writer, "Only updates contract is authorized.");
        _;
    }

    modifier onlyAssetExporterContract() {
        require(
            msg.sender == _assetExporter,
            "Only assetExporter contract is authorized."
        );
        _;
    }

    /// @inheritdoc IStorageGetters
    function license() external view returns (string memory) {
        return _license;
    }

    // UNIVERSE GETTERS

    /// @inheritdoc IStorageGetters
    function universeOwner(uint256 universeIdx)
        external
        view
        returns (address)
    {
        return _universes[universeIdx].owner;
    }

    /// @inheritdoc IStorageGetters
    function universeName(uint256 universeIdx)
        external
        view
        returns (string memory)
    {
        return _universes[universeIdx].name;
    }

    /// @inheritdoc IStorageGetters
    function universeAuthorizesRelay(uint256 universeIdx)
        external
        view
        returns (bool)
    {
        return _universes[universeIdx].authorizesRelay;
    }

    /// @inheritdoc IStorageGetters
    function universeVerse(uint256 universeIdx)
        external
        view
        returns (uint256)
    {
        return _universes[universeIdx].roots.length - 1;
    }

    /// @inheritdoc IStorageGetters
    function universeRootAtVerse(uint256 universeIdx, uint256 verse)
        external
        view
        returns (bytes32)
    {
        return _universes[universeIdx].roots[verse];
    }

    /// @inheritdoc IStorageGetters
    function universeRootCurrent(uint256 universeIdx)
        external
        view
        returns (bytes32)
    {
        return
            _universes[universeIdx].roots[
                _universes[universeIdx].roots.length - 1
            ];
    }

    /// @inheritdoc IStorageGetters
    function nUniverses() public view returns (uint256) {
        return _universes.length;
    }

    /// @inheritdoc IStorageGetters
    function universeRootSubmissionTimeAtVerse(
        uint256 universeIdx,
        uint256 verse
    ) external view returns (uint256) {
        return _universes[universeIdx].rootsSubmissionTimes[verse];
    }

    /// @inheritdoc IStorageGetters
    function universeRootSubmissionTimeCurrent(uint256 universeIdx)
        external
        view
        returns (uint256)
    {
        return
            _universes[universeIdx].rootsSubmissionTimes[
                _universes[universeIdx].rootsSubmissionTimes.length - 1
            ];
    }

    /// @inheritdoc IStorageGetters
    function universeIsClosed(uint256 universeIdx)
        external
        view
        returns (bool)
    {
        return _universes[universeIdx].closureConfirmed;
    }

    /// @inheritdoc IStorageGetters
    function universeIsClosureRequested(uint256 universeIdx)
        external
        view
        returns (bool)
    {
        return _universes[universeIdx].closureRequested;
    }

    // OWNERSHIP GETTERS

    /// @inheritdoc IStorageGetters
    function challengeWindowNextVerses() external view returns (uint256) {
        return _challengeWindowNextVerses;
    }

    /// @inheritdoc IStorageGetters
    function nLevelsPerChallengeNextVerses() external view returns (uint8) {
        return _nLevelsPerChallengeNextVerses;
    }

    /// @inheritdoc IStorageGetters
    function maxTimeWithoutVerseProduction() external view returns (uint256) {
        return _maxTimeWithoutVerseProduction;
    }

    /// @inheritdoc IStorageGetters
    function exportRequestInfo(uint256 assetId)
        external
        view
        returns (
            address owner,
            uint256 requestVerse,
            uint256 completedVerse
        )
    {
        ExportInfo memory request = _exportInfo[assetId];
        return (request.owner, request.requestVerse, request.completedVerse);
    }

    /// @inheritdoc IStorageGetters
    function exportOwner(uint256 assetId)
        external
        view
        returns (address owner)
    {
        return _exportInfo[assetId].owner;
    }

    /// @inheritdoc IStorageGetters
    function exportRequestVerse(uint256 assetId)
        external
        view
        returns (uint256 requestVerse)
    {
        return _exportInfo[assetId].requestVerse;
    }

    /// @inheritdoc IStorageGetters
    function exportCompletedVerse(uint256 assetId)
        external
        view
        returns (uint256 completedVerse)
    {
        return _exportInfo[assetId].completedVerse;
    }

    /// @inheritdoc IStorageGetters
    function ownershipCurrentVerse() external view returns (uint256) {
        return _ownerships.length - 1;
    }

    /// @inheritdoc IStorageGetters
    function txRootsCurrentVerse() external view returns (uint256) {
        return _txBatches.length - 1;
    }

    /// @inheritdoc IStorageGetters
    function referenceVerse() external view returns (uint256) {
        return _referenceVerse;
    }

    /// @inheritdoc IStorageGetters
    function referenceTime() external view returns (uint256) {
        return _referenceTime;
    }

    /// @inheritdoc IStorageGetters
    function verseInterval() external view returns (uint256) {
        return _verseInterval;
    }

    /// @inheritdoc IStorageGetters
    function ownershipRootAtVerse(uint256 verse)
        external
        view
        returns (bytes32)
    {
        return _ownerships[verse].root;
    }

    /// @inheritdoc IStorageGetters
    function txRootAtVerse(uint256 verse) external view returns (bytes32) {
        return _txBatches[verse].root;
    }

    /// @inheritdoc IStorageGetters
    function nLevelsPerChallengeAtVerse(uint256 verse)
        external
        view
        returns (uint8)
    {
        return _txBatches[verse].nLevelsPerChallenge;
    }

    /// @inheritdoc IStorageGetters
    function levelVerifiableOnChainAtVerse(uint256 verse)
        external
        view
        returns (uint8)
    {
        return _txBatches[verse].levelVerifiableOnChain;
    }

    /// @inheritdoc IStorageGetters
    function nTXsAtVerse(uint256 verse) external view returns (uint256) {
        return _txBatches[verse].nTXs;
    }

    /// @inheritdoc IStorageGetters
    function challengeWindowAtVerse(uint256 verse)
        external
        view
        returns (uint256)
    {
        return _txBatches[verse].challengeWindow;
    }

    /// @inheritdoc IStorageGetters
    function txSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256)
    {
        return _txBatches[verse].submissionTime;
    }

    /// @inheritdoc IStorageGetters
    function ownershipSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256)
    {
        return _ownerships[verse].submissionTime;
    }

    /// @inheritdoc IStorageGetters
    function ownershipRootCurrent() external view returns (bytes32) {
        return _ownerships[_ownerships.length - 1].root;
    }

    /// @inheritdoc IStorageGetters
    function txRootCurrent() external view returns (bytes32) {
        return _txBatches[_txBatches.length - 1].root;
    }

    /// @inheritdoc IStorageGetters
    function nLevelsPerChallengeCurrent() public view returns (uint8) {
        return _txBatches[_txBatches.length - 1].nLevelsPerChallenge;
    }

    /// @inheritdoc IStorageGetters
    function levelVerifiableOnChainCurrent() public view returns (uint8) {
        return _txBatches[_txBatches.length - 1].levelVerifiableOnChain;
    }

    /// @inheritdoc IStorageGetters
    function nTXsCurrent() external view returns (uint256) {
        return _txBatches[_txBatches.length - 1].nTXs;
    }

    /// @inheritdoc IStorageGetters
    function challengeWindowCurrent() external view returns (uint256) {
        return _txBatches[_txBatches.length - 1].challengeWindow;
    }

    /// @inheritdoc IStorageGetters
    function txSubmissionTimeCurrent() external view returns (uint256) {
        return _txBatches[_txBatches.length - 1].submissionTime;
    }

    /// @inheritdoc IStorageGetters
    function ownershipSubmissionTimeCurrent() external view returns (uint256) {
        return _ownerships[_ownerships.length - 1].submissionTime;
    }

    // CHALLENGES GETTERS

    /// @inheritdoc IStorageGetters
    function challengesOwnershipRoot(uint8 level)
        external
        view
        returns (bytes32)
    {
        return _challenges[level].ownershipRoot;
    }

    /// @inheritdoc IStorageGetters
    function challengesTransitionsRoot(uint8 level)
        external
        view
        returns (bytes32)
    {
        return _challenges[level].transitionsRoot;
    }

    /// @inheritdoc IStorageGetters
    function challengesRootAtEdge(uint8 level) external view returns (bytes32) {
        return _challenges[level].rootAtEdge;
    }

    /// @inheritdoc IStorageGetters
    function challengesPos(uint8 level) public view returns (uint256) {
        return _challenges[level].pos;
    }

    /// @inheritdoc IStorageGetters
    function challengesLevel() public view returns (uint8) {
        return uint8(_challenges.length);
    }

    /// @inheritdoc IStorageGetters
    function areAllChallengePosZero() public view returns (bool) {
        for (uint8 level = 0; level < challengesLevel(); level++) {
            if (challengesPos(level) != 0) return false;
        }
        return true;
    }

    /// @inheritdoc IStorageGetters
    function nLeavesPerChallengeCurrent() public view returns (uint256) {
        return 2**uint256(nLevelsPerChallengeCurrent());
    }

    /// @inheritdoc IStorageGetters
    function computeBottomLevelLeafPos(uint256 finalTransEndPos)
        external
        view
        returns (uint256 bottomLevelLeafPos)
    {
        require(
            (challengesLevel() + 1) == levelVerifiableOnChainCurrent(),
            "not enough challenges to compute bottomLevelLeafPos"
        );
        bottomLevelLeafPos = finalTransEndPos;
        uint256 factor = nLeavesPerChallengeCurrent();
        // _challengePos[level = 0] is always 0 (the first challenge is a challenge to one single root)
        for (uint8 level = challengesLevel() - 1; level > 0; level--) {
            bottomLevelLeafPos += challengesPos(level) * factor;
            factor *= factor;
        }
    }

    // ROLES GETTERS

    /// @inheritdoc IStorageGetters
    function company() external view returns (address) {
        return _company;
    }

    /// @inheritdoc IStorageGetters
    function proposedCompany() external view returns (address) {
        return _proposedCompany;
    }

    /// @inheritdoc IStorageGetters
    function superUser() external view returns (address) {
        return _superUser;
    }

    /// @inheritdoc IStorageGetters
    function universesRelayer() external view returns (address) {
        return _universesRelayer;
    }

    /// @inheritdoc IStorageGetters
    function txRelayer() external view returns (address) {
        return _txRelayer;
    }

    /// @inheritdoc IStorageGetters
    function stakers() external view returns (address) {
        return _stakers;
    }

    /// @inheritdoc IStorageGetters
    function writer() external view returns (address) {
        return _writer;
    }

    /// @inheritdoc IStorageGetters
    function directory() external view returns (address) {
        return _directory;
    }

    /// @inheritdoc IStorageGetters
    function externalNFTContract() external view returns (address) {
        return _externalNFTContract;
    }

    /// @inheritdoc IStorageGetters
    function assetExporter() external view returns (address) {
        return _assetExporter;
    }

    // CLAIMS

    /// @inheritdoc IStorageGetters
    function claim(uint256 claimIdx, uint256 key)
        external
        view
        returns (uint256 verse, string memory value)
    {
        Claim memory c = _claims[claimIdx][key];
        return (c.verse, c.value);
    }

    /// @inheritdoc IStorageGetters
    function nClaims() external view returns (uint256) {
        return _claims.length;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.11;

/**
 @title Declaration of all storage variables
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IStorageBase.sol";

contract StorageBase is IStorageBase {
    /// @notice address of the license details for the contract code
    string internal _license;

    //ROLES ADDRESSES

    /// @notice address with company authorization
    address internal _company;

    /// @notice address proposed for company authorization
    address internal _proposedCompany;

    /// @notice address with super user authorization
    address internal _superUser;

    /// @notice address with universe-roots relayer authorization
    address internal _universesRelayer;

    /// @notice address with TX Batch relayer authorization
    address internal _txRelayer;

    /// @notice address of the Stakers contract
    address internal _stakers;

    /// @notice address of the Writers contract
    /// @dev responsible for writing to storage from the Updates & Challenges contracts
    address internal _writer;

    /// @notice address of the Assets Exporter contract
    address internal _assetExporter;

    /// @notice address of the NFT contract where assets are minted when exported
    address internal _externalNFTContract;

    /// @notice address of the Directory contract
    /// @dev contains the addresses of all contracts of the platform
    address internal _directory;

    /// @notice the maximum time since the production of the last verse
    /// @notice beyond which assets can be exported without new verses being produced
    uint256 internal _maxTimeWithoutVerseProduction;

    /// @notice the amount of time allowed for challenging an ownership root
    /// @notice that is currently set as default for next verses
    uint256 internal _challengeWindowNextVerses;

    /// @notice the number of levels contained in each challenge
    /// @notice set as default for next verses
    uint8 internal _nLevelsPerChallengeNextVerses;

    /// @notice Params that determine the planned time to relay txBatches
    uint256 internal _verseInterval;
    uint256 internal _referenceVerse;
    uint256 internal _referenceTime;

    /// @notice The array that stores all Universes structs
    Universe[] internal _universes;

    /// @notice The array that stores all TX Batches structs
    TXBatch[] internal _txBatches;

    /// @notice The array that stores all Ownership structs
    Ownership[] internal _ownerships;

    /// @notice The array that stores all Challenges structs
    Challenge[] internal _challenges;

    /// @notice The mapping that stores all ExportInfo structs
    mapping(uint256 => ExportInfo) internal _exportInfo;

    /// @notice The mapping that stores all Claims structs
    mapping(uint256 => Claim)[] internal _claims;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.11;

/**
 @title Manages authorized addresses
 @author Freeverse.io, www.freeverse.io
 @dev Setters for all roles
 @dev Company owner can reset every other role.
*/

import "../interfaces/IRolesSetters.sol";
import "../storage/StorageGetters.sol";

contract RolesSetters is IRolesSetters, StorageGetters {
    /**
     * @notice Proposes a new company owner, who needs to later accept it
     * @param addr the address of new company owner
     */
    function proposeCompany(address addr) external onlyCompany {
        _proposedCompany = addr;
        emit NewProposedCompany(addr);
    }

    /**
     * @notice The proposed owner uses this function to become the new owner
     */
    function acceptCompany() external {
        require(
            msg.sender == _proposedCompany,
            "only proposed owner can become owner"
        );
        _company = _proposedCompany;
        _proposedCompany = address(0);
        emit NewCompany(_company);
    }

    /**
     * @notice Sets a new superuser
     * @param addr the address of new superuser
     */
    function setSuperUser(address addr) external onlyCompany {
        _superUser = addr;
        emit NewSuperUser(addr);
    }

    /**
     * @notice Sets a new universes relayer
     * @param addr the address of the new universes relayer
     */
    function setUniversesRelayer(address addr) external onlySuperUser {
        _universesRelayer = addr;
        emit NewUniversesRelayer(addr);
    }

    /**
     * @notice Sets a new TX batch relayer
     * @param addr the address of the new TX batch relayer
     */
    function setTxRelayer(address addr) external onlySuperUser {
        _txRelayer = addr;
        emit NewTxRelayer(addr);
    }

    /**
     * @notice Sets a new Writer contract
     * @param addr the address of the new Writer contract
     */
    function setWriter(address addr) public onlySuperUser {
        _writer = addr;
        emit NewWriter(addr);
    }

    /**
     * @notice Sets a new Staker contract
     * @param addr the address of the new Staker contract
     */
    function setStakers(address addr) external onlySuperUser {
        _stakers = addr;
        emit NewStakers(addr);
    }

    /**
     * @notice Sets a new NFT contract to export assets to
     * @param addr the address of the new NFT contract
     */
    function setExternalNFTContract(address addr) external onlySuperUser {
        _externalNFTContract = addr;
        emit NewExternalNFTContract(addr);
    }

    /**
     * @notice Sets a new AssetExporter contract that manages export of assets
     * @param addr the address of the new AssetExporter contract
     */
    function setAssetExporter(address addr) public onlySuperUser {
        _assetExporter = addr;
        emit NewAssetExporter(addr);
    }

    /**
     * @notice Sets a new Directory contract
     * @param addr the address of the new Directory contract
     */
    function setDirectory(address addr) public onlySuperUser {
        _directory = addr;
        emit NewDirectory(addr);
    }

    /**
     * @notice Upgrades contracts
     * @dev Upgrading amounts to changing the contracts with write permissions to storage,
     * and reporting new contract addresses in a new Directory contract
     * @param newWriter the address of the new Writer contract
     * @param newAssetExporter the address of the new AssetExporter contract
     * @param newDirectory the address of the new Directory contract
     */
    function upgrade(
        address newWriter,
        address newAssetExporter,
        address newDirectory
    ) external onlySuperUser {
        setWriter(newWriter);
        setAssetExporter(newAssetExporter);
        setDirectory(newDirectory);
    }

    /**
     * @notice Sets a new owner for a provided universe
     * @dev The owner of a universe must sign any transaction that updates the state
     * of the corresponding universe assets
     * @param universeIdx the idx of the universe
     * @param newOwner the new owner
     */
    function setUniverseOwner(uint256 universeIdx, address newOwner)
        external
        onlySuperUser
    {
        require(universeIdx < nUniverses(), "universeIdx does not exist");
        _universes[universeIdx].owner = newOwner;
        emit NewUniverseOwner(universeIdx, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to the main storage getters
 @author Freeverse.io, www.freeverse.io
*/

interface IStorageGetters {
    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    // UNIVERSE GETTERS

    /**
     * @notice Returns the owner of a universe
     * @param universeIdx The idx of the universe
     * @return The address of the owner
     */
    function universeOwner(uint256 universeIdx) external view returns (address);

    /**
     * @notice Returns the name of a universe
     * @param universeIdx The idx of the universe
     * @return The name of the universe
     */
    function universeName(uint256 universeIdx)
        external
        view
        returns (string memory);

    /**
     * @notice Returns whether owner of a universe authorizes the default relayer
     * @param universeIdx The idx of the universe
     * @return Returns true if owner of a universe authorizes the default relayer
     */
    function universeAuthorizesRelay(uint256 universeIdx)
        external
        view
        returns (bool);

    /**
     * @notice Returns the current verse at which a universe is
     * @param universeIdx The idx of the universe
     * @return The verse
     */
    function universeVerse(uint256 universeIdx) external view returns (uint256);

    /**
     * @notice Returns the root of a universe at the provided verse
     * @param universeIdx The idx of the universe
     * @param verse The verse queried
     * @return The root of the universe at the provided verse
     */
    function universeRootAtVerse(uint256 universeIdx, uint256 verse)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns current root of a universe
     * @param universeIdx The idx of the universe
     * @return The root of the universe at the current verse
     */
    function universeRootCurrent(uint256 universeIdx)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the number of universes created
     * @return The number of universes created
     */
    function nUniverses() external view returns (uint256);

    /**
     * @notice Returns the submission time of a universe root at the
     * provided verse
     * @param universeIdx The idx of the universe
     * @param verse The verse queried
     * @return The submission time
     */
    function universeRootSubmissionTimeAtVerse(
        uint256 universeIdx,
        uint256 verse
    ) external view returns (uint256);

    /**
     * @notice Returns the submission time of the current universe root
     * @param universeIdx The idx of the universe
     * @return The submission time
     */
    function universeRootSubmissionTimeCurrent(uint256 universeIdx)
        external
        view
        returns (uint256);

    /**
     * @notice Returns true if the universe if closed
     * @param universeIdx The idx of the universe
     * @return Returns true if it is closed
     */
    function universeIsClosed(uint256 universeIdx) external view returns (bool);

    /**
     * @notice Returns true if the universe has its closure requested
     * @param universeIdx The idx of the universe
     * @return Returns true if it has its closure requested
     */
    function universeIsClosureRequested(uint256 universeIdx)
        external
        view
        returns (bool);

    // OWNERSHIP GETTERS

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root that is currently set as default for next verses
     * @return the amount of time allowed for challenging
     */
    function challengeWindowNextVerses() external view returns (uint256);

    /**
     * @notice Returns the number of levels contained in each challenge
     * set as default for next verses
     * @return the number of levels contained in each challenge
     */
    function nLevelsPerChallengeNextVerses() external view returns (uint8);

    /**
     * @notice Returns the maximum time since the production of the last
     * verse beyond which assets can be exported without new verses being produced
     * @return the maximum time
     */
    function maxTimeWithoutVerseProduction() external view returns (uint256);

    /**
     * @notice Returns information about possible export requests about the provided asset
     * @param assetId The id of the asset
     * @return owner The owner that requested the asset export
     * @return requestVerse The TX verse at which the export request was received
     * @return completedVerse The TX verse at which the export process was completed (0 if not completed)
     */
    function exportRequestInfo(uint256 assetId)
        external
        view
        returns (
            address owner,
            uint256 requestVerse,
            uint256 completedVerse
        );

    /**
     * @notice Returns the owner that requested the asset export
     * @param assetId The id of the asset
     * @return owner The owner that requested the asset export
     */
    function exportOwner(uint256 assetId) external view returns (address owner);

    /**
     * @notice Returns the TX verse at which the export request was received
     * @param assetId The id of the asset
     * @return requestVerse The TX verse at which the export request was received
     */
    function exportRequestVerse(uint256 assetId)
        external
        view
        returns (uint256 requestVerse);

    /**
     * @notice Returns the TX verse at which the export process was completed (0 if not completed)
     * @param assetId The id of the asset
     * @return completedVerse The TX verse at which the export process was completed (0 if not completed)
     */
    function exportCompletedVerse(uint256 assetId)
        external
        view
        returns (uint256 completedVerse);

    /**
     * @notice Returns the length of the ownership root array
     * @return the length of the ownership root array
     */
    function ownershipCurrentVerse() external view returns (uint256);

    /**
     * @notice Returns the length of the TXs root array
     * @return the length of the TXs root array
     */
    function txRootsCurrentVerse() external view returns (uint256);

    /**
     * @notice Returns the reference verse used in the computation of
     * the time planned for the submission of a TX batch for a given verse
     * @return The reference verse
     */
    function referenceVerse() external view returns (uint256);

    /**
     * @notice Returns the timestamp at which the reference verse took
     * place used, in the computation of the time planned for
     * the submission of a TX batch for a given verse
     * @return The timestamp at which the reference verse took place
     */
    function referenceTime() external view returns (uint256);

    /**
     * @notice Returns the seconds between txVerses between TX batch
     * submissions, used in the computation of the time planned for
     * each submission
     * @return The seconds between txVerses
     */
    function verseInterval() external view returns (uint256);

    /**
     * @notice Returns the ownership root at the provided verse
     * @param verse The verse queried
     * @return The ownership root at the provided verse
     */
    function ownershipRootAtVerse(uint256 verse)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the TX root at the provided verse
     * @param verse The verse queried
     * @return The TX root at the provided verse
     */
    function txRootAtVerse(uint256 verse) external view returns (bytes32);

    /**
     * @notice Returns the number of levels contained in each challenge
     * at the provided verse
     * @param verse The verse queried
     * @return The TX root at the provided verse
     */
    function nLevelsPerChallengeAtVerse(uint256 verse)
        external
        view
        returns (uint8);

    /**
     * @notice Returns the challenge level verifiable on chain
     * at the provided verse
     * @param verse The verse queried
     * @return The level verifiable on chain
     */
    function levelVerifiableOnChainAtVerse(uint256 verse)
        external
        view
        returns (uint8);

    /**
     * @notice Returns the number of TXs included in the batch at
     * the provided verse
     * @param verse The verse queried
     * @return The number of TXs included in the batch
     */
    function nTXsAtVerse(uint256 verse) external view returns (uint256);

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root at the provided verse
     * @param verse The verse queried
     * @return the amount of time allowed for challenging
     */
    function challengeWindowAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the submission time of the TX batch
     * at the provided verse
     * @param verse The verse queried
     * @return the submission time of the TX batch
     */
    function txSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the submission time of the Ownership root
     * at the provided verse
     * @param verse The verse queried
     * @return the submission time of the Ownership root
     */
    function ownershipSubmissionTimeAtVerse(uint256 verse)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the last entry of the ownership root array
     * @return the last entry of the ownership root array
     */
    function ownershipRootCurrent() external view returns (bytes32);

    /**
     * @notice Returns the last entry of the TXs root array
     * @return the last entry of the TXs root array
     */
    function txRootCurrent() external view returns (bytes32);

    /**
     * @notice Returns the number of levels contained in each challenge
     * in the current verse
     * @return the number of levels contained in each challenge
     */
    function nLevelsPerChallengeCurrent() external view returns (uint8);

    /**
     * @notice Returns the challenge level verifiable on chain
     * in the current verse
     * @return The level verifiable on chain
     */
    function levelVerifiableOnChainCurrent() external view returns (uint8);

    /**
     * @notice Returns the number of TXs included in the batch
     * in the current verse
     * @return The number of TXs included in the batch
     */
    function nTXsCurrent() external view returns (uint256);

    /**
     * @notice Returns the amount of time allowed for challenging
     * an ownership root in the current verse
     * @return the amount of time allowed for challenging
     */
    function challengeWindowCurrent() external view returns (uint256);

    /**
     * @notice Returns the submission time of the TX batch
     * in the current verse
     * @return the submission time of the TX batch
     */
    function txSubmissionTimeCurrent() external view returns (uint256);

    /**
     * @notice Returns the submission time of the Ownership root
     * in the current verse
     * @return the submission time of the Ownership root
     */
    function ownershipSubmissionTimeCurrent() external view returns (uint256);

    // CHALLENGES GETTERS

    /**
     * @notice Returns the ownership root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesOwnershipRoot(uint8 level)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the transitions root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesTransitionsRoot(uint8 level)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the edge-root stored at the provided challenge level
     * @param level The queried challenge level
     * @return the stored root
     */
    function challengesRootAtEdge(uint8 level) external view returns (bytes32);

    /**
     * @notice Returns the position stored at the provided challenge level
     * @param level The queried challenge level
     * @return the position
     */
    function challengesPos(uint8 level) external view returns (uint256);

    /**
     * @notice Returns the level stored in the current challenge process
     * @return the level
     */
    function challengesLevel() external view returns (uint8);

    /**
     * @notice Returns true if all positions stored in the current
     * challenge process are zero
     * @return Returns true if all positions are zero
     */
    function areAllChallengePosZero() external view returns (bool);

    /**
     * @notice Returns number of leaves contained in each challenge
     * in the current verse
     * @return Returns true if all positions are zero
     */
    function nLeavesPerChallengeCurrent() external view returns (uint256);

    /**
     * @notice Returns the position of the leaf at the bottom level
     * of the current challenge process
     * @return bottomLevelLeafPos The position of the leaf
     */
    function computeBottomLevelLeafPos(uint256)
        external
        view
        returns (uint256 bottomLevelLeafPos);

    // ROLES GETTERS

    /**
     * @notice Returns the address with company authorization
     */
    function company() external view returns (address);

    /**
     * @notice Returns the address proposed for company authorization
     */
    function proposedCompany() external view returns (address);

    /**
     * @notice Returns the address with super user authorization
     */
    function superUser() external view returns (address);

    /**
     * @notice Returns the address with universe-roots relayer authorization
     */
    function universesRelayer() external view returns (address);

    /**
     * @notice Returns the address with TX Batch relayer authorization
     */
    function txRelayer() external view returns (address);

    /**
     * @notice Returns the address of the Stakers contract
     */
    function stakers() external view returns (address);

    /**
     * @notice Returns the address of the Writer contract
     */
    function writer() external view returns (address);

    /**
     * @notice Returns the address of the Directory contract
     */
    function directory() external view returns (address);

    /**
     * @notice Returns the address of the NFT contract where
     * assets are minted when exported
     */
    function externalNFTContract() external view returns (address);

    /**
     * @notice Returns the address of the Assets Exporter contract
     */
    function assetExporter() external view returns (address);

    // CLAIMS GETTERS

    /**
     * @notice Returns the (verse, value) pair of the provided key
     * in the provided claim
     * @param claimIdx The Idx that identifies claim
     * @param key The key queried the claim
     * @return verse The verse at which the key was set
     * @return value The value that corresponds to the key
     */
    function claim(uint256 claimIdx, uint256 key)
        external
        view
        returns (uint256 verse, string memory value);

    /**
     * @notice Returns the number of Claims created
     * @return the number of Claims created
     */
    function nClaims() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract with declaration of all storage variables
 @author Freeverse.io, www.freeverse.io
*/

interface IStorageBase {
    struct Universe {
        address owner;
        string name;
        bool authorizesRelay;
        bytes32[] roots;
        uint256[] rootsSubmissionTimes;
        bool closureRequested;
        bool closureConfirmed;
    }

    struct TXBatch {
        bytes32 root;
        uint256 submissionTime;
        uint256 nTXs;
        uint8 levelVerifiableOnChain;
        uint8 nLevelsPerChallenge;
        uint256 challengeWindow;
    }

    struct Ownership {
        bytes32 root;
        uint256 submissionTime;
    }

    struct Challenge {
        bytes32 ownershipRoot;
        bytes32 transitionsRoot;
        bytes32 rootAtEdge;
        uint256 pos;
    }

    struct ExportInfo {
        address owner;
        uint256 requestVerse;
        uint256 completedVerse;
    }

    struct Claim {
        uint256 verse;
        string value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contact with main Storage of the Living Assets Platform
 @author Freeverse.io, www.freeverse.io
*/

interface IStorage {
    event NewLicense(string newPath);
    event ChallengeWindow(uint256 newTime);
    event TimeWithoutVerseProduction(uint256 newTime);
    event LevelsPerChallengeNextVerses(uint8 value);
    event UniverseClosure(uint256 universeIdx, bool closureRequested, bool closureConfirmed);
    event UniverseName(uint256 universeIdx, string name);
    event UniverseAuthorizesRelay(uint256 universeIdx, bool authorizesRelay);
    event TXBatchReference(
        uint256 refVerse,
        uint256 refTime,
        uint256 vInterval
    );
    event CreateUniverse(
        uint256 universeIdx,
        address owner,
        string name,
        bool authorizesRelay
    );

    /**
     * @notice Closes a universe so that it cannot be updated further
     * @param universeIdx The idx of the Universe
     * @param closureRequested True if the closure has been requested
     * @param closureConfirmed True if the closure has been confirmed
     */
    function changeUniverseClosure(
        uint256 universeIdx,
        bool closureRequested,
        bool closureConfirmed
    ) external;

    /**
     * @notice Adds a new universe root struct to the universes array
     * @param universeIdx The idx of the Universe
     * @param newRoot The new root to be pushed
     * @param submissionTime The timestamp associated with the new root
     * @return verse The verse at which the universe is after the push
     */
    function pushUniverseRoot(
        uint256 universeIdx,
        bytes32 newRoot,
        uint256 submissionTime
    ) external returns (uint256 verse);

    /**
     * @notice Sets last ownership root to provided value
     * @param newRoot The new root
     */
    function setLastOwnershipRoot(bytes32 newRoot) external;

    /**
     * @notice Sets last ownership submission time to provided value
     * @param newTime The new time
     */
    function setLastOwnershipSubmissionTime(uint256 newTime) external;

    /**
     * @notice Deletes the Challenges array
     */
    function deleteChallenges() external;

    /**
     * @notice Pushes a new TXBatch to the txBatches array
     * @param newTXsRoot The root of the TXBatch
     * @param submissionTime The timestamp associated with the TXBatch
     * @param nTXs The number of TXs included in the TXBatch
     * @param levelVeriableByBC The challenge level that can be verified by
     * the blockchain in case that the ownership root is challenged
     * @param txVerse The new txVerse after executing the push
     */
    function pushTXRoot(
        bytes32 newTXsRoot,
        uint256 submissionTime,
        uint256 nTXs,
        uint8 levelVeriableByBC
    ) external returns (uint256 txVerse);

    /**
     * @notice Pushes a new Ownership stuct to the ownerships array
     * @param newOwnershipRoot The onwership root to be pushed
     * @param submissionTime The timestamp associated with the root
     * @param ownVerse The new length of the ownership array after executing the push
     */
    function pushOwnershipRoot(bytes32 newOwnershipRoot, uint256 submissionTime)
        external
        returns (uint256 ownVerse);

    /**
     * @notice Pushes a new challenge to the challenges array
     * @param ownershipRoot The new proposed ownership root
     * @param transitionsRoot The transitions root provided by the challenger
     * @param rootAtEdge The edge-root stored at the provided challenge level
     * @param pos The position stored at the provided challenge level
     */
    function pushChallenge(
        bytes32 ownershipRoot,
        bytes32 transitionsRoot,
        bytes32 rootAtEdge,
        uint256 pos
    ) external;

    /**
     * @notice Pops the last entry from the universeRoot/universeSubmissionTime arrays
     * @param universeId The universeId
     * @return verse The universe verse after applying the operation
     */
    function popUniverseRoot(uint256 universeId)
        external
        returns (uint256 verse);

    /**
     * @notice Pops the last entry from the challenges array
     */
    function popChallenge() external;

    /**
     * @notice Sets the exportInfo struct associated to an assetId
     * @param assetId The id of the asset
     * @param owner The address of the owner exporting the asset
     * @param requestVerse The TX verse at which the export request is made
     * @param completedVerse The TX verse at which the export is completed
     */
    function setExportInfo(
        uint256 assetId,
        address owner,
        uint256 requestVerse,
        uint256 completedVerse
    ) external;

    /**
     * @notice Sets a claim with to a provided key-value pair
     * @param claimIdx The Idx that identifies claim
     * @param key The key in the claim
     * @param verse The verse at which the key is set
     * @param value The value that corresponds to the key
     */
    function setClaim(
        uint256 claimIdx,
        uint256 key,
        uint256 verse,
        string memory value
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract with setters for all roles 
 @author Freeverse.io, www.freeverse.io
*/

interface IRolesSetters {
    event NewDirectory(address addr);
    event NewCompany(address addr);
    event NewProposedCompany(address addr);
    event NewWriter(address addr);
    event NewSuperUser(address addr);
    event NewUniversesRelayer(address addr);
    event NewTxRelayer(address addr);
    event NewStakers(address addr);
    event NewUniverseOwner(uint256 universeIdx, address owner);
    event NewExternalNFTContract(address addr);
    event NewAssetExporter(address addr);
}