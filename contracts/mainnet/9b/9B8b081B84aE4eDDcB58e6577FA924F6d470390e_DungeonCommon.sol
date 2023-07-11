// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../openzeppelin/IERC20.sol";
import "../openzeppelin/IERC721.sol";
import "../openzeppelin/SafeERC20.sol";
import "../openzeppelin/EnumerableSet.sol";
import "../openzeppelin/ERC721Holder.sol";
import "../interfaces/IHero.sol";
import "../interfaces/IDungeon.sol";
import "../interfaces/IChamber.sol";
import "../interfaces/IItem.sol";
import "../interfaces/IStatController.sol";
import "../interfaces/IDungeonFactory.sol";
import "../interfaces/IGameToken.sol";
import "../interfaces/IMinter.sol";
import "../interfaces/IReinforcementController.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IChamberController.sol";
import "../interfaces/IMonster.sol";
import "../interfaces/IProxyControlled.sol";
import "../proxy/Controllable.sol";
import "../lib/SlotsLib.sol";
import "../lib/CalcLib.sol";

abstract contract DungeonBase is Controllable, IDungeon, ERC721Holder {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  // ---- CONSTANTS ----

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant DUNGEON_BASE_VERSION = "1.0.0";
  /// @dev Indicate that this contract is dungeon
  bool public constant override IS_DUNGEON = true;

  // ---- VARIABLES ----

  // ---- these variables should be inited in logic contract too
  bool internal logicInited;
  string public override dungeonName;
  uint public override stages;
  string public override uri;
  uint public override biome;
  // ----

  bool public override isCompleted;
  address public heroToken;
  uint public heroTokenId;

  ChamberGenerateInfo internal _info;
  bool internal _heroInited;

  IChamber public override currentChamber;
  uint public override currentChamberIndex;

  EnumerableSet.AddressSet internal _treasuryTokens;
  IStatController.NftItem[] public treasuryItems;

  // ---- EVENTS ----

  event ChamberOpened(address hero, uint id, address chamber, uint iteration);
  event ChamberAction(
    IChamber.ChamberResult result,
    uint chamberIndex,
    address heroToken,
    uint heroTokenId
  );
  event Entered(address hero, uint id);
  event ClaimToken(address token, uint amount);
  event ClaimItem(address token, uint id);
  event Exit(bool claim);
  event Clear();
  event UriChanged(string uri);
  event NameChanged(string name);
  event AddTreasuryItem(address itemAdr, uint itemId);
  event AddTreasuryToken(address token, uint amount);

  // ---- INITIALIZER ----

  function __DungeonBase_init(
    address controller_,
    ChamberGenerateInfo memory info_,
    string memory dungeonName_,
    string memory uri_,
    uint biome_
  ) internal {
    _onlyInitializing();

    __Controllable_init(controller_);

    _info = info_;
    dungeonName = dungeonName_;
    stages = _checkChamberInfo(info_);
    uri = uri_;
    biome = biome_;

    logicInited = true;
  }

  /// @dev Init dungeon in logic implementation contract.
  function initDungeonLogic(
    ChamberGenerateInfo memory info_,
    string memory dungeonName_,
    string memory uri_,
    uint biome_
  ) external {
    require(!logicInited);

    _info = info_;
    dungeonName = dungeonName_;
    stages = _checkChamberInfo(info_);
    uri = uri_;
    biome = biome_;

    logicInited = true;
  }

  function initDungeonWithHero(
    address heroToken_,
    uint heroTokenId_,
    address payToken_
  ) external override {
    require(!_heroInited, "inited");
    require(IController(controller()).dungeonFactory() == msg.sender, "!factory");

    _heroInited = true;
    _treasuryTokens.add(payToken_);
    _enter(heroToken_, heroTokenId_);
  }

  // ---- RESTRICTIONS ----

  function onlyCompleted() internal view {
    require(isCompleted, "Not completed");
  }

  function onlyEnteredHeroOwner() internal view {
    require(IHero(heroToken).isOwner(msg.sender, heroTokenId), "Not hero owner");
  }

  function onlyCurrentHero(address _heroToken, uint _heroTokenId, IStatController statController) internal view {
    require(IHero(_heroToken).isOwner(msg.sender, _heroTokenId), "Not hero owner");
    require(!isCompleted, "Dungeon completed");
    require(IHero(_heroToken).currentDungeon(_heroTokenId) == address(this), "Hero not in dungeon");
    require(statController.isHeroAlive(_heroToken, _heroTokenId), "Hero is dead");
  }

  // ---- VIEWS ----

  function dungeonGenerateInfo() external view override returns (ChamberGenerateInfo memory) {
    return _info;
  }

  function enteredHero() external view override returns (address token, uint id) {
    return (heroToken, heroTokenId);
  }

  function enteredHeroOwner() external view override returns (address) {
    return IERC721(heroToken).ownerOf(heroTokenId);
  }

  function treasuryTokensLength() external view returns (uint) {
    return _treasuryTokens.length();
  }

  function treasuryTokens(uint index) external view returns (address) {
    return _treasuryTokens.at(index);
  }

  function treasuryItemsLength() external view returns (uint) {
    return treasuryItems.length;
  }

  // ---- GOV ACTIONS ----

  function setUri(string memory value) external {
    require(isGovernance(msg.sender), "!gov");
    uri = value;
    emit UriChanged(value);
  }

  function setName(string memory value) external {
    require(isGovernance(msg.sender), "!gov");
    dungeonName = value;
    emit NameChanged(value);
  }

  /// @dev Governance can drop hero from dungeon in emergency case
  function emergencyExit() external {
    require(isGovernance(msg.sender), "!gov");
    _exit(heroToken, heroTokenId);
    isCompleted = true;
    heroToken = address(0);
    heroTokenId = 0;
    emit Exit(false);
  }

  // ---- USER ACTIONS ----

  function enter(address heroToken_, uint heroTokenId_) external {
    require(_isNotSmartContract(), "Only EOA");
    require(IERC721(heroToken_).ownerOf(heroTokenId_) == msg.sender, "Not owner");

    _enter(heroToken_, heroTokenId_);
  }

  function openChamber() external override {
    require(_isNotSmartContract(), "Only EOA");
    require(address(currentChamber) == address(0), "!ready");

    address _heroToken = heroToken;
    uint _heroTokenId = heroTokenId;
    IController _controller = IController(controller());
    IStatController statController = IStatController(_controller.statController());

    onlyCurrentHero(_heroToken, _heroTokenId, statController);

    IChamber _chamber = _generateChamber(_heroToken, _heroTokenId);
    currentChamber = _chamber;
    // generate some info for UI
    uint iteration = _chamber.open(_heroToken, _heroTokenId);

    emit ChamberOpened(_heroToken, _heroTokenId, address(_chamber), iteration);
  }

  function chamberAction(bytes memory data) external override {
    require(_isNotSmartContract(), "Only EOA");

    address _heroToken = heroToken;
    uint _heroTokenId = heroTokenId;
    IController _controller = IController(controller());
    IStatController statController = IStatController(_controller.statController());

    onlyCurrentHero(_heroToken, _heroTokenId, statController);

    IChamber _chamber = currentChamber;
    uint _currentChamberId = currentChamberIndex;
    IChamber.ChamberResult memory result = _chamber.action(
      msg.sender,
      _heroToken,
      _heroTokenId,
      _currentChamberId,
      data
    );

    if (isBattleChamber(_chamber)) {
      IFightCalculator(IController(controller()).fightCalculator()).markSkillSlotsForDurabilityReduction(data, _heroToken, _heroTokenId);
    }

    IStatController.ChangeableStats memory stats = statController.heroStats(_heroToken, _heroTokenId);

    require(stats.mana >= result.manaConsumed, "Not enough mana");

    if (result.kill || stats.life <= result.damage) {
      result.kill == true;
      IHero(_heroToken).changeCurrentDungeon(_heroTokenId, address(0));
      IHero(_heroToken).releaseReinforcement(_heroTokenId);

      // no need to release if we completed the dungeon - we will never back on the same
      IFightCalculator(IController(controller()).fightCalculator()).releaseSkillSlotsForDurabilityReduction(_heroToken, _heroTokenId);

      // if it was the last life chance - kill the hero
      if (stats.lifeChances <= 1) {
        _killHero(_heroToken, _heroTokenId);
      } else {
        _afterChamberCompleteForSurvivedHero(statController, _heroToken, _heroTokenId, _chamber);
        _reduceLifeChances(statController, _heroToken, _heroTokenId, stats.life, stats.mana);
      }
      _clear();
    } else {
      _increaseChangeableStats(statController, _heroToken, _heroTokenId, result);
      _decreaseChangeableStats(statController, _heroToken, _heroTokenId, result);
      _mintItems(result);
      if (result.completed) {
        _afterChamberCompleteForSurvivedHero(statController, _heroToken, _heroTokenId, _chamber);
        _nextRoomOrComplete(_currentChamberId, _controller, stats.level, result.rewriteNextChamber);
      }
    }

    emit ChamberAction(result, _currentChamberId, _heroToken, _heroTokenId);
  }

  function exit(bool claim) external {
    onlyCompleted();
    address _heroToken = heroToken;
    uint _heroTokenId = heroTokenId;

    IDungeonFactory(IController(controller()).dungeonFactory()).setDungeonCompleted(_heroToken, _heroTokenId);

    require(IHero(_heroToken).isOwner(msg.sender, _heroTokenId), "Not hero owner");
    if (claim) {
      _claimAll();
    }
    _exit(_heroToken, _heroTokenId);
    emit Exit(claim);
  }

  function claimToken(address token) external {
    onlyEnteredHeroOwner();
    onlyCompleted();

    (address helpHeroToken, uint helpHeroId) = IHero(heroToken).heroReinforcementHelp(heroTokenId);
    uint toHelperRatio = IReinforcementController(IController(controller()).reinforcementController()).toHelperRatio(helpHeroToken, helpHeroId);
    _claimToken(token, helpHeroToken, helpHeroId, toHelperRatio);
  }

  function claimItem(address token, uint tokenId) external {
    onlyEnteredHeroOwner();
    onlyCompleted();
    (address helpHeroToken, uint helpHeroId) = IHero(heroToken).heroReinforcementHelp(heroTokenId);
    uint toHelperRatio = IReinforcementController(IController(controller()).reinforcementController()).toHelperRatio(helpHeroToken, helpHeroId);
    _claimItem(token, tokenId, helpHeroToken, helpHeroId, toHelperRatio);
  }

  // ---- INTERNAL LOGIC ----

  function _enter(address heroToken_, uint heroTokenId_) internal {
    IStatController.ChangeableStats memory stats = IHero(heroToken_).stats(heroTokenId_);
    require(IHero(heroToken_).currentDungeon(heroTokenId_) == address(0), "Already in dungeon");
    require(stats.life > 0, "Hero is dead");
    require(!isCompleted, "Dungeon completed");
    require(heroToken == address(0), "Dungeon busy");
    address c = controller();
    require(IController(c).validHeroes(heroToken_), "Not hero");

    IDungeonFactory dungeonFactory = IDungeonFactory(IController(c).dungeonFactory());
    require(dungeonFactory.isDungeonEligibleForHero(
      c,
      IProxyControlled(address(this)).implementation(),
      stats.level,
      heroToken_,
      heroTokenId_
    ), "Not eligible");

    dungeonFactory.removeFreeDungeon();

    IHero(heroToken_).changeCurrentDungeon(heroTokenId_, address(this));
    currentChamberIndex = uint(0);
    heroToken = heroToken_;
    heroTokenId = heroTokenId_;
    emit Entered(heroToken_, heroTokenId_);
  }

  /// @dev Not necessary to call if a hero is dead
  function _afterChamberCompleteForSurvivedHero(
    IStatController statController,
    address _heroToken,
    uint _heroTokenId,
    IChamber chamber
  ) internal {
    if (isBattleChamber(chamber)) {
      // reduce item durability
      IHero(_heroToken).reduceDurability(_heroTokenId, biome);
      // clear temporally attributes
      statController.clearTemporallyAttributes(_heroToken, _heroTokenId);
    }
  }

  function isBattleChamber(IChamber chamber) public view returns (bool){
    bool isMonster;
    try IMonster(address(chamber)).race() returns (uint){
      isMonster = true;
    }catch {}

    return isMonster;
  }

  function _killHero(address _heroToken, uint _heroTokenId) internal {
    (IStatController.NftItem[] memory drop, uint tokenAmount) = IHero(_heroToken).kill(_heroTokenId);
    uint dropLength = drop.length;
    for (uint i; i < dropLength;) {
      treasuryItems.push(drop[i]);
      emit AddTreasuryItem(drop[i].token, drop[i].tokenId);
      unchecked{++i;}
    }
    address token = IHero(_heroToken).payToken();
    _registerTreasuryToken(token);
    emit AddTreasuryToken(token, tokenAmount);
  }

  function _reduceLifeChances(
    IStatController statController,
    address _heroToken,
    uint _heroTokenId,
    uint curLife,
    uint curMana
  ) internal {
    statController.changeCurrentStats(
      _heroToken,
      _heroTokenId,
      IStatController.ChangeableStats({
        level: 0,
        experience: 0,
        life: curLife - 1,
        mana: curMana,
        lifeChances: 1
      }),
      false
    );
  }

  function _increaseChangeableStats(
    IStatController statController,
    address _heroToken,
    uint _heroTokenId,
    IChamber.ChamberResult memory result
  ) internal {
    if (result.heal != 0 || result.manaRegen != 0 || result.experience != 0 || result.lifeChancesRecovered != 0) {
      if (result.experience != 0) {
        // assume that each fight has experience
        IHero(_heroToken).refreshLastFight(_heroTokenId);
      }
      statController.changeCurrentStats(
        _heroToken,
        _heroTokenId,
        IStatController.ChangeableStats({
          level: 0,
          experience: result.experience,
          life: result.heal,
          mana: result.manaRegen,
          lifeChances: result.lifeChancesRecovered
        }),
        true
      );
    }
  }

  function _decreaseChangeableStats(
    IStatController statController,
    address _heroToken,
    uint _heroTokenId,
    IChamber.ChamberResult memory result
  ) internal {
    // decrease changeable stats
    if (result.damage != 0 || result.manaConsumed != 0) {
      statController.changeCurrentStats(
        _heroToken,
        _heroTokenId,
        IStatController.ChangeableStats({
          level: 0,
          experience: 0,
          life: result.damage,
          mana: result.manaConsumed,
          lifeChances: 0
        }),
        false
      );
    }
  }

  function _mintItems(IChamber.ChamberResult memory result) internal {
    for (uint i; i < result.mintItems.length; i++) {
      if (result.mintItems[i] == address(0)) {
        continue;
      }
      uint itemId = IItem(result.mintItems[i]).mint();
      treasuryItems.push(IStatController.NftItem(result.mintItems[i], itemId));
      emit AddTreasuryItem(result.mintItems[i], itemId);
    }
  }

  function _nextRoomOrComplete(uint _currentChamberId, IController _controller, uint heroLvl, address rewriteNextChamber) internal {
    if (_currentChamberId + 1 >= stages) {
      _mintGameTokens(_controller, heroLvl);
      isCompleted = true;
    } else {

      if (rewriteNextChamber != address(0)) {
        _info.uniqChambers[_currentChamberId + 1] = rewriteNextChamber;
      }

      currentChamberIndex = _currentChamberId + 1;
    }
    currentChamber = IChamber(address(0));
  }

  function _mintGameTokens(IController _controller, uint heroLvl) private {
    address gameToken = _controller.gameToken();
    _registerTreasuryToken(gameToken);
    uint amount = IMinter(IGameToken(gameToken).minter()).mintDungeonReward(biome, heroLvl);
    emit AddTreasuryToken(gameToken, amount);
  }

  function _registerTreasuryToken(address rewardToken) internal {
    if (!_treasuryTokens.contains(rewardToken)) {
      _treasuryTokens.add(rewardToken);
    }
  }

  function _claimAll() internal {
    (address helpHeroToken, uint helpHeroId) = IHero(heroToken).heroReinforcementHelp(heroTokenId);
    uint toHelperRatio = IReinforcementController(IController(controller()).reinforcementController()).toHelperRatio(helpHeroToken, helpHeroId);
    for (uint i; i < _treasuryTokens.length(); i++) {
      _claimToken(_treasuryTokens.at(i), helpHeroToken, helpHeroId, toHelperRatio);
    }

    for (uint i; i < treasuryItems.length; i++) {
      _claimItem(treasuryItems[i].token, treasuryItems[i].tokenId, helpHeroToken, helpHeroId, toHelperRatio);
    }
  }

  function _claimToken(address token, address helpHeroToken, uint helpHeroId, uint toHelperRatio) internal {
    uint amount = IERC20(token).balanceOf(address(this));
    if (amount > 0) {
      uint toHelper = helpHeroToken == address(0) ? 0 : amount * toHelperRatio / 100;
      uint toHeroOwner = amount - toHelper;
      if (toHeroOwner != 0) {
        IERC20(token).safeTransfer(msg.sender, toHeroOwner);
      }
      if (toHelper != 0) {
        address rc = IController(controller()).reinforcementController();
        IERC20(token).safeTransfer(rc, toHelper);
        IReinforcementController(rc).registerTokenReward(helpHeroToken, helpHeroId, token, toHelper);
      }
    }
    emit ClaimToken(token, amount);
  }

  function _claimItem(address token, uint tokenId, address helpHeroToken, uint helpHeroId, uint toHelperRatio) internal {
    if (IERC721(token).ownerOf(tokenId) == address(this)) {
      bool toHelper = false;
      if (helpHeroToken != address(0)) {
        toHelper = IOracle(IController(controller()).oracle()).getRandomNumber(100, tokenId + helpHeroId) < toHelperRatio;
      }

      if (toHelper) {
        address rc = IController(controller()).reinforcementController();
        IERC721(token).safeTransferFrom(address(this), rc, tokenId);
        IReinforcementController(rc).registerNftReward(helpHeroToken, helpHeroId, token, tokenId);
      } else {
        IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
      }
      emit ClaimItem(token, tokenId);
    }
  }

  function _exit(address _heroToken, uint _heroTokenId) internal {
    IHero(_heroToken).changeCurrentDungeon(_heroTokenId, address(0));
    IHero(_heroToken).releaseReinforcement(_heroTokenId);
  }

  function _clear() internal {
    heroToken = address(0);
    heroTokenId = uint(0);
    currentChamber = IChamber(address(0));
    currentChamberIndex = 0;
    IDungeonFactory(IController(controller()).dungeonFactory()).addFreeDungeon();
    emit Clear();
  }

  function _generateChamber(
    address _heroToken,
    uint _heroTokenId
  ) internal returns (IChamber chamber) {
    uint stage = currentChamberIndex;
    require(stage < stages, "Wrong chamber");

    address uniqChamber = _info.uniqChambers[stage];
    if (uniqChamber != address(0)) {
      return IChamber(uniqChamber);
    } else {
      uint[] memory cTypes = _info.chamberTypesByStages[stage];
      uint[] memory chances = _info.chamberChancesByStages[stage];
      return IChamber(IChamberController(IController(controller()).chamberController())
      .getRandomChamber(cTypes, chances, biome, _heroToken, _heroTokenId));
    }
  }

  function _checkChamberInfo(ChamberGenerateInfo memory info_) internal view returns (uint) {
    require(_info.chamberChancesByStages.length == _info.chamberTypesByStages.length
    && _info.chamberTypesByStages.length == _info.uniqChambers.length, "!stages");
    for (uint i; i < info_.chamberChancesByStages.length; ++i) {
      require(info_.chamberChancesByStages[i].length == _info.chamberTypesByStages[i].length, "!chances");
    }
    return _info.chamberChancesByStages.length;
  }

  /// @dev This empty reserved space is put in place to allow future versions to add new
  ///      variables without shifting down storage in the inheritance chain.
  ///      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  uint256[47] private __gap;

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

import "../base/DungeonBase.sol";

contract DungeonCommon is DungeonBase {

  // ---- CONSTANTS ----

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant override VERSION = "1.0.2";

  // ---- INITIALIZER ----

  function init(
    address controller_,
    ChamberGenerateInfo memory info_,
    string memory dungeonName_,
    string memory uri_,
    uint biome_
  ) external initializer override {
    __DungeonBase_init(
      controller_,
      info_,
      dungeonName_,
      uri_,
      biome_
    );
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

import "../openzeppelin/IERC20.sol";

interface IGameToken is IERC20 {

  function minter() external view returns (address);

  function mint(address account, uint amount) external returns (bool);

  function burn(uint amount) external returns (bool);

  function setMinter(address _minter) external;

  function pause(bool value) external;

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


interface IMinter {

  function mintDungeonReward(uint dungeonBiomeLevel, uint heroLvl) external  returns (uint amount);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IFightCalculator.sol";

interface IMonster {

  struct MonsterGenerateInfo {
    uint[] ids;
    uint[] values;
    uint level;
    uint experience;
    IFightCalculator.AttackInfo attackInfo;
  }

  function race() external view returns (uint);

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

import "./IStatController.sol";

interface IReinforcementController {

  function toHelperRatio(address heroToken, uint heroId) external view returns (uint);

  function isStaked(address heroToken, uint heroId) external view returns (bool);

  function askHero(uint biome) external returns (address heroToken, uint heroId, uint[] memory attributes);

  function registerTokenReward(address heroToken, uint heroId, address token, uint amount) external;

  function registerNftReward(address heroToken, uint heroId, address token, uint tokenId) external;

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

import "./IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   *
   * Always returns `IERC721Receiver.onERC721Received.selector`.
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
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