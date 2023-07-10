// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IStatController.sol";

interface IAttackItem {

  struct GenerateAttackInfo {
    IStatController.MagicAttackType attackType;
    IStatController.CoreAttributes attributeFactors;
    uint damageMin;
    uint damageMax;
    uint manaConsumeMin;
    uint manaConsumeMax;
  }

  function attackAttributes(uint tokenId) external view returns (IStatController.MagicAttack memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IStatController.sol";

interface IBuffItem {

  function buff(uint tokenId)
  external view returns (uint[] memory casterBuff, uint[] memory casterDebuff, uint mana);

  function debuff(uint tokenId)
  external view returns (uint[] memory targetDebuff, uint[] memory targetBuff);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IFightCalculator.sol";

interface IChamber {

  struct ChamberMeta {
    uint biome;
    uint chamberType;
    string name;
    string symbol;
    string uri;
  }

  struct ChamberResult {
    address chamber;
    address heroToken;
    uint heroTokenId;
    bool kill;
    uint experience;
    uint heal;
    uint manaRegen;
    uint lifeChancesRecovered;
    uint damage;
    uint manaConsumed;
    address[] mintItems;
    bool completed;
    address rewriteNextChamber;
    uint iteration;  // should be rewrite in ChamberBase
  }

  function biome() external view returns (uint);

  function chamberType() external view returns (uint);

  function iterations(address heroAdr, uint heroId) external view returns (uint iteration);

  function IS_CHAMBER() external pure returns (bool);

  function open(address heroToken, uint heroTokenId) external returns (uint iteration);

  function action(address sender, address heroToken, uint heroTokenId, uint stageId, bytes memory data) external returns (ChamberResult memory);

  function isAvailableForHero(address heroToken, uint heroTokenId) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IChamberController {

  enum ChamberType {
    UNKNOWN_0, // 0
    ENEMY_NPC_1, // 1
    ENEMY_NPC_SUPER_RARE_2, // 2
    BOSS_3, // 3
    SHRINE_4, // 4
    CHEST_5, // 5
    STORY_6, // 6
    STORY_UNIQUE_7, // 7
    SHRINE_UNIQUE_8, // 8
    CHEST_UNIQUE_9, // 9
    ENEMY_NPC_UNIQUE_10, // 10
    STORY_ON_ROAD_11, // 11
    STORY_UNDERGROUND_12, // 12
    STORY_NIGHT_CAMP_13, // 13
    STORY_MOUNTAIN_14, // 14
    STORY_WATER_15, // 15
    STORY_CASTLE_16, // 16
    STORY_HELL_17, // 17
    STORY_SPACE_18, // 18
    STORY_WOOD_19, // 19
    STORY_CATACOMBS_20, // 20
    STORY_BAD_HOUSE_21, // 21
    STORY_GOOD_TOWN_22, // 22
    STORY_BAD_TOWN_23, // 23
    STORY_BANDIT_CAMP_24, // 24
    STORY_BEAST_LAIR_25, // 25
    STORY_PRISON_26, // 26
    STORY_SWAMP_27, // 27
    STORY_INSIDE_28, // 28
    STORY_OUTSIDE_29, // 29
    STORY_INSIDE_RARE_30,
    STORY_OUTSIDE_RARE_31,
    ENEMY_NPC_INSIDE_32,
    ENEMY_NPC_INSIDE_RARE_33,
    ENEMY_NPC_OUTSIDE_34,
    ENEMY_NPC_OUTSIDE_RARE_35,
    SLOT_36,
    SLOT_37,
    SLOT_38,
    SLOT_39,
    SLOT_40,
    SLOT_41,
    SLOT_42,
    SLOT_43,
    SLOT_44,
    SLOT_45,
    SLOT_46,
    SLOT_47,
    SLOT_48,
    SLOT_49,
    SLOT_50
  }

  function validChambers(address chamber) external view returns (bool);

  function chambersByTypeAndBiomeLevel(uint cType, uint biome, uint index) external view returns (address);

  function chambersByTypeAndBiomeLevelLength(uint cType, uint biome) external view returns (uint);

  function getRandomChamber(uint[] memory cTypes, uint[] memory chances, uint biomeLevel, address heroToken, uint heroTokenId) external returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IStatController.sol";

interface IConsumableItem {

  struct GenerateConsumableInfo {
    uint[] ids;
    uint[] values;
    bool[] increase;
  }

  function consumableAttributesAndStats(uint tokenId)
  external view returns (uint[] memory positive, uint[] memory negative, IStatController.ChangeableStats memory stats);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IController {

  function dungeonSpecific(uint heroLvl, uint heroCls) external view returns (address);

  function governance() external view returns (address);

  function statController() external view returns (address);

  function storyController() external view returns (address);

  function chamberController() external view returns (address);

  function reinforcementController() external view returns (address);

  function oracle() external view returns (address);

  function treasury() external view returns (address);

  function fightCalculator() external view returns (address);

  function itemCalculator() external view returns (address);

  function dungeonFactory() external view returns (address);

  function gameToken() external view returns (address);

  function fightDelay() external view returns (uint);

  function dungeonMultiplier(address dungeonImpl, address monsterProxy) external view returns (uint);

  function validHeroes(address hero) external view returns (bool);

  function validDungeons(address dungeon) external view returns (bool);

  function validItems(address item) external view returns (bool);

  function validTreasuryTokens(address token) external view returns (bool);

  function heroes(uint id) external view returns (address);

  function heroNameExist(string memory name) external view returns (bool);

  function globalBiomeMonsterMultiplier(uint biome) external view returns (uint);

  function dungeons(uint id) external view returns (address);

  function items(uint id) external view returns (address);

  function heroesLength() external view returns (uint);

  function dungeonsLength() external view returns (uint);

  function itemsLength() external view returns (uint);

  function dungeonImplByBiomeLevel(uint level, uint index) external view returns (address);

  function dungeonImplLength(uint level) external view returns (uint);

  function minLevelForTreasury(address token) external view returns (uint);

  function registerDungeon(address dungeonProxy) external;

  function registerHeroName(string memory name) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IStatController.sol";
import "./IItem.sol";

interface IEvent {

  struct EventGenerateInfo {
    IItem.GenerateInfo positiveAttributes;
    IItem.GenerateInfo negativeAttributes;

    PositiveStats positiveStats;
    NegativeStats negativeStats;
    uint positiveStatsChance;

    address[] mintItems;
    uint[] mintItemsChances;
  }

  struct PositiveStats {
    uint experience;
    uint heal;
    uint manaRegen;
    uint lifeChancesRecovered;
  }

  struct NegativeStats {
    uint damage;
    uint manaConsumed;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IStatController.sol";

interface IFightCalculator {

  enum AttackType {
    UNKNOWN, // 0
    MELEE, // 1
    MAGIC, // 2
    SLOT_3,
    SLOT_4,
    SLOT_5,
    SLOT_6,
    SLOT_7,
    SLOT_8,
    SLOT_9,
    SLOT_10
  }

  struct AttackInfo {
    AttackType attackType;
    address attackToken;
    uint attackTokenId;
    address[] skillTokens;
    uint[] skillTokenIds;
  }

  struct FighterInfo {
    uint[] fighterAttributes;
    IStatController.ChangeableStats fighterStats;
    AttackType attackType;
    address attackToken;
    uint attackTokenId;
    uint race;
  }

  struct Statuses {
    bool stun;
    bool burn;
    bool freeze;
    bool confuse;
    bool curse;
    bool poison;
  }

  struct FightResult {
    uint healthA;
    uint healthB;
    uint manaConsumedA;
    uint manaConsumedB;
  }

  struct FightCall {
    FighterInfo fighterA;
    FighterInfo fighterB;
    address dungeon;
    address heroAdr;
    uint heroId;
    uint stageId;
  }

  struct SkillSlots {
    bool slot1;
    bool slot2;
    bool slot3;
  }

  function decodeAndCheckAttackInfo(bytes memory data, address _heroToken, uint _heroId) external view returns (AttackInfo memory);

  function skillSlotsForDurabilityReduction(address dungeon, address heroToken, uint heroTokenId) external view returns (SkillSlots memory);

  function fight(FightCall memory callData) external returns (FightResult memory);

  function markSkillSlotsForDurabilityReduction(bytes memory data, address heroToken, uint heroTokenId) external;

  function releaseSkillSlotsForDurabilityReduction(address heroToken, uint heroTokenId) external;

}

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

import "./IStatController.sol";

interface IItem {

  struct GenerateInfo {
    uint[] ids;
    uint[] mins;
    uint[] maxs;
    uint[] chances;
    // it doesn't include positions with 100% chance
    uint minRandomAttributes;
    uint maxRandomAttributes;
  }

  enum FeeType {
    UNKNOWN,
    REPAIR,
    AUGMENT
  }

  enum ItemRarity {
    UNKNOWN, // 0
    NORMAL, // 1
    MAGIC, // 2
    RARE, // 3
    SET, // 4
    UNIQUE // 5
  }

  enum ItemType {
    NO_SLOT, // 0
    HEAD, // 1
    BODY, // 2
    GLOVES, // 3
    BELT, // 4
    AMULET, // 5
    RING, // 6
    OFF_HAND, // 7
    BOOTS, // 8
    ONE_HAND, // 9
    TWO_HAND, // 10
    SKILL // 11
  }

  enum ItemMetaType {
    UNKNOWN, // 0
    COMMON, // 1
    ATTACK_ITEM, // 2
    BUFF_ITEM, // 3
    CONSUMABLE_ITEM // 4
  }

  struct ItemMeta {
    string name;
    string symbol;
    string uri;
    address augmentToken;
    uint augmentTokenAmount;
    // Level in range 1-99. Reducing durability in low level dungeons. lvl/5+1 = biome
    uint itemLevel;
    ItemType itemType;
    uint baseDurability;
  }

  function itemMetaType() external view returns (ItemMetaType);

  function isOwner(address account, uint256 tokenId) external view returns (bool);

  function augmentationLevel(uint tokenId) external view returns (uint);

  function itemRarity(uint tokenId) external view returns (uint);

  function baseDurability() external view returns (uint);

  function itemDurability(uint tokenId) external view returns (uint);

  function equipped(uint tokenId) external view returns (bool);

  function equippedOn(uint tokenId, address heroAdr) external view returns (uint heroId);

  function isItem() external pure returns (bool);

  function isAttackItem() external view returns (bool);

  function isBuffItem() external view returns (bool);

  function isConsumableItem() external pure returns (bool);

  function augmentToken() external returns (address);

  function augmentTokenAmount() external returns (uint);

  function itemLevel() external returns (uint);

  function itemType() external returns (uint);

  function itemAttributes(uint tokenId) external view returns (uint[] memory);

  function negativeItemAttributes(uint tokenId) external view returns (uint[] memory);

  function requirementAttributes() external returns (IStatController.CoreAttributes memory);

  function score(uint tokenId) external view returns (uint);

  function mint() external returns (uint tokenId);

  function equip(uint tokenId, address heroToken, uint heroTokenId, uint itemSlot) external;

  function takeOff(uint tokenId, address heroToken, uint heroTokenId, uint itemSlot, address destination, bool broken) external;

  function reduceDurability(uint tokenId, uint dungeonBiomeLevel) external returns (uint);

  function repairDurability(uint tokenId, uint consumedItemId) external;

  function destroy(uint tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IItem.sol";
import "./IBuffItem.sol";
import "./IAttackItem.sol";
import "./IStatController.sol";
import "./IConsumableItem.sol";

interface IItemCalculator {

  function augmentGovFee() external view returns (uint);

  function repairGovFee() external view returns (uint);

  function score(uint[] memory attributes, uint baseDurability) external view returns (uint);

  function calcReduceDurability(
    uint dungeonBiomeLevel,
    uint currentDurability,
    uint _itemLevel
  ) external pure returns (uint);

  function augmentSuccess(uint random) external view returns (bool);

  function generateAttributes(IItem.GenerateInfo memory _info, uint rarity) external returns (uint[] memory ids, uint[] memory values, IItem.ItemRarity itemRarity);

  function generateSkillAttributes(IItem.GenerateInfo memory _info, bool onlyPositiveChances)
  external returns (uint[] memory ids, uint[] memory values);

  function generateAttack(IAttackItem.GenerateAttackInfo memory _info) external returns (IStatController.MagicAttack memory);

  function augmentAttribute(uint value) external view returns (uint);

  function augmentMagicAttack(IStatController.MagicAttack memory current) external pure returns (IStatController.MagicAttack memory);

  function consumableInfoToGenerateInfo(IConsumableItem.GenerateConsumableInfo memory consumableGenInfo) external pure returns (IItem.GenerateInfo memory pos, IItem.GenerateInfo memory neg);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOracle {

  function getRandomNumber(uint max, uint seed) external returns (uint);

  function getRandomNumberInRange(uint min, uint max, uint seed) external returns (uint);

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

import "../interfaces/IChamber.sol";
import "./IController.sol";

interface IStoryController {

  enum AnswerResultId {
    UNKNOWN, // 0
    SUCCESS, // 1
    ATTRIBUTE_FAIL, // 2
    RANDOM_FAIL, // 3
    DELAY_FAIL, // 4
    HERO_CUSTOM_DATA_FAIL, // 5
    GLOBAL_CUSTOM_DATA_FAIL // 6
  }

  enum CustomDataResult {
    UNKNOWN, // 0
    HERO_SUCCESS, // 1
    HERO_FAIL, // 2
    GLOBAL_SUCCESS, // 3
    GLOBAL_FAIL // 4
  }

  /// @dev We need to have flat structure coz Solidity can not handle arrays of structs properly
  struct StoryMetaInfo {
    uint storyId;
    bytes32 requiredCustomDataIndex;
    uint requiredCustomDataMinValue;
    uint requiredCustomDataMaxValue;
    bool requiredCustomDataIsHero;

    bytes32[] finalAnswers;

    bytes32[] answerBurnRandomItemAnswerId;
    uint[] answerBurnRandomItemSlot;
    uint[] answerBurnRandomItemChance;

    NextChambersRewriteMeta nextChambersRewriteMeta;

    AnswersMeta answersMeta;
    AnswerNextPageMeta answerNextPage;
    AnswerAttributeRequirementsMeta answerAttributeRequirements;
    AnswerItemRequirementsMeta answerItemRequirements;
    AnswerTokenRequirementsMeta answerTokenRequirements;
    AnswerRandomRequirementMeta answerRandomRequirements;
    AnswerDelayRequirementMeta answerDelayRequirements;
    AnswerCustomDataMeta answerHeroCustomDataRequirement;
    AnswerCustomDataMeta answerGlobalCustomDataRequirement;

    AnswerResultMeta successInfo;
    AnswerResultMeta failInfo;

    AnswerCustomDataResultMeta successHeroCustomData;
    AnswerCustomDataResultMeta failHeroCustomData;
    AnswerCustomDataResultMeta successGlobalCustomData;
    AnswerCustomDataResultMeta failGlobalCustomData;

  }

  struct NextChambersRewriteMeta {
    uint[] nextChamberPageIds;
    address [] nextChamberAddresses;
  }

  struct AnswersMeta {
    uint[] answerPageIds;
    uint[] answerHeroClasses;
    uint[] answerIds;
  }

  struct AnswerNextPageMeta {
    bytes32[] answerIndexes;
    uint[] answerResultIds;
    uint[][] answerNextPageIds;
  }

  struct AnswerAttributeRequirementsMeta {
    bytes32[] answerIndexes;
    bool[][] cores;
    uint[][] ids;
    uint[][] values;
  }

  struct AnswerItemRequirementsMeta {
    bytes32[] answerIndexes;
    address[][] requireItems;
    bool[][] requireItemBurn;
    bool[][] requireItemEquipped;
  }

  struct AnswerTokenRequirementsMeta {
    bytes32[] answerIndexes;
    address[][] requireToken;
    uint[][] requireAmount;
    bool[][] requireTransfer;
  }

  struct AnswerRandomRequirementMeta {
    bytes32[] answerIndexes;
    uint[] randomRequirements;
  }

  struct AnswerDelayRequirementMeta {
    bytes32[] answerIndexes;
    uint[] delayRequirements;
  }

  struct AnswerCustomDataMeta {
    bytes32[] answerIndexes;
    bytes32[] dataIndexes;
    bool[] mandatory;
    uint[] dataValuesMin;
    uint[] dataValuesMax;
  }

  struct AnswerResultMeta {
    bytes32[] answerIndexes;

    uint[][] positiveIds;
    uint[][] positiveValues;
    uint[][] negativeIds;
    uint[][] negativeValues;

    uint[] experience;
    uint[] heal;
    uint[] manaRegen;
    uint[] lifeChancesRecovered;
    uint[] damage;
    uint[] manaConsumed;

    address[][] mintItems;
    uint[][] mintItemsChances;
  }

  struct AnswerCustomDataResultMeta {
    bytes32[] answerIndexes;
    bytes32[][] dataIndexes;
    uint[][] dataValues;
    bool[][] increase;
  }

  struct AttributeRequirements {
    bool core;
    uint id;
    uint value;
  }

  struct ItemRequirements {
    address requireItem;
    bool requireItemBurn;
    bool requireItemEquipped;
  }

  struct TokenRequirements {
    address requireToken;
    uint requireAmount;
    bool requireTransfer;
  }

  struct CustomDataRequirement {
    bytes32 index;
    uint valueMin;
    uint valueMax;
    bool mandatory;
  }

  struct CustomDataRequirementRange {
    bytes32 index;
    uint minValue;
    uint maxValue;
    bool isHeroData;
  }

  struct CustomData {
    bytes32 index;
    uint value;
    bool increase;
  }

  struct BurnInfo {
    uint slot;
    uint chance;
  }

  struct StoryResultInfo {
    AttributesInfo positiveAttributes;
    AttributesInfo negativeAttributes;

    uint experience;
    uint heal;
    uint manaRegen;
    uint lifeChancesRecovered;
    uint damage;
    uint manaConsumed;

    address[] mintItems;
    uint[] mintItemsChances;
  }

  struct AttributesInfo {
    uint[] ids;
    uint[] values;
  }

  struct StoryActionContext {
    address sender;
    address dungeon;
    address story;
    uint stageId;
    IController controller;
    IStatController statController;
    address heroToken;
    uint heroTokenId;
    bytes32 answerIdHash;
  }

  function isStoryAvailableForHero(address story, address heroToken, uint heroTokenId) external view returns (bool);


  function setBurnItemsMeta(
    uint storyId,
    bytes32[] memory answerBurnRandomItemAnswerId,
    uint[] memory answerBurnRandomItemSlot,
    uint[] memory answerBurnRandomItemChance
  ) external;

  function setNextChambersRewriteMeta(uint storyId, NextChambersRewriteMeta memory meta) external;

  function setAnswersMeta(uint storyId, AnswersMeta memory meta) external;

  function setAnswerNextPageMeta(uint storyId, AnswerNextPageMeta memory meta) external;

  function setAnswerAttributeRequirements(uint storyId, AnswerAttributeRequirementsMeta memory meta) external;

  function setAnswerItemRequirements(uint storyId, AnswerItemRequirementsMeta memory meta) external;

  function setAnswerTokenRequirementsMeta(uint storyId, AnswerTokenRequirementsMeta memory meta) external;

  function setAnswerRandomRequirementMeta(uint storyId, AnswerRandomRequirementMeta memory meta) external;

  function setAnswerDelayRequirementMeta(uint storyId, AnswerDelayRequirementMeta memory meta) external;

  function setAnswerHeroCustomDataRequirementMeta(uint storyId, AnswerCustomDataMeta memory meta) external;

  function setAnswerGlobalCustomDataRequirementMeta(uint storyId, AnswerCustomDataMeta memory meta) external;

  function setSuccessInfo(uint storyId, AnswerResultMeta memory meta) external;

  function setFailInfo(uint storyId, AnswerResultMeta memory meta) external;

  function setCustomDataResult(
    uint storyId,
    AnswerCustomDataResultMeta memory meta,
    CustomDataResult _type
  ) external;

  function setStoryFinalAnswers(uint storyId, bytes32[] memory finalAnswers_) external;

  function setStoryCustomDataRequirements(
    uint storyId,
    bytes32[] memory requiredCustomDataIndex,
    uint[] memory requiredCustomDataMinValue,
    uint[] memory requiredCustomDataMaxValue,
    bool[] memory requiredCustomDataIsHero,
    uint minLevel
  ) external;

  function finalizeStoryRegistration(uint storyId) external;


  function storyAction(
    address sender,
    address dungeon,
    address story,
    uint stageId,
    address heroToken,
    uint heroTokenId,
    bytes memory data
  ) external returns (IChamber.ChamberResult memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IItem.sol";

interface ITreasury {

  function balanceOfToken(address token) external view returns (uint);

  function sendToDungeon(address dungeon, address token, uint amount) external;

  function sendFee(address token, uint amount, IItem.FeeType feeType) external;

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

import "../interfaces/IOracle.sol";
import "./StatLib.sol";
import "./CalcLib.sol";
import "../interfaces/IController.sol";
import "../interfaces/IItem.sol";
import "../interfaces/IEvent.sol";
import "../interfaces/IItemCalculator.sol";

library ChamberLib {

  struct EventInternalResult {
    uint[] posAttributes;
    uint[] negAttributes;

    uint experience;
    uint heal;
    uint manaRegen;
    uint lifeChancesRecovered;
    uint damage;
    uint manaConsumed;
  }

  struct MintItemInfo {
    address[] mintItems;
    uint[] mintItemsChances;
    uint biome;
    uint amplifier;
    uint seed;
    IOracle oracle;
    uint heroExp;
    uint heroCurrentLvl;
    uint magicFind;
    uint destroyItems;
    uint maxItems;
  }

  uint internal constant _ITEM_MAX_CHANCE = 1e18;

  function _generate(IController _controller, address heroToken, uint heroTokenId, IEvent.EventGenerateInfo memory _info) internal returns (EventInternalResult memory) {
    uint[] memory heroAttributes = IStatController(_controller.statController()).heroAttributes(heroToken, heroTokenId);

    EventInternalResult[] memory tmp = new EventInternalResult[](1);
    EventInternalResult memory result = tmp[0];

    result.posAttributes = generateAttributes(_controller, _info.positiveAttributes);
    result.negAttributes = generateAttributes(_controller, _info.negativeAttributes);

    // negative values should not be higher than hero has
    for (uint i; i < result.negAttributes.length; ++i) {
      if (result.negAttributes[i] > heroAttributes[i]) {
        result.negAttributes[i] = heroAttributes[i];
      }
    }

    uint random = IOracle(_controller.oracle()).getRandomNumber(_ITEM_MAX_CHANCE, 0);
    if (random <= _info.positiveStatsChance) {
      IEvent.PositiveStats memory stats = _info.positiveStats;

      result.experience = stats.experience;
      result.heal = stats.heal;
      result.manaRegen = stats.manaRegen;
      result.lifeChancesRecovered = stats.lifeChancesRecovered;
    } else {
      IEvent.NegativeStats memory stats = _info.negativeStats;

      result.damage = stats.damage;
      result.manaConsumed = stats.manaConsumed;
    }

    return result;
  }

  function mintRandomItems(MintItemInfo memory info) internal returns (address[] memory) {
    unchecked{

    // Fisher–Yates shuffle
      if (info.mintItems.length > 1) {
        for (uint i; i < info.mintItems.length; i++) {
          uint randomIndex = CalcLib.pseudoRandomInRange(i, info.mintItems.length - 1);
          address temp = info.mintItems[randomIndex];
          uint temp2 = info.mintItemsChances[randomIndex];
          info.mintItems[randomIndex] = info.mintItems[i];
          info.mintItemsChances[randomIndex] = info.mintItemsChances[i];
          info.mintItems[i] = temp;
          info.mintItemsChances[i] = temp2;
        }
      }

      address[] memory minted = new address[](info.mintItems.length);
      uint mintedLength;

      for (uint i; i < info.mintItems.length; ++i) {
        uint chance = StatLib.mintDropChance(info.mintItemsChances[i], info.amplifier, info.biome, info.heroExp, info.heroCurrentLvl);
        chance += chance * info.magicFind / 100;
        chance -= chance * Math.min(info.destroyItems, 100) / 100;

        // need to call random in each loop coz each minted item should have dedicated chance
        uint rnd = info.oracle.getRandomNumber(_ITEM_MAX_CHANCE, info.seed);

        if (chance != 0 && (chance >= _ITEM_MAX_CHANCE || rnd < chance)) {
          minted[i] = info.mintItems[i];
          ++mintedLength;
          if (mintedLength >= info.maxItems) {
            break;
          }
        }
      }

      address[] memory mintedAdjusted = new address[](mintedLength);
      uint j;
      for (uint i; i < minted.length; ++i) {
        if (minted[i] != address(0)) {
          mintedAdjusted[j] = minted[i];
          ++j;
        }
      }

      return mintedAdjusted;
    }
  }

  function generateAttributes(IController _controller, IItem.GenerateInfo memory info) internal returns (uint[] memory attributes) {
    bool hasValues;
    if (info.ids.length != 0) {
      attributes = new uint[](uint(IStatController.ATTRIBUTES.END_SLOT));
      (uint[] memory ids, uint[] memory values,) = IItemCalculator(_controller.itemCalculator()).generateAttributes(info, 0);

      for (uint i; i < ids.length;) {
        uint value = values[i];
        attributes[ids[i]] = value;
        if (value != 0) {
          hasValues = true;
        }
        unchecked{++i;}
      }
      if (!hasValues) {
        attributes = new uint[](0);
      }
    } else {
      attributes = new uint[](0);
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

import "../interfaces/IStoryController.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IItem.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IController.sol";
import "../interfaces/IChamberController.sol";
import "../openzeppelin/IERC20.sol";
import "../openzeppelin/IERC721Enumerable.sol";
import "../openzeppelin/SafeERC20.sol";
import "../lib/ChamberLib.sol";
import "../lib/CalcLib.sol";

library StoryLib {
  using CalcLib for uint;
  using SafeERC20 for IERC20;

  event ItemBurned(
    address heroToken,
    uint heroTokenId,
    address dungeon,
    address story,
    address nftToken,
    uint nftId,
    uint stageId,
    uint iteration
  );
  event StoryChangeAttributes(
    address heroToken,
    uint heroTokenId,
    address dungeon,
    address story,
    uint stageId,
    uint iteration,
    uint[] posAttributes,
    uint[] negAttributes
  );

  function isStoryAvailableForHero(
    address story,
    address heroToken,
    uint heroTokenId,
    address statController,
    mapping(address => IStoryController.CustomDataRequirementRange[]) storage storyRequiredHeroData,
    mapping(address => uint) storage storyRequiredLevel
  ) external view returns (bool) {
    if (IStatController(statController).heroStats(heroToken, heroTokenId).level < storyRequiredLevel[story]) {
      return false;
    }

    IStoryController.CustomDataRequirementRange[] storage allData = storyRequiredHeroData[story];
    uint length = allData.length;
    for (uint i; i < length; ++i) {

      IStoryController.CustomDataRequirementRange memory data = allData[i];

      if (data.index == bytes32(0)) {
        continue;
      }
      uint value;
      if (data.isHeroData) {
        value = IStatController(statController).heroCustomData(heroToken, heroTokenId, data.index);
      } else {
        value = IStatController(statController).globalCustomData(data.index);
      }
      if (value < data.minValue || value > data.maxValue) {
        return false;
      }
    }
    return true;
  }

  function handleResult(
    IStoryController.StoryActionContext memory context,
    IChamber.ChamberResult memory result,
    IStoryController.StoryResultInfo memory info
  ) public returns (IChamber.ChamberResult memory) {
    IStatController.ChangeableStats memory heroStats = IHero(context.heroToken).stats(context.heroTokenId);
    uint[] memory posAttributes = generateAttributes(info.positiveAttributes);

    if (posAttributes.length != 0) {
      context.statController.changeBonusAttributes(IStatController.ChangeAttributesInfo({
        heroToken: context.heroToken,
        heroTokenId: context.heroTokenId,
        changeAttributes: posAttributes,
        increase: true,
        temporally: true
      }));
    }

    uint[] memory negAttributes = generateAttributes(info.negativeAttributes);

    if (negAttributes.length != 0) {
      context.statController.changeBonusAttributes(IStatController.ChangeAttributesInfo({
        heroToken: context.heroToken,
        heroTokenId: context.heroTokenId,
        changeAttributes: negAttributes,
        increase: false,
        temporally: true
      }));
    }

    if (posAttributes.length != 0 || negAttributes.length != 0) {
      emit StoryChangeAttributes(
        context.heroToken,
        context.heroTokenId,
        context.dungeon,
        context.story,
        context.stageId,
        IChamber(context.story).iterations(context.heroToken, context.heroTokenId),
        posAttributes,
        negAttributes
      );
    }

    if (info.heal != 0) {
      uint max = context.statController.heroAttribute(context.heroToken, context.heroTokenId, uint(IStatController.ATTRIBUTES.LIFE));
      result.heal = max * info.heal / 100;
    }

    if (info.manaRegen != 0) {
      uint max = context.statController.heroAttribute(context.heroToken, context.heroTokenId, uint(IStatController.ATTRIBUTES.MANA));
      result.manaRegen = max * info.manaRegen / 100;
    }

    if (info.damage != 0) {
      uint max = context.statController.heroAttribute(context.heroToken, context.heroTokenId, uint(IStatController.ATTRIBUTES.LIFE));
      result.damage = max * info.damage / 100;

      if(heroStats.life <= result.damage) {
        result.kill = true;
      }
    }

    if (info.manaConsumed != 0) {
      uint max = context.statController.heroAttribute(context.heroToken, context.heroTokenId, uint(IStatController.ATTRIBUTES.MANA));
      result.manaConsumed = Math.min(max * info.manaConsumed / 100, heroStats.mana);
    }

    result.experience = info.experience;
    result.lifeChancesRecovered = info.lifeChancesRecovered;

    if (info.mintItems.length != 0) {
      result.mintItems = ChamberLib.mintRandomItems(ChamberLib.MintItemInfo({
        mintItems: info.mintItems,
        mintItemsChances: info.mintItemsChances,
        biome: IChamber(context.story).biome(),
        amplifier: 0,
        seed: 0,
        oracle: IOracle(context.controller.oracle()),
        heroExp: heroStats.experience,
        heroCurrentLvl: heroStats.level,
        magicFind: 0,
        destroyItems: 0,
        maxItems: 1 // MINT ONLY 1 ITEM!
      }));
    }
    return result;
  }

  function generateAttributes(IStoryController.AttributesInfo memory info) internal pure returns (uint[] memory attributes) {
    bool hasValues;
    if (info.ids.length != 0) {
      attributes = new uint[](uint(IStatController.ATTRIBUTES.END_SLOT));

      for (uint i; i < info.ids.length;) {
        uint value = info.values[i];
        attributes[info.ids[i]] = value;
        if (value != 0) {
          hasValues = true;
        }
        unchecked{++i;}
      }
      if (!hasValues) {
        attributes = new uint[](0);
      }
    } else {
      attributes = new uint[](0);
    }
  }

  function handleCustomDataResult(
    IStoryController.StoryActionContext memory context,
    IStoryController.CustomData[] memory heroCustomDatas,
    IStoryController.CustomData[] memory globalCustomDatas
  ) public {

    for (uint i; i < heroCustomDatas.length; ++i) {
      IStoryController.CustomData memory heroCustomData = heroCustomDatas[i];
      if (heroCustomData.index != 0) {
        uint curValue = context.statController.heroCustomData(context.heroToken, context.heroTokenId, heroCustomData.index);
        context.statController.setHeroCustomData(
          context.heroToken,
          context.heroTokenId,
          heroCustomData.index,
            heroCustomData.value == 0 ? 0 :
              heroCustomData.increase ? curValue + heroCustomData.value
              : curValue.minusWithZeroFloor(heroCustomData.value)
        );
      }
    }

    for (uint i; i < globalCustomDatas.length; ++i) {
      IStoryController.CustomData memory globalCustomData = globalCustomDatas[i];
      if (globalCustomData.index != 0) {
        uint curValue = context.statController.globalCustomData(globalCustomData.index);
        context.statController.setGlobalCustomData(
          globalCustomData.index,
            globalCustomData.value == 0 ? 0 :
              globalCustomData.increase ? curValue + globalCustomData.value
              : curValue.minusWithZeroFloor(globalCustomData.value)
        );
      }
    }
  }

  function burn(IStoryController.StoryActionContext memory context, IStoryController.BurnInfo memory burnInfo) external {
    if (burnInfo.chance != 0) {
      IOracle oracle = IOracle(context.controller.oracle());
      if (oracle.getRandomNumberInRange(0, 100, 0) <= burnInfo.chance) {
        uint[] memory busySlots = context.statController.heroItemSlots(context.heroToken, context.heroTokenId);
        if (busySlots.length != 0) {
          uint busySlotIndex;
          bool itemExist;
          if (burnInfo.slot == 0) {
            busySlotIndex = oracle.getRandomNumberInRange(0, busySlots.length - 1, 0);
            itemExist = true;
          } else {
            for (uint i; i < busySlots.length; ++i) {
              if (busySlots[i] == burnInfo.slot) {
                busySlotIndex = i;
                itemExist = true;
                break;
              }
            }
          }

          if (itemExist) {
            burnItemInHeroSlot(context, busySlots[busySlotIndex]);
          }
        }
      }
    }
  }

  function burnItemInHeroSlot(IStoryController.StoryActionContext memory context, uint slot) internal {
    IStatController.NftItem memory nft = context.statController.heroItemSlot(context.heroToken, context.heroTokenId, slot);
    IItem(nft.token).takeOff(nft.tokenId, context.heroToken, context.heroTokenId, slot, address(this), false);
    IItem(nft.token).destroy(nft.tokenId);
    emit ItemBurned(
      context.heroToken,
      context.heroTokenId,
      context.dungeon,
      context.story,
      nft.token,
      nft.tokenId,
      context.stageId,
      IChamber(context.story).iterations(context.heroToken, context.heroTokenId)
    );
  }

  ////////////////////////////////////////////////////////////
  //               CHECK ANSWER
  ////////////////////////////////////////////////////////////

  function checkAnswer(
    IStoryController.StoryActionContext memory context,
    bytes32 answerIndex,
    mapping(address => mapping(bytes32 => IStoryController.AttributeRequirements[])) storage attributeRequirements,
    mapping(address => mapping(bytes32 => IStoryController.ItemRequirements[])) storage itemRequirements,
    mapping(address => mapping(bytes32 => IStoryController.TokenRequirements[])) storage tokenRequirements,
    mapping(address => mapping(bytes32 => uint)) storage randomRequirement,
    mapping(address => mapping(bytes32 => uint)) storage delayRequirement,
    mapping(address => mapping(bytes32 => IStoryController.CustomDataRequirement)) storage heroCustomDataRequirement,
    mapping(address => mapping(bytes32 => IStoryController.CustomDataRequirement)) storage globalCustomDataRequirement,
    mapping(address => mapping(address => mapping(uint => uint))) storage heroLastActionTS
  ) external returns (IStoryController.AnswerResultId result) {
    result = checkAnswerAttributes(context, answerIndex, attributeRequirements);
    if (result == IStoryController.AnswerResultId.SUCCESS) {
      result = checkAnswerItems(context, answerIndex, itemRequirements);
    }
    if (result == IStoryController.AnswerResultId.SUCCESS) {
      result = checkAnswerTokens(context, answerIndex, tokenRequirements);
    }
    if (result == IStoryController.AnswerResultId.SUCCESS) {
      result = checkAnswerDelay(context, answerIndex, delayRequirement, heroLastActionTS);
    }
    if (result == IStoryController.AnswerResultId.SUCCESS) {
      result = checkAnswerHeroCustomData(context, answerIndex, heroCustomDataRequirement);
    }
    if (result == IStoryController.AnswerResultId.SUCCESS) {
      result = checkAnswerGlobalCustomData(context, answerIndex, globalCustomDataRequirement);
    }
    if (result == IStoryController.AnswerResultId.SUCCESS) {
      result = checkAnswerRandom(context, answerIndex, randomRequirement);
    }
  }

  function checkAnswerAttributes(
    IStoryController.StoryActionContext memory context,
    bytes32 answerIndex,
    mapping(address => mapping(bytes32 => IStoryController.AttributeRequirements[])) storage attributeRequirements
  ) internal view returns (IStoryController.AnswerResultId) {
    IStoryController.AttributeRequirements[] storage reqs = attributeRequirements[context.story][answerIndex];
    uint length = reqs.length;

    for (uint i; i < length; ++i) {
      IStoryController.AttributeRequirements memory req = reqs[i];
      if (req.core) {
        IStatController.CoreAttributes memory base = context.statController.heroBaseAttributes(context.heroToken, context.heroTokenId);
        if (req.id == uint(IStatController.ATTRIBUTES.STRENGTH) && base.strength < req.value) {
          return IStoryController.AnswerResultId.ATTRIBUTE_FAIL;
        }
        if (req.id == uint(IStatController.ATTRIBUTES.DEXTERITY) && base.dexterity < req.value) {
          return IStoryController.AnswerResultId.ATTRIBUTE_FAIL;
        }
        if (req.id == uint(IStatController.ATTRIBUTES.VITALITY) && base.vitality < req.value) {
          return IStoryController.AnswerResultId.ATTRIBUTE_FAIL;
        }
        if (req.id == uint(IStatController.ATTRIBUTES.ENERGY) && base.energy < req.value) {
          return IStoryController.AnswerResultId.ATTRIBUTE_FAIL;
        }
      } else {
        uint attr = context.statController.heroAttribute(context.heroToken, context.heroTokenId, req.id);
        if (attr < req.value) {
          return IStoryController.AnswerResultId.ATTRIBUTE_FAIL;
        }
      }
    }

    return IStoryController.AnswerResultId.SUCCESS;
  }

  function checkAnswerItems(
    IStoryController.StoryActionContext memory context,
    bytes32 answerIndex,
    mapping(address => mapping(bytes32 => IStoryController.ItemRequirements[])) storage itemRequirements
  ) internal returns (IStoryController.AnswerResultId) {
    // --- check items

    IStoryController.ItemRequirements[] storage reqs = itemRequirements[context.story][answerIndex];
    uint length = reqs.length;

    for (uint i; i < length; ++i) {
      IStoryController.ItemRequirements memory req = reqs[i];

      if (req.requireItemEquipped && IERC721Enumerable(req.requireItem).balanceOf(context.heroToken) == 0) {
        revert("!item");
      }

      if (req.requireItemBurn) {
        // burn first owned item
        uint itemId = IERC721Enumerable(req.requireItem).tokenOfOwnerByIndex(context.sender, 0);
        IItem(req.requireItem).destroy(itemId);
      }

      if (!req.requireItemEquipped && !req.requireItemBurn) {
        require(IERC721Enumerable(req.requireItem).balanceOf(context.sender) != 0);
      }

    }
    return IStoryController.AnswerResultId.SUCCESS;
  }

  function checkAnswerTokens(
    IStoryController.StoryActionContext memory context,
    bytes32 answerIndex,
    mapping(address => mapping(bytes32 => IStoryController.TokenRequirements[])) storage tokenRequirements
  ) internal returns (IStoryController.AnswerResultId) {
    IStoryController.TokenRequirements[] memory reqs = tokenRequirements[context.story][answerIndex];
    uint length = reqs.length;
    for (uint i; i < length; ++i) {
      IStoryController.TokenRequirements memory req = reqs[i];

      uint balance = IERC20(req.requireToken).balanceOf(context.sender);

      if (req.requireAmount != 0) {
        require(balance >= req.requireAmount, "!amount");

        if (req.requireTransfer) {
          address treasury = context.controller.treasury();
          IERC20(req.requireToken).safeTransferFrom(
            context.sender,
            address(this),
            req.requireAmount
          );
          IERC20(req.requireToken).approve(treasury, req.requireAmount);
          ITreasury(treasury).sendFee(req.requireToken, req.requireAmount, IItem.FeeType.UNKNOWN);
        }
      }
    }
    return IStoryController.AnswerResultId.SUCCESS;
  }

  function checkAnswerRandom(
    IStoryController.StoryActionContext memory context,
    bytes32 answerIndex,
    mapping(address => mapping(bytes32 => uint)) storage randomRequirement
  ) internal returns (IStoryController.AnswerResultId) {

    uint random = randomRequirement[context.story][answerIndex];
    if (random != 0 && random < 100) {
      if (IOracle(context.controller.oracle()).getRandomNumber(100, 0) > random) {
        return IStoryController.AnswerResultId.RANDOM_FAIL;
      }
    }

    return IStoryController.AnswerResultId.SUCCESS;
  }

  function checkAnswerDelay(
    IStoryController.StoryActionContext memory context,
    bytes32 answerIndex,
    mapping(address => mapping(bytes32 => uint)) storage delayRequirement,
    mapping(address => mapping(address => mapping(uint => uint))) storage heroLastActionTS
  ) internal view returns (IStoryController.AnswerResultId) {

    uint delay = delayRequirement[context.story][answerIndex];
    if (delay != 0) {
      uint lastCall = heroLastActionTS[context.story][context.heroToken][context.heroTokenId];
      if (lastCall != 0 && lastCall < block.timestamp && block.timestamp - lastCall > delay) {
        return IStoryController.AnswerResultId.DELAY_FAIL;
      }
    }

    return IStoryController.AnswerResultId.SUCCESS;
  }

  function checkAnswerHeroCustomData(
    IStoryController.StoryActionContext memory context,
    bytes32 answerIndex,
    mapping(address => mapping(bytes32 => IStoryController.CustomDataRequirement)) storage heroCustomDataRequirement
  ) internal view returns (IStoryController.AnswerResultId) {

    IStoryController.CustomDataRequirement memory data = heroCustomDataRequirement[context.story][answerIndex];
    if (data.index != 0) {
      uint heroValue = context.statController.heroCustomData(context.heroToken, context.heroTokenId, data.index);
      if (heroValue < data.valueMin || heroValue > data.valueMax) {
        if (data.mandatory) {
          revert('!hero data');
        } else {
          return IStoryController.AnswerResultId.HERO_CUSTOM_DATA_FAIL;
        }
      }
    }

    return IStoryController.AnswerResultId.SUCCESS;
  }

  function checkAnswerGlobalCustomData(
    IStoryController.StoryActionContext memory context,
    bytes32 answerIndex,
    mapping(address => mapping(bytes32 => IStoryController.CustomDataRequirement)) storage globalCustomDataRequirement
  ) internal view returns (IStoryController.AnswerResultId) {
    IStoryController.CustomDataRequirement memory data = globalCustomDataRequirement[context.story][answerIndex];
    uint globalData = context.statController.globalCustomData(data.index);
    if (data.index != 0) {
      if (globalData < data.valueMin || globalData > data.valueMax) {
        if (data.mandatory) {
          revert('!global data');
        } else {
          return IStoryController.AnswerResultId.GLOBAL_CUSTOM_DATA_FAIL;
        }
      }
    }
    return IStoryController.AnswerResultId.SUCCESS;
  }

  function findAnswerIndex(bytes32[] memory heroAnswers, bytes32 answerIdHash) external pure returns (bytes32){
    bytes32 answerIndex;
    for (uint i; i < heroAnswers.length; ++i) {
      if (heroAnswers[i] == answerIdHash) {
        answerIndex = answerIdHash;
        break;
      }
    }
    require(answerIndex != bytes32(0), "!answer");

    return answerIndex;
  }

  function handleAnswer(
    bytes32 answerIndex,
    IStoryController.AnswerResultId answerResultId,
    mapping(address => mapping(address => mapping(uint => uint))) storage heroPage,
    mapping(address => mapping(bytes32 => mapping(IStoryController.CustomDataResult => IStoryController.CustomData[]))) storage customDataResult,
    mapping(address => mapping(bytes32 => IStoryController.StoryResultInfo)) storage successInfo,
    mapping(address => mapping(bytes32 => IStoryController.StoryResultInfo)) storage failInfo,
    mapping(address => mapping(bytes32 => mapping(IStoryController.AnswerResultId => uint[]))) storage nextPageIds,
    IStoryController.StoryActionContext memory context,
    IChamber.ChamberResult memory result
  ) external returns (IChamber.ChamberResult memory returnResult) {

    heroPage[context.story][context.heroToken][context.heroTokenId] = getNextPage(context.controller.oracle(), nextPageIds[context.story][answerIndex][answerResultId]);

    if (answerResultId == IStoryController.AnswerResultId.SUCCESS) {
      result = handleResult(context, result, successInfo[context.story][answerIndex]);

      handleCustomDataResult(
        context,
        customDataResult[context.story][answerIndex][IStoryController.CustomDataResult.HERO_SUCCESS],
        customDataResult[context.story][answerIndex][IStoryController.CustomDataResult.GLOBAL_SUCCESS]
      );
    } else {
      result = handleResult(context, result, failInfo[context.story][answerIndex]);

      handleCustomDataResult(
        context,
        customDataResult[context.story][answerIndex][IStoryController.CustomDataResult.HERO_FAIL],
        customDataResult[context.story][answerIndex][IStoryController.CustomDataResult.GLOBAL_FAIL]
      );
    }
    returnResult = result;
  }

  function getNextPage(address oracle, uint[] memory pages) internal returns (uint) {
    if (pages.length == 0) {
      return 0;
    }
    if (pages.length == 1) {
      return pages[0];
    }
    return pages[IOracle(oracle).getRandomNumberInRange(0, pages.length - 1, 0)];
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

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
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
  unchecked {
    uint256 oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint256 newAllowance = oldAllowance - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}