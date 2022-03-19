/**
 *Submitted for verification at polygonscan.com on 2022-03-18
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: Unlicense
interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IDrawSvg {
  function drawSvg(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
  function drawSvgNew(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
}

interface INameChange {
  function changeName(address owner, uint256 id, string memory newName) external;
}

interface IDogewood {
    // struct to store each token's traits
    struct Doge2 {
        uint8 head;
        uint8 breed;
        uint8 color;
        uint8 class;
        uint8 armor;
        uint8 offhand;
        uint8 mainhand;
        uint16 level;
        uint16 breedRerollCount;
        uint16 classRerollCount;
        uint8 artStyle; // 0: new, 1: old
    }

    function getTokenTraits(uint256 tokenId) external view returns (Doge2 memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwnerOfDoge(uint256 id, address who_) external view returns (bool);
    function unstakeForQuest(address[] memory owners, uint256[] memory ids) external;
    function updateQuestCooldown(uint256[] memory doges, uint88 timestamp) external;
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level, uint16 breedRerollCount, uint16 classRerollCount, uint8 artStyle) external;
    function transfer(address to, uint256 tokenId) external;
    // function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
}

// interface DogeLike {
//     function pull(address owner, uint256[] calldata ids) external;
//     function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level) external;
//     function transfer(address to, uint256 tokenId) external;
//     function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

// interface DogewoodLike {
//     function ownerOf(uint256 id) external view returns (address owner_);
//     function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
//     function doges(uint256 dogeId) external view returns (uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface QuestLike {
    struct GroupConfig {
        uint16 lvlFrom;
        uint16 lvlTo;
        uint256 entryFee; // additional entry $TREAT
        uint256 initPrize; // init prize pool $TREAT
    }
    struct Leaderboard {
        uint256 performId; // unique id to distinguish leaderboard updates
        uint88 timestamp;
        uint256 prizePool; // daily total gathered to distribute
        uint256 prizeAmount; // 40%
        uint256 burnAmount; // 55%
        uint256 teamAmount; // 5%
        mapping(uint256 => Action) winners; // Action[5] winners; rank => Action
        mapping(uint256 => uint256[]) scores; // rank => finalScore
    }
    struct Action {
        uint256 id; // unique id to distinguish activities
        uint88 timestamp;
        uint256[] doges;
        address[] owners;
        uint256[] scores;
    }

    function doQuestByAdmin(uint256[] memory doges, address[] memory owners, uint256[] memory scores, uint8 groupIndex) external;
}

interface IOracle {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface IVRF {
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom(string memory seed) external returns (uint256);
    function getRand(uint256 nonce) external view returns (uint256);
    function getRange(uint min, uint max,uint nonce) external view returns(uint);
}

/// @dev Battle game contracts, proxy implementation
/// vrf.setAuth(battle, true)
/// quest.setAuth(battle, true)
/// Should init - initialize, resetStatInfo
contract BattlePoly {

    address implementation_;
    address public admin;

    IDogewood public dogewood;
    IVRF public vrf; // random generator
    QuestLike public quest;

    // stat info : level => class => breed => playerType => StatInfo
    //    playerType: 0 => player, 1 => enemy
    mapping(uint16 => mapping(uint8 => mapping(uint8 => mapping(uint8 => StatInfo)))) public statInfo;

    // policy variables
    mapping(PolicyVariables => uint) public policyVariables;

    // class info
    mapping(uint8 => ClassInfo) public classInfo;
    // breed info
    mapping(uint8 => StatInfo) public breedInfo;
    // level info
    mapping(uint16 => LevelInfo) public levelInfo;

    uint public constant PERCENT_MULTIPLIER = 10000; // number of 100% (ex: 100% => 10000 => 10000/10000=1)

    // dungeon
    // uint public _currentDungeonId;
    // mapping(uint => DungeonInfo) public dogeDungeonInfo;
    uint public _currentCombatId;

    /*///////////////////////////////////////////////////////////////
                    End of data
    //////////////////////////////////////////////////////////////*/

    function initialize(address dogewood_, address vrf_) external {
        require(msg.sender == admin);

        dogewood = IDogewood(dogewood_);
        vrf = IVRF(vrf_);

        // init policy variables
        policyVariables[PolicyVariables.HERO_STAT_POINTS_START] = 60; // Hero Stat Points Start	60
        policyVariables[PolicyVariables.HERO_STAT_POINTS_DELTA] = 10; // Hero Stat Points Delta	10
        policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC] = 6000; // Enemy Stat Points %	60.00%
        policyVariables[PolicyVariables.HP_PER_COAT] = 20; // HP per Coat	20
        policyVariables[PolicyVariables.MIN_DAMAGE_PERC] = 6000; // Min Damage %	60.00%
        policyVariables[PolicyVariables.MAX_CRIT_CHANCE_PERC] = 500; // Max Crit Chance	5%
        policyVariables[PolicyVariables.MAX_LUCK_CRIT_STAT] = 10000; // Max Luck Crit Stat	100
        policyVariables[PolicyVariables.MAX_DODGE_PERC] = 2000; // Max Dodge %	20.00%
        policyVariables[PolicyVariables.MAX_SNEAK_DODGE_STAT] = 10000; // Max Sneak Dodge Stat	100
        policyVariables[PolicyVariables.MAX_NOSE_DODGE_STAT] = 10000; // Max Nose Dodge Stat	100
        policyVariables[PolicyVariables.MAX_WAG_DODGE_STAT] = 10000; // Max Wag Dodge Stat	100
        policyVariables[PolicyVariables.BONUS_LB_POINTS_PER_HP] = 1; // Bonus LB Points per HP	1

        // level info
        levelInfo[1] = LevelInfo(0, 6000);
        levelInfo[2] = LevelInfo(12, 7000);
        levelInfo[3] = LevelInfo(16, 8000);
        levelInfo[4] = LevelInfo(20, 9000);
        levelInfo[5] = LevelInfo(24, 10000);
        levelInfo[6] = LevelInfo(30, 11000);
        levelInfo[7] = LevelInfo(36, 12000);
        levelInfo[8] = LevelInfo(42, 13000);
        levelInfo[9] = LevelInfo(48, 14000);
        levelInfo[10] = LevelInfo(54, 15000);
        levelInfo[11] = LevelInfo(62, 16000);
        levelInfo[12] = LevelInfo(70, 17000);
        levelInfo[13] = LevelInfo(78, 18000);
        levelInfo[14] = LevelInfo(86, 19000);
        levelInfo[15] = LevelInfo(96, 20000);
        levelInfo[16] = LevelInfo(106, 21000);
        levelInfo[17] = LevelInfo(116, 22000);
        levelInfo[18] = LevelInfo(126, 23000);
        levelInfo[19] = LevelInfo(138, 24000);
        levelInfo[20] = LevelInfo(150, 25000);

        // class info
        // classes = ["Warrior", "Rogue", "Mage", "Hunter", "Cleric", "Bard", "Merchant", "Forager"];
        classInfo[0] = ClassInfo(AttackTypes.Melee, StatInfo(2500, 2000, 500, 2000, 500, 500, 500, 1500)); // Warrior 25.00% 20.00% 5.00% 20.00% 5.00% 5.00% 5.00% 15.00%
        classInfo[1] = ClassInfo(AttackTypes.Melee, StatInfo(2000, 1500, 500, 2500, 500, 500, 2000, 500)); // Rogue 20.00% 15.00% 5.00% 25.00% 5.00% 5.00% 20.00% 5.00%
        classInfo[2] = ClassInfo(AttackTypes.Magic, StatInfo(500, 1500, 2500, 500, 500, 2000, 500, 2000)); // Mage 5.00% 15.00% 25.00% 5.00% 5.00% 20.00% 5.00% 20.00%
        classInfo[3] = ClassInfo(AttackTypes.Ranged, StatInfo(500, 2000, 500, 2000, 2500, 1500, 500, 500)); // Hunter 5.00% 20.00% 5.00% 20.00% 25.00% 15.00% 5.00% 5.00%
        classInfo[4] = ClassInfo(AttackTypes.Magic, StatInfo(500, 2500, 2000, 500, 500, 2000, 1500, 500)); // Cleric 5.00% 25.00% 20.00% 5.00% 5.00% 20.00% 15.00% 5.00%
        classInfo[5] = ClassInfo(AttackTypes.Ranged, StatInfo(500, 1500, 2000, 500, 2000, 500, 2500, 500)); // Bard 5.00% 15.00% 20.00% 5.00% 20.00% 5.00% 25.00% 5.00%
        classInfo[6] = ClassInfo(AttackTypes.Ranged, StatInfo(500, 1500, 500, 500, 2000, 500, 2000, 2500)); // Merchant 5.00% 15.00% 5.00% 5.00% 20.00% 5.00% 20.00% 25.00%
        classInfo[7] = ClassInfo(AttackTypes.Melee, StatInfo(2000, 1500, 500, 500, 500, 2500, 500, 2000)); // Forager 20.00% 15.00% 5.00% 5.00% 5.00% 25.00% 5.00% 20.00%

        // breed info
        // breeds = ["Shiba", "Pug", "Corgi", "Labrador", "Dachshund", "Poodle", "Pitbull", "Bulldog"];
        breedInfo[0] = StatInfo(0, -200, 100, 0, 200, 0, 0, -100); // Shiba 0.00% -2.00% 1.00% 0.00% 2.00% 0.00% 0.00% -1.00%
        breedInfo[1] = StatInfo(0, 0, -100, 100, -200, 0, 200, 0); // Pug 0.00% 0.00% -1.00% 1.00% -2.00% 0.00% 2.00% 0.00%
        breedInfo[2] = StatInfo(0, -100, 0, 200, 0, -200, 100, 0); // Corgi 0.00% -1.00% 0.00% 2.00% 0.00% -2.00% 1.00% 0.00%
        breedInfo[3] = StatInfo(0, 200, 0, 0, -100, 100, 0, -200); // Labrador 0.00% 2.00% 0.00% 0.00% -1.00% 1.00% 0.00% -2.00%
        breedInfo[4] = StatInfo(-100, 0, 0, 0, 100, 200, -200, 0); // Dachshund -1.00% 0.00% 0.00% 0.00% 1.00% 2.00% -2.00% 0.00%
        breedInfo[5] = StatInfo(-200, 0, 200, 0, 0, -100, 0, 100); // Poodle -2.00% 0.00% 2.00% 0.00% 0.00% -1.00% 0.00% 1.00%
        breedInfo[6] = StatInfo(100, 0, 0, -200, 0, 0, -100, 200); // Pitbull 1.00% 0.00% 0.00% -2.00% 0.00% 0.00% -1.00% 2.00%
        breedInfo[7] = StatInfo(200, 100, -200, -100, 0, 0, 0, 0); // Bulldog 2.00% 1.00% -2.00% -1.00% 0.00% 0.00% 0.00% 0.00%

        // set stat info - this should be called manually by several times to avoid block gas limit
        // resetStatInfo();
        for (uint16 level_ = 1; level_ <= 20; level_++) {
            for (uint8 class_ = 0; class_ < 8; class_++) {
                for (uint8 breed_ = 0; breed_ < 8; breed_++) {
                    statInfo[level_][class_][breed_][0] = StatInfo(0, 0, 0, 0, 0, 0, 0, 0); // doge
                    statInfo[level_][class_][breed_][1] = StatInfo(0, 0, 0, 0, 0, 0, 0, 0); // doge
                }
            }
        }
    }

    function resetStatInfo(uint16 level_, uint8 classFrom_, uint8 classTo_) external {
        require(msg.sender == admin);
        require(level_ >= 1 && level_ <= 20, "level should be 1-20");
        require(classFrom_ < 8 && classTo_ < 8, "level should be 1-20");
        // statInfo[level_][class_][breed_][playerType_] = stat_;

        // for (uint16 level_ = 1; level_ <= 20; level_++) 
        {
            for (uint8 class_ = classFrom_; class_ < classTo_; class_++) { // for (uint8 class_ = 0; class_ < 8; class_++) {
                for (uint8 breed_ = 0; breed_ < 8; breed_++) {
                    int paw_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int coat_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int magic_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int sneak_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int hunt_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int nose_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int wag_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int luck_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    
                    // statInfo[level_][class_][breed_][0] = StatInfo(paw_, coat_, magic_, sneak_, hunt_, nose_, wag_, luck_); // doge
                    statInfo[level_][class_][breed_][0].paw = paw_;
                    statInfo[level_][class_][breed_][0].coat = coat_;
                    statInfo[level_][class_][breed_][0].magic = magic_;
                    statInfo[level_][class_][breed_][0].sneak = sneak_;
                    statInfo[level_][class_][breed_][0].hunt = hunt_;
                    statInfo[level_][class_][breed_][0].nose = nose_;
                    statInfo[level_][class_][breed_][0].wag = wag_;
                    statInfo[level_][class_][breed_][0].luck = luck_;
                     // enemy
                    // statInfo[level_][class_][breed_][1] = StatInfo(
                    //     paw_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                    //     coat_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                    //     magic_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                    //     sneak_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                    //     hunt_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                    //     nose_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                    //     wag_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                    //     luck_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER)
                    // );
                    statInfo[level_][class_][breed_][1].paw = paw_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER);
                    statInfo[level_][class_][breed_][1].coat = coat_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER);
                    statInfo[level_][class_][breed_][1].magic = magic_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER);
                    statInfo[level_][class_][breed_][1].sneak = sneak_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER);
                    statInfo[level_][class_][breed_][1].hunt = hunt_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER);
                    statInfo[level_][class_][breed_][1].nose = nose_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER);
                    statInfo[level_][class_][breed_][1].wag = wag_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER);
                    statInfo[level_][class_][breed_][1].luck = luck_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER);
                }
            }
        }
    }

    function setStatInfo(uint16 level_, uint8 class_, uint8 breed_, uint8 playerType_, StatInfo memory stat_) external {
        require(msg.sender == admin);
        statInfo[level_][class_][breed_][playerType_] = stat_;
    }

    function setClassInfo(uint8 class_, ClassInfo memory stat_) external {
        require(msg.sender == admin);
        classInfo[class_] = stat_;
    }

    function setBreedInfo(uint8 breed_, StatInfo memory stat_) external {
        require(msg.sender == admin);
        breedInfo[breed_] = stat_;
    }

    function setLevelInfo(uint16 level_, LevelInfo memory info_) external {
        require(msg.sender == admin);
        levelInfo[level_] = info_;
    }

    /*///////////////////////////////////////////////////////////////
                    Events
    //////////////////////////////////////////////////////////////*/
    
    event CombatStart(uint currentCombatId, uint dogeId, address user, IDogewood.Doge2 doge, uint dogeHp, uint enemyHp);
    event TurnOrder(uint currentCombatId, uint turnId, uint8[2] playerTypes);
    event RollDamageDodge(CombatDamageDodgeLog damageDodgeLog);
    event CombatWin(uint currentCombatId, uint dogeId, address user, uint dogeHp, uint enemyHp, uint lbPoints);

    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/
    struct StatInfo { // all item is multiplied by 100
        int paw;
        int coat;
        int magic;
        int sneak;
        int hunt;
        int nose;
        int wag;
        int luck;
    }
    struct ClassInfo {
        AttackTypes attackType;
        StatInfo statInfo;
    }
    struct LevelInfo {
        uint treat;
        uint heroStatPoints; // multiplied by 100
        // uint enemyStatPoints; // multiplied by 100
    }
    struct CombatDamageDodgeLog {
        uint currentCombatId;
        uint turnId;
        uint8 attackerType;
        uint baseDamage;
        bool isCriticalDamage;
        bool rollDodge;
        uint defenderHp;
    }

    enum PolicyVariables {
        HERO_STAT_POINTS_START,
        HERO_STAT_POINTS_DELTA,
        ENEMY_STAT_POINTS_PERC,
        HP_PER_COAT,
        MIN_DAMAGE_PERC,
        MAX_CRIT_CHANCE_PERC,
        MAX_LUCK_CRIT_STAT,
        MAX_DODGE_PERC,
        MAX_SNEAK_DODGE_STAT,
        MAX_NOSE_DODGE_STAT,
        MAX_WAG_DODGE_STAT,
        BONUS_LB_POINTS_PER_HP
    }
    enum AttackTypes {
        Melee,
        Magic,
        Ranged
    }

    /*///////////////////////////////////////////////////////////////
                BATTLE METHODS
    //////////////////////////////////////////////////////////////*/

    function combatSingle(uint256 dogeId) external {
        IDogewood.Doge2 memory doge_ = dogewood.getTokenTraits(dogeId);
        require(doge_.level > 0, "still in reroll cooldown");
        require(dogewood.validateOwnerOfDoge(dogeId, msg.sender), "invalid owner");

        // health points
        uint[] memory hp_ = new uint[](2);
        hp_[0] = uint(statInfo[doge_.level][doge_.class][doge_.breed][0].coat) * policyVariables[PolicyVariables.HP_PER_COAT];
        hp_[1] = uint(statInfo[doge_.level][doge_.class][doge_.breed][1].coat) * policyVariables[PolicyVariables.HP_PER_COAT];
        uint originEnemyHP_ = hp_[1];

        _currentCombatId ++;
        emit CombatStart(_currentCombatId, dogeId, msg.sender, doge_, hp_[0], hp_[1]);

        uint turnId_;
        while(hp_[0] > 0 && hp_[1] > 0) { // turn play
            turnId_ ++;
            // turn order
            // roll for attack order
            uint dSneak_ = vrf.getRandom("doge sneak") % uint(statInfo[doge_.level][doge_.class][doge_.breed][0].sneak);
            uint eSneak_ = vrf.getRandom("enemy sneak") % uint(statInfo[doge_.level][doge_.class][doge_.breed][1].sneak);

            uint8[2] memory playerTypes_ = dSneak_ >= eSneak_ ? [0, 1] : [1, 0];
            emit TurnOrder(_currentCombatId, turnId_, playerTypes_);

            for (uint256 i = 0; i < playerTypes_.length; i++) {
                // roll for damage
                uint8 attackerType_ = playerTypes_[i];
                uint8 defenderType_ = 1 - attackerType_;
                uint baseDamage_ = _getBaseDamage(doge_, attackerType_);
                bool isCriticalDamage_ = _isCriticalDamage(doge_, attackerType_);
                if(isCriticalDamage_) baseDamage_ *= 2;
                // roll for dodge
                bool rollDodge_ = _rollDodge(doge_, defenderType_);
                if(!rollDodge_) {
                    // take full damage
                    hp_[defenderType_] = hp_[defenderType_] > baseDamage_ ? (hp_[defenderType_] - baseDamage_) : 0;
                }
                emit RollDamageDodge(CombatDamageDodgeLog(_currentCombatId, turnId_, attackerType_, baseDamage_, isCriticalDamage_, rollDodge_, hp_[defenderType_]));

                if(hp_[defenderType_] == 0) break; // battle end
            }
        }

        // battle end
        uint8 winnerPlayerType_ = hp_[0] == 0 ? 1 : 0;
        // leaderboard points
        uint lbPoints_;
        if(winnerPlayerType_ == 0) lbPoints_ = 100;
        else { // winner is enemy
            lbPoints_ = 100 * (originEnemyHP_ - hp_[1]) / originEnemyHP_;
        }
        emit CombatWin(_currentCombatId, dogeId, msg.sender, hp_[0], hp_[1], lbPoints_);
        if(lbPoints_ > 0) {
            // add leaderboard log
            uint[] memory doges_ = new uint[](1); doges_[0] = dogeId;
            address[] memory owners_ = new address[](1); owners_[0] = msg.sender;
            uint[] memory scores_ = new uint[](1); scores_[0] = lbPoints_;
            quest.doQuestByAdmin(doges_, owners_, scores_, _getGroupIndex(doge_.level));
        }
        // TODO -- victory healing
    }
    function _getGroupIndex(uint16 level_) public pure returns (uint8 groupIndex_) {
        // Groups:
        //     Level 1-5
        //     Initial Prize Pool: 30 $TREAT
        //     Additional Entry: 1 $TREAT
        //     Level 6-10
        //     Initial Prize Pool: 60 $TREAT
        //     Additional Entry 2 $TREAT 
        //     Level 11-15
        //     Initial Prize Pool: 100 $TREAT
        //     Additional Entry 5 $TREAT 
        //     Level 16-20
        //     Initial Prize Pool: 250 $TREAT
        //     Additional Entry 10 $TREAT 
        if(level_ <= 5) groupIndex_ = 0;
        else if(level_ <= 10) groupIndex_ = 1;
        else if(level_ <= 15) groupIndex_ = 2;
        else if(level_ <= 20) groupIndex_ = 3;
    }

    /**
     * get base damage
     * return baseDamage = maxDamage * min_damage_percent + relevant_damage * (1 - min_damage_percent)
     */
    function _getBaseDamage(IDogewood.Doge2 memory doge_, uint8 playerType_) internal returns (uint baseDamage_) {
        uint maxDamage_;
        if(classInfo[doge_.class].attackType == AttackTypes.Melee) {
            maxDamage_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][playerType_].paw);
        } else if(classInfo[doge_.class].attackType == AttackTypes.Ranged) {
            maxDamage_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][playerType_].hunt);
        } else {
            maxDamage_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][playerType_].magic); // AttackTypes.Magic
        }

        baseDamage_ = maxDamage_ * policyVariables[PolicyVariables.MIN_DAMAGE_PERC] / PERCENT_MULTIPLIER + 
            (vrf.getRandom("max damage") % maxDamage_) * (PERCENT_MULTIPLIER - policyVariables[PolicyVariables.MIN_DAMAGE_PERC])
                / PERCENT_MULTIPLIER;
    }
    
    function _isCriticalDamage(IDogewood.Doge2 memory doge_, uint8 playerType_) internal returns (bool) {
        uint critLuckRange_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][playerType_].luck) * policyVariables[PolicyVariables.MAX_CRIT_CHANCE_PERC]; // / PERCENT_MULTIPLIER;
        uint relevantLuck_ = vrf.getRandom("is critical damage") % (policyVariables[PolicyVariables.MAX_LUCK_CRIT_STAT] * PERCENT_MULTIPLIER);
        return relevantLuck_ <= critLuckRange_;
    }

    function _rollDodge(IDogewood.Doge2 memory doge_, uint8 dodgePlayerType_) internal returns (bool) {
        uint stat_;
        uint maxDodge_;
        if(classInfo[doge_.class].attackType == AttackTypes.Melee) {
            stat_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][dodgePlayerType_].sneak);
            maxDodge_ = policyVariables[PolicyVariables.MAX_SNEAK_DODGE_STAT];
        } else if(classInfo[doge_.class].attackType == AttackTypes.Ranged) {
            stat_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][dodgePlayerType_].nose);
            maxDodge_ = policyVariables[PolicyVariables.MAX_NOSE_DODGE_STAT];
        } else {
            stat_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][dodgePlayerType_].wag);
            maxDodge_ = policyVariables[PolicyVariables.MAX_WAG_DODGE_STAT];
        }
        uint relevantDodge_ = stat_ * policyVariables[PolicyVariables.MAX_DODGE_PERC];
        maxDodge_ = maxDodge_ * PERCENT_MULTIPLIER;
        return (vrf.getRandom("roll dodge") % maxDodge_) <= relevantDodge_;
    }
}