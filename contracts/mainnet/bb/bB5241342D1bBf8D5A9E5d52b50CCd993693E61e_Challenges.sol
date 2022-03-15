// SPDX-License-Identifier: BUSL-1.1
// License details specified at address returned by calling the function: license()
pragma solidity =0.8.11;

/**
 @title Entry point for challenges of submitted roots
 @author Freeverse.io, www.freeverse.io
 @dev When a challenge is accepted, it communicates with the Stakers contract,
 @dev which is responsible for managing stakes and rewards accordingly
*/

import "../interfaces/IWriter.sol";
import "../interfaces/IStorageGetters.sol";
import "../interfaces/IInfo.sol";
import "../interfaces/IChallenges.sol";

import "../pure/serialization/SerializeBuyNowGet.sol";
import "../pure/serialization/SerializeCompleteGet.sol";
import "../pure/serialization/SerializeFreezeGet.sol";
import "../pure/serialization/SerializeOwnershipGet.sol";
import "../pure/Constants.sol";
import "../pure/MerkleSerialized.sol";
import "../pure/ChallengeLibFreeze.sol";
import "../pure/ChallengeLibComplete.sol";
import "../pure/ChallengeLibBuyNow.sol";

contract Challenges is
    IChallenges,
    Constants,
    MerkleSerialized,
    SerializeCompleteGet,
    SerializeFreezeGet,
    SerializeOwnershipGet,
    SerializeBuyNowGet
{
    /// @inheritdoc IChallenges
    address public _sto;
    /// @inheritdoc IChallenges
    address public _writer;
    /// @inheritdoc IChallenges
    address public _info;
    /// @inheritdoc IChallenges
    address public _freezelib;
    /// @inheritdoc IChallenges
    address public _completelib;
    /// @inheritdoc IChallenges
    address public _buyNowlib;

    modifier onlySuperUser() {
        require(
            msg.sender == IStorageGetters(_sto).superUser(),
            "Only superUser is authorized."
        );
        _;
    }

    constructor(
        address storageAddress,
        address chalibFreeze,
        address chalibComplete,
        address chalibBuyNow,
        address info,
        address writer
    ) {
        _sto = storageAddress;
        _freezelib = chalibFreeze;
        _completelib = chalibComplete;
        _buyNowlib = chalibBuyNow;
        _info = info;
        _writer = writer;
    }

    /// @inheritdoc IChallenges
    function license() external view returns (string memory) {
        return IStorageGetters(_sto).license();
    }

    /// @inheritdoc IChallenges
    function challToNextLevel(
        bytes memory challengedLeafData,
        bytes memory leftOfChallengedLeafData,
        bytes memory nextLevelEdgeTransRootData,
        bytes32[] memory nextLevelTransRoots,
        bytes32 newOwnershipRoot
    ) public {
        require(
            IInfo(_info).isReadyForChallenge(),
            "verse settled hence too late to challenge, or verse with 0 TXs"
        );

        // First, take time into account to see if some previous challenges have been tacitly accepted,
        // in which case, some provided-roots needs to be removed.
        (
            uint8 level,
            uint8 levelVerifableOnChain
        ) = _processLevelsResolvedByTime();
        require(level > 0, "expected submitNewOwnership first");
        require(
            level + 1 < levelVerifableOnChain,
            "function to be called for non-on-chain-verifiable challenges"
        );

        require(
            nextLevelTransRoots.length ==
                IStorageGetters(_sto).nLeavesPerChallengeCurrent(),
            "incorrect length of provided leaves"
        );

        bytes32 rootOfNextLevelTransRoots = merkleRoot(
            nextLevelTransRoots,
            IStorageGetters(_sto).nLevelsPerChallengeCurrent()
        );
        bytes32 rootAtEdge;
        uint256 challPos;

        if (level == 1) {
            require(
                newOwnershipRoot != bytes32(0x0),
                "newOwnershipRoot cannot be null when challenging level 1"
            );
            require(
                newOwnershipRoot !=
                    IStorageGetters(_sto).challengesOwnershipRoot(0),
                "newOwnershipRoot cannot be the same as provided by initial submitter"
            );
            require(
                rootOfNextLevelTransRoots != bytes32(0x0),
                "rootOfNextLevelTransRoots provided at level 1 cannot be null"
            );
            require(
                challengedLeafData.length == 0,
                "challengedLeafData data should not be present when challenging level 1"
            );
            require(
                leftOfChallengedLeafData.length == 0,
                "leftOfChallengedLeafData should not be present when challenging level 1"
            );
            require(
                nextLevelEdgeTransRootData.length == 0,
                "nextLevelEdgeTransRootData data should not be present when challenging level 1"
            );
        } else {
            bytes32 prevTransRoot = IStorageGetters(_sto)
                .challengesTransitionsRoot(level - 1);
            require(
                newOwnershipRoot == bytes32(0x0),
                "newOwnershipRoot must be null when challenging level > 1"
            );
            require(
                rootOfNextLevelTransRoots != MTLeaf(challengedLeafData),
                "you are declaring that the provided leaves lead to same root being challenged"
            );
            require(
                MTVerifySerialized(prevTransRoot, challengedLeafData),
                "merkle proof not correct"
            );
            challPos = MTPos(challengedLeafData);
            if (
                IStorageGetters(_sto).areAllChallengePosZero() &&
                (challPos == 0)
            ) {
                // Case 3 above
                require(
                    leftOfChallengedLeafData.length == 0,
                    "leftOfChallengedLeafData should not be present when challenging left-most root"
                );
                require(
                    nextLevelEdgeTransRootData.length == 0,
                    "nextLevelEdgeTransRootData data should not be present when challenging left-most root"
                );
            } else {
                if (challPos == 0) {
                    // Case 2 above
                    // verify the the root inside nextLevelEdgeTransRootData is at last pos of the tree under MTLeaf(leftOfChallengedLeafData)
                    require(
                        leftOfChallengedLeafData.length == 0,
                        "leftOfChallengedLeafData should not be present when challenging root at pos = 0"
                    );
                    require(
                        MTPos(nextLevelEdgeTransRootData) ==
                            IStorageGetters(_sto).nLeavesPerChallengeCurrent() -
                                1,
                        "single merkle leave pos should be the last possible"
                    );
                    require(
                        MTVerifySerialized(
                            IStorageGetters(_sto).challengesRootAtEdge(level),
                            nextLevelEdgeTransRootData
                        ),
                        "merkle proof not correct for single previous leave at pos = 0"
                    );
                } else {
                    // Case 1 above
                    // Verify the the root inside leftOfChallengedLeafData is at pos = challenged leave - 1, and that it belongs to the same written root
                    require(
                        MTPos(leftOfChallengedLeafData) + 1 == challPos,
                        "prev merkle proof pos is not the previous one"
                    );
                    require(
                        MTVerifySerialized(
                            prevTransRoot,
                            leftOfChallengedLeafData
                        ),
                        "merkle proof not correct for previous leave"
                    );
                    // Verify the the root inside nextLevelEdgeTransRootData is at last pos of the tree under MTLeaf(leftOfChallengedLeafData)
                    require(
                        MTPos(nextLevelEdgeTransRootData) ==
                            IStorageGetters(_sto).nLeavesPerChallengeCurrent() -
                                1,
                        "single merkle leave pos should be the last possible"
                    );
                    require(
                        MTVerifySerialized(
                            MTLeaf(leftOfChallengedLeafData),
                            nextLevelEdgeTransRootData
                        ),
                        "merkle proof not correct for single previous leave at pos != 0"
                    );
                }
                rootAtEdge = MTLeaf(nextLevelEdgeTransRootData);
            }
        }
        // Accept the challenge and store new roots
        IWriter(_writer).pushChallenge(
            newOwnershipRoot,
            rootOfNextLevelTransRoots,
            rootAtEdge,
            challPos
        );
        IWriter(_writer).setLastOwnershipSubmissiontime(block.timestamp);
        IWriter(_writer).addChallenge(level, msg.sender);
        emit ChallengeAccepted(
            level,
            rootOfNextLevelTransRoots,
            nextLevelTransRoots,
            newOwnershipRoot,
            rootAtEdge,
            challPos
        );
    }

    /// @inheritdoc IChallenges
    function challToNextLevelFromPreviousPos(
        uint8 challengedLevel,
        bytes calldata challengedLeafData,
        bytes calldata leftOfChallengedLeafData,
        bytes calldata nextLevelEdgeTransRootData,
        bytes32[] calldata nextLevelTransRoots,
        bytes32 newOwnershipRoot
    ) external {
        require(
            IInfo(_info).isReadyForChallenge(),
            "verse settled hence too late to challenge, or verse with 0 TXs"
        );

        // First, take time into account to see if some previous challenges have been tacitly accepted,
        // in which case, some provided-roots needs to be removed.
        (
            uint8 level,
            uint8 levelVerifableOnChain
        ) = _processLevelsResolvedByTime();
        require(level > 0, "expected submitNewOwnership first");
        require(
            level + 1 < levelVerifableOnChain,
            "function to be called for non-on-chain-verifiable challenges"
        );
        require(
            challengedLevel <= level,
            "you can only challToNextLevelFromPreviousPos a lower still-challengeable level"
        );
        require(
            MTPos(challengedLeafData) <
                IStorageGetters(_sto).challengesPos(challengedLevel),
            "you can only challToNextLevelFromPreviousPos a lower pos"
        );
        IWriter(_writer).popChallengeDataToLevel(challengedLevel - 1);
        IWriter(_writer).rewindToLevel(challengedLevel - 1);
        challToNextLevel(
            challengedLeafData,
            leftOfChallengedLeafData,
            nextLevelEdgeTransRootData,
            nextLevelTransRoots,
            newOwnershipRoot
        );
    }

    /// @inheritdoc IChallenges
    function challVerifiableOnChain(
        bytes memory txData,
        bytes memory initOwnershipData,
        bytes memory challengedOwnershipData,
        bytes memory initOwnershipRaw
    ) external {
        require(
            IInfo(_info).isReadyForChallenge(),
            "verse settled hence too late to challenge, or verse with 0 TXs"
        );

        // First, take time into account to see if some previous challenges have been tacitly accepted,
        // in which case, some provided-roots needs to be removed.
        (
            uint8 level,
            uint8 levelVerifableOnChain
        ) = _processLevelsResolvedByTime();
        require(
            level + 1 == levelVerifableOnChain,
            "function only for on-chain-verifiable challenges"
        );

        // Compute the position of the ownership root at the very bottom of the tree:
        uint256 challengedOwnershipPos = MTPos(challengedOwnershipData);
        uint256 bottomLeafPos = IStorageGetters(_sto).computeBottomLevelLeafPos(
            challengedOwnershipPos
        );
        require(
            bottomLeafPos < IStorageGetters(_sto).nTXsCurrent(),
            "leafPos larger than nTXs"
        );

        // Revert unless the data provided for on-chain verification matches the requirements:
        bytes32 initOwnershipRoot = ChallengeLibFreeze(_freezelib)
            .verifyOwnershipData(
                IStorageGetters(_sto).challengesTransitionsRoot(level - 1),
                IStorageGetters(_sto).areAllChallengePosZero(),
                IStorageGetters(_sto).challengesRootAtEdge(level - 1),
                IStorageGetters(_sto).ownershipRootCurrent(),
                initOwnershipData,
                challengedOwnershipData,
                challengedOwnershipPos,
                initOwnershipRaw
            );

        // The next steps depend on the TX type (Freeze or Complete)
        // In either type, first revert unless the TX meets the requirements.
        // Then, we have full certainty that all raw data provided (inside TX and initOwnership) is legit,
        // and therefore the challengedOwnershipRoot is deterministic:
        // - identical to initOwnershipRoot is the seller/buyer signature is not correct, time constraints are OK, etc.
        // - corresponding to a new state or owner otherwise.
        uint256 assetId = ownAssetId(initOwnershipRaw);
        bool isTXValid;
        require(
            txGetType(txData) <= TX_IDX_BUYNOW,
            "txType larger than allowed"
        );
        if (txGetType(txData) == TX_IDX_FREEZE) {
            ChallengeLibFreeze(_freezelib).verifyFreezeTXData(
                txData,
                bottomLeafPos,
                assetId,
                IStorageGetters(_sto).txRootCurrent()
            );
            isTXValid = ChallengeLibFreeze(_freezelib).isFreezeValidSerialized(
                IStorageGetters(_sto).txRootsCurrentVerse(),
                txData,
                initOwnershipRaw
            );
        }
        if (txGetType(txData) == TX_IDX_COMPLETE) {
            ChallengeLibComplete(_completelib).verifyCompleteTXData(
                txData,
                bottomLeafPos,
                assetId,
                IStorageGetters(_sto).txRootCurrent()
            );

            bytes32 universeRoot = IStorageGetters(_sto).universeRootAtVerse(
                ChallengeLibFreeze(_freezelib).decodeUniverseIdx(assetId),
                complTXAssetPropsVerse(txData)
            );

            isTXValid = ChallengeLibComplete(_completelib)
                .isCompleteValidSerialized(
                    IStorageGetters(_sto).txRootsCurrentVerse(),
                    txData,
                    initOwnershipRaw
                );
            isTXValid =
                isTXValid &&
                ChallengeLibComplete(_completelib).complTXCertifyAssetProps(
                    universeRoot,
                    txData
                );
        }
        if (txGetType(txData) == TX_IDX_BUYNOW) {
            ChallengeLibBuyNow(_buyNowlib).verifyBuyNowTXData(
                txData,
                bottomLeafPos,
                assetId,
                IStorageGetters(_sto).txRootCurrent()
            );

            bytes32 universeRoot = IStorageGetters(_sto).universeRootAtVerse(
                ChallengeLibFreeze(_freezelib).decodeUniverseIdx(assetId),
                buyNowTXAssetPropsVerse(txData)
            );

            isTXValid = ChallengeLibBuyNow(_buyNowlib).isBuyNowValidSerialized(
                IStorageGetters(_sto).txRootsCurrentVerse(),
                txData,
                initOwnershipRaw
            );
            isTXValid =
                isTXValid &&
                ChallengeLibBuyNow(_buyNowlib).buyNowTXCertifyAssetProps(
                    universeRoot,
                    txData
                );
        }
        // Further check that the asset was not already blocked due to export request/completion
        // or by an untradable mark set on asset creation
        isTXValid =
            isTXValid &&
            !IInfo(_info).isAssetBlockedByExport(
                assetId,
                ownOwner(initOwnershipRaw)
            ) &&
            !ChallengeLibFreeze(_freezelib).decodeIsUntradable(assetId);
        // Finally compare expected root against challenged root. Reverts if there is match.
        requireEndStateCorrect(
            txData,
            initOwnershipRaw,
            initOwnershipRoot,
            MTLeaf(challengedOwnershipData),
            isTXValid
        );
        // Challenger successfully proved wrong challenged root. Update storage and stakers.
        _completeSuccessfulOnChainChallenge(level);
    }

    /// @inheritdoc IChallenges
    function challProvidedFinalRoot(
        bytes memory lastOwnershipInTransitionsTreeData
    ) external {
        require(
            IInfo(_info).isReadyForChallenge(),
            "verse settled hence too late to challenge, or verse with 0 TXs"
        );

        // First, take time into account to see if some previous challenges have been tacitly accepted,
        // in which case, some provided-roots needs to be removed.
        (uint8 level, ) = _processLevelsResolvedByTime();
        // Current level can be any thing beyond challengedLevel.
        // ChallengedLevel must be 1 or 2, where the ownershipRoots are provided separately.
        require(
            level >= 2,
            "challProvidedFinalRoot: current level must be at least 2"
        );

        bytes32 topTransitionsRoot = IStorageGetters(_sto)
            .challengesTransitionsRoot(1);

        // Require that the provided last entry actually differs from the challenged one.
        require(
            IStorageGetters(_sto).challengesOwnershipRoot(1) !=
                MTLeaf(lastOwnershipInTransitionsTreeData),
            "provided ownership root coincides with previous update"
        );

        // Require that the provided last entry is actually the last entry, according to the nTXs in the TXBatch.
        require(
            IStorageGetters(_sto).nTXsCurrent() ==
                (1 + MTPos(lastOwnershipInTransitionsTreeData)),
            "provided pos must equal NTXs-1 for an explicit ownership challenge"
        );

        // Require that the provided last entry is in the transitionsRoot provided earlier alongside the ownershipRoot
        require(
            MTVerifySerialized(
                topTransitionsRoot,
                lastOwnershipInTransitionsTreeData
            ),
            "provided merkle proof does not belong to parent root"
        );

        // Challenge is successful. If executed several levels after the challenged level, reset to challenged level
        if (level > 2) {
            IWriter(_writer).popChallengeDataToLevel(2);
            IWriter(_writer).rewindToLevel(2);
        }
        _completeSuccessfulOnChainChallenge(2);
    }

    /**
    @dev When an on-chain challenge is successful: 
         inform stakers, update storage structs, update timestamp, emit.
    */
    function _completeSuccessfulOnChainChallenge(uint8 challengedLevel)
        private
    {
        IWriter(_writer).popChallengeDataToLevel(challengedLevel - 1);
        IWriter(_writer).addChallenge(challengedLevel, msg.sender);
        IWriter(_writer).resolveToLevel(challengedLevel - 1);
        uint256 timeStamp = block.timestamp;
        IWriter(_writer).setLastOwnershipSubmissiontime(timeStamp);
        emit ChallengeResolved(challengedLevel + 1, true, timeStamp);
        emit ChallengeResolved(challengedLevel, false, timeStamp);
    }

    /**
    @dev Accounting for the current timestamp, some (or all) challenges may have been accepted implicitly,
         due to lack of further challenges during the available challenge window.
         If so, inform the stakers contract, and clean challenge data up to the current level.
    */
    function _processLevelsResolvedByTime()
        private
        returns (uint8 level, uint8 levelVerifableOnChain)
    {
        level = IStorageGetters(_sto).challengesLevel();
        levelVerifableOnChain = IStorageGetters(_sto)
            .levelVerifiableOnChainCurrent();

        // actualLevel is the actual level at which we are, after having time passed into account;
        // if some challenges are approved tacitly, there will be "jumps up" in the challenge state machine.
        (, uint8 actualLevel, uint8 nJumps) = IInfo(_info).computeChallStatus(
            IStorageGetters(_sto).nTXsCurrent(),
            block.timestamp,
            IStorageGetters(_sto).txSubmissionTimeCurrent(),
            IStorageGetters(_sto).ownershipSubmissionTimeCurrent(),
            IStorageGetters(_sto).challengeWindowCurrent(),
            level
        );

        // if there were 0 jumps, do nothing
        if (nJumps == 0) return (level, levelVerifableOnChain);

        // otherwise clean all data except above the actualLevel
        require(
            level == actualLevel + 2 * nJumps,
            "challenge status: nJumps incompatible with writtenLevel and actualLevel"
        );
        for (uint8 j = 0; j < nJumps; j++) {
            uint8 levelAccepted = actualLevel + 2 * (j + 1);
            uint256 timeStamp = block.timestamp;
            emit ChallengeResolved(levelAccepted, true, timeStamp);
            emit ChallengeResolved(levelAccepted - 1, false, timeStamp);
        }
        IWriter(_writer).popChallengeDataToLevel(actualLevel);
        IWriter(_writer).resolveToLevel(actualLevel);
        level = actualLevel;
    }

    // VIEW FUNCTIONS

    /// @inheritdoc IChallenges
    function requireEndStateCorrect(
        bytes memory txData,
        bytes memory initOwnershipRaw,
        bytes32 initOwnershipRoot,
        bytes32 challengedOwnershipRoot,
        bool isTXValid
    ) public view {
        if (isTXValid) {
            // check that applying the TX to initRoot led to a new root that does not match the submitted root.
            require(
                challengedOwnershipRoot !=
                    ChallengeLibComplete(_completelib)
                        .updateOwnershipTreeSerialized(
                            txData,
                            initOwnershipRaw
                        ),
                "the obtained final ownership state matches the one provided by previous challenger"
            );
        } else {
            // check that applying the TX to initRoot led to a new root that does not match the submitted root.
            require(
                challengedOwnershipRoot != initOwnershipRoot,
                "the obtained final ownership state matches the initial one, which was expected because TX could not be applied."
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Simple tool common to serialization functions
 @author Freeverse.io, www.freeverse.io
*/

contract SerializeSettersBase {
    function addToSerialization(
        bytes memory serialized,
        bytes memory s,
        uint256 counter
    ) public pure returns (uint256 newCounter) {
        for (uint256 i = 0; i < s.length; i++) {
            serialized[counter] = s[i];
            counter++;
        }
        return counter++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Deserialization of Ownership parameters
 @author Freeverse.io, www.freeverse.io
*/

import "./SerializeBase.sol";

contract SerializeOwnershipGet is SerializeBase {
    function ownAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 40))
        }
    }

    function ownOwner(bytes memory serialized)
        public
        pure
        returns (address owner)
    {
        assembly {
            owner := mload(add(serialized, 60))
        }
    }

    function ownMarketData(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 marketDataLength;
        assembly {
            marketDataLength := mload(add(serialized, 4))
        }
        bytes memory marketData = new bytes(marketDataLength);
        for (uint32 i = 0; i < marketDataLength; i++) {
            marketData[i] = serialized[60 + i];
        }
        return marketData;
    }

    function ownProof(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 marketDataLength;
        assembly {
            marketDataLength := mload(add(serialized, 4))
        }
        uint32 proofLength;
        assembly {
            proofLength := mload(add(serialized, 8))
        }
        bytes memory proof = new bytes(proofLength);
        for (uint32 i = 0; i < proofLength; i++) {
            proof[i] = serialized[60 + marketDataLength + i];
        }
        return proof;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Deserialization of Merkle Tree parameters
 @author Freeverse.io, www.freeverse.io
*/

import "./SerializeBase.sol";

contract SerializeMerkleGet is SerializeBase {
    // Merkle Proof Getters (for transition proofs, merkle proofs in general)
    function MTPos(bytes memory serialized) public pure returns (uint256 pos) {
        assembly {
            pos := mload(add(serialized, 32))
        }
    }

    function MTLeaf(bytes memory serialized)
        public
        pure
        returns (bytes32 root)
    {
        assembly {
            root := mload(add(serialized, 64))
        } // 8 + 2 * 32
    }

    function MTProof(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        // total length = 32 * 2 + 32 * nEntries
        uint32 nEntries = (uint32(serialized.length) - 64) / 32;
        require(
            serialized.length == 32 * 2 + 32 * nEntries,
            "incorrect serialized length"
        );
        return bytesToBytes32ArrayWithoutHeader(serialized, 64, nEntries);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Serialization of MarketData parameters
 @author Freeverse.io, www.freeverse.io
 @dev ValidUntil and TimeToPay are expressed in units of verse
*/

import "./SerializeSettersBase.sol";

contract SerializeMarketDataSet is SerializeSettersBase {
    function serializeMarketData(
        bytes32 auctionId,
        uint32 validUntil,
        uint32 versesToPay
    ) public pure returns (bytes memory serialized) {
        serialized = new bytes(32 + 4 * 2);
        uint256 counter = 0;
        counter = addToSerialization(
            serialized,
            abi.encodePacked(auctionId),
            counter
        ); // 32
        counter = addToSerialization(
            serialized,
            abi.encodePacked(validUntil),
            counter
        ); // 36
        counter = addToSerialization(
            serialized,
            abi.encodePacked(versesToPay),
            counter
        ); // 40
        return (serialized);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title DeSerialization of MarketData parameters
 @author Freeverse.io, www.freeverse.io
*/

import "./SerializeBase.sol";

contract SerializeMarketDataGet is SerializeBase {
    function marketDataNeverTraded(bytes memory marketData)
        public
        pure
        returns (bool hasBeenInMarket)
    {
        return marketData.length == 0;
    }

    function marketDataAuctionId(bytes memory marketData)
        public
        pure
        returns (bytes32 auctionId)
    {
        assembly {
            auctionId := mload(add(marketData, 32))
        }
    }

    function marketDataValidUntil(bytes memory marketData)
        public
        pure
        returns (uint32 validUntil)
    {
        assembly {
            validUntil := mload(add(marketData, 36))
        }
    }

    function marketDataTimeToPay(bytes memory marketData)
        public
        pure
        returns (uint32 versesToPay)
    {
        assembly {
            versesToPay := mload(add(marketData, 40))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title DeSerialization of FreezeTX parameters
 @author Freeverse.io, www.freeverse.io
*/

import "./SerializeBase.sol";

contract SerializeFreezeGet is SerializeBase {
    // Transactions Getters

    function freezeTXPosTX(bytes memory serialized)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(serialized, 41))
        } // 1+8 + 32
    }

    function freezeTXSellerHiddenPrice(bytes memory serialized)
        public
        pure
        returns (bytes32 sellerHiddenPrice)
    {
        assembly {
            sellerHiddenPrice := mload(add(serialized, 73))
        } // 1+8 + 2 * 32
    }

    function freezeTXAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 105))
        } // 1+8 + 3 *32
    }

    function freezeTXValidUntil(bytes memory serialized)
        public
        pure
        returns (uint32 validUntil)
    {
        assembly {
            validUntil := mload(add(serialized, 109))
        } // + 4
    }

    function freezeTXOfferValidUntil(bytes memory serialized)
        public
        pure
        returns (uint32 offerValidUntil)
    {
        assembly {
            offerValidUntil := mload(add(serialized, 113))
        } // +4
    }

    function freezeTXTimeToPay(bytes memory serialized)
        public
        pure
        returns (uint32 versesToPay)
    {
        assembly {
            versesToPay := mload(add(serialized, 117))
        } // +4
    }

    function freezeTXSellerSig(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 signatureLength;
        assembly {
            signatureLength := mload(add(serialized, 5))
        }
        bytes memory signature = new bytes(signatureLength);
        for (uint32 i = 0; i < signatureLength; i++) {
            signature[i] = serialized[117 + i];
        }
        return signature;
    }

    function freezeTXProofTX(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        uint32 signatureLength;
        assembly {
            signatureLength := mload(add(serialized, 5))
        }
        uint32 nEntries;
        assembly {
            nEntries := mload(add(serialized, 9))
        }
        return
            bytesToBytes32ArrayWithoutHeader(
                serialized,
                117 + signatureLength,
                nEntries
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title DeSerialization of CompleteTX parameters
 @author Freeverse.io, www.freeverse.io
*/

import "./SerializeBase.sol";

contract SerializeCompleteGet is SerializeBase {
    // CompleteAuction TX getters

    function complTXAssetPropsVerse(bytes memory serialized)
        public
        pure
        returns (uint256 assetPropsVerse)
    {
        assembly {
            assetPropsVerse := mload(add(serialized, 49))
        }
    }

    function complTXPosTX(bytes memory serialized)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(serialized, 81))
        }
    }

    function complTXAuctionId(bytes memory serialized)
        public
        pure
        returns (bytes32 auctionId)
    {
        assembly {
            auctionId := mload(add(serialized, 113))
        }
    }

    function complTXAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 145))
        }
    }

    function complTXBuyerHiddenPrice(bytes memory serialized)
        public
        pure
        returns (bytes32 buyerHiddenPrice)
    {
        assembly {
            buyerHiddenPrice := mload(add(serialized, 177))
        }
    }

    function complTXAssetCID(bytes memory serialized)
        public
        pure
        returns (string memory assetCID)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        bytes memory assetCIDbytes = new bytes(assetCIDlen);
        for (uint32 i = 0; i < assetCIDlen; i++) {
            assetCIDbytes[i] = serialized[177 + i];
        }
        return string(assetCIDbytes);
    }

    function complTXProofProps(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }

        bytes memory proofProps = new bytes(proofPropsLen);
        for (uint32 i = 0; i < proofPropsLen; i++) {
            proofProps[i] = serialized[177 + assetCIDlen + i];
        }
        return proofProps;
    }

    function complTXBuyerSig(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sigLength;
        assembly {
            sigLength := mload(add(serialized, 13))
        }
        bytes memory signature = new bytes(sigLength);
        for (uint32 i = 0; i < sigLength; i++) {
            signature[i] = serialized[177 + assetCIDlen + proofPropsLen + i];
        }
        return signature;
    }

    function complTXProofTX(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sigLength;
        assembly {
            sigLength := mload(add(serialized, 13))
        }
        uint32 nEntries;
        assembly {
            nEntries := mload(add(serialized, 17))
        }
        return
            bytesToBytes32ArrayWithoutHeader(
                serialized,
                177 + assetCIDlen + proofPropsLen + sigLength,
                nEntries
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title DeSerialization of BuynowTX parameters
 @author Freeverse.io, www.freeverse.io
*/

import "./SerializeBase.sol";

contract SerializeBuyNowGet is SerializeBase {
    // CompleteAuction TX getters

    function buyNowTXAssetPropsVerse(bytes memory serialized)
        public
        pure
        returns (uint256 assetPropsVerse)
    {
        assembly {
            assetPropsVerse := mload(add(serialized, 53))
        }
    }

    function buyNowTXPosTX(bytes memory serialized)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(serialized, 85))
        }
    }

    function buyNowTXValidUntil(bytes memory serialized)
        public
        pure
        returns (uint32 validUntil)
    {
        assembly {
            validUntil := mload(add(serialized, 89))
        }
    }

    function buyNowTXAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 121))
        }
    }

    function buyNowTXHiddenPrice(bytes memory serialized)
        public
        pure
        returns (bytes32 buyerHiddenPrice)
    {
        assembly {
            buyerHiddenPrice := mload(add(serialized, 153))
        }
    }

    function buyNowTXAssetCID(bytes memory serialized)
        public
        pure
        returns (string memory assetCID)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        bytes memory assetCIDbytes = new bytes(assetCIDlen);
        for (uint32 i = 0; i < assetCIDlen; i++) {
            assetCIDbytes[i] = serialized[153 + i];
        }
        return string(assetCIDbytes);
    }

    function buyNowTXProofProps(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }

        bytes memory proofProps = new bytes(proofPropsLen);
        for (uint32 i = 0; i < proofPropsLen; i++) {
            proofProps[i] = serialized[153 + assetCIDlen + i];
        }
        return proofProps;
    }

    function buyNowTXSellerSig(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sellerSigLength;
        assembly {
            sellerSigLength := mload(add(serialized, 13))
        }
        bytes memory signature = new bytes(sellerSigLength);
        for (uint32 i = 0; i < sellerSigLength; i++) {
            signature[i] = serialized[153 + assetCIDlen + proofPropsLen + i];
        }
        return signature;
    }

    function buyNowTXBuyerSig(bytes memory serialized)
        public
        pure
        returns (bytes memory)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sellerSigLength;
        assembly {
            sellerSigLength := mload(add(serialized, 13))
        }
        uint32 buyerSigLength;
        assembly {
            buyerSigLength := mload(add(serialized, 17))
        }
        bytes memory signature = new bytes(buyerSigLength);
        uint32 offset = 153 + assetCIDlen + proofPropsLen + sellerSigLength;
        for (uint32 i = 0; i < buyerSigLength; i++) {
            signature[i] = serialized[offset + i];
        }
        return signature;
    }

    function buyNowTXProofTX(bytes memory serialized)
        public
        pure
        returns (bytes32[] memory proof)
    {
        uint32 assetCIDlen;
        assembly {
            assetCIDlen := mload(add(serialized, 5))
        }
        uint32 proofPropsLen;
        assembly {
            proofPropsLen := mload(add(serialized, 9))
        }
        uint32 sellerSigLength;
        assembly {
            sellerSigLength := mload(add(serialized, 13))
        }
        uint32 buyerSigLength;
        assembly {
            buyerSigLength := mload(add(serialized, 17))
        }
        uint32 nEntries;
        assembly {
            nEntries := mload(add(serialized, 21))
        }
        uint32 offset = 153 +
            assetCIDlen +
            proofPropsLen +
            sellerSigLength +
            buyerSigLength;
        return bytesToBytes32ArrayWithoutHeader(serialized, offset, nEntries);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Common tool for serilization/deserialization functions
 @author Freeverse.io, www.freeverse.io
*/

contract SerializeBase {
    // For all types of txs you always start with 1 byte for tx type:
    function txGetType(bytes memory serialized)
        public
        pure
        returns (uint8 txType)
    {
        assembly {
            txType := mload(add(serialized, 1))
        }
    }

    function bytesToBytes32ArrayWithoutHeader(
        bytes memory input,
        uint256 offset,
        uint32 nEntries
    ) public pure returns (bytes32[] memory) {
        bytes32[] memory output = new bytes32[](nEntries);

        for (uint32 p = 0; p < nEntries; p++) {
            offset += 32;
            bytes32 thisEntry;
            assembly {
                thisEntry := mload(add(input, offset))
            }
            output[p] = thisEntry;
        }
        return output;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title DeSerialization of Asset Properties parameters
 @author Freeverse.io, www.freeverse.io
*/

import "./SerializeBase.sol";

contract SerializeAssetPropsGet is SerializeBase {
    function assetPropsPos(bytes memory assetProps)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(assetProps, 32))
        }
    }

    function assetPropsProof(bytes memory assetProps)
        public
        pure
        returns (bytes32[] memory proof)
    {
        if (assetProps.length == 0) return new bytes32[](0);
        // Length must be a multiple of 32, and less than 2**32.
        require(
            (assetProps.length >= 32) && (assetProps.length < 4294967296),
            "assetProps length beyond boundaries"
        );
        // total length = 32 + 32 * nEntries
        uint32 nEntries = (uint32(assetProps.length) - 32) / 32;
        require(
            assetProps.length == 32 + 32 * nEntries,
            "incorrect assetProps length"
        );
        return bytesToBytes32ArrayWithoutHeader(assetProps, 32, nEntries);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// License details specified at ipfs://QmSiTS1wfYqwjoU8coz6U327AEsJ6iSVSccUdz7MJapA7C
// with possible additions as returned by calling the function license()
// from the main storage contract
pragma solidity =0.8.11;

/**
 @title Sparse Merkle Tree functions
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/ISparseMerkleTree.sol";

contract SparseMerkleTree is ISparseMerkleTree {
    /// @inheritdoc ISparseMerkleTree
    function updateRootFromProof(
        bytes32 leaf,
        uint256 index,
        uint256 depth,
        bytes memory proof
    ) public pure returns (bytes32) {
        require(depth <= 256, "depth cannot be larger than 256");
        uint256 p = (depth % 8) == 0 ? depth / 8 : depth / 8 + 1; // length of trail in bytes = ceil( depth // 8 )
        require(
            (proof.length - p) % 32 == 0 && proof.length <= 8224,
            "invalid proof format"
        ); // 8224 = 32 * 256 + 32
        bytes32 proofElement;
        bytes32 computedHash = leaf;
        uint256 proofBits;
        uint256 _index = index;
        assembly {
            proofBits := div(mload(add(proof, 32)), exp(256, sub(32, p)))
        } // 32-p is number of bytes to shift

        for (uint256 d = 0; d < depth; d++) {
            if (proofBits % 2 == 0) {
                // check if last bit of proofBits is 0
                proofElement = 0;
            } else {
                p += 32;
                require(proof.length >= p, "proof not long enough");
                assembly {
                    proofElement := mload(add(proof, p))
                }
            }
            if (computedHash == 0 && proofElement == 0) {
                computedHash = 0;
            } else if (_index % 2 == 0) {
                assembly {
                    mstore(0, computedHash)
                    mstore(0x20, proofElement)
                    computedHash := keccak256(0, 0x40)
                }
            } else {
                assembly {
                    mstore(0, proofElement)
                    mstore(0x20, computedHash)
                    computedHash := keccak256(0, 0x40)
                }
            }
            proofBits = proofBits / 2; // shift it right for next bit
            _index = _index / 2;
        }
        return computedHash;
    }

    /// @inheritdoc ISparseMerkleTree
    function SMTVerify(
        bytes32 expectedRoot,
        bytes32 leaf,
        uint256 index,
        uint256 depth,
        bytes memory proof
    ) public pure returns (bool) {
        return expectedRoot == updateRootFromProof(leaf, index, depth, proof);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Pure library to recover address from signatures
*/

contract Messages {
    /**
     @notice retrieves the addr that signed a message
     @param msgHash the message digest
     @param sig the message signature
     @return the retrieved address
     */
    function recoverAddrFromBytes(bytes32 msgHash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0x0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }
        return ecrecover(msgHash, v, r, s);
    }

    /**
     @notice retrieves the addr that signed a message
     @param msgHash the message digest
     @param v,r,s the (v,r,s) params of the signtature
     @return the retrieved address
     */
    function recoverAddr(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(msgHash, v, r, s);
    }

    /**
     @notice Returns the hash after prepending eth_sign prefix
     @param hash the hash before prepending
     @return the hash after prepending eth_sign prefix
     */
    function prefixed(bytes32 hash) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Base functions for Standard Merkle Trees
*/

contract MerkleTreeBase {
    bytes32 constant NULL_BYTES32 = bytes32(0);

    function hash_node(bytes32 left, bytes32 right)
        public
        pure
        returns (bytes32 hash)
    {
        if ((right == NULL_BYTES32) && (left == NULL_BYTES32))
            return NULL_BYTES32;
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }

    function buildProof(
        uint256 leafPos,
        bytes32[] memory leaves,
        uint256 nLevels
    ) public pure returns (bytes32[] memory proof) {
        if (nLevels == 0) {
            require(
                leaves.length == 1,
                "buildProof: leaves length must be 0 if nLevels = 0"
            );
            require(
                leafPos == 0,
                "buildProof: leafPos must be 0 if there is only one leaf"
            );
            return proof; // returns the empty array []
        }
        uint256 nLeaves = 2**nLevels;
        require(
            leaves.length == nLeaves,
            "number of leaves is not = pow(2,nLevels)"
        );
        proof = new bytes32[](nLevels);
        // The 1st element is just its pair
        proof[0] = ((leafPos % 2) == 0)
            ? leaves[leafPos + 1]
            : leaves[leafPos - 1];
        // The rest requires computing all hashes
        for (uint8 level = 0; level < nLevels - 1; level++) {
            nLeaves /= 2;
            leafPos /= 2;
            for (uint256 pos = 0; pos < nLeaves; pos++) {
                leaves[pos] = hash_node(leaves[2 * pos], leaves[2 * pos + 1]);
            }
            proof[level + 1] = ((leafPos % 2) == 0)
                ? leaves[leafPos + 1]
                : leaves[leafPos - 1];
        }
    }

    /**
    * @dev 
        if nLevel = 0, there is one single leaf, corresponds to an empty proof
        if nLevels = 1, we need 1 element in the proof array
        if nLevels = 2, we need 2 elements...
            .
            ..   ..
        .. .. .. ..
        01 23 45 67
    */
    function MTVerify(
        bytes32 root,
        bytes32[] memory proof,
        bytes32 leafHash,
        uint256 leafPos
    ) public pure returns (bool) {
        for (uint32 pos = 0; pos < proof.length; pos++) {
            if ((leafPos % 2) == 0) {
                leafHash = hash_node(leafHash, proof[pos]);
            } else {
                leafHash = hash_node(proof[pos], leafHash);
            }
            leafPos /= 2;
        }
        return root == leafHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Merkle Tree Verify for serialized inputs
 @dev Unpacks serialized inputs and then calls Merkle Tree Verify
*/

import "../pure/Merkle.sol";
import "../pure/serialization/SerializeMerkleGet.sol";

contract MerkleSerialized is Merkle, SerializeMerkleGet {
    /**
    @dev
         MTData serializes the leaf, its position, and the proof that it belongs to a tree
         MTVerifySerialized returns true if such tree has root that coincides with the provided root.
    */
    function MTVerifySerialized(bytes32 root, bytes memory MTData)
        public
        pure
        returns (bool)
    {
        return MTVerify(root, MTProof(MTData), MTLeaf(MTData), MTPos(MTData));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Computation of Root in Standard Merkle Tree
 @author Freeverse.io, www.freeverse.io
 @dev Version that does not overwrite the input leaves
*/

import "../pure/MerkleTreeBase.sol";

contract Merkle is MerkleTreeBase {
    /**
    * @dev 
        If it is called with nLeaves != 2**nLevels, then it behaves as if zero-padded to 2**nLevels
        If it is called with nLeaves != 2**nLevels, then it behaves as if zero-padded to 2**nLevels
        Assumed convention:
        nLeaves = 1, nLevels = 0, there is one leaf, which coincides with the root
        nLeaves = 2, nLevels = 1, the root is the hash of both leaves
        nLeaves = 4, nLevels = 2, ...
    */
    function merkleRoot(bytes32[] memory leaves, uint256 nLevels)
        public
        pure
        returns (bytes32)
    {
        if (nLevels == 0) return leaves[0];
        uint256 nLeaves = 2**nLevels;
        require(
            nLeaves >= leaves.length,
            "merkleRoot: not enough levels given the number of leaves"
        );

        /**
        * @dev 
            instead of reusing the leaves array entries to store hashes leaves,
            create a half-as-long array (_leaves) for that purpose, to avoid modifying
            the input array. Solidity passes-by-reference when the function is in the same contract)
            and passes-by-value when calling a function in an external contract
        */
        bytes32[] memory _leaves = new bytes32[](nLeaves);

        // level = 0 uses the original leaves:
        nLeaves /= 2;
        uint256 nLeavesNonNull = (leaves.length % 2 == 0)
            ? (leaves.length / 2)
            : ((leaves.length / 2) + 1);
        if (nLeavesNonNull > nLeaves) nLeavesNonNull = nLeaves;

        for (uint256 pos = 0; pos < nLeavesNonNull; pos++) {
            _leaves[pos] = hash_node(leaves[2 * pos], leaves[2 * pos + 1]);
        }
        for (uint256 pos = nLeavesNonNull; pos < nLeaves; pos++) {
            _leaves[pos] = NULL_BYTES32;
        }

        // levels > 0 reuse the smaller _leaves array:
        for (uint8 level = 1; level < nLevels; level++) {
            nLeaves /= 2;
            nLeavesNonNull = (nLeavesNonNull % 2 == 0)
                ? (nLeavesNonNull / 2)
                : ((nLeavesNonNull / 2) + 1);
            if (nLeavesNonNull > nLeaves) nLeavesNonNull = nLeaves;

            for (uint256 pos = 0; pos < nLeavesNonNull; pos++) {
                _leaves[pos] = hash_node(
                    _leaves[2 * pos],
                    _leaves[2 * pos + 1]
                );
            }
            for (uint256 pos = nLeavesNonNull; pos < nLeaves; pos++) {
                _leaves[pos] = NULL_BYTES32;
            }
        }
        return _leaves[0];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.11;

/**
 @dev Library of pure functions to help providing info
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IInfoBase.sol";

import "../pure/EncodingAssets.sol";
import "../pure/serialization/SerializeAssetPropsGet.sol";
import "../pure/serialization/SerializeCompleteGet.sol";
import "../pure/serialization/SerializeFreezeGet.sol";
import "../pure/serialization/SerializeBuyNowGet.sol";
import "../pure/serialization/SerializeMerkleGet.sol";
import "../pure/serialization/SerializeOwnershipGet.sol";
import "../pure/serialization/SerializeMarketDataGet.sol";
import "../pure/serialization/SerializeMarketDataSet.sol";
import "../pure/SparseMerkleTree.sol";
import "../pure/MerkleSerialized.sol";
import "../pure/Constants.sol";
import "../pure/Messages.sol";
import "../pure/ChallengeLibStatus.sol";

contract InfoBase is
    IInfoBase,
    Constants,
    EncodingAssets,
    SerializeMarketDataSet,
    SerializeAssetPropsGet,
    SerializeCompleteGet,
    SerializeFreezeGet,
    SerializeBuyNowGet,
    SerializeMerkleGet,
    SerializeOwnershipGet,
    SerializeMarketDataGet,
    SparseMerkleTree,
    MerkleSerialized,
    Messages,
    ChallengeLibStatus
{
    /// @inheritdoc IInfoBase
    function isOwnerInOwnershipRoot(
        bytes32 ownershipRoot,
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) public pure returns (bool) {
        if (marketDataNeverTraded(marketData)) {
            return
                (owner == decodeOwner(assetId)) &&
                SMTVerify(
                    ownershipRoot,
                    bytes32(0),
                    assetId,
                    DEPTH_OWNERSHIP_TREE,
                    proof
                );
        }
        bytes32 digest = keccak256(abi.encode(assetId, owner, marketData));
        return
            SMTVerify(
                ownershipRoot,
                digest,
                assetId,
                DEPTH_OWNERSHIP_TREE,
                proof
            );
    }

    /// @inheritdoc IInfoBase
    function isAssetPropsInUniverseRoot(
        bytes32 root,
        bytes memory proof,
        uint256 assetId,
        string memory assetCID
    ) public pure returns (bool) {
        return
            MTVerify(
                root,
                assetPropsProof(proof),
                computeAssetLeaf(assetId, assetCID),
                assetPropsPos(proof)
            );
    }

    /// @inheritdoc IInfoBase
    function isOwnerInOwnershipRootSerialized(
        bytes memory data,
        bytes32 ownershipRoot
    ) public pure returns (bool) {
        return
            isOwnerInOwnershipRoot(
                ownershipRoot,
                ownAssetId(data),
                ownOwner(data),
                ownMarketData(data),
                ownProof(data)
            );
    }

    /// @inheritdoc IInfoBase
    function updateOwnershipTreeSerialized(
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) public pure returns (bytes32) {
        uint256 assetId = ownAssetId(initOwnershipRaw);
        bytes memory newMarketData;
        address owner;
        uint8 txType = txGetType(txData);

        if (txType == TX_IDX_FREEZE) {
            owner = ownOwner(initOwnershipRaw); // owner remains the same
            newMarketData = encodeMarketData(
                assetId,
                freezeTXValidUntil(txData),
                freezeTXOfferValidUntil(txData),
                freezeTXTimeToPay(txData),
                freezeTXSellerHiddenPrice(txData)
            );
        } else {
            owner = (txType == TX_IDX_COMPLETE)
                ? complTXRecoverBuyer(txData)
                : buyNowTXRecoverBuyer(txData); // owner should now be the buyer
            newMarketData = serializeMarketData(bytes32(0), 0, 0);
        }

        bytes32 newLeafVal = keccak256(
            abi.encode(assetId, owner, newMarketData)
        );
        return
            updateOwnershipTree(
                newLeafVal,
                assetId,
                ownProof(initOwnershipRaw)
            );
    }

    /// @inheritdoc IInfoBase
    function encodeMarketData(
        uint256 assetId,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay,
        bytes32 sellerHiddenPrice
    ) public pure returns (bytes memory) {
        bytes32 auctionId = computeAuctionId(
            sellerHiddenPrice,
            assetId,
            validUntil,
            offerValidUntil,
            versesToPay
        );
        return serializeMarketData(auctionId, validUntil, versesToPay);
    }

    /// @inheritdoc IInfoBase
    function complTXRecoverBuyer(bytes memory txData)
        public
        pure
        returns (address)
    {
        return
            recoverAddrFromBytes(
                prefixed(
                    keccak256(
                        abi.encode(
                            complTXAuctionId(txData),
                            complTXBuyerHiddenPrice(txData),
                            complTXAssetCID(txData)
                        )
                    )
                ),
                complTXBuyerSig(txData)
            );
    }

    /// @inheritdoc IInfoBase
    function buyNowTXRecoverBuyer(bytes memory txData)
        public
        pure
        returns (address)
    {
        return
            recoverAddrFromBytes(
                prefixed(
                    digestBuyNow(
                        buyNowTXHiddenPrice(txData),
                        buyNowTXAssetId(txData),
                        buyNowTXValidUntil(txData),
                        buyNowTXAssetCID(txData)
                    )
                ),
                buyNowTXBuyerSig(txData)
            );
    }

    /// @inheritdoc IInfoBase
    function digestBuyNow(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint256 validUntil,
        string memory assetCID
    ) public pure returns (bytes32) {
        bytes32 buyNowId = keccak256(
            abi.encode(hiddenPrice, assetId, validUntil)
        );
        return keccak256(abi.encode(buyNowId, assetCID));
    }

    /// @inheritdoc IInfoBase
    function updateOwnershipTree(
        bytes32 newLeafVal,
        uint256 assetId,
        bytes memory proofPrevLeafVal
    ) public pure returns (bytes32) {
        return
            updateRootFromProof(
                newLeafVal,
                assetId,
                DEPTH_OWNERSHIP_TREE,
                proofPrevLeafVal
            );
    }

    /// @inheritdoc IInfoBase
    function computeAuctionId(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay
    ) public pure returns (bytes32) {
        return
            (offerValidUntil == 0)
                ? keccak256(
                    abi.encode(hiddenPrice, assetId, validUntil, versesToPay)
                )
                : keccak256(
                    abi.encode(
                        hiddenPrice,
                        assetId,
                        offerValidUntil,
                        versesToPay
                    )
                );
    }

    /// @inheritdoc IInfoBase
    function wasAssetFrozen(bytes memory marketData, uint256 checkVerse)
        public
        pure
        returns (bool)
    {
        if (marketDataNeverTraded(marketData)) return false;
        return (uint256(marketDataValidUntil(marketData)) +
            uint256(marketDataTimeToPay(marketData)) >
            checkVerse);
    }

    /// @inheritdoc IInfoBase
    function computeAssetLeaf(uint256 assetId, string memory cid)
        public
        pure
        returns (bytes32 leafVal)
    {
        return keccak256(abi.encode(assetId, cid));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Main serialization/deserialization of data into an assetId
 @author Freeverse.io, www.freeverse.io
 @dev assetId = 
 @dev  version(8b) + universeIdx (24) + isImmutable(1b) + isUntradable(1b) + editionIdx (24b) + assetIdx(38b) + initOwner (160b)
*/

contract EncodingAssets {
    function encodeAssetId(
        uint256 universeIdx,
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
        require(editionIdx >> 24 == 0, "assetIdx cannot be larger than 24 bit");
        return ((universeIdx << 224) |
            (uint256(isImmutable ? 1 : 0) << 223) |
            (uint256(isUntradable ? 1 : 0) << 222) |
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
        return uint32((assetId >> 198) & 16777215); // 2**24 - 1
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
 @title Constants used throughout the platform
 @author Freeverse.io, www.freeverse.io
 @dev Time is always expressed in units of 'verse'
*/

contract Constants {
    uint32 internal constant MAX_VALID_UNTIL = 8640; // 90 days
    uint32 internal constant MAX_VERSES_TO_PAY = 960; // 10 days;

    uint16 internal constant DEPTH_OWNERSHIP_TREE = 256;

    uint8 internal constant TX_IDX_FREEZE = 0;
    uint8 internal constant TX_IDX_COMPLETE = 1;
    uint8 internal constant TX_IDX_BUYNOW = 2;
}

// SPDX-License-Identifier: BUSL-1.1
// License details specified at ipfs://QmSiTS1wfYqwjoU8coz6U327AEsJ6iSVSccUdz7MJapA7C
// with possible additions as returned by calling the function license()
// from the main storage contract
pragma solidity =0.8.11;

/**
 @title Pure functions to compute the status of a challenge
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IChallengeLibStatus.sol";

contract ChallengeLibStatus is IChallengeLibStatus {
    /// @inheritdoc IChallengeLibStatus
    function isInChallengePeriodFinishedPhasePure(
        uint256 nTXs,
        uint256 txRootsCurrentVerse,
        uint256 ownershipSubmissionTimeCurrent,
        uint256 challengeWindowCurrent,
        uint256 txSubmissionTimeCurrent,
        uint256 blockTimestamp,
        uint8 challengesLevel
    ) public pure returns (bool isInChallengeOver, uint8 actualLevel) {
        if (txRootsCurrentVerse == 0) return (true, 1);
        bool isOwnershipMoreRecent = ownershipSubmissionTimeCurrent >=
            txSubmissionTimeCurrent;
        bool isSettled;
        (isSettled, actualLevel, ) = computeChallStatus(
            nTXs,
            blockTimestamp,
            txSubmissionTimeCurrent,
            ownershipSubmissionTimeCurrent,
            challengeWindowCurrent,
            challengesLevel
        );
        isInChallengeOver = isSettled && isOwnershipMoreRecent;
    }

    /// @inheritdoc IChallengeLibStatus
    function computeChallStatus(
        uint256 nTXs,
        uint256 currentTime,
        uint256 lastTxSubmissionTime,
        uint256 lastChallTime,
        uint256 challengeWindow,
        uint8 writtenLevel
    )
        public
        pure
        returns (
            bool isSettled,
            uint8 actualLevel,
            uint8 nJumps
        )
    {
        if (challengeWindow == 0)
            return (
                currentTime > lastChallTime,
                (writtenLevel % 2) == 1 ? 1 : 2,
                0
            );
        uint256 numChallPeriods = (currentTime > lastChallTime)
            ? (currentTime - lastChallTime) / challengeWindow
            : 0;
        // actualLevel in the following formula can either end up as 0 or 1.
        actualLevel = (writtenLevel >= 2 * numChallPeriods)
            ? uint8(writtenLevel - 2 * numChallPeriods)
            : (writtenLevel % 2);
        // if we reached actualLevel = 0 via jumps, it means that there was enough time to settle level 2. So we're settled and remain at level = 2.
        if ((writtenLevel > 1) && (actualLevel == 0)) {
            return (true, 2, 0);
        }
        nJumps = (writtenLevel - actualLevel) / 2;
        isSettled =
            (nTXs == 0) ||
            (lastTxSubmissionTime > lastChallTime) ||
            (currentTime > (lastChallTime + (nJumps + 1) * challengeWindow));
    }
}

// SPDX-License-Identifier: BUSL-1.1
// License details specified at ipfs://QmSiTS1wfYqwjoU8coz6U327AEsJ6iSVSccUdz7MJapA7C
// with possible additions as returned by calling the function license()
// from the main storage contract
pragma solidity =0.8.11;

/**
 @title Pure functions needed in challenges involving freeze TXs
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IChallengeLibFreeze.sol";

import "../pure/InfoBase.sol";
import "../pure/Messages.sol";

contract ChallengeLibFreeze is IChallengeLibFreeze, Messages, InfoBase {
    /// @inheritdoc IChallengeLibFreeze
    function verifyFreezeTXData(
        bytes memory txData,
        uint256 challengedOwnershipPos,
        uint256 assetIdInOwnershipData,
        bytes32 lastTXSubmissionRoot
    ) public pure {
        // check compatibility of assetId, root, and pos across serialized inputs:
        require(
            freezeTXPosTX(txData) == challengedOwnershipPos,
            "freeze: pos in transaction and transition data does not match"
        );
        require(
            freezeTXAssetId(txData) == assetIdInOwnershipData,
            "freeze: assetId in TX and Ownership data does not match"
        );
        // check that the provided data correspond to the TX that should have connected both roots:
        require(
            isFreezeTXIncluded(txData, lastTXSubmissionRoot),
            "freeze TX data not part of lastTXSubmissionRoot"
        );
    }

    /// @inheritdoc IChallengeLibFreeze
    function isFreezeTXIncluded(bytes memory data, bytes32 txRoot)
        public
        pure
        returns (bool)
    {
        return
            MTVerify(
                txRoot,
                freezeTXProofTX(data),
                hashFreezeTX(data),
                freezeTXPosTX(data)
            );
    }

    /// @inheritdoc IChallengeLibFreeze
    function hashFreezeTX(bytes memory data) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    freezeTXAssetId(data),
                    freezeTXSellerHiddenPrice(data),
                    freezeTXSellerSig(data),
                    freezeTXValidUntil(data),
                    freezeTXOfferValidUntil(data),
                    freezeTXTimeToPay(data)
                )
            );
    }

    /// @inheritdoc IChallengeLibFreeze
    function isFreezeValidSerialized(
        uint256 currentVerse,
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) public pure returns (bool ok) {
        return
            isFreezeValid(
                ownOwner(initOwnershipRaw),
                ownMarketData(initOwnershipRaw),
                freezeTXSellerHiddenPrice(txData),
                ownAssetId(initOwnershipRaw),
                freezeTXSellerSig(txData),
                freezeTXValidUntil(txData),
                freezeTXOfferValidUntil(txData),
                freezeTXTimeToPay(txData),
                currentVerse
            );
    }

    /// @inheritdoc IChallengeLibFreeze
    function isFreezeValid(
        address owner,
        bytes memory marketData,
        bytes32 sellerHiddenPrice,
        uint256 assetId,
        bytes memory signature,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay,
        uint256 currentVerse
    ) public pure returns (bool ok) {
        if (offerValidUntil == 0) {
            // check validUntil has not expired
            ok = (validUntil >= currentVerse);
        } else {
            // check offerValidUntil and valindUntil have not expired, and that validUntil is larger
            ok =
                (offerValidUntil >= currentVerse) &&
                (validUntil > offerValidUntil);
        }

        ok =
            ok &&
            // check asset is not already frozen (marketData contains data before applying this TX)
            (!wasAssetFrozen(marketData, currentVerse)) &&
            // check that validUntil and versesToPay are not unreseanoably large
            (validUntil < currentVerse + MAX_VALID_UNTIL) &&
            (versesToPay < MAX_VERSES_TO_PAY);

        // If this is an academy asset, just check that the msg arrives from the owner of the market.
        if (!ok) return false;
        // Finally, check that the signature is from the asset owner
        bytes32 sellerDigest = computePutForSaleDigest(
            sellerHiddenPrice,
            assetId,
            validUntil,
            offerValidUntil,
            versesToPay
        );
        return (owner == recoverAddrFromBytes(sellerDigest, signature));
    }

    function computePutForSaleDigest(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay
    ) public pure returns (bytes32) {
        return
            prefixed(
                keccak256(
                    abi.encode(
                        hiddenPrice,
                        assetId,
                        validUntil,
                        offerValidUntil,
                        versesToPay
                    )
                )
            );
    }

    /// @inheritdoc IChallengeLibFreeze
    function verifyOwnershipData(
        bytes32 transRootPreviousLevel,
        bool areAllChallengePosZero,
        bytes32 rootAtEdge,
        bytes32 prevVerseSettledOwnershipRoot,
        bytes memory initOwnershipData,
        bytes memory challengedOwnershipData,
        uint256 challengedOwnershipPos,
        bytes memory initOwnershipRaw
    ) public pure returns (bytes32 initOwnershipRoot) {
        // Prove that the challenged ownership root is part of the transitions root stored after the last challenge
        require(
            MTVerifySerialized(transRootPreviousLevel, challengedOwnershipData),
            "merkle proof for challengedOwnershipData not correct"
        );

        if (areAllChallengePosZero && (challengedOwnershipPos == 0)) {
            // If the challenged root is the very first one in this verse, then the init root is the previous verse settled root,
            // and there is no need to provide neither such root, nor any proof related to it, as part of initOwnershipData.
            require(
                initOwnershipData.length == 0,
                "initOwnershipData data should not be present when challenging left-most root at levelVerifiable"
            );
            initOwnershipRoot = prevVerseSettledOwnershipRoot;
        } else {
            // If the challenged root is not the very first one in this verse, then initOwnershipData must contain:
            // - the initOwnershipRoot (the one just left from the challenged root)
            // - the prove that initOwnershipRoot belongs to either the corresponding transitionRoot
            //   (etiher rootAtEdge or the same transRootPreviousLevel as the challengedOwnership
            initOwnershipRoot = MTLeaf(initOwnershipData);
            if (challengedOwnershipPos == 0) {
                require(
                    MTVerifySerialized(rootAtEdge, initOwnershipData),
                    "merkle proof for initOwnershipData not correct, given challengedOwnershipPos = 0"
                );
            } else {
                require(
                    MTPos(initOwnershipData) + 1 == challengedOwnershipPos,
                    "prev merkle proof pos is not the previous one"
                );
                require(
                    MTVerifySerialized(
                        transRootPreviousLevel,
                        initOwnershipData
                    ),
                    "merkle proof for initOwnershipData not correct, given challengedOwnershipPos != 0"
                );
            }
        }
        // Verify that the provided raw init ownership data is inside initOwnershipRoot
        require(
            isOwnerInOwnershipRootSerialized(
                initOwnershipRaw,
                initOwnershipRoot
            ),
            "ownership data for init state does not match init transition root"
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
// License details specified at ipfs://QmSiTS1wfYqwjoU8coz6U327AEsJ6iSVSccUdz7MJapA7C
// with possible additions as returned by calling the function license()
// from the main storage contract
pragma solidity =0.8.11;

/**
 @title Pure functions needed in challenges involving complete TXs
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IChallengeLibComplete.sol";

import "../pure/InfoBase.sol";

contract ChallengeLibComplete is IChallengeLibComplete, InfoBase {
    /// @inheritdoc IChallengeLibComplete
    function verifyCompleteTXData(
        bytes memory txData,
        uint256 challengedOwnershipPos,
        uint256 assetIdInOwnershipData,
        bytes32 lastTXSubmissionRoot
    ) public pure {
        require(
            complTXPosTX(txData) == challengedOwnershipPos,
            "complete: pos in transaction and transition data does not match"
        );
        require(
            complTXAssetId(txData) == assetIdInOwnershipData,
            "complete: assetId in TX and Ownership data does not match"
        );
        require(
            isCompleteTXIncluded(txData, lastTXSubmissionRoot),
            "completeAuction TX data not part of lastTXSubmissionRoot"
        );
    }

    /// @inheritdoc IChallengeLibComplete
    function complTXCertifyAssetProps(bytes32 universeRoot, bytes memory txData)
        public
        pure
        returns (bool isOK)
    {
        string memory assetsPropsCID = complTXAssetCID(txData);
        // if buyer explicitly wanted an uncertified transfer, do not check further.
        if (bytes(assetsPropsCID).length == 0) return true;
        return (
            isAssetPropsInUniverseRoot(
                universeRoot,
                complTXProofProps(txData),
                complTXAssetId(txData),
                assetsPropsCID
            )
        );
    }

    /// @inheritdoc IChallengeLibComplete
    function isCompleteTXIncluded(bytes memory data, bytes32 txRoot)
        public
        pure
        returns (bool)
    {
        return
            MTVerify(
                txRoot,
                complTXProofTX(data),
                hashCompleteTX(data),
                complTXPosTX(data)
            );
    }

    /// @inheritdoc IChallengeLibComplete
    function hashCompleteTX(bytes memory data) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    complTXAssetPropsVerse(data),
                    complTXAssetId(data),
                    complTXAuctionId(data),
                    complTXBuyerHiddenPrice(data),
                    complTXProofProps(data),
                    complTXAssetCID(data),
                    complTXBuyerSig(data)
                )
            );
    }

    /// @inheritdoc IChallengeLibComplete
    function isCompleteValidSerialized(
        uint256 currentVerse,
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) public pure returns (bool ok) {
        return
            isCompleteValid(
                ownOwner(initOwnershipRaw),
                complTXRecoverBuyer(txData),
                ownMarketData(initOwnershipRaw),
                complTXAuctionId(txData),
                currentVerse
            );
    }

    /// @inheritdoc IChallengeLibComplete
    function isCompleteValid(
        address prevOwner,
        address buyerAddr,
        bytes memory marketData,
        bytes32 auctionId,
        uint256 currentVerse
    ) public pure returns (bool ok) {
        ok = // origin and target owners must be different
            (prevOwner != buyerAddr) &&
            // owner is not a null address
            (buyerAddr != address(0x0)) &&
            // check buyer and seller refer to the exact same auction
            auctionId == marketDataAuctionId(marketData) &&
            // check asset is still frozen using fiat (which requires the freeze paradigm)
            (wasAssetFrozen(marketData, currentVerse));
    }
}

// SPDX-License-Identifier: BUSL-1.1
// License details specified at ipfs://QmSiTS1wfYqwjoU8coz6U327AEsJ6iSVSccUdz7MJapA7C
// with possible additions as returned by calling the function license()
// from the main storage contract
pragma solidity =0.8.11;

/**
 @title Pure functions needed in challenges involving buyNow TXs
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IChallengeLibBuyNow.sol";

import "../pure/InfoBase.sol";

contract ChallengeLibBuyNow is IChallengeLibBuyNow, InfoBase {
    /// @inheritdoc IChallengeLibBuyNow
    function verifyBuyNowTXData(
        bytes memory txData,
        uint256 challengedOwnershipPos,
        uint256 assetIdInOwnershipData,
        bytes32 lastTXSubmissionRoot
    ) public pure {
        require(
            buyNowTXPosTX(txData) == challengedOwnershipPos,
            "buyNow: pos in transaction and transition data does not match"
        );
        require(
            buyNowTXAssetId(txData) == assetIdInOwnershipData,
            "buyNow: assetId in TX and Ownership data does not match"
        );
        require(
            isBuyNowTXIncluded(txData, lastTXSubmissionRoot),
            "buyNow TX data not part of lastTXSubmissionRoot"
        );
    }

    /// @inheritdoc IChallengeLibBuyNow
    function buyNowTXCertifyAssetProps(
        bytes32 universeRoot,
        bytes memory txData
    ) public pure returns (bool isOK) {
        string memory assetsPropsCID = buyNowTXAssetCID(txData);
        // if buyer explicitly wanted an uncertified transfer, do not check further.
        if (bytes(assetsPropsCID).length == 0) return true;
        return (
            isAssetPropsInUniverseRoot(
                universeRoot,
                buyNowTXProofProps(txData),
                buyNowTXAssetId(txData),
                assetsPropsCID
            )
        );
    }

    /// @inheritdoc IChallengeLibBuyNow
    function isBuyNowTXIncluded(bytes memory data, bytes32 txRoot)
        public
        pure
        returns (bool)
    {
        return
            MTVerify(
                txRoot,
                buyNowTXProofTX(data),
                hashBuyNowTX(data),
                buyNowTXPosTX(data)
            );
    }

    /// @inheritdoc IChallengeLibBuyNow
    function hashBuyNowTX(bytes memory data) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    buyNowTXAssetPropsVerse(data),
                    buyNowTXAssetId(data),
                    buyNowTXHiddenPrice(data),
                    buyNowTXValidUntil(data),
                    buyNowTXProofProps(data),
                    buyNowTXAssetCID(data),
                    buyNowTXSellerSig(data),
                    buyNowTXBuyerSig(data)
                )
            );
    }

    /// @inheritdoc IChallengeLibBuyNow
    function isBuyNowValidSerialized(
        uint256 currentVerse,
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) public pure returns (bool ok) {
        return
            isBuyNowValid(
                ownOwner(initOwnershipRaw),
                buyNowTXRecoverBuyer(txData),
                buyNowTXSellerSig(txData),
                ownMarketData(initOwnershipRaw),
                buyNowTXHiddenPrice(txData),
                buyNowTXAssetId(txData),
                buyNowTXValidUntil(txData),
                currentVerse
            );
    }

    /// @inheritdoc IChallengeLibBuyNow
    function isBuyNowValid(
        address prevOwner,
        address buyer,
        bytes memory sellerSig,
        bytes memory marketData,
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        uint256 currentVerse
    ) public pure returns (bool ok) {
        ok = // origin and target owners must be different
            (prevOwner != buyer) &&
            // owner is not a null address
            (buyer != address(0x0)) &&
            // check asset is not frozen in an auction
            (!wasAssetFrozen(marketData, currentVerse)) &&
            // check that the signer as seller is the previous owner
            prevOwner ==
            buyNowTXRecoverSeller(
                hiddenPrice,
                assetId,
                validUntil,
                sellerSig
            ) &&
            // check that the payment arrived on time
            currentVerse <= validUntil;
    }

    /// @inheritdoc IChallengeLibBuyNow
    function buyNowTXRecoverSeller(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 sellerDigest = prefixed(
            keccak256(abi.encode(hiddenPrice, assetId, validUntil))
        );
        return recoverAddrFromBytes(sellerDigest, signature);
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
 @title Interface to contract with Sparse Merkle Tree functions
 @author Freeverse.io, www.freeverse.io
*/

interface ISparseMerkleTree {
    /**
     * @notice Updates the root of a Sparse Merkle Tree
     * after setting a new value to one leaf
     * @param leaf The new value
     * @param index The idx of the leaf
     * @param depth The depth of the SMT
     * @param proof The proof that the leaf belongs to the SMT
     * @return The updated SMT root
     */
    function updateRootFromProof(
        bytes32 leaf,
        uint256 index,
        uint256 depth,
        bytes memory proof
    ) external pure returns (bytes32);

    /**
     * @notice Returns true if the leaf provided belongs to the SMT
     * with the provided root
     * @param expectedRoot The SMT root
     * @param leaf The leaf value
     * @param index The idx of the leaf
     * @param depth The depth of the SMT
     * @param proof The proof that the leaf belongs to the SMT
     * @return Returns true if leaf belongs to SMT
     */
    function SMTVerify(
        bytes32 expectedRoot,
        bytes32 leaf,
        uint256 index,
        uint256 depth,
        bytes memory proof
    ) external pure returns (bool);
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
     * @notice Retrieves the Buyer from a provided buynow TX data
     * @dev the TX data includes a signature, which is ultimately used to derive the buyer
     * @param txData The serialized data that describes the TX
     * @return the address of the buyer
     */
    function buyNowTXRecoverBuyer(bytes memory txData)
        external
        pure
        returns (address);

    /**
     * @notice Returns the digest of a buynow TX that is signed by buyer/seller
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

interface IInfo is IChallengeLibStatus {
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
     * @return isInChallengeOver Whether the system is in the phase between the settlement of
     * the last ownership root, and the submission of a new TX Batch
     * @return actualLevel The level at which the last challenge process is, accounting for
     * implicit time-driven changes
     * @return txVerse The current txVerse
     */
    function isInChallengePeriodFinishedPhase()
        external
        view
        returns (
            bool isInChallengeOver,
            uint8 actualLevel,
            uint256 txVerse
        );

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
 @author Freeverse.io, www.freeverse.io
 @title Interface to contract for challenges of submitted ownership roots
 @dev When a challenge is accepted, it communicates with the Stakers contract,
 @dev which is responsible for managing stakes and rewards accordingly
*/

interface IChallenges {
    event ChallengeAccepted(
        uint8 challengedLevel,
        bytes32 indexed root,
        bytes32[] nextLevelTransRoots,
        bytes32 indexed newOwnershipRoot,
        bytes32 rootAtEdge,
        uint256 challPos
    );
    event ChallengeResolved(
        uint8 resolvedLevel,
        bool isSuccessful,
        uint256 indexed timeStamp
    );

    /**
     * @notice Returns address of the license details for the contract code
     */
    function license() external view returns (string memory);

    /**
     * @notice Returns the address of the Storage contract that
     * this contract can communicate with
     */
    function _sto() external view returns (address);

    /**
     * @notice Returns the address of the Writer contract that
     * this contract can communicate with
     */
    function _writer() external view returns (address);

    // External libraries of pure functions.

    /**
     * @notice Returns the address of the Freeze Lib contract that
     * this contract can communicate with
     */
    function _freezelib() external view returns (address);

    /**
     * @notice Returns the address of the Complete Lib contract that
     * this contract can communicate with
     */
    function _completelib() external view returns (address);

    /**
     * @notice Returns the address of the Buynow Lib contract that
     * this contract can communicate with
     */
    function _buyNowlib() external view returns (address);

    /**
     * @notice Returns the address of the Info contract that
     * this contract can communicate with
     */
    function _info() external view returns (address);

    /**
     * @notice Challenges an ownership root
     * @dev Main entry point for challenges. The challenger states that:
         - if level = 0, function reverts. Must use submitNewOwnership instead.
         - if level can be verified on-chain, function reverts. Must use challVerifiableOnChain instead.
         - if level = 1:
            - the submitted ownership root is wrong
            - the correct root is as newOwnershipRoot (which must be != submitted ownership root)
            - the transition Roots at next level are: nextLevelTransRoots
                - note that Root(nextLevelTransRoots) is stored, 
                - while nextLevelTransRoots are only emitted
            - must provide empty (not used): challengedLeafData, leftOfChallengedLeafData, nextLevelEdgeTransRootData
         - if level > 1:
            - the root submitted at previous level is wrong. 
            - newOwnershipRoot (not used) must be null
            - statement: the root claimed as wrong is claimAsWrong = MTLeaf(challengedLeafData) AND all roots left from it are correct.
            - since it had been emitted, the proof that claimAsWrong belonged to the previously stored root is MTPos(challengedLeafData), MTProof(challengedLeafData)
            - what the actual correct root is implicit in providing its correct next-level transitions roots nextLevelTransRoots:
                    - will be stored: actual root = Root(nextLevelTransRoots)
                    - nextLevelTransRoots will be emitted
            - Having provided nextLevelTransRoots, it also needs to be provided, from the same level as nextLevelTransRoots,
              the last trasnition root of the previous pack of roots. This is needed to be stored and carried through the last on-chain verifiable level,
              so that the on-chain claim can have enough data to prove that "given prev state, this should be the correct state".
              There are 3 cases to consider:
              - case I: Imagine H3 is challenged. ClaimedAsWrong = H3. challengedLeafData proves that H3 is in H.
                        The transitions roots h31..h34 are provided and Root(h31..h34) is stored as claimed correct root.
                        h24 is provided in nextLevelEdgeTransRootData, with the proof that it is in H2,
                        and the proof that H2 is also in H, via leftOfChallengedLeafData.
                        h24 is stored.
                                                         H
                                                    H0 H1 H2 H3            
                                            h21 h22 h23 h24  h31 h32 h33 h34

              - case 2: Imagine h31 is challenged. ClaimedAsWrong = h31. challengedLeafData proves that h31 is in H3.
                        The transitions roots x311..x314 are provided and Root(x311..x314) is stored as claimed correct root.
                        x244 is provided in nextLevelEdgeTransRootData, with the proof that it is in h24,
                        and the proof that h24... which had already been explicitly stored as edgeRoot. No need to use leftOfChallengedLeafData (forced empty)
                        x244 is stored
                                                         H
                                                    H0 H1 H2 H3            
                                            h21 h22 h23 h24  h31 h32 h33 h34
                                                ... x244  x311 x312 x313 x314

              - case 3: Imagine H0 is challenged. ClaimedAsWrong = H0. challengedLeafData proves that H0 is in H.
                        The transitions roots h01..h03 are provided and Root(h01..h03) is stored as claimed correct root.
                        In this case, the root at the left of h01, is the ownwership root of the previous verse!
                        This is also the case at all levels, as long as the challenged pos = 0 at all levels. 
                        In these cases, no need to use leftOfChallengedLeafData nor nextLevelEdgeTransRootData, both forced empty.
                        No need to store anything else.
                                                         H
                                                    H0 H1 H2 H3            
                                            h01 h02 h03 h04  ...
     *
     * @param challengedLeafData The serialized data that describes the challenged leaf
     * @param leftOfChallengedLeafData The serialized data that describes the leaf immediately-on-the-left of the challenged
     * @param nextLevelEdgeTransRootData The serialized data that describes the transition root at edge of next level
     * @param nextLevelTransRoots The serialized data that describes the next level transition roots
     * @param newOwnershipRoot The new ownership root proposed by the challenger
     */
    function challToNextLevel(
        bytes memory challengedLeafData,
        bytes memory leftOfChallengedLeafData,
        bytes memory nextLevelEdgeTransRootData,
        bytes32[] memory nextLevelTransRoots,
        bytes32 newOwnershipRoot
    ) external;

    /**
     * @notice Challenges an ownership root provided at a previous challenges
     * @dev Identical to challToNextLevel except for the fact that the statement here claims that the first wrong transition root
     * is left from roots previously challenged. In such case, the game reverts previous challenges and starts clean from the
     * level at which the nex challenged root sits.
     * @param challengedLevel The the level of the previous challenge
     * @param challengedLeafData The serialized data that describes the challenged leaf
     * @param leftOfChallengedLeafData The serialized data that describes the leaf immediately-on-the-left of the challenged
     * @param nextLevelEdgeTransRootData The serialized data that describes the transition root at edge of next level
     * @param nextLevelTransRoots The serialized data that describes the next level transition roots
     * @param newOwnershipRoot The new ownership root proposed by the challenger
     */
    function challToNextLevelFromPreviousPos(
        uint8 challengedLevel,
        bytes calldata challengedLeafData,
        bytes calldata leftOfChallengedLeafData,
        bytes calldata nextLevelEdgeTransRootData,
        bytes32[] calldata nextLevelTransRoots,
        bytes32 newOwnershipRoot
    ) external;

    /**
     * @notice Final on-chain resolution challenge.
     * @dev Final on-chain resolution challenge.
        The statement is: given INIT ownership root, if the corresponding TX is applied, the result is not END ownership root.
        Note that at this last level, the leaves are ownership roots directly. In other words, the emitted roots at prev level 
        were true ownership roots.
     * @param challengedOwnershipData: as challengedLeafData in previous functions:
                - claimedWrongOwnershipRoot =  MTLeaf(challengedOwnershipData)
                - (pos, proof) = MTPos/Proof(challengedOwnershipData) => proof that claimedWrongOwnershipRoot is in previously stored transRoot
     * @param initOwnershipData: as leftOfChallengedLeafData in previous functions:
                - initOwnershipRoot =  MTLeaf(challengedOwnershipData)
                - if challPos > 0, then initOwnershipData must contain the proof that it belongs to the same previously stored transRoot as challengedOwnershipData
                - if challPos = 0, then initOwnershipData must coincide with the stored edge root
     * @param initOwnershipRaw: serialized ownership pre-hash data about the assetId involved in this TX.
                - it contains the proof that such pre-hash data is correctly included in initOwnershipRoot
     * @param txData: serialized pre-hash data that describes the transaction that needs to be applied at this pos. 
                - it contains the proof that such pre-hash is correctly included in the current submitted TXBatch root.
     * @dev On numbering: pos(challengedOwnershipData) must equal pos(TX), so the semantics is:
            - TX0 brings from settled ownership at previous verse to the very first commited root in this new verse
            - TX1 brings from root = 0 at this verse to root = 1 at this verse.
     */
    function challVerifiableOnChain(
        bytes memory txData,
        bytes memory initOwnershipData,
        bytes memory challengedOwnershipData,
        bytes memory initOwnershipRaw
    ) external;

    /**
     * @notice Challenges the separately provided ownership root in previous challenge
     * @dev Simplest challenge of all. It is an on-chain verifiable challenge, relevant in the case that all transitionRoots are correct,
     * but the separately provided ownership root (which should coincide with the last leaf that forms the transitionRoots) is not.
     * The staker states that he accepts validity of all transitionRoots.
     * He then needs to provide the last leaf, and the proof that it belongs to the transitionRoot.
     * The onchain contract compares against the stored ownershipRoot.
     * The staker can execute this function at any time after the challenge process has moved to level 2,
     * where the ownershipRoots are provided separately.
     * The provided leaf is at the absolute bottom of the transitionsRoot tree,
     * unlike in other challenges, where the transitionsRoot tree unveils level by level.
     * @param lastOwnershipInTransitionsTreeData The serialized data that describes the last ownerhsip tree data
     */
    function challProvidedFinalRoot(
        bytes memory lastOwnershipInTransitionsTreeData
    ) external;

    // END OF CHALLENGE FUNCTIONS

    /**
     * @notice Reverts unless the an ownership root follows from a previous
     * provided root by applying a provided TX.
     * @dev if isTXValid == false, it requires that both roots coincide
     * @param txData The serialized data that describes the TX
     * @param initOwnershipRaw The serialized data that describes the leaf affected by the TX
     * in the initial ownership tree
     * @param initOwnershipRoot The initial ownership root
     * @param challengedOwnershipRoot The challenged final ownership root
     * @param isTXValid Whether the TX has been considered valid and should be applied
     */
    function requireEndStateCorrect(
        bytes memory txData,
        bytes memory initOwnershipRaw,
        bytes32 initOwnershipRoot,
        bytes32 challengedOwnershipRoot,
        bool isTXValid
    ) external view;
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
        uint256 nTXs,
        uint256 txRootsCurrentVerse,
        uint256 ownershipSubmissionTimeCurrent,
        uint256 challengeWindowCurrent,
        uint256 txSubmissionTimeCurrent,
        uint256 blockTimestamp,
        uint8 challengesLevel
    ) external pure returns (bool isInChallengeOver, uint8 actualLevel);

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
        uint256 nTXs,
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
 @title Interface to contract with pure functions needed in challenges involving freeze TXs
 @author Freeverse.io, www.freeverse.io
*/

interface IChallengeLibFreeze {
    /**
    @dev Reverts unless the data provided inside txData matches the requirements.
    */
    function verifyFreezeTXData(
        bytes memory txData,
        uint256 challengedOwnershipPos,
        uint256 assetIdInOwnershipData,
        bytes32 lastTXSubmissionRoot
    ) external pure;

    /**
    @dev Returns true if the provided raw freeze TX data is in a Merkle tree with root TXRoot (serialized version)
    */
    function isFreezeTXIncluded(bytes memory data, bytes32 txRoot)
        external
        pure
        returns (bool);

    /**
    @dev Hashes a FreezeTX, allowing proof of inclusion
    */
    function hashFreezeTX(bytes memory data) external pure returns (bytes32);

    /**
    @dev Unpacks serialized data to call isFreezeValid
    */
    function isFreezeValidSerialized(
        uint256 currentVerse,
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) external pure returns (bool ok);

    /**
    @dev Checks if the standard freeze verifications are correct
    */
    function isFreezeValid(
        address owner,
        bytes memory marketData,
        bytes32 sellerHiddenPrice,
        uint256 assetId,
        bytes memory signature,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay,
        uint256 currentVerse
    ) external pure returns (bool ok);

    function computePutForSaleDigest(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        uint32 offerValidUntil,
        uint32 versesToPay
    ) external pure returns (bytes32);

    /**
    @dev Reverts unless the data provided in ownership inputs for on-chain verification matches the requirements.
         Step needed for all types of on-chain challenges, regardless of the TX type
    */
    function verifyOwnershipData(
        bytes32 transRootPreviousLevel,
        bool areAllChallengePosZero,
        bytes32 rootAtEdge,
        bytes32 prevVerseSettledOwnershipRoot,
        bytes memory initOwnershipData,
        bytes memory challengedOwnershipData,
        uint256 challengedOwnershipPos,
        bytes memory initOwnershipRaw
    ) external pure returns (bytes32 initOwnershipRoot);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract with pure functions needed in challenges involving complete TXs
 @author Freeverse.io, www.freeverse.io
*/

interface IChallengeLibComplete {
    /**
    @dev Reverts unless the data provided inside txData matches the requirements.
    */
    function verifyCompleteTXData(
        bytes memory txData,
        uint256 challengedOwnershipPos,
        uint256 assetIdInOwnershipData,
        bytes32 lastTXSubmissionRoot
    ) external pure;

    /**
    @dev Returns true if props inside txData are correct are included in the universeRoot.
         If assetCID is empty, the transfer is accepted as a transfer that does not check
         assetProps, and hence does not perform any check, just returns true.
    */
    function complTXCertifyAssetProps(bytes32 universeRoot, bytes memory txData)
        external
        pure
        returns (bool isOK);

    /**
    @dev Returns true if the provided raw complete TX data is in a Merkle tree with root TXRoot (serialized version)
    */
    function isCompleteTXIncluded(bytes memory data, bytes32 txRoot)
        external
        pure
        returns (bool);

    /**
    @dev Hashes a CompleteTX, allowing proof of inclusion
    */
    function hashCompleteTX(bytes memory data) external pure returns (bytes32);

    /**
    @dev Unpacks serialized data to call isCompleteValid
    @dev The buyer is derived from the txData (derived from message & buyerSig)
    */
    function isCompleteValidSerialized(
        uint256 currentVerse,
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) external pure returns (bool ok);

    /**
    @dev Checks if the standard complete verifications are correct
    @dev The seller was retrieved from the already verified initOwnership tree
    @dev The buyer was derived from the txData (derived from message & buyerSig)    
    @dev The auctionId was retrieved from txData, and needs to be compared 
    @dev against the auctionId inside marketData from initOwnership tree    
    */
    function isCompleteValid(
        address prevOwner,
        address buyerAddr,
        bytes memory marketData,
        bytes32 auctionId,
        uint256 currentVerse
    ) external pure returns (bool ok);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
 @title Interface to contract with pure functions needed in challenges involving buyNow TXs
 @author Freeverse.io, www.freeverse.io
*/

interface IChallengeLibBuyNow {
    /**
    @dev Reverts unless the data provided inside txData matches the requirements.
    */
    function verifyBuyNowTXData(
        bytes memory txData,
        uint256 challengedOwnershipPos,
        uint256 assetIdInOwnershipData,
        bytes32 lastTXSubmissionRoot
    ) external pure;

    /**
    @dev Returns true if props inside txData are correct are included in the universeRoot.
         If assetCID is empty, the transfer is accepted as a transfer that does not check
         assetProps, and hence does not perform any check, just returns true.
    */
    function buyNowTXCertifyAssetProps(
        bytes32 universeRoot,
        bytes memory txData
    ) external pure returns (bool isOK);

    /**
    @dev Returns true if the provided raw buyNow TX data is in a Merkle tree with root TXRoot (serialized version)
    */
    function isBuyNowTXIncluded(bytes memory data, bytes32 txRoot)
        external
        pure
        returns (bool);

    /**
    @dev Hashes a BuyNow TX, allowing proof of inclusion
    */
    function hashBuyNowTX(bytes memory data) external pure returns (bytes32);

    /**
    @dev Unpacks serialized data to call isBuyNowValid
    */
    function isBuyNowValidSerialized(
        uint256 currentVerse,
        bytes memory txData,
        bytes memory initOwnershipRaw
    ) external pure returns (bool ok);

    /**
    @dev Checks if the standard buyNow verifications are correct
    */
    function isBuyNowValid(
        address prevOwner,
        address buyer,
        bytes memory sellerSig,
        bytes memory marketData,
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        uint256 currentVerse
    ) external pure returns (bool ok);

    /**
    @dev Returns the signer of the putForSaleBuyNow transaction
    */
    function buyNowTXRecoverSeller(
        bytes32 hiddenPrice,
        uint256 assetId,
        uint32 validUntil,
        bytes memory signature
    ) external pure returns (address);
}