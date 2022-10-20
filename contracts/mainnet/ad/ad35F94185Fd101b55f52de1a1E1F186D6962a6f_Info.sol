// SPDX-License-Identifier: BUSL-1.1
// License details specified at address returned by calling the function: license()
pragma solidity =0.8.11;

/**
 @title Main view functions for applications that require ownership/prop verification 
 @author Freeverse.io, www.freeverse.io
*/

import "../interfaces/IInfo.sol";
import "../interfaces/IStorageGetters.sol";

import "../pure/InfoBase.sol";

contract Info is IInfo, InfoBase {
    address private _sto;

    constructor(address storageAddress) {
        _sto = storageAddress;
    }

    /// @inheritdoc IInfo
    function license() external view returns (string memory) {
        return IStorageGetters(_sto).license();
    }

    /// @inheritdoc IInfo
    function isCurrentOwnerOfAssetWithProps(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        string memory assetCID,
        bytes memory ownershipProof,
        bytes memory propsProof
    ) public view returns (bool) {
        return
            isCurrentOwner(assetId, owner, marketData, ownershipProof) &&
            isCurrentAssetProps(assetId, assetCID, propsProof);
    }

    /// @inheritdoc IInfo
    function isCurrentOwner(
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) public view returns (bool) {
        (, , uint256 completedVerse) = IStorageGetters(_sto).exportRequestInfo(
            assetId
        );
        if (completedVerse > 0) return false;
        return
            isOwnerInOwnershipRoot(
                currentSettledOwnershipRoot(),
                assetId,
                owner,
                marketData,
                proof
            );
    }

    /// @inheritdoc IInfo
    function wasOwnerAtVerse(
        uint256 verse,
        uint256 assetId,
        address owner,
        bytes memory marketData,
        bytes memory proof
    ) public view returns (bool) {
        (, , uint256 completedVerse) = IStorageGetters(_sto).exportRequestInfo(
            assetId
        );
        if (completedVerse > 0 && completedVerse <= verse) return false;
        return
            isOwnerInOwnershipRoot(
                IStorageGetters(_sto).ownershipRootAtVerse(verse),
                assetId,
                owner,
                marketData,
                proof
            );
    }

    /// @inheritdoc IInfo
    function isCurrentOwnerSerialized(bytes memory data)
        public
        view
        returns (bool)
    {
        return
            isCurrentOwner(
                ownAssetId(data),
                ownOwner(data),
                ownMarketData(data),
                ownProof(data)
            );
    }

    /// @inheritdoc IInfo
    function wasOwnerAtVerseSerialized(uint256 verse, bytes memory data)
        public
        view
        returns (bool)
    {
        return
            wasOwnerAtVerse(
                verse,
                ownAssetId(data),
                ownOwner(data),
                ownMarketData(data),
                ownProof(data)
            );
    }

    /// @inheritdoc IInfo
    function isCurrentAssetProps(
        uint256 assetId,
        string memory assetCID,
        bytes memory proof
    ) public view returns (bool) {
        return
            isAssetPropsInUniverseRoot(
                IStorageGetters(_sto).universeRootCurrent(
                    decodeUniverseIdx(assetId)
                ),
                proof,
                assetId,
                assetCID
            );
    }

    /// @inheritdoc IInfo
    function wasAssetPropsAtVerse(
        uint256 assetId,
        uint256 verse,
        string memory assetCID,
        bytes memory proof
    ) public view returns (bool) {
        return
            isAssetPropsInUniverseRoot(
                IStorageGetters(_sto).universeRootAtVerse(
                    decodeUniverseIdx(assetId),
                    verse
                ),
                proof,
                assetId,
                assetCID
            );
    }

    /// @inheritdoc IInfo
    function currentSettledOwnershipRoot() public view returns (bytes32) {
        (
            bool isInChallengeOver,
            uint8 actualLevel,
            uint256 txVerse
        ) = isInChallengePeriodFinishedPhase();
        // If phase 3:
        if (isInChallengeOver)
            return
                IStorageGetters(_sto).challengesOwnershipRoot(actualLevel - 1);
        uint256 ownVerse = IStorageGetters(_sto).ownershipCurrentVerse();
        // If phase 1:
        if (txVerse > ownVerse)
            return IStorageGetters(_sto).ownershipRootCurrent();
        // If phase 2:
        return IStorageGetters(_sto).ownershipRootAtVerse(ownVerse - 1);
    }

    /// @inheritdoc IInfo
    function currentSettledOwnershipVerse() public view returns (uint256) {
        (
            bool isInChallengeOver,
            ,
            uint256 txVerse
        ) = isInChallengePeriodFinishedPhase();
        return isInChallengeOver ? txVerse : txVerse - 1;
    }

    /// @inheritdoc IInfo
    function isInChallengePeriodFinishedPhase()
        public
        view
        returns (
            bool isInChallengeOver,
            uint8 actualLevel,
            uint256 txVerse
        )
    {
        txVerse = IStorageGetters(_sto).txRootsCurrentVerse();
        (isInChallengeOver, actualLevel) = isInChallengePeriodFinishedPhasePure(
            IStorageGetters(_sto).nTXsCurrent(),
            txVerse,
            IStorageGetters(_sto).ownershipSubmissionTimeCurrent(),
            IStorageGetters(_sto).challengeWindowCurrent(),
            IStorageGetters(_sto).txSubmissionTimeCurrent(),
            block.timestamp,
            IStorageGetters(_sto).challengesLevel()
        );
    }

    /// @inheritdoc IInfo
    function isReadyForTXSubmission()
        public
        view
        returns (bool isReady, uint8 actualLevel)
    {
        bool isInChallengeOver;
        (isInChallengeOver, actualLevel, ) = isInChallengePeriodFinishedPhase();
        isReady =
            isInChallengeOver &&
            (plannedTime(
                IStorageGetters(_sto).txRootsCurrentVerse() + 1,
                IStorageGetters(_sto).referenceVerse(),
                IStorageGetters(_sto).referenceTime(),
                IStorageGetters(_sto).verseInterval()
            ) < block.timestamp);
    }

    /// @inheritdoc IInfo
    function plannedTime(
        uint256 verse,
        uint256 referenceVerse,
        uint256 referenceTime,
        uint256 verseInterval
    ) public pure returns (uint256) {
        return referenceTime + (verse - referenceVerse) * verseInterval;
    }

    /// @inheritdoc IInfo
    function isReadyForChallenge() public view returns (bool) {
        (bool isSettled, , ) = getCurrentChallengeStatus();
        return !isSettled;
    }

    /// @inheritdoc IInfo
    function getCurrentChallengeStatus()
        public
        view
        returns (
            bool isSettled,
            uint8 actualLevel,
            uint8 nJumps
        )
    {
        return
            computeChallStatus(
                IStorageGetters(_sto).nTXsCurrent(),
                block.timestamp,
                IStorageGetters(_sto).txSubmissionTimeCurrent(),
                IStorageGetters(_sto).ownershipSubmissionTimeCurrent(),
                IStorageGetters(_sto).challengeWindowCurrent(),
                IStorageGetters(_sto).challengesLevel()
            );
    }

    /// @inheritdoc IInfo
    function isAssetBlockedByExport(uint256 assetId, address currentOwner)
        public
        view
        returns (bool)
    {
        (
            address requestOwner,
            uint256 requestVerse,
            uint256 completedVerse
        ) = IStorageGetters(_sto).exportRequestInfo(assetId);

        return
            isAssetBlockedByExportPure(
                currentOwner,
                IStorageGetters(_sto).txRootsCurrentVerse(),
                requestOwner,
                requestVerse,
                completedVerse
            );
    }

    /// @inheritdoc IInfo
    function isAssetBlockedByExportPure(
        address currentOwner,
        uint256 currentVerse,
        address requestOwner,
        uint256 requestVerse,
        uint256 completedVerse
    ) public pure returns (bool) {
        if (completedVerse > 0) return true; // already fully exported
        if (requestOwner == address(0)) return false; // no request entry
        if (currentOwner != requestOwner) return false; // a previous owner had requested, but not completed, the export; current owner is free to operate with it
        // finally: make sure the request arrived, at least, one verse ago.
        return (currentVerse > (requestVerse + 1));
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
            assetPropsVerse := mload(add(serialized, 49))
        }
    }

    function buyNowTXPosTX(bytes memory serialized)
        public
        pure
        returns (uint256 pos)
    {
        assembly {
            pos := mload(add(serialized, 81))
        }
    }

    function buyNowTXValidUntil(bytes memory serialized)
        public
        pure
        returns (uint32 validUntil)
    {
        assembly {
            validUntil := mload(add(serialized, 85))
        }
    }

    function buyNowTXAssetId(bytes memory serialized)
        public
        pure
        returns (uint256 assetId)
    {
        assembly {
            assetId := mload(add(serialized, 117))
        }
    }

    function buyNowTXHiddenPrice(bytes memory serialized)
        public
        pure
        returns (bytes32 buyerHiddenPrice)
    {
        assembly {
            buyerHiddenPrice := mload(add(serialized, 149))
        }
    }

    function buyNowTXBuyer(bytes memory serialized)
        public
        pure
        returns (address buyer)
    {
        assembly {
            buyer := mload(add(serialized, 169))
        }
        return buyer;
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
            assetCIDbytes[i] = serialized[169 + i];
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
            proofProps[i] = serialized[169 + assetCIDlen + i];
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
            signature[i] = serialized[169 + assetCIDlen + proofPropsLen + i];
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
        uint32 nEntries;
        assembly {
            nEntries := mload(add(serialized, 17))
        }
        uint32 offset = 169 +
            assetCIDlen +
            proofPropsLen +
            sellerSigLength;
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
        if (assetProps.length == 0) return 0;
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
        // return false if leafPos was too large for given tree depth
        // (at level previous to root, leafPos had to be 0 or 1,
        // so at the end of last iteration, it must be 0)
        return (leafPos == 0) && (root == leafHash);
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
        nLeaves /= 2;
        bytes32[] memory _leaves = new bytes32[](nLeaves);

        // level = 0 uses the original leaves:
        uint256 nLeavesNonNull = leaves.length / 2;
        for (uint256 pos = 0; pos < nLeavesNonNull; pos++) {
            _leaves[pos] = hash_node(leaves[2 * pos], leaves[2 * pos + 1]);
        }

        if (leaves.length % 2 != 0) {
            _leaves[nLeavesNonNull] = hash_node(leaves[leaves.length - 1], NULL_BYTES32);
            nLeavesNonNull += 1;
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
                : buyNowTXBuyer(txData); // owner should now be the buyer
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