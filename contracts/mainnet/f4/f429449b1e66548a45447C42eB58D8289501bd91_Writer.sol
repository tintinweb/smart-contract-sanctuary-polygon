// SPDX-License-Identifier: BUSL-1.1
// License details specified at address returned by calling the function: license()
pragma solidity =0.8.11;

/**
 @title Contract authorized to write to main storage
 @author Freeverse.io, www.freeverse.io
 @dev This contract is the must-go-through route for any update/challenge 
 @dev that wants to write to storage
*/

import "../interfaces/IStorageGetters.sol";
import "../interfaces/IStorage.sol";
import "../interfaces/IStakers.sol";
import "../interfaces/IWriter.sol";

contract Writer is IWriter {
    // Contracts to which the can write from this contract:
    /// @inheritdoc IWriter
    address public _sto;
    /// @inheritdoc IWriter
    address public _stakers;

    // Contracts from which functions in this contract can be called:
    /// @inheritdoc IWriter
    address public _updates;
    /// @inheritdoc IWriter
    address public _challenges;

    modifier onlySuperUser() {
        require(
            msg.sender == IStorageGetters(_sto).superUser(),
            "Only superUser is authorized."
        );
        _;
    }

    modifier onlyUpdates() {
        require(msg.sender == _updates, "Only _updates is authorized.");
        _;
    }

    modifier onlyChallenges() {
        require(
            msg.sender == _challenges,
            "Only challengesContract is authorized."
        );
        _;
    }

    modifier onlyUpdatesOrChallenges() {
        require(
            (msg.sender == _updates) || (msg.sender == _challenges),
            "Only _updates or _challenges are authorized."
        );
        _;
    }

    constructor(address storageAddress) {
        _sto = storageAddress;
        _stakers = IStorageGetters(_sto).stakers();
    }

    /// @inheritdoc IWriter
    function license() external view returns (string memory) {
        return IStorageGetters(_sto).license();
    }

    /**
     * @notice Sets the address of the Updates and Challenges
     * contracts that this contract can communicate with
     * @param updatesContract the address of the Updates Contract
     * @param challengesContract the address of the Challenges Contract
     */
    function setUpdatesAndChallenges(
        address updatesContract,
        address challengesContract
    ) external onlySuperUser {
        _updates = updatesContract;
        _challenges = challengesContract;
    }

    /// @inheritdoc IWriter
    function addUniverseRoot(
        uint256 universeIdx,
        bytes32 root,
        uint256 timestamp
    ) external onlyUpdates returns (uint256 verse) {
        return IStorage(_sto).pushUniverseRoot(universeIdx, root, timestamp);
    }

    /// @inheritdoc IWriter
    function addTXRoot(
        bytes32 txRoot,
        uint256 timestamp,
        uint256 nTXs,
        uint8 actualLevel,
        uint8 levelVeriableByBC
    ) external onlyUpdates returns (uint256 txVerse) {
        IStorage(_sto).setLastOwnershipRoot(
            IStorageGetters(_sto).challengesOwnershipRoot(actualLevel - 1)
        );
        txVerse = IStorage(_sto).pushTXRoot(
            txRoot,
            timestamp,
            nTXs,
            levelVeriableByBC
        );
        IStorage(_sto).deleteChallenges();
    }

    /// @inheritdoc IWriter
    function addOwnershipRoot(bytes32 ownershipRoot)
        external
        onlyUpdates
        returns (uint256 ownVerse)
    {
        if (IStorageGetters(_sto).challengesLevel() > 0) {
            // Challenge game had moved tacitly to level 0: rewrite
            IStorage(_sto).deleteChallenges();
            IStorage(_sto).setLastOwnershipSubmissionTime(block.timestamp);
        } else {
            // Challenge finished and ownership settled: create ownership struct for new verse
            IStorage(_sto).pushOwnershipRoot(bytes32(0x0), block.timestamp);
        }
        IStorage(_sto).pushChallenge(
            ownershipRoot,
            bytes32(0),
            bytes32(0x0),
            0
        );
        return IStorageGetters(_sto).ownershipCurrentVerse();
    }

    /// @inheritdoc IWriter
    function pushChallenge(
        bytes32 ownershipRoot,
        bytes32 transitionsRoot,
        bytes32 rootAtEdge,
        uint256 pos
    ) external onlyChallenges {
        IStorage(_sto).pushChallenge(
            ownershipRoot,
            transitionsRoot,
            rootAtEdge,
            pos
        );
    }

    /// @inheritdoc IWriter
    function setLastOwnershipSubmissiontime(uint256 timestamp)
        external
        onlyChallenges
    {
        IStorage(_sto).setLastOwnershipSubmissionTime(timestamp);
    }

    /// @inheritdoc IWriter
    function popChallengeDataToLevel(uint8 actualLevel)
        external
        onlyChallenges
    {
        uint8 currentLevel = IStorageGetters(_sto).challengesLevel();
        require(
            currentLevel > actualLevel,
            "cannot pop unless final level is lower than current level"
        );
        for (uint8 n = 0; n < (currentLevel - actualLevel); n++) {
            IStorage(_sto).popChallenge();
        }
    }

    /// @inheritdoc IWriter
    function changeUniverseClosure(
        uint256 universeIdx,
        bool closureRequested,
        bool closureConfirmed
    ) external onlyUpdates {
        IStorage(_sto).changeUniverseClosure(
            universeIdx,
            closureRequested,
            closureConfirmed
        );
    }

    /// @inheritdoc IWriter
    function finalize() external onlyUpdates {
        IStakers(_stakers).finalize();
    }

    /// @inheritdoc IWriter
    function addChallenge(uint8 level, address staker)
        external
        onlyUpdatesOrChallenges
    {
        IStakers(_stakers).addChallenge(level, staker);
    }

    /// @inheritdoc IWriter
    function resolveToLevel(uint8 level) external onlyChallenges {
        IStakers(_stakers).resolveToLevel(level);
    }

    /// @inheritdoc IWriter
    function rewindToLevel(uint8 level) external onlyChallenges {
        IStakers(_stakers).rewindToLevel(level);
    }

    /**
     * @notice Sets a key-value pair in a Claim
     */
    function setClaim(
        uint256 claimIdx,
        uint256 key,
        uint256 verse,
        string memory value
    ) external onlySuperUser {
        IStorage(_sto).setClaim(claimIdx, key, verse, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract with write authorization to storage
 @author Freeverse.io, www.freeverse.io
*/

interface IWriter {
    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns the address of the Storage contract that
     * this contract can write to
     */
    function _sto() external view returns (address);

    /**
     * @notice Returns the address of the Stakers contract that
     * this contract can communicate with
     */
    function _stakers() external view returns (address);

    /**
     * @notice Returns the address of the Updates contract that
     * this contract can communicate with
     */
    function _updates() external view returns (address);

    /**
     * @notice Returns the address of the Challenges contract that
     * this contract can communicate with
     */
    function _challenges() external view returns (address);

    // Functions that write to the Storage Contract

    /**
     * @notice Adds a new root to a Universe
     * @param universeIdx The idx of the universe
     * @param root The root to be added
     * @param timestamp The timestamp to be associated
     * @return verse The verse at which the universe is after the addition
     */
    function addUniverseRoot(
        uint256 universeIdx,
        bytes32 root,
        uint256 timestamp
    ) external returns (uint256 verse);

    /**
     * @notice Adds a new TX root
     * @dev TXs are added in batches. When adding a new batch, the ownership root settled in the previous verse
     * is settled, by copying from the challenge struct to the last ownership entry.
     * @param txRoot The nex TX root to be added
     * @param timestamp The timestamp to be associated
     * @param nTXs The number of TXs included in the batch
     * @param actualLevel The level at which the last challenge ended at
     * @param levelVeriableByBC The level at which a Challenge can be verified by the blockchain contract
     * @return txVerse The length of the TX roots array after the addition
     */
    function addTXRoot(
        bytes32 txRoot,
        uint256 timestamp,
        uint256 nTXs,
        uint8 actualLevel,
        uint8 levelVeriableByBC
    ) external returns (uint256 txVerse);

    /**
     * @notice Adds a new Ownership root
     * @dev A new ownership root, ready for challenge is received.
     * Registers timestamp of reception, creates challenge and it
     * either appends to _ownerships, or rewrites last entry, depending on
     * whether it corresponds to a new verse, or it results from a challenge
     * to the current verse.
     * The latter can happen when the challenge game moved tacitly to level 0.
     * @param ownershipRoot The new ownership root to be added
     * @return ownVerse The length of the ownership array after the addition
     */
    function addOwnershipRoot(bytes32 ownershipRoot)
        external
        returns (uint256 ownVerse);

    /**
     * @notice Pushes a challenge to the Challenges array
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
     * @notice Sets the timestamp associated to the last ownership root received
     * @param timestamp The new time
     */
    function setLastOwnershipSubmissiontime(uint256 timestamp) external;

    /**
     * @notice Pops the last entries in the Challenge array as many times
     * as required to set its length to actualLevel
     */
    function popChallengeDataToLevel(uint8 actualLevel) external;

    /**
     * @notice Changes the data associated with the closure of a universe
     */
    function changeUniverseClosure(
        uint256 universeIdx,
        bool closureRequested,
        bool closureConfirmed
    ) external;

    /**
     * @dev Functions that write to Stakers conttact
     */

    /**
     * @notice Finalizes the currently opened challenge
     */
    function finalize() external;

    /**
     * @notice Adds a new challenge
     */
    function addChallenge(uint8 level, address staker) external;

    /**
     * @notice Resolves the last entries of a Challenge so as to
     * leave its final level to equal the provided level
     */
    function resolveToLevel(uint8 level) external;

    /**
     * @notice Pops updaters from a Challenge so as to
     * leave its final level to equal the provided level
     */
    function rewindToLevel(uint8 level) external;
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
 @title Interface to contact with main Storage of the Living Assets Platform
 @author Freeverse.io, www.freeverse.io
*/

interface IStorage {
    event NewLicense(string newPath);
    event ChallengeWindow(uint256 newTime);
    event TimeWithoutVerseProduction(uint256 newTime);
    event LevelsPerChallengeNextVerses(uint8 value);
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
 @title Interface to contract that Manages Stakers and their deposits. 
 @author Freeverse.io, www.freeverse.io
*/

interface IStakers {
    event PotBalanceChange(uint256 newBalance);
    event RewardsExecuted();
    event AddedTrustedParty(address indexed party);
    event RemovedTrustedParty(address indexed party);
    event NewEnrol(address indexed staker);
    event NewUnenrol(address indexed staker);
    event SlashedBy(address indexed slashedStaker, address indexed goodStaker);
    event AddedRewardToUpdater(address indexed staker);
    event FinalizedLogicRound();
    event NewLevel(uint16 indexed level);

    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns address of the storage contract that
     * this contract is attached to.
     */
    function sto() external view returns (address);

    /**
     * @notice Returns true if the provided address is registered as staker.
     * @return whether the provided address is a staker
     */
    function isStaker(address) external view returns (bool);

    /**
     * @notice Returns true if the provided address is has been slashed.
     * @return whether the provided address has been slashed
     */
    function isSlashed(address) external view returns (bool);

    /**
     * @notice Returns true if the provided address is registered as trusted party.
     * @return whether the provided address is a trusted party
     */
    function isTrustedParty(address) external view returns (bool);

    /**
     * @notice Returns the amount staked by the provided address.
     * @return the amount staked by the provided address.
     */
    function stakes(address) external view returns (uint256);

    /**
     * @notice Returns the amount available for withdrawal
     * by the the provided address.
     * @return the amount available for withdrawal
     */
    function pendingWithdrawals(address) external view returns (uint256);

    /**
     * @notice Returns the number of updates performed
     * by the the provided address since the last event of
     * reward execution
     * @return the number of updates performed
     */
    function nUpdates(address) external view returns (uint256);

    /**
     * @notice Returns the number of registered stakers
     * @return the number of registered stakers
     */
    function nStakers() external view returns (uint256);

    /**
     * @notice Returns the stake amount required to join as staker
     * @return the stake amount required to join as staker
     */
    function requiredStake() external view returns (uint256);

    /**
     * @notice Returns the amount available in the pot
     * @return the amount available in the pot
     */
    function potBalance() external view returns (uint256);

    /**
     * @notice Returns total number of updates performed since
     * the last event of reward execution
     * @return the total number of updates performed
     */
    function totalNumUpdates() external view returns (uint256);

    /**
     * @notice Returns the address at the provided idx of the array of
     * stakers to be rewarded
     * @param idx The index in the array
     * @return the address of the staker to be rewarded at the idx provided
     */
    function toBeRewarded(uint256 idx) external view returns (address);

    /**
     * @notice Returns the address of the updater at the idx provided
     * @param idx The index in the array
     * @return the address of the updater at the idx provided
     */
    function updaters(uint256 idx) external view returns (address);

    /**
     * @notice Transfers pendingWithdrawals to the calling staker;
     * @dev the stake remains until unenrol is called
     */
    function withdraw() external;

    /**
     * @notice Reverts if the address does not fulfil the conditions
     * required to become a trusted party
     */
    function assertGoodCandidate(address _addr) external view;

    /**
     * @notice Registers a new staker
     * @dev Must be called by the candidate
     */
    function enrol() external payable;

    /**
     * @notice Unregisters a staker and transfers all earnings
     * @dev Must be called by the corresponding staker
     */
    function unEnroll() external;

    /**
     * @notice Update to a new level
     * @dev This function will also resolve previous updates when
     * level is below current or level has reached the end
     * Requiring that _staker is not slashed is already covered by not being part of stakers,
     * because slashing removes address from stakers
     * @param _level to which update
     * @param _staker address of the staker that reports this update
     */
    function addChallenge(uint16 _level, address _staker) external;

    /**
     * @notice Resolves a challenge at the provided level
     * @param _level at which we will end up, due to a level proven right,
     * and previous one proven wrong, possibly a few times.
     */
    function resolveToLevel(uint16 _level) external;

    /**
     * @notice Rewinds a challenge process to a previous level
     * @param _level at which we will end up, due to a challenge to a previously-challenged level.
     */
    function rewindToLevel(uint16 _level) external;

    /**
     * @notice Finalize current challenge process, get ready for next one.
     * @dev Current state will be resolved at this point.
     * If called from level 1, then staker is rewarded.
     * When called from any other level, means that every
     * other staker told the truth but the one in between lied.
     */
    function finalize() external;

    /**
     * @notice Adds funds to pot to be shared by stakers who update
     * @dev Any address can add funds
     */
    function addRewardToPot() external payable;

    /**
     * @notice Returns true if the provided address has already
     * performed an update in the current challenge
     * @return whether the provided address has already performed an update
     */
    function alreadyDidUpdate(address _address) external view returns (bool);

    /**
     * @notice Returns the level at which the challenge is
     * @return the level at which the challenge is
     */
    function level() external view returns (uint16);
}