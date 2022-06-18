//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./abstract/HorseProperty.sol";
import "./interfaces/IDerbyStarsData.sol";

contract BreedingCalculator {
    enum FeeType {
        RARITY,
        RANK,
        SPECIAL,
        SKILL
    }

    enum StatType {
        SPEED,
        STAMINA,
        POWER,
        GRIT,
        INTELLECT
    }

    enum BodyPartTypes {
        TORSO,
        EYES,
        MANE,
        HORN,
        LEGS,
        MUZZLE,
        TAIL,
        WINGS,
        REIN
    }

    struct Distribution {
        uint16 range0;
        uint16 range1;
        uint16 range2;
        uint16 range3;
        uint16 range4;
        uint16 range5;
        uint16 range6;
    }

    struct Skill {
        uint256 id;
        uint256 tier;
    }

    struct Color {
        uint8 group;
        uint16 id;
    }

    struct Stat {
        StatType statType;
        uint256 parentSum;
        uint256 newValue;
    }

    struct BodyPartPair {
        BodyPartTypes bodyPartType;
        uint8 weight;
        uint8 chosen;
    }

    // Packing to avoid stack too deep error
    struct MutantSkill {
        uint8 index1;
        uint8 index2;
        uint8 count;
    }

    function calculateBreedingFee(
        Properties memory father,
        IDerbyStarsData dsData
    ) public view returns (uint256) {
        uint256 fee = 130 * 1e18;
        uint256 add_fee = 0;
        {
            uint256 rarity = father.dtrait.rarity;
            add_fee += dsData.getBreedingFee(uint256(FeeType.RARITY), rarity);
        }
        {
            add_fee += dsData.getBreedingFee(uint256(FeeType.RANK), father.dtrait.talent_rr);
            add_fee += dsData.getBreedingFee(uint256(FeeType.RANK), father.dtrait.talent_fr);
            add_fee += dsData.getBreedingFee(uint256(FeeType.RANK), father.dtrait.talent_st);
            add_fee += dsData.getBreedingFee(uint256(FeeType.RANK), father.dtrait.talent_sr);
        }
        {
            uint256 special_rank = dsData.getSpecialSkillTier(father.dtrait.skill1);
            add_fee += dsData.getBreedingFee(uint256(FeeType.SPECIAL), special_rank);
        }
        {
            uint256 skill_rank_sum = dsData.getNormalSkillTier(father.dtrait.skill2)
                + dsData.getNormalSkillTier(father.dtrait.skill3)
                + dsData.getNormalSkillTier(father.dtrait.skill4)
                + dsData.getNormalSkillTier(father.dtrait.skill5)
                + dsData.getNormalSkillTier(father.dtrait.skill6);
            // XXX : integer division
            add_fee += dsData.getBreedingFee(uint256(FeeType.SKILL), skill_rank_sum / 5);
        }
        if (father.breed_count_father == 0) {
            return fee + add_fee * 1e18;
        } else {
            //(기본 보상금 * (교배 횟수 * 교배 횟수 가중치) * 교배 횟수) 
            uint256 lhs = fee * (father.breed_count_father * 10 / 3) * father.breed_count_father;
            //(추가 비용 합산 + (추가 비용 합산 * (교배 횟수 * 교배 횟수 가중치) * 교배 횟수)
            add_fee = add_fee * 1e18;
            uint256 rhs = add_fee + (add_fee * (father.breed_count_father * 10 / 3) * father.breed_count_father);
            return fee + lhs + rhs;
        }
    }

    function calculateProperties(
        Properties memory mother,
        Properties memory father,
        bytes32 randomSeed,
        IDerbyStarsData dsData
    ) public view returns (Properties memory properties) {
        uint256 nonce = 0;
        bool rare = calculateRareness(
            mother.dtrait.rarity + father.dtrait.rarity,
            randomSeed,
            nonce
        );
        nonce += 1;
        console.log("rare: ", rare);

        if (rare) {
            nonce = calculateAndUpdateRarity(
                properties,
                mother.dtrait.rarity + father.dtrait.rarity, 
                randomSeed,
                nonce
            );

            nonce = calculateAndUpdateRareBodyParts(
                properties,
                properties.dtrait.rarity,
                randomSeed,
                nonce,
                dsData
            );
        }

        nonce = calculateAndUpdateCommonBodyParts(mother, father, properties, randomSeed, nonce, dsData);
        nonce = calculateAndUpdateTalents(mother, father, properties, randomSeed, nonce);
        nonce = calculateAndUpdateStats(mother, father, properties, randomSeed, nonce);
        nonce = calculateAndUpdateSkills(mother, father, properties, randomSeed, nonce, dsData);
        nonce = calculateAndUpdateTrackPref(mother, father, properties, randomSeed, nonce);
        nonce = calculateAndUpdateColor(mother, father, properties, randomSeed, nonce, dsData);

        return properties;
    }

    function calculateRareness(uint256 combinedRarity, bytes32 randomSeed, uint256 nonce) internal view returns (bool) {
        bool rare = false;
        uint256 rn = getRN(randomSeed, nonce);
        if (combinedRarity == 0) {
            if (rn % 100 < 3) rare = true;
        } else if (combinedRarity == 1) {
            if (rn % 10000 < 315) rare = true;
        } else if (combinedRarity == 2) {
            if (rn % 1000 < 33) rare = true;
        } else if (combinedRarity == 3) {
            if (rn % 10000 < 345) rare = true;
        } else if (combinedRarity == 4) {
            if (rn % 1000 < 36) rare = true;
        } else if (combinedRarity == 5) {
            if (rn % 10000 < 375) rare = true;
        } else if (combinedRarity == 6) {
            if (rn % 1000 < 39) rare = true;
        } else if (combinedRarity == 7) {
            if (rn % 10000 < 405) rare = true;
        } else if (combinedRarity == 8) {
            if (rn % 1000 < 42) rare = true;
        } else if (combinedRarity == 9) {
            if (rn % 10000 < 435) rare = true;
        } else if (combinedRarity == 10) {
            if (rn % 1000 < 45) rare = true;
        } else if (combinedRarity == 11) {
            if (rn % 10000 < 465) rare = true;
        } else if (combinedRarity == 12) {
            if (rn % 1000 < 48) rare = true;
        } else if (combinedRarity == 13) {
            if (rn % 10000 < 495) rare = true;
        } else if (combinedRarity == 14) {
            if (rn % 1000 < 51) rare = true;
        } else if (combinedRarity == 15) {
            if (rn % 10000 < 525) rare = true;
        } else if (combinedRarity == 16) {
            if (rn % 1000 < 54) rare = true;
        } else if (combinedRarity == 17) {
            if (rn % 10000 < 555) rare = true;
        } else if (combinedRarity == 18) {
            if (rn % 1000 < 57) rare = true;
        }
        return rare;
    }

    function calculateAndUpdateRarity(Properties memory properties, uint256 combinedRarity, bytes32 randomSeed, uint256 nonce) internal view returns (uint256) {
        uint256 remainder = getRN(randomSeed, nonce) % 1000;
        console.log("remainder: ", remainder);
        uint256 rarity;
        if (combinedRarity == 0) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(0, 0, 0, 0, 0, 20, 68)
            );
        } else if (combinedRarity == 1) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(0, 0, 0, 0, 0, 21, 70)
            );
        } else if (combinedRarity == 2) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(0, 0, 1, 2, 3, 25, 76)
            );
        } else if (combinedRarity == 3) {
            return getRarityValuesFromRanges(
                remainder,
                Distribution(0, 1, 2, 4, 7, 32, 86)
            );
        } else if (combinedRarity == 4) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(1, 3, 5, 8, 13, 41, 100)
            );
        } else if (combinedRarity == 5) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(1, 3, 7, 12, 19, 50, 114)
            );
        } else if (combinedRarity == 6) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(1, 4, 9, 15, 24, 60, 130)
            );
        } else if (combinedRarity == 7) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(2, 6, 13, 21, 34, 75, 152)
            );
        } else if (combinedRarity == 8) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(2, 7, 16, 27, 43, 90, 176)
            );
        } else if (combinedRarity == 9) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(3, 10, 21, 35, 55, 109, 204)
            );
        } else if (combinedRarity == 10) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(3, 11, 24, 41, 66, 127, 233)
            );
        } else if (combinedRarity == 11) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(4, 14, 30, 50, 80, 150, 267)
            );
        } else if (combinedRarity == 12) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(5, 17, 36, 59, 94, 173, 303)
            );
        } else if (combinedRarity == 13) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(5, 19, 41, 68, 109, 197, 341)
            );
        } else if (combinedRarity == 14) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(6, 22, 47, 79, 126, 225, 383)
            );
        } else if (combinedRarity == 15) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(7, 25, 54, 90, 144, 254, 428)
            );
        } else if (combinedRarity == 16) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(8, 28, 61, 102, 163, 285, 476)
            );
        } else if (combinedRarity == 17) {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(9, 32, 69, 115, 184, 319, 528)
            );
        } else {
            rarity = getRarityValuesFromRanges(
                remainder,
                Distribution(10, 36, 77, 128, 205, 353, 581)
            );
        }
        properties.dtrait.rarity = uint8(rarity);
        return nonce + 1;
    }

    function calculateAndUpdateRareBodyParts(
        Properties memory properties,
        uint256 rarity,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsData dsData
    ) internal view returns (uint256) {
        if (rarity == 8) {
            properties.bpf.torso_id = uint24(getRandomBodyPart(BodyPartTypes.TORSO, 1, randomSeed, nonce, dsData));
            properties.bpf.torso_rarity = 1;
            properties.bpf.eyes_id = uint24(getRandomBodyPart(BodyPartTypes.EYES, 1, randomSeed, nonce + 1, dsData));
            properties.bpf.eyes_rarity = 1;
            properties.bpf.mane_id = uint24(getRandomBodyPart(BodyPartTypes.MANE, 1, randomSeed, nonce + 2, dsData));
            properties.bpf.mane_rarity = 1;
            properties.bpf.horn_id = uint24(getRandomBodyPart(BodyPartTypes.HORN, 1, randomSeed, nonce + 3, dsData));
            properties.bpf.horn_rarity = 1;
            properties.bpf.legs_id = uint24(getRandomBodyPart(BodyPartTypes.LEGS, 1, randomSeed, nonce + 4, dsData));
            properties.bps.legs_rarity = 1;
            properties.bps.muzzle_id = uint24(getRandomBodyPart(BodyPartTypes.MUZZLE, 1, randomSeed, nonce + 5, dsData));
            properties.bps.muzzle_rarity = 1;
            properties.bps.tail_id = uint24(getRandomBodyPart(BodyPartTypes.TAIL, 1, randomSeed, nonce + 6, dsData));
            properties.bps.tail_rarity = 1;
            properties.bps.wings_id = uint24(getRandomBodyPart(BodyPartTypes.WINGS, 1, randomSeed, nonce + 7, dsData));
            properties.bps.wings_rarity = 1;
            return nonce + 8;
        }

        BodyPartPair[8] memory bodyPartPairs = [
            BodyPartPair(BodyPartTypes.MUZZLE, 20, 0),
            BodyPartPair(BodyPartTypes.EYES, 5, 0),
            BodyPartPair(BodyPartTypes.MANE, 12, 0),
            BodyPartPair(BodyPartTypes.TORSO, 20, 0),
            BodyPartPair(BodyPartTypes.LEGS, 20, 0),
            BodyPartPair(BodyPartTypes.TAIL, 10, 0),
            BodyPartPair(BodyPartTypes.HORN, 8, 0),
            BodyPartPair(BodyPartTypes.WINGS, 5, 0)
        ];

        for (uint256 i = 0; i < rarity; i++) {
            setRandomRareBodyPartBasedOnWeight(bodyPartPairs, getRN(randomSeed, nonce + i));
        }
        nonce += rarity;

        for (uint256 i = 0; i < 8; i++) {
            if (bodyPartPairs[i].chosen == 0) {
                continue;
            }
            
            if (bodyPartPairs[i].bodyPartType == BodyPartTypes.TORSO) {
                properties.bpf.torso_id = uint24(getRandomBodyPart(bodyPartPairs[i].bodyPartType, 1, randomSeed, nonce, dsData));
                nonce += 1;
                properties.bpf.torso_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.EYES) {
                properties.bpf.eyes_id = uint24(getRandomBodyPart(bodyPartPairs[i].bodyPartType, 1, randomSeed, nonce, dsData));
                nonce += 1;
                properties.bpf.eyes_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.MANE) {
                properties.bpf.mane_id = uint24(getRandomBodyPart(bodyPartPairs[i].bodyPartType, 1, randomSeed, nonce, dsData));
                nonce += 1;
                properties.bpf.mane_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.HORN) {
                properties.bpf.horn_id = uint24(getRandomBodyPart(bodyPartPairs[i].bodyPartType, 1, randomSeed, nonce, dsData));
                nonce += 1;
                properties.bpf.horn_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.LEGS) {
                properties.bpf.legs_id = uint24(getRandomBodyPart(bodyPartPairs[i].bodyPartType, 1, randomSeed, nonce, dsData));
                nonce += 1;
                properties.bps.legs_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.MUZZLE) {
                properties.bps.muzzle_id = uint24(getRandomBodyPart(bodyPartPairs[i].bodyPartType, 1, randomSeed, nonce, dsData));
                nonce += 1;
                properties.bps.muzzle_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.TAIL) {
                properties.bps.tail_id = uint24(getRandomBodyPart(bodyPartPairs[i].bodyPartType, 1, randomSeed, nonce, dsData));
                nonce += 1;
                properties.bps.tail_rarity = 1;
            } else if (bodyPartPairs[i].bodyPartType == BodyPartTypes.WINGS) {
                properties.bps.wings_id = uint24(getRandomBodyPart(bodyPartPairs[i].bodyPartType, 1, randomSeed, nonce, dsData));
                nonce += 1;
                properties.bps.wings_rarity = 1;
            }
        }
        return nonce;
    }

    function calculateAndUpdateCommonBodyParts(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsData dsData
    ) internal view returns (uint256) {
        if (properties.bpf.torso_rarity == 0) {
            properties.bpf.torso_id = uint24(getBodyPartId(mother, father, randomSeed, nonce, BodyPartTypes.TORSO, dsData));
        }
        if (properties.bpf.eyes_rarity == 0) {
            properties.bpf.eyes_id = uint24(getBodyPartId(mother, father, randomSeed, nonce + 1, BodyPartTypes.EYES, dsData));
        }
        if (properties.bpf.mane_rarity == 0) {
            properties.bpf.mane_id = uint24(getBodyPartId(mother, father, randomSeed, nonce + 2, BodyPartTypes.MANE, dsData));
        }
        if (properties.bps.legs_rarity == 0) {
            properties.bpf.legs_id = uint24(getBodyPartId(mother, father, randomSeed, nonce + 3, BodyPartTypes.LEGS, dsData));
        }
        if (properties.bps.muzzle_rarity == 0) {
            properties.bps.muzzle_id = uint24(getBodyPartId(mother, father, randomSeed, nonce + 4, BodyPartTypes.MUZZLE, dsData));
        }
        if (properties.bps.tail_rarity == 0) {
            properties.bps.tail_id = uint24(getBodyPartId(mother, father, randomSeed, nonce + 5, BodyPartTypes.TAIL, dsData));
        }
        return nonce + 6;
    }

    function calculateAndUpdateTalents(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce
    ) internal pure returns (uint256) {
        uint256 motherSTalentCount = getTalentRankCount(mother, 5);
        uint256 fatherSTalentCount = getTalentRankCount(father, 5);

        uint256[4] memory talents;
        uint256 sTalentCount;
        if (motherSTalentCount > 0 && fatherSTalentCount > 0) {
            sTalentCount = getRN(randomSeed, nonce) % 2 == 0 ? 1 : 0; // 50% chance
        } else if (motherSTalentCount > 0 || fatherSTalentCount > 0) {
            sTalentCount = getRN(randomSeed, nonce) % 5 == 0 ? 1 : 0; // 20% chance
        } else {
            uint256 motherATalentCount = getTalentRankCount(mother, 4);
            uint256 fatherATalentCount = getTalentRankCount(father, 4);
            
            if (motherATalentCount > 0 && fatherATalentCount > 0) {
                sTalentCount = getRN(randomSeed, nonce) % 50 == 0 ? 1 : 0; // 2% chance
            }
        }
        nonce += 1;

        uint256 aTalentCount;
        uint256 bTalentCount;
        if (sTalentCount == 1) {
            talents[0] = 5;
            uint256 remainder = getRN(randomSeed, nonce) % 100;
            if (remainder < 5) {
                aTalentCount = 1;
                talents[1] = 4;
            } else if (remainder < 40) {
                bTalentCount = 1;
                talents[1] = 3;
            }
        } else {
            uint256 remainder = getRN(randomSeed, nonce) % 100;
            if (remainder < 40) {
                aTalentCount = 1;
                talents[0] = 4;
            } else if (remainder < 40) {
                bTalentCount = 1;
                talents[0] = 3;
            } else {
                bTalentCount = 2;
                talents[0] = 3;
                talents[1] = 3;
            }
        }
        nonce += 1;

        if (sTalentCount + aTalentCount + bTalentCount == 2) {
            for (uint256 i = 2; i < 4; i++) {
                if (getRN(randomSeed, nonce) % 2 == 0) {
                    talents[i] = 1;
                } else {
                    talents[i] = 0;
                }
                nonce += 1;
            }
        } else {
            for (uint256 i = 1; i < 4; i++) {
                uint256 remainder = getRN(randomSeed, nonce) % 10;
                if (remainder < 4) {
                    talents[i] = 2;
                } else if (remainder < 7) {
                    talents[i] = 1;
                } else {
                    talents[i] = 0;
                }
                nonce += 1;
            }
            if (talents[1] == 0 && talents[2] == 0 && talents[3] == 0) {
                talents[3] = 2;
            }
            nonce += 1;
        }

        uint256[] memory indices = new uint256[](4);
        indices[0] = getRN(randomSeed, nonce) % 4;
        uint256 offset_from_index_0 = getRN(randomSeed, nonce + 1) % 3 + 1;
        indices[1] = (offset_from_index_0 + indices[0]) % 4;
        uint256 offset_from_index_1 = getRN(randomSeed, nonce + 2) % 2;
        for (uint256 i = 0; i < 4; i++) {
            if (i != indices[0] && i != indices[1]) {
                if (offset_from_index_1 == 1) {
                    indices[3] = i;
                    offset_from_index_1 -= 1;
                } else {
                    indices[2] = i;
                }
            }
        }
        properties.dtrait.talent_rr = uint8(talents[indices[0]]);
        properties.dtrait.talent_fr = uint8(talents[indices[1]]);
        properties.dtrait.talent_st = uint8(talents[indices[2]]);
        properties.dtrait.talent_sr = uint8(talents[indices[3]]);
        return nonce + 3;
    }

    function calculateAndUpdateStats(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce
    ) internal view returns (uint256) {
        Stat[5] memory stats;
        stats[0] = Stat(StatType.SPEED, mother.dtrait.stat_spd + father.dtrait.stat_spd, 0);
        stats[1] = Stat(StatType.STAMINA, mother.dtrait.stat_stm + father.dtrait.stat_stm, 0);
        stats[2] = Stat(StatType.POWER, mother.dtrait.stat_pow + father.dtrait.stat_pow, 0);
        stats[3] = Stat(StatType.GRIT, mother.dtrait.stat_grt + father.dtrait.stat_grt, 0);
        stats[4] = Stat(StatType.INTELLECT, mother.dtrait.stat_int + father.dtrait.stat_int, 0);
        sortStats(stats);

        stats[4].newValue = getRandomStat(60, 81, getRN(randomSeed, nonce));
        nonce += 1;
        stats[3].newValue = getRandomStat(50, 71, getRN(randomSeed, nonce));
        nonce += 1;
        stats[2].newValue = getRandomStat(40, 61, getRN(randomSeed, nonce));
        nonce += 1;
        stats[1].newValue = (250 - stats[4].newValue - stats[3].newValue - stats[2].newValue) * 6 / 10;
        stats[0].newValue = 250 - stats[4].newValue - stats[3].newValue - stats[2].newValue - stats[1].newValue;

        for (uint256 i = 0; i < 5; i++) {
            if (stats[i].statType == StatType.SPEED) {
                properties.dtrait.stat_spd = uint8(stats[i].newValue);
            } else if (stats[i].statType == StatType.STAMINA) {
                properties.dtrait.stat_stm = uint8(stats[i].newValue);
            } else if (stats[i].statType == StatType.POWER) {
                properties.dtrait.stat_pow = uint8(stats[i].newValue);
            } else if (stats[i].statType == StatType.GRIT) {
                properties.dtrait.stat_grt = uint8(stats[i].newValue);
            } else if (stats[i].statType == StatType.INTELLECT) {
                properties.dtrait.stat_int = uint8(stats[i].newValue);
            }
        }
        return nonce;
    }

    function calculateAndUpdateSkills(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsData dsData
    ) internal view returns (uint256) {
        uint256 motherSpecialSkillTier = dsData.getSpecialSkillTier(mother.dtrait.skill1);
        uint256 fatherSpecialSkillTier = dsData.getSpecialSkillTier(father.dtrait.skill1);
        uint256 specialSkillRemainder = getRN(randomSeed, nonce) % (motherSpecialSkillTier + fatherSpecialSkillTier);
        if (specialSkillRemainder < motherSpecialSkillTier) {
            properties.dtrait.skill1 = mother.dtrait.skill1;
        } else {
            properties.dtrait.skill1 = father.dtrait.skill1;
        }
        nonce += 1;

        uint256 mutantSkillsCount;
        uint256 countRemainder = getRN(randomSeed, nonce) % 100;
        if (countRemainder < 75) {
            mutantSkillsCount = 1;
        } else if (countRemainder < 85) {
            mutantSkillsCount = 2;
        }
        nonce += 1;

        uint8 mutantSkillIndex1 = 255;
        if (mutantSkillsCount > 0) {
            mutantSkillIndex1 = uint8(getRN(randomSeed, nonce) % 5);
            nonce += 1;
        }

        uint8 mutantSkillIndex2 = 255;
        if (mutantSkillsCount > 1) {
            uint256 offsetFromIndex1 = getRN(randomSeed, nonce) % 4 + 1;
            mutantSkillIndex2 = uint8((mutantSkillIndex1 + offsetFromIndex1) % 5);
            nonce += 1;
        }

        return calculateAndUpdateSkills2(
            mother,
            father,
            properties,
            MutantSkill(
                uint8(mutantSkillIndex1),
                uint8(mutantSkillIndex2),
                uint8(mutantSkillsCount)
            ),
            randomSeed,
            nonce,
            dsData
        );
    }

    function calculateAndUpdateSkills2(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        MutantSkill memory mutantSkill,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsData dsData
    ) internal view returns (uint256) {
        if (mutantSkill.index1 == 0 || mutantSkill.index2 == 0) {
            properties.dtrait.skill2 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill2),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill2 = getRN(randomSeed, nonce) % 100 < 65 ? mother.dtrait.skill2 : father.dtrait.skill2;
            nonce += 1;
        }

        if (mutantSkill.index1 == 1 || mutantSkill.index2 == 1) {
            properties.dtrait.skill3 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill3),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill3 = getRN(randomSeed, nonce) % 100 < 65 ? mother.dtrait.skill3 : father.dtrait.skill3;
            nonce += 1;
        }

        if (mutantSkill.index1 == 2 || mutantSkill.index2 == 2) {
            properties.dtrait.skill4 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill4),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill4 = getRN(randomSeed, nonce) % 100 < 65 ? mother.dtrait.skill4 : father.dtrait.skill4;
            nonce += 1;
        }

        if (mutantSkill.index1 == 3 || mutantSkill.index2 == 3) {
            properties.dtrait.skill5 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill5),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill5 = getRN(randomSeed, nonce) % 100 < 65 ? mother.dtrait.skill5 : father.dtrait.skill5;
            nonce += 1;
        }

        if (mutantSkill.index1 == 4 || mutantSkill.index2 == 4) {
            properties.dtrait.skill6 = uint24(
                getRandomSkill(
                    dsData.getNormalSkillTier(mother.dtrait.skill6),
                    dsData,
                    randomSeed,
                    nonce
                )
            );
            nonce += 2;
        } else {
            properties.dtrait.skill6 = getRN(randomSeed, nonce) % 100 < 65 ? mother.dtrait.skill6 : father.dtrait.skill6;
            nonce += 1;
        }

        return nonce;
    }

    function calculateAndUpdateTrackPref(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce
    ) internal pure returns (uint256) {
        uint256 remainder = getRN(randomSeed, nonce) % 100;
        nonce += 1;
        uint256 trackPrefTurf = calculateTrackPref(
            mother.dtrait.track_perf_turf,
            father.dtrait.track_perf_turf,
            remainder
        );

        remainder = getRN(randomSeed, nonce) % 100;
        nonce += 1;
        uint256 trackPrefDirt = calculateTrackPref(
            mother.dtrait.track_perf_dirt,
            father.dtrait.track_perf_dirt,
            remainder
        );

        if (trackPrefDirt == 0 && trackPrefTurf == 0) {
            remainder = getRN(randomSeed, nonce) % 2;
            nonce += 1;
            if (remainder == 0) {
                trackPrefTurf = 1;
            } else {
                trackPrefDirt = 1;
            }
        }

        properties.dtrait.track_perf_turf = uint8(trackPrefTurf);
        properties.dtrait.track_perf_dirt = uint8(trackPrefDirt);

        return nonce;
    }

    function calculateTrackPref(uint256 motherTrackPref, uint256 fatherTrackPref, uint256 remainder) internal pure returns (uint256 newTrackPref) {
       uint256 sum = motherTrackPref + fatherTrackPref;
        if (sum == 4) {
            if (remainder < 65) {
                newTrackPref = 2;
            } else {
                newTrackPref = 1;
            }
        } else if (sum == 3) {
            if (remainder < 30) {
                newTrackPref = 2;
            } else if (remainder < 90) {
                newTrackPref = 1;
            }
        } else if (sum == 2) {
            if (motherTrackPref == 1) {
                if (remainder < 10) {
                    newTrackPref = 2;
                } else if (remainder < 90) {
                    newTrackPref = 1;
                }
            } else {
                if (remainder < 10) {
                    newTrackPref = 2;
                } else if (remainder < 65) {
                    newTrackPref = 1;
                }
            }
        } else if (sum == 1) {
            if (remainder < 6) {
                newTrackPref = 2;
            } else if (remainder < 53) {
                newTrackPref = 1;
            }
        } else {
            if (remainder < 3) {
                newTrackPref = 2;
            } else if (remainder < 20) {
                newTrackPref = 1;
            }
        }
    }

    function calculateAndUpdateColor(
        Properties memory mother,
        Properties memory father,
        Properties memory properties,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsData dsData
    ) internal view returns (uint256) {
        // Update for when both mother and father are unique horses
        if (mother.dtrait.rarity == 9 && father.dtrait.rarity == 9) {
            Color memory torsoColor = getRandomColor(BodyPartTypes.TORSO, randomSeed, nonce, dsData);
            properties.bpf.torso_colorgroup = torsoColor.group;
            properties.bpf.torso_colorid = torsoColor.id;
            properties.bps.muzzle_colorgroup = torsoColor.group;
            properties.bps.muzzle_colorid = torsoColor.id;
            properties.bpf.eyes_colorgroup = torsoColor.group;
            properties.bpf.eyes_colorid = torsoColor.id;

            Color memory maneColor = getRandomColor(BodyPartTypes.MANE, randomSeed, nonce + 2, dsData);
            properties.bpf.mane_colorgroup = maneColor.group;
            properties.bpf.mane_colorid = maneColor.id;

            Color memory legsColor = getRandomColor(BodyPartTypes.TORSO, randomSeed, nonce + 4, dsData);
            properties.bps.legs_colorgroup = legsColor.group;
            properties.bps.legs_colorid = legsColor.id;

            Color memory tailColor = getRandomColor(BodyPartTypes.TAIL, randomSeed, nonce + 6, dsData);
            properties.bps.tail_colorgroup = tailColor.group;
            properties.bps.tail_colorid = tailColor.id;

            Color memory hornColor = getRandomColor(BodyPartTypes.HORN, randomSeed, nonce + 8, dsData);
            properties.bpf.horn_colorgroup = hornColor.group;
            properties.bpf.horn_colorid = hornColor.id;

            return nonce + 10;
        }

        // Torso, muzzle, and eyes have the same color and will inherit either from the mother or the father
        Properties memory ancestor = getRN(randomSeed, nonce) % 2 == 0 ? mother : father;
        nonce += 1;
        properties.bpf.torso_colorgroup = ancestor.bpf.torso_colorgroup;
        properties.bpf.torso_colorid = ancestor.bpf.torso_colorid;
        properties.bps.muzzle_colorgroup = ancestor.bps.muzzle_colorgroup;
        properties.bps.muzzle_colorid = ancestor.bps.muzzle_colorid;
        properties.bpf.eyes_colorgroup = ancestor.bpf.eyes_colorgroup;
        properties.bpf.eyes_colorid = ancestor.bpf.eyes_colorid;

        uint256 maneRemainder = getRN(randomSeed, nonce) % 1000;
        if (maneRemainder < 250) {
            properties.bpf.mane_colorgroup = father.bpf.mane_colorgroup;
            properties.bpf.mane_colorid = father.bpf.mane_colorid;
        } else if (maneRemainder < 500) {
            properties.bpf.mane_colorgroup = mother.bpf.mane_colorgroup;
            properties.bpf.mane_colorid = mother.bpf.mane_colorid;
        } else if (maneRemainder < 735) {
            properties.bpf.mane_colorgroup = mother.bpf.mane_colorgroup;
            properties.bpf.mane_colorid = getRandomColorFromGroup(mother.bpf.mane_colorgroup, randomSeed, nonce, dsData);
        } else if (maneRemainder < 970) {
            properties.bpf.mane_colorgroup = mother.bpf.mane_colorgroup;
            properties.bpf.mane_colorid = getRandomColorFromGroup(mother.bpf.mane_colorgroup, randomSeed, nonce, dsData);
        } else {
            Color memory color = getRandomColor(BodyPartTypes.MANE, randomSeed, nonce, dsData);
            properties.bpf.mane_colorgroup = color.group;
            properties.bpf.mane_colorid = color.id;
        }
        nonce += 2;

        uint256 legsRemainder = getRN(randomSeed, nonce) % 1000;
        if (legsRemainder < 250) {
            properties.bps.legs_colorgroup = father.bps.legs_colorgroup;
            properties.bps.legs_colorid = father.bps.legs_colorid;
        } else if (legsRemainder < 500) {
            properties.bps.legs_colorgroup = mother.bps.legs_colorgroup;
            properties.bps.legs_colorid = mother.bps.legs_colorid;
        } else if (legsRemainder < 735) {
            properties.bps.legs_colorgroup = father.bps.legs_colorgroup;
            properties.bps.legs_colorid = getRandomColorFromGroup(father.bps.legs_colorgroup, randomSeed, nonce, dsData);
        } else if (legsRemainder < 970) {
            properties.bps.legs_colorgroup = mother.bps.legs_colorgroup;
            properties.bps.legs_colorid = getRandomColorFromGroup(mother.bps.legs_colorgroup, randomSeed, nonce, dsData);
        } else {
            Color memory color = getRandomColor(BodyPartTypes.TORSO, randomSeed, nonce, dsData);
            properties.bps.legs_colorgroup = color.group;
            properties.bps.legs_colorid = color.id;
        }
        nonce += 2;

        uint256 tailRemainder = getRN(randomSeed, nonce) % 1000;
        if (tailRemainder < 250) {
            properties.bps.tail_colorgroup = father.bps.tail_colorgroup;
            properties.bps.tail_colorid = father.bps.tail_colorid;
        } else if (tailRemainder < 500) {
            properties.bps.tail_colorgroup = mother.bps.tail_colorgroup;
            properties.bps.tail_colorid = mother.bps.tail_colorid;
        } else if (tailRemainder < 735) {
            properties.bps.tail_colorgroup = father.bps.tail_colorgroup;
            properties.bps.tail_colorid = getRandomColorFromGroup(father.bps.tail_colorgroup, randomSeed, nonce, dsData);
        } else if (tailRemainder < 970) {
            properties.bps.tail_colorgroup = mother.bps.tail_colorgroup;
            properties.bps.tail_colorid = getRandomColorFromGroup(mother.bps.tail_colorgroup, randomSeed, nonce, dsData);
        } else {
            Color memory color = getRandomColor(BodyPartTypes.TAIL, randomSeed, nonce, dsData);
            properties.bps.tail_colorgroup = color.group;
            properties.bps.tail_colorid = color.id;
        }
        nonce += 2;

        uint256 hornRemainder = getRN(randomSeed, nonce) % 1000;
        if (hornRemainder < 250) {
            properties.bpf.horn_colorgroup = father.bpf.horn_colorgroup;
            properties.bpf.horn_colorid = father.bpf.horn_colorid;
        } else if (hornRemainder < 500) {
            properties.bpf.horn_colorgroup = mother.bpf.horn_colorgroup;
            properties.bpf.horn_colorid = mother.bpf.horn_colorid;
        } else if (hornRemainder < 735) {
            properties.bpf.horn_colorgroup = father.bpf.horn_colorgroup;
            properties.bpf.horn_colorid = getRandomColorFromGroup(father.bpf.horn_colorgroup, randomSeed, nonce, dsData);
        } else if (hornRemainder < 970) {
            properties.bpf.horn_colorgroup = mother.bpf.horn_colorgroup;
            properties.bpf.horn_colorid = getRandomColorFromGroup(mother.bpf.horn_colorgroup, randomSeed, nonce, dsData);
        } else {
            Color memory color = getRandomColor(BodyPartTypes.HORN, randomSeed, nonce, dsData);
            properties.bpf.horn_colorgroup = color.group;
            properties.bpf.horn_colorid = color.id;
        }
        nonce += 2;

        return nonce;
    }

    function getRandomSkill(
        uint256 motherTier,
        IDerbyStarsData dsData,
        bytes32 randomSeed,
        uint256 nonce
    ) internal view returns (uint256) {
        uint256 remainder = getRN(randomSeed, nonce) % 100;
        uint256 newTier;
        if (remainder < 10) {
            if (motherTier == 1) {
                newTier = motherTier;
            } else if (motherTier == 2) {
                newTier = motherTier - 1;
            } else {
                newTier = motherTier - 2;
            }
        } else if (remainder < 35) {
            if (motherTier == 1) {
                newTier = motherTier;
            } else {
                newTier = motherTier - 1;
            }
        } else if (remainder < 85) {
            newTier = motherTier;
        } else {
            if (motherTier == 10) {
                newTier = motherTier + 1;
            } else {
                newTier = motherTier;
            }
        }
        uint256[] memory skills = dsData.getNormalSkillIds(newTier);
        return skills[getRN(randomSeed, nonce) % skills.length];
    }

    function getRarityValuesFromRanges(
        uint256 remainder,
        Distribution memory distribution
    ) internal pure returns (uint256) {
        if (remainder < distribution.range0) {
            return 8;
        } else if (remainder < distribution.range1) {
            return 7;
        } else if (remainder < distribution.range2) {
            return 6;                
        } else if (remainder < distribution.range3) {
            return 5;
        } else if (remainder < distribution.range4) {
            return 4;
        } else if (remainder < distribution.range5) {
            return 3;
        } else if (remainder < distribution.range6) {
            return 2;
        } else {
            return 1;
        }
    }

    function getBodyPartId(
        Properties memory mother,
        Properties memory father,
        bytes32 randomSeed,
        uint256 nonce,
        BodyPartTypes bodyPartType,
        IDerbyStarsData dsData        
    ) internal view returns (uint256) {
        uint256 motherRarity = mother.bpf.torso_rarity;
        uint256 fatherRarity = father.bpf.torso_rarity;

        if (motherRarity == 0 && fatherRarity == 0) {
            Properties memory inheritor = getRN(randomSeed, nonce) % 2 == 0 ? mother : father;
            return inheritor.bpf.torso_id;
        } else if (motherRarity == 1 && fatherRarity == 1) {
            return uint24(getRandomBodyPart(bodyPartType, 0, randomSeed, nonce, dsData));
        } else {
            if (motherRarity == 0) {
                return mother.bpf.torso_id;
            } else {
                return father.bpf.torso_id;
            }
        }
    }

    function getRandomBodyPart(
        BodyPartTypes bodyPartType,
        uint256 bodyPartRarity,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsData dsData
    ) internal view returns (uint256) {
        uint256[] memory ids = dsData.getBodyPartRarityGroupIds(uint256(bodyPartType), bodyPartRarity);
        if (ids.length == 0) {
            return 0;
        }
        uint256 idPrefix;
        if (bodyPartType == BodyPartTypes.TORSO) {
            idPrefix = 10_000_000;
        } else if (bodyPartType == BodyPartTypes.EYES) {
            idPrefix = 11_000_000;
        } else if (bodyPartType == BodyPartTypes.MANE) {
            idPrefix = 12_000_000;
        } else if (bodyPartType == BodyPartTypes.HORN) {
            idPrefix = 13_000_000;
        } else if (bodyPartType == BodyPartTypes.LEGS) {
            idPrefix = 14_000_000;
        } else if (bodyPartType == BodyPartTypes.MUZZLE) {
            idPrefix = 15_000_000;
        } else if (bodyPartType == BodyPartTypes.TAIL) {
            idPrefix = 17_000_000;
        } else if (bodyPartType == BodyPartTypes.WINGS) {
            idPrefix = 30_000_000;
        }
        return ids[getRN(randomSeed, nonce) % ids.length] - idPrefix;
    }

    function getRandomColor(
        BodyPartTypes bodyPartType,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsData dsData
    ) internal view returns (Color memory) {
        uint256[] memory groups = dsData.getColorGroups(uint256(bodyPartType));
        uint256 randomGroupIndex = groups[getRN(randomSeed, nonce) % groups.length];
        uint256 groupColorsLength = dsData.getColorsLength(randomGroupIndex);
        uint256 randomColorIndex = getRN(randomSeed, nonce + 1) % groupColorsLength;
        return Color(uint8(randomGroupIndex), uint16(randomColorIndex));
    }

    function getRandomColorFromGroup(
        uint256 groupIndex,
        bytes32 randomSeed,
        uint256 nonce,
        IDerbyStarsData dsData
    ) internal view returns (uint16) {
        uint256 groupColorsLength = dsData.getColorsLength(groupIndex);
        return uint16(getRN(randomSeed, nonce) % groupColorsLength);
    }

    function getRN(bytes32 seed, uint256 nonce) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(seed, nonce)));
    }

    function getTalentRankCount(Properties memory properties, uint256 talentRank) internal pure returns (uint256 count) {
        if (properties.dtrait.talent_rr == talentRank) count += 1;
        if (properties.dtrait.talent_fr == talentRank) count += 1;
        if (properties.dtrait.talent_st == talentRank) count += 1;
        if (properties.dtrait.talent_sr == talentRank) count += 1;
        return count;
    }

    function setRandomRareBodyPartBasedOnWeight(BodyPartPair[8] memory bodyPartPairs, uint256 rn) internal pure {
        uint256 weightSum;
        for (uint256 i = 0; i < 8; i++) {
            if (bodyPartPairs[i].chosen == 0) {
                weightSum += bodyPartPairs[i].weight;
            }
        }
        uint256 remainder = rn % weightSum;

        for (uint256 i = 0; i < 8; i++) {
            if (bodyPartPairs[i].chosen == 0) {
                if (remainder > bodyPartPairs[i].weight) {
                    remainder -= bodyPartPairs[i].weight;
                } else {
                    bodyPartPairs[i].chosen = 1;
                    return;
                }
            }
        }
    }

    function getRandomStat(uint256 lowerBound, uint256 upperBound, uint256 rn) internal pure returns (uint256) {
        return lowerBound + rn % (upperBound - lowerBound);
    }

    function sortStats(Stat[5] memory statSums) internal view returns (Stat[5] memory) {
        quickSortStats(statSums, int256(0), int256(statSums.length - 1));
        return statSums;
    }

    function quickSortStats(
        Stat[5] memory arr,
        int256 left,
        int256 right
    ) internal view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        Stat memory pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)].parentSum < pivot.parentSum) i++;
            while (pivot.parentSum < arr[uint256(j)].parentSum) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSortStats(arr, left, j);
        if (i < right) quickSortStats(arr, i, right);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IDerbyStarsData} from "../interfaces/IDerbyStarsData.sol";

struct DefaultTrait {
    uint8 origin;
    uint8 rarity;
    uint8 talent_rr;
    uint8 talent_fr;
    uint8 talent_st;
    uint8 talent_sr;
    uint8 stat_spd;
    uint8 stat_stm;
    uint8 stat_pow;
    uint8 stat_grt;
    uint8 stat_int;
    uint8 track_perf_turf;
    uint8 track_perf_dirt;
    uint24 skill1;
    uint24 skill2;
    uint24 skill3;
    uint24 skill4;
    uint24 skill5;
    uint24 skill6;
}

struct TrainedTrait {
    uint8 stat_spd;
    uint8 stat_stm;
    uint8 stat_pow;
    uint8 stat_grt;
    uint8 stat_int;
}

struct BodyPartsFirst {
    uint24 torso_id;
    uint8 torso_colorgroup;
    uint16 torso_colorid;
    uint8 torso_rarity;
    uint24 eyes_id;
    uint8 eyes_colorgroup;
    uint16 eyes_colorid;
    uint8 eyes_rarity;
    uint24 mane_id;
    uint8 mane_colorgroup;
    uint16 mane_colorid;
    uint8 mane_rarity;
    uint24 horn_id;
    uint8 horn_colorgroup;
    uint16 horn_colorid;
    uint8 horn_rarity;
    uint24 legs_id;
}

struct BodyPartsSecond {
    uint8 legs_colorgroup;
    uint16 legs_colorid;
    uint8 legs_rarity;
    uint24 muzzle_id;
    uint8 muzzle_colorgroup;
    uint16 muzzle_colorid;
    uint8 muzzle_rarity;
    uint24 rein_id;
    uint8 rein_colorgroup;
    uint16 rein_colorid;
    uint8 rein_rarity;
    uint24 tail_id;
    uint8 tail_colorgroup;
    uint16 tail_colorid;
    uint8 tail_rarity;
    uint24 wings_id;
    uint8 wings_colorgroup;
    uint16 wings_colorid;
    uint8 wings_rarity;
}

struct Properties {
    uint112 id_mother;
    uint112 id_father;
    uint16 breed_count_mother;
    uint16 breed_count_father;
    DefaultTrait dtrait;
    TrainedTrait ttrait;
    BodyPartsFirst bpf;
    BodyPartsSecond bps;
}

abstract contract HorseProperty {
    // Properties public layoutTest;
    mapping(uint256 => Properties) public properties;
    string[] public addPropKeys;
    mapping(uint256 => mapping(bytes32 => string)) public addPropVal;
    //address public dsData;
    IDerbyStarsData public dsData;

    constructor(address data_) {
        dsData = IDerbyStarsData(data_);
    }

    function getProperty(uint256 index) public view virtual returns (Properties memory) {
        return properties[index];
    }

    //address private
    // function toMetadata(uint256 id_) external view returns (string memory) {
    //     Properties memory prop = properties[id_];

    //     bytes memory metadata = abi.encodePacked(
    //         'data:application/json;utf8,{"name":"Horse #',
    //         Strings.toString(id_),
    //         '","external_url":"',
    //         "someurl",
    //         '","description":"',
    //         "",
    //         '","attributes":['
    //     );

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"breed count as mother","value":',
    //             Strings.toString(prop.breed_count_mother),
    //             "},",
    //             '{"trait_type":"breed count as father","value":',
    //             Strings.toString(prop.breed_count_father),
    //             "},",
    //             '{"trait_type":"mother id","value":',
    //             Strings.toString(prop.id_mother),
    //             "},",
    //             '{"trait_type":"father id","value":',
    //             Strings.toString(prop.id_father),
    //             "},"
    //         );
    //     }

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"origin","value":"',
    //             Strings.toString(prop.dtrait.origin),
    //             '"},',
    //             '{"trait_type":"rarity","value":"',
    //             Strings.toString(prop.dtrait.rarity),
    //             '"},',
    //             '{"trait_type":"speed","value":',
    //             Strings.toString(prop.dtrait.stat_spd),
    //             "},",
    //             '{"trait_type":"stamina","value":',
    //             Strings.toString(prop.dtrait.stat_stm),
    //             "},",
    //             '{"trait_type":"power","value":',
    //             Strings.toString(prop.dtrait.stat_pow),
    //             "},",
    //             '{"trait_type":"grit","value":',
    //             Strings.toString(prop.dtrait.stat_grt),
    //             "},"
    //         );
    //     }

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"intellect","value":',
    //             Strings.toString(prop.dtrait.stat_int),
    //             "},", // TODO : prop name
    //             '{"trait_type":"torso","value":"',
    //             Strings.toString(prop.bpf.torso_id),
    //             '"},',
    //             '{"trait_type":"eyes","value":"',
    //             Strings.toString(prop.bpf.eyes_id),
    //             '"},',
    //             '{"trait_type":"mane","value":"',
    //             Strings.toString(prop.bpf.mane_id),
    //             '"},',
    //             '{"trait_type":"horn","value":"',
    //             Strings.toString(prop.bpf.horn_id),
    //             '"},'
    //         );
    //     }

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"legs","value":"',
    //             Strings.toString(prop.bpf.legs_id),
    //             '"},',
    //             '{"trait_type":"muzzle","value":"',
    //             Strings.toString(prop.bps.muzzle_id),
    //             '"},',
    //             '{"trait_type":"rein","value":"',
    //             Strings.toString(prop.bps.rein_id),
    //             '"},',
    //             '{"trait_type":"tail","value":"',
    //             Strings.toString(prop.bps.tail_id),
    //             '"},',
    //             '{"trait_type":"wings","value":"',
    //             Strings.toString(prop.bps.wings_id),
    //             '"},'
    //         );
    //     }

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"skill 1","value":"',
    //             Strings.toString(prop.dtrait.skill1),
    //             '"},',
    //             '{"trait_type":"skill 2","value":"',
    //             Strings.toString(prop.dtrait.skill2),
    //             '"},',
    //             '{"trait_type":"skill 3","value":"',
    //             Strings.toString(prop.dtrait.skill3),
    //             '"},',
    //             '{"trait_type":"skill 4","value":"',
    //             Strings.toString(prop.dtrait.skill4),
    //             '"},',
    //             '{"trait_type":"skill 5","value":"',
    //             Strings.toString(prop.dtrait.skill5),
    //             '"},'
    //         );
    //     }

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"skill 6","value":"',
    //             Strings.toString(prop.dtrait.skill6),
    //             '"},',
    //             '{"trait_type":"Talent:RunawayRunner","value":"',
    //             Strings.toString(prop.dtrait.talent_rr),
    //             '"},',
    //             '{"trait_type":"Talent:FrontRunner","value":"',
    //             Strings.toString(prop.dtrait.talent_fr),
    //             '"},',
    //             '{"trait_type":"Talent:Stalker","value":"',
    //             Strings.toString(prop.dtrait.talent_st),
    //             '"},',
    //             '{"trait_type":"Talent:StretchRunner","value":"',
    //             Strings.toString(prop.dtrait.talent_sr),
    //             '"},'
    //         );
    //     }

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"Track:Turf","value":"',
    //             Strings.toString(prop.dtrait.track_perf_turf),
    //             '"},',
    //             '{"trait_type":"Track:Dirt","value":"',
    //             Strings.toString(prop.dtrait.track_perf_dirt),
    //             '"},',
    //             '{"trait_type":"torso_color","value":"',
    //             dsData.getColor(
    //                 prop.bpf.torso_colorgroup,
    //                 prop.bpf.torso_colorid
    //             ),
    //             '"},'
    //         );
    //     }

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"eyes_color","value":"',
    //             dsData.getColor(
    //                 prop.bpf.eyes_colorgroup,
    //                 prop.bpf.eyes_colorid
    //             ),
    //             '"},',
    //             '{"trait_type":"mane_color","value":"',
    //             dsData.getColor(
    //                 prop.bpf.mane_colorgroup,
    //                 prop.bpf.mane_colorid
    //             ),
    //             '"},',
    //             '{"trait_type":"horn_color","value":"',
    //             dsData.getColor(
    //                 prop.bpf.horn_colorgroup,
    //                 prop.bpf.horn_colorid
    //             ),
    //             '"},',
    //             '{"trait_type":"legs_color","value":"',
    //             dsData.getColor(
    //                 prop.bps.legs_colorgroup,
    //                 prop.bps.legs_colorid
    //             ),
    //             '"},'
    //         );
    //     }

    //     {
    //         metadata = abi.encodePacked(
    //             metadata,
    //             '{"trait_type":"muzzle_color","value":"',
    //             dsData.getColor(
    //                 prop.bps.muzzle_colorgroup,
    //                 prop.bps.muzzle_colorid
    //             ),
    //             '"},',
    //             '{"trait_type":"rein_color","value":"',
    //             dsData.getColor(
    //                 prop.bps.rein_colorgroup,
    //                 prop.bps.rein_colorid
    //             ),
    //             '"},',
    //             '{"trait_type":"tail_color","value":"',
    //             dsData.getColor(
    //                 prop.bps.tail_colorgroup,
    //                 prop.bps.tail_colorid
    //             ),
    //             '"},',
    //             '{"trait_type":"wings_color","value":"',
    //             dsData.getColor(
    //                 prop.bps.wings_colorgroup,
    //                 prop.bps.wings_colorid
    //             ),
    //             '"}'
    //         );
    //     }

    //     for (uint256 i = 0; i < addPropKeys.length; i += 1) {
    //         string memory key = addPropKeys[i];
    //         // TODO : if addPropVal[i][keccak256(abi.encodePacked(key))] not exists?
    //         metadata = abi.encodePacked(
    //             metadata,
    //             ',{"trait_type":"',
    //             key,
    //             '","value":"',
    //             addPropVal[i][keccak256(abi.encodePacked(key))],
    //             '"}'
    //         );
    //     }

    //     // TODO : imgae
    //     metadata = abi.encodePacked(
    //         metadata,
    //         '],"image":"',
    //         //externalImgUri,
    //         '"}'
    //     );

    //     return string(metadata);
    // }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IDerbyStarsData {
    struct SkillSet {
        uint256 tier;
        uint256[] ids;
    }

    struct Skill {
        uint256 tier;
        uint256 id;
    }

    struct BodyPartRarityGroup {
        uint256 rarity;
        uint256[] ids;
    }

    struct BodyPart {
        uint256 id;
        uint256 rarity;
    }

    function addTraitFamily(string[] calldata _familynames) external;

    function addTrait(
        string calldata _familyname,
        uint256[] calldata _ids,
        string[] calldata _vals
    ) external;

    function addColorGroup(string[] calldata _colorgroups, uint256 part)
        external;

    function addColor(uint256 _colorgroupid, string[] calldata _colors)
        external;

    function addSpecialSkills(Skill[] memory _skills, SkillSet[] memory _skillSets)
        external;

    function addNormalSkills(Skill[] memory _skills, SkillSet[] memory _skillSets)
        external;

    function addBodyPartTypes(uint256 _bodyPartType, BodyPartRarityGroup[] memory _groups) external;

    function addBodyParts(BodyPart[] memory _bodyParts) external;

    function getTrait(string calldata _familyname, uint256 _id)
        external
        view
        returns (string memory);

    function getColor(uint256 _colorgroupid, uint256 _id)
        external
        view
        returns (string memory);

    function getColorGroups(uint256 part)
        external
        view
        returns (uint256[] memory);

    function getColorsLength(uint256 _colorgroupid) external view returns (uint256);

    function getSpecialSkillTier(uint256 _id) external view returns (uint256);

    function getSpecialSkillIds(uint256 _tier) external view returns (uint256[] memory);

    function getNormalSkillTier(uint256 _id) external view returns (uint256);

    function getNormalSkillIds(uint256 _tier) external view returns (uint256[] memory);

    function getBodyPartRarityGroupIds(uint256 _bodyPartType, uint256 _rarity) external view returns (uint256[] memory);

    function getBodyPartRarity(uint256 _bodyPartId) external view returns (uint256);

    function setBreedingFee(uint256 _type, uint256[] calldata _fees) external;
    
    function modifyBreedingFee(uint256 _type, uint256 _tier, uint256 _fee) external;

    function getBreedingFee(uint256 _type, uint256 _tier) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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