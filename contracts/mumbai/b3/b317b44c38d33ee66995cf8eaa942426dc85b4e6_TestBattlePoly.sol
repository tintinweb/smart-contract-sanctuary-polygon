/**
 *Submitted for verification at polygonscan.com on 2022-04-28
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
    struct Action {
        uint256 id; // unique id to distinguish activities
        uint88 timestamp;
        uint256 doge;
        address owner;
        uint256 score;
        uint256 finalScore;
    }

    function doQuestByAdmin(uint256 doge, address owner, uint256 score, uint8 groupIndex, uint256 combatId) external;
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

interface ICommoner {
    // struct to store each token's traits
    struct Commoner {
        uint8 head;
        uint8 breed;
        uint8 palette;
        uint8 bodyType;
        uint8 clothes;
        uint8 accessory;
        uint8 background;
        uint8 smithing;
        uint8 alchemy;
        uint8 cooking;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Commoner memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwner(uint256 id, address who_) external view returns (bool);
    function pull(address owner, uint256[] calldata ids) external;
    function adjust(uint256 id, uint8 head, uint8 breed, uint8 palette, uint8 bodyType, uint8 clothes, uint8 accessory, uint8 background, uint8 smithing, uint8 alchemy, uint8 cooking) external;
    function transfer(address to, uint256 tokenId) external;
}

/// @dev Battle game contracts, proxy implementation
/// vrf.setAuth(battle, true)
/// quest.setAuth(battle, true)
/// Should init - initialize, resetStatInfo
/// items.setMinter(battle, true)
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
    uint public _currentCombatId;

    // last combat score of the doge
    mapping(uint256 => uint256) public _dogeLastScore; // doge => score

    ERC1155Like public items;
    uint256 constant LOOTBOX_COMMON_ID = 1;
    uint256 constant LOOTBOX_UNCOMMON_ID = 2;
    uint256 constant LOOTBOX_RARE_ID = 3;
    uint256 constant LOOTBOX_EPIC_ID = 4;
    uint256 constant LOOTBOX_LEGENDARY_ID = 5;
    uint256 constant ARMOR_ID = 6; 
    uint256 constant POTION_ID = 7; 
    uint256 constant STEW_ID  = 8; 
    /*///////////////////////////////////////////////////////////////
                    End of data
    //////////////////////////////////////////////////////////////*/

    function initialize(address dogewood_, address vrf_, address quest_, address items_) external {
        require(msg.sender == admin);

        dogewood = IDogewood(dogewood_);
        vrf = IVRF(vrf_);
        quest = QuestLike(quest_);
        items = ERC1155Like(items_);

        // init policy variables
        policyVariables[PolicyVariables.HERO_STAT_POINTS_START] = 60; // Hero Stat Points Start	60
        policyVariables[PolicyVariables.HERO_STAT_POINTS_DELTA] = 10; // Hero Stat Points Delta	10
        policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC] = 6000; // Enemy Stat Points %	60.00%
        policyVariables[PolicyVariables.HP_PER_HEART] = 20; // HP per Heart	20
        policyVariables[PolicyVariables.MIN_DAMAGE_PERC] = 6000; // Min Damage %	60.00%
        policyVariables[PolicyVariables.MAX_CRIT_CHANCE_PERC] = 500; // Max Crit Chance	5%
        policyVariables[PolicyVariables.MAX_LUCK_CRIT_STAT] = 10000; // Max Luck Crit Stat	100
        policyVariables[PolicyVariables.MAX_DODGE_PERC] = 2000; // Max Dodge %	20.00%
        policyVariables[PolicyVariables.MAX_SPEED_DODGE_STAT] = 10000; // Max Speed Dodge Stat	100
        policyVariables[PolicyVariables.MAX_NOSE_DODGE_STAT] = 10000; // Max Nose Dodge Stat	100
        policyVariables[PolicyVariables.MAX_WAG_DODGE_STAT] = 10000; // Max Wag Dodge Stat	100
        policyVariables[PolicyVariables.BONUS_LB_POINTS_PER_HP] = 1; // Bonus LB Points per HP	1
        policyVariables[PolicyVariables.ENEMY_HEART_BOOST_PERC] = 200000; // Enemy Heart Boost Points %	2000.00%

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
        breedInfo[0] = StatInfo(0, 100, 0, 0, 0, 0, 0, 200); // Shiba 0.00%	1.00%	0.00%	0.00%	0.00%	0.00%	0.00%	2.00%
        breedInfo[1] = StatInfo(0, 0, 0, 200, 0, 0, 0, 100); // Pug 0.00%	0.00%	0.00%	2.00%	0.00%	0.00%	0.00%	1.00%
        breedInfo[2] = StatInfo(0, 0, 200, 0, 0, 0, 100, 0); // Corgi 0.00%	0.00%	2.00%	0.00%	0.00%	0.00%	1.00%	0.00%
        breedInfo[3] = StatInfo(0, 0, 0, 0, 200, 100, 0, 0); // Labrador 0.00%	0.00%	0.00%	0.00%	2.00%	1.00%	0.00%	0.00%
        breedInfo[4] = StatInfo(0, 0, 100, 0, 0, 200, 0, 0); // Dachshund 0.00%	0.00%	1.00%	0.00%	0.00%	2.00%	0.00%	0.00%
        breedInfo[5] = StatInfo(0, 0, 0, 0, 100, 0, 200, 0); // Poodle 0.00%	0.00%	0.00%	0.00%	1.00%	0.00%	2.00%	0.00%
        breedInfo[6] = StatInfo(200, 0, 0, 100, 0, 0, 0, 0); // Pitbull 2.00%	0.00%	0.00%	1.00%	0.00%	0.00%	0.00%	0.00%
        breedInfo[7] = StatInfo(100, 200, 0, 0, 0, 0, 0, 0); // Bulldog 1.00%	2.00%	0.00%	0.00%	0.00%	0.00%	0.00%	0.00%

        // set stat info - this should be called manually by several times to avoid block gas limit
        // resetStatInfo();
    }

    function resetStatInfo(uint16 level_, uint8 classFrom_, uint8 classTo_) external virtual {
        require(msg.sender == admin);
        require(level_ >= 1 && level_ <= 20, "level should be 1-20");
        require(classFrom_ < 8 && classTo_ <= 8, "class should be 1-7");
        // statInfo[level_][class_][breed_][playerType_] = stat_;

        // for (uint16 level_ = 1; level_ <= 20; level_++) 
        {
            for (uint8 class_ = classFrom_; class_ < classTo_; class_++) { // for (uint8 class_ = 0; class_ < 8; class_++) {
                for (uint8 breed_ = 0; breed_ < 8; breed_++) {
                    int paw_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int heart_ = (classInfo[class_].statInfo.heart + breedInfo[breed_].heart) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int smarts_ = (classInfo[class_].statInfo.smarts + breedInfo[breed_].smarts) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int speed_ = (classInfo[class_].statInfo.speed + breedInfo[breed_].speed) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int hunt_ = (classInfo[class_].statInfo.hunt + breedInfo[breed_].hunt) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int nose_ = (classInfo[class_].statInfo.nose + breedInfo[breed_].nose) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int wag_ = (classInfo[class_].statInfo.wag + breedInfo[breed_].wag) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int luck_ = (classInfo[class_].statInfo.luck + breedInfo[breed_].luck) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    
                    statInfo[level_][class_][breed_][0] = StatInfo(paw_, heart_, smarts_, speed_, hunt_, nose_, wag_, luck_); // doge
                     // enemy
                    statInfo[level_][class_][breed_][1] = StatInfo(
                        paw_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        heart_ * int(policyVariables[PolicyVariables.ENEMY_HEART_BOOST_PERC]) / int(PERCENT_MULTIPLIER),
                        smarts_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        speed_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        hunt_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        nose_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        wag_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        luck_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER)
                    );
                }
            }
        }
    }

    function updateEnemyStatPointsPercent(uint256 perc_, uint16 levelFrom_, uint16 levelTo_) external virtual { // perc_ = percent * 100 (60%=6000)
        require(msg.sender == admin);
        require(levelFrom_ >= 1 && levelFrom_ <= 20, "level should be 1-20");
        require(levelTo_ >= 1 && levelTo_ <= 20, "level should be 1-20");

        policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC] = perc_; // Enemy Stat Points %	60.00%
        for (uint16 level_ = levelFrom_; level_ <= levelTo_; level_++) { // for (uint16 level_ = 1; level_ <= 20; level_++)
            for (uint8 class_ = 0; class_ < 8; class_++) {
                for (uint8 breed_ = 0; breed_ < 8; breed_++) {
                    StatInfo memory ds_ = statInfo[level_][class_][breed_][0];
                    statInfo[level_][class_][breed_][1] = StatInfo(
                            ds_.paw * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.heart * int(policyVariables[PolicyVariables.ENEMY_HEART_BOOST_PERC]) / int(PERCENT_MULTIPLIER),
                            ds_.smarts * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.speed * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.hunt * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.nose * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.wag * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.luck * int(perc_) / int(PERCENT_MULTIPLIER)
                        );
                }
            }
        }
    }

    function setStatInfo(uint16 level_, uint8 class_, uint8 breed_, uint8 playerType_, StatInfo memory stat_) external virtual {
        require(msg.sender == admin);
        statInfo[level_][class_][breed_][playerType_] = stat_;
    }

    function setClassInfo(uint8 class_, ClassInfo memory stat_) external virtual {
        require(msg.sender == admin);
        classInfo[class_] = stat_;
    }

    function setBreedInfo(uint8 breed_, StatInfo memory stat_) external virtual {
        require(msg.sender == admin);
        breedInfo[breed_] = stat_;
    }

    function setLevelInfo(uint16 level_, LevelInfo memory info_) external virtual {
        require(msg.sender == admin);
        levelInfo[level_] = info_;
    }

    function setItems(address items_) external {
        require(msg.sender == admin);
        items = ERC1155Like(items_);
    }

    /*///////////////////////////////////////////////////////////////
                    Events
    //////////////////////////////////////////////////////////////*/
    
    event CombatStart(uint currentCombatId, uint dogeId, address user, IDogewood.Doge2 doge, uint dogeHp, uint enemyHp);
    event CombatStart2(uint currentCombatId, uint dogeId, address user, IDogewood.Doge2 doge, uint dogeHp, uint enemyHp, uint8 enemyClass);
    event TurnOrder(uint currentCombatId, uint turnId, uint8[2] playerTypes);
    event RollDamageDodge(CombatDamageDodgeLog damageDodgeLog);
    event CombatWin(uint currentCombatId, uint dogeId, address user, uint dogeHp, uint enemyHp, uint lbPoints);
    event LootBoxFound(uint currentCombatId,uint dogeId,address user,uint itemId,uint amount);

    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/
    struct StatInfo { // all item is multiplied by 100
        int paw;
        int heart;
        int smarts;
        int speed;
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
        HP_PER_HEART,
        MIN_DAMAGE_PERC,
        MAX_CRIT_CHANCE_PERC,
        MAX_LUCK_CRIT_STAT,
        MAX_DODGE_PERC,
        MAX_SPEED_DODGE_STAT,
        MAX_NOSE_DODGE_STAT,
        MAX_WAG_DODGE_STAT,
        BONUS_LB_POINTS_PER_HP,
        ENEMY_HEART_BOOST_PERC
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
        uint8 enemyClass_ = uint8(vrf.getRandom("random enemy class") % 8);
        uint8 dogeClass_ = doge_.class;
        uint[] memory hp_ = new uint[](2);
        hp_[0] = uint(statInfo[doge_.level][doge_.class][doge_.breed][0].heart) * policyVariables[PolicyVariables.HP_PER_HEART];
        hp_[1] = uint(statInfo[doge_.level][enemyClass_][doge_.breed][1].heart) * policyVariables[PolicyVariables.HP_PER_HEART];
        uint originEnemyHP_ = hp_[1];

        _currentCombatId ++;
        emit CombatStart2(_currentCombatId, dogeId, msg.sender, doge_, hp_[0], hp_[1], enemyClass_);

        uint turnId_;
        while(hp_[0] > 0 && hp_[1] > 0) { // turn play
            turnId_ ++;
            uint8[2] memory playerTypes_;
            {
                // turn order
                // roll for attack order
                uint dSpeed_ = vrf.getRandom("doge speed") % uint(statInfo[doge_.level][doge_.class][doge_.breed][0].speed);
                uint eSpeed_ = vrf.getRandom("enemy speed") % uint(statInfo[doge_.level][enemyClass_][doge_.breed][1].speed);

                playerTypes_ = dSpeed_ >= eSpeed_ ? [0, 1] : [1, 0];
                emit TurnOrder(_currentCombatId, turnId_, playerTypes_);
            }

            for (uint256 i = 0; i < playerTypes_.length; i++) {
                // roll for damage
                uint8 attackerType_ = playerTypes_[i];
                uint8 defenderType_ = 1 - attackerType_;
                // uint8 attackerClass_ = attackerType_ == 0 ? dogeClass_ : enemyClass_;
                // uint8 defenderClass_ = attackerType_ == 1 ? dogeClass_ : enemyClass_;
                uint baseDamage_ = _getBaseDamage(doge_, attackerType_, attackerType_ == 0 ? dogeClass_ : enemyClass_);
                bool isCriticalDamage_ = _isCriticalDamage(doge_, attackerType_, attackerType_ == 0 ? dogeClass_ : enemyClass_);
                if(isCriticalDamage_) baseDamage_ *= 2;
                // roll for dodge
                bool rollDodge_ = _rollDodge(doge_, defenderType_, enemyClass_);
                if(!rollDodge_) {
                    // take full damage
                    hp_[defenderType_] = hp_[defenderType_] > baseDamage_ ? (hp_[defenderType_] - baseDamage_) : 0;
                }
                emit RollDamageDodge(CombatDamageDodgeLog(_currentCombatId, turnId_, attackerType_, baseDamage_, isCriticalDamage_, rollDodge_, hp_[defenderType_]));

                if(hp_[defenderType_] == 0) break; // battle end
            }
        }

        {
            // battle end
            uint8 winnerPlayerType_ = hp_[0] == 0 ? 1 : 0;
            // leaderboard points
            uint lbPoints_;
            if(winnerPlayerType_ == 0) lbPoints_ = originEnemyHP_;
            else { // winner is enemy
                lbPoints_ = originEnemyHP_ - hp_[1];
            }
            emit CombatWin(_currentCombatId, dogeId, msg.sender, hp_[0], hp_[1], lbPoints_);
            _dogeLastScore[dogeId] = lbPoints_;
            quest.doQuestByAdmin(dogeId, msg.sender, lbPoints_, _getGroupIndex(doge_.level), _currentCombatId);
            // loot box
            uint256 itemId_ = _rollForLoot(doge_);
            if(itemId_ > 0) emit LootBoxFound(_currentCombatId, dogeId, msg.sender, itemId_, 1);
            // TODO -- victory healing
        }
    }

    function _getGroupIndex(uint16 level_) public pure returns (uint8 groupIndex_) {
        // Groups:
        if(level_ <= 5) groupIndex_ = 0;
        else if(level_ <= 10) groupIndex_ = 1;
        else if(level_ <= 15) groupIndex_ = 2;
        else if(level_ <= 20) groupIndex_ = 3;
    }

    /**
     * get base damage
     * return baseDamage = maxDamage * min_damage_percent + relevant_damage * (1 - min_damage_percent)
     */
    function _getBaseDamage(IDogewood.Doge2 memory doge_, uint8 playerType_, uint8 class_) internal returns (uint baseDamage_) {
        uint maxDamage_;
        if(classInfo[class_].attackType == AttackTypes.Melee) {
            maxDamage_ = uint(statInfo[doge_.level][class_][doge_.breed][playerType_].paw);
        } else if(classInfo[class_].attackType == AttackTypes.Ranged) {
            maxDamage_ = uint(statInfo[doge_.level][class_][doge_.breed][playerType_].hunt);
        } else {
            maxDamage_ = uint(statInfo[doge_.level][class_][doge_.breed][playerType_].smarts); // AttackTypes.Magic
        }

        baseDamage_ = maxDamage_ * policyVariables[PolicyVariables.MIN_DAMAGE_PERC] / PERCENT_MULTIPLIER + 
            (vrf.getRandom("max damage") % maxDamage_) * (PERCENT_MULTIPLIER - policyVariables[PolicyVariables.MIN_DAMAGE_PERC])
                / PERCENT_MULTIPLIER;
    }
    
    function _isCriticalDamage(IDogewood.Doge2 memory doge_, uint8 playerType_, uint8 class_) internal returns (bool) {
        // uint critLuckRange_ = uint(statInfo[doge_.level][class_][doge_.breed][playerType_].luck) * policyVariables[PolicyVariables.MAX_CRIT_CHANCE_PERC]; // / PERCENT_MULTIPLIER;
        // uint relevantLuck_ = vrf.getRandom("is critical damage") % (policyVariables[PolicyVariables.MAX_LUCK_CRIT_STAT] * PERCENT_MULTIPLIER);
        // return relevantLuck_ <= critLuckRange_;
        /**
         * new formula
         *  Luck*5% + 10% (rogue) => luck*0.05 + 10 => 10.20*0.05 + 10 vs 100  => 1020*0.05 + 1000 vs 10_000 => 1020*5 + 100_000 vs 1_000_000
         *  Luck * 5% + 5% (everything else)    => luck * 0.05 + 5
         */
        uint critLuckRange_ = uint(statInfo[doge_.level][class_][doge_.breed][playerType_].luck) * 5;
        if(class_ == 1) critLuckRange_ += 100_000; // rogue
        else critLuckRange_ += 50_000;
        uint relevantLuck_ = vrf.getRandom("is critical damage") % 1_000_000;
        return relevantLuck_ <= critLuckRange_;
    }

    function _rollDodge(IDogewood.Doge2 memory doge_, uint8 dodgePlayerType_, uint8 enemyClass_) internal returns (bool) {
        uint8 attackerClass_;
        uint8 defenderClass_;
        if(dodgePlayerType_ == 0) {
            attackerClass_ = enemyClass_;
            defenderClass_ = doge_.class;
        } else {
            attackerClass_ = doge_.class;
            defenderClass_ = enemyClass_;
        }

        uint stat_;
        uint maxDodge_;
        if(classInfo[attackerClass_].attackType == AttackTypes.Melee) {
            stat_ = uint(statInfo[doge_.level][defenderClass_][doge_.breed][dodgePlayerType_].speed);
            maxDodge_ = policyVariables[PolicyVariables.MAX_SPEED_DODGE_STAT];
        } else if(classInfo[attackerClass_].attackType == AttackTypes.Ranged) {
            stat_ = uint(statInfo[doge_.level][defenderClass_][doge_.breed][dodgePlayerType_].nose);
            maxDodge_ = policyVariables[PolicyVariables.MAX_NOSE_DODGE_STAT];
        } else {
            stat_ = uint(statInfo[doge_.level][defenderClass_][doge_.breed][dodgePlayerType_].wag);
            maxDodge_ = policyVariables[PolicyVariables.MAX_WAG_DODGE_STAT];
        }
        // uint relevantDodge_ = stat_ * policyVariables[PolicyVariables.MAX_DODGE_PERC];
        // maxDodge_ = maxDodge_ * PERCENT_MULTIPLIER;
        // return (vrf.getRandom("roll dodge") % maxDodge_) <= relevantDodge_;
        /**
         * New Formula for Dodge= (Speed/Nose/Wag)*.025 + Base Probability
         *  12.00*0.25 + 5      vs 100
         *  1200*0.25 + 500     vs 10_000
         *  1200*25 + 50_000    vs 1_000_000
         */
        uint relevantDodge_ = stat_ * 25 + 50_000;
        return (vrf.getRandom("roll dodge") % 1_000_000) <= relevantDodge_;
    }

    /**
     * returns item id of loot box found - 0: not found
     */
    function _rollForLoot(IDogewood.Doge2 memory doge_) internal returns (uint256) {
        /**
         * Formula for discovery = (Nose * .01) + Base Probability
         *      12.00 * 0.1 + 2    vs  100%
         *      1200 * 0.1 + 200   vs 10_000
         *      1200 * 1 + 2_000   vs 100_000
         */
        uint discoveryRange_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][0].nose) + 2_000;
        uint relevantDiscovery_ = vrf.getRandom("discovery loot") % 100_000;
        if(relevantDiscovery_ <= discoveryRange_) { // loot found
            /**
             * Formula for Epic buff =  Luck *.03 + Base Probability
             * Formula for Legendary buff =  Luck *.01 + Base Probability
             *      Luck *.03 + Base Probability    vs  100%
             *      12.00 * 0.03 + 2                vs  100%
             *      1200 * 0.03 + 200               vs  10_000
             *      1200 * 3 + 20_000               vs  1_000_000
             */
            uint relevantBox_ = vrf.getRandom("loot box type") % 1_000_000;
            uint legendPerc_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][0].luck)*1 + 5_000; // .5%
            uint epicPerc_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][0].luck)*3 + 20_000; // 2%
            uint rarePerc_ = uint(statInfo[doge_.level][doge_.class][doge_.breed][0].luck)*5 + 75_000; // 7.5%

            uint256 itemId_;
            if(relevantBox_ <= legendPerc_) itemId_ = LOOTBOX_LEGENDARY_ID;
            else if(relevantBox_ <= legendPerc_+ epicPerc_) itemId_ = LOOTBOX_EPIC_ID;
            else if(relevantBox_ <= legendPerc_+ epicPerc_ + rarePerc_) itemId_ = LOOTBOX_RARE_ID;
            else if(relevantBox_ <= legendPerc_+ epicPerc_ + rarePerc_ + 200_000) itemId_ = LOOTBOX_UNCOMMON_ID; // 20%
            else itemId_ = LOOTBOX_COMMON_ID; // 70%

            items.mint(msg.sender, itemId_, 1 ether);
            return itemId_;
        } else { // loot not found
            return 0;
        }
    }
}

contract TestBattlePoly is BattlePoly {
    
    function resetStatInfo(uint16 level_, uint8 classFrom_, uint8 classTo_) external override {
        // require(msg.sender == admin);
        require(level_ >= 1 && level_ <= 20, "level should be 1-20");
        require(classFrom_ < 8 && classTo_ <= 8, "class should be 1-7");
        // statInfo[level_][class_][breed_][playerType_] = stat_;

        // for (uint16 level_ = 1; level_ <= 20; level_++) 
        {
            for (uint8 class_ = classFrom_; class_ < classTo_; class_++) { // for (uint8 class_ = 0; class_ < 8; class_++) {
                for (uint8 breed_ = 0; breed_ < 8; breed_++) {
                    int paw_ = (classInfo[class_].statInfo.paw + breedInfo[breed_].paw) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int heart_ = (classInfo[class_].statInfo.heart + breedInfo[breed_].heart) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int smarts_ = (classInfo[class_].statInfo.smarts + breedInfo[breed_].smarts) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int speed_ = (classInfo[class_].statInfo.speed + breedInfo[breed_].speed) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int hunt_ = (classInfo[class_].statInfo.hunt + breedInfo[breed_].hunt) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int nose_ = (classInfo[class_].statInfo.nose + breedInfo[breed_].nose) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int wag_ = (classInfo[class_].statInfo.wag + breedInfo[breed_].wag) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    int luck_ = (classInfo[class_].statInfo.luck + breedInfo[breed_].luck) * int(levelInfo[level_].heroStatPoints) / int(PERCENT_MULTIPLIER);
                    
                    statInfo[level_][class_][breed_][0] = StatInfo(paw_, heart_, smarts_, speed_, hunt_, nose_, wag_, luck_); // doge
                     // enemy
                    statInfo[level_][class_][breed_][1] = StatInfo(
                        paw_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        heart_ * int(policyVariables[PolicyVariables.ENEMY_HEART_BOOST_PERC]) / int(PERCENT_MULTIPLIER),
                        smarts_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        speed_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        hunt_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        nose_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        wag_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER),
                        luck_ * int(policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC]) / int(PERCENT_MULTIPLIER)
                    );
                }
            }
        }
    }


    function updateEnemyStatPointsPercent(uint256 perc_, uint16 levelFrom_, uint16 levelTo_) external override { // perc_ = percent * 100 (60%=6000)
        // require(msg.sender == admin);
        require(levelFrom_ >= 1 && levelFrom_ <= 20, "level should be 1-20");
        require(levelTo_ >= 1 && levelTo_ <= 20, "level should be 1-20");

        policyVariables[PolicyVariables.ENEMY_STAT_POINTS_PERC] = perc_; // Enemy Stat Points %	60.00%
        for (uint16 level_ = levelFrom_; level_ <= levelTo_; level_++) { // for (uint16 level_ = 1; level_ <= 20; level_++)
            for (uint8 class_ = 0; class_ < 8; class_++) {
                for (uint8 breed_ = 0; breed_ < 8; breed_++) {
                    StatInfo memory ds_ = statInfo[level_][class_][breed_][0];
                    statInfo[level_][class_][breed_][1] = StatInfo(
                            ds_.paw * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.heart * int(policyVariables[PolicyVariables.ENEMY_HEART_BOOST_PERC]) / int(PERCENT_MULTIPLIER),
                            ds_.smarts * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.speed * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.hunt * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.nose * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.wag * int(perc_) / int(PERCENT_MULTIPLIER),
                            ds_.luck * int(perc_) / int(PERCENT_MULTIPLIER)
                        );
                }
            }
        }
    }

    function setStatInfo(uint16 level_, uint8 class_, uint8 breed_, uint8 playerType_, StatInfo memory stat_) external override {
        // require(msg.sender == admin);
        statInfo[level_][class_][breed_][playerType_] = stat_;
    }

    function setClassInfo(uint8 class_, ClassInfo memory stat_) external override {
        // require(msg.sender == admin);
        classInfo[class_] = stat_;
    }

    function setBreedInfo(uint8 breed_, StatInfo memory stat_) external override {
        // require(msg.sender == admin);
        breedInfo[breed_] = stat_;
    }

    function setLevelInfo(uint16 level_, LevelInfo memory info_) external override {
        // require(msg.sender == admin);
        levelInfo[level_] = info_;
    }

    function mockMintItems(address to_, uint256 itemId_, uint256 amount_) external {
        items.mint(to_, itemId_, amount_);
    }
}