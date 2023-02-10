// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Contract for querying and using blackholeId 
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IBlackholeId.sol";
import "../interfaces/IStorageGetters.sol";
import "../pure/EncodingAssets.sol";

contract BlackholeId is EncodingAssets, IBlackholeId {

    bytes32 constant internal hashBlackholeId = keccak256(abi.encodePacked('blackholeID')); 
    address private immutable _sto;

    constructor(address storageAddr) {
        _sto = storageAddr;
    }

    /// @inheritdoc IBlackholeId
    function blackholeId() public view returns (uint8) {
        (uint256 verse, ) = IStorageGetters(_sto).claim(0, 0);
        return uint8(verse);
    }

    /// @inheritdoc IBlackholeId
    function hasBlackholeId() public view returns (bool) {
        if (IStorageGetters(_sto).nClaims() == 0) return false;
        (uint256 verse, string memory str) = IStorageGetters(_sto).claim(0, 0);
        return claimIsValidBlackholeID(verse, str);
    }

    /// @inheritdoc IBlackholeId
    function claimIsValidBlackholeID(uint256 verse, string memory str) public pure returns (bool) {
        return (keccak256(abi.encodePacked(str)) == hashBlackholeId) && (verse < 256);
    }

    /// @inheritdoc IBlackholeId
    function assertValidBlackholeId() public view {
        require( 
            hasBlackholeId(),
            "BlackholeId::assertValidBlackholeId: invalid BlackholeId"            
        );
    }

    /// @inheritdoc IBlackholeId
    function hasCorrectBlackholeId(uint256 assetId, uint8 id) public pure returns (bool) {
        return decodeBlackholeId(assetId) == id;
    }

    /// @inheritdoc IBlackholeId
    function hasCorrectBlackholeId(uint256 assetId) public view returns (bool) {
        return decodeBlackholeId(assetId) == blackholeId();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Main serialization/deserialization of data into an assetId
 @author Freeverse.io, www.freeverse.io
 @dev Convention: 'idx' for labeling consecutive integers, 'id' for generic non-consecutive integers
 @dev assetId = (from left ro right in binary representation)
 @dev  version(8b) + universeIdx(24) + isImmutable(1b) + isUntradable(1b) + blackholeId(8b) + editionIdx(16b) + assetIdx(38b) + initOwner(160b)
*/

contract EncodingAssets {
    function encodeAssetId(
        uint256 universeIdx,
        uint256 blackholeId,
        uint256 editionIdx,
        uint256 assetIdx,
        address initOwner,
        bool isImmutable,
        bool isUntradable
    ) public pure returns (uint256) {
        require(
            universeIdx >> 24 == 0,
            "universeIdx cannot be larger than 24 bit"
        );
        require(assetIdx >> 38 == 0, "assetIdx cannot be larger than 38 bit");
        require(blackholeId >> 8 == 0, "blackholeId cannot be larger than 8 bit");
        require(editionIdx >> 16 == 0, "editionIdx cannot be larger than 16 bit");
        return ((universeIdx << 224) |
            (uint256(isImmutable ? 1 : 0) << 223) |
            (uint256(isUntradable ? 1 : 0) << 222) |
            (blackholeId << 214) |
            (editionIdx << 198) |
            (assetIdx << 160) |
            uint256(uint160(initOwner)));
    }

    function decodeIsImmutable(uint256 assetId)
        public
        pure
        returns (bool isImmutable)
    {
        return ((assetId >> 223) & 1) == 1;
    }

    function decodeIsUntradable(uint256 assetId)
        public
        pure
        returns (bool isUntradable)
    {
        return ((assetId >> 222) & 1) == 1;
    }

    function decodeEditionIdx(uint256 assetId)
        public
        pure
        returns (uint32 editionIdx)
    {
        return uint32((assetId >> 198) & 65535); // 2**16 - 1
    }

    function decodeBlackholeId(uint256 assetId)
        public
        pure
        returns (uint32 blackholeId)
    {
        return uint8((assetId >> 214) & 255); // 2**8 - 1
    }

    function decodeOwner(uint256 assetId)
        public
        pure
        returns (address initOwner)
    {
        return
            address(
                uint160(
                    assetId & 1461501637330902918203684832716283019655932542975
                )
            ); // 2**160 - 1
    }

    function decodeAssetIdx(uint256 assetId)
        public
        pure
        returns (uint256 assetIdx)
    {
        return (assetId >> 160) & 274877906943; // 2**38-1
    }

    function decodeUniverseIdx(uint256 assetId)
        public
        pure
        returns (uint256 assetIdx)
    {
        return (assetId >> 224);
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