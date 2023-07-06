// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import {LibUnicornDNA} from "LibUnicornDNA.sol";
import {LibDiamond} from "LibDiamond.sol";
import {LibMumbaiDebugV1} from "LibMumbaiDebugV1.sol";
import {LibIdempotence} from "LibIdempotence.sol";
import {LibHatching} from "LibHatching.sol";
import "SignatureChecker.sol";
import {LibServerSideSigning} from "LibServerSideSigning.sol";
import {LibRNG} from "LibRNG.sol";
import "ERC721.sol";
import {LibElo} from "LibElo.sol";
import {LibEvents} from "LibEvents.sol";
import {LibCheck} from "LibCheck.sol";

contract DebugFacet2  {

    function debugChangeClass(uint256 tokenId, uint8 classId) external {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        uint256 dna = LibUnicornDNA._getCanonicalDNA(tokenId);
        dna = LibUnicornDNA._setClass(dna, classId);
        LibUnicornDNA._setDNA(tokenId, dna);
    }

    function debugGetRoundtripId(uint256 _tokenId) external view returns (
        uint256 breedingRoundtrip,
        uint256 hatchingRoundtrip,
        uint256 evolutionRoundtrip
    ) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();

        //  TODO: add breeding
        breedingRoundtrip = 0;

        //  Hatching
        hatchingRoundtrip = LibHatching.getRoundTripIdForToken(_tokenId);

        //  TODO: add evolution
        evolutionRoundtrip = 0;
    }

    function debugSpoofHatchRoundtrip (uint256 tokenId) external {
        debugSetHatchRoundtripState(tokenId, tokenId, bytes32(tokenId), 1026062318, 2500, 33, 44, 55, block.timestamp);
    }


    function debugSetHatchRoundtripState (
        uint256 tokenId,
        uint256 roundTripId,
        bytes32 vrfRequestId,
        uint256 blockDeadline,
        uint256 inheritanceChance,
        uint256 rng,
        uint256 rngRandomness,
        uint256 rngBlockNumber,
        uint256 birthday
    ) public {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        LibHatching.LibHatchingStorage storage lhs = LibHatching.hatchingStorage();
        lhs.roundTripIdByTokenId[tokenId] = roundTripId;
        lhs.vrfRequestIdByRoundTripId[roundTripId] = vrfRequestId;
        lhs.blockDeadlineByVRFRequestId[vrfRequestId] = blockDeadline;
        lhs.inheritanceChanceByVRFRequestId[vrfRequestId] = inheritanceChance;
        lhs.rngByVRFRequestId[vrfRequestId] = rng;
        LibDiamond.diamondStorage().rng_randomness[vrfRequestId] = rngRandomness;
        lhs.rngBlockNumberByVRFRequestId[vrfRequestId] = rngBlockNumber;
        LibHatching.setBirthday(vrfRequestId, birthday);

        lhs.tokenIdByVRFRequestId[vrfRequestId] = tokenId;
        lhs.roundTripIdByVRFRequestId[vrfRequestId] = roundTripId;
        lhs.birthdayByVRFRequestId[vrfRequestId] = birthday;
    }

    function debugDumpHatchRoundtrip(uint256 tokenId) external view returns (
        uint256 roundTripId,
        bytes32 vrfRequestId,
        uint256 blockDeadline,
        uint256 inheritanceChance,
        uint256 rng,
        uint256 rngRandomness,
        uint256 rngBlockNumber,
        uint256 canonicalDNA,
        uint256 predictedDNA,
        uint256 predictedBirthday
    ) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibHatching.LibHatchingStorage storage lhs = LibHatching.hatchingStorage();
        roundTripId = lhs.roundTripIdByTokenId[tokenId];
        vrfRequestId = lhs.vrfRequestIdByRoundTripId[roundTripId];
        blockDeadline = lhs.blockDeadlineByVRFRequestId[vrfRequestId];
        inheritanceChance = lhs.inheritanceChanceByVRFRequestId[vrfRequestId];
        rng = lhs.rngByVRFRequestId[vrfRequestId];
        rngRandomness = LibDiamond.diamondStorage().rng_randomness[vrfRequestId];
        rngBlockNumber = lhs.rngBlockNumberByVRFRequestId[vrfRequestId];
        canonicalDNA = LibUnicornDNA._getCanonicalDNA(tokenId);

        if (
            !LibIdempotence._getHatchingStarted(tokenId) &&
            LibIdempotence._getHatchingRandomnessFulfilled(tokenId) &&
            LibUnicornDNA._getLifecycleStage(canonicalDNA) == LibUnicornDNA.LIFECYCLE_EGG
        ) {
            // birthday
            predictedBirthday = LibHatching.predictBabyBirthday(tokenId);

            if (rngBlockNumber > 0 && rngBlockNumber < block.number) {
                predictedDNA = LibHatching.predictBabyDNA(tokenId);
            }
        }
    }

    function debugGetBreedingRoundtrip(uint256 _roundtripId) external view returns (
        uint256 roundTripId,
        uint256[3] memory possibleClasses,
        uint256[3] memory classProbabilities,
        uint256 ttlBlock,
        uint256 eggId
    ) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        uint256[8] storage breeding = LibDiamond.diamondStorage().breedingByRoundTripId[_roundtripId];
        roundTripId = _roundtripId;
        possibleClasses = [breeding[0], breeding[1], breeding[2]];
        classProbabilities = [breeding[3], breeding[4], breeding[5]];
        ttlBlock = breeding[6];
        eggId = breeding[7];
    }

    function debugGetHatchRoundtrip(uint256 _roundtripId) external view returns (
        uint256 roundTripId,
        uint256 blockDeadline,
        uint256 tokenId,
        uint256 inheritanceChance
    ) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibHatching.LibHatchingStorage storage lhs = LibHatching.hatchingStorage();
        roundTripId = _roundtripId;
        bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[_roundtripId];
        blockDeadline = lhs.blockDeadlineByVRFRequestId[vrfRequestId];
        tokenId = lhs.tokenIdByVRFRequestId[vrfRequestId];
        inheritanceChance = lhs.inheritanceChanceByVRFRequestId[vrfRequestId];
    }

    function debugGetStructHash(uint256 nonce) public view returns (bytes32) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        uint256 roundTripId = 99;
        uint256 tokenId = nonce;
        uint256 inheritanceChance = 2500;
        uint256 bundleId = 111;
        uint256 blockDeadline = 28059402;
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "BeginHatchingingPayload(uint256 roundTripId, uint256 tokenId, uint256 inheritanceChance, uint256 bundleId, uint256 blockDeadline)"
                ),
                roundTripId,
                tokenId,
                inheritanceChance,
                bundleId,
                blockDeadline
            )
        );
        return structHash;
    }

    function debugGetSSSHash(uint256 nonce) external view returns (bytes32 structHash, bytes32 digest) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        structHash = debugGetStructHash(nonce);
        digest = LibServerSideSigning._hashTypedDataV4(structHash);
    }

    function debugTestSSS(uint256 nonce, bytes memory signature) external view returns (bytes32 structHash, bytes32 digest, bool signatureCheck, address gameServer, address sender){
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        structHash = debugGetStructHash(nonce);
        digest = LibServerSideSigning._hashTypedDataV4(structHash);
        gameServer = LibDiamond.gameServer();
        signatureCheck = SignatureChecker.isValidSignatureNow(gameServer, digest, signature);
        sender = msg.sender;
    }

    function debugSpoofUnstableHatchingState(uint256 tokenId) external {
        LibMumbaiDebugV1.enforceTestnet();
        LibMumbaiDebugV1.enforceAdmin();

        LibIdempotence._clearState(tokenId);
        LibIdempotence._setHatchingStarted(tokenId, true);
        LibIdempotence._setHatchingRandomnessFulfilled(tokenId, true);

        LibHatching.hatchingStorage().rngBlockNumberByVRFRequestId[bytes32(tokenId)] = 1;
        LibDiamond.diamondStorage().bio_clock[tokenId] = 1;

        uint256 dna = LibUnicornDNA._getCanonicalDNA(tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        dna = LibUnicornDNA._setOrigin(dna, false);
        dna = LibUnicornDNA._setGameLocked(dna, true);
        dna = LibUnicornDNA._setLifecycleStage(dna, 0);
        LibUnicornDNA._setDNA(tokenId, dna);
    }

    function debugCheckPredictiveDNA(uint256 tokenId) external view returns (
        bool shouldUsePredictiveDNA,
        uint256 canonicalDNA,
        uint256 predictedDNA
    ) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        shouldUsePredictiveDNA = LibHatching.shouldUsePredictiveDNA(tokenId);
        canonicalDNA = LibUnicornDNA._getCanonicalDNA(tokenId);
        predictedDNA = LibHatching.predictBabyDNA(tokenId);
    }

    function debugGetParents(uint256 tokenId) external view returns (uint256 firstParent, uint256 secondParent, uint8 firstParentClass, uint8 secondParentClass) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        firstParent = ds.unicornParents[tokenId][0];
        secondParent = ds.unicornParents[tokenId][1];
        firstParentClass = LibUnicornDNA._getClass(LibUnicornDNA._getDNA(firstParent));
        secondParentClass = LibUnicornDNA._getClass(LibUnicornDNA._getDNA(secondParent));
    }

    function debugTestRNGExpand(uint256 randomness) external view returns (uint256, uint256, uint256, uint256, uint256) {
        LibMumbaiDebugV1.enforceTestnet();
        return (
            LibRNG.expand(10000, randomness, 11),
            LibRNG.expand(10000, randomness, 12),
            LibRNG.expand(10000, randomness, 13),
            LibRNG.expand(10000, randomness, 14),
            LibRNG.expand(10000, randomness, 15)
        );
    }

    function debugTestRandomPartGen(uint256 classId, uint256 slotId, uint256 randomness) external view returns (uint256, uint256, uint256, uint256, uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return (
            LibHatching.getRandomPartId(ds, classId, slotId, randomness, 11),
            LibHatching.getRandomPartId(ds, classId, slotId, randomness, 12),
            LibHatching.getRandomPartId(ds, classId, slotId, randomness, 13),
            LibHatching.getRandomPartId(ds, classId, slotId, randomness, 14),
            LibHatching.getRandomPartId(ds, classId, slotId, randomness, 15)
        );
    }

    function debugTestRandomGeneGen(uint256 classId, uint256 randomness) external view returns (uint256, uint256, uint256, uint256, uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return (
            getRandomGeneId(ds, classId, randomness, 11),
            getRandomGeneId(ds, classId, randomness, 12),
            getRandomGeneId(ds, classId, randomness, 13),
            getRandomGeneId(ds, classId, randomness, 14),
            getRandomGeneId(ds, classId, randomness, 15)
        );
    }

    function getRandomGeneId(
        LibDiamond.DiamondStorage storage ds,
        uint256 _classId,
        uint256 _rngSeed,
        uint256 _salt
    ) private view returns (uint256) {
        uint256 numGenes = ds.geneBuckets[_classId].length;
        uint256 target = LibRNG.expand(ds.geneBucketSumWeights[_classId], _rngSeed, _salt) + 1;
        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < numGenes; ++i) {
            uint256 geneId = ds.geneBuckets[_classId][i];
            cumulativeWeight += ds.geneWeightById[geneId];
            if (target <= cumulativeWeight) {
                return geneId;
            }
        }
        revert("DebugFacet2: Failed getting RNG gene");
    }


    function debugDumpBodyPartBuckets(uint8 classId, uint8 slotId) external view returns (uint256[] memory){
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        return LibDiamond.diamondStorage().bodyPartBuckets[classId][slotId];
    }

    function debugDumpGenes(uint8 classId) external view returns (uint256[] memory) {
        LibMumbaiDebugV1.enforceTestnet();
        return LibDiamond.diamondStorage().geneBuckets[classId];
    }

    function debugDumpGeneBucketSumWeights(uint8 classId) external view returns (uint256) {
        LibMumbaiDebugV1.enforceTestnet();
        return LibDiamond.diamondStorage().geneBucketSumWeights[classId];
    }

    function debugGetBodyPartDefinition(uint256 globalId) external view returns (uint256 localId, bool isMythic, uint256 inheritedGene, uint256 weight) {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        localId = ds.bodyPartLocalIdFromGlobalId[globalId];
        isMythic = ds.bodyPartIsMythic[globalId];
        inheritedGene = ds.bodyPartInheritedGene[globalId];
        weight = ds.bodyPartWeight[globalId];
    }

    function debugGetGeneDef(uint256 geneId) external view returns (uint256 tier, uint256 nextUpgrade, uint256 application) {
        LibMumbaiDebugV1.enforceTestnet();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        tier = ds.geneTierById[geneId];
        nextUpgrade = ds.geneTierUpgradeById[geneId];
        application = ds.geneApplicationById[geneId];
        // geneBonusStatByGeneId[geneId][1]
    }

    function debugGetBodyPartsTotalWeight(uint256 _classId, uint256 _slotId) public view returns(uint256) {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 i = 0;
        uint256 numBodyParts = ds.bodyPartBuckets[_classId][_slotId].length;
        uint256 totalWeight = 0;
        for (i = 0; i < numBodyParts; i++) {
            totalWeight += ds.bodyPartWeight[ds.bodyPartBuckets[_classId][_slotId][i]];
        }
        return totalWeight;
    }

    function debugSetVRFFailure(uint256 tokenId, bool willItFail) external {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        LibMumbaiDebugV1.setVRFFailure(tokenId, willItFail);
    }

    function debugGetVRFFailure(uint256 tokenId) external view returns(bool) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibMumbaiDebugV1.getVRFFailure(tokenId);
    }


    function debugDumpHatchingData(uint256 tokenId) external view returns(
        uint256 blockDeadlineByVRFRequestId,
        uint256 roundTripIdByVRFRequestId,
        bytes32 vrfRequestIdByRoundTripId,
        uint256 tokenIdByVRFRequestId,
        uint256 inheritanceChanceByVRFRequestId,
        uint256 rngByVRFRequestId,
        uint256 rngBlockNumberByVRFRequestId,
        uint256 birthdayByVRFRequestId,
        uint256 roundTripIdByTokenId
    ){
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibMumbaiDebugV1.debugDumpHatchingData(tokenId);
    }

    function debugTestHatchMatching(uint256 tokenId) external view returns (
        uint256 firstParentDNA,
        uint256 secondParentDNA,
        uint256 dna,
        uint256 classId,
        uint256 matching
    ) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibMumbaiDebugV1.debugTestHatchMatching(tokenId);
    }

    function debugStepthroughHatchingA(uint256 tokenId) external view returns (
        uint256 dnaA,
        uint256 dnaB,
        uint256 dnaC,
        uint256 rng11,
        uint256 rng12,
        string memory bodyTrace,
        uint256 partId
    ) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibMumbaiDebugV1.debugStepthroughHatchingA(tokenId);
    }

    function debugGetBodyPartBucket(uint256 i, uint256 j) public view returns(uint256[] memory) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibDiamond.diamondStorage().bodyPartBuckets[i][j];
    }

    function debugGetBodyPartWeight(uint256 globalPartId) public view returns(uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibDiamond.diamondStorage().bodyPartWeight[globalPartId];
    }

    function debugGetTotalWeight(uint256 _classId, uint256 _slotId) public view returns(uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 i = 0;
        uint256 numBodyParts = ds.bodyPartBuckets[_classId][_slotId].length;

        uint256 totalWeight = 0;
        for (i = 0; i < numBodyParts; i++) {
            totalWeight += ds.bodyPartWeight[ds.bodyPartBuckets[_classId][_slotId][i]];
        }
        return totalWeight;
    }

    function debugGetNumBodyParts(uint256 _classId, uint256 _slotId) public view returns(uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.bodyPartBuckets[_classId][_slotId].length;
    }

    function debugGetRandomPartId(
        uint256 classId,
        uint256 slotId,
        uint256 randomness,
        uint256 salt
    ) external view returns (uint256) { //  globalId of part
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return LibHatching.getRandomPartId(ds, classId, slotId, randomness, salt);
    }

    function debugHatchingRNGGates(uint256 tokenId) public view returns (
        uint256 randomness,
        uint256 inheritanceChance,
        uint256 bodyChance,
        uint256 faceChance,
        uint256 hornChance,
        uint256 hoovesChance,
        uint256 maneChance,
        uint256 tailChance
    ) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibMumbaiDebugV1.debugHatchingRNGGates(tokenId);
    }


    function debugInheritBody(uint256 dna, uint256 parent) external view returns (uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibUnicornDNA._inheritBody(dna, parent);
    }

    function debugInheritFace(uint256 dna, uint256 parent) external view returns (uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibUnicornDNA._inheritFace(dna, parent);
    }


    function debugInheritHorn(uint256 dna, uint256 parent) external view returns (uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibUnicornDNA._inheritHorn(dna, parent);
    }

    function debugInheritHooves(uint256 dna, uint256 parent) external view returns (uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibUnicornDNA._inheritHooves(dna, parent);
    }


    function debugInheritMane(uint256 dna, uint256 parent) external view returns (uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibUnicornDNA._inheritMane(dna, parent);
    }


    function debugInheritTail(uint256 dna, uint256 parent) external view returns (uint256) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        return LibUnicornDNA._inheritTail(dna, parent);
    }

    function debugDNAParentFullMatch(uint256 eggId, uint256 parentId) external view returns (bool) {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        bool matches = true;
        uint256 eggDNA = LibUnicornDNA._getCanonicalDNA(eggId);
        uint256 parentDNA = LibUnicornDNA._getCanonicalDNA(parentId);
        //Body
        matches = matches && (LibUnicornDNA._getBodyMajorGene(eggDNA) == LibUnicornDNA._getBodyMajorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getBodyMidGene(eggDNA) == LibUnicornDNA._getBodyMidGene(parentDNA));
        matches = matches && (LibUnicornDNA._getBodyMinorGene(eggDNA) == LibUnicornDNA._getBodyMinorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getBodyPart(eggDNA) == LibUnicornDNA._getBodyPart(parentDNA));

        //Face
        matches = matches && (LibUnicornDNA._getFaceMajorGene(eggDNA) == LibUnicornDNA._getFaceMajorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getFaceMidGene(eggDNA) == LibUnicornDNA._getFaceMidGene(parentDNA));
        matches = matches && (LibUnicornDNA._getFaceMinorGene(eggDNA) == LibUnicornDNA._getFaceMinorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getFacePart(eggDNA) == LibUnicornDNA._getFacePart(parentDNA));

        //Horn
        matches = matches && (LibUnicornDNA._getHornMajorGene(eggDNA) == LibUnicornDNA._getHornMajorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getHornMidGene(eggDNA) == LibUnicornDNA._getHornMidGene(parentDNA));
        matches = matches && (LibUnicornDNA._getHornMinorGene(eggDNA) == LibUnicornDNA._getHornMinorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getHornPart(eggDNA) == LibUnicornDNA._getHornPart(parentDNA));

        //Hooves
        matches = matches && (LibUnicornDNA._getHoovesMajorGene(eggDNA) == LibUnicornDNA._getHoovesMajorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getHoovesMidGene(eggDNA) == LibUnicornDNA._getHoovesMidGene(parentDNA));
        matches = matches && (LibUnicornDNA._getHoovesMinorGene(eggDNA) == LibUnicornDNA._getHoovesMinorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getHoovesPart(eggDNA) == LibUnicornDNA._getHoovesPart(parentDNA));

        //Mane
        matches = matches && (LibUnicornDNA._getManeMajorGene(eggDNA) == LibUnicornDNA._getManeMajorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getManeMidGene(eggDNA) == LibUnicornDNA._getManeMidGene(parentDNA));
        matches = matches && (LibUnicornDNA._getManeMinorGene(eggDNA) == LibUnicornDNA._getManeMinorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getManePart(eggDNA) == LibUnicornDNA._getManePart(parentDNA));

        //Tail
        matches = matches && (LibUnicornDNA._getTailMajorGene(eggDNA) == LibUnicornDNA._getTailMajorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getTailMidGene(eggDNA) == LibUnicornDNA._getTailMidGene(parentDNA));
        matches = matches && (LibUnicornDNA._getTailMinorGene(eggDNA) == LibUnicornDNA._getTailMinorGene(parentDNA));
        matches = matches && (LibUnicornDNA._getTailPart(eggDNA) == LibUnicornDNA._getTailPart(parentDNA));

        return matches;
    }

    function debugSetCachedDNA(uint256 tokenId, uint256 cachedDNA) external returns (bool) {
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        LibUnicornDNA.LibDNAStorage storage lds = LibUnicornDNA.dnaStorage();
        lds.cachedDNA[tokenId] = cachedDNA;
    }

    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    function debugSpoofTransferEventsForOS(uint256 from, uint256 to) external {
        LibMumbaiDebugV1.enforceTestnet();
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if(to > ds.erc721_allTokens.length) to = ds.erc721_allTokens.length;
        for(uint256 i = from; i <= to; ++i) {
            address owner = ds.erc721_owners[i];
            if(owner != address(0)) {   // _exists()
                emit LibEvents.Transfer(address(0), ds.erc721_owners[i], i);
            }
        }
    }

    function debugFirstNameIsListed(uint256 _tokenId) external view returns(bool isListed){
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        isListed = false;
        for(uint256 i = 0; i < ds.validFirstNames.length; i++) {
            if(ds.validFirstNames[i] == LibUnicornDNA._getFirstNameIndex(LibUnicornDNA._getDNA(_tokenId))) {
                isListed = true;
            }
        }
        return isListed;
    }

    function debugLastNameIsListed(uint256 _tokenId) external view returns(bool isListed){
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        isListed = false;
        for(uint256 i = 0; i < ds.validLastNames.length; i++) {
            if(ds.validLastNames[i] == LibUnicornDNA._getLastNameIndex(LibUnicornDNA._getDNA(_tokenId))) {
                isListed = true;
            }
        }
        return isListed;
    }


    /// @notice Set raw unicorn record for given tokenIds and unicornRecord
    /// @dev The external function can be called only by debug admin
    /// @param tokenId - Unique id of the token
    /// @param unicornRecord - unicorn record to be set for tokenId
    /// @custom:emits UnicornRecordChanged
    function debugSetRawUnicornRecord(uint256 tokenId, uint256 unicornRecord) external {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        LibElo._setRawUnicornRecord(tokenId, unicornRecord);
    }

    /// @notice Set raw unicorn record for given tokenIds
    /// @dev The external function can be called only by debug admin. It also validates the input array length.
    /// @param tokenIds - Unique ids of the tokens
    /// @param unicornRecords - unicorn records to be set for tokenIds
    /// @custom:emits UnicornRecordChanged
    function debugSetBatchRawUnicornRecord(
        uint256[] memory tokenIds,
        uint256[] memory unicornRecords
    ) external {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        LibCheck.enforceEqualArrayLength(tokenIds, unicornRecords);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            LibElo._setRawUnicornRecord(tokenIds[i], unicornRecords[i]);
        }
    }

    /// @notice Set target unicorn version for jousting system
    /// @dev The external function can be called only by debug admin
    /// @param _versionNumber - New target unicorn version number
    /// @custom:emits TargetUnicornVersionUpdated
    function debugSetTargetUnicornVersion(uint8 _versionNumber) external {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        LibElo._setTargetUnicornVersion(_versionNumber);
    }

    /// @notice Set unicorn record for the token in jousting system
    /// @dev The external function can be called only by debug admin
    /// @param tokenId - Unique id of the token
    /// @param joustWins - Joust matches won
    /// @param joustLosses - Joust matches lost
    /// @param joustTournamentWins - Joust tournament won
    /// @param joustEloScore - Joust elo score
    /// @custom:emits UnicornRecordChanged
    function debugSetJoustRecord(
        uint256 tokenId,
        uint256 joustWins,
        uint256 joustLosses,
        uint256 joustTournamentWins,
        uint256 joustEloScore
    ) external {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        LibElo._setJoustRecord(
            tokenId,
            joustWins,
            joustLosses,
            joustTournamentWins,
            joustEloScore
        );
    }

    /// @notice Set unicorn record for the tokens in jousting system
    /// @dev The external function can be called only by debug admin
    /// @param tokenIds - Unique id of the tokens
    /// @param joustWins - Joust matches won
    /// @param joustLosses - Joust matches lost
    /// @param joustTournamentWins - Joust tournament won
    /// @param joustEloScores - Joust elo scores
    /// @custom:emits UnicornRecordChanged
    function debugSetBatchJoustRecord(
        uint256[] memory tokenIds,
        uint256[] memory joustWins,
        uint256[] memory joustLosses,
        uint256[] memory joustTournamentWins,
        uint256[] memory joustEloScores
    ) external {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibMumbaiDebugV1.enforceDebuggingEnabled();
        LibMumbaiDebugV1.enforceAdmin();
        LibCheck.enforceEqualArrayLength(tokenIds, joustWins);
        LibCheck.enforceEqualArrayLength(tokenIds, joustLosses);
        LibCheck.enforceEqualArrayLength(tokenIds, joustTournamentWins);
        LibCheck.enforceEqualArrayLength(tokenIds, joustEloScores);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            LibElo._setJoustRecord(
                tokenIds[i],
                joustWins[i],
                joustLosses[i],
                joustTournamentWins[i],
                joustEloScores[i]
            );
        }
    }

    function debugMintFromDNA(address _to, uint256 _dna, string calldata _tokenURI, bool _emitTransferEvent) external {
        LibMumbaiDebugV1.enforceTestnetOrLocal();
        LibMumbaiDebugV1.enforceDebuggerOrAdmin();
        LibMumbaiDebugV1.mintFromDNA(_to, _dna, _tokenURI, _emitTransferEvent);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";
import {LibHatching} from "LibHatching.sol";


library LibUnicornDNA {
    event DNAUpdated(uint256 tokenId, uint256 dna);

    uint256 internal constant STAT_ATTACK = 1;
    uint256 internal constant STAT_ACCURACY = 2;
    uint256 internal constant STAT_MOVE_SPEED = 3;
    uint256 internal constant STAT_ATTACK_SPEED = 4;
    uint256 internal constant STAT_DEFENSE = 5;
    uint256 internal constant STAT_VITALITY = 6;
    uint256 internal constant STAT_RESISTANCE = 7;
    uint256 internal constant STAT_MAGIC = 8;

    // uint256 internal constant DNA_VERSION = 1;   // deprecated - use targetDNAVersion()
    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    //  version is in bits 0-7 = 0b11111111
    uint256 internal constant DNA_VERSION_MASK = 0xFF;
    //  origin is in bit 8 = 0b100000000
    uint256 internal constant DNA_ORIGIN_MASK = 0x100;
    //  locked is in bit 9 = 0b1000000000
    uint256 internal constant DNA_LOCKED_MASK = 0x200;
    //  limitedEdition is in bit 10 = 0b10000000000
    uint256 internal constant DNA_LIMITEDEDITION_MASK = 0x400;
    //  lifecycleStage is in bits 11-12 = 0b1100000000000
    uint256 internal constant DNA_LIFECYCLESTAGE_MASK = 0x1800;
    //  breedingPoints is in bits 13-16 = 0b11110000000000000
    uint256 internal constant DNA_BREEDINGPOINTS_MASK = 0x1E000;
    //  class is in bits 17-20 = 0b111100000000000000000
    uint256 internal constant DNA_CLASS_MASK = 0x1E0000;
    //  bodyArt is in bits 21-28 = 0b11111111000000000000000000000
    uint256 internal constant DNA_BODYART_MASK = 0x1FE00000;
    //  bodyMajorGene is in bits 29-36 = 0b1111111100000000000000000000000000000
    uint256 internal constant DNA_BODYMAJORGENE_MASK = 0x1FE0000000;
    //  bodyMidGene is in bits 37-44 = 0b111111110000000000000000000000000000000000000
    uint256 internal constant DNA_BODYMIDGENE_MASK = 0x1FE000000000;
    //  bodyMinorGene is in bits 45-52 = 0b11111111000000000000000000000000000000000000000000000
    uint256 internal constant DNA_BODYMINORGENE_MASK = 0x1FE00000000000;
    //  faceArt is in bits 53-60 = 0b1111111100000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FACEART_MASK = 0x1FE0000000000000;
    //  faceMajorGene is in bits 61-68 = 0b111111110000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FACEMAJORGENE_MASK = 0x1FE000000000000000;
    //  faceMidGene is in bits 69-76 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FACEMIDGENE_MASK = 0x1FE00000000000000000;
    //  faceMinorGene is in bits 77-84 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FACEMINORGENE_MASK = 0x1FE0000000000000000000;
    //  hornArt is in bits 85-92 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HORNART_MASK = 0x1FE000000000000000000000;
    //  hornMajorGene is in bits 93-100 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HORNMAJORGENE_MASK =
        0x1FE00000000000000000000000;
    //  hornMidGene is in bits 101-108 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HORNMIDGENE_MASK =
        0x1FE0000000000000000000000000;
    //  hornMinorGene is in bits 109-116 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HORNMINORGENE_MASK =
        0x1FE000000000000000000000000000;
    //  hoovesArt is in bits 117-124 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HOOVESART_MASK =
        0x1FE00000000000000000000000000000;
    //  hoovesMajorGene is in bits 125-132 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HOOVESMAJORGENE_MASK =
        0x1FE0000000000000000000000000000000;
    //  hoovesMidGene is in bits 133-140 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HOOVESMIDGENE_MASK =
        0x1FE000000000000000000000000000000000;
    //  hoovesMinorGene is in bits 141-148 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_HOOVESMINORGENE_MASK =
        0x1FE00000000000000000000000000000000000;
    //  maneArt is in bits 149-156 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_MANEART_MASK =
        0x001FE0000000000000000000000000000000000000;
    //  maneMajorGene is in bits 157-164 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_MANEMAJORGENE_MASK =
        0x1FE000000000000000000000000000000000000000;
    //  maneMidGene is in bits 165-172 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_MANEMIDGENE_MASK =
        0x1FE00000000000000000000000000000000000000000;
    //  maneMinorGene is in bits 173-180 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_MANEMINORGENE_MASK =
        0x1FE0000000000000000000000000000000000000000000;
    //  tailArt is in bits 181-188 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_TAILART_MASK =
        0x1FE000000000000000000000000000000000000000000000;
    //  tailMajorGene is in bits 189-196 = 0b11111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_TAILMAJORGENE_MASK =
        0x1FE00000000000000000000000000000000000000000000000;
    //  tailMidGene is in bits 197-204 = 0b1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_TAILMIDGENE_MASK =
        0x1FE0000000000000000000000000000000000000000000000000;
    //  tailMinorGene is in bits 205-212 = 0b111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_TAILMINORGENE_MASK =
        0x1FE000000000000000000000000000000000000000000000000000;

    //  firstName index is in bits 213-222 = 0b1111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_FIRST_NAME = 0x7FE00000000000000000000000000000000000000000000000000000;
    //  lastName index is in bits 223-232 = 0b11111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    uint256 internal constant DNA_LAST_NAME = 0x1FF80000000000000000000000000000000000000000000000000000000;

    uint8 internal constant LIFECYCLE_EGG = 0;
    uint8 internal constant LIFECYCLE_BABY = 1;
    uint8 internal constant LIFECYCLE_ADULT = 2;

    uint8 internal constant DEFAULT_BREEDING_POINTS = 8;

    bytes32 private constant DNA_STORAGE_POSITION = keccak256("diamond.libUnicornDNA.storage");

    struct LibDNAStorage {
        mapping(uint256 => uint256) cachedDNA;
    }

    function dnaStorage() internal pure returns (LibDNAStorage storage lds) {
        bytes32 position = DNA_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lds.slot := position
        }
    }

    function _getDNA(uint256 _tokenId) internal view returns (uint256) {
        if(dnaStorage().cachedDNA[_tokenId] > 0) {
            return dnaStorage().cachedDNA[_tokenId];
        } else if (LibHatching.shouldUsePredictiveDNA(_tokenId)) {
            return LibHatching.predictBabyDNA(_tokenId);
        }

        return LibDiamond.diamondStorage().unicorn_dna[_tokenId];
    }

    function _getCanonicalDNA(uint256 _tokenId) internal view returns (uint256) {
        return LibDiamond.diamondStorage().unicorn_dna[_tokenId];
    }

    function _setDNA(uint256 _tokenId, uint256 _dna)
        internal
        returns (uint256)
    {
        require(_dna > 0, "LibUnicornDNA: cannot set 0 DNA");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.unicorn_dna[_tokenId] = _dna;
        emit DNAUpdated(_tokenId, _dna);
        return _dna;
    }

    function _getBirthday(uint256 _tokenId) internal view returns (uint256) {
        if (LibHatching.shouldUsePredictiveDNA(_tokenId)) {
            return LibHatching.predictBabyBirthday(_tokenId);
        }
        return LibDiamond.diamondStorage().hatch_birthday[_tokenId];
    }

    //  The currently supported DNA version - all DNA should be at this number,
    //  or lower if migrating...
    function _targetDNAVersion() internal view returns (uint256) {
        return LibDiamond.diamondStorage().targetDNAVersion;
    }

    function _setVersion(uint256 _dna, uint256 _value)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _value, DNA_VERSION_MASK);
    }

    function _getVersion(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_VERSION_MASK);
    }

    function enforceDNAVersionMatch(uint256 _dna) internal view {
        require(
            _getVersion(_dna) == _targetDNAVersion(),
            "LibUnicornDNA: Invalid DNA version"
        );
    }

    function _setOrigin(uint256 _dna, bool _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_ORIGIN_MASK);
    }

    function _getOrigin(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_ORIGIN_MASK);
    }

    function _setGameLocked(uint256 _dna, bool _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_LOCKED_MASK);
    }

    function _getGameLocked(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_LOCKED_MASK);
    }

    function _setLimitedEdition(uint256 _dna, bool _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_LIMITEDEDITION_MASK);
    }

    function _getLimitedEdition(uint256 _dna) internal pure returns (bool) {
        return LibBin.extractBool(_dna, DNA_LIMITEDEDITION_MASK);
    }

    function _setLifecycleStage(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_LIFECYCLESTAGE_MASK);
    }

    function _getLifecycleStage(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LIFECYCLESTAGE_MASK);
    }

    function _setBreedingPoints(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BREEDINGPOINTS_MASK);
    }

    function _getBreedingPoints(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BREEDINGPOINTS_MASK);
    }

    function _setClass(uint256 _dna, uint8 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, uint256(_val), DNA_CLASS_MASK);
    }

    function _getClass(uint256 _dna) internal pure returns (uint8) {
        return uint8(LibBin.extract(_dna, DNA_CLASS_MASK));
    }

    function _multiSetBody(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_BODYMINORGENE_MASK),
                    _midGene,
                    DNA_BODYMIDGENE_MASK
                ),
                _majorGene,
                DNA_BODYMAJORGENE_MASK
            ),
            _part,
            DNA_BODYART_MASK
        );
    }

    function _inheritBody(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetBody(
            _dna,
            _getBodyPart(_inherited),
            _getBodyMajorGene(_inherited),
            _getBodyMidGene(_inherited),
            _getBodyMinorGene(_inherited)
        );
    }

    function _setBodyPart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BODYART_MASK);
    }

    function _getBodyPart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BODYART_MASK);
    }

    function _setBodyMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BODYMAJORGENE_MASK);
    }

    function _getBodyMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BODYMAJORGENE_MASK);
    }

    function _setBodyMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BODYMIDGENE_MASK);
    }

    function _getBodyMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BODYMIDGENE_MASK);
    }

    function _setBodyMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_BODYMINORGENE_MASK);
    }

    function _getBodyMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_BODYMINORGENE_MASK);
    }

    function _multiSetFace(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_FACEMINORGENE_MASK),
                    _midGene,
                    DNA_FACEMIDGENE_MASK
                ),
                _majorGene,
                DNA_FACEMAJORGENE_MASK
            ),
            _part,
            DNA_FACEART_MASK
        );
    }

    function _inheritFace(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetFace(
            _dna,
            _getFacePart(_inherited),
            _getFaceMajorGene(_inherited),
            _getFaceMidGene(_inherited),
            _getFaceMinorGene(_inherited)
        );
    }

    function _setFacePart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FACEART_MASK);
    }

    function _getFacePart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FACEART_MASK);
    }

    function _setFaceMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FACEMAJORGENE_MASK);
    }

    function _getFaceMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FACEMAJORGENE_MASK);
    }

    function _setFaceMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FACEMIDGENE_MASK);
    }

    function _getFaceMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FACEMIDGENE_MASK);
    }

    function _setFaceMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FACEMINORGENE_MASK);
    }

    function _getFaceMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FACEMINORGENE_MASK);
    }

    function _multiSetHooves(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_HOOVESMINORGENE_MASK),
                    _midGene,
                    DNA_HOOVESMIDGENE_MASK
                ),
                _majorGene,
                DNA_HOOVESMAJORGENE_MASK
            ),
            _part,
            DNA_HOOVESART_MASK
        );
    }

    function _inheritHooves(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetHooves(
            _dna,
            _getHoovesPart(_inherited),
            _getHoovesMajorGene(_inherited),
            _getHoovesMidGene(_inherited),
            _getHoovesMinorGene(_inherited)
        );
    }

    function _setHoovesPart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HOOVESART_MASK);
    }

    function _getHoovesPart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HOOVESART_MASK);
    }

    function _setHoovesMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HOOVESMAJORGENE_MASK);
    }

    function _getHoovesMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HOOVESMAJORGENE_MASK);
    }

    function _setHoovesMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HOOVESMIDGENE_MASK);
    }

    function _getHoovesMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HOOVESMIDGENE_MASK);
    }

    function _setHoovesMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HOOVESMINORGENE_MASK);
    }

    function _getHoovesMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HOOVESMINORGENE_MASK);
    }

    function _multiSetHorn(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_HORNMINORGENE_MASK),
                    _midGene,
                    DNA_HORNMIDGENE_MASK
                ),
                _majorGene,
                DNA_HORNMAJORGENE_MASK
            ),
            _part,
            DNA_HORNART_MASK
        );
    }

    function _inheritHorn(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetHorn(
            _dna,
            _getHornPart(_inherited),
            _getHornMajorGene(_inherited),
            _getHornMidGene(_inherited),
            _getHornMinorGene(_inherited)
        );
    }

    function _setHornPart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HORNART_MASK);
    }

    function _getHornPart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HORNART_MASK);
    }

    function _setHornMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HORNMAJORGENE_MASK);
    }

    function _getHornMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HORNMAJORGENE_MASK);
    }

    function _setHornMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HORNMIDGENE_MASK);
    }

    function _getHornMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HORNMIDGENE_MASK);
    }

    function _setHornMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_HORNMINORGENE_MASK);
    }

    function _getHornMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_HORNMINORGENE_MASK);
    }

    function _multiSetMane(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_MANEMINORGENE_MASK),
                    _midGene,
                    DNA_MANEMIDGENE_MASK
                ),
                _majorGene,
                DNA_MANEMAJORGENE_MASK
            ),
            _part,
            DNA_MANEART_MASK
        );
    }

    function _inheritMane(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetMane(
            _dna,
            _getManePart(_inherited),
            _getManeMajorGene(_inherited),
            _getManeMidGene(_inherited),
            _getManeMinorGene(_inherited)
        );
    }

    function _setManePart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_MANEART_MASK);
    }

    function _getManePart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MANEART_MASK);
    }

    function _setManeMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_MANEMAJORGENE_MASK);
    }

    function _getManeMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MANEMAJORGENE_MASK);
    }

    function _setManeMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_MANEMIDGENE_MASK);
    }

    function _getManeMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MANEMIDGENE_MASK);
    }

    function _setManeMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_MANEMINORGENE_MASK);
    }

    function _getManeMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_MANEMINORGENE_MASK);
    }

    function _multiSetTail(
        uint256 _dna,
        uint256 _part,
        uint256 _majorGene,
        uint256 _midGene,
        uint256 _minorGene
    ) internal pure returns (uint256) {
        return LibBin.splice(
            LibBin.splice(
                LibBin.splice(
                    LibBin.splice(_dna, _minorGene, DNA_TAILMINORGENE_MASK),
                    _midGene,
                    DNA_TAILMIDGENE_MASK
                ),
                _majorGene,
                DNA_TAILMAJORGENE_MASK
            ),
            _part,
            DNA_TAILART_MASK
        );
    }

    function _inheritTail(
        uint256 _dna,
        uint256 _inherited
    ) internal pure returns (uint256) {
        return _multiSetTail(
            _dna,
            _getTailPart(_inherited),
            _getTailMajorGene(_inherited),
            _getTailMidGene(_inherited),
            _getTailMinorGene(_inherited)
        );
    }

    function _setTailPart(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_TAILART_MASK);
    }

    function _getTailPart(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_TAILART_MASK);
    }

    function _setTailMajorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_TAILMAJORGENE_MASK);
    }

    function _getTailMajorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_TAILMAJORGENE_MASK);
    }

    function _setTailMidGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_TAILMIDGENE_MASK);
    }

    function _getTailMidGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_TAILMIDGENE_MASK);
    }

    function _setTailMinorGene(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_TAILMINORGENE_MASK);
    }

    function _getTailMinorGene(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_TAILMINORGENE_MASK);
    }

    function _setFirstNameIndex(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_FIRST_NAME);
    }

    function _getFirstNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_FIRST_NAME);
    }

    function _setLastNameIndex(uint256 _dna, uint256 _val)
        internal
        pure
        returns (uint256)
    {
        return LibBin.splice(_dna, _val, DNA_LAST_NAME);
    }

    function _getLastNameIndex(uint256 _dna) internal pure returns (uint256) {
        return LibBin.extract(_dna, DNA_LAST_NAME);
    }

    //  @return bodyPartIds - An ordered array of bodypart globalIds [body, face, horn, hooves, mane, tail]
    //  @return geneIds - An ordered array of geen ids [
        // bodyMajor, bodyMid, bodyMinor, 
        // faceMajor, faceMid, faceMinor, 
        // hornMajor, hornMid, hornMinor, 
        // hoovesMajor, hoovesMid, hoovesMinor, 
        // maneMajor, maneMid, maneMinor, 
        // tailMajor, tailMid, tailMinor]
    function _getGeneMapFromDNA(uint256 _dna) internal view returns(uint256[6] memory parts, uint256[18] memory genes){
        parts = [uint256(0),0,0,0,0,0];
        genes = [uint256(0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        if(_getLifecycleStage(_dna) != LibUnicornDNA.LIFECYCLE_EGG) {
            mapping(uint256 => mapping(uint256 => uint256)) storage globalIdsByBucket = LibDiamond.diamondStorage().bodyPartGlobalIdFromLocalId[_getClass(_dna)];
            
            parts = [
                globalIdsByBucket[1][_getBodyPart(_dna)],
                globalIdsByBucket[2][_getFacePart(_dna)],
                globalIdsByBucket[3][_getHornPart(_dna)],
                globalIdsByBucket[4][_getHoovesPart(_dna)],
                globalIdsByBucket[5][_getManePart(_dna)],
                globalIdsByBucket[6][_getTailPart(_dna)]
            ];
            genes = [
                _getBodyMajorGene(_dna),
                _getBodyMidGene(_dna),
                _getBodyMinorGene(_dna),
                _getFaceMajorGene(_dna),
                _getFaceMidGene(_dna),
                _getFaceMinorGene(_dna),
                _getHornMajorGene(_dna),
                _getHornMidGene(_dna),
                _getHornMinorGene(_dna),
                _getHoovesMajorGene(_dna),
                _getHoovesMidGene(_dna),
                _getHoovesMinorGene(_dna),
                _getManeMajorGene(_dna),
                _getManeMidGene(_dna),
                _getManeMinorGene(_dna),
                _getTailMajorGene(_dna),
                _getTailMidGene(_dna),
                _getTailMinorGene(_dna)
            ];    
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibBin {

    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // Using the mask, determine how many bits we need to shift to extract the desired value
    //  @param _mask A bitstring with right-padding zeroes
    //  @return The number of right-padding zeroes on the _mask
    function _getShiftAmount(uint256 _mask) internal pure returns (uint256) {
        uint256 count = 0;
        while (_mask & 0x1 == 0) {
            _mask >>= 1;
            ++count;
        }
        return count;
    }

    //  Insert _insertion data into the _bitArray bitstring
    //  @param _bitArray The base dna to manipulate
    //  @param _insertion Data to insert (no right-padding zeroes)
    //  @param _mask The location in the _bitArray where the insertion will take place
    //  @return The combined _bitArray bitstring
    function splice(
        uint256 _bitArray,
        uint256 _insertion,
        uint256 _mask
    ) internal pure returns (uint256) {
        uint256 offset = _getShiftAmount(_mask);
        uint256 passthroughMask = MAX ^ _mask;
        require(_insertion & (passthroughMask >> offset) == 0, "LibBin: Overflow, review carefuly the mask limits");
        //  remove old value,  shift new value to correct spot,  mask new value
        return (_bitArray & passthroughMask) | ((_insertion << offset) & _mask);
    }

    //  Alternate function signature for boolean insertion
    function splice(
        uint256 _bitArray,
        bool _insertion,
        uint256 _mask
    ) internal pure returns (uint256) {
        return splice(_bitArray, _insertion ? 1 : 0, _mask);
    }

    //  Retrieves a segment from the _bitArray bitstring
    //  @param _bitArray The dna to parse
    //  @param _mask The location in teh _bitArray to isolate
    //  @return The data from _bitArray that was isolated in the _mask (no right-padding zeroes)
    function extract(uint256 _bitArray, uint256 _mask)
        internal
        pure
        returns (uint256)
    {
        uint256 offset = _getShiftAmount(_mask);
        return (_bitArray & _mask) >> offset;
    }

    //  Alternate function signature for boolean retrieval
    function extractBool(uint256 _bitArray, uint256 _mask)
        internal
        pure
        returns (bool)
    {
        return (_bitArray & _mask) != 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/******************************************************************************\
* Modified from original contract, which was written by:
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "IDiamondCut.sol";


library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    //TODO: Should this go into DiamondStorage?
    uint256 internal constant ERC721_GENESIS_TOKENS = 10000;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    /* solhint-disable var-name-mixedcase */
    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
        // LG game server wallet
        address gameServer;
        // Erc721 state:
        // Mapping from token ID to owner address
        mapping(uint256 => address) erc721_owners;
        // Mapping owner address to token count
        mapping(address => uint256) erc721_balances;
        // Mapping of owners to owned token IDs
        mapping(address => mapping(uint256 => uint256)) erc721_ownedTokens;
        // Mapping of tokens to their index in their owners ownedTokens array.
        mapping(uint256 => uint256) erc721_ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] erc721_allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) erc721_allTokensIndex;
        // Mapping from token ID to approved address
        mapping(uint256 => address) erc721_tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) erc721_operatorApprovals;
        string erc721_name;
        // Token symbol
        string erc721_symbol;
        // Token contractURI - permaweb location of the contract json file
        string erc721_contractURI;
        // Token licenseURI - permaweb location of the license.txt file
        string erc721_licenseURI;
        // Timestamp when genesis eggs can be bought
        uint256 erc721_genesisEggPresaleUnlockTime;
        // Timestamp when genesis eggs can hatch
        uint256 erc721_genesisEggHatchUnlockTime;
        // Token URIs
        mapping(uint256 => string) erc721_tokenURIs;
        //whitelist_addresses
        mapping(address => uint8) erc721_mint_whitelist;
        uint256 erc721_current_token_id;
        //wETH token address (this is the one used to buy unicorns/land)
        address WethTokenAddress;
        // Unicorn token -> DNA mapping. DNA is represented by a uint256.
        mapping(uint256 => uint256) unicorn_dna; // DO NOT ACCESS DIRECTLY! Use LibUnicornDNA
        // The state of the NFT when it is round-tripping with the server
        mapping(uint256 => uint256) idempotence_state;
        // Unicorn token -> Timestamp (in seconds) when Egg hatched
        mapping(uint256 => uint256) hatch_birthday;
        // Unicorn token -> Timestamp (in seconds) when Unicorn last bred/hatched/evolved
        mapping(uint256 => uint256) bio_clock;
        // Seed for the cheap RNG
        uint256 rngNonce;
        // [geneTier][geneDominance] => chance to upgrade [0-100]
        mapping(uint256 => mapping(uint256 => uint256)) geneUpgradeChances;
        // [geneId] => tier of the gene [1-6]
        mapping(uint256 => uint256) geneTierById;
        // [geneId] => id of the next tier version of the gene
        mapping(uint256 => uint256) geneTierUpgradeById;
        // [geneId] => how the bonuses are applied (1 = multiply, 2 = add)
        mapping(uint256 => uint256) geneApplicationById;
        // [classId] => List of available gene globalIds for that class
        mapping(uint256 => uint256[]) geneBuckets;
        // [classId] => sum of weights in a geneBucket
        mapping(uint256 => uint256) geneBucketSumWeights;
        // uint256 geneWeightSum;
        mapping(uint256 => uint256) geneWeightById;
        //  [geneId][geneBonusSlot] => statId to affect
        mapping(uint256 => mapping(uint256 => uint256)) geneBonusStatByGeneId;
        //  [geneId][geneBonusSlot] => increase amount (percentages are scaled * 100)
        mapping(uint256 => mapping(uint256 => uint256)) geneBonusValueByGeneId;
        //  [globalPartId] => localPartId
        mapping(uint256 => uint256) bodyPartLocalIdFromGlobalId;
        //  [globalPartId] => true if mythic
        mapping(uint256 => bool) bodyPartIsMythic;
        //  [globalPartId] => globalPartId of next tier version of the gene
        mapping(uint256 => uint256) bodyPartInheritedGene;
        // [ClassId][PartSlotId] => globalIds[] - this is how we randomize slots
        mapping(uint256 => mapping(uint256 => uint256[])) bodyPartBuckets;
        // [ClassId][PartSlotId][localPartId] => globalPartId
        mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) bodyPartGlobalIdFromLocalId;
        //  [globalPartId] => weight
        mapping(uint256 => uint256) bodyPartWeight;
        // [classId][statId] => base stat value
        mapping(uint256 => mapping(uint256 => uint256)) baseStats;
        // requestId (number provided by ChainLink) => mechanicId (ie BREEDING, EVOLVING, etc.)
        // This map allows us to share RNG facet between mechanichs.
        mapping(bytes32 => uint256) rng_mechanicIdByVRFRequestId;
        // requestId => randomness provided by ChainLink
        mapping(bytes32 => uint256) rng_randomness;
        // ChainLink's keyhash
        bytes32 rng_chainlinkVRFKeyhash;
        // ChainLink's fee
        uint256 rng_chainlinkVRFFee;
        // transactionId => an array that represents breeding structure
        mapping(uint256 => uint256[8]) breedingByRoundTripId;
        // requestId => the transactionId that requested that randomness
        mapping(bytes32 => uint256) roundTripIdByVRFRequestId;
        // RBW token address
        address rbwTokenAddress;
        // UNIM token address
        address unimTokenAddress;
        // LINK token address
        address linkTokenAddress;
        // Nonces for each VRF key from which randomness has been requested.
        // Must stay in sync with VRFCoordinator[_keyHash][this]
        // keyHash => nonce
        mapping(bytes32 => uint256) rng_nonces;
        //VRF coordinator address
        address vrfCoordinator;

        // Unicorn token -> Last timestamp when it was unlocked forcefully
        mapping(uint256 => uint256) erc721_unicornLastForceUnlock;
        // After unlocking forcefully, user has to wait erc721_forceUnlockUnicornCooldown seconds to be able to transfer
        uint256 erc721_forceUnlockUnicornCooldown;

        mapping(uint256 => uint256[2]) unicornParents;
        // transactionId => an array that represents hatching structure
        mapping(uint256 => uint256[3]) hatchingByRoundTripId;   //  DEPRECATED - do not use
        // Blocks that we wait for Chainlink's response after SSS bundle is sent
        uint256 vrfBlocksToRespond;

        // nameIndex -> name string
        mapping(uint256 => string) firstNamesList;
        mapping(uint256 => string) lastNamesList;

        // Names which can be chosen by RNG for new lands (unordered)
        uint256[] validFirstNames;
        uint256[] validLastNames;

        //  The currently supported DNA Version
        uint256 targetDNAVersion;

        // roundTripId => an array that represents evolution structure // not being used actually, replaced by libEvolutionStorage
        mapping(uint256 => uint256[3]) evolutionByRoundTripId;

        //Scalars for score calculations
        uint256 power_scalar;
        uint256 power_attack_scalar;
        uint256 power_accuracy_scalar;
        uint256 speed_scalar;
        uint256 speed_movespeed_scalar;
        uint256 speed_attackspeed_scalar;
        uint256 endurance_scalar;
        uint256 endurance_vitality_scalar;
        uint256 endurance_defense_scalar;
        uint256 intelligence_scalar;
        uint256 intelligence_magic_scalar;
        uint256 intelligence_resistance_scalar;

        // game bank address, used to transfer funds from operations like breeding
        address gameBankAddress;

    } /* solhint-enable var-name-mixedcase */

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    // Ownership functionality
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function setGameServerAddress(address _newAddress) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.gameServer = _newAddress;
    }

    function setName(string memory _name) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_name = _name;
    }

    function setSymbol(string memory _symbol) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_symbol = _symbol;
    }

    function setContractURI(string memory _uri) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_contractURI = _uri;
    }

    function setLicenseURI(string memory _uri) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_licenseURI = _uri;
    }

    function setGenesisEggPresaleUnlockTime(uint256 _timestamp) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_genesisEggPresaleUnlockTime = _timestamp;
    }

    function setGenesisEggHatchUnlockTime(uint256 _timestamp) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.erc721_genesisEggHatchUnlockTime = _timestamp;
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function gameServer() internal view returns (address) {
        return diamondStorage().gameServer;
    }

    //TODO: Now using this to set the WethTokenAddress
    function setWethTokenAddress(address _wethTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.WethTokenAddress = _wethTokenAddress;
    }

    function setRbwTokenAddress(address _rbwTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.rbwTokenAddress = _rbwTokenAddress;
    }

    function setUnimTokenAddress(address _unimTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.unimTokenAddress = _unimTokenAddress;
    }

    function setLinkTokenAddress(address _linkTokenAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.linkTokenAddress = _linkTokenAddress;
    }

    function setGameBankAddress(address _gameBankAddress) internal {
        enforceIsContractOwner();
        DiamondStorage storage ds = diamondStorage();
        ds.gameBankAddress = _gameBankAddress;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    function enforceIsGameServer() internal view {
        require(
            msg.sender == diamondStorage().gameServer,
            "LibDiamond: Must be trusted game server"
        );
    }

    function enforceIsOwnerOrGameServer() internal view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.contractOwner ||
            msg.sender == ds.gameServer,
            "LibDiamond: Must be contract owner or trusted game server"
        );
    }

    function enforceCallerOwnsNFT(uint256 _tokenId) internal view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.erc721_owners[_tokenId],
            "LibDiamond: NFT must belong to the caller"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function enforceBlockDeadlineIsValid(uint256 blockDeadline) internal view {
        require(block.number < blockDeadline, "blockDeadline is overdue");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibERC721} from "LibERC721.sol";
import {LibIdempotence} from "LibIdempotence.sol";
import {LibRNG} from "LibRNG.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";
import {IPermissionProvider} from "IPermissionProvider.sol";
import {LibPermissions} from "LibPermissions.sol";

library LibHatching {

    event HatchingRNGRequested(uint256 indexed roundTripId, bytes32 indexed vrfRequestId, address indexed playerWallet);
    event HatchingRNGRequestedV2(uint256 indexed roundTripId, bytes32 indexed vrfRequestId, address indexed owner, address playerWallet);
    event HatchingReadyForTokenURI(uint256 indexed roundTripId, address indexed playerWallet);
    event HatchingReadyForTokenURIV2(uint256 indexed roundTripId, address indexed owner, address indexed playerWallet);
    event HatchingComplete(uint256 indexed roundTripId, address indexed playerWallet);
    event HatchingCompleteV2(uint256 indexed roundTripId, address indexed owner, address indexed playerWallet);

    bytes32 private constant HATCHING_STORAGE_POSITION = keccak256("diamond.libHatching.storage");

    uint256 private constant BODY_SLOT = 1;
    uint256 private constant FACE_SLOT = 2;
    uint256 private constant HORN_SLOT = 3;
    uint256 private constant HOOVES_SLOT = 4;
    uint256 private constant MANE_SLOT = 5;
    uint256 private constant TAIL_SLOT = 6;

    uint256 private constant SALT_11 = 11;
    uint256 private constant SALT_12 = 12;
    uint256 private constant SALT_13 = 13;
    uint256 private constant SALT_14 = 14;
    uint256 private constant SALT_15 = 15;
    uint256 private constant SALT_16 = 16;

    uint256 private constant SALT_21 = 21;
    uint256 private constant SALT_22 = 22;
    uint256 private constant SALT_23 = 23;
    uint256 private constant SALT_24 = 24;
    uint256 private constant SALT_25 = 25;
    uint256 private constant SALT_26 = 26;

    uint256 private constant SALT_31 = 31;
    uint256 private constant SALT_32 = 32;
    uint256 private constant SALT_33 = 33;
    uint256 private constant SALT_34 = 34;
    uint256 private constant SALT_35 = 35;
    uint256 private constant SALT_36 = 36;

    uint256 private constant SALT_41 = 41;
    uint256 private constant SALT_42 = 42;
    uint256 private constant SALT_43 = 43;
    uint256 private constant SALT_44 = 44;
    uint256 private constant SALT_45 = 45;
    uint256 private constant SALT_46 = 46;

    uint256 private constant SALT_51 = 51;
    uint256 private constant SALT_52 = 52;
    uint256 private constant SALT_53 = 53;
    uint256 private constant SALT_54 = 54;
    uint256 private constant SALT_55 = 55;
    uint256 private constant SALT_56 = 56;

    uint256 private constant SALT_61 = 61;
    uint256 private constant SALT_62 = 62;
    uint256 private constant SALT_63 = 63;
    uint256 private constant SALT_64 = 64;
    uint256 private constant SALT_65 = 65;
    uint256 private constant SALT_66 = 66;

    struct LibHatchingStorage {
        mapping(bytes32 => uint256) blockDeadlineByVRFRequestId;
        mapping(bytes32 => uint256) roundTripIdByVRFRequestId;
        mapping(uint256 => bytes32) vrfRequestIdByRoundTripId;
        mapping(bytes32 => uint256) tokenIdByVRFRequestId;
        mapping(bytes32 => uint256) inheritanceChanceByVRFRequestId;
        mapping(bytes32 => uint256) rngByVRFRequestId;
        mapping(bytes32 => uint256) rngBlockNumberByVRFRequestId;
        mapping(bytes32 => uint256) birthdayByVRFRequestId;
        mapping(uint256 => uint256) roundTripIdByTokenId;
    }

    function hatchingStorage() internal pure returns (LibHatchingStorage storage lhs) {
        bytes32 position = HATCHING_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lhs.slot := position
        }
    }

    function saveDataOnHatchingStruct(
        uint256 roundTripId,
        bytes32 vrfRequestId,
        uint256 blockDeadline,
        uint256 tokenId,
        uint256 inheritanceChance
    ) internal {
        LibHatchingStorage storage lhs = hatchingStorage();
        lhs.blockDeadlineByVRFRequestId[vrfRequestId] = blockDeadline;
        lhs.roundTripIdByVRFRequestId[vrfRequestId] = roundTripId;
        lhs.tokenIdByVRFRequestId[vrfRequestId] = tokenId;
        lhs.inheritanceChanceByVRFRequestId[vrfRequestId] = inheritanceChance;
        lhs.vrfRequestIdByRoundTripId[roundTripId] = vrfRequestId;
        lhs.roundTripIdByTokenId[tokenId] = roundTripId;
        lhs.birthdayByVRFRequestId[vrfRequestId] = block.timestamp;
    }

    function cleanUpRoundTrip(bytes32 vrfRequestId) internal {
        LibHatchingStorage storage lhs = hatchingStorage();
        uint256 roundTripId = lhs.roundTripIdByVRFRequestId[vrfRequestId];
        uint256 tokenId = lhs.tokenIdByVRFRequestId[vrfRequestId];
        delete lhs.blockDeadlineByVRFRequestId[vrfRequestId];
        delete lhs.roundTripIdByVRFRequestId[vrfRequestId];
        delete lhs.vrfRequestIdByRoundTripId[roundTripId];
        delete lhs.tokenIdByVRFRequestId[vrfRequestId];
        delete lhs.inheritanceChanceByVRFRequestId[vrfRequestId];
        delete lhs.rngByVRFRequestId[vrfRequestId];
        delete lhs.rngBlockNumberByVRFRequestId[vrfRequestId];
        delete lhs.birthdayByVRFRequestId[vrfRequestId];
        delete lhs.roundTripIdByTokenId[tokenId];
    }

    function getVRFRequestId(uint256 roundTripId) internal view returns (bytes32) {
        return hatchingStorage().vrfRequestIdByRoundTripId[roundTripId];
    }

    function getRoundTripId(bytes32 vrfRequestId) internal view returns (uint256) {
        return hatchingStorage().roundTripIdByVRFRequestId[vrfRequestId];
    }

    function getRoundTripIdForToken(uint256 tokenId) internal view returns (uint256) {
        return hatchingStorage().roundTripIdByTokenId[tokenId];
    }

    function getBlockDeadline(bytes32 vrfRequestId) internal view returns (uint256) {
        return hatchingStorage().blockDeadlineByVRFRequestId[vrfRequestId];
    }

    function getTokenId(bytes32 vrfRequestId) internal view returns (uint256) {
        return hatchingStorage().tokenIdByVRFRequestId[vrfRequestId];
    }

    function setRandomness(bytes32 vrfRequestId, uint256 randomness) internal {
        LibHatchingStorage storage lhs = hatchingStorage();
        lhs.rngByVRFRequestId[vrfRequestId] = randomness;
        lhs.rngBlockNumberByVRFRequestId[vrfRequestId] = block.number;
    }

    function setBirthday(bytes32 vrfRequestId, uint256 timestamp) internal {
        hatchingStorage().birthdayByVRFRequestId[vrfRequestId] = timestamp;
    }

    function shouldUsePredictiveDNA(uint256 tokenId) internal view returns (bool) {
        if (
            LibIdempotence._getHatchingRandomnessFulfilled(tokenId) &&
            !LibIdempotence._getHatchingStarted(tokenId)
        ) {
            LibHatchingStorage storage lhs = hatchingStorage();
            uint256 roundTripId = lhs.roundTripIdByTokenId[tokenId];
            bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[roundTripId];
            if (
                lhs.rngBlockNumberByVRFRequestId[vrfRequestId] > 0 &&
                lhs.rngBlockNumberByVRFRequestId[vrfRequestId] < block.number
            ) {
                return true;
            } 
        }
        return false;
    }

    function predictBabyBirthday(uint256 tokenId) internal view returns (uint256) {
        require(!LibIdempotence._getHatchingStarted(tokenId), "LibHatching: RNG not ready");
        require(LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: Waiting for VRF TTL");
        LibHatchingStorage storage lhs = hatchingStorage();
        uint256 roundTripId = lhs.roundTripIdByTokenId[tokenId];
        bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[roundTripId];
        uint256 eggDNA = LibUnicornDNA._getCanonicalDNA(tokenId);
        require(LibUnicornDNA._getLifecycleStage(eggDNA) == LibUnicornDNA.LIFECYCLE_EGG, "LibHatching: DNA has already been persisted (birthday)");
        return lhs.birthdayByVRFRequestId[vrfRequestId];
    }

    //  This is gigantic hack to move gas costs out of the Chainlink VRF call. Instead of rolling for
    //  random DNA and saving it, the dna is calculated on-the-fly when it's needed. When hatching is
    //  completed, this dna is written into storage and the temporary state is deleted. -RS
    //
    //  This code MUST be deterministic - DO NOT MODIFY THE RANDOMNESS OR SALT CONSTANTS

    function predictBabyDNA(uint256 tokenId) internal view returns (uint256) {
        require(!LibIdempotence._getHatchingStarted(tokenId), "LibHatching: RNG not ready");
        require(LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: Waiting for VRF TTL");
        LibHatchingStorage storage lhs = hatchingStorage();

        bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[lhs.roundTripIdByTokenId[tokenId]];
        require(lhs.rngBlockNumberByVRFRequestId[vrfRequestId] > 0, "LibHatching: No RNG set");
        require(lhs.rngBlockNumberByVRFRequestId[vrfRequestId] < block.number, "LibHatching: Prediction masked during RNG set block");

        uint256 inheritanceChance  = lhs.inheritanceChanceByVRFRequestId[vrfRequestId];
        uint256 randomness = lhs.rngByVRFRequestId[vrfRequestId];
        uint256 dna = LibUnicornDNA._getCanonicalDNA(tokenId);
        require(LibUnicornDNA._getLifecycleStage(dna) == LibUnicornDNA.LIFECYCLE_EGG, "LibHatching: DNA has already been persisted (dna)");

        uint256 classId = LibUnicornDNA._getClass(dna);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 firstParentDNA = LibUnicornDNA._getDNA(ds.unicornParents[tokenId][0]);
        uint256 secondParentDNA = LibUnicornDNA._getDNA(ds.unicornParents[tokenId][1]);

        //  Optimization for stack depth limit:
        //  {0: neither,  1: firstParent,  2: secondParent,  3: both}
        uint256 matching = 0;

        if(classId == LibUnicornDNA._getClass(firstParentDNA)) {
            matching += 1;
        }

        if(classId == LibUnicornDNA._getClass(secondParentDNA)) {
            matching += 2;
        }

        dna = LibUnicornDNA._setLifecycleStage(dna, LibUnicornDNA.LIFECYCLE_BABY);
        
        uint256 partId;

        //  BODY
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_11) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_12) == 1) {
                    dna = LibUnicornDNA._inheritBody(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritBody(dna, secondParentDNA);
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritBody(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritBody(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, BODY_SLOT, randomness, SALT_13);
            dna = LibUnicornDNA._multiSetBody(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_15),
                getRandomGeneId(ds, classId, randomness, SALT_16)
            );
        }

        //  FACE
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_21) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_22) == 1) {
                    dna = LibUnicornDNA._inheritFace(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritFace(dna, secondParentDNA);
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritFace(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritFace(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, FACE_SLOT, randomness, SALT_23);
            dna = LibUnicornDNA._multiSetFace(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_25),
                getRandomGeneId(ds, classId, randomness, SALT_26)
            );
        }

        //  HORN
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_31) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_32) == 1) {
                    dna = LibUnicornDNA._inheritHorn(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritHorn(dna, secondParentDNA);
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritHorn(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritHorn(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, HORN_SLOT, randomness, SALT_33);
            dna = LibUnicornDNA._multiSetHorn(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_35),
                getRandomGeneId(ds, classId, randomness, SALT_36)
            );
        }

        //  HOOVES
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_41) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_42) == 1) {
                    dna = LibUnicornDNA._inheritHooves(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritHooves(dna, secondParentDNA);
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritHooves(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritHooves(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, HOOVES_SLOT, randomness, SALT_43);
            dna = LibUnicornDNA._multiSetHooves(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_45),
                getRandomGeneId(ds, classId, randomness, SALT_46)
            );
        }

        //  MANE
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_51) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_52) == 1) {
                    dna = LibUnicornDNA._inheritMane(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritMane(dna, secondParentDNA);
                }
            } else if(matching == 2) {
                dna = LibUnicornDNA._inheritMane(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritMane(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, MANE_SLOT, randomness, SALT_53);
            dna = LibUnicornDNA._multiSetMane(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_55),
                getRandomGeneId(ds, classId, randomness, SALT_56)
            );
        }

        //  TAIL
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_61) < inheritanceChance) {
            //  inherit
            if (matching == 3) {
                if(LibRNG.expand(2, randomness, SALT_62) == 1) {
                    dna = LibUnicornDNA._inheritTail(dna, firstParentDNA);
                } else {
                    dna = LibUnicornDNA._inheritTail(dna, secondParentDNA);
                }
            } else if (matching == 2){
                dna = LibUnicornDNA._inheritTail(dna, secondParentDNA);
            } else {
                dna = LibUnicornDNA._inheritTail(dna, firstParentDNA);
            }
        } else {
            //  randomize
            partId = getRandomPartId(ds, classId, TAIL_SLOT, randomness, SALT_63);
            dna = LibUnicornDNA._multiSetTail(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                getRandomGeneId(ds, classId, randomness, SALT_65),
                getRandomGeneId(ds, classId, randomness, SALT_66)
            );
        }
        return dna;
    }

    //  Chooses a bodypart from the weighted random pool in `partsBySlot` and returns the id
    //  @param _classId Index the unicorn class
    //  @param _slotId Index of the bodypart slot
    //  @return Struct of the body part
    function getRandomPartId(
        LibDiamond.DiamondStorage storage ds,
        uint256 _classId,
        uint256 _slotId,
        uint256 _rngSeed,
        uint256 _salt
    ) internal view returns (uint256) {
        uint256 numBodyParts = ds.bodyPartBuckets[_classId][_slotId].length;
        uint256 totalWeight = 0;
        for (uint i = 0; i < numBodyParts; i++) {
            totalWeight += ds.bodyPartWeight[ds.bodyPartBuckets[_classId][_slotId][i]];
        }
        uint256 target = LibRNG.expand(totalWeight, _rngSeed, _salt) + 1;
        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < numBodyParts; ++i) {
            uint256 globalId = ds.bodyPartBuckets[_classId][_slotId][i];
            uint256 partWeight = ds.bodyPartWeight[globalId];
            cumulativeWeight += partWeight;
            if (target <= cumulativeWeight) {
                return globalId;
            }
        }
        revert("LibHatching: Failed getting RNG bodyparts");
    }

    function getRandomGeneId(
        LibDiamond.DiamondStorage storage ds,
        uint256 _classId,
        uint256 _rngSeed,
        uint256 _salt
    ) internal view returns (uint256) {
        uint256 numGenes = ds.geneBuckets[_classId].length;
        uint256 target = LibRNG.expand(ds.geneBucketSumWeights[_classId], _rngSeed, _salt) + 1;
        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < numGenes; ++i) {
            uint256 geneId = ds.geneBuckets[_classId][i];
            cumulativeWeight += ds.geneWeightById[geneId];
            if (target <= cumulativeWeight) {
                return geneId;
            }
        }
        revert("LibHatching: Failed getting RNG gene");
    }

    function completeBeginHatching(bytes32 vrfRequestId, uint256 blockDeadline, uint256 tokenId, uint256 inheritanceChance, uint256 roundTripId) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        saveDataOnHatchingStruct(roundTripId, vrfRequestId, blockDeadline, tokenId, inheritanceChance);
        LibIdempotence._setIdempotenceState(tokenId, LibIdempotence._setHatchingStarted(tokenId, true));
        emit HatchingRNGRequested(roundTripId, vrfRequestId, ds.erc721_owners[tokenId]);
        emit HatchingRNGRequestedV2(roundTripId, vrfRequestId, ds.erc721_owners[tokenId], msg.sender);
    }

    function beginHatching(uint256 roundTripId, uint256 blockDeadline, uint256 tokenId, uint256 inheritanceChance) internal {
        validateBeginHatching(blockDeadline, tokenId);
        uint256 vrfRequestId = LibRNG.requestRandomWordsFor(LibRNG.RNG_HATCHING);
        completeBeginHatching(bytes32(vrfRequestId), blockDeadline, tokenId, inheritanceChance, roundTripId);
    }

    function validateBeginHatching(uint256 blockDeadline, uint256 tokenId) private view {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(blockDeadline >= ds.vrfBlocksToRespond + block.number , "LibHatching: TTL has expired."); 

        LibPermissions.enforceCallerOwnsNFTOrHasPermission(tokenId, IPermissionProvider.Permission.UNICORN_HATCHING_ALLOWED);
        require(!LibIdempotence._getGenesisHatching(tokenId), "LibHatching: IDMP currently genesisHatching");
        require(!LibIdempotence._getHatching(tokenId), "LibHatching: IDMP currently hatching");
        require(!LibIdempotence._getHatchingStarted(tokenId), "LibHatching: IDMP already started hatching");
        require(!LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: IDMP already received hatch RNG");
        require(!LibIdempotence._getNewEggWaitingForRNG(tokenId), "LibHatching: IDMP new egg waiting for RNG");
        require(!LibIdempotence._getNewEggReceivedRNGWaitingForTokenURI(tokenId), "LibHatching: IDMP new egg waiting for tokenURI");
        require(ds.bio_clock[tokenId] + 300 <= block.timestamp, "LibHatching: Egg has to be at least 5 minutes old to hatch");
        uint256 dna = LibUnicornDNA._getDNA(tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        require(LibUnicornDNA._getLifecycleStage(dna) == LibUnicornDNA.LIFECYCLE_EGG, "LibHatching: Only eggs can be hatched");
        require(!LibUnicornDNA._getOrigin(dna), "LibHatching: Only non origin eggs can be hatched in this facet");
        require(LibUnicornDNA._getGameLocked(dna), "LibHatching: Egg must be locked in order to begin hatching");
    }

    function hatchingFulfillRandomness(bytes32 requestId, uint256 randomness) internal {
        LibDiamond.enforceBlockDeadlineIsValid(getBlockDeadline(requestId));
        uint256 tokenId = getTokenId(requestId);
        require(LibIdempotence._getHatchingStarted(tokenId), "LibHatching: Hatching has to be in STARTED state to fulfillRandomness");
        setRandomness(requestId, randomness);
        updateIdempotenceAndEmitEvent(tokenId, getRoundTripId(requestId));
    }

    function updateIdempotenceAndEmitEvent(uint256 tokenId, uint256 roundTripId) internal {
        LibIdempotence._setIdempotenceState(tokenId, LibIdempotence._setHatchingStarted(tokenId, false));
        LibIdempotence._setIdempotenceState(tokenId, LibIdempotence._setHatchingRandomnessFulfilled(tokenId, true));
        emit HatchingReadyForTokenURI(roundTripId, LibDiamond.diamondStorage().erc721_owners[tokenId]);
        emit HatchingReadyForTokenURIV2(roundTripId, LibDiamond.diamondStorage().erc721_owners[tokenId], msg.sender);
    }

    //  Chooses a bodypart from the weighted random pool in `partsBySlot` and returns the id
    //  @param _classId Index the unicorn class
    //  @param _slotId Index of the bodypart slot
    //  @return Struct of the body part
    function getRandomPartId(uint256 _classId, uint256 _slotId) internal returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 i = 0;
        uint256 numBodyParts = ds.bodyPartBuckets[_classId][_slotId].length;

        uint256 totalWeight = 0;
        for (i = 0; i < numBodyParts; i++) {
            totalWeight += ds.bodyPartWeight[ds.bodyPartBuckets[_classId][_slotId][i]];
        }

        uint256 target = LibRNG.getRuntimeRNG(totalWeight) + 1;
        uint256 cumulativeWeight = 0;

        for (i = 0; i < numBodyParts; i++) {
            uint256 globalId = ds.bodyPartBuckets[_classId][_slotId][i];
            uint256 partWeight = ds.bodyPartWeight[globalId];
            cumulativeWeight += partWeight;
            if(target <= cumulativeWeight) {
                return globalId;
            }
        }
        revert("LibHatching: Failed getting RNG bodyparts");
    }

    function getRandomGeneId(uint256 _classId) internal returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        uint256 numGenes = ds.geneBuckets[_classId].length;

        uint256 i = 0;
        uint256 totalWeight = ds.geneBucketSumWeights[_classId];

        uint256 target = LibRNG.getRuntimeRNG(totalWeight) + 1;
        uint256 cumulativeWeight = 0;

        for (i = 0; i < numGenes; i++) {
            uint256 geneId = ds.geneBuckets[_classId][i];
            cumulativeWeight += ds.geneWeightById[geneId];
            if(target <= cumulativeWeight) {
                return geneId;
            }
        }

        revert("LibHatching: Failed getting RNG gene");
    }

    function getParentDNAs(uint256 tokenId) internal view returns(uint256[2] memory parentDNA) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 firstParentId = ds.unicornParents[tokenId][0];
        uint256 secondParentId = ds.unicornParents[tokenId][1];
        parentDNA[0] = LibUnicornDNA._getDNA(firstParentId);
        parentDNA[1] = LibUnicornDNA._getDNA(secondParentId);
        return parentDNA;
    }

    function retryHatching(uint256 roundTripId) internal {
        bytes32 requestId = getVRFRequestId(roundTripId);
        uint256 tokenId = getTokenId(requestId);

        LibPermissions.enforceCallerOwnsNFTOrHasPermission(tokenId, IPermissionProvider.Permission.UNICORN_HATCHING_ALLOWED);
        uint256 blockDeadline = getBlockDeadline(requestId);
        require(blockDeadline > 0, "LibHatching: Transaction not found");
        require(block.number > blockDeadline, "LibHatching: Cannot retry while old TTL is ongoing");
        require(LibIdempotence._getHatchingStarted(tokenId), "LibHatching: Hatching has to be in STARTED state to retry hatching");
        uint256 randomness = LibRNG.getRuntimeRNG();
        setRandomness(requestId, randomness);
        updateIdempotenceAndEmitEvent(tokenId, roundTripId);
    }

    function finishHatching(uint256 roundTripId, uint256 tokenId, bytes32 vrfRequestId, string memory tokenURI) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        LibPermissions.enforceCallerOwnsNFTOrHasPermission(tokenId, IPermissionProvider.Permission.UNICORN_HATCHING_ALLOWED);
        require(LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: Cannot finish hatching before randomness has been fulfilled");
        LibERC721.setTokenURI(tokenId, tokenURI);

        uint256 newDNA;
        uint256 newBirthday = predictBabyBirthday(tokenId);
        
        if(LibUnicornDNA.dnaStorage().cachedDNA[tokenId] > 0) {
            // Check for any DNA held over from old versions of the deterministic logic...
            newDNA = LibUnicornDNA.dnaStorage().cachedDNA[tokenId];
            delete LibUnicornDNA.dnaStorage().cachedDNA[tokenId];
        } else {
            newDNA = predictBabyDNA(tokenId);
        }

        ds.hatch_birthday[tokenId] = newBirthday;
        LibUnicornDNA._setDNA(tokenId, newDNA);
        ds.bio_clock[tokenId] = block.timestamp;
        
        LibIdempotence._setIdempotenceState(tokenId, LibIdempotence._setHatchingRandomnessFulfilled(tokenId, false));
        emit HatchingComplete(roundTripId, ds.erc721_owners[tokenId]);
        emit HatchingCompleteV2(roundTripId, ds.erc721_owners[tokenId], msg.sender);
        //  clean up workflow data:
        delete ds.rng_randomness[vrfRequestId];
        cleanUpRoundTrip(vrfRequestId);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "IERC721Receiver.sol";
import "Address.sol";

import {LibUnicornDNA} from "LibUnicornDNA.sol";
import {LibDiamond} from "LibDiamond.sol";
import {LibAirlock} from "LibAirlock.sol";
import {LibEvents} from "LibEvents.sol";

library LibERC721 {
    using Address for address;

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
    function safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        transfer(from, to, tokenId);
        require(
            checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`mint`),
     * and stop existing when they are burned (`burn`).
     */
    function exists(uint256 tokenId) internal view returns (bool) {
        return LibDiamond.diamondStorage().erc721_owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
    function safeMint(address to, uint256 tokenId) internal {
        safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-safeMint-address-uint256-}[`safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        mint(to, tokenId);
        require(
            checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        beforeTokenTransfer(address(0), to, tokenId);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_balances[to] += 1;
        ds.erc721_owners[tokenId] = to;

        emit LibEvents.Transfer(address(0), to, tokenId);
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
    function burn(uint256 tokenId) internal {
        enforceUnicornIsTransferable(tokenId);
        address owner = ownerOf(tokenId);

        beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        approve(address(0), tokenId);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_balances[owner] -= 1;
        delete ds.erc721_owners[tokenId];

        if (bytes(ds.erc721_tokenURIs[tokenId]).length != 0) {
            delete ds.erc721_tokenURIs[tokenId];
        }

        emit LibEvents.Transfer(owner, address(0), tokenId);
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
    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        enforceUnicornIsTransferable(tokenId);

        beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        approve(address(0), tokenId);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_balances[from] -= 1;
        ds.erc721_balances[to] += 1;
        ds.erc721_owners[tokenId] = to;

        emit LibEvents.Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function approve(address to, uint256 tokenId) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_tokenApprovals[tokenId] = to;
        emit LibEvents.Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.erc721_operatorApprovals[owner][operator] = approved;
        emit LibEvents.ApprovalForAll(owner, operator, approved);
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
    function checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (from == address(0)) {
            addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 length = balanceOf(to);
        ds.erc721_ownedTokens[to][length] = tokenId;
        ds.erc721_ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        internal
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = ds.erc721_ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ds.erc721_ownedTokens[from][lastTokenIndex];

            ds.erc721_ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ds.erc721_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ds.erc721_ownedTokensIndex[tokenId];
        delete ds.erc721_ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function addTokenToAllTokensEnumeration(uint256 tokenId) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.erc721_allTokensIndex[tokenId] = ds.erc721_allTokens.length;
        ds.erc721_allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function removeTokenFromAllTokensEnumeration(uint256 tokenId) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ds.erc721_allTokens.length - 1;
        uint256 tokenIndex = ds.erc721_allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ds.erc721_allTokens[lastTokenIndex];

        ds.erc721_allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ds.erc721_allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ds.erc721_allTokensIndex[tokenId];
        ds.erc721_allTokens.pop();
    }

    function ownerOf(uint256 tokenId) internal view returns(address) {
        address owner = LibDiamond.diamondStorage().erc721_owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function getApproved(uint256 tokenId) internal view returns(address) {
        require(
            exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return LibDiamond.diamondStorage().erc721_tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) internal view returns(bool) {
        return LibDiamond.diamondStorage().erc721_operatorApprovals[owner][operator];
    }

    function balanceOf(address owner) internal view returns(uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return LibDiamond.diamondStorage().erc721_balances[owner];
    }

    function enforceUnicornIsTransferable(uint256 tokenId) internal view {
        require(
            unicornIsTransferable(tokenId),
            "LibERC721: Unicorn must be unlocked from game before transfering"
        );
    }

    function unicornIsTransferable(uint256 tokenId) internal view returns(bool) {
        return (
            LibAirlock.unicornIsLocked(tokenId) == false &&
            LibAirlock.unicornIsCoolingDown(tokenId) == false
            //  TODO: add idempotence checks here
        );
    }

    function getTokenURI(uint256 tokenId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().erc721_tokenURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        LibDiamond.diamondStorage().erc721_tokenURIs[tokenId] = tokenURI;
    }

    function enforceCallerOwnsNFT(uint256 tokenId) internal view {
        require(
            ownerOf(tokenId) == msg.sender,
            "ERC721: Caller must own NFT"
        );
    }

    function mintNextToken(address _to)
        internal
        returns (uint256 nextTokenId)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        nextTokenId = ds.erc721_current_token_id + 1;
        mint(_to, nextTokenId);
        ds.erc721_current_token_id = nextTokenId;
        return nextTokenId;
    }

    function setDNAForGenesisToken(uint256 _tokenId, uint8 _class)
        internal
        returns (uint256)
    {
        require(
            _tokenId <= LibDiamond.ERC721_GENESIS_TOKENS,
            "LibERC721: Can only set DNA for genesis tokens"
        );
        uint256 dna = 0;
        dna = LibUnicornDNA._setVersion(dna, LibUnicornDNA._targetDNAVersion());
        dna = LibUnicornDNA._setOrigin(dna, true);
        dna = LibUnicornDNA._setGameLocked(dna, false);
        dna = LibUnicornDNA._setLimitedEdition(dna, false);
        dna = LibUnicornDNA._setLifecycleStage(
            dna,
            LibUnicornDNA.LIFECYCLE_EGG
        );
        dna = LibUnicornDNA._setBreedingPoints(dna, 0);
        dna = LibUnicornDNA._setClass(dna, _class);
        return LibUnicornDNA._setDNA(_tokenId, dna);
    }

    /**
     * Unicorn DNA methods
     */
    function getDNA(uint256 _tokenId) internal view returns (uint256) {
        return LibUnicornDNA._getDNA(_tokenId);
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
        assembly {
            size := extcodesize(account)
        }
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibERC721} from "LibERC721.sol";
import {LibServerSideSigning} from "LibServerSideSigning.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";


library LibAirlock {

    event UnicornLockedIntoGame(uint256 tokenId, address locker);
    event UnicornLockedIntoGameV2(uint256 indexed tokenId, address indexed owner, address indexed locker);
    event UnicornUnlockedOutOfGame(uint256 tokenId, address locker);
    event UnicornUnlockedOutOfGameV2(uint256 indexed tokenId, address indexed owner, address indexed locker);
    event UnicornUnlockedOutOfGameForcefully(uint256 timestamp, uint256 tokenId, address locker);

    function enforceDNAIsLocked(uint256 dna) internal pure {
        require(
            LibUnicornDNA._getGameLocked(dna),
            "LibAirlock: Unicorn DNA must be locked into game."
        );
    }

    function enforceUnicornIsLocked(uint256 tokenId) internal view {
        require(
            LibUnicornDNA._getGameLocked(LibUnicornDNA._getDNA(tokenId)),
            "LibAirlock: Unicorn must be locked into game."
        );
    }

    function enforceDNAIsUnlocked(uint256 dna) internal pure {
        require(
            LibUnicornDNA._getGameLocked(dna) == false,
            "LibAirlock: Unicorn DNA must be unlocked."
        );
    }

    function enforceUnicornIsUnlocked(uint256 tokenId) internal view {
        require(
            LibUnicornDNA._getGameLocked(LibUnicornDNA._getDNA(tokenId)) == false,
            "LibAirlock: Unicorn must be unlocked."
        );
    }

    function enforceUnicornIsNotCoolingDown(uint256 tokenId) internal view {
        require(!unicornIsCoolingDown(tokenId),
            "LibAirlock: Unicorn is cooling down from force unlock."
        );
    }

    function unicornIsLocked(uint256 tokenId) internal view returns (bool) {
        return LibUnicornDNA._getGameLocked(LibUnicornDNA._getDNA(tokenId));
    }

    function dnaIsLocked(uint256 dna) internal pure returns (bool) {
        return LibUnicornDNA._getGameLocked(dna);
    }

    function unicornIsCoolingDown(uint256 tokenId) internal view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.erc721_unicornLastForceUnlock[tokenId] != 0 && (ds.erc721_unicornLastForceUnlock[tokenId] + ds.erc721_forceUnlockUnicornCooldown) >= block.timestamp;
    }

    function lockUnicornIntoGame(uint256 tokenId) internal {
        lockUnicornIntoGame(tokenId, true);
    }

    function lockUnicornIntoGame(uint256 tokenId, bool emitLockedEvent) internal {
        enforceUnicornIsNotCoolingDown(tokenId);
        uint256 dna = LibUnicornDNA._getDNA(tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        enforceDNAIsUnlocked(dna);
        dna = LibUnicornDNA._setGameLocked(dna, true);
        LibUnicornDNA._setDNA(tokenId, dna);
        if (emitLockedEvent) {
            emit UnicornLockedIntoGame(tokenId, msg.sender);
            emit UnicornLockedIntoGameV2(tokenId, LibDiamond.diamondStorage().erc721_owners[tokenId], msg.sender);
        }
    }

    function unlockUnicornOutOfGameGenerateMessageHash(
        uint256 tokenId,
        string memory tokenURI,
        uint256 requestId,
        uint256 blockDeadline
    ) internal view returns (bytes32) {
        /* solhint-disable max-line-length */
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "UnlockUnicornOutOfGamePayload(uint256 tokenId, string memory tokenURI, uint256 requestId, uint256 blockDeadline)"
                ),
                tokenId,
                tokenURI,
                requestId,
                blockDeadline
            )
        );
        return LibServerSideSigning._hashTypedDataV4(structHash);
        /* solhint-enable max-line-length */
    }

    function unlockUnicornOutOfGame(
        uint256 tokenId,
        string memory tokenURI
    ) internal {
        unlockUnicornOutOfGame(tokenId, tokenURI, true);
    }

    function unlockUnicornOutOfGame(
        uint256 tokenId,
        string memory tokenURI,
        bool emitUnlockEvent
    ) internal {
        
        _unlockUnicorn(tokenId);
        LibERC721.setTokenURI(tokenId, tokenURI);
        if (emitUnlockEvent) {
            emit UnicornUnlockedOutOfGame(tokenId, msg.sender);
            emit UnicornUnlockedOutOfGameV2(tokenId, LibDiamond.diamondStorage().erc721_owners[tokenId], msg.sender);
        }
    }

    function forceUnlockUnicornOutOfGame(uint256 tokenId) internal {
        _unlockUnicorn(tokenId);
        LibDiamond.diamondStorage().erc721_unicornLastForceUnlock[tokenId] = block.timestamp;
        emit UnicornUnlockedOutOfGameForcefully(block.timestamp, tokenId, msg.sender);
    }

    function _unlockUnicorn(uint256 tokenId) private {
        uint256 dna = LibUnicornDNA._getDNA(tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        enforceDNAIsLocked(dna);
        enforceUnicornIsNotCoolingDown(tokenId);
        dna = LibUnicornDNA._setGameLocked(dna, false);
        LibUnicornDNA._setDNA(tokenId, dna);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * Much of the functionality in this library is adapted from OpenZeppelin's EIP712 implementation:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/draft-EIP712.sol
 */

import "ECDSA.sol";

library LibServerSideSigning {
    bytes32 internal constant SERVER_SIDE_SIGNING_STORAGE_POSITION =
        keccak256("CryptoUnicorns.ServerSideSigning.storage");

    /* solhint-disable var-name-mixedcase */
    struct ServerSideSigningStorage {
        string name;
        string version;
        bytes32 CACHED_DOMAIN_SEPARATOR;
        uint256 CACHED_CHAIN_ID;
        bytes32 HASHED_NAME;
        bytes32 HASHED_VERSION;
        bytes32 TYPE_HASH;
        mapping(uint256 => bool) completedRequests;
    } /* solhint-enable var-name-mixedcase */

    function serverSideSigningStorage()
        internal
        pure
        returns (ServerSideSigningStorage storage ss)
    {
        bytes32 position = SERVER_SIDE_SIGNING_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ss.slot := position
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _setEIP712Parameters(string memory name, string memory version)
        internal
    {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        ss.name = name;
        ss.version = version;
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        ss.HASHED_NAME = hashedName;
        ss.HASHED_VERSION = hashedVersion;
        ss.CACHED_CHAIN_ID = block.chainid;
        ss.CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        ss.TYPE_HASH = typeHash;
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        if (block.chainid == ss.CACHED_CHAIN_ID) {
            return ss.CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(ss.TYPE_HASH, ss.HASHED_NAME, ss.HASHED_VERSION);
        }
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function _completeRequest(uint256 requestId) internal {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        ss.completedRequests[requestId] = true;
    }

    function _clearRequest(uint256 requestId) internal {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        ss.completedRequests[requestId] = false;
    }

    function _checkRequest(uint256 requestId) internal view returns (bool) {
        ServerSideSigningStorage storage ss = serverSideSigningStorage();
        return ss.completedRequests[requestId];
    }

    // TODO(zomglings): Add a function called `_invalidateServerSideSigningRequest(uint256 requestId)`.
    // Invalidation can be achieved by setting completedRequests[requestId] = true.
    // Similarly, we may want to add a `_clearRequest` function which sets to false.
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library LibEvents {
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

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";
import {LibUtil} from "LibUtil.sol";

library LibIdempotence {

    uint256 internal constant MAX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    //  GENESIS_HATCHING is in bit 0 = 0b1
    uint256 public constant IDMP_GENESIS_HATCHING_MASK = 0x1;
    //  HATCHING is in bit 1 = 0b10
    uint256 public constant IDMP_HATCHING_MASK = 0x2;
    //  EVOLVING is in bit 2 = 0b100
    uint256 public constant IDMP_EVOLVING_MASK = 0x4;
    //  PARENT IS BREEDING is in bit 3 = 0b1000
    uint256 public constant IDMP_PARENT_IS_BREEDING_MASK = 0x8;
    // NEW_EGG_WAITING_FOR_RNG is in bit 4 = 0b10000
    uint256 public constant IDMP_NEW_EGG_WAITING_FOR_RNG_MASK = 0x10;
    // NEW_EGG_RNG_RECEIVED_WAITING_FOR_TOKENURI is in bit 5 = 0b100000
    uint256 public constant IDMP_NEW_EGG_RNG_RECEIVED_WAITING_FOR_TOKENURI_MASK = 0x20;
    // HATCHING_STARTED is in bit 6 = 0b1000000
    uint256 public constant IDMP_HATCHING_STARTED_MASK = 0x40;
    // HATCHING_RANDOMNESS_FULFILLED is in bit 7 = 0b10000000
    uint256 public constant IDMP_HATCHING_RANDOMNESS_FULFILLED_MASK = 0x80;
    // EVOLUTION_STARTED is int bit 8 = 0b100000000
    uint256 public constant IDMP_EVOLUTION_STARTED_MASK = 0x100;
    // EVOLUTION_RANDOMNESS_FULFILLED is int bit 9 = 0b1000000000
    uint256 public constant IDMP_EVOLUTION_RANDOMNESS_FULFILLED_MASK = 0x200;

    function enforceCleanState(uint256 _tokenId) internal view returns (bool) {
        require(
            !_getGenesisHatching(_tokenId) &&
            !_getHatching(_tokenId) &&
            !_getEvolving(_tokenId) &&
            !_getParentIsBreeding(_tokenId) &&
            !_getNewEggWaitingForRNG(_tokenId) &&
            !_getNewEggReceivedRNGWaitingForTokenURI(_tokenId),
            LibUtil.concat(
                "LibIdempotence: Token [",
                LibUtil.uintToString(_tokenId),
                "] is already in a workflow: ",
                LibUtil.uintToString(_getIdempotenceState(_tokenId))
            )
        );
    }

    function _getIdempotenceState(uint256 _tokenId) internal view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.idempotence_state[_tokenId];
    }

    function _setIdempotenceState(uint256 _tokenId, uint256 _state)
        internal
        returns (uint256)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.idempotence_state[_tokenId] = _state;
        return _state;
    }

    function _clearState(uint256 _tokenId) internal {
        _setIdempotenceState(_tokenId, 0);
    }

    function _setGenesisHatching(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_GENESIS_HATCHING_MASK);
    }

    function _getGenesisHatching(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_GENESIS_HATCHING_MASK);
    }

    function _setHatching(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_HATCHING_MASK);
    }

    function _getHatching(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_HATCHING_MASK);
    }

    function _setHatchingStarted(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getHatchingRandomnessFulfilled(_tokenId) && _val) == false, "Cannot set both hatching flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_HATCHING_STARTED_MASK);
    }

    function _getHatchingStarted(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_HATCHING_STARTED_MASK);
    }

    function _setHatchingRandomnessFulfilled(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getHatchingStarted(_tokenId) && _val) == false, "Cannot set both hatching flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_HATCHING_RANDOMNESS_FULFILLED_MASK);
    }

    function _getHatchingRandomnessFulfilled(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_HATCHING_RANDOMNESS_FULFILLED_MASK);
    }

    function _setEvolving(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_EVOLVING_MASK);
    }

    function _getEvolving(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_EVOLVING_MASK);
    }

    function _setParentIsBreeding(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_PARENT_IS_BREEDING_MASK);
    }
    function _getParentIsBreeding(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_PARENT_IS_BREEDING_MASK);
    }

    function _setNewEggWaitingForRNG(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getNewEggReceivedRNGWaitingForTokenURI(_tokenId) && _val) == false, "Cannot set both new_egg flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_NEW_EGG_WAITING_FOR_RNG_MASK);
    }
    function _getNewEggWaitingForRNG(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_NEW_EGG_WAITING_FOR_RNG_MASK);
    }

    function _setNewEggReceivedRNGWaitingForTokenURI(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getNewEggWaitingForRNG(_tokenId) && _val) == false, "Cannot set both new_egg flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val, IDMP_NEW_EGG_RNG_RECEIVED_WAITING_FOR_TOKENURI_MASK);
    }

    function _getNewEggReceivedRNGWaitingForTokenURI(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_NEW_EGG_RNG_RECEIVED_WAITING_FOR_TOKENURI_MASK);
    }

    function _setEvolutionStarted(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getEvolutionRandomnessFulfilled(_tokenId) && _val) == false, "Cannot set both evolution flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val,  IDMP_EVOLUTION_STARTED_MASK);
    }

    function _getEvolutionStarted(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_EVOLUTION_STARTED_MASK);
    }

    function _setEvolutionRandomnessFulfilled(uint256 _tokenId, bool _val)
        internal
        returns (uint256)
    {
        require((_getEvolutionStarted(_tokenId) && _val) == false, "Cannot set both evolution flags in true");
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.splice(state, _val,  IDMP_EVOLUTION_RANDOMNESS_FULFILLED_MASK);
    }

    function _getEvolutionRandomnessFulfilled(uint256 _tokenId) internal view returns (bool) {
        uint256 state = _getIdempotenceState(_tokenId);
        return LibBin.extractBool(state, IDMP_EVOLUTION_RANDOMNESS_FULFILLED_MASK);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";


library LibUtil {

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, " ", b));
    }

    function concat(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, " ", b, " ", c));
    }

    function concat(
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, " ", b, " ", c, " ", d));
    }

    //  @see: https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LinkTokenInterface} from "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";

library LibRNG {
    uint256 internal constant RNG_BREEDING = 1;
    uint256 internal constant RNG_HATCHING = 2;
    uint256 internal constant RNG_EVOLUTION = 3;

    bytes32 private constant RNGVRF_STORAGE_POSITION = keccak256("diamond.LibRNGVRFV2.storage");

    struct LibRNGVRFV2Storage {
        // Your subscription ID.
        //1923 mumbai
        uint64 subscriptionId;

        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        // mumbai = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        address vrfCoordinator;

        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        //mumbai = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
        bytes32 keyHash;

        // Depends on the number of requested values that you want sent to the
        // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
        // so 100,000 is a safe default for this example contract. Test and adjust
        // this limit based on the network that you select, the size of the request,
        // and the processing of the callback request in the fulfillRandomWords()
        // function.
        mapping (uint256 => uint32) callbackGasLimitForMechanicId;

        // The default is 3, but you can set this higher.
        mapping (uint256 => uint16) confirmationsForMechanicId;

        // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
        uint32 numWords;
    }

    function vrfV2Storage() internal pure returns (LibRNGVRFV2Storage storage vrf) {
        bytes32 position = RNGVRF_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            vrf.slot := position
        }
    }

    function requestRandomnessFor(uint256 mechanicId) internal returns(bytes32) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes32 requestId = requestRandomness(
                ds.rng_chainlinkVRFKeyhash,
                ds.rng_chainlinkVRFFee
        );
        ds.rng_mechanicIdByVRFRequestId[requestId] = mechanicId;
        return requestId;
    }

    function requestRandomWordsFor(uint256 mechanicId) internal returns(uint256) {
		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibRNGVRFV2Storage storage vrfs = vrfV2Storage();
        uint32 callbackGasLimit = vrfs.callbackGasLimitForMechanicId[mechanicId];
        uint16 requestConfirmations = vrfs.confirmationsForMechanicId[mechanicId];
        uint256 requestId = VRFCoordinatorV2Interface(vrfs.vrfCoordinator).requestRandomWords(
            vrfs.keyHash,
            vrfs.subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            vrfs.numWords
        );
		ds.rng_mechanicIdByVRFRequestId[bytes32(requestId)] = mechanicId;
		return requestId;
	}

    function setVRFV2RequestConfirmationsByMechanicId(uint256 mechanicId, uint16 confirmations) internal {
	    vrfV2Storage().confirmationsForMechanicId[mechanicId] = confirmations;
    }

    function setVRFV2NumWords(uint32 words) internal {
        vrfV2Storage().numWords = words;
    }

    function setVRFV2CallbackGasLimitByMechanicId(uint256 mechanicId, uint32 limit) internal {
        vrfV2Storage().callbackGasLimitForMechanicId[mechanicId] = limit;
    }

    function setVRFV2KeyHash(bytes32 keyHash) internal {
        vrfV2Storage().keyHash = keyHash;
    }

    function setVRFV2VrfCoordinatorAddress(address coordinator) internal {
        vrfV2Storage().vrfCoordinator = coordinator;
    }

    function setVRFV2SubscriptionId(uint64 subscriptionId) internal {
        vrfV2Storage().subscriptionId = subscriptionId;
    }

    function getVRFV2RequestConfirmationsByMechanicId(uint256 mechanicId) internal view returns(uint16) {
        return vrfV2Storage().confirmationsForMechanicId[mechanicId];
    }

    function getVRFV2NumWords() internal view returns(uint32) {
        return vrfV2Storage().numWords;
    }

    function getVRFV2CallbackGasLimitByMechanicId(uint256 mechanicId) internal view returns(uint32) {
        return vrfV2Storage().callbackGasLimitForMechanicId[mechanicId];
    }

    function getVRFV2KeyHash() internal view returns(bytes32) {
        return vrfV2Storage().keyHash;
    }

    function getVRFV2VrfCoordinatorAddress() internal view returns(address) {
        return vrfV2Storage().vrfCoordinator;
    }

    function getVRFV2SubscriptionId() internal view returns(uint64) {
        return vrfV2Storage().subscriptionId;
    }

	function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
	function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

	function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee
    ) internal returns (bytes32 requestId) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		LinkTokenInterface(ds.linkTokenAddress).transferAndCall(ds.vrfCoordinator, _fee, abi.encode(_keyHash, 0));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        // So the seed doesn't actually do anything and is left over from an old API.
        uint256 vrfSeed = makeVRFInputSeed(_keyHash, 0, address(this), ds.rng_nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful Link.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input
        // seed, which would result in a predictable/duplicate output.
        ds.rng_nonces[_keyHash]++;
        return makeRequestId(_keyHash, vrfSeed);
    }

    //  Generates a pseudo-random integer. This is cheaper than VRF but less secure.
    //  The rngNonce seed should be rotated by VRF before using this pRNG.
    //  @see: https://www.geeksforgeeks.org/random-number-generator-in-solidity-using-keccak256/
    //  @see: https://docs.chain.link/docs/chainlink-vrf-best-practices/
    //  @return Random integer in the range of [0-_modulus)
	function getCheapRNG(uint _modulus) internal returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ++ds.rngNonce;
        // return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, ds.rngNonce))) % _modulus;
        return uint256(keccak256(abi.encode(ds.rngNonce))) % _modulus;
    }

    function expand(uint256 _modulus, uint256 _seed, uint256 _salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_seed, _salt))) % _modulus;
    }

    function getRuntimeRNG() internal returns (uint256) {
        return getRuntimeRNG(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function getRuntimeRNG(uint _modulus) internal returns (uint256) {
        require(msg.sender != block.coinbase, "RNG: Validators are not allowed to generate their own RNG");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return uint256(keccak256(abi.encodePacked(block.coinbase, gasleft(), block.number, ++ds.rngNonce))) % _modulus;
    }

    function enforceSenderIsSelf() internal {
        require(msg.sender == address(this), "Caller must be the CU Diamond");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPermissionProvider {

    enum Permission {               // WARNING: This list must NEVER be re-ordered
        FARM_ALLOWED,                                                   //0
        JOUST_ALLOWED,              //  Not in use yet                  //1
        RACE_ALLOWED,               //  Not in use yet                  //2
        PVP_ALLOWED,                //  Not in use yet                  //3
        UNIGATCHI_ALLOWED,          //  Not in use yet                  //4
        RAINBOW_RUMBLE_ALLOWED,     //  Not in use yet                  //5
        UNICORN_PARTY_ALLOWED,      //  Not in use yet                  //6

        UNICORN_BREEDING_ALLOWED,                                       //7
        UNICORN_HATCHING_ALLOWED,                                       //8
        UNICORN_EVOLVING_ALLOWED,                                       //9
        UNICORN_AIRLOCK_IN_ALLOWED,                                     //10
        UNICORN_AIRLOCK_OUT_ALLOWED,                                    //11

        LAND_AIRLOCK_IN_ALLOWED,                                        //12
        LAND_AIRLOCK_OUT_ALLOWED,                                       //13

        BANK_STASH_RBW_IN_ALLOWED,                                      //14
        BANK_STASH_RBW_OUT_ALLOWED,                                     //15
        BANK_STASH_UNIM_IN_ALLOWED,                                     //16
        BANK_STASH_UNIM_OUT_ALLOWED,                                    //17
        BANK_STASH_LOOTBOX_IN_ALLOWED,                                  //18                                
        BANK_STASH_KEYSTONE_OUT_ALLOWED,                                //19

        FARM_RMP_BUY,                                                   //20
        FARM_RMP_SELL                                                   //21
    }
    
    event PermissionsChanged(
        address indexed owner,
        address indexed delegate,
        uint256 oldPermissions,
        uint256 newPermissions
    );

    
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IDelegatePermissions} from "IDelegatePermissions.sol";
import {IPermissionProvider} from "IPermissionProvider.sol";
import {LibERC721} from "LibERC721.sol";

library LibPermissions {
    struct LibDelegationStorage {
        address permissionProvider;
    }

    bytes32 private constant DELEGATION_STORAGE_POSITION = keccak256("diamond.libDelegation.storage");
    

    function delegationStorage() internal pure returns (LibDelegationStorage storage lhs) {        
        bytes32 position = DELEGATION_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lhs.slot := position
        }
    }

    function setPermissionProvider(address permissionProvider) internal {
        delegationStorage().permissionProvider = permissionProvider;
    }

    function getPermissionProvider() internal view returns(IDelegatePermissions){
        return IDelegatePermissions(delegationStorage().permissionProvider);
    }
    function allTrue(bool[] memory booleans) private pure returns(bool) {
        uint256 i = 0;
        while(i < booleans.length && booleans[i] == true){
            i++;
        }
        return (i == booleans.length);
    }
    // pros: we reuse this function in every previous enforceCallerOwnsNFT.
    // cons: it's not generic
    function enforceCallerOwnsNFTOrHasPermissions(uint256 tokenId, IPermissionProvider.Permission[] memory permissions) internal view {
        IDelegatePermissions pp = getPermissionProvider();
        address ownerOfNFT = LibERC721.ownerOf(tokenId);

        // Warning: this can be address(0) if the msg.sender is the delegator
        address delegator = pp.getDelegator(msg.sender);

        //Sender owns the NFT or sender's owner owns the NFT and sender has specific permission for this action.
        require(ownerOfNFT == msg.sender || (ownerOfNFT == delegator && pp.checkDelegatePermissions(delegator, permissions)), "LibPermissions: Must own the NFT or have permission from owner");
    }

    function enforceCallerOwnsNFTOrHasPermission(uint256 tokenId, IPermissionProvider.Permission permission) internal view {
        IDelegatePermissions pp = getPermissionProvider();
        address ownerOfNFT = LibERC721.ownerOf(tokenId);

        // Warning: this can be address(0) if the msg.sender is the delegator
        address delegator = pp.getDelegator(msg.sender);

        //Sender owns the NFT or sender's owner owns the NFT and sender has specific permission for this action.
        require(ownerOfNFT == msg.sender || (ownerOfNFT == delegator && pp.checkDelegatePermission(delegator, permission)), "LibPermissions: Must own the NFT or have permission from owner");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IPermissionProvider} from "IPermissionProvider.sol";

interface IDelegatePermissions {
    //  Resets all permissions granted by the caller (delegator) to 0/false.
    //  @emits PermissionsChanged
    function resetDelegatePermissions() external;

    //  Returns the delegate address of a wallet, or 0 if unset.
    //  @param address delegator - The delegator/scholar address to query
    //  @return address delegate - The address with permissions on this account
    function getDelegate(address delegator) external view returns (address delegate);


    //  Returns the delegator address for a delegate, or 0 if unset.
    //  @param address delegate - The address with delegated permissions
    //  @return address delegator - The address granting permissions to the delegate
    function getDelegator(address delegate) external view returns (address delegator);


    //  Returns the location of a Permission in the raw permissions binary map.
    //  @param Permission p - A permission to lookup
    //  @return uint256 index - The location of the permission-bit in the rawPermissions
    function getIndexForDelegatePermission(IPermissionProvider.Permission p) external pure returns (uint256 index);


    //  Returns the raw permission bit array granted by an delegator to a delegate.
    //  If the delegator and delegate arguments don't match the getDelegator/getDelegate
    //  mapping, an error will be thrown.
    //  delegate-less wallet to check the current permission settings.
    //  @param address delegator - The address granteing permission
    //  @return uint256 rawPermissions - The raw bit array of granted permissions
    function getRawDelegatePermissions(address delegator) external view returns (uint256 rawPermissions);


    //  Sets the raw permission bit array granted by the caller.
    //  @return uint256 rawPermissions - The raw bit array of granted permissions
    //  @emits PermissionsChanged
    function setDelegatePermissionsRaw(uint256 rawPermissions) external;


    //  Returns true if the delegator is granting the permission to the delegate.
    //  @param address delegator - The address granteing permission
    //  @param Permission p - The permission to check
    //  @return bool - True if the permission is allowed, otherwise false
    function checkDelegatePermission(address delegator, IPermissionProvider.Permission p) external view returns (bool);


    //  Checks if the delegator is granting permission to the delegate for a list 
    //  of permissions.
    //  @param address delegator - The address granteing permission
    //  @param Permission[] p - List of permissions to check
    //  @return bool - Returns if the delegate associated to the delegator has all the permissions inside the Permission[] array
    function checkDelegatePermissions(address delegator, IPermissionProvider.Permission[] calldata p) external view returns (bool);


    //  Checks if the delegator is granting the permission to the delegate. If the 
    //  permission is not allowed, the transaction will be reverted with an error.
    //  @param address delegator - The address granteing permission
    //  @param Permission p - The permission to check
    function requireDelegatePermission(address delegator, IPermissionProvider.Permission p) external view;


    //  Checks if the delegator is granting multiple permissions to the delegate.
    //  If any of the permissions are not allowed, the transaction will be reverted
    //  with an error.
    //  @param address delegator - The address granteing permission
    //  @param Permission[] p - List of permissions to check
    function requireDelegatePermissions(address delegator, IPermissionProvider.Permission[] calldata p) external view;


    //  Sets an individual permission bit flag to true or false for the caller,
    //  which grants that permission to the associated delegate address. If no 
    //  delegate is assigned (ie. address 0) then the permission is still set and
    //  will become active when a delegate address is set.
    //  @param Permission permission - The permission to set
    //  @param bool state - True to allow permission, or false to revoke
    //  @emits PermissionsChanged
    function setDelegatePermission(IPermissionProvider.Permission permission, bool state) external;


    //  Sets multiple permissions to true or false for the caller, which grants
    //  those permissions t othe associated delegate address. If no delegate is 
    //  assigned (ie. address 0) then the permissions will still be set and will
    //  become active when a delegate address is set.
    //  @param Permission[] permissions - A list of permissions
    //  @param bool[] states - True or false for each Permission
    //  @emits PermissionsChanged
    function setDelegatePermissions(IPermissionProvider.Permission[] calldata permissions, bool[] calldata states) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibERC721} from "LibERC721.sol";
import {LibRNG} from "LibRNG.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";
import {LibUnicornNames} from "LibUnicornNames.sol";
import {LibIdempotence} from "LibIdempotence.sol";
import {LibRNG} from "LibRNG.sol";
import {LibHatching} from "LibHatching.sol";
import {LibEvents} from "LibEvents.sol";

interface IEggHelper {
    function getClass(uint256 tokenId) external view returns (uint8);
    function getTokenURI(uint256 i) external pure returns (string memory);
}


library LibMumbaiDebugV1 {
    event LibMumbaiDebugV1Activity(string method, address indexed caller);

    uint256 private constant MUMBAI_CHAINID = 80001;
    uint256 private constant POLYGON_CHAINID = 137;
    uint256 private constant LOCAL_CHAINID = 1337;
    bytes32 private constant DEBUG_STORAGE_POSITION = keccak256("diamond.libMumbaiDebug.storage");

    /* solhint-disable var-name-mixedcase */
    struct LibMumbaiDebugStorage {
        bool debugEnabled;
        mapping(address => bool) admins;
        address[] allAdmins;
        mapping(address => bool) debuggers;
        address[] allDebuggers;
        mapping(address => bool) bans;
        address eggHelperAddress;
        uint256[4] HEART_DNAS;
        uint256[4] CLOUD_DNAS;
        uint256[4] FLOWER_DNAS;
        uint256[4] CANDY_DNAS;
        uint256[4] CRYSTAL_DNAS;
        uint256[4] MOON_DNAS;
        string[4] HEART_URIS;
        string[4] CLOUD_URIS;
        string[4] FLOWER_URIS;
        string[4] CANDY_URIS;
        string[4] CRYSTAL_URIS;
        string[4] MOON_URIS;
        mapping(uint256 => bool) tokenIdToVRFWillFail;
    } /* solhint-enable var-name-mixedcase */

    function libMumbaiDebugStorage() private pure returns (LibMumbaiDebugStorage storage lmds) {
        bytes32 position = DEBUG_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lmds.slot := position
        }
    }

    function enforceDebuggingEnabled() internal view {
        enforceTestnetOrLocal();
        require(libMumbaiDebugStorage().debugEnabled, "LibMumbaiDebugV1: Debugging is disabled");
    }

    function enforceTestnet() internal view {
        require(block.chainid == MUMBAI_CHAINID, "LibMumbaiDebugV1: This code CANNOT run be outside of Testnet!");
    }

    function enforceTestnetOrLocal() internal view {
        require(block.chainid == MUMBAI_CHAINID || block.chainid == LOCAL_CHAINID, "LibMumbaiDebugV1: This code CANNOT run be outside of Testnet or locally!");
    }

    function enforceDebuggerOrAdmin() internal view {
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        require(!lmds.bans[msg.sender], "LibMumbaiDebugV1: Caller is banned");
        require(lmds.admins[msg.sender] || lmds.debuggers[msg.sender], "LibMumbaiDebugV1: Caller is not a recognized debugger");
    }

    function enforceAdmin() internal view {
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        require(!lmds.bans[msg.sender], "LibMumbaiDebugV1: Caller is banned");
        require(lmds.admins[msg.sender], "LibMumbaiDebugV1: Caller is not a recognized admin");
    }

    function initialize() internal {
        enforceTestnetOrLocal();
        LibDiamond.enforceIsContractOwner();
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        lmds.admins[msg.sender] = true;   //  owner is always an admin
        lmds.allAdmins.push(msg.sender);
        lmds.eggHelperAddress = 0xE5641BC9c1a4ef6eE58c8DebE8dfa1022B3F1FdC;
        lmds.debuggers[msg.sender] = true;   //  owner is always an admin
        lmds.allDebuggers.push(msg.sender);
        initializeContent();
        debugEvent("initialize");
    }

    function debugEvent(string memory _s) internal {
        enforceTestnetOrLocal();
        emit LibMumbaiDebugV1Activity(_s, msg.sender);
    }

    function enableDebugging() internal {
        enforceTestnetOrLocal();
        LibDiamond.enforceIsContractOwner();
        libMumbaiDebugStorage().debugEnabled = true;
    }

    function disableDebugging() internal {
        enforceAdmin();
        libMumbaiDebugStorage().debugEnabled = false;
    }

    function registerAdmin(address _a) internal {
        enforceTestnet();
        enforceAdmin();
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        lmds.admins[_a] = true;
        lmds.allAdmins.push(_a);
        debugEvent("libMumbaiDebugRegisterAdmin");
    }

    function registerDebugger(address _a) internal {
        enforceTestnet();
        enforceAdmin();
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        lmds.debuggers[_a] = true;
        lmds.allDebuggers.push(_a);
        debugEvent("libMumbaiDebugRegisterDebugger");
    }

    function repairMissingRoles() internal {
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        for(uint i = 0; i < lmds.allDebuggers.length; ++i) {
            lmds.debuggers[lmds.allDebuggers[i]] = true;
        }

        for(uint i = 0; i < lmds.allAdmins.length; ++i) {
            lmds.admins[lmds.allAdmins[i]] = true;
        }
    }

    function isAdmin(address _a) internal view returns (bool) {
        return libMumbaiDebugStorage().admins[_a];
    }

    function isDebugger(address _a) internal view returns (bool) {
        return libMumbaiDebugStorage().debuggers[_a];
    }

    function setEggHelperAddress(address _a) internal {
        enforceTestnet();
        enforceAdmin();
        libMumbaiDebugStorage().eggHelperAddress = _a;
        debugEvent("setEggHelperAddress");
    }

    function getEggClassFromHelper(uint256 tokenId) internal view returns (uint8) {
        enforceTestnet();
        IEggHelper ie = IEggHelper(libMumbaiDebugStorage().eggHelperAddress);
        return ie.getClass(tokenId);
    }

    function getEggURIFromHelper(uint256 tokenId) internal view returns (string memory) {
        enforceTestnet();
        IEggHelper ie = IEggHelper(libMumbaiDebugStorage().eggHelperAddress);
        return ie.getTokenURI(tokenId);
    }

    function mintGenesisEgg(address _to) internal {
        enforceDebuggingEnabled();
        enforceDebuggerOrAdmin();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // inline _mint
        uint256 tokenId = ds.erc721_current_token_id + 1;
        require(ds.erc721_owners[tokenId] == address(0), "LibMumbaiDebug: Token already minted");
        ds.erc721_allTokensIndex[tokenId] = ds.erc721_allTokens.length;
        ds.erc721_allTokens.push(tokenId);
        uint256 length = ds.erc721_balances[_to];
        ds.erc721_ownedTokens[_to][length] = tokenId;
        ds.erc721_ownedTokensIndex[tokenId] = length;
        ds.erc721_balances[_to] += 1;
        ds.erc721_owners[tokenId] = _to;
        ds.erc721_current_token_id = tokenId;
        // emit Transfer(address(0), _to, tokenId);

        uint256 dna = 0;
        dna = LibUnicornDNA._setVersion(dna, LibUnicornDNA._targetDNAVersion());
        dna = LibUnicornDNA._setOrigin(dna, true);
        dna = LibUnicornDNA._setGameLocked(dna, false);
        dna = LibUnicornDNA._setLimitedEdition(dna, false);
        dna = LibUnicornDNA._setLifecycleStage(dna, LibUnicornDNA.LIFECYCLE_EGG);
        dna = LibUnicornDNA._setBreedingPoints(dna, 0);
        dna = LibUnicornDNA._setClass(dna, getEggClassFromHelper(tokenId));
        LibUnicornDNA._setDNA(tokenId, dna);
        LibERC721.setTokenURI(tokenId, getEggURIFromHelper(tokenId));
        debugEvent("mintGenesisEgg");
    }

    function mintFromDNA(address _to, uint256 _dna, string calldata _uri, bool _transferEvent) internal {
        enforceDebuggingEnabled();
        enforceDebuggerOrAdmin();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // inline _mint
        uint256 tokenId = ds.erc721_current_token_id + 1;
        require(ds.erc721_owners[tokenId] == address(0), "LibMumbaiDebug: Token already minted");
        ds.erc721_allTokensIndex[tokenId] = ds.erc721_allTokens.length;
        ds.erc721_allTokens.push(tokenId);
        uint256 length = ds.erc721_balances[_to];
        ds.erc721_ownedTokens[_to][length] = tokenId;
        ds.erc721_ownedTokensIndex[tokenId] = length;
        ds.erc721_balances[_to] += 1;
        ds.erc721_owners[tokenId] = _to;
        ds.erc721_current_token_id = tokenId;

        LibUnicornDNA._setDNA(tokenId, _dna);
        LibERC721.setTokenURI(tokenId, getEggURIFromHelper(tokenId));

        if (_transferEvent) {
            emit LibEvents.Transfer(address(0), _to, tokenId);
        }
        debugEvent("mintGenesisEgg");
    }

    function downgradeToEgg(uint256 _tokenId) internal {
        enforceDebuggingEnabled();
        enforceDebuggerOrAdmin();
        uint256 dna = LibUnicornDNA._getDNA(_tokenId);
        uint256 newDNA = 0;
        newDNA = LibUnicornDNA._setVersion(newDNA, LibUnicornDNA._getVersion(dna));
        newDNA = LibUnicornDNA._setOrigin(newDNA, LibUnicornDNA._getOrigin(dna));
        newDNA = LibUnicornDNA._setGameLocked(newDNA, LibUnicornDNA._getGameLocked(dna));
        newDNA = LibUnicornDNA._setLimitedEdition(newDNA, LibUnicornDNA._getLimitedEdition(dna));
        newDNA = LibUnicornDNA._setLifecycleStage(newDNA, LibUnicornDNA.LIFECYCLE_EGG);
        newDNA = LibUnicornDNA._setBreedingPoints(newDNA, 0);
        newDNA = LibUnicornDNA._setClass(newDNA, LibUnicornDNA._getClass(dna));
        LibERC721.setTokenURI(_tokenId, getEggURIFromHelper(_tokenId));
        newDNA = LibUnicornDNA._setFirstNameIndex(newDNA, LibUnicornDNA._getFirstNameIndex(dna));
        newDNA = LibUnicornDNA._setLastNameIndex(newDNA, LibUnicornDNA._getLastNameIndex(dna));
        debugEvent("downgradeToEgg");
    }

    function downgradeToBaby(uint256 _tokenId) internal {
        enforceDebuggingEnabled();
        enforceDebuggerOrAdmin();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 dna = LibUnicornDNA._getDNA(_tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        require(LibUnicornDNA._getLifecycleStage(dna) == LibUnicornDNA.LIFECYCLE_ADULT, "Debug: Unicorn is not an adult");
        dna = LibUnicornDNA._setLifecycleStage(dna, LibUnicornDNA.LIFECYCLE_BABY);
        dna = LibUnicornDNA._setBreedingPoints(dna, 0);
        LibUnicornDNA._setDNA(_tokenId, dna);
        // _setTokenURI(tokenId, tokenURI);
        LibIdempotence._clearState(_tokenId);
        debugEvent("downgradeToBaby");
    }

    function hatchToRandomAdult(uint256 _tokenId) internal {
        enforceDebuggingEnabled();
        enforceDebuggerOrAdmin();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        uint256 dna = LibUnicornDNA._getDNA(_tokenId);
        LibUnicornDNA.enforceDNAVersionMatch(dna);
        uint256 unicornClass = LibUnicornDNA._getClass(dna);
        uint rng = _tokenId % 4;
        if(unicornClass == 0 || unicornClass == 9) {
            dna = lmds.HEART_DNAS[rng];
            ds.erc721_tokenURIs[_tokenId] = lmds.HEART_URIS[rng];
        } else if (unicornClass == 2) {
            dna = lmds.CLOUD_DNAS[rng];
            ds.erc721_tokenURIs[_tokenId] = lmds.CLOUD_URIS[rng];
        } else if (unicornClass == 3) {
            dna = lmds.FLOWER_DNAS[rng];
            ds.erc721_tokenURIs[_tokenId] = lmds.FLOWER_URIS[rng];
        } else if (unicornClass == 4) {
            dna = lmds.CANDY_DNAS[rng];
            ds.erc721_tokenURIs[_tokenId] = lmds.CANDY_URIS[rng];
        } else if (unicornClass == 6) {
            dna = lmds.CRYSTAL_DNAS[rng];
            ds.erc721_tokenURIs[_tokenId] = lmds.CRYSTAL_URIS[rng];
        } else if (unicornClass == 7) {
            dna = lmds.MOON_DNAS[rng];
            ds.erc721_tokenURIs[_tokenId] = lmds.MOON_URIS[rng];
        } else {
            revert("Invalid class");
        }

        uint256[2] memory names = LibUnicornNames._getRandomName(LibRNG.getRuntimeRNG(10000000000), LibRNG.getRuntimeRNG(10000000000));
        dna = LibUnicornDNA._setFirstNameIndex(dna, names[0]);
        dna = LibUnicornDNA._setFirstNameIndex(dna, names[1]);
        ds.unicorn_dna[_tokenId] = dna;

        ds.hatch_birthday[_tokenId] = block.timestamp;
        ds.bio_clock[_tokenId] = block.timestamp;
        debugEvent("hatchToRandomAdult");
    }

    function initializeContent() private {
        LibMumbaiDebugStorage storage lmds = libMumbaiDebugStorage();
        lmds.HEART_DNAS = [
            2627779188654163462426433593434964104127275422571432525864964353,
            1357667288245092020836087703232713913554851935097137589058081025,
            1595528649910161565294797183476549444091253814225139698887627009,
            2529752051181410907210730301131099236257106677950721590160331009
        ];

        lmds.HEART_URIS = [
            "https://arweave.net/GICm0dvCKREIFG6rtDT4Ru5vTH4VjQTpU2Zl_jxH1P0",
            "https://arweave.net/shW87v6QDL1VjPYW3coFgX79TFd_JU9KcRU3KRpm2p4",
            "https://arweave.net/dfmy9U6gYrlJQtuU4MLT9aLkQh9dOAcpNttE51myANs",
            "https://arweave.net/mVq8-vc-esTbq5R_FCE3paT386DeaRJrNrOA14zEagw"
        ];

        lmds.CLOUD_DNAS = [
            1906661039883918528179941700479225846500802447199510872631611649,
            1913906369008975733322391261128984527859022307643676082886217985,
            412022702493568466279959751974465079752596793022912481341018369,
            417636772906553942305939467247591172633113095561391126260027649
        ];

        lmds.CLOUD_URIS = [
            "https://arweave.net/GMzy93DZhsmbatjoTa34TRnvb1ufvHl1bG2kpD_EpUM",
            "https://arweave.net/w0V-mJWSpMsR5inLp0-2zKAg1hPMBo9swgOS8Uw4Opk",
            "https://arweave.net/xAxfcteC0cE-V_-ww3Lz_pN1qftp-462Hna-0wQc7eU",
            "https://arweave.net/BsKd1c6Jl8-4mZOf7TqtPXC1fl9E9ygCKbl8wYojiM0"
        ];

        lmds.FLOWER_DNAS = [
            672356081901075913321992244769133676693246364924709624141517057,
            109123494361698739045525162863955305292285610587294481426878721,
            1290825558370755060012090069880246839793671148788283367206883585,
            3500533288607652368433384165039342527077126737019246995636162817
        ];

        lmds.FLOWER_URIS = [
            "https://arweave.net/MncnGz1r_tE0pgC6c04A1aEY-UbTxUAuDk_chMPrcNM",
            "https://arweave.net/B9vjtU8CYcW7H5SsC2ztHhs3p-RqVi220UBhjIMao2s",
            "https://arweave.net/2pYtcqbUIr6KUZuQBropACHPVVqbjmH7gMG-cb8FeBo",
            "https://arweave.net/KakO38MYPkc1TURJqovs-FD7b_w3mCpK_1IRtQ3thhE"
        ];

        lmds.CANDY_DNAS = [
            5659058307955590067888273030014257816058203730023217418704851201,
            364986804442619093142230772324888155549639333242114503585894657,
            1705793778363878859881059110161224695140546716389060936955662593,
            2268853736411046521414350156219102870894704328962900148116590849
        ];

        lmds.CANDY_URIS = [
            "https://arweave.net/xj97rWRSFk20sB_XUCTVz9OoHOTOVjkfwIlR6HoQyLM",
            "https://arweave.net/LGTNx7Rui3mXZAtIJrBo8_GkYss_l-nfsDqH79uJbmk",
            "https://arweave.net/cIqSB8AZyp4OBIiwpiucsWOA268K6eaBybCgE7zGie4",
            "https://arweave.net/I-EE7Oe2LoxoDVsI4gGAcMkJxjnaM4YbdJcRPlTBLhY"
        ];

        lmds.CRYSTAL_DNAS = [
            1617473390749688233437118205264910748645794200383683241582596353,
            675923816896742257293525728393240595500757823081559932202193153,
            1285958465579723500647553391918654504475577542838983569376612609,
            1925934868574376031200497530858220592418275533067263992679698689
        ];

        lmds.CRYSTAL_URIS = [
            "https://arweave.net/CuKNanGKtHPf6xZ3nFvLWAQ8bjVux_3vE3gq8gLc7Lw",
            "https://arweave.net/Zwz8yQpoQ-WQp7yQigKF1AHZf9HdBMe7AoMo2FG73oE",
            "https://arweave.net/oVmMYtwnvvqnnJv0dytgrJaiOy7EIkCT6uLRuWHM8sA",
            "https://arweave.net/S8g5UX2B7lwClXioWEe3qidQmFzFUi0uO0XjRWTqbcw"
        ];

        lmds.MOON_DNAS = [
            1289396742150673540086552481376983199148966544943699077211558145,
            5936642741097545194260733952007448165270588517088649359360200961,
            57855277562884871098257633462799229474871095186288286618292481,
            2228230684348877476617113637697792212343736090931153477009608961
        ];

        lmds.MOON_URIS = [
            "https://arweave.net/3TfzyXRip8AApBnMQHIWcFTbUxCSEmH6Oebh5T7J-8U",
            "https://arweave.net/PfBuwFUhNDP7VfKyjAhKMDt_wATXOufCAIZlGFY6ptk",
            "https://arweave.net/1_-mBnBN9pODctjQn6dua1KIAmk609NyVB20gs98rvM",
            "https://arweave.net/XOjx8z-qwcNjstajZe81DPPObdSacUlB_l98ydxDL5A"
        ];
    }

    function getVRFFailure(uint256 tokenId) internal view returns(bool willItFail){
        enforceTestnetOrLocal();
        LibMumbaiDebugStorage storage lms = libMumbaiDebugStorage();
        willItFail = lms.tokenIdToVRFWillFail[tokenId];
    }

    function setVRFFailure(uint256 tokenId, bool willItFail) internal {
        enforceTestnetOrLocal();
        enforceAdmin();
        LibMumbaiDebugStorage storage lms = libMumbaiDebugStorage();
        lms.tokenIdToVRFWillFail[tokenId] = willItFail;
    }

    function enforceTokenIsNotBannedFromVRF(uint256 tokenId) internal view {
        enforceTestnetOrLocal();
        require(!getVRFFailure(tokenId), "Token is banned from fulfilling randomness");
    }

    //  TODO - remove these
    uint256 private constant BODY_SLOT = 1;
    uint256 private constant FACE_SLOT = 2;
    uint256 private constant HORN_SLOT = 3;
    uint256 private constant HOOVES_SLOT = 4;
    uint256 private constant MANE_SLOT = 5;
    uint256 private constant TAIL_SLOT = 6;
    uint256 private constant SALT_11 = 11;
    uint256 private constant SALT_12 = 12;
    uint256 private constant SALT_13 = 13;
    uint256 private constant SALT_14 = 14;
    uint256 private constant SALT_15 = 15;
    uint256 private constant SALT_16 = 16;
    uint256 private constant SALT_21 = 21;
    uint256 private constant SALT_22 = 22;
    uint256 private constant SALT_23 = 23;
    uint256 private constant SALT_24 = 24;
    uint256 private constant SALT_25 = 25;
    uint256 private constant SALT_26 = 26;
    uint256 private constant SALT_31 = 31;
    uint256 private constant SALT_32 = 32;
    uint256 private constant SALT_33 = 33;
    uint256 private constant SALT_34 = 34;
    uint256 private constant SALT_35 = 35;
    uint256 private constant SALT_36 = 36;
    uint256 private constant SALT_41 = 41;
    uint256 private constant SALT_42 = 42;
    uint256 private constant SALT_43 = 43;
    uint256 private constant SALT_44 = 44;
    uint256 private constant SALT_45 = 45;
    uint256 private constant SALT_46 = 46;
    uint256 private constant SALT_51 = 51;
    uint256 private constant SALT_52 = 52;
    uint256 private constant SALT_53 = 53;
    uint256 private constant SALT_54 = 54;
    uint256 private constant SALT_55 = 55;
    uint256 private constant SALT_56 = 56;
    uint256 private constant SALT_61 = 61;
    uint256 private constant SALT_62 = 62;
    uint256 private constant SALT_63 = 63;
    uint256 private constant SALT_64 = 64;
    uint256 private constant SALT_65 = 65;
    uint256 private constant SALT_66 = 66;

    //  TODO - remove this
    function debugDumpHatchingData(uint256 tokenId) internal view returns(
        uint256 blockDeadlineByVRFRequestId,
        uint256 roundTripIdByVRFRequestId,
        bytes32 vrfRequestIdByRoundTripId,
        uint256 tokenIdByVRFRequestId,
        uint256 inheritanceChanceByVRFRequestId,
        uint256 rngByVRFRequestId,
        uint256 rngBlockNumberByVRFRequestId,
        uint256 birthdayByVRFRequestId,
        uint256 roundTripIdByTokenId
    ){
        enforceTestnetOrLocal();
        LibHatching.LibHatchingStorage storage lhs = LibHatching.hatchingStorage();
        uint256 roundTripId = lhs.roundTripIdByTokenId[tokenId];
        bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[roundTripId];
        blockDeadlineByVRFRequestId = lhs.blockDeadlineByVRFRequestId[vrfRequestId];
        roundTripIdByVRFRequestId = lhs.roundTripIdByVRFRequestId[vrfRequestId];
        vrfRequestIdByRoundTripId = lhs.vrfRequestIdByRoundTripId[roundTripId];
        tokenIdByVRFRequestId = lhs.tokenIdByVRFRequestId[vrfRequestId];
        inheritanceChanceByVRFRequestId = lhs.inheritanceChanceByVRFRequestId[vrfRequestId];
        rngByVRFRequestId = lhs.rngByVRFRequestId[vrfRequestId];
        rngBlockNumberByVRFRequestId = lhs.rngBlockNumberByVRFRequestId[vrfRequestId];
        birthdayByVRFRequestId = lhs.birthdayByVRFRequestId[vrfRequestId];
        roundTripIdByTokenId = lhs.roundTripIdByTokenId[tokenId];
    }

    //  TODO - remove this
    function debugTestHatchMatching(uint256 tokenId) internal view returns (
        uint256 firstParentDNA,
        uint256 secondParentDNA,
        uint256 dna,
        uint256 classId,
        uint256 matching
    ) {
        dna = LibUnicornDNA._getCanonicalDNA(tokenId);
        classId = LibUnicornDNA._getClass(dna);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        firstParentDNA = LibUnicornDNA._getDNA(ds.unicornParents[tokenId][0]);
        secondParentDNA = LibUnicornDNA._getDNA(ds.unicornParents[tokenId][1]);

        //  Optimization for stack depth limit:
        //  {0: neither,  1: firstParent,  2: secondParent,  3: both}
        matching = 0;

        if(classId == LibUnicornDNA._getClass(firstParentDNA)) {
            matching += 1;
        }

        if(classId == LibUnicornDNA._getClass(secondParentDNA)) {
            matching += 2;
        }
    }

    //  TODO - remove this
    function preflightHatchingA(uint256 tokenId) private view returns (
        bytes32 vrfRequestId,
        uint256 dna,
        uint256 classId,
        uint256 matching,
        LibDiamond.DiamondStorage storage ds,
        uint256 firstParentDNA,
        uint256 secondParentDNA
    ){
        require(!LibIdempotence._getHatchingStarted(tokenId), "LibHatching: RNG not ready");
        require(LibIdempotence._getHatchingRandomnessFulfilled(tokenId), "LibHatching: Waiting for VRF TTL");
        LibHatching.LibHatchingStorage storage lhs = LibHatching.hatchingStorage();
        vrfRequestId = lhs.vrfRequestIdByRoundTripId[lhs.roundTripIdByTokenId[tokenId]];
        require(lhs.rngBlockNumberByVRFRequestId[vrfRequestId] > 0, "LibHatching: No RNG set");
        require(lhs.rngBlockNumberByVRFRequestId[vrfRequestId] < block.number, "LibHatching: Prediction masked during RNG set block");
        dna = LibUnicornDNA._getCanonicalDNA(tokenId);
        require(LibUnicornDNA._getLifecycleStage(dna) == LibUnicornDNA.LIFECYCLE_EGG, "LibHatching: DNA has already been persisted (dna)");
        classId = LibUnicornDNA._getClass(dna);

        ds = LibDiamond.diamondStorage();
        firstParentDNA = LibUnicornDNA._getDNA(ds.unicornParents[tokenId][0]);
        secondParentDNA = LibUnicornDNA._getDNA(ds.unicornParents[tokenId][1]);

        //  Optimization for stack depth limit:
        //  {0: neither,  1: firstParent,  2: secondParent,  3: both}
        matching = 0;

        if(classId == LibUnicornDNA._getClass(firstParentDNA)) {
            matching += 1;
        }

        if(classId == LibUnicornDNA._getClass(secondParentDNA)) {
            matching += 2;
        }
    }

    //  TODO - remove this
    function debugStepthroughHatchingA(uint256 tokenId) internal view returns (
        uint256 dnaA,
        uint256 dnaB,
        uint256 dnaC,
        uint256 rng11,
        uint256 rng12,
        string memory bodyTrace,
        uint256 partId
    ) {
        bytes32 vrfRequestId;
        uint256 dna;
        uint256 classId;
        uint256 matching;
        LibDiamond.DiamondStorage storage ds;
        uint256 firstParentDNA;
        uint256 secondParentDNA;

        (vrfRequestId, dna, classId, matching, ds, firstParentDNA, secondParentDNA) = preflightHatchingA(tokenId);
        LibHatching.LibHatchingStorage storage lhs = LibHatching.hatchingStorage();

        dnaA = dna;
        dna = LibUnicornDNA._setLifecycleStage(dna, LibUnicornDNA.LIFECYCLE_BABY);
        dnaB = dna;
        uint256 inheritanceChance  = lhs.inheritanceChanceByVRFRequestId[vrfRequestId];
        uint256 randomness = lhs.rngByVRFRequestId[vrfRequestId];
        rng11 = LibRNG.expand(10000, randomness, SALT_11);

        //  BODY
        if (matching > 0 && LibRNG.expand(10000, randomness, SALT_11) < inheritanceChance) {
            bodyTrace = "a";
            //  inherit
            if (matching == 3) {
                bodyTrace = "b";
                if(LibRNG.expand(2, randomness, SALT_12) == 1) {
                    bodyTrace = "c";
                    dna = LibUnicornDNA._inheritBody(dna, firstParentDNA);
                    dnaC = dna;
                } else {
                    bodyTrace = "d";
                    dna = LibUnicornDNA._inheritBody(dna, secondParentDNA);
                    dnaC = dna;
                }
            } else if (matching == 2) {
                dna = LibUnicornDNA._inheritBody(dna, secondParentDNA);
                bodyTrace = "e";
                dnaC = dna;
            } else {
                dna = LibUnicornDNA._inheritBody(dna, firstParentDNA);
                bodyTrace = "f";
                dnaC = dna;
            }
        } else {
            bodyTrace = "g";
            //  randomize
            partId = LibHatching.getRandomPartId(ds, classId, BODY_SLOT, randomness, SALT_13);
            dna = LibUnicornDNA._multiSetBody(
                dna,
                ds.bodyPartLocalIdFromGlobalId[partId],
                ds.bodyPartInheritedGene[partId],
                LibHatching.getRandomGeneId(ds, classId, randomness, SALT_15),
                LibHatching.getRandomGeneId(ds, classId, randomness, SALT_16)
            );
            dnaC = dna;
        }
    }

    function debugHatchingRNGGates(uint256 tokenId) internal view returns (
        uint256 randomness,
        uint256 inheritanceChance,
        uint256 bodyChance,
        uint256 faceChance,
        uint256 hornChance,
        uint256 hoovesChance,
        uint256 maneChance,
        uint256 tailChance
    ) {
        LibHatching.LibHatchingStorage storage lhs = LibHatching.hatchingStorage();
        bytes32 vrfRequestId = lhs.vrfRequestIdByRoundTripId[lhs.roundTripIdByTokenId[tokenId]];
        randomness = lhs.rngByVRFRequestId[vrfRequestId];
        inheritanceChance  = lhs.inheritanceChanceByVRFRequestId[vrfRequestId];

        bodyChance = LibRNG.expand(10000, randomness, SALT_11);
        faceChance = LibRNG.expand(10000, randomness, SALT_21);
        hornChance = LibRNG.expand(10000, randomness, SALT_31);
        hoovesChance = LibRNG.expand(10000, randomness, SALT_41);
        maneChance = LibRNG.expand(10000, randomness, SALT_51);
        tailChance = LibRNG.expand(10000, randomness, SALT_61);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibDiamond} from "LibDiamond.sol";
import {LibUnicornDNA} from "LibUnicornDNA.sol";

library LibUnicornNames {

    function _lookupFirstName(uint256 _nameId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().firstNamesList[_nameId];
    }

    function _lookupLastName(uint256 _nameId) internal view returns (string memory) {
        return LibDiamond.diamondStorage().lastNamesList[_nameId];
    }

    function _getFullName(uint256 _tokenId) internal view returns (string memory) {
        return _getFullNameFromDNA(LibUnicornDNA._getDNA(_tokenId));
    }

    function _getFullNameFromDNA(uint256 _dna) internal view returns (string memory) {
        LibUnicornDNA.enforceDNAVersionMatch(_dna);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        //  check if either first or last name is "" - avoid extra whitespace
        if(LibUnicornDNA._getFirstNameIndex(_dna) == 1) {
            return ds.lastNamesList[LibUnicornDNA._getLastNameIndex(_dna)];
        } else if (LibUnicornDNA._getLastNameIndex(_dna) == 1) {
            return ds.firstNamesList[LibUnicornDNA._getFirstNameIndex(_dna)];
        }

        return string(
            abi.encodePacked(
                ds.firstNamesList[LibUnicornDNA._getFirstNameIndex(_dna)], " ",
                ds.lastNamesList[LibUnicornDNA._getLastNameIndex(_dna)]
            )
        );
    }

    ///@notice Obtains random names from the valid ones.
    ///@dev Will throw if there are no validFirstNames or validLastNames
    ///@param randomnessFirstName at least 10 bits of randomness
    ///@param randomnessLastName at least 10 bits of randomness
    function _getRandomName(uint256 randomnessFirstName, uint256 randomnessLastName) internal view returns (uint256[2] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.validFirstNames.length > 0, "NamesFacet: First-name list is empty");
        require(ds.validLastNames.length > 0, "NamesFacet: Last-name list is empty");
        return [
            ds.validFirstNames[(randomnessFirstName % ds.validFirstNames.length)],
            ds.validLastNames[(randomnessLastName % ds.validLastNames.length)]
        ];
    }

    function _firstNameIsAssignable(uint256 firstNameIndex) internal view returns(bool isAssignable){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        isAssignable = false;
        for(uint256 i = 0; i < ds.validFirstNames.length; i++) {
            if(ds.validFirstNames[i] == firstNameIndex) {
                isAssignable = true;
            }
        }
        return isAssignable;
    }
    
    function _lastNameIsAssignable(uint256 lastNameIndex) internal view returns(bool isAssignable){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        isAssignable = false;
        for(uint256 i = 0; i < ds.validLastNames.length && !isAssignable; i++) {
            if(ds.validLastNames[i] == lastNameIndex) {
                isAssignable = true;
            }
        }
        return isAssignable;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ECDSA.sol";
import "Address.sol";
import "IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

import "IERC721.sol";

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {LibBin} from "LibBin.sol";
import {LibDiamond} from "LibDiamond.sol";

library LibElo {
    event UnicornRecordChanged(
        uint256 indexed tokenId,
        uint256 oldUnicornRecord,
        uint256 newUnicornRecord
    );
    event JoustOracleUpdated(
        address indexed oldOracle,
        address indexed newOracle
    );
    event TargetUnicornVersionUpdated(
        uint8 oldUnicornVersion,
        uint8 newUnicornVersion
    );

    //  version is in bits 0-7 = 0b11111111
    uint256 public constant DNA_VERSION_MASK = 0xFF;

    //  joustWins is in bits 8-27 = 0b1111111111111111111100000000
    uint256 public constant DNA_JOUSTWINS_MASK = 0xFFFFF00;

    //  joustLosses is in bits 28-47 = 0b111111111111111111110000000000000000000000000000
    uint256 public constant DNA_JOUSTLOSSES_MASK = 0xFFFFF0000000;

    //  joustTourneyWins is in bits 48-67 = 0b11111111111111111111000000000000000000000000000000000000000000000000
    uint256 public constant DNA_JOUSTTOURNEYWINS_MASK = 0xFFFFF000000000000;

    //  joustElo is in bits 68-81 = 0b1111111111111100000000000000000000000000000000000000000000000000000000000000000000
    uint256 public constant DNA_JOUSTELO_MASK = 0x3FFF00000000000000000;

    // Maximum value for 20 bits (1048576)
    uint256 public constant MAX_VALUE_20_BITS = 1048576;

    bytes32 private constant ELO_STORAGE_POSITION =
        keccak256("diamond.LibElo.storage");

    struct LibEloStorage {
        mapping(uint256 tokenId => uint256 record) unicornRecord;
        address oracle;
        uint8 targetUnicornVersion;
    }

    function eloStorage() internal pure returns (LibEloStorage storage lelos) {
        bytes32 position = ELO_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lelos.slot := position
        }
    }

    /// @notice Set raw unicorn record for the tokenId
    /// @dev The internal function validates joustWins, joustLosses, joustTournamentWins, and joustEloScore
    /// @param _tokenId - Unique id of the token
    /// @param _unicornRecord - Unicorn record data to be set for tokenId
    /// @custom:emits UnicornRecordChanged
    function _setRawUnicornRecord(
        uint256 _tokenId,
        uint256 _unicornRecord
    ) internal {
        require(
            LibDiamond.diamondStorage().erc721_owners[_tokenId] != address(0),
            "LibElo: TokenID does not have owner"
        );

        require(_unicornRecord > 0, "LibElo: cannot set 0 as unicorn record");

        uint256 _oldUnicornRecord = eloStorage().unicornRecord[_tokenId];
        uint256 version = _getVersion(_unicornRecord);
        uint256 joustWins = _getJoustWins(_unicornRecord);
        uint256 joustLosses = _getJoustLosses(_unicornRecord);
        uint256 joustTournamentWins = _getJoustTournamentWins(_unicornRecord);
        uint256 joustEloScore = _getJoustEloScore(_unicornRecord);

        validateJoustData(
            version,
            joustWins,
            joustLosses,
            joustTournamentWins,
            joustEloScore
        );

        eloStorage().unicornRecord[_tokenId] = _unicornRecord;
        emit UnicornRecordChanged(_tokenId, _oldUnicornRecord, _unicornRecord);
    }

    /// @notice Set unicorn record for the token in jousting system
    /// @dev The external function can be called only by oracle or contract owner.
    /// @param _tokenId - Unique id of the token
    /// @param _joustWins - Joust matches won
    /// @param _joustLosses - Joust matches lost
    /// @param _joustTournamentWins - Joust tournament won
    /// @param _joustEloScore - Joust elo score
    /// @custom:emits UnicornRecordChanged
    function _setJoustRecord(
        uint256 _tokenId,
        uint256 _joustWins,
        uint256 _joustLosses,
        uint256 _joustTournamentWins,
        uint256 _joustEloScore
    ) internal {
        require(
            LibDiamond.diamondStorage().erc721_owners[_tokenId] != address(0),
            "LibElo: TokenID does not have owner"
        );

        uint256 _oldUnicornRecord = eloStorage().unicornRecord[_tokenId];

        uint256 _newUnicornRecord = _getEmbeddedJoustRecord(
            _tokenId,
            _getTargetUnicornVersion(),
            _joustWins,
            _joustLosses,
            _joustTournamentWins,
            _joustEloScore
        );

        eloStorage().unicornRecord[_tokenId] = _newUnicornRecord;
        emit UnicornRecordChanged(
            _tokenId,
            _oldUnicornRecord,
            _newUnicornRecord
        );
    }

    /// @notice Set version in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new version
    /// @param unicornRecord - unicorn record of token
    /// @param version - version to be set in unicorn record
    /// @return newUnicornRecord - unicorn record with version
    function _setVersion(
        uint256 unicornRecord,
        uint256 version
    ) internal view returns (uint256) {
        enforceValidVersion(version);
        return LibBin.splice(unicornRecord, version, DNA_VERSION_MASK);
    }

    /// @notice Set wins in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new wins
    /// @param unicornRecord - unicorn record of token
    /// @param joustWins - wins to be set in unicorn record
    /// @return unicornRecord - unicorn record with wins
    function _setJoustWins(
        uint256 unicornRecord,
        uint256 joustWins
    ) internal pure returns (uint256) {
        enforceMax20Bits(joustWins, "Joust Wins");
        return LibBin.splice(unicornRecord, joustWins, DNA_JOUSTWINS_MASK);
    }

    /// @notice Set losses in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new losses
    /// @param unicornRecord - unicorn record of token
    /// @param joustLosses - losses to be set in unicorn record
    /// @return unicornRecord - unicorn record with losses
    function _setJoustLosses(
        uint256 unicornRecord,
        uint256 joustLosses
    ) internal pure returns (uint256) {
        enforceMax20Bits(joustLosses, "Joust Losses");
        return LibBin.splice(unicornRecord, joustLosses, DNA_JOUSTLOSSES_MASK);
    }

    /// @notice Set joustTournamentWins in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new joustTournamentWins
    /// @param unicornRecord - unicorn record of token
    /// @param joustTournamentWins - joustTournamentWins to be set in unicorn record
    /// @return unicornRecord - unicorn record with joustTournamentWins
    function _setJoustTournamentWins(
        uint256 unicornRecord,
        uint256 joustTournamentWins
    ) internal pure returns (uint256) {
        enforceMax20Bits(joustTournamentWins, "Joust Tournament Wins");
        return
            LibBin.splice(
                unicornRecord,
                joustTournamentWins,
                DNA_JOUSTTOURNEYWINS_MASK
            );
    }

    /// @notice Set eloScore in unicorn record and returns new unicorn record
    /// @dev The internal function splices the previous unicorn record and the new eloScore
    /// @param unicornRecord - unicorn record of token
    /// @param eloScore - eloScore to be set in unicorn record
    /// @return unicornRecord - unicorn record with eloScore
    function _setJoustEloScore(
        uint256 unicornRecord,
        uint256 eloScore
    ) internal pure returns (uint256) {
        validateJoustEloScore(eloScore);
        return LibBin.splice(unicornRecord, eloScore, DNA_JOUSTELO_MASK);
    }

    /// @notice Set joust oracle address
    /// @dev The internal function validates address is not zero address
    /// @param _oracle - address of new oracle
    /// @custom:emits JoustOracleUpdated
    function _setJoustOracle(address _oracle) internal {
        address oldOracle = eloStorage().oracle;
        eloStorage().oracle = _oracle;
        emit JoustOracleUpdated(oldOracle, _oracle);
    }

    /// @notice Set target unicorn version for jousting system
    /// @dev The internal function validates the version number by checking against previous version and 8 bit value
    /// @param _versionNumber - New target unicorn version number
    /// @custom:emits TargetUnicornVersionUpdated
    function _setTargetUnicornVersion(uint8 _versionNumber) internal {
        uint8 _oldUnicornVersion = eloStorage().targetUnicornVersion;
        require(
            _versionNumber > _oldUnicornVersion,
            "LibElo: Unicorn version must be greater than previous value"
        );
        eloStorage().targetUnicornVersion = _versionNumber;
        emit TargetUnicornVersionUpdated(_oldUnicornVersion, _versionNumber);
    }

    /// @notice Embeds version, wins, losses, tournamentWins and eloScore in unicorn record and returns new unicorn record
    /// @dev This internal function validates version, joustWins, joustLosses, joustTournamentWins and joustEloScore
    /// @param version - Data version
    /// @param joustWins - Joust matches won
    /// @param joustLosses - Joust matches lost
    /// @param joustTournamentWins - Joust tournament won
    /// @param joustEloScore - Joust elo score
    /// @return unicornRecord - Embedded unicorn record with updated version, wins, losses, tournamentWins and eloScore
    function _getEmbeddedJoustRecord(
        uint256 tokenId,
        uint256 version,
        uint256 joustWins,
        uint256 joustLosses,
        uint256 joustTournamentWins,
        uint256 joustEloScore
    ) internal view returns (uint256) {
        uint256 unicornRecord = eloStorage().unicornRecord[tokenId];
        unicornRecord = _setVersion(unicornRecord, version);
        unicornRecord = _setJoustWins(unicornRecord, joustWins);
        unicornRecord = _setJoustLosses(unicornRecord, joustLosses);
        unicornRecord = _setJoustTournamentWins(
            unicornRecord,
            joustTournamentWins
        );
        unicornRecord = _setJoustEloScore(unicornRecord, joustEloScore);
        return unicornRecord;
    }

    /// @notice Get target unicorn version
    /// @dev The internal function returns the target unicorn version
    /// @return targetUnicornVersion - Target unicorn version for jousting system
    function _getTargetUnicornVersion() internal view returns (uint256) {
        return eloStorage().targetUnicornVersion;
    }

    /// @notice Get and return version from the unicorn record
    /// @dev The internal function extracts version from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return version - Version from unicorn record
    function _getVersion(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_VERSION_MASK);
    }

    /// @notice Get and return wins from the unicorn record
    /// @dev The internal function extracts wins from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return wins - Wins from unicorn record
    function _getJoustWins(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_JOUSTWINS_MASK);
    }

    /// @notice Get and return losses from the unicorn record
    /// @dev The internal function extracts losses from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return losses - Losses from unicorn record
    function _getJoustLosses(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_JOUSTLOSSES_MASK);
    }

    /// @notice Get and return tourneyWins from the unicorn record
    /// @dev The internal function extracts tourneyWins from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return tourneyWins - Tournament Wins from unicorn record
    function _getJoustTournamentWins(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_JOUSTTOURNEYWINS_MASK);
    }

    /// @notice Get and return eloScore from the unicorn record
    /// @dev The internal function extracts eloScore from the unicorn record
    /// @param _unicornRecord - Elo data of token
    /// @return eloScore - Elo Score from unicorn record
    function _getJoustEloScore(
        uint256 _unicornRecord
    ) internal pure returns (uint256) {
        return LibBin.extract(_unicornRecord, DNA_JOUSTELO_MASK);
    }

    /// @notice Get Joust Record for the tokenId
    /// @dev The internal function ensures eloScore is 1000 when version is 0, and returns joustEloScore, joustWins, joustLosses, and joustTournamentWins
    /// @param _tokenId - Unique id of the token
    /// @return version - version for tokenId
    /// @return matchesWon - joustWins for tokenId
    /// @return matchesLost - joustLosses for tokenId
    /// @return tournamentsWon - joustTournamentWins for tokenId
    /// @return eloScore - eloScore for tokenId
    function _getJoustRecord(
        uint256 _tokenId
    )
        internal
        view
        returns (
            uint256 version,
            uint256 matchesWon,
            uint256 matchesLost,
            uint256 tournamentsWon,
            uint256 eloScore
        )
    {
        uint256 _unicornRecord = _getRawUnicornRecord(_tokenId);
        uint256 _eloScore = _getJoustEloScore(_unicornRecord);
        if (_getVersion(_unicornRecord) == 0) {
            _eloScore = 1000;
        }

        return (
            _getVersion(_unicornRecord),
            _getJoustWins(_unicornRecord),
            _getJoustLosses(_unicornRecord),
            _getJoustTournamentWins(_unicornRecord),
            _eloScore
        );
    }

    /// @notice Get raw unicorn record for the tokenId
    /// @dev This function ensures eloScore is 1000 when version is 0, and returns unicorn record
    /// @param _tokenId - Unique id of the token
    /// @return unicornRecord - raw unicorn record for tokenId
    function _getRawUnicornRecord(
        uint256 _tokenId
    ) internal view returns (uint256) {
        if (_getVersion(eloStorage().unicornRecord[_tokenId]) != 0) {
            return eloStorage().unicornRecord[_tokenId];
        } else {
            uint256 eloScore = 1000;
            uint256 unicornRecord = eloStorage().unicornRecord[_tokenId];
            uint256 newUnicornRecord = _setVersion(
                _setJoustEloScore(unicornRecord, eloScore),
                _getTargetUnicornVersion()
            );
            return newUnicornRecord;
        }
    }

    /// @notice Enforce joust data is valid by checking each parameter
    function validateJoustData(
        uint256 version,
        uint256 joustWins,
        uint256 joustLosses,
        uint256 joustTournamentWins,
        uint256 joustEloScore
    ) internal view {
        enforceValidVersion(version);
        enforceMax20Bits(joustWins, "Joust Wins");
        enforceMax20Bits(joustLosses, "Joust Losses");
        enforceMax20Bits(joustTournamentWins, "Joust Tournament Wins");
        validateJoustEloScore(joustEloScore);
    }

    /// @notice Enforce joust data is less than max value of 20 bits
    function enforceMax20Bits(
        uint256 joustData,
        string memory message
    ) internal pure {
        string memory errorMessage = string(
            abi.encodePacked("LibElo: ", message, " should be below 1048576")
        );
        require(joustData < MAX_VALUE_20_BITS, errorMessage);
    }

    /// @notice Validate joust elo score is between 1 and 16000
    function validateJoustEloScore(uint256 joustEloScore) internal pure {
        require(
            joustEloScore <= 16000 && joustEloScore >= 1,
            "LibElo: Joust Elo Score should be within [1, 16000]"
        );
    }

    /// @notice Enforce caller is either oracle or contract owner
    function enforceIsOwnerOrOracle() internal view {
        require(
            msg.sender == eloStorage().oracle ||
                msg.sender == LibDiamond.diamondStorage().contractOwner,
            "LibElo: Must be Owner or Oracle address"
        );
    }

    /// @notice Enforce unicorn version is target unicorn version
    function enforceValidVersion(uint256 version) internal view {
        require(
            version == _getTargetUnicornVersion(),
            "LibElo: Invalid unicorn version"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library LibCheck {
    function enforceValidString(string memory str) internal pure {
        require(bytes(str).length > 0, "LibCheck: String cannot be empty");
    }

    function enforceValidAddress(address addr) internal pure {
        require(
            addr != address(0),
            "LibCheck: Address cannnot be zero address"
        );
    }

    function enforceValidArray(uint256[] memory array) internal pure {
        require(array.length > 0, "LibCheck: Array cannot be empty");
    }

    function enforceEqualArrayLength(
        uint256[] memory array1,
        uint256[] memory array2
    ) internal pure {
        enforceValidArray(array1);
        enforceValidArray(array2);
        require(
            array1.length == array2.length,
            "LibCheck: Array must be equal length"
        );
    }
}