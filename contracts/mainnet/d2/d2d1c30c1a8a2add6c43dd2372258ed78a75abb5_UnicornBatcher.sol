/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//  Polygon : 0xD2D1C30c1a8a2add6C43Dd2372258Ed78a75aBB5
//  Mumbai: 0x4bb1eD5b066b89050840e6Ff98D43B2F9294480d

interface IUnicorn {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getDNA(uint256 _tokenId) external view returns (uint256);
    function getUnicornName(uint256 _tokenId) external view returns (string memory);
    function getIdempotentState(uint256 _tokenId) external view returns (uint256);
    function getUnicornParents(uint256 tokenId) external view returns (uint256, uint256);
    function getAttack(uint256 _dna) external view returns (uint256);
    function getAccuracy(uint256 _dna) external view returns (uint256);
    function getMovementSpeed(uint256 _dna) external view returns (uint256);
    function getAttackSpeed(uint256 _dna) external view returns (uint256);
    function getDefense(uint256 _dna) external view returns (uint256);
    function getVitality(uint256 _dna) external view returns (uint256);
    function getResistance(uint256 _dna) external view returns (uint256);
    function getMagic(uint256 _dna) external view returns (uint256);
    function getPowerScore(uint256 tokenId) external view returns (uint256);
    function getSpeedScore(uint256 tokenId) external view returns (uint256);
    function getEnduranceScore(uint256 tokenId) external view returns (uint256);
    function getIntelligenceScore(uint256 tokenId) external view returns (uint256);
    function unicornIsTransferable(uint256 tokenId) external view returns (bool);
    function unicornIsCoolingDown(uint256 tokenId) external view returns (bool);
    function unicornLastForceUnlock(uint256 tokenId) external view returns (uint256);
    function getBaseStats(uint256 _classId, uint256 _statId) external view returns (uint256);

    function getUnicornMetadata(uint256 _tokenId) external view returns (
        bool origin,
        bool gameLocked,
        bool limitedEdition,
        uint256 lifecycleStage,
        uint256 breedingPoints,
        uint256 unicornClass,
        uint256 hatchBirthday
    );

    function getUnicornBodyParts(uint256 _dna) external view returns (
        uint256 bodyPartId,
        uint256 facePartId,
        uint256 hornPartId,
        uint256 hoovesPartId,
        uint256 manePartId,
        uint256 tailPartId,
        uint8 mythicCount
    );

    function getStats(uint256 _dna) external view returns (
        uint256 attack,
        uint256 accuracy,
        uint256 movementSpeed,
        uint256 attackSpeed,
        uint256 defense,
        uint256 vitality,
        uint256 resistance,
        uint256 magic
    );
    
    function getUnicornsByOwner(address _owner, uint32 _pageNumber) external view returns (
        uint256[] memory tokenIds,
        uint16[] memory classes,
        string[] memory names,
        bool[] memory gameLocked,
        bool moreEntriesExist
    );
}

contract UnicornBatcher {
    address constant UNICORN = 0xdC0479CC5BbA033B3e7De9F178607150B3AbCe1f;

    function getTokenURIs(uint256[] calldata _ids) external view returns (string[] memory) {
        string[] memory uris = new string[](_ids.length);
        for(uint i = 0; i < _ids.length; ++i) {
            uris[i] = IUnicorn(UNICORN).tokenURI(_ids[i]);
        }
        return uris;
    }

    function getDNAs(uint256[] calldata _ids) external view returns (uint256[] memory) {
        uint256[] memory dnas = new uint256[](_ids.length);
        for(uint i = 0; i < _ids.length; ++i) {
            dnas[i] = IUnicorn(UNICORN).getDNA(_ids[i]);
        }
        return dnas;
    }

    function getUnicornNames(uint256[] calldata _ids) external view returns (string[] memory) {
        string[] memory names = new string[](_ids.length);
        for(uint i = 0; i < _ids.length; ++i) {
            names[i] = IUnicorn(UNICORN).getUnicornName(_ids[i]);
        }
        return names;
    }

    function getIdempotences(uint256[] calldata _ids) external view returns (uint256[] memory) {
        uint256[] memory idmp = new uint256[](_ids.length);
        for(uint i = 0; i < _ids.length; ++i) {
            idmp[i] = IUnicorn(UNICORN).getIdempotentState(_ids[i]);
        }
        return idmp;
    }

    struct AgeAndState { uint256 age; uint256 idmp; }
    uint256 internal constant DNA_LIFECYCLESTAGE_MASK = 0x1800;
    function getIdempotenceAndAge(uint256[] calldata _ids) external view returns (AgeAndState[] memory) {
        AgeAndState[] memory aas = new AgeAndState[](_ids.length);
        for(uint i = 0; i < _ids.length; ++i) {
            uint256 dna = IUnicorn(UNICORN).getDNA(_ids[i]);
            uint256 age = extract(dna, DNA_LIFECYCLESTAGE_MASK);
            aas[i] = AgeAndState(
                age,
                IUnicorn(UNICORN).getIdempotentState(_ids[i])
            );
        }
        return aas;
    }

    struct Parents { uint256 a; uint256 b; }
    function getParents(uint256[] calldata _ids) external view returns (Parents[] memory) {
        Parents[] memory p = new Parents[](_ids.length);
        for(uint i = 0; i < _ids.length; ++i) {
            uint256 a;
            uint256 b;
            (a, b) = IUnicorn(UNICORN).getUnicornParents(_ids[i]);
            p[i] = Parents(a, b);
        }
        return p;
    }

    // Using the mask, determine how many bits we need to shift to extract the desired value
    //  @param _mask A bitstring with right-padding zeroes
    //  @return The number of right-padding zeroes on the _mask
    function _getShiftAmount(uint256 _mask) private pure returns (uint256) {
        uint256 count = 0;
        while (_mask & 0x1 == 0) {
            _mask >>= 1;
            ++count;
        }
        return count;
    }

    //  Retrieves a segment from the _bitArray bitstring
    //  @param _bitArray The dna to parse
    //  @param _mask The location in teh _bitArray to isolate
    //  @return The data from _bitArray that was isolated in the _mask (no right-padding zeroes)
    function extract(uint256 _bitArray, uint256 _mask)
        private
        pure
        returns (uint256)
    {
        uint256 offset = _getShiftAmount(_mask);
        return (_bitArray & _mask) >> offset;
    }

}