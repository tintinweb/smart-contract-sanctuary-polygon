// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";

// StatusCodes {
//     0: idle;
//     1: combatTrain;
//     2: goldQuest;
//     3: manaTrain;
//     4: Arena;
//     5: gemQuest;
// }

struct Equipment {
    uint256 id;
    uint256 pointer;
    uint256 slot;
    uint256 rank;
    uint256 value;
    uint256 stat;
    uint256 owner;
    string name;
    string uri;
    bool isEquiped;
}

// stat {
//     0: strength;
//     1: health;
//     2: agility;
//     3: magic;
//     4: defense;
//     5: luck;
// }

struct Treasure {
    uint256 id;
    uint256 rank;
    uint256 pointer;
    string name;
}

library StorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant QUEST_STORAGE_POSITION = keccak256("quest.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
    bytes32 constant EQUIPMENT_STORAGE_POSITION = keccak256("equipment.test.storage.a");
    bytes32 constant TREASURE_STORAGE_POSITION = keccak256("treasure.test.storage.a");

    using PlayerSlotLib for PlayerSlotLib.Player;
    using PlayerSlotLib for PlayerSlotLib.Slot;

    struct PlayerStorage {
        uint256 totalSupply;
        uint256 playerCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => PlayerSlotLib.Player) players;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(string => bool) usedNames;
        mapping(address => uint256[]) addressToPlayers;
    }

    struct QuestStorage {
        uint256 questCounter;
        mapping(uint256 => uint256) goldQuest;
        mapping(uint256 => uint256) gemQuest;
        mapping(uint256 => uint256) totemQuest;
        mapping(uint256 => uint256) diamondQuest;
        mapping(uint256 => uint256) cooldowns;
        mapping(uint256 => uint256) dragonCooldown;
        mapping(uint256 => uint256) gravityHammerQuestCooldown;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    struct EquipmentStorage {
        uint256 equipmentCount;
        mapping(uint256 => uint256) owners; //maps equipment id to player id
        mapping(uint256 => Equipment) equipment;
        mapping(uint256 => uint256[]) playerToEquipment;
        mapping(uint256 => uint256) cooldown;
    }

    struct TreasureStorage {
        uint256 treasureCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => Treasure) treasures;
        mapping(uint256 => uint256[]) playerToTreasure;
    }

    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageQuest() internal pure returns (QuestStorage storage ds) {
        bytes32 position = QUEST_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageCoin() internal pure returns (CoinStorage storage ds) {
        bytes32 position = COIN_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageItem() internal pure returns (EquipmentStorage storage ds) {
        bytes32 position = EQUIPMENT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStorageTreasure() internal pure returns (TreasureStorage storage ds) {
        bytes32 position = TREASURE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _startQuestGold(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        QuestStorage storage q = diamondStorageQuest();
        require(s.players[_tokenId].status == 0); //make sure player is idle
        require(s.owners[_tokenId] == msg.sender); //ownerOf

        s.players[_tokenId].status = 2; //set quest status
        q.goldQuest[_tokenId] = block.timestamp; //set start time
    }

    function _endQuestGold(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        QuestStorage storage q = diamondStorageQuest();
        require(s.owners[_tokenId] == msg.sender);
        require(s.players[_tokenId].status == 2);
        require(block.timestamp >= q.goldQuest[_tokenId] + 1, "it's too early to pull out");
        s.players[_tokenId].status = 0; //set back to idle
        delete q.goldQuest[_tokenId]; //remove the start time
        c.goldBalance[msg.sender]++; //mint one gold
    }

    function _startQuestGem(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        QuestStorage storage q = diamondStorageQuest();
        require(s.players[_tokenId].status == 0); //make sure player is idle
        require(s.owners[_tokenId] == msg.sender); //ownerOf
        require(block.timestamp >= q.cooldowns[_tokenId] + 60); //make sure that they have waited 5 mins for gem

        s.players[_tokenId].status = 5; //set gemQuest status
        q.gemQuest[_tokenId] = block.timestamp; //set start time
    }

    function _endQuestGem(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        QuestStorage storage q = diamondStorageQuest();
        require(s.owners[_tokenId] == msg.sender);
        require(s.players[_tokenId].status == 5);
        require(
            block.timestamp >= q.gemQuest[_tokenId] + 60, //must wait 5 mins
            "it's too early to pull out"
        );
        s.players[_tokenId].status = 0; //set back to idle
        delete q.gemQuest[_tokenId]; //remove the start time
        c.gemBalance[msg.sender]++; //mint one gem
        q.cooldowns[_tokenId] = block.timestamp;
    }

    function _dragonQuest(uint256 _playerId) internal returns (bool) {
        PlayerStorage storage s = diamondStoragePlayer();
        QuestStorage storage q = diamondStorageQuest();
        EquipmentStorage storage e = diamondStorageItem();
        TreasureStorage storage t = diamondStorageTreasure();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(block.timestamp >= q.cooldowns[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);
        require(
            keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.head].name))
                == keccak256(abi.encodePacked("WizHat")),
            "not wearing hat"
        ); // must have wizard hat on
        q.cooldowns[_playerId] = block.timestamp; //reset cooldown
        if (_random(_playerId) % 20 >= 19) {
            //5%
            t.treasureCount++;
            t.treasures[t.treasureCount] = Treasure(t.treasureCount, 1, t.playerToTreasure[_playerId].length, "Dscale"); //create treasure and add it main map
            t.playerToTreasure[_playerId].push(t.treasureCount); //push
            t.owners[t.treasureCount] = msg.sender; //set the user as the owner of the item;
            s.players[_playerId].xp++; //increment xp
            return true;
        } else {
            return false;
        }
    }

    function _gravityHammerQuest(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        QuestStorage storage q = diamondStorageQuest();
        EquipmentStorage storage e = diamondStorageItem();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(block.timestamp >= q.cooldowns[_playerId] + 43200); //make sure that they have waited 12 hours since last quest (43200 seconds);
        require(
            keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.head].name)) == keccak256(abi.encodePacked("GHammer")) || 
            keccak256(abi.encodePacked(e.equipment[s.players[_playerId].slot.head].name)) == keccak256(abi.encodePacked("WizHat"))
        );
    }

    function _random(uint256 nonce) internal returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        q.questCounter++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nonce, q.questCounter)));
    }

    function _getGoldBalance(address _address) internal view returns (uint256) {
        CoinStorage storage c = diamondStorageCoin();
        return c.goldBalance[_address];
    }

    function _getGemBalance(address _address) internal view returns (uint256) {
        CoinStorage storage c = diamondStorageCoin();
        return c.gemBalance[_address];
    }

    function _getGoldStart(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.goldQuest[_playerId];
    }

    function _getGemStart(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.gemQuest[_playerId];
    }

    function _getCooldown(uint256 _playerId) internal view returns (uint256) {
        QuestStorage storage q = diamondStorageQuest();
        return q.cooldowns[_playerId];
    }

    function _getTreasures(uint256 _playerId) internal view returns (uint256[] memory) {
        TreasureStorage storage t = diamondStorageTreasure();
        return t.playerToTreasure[_playerId];
    }

    function _getTreasure(uint256 _treasureId) internal view returns (Treasure memory) {
        TreasureStorage storage t = diamondStorageTreasure();
        return t.treasures[_treasureId];
    }
}

contract QuestFacet {
    event BeginQuesting(address indexed _playerAddress, uint256 _id);
    event EndQuesting(address indexed _playerAddress, uint256 _id);
    event DragonQuest(uint256 indexed _playerId);

    function startQuestGold(uint256 _tokenId) external {
        StorageLib._startQuestGold(_tokenId);
        emit BeginQuesting(msg.sender, _tokenId);
    }

    function endQuestGold(uint256 _tokenId) external {
        StorageLib._endQuestGold(_tokenId);
        emit EndQuesting(msg.sender, _tokenId);
    }

    function getGoldBalance(address _address) public view returns (uint256) {
        return StorageLib._getGoldBalance(_address);
    }

    function startQuestGem(uint256 _tokenId) external {
        StorageLib._startQuestGem(_tokenId);
        emit BeginQuesting(msg.sender, _tokenId);
    }

    function endQuestGem(uint256 _tokenId) external {
        StorageLib._endQuestGem(_tokenId);
        emit EndQuesting(msg.sender, _tokenId);
    }

    function dragonQuest(uint256 _playerId) external returns (bool result) {
        result = StorageLib._dragonQuest(_playerId);
        if (result) emit DragonQuest(_playerId);
        return result;
    }

    function getGemBalance(address _address) public view returns (uint256) {
        return StorageLib._getGemBalance(_address);
    }

    function getGoldStart(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getGoldStart(_playerId);
    }

    function getGemStart(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getGemStart(_playerId);
    }

    function getCooldown(uint256 _playerId) external view returns (uint256) {
        return StorageLib._getCooldown(_playerId);
    }

    function getTreasures(uint256 _playerId) external view returns (uint256[] memory) {
        return StorageLib._getTreasures(_playerId);
    }

    function getTreasure(uint256 _treasureId) external view returns (Treasure memory) {
        return StorageLib._getTreasure(_treasureId);
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PlayerSlotLib {
    struct Player {
        uint256 level;
        uint256 xp;
        uint256 status;
        uint256 strength;
        uint256 health;
        uint256 magic;
        uint256 mana;
        uint256 agility;
        uint256 luck;
        uint256 wisdom;
        uint256 haki;
        uint256 perception;
        uint256 defense;
        string name;
        string uri;
        bool male;
        Slot slot;
    }

    // slots {
    //     0: head;
    //     1: body;
    //     2: lefthand;
    //     3: rightHand;
    //     4: pants;
    //     5: feet;
    // }

    // StatusCodes {
    //     0: idle;
    //     1: combatTrain;
    //     2: goldQuest;
    //     3: manaTrain;
    //     4: Arena;
    //     5: gemQuest;
    // }

    struct Slot {
        uint256 head;
        uint256 body;
        uint256 leftHand;
        uint256 rightHand;
        uint256 pants;
        uint256 feet;
    }

    enum TokenTypes {
        PlayerMale,
        PlayerFemale,
        Guitar,
        Sword,
        Armor,
        Helmet,
        WizHat,
        SorcShoes,
        GemSword,
        GoldCoin,
        GemCoin,
        TotemCoin,
        DiamondCoin
    }
}