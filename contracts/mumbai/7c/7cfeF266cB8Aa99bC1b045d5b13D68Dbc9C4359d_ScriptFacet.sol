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

// status {
//     0: idle;
//     1: training;
//     2: quest;
//     3: crafting;
//     4: arena;
// }

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
    uint256 feet;
}

// slots {
//     0: head;
//     1: body;
//     2: hand;
//     3: pants;
//     4: feet;
// }


library StorageLib {

    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
    bytes32 constant ARENA_STORAGE_POSITION = keccak256("Arena.test.storage.a");
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

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) gemBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    struct ItemStorage {
        uint256 itemCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => Item) items;
        mapping(address => uint256[]) addressToItems;
        mapping(uint256 => uint256) cooldown;
    }

    struct ArenaStorage {
        bool open;
        uint256 arenaCounter;
        Arena mainArena;
        Arena secondArena;
        Arena thirdArena;
        Arena magicArena;
        mapping(uint256 => uint256) mainArenaWins;
        mapping(uint256 => uint256) mainArenaLosses;
        mapping(uint256 => uint256) secondArenaWins;
        mapping(uint256 => uint256) secondArenaLosses;
        mapping(uint256 => uint256) thirdArenaWins;
        mapping(uint256 => uint256) thirdArenaLosses;
        mapping(uint256 => uint256) magicArenaWins;
        mapping(uint256 => uint256) magicArenaLosses;
        mapping(uint256 => uint256) totalArenaWins;
        mapping(uint256 => uint256) totalArenaLosses;   
    }

    struct Arena {
        bool open;
        uint256 hostId;
        uint256 ante;
        address payable hostAddress;
    }


    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
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
    function diamondStorageArena() internal pure returns (ArenaStorage storage ds) {
        bytes32 position = ARENA_STORAGE_POSITION;
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

    function _activeScript(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        s.players[_playerId].mana += 50;
        c.gemBalance[msg.sender] += 50;
        c.goldBalance[msg.sender] += 500;
    }



    function _openSecondArena () internal {
        ArenaStorage storage a = diamondStorageArena();
        a.secondArena.open = true;
    }

    function _forceUnEquip() internal {
        ItemStorage storage i = diamondStorageItem();   
        for (uint256 j = 0; j < i.itemCount; j++) {
            if (i.items[j].slot == 0) {
                i.items[j].isEquiped = false;
            }
        }
    }

    function _getBalance(address _address) internal view returns(uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        return s.balances[_address];
    }

    function _openArenas () internal {
        ArenaStorage storage a = diamondStorageArena();
        a.mainArena.open = true;
        // a.secondArena.open = true;
        // a.thirdArena.open = true;
        // a.magicArena.open = true;
    }

}



contract ScriptFacet {



    // function activeScript(uint256 _playerId) public {
    //     StorageLib._activeScript(_playerId);
    // }

    // function forceUnEquip() public {
    //     StorageLib._forceUnEquip();
    // }

    function openArena() public {
        StorageLib._openArenas();
    }




    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}