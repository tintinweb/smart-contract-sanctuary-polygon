// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GeneScience
{
     bool public isGeneScience = true;
    /// @dev given a number get a slice of any bits, at certain offset
    /// @param _n a number to be sliced
    /// @param _nbits how many bits long is the new number
    /// @param _offset how many bits to skip
    function sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        // AND n with mask, and trim to max of _nbits bits
        return uint256((_n & mask) >> _offset);
    }

    /// @dev Get a 4 bit slice from an input as a number
    /// @param _input bits, encoded as uint
    /// @param _slot from 0 to 11
    function get4Bits(uint256 _input, uint256 _slot) internal pure returns(uint8) {
        return uint8(sliceNumber(_input, uint256(4), _slot * 4));
    }

    function decode(uint256 _genes) public pure returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](12);
        uint256 i;
        for(i = 0; i < 12; i++) {
            traits[i] = get4Bits(_genes, i);
        }
        return traits;
    }

    /// @dev Given an array of traits return the number that represent genes
    function encode(uint8[] memory _traits) public pure returns (uint256 _genes) {
        _genes = 0;
        for(uint256 i = 0; i < 12; i++) {
            _genes = _genes << 4;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[11 - i];
        }
        return _genes;
    }

    /// @dev return the expressing traits
    /// @param _genes the long number expressing cat genes
    function expressingTraits(uint256 _genes) public pure returns(uint8[3] memory) {
        uint8[3] memory express;
        for(uint256 i = 0; i < 3; i++) {
            express[i] = get4Bits(_genes, i * 4);
        }
        return express;
    }

    function ascend(uint8 trait1, uint8 trait2, uint256 rand) internal pure returns(uint8 ascension) {
        ascension = 0;

        uint8 smallT = trait1;
        uint8 bigT = trait2;

        if (smallT > bigT) {
            bigT = trait1;
            smallT = trait2;
        }

        if ((bigT - smallT == 1) && smallT % 2 == 0) {

            // The rand argument is expected to be a random number 0-7.
            // rare trait: 1/4 chance (rand is 0 or 1)
            // common trait: 1/8 chance (rand is 0)

            uint256 maxRand;
            if (smallT < 10) maxRand = 1;
            else maxRand = 0;

            if (rand <= maxRand ) {
                ascension = (smallT / 2) + 8;
            }
        }
    }

    function createGene() public view returns(uint256)
    {
        uint256 randomN = uint256(blockhash(block.number - 1));
        randomN = uint256(keccak256(abi.encodePacked(randomN, msg.sender)));
        uint256 randomIndex = 0;
        uint8[] memory geneArray = new uint8[](12);
        uint256 traitPos;

        for(uint256 i = 0; i < 3; i++) {
            // pick 4 traits for characteristic i
            uint256 j;
            // store the current random value
            uint256 rand;
            for(j = 3; j >= 1; j--) {
                traitPos = (i * 4) + j;
                rand = sliceNumber(randomN, 3, randomIndex) + 1; // 1~8
                randomIndex += 4;
                geneArray[traitPos] = uint8(rand);
            }
        }
        return encode(geneArray);
    }

    /// @dev the function as defined in the breeding contract
    function mixGenes(uint256 _genes1, uint256 _genes2, uint256 _coolDownEndTime) public view returns (uint256) {

        uint256 randomN = uint256(blockhash(block.number - 1));
        randomN = uint256(keccak256(abi.encodePacked(randomN, _genes1, _genes2, _coolDownEndTime)));
        uint256 randomIndex = 0;

        uint8[] memory genes1Array = decode(_genes1);
        uint8[] memory genes2Array = decode(_genes2);
        // All traits that will belong to baby
        uint8[] memory babyArray = new uint8[](12);
        // A pointer to the trait we are dealing with currently
        uint256 traitPos;
        // Trait swap value holder
        uint8 swap;
        uint256 rand;
        // iterate all 3 characteristics
        for(uint256 i = 0; i < 3; i++) {
            // pick 4 traits for characteristic i
            uint256 j;
            // store the current random value
            
            for(j = 3; j >= 1; j--) {
                traitPos = (i * 4) + j;

                rand = sliceNumber(randomN, 2, randomIndex); // 0~3
                randomIndex += 2;

                // 1/4 of a chance of gene swapping forward towards expressing.
                if (rand == 0) {
                    // do it for parent 1
                    swap = genes1Array[traitPos];
                    genes1Array[traitPos] = genes1Array[traitPos - 1];
                    genes1Array[traitPos - 1] = swap;

                }

                rand = sliceNumber(randomN, 2, randomIndex); // 0~3
                randomIndex += 2;

                if (rand == 0) {
                    // do it for parent 2
                    swap = genes2Array[traitPos];
                    genes2Array[traitPos] = genes2Array[traitPos - 1];
                    genes2Array[traitPos - 1] = swap;
                }
            }

        }


        for(traitPos = 0; traitPos < 12; traitPos++) {

            // See if this trait pair should ascend
            uint8 ascendedTrait = 0;

            // There are two checks here. The first is straightforward, only the trait
            // in the first slot can ascend. The first slot is zero mod 4.
            //
            // The second check is more subtle: Only values that are one apart can ascend,
            // which is what we check inside the _ascend method. However, this simple mask
            // and compare is very cheap (9 gas) and will filter out about half of the
            // non-ascending pairs without a function call.
            //
            // The comparison itself just checks that one value is even, and the other
            // is odd.
            if ((traitPos % 4 == 0) && (genes1Array[traitPos] & 1) != (genes2Array[traitPos] & 1)) {
                rand = sliceNumber(randomN, 3, randomIndex);
                randomIndex += 3;

                ascendedTrait = ascend(genes1Array[traitPos], genes2Array[traitPos], rand);
            }

            if (ascendedTrait > 0) {
                babyArray[traitPos] = uint8(ascendedTrait);
            } else {
                // did not ascend, pick one of the parent's traits for the baby
                // We use the top bit of rand for this (the bottom three bits were used
                // to check for the ascension itself).
                rand = sliceNumber(randomN, 1, randomIndex);
                randomIndex += 1;

                if (rand == 0) {
                    babyArray[traitPos] = uint8(genes1Array[traitPos]);
                } else {
                    babyArray[traitPos] = uint8(genes2Array[traitPos]);
                }
            }
        }

        return encode(babyArray);
    }
}