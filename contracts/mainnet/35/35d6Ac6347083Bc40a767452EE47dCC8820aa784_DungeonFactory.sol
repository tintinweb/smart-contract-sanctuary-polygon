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

import "../openzeppelin/EnumerableSet.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IHero.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IStatController.sol";
import "../interfaces/IChamber.sol";
import "../interfaces/IDungeon.sol";
import "../interfaces/IDungeonFactory.sol";
import "../interfaces/IChamberController.sol";
import "../proxy/ProxyControlled.sol";
import "../proxy/Controllable.sol";
import "../lib/StatLib.sol";
import "../lib/CalcLib.sol";

contract DungeonFactory is Controllable, IDungeonFactory {
  using EnumerableSet for EnumerableSet.AddressSet;

  // ---- CONSTANTS ----

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant override VERSION = "1.0.0";

  // ---- VARIABLES ----

  EnumerableSet.AddressSet internal _freeDungeons;
  mapping(uint => EnumerableSet.AddressSet) internal _freeDungeonsByBiomeLevel;
  /// @dev hero -> token -> biome -> completed
  mapping(address => mapping(uint => mapping(uint => bool))) public bossCompleted;
  /// @dev hero -> token -> dungeon logic -> completed
  mapping(address => mapping(uint => mapping(address => bool))) public specificDungeonCompleted;
  /// @dev hero -> token -> dungeon logic -> completed
  mapping(address => mapping(uint => uint)) public override maxBiomeCompleted;

  // ---- EVENTS ----

  event DungeonLaunched(
    address dungeon,
    address heroToken,
    uint heroTokenId,
    address treasuryToken,
    uint treasuryAmount
  );

  event FreeDungeonAdded(address dungeon);
  event BossCompleted(address dungeon, uint biome, address hero, uint heroId);
  event DungeonCompleted(address dungeon, address logic, address hero, uint heroId);
  event FreeDungeonRemoved(address dungeon);

  // ---- INITIALIZER ----

  function init(
    address controller_
  ) external initializer {
    __Controllable_init(controller_);
  }

  // ---- RESTRICTIONS ----

  function onlyDungeon() internal view {
    require(IController(controller()).validDungeons(msg.sender), "Not dungeon");
  }

  function onlyChamber() internal view {
    require(IChamberController(IController(controller()).chamberController()).validChambers(msg.sender), "Not chamber");
  }

  // ---- VIEWS ----

  function freeDungeonsLength() external view returns (uint) {
    return _freeDungeons.length();
  }

  function freeDungeons(uint id) external view returns (address) {
    return _freeDungeons.at(id);
  }

  function freeDungeonsByLevelLength(uint level_) external view returns (uint) {
    return _freeDungeonsByBiomeLevel[level_].length();
  }

  function freeDungeonsByLevel(uint id, uint level_) external view returns (address) {
    return _freeDungeonsByBiomeLevel[level_].at(id);
  }

  function dungeonTreasuryReward(
    uint minLevelForTreasury,
    uint treasuryBalance,
    uint heroLevel,
    uint dungeonBiome
  ) public pure returns (uint) {
    require(heroLevel <= StatLib.MAX_LEVEL, "Wrong level");
    // we need some initial gap as protection against bots
    require(minLevelForTreasury >= 5, "Wrong min level for treasury");
    if (heroLevel < minLevelForTreasury) {
      return 0;
    }
    uint biomeLevel = dungeonBiome * StatLib.BIOME_LEVEL_STEP;

    // StatLib.log2((StatLib.MAX_LEVEL + 1) * 1e18);
    uint maxMultiplier = 6643856189774724682;
    uint multiplier = (maxMultiplier - CalcLib.log2((StatLib.MAX_LEVEL - biomeLevel + 1) * 1e18)) / 1000;
    require(multiplier < 1e18, "Wrong multiplier");
    uint base = treasuryBalance * multiplier / 1e18;


    if (biomeLevel < heroLevel) {
      // reduce base on biome difference
      base = base / 2 ** (heroLevel - biomeLevel);
    }
    return base;
  }

  function getDungeonLogic(IController _controller, uint heroLevel, address heroToken, uint heroTokenId, uint random) public view returns (address) {
    require(heroLevel != 0, "Hero level start from 1");

    // specific dungeon for concrete lvl and class
    address specificDungeon = _controller.dungeonSpecific(heroLevel, IHero(heroToken).heroClass());
    // if no specific dungeon for concrete class try to find for all classes
    if (specificDungeon == address(0)) {
      specificDungeon = _controller.dungeonSpecific(heroLevel, 0);
    }
    if (specificDungeon != address(0)) {
      if (!specificDungeonCompleted[heroToken][heroTokenId][specificDungeon]) {
        return specificDungeon;
      }
    }

    uint heroBiome = IHero(heroToken).heroBiome(heroTokenId);
    uint size = _controller.dungeonImplLength(heroBiome);
    require(size != 0, "No dungeons for this biome!");

    address dungeonLogic;
    uint dungeonIndex = random % size;
    for (uint i; i < size; ++i) {
      dungeonLogic = _controller.dungeonImplByBiomeLevel(heroBiome, dungeonIndex);

      if (isDungeonEligibleForHero(address(_controller), dungeonLogic, heroLevel, heroToken, heroTokenId)) {
        return dungeonLogic;
      }
      dungeonIndex++;
      if (dungeonIndex >= size) {
        dungeonIndex = 0;
      }
    }

    revert("No eligible dungeons");
  }

  function isDungeonEligibleForHero(address _controller, address dungeonLogic, uint heroLevel, address heroToken, uint heroTokenId) public view override returns (bool) {
    IDungeon.ChamberGenerateInfo memory info = IDungeon(dungeonLogic).dungeonGenerateInfo();
    IStatController statController = IStatController(IController(_controller).statController());

    if (heroLevel < info.minLevel || heroLevel > info.maxLevel) {
      return false;
    }

    for (uint i; i < info.requiredCustomDataIndex.length; ++i) {
      bytes32 index = info.requiredCustomDataIndex[i];
      uint min = info.requiredCustomDataMinValue[i];
      uint max = info.requiredCustomDataMaxValue[i];
      bool isHeroValue = info.requiredCustomDataIsHero[i];

      if (index == bytes32(0)) {
        continue;
      }

      uint value;
      if (isHeroValue) {
        value = statController.heroCustomData(heroToken, heroTokenId, index);
      } else {
        value = statController.globalCustomData(index);
      }
      if (value < min || value > max) {
        return false;
      }
    }


    return true;
  }

  /// @dev Easily get info should given hero fight with boss in the current biome or not.
  function isBiomeBoss(address heroToken, uint heroTokenId) external view returns (bool) {
    uint heroBiome = IHero(heroToken).heroBiome(heroTokenId);
    return bossCompleted[heroToken][heroTokenId][heroBiome];
  }

  // ---- ACTIONS ----

  function launch(address heroToken, uint heroTokenId, address treasuryToken) external returns (address) {
    require(_isNotSmartContract(), "Only EOA");
    IController _controller = IController(controller());
    require(_controller.validHeroes(heroToken), "Not hero");
    require(_controller.validTreasuryTokens(treasuryToken), "!token");
    require(IHero(heroToken).isOwner(msg.sender, heroTokenId), "Not hero owner");
    uint heroLevel = IHero(heroToken).stats(heroTokenId).level;

    address dungeonLogic = _getDungeonLogic(_controller, heroLevel, heroToken, heroTokenId);
    address dungeonProxy = address(new ProxyControlled(dungeonLogic));

    IController(controller()).registerDungeon(dungeonProxy);

    IDungeon(dungeonProxy).init(
      address(_controller),
      IDungeon(dungeonLogic).dungeonGenerateInfo(),
      IDungeon(dungeonLogic).dungeonName(),
      IDungeon(dungeonLogic).uri(),
      IDungeon(dungeonLogic).biome()
    );

    IDungeon(dungeonProxy).initDungeonWithHero(
      heroToken,
      heroTokenId,
      treasuryToken
    );

    ITreasury treasury = ITreasury(_controller.treasury());
    uint treasuryAmount = dungeonTreasuryReward(
      _controller.minLevelForTreasury(treasuryToken),
      treasury.balanceOfToken(treasuryToken),
      heroLevel,
      IDungeon(dungeonProxy).biome()
    );
    if (treasuryAmount != 0) {
      ITreasury(treasury).sendToDungeon(dungeonProxy, treasuryToken, treasuryAmount);
    }

    emit DungeonLaunched(dungeonProxy, heroToken, heroTokenId, treasuryToken, treasuryAmount);
    return dungeonProxy;
  }

  function addFreeDungeon() external override {
    onlyDungeon();
    require(_freeDungeons.add(msg.sender), "Dungeon not free");
    require(_freeDungeonsByBiomeLevel[IDungeon(msg.sender).biome()].add(msg.sender), "Dungeon not free by level");
    emit FreeDungeonAdded(msg.sender);
  }

  function setBossCompleted(address heroToken, uint heroTokenId) external override {
    onlyChamber();
    uint heroBiome = IHero(heroToken).heroBiome(heroTokenId);
    bossCompleted[heroToken][heroTokenId][heroBiome] = true;
    uint maxBiome = maxBiomeCompleted[heroToken][heroTokenId];
    if (maxBiome < heroBiome) {
      maxBiomeCompleted[heroToken][heroTokenId] = heroBiome;
    }
    emit BossCompleted(msg.sender, heroBiome, heroToken, heroTokenId);
  }

  function setDungeonCompleted(address heroToken, uint heroTokenId) external override {
    onlyDungeon();
    address dungeonLogic = IProxyControlled(msg.sender).implementation();
    specificDungeonCompleted[heroToken][heroTokenId][dungeonLogic] = true;
    emit DungeonCompleted(msg.sender, dungeonLogic, heroToken, heroTokenId);
  }

  /// @dev Can be called with not existing dungeon
  function removeFreeDungeon() external override {
    onlyDungeon();
    _freeDungeons.remove(msg.sender);
    _freeDungeonsByBiomeLevel[IDungeon(msg.sender).biome()].remove(msg.sender);
    emit FreeDungeonRemoved(msg.sender);
  }

  function _getDungeonLogic(IController _controller, uint heroLevel, address heroToken, uint heroTokenId) internal returns (address) {
    return getDungeonLogic(_controller, heroLevel, heroToken, heroTokenId, IOracle(_controller.oracle()).getRandomNumber(1e18, heroLevel));
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

import "./IChamber.sol";

interface IDungeon {

  struct DungeonTreasury {
    address token;
    uint amount;
  }

  struct ChamberGenerateInfo {
    uint[][] chamberTypesByStages;
    uint[][] chamberChancesByStages;

    address[] uniqChambers;

    uint minLevel;
    uint maxLevel;

    bytes32[] requiredCustomDataIndex;
    uint[] requiredCustomDataMinValue;
    uint[] requiredCustomDataMaxValue;
    bool[] requiredCustomDataIsHero;
  }

  function init(
    address controller,
    ChamberGenerateInfo memory info_,
    string memory dungeonName_,
    string memory uri_,
    uint biome_
  ) external;

  function initDungeonWithHero(
    address heroToken_,
    uint heroTokenId_,
    address payToken_
  ) external;

  function dungeonGenerateInfo() external view returns (ChamberGenerateInfo memory);

  function dungeonName() external view returns (string memory);

  function stages() external view returns (uint);

  function uri() external view returns (string memory);

  function biome() external view returns (uint);

  function IS_DUNGEON() external pure returns (bool);

  function isCompleted() external view returns (bool);

  function enteredHero() external view returns (address token, uint id);

  function enteredHeroOwner() external view returns (address);

  function currentChamberIndex() external view returns (uint);

  function currentChamber() external view returns (IChamber);

  function openChamber() external;

  function chamberAction(bytes memory data) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IDungeonFactory {

  function maxBiomeCompleted(address heroToken, uint heroTokenId) external view returns (uint);

  function addFreeDungeon() external;

  function setBossCompleted(address heroToken, uint heroTokenId) external;

  function setDungeonCompleted(address heroToken, uint heroTokenId) external;

  function removeFreeDungeon() external;

  function isDungeonEligibleForHero(address _controller, address dungeonLogic, uint heroLevel, address heroToken, uint heroTokenId) external view returns (bool);

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

interface IOracle {

  function getRandomNumber(uint max, uint seed) external returns (uint);

  function getRandomNumberInRange(uint min, uint max, uint seed) external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IProxyControlled {

  function upgrade(address _newImplementation) external;

  function implementation() external view returns (address);

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

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
  /**
   * @dev Delegates the current call to `implementation`.
   *
   * This function does not return to its internall call site, it will return directly to the external caller.
   */
  function _delegate(address implementation) internal virtual {
    assembly {
    // Copy msg.data. We take full control of memory in this inline assembly
    // block because it will not return to Solidity code. We overwrite the
    // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

    // Call the implementation.
    // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

    // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
   * and {_fallback} should delegate.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates the current call to the address returned by `_implementation()`.
   *
   * This function does not return to its internall call site, it will return directly to the external caller.
   */
  function _fallback() internal virtual {
    _beforeFallback();
    _delegate(_implementation());
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
   * function in the contract matches the call data.
   */
  fallback() external payable virtual {
    _fallback();
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
   * is empty.
   */
  receive() external payable virtual {
    _fallback();
  }

  /**
   * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
   * call, or as part of the Solidity `fallback` or `receive` functions.
   *
   * If overriden should call `super._beforeFallback()`.
   */
  function _beforeFallback() internal virtual {}
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


import "./UpgradeableProxy.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IProxyControlled.sol";

/// @title EIP1967 Upgradable proxy implementation.
/// @dev Only Controller has access and should implement time-lock for upgrade action.
/// @author belbix
contract ProxyControlled is UpgradeableProxy, IProxyControlled {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant PROXY_CONTROLLED_VERSION = "1.0.0";


  constructor(address _logic) UpgradeableProxy(_logic) {
    //make sure that given logic is controllable
    require(IControllable(_logic).created() >= 0);
  }

  /// @notice Upgrade contract logic
  /// @dev Upgrade allowed only for Controller and should be done only after time-lock period
  /// @param _newImplementation Implementation address
  function upgrade(address _newImplementation) external override {
    require(IControllable(address(this)).isController(msg.sender), "Proxy: Forbidden");
    IControllable(address(this)).increaseRevision(_implementation());
    _upgradeTo(_newImplementation);
    // the new contract must have the same ABI and you must have the power to change it again
    require(IControllable(address(this)).isController(msg.sender), "Proxy: Wrong implementation");
  }

  /// @notice Return current logic implementation
  function implementation() external override view returns (address) {
    return _implementation();
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

import "../openzeppelin/Proxy.sol";
import "../openzeppelin/Address.sol";


/// @title OpenZeppelin https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/proxy/UpgradeableProxy.sol
/// @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
///      implementation address that can be changed. This address is stored in storage in the location specified by
///      https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
///      implementation behind the proxy.
///      Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
///      {TransparentUpgradeableProxy}.
abstract contract UpgradeableProxy is Proxy {

  /// @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
  ///      If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
  ///      function call, and allows initializating the storage of the proxy like a Solidity constructor.
  constructor(address _logic) payable {
    assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    _setImplementation(_logic);
  }

  /// @dev Emitted when the implementation is upgraded.
  event Upgraded(address indexed implementation);

  ///@dev Storage slot with the address of the current implementation.
  ///     This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
  ///     validated in the constructor.
  bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /// @dev Returns the current implementation address.
  function _implementation() internal view virtual override returns (address impl) {
    bytes32 slot = _IMPLEMENTATION_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(slot)
    }
  }

  /// @dev Upgrades the proxy to a new implementation.
  ///      Emits an {Upgraded} event.
  function _upgradeTo(address newImplementation) internal virtual {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /// @dev Stores a new address in the EIP1967 implementation slot.
  function _setImplementation(address newImplementation) private {
    require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

    bytes32 slot = _IMPLEMENTATION_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newImplementation)
    }
  }
}