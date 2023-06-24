// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";

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
    bytes32 constant EQUIPMENT_STORAGE_POSITION = keccak256("equipment.test.storage.a");
    bytes32 constant POTION_STORAGE_POSITION = keccak256("potion.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
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

    struct EquipmentStorage {
        uint256 equipmentCount;
        mapping(uint256 => uint256) owners; //maps equipment id to player id
        mapping(uint256 => Equipment) equipment;
        mapping(uint256 => uint256[]) playerToEquipment;
        mapping(uint256 => uint256) cooldown;
    }

    struct PotionStorage {
        mapping(uint256 => address) timePotion;
        mapping(address => uint256) healthPotion;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
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

    function diamondStorageItem() internal pure returns (EquipmentStorage storage ds) {
        bytes32 position = EQUIPMENT_STORAGE_POSITION;
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

    function diamondStorageTreasure() internal pure returns (TreasureStorage storage ds) {
        bytes32 position = TREASURE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _craftSword(uint256 _playerId, string memory _uri) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(c.goldBalance[msg.sender] >= 5); //check user has enough gold
        c.goldBalance[msg.sender] -= 5; //deduct 5 gold from the address' balance
        e.equipmentCount++; //increment equipmentCount
        e.owners[e.equipmentCount] = _playerId; //set owner to playerId
        e.equipment[e.equipmentCount] = Equipment(e.equipmentCount, e.playerToEquipment[_playerId].length, 2, 1, 3, 0, _playerId, "Sword", _uri, false);
        e.playerToEquipment[_playerId].push(e.equipmentCount);
    }

    function _craftWarHammer(uint256 _playerId, string memory _uri) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(c.goldBalance[msg.sender] >= 15); //check user has enough gold
        c.goldBalance[msg.sender] -= 15; //deduct 5 gold from the address' balance
        e.equipmentCount++; //increment equipmentCount
        e.owners[e.equipmentCount] = _playerId; //set owner to playerId
        e.equipment[e.equipmentCount] = Equipment(e.equipmentCount, e.playerToEquipment[_playerId].length, 2, 1, 5, 0, _playerId, "WHammer", _uri, false);
        e.playerToEquipment[_playerId].push(e.equipmentCount);
    }

    function _craftGravityHammer(uint256 _playerId, uint256 _itemId, string memory _uri) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0, "must be idle"); //make sure player is idle
        require(s.owners[_playerId] == msg.sender, "you are not the owner"); //ownerOf
        require(e.owners[_itemId] == _playerId); //check that the player is the onwer of the hamemr
        require(!e.equipment[_itemId].isEquiped, "must not be equipped"); //check that the hammer is not equipped
        require(
            keccak256(abi.encodePacked(e.equipment[_itemId].name))
                == keccak256(abi.encodePacked("WHammer")),
            "this is not a war hammer"
        );

        uint256 keyToDelete = e.equipment[_itemId].pointer; //sets the index to delete as the desired key
        uint256 keyToMove = e.playerToEquipment[_playerId].length - 1; //gets the index of the last equipment that is owned by the player
        e.playerToEquipment[_playerId][keyToDelete] = keyToMove; //the id in the playerToEquipment is replaced w the last index key 
        e.equipment[e.playerToEquipment[_playerId][keyToDelete]].pointer = keyToDelete; //reset the pointer
        e.playerToEquipment[_playerId].pop(); //remove the last key item
        delete e.playerToEquipment[_itemId]; //delete the item

        e.equipmentCount++; //increment equipmentCount
        e.owners[e.equipmentCount] = _playerId; //set owner to playerId
        e.equipment[e.equipmentCount] = Equipment(e.equipmentCount, e.playerToEquipment[_playerId].length, 2, 1, 10, 0, _playerId, "GHammer", _uri, false);
        e.playerToEquipment[_playerId].push(e.equipmentCount);
    }

    function _craftGuitar(uint256 _playerId, string memory _uri) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(c.goldBalance[msg.sender] >= 10); //check user has enough gold
        require(s.players[_playerId].mana >= 2); //make sure player has at least 2 mana
        c.goldBalance[msg.sender] -= 10; //deduct 10 gold from the address' balance
        s.players[_playerId].mana -= 2; //deduct 2 mana from the player
        e.equipmentCount++; //increment equipmentCount
        e.owners[e.equipmentCount] = _playerId; //set owner to playerId
        e.equipment[e.equipmentCount] = Equipment(e.equipmentCount, e.playerToEquipment[_playerId].length, 2, 1, 1, 0, _playerId, "Guitar", _uri, false);
        e.playerToEquipment[_playerId].push(e.equipmentCount);
    }

    function _craftArmor(uint256 _playerId, string memory _uri) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        EquipmentStorage storage e = diamondStorageItem();
        CoinStorage storage c = diamondStorageCoin();
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        require(c.goldBalance[msg.sender] >= 10); //check user has enough gold
        require(s.players[_playerId].mana >= 2); //make sure player has at least 2 mana
        c.goldBalance[msg.sender] -= 10; //deduct 10 gold from the address' balance
        s.players[_playerId].mana -= 2; //deduct 2 mana from the player
        e.equipmentCount++; //increment equipmentCount
        e.owners[e.equipmentCount] = _playerId; //set owner to playerId
        e.equipment[e.equipmentCount] = Equipment(e.equipmentCount, e.playerToEquipment[_playerId].length, 1, 1, 10, 1, _playerId, "Armor", _uri, false);
        e.playerToEquipment[_playerId].push(e.equipmentCount);
    }

    // function _craftHelmet(uint256 _tokenId) internal {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     ItemStorage storage i = diamondStorageItem();
    //     CoinStorage storage c = diamondStorageCoin();
    //     require(s.players[_tokenId].status == 0); //make sure player is idle
    //     require(s.owners[_tokenId] == msg.sender); //ownerOf
    //     require(c.goldBalance[msg.sender] >= 4); //check user has enough gold
    //     c.goldBalance[msg.sender] -= 4; //deduct 8 gold from the address' balance
    //     i.itemCount++;
    //     i.owners[i.itemCount] = msg.sender;
    //     i.items[i.itemCount] = Item(0, 1, 4, 1, "Helmet", msg.sender, false); // slot, rank, value, stat
    //     i.addressToItems[msg.sender].push(i.itemCount);
    // }

    // function _craftWizardHat(uint256 _tokenId) internal {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     ItemStorage storage i = diamondStorageItem();
    //     CoinStorage storage c = diamondStorageCoin();
    //     require(s.players[_tokenId].status == 0); //make sure player is idle
    //     require(s.owners[_tokenId] == msg.sender); //ownerOf
    //     require(c.gemBalance[msg.sender] >= 10); //check user has enough gem
    //     require(s.players[_tokenId].mana >= 10); //make sure player has at least 10 mana
    //     c.gemBalance[msg.sender] -= 10; //deduct 8 gem from the address' balance
    //     s.players[_tokenId].mana -= 10; //deduct 51 mana from the player
    //     i.itemCount++;
    //     i.owners[i.itemCount] = msg.sender;
    //     i.items[i.itemCount] = Item(0, 1, 5, 3, "WizHat", msg.sender, false); // slot, rank, value, stat(catagory)
    //     i.addressToItems[msg.sender].push(i.itemCount);
    // }

    // function _craftSorcerShoes(uint256 _tokenId) internal {
    //     PlayerStorage storage s = diamondStoragePlayer();
    //     ItemStorage storage i = diamondStorageItem();
    //     CoinStorage storage c = diamondStorageCoin();
    //     require(s.players[_tokenId].status == 0); //make sure player is idle
    //     require(s.owners[_tokenId] == msg.sender); //ownerOf
    //     require(s.players[_tokenId].mana >= 1); //make sure player has at least 1 mana
    //     require(c.goldBalance[msg.sender] >= 3); //check user has enough gold
    //     require(c.gemBalance[msg.sender] >= 1); //check user has enough gem
    //     c.goldBalance[msg.sender] -= 3; //deduct 3 gold from the address' balance
    //     c.gemBalance[msg.sender] -= 1; //deduct 1 gem from the address' balance
    //     s.players[_tokenId].mana -= 1; //deduct 51 mana from the player
    //     i.itemCount++; //increment item count
    //     i.owners[i.itemCount] = msg.sender;
    //     i.items[i.itemCount] = Item(5, 1, 2, 3, "SorcShoes", msg.sender, false); // slot, rank, value, stat
    //     i.addressToItems[msg.sender].push(i.itemCount);
    // }



    function _getPlayerToEquipment(uint256 _playerId) internal view returns (uint256[] memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.playerToEquipment[_playerId];
    }

    function _getEquipment(uint256 _equipmentId) internal view returns (Equipment memory) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.equipment[_equipmentId];
    }

    function _getEquipmentCount() internal view returns (uint256) {
        EquipmentStorage storage e = diamondStorageItem();
        return e.equipmentCount;
    }

    // function _mintCoins() internal {
    //     CoinStorage storage c = diamondStorageCoin();
    //     c.goldBalance[msg.sender] += 100; //mint one gold
    //     c.gemBalance[msg.sender] += 100; //mint one gold
    //     c.diamondBalance[msg.sender] += 100; //mint one gold
    //     c.totemBalance[msg.sender] += 100; //mint one gold
    // }

    // function _getCoinBalances(address _player)
    //     internal
    //     view
    //     returns (uint256 goldBalance, uint256 gemBalance, uint256 totemBalance, uint256 diamondBalance)
    // {
    //     CoinStorage storage c = diamondStorageCoin();
    //     goldBalance = c.goldBalance[_player];
    //     gemBalance = c.gemBalance[_player];
    //     totemBalance = c.totemBalance[_player];
    //     diamondBalance = c.diamondBalance[_player];
    // }
}

contract CraftFacet {
    event ItemCrafted(address indexed _owner, uint256 _player);

    function craftSword(uint256 _tokenId, string memory _uri) external {
        StorageLib._craftSword(_tokenId, _uri);
        emit ItemCrafted(msg.sender, _tokenId);
    }

    // function craftGuitar(uint256 _tokenId) external {
    //     StorageLib._craftGuitar(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function craftArmor(uint256 _tokenId) external {
    //     StorageLib._craftArmor(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function craftHelmet(uint256 _tokenId) external {
    //     StorageLib._craftHelmet(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function craftSorcerShoes(uint256 _tokenId) external {
    //     StorageLib._craftSorcerShoes(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function craftWizardHat(uint256 _tokenId) external {
    //     StorageLib._craftWizardHat(_tokenId);
    //     emit ItemCrafted(msg.sender, _tokenId);
    // }

    // function getItems(address _address) public view returns (uint256[] memory items) {
    //     items = StorageLib._getItems(_address);
    // }

    // function getItem(uint256 _itemId) public view returns (Item memory item) {
    //     item = StorageLib._getItem(_itemId);
    // }

    // function getItemCount() public view returns (uint256 count) {
    //     count = StorageLib._getItemCount();
    // }

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