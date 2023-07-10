// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/IOracle.sol";
import "../../interfaces/IStatController.sol";
import "../../interfaces/IChamber.sol";
import "../../proxy/Controllable.sol";

abstract contract ChamberBase is Controllable, IChamber {

  // ---- CONSTANTS ----

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CHAMBER_BASE_VERSION = "1.0.0";
  uint internal constant _ITEM_MAX_CHANCE = 1e18;
  uint internal constant _MAX_AMPLIFIER = 1e18;
  bool public constant override IS_CHAMBER = true;

  // ---- VARIABLES ----

  string public uri;
  string public chamberName;
  string public chamberSymbol;
  uint public override biome;
  uint public override chamberType;
  /// @dev Hero adr => hero id => iteration count. It needs for properly emit events for every new entrance.
  mapping(address => mapping(uint => uint)) public override iterations;

  // ---- EVENTS ----

  event ChamberResultEvent(
    address dungeon,
    address hero,
    uint heroId,
    uint chamberId,
    bytes data,
    ChamberResult result
  );
  event UriChanged(string uri);
  event NameChanged(string name);

  // ---- INITIALIZER ----

  function __ChamberBase_init(address controller_, ChamberMeta memory meta) internal {
    _onlyInitializing();

    __Controllable_init(controller_);
    biome = meta.biome;
    chamberType = meta.chamberType;
    uri = meta.uri;
    chamberName = meta.name;
    chamberSymbol = meta.symbol;
    emit UriChanged(meta.uri);
    emit NameChanged(meta.name);
  }

  // ---- RESTRICTIONS ----

  function onlyDungeon() internal view {
    require(IController(controller()).validDungeons(msg.sender), "Not dungeon");
  }

  // ---- VIEWS ----

  function _statController() internal view returns (IStatController) {
    return IStatController(IController(controller()).statController());
  }

  function _oracle() internal view returns (IOracle) {
    return IOracle(IController(controller()).oracle());
  }

  function _checkItem(
    address[] memory mintItems_,
    uint[] memory mintItemsChances_
  ) internal pure {
    uint length = mintItems_.length;
    for (uint i; i < length;) {
      require(mintItems_[i] != address(0), "Zero address");
      require(mintItemsChances_[i] != 0, "Zero chance");
      require(mintItemsChances_[i] <= _ITEM_MAX_CHANCE, "Too high chance");
    unchecked{++i;}
    }
  }

  function isAvailableForHero(address /*heroToken*/, uint /*heroTokenId*/) external view override virtual returns (bool) {
    return true;
  }

  // ---- GOV ACTIONS ----

  function setUri(string memory _uri) external {
    require(isGovernance(msg.sender), "Not gov");
    uri = _uri;
    emit UriChanged(_uri);
  }

  function setName(string memory _name) external {
    require(isGovernance(msg.sender), "Not gov");
    chamberName = _name;
    emit NameChanged(_name);
  }

  // ---- USER ACTIONS ----

  function open(address heroToken, uint heroTokenId) public virtual override returns (uint iteration) {
    uint i = iterations[heroToken][heroTokenId] + 1;
    iterations[heroToken][heroTokenId] = i;
    return i;
  }

  function action(
    address sender,
    address heroToken,
    uint heroTokenId,
    uint stageId,
    bytes memory data
  ) external virtual override returns (ChamberResult memory) {
    onlyDungeon();
    require(IController(controller()).validHeroes(heroToken), "Hero not registered");
    ChamberResult memory r = _action(sender, heroToken, heroTokenId, stageId, data);

    r.iteration = iterations[heroToken][heroTokenId];

    emit ChamberResultEvent(
      msg.sender,
      heroToken,
      heroTokenId,
      stageId,
      data,
      r
    );
    return r;
  }

  function _action(
    address sender,
    address heroToken,
    uint heroTokenId,
    uint stageId,
    bytes memory data
  ) internal virtual returns (ChamberResult memory);

  /// @dev This empty reserved space is put in place to allow future versions to add new
  ///      variables without shifting down storage in the inheritance chain.
  ///      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint256[48] private __gap;

}

// SPDX-License-Identifier: MIT
/**
            ▒▓▒  ▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▒     ▒▒▒▒▓▓▓▒▓▓▓▓▓▓▓██▓
             ▒██▒▓▓▓▓█▓██████████████████▓  ▒▒▒▓███████████████▒
              ▒██▒▓█████████████████████▒ ▒▓██████████▓███████
               ▒███████████▓▒                   ▒███▓▓██████▓
                 █████████▒                     ▒▓▒▓███████▒
                  ███████▓      ▒▒▒▒▒▓▓█▓▒     ▓█▓████████
                   ▒▒▒▒▒   ▒▒▒▒▓▓▓█████▒      ▓█████████▓
                         ▒▓▓▓▒▓██████▓      ▒▓▓████████▒
                       ▒██▓▓▓███████▒      ▒▒▓███▓████
                        ▒███▓█████▒       ▒▒█████▓██▓
                          ██████▓   ▒▒▒▓██▓██▓█████▒
                           ▒▒▓▓▒   ▒██▓▒▓▓████████
                                  ▓█████▓███████▓
                                 ██▓▓██████████▒
                                ▒█████████████
                                 ███████████▓
      ▒▓▓▓▓▓▓▒▓                  ▒█████████▒                      ▒▓▓
    ▒▓█▒   ▒▒█▒▒                   ▓██████                       ▒▒▓▓▒
   ▒▒█▒       ▓▒                    ▒████                       ▒▓█▓█▓▒
   ▓▒██▓▒                             ██                       ▒▓█▓▓▓██▒
    ▓█▓▓▓▓▓█▓▓▓▒        ▒▒▒         ▒▒▒▓▓▓▓▒▓▒▒▓▒▓▓▓▓▓▓▓▓▒    ▒▓█▒ ▒▓▒▓█▓
     ▒▓█▓▓▓▓▓▓▓▓▓▓▒    ▒▒▒▓▒     ▒▒▒▓▓     ▓▓  ▓▓█▓   ▒▒▓▓   ▒▒█▒   ▒▓▒▓█▓
            ▒▒▓▓▓▒▓▒  ▒▓▓▓▒█▒   ▒▒▒█▒          ▒▒█▓▒▒▒▓▓▓▒   ▓██▓▓▓▓▓▓▓███▓
 ▒            ▒▓▓█▓  ▒▓▓▓▓█▓█▓  ▒█▓▓▒          ▓▓█▓▒▓█▓▒▒   ▓█▓        ▓███▓
▓▓▒         ▒▒▓▓█▓▒▒▓█▒   ▒▓██▓  ▓██▓▒     ▒█▓ ▓▓██   ▒▓▓▓▒▒▓█▓        ▒▓████▒
 ██▓▓▒▒▒▒▓▓███▓▒ ▒▓▓▓▓▒▒ ▒▓▓▓▓▓▓▓▒▒▒▓█▓▓▓▓█▓▓▒▒▓▓▓▓▓▒    ▒▓████▓▒     ▓▓███████▓▓▒
*/
pragma solidity 0.8.17;

import "../../interfaces/IStory.sol";
import "../../interfaces/IStoryController.sol";
import "../../interfaces/IStatController.sol";
import "./ChamberBase.sol";
import "./../../lib/StringLib.sol";

contract CommonStory is ChamberBase, IStory {

  // ---- CONSTANTS ----

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant VERSION = "1.0.0";

  // ---- VARIABLES ----

  /// @dev Indicate story initialisation.
  uint public storyId;

  // ---- EVENTS ----

  event StoryMetaChanged(IStoryController.StoryMetaInfo meta);

  // ---- INITIALIZER ----

  function init(
    address controller_,
    ChamberMeta memory meta
  ) external {
    _initializer();

    __ChamberBase_init(controller_, meta);

    _finishInitializer();
  }

  // ---- META SETUP ACTIONS ----

  function _isAbleToSet() internal view {
    require(isGovernance(msg.sender) || storyId == 0, "!gov");
  }

  function setBurnItemsMeta(
    uint storyId_,
    bytes32[] memory answerBurnRandomItemAnswerId,
    uint[] memory answerBurnRandomItemSlot,
    uint[] memory answerBurnRandomItemChance
  ) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setBurnItemsMeta(
      storyId_,
      answerBurnRandomItemAnswerId,
      answerBurnRandomItemSlot,
      answerBurnRandomItemChance
    );
  }

  function setNextChambersRewriteMeta(uint storyId_, IStoryController.NextChambersRewriteMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setNextChambersRewriteMeta(
      storyId_,
      meta
    );
  }

  function setAnswersMeta(uint storyId_, IStoryController.AnswersMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswersMeta(
      storyId_,
      meta
    );
  }

  function setAnswerNextPageMeta(uint storyId_, IStoryController.AnswerNextPageMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswerNextPageMeta(
      storyId_,
      meta
    );
  }

  function setAnswerAttributeRequirements(uint storyId_, IStoryController.AnswerAttributeRequirementsMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswerAttributeRequirements(
      storyId_,
      meta
    );
  }

  function setAnswerItemRequirements(uint storyId_, IStoryController.AnswerItemRequirementsMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswerItemRequirements(
      storyId_,
      meta
    );
  }

  function setAnswerTokenRequirementsMeta(uint storyId_, IStoryController.AnswerTokenRequirementsMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswerTokenRequirementsMeta(
      storyId_,
      meta
    );
  }

  function setAnswerRandomRequirementMeta(uint storyId_, IStoryController.AnswerRandomRequirementMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswerRandomRequirementMeta(
      storyId_,
      meta
    );
  }

  function setAnswerDelayRequirementMeta(uint storyId_, IStoryController.AnswerDelayRequirementMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswerDelayRequirementMeta(
      storyId_,
      meta
    );
  }

  function setAnswerHeroCustomDataRequirementMeta(uint storyId_, IStoryController.AnswerCustomDataMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswerHeroCustomDataRequirementMeta(
      storyId_,
      meta
    );
  }

  function setAnswerGlobalCustomDataRequirementMeta(uint storyId_, IStoryController.AnswerCustomDataMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setAnswerGlobalCustomDataRequirementMeta(
      storyId_,
      meta
    );
  }

  function setSuccessInfo(uint storyId_, IStoryController.AnswerResultMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setSuccessInfo(
      storyId_,
      meta
    );
  }

  function setFailInfo(uint storyId_, IStoryController.AnswerResultMeta memory meta) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setFailInfo(
      storyId_,
      meta
    );
  }

  function setCustomDataResult(
    uint storyId_,
    IStoryController.AnswerCustomDataResultMeta memory meta,
    IStoryController.CustomDataResult _type
  ) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setCustomDataResult(
      storyId_,
      meta,
      _type
    );
  }

  function setStoryFinalAnswers(uint storyId_, bytes32[] memory finalAnswers_) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setStoryFinalAnswers(
      storyId_,
      finalAnswers_
    );
  }

  function setStoryCustomDataRequirements(
    uint storyId_,
    bytes32[] memory requiredCustomDataIndex,
    uint[] memory requiredCustomDataMinValue,
    uint[] memory requiredCustomDataMaxValue,
    bool[] memory requiredCustomDataIsHero,
    uint minLevel
  ) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).setStoryCustomDataRequirements(
      storyId_,
      requiredCustomDataIndex,
      requiredCustomDataMinValue,
      requiredCustomDataMaxValue,
      requiredCustomDataIsHero,
      minLevel
    );
  }

  function finalizeStoryRegistration(uint storyId_) external {
    _isAbleToSet();

    IStoryController(IController(controller()).storyController()).finalizeStoryRegistration(storyId_);
    storyId = storyId_;
  }

  // ---- MAIN LOGIC ----

  function _action(
    address sender,
    address heroToken,
    uint heroTokenId,
    uint stageId,
    bytes memory data
  ) internal override returns (ChamberResult memory result) {
    require(storyId != 0, "story not inited");

    IController c = IController(controller());
    result = IStoryController(c.storyController()).storyAction(sender, msg.sender, address(this), stageId, heroToken, heroTokenId, data);

    if (result.completed) {
      IStatController statController = IStatController(c.statController());
      bytes32 index = bytes32(abi.encodePacked("STORY_", StringLib._toString(storyId)));
      uint curValue = statController.heroCustomData(heroToken, heroTokenId, index);
      statController.setHeroCustomData(
        heroToken,
        heroTokenId,
        index,
        curValue + 1
      );
    }
  }

  function isAvailableForHero(address heroToken, uint heroTokenId) external view override virtual returns (bool) {
    return IStoryController(IController(controller()).storyController()).isStoryAvailableForHero(address(this), heroToken, heroTokenId);
  }

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

interface IControllable {

  function VERSION() external pure returns (string memory);

  function revision() external view returns (uint);

  function previousImplementation() external view returns (address);

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

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

import "./IEvent.sol";

interface IStory is IEvent {

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

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


library StringLib {

  /// @dev Inspired by OraclizeAPI's implementation - MIT license
  ///      https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
  function toString(uint value) external pure returns (string memory) {
    return _toString(value);
  }

  function _toString(uint value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function toAsciiString(address x) external pure returns (string memory) {
    return _toAsciiString(x);
  }

  function _toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = _char(hi);
      s[2 * i + 1] = _char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) external pure returns (bytes1 c) {
    return _char(b);
  }

  function _char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
    // contract may have been reentered.
    require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} modifier, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  function _isConstructor() private view returns (bool) {
    return !Address.isContract(address(this));
  }


  // ----------------  Additional functions for reduce contract size

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  function _initializer() internal {
    // If the contract is initializing we ignore whether _initialized is set in order to support multiple
    // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
    // contract may have been reentered.
    require(_initializing ? _isConstructor() : !_initialized, "initialized");

    if (!_initializing) {
      _initializing = true;
      _initialized = true;
    }
  }

  function _finishInitializer() internal {
    if (!_initializing) {
      _initializing = false;
    }
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} modifier, directly or indirectly.
   */
  function _onlyInitializing() internal view {
    require(_initializing, "initializing");
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.17;

import "../openzeppelin/Initializable.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "1.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  // init implementation contract
  constructor() initializer {}

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) public {
    _onlyInitializing();
    require(controller_ != address(0), "Zero controller");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @notice Return true if given address is not a smart contract but a wallet address.
  /// @dev It is not 100% guarantee after EIP-3074 implementation, use it as an additional check.
  /// @return true if the address is a wallet.
  function _isNotSmartContract() internal view returns (bool) {
    return msg.sender == tx.origin;
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view override returns (uint) {
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view override returns (address) {
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

}