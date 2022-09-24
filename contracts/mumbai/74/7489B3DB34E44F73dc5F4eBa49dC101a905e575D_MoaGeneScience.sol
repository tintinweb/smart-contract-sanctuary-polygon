pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "./IMoaGeneScience.sol";

/// @title GeneScience implements the trait calculation for new MoA
/// @author
contract MoaGeneScience is IMoaGeneScience {
    // event Debug(uint256 number);

    uint256 internal constant maskLast8Bits = uint256(0xff);
    uint256 internal constant maskFirst248Bits = ~uint256(0xff);

    /// @dev tmp storage of grand parents species trait
    struct GrandParentTraits {
        uint256 coreGrandfather;
        uint256 coreGrandmother;
        uint256 supportGrandfather;
        uint256 supportGrandmother;
    }

    /// @dev for iterating on body parts
    struct BodyPartOffset {
        uint256 variationOffsets;
        uint256 randomNoffset;
    }

    function GeneScience() public {}

    function isGeneScience() public pure override returns (bool) {
        return true;
    }

    /// @dev given a number get a slice of any bits, at certain offset
    /// @param _n a number to be sliced
    /// @param _nbits how many bits long is the new number
    /// @param _offset how many bits to skip
    function _sliceNumber(
        uint256 _n,
        uint256 _nbits,
        uint256 _offset
    ) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 shiftBits = 256 - _nbits - _offset;
        uint256 mask = uint256((2**_nbits) - 1);
        return uint256((_n >> shiftBits) & mask);
    }

    /// @dev append the traits into genes
    /// @param _genes genes before append
    /// @param _nbits max bits size of the traits
    /// @param _traits traits to append
    function _genesShifter(
        uint256 _genes,
        uint256 _nbits,
        uint256 _traits
    ) internal pure returns (uint256) {
        _genes = _genes << _nbits;
        _genes = _genes | _traits;
        return _genes;
    }

    /// @dev Rainbow trait basic possibilites is approx. 1%,
    /// if each parent is also Rainbow, add ~0.5% chance
    /// @param coreIsRainbowTrait trait for Core MoA, 1bits
    /// @param supportIsRainbowTrait trait for Supporting MoA, 1bits
    /// @param rand random number, 10bits (0-1023)
    function _isRainbowToss(
        uint256 coreIsRainbowTrait,
        uint256 supportIsRainbowTrait,
        uint256 rand
    ) internal pure returns (uint256) {
        uint256 chance = 10;
        if (coreIsRainbowTrait == 1) {
            chance += 5;
        }
        if (supportIsRainbowTrait == 1) {
            chance += 5;
        }
        return (rand < chance) ? 1 : 0;
    }

    /// @dev Color trait tossing
    /// approx. 30% of possibilities will directly inherit the color from either core or support, ~15% each
    /// approx. 70% of possibilities will allocate a random color, each color of 11 will be ~6.5%
    /// @param coreColorTrait trait for Core MoA , 4bits uint
    /// @param supportColorTrait trait for Supporting MoA, 4bits uint
    /// @param rand random number, 10bits (0-1023)
    function _colorToss(
        uint256 coreColorTrait,
        uint256 supportColorTrait,
        uint256 rand
    ) internal pure returns (uint256) {
        if (rand < 153) {
            return coreColorTrait;
        } else if (rand < 306) {
            return supportColorTrait;
        } else {
            return rand % 11;
        }
    }

    /// @dev Variation Trait - 10bits randomN will be used
    /// approx. 15% of possibilities will inherit the variation from core parent variation
    /// approx. 15% of possibilities will inherit the variation from support parent variation
    /// approx. 10% of possibilities will get variation 0 , p.s. variation 0 is the original, it preserves a special rarity.
    /// approx. 60% of possibilities will get variation 1-3 in equal chances
    /// @param rand random number, 10bits (0-1023)
    function _variationToss(
        uint256 coreVariationTrait,
        uint256 supportVariationTrait,
        uint256 rand
    ) internal pure returns (uint256) {
        if (rand < 153) {
            // ~15% inherit from Core MoA
            return coreVariationTrait;
        } else if (rand < 306) {
            // ~15% inherit from Supporting MoA
            return supportVariationTrait;
        } else if (rand < 408) {
            // ~10% that gives original (i.e. 0)
            return 0;
        } else {
            // return trait 1-3
            return (rand % 3) + 1;
        }
    }

    /// @dev Species Trait - 6bits randomN will be used
    /// approx. 3% will trigger to inherit grandparent species on certain part
    /// else, equal chances to inherit from Core or Supporting MoA
    /// @param rand 10bits of random
    function _speciesToss(
        uint256 coreSpeciesTrait,
        uint256 supportSpeciesTrait,
        uint256 coreGrandmotherTrait,
        uint256 coreGrandfatherTrait,
        uint256 supportGrandmotherTrait,
        uint256 supportGrandfatherTrait,
        uint256 rand
    ) internal pure returns (uint256 speciesTrait) {
        if (rand < 32) {
            // ~3%
            uint256 inhert = rand % 4;
            if (inhert == 0) {
                return coreGrandmotherTrait;
            } else if (inhert == 1) {
                return coreGrandfatherTrait;
            } else if (inhert == 2) {
                return supportGrandmotherTrait;
            }
            return supportGrandfatherTrait;
        }
        // for the rest, equal chances to inherit from Core / Supporting MoA
        return (rand % 2 == 0) ? coreSpeciesTrait : supportSpeciesTrait;
    }

    function _bodyPartIterator(
        uint256 _genes1,
        uint256 _genes2,
        uint256 randomN,
        uint256 _genes
    ) internal pure returns (uint256) {
        BodyPartOffset memory _bodyPartOffset;
        _bodyPartOffset.variationOffsets = 6; // bit offset on body parts of genes, 4 + 12 bits for each body parts
        _bodyPartOffset.randomNoffset = 21; // bits already used in the randomN

        GrandParentTraits memory _grandParentTraits;
        _grandParentTraits.coreGrandfather = _sliceNumber(_genes1, 12, 134); // species of grand-parents of Core side, Core
        _grandParentTraits.coreGrandmother = _sliceNumber(_genes1, 12, 146); // species of grand-parents of Core side, Supporting
        _grandParentTraits.supportGrandfather = _sliceNumber(_genes2, 12, 134); // species of grand-parents of Supporting side, Core
        _grandParentTraits.supportGrandmother = _sliceNumber(_genes2, 12, 146); // species of grand-parents of Supporting side, Supporting

        for (uint256 j = 0; j < 8; j++) {
            uint256 variationTrait = _variationToss(
                uint256(
                    _sliceNumber(_genes1, 4, _bodyPartOffset.variationOffsets)
                ), // variation trait of the Core MoA
                uint256(
                    _sliceNumber(_genes2, 4, _bodyPartOffset.variationOffsets)
                ), // variation trait of the Supporing MoA
                _sliceNumber(randomN, 10, _bodyPartOffset.randomNoffset) // 10bits of random for variation
            );
            _genes = _genesShifter(_genes, 4, variationTrait);

            uint256 speciesTrait = _speciesToss(
                uint256(
                    _sliceNumber(
                        _genes1,
                        12,
                        _bodyPartOffset.variationOffsets + 4
                    )
                ), // species trait of the Core MoA (of this body part)
                uint256(
                    _sliceNumber(
                        _genes2,
                        12,
                        _bodyPartOffset.variationOffsets + 4
                    )
                ), // species trait of the Supporting MoA (of this body part)
                _grandParentTraits.coreGrandmother,
                _grandParentTraits.coreGrandfather,
                _grandParentTraits.supportGrandmother,
                _grandParentTraits.supportGrandfather,
                _sliceNumber(randomN, 10, _bodyPartOffset.randomNoffset + 10) // 6bits of random for species
            );

            _genes = _genesShifter(_genes, 12, speciesTrait);

            _bodyPartOffset.variationOffsets += 16;
            _bodyPartOffset.randomNoffset += 20;
        }

        return _genes;
    }

    function mixGenes(
        uint256 _genes1,
        uint256 _genes2,
        uint256 _targetBlock
    ) public view override returns (uint256) {
        return _mixGenes(_genes1, _genes2, _targetBlock, uint160(address(this)));
    }

    function mixGenes(
        uint256 _genes1,
        uint256 _genes2,
        uint256 _targetBlock,
        uint256 _seed
    ) public view override returns (uint256) {
        return _mixGenes(_genes1, _genes2, _targetBlock, _seed);
    }

    /// @dev return a new genes by mixing two genes
    function _mixGenes(
        uint256 _genes1,
        uint256 _genes2,
        uint256 _targetBlock,
        uint256 _seed
    ) internal view returns (uint256) {
        require(block.number > _targetBlock, "Invalid target block");

        // Try to grab the hash of the "target block". This should be available the vast
        // majority of the time (it will only fail if no-one calls giveBirth() within 256
        // blocks of the target block, which is about 40 minutes. Since anyone can call
        // giveBirth() and they are rewarded with ether if it succeeds, this is quite unlikely.)
        uint256 randomN = uint256(blockhash(_targetBlock));

        if (randomN == 0) {
            // We don't want to completely bail if the target block is no-longer available,
            // nor do we want to just use the current block's hash (since it could allow a
            // caller to game the random result). Compute the most recent block that has the
            // the same value modulo 256 as the target block. The hash for this block will
            // still be available, and – while it can still change as time passes – it will
            // only change every 40 minutes. Again, someone is very likely to jump in with
            // the giveBirth() call before it can cycle too many times.
            _targetBlock =
                (block.number & maskFirst248Bits) +
                (_targetBlock & maskLast8Bits);

            // The computation above could result in a block LARGER than the current block,
            // if so, subtract 256.
            if (_targetBlock >= block.number) _targetBlock -= 256;

            randomN = uint256(blockhash(_targetBlock));

            // DEBUG ONLY
            // assert(block.number != _targetBlock);
            // assert((block.number - _targetBlock) <= 256);
            // assert(randomN != 0);
        }

        // generate 256 bits of random, using as much entropy as we can from
        // sources that can't change between calls.
        randomN = uint256(
            keccak256(
                abi.encode(randomN, _genes1, _genes2, _targetBlock, _seed)
            )
        );

        uint256 _genes = 0; // Initialize child genes

        // Rainbow - 1 bit
        uint256 isRainbowTrait = _isRainbowToss(
            uint256(_sliceNumber(_genes1, 1, 0)), // Core MoA rainbow trait bit
            uint256(_sliceNumber(_genes2, 1, 0)), // Supporing MoA rainbow trait bit
            uint256(_sliceNumber(randomN, 10, 0)) // 10bits of random
        );
        _genes = _genesShifter(_genes, 1, isRainbowTrait);

        // Color - 4 bits
        uint256 colorTrait = _colorToss(
            uint256(_sliceNumber(_genes1, 4, 1)), // Core MoA color Trait
            uint256(_sliceNumber(_genes2, 4, 1)), // Supporting MoA color Trait
            uint256(_sliceNumber(randomN, 10, 10)) // 10bits of random
        );
        _genes = _genesShifter(_genes, 4, colorTrait);

        // Gender - 1 bit
        _genes = _genesShifter(
            _genes,
            1,
            uint256(_sliceNumber(randomN, 1, 20))
        ); // 1bit of random for gender, do not depends on parents

        // Body Parts - 128 bits
        _genes = _bodyPartIterator(_genes1, _genes2, randomN, _genes);

        // Parent species - 24 bits
        _genes = _genesShifter(_genes, 12, _sliceNumber(_genes1, 12, 10)); // record Core MoA's species
        _genes = _genesShifter(_genes, 12, _sliceNumber(_genes2, 12, 10)); // record Support MoA's species

        // Reserved for Accessories - 80 bits
        _genes = _genesShifter(_genes, 80, 0);
        // Fill up last 18bits
        _genes = _genesShifter(_genes, 18, 0);

        return uint256(_genes);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title defined the interface that will be referenced in main MoA contract
interface IMoaGeneScience {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isGeneScience() external pure returns (bool);

    /// @dev given genes of MoA 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of sire
    /// @param _targetBlock target block
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(
        uint256 genes1,
        uint256 genes2,
        uint256 _targetBlock
    ) external view returns (uint256);

    /// @dev given genes of MoA 1 & 2, return a genetic combination - may have a random factor
    /// @param genes1 genes of mom
    /// @param genes2 genes of sire
    /// @param _targetBlock target block
    /// @param _seed extra seed values, useful for mintGen1
    /// @return the genes that are supposed to be passed down the child
    function mixGenes(
        uint256 genes1,
        uint256 genes2,
        uint256 _targetBlock,
        uint256 _seed
    ) external view returns (uint256);
}