// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IStatController.sol";

interface IHero {

  struct TokenTreasury {
    address token;
    uint amount;
  }

  function attributes(uint tokenId) external view returns (uint[] memory);

  function lastFightTs(uint tokenId) external view returns (uint);

  function heroBiome(uint tokenId) external view returns (uint);

  function stats(uint tokenId) external view returns (IStatController.ChangeableStats memory);

  function currentDungeon(uint tokenId) external view returns (address);

  function isOwner(address account, uint256 tokenId) external view returns (bool);

  function isHero() external view returns (bool);

  function payToken() external view returns (address);

  function payTokenAmount() external view returns (uint);

  function heroClass() external view returns (uint);

  function score(uint tokenId) external view returns (uint);

  function heroReinforcementHelp(uint tokenId) external view returns (address heroToken, uint heroId);

  function isReadyToFight(uint tokenId) external view returns (bool);

  function isAlive(uint tokenId) external view returns (bool);

  function create(string memory name) external returns (uint);

  function kill(uint heroId) external returns (IStatController.NftItem[] memory dropItems, uint dropTokenAmount);

  function levelUp(uint tokenId, IStatController.CoreAttributes memory change) external;

  function reduceDurability(uint heroId, uint dungeonLevel) external;

  function changeCurrentDungeon(uint tokenId, address dungeon) external;

  function refreshLastFight(uint tokenId) external;

  function changeCurrentStats(
    uint tokenId,
    IStatController.ChangeableStats memory change,
    bool increase
  ) external;

  function tokenTreasures(uint tokenId) external view returns (uint);

  function releaseReinforcement(uint heroId) external returns (address helperToken, uint helperId);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IStatController {

  enum ATTRIBUTES {
    // core
    STRENGTH, // 0
    DEXTERITY, // 1
    VITALITY, // 2
    ENERGY, // 3
    // attributes
    DAMAGE_MIN, // 4
    DAMAGE_MAX, // 5
    ATTACK_RATING, // 6
    DEFENSE, // 7
    BLOCK_RATING, // 8
    LIFE, // 9
    MANA, // 10
    // resistance
    FIRE_RESISTANCE, // 11
    COLD_RESISTANCE, // 12
    LIGHTNING_RESISTANCE, // 13
    // dmg against
    DMG_AGAINST_HUMAN, // 14
    DMG_AGAINST_UNDEAD, // 15
    DMG_AGAINST_DAEMON, // 16
    DMG_AGAINST_BEAST, // 17

    // defence against
    DEF_AGAINST_HUMAN, // 18
    DEF_AGAINST_UNDEAD, // 19
    DEF_AGAINST_DAEMON, // 20
    DEF_AGAINST_BEAST, // 21

    // --- unique, not augmentable
    // hero will not die until have positive chances
    LIFE_CHANCES, // 22
    // increase chance to get an item
    MAGIC_FIND, // 23
    // decrease chance to get an item
    DESTROY_ITEMS, // 24
    // percent of chance x2 dmg
    CRITICAL_HIT, // 25
    // dmg factors
    MELEE_DMG_FACTOR, // 26
    FIRE_DMG_FACTOR, // 27
    COLD_DMG_FACTOR, // 28
    LIGHTNING_DMG_FACTOR, // 29
    // increase attack rating on given percent
    AR_FACTOR, // 30
    // percent of damage will be converted to HP
    LIFE_STOLEN_PER_HIT, // 31
    // amount of mana restored after each battle
    MANA_AFTER_KILL, // 32
    // reduce all damage on percent after all other reductions
    DAMAGE_REDUCTION, // 33

    // -- statuses
    // chance to stun an enemy, stunned enemy skip next hit
    STUN, // 34
    // chance burn an enemy, burned enemy will loss 50% of defence
    BURN, // 35
    // chance freeze an enemy, frozen enemy will loss 50% of MELEE damage
    FREEZE, // 36
    // chance to reduce enemy's attack rating on 50%
    CONFUSE, // 37
    // chance curse an enemy, cursed enemy will loss 50% of resistance
    CURSE, // 38
    // percent of dmg return to attacker
    REFLECT_DAMAGE_MELEE, // 39
    REFLECT_DAMAGE_MAGIC, // 40
    // chance to poison enemy, poisoned enemy will loss 10% of the current health
    POISON, // 41
    // reduce chance get any of uniq statuses
    RESIST_TO_STATUSES, // 42

    END_SLOT // 46
  }

  // possible
  // HEAL_FACTOR

  struct CoreAttributes {
    uint strength;
    uint dexterity;
    uint vitality;
    uint energy;
  }

  struct ChangeableStats {
    uint level;
    uint experience;
    uint life;
    uint mana;
    uint lifeChances;
  }

  enum MagicAttackType {
    UNKNOWN, // 0
    FIRE, // 1
    COLD, // 2
    LIGHTNING, // 3
    CHAOS // 4
  }

  struct MagicAttack {
    MagicAttackType aType;
    uint min;
    uint max;
    // if not zero - activate attribute factor for the attribute
    CoreAttributes attributeFactors;
    uint manaConsume;
  }

  enum ItemSlots {
    UNKNOWN, // 0
    HEAD, // 1
    BODY, // 2
    GLOVES, // 3
    BELT, // 4
    AMULET, // 5
    BOOTS, // 6
    RIGHT_RING, // 7
    LEFT_RING, // 8
    RIGHT_HAND, // 9
    LEFT_HAND, // 10
    TWO_HAND, // 11
    SKILL_1, // 12
    SKILL_2, // 13
    SKILL_3, // 14
    END_SLOT // 15
  }

  struct NftItem {
    address token;
    uint tokenId;
  }

  enum Race {
    UNKNOWN, // 0
    HUMAN, // 1
    UNDEAD, // 2
    DAEMON, // 3
    BEAST, // 4
    SLOT_5, // 5
    SLOT_6, // 6
    SLOT_7, // 7
    SLOT_8, // 8
    SLOT_9, // 9
    SLOT_10 // 10
  }

  struct ChangeAttributesInfo {
    address heroToken;
    uint heroTokenId;
    uint[] changeAttributes;
    bool increase;
    bool temporally;
  }

  struct BuffInfo {
    address heroToken;
    uint heroTokenId;
    uint heroLevel;
    address[] buffTokens;
    uint[] buffTokenIds;
  }

  function initNewHero(address token, uint tokenId, uint heroClass) external;

  function heroAttributes(address token, uint tokenId) external view returns (uint[] memory);

  function heroAttribute(address token, uint tokenId, uint index) external view returns (uint);

  function heroAttributesLength(address token, uint tokenId) external view returns (uint);

  function heroBaseAttributes(address token, uint tokenId) external view returns (CoreAttributes memory);

  function heroCustomData(address token, uint tokenId, bytes32 index) external view returns (uint);

  function globalCustomData(bytes32 index) external view returns (uint);

  function heroStats(address token, uint tokenId) external view returns (ChangeableStats memory);

  function heroItemSlot(address token, uint tokenId, uint itemSlot) external view returns (NftItem memory);

  function heroItemSlots(address heroToken, uint heroTokenId) external view returns (uint[] memory);

  function isHeroAlive(address heroToken, uint heroTokenId) external view returns (bool);

  function levelUp(address token, uint tokenId, uint heroClass, CoreAttributes memory change) external;

  function changeHeroItemSlot(
    address heroToken,
    uint heroTokenId,
    uint itemType,
    uint itemSlot,
    address itemToken,
    uint itemTokenId,
    bool equip
  ) external;

  function changeCurrentStats(
    address token,
    uint tokenId,
    ChangeableStats memory change,
    bool increase
  ) external;

  function changeBonusAttributes(ChangeAttributesInfo memory info) external;

  function registerConsumableUsage(address heroToken, uint heroTokenId, address item) external;

  function clearUsedConsumables(address heroToken, uint heroTokenId) external;

  function clearTemporallyAttributes(address heroToken, uint heroTokenId) external;

  function buffHero(BuffInfo memory info) external view returns (uint[] memory attributes, uint manaConsumed);

  function generateMonsterAttributes(
    uint[] memory ids,
    uint[] memory values,
    uint amplifier,
    uint dungeonMultiplier,
    uint baseExperience
  ) external pure returns (uint[] memory attributes, uint experience);

  function setHeroCustomData(address token, uint tokenId, bytes32 index, uint value) external;

  function setGlobalCustomData(bytes32 index, uint value) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library CalcLib {

  function toUint(int n) internal pure returns (uint) {
    if (n < 0) {
      return 0;
    }
    return uint(n);
  }

  /// @dev Simplified pseudo-random for minor functionality
  function pseudoRandom(uint maxValue) internal view returns (uint) {
    if (maxValue == 0) {
      return 0;
    }
    // pseudo random number
    return (uint(keccak256(abi.encodePacked(blockhash(block.number), block.coinbase, block.difficulty, block.number, block.timestamp, tx.gasprice, gasleft()))) % (maxValue + 1));
  }

  /// @dev Simplified pseudo-random for minor functionality, in range
  function pseudoRandomInRange(uint min, uint max) internal view returns (uint) {
    if (min >= max) {
      return max;
    }
    uint r = pseudoRandom(max - min);
    return min + r;
  }

  function minusWithZeroFloor(uint a, uint b) internal pure returns (uint){
    if (a <= b) {
      return 0;
    }
    return a - b;
  }

  function sqrt(uint x) internal pure returns (uint z) {
    assembly {
    // Start off with z at 1.
      z := 1

    // Used below to help find a nearby power of 2.
      let y := x

    // Find the lowest power of 2 that is at least sqrt(x).
      if iszero(lt(y, 0x100000000000000000000000000000000)) {
        y := shr(128, y) // Like dividing by 2 ** 128.
        z := shl(64, z) // Like multiplying by 2 ** 64.
      }
      if iszero(lt(y, 0x10000000000000000)) {
        y := shr(64, y) // Like dividing by 2 ** 64.
        z := shl(32, z) // Like multiplying by 2 ** 32.
      }
      if iszero(lt(y, 0x100000000)) {
        y := shr(32, y) // Like dividing by 2 ** 32.
        z := shl(16, z) // Like multiplying by 2 ** 16.
      }
      if iszero(lt(y, 0x10000)) {
        y := shr(16, y) // Like dividing by 2 ** 16.
        z := shl(8, z) // Like multiplying by 2 ** 8.
      }
      if iszero(lt(y, 0x100)) {
        y := shr(8, y) // Like dividing by 2 ** 8.
        z := shl(4, z) // Like multiplying by 2 ** 4.
      }
      if iszero(lt(y, 0x10)) {
        y := shr(4, y) // Like dividing by 2 ** 4.
        z := shl(2, z) // Like multiplying by 2 ** 2.
      }
      if iszero(lt(y, 0x8)) {
      // Equivalent to 2 ** z.
        z := shl(1, z)
      }

    // Shifting right by 1 is like dividing by 2.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

    // Compute a rounded down version of z.
      let zRoundDown := div(x, z)

    // If zRoundDown is smaller, use it.
      if lt(zRoundDown, z) {
        z := zRoundDown
      }
    }
  }

  /*********************************************
 *              PRB-MATH                      *
 *   https://github.com/hifi-finance/prb-math *
 **********************************************/

  /// @notice Calculates the binary logarithm of x.
  ///
  /// @dev Based on the iterative approximation algorithm.
  /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
  ///
  /// Requirements:
  /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
  ///
  /// Caveats:
  /// - The results are nor perfectly accurate to the last decimal,
  ///   due to the lossy precision of the iterative approximation.
  ///
  /// @param x The unsigned 60.18-decimal fixed-point number for which
  ///           to calculate the binary logarithm.
  /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
  function log2(uint256 x) internal pure returns (uint256 result) {
    require(x >= 1e18, "x too low");

    // Calculate the integer part of the logarithm
    // and add it to the result and finally calculate y = x * 2^(-n).
    uint256 n = mostSignificantBit(x / 1e18);

    // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number.
    // The operation can't overflow because n is maximum 255 and SCALE is 1e18.
    uint256 rValue = n * 1e18;

    // This is y = x * 2^(-n).
    uint256 y = x >> n;

    // If y = 1, the fractional part is zero.
    if (y == 1e18) {
      return rValue;
    }

    // Calculate the fractional part via the iterative approximation.
    // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
    for (uint256 delta = 5e17; delta > 0; delta >>= 1) {
      y = (y * y) / 1e18;

      // Is y^2 > 2 and so in the range [2,4)?
      if (y >= 2 * 1e18) {
        // Add the 2^(-m) factor to the logarithm.
        rValue += delta;

        // Corresponds to z/2 on Wikipedia.
        y >>= 1;
      }
    }
    return rValue;
  }

  /// @notice Finds the zero-based index of the first one in the binary representation of x.
  /// @dev See the note on msb in the "Find First Set"
  ///      Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
  /// @param x The uint256 number for which to find the index of the most significant bit.
  /// @return msb The index of the most significant bit as an uint256.
  //noinspection NoReturn
  function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
    if (x >= 2 ** 128) {
      x >>= 128;
      msb += 128;
    }
    if (x >= 2 ** 64) {
      x >>= 64;
      msb += 64;
    }
    if (x >= 2 ** 32) {
      x >>= 32;
      msb += 32;
    }
    if (x >= 2 ** 16) {
      x >>= 16;
      msb += 16;
    }
    if (x >= 2 ** 8) {
      x >>= 8;
      msb += 8;
    }
    if (x >= 2 ** 4) {
      x >>= 4;
      msb += 4;
    }
    if (x >= 2 ** 2) {
      x >>= 2;
      msb += 2;
    }
    if (x >= 2 ** 1) {
      // No need to shift x any more.
      msb += 1;
    }
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IStatController.sol";
import "../interfaces/IHero.sol";
import "../openzeppelin/Math.sol";
import "./CalcLib.sol";
import "../openzeppelin/EnumerableMap.sol";
import "./StructLib.sol";

library StatLib {
  using StructLib for EnumerableMap.UintToIntMap;
  using EnumerableMap for EnumerableMap.UintToIntMap;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant STAT_LIB_VERSION = "1.0.0";
  uint public constant MAX_LEVEL = 99;
  uint public constant BASE_EXPERIENCE = 100_000;
  uint public constant BIOME_LEVEL_STEP = 5;
  uint internal constant _MAX_AMPLIFIER = 1e18;

  struct BaseMultiplier {
    uint minDamage;
    uint maxDamage;
    uint attackRating;
    uint defense;
    uint blockRating;
    uint life;
    uint mana;
  }

  struct LevelUp {
    uint life;
    uint mana;
  }

  struct InitialHero {
    IStatController.CoreAttributes core;
    BaseMultiplier multiplier;
    LevelUp levelUp;
    uint baseLifeChances;
  }

  uint private constant _PRECISION = 1e18;

  // --------- BASE -----------

  // --- HERO 1 (Slave) ---

  function initialHero1() internal pure returns (InitialHero memory) {
    return InitialHero({
    core : IStatController.CoreAttributes({
    strength : 15,
    dexterity : 15,
    vitality : 30,
    energy : 10
    }),

    multiplier : BaseMultiplier({
    minDamage : 0.1e18,
    maxDamage : 0.2e18,
    attackRating : 2e18,
    defense : 2e18,
    blockRating : 0.1e18,
    life : 1.5e18,
    mana : 0.5e18
    }),

    levelUp : LevelUp({
    life : 2e18,
    mana : 1e18
    }),

    baseLifeChances : 5
    });
  }

  // --- HERO 2 (Spata) ---

  function initialHero2() internal pure returns (InitialHero memory) {
    return InitialHero({
    core : IStatController.CoreAttributes({
    strength : 30,
    dexterity : 5,
    vitality : 25,
    energy : 10
    }),

    multiplier : BaseMultiplier({
    minDamage : 0.15e18,
    maxDamage : 0.25e18,
    attackRating : 2e18,
    defense : 1e18,
    blockRating : 0.08e18,
    life : 1.3e18,
    mana : 0.5e18
    }),

    levelUp : LevelUp({
    life : 1.8e18,
    mana : 1e18
    }),

    baseLifeChances : 5
    });
  }

  // --- HERO 3 (Decidia) ---

  function initialHero3() internal pure returns (InitialHero memory) {
    return InitialHero({
    core : IStatController.CoreAttributes({
    strength : 10,
    dexterity : 15,
    vitality : 20,
    energy : 25
    }),

    multiplier : BaseMultiplier({
    minDamage : 0.1e18,
    maxDamage : 0.2e18,
    attackRating : 2e18,
    defense : 1e18,
    blockRating : 0.1e18,
    life : 1e18,
    mana : 2e18
    }),

    levelUp : LevelUp({
    life : 1.3e18,
    mana : 2e18
    }),

    baseLifeChances : 5
    });
  }

  // --- HERO 4 (Innatus) ---

  function initialHero4() internal pure returns (InitialHero memory) {
    return InitialHero({
    core : IStatController.CoreAttributes({
    strength : 15,
    dexterity : 25,
    vitality : 15,
    energy : 15
    }),

    multiplier : BaseMultiplier({
    minDamage : 0.1e18,
    maxDamage : 0.2e18,
    attackRating : 4e18,
    defense : 3e18,
    blockRating : 0.2e18,
    life : 1.2e18,
    mana : 1e18
    }),

    levelUp : LevelUp({
    life : 1.7e18,
    mana : 1.5e18
    }),

    baseLifeChances : 5
    });
  }

  // ------

  function initialHero(uint heroClass) internal pure returns (InitialHero memory) {
    if (heroClass == 1) {
      return initialHero1();
    } else if (heroClass == 2) {
      return initialHero2();
    } else if (heroClass == 3) {
      return initialHero3();
    } else if (heroClass == 4) {
      return initialHero4();
    } else {
      revert("Unknown class");
    }
  }

  // --------- CALCULATIONS -----------

  function minDamage(uint strength, uint heroClass) internal pure returns (uint){
    return strength * initialHero(heroClass).multiplier.minDamage / _PRECISION;
  }

  function maxDamage(uint strength, uint heroClass) internal pure returns (uint){
    return strength * initialHero(heroClass).multiplier.maxDamage / _PRECISION;
  }

  function attackRating(uint dexterity, uint heroClass) internal pure returns (uint){
    return dexterity * initialHero(heroClass).multiplier.attackRating / _PRECISION;
  }

  function defense(uint dexterity, uint heroClass) internal pure returns (uint){
    return dexterity * initialHero(heroClass).multiplier.defense / _PRECISION;
  }

  function blockRating(uint dexterity, uint heroClass) internal pure returns (uint){
    return Math.min((dexterity * initialHero(heroClass).multiplier.blockRating / _PRECISION), 75);
  }

  function life(uint vitality, uint heroClass, uint level) internal pure returns (uint){
    return (vitality * initialHero(heroClass).multiplier.life / _PRECISION)
    + (level * initialHero(heroClass).levelUp.life / _PRECISION);
  }

  function mana(uint energy, uint heroClass, uint level) internal pure returns (uint){
    return (energy * initialHero(heroClass).multiplier.mana / _PRECISION)
    + (level * initialHero(heroClass).levelUp.mana / _PRECISION);
  }

  function lifeChances(uint heroClass, uint level) internal pure returns (uint){
    return initialHero(heroClass).baseLifeChances + (level / 49);
  }

  function levelExperience(uint level) internal pure returns (uint) {
    if (level == 0 || level >= MAX_LEVEL) {
      return 0;
    }
    return level * BASE_EXPERIENCE * (67e17 - CalcLib.log2((MAX_LEVEL - level + 2) * 1e18)) / 1e18;
  }

  function chanceToHit(
    uint attackersAttackRating,
    uint defendersDefenceRating,
    uint attackersLevel,
    uint defendersLevel,
    uint arFactor
  ) internal pure returns (uint) {
    attackersAttackRating += attackersAttackRating * arFactor / 100;
    uint dividerForLowLevel = 1;
    // first 5 levels we are reducing defender level impact
    if (attackersLevel < 5) {
      dividerForLowLevel = 10 - (attackersLevel * 2);
    }
    uint base = (2
    * (Math.max(attackersAttackRating, 1) * 1e18 / Math.max(attackersAttackRating + defendersDefenceRating, 1))
    * (attackersLevel * 1e18 / (attackersLevel + (defendersLevel / dividerForLowLevel)))
    / 1e18);
    return Math.max(Math.min(base, 95e17), 5e16);
  }

  function experienceToLvl(uint experience, uint startFromLevel) internal pure returns (uint level) {
    level = startFromLevel;
    for (; level < MAX_LEVEL;) {
      if (levelExperience(level) >= experience) {
        break;
      }
    unchecked{++level;}
    }
  }

  function expPerMonster(uint monsterExp, uint monsterRarity, uint heroExp, uint heroCurrentLvl, uint monsterBiome) internal pure returns (uint) {
    uint heroLvl = experienceToLvl(heroExp, heroCurrentLvl);
    uint heroBiome = heroLvl / StatLib.BIOME_LEVEL_STEP + 1;
    uint base = monsterExp + monsterExp * monsterRarity / _MAX_AMPLIFIER;

    // reduce exp if hero not in his biome
    if (heroBiome > monsterBiome) {
      base = base / (2 ** (heroBiome - monsterBiome));
    }
    return base;
  }

  function amplify(uint value, uint amplifier, uint dungeonMultiplier) internal pure returns (uint) {
    if (value == 0) {
      return 0;
    }
    return value + (value * amplifier / _MAX_AMPLIFIER) + (value * dungeonMultiplier / _MAX_AMPLIFIER);
  }

  function mintDropChance(uint baseChance, uint monsterRarity, uint monsterBiome, uint heroExp, uint heroCurrentLvl) internal pure returns (uint) {
    uint heroLvl = StatLib.experienceToLvl(heroExp, heroCurrentLvl);
    uint heroBiome = heroLvl / StatLib.BIOME_LEVEL_STEP + 1;
    uint chance = baseChance + baseChance * monsterRarity / _MAX_AMPLIFIER;

    // reduce chance if hero not in his biome
    if (heroBiome > monsterBiome) {
      chance = chance / (2 ** (heroBiome - monsterBiome));
    }
    return chance;
  }

  function isCoreAttribute(uint index) internal pure returns (bool) {
    return
    uint(IStatController.ATTRIBUTES.STRENGTH) == index
    || uint(IStatController.ATTRIBUTES.DEXTERITY) == index
    || uint(IStatController.ATTRIBUTES.VITALITY) == index
    || uint(IStatController.ATTRIBUTES.ENERGY) == index;

  }

  function initAttributes(
    EnumerableMap.UintToIntMap storage attributes,
    uint heroClass,
    uint level,
    IStatController.CoreAttributes memory base
  ) internal {

    attributes.setUint(uint(IStatController.ATTRIBUTES.STRENGTH), base.strength);
    attributes.setUint(uint(IStatController.ATTRIBUTES.DEXTERITY), base.dexterity);
    attributes.setUint(uint(IStatController.ATTRIBUTES.VITALITY), base.vitality);
    attributes.setUint(uint(IStatController.ATTRIBUTES.ENERGY), base.energy);

    attributes.setUint(uint(IStatController.ATTRIBUTES.DAMAGE_MIN), minDamage(base.strength, heroClass));
    attributes.setUint(uint(IStatController.ATTRIBUTES.DAMAGE_MAX), maxDamage(base.strength, heroClass));
    attributes.setUint(uint(IStatController.ATTRIBUTES.ATTACK_RATING), attackRating(base.dexterity, heroClass));
    attributes.setUint(uint(IStatController.ATTRIBUTES.DEFENSE), defense(base.dexterity, heroClass));
    attributes.setUint(uint(IStatController.ATTRIBUTES.BLOCK_RATING), blockRating(base.dexterity, heroClass));
    attributes.setUint(uint(IStatController.ATTRIBUTES.LIFE), life(base.vitality, heroClass, level));
    attributes.setUint(uint(IStatController.ATTRIBUTES.MANA), mana(base.energy, heroClass, level));
    attributes.setUint(uint(IStatController.ATTRIBUTES.LIFE_CHANCES), lifeChances(heroClass, level));
  }

  function updateCoreDependAttributesInMemory(uint[] memory attributes, uint[] memory bonus, uint heroClass, uint level) internal pure returns (uint[] memory) {
    uint strength = attributes[uint(IStatController.ATTRIBUTES.STRENGTH)];
    uint dexterity = attributes[uint(IStatController.ATTRIBUTES.DEXTERITY)];
    uint vitality = attributes[uint(IStatController.ATTRIBUTES.VITALITY)];
    uint energy = attributes[uint(IStatController.ATTRIBUTES.ENERGY)];

    attributes[uint(IStatController.ATTRIBUTES.DAMAGE_MIN)] = minDamage(strength, heroClass) + bonus[uint(IStatController.ATTRIBUTES.DAMAGE_MIN)];
    attributes[uint(IStatController.ATTRIBUTES.DAMAGE_MAX)] = maxDamage(strength, heroClass) + bonus[uint(IStatController.ATTRIBUTES.DAMAGE_MAX)];
    attributes[uint(IStatController.ATTRIBUTES.ATTACK_RATING)] = attackRating(dexterity, heroClass) + bonus[uint(IStatController.ATTRIBUTES.ATTACK_RATING)];
    attributes[uint(IStatController.ATTRIBUTES.DEFENSE)] = defense(dexterity, heroClass) + bonus[uint(IStatController.ATTRIBUTES.DEFENSE)];
    attributes[uint(IStatController.ATTRIBUTES.BLOCK_RATING)] = blockRating(dexterity, heroClass) + bonus[uint(IStatController.ATTRIBUTES.BLOCK_RATING)];
    attributes[uint(IStatController.ATTRIBUTES.LIFE)] = life(vitality, heroClass, level) + bonus[uint(IStatController.ATTRIBUTES.LIFE)];
    attributes[uint(IStatController.ATTRIBUTES.MANA)] = mana(energy, heroClass, level) + bonus[uint(IStatController.ATTRIBUTES.MANA)];
    return attributes;
  }

  function updateCoreDependAttributes(
    EnumerableMap.UintToIntMap storage attributes,
    EnumerableMap.UintToIntMap storage bonusMain,
    EnumerableMap.UintToIntMap storage bonusExtra,
    IStatController.ChangeableStats storage _heroStats,
    uint index,
    address heroToken,
    uint base
  ) internal {
    if (index == uint(IStatController.ATTRIBUTES.STRENGTH)) {
      uint heroClass = IHero(heroToken).heroClass();

      attributes.setUint(uint(IStatController.ATTRIBUTES.DAMAGE_MIN),
        StatLib.minDamage(base, heroClass)
        + bonusMain.getOrZeroA(IStatController.ATTRIBUTES.DAMAGE_MIN)
        + bonusExtra.getOrZeroA(IStatController.ATTRIBUTES.DAMAGE_MIN)
      );
      attributes.setUint(uint(IStatController.ATTRIBUTES.DAMAGE_MAX),
        StatLib.maxDamage(base, heroClass)
        + bonusMain.getOrZeroA(IStatController.ATTRIBUTES.DAMAGE_MAX)
        + bonusExtra.getOrZeroA(IStatController.ATTRIBUTES.DAMAGE_MAX)
      );
    } else if (index == uint(IStatController.ATTRIBUTES.DEXTERITY)) {
      uint heroClass = IHero(heroToken).heroClass();

      attributes.setUint(uint(IStatController.ATTRIBUTES.ATTACK_RATING),
        StatLib.attackRating(base, heroClass)
        + bonusMain.getOrZeroA(IStatController.ATTRIBUTES.ATTACK_RATING)
        + bonusExtra.getOrZeroA(IStatController.ATTRIBUTES.ATTACK_RATING)
      );

      attributes.setUint(uint(IStatController.ATTRIBUTES.DEFENSE),
        StatLib.defense(base, heroClass)
        + bonusMain.getOrZeroA(IStatController.ATTRIBUTES.DEFENSE)
        + bonusExtra.getOrZeroA(IStatController.ATTRIBUTES.DEFENSE)
      );

      attributes.setUint(uint(IStatController.ATTRIBUTES.BLOCK_RATING),
        StatLib.blockRating(base, heroClass)
        + bonusMain.getOrZeroA(IStatController.ATTRIBUTES.BLOCK_RATING)
        + bonusExtra.getOrZeroA(IStatController.ATTRIBUTES.BLOCK_RATING)
      );
    } else if (index == uint(IStatController.ATTRIBUTES.VITALITY)) {
      uint heroClass = IHero(heroToken).heroClass();
      uint level = _heroStats.level;

      attributes.setUint(uint(IStatController.ATTRIBUTES.LIFE),
        StatLib.life(base, heroClass, level)
        + bonusMain.getOrZeroA(IStatController.ATTRIBUTES.LIFE)
        + bonusExtra.getOrZeroA(IStatController.ATTRIBUTES.LIFE)
      );
    } else if (index == uint(IStatController.ATTRIBUTES.ENERGY)) {
      uint heroClass = IHero(heroToken).heroClass();
      uint level = _heroStats.level;

      attributes.setUint(uint(IStatController.ATTRIBUTES.MANA),
        StatLib.mana(base, heroClass, level)
        + bonusMain.getOrZeroA(IStatController.ATTRIBUTES.MANA)
        + bonusExtra.getOrZeroA(IStatController.ATTRIBUTES.MANA)
      );
    }
  }

  function attributesAdd(uint[] memory base, uint[] memory add) internal pure returns (uint[] memory) {
  unchecked{
    for (uint i; i < base.length; ++i) {
      base[i] += add[i];
    }
  }
    return base;
  }

  function attributesRemove(uint[] memory base, uint[] memory remove) internal pure returns (uint[] memory) {
  unchecked{
    for (uint i; i < base.length; ++i) {
      base[i] = CalcLib.minusWithZeroFloor(base[i], remove[i]);
    }
  }
    return base;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../openzeppelin/EnumerableMap.sol";
import "../interfaces/IStatController.sol";

library StructLib {
  using EnumerableMap for EnumerableMap.UintToIntMap;

  function flat(EnumerableMap.UintToIntMap storage map) internal view returns (uint[] memory){
  unchecked{
    uint length = map.length();
    uint[] memory values = new uint[](uint(IStatController.ATTRIBUTES.END_SLOT));
    for (uint i; i < length; ++i) {
      (uint index, int value) = map._at(i);
      if (value < 0) {
        value = 0;
      }
      values[index] = uint(value);
    }
    return values;
  }
  }

  function flatInt(EnumerableMap.UintToIntMap storage map) internal view returns (int[] memory){
  unchecked{
    uint length = map.length();
    int[] memory values = new int[](uint(IStatController.ATTRIBUTES.END_SLOT));
    for (uint i; i < length; ++i) {
      (uint index, int value) = map._at(i);
      values[index] = value;
    }
    return values;
  }
  }

  function getOrZeroA(EnumerableMap.UintToIntMap storage map, IStatController.ATTRIBUTES index) internal view returns (uint) {
    (,int value) = map.tryGet(uint(index));
    if (value < 0) {
      value = 0;
    }
    return uint(value);
  }

  function getOrZero(EnumerableMap.UintToIntMap storage map, uint index) internal view returns (uint) {
    (,int value) = map.tryGet(index);
    if (value < 0) {
      value = 0;
    }
    return uint(value);
  }

  function getOrZeroInt(EnumerableMap.UintToIntMap storage map, uint index) internal view returns (int) {
    (,int value) = map.tryGet(index);
    return value;
  }

  function increment(EnumerableMap.UintToIntMap storage map, uint index, uint value) internal returns (uint) {
    (,int oldValue) = map.tryGet(index);
    int newValue = oldValue + int(value);
    map._set(index, newValue);
    return uint(newValue);
  }

  function decrement(EnumerableMap.UintToIntMap storage map, uint index, int value) internal returns (int) {
    (,int oldValue) = map.tryGet(index);
    int newValue = oldValue - int(value);
    if (newValue == 0) {
      map.remove(index);
    } else {
      map._set(index, newValue);
    }

    return newValue;
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Map type with
  // bytes32 keys and values.
  // The Map implementation uses private functions, and user-facing
  // implementations (such as Uint256ToAddressMap) are just wrappers around
  // the underlying Map.
  // This means that we can only create new EnumerableMaps for types that fit
  // in bytes32.

  struct Bytes32ToBytes32Map {
    // Storage of keys
    EnumerableSet.Bytes32Set _keys;
    mapping(bytes32 => bytes32) _values;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    Bytes32ToBytes32Map storage map,
    bytes32 key,
    bytes32 value
  ) internal returns (bool) {
    map._values[key] = value;
    return map._keys.add(key);
  }

  /**
   * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
    delete map._values[key];
    return map._keys.remove(key);
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
    return map._keys.contains(key);
  }

  /**
   * @dev Returns the number of key-value pairs in the map. O(1).
     */
  function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
    return map._keys.length();
  }

  /**
   * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
    bytes32 key = map._keys.at(index);
    return (key, map._values[key]);
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
    bytes32 value = map._values[key];
    if (value == bytes32(0)) {
      return (contains(map, key), bytes32(0));
    } else {
      return (true, value);
    }
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
    bytes32 value = map._values[key];
    require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
    return value;
  }

  /**
   * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
  function get(
    Bytes32ToBytes32Map storage map,
    bytes32 key,
    string memory errorMessage
  ) internal view returns (bytes32) {
    bytes32 value = map._values[key];
    require(value != 0 || contains(map, key), errorMessage);
    return value;
  }

  // UintToUintMap

  struct UintToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    UintToUintMap storage map,
    uint256 key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, bytes32(key), bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
    return remove(map._inner, bytes32(key));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
    return contains(map._inner, bytes32(key));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
     */
  function length(UintToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (uint256(key), uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(key)));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    UintToUintMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(key), errorMessage));
  }

  // UintToAddressMap

  struct UintToAddressMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    UintToAddressMap storage map,
    uint256 key,
    address value
  ) internal returns (bool) {
    return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
    return remove(map._inner, bytes32(key));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
    return contains(map._inner, bytes32(key));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
     */
  function length(UintToAddressMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (uint256(key), address(uint160(uint256(value))));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
    return (success, address(uint160(uint256(value))));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
    return address(uint160(uint256(get(map._inner, bytes32(key)))));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    UintToAddressMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (address) {
    return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
  }

  // AddressToUintMap

  struct AddressToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    AddressToUintMap storage map,
    address key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(AddressToUintMap storage map, address key) internal returns (bool) {
    return remove(map._inner, bytes32(uint256(uint160(key))));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
    return contains(map._inner, bytes32(uint256(uint160(key))));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
     */
  function length(AddressToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (address(uint160(uint256(key))), uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    AddressToUintMap storage map,
    address key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
  }

  // Bytes32ToUintMap

  struct Bytes32ToUintMap {
    Bytes32ToBytes32Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
  function set(
    Bytes32ToUintMap storage map,
    bytes32 key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, key, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
  function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
    return remove(map._inner, key);
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
     */
  function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
    return contains(map._inner, key);
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
     */
  function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (key, uint256(value));
  }

  /**
   * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
  function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
    (bool success, bytes32 value) = tryGet(map._inner, key);
    return (success, uint256(value));
  }

  /**
   * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
  function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
    return uint256(get(map._inner, key));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
  function get(
    Bytes32ToUintMap storage map,
    bytes32 key,
    string memory errorMessage
  ) internal view returns (uint256) {
    return uint256(get(map._inner, key, errorMessage));
  }

  //////////////////////////////////////////////////
  //          CUSTOM IMPLEMENTATIONS
  //////////////////////////////////////////////////

  // UintToIntMap
  // It is very specific custom structure specific for game mechanics.

  struct UintToIntMap {
    Bytes32ToBytes32Map _inner;
  }

  /// @dev Attention! Use it wisely, with properly checks.
  function _set(
    UintToIntMap storage map,
    uint256 key,
    int256 value
  ) internal returns (bool) {
    return set(map._inner, bytes32(key), bytes32(uint(value)));
  }

  function setUint(
    UintToIntMap storage map,
    uint256 key,
    uint256 value
  ) internal returns (bool) {
    return set(map._inner, bytes32(key), bytes32(value));
  }

  function remove(UintToIntMap storage map, uint256 key) internal returns (bool) {
    return remove(map._inner, bytes32(key));
  }

  function contains(UintToIntMap storage map, uint256 key) internal view returns (bool) {
    return contains(map._inner, bytes32(key));
  }

  function length(UintToIntMap storage map) internal view returns (uint256) {
    return length(map._inner);
  }

  function _at(UintToIntMap storage map, uint256 index) internal view returns (uint256, int256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    return (uint256(key), int256(uint(value)));
  }

  function atUint(UintToIntMap storage map, uint256 index) internal view returns (uint256, uint256) {
    (bytes32 key, bytes32 value) = at(map._inner, index);
    int _v = int256(uint(value));
    if (_v < 0) {
      _v = 0;
    }
    return (uint256(key), uint(_v));
  }

  function tryGet(UintToIntMap storage map, uint256 key) internal view returns (bool, int256) {
    (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
    return (success, int256(uint(value)));
  }

  function _get(UintToIntMap storage map, uint256 key) internal view returns (int256) {
    return int256(uint(get(map._inner, bytes32(key))));
  }

  function getUint(UintToIntMap storage map, uint256 key) internal view returns (uint256) {
    int value = int256(uint(get(map._inner, bytes32(key))));
    if (value < 0) {
      value = 0;
    }
    return uint(value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Set type with
  // bytes32 values.
  // The Set implementation uses private functions, and user-facing
  // implementations (such as AddressSet) are just wrappers around the
  // underlying Set.
  // This means that we can only create new EnumerableSets for types that fit
  // in bytes32.

  struct Set {
    // Storage of set values
    bytes32[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(bytes32 => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
  function _remove(Set storage set, bytes32 value) private returns (bool) {
    // We read and store the value's index to prevent multiple reads from the same storage slot
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      if (lastIndex != toDeleteIndex) {
        bytes32 lastValue = set._values[lastIndex];

        // Move the last value to the index where the value to delete is
        set._values[toDeleteIndex] = lastValue;
        // Update the index for the moved value
        set._indexes[lastValue] = valueIndex;
        // Replace lastValue's index to valueIndex
      }

      // Delete the slot where the moved value was stored
      set._values.pop();

      // Delete the index for the deleted slot
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
     */
  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values on the set. O(1).
     */
  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    return set._values[index];
  }

  /**
   * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
  function _values(Set storage set) private view returns (bytes32[] memory) {
    return set._values;
  }

  // Bytes32Set

  struct Bytes32Set {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
  function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
     */
  function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  /**
   * @dev Returns the number of values in the set. O(1).
     */
  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  /**
   * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
  function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
    bytes32[] memory store = _values(set._inner);
    bytes32[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
  }

  // AddressSet

  struct AddressSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
     */
  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns the number of values in the set. O(1).
     */
  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(AddressSet storage set, uint256 index) internal view returns (address) {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  /**
   * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
  function values(AddressSet storage set) internal view returns (address[] memory) {
    bytes32[] memory store = _values(set._inner);
    address[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
  }

  // UintSet

  struct UintSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
     */
  function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  /**
   * @dev Returns the number of values in the set. O(1).
     */
  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
  function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }

  /**
   * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
  function values(UintSet storage set) internal view returns (uint256[] memory) {
    bytes32[] memory store = _values(set._inner);
    uint256[] memory result;

    /// @solidity memory-safe-assembly
    assembly {
      result := store
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../lib/StatLib.sol";

contract StatReader {

  function chanceToHit(
    uint attackersAttackRating,
    uint defendersDefenceRating,
    uint attackersLevel,
    uint defendersLevel,
    uint arFactor
  ) external pure returns (uint) {
    return StatLib.chanceToHit(
      attackersAttackRating,
      defendersDefenceRating,
      attackersLevel,
      defendersLevel,
      arFactor
    );
  }

  function levelExperience(uint level) external pure returns (uint) {
    return StatLib.levelExperience(level);
  }

  function experienceToLvl(uint exp, uint startFromLevel) external pure returns (uint) {
    return StatLib.experienceToLvl(exp, startFromLevel);
  }

  function startHeroAttributes(uint heroClass) external pure returns (
    IStatController.CoreAttributes memory,
    StatLib.BaseMultiplier memory,
    StatLib.LevelUp memory
  ) {
    return (
    StatLib.initialHero(heroClass).core,
    StatLib.initialHero(heroClass).multiplier,
    StatLib.initialHero(heroClass).levelUp
    );
  }

}