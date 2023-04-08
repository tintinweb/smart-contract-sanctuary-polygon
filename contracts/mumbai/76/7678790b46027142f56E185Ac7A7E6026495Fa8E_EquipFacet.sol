// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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

struct Item {
    uint256 slot;
    uint256 rank;
    uint256 value;
    uint256 stat;
    string name;
    address owner;
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

struct Slot {
    uint256 head;
    uint256 body;
    uint256 leftHand;
    uint256 rightHand;
    uint256 pants;
    uint256 feet;
}

// slots {
//     0: head;
//     1: body;
//     2: lefthand;
//     3: rightHand;
//     4: pants;
//     5: feet;
// }

library StorageLib {

    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant ITEM_STORAGE_POSITION = keccak256("item.test.storage.a");


    struct PlayerStorage {
        uint256 totalSupply;
        uint256 playerCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => Player) players;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(string => bool) usedNames;
        mapping(address => uint256[]) addressToPlayers;
        mapping(uint256 => Slot) slots;
    }

    struct ItemStorage {
        uint256 itemCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => Item) items;
        mapping(address => uint256[]) addressToItems;
    }


    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function diamondStorageItem() internal pure returns (ItemStorage storage ds) {
        bytes32 position = ITEM_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _increaseStats (uint256 _playerId, uint256 _itemId) internal {
        ItemStorage storage i = diamondStorageItem();   
        PlayerStorage storage s = diamondStoragePlayer();
        uint256 stat = i.items[_itemId].stat;
        if (stat == 0) { //if strength
            s.players[_playerId].strength += i.items[_itemId].value;
        } else if (stat == 1) { //if health
            s.players[_playerId].health += i.items[_itemId].value;
        } else if (stat == 2) { //if agility
            s.players[_playerId].agility += i.items[_itemId].value;
        } else if (stat == 3) { //if magic
            s.players[_playerId].magic += i.items[_itemId].value;
        } else if (stat == 4) { //if defense 
            s.players[_playerId].defense += i.items[_itemId].value;
        } else { // must be luck
            s.players[_playerId].luck += i.items[_itemId].value;
        }
    }
    function _decreaseStats (uint256 _playerId, uint256 _itemId) internal {
        ItemStorage storage i = diamondStorageItem();   
        PlayerStorage storage s = diamondStoragePlayer();
        uint256 stat = i.items[_itemId].stat;
        if (stat == 0) { //if strength
            s.players[_playerId].strength -= i.items[_itemId].value;
        } else if (stat == 1) { //if health
            s.players[_playerId].health -= i.items[_itemId].value;
        } else if (stat == 2) { //if agility
            s.players[_playerId].agility -= i.items[_itemId].value;
        } else if (stat == 3) { //if magic
            s.players[_playerId].magic -= i.items[_itemId].value;
        } else if (stat == 4) { //if defense 
            s.players[_playerId].defense -= i.items[_itemId].value;
        } else { // must be luck
            s.players[_playerId].luck -= i.items[_itemId].value;
        }
    }

    function _equipHead (uint256 _playerId, uint256 _itemId) internal {
        ItemStorage storage i = diamondStorageItem();   
        PlayerStorage storage s = diamondStoragePlayer();
        require(i.owners[_itemId] == msg.sender); //require owner of Item
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        require(i.items[_itemId].slot == 0); //require item head
        require(!i.items[_itemId].isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.head == 0); //require that player doesnt have a head item on

        i.items[_itemId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.head == _itemId; //equip the item to the player
        _increaseStats(_playerId, _itemId);
    }
    
    function _unequipHead (uint256 _playerId, uint256 _itemId) internal {
        ItemStorage storage i = diamondStorageItem();   
        PlayerStorage storage s = diamondStoragePlayer();
        require(i.owners[_itemId] == msg.sender); //require owner of Item
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        require(i.items[_itemId].slot == 0); //require item head
        require(i.items[_itemId].isEquiped); //require item is equiped
        require(s.players[_playerId].slot.head == _itemId); //require that player has the same item on

        i.items[_itemId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.head == 0; //reset the slot value to 0
        _decreaseStats(_playerId, _itemId);
    }
    function _equipBody (uint256 _playerId, uint256 _itemId) internal {
        ItemStorage storage i = diamondStorageItem();   
        PlayerStorage storage s = diamondStoragePlayer();
        // require(i.owners[_itemId] == msg.sender); //require owner of Item
        // require(s.players[_playerId].status == 0); //make sure player is idle
        // require(s.owners[_playerId] == msg.sender); //ownerOf player
        // require(i.items[_itemId].slot == 1); //require item body
        // require(!i.items[_itemId].isEquiped); //require item isn't equiped
        // require(s.players[_playerId].slot.body == 0); //require that player doesnt have a body item on

        i.items[_itemId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.body = _itemId; //equip the item to the player
        _increaseStats(_playerId, _itemId);
    }

    function _unequipBody (uint256 _playerId, uint256 _itemId) internal {
        ItemStorage storage i = diamondStorageItem();   
        PlayerStorage storage s = diamondStoragePlayer();
        require(i.owners[_itemId] == msg.sender); //require owner of Item
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        require(i.items[_itemId].slot == 1); //require item body
        require(i.items[_itemId].isEquiped); //require item is equiped
        require(s.players[_playerId].slot.body == _itemId); //require that player has the same item on

        i.items[_itemId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.body = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _itemId);
    }

    function _equipRightHand (uint256 _playerId, uint256 _itemId) internal {
        ItemStorage storage i = diamondStorageItem();   
        PlayerStorage storage s = diamondStoragePlayer();
        require(i.owners[_itemId] == msg.sender); //require owner of Item
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        require(i.items[_itemId].slot == 3 || i.items[_itemId].slot == 2); //require item is a hand item
        require(!i.items[_itemId].isEquiped); //require item isn't equiped
        require(s.players[_playerId].slot.rightHand == 0); //require that player doesnt have a right hand item on

        i.items[_itemId].isEquiped = true; //set equiped status to true;
        s.players[_playerId].slot.rightHand = _itemId; //equip the item to the player
        _increaseStats(_playerId, _itemId);
    }
    function _unequipRightHand (uint256 _playerId, uint256 _itemId) internal {
        ItemStorage storage i = diamondStorageItem();   
        PlayerStorage storage s = diamondStoragePlayer();
        require(i.owners[_itemId] == msg.sender); //require owner of Item
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf player
        require(i.items[_itemId].slot == 3 || i.items[_itemId].slot == 2); //require item on right hand
        require(i.items[_itemId].isEquiped); //require item is equiped
        require(s.players[_playerId].slot.rightHand == _itemId); //require that player has the same item on

        i.items[_itemId].isEquiped = false; //set isEquiped status to false;
        s.players[_playerId].slot.rightHand = 0; //reset the slot value to 0
        _decreaseStats(_playerId, _itemId);
    }


}



contract EquipFacet {

    event ItemEquiped(address indexed _owner, uint256 indexed _playerId, uint256 indexed _itemId);
    event ItemUnequiped(address indexed _owner, uint256 indexed _playerId, uint256 indexed _itemId);

    function equipHead(uint256 _playerId, uint256 _itemId) external {
        StorageLib._equipHead(_playerId, _itemId);
        emit ItemEquiped(msg.sender, _playerId, _itemId);
    }
    function equipBody(uint256 _playerId, uint256 _itemId) external {
        StorageLib._equipBody(_playerId, _itemId);
        emit ItemEquiped(msg.sender, _playerId, _itemId);
    }
    function equipRightHand(uint256 _playerId, uint256 _itemId) external {
        StorageLib._equipRightHand(_playerId, _itemId);
        emit ItemEquiped(msg.sender, _playerId, _itemId);
    }
    function unequipHead(uint256 _playerId, uint256 _itemId) external {
        StorageLib._unequipHead(_playerId, _itemId);
        emit ItemUnequiped(msg.sender, _playerId, _itemId);
    }
    function unequipBody(uint256 _playerId, uint256 _itemId) external {
        StorageLib._unequipBody(_playerId, _itemId);
        emit ItemUnequiped(msg.sender, _playerId, _itemId);
    }
    function unequipRightHand(uint256 _playerId, uint256 _itemId) external {
        StorageLib._unequipRightHand(_playerId, _itemId);
        emit ItemUnequiped(msg.sender, _playerId, _itemId);
    }






    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}