// SPDX-License-Identifier: BUSL-1.1
// License details specified at address returned by calling the function: license()
pragma solidity =0.8.11;

/**
 @title Main Contract for exporting Living Assets to Standard Layer-1 ERC721 NFTs
 @author Freeverse.io, www.freeverse.io
 @dev Asset owners can use the main functions in this contract permissionlessly
*/

import "../interfaces/IStorage.sol";
import "../interfaces/IStorageGetters.sol";
import "../interfaces/IInfo.sol";
import "../interfaces/IInfoBase.sol";
import "../interfaces/IAssetExport.sol";

import "../erc721/ERC721FV.sol";

contract AssetExport is IAssetExport {
    /// @inheritdoc IAssetExport
    address public _info;
    /// @inheritdoc IAssetExport
    address public _erc721;
    /// @inheritdoc IAssetExport
    address public immutable _sto;

    constructor(address storageAddress, address infoAddress) {
        _info = infoAddress;
        _sto = storageAddress;
        _erc721 = IStorageGetters(_sto).externalNFTContract();
    }

    modifier onlySuperUser() {
        require(
            msg.sender == IStorageGetters(_sto).superUser(),
            "AssetExport: Only superUser is authorized."
        );
        _;
    }

    /// @inheritdoc IAssetExport
    function license() external view returns (string memory) {
        return IStorageGetters(_sto).license();
    }

    /**
     * @notice Transfers ownership of the external NFT contract
     * @dev The new owner contract must implement a transferOwnership method too.
     * @param newOwner The address of the new owner
     */
    function transferERCOwnership(address newOwner) external onlySuperUser {
        ERC721FV(_erc721).transferOwnership(newOwner);
    }

    // Main contracts required by AssetExport: Info & external ERC721

    function setInfoAddress(address newAddr) external onlySuperUser {
        _info = newAddr;
        emit NewInfoAddress(newAddr);
    }

    function setERC721Address(address newAddr) external onlySuperUser {
        _erc721 = newAddr;
        emit NewERC721Address(newAddr);
    }

    /// @inheritdoc IAssetExport
    function requestAssetExport(
        uint256 assetId,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory assetPropsProof
    ) external {
        require(
            bytes(assetCID).length > 8,
            "requestAssetExport: only created assets with valid CID can be exported"
        );
        require(
            !tokenHasOwner(assetId),
            "requestAssetExport: asset already exported"
        );
        uint256 txRootsVerse = IStorageGetters(_sto).txRootsCurrentVerse();
        require(
            !IInfoBase(_info).wasAssetFrozen(marketData, txRootsVerse),
            "requestAssetExport: cannot export an asset that is currently frozen"
        );
        require(
            IInfo(_info).isCurrentOwner(
                assetId,
                msg.sender,
                marketData,
                ownershipProof
            ),
            "requestAssetExport: isCurrentOwner failed"
        );
        require(
            IInfo(_info).isCurrentAssetProps(
                assetId,
                assetCID,
                assetPropsProof
            ),
            "requestAssetExport: isCurrentAssetProps failed"
        );
        (address requestOwner, , uint256 completedVerse) = IStorageGetters(_sto)
            .exportRequestInfo(assetId);
        require(
            msg.sender != requestOwner,
            "requestAssetExport: owner cannot re-request export"
        );
        require(
            completedVerse == 0,
            "createExportRequest: asset already exported"
        );
        IStorage(_sto).setExportInfo(assetId, msg.sender, txRootsVerse, 0);
        emit RequestAssetExport(assetId, msg.sender, txRootsVerse);
    }

    /// @inheritdoc IAssetExport
    function completeAssetExport(
        uint256 assetId,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory assetPropsProof
    ) external {
        require(
            bytes(assetCID).length > 8,
            "completeAssetExport: only created assets with valid CID can be exported"
        );
        require(
            !tokenHasOwner(assetId),
            "completeAssetExport: asset already exported"
        );
        uint256 txRootsVerse = IStorageGetters(_sto).txRootsCurrentVerse();
        require(
            !IInfoBase(_info).wasAssetFrozen(marketData, txRootsVerse),
            "completeAssetExport: cannot export an asset that is currently frozen"
        );
        require(
            IInfo(_info).isCurrentOwner(
                assetId,
                msg.sender,
                marketData,
                ownershipProof
            ),
            "completeAssetExport: isCurrentOwner failed"
        );
        require(
            IInfo(_info).isCurrentAssetProps(
                assetId,
                assetCID,
                assetPropsProof
            ),
            "completeAssetExport: isCurrentAssetProps failed"
        );
        (
            address requestOwner,
            uint256 requestVerse,
            uint256 completedVerse
        ) = IStorageGetters(_sto).exportRequestInfo(assetId);
        require(
            completedVerse == 0,
            "completeAssetExport: asset already exported"
        );
        require(
            msg.sender == requestOwner,
            "completeAssetExport: must be completed by same owner that request it"
        );
        // Export can be completed 2 verses after request.
        // If operations ceased, verses may not continue being processed. In that case,
        // it suffices to wait for time = maxTimeWithoutVerseProduction()
        if (!(txRootsVerse > requestVerse + 1)) {
            uint256 requestTimestamp = IStorageGetters(_sto)
                .txSubmissionTimeAtVerse(requestVerse);
            require(
                block.timestamp >
                    requestTimestamp +
                        IStorageGetters(_sto).maxTimeWithoutVerseProduction(),
                "completeAssetExport: must wait for at least 1 verse fully confirmed, or enough time since export request"
            );
        }
        IStorage(_sto).setExportInfo(
            assetId,
            msg.sender,
            requestVerse,
            txRootsVerse
        );
        emit CompleteAssetExport(assetId, msg.sender, txRootsVerse);
        ERC721FV(_erc721).mint(msg.sender, assetId, addIPFSPrefix(assetCID));
    }

    /// @inheritdoc IAssetExport
    function tokenHasOwner(uint256 assetId) public view returns (bool) {
        return ERC721FV(_erc721).exists(assetId);
    }

    /// @inheritdoc IAssetExport
    function addIPFSPrefix(string memory assetCID)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("ipfs://", assetCID));
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
 @title Interface to contract for querying and using storage extensions 
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IBlackholeId.sol";
import "../interfaces/IGovernance.sol";

interface IStorageExtension is IBlackholeId, IGovernance {

    /**
     * @notice Reverts unless the Storage contract stores the expected
     *  claims, with the expected allowed values
     */
    function assertValidStorageExtension() external view;
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
 @title Interface to library of pure functions to help providing info 
 @author Freeverse.io, www.freeverse.io
*/

interface IInfoBase {
    /**
     * @notice Returns true if the ownership data provided is
     * in a leave of the provided ownership root
     * @param ownershipRoot The ownership root to check against
     * @param assetId The id of the asset
     * @param owner The address of the owner
     * @param marketData The market data of the asset
     * @param proof The proof that the data belong to the SMT with root = ownershipRoot
     * @return whether the proof is valid or not
     */
    function isOwnerInOwnershipRoot(
        bytes32 ownershipRoot,
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) external pure returns (bool);

    /**
     * @notice Returns true if the asset data provided is
     * in a leave of the provided universe root
     * @param root The universe root to check against
     * @param proof The proof that the data belongs to a tree with provided root
     * @param assetId The id of the asset
     * @param assetCID The CID of the asset
     * @return whether the proof is valid or not
     */
    function isAssetPropsInUniverseRoot(
        bytes32 root,
        bytes memory proof,
        uint256 assetId,
        string memory assetCID
    ) external pure returns (bool);

    /**
     * @dev Calls isOwnerInOwnershipRoot after deserializing the provided data
     * @param data The serialized input params required by isOwnerInOwnershipRoot
     * @param ownershipRoot The ownership root to check against
     * @return whether the proof is valid or not
     */
    function isOwnerInOwnershipRootSerialized(
        bytes memory data,
        bytes32 ownershipRoot
    ) external pure returns (bool);

    /**
     * @notice Updates the root of the Ownership Tree using the provided TX
     * @param txData The serialized TX data
     * @param initOwnershipRaw The serialized data describing the leaf in the initial Ownership Tree.
     * @return the new updated Root
     */
    function updateOwnershipTreeSerialized(
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) external pure returns (bytes32);

    /**
     * @notice Encodes market data in a serialized form
     * @param assetId The id of the asset
     * @param validUntil The verse until which the auction is valid
     * @param offerValidUntil The verse until which the offer is valid
     * @param versesToPay The number of verses available to pay after auction finishes
     * @param sellerHiddenPrice The unique hash describing sale data
     * @return the serialized market data
     */
    function encodeMarketData(
        uint256 assetId,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay,
        bytes32 sellerHiddenPrice
    ) external pure returns (bytes memory);

    /**
     * @notice Retrieves the Buyer from a provided complete-auction TX data
     * @dev the TX data includes a signature, which is ultimately used to derive the buyer
     * @param txData The serialized data that describes the TX
     * @return the address of the buyer
     */
    function complTXRecoverBuyer(bytes memory txData)
        external
        pure
        returns (address);

    /**
     * @notice Returns the digest of a buynow TX that is signed by seller
     * @param hiddenPrice The unique hash describing sale data
     * @param assetId The id of the asset
     * @param validUntil The verse until which the buynow is valid
     * @param assetCID The assetCID
     * @return the digest
     */
    function digestBuyNow(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint256 validUntil,
        string memory assetCID
    ) external pure returns (bytes32);

    /**
     * @notice Returns the root of an SMT after changing one leaf
     * @dev The update the ownership tree reuses the proof of the previous leafVal, since all siblings remain identical
     * @dev The fact that proofPrevLeafVal actually proves the prevLeafVal needs to be checked before calling this function.
     * @param newLeafVal The new value of the leaf
     * @param assetId The id of the asset
     * @param proofPrevLeafVal The proof that the previous leaf belonged to the tree
     * @return the root of the updated tree
     */
    function updateOwnershipTree(
        bytes32 newLeafVal,
        uint256 assetId,
        bytes memory proofPrevLeafVal
    ) external pure returns (bytes32);

    /**
     * @notice Returns a unique Id that describes an auction, given its characteristics
     * @param hiddenPrice The unique hash describing sale data
     * @param assetId The id of the asset
     * @param validUntil The verse until which the auction is valid
     * @param offerValidUntil The verse until which the offer is valid
     * @param versesToPay The amount of verses available to pay after auction finishes
     * @return the unique auction Id
     */
    function computeAuctionId(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay
    ) external pure returns (bytes32);

    /**
     * @notice Returns true if the asset was frozen at provided verse
     * @param marketData The market data of the asset
     * @param checkVerse The verse to which the query refers
     * @return bool that is true if asset was frozen at checkVerse
     */
    function wasAssetFrozen(bytes memory marketData, uint256 checkVerse)
        external
        pure
        returns (bool);

    /**
     * @notice Returns the leaf value of an asset in its universe tree
     * @param assetId The id of the asset
     * @param cid The asset CID
     * @return leafVal The leaf value
     */
    function computeAssetLeaf(uint256 assetId, string memory cid)
        external
        pure
        returns (bytes32 leafVal);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract with info/view functions
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IChallengeLibStatus.sol";
import "../interfaces/IStorageExtension.sol";

interface IInfo is IChallengeLibStatus, IStorageExtension {

    /**
     * @notice The enum that describes the possible states of the L2 -> L1 ownership sync flow
     */
    enum OwnershipState { AWAIT_TXS, AWAIT_OWNERSHIP, AWAIT_CHALLENGE, AWAIT_VERSE_TICK, AWAIT_GOVERNANCE }

    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns true only if the input owner owns the asset AND the asset has the provided props
     * @dev Proofs need to be provided. They are verified against current Ownerhsip and Universe roots.
     * @param assetId The id of the asset
     * @param owner The address of the asset owner
     * @param marketData The market data of the asset
     * @param assetCID The CID of the asset
     * @param ownershipProof The proof that the asset belongs to the current Ownership tree
     * @param propsProof The proof that the asset properties belong to the current Universe tree
     * @return whether the proofs are valid or not
     */
    function isCurrentOwnerOfAssetWithProps(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory propsProof
    ) external view returns (bool);

    /**
     * @notice Returns true only if the input owner owns the asset
     * @dev Proof needs to be provided. They are verified against current Ownership root
     * - if marketDataNeverTraded(marketData) == true (asset has never been included in the ownership tree)
     *   - it first verifies that it's not in the tree (the leafHash is bytes(0x0))
     *   - it then verifies that "owner" is the default owner
     * - if marketDataNeverTraded(marketData) == false (asset must be included in the ownership tree)
     *   - it only verifies owner == current owner stored in the ownership tree
     * Once an asset is traded once, marketDataNeverTraded remains false forever.
     * If asset has been exported, this function returns false; ownership needs to be queried in the external ERC721 contract.
     * @param assetId The id of the asset
     * @param owner The address of the asset owner
     * @param marketData The market data of the asset
     * @param proof The proof that the asset belongs to the current Ownership tree
     * @return whether the proof is valid or not
     */
    function isCurrentOwner(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Returns true only if the input owner owned the asset at provided verse
     * @dev Identical to isCurrentOwner, but uses the Ownership root at provided verse
     * @param verse The ownership verse at which the query refers
     * @param assetId The id of the asset
     * @param owner The address of the asset owner
     * @param marketData The market data of the asset
     * @param proof The proof that the asset belonged to the Ownership tree at provided verse
     * @return whether the proof is valid or not
     */
    function wasOwnerAtVerse(
        uint256 verse,
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Serialized-inputs version of isCurrentOwner
     * @dev Unpacks inputs and calls isCurrentOwner
     * @param data The serialized ownership data
     * @return whether the proof contained in data is valid or not
     */
    function isCurrentOwnerSerialized(bytes memory data)
        external
        view
        returns (bool);

    /**
     * @notice Serialized-inputs version of wasOwnerAtVerse
     * @dev Unpacks inputs and calls wasOwnerAtVerse
     * @param verse The ownership verse at which the query refers
     * @param data The serialized ownership data
     * @return whether the proof contained in data is valid or not
     */
    function wasOwnerAtVerseSerialized(uint256 verse, bytes memory data)
        external
        view
        returns (bool);

    /**
     * @notice Returns true only if asset currently has the provided props
     * @dev Proof needs to be provided. They are verified against current Universe root
     * @param assetId The id of the asset
     * @param assetCID The CID of the asset
     * @param proof The proof that the asset belongs to the current Universe tree
     * @return whether the proof is valid or not
     */
    function isCurrentAssetProps(
        uint256 assetId,
        string memory assetCID,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Returns true only if the asset had the provided props at the provided verse
     * @dev Identical to isCurrentAssetProps, but uses the Universe root at the provided verse
     * @param assetId The id of the asset
     * @param verse The universe verse at which the query refers
     * @param assetCID The CID of the asset
     * @param proof The proof that the asset properties belonged to the
     * Universe tree at provided verse
     * @return whether the proof is valid or not
     */
    function wasAssetPropsAtVerse(
        uint256 assetId,
        uint256 verse,
        string memory assetCID,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Returns the last Ownership root that is fully settled (there could be one still in challenge process)
     * @dev There are 3 phases to consider.
     * 1. When submitTX just arrived, we just need to return the last stored ownership root
     * 2. When submitOwn just arrived, a temp root is added, so we return the last-to-last stored ownership root
     * 3. When the challenge period is over we return the settled root, which is in the challenge struct.
     * @return the current settled ownership root
     */
    function currentSettledOwnershipRoot() external view returns (bytes32);

    /**
     * @notice Returns the last settled ownership verse number
     * @return the settled ownership verse
     */
    function currentSettledOwnershipVerse() external view returns (uint256);

    /**
     * @notice Computes data about whether the system is in the phase that goes between
     * the finishing of the challenge period, and the arrival
     * of a new submission of a TX Batch
     * @return isChallengeOver Whether the system is in the phase between the settlement of
     * the last ownership root, and the submission of a new TX Batch
     * @return actualLevel The level at which the last challenge process is, accounting for
     * implicit time-driven changes
     * @return txVerse The current txVerse
     */
    function isInChallengePeriodFinishedPhase()
        external
        view
        returns (
            bool isChallengeOver,
            uint8 actualLevel,
            uint256 txVerse
        );

    /**
     * @notice Returns the current state of the ownership synchronization state machine
     * @return the current ownership state
     */
    function ownershipState() external view returns(OwnershipState);

    /**
     * @notice Computes data about whether the system is ready to accept
     * the submission of a new TX batch
     * @return isReady Whether the system is ready to accept a new TX batch submission
     * @return actualLevel The level at which the last challenge process is, accounting for
     * implicit time-driven changes
     */
    function isReadyForTXSubmission()
        external
        view
        returns (bool isReady, uint8 actualLevel);

    /**
     * @notice Returns the time planned for the submission of a TX batch for a given verse
     * @param verse The TX verse queried
     * @param referenceVerse The reference verse used in the computation
     * @param referenceTime The timestamp at which the reference verse took place
     * @param verseInterval The seconds between txVerses
     * @return the time planned for the submission of a TX batch for a given verse
     */
    function plannedTime(
        uint256 verse,
        uint256 referenceVerse,
        uint256 referenceTime,
        uint256 verseInterval
    ) external pure returns (uint256);

    /**
     * @notice Returns true if the system is ready to accept a new ownership root
     * @dev When a TXs batch is submitted, a new Ownership state can be submitted.
     * @return Returns true if the system is ready to accept a new ownership root
     */
    function isReadyForOwnershipSubmission() external view returns (bool);

    /**
     * @notice Returns true if the system is ready to accept challenges to the last
     * submitted ownership root
     * @return Whether the system is ready to accept challenges
     */
    function isReadyForChallenge() external view returns (bool);

    /**
     * @notice Returns data about the status of the current challenge,
     * taking into account the time passed, so that the actual level
     * can be less than the level explicitly stored, or just settled.
     * @return isSettled Whether the current challenge process is settled
     * @return actualLevel The level at which the last challenge process is, accounting for
     * @return nJumps The number of challenge levels already accounted for when
     * taking time into account
     */
    function getCurrentChallengeStatus()
        external
        view
        returns (
            bool isSettled,
            uint8 actualLevel,
            uint8 nJumps
        );

    /**
     * @notice Returns true if the asset cannot undergo any ownership change
     * because of its export process
     * @dev This function requires both the assetId and the owner as inputs,
     * because an asset is blocked only if the owner coincides with
     * the address that made the request earlier.
     * This view function gathers export info from storage and calls isAssetBlockedByExportPure
     * @param assetId the id of the asset
     * @param currentOwner the current owner of the asset
     * @return whether the asset is blocked or not
     */
    function isAssetBlockedByExport(uint256 assetId, address currentOwner)
        external
        view
        returns (bool);

    /**
     * @notice Returnss true if the asset cannot undergo any ownership change
     * @dev Pure version of isAssetBlockedByExport
     * @param currentOwner The current owner of the asset
     * @param currentVerse The current txVerse
     * @param requestOwner The address of the owner who started the export request
     * @param requestVerse The txVerse at which the export request was made
     * @param completedVerse The txVerse at which the export process was completed.
     * Should be 0 if process is not completed.
     * @return whether the asset is blocked or not
     */
    function isAssetBlockedByExportPure(
        address currentOwner,
        uint256 currentVerse,
        address requestOwner,
        uint256 requestVerse,
        uint256 completedVerse
    ) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract for querying and using isAwaitingGovernance 
 @author Freeverse.io, www.freeverse.io
*/

interface IGovernance {

    /**
     * @notice Returns the awaitGovernance bool stored in the Storage contract
     *  WARNING: this function can revert if the claim does not exist in storage,
     *  use hasGovernance() before calling this function to avoid unwanted reverts.
     * @return the awaitGovernance bool stored in the Storage contract
     */
    function isAwaitingGovernance() external view returns (bool);

    /**
     * @notice Returns true if the Storage contract stores as claim(1,0)
     *  the expected data for a isAwaitingGovernance
     * @return true if the stored isAwaitingGovernance is as expected
     */
    function hasGovernance() external view returns (bool);

    /**
     * @notice Returns true if the provided inputs follow the 
     *  the expected data for a isAwaitingGovernance
     * @param str the provided string that identifies the claim as referring to 'isAwaitingGovernance'
     * @return true if the provided inputs follow the expected data for a isAwaitingGovernance
     */
    function claimIsValidGovernance(string memory str) external pure returns (bool);

    /**
     * @notice Reverts unless the Storage contract stores as claim(1,0)
     *  the expected data for a isAwaitingGovernance
     */
    function assertValidGovernance() external view; 
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @author Freeverse.io, www.freeverse.io
 @dev Interface to contract with pure function to compute the status of a challenge
*/

interface IChallengeLibStatus {
    /**
     * @dev Computes if the system is ready to accept a new TX Batch submission
     *      Data from storage is fetched previous to passing to this function.
     */
    function isInChallengePeriodFinishedPhasePure(
        uint256 txRootsCurrentVerse,
        uint256 ownershipSubmissionTimeCurrent,
        uint256 challengeWindowCurrent,
        uint256 txSubmissionTimeCurrent,
        uint256 blockTimestamp,
        uint8 challengesLevel
    ) external pure returns (bool isChallengeOver, uint8 actualLevel);

    /**
    * @dev Pure function to compute if the current challenge is settled already,
           or if due to time passing, one or more challenges have been tacitly accepted.
           In such case, the challenge processs reduces 2 levels per challenge accepted.
           inputs:
            currentTime: now, in secs, as return by block.timstamp
            lastChallTime: time at which the last challenge was received (at level 0, time of submission of ownershipRoot)
            challengeWindow: amount of time available for submitting a new challenge
            writtenLevel: the last stored level of the current challenge game
           returns:
            isSettled: if true, challenges are still accepted
            actualLevel: the level at which the challenge truly is, taking time into account.
            nJumps: the number of challenges tacitly accepted, taking time into account.
    */
    function computeChallStatus(
        uint256 currentTime,
        uint256 lastTxSubmissionTime,
        uint256 lastChallTime,
        uint256 challengeWindow,
        uint8 writtenLevel
    )
        external
        pure
        returns (
            bool isSettled,
            uint8 actualLevel,
            uint8 nJumps
        );
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract for querying and using blackholeId 
 @author Freeverse.io, www.freeverse.io
*/

interface IBlackholeId {

    /**
     * @notice Returns the blackholeId stored in the Storage contract
     *  WARNING: this function can revert if no claims exist in storage,
     *  use hasBlackholeId() before calling this function to avoid unwanted reverts.
     * @return blackholeId the blackholeId
     */
    function blackholeId() external view returns (uint8);

    /**
     * @notice Returns true if the Storage contract stores as claim(0,0)
     *  the expected data for a BlackholeID
     * @return true if the stored blackholeId is as expected
     */
    function hasBlackholeId() external view returns (bool);

    /**
     * @notice Returns true if the provided inputs follow the 
     *  the expected data for a BlackholeID
     * @param number the provided value for blackholeId
     * @param str the provided string that identifies the claim as referring to 'blackholeId'
     * @return true if the provided inputs follow the expected data for a BlackholeID
     */
    function claimIsValidBlackholeID(uint256 number, string memory str) external pure returns (bool);

    /**
     * @notice Reverts unless the Storage contract stores as claim(0,0)
     *  the expected data for a BlackholeID
     */
    function assertValidBlackholeId() external view; 

    /**
     * @notice Returns true if the provided assetId encodes a blackholeId that
     *  matches the provided id 
     * @param assetId the assetId that encodes a certain blackholeId
     * @param id the blackholeId against which to compare
     * @return true if the provided assetId encodes a blackholeId that
     *  matches the provided id
     */
    function hasCorrectBlackholeId(uint256 assetId, uint8 id) external pure returns (bool);

    /**
     * @notice Returns true if the provided assetId encodes a blackholeId that
     *  matches the blackholeId in the Storage contract
     * @param assetId the assetId that encodes a certain blackholeId
     * @return true if the provided assetId encodes a blackholeId that
     *  matches the blackholeId in the Storage contract
     */
    function hasCorrectBlackholeId(uint256 assetId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @author Freeverse.io, www.freeverse.io
 @title Interface to main Contract for exporting Living Assets to Standard Layer-1 ERC721 NFTs
 @dev Asset owners can use the main functions in this contract permissionlessly
*/

interface IAssetExport {
    event NewInfoAddress(address addr);
    event NewERC721Address(address addr);
    event RequestAssetExport(
        uint256 assetId,
        address owner,
        uint256 currentVerse
    );
    event CompleteAssetExport(
        uint256 assetId,
        address owner,
        uint256 currentVerse
    );

    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns the address of the Info contract that
     * this contract can communicate with
     */
    function _info() external view returns (address);

    /**
     * @notice Returns the address of the NFT contract where
     * assets are minted when exported
     */
    function _erc721() external view returns (address);

    /**
     * @notice Returns the address of the Storage contract that
     * this contract can communicate with
     */
    function _sto() external view returns (address);

    /**
     * @notice Requests the export of an assset
     * @dev This if the first step required before exporting asset.
     * It requires the asset not be frozen / in transfer at this moment.
     * It enforces that, as of next verses, the asset will be blocked from trading
     * @param assetId The id of the asset
     * @param marketData The market data of the asset
     * @param assetCID The CID of the asset
     * @param ownershipProof The proof that the asset belongs to the current Ownership tree
     * @param assetPropsProof The proof that the asset properties belong to the current Universe tree
     */
    function requestAssetExport(
        uint256 assetId,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory assetPropsProof
    ) external;

    /**
     * @notice Completes the export of an assset
     * @dev Requires existence of a previous export request
     * It mints a new NFT in the external ERC721 contract
     * with tokenURI = addIPFSPrefix(assetCID)
     * @param assetId The id of the asset
     * @param marketData The market data of the asset
     * @param assetCID The CID of the asset
     * @param ownershipProof The proof that the asset belongs to the current Ownership tree
     * @param assetPropsProof The proof that the asset properties belong to the current Universe tree
     */
    function completeAssetExport(
        uint256 assetId,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory assetPropsProof
    ) external;

    /**
     * @notice Returns true if the token has a non-null owner in the external ERC721 contract
     * @dev If the token has been exported, and then burnt, this function returns false.
     * This is why it is important that "isExported" is stored in the Storage contract.
     * @param assetId The id of the asset
     * @return Returns true if the token has a non-null owner
     */
    function tokenHasOwner(uint256 assetId) external view returns (bool);

    /**
     * @notice Prepends the ipfs prefix to the provided string
     * @param assetCID The CID of the asset
     * @return the prepended string
     */
    function addIPFSPrefix(string memory assetCID)
        external
        pure
        returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;

    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    function baseTokenURI() public pure virtual returns (string memory);

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Contract for NFTs exported from Layer-2
 * @author Freeverse.io, www.freeverse.io
 */

contract ERC721FV is ERC721Tradable {
    /**
     * @notice Mapping from assetID to URI.
     * @dev Ideally, URI is an IPFS address in format ipfs://CID
     */
    mapping(uint256 => string) internal assetURI;

    /**
     * @notice If true, it allows proxy registry to be changed
     */
    bool public isProxyRegistryAddressLocked;

    constructor(string memory _name, string memory _symbol)
        ERC721Tradable(_name, _symbol, address(0))
    {}

    /**
     * @notice Sets a new proxyRegistryAddress after deploy
     * @dev Only possible if isProxyRegistryAddressLocked == false
     */
    function setProxyRegistryAddress(address _newAddr) external onlyOwner {
        require(
            !isProxyRegistryAddressLocked,
            "proxyAddress cannot be modified anymore"
        );
        proxyRegistryAddress = _newAddr;
    }

    /**
     * @dev Avoid any possible future change of proxyRegistry
     */
    function lockProxyRegistryAddress() external onlyOwner {
        isProxyRegistryAddressLocked = true;
    }

    /**
     * @notice Mints a new NFT.
     * @param _to The address that will own the minted NFT.
     * @param _id Unique ID of the NFT to be minted by msg.sender.
     * @param _assetURI The URI with its metadata, ideally an IPFS address
     */
    function mint(
        address _to,
        uint256 _id,
        string calldata _assetURI
    ) external onlyOwner {
        super._mint(_to, _id);
        assetURI[_id] = _assetURI;
    }

    /**
     * @notice Burns an NFT
     * @notice The owner of the NFT can burn permisionlessly
     * @param _id The id of the NFT to burn.
     */
    function burn(uint256 _id) external {
        require(ownerOf(_id) == msg.sender, "msg.sender is not owner of token");
        super._burn(_id);
        delete assetURI[_id];
    }

    /**
        VIEW FUNCTIONS
    */

    /**
     * @notice Returns URI of an NFT
     * @param _id Id for which we want the URI.
     * @return URI corresponding to the NFT.
     */
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        require(exists(_id), "token does not exist");
        return assetURI[_id];
    }

    function proxyRegistry() public view returns (address) {
        return proxyRegistryAddress;
    }

    function exists(uint256 _id) public view returns (bool) {
        return _exists(_id);
    }

    /**
     * @notice Dummy implementation of unused baseTokenURI
     * @dev Required to be implemented by interface
     * @return Always returns an empty string
     */
    function baseTokenURI() public pure override returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}