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
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    struct ArenaStorage {
        bool open;
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

    function _enterMainArena(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(a.mainArena.open, "arena is closed"); //check that the arena is open
        require(c.goldBalance[msg.sender] >= 1, "not enough gold"); //check to make sure the user has enough gold
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        c.goldBalance[msg.sender] -= 1; //deduct one gold from their balance
        s.players[_playerId].status = 4; //set the host's status to being in the arena
        a.mainArena.open = false;
        a.mainArena.hostId = _playerId;
        a.mainArena.hostAddress = payable(msg.sender);
    }

    function _fightMainArena(uint256 _challengerId) internal returns (uint256[] memory) {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(!a.mainArena.open, "arena is empty");
        require(s.players[_challengerId].status == 0); //make sure player is idle
        require(c.goldBalance[msg.sender] >= 1, "not enough gold"); //check to make sure the user has enough gold
        uint256 winner = _simulateFight(a.mainArena.hostId, _challengerId);
        uint256 _winner;
        uint256 _loser;
        if (winner == _challengerId) { //means the challenger won
            _winner = _challengerId;
            _loser = a.mainArena.hostId;
            a.mainArenaWins[_challengerId]++; //add main Arena wins
            a.totalArenaWins[_challengerId]++; //add total wins
            a.mainArenaLosses[a.mainArena.hostId]++; //add main Arena losses
            a.totalArenaLosses[a.mainArena.hostId]++; //add total losses
            c.goldBalance[msg.sender] += 1; //increase gold
        } else { //means the host won
            _loser = _challengerId;
            _winner = a.mainArena.hostId;
            a.mainArenaWins[a.mainArena.hostId]++; //add main Arena wins
            a.totalArenaWins[a.mainArena.hostId]++; //add total wins
            a.mainArenaLosses[_challengerId]++; //add main Arena losses
            a.totalArenaLosses[_challengerId]++; //add total losses
            c.goldBalance[a.mainArena.hostAddress] += 2; //increase gold of the host
            c.goldBalance[msg.sender] -= 1; //decrease gold
        }
        a.mainArena.open = true;
        s.players[a.mainArena.hostId].status = 0; // set the host to idle
        uint256[] memory result;
        result[0] = _winner;
        result[1] = _loser;
        return result;
    }

    function _simulateFight(uint256 _hostId, uint256 _challengerId) internal view returns (uint256) {
        PlayerStorage storage s = diamondStoragePlayer();

        Player storage host = s.players[_hostId];
        Player storage challenger = s.players[_challengerId];
        uint hostPoints = (host.health * (_randomMainArena(_hostId) % 5)) - (challenger.strength  * (_randomMainArena(_challengerId) % 4));
        uint challengerPoints = (challenger.health * (_randomMainArena(_challengerId) % 5)) - (host.strength  * (_randomMainArena(_hostId) % 5));
        if ( hostPoints >= challengerPoints ) {
            return _hostId;
        } else {
            return _challengerId;
        }
    }

    function _randomMainArena (uint _tokenId) internal view returns(uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        return uint256(keccak256(abi.encodePacked(block.timestamp + s.playerCount + _tokenId)));
    }

    function _enterMagicArena(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(a.magicArena.open, "arena is closed"); //check that the arena is open
        require(c.goldBalance[msg.sender] >= 1, "not enough gold"); //check to make sure the user has enough gold
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        c.goldBalance[msg.sender] -= 1; //deduct one gold from their balance
        s.players[_playerId].status = 4; //set the host's status to being in the arena
        a.magicArena.open = false;
        a.magicArena.hostId = _playerId;
        a.magicArena.hostAddress = payable(msg.sender);
    }

    function _fightMagicArena(uint256 _challengerId) internal returns (uint256[] memory) {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(!a.magicArena.open, "arena is empty");
        require(s.players[_challengerId].status == 0); //make sure player is idle
        require(c.goldBalance[msg.sender] >= 1, "not enough gold"); //check to make sure the user has enough gold
        uint256 winner = _simulateMagicFight(a.magicArena.hostId, _challengerId);
        uint256 _winner;
        uint256 _loser;
        if (winner == _challengerId) { //means the challenger won
            _winner = _challengerId;
            _loser = a.mainArena.hostId;
            a.magicArenaWins[_challengerId]++; //add main Arena wins
            a.totalArenaWins[_challengerId]++; //add total wins
            a.magicArenaLosses[a.mainArena.hostId]++; //add main Arena losses
            a.totalArenaLosses[a.mainArena.hostId]++; //add total losses
            c.goldBalance[msg.sender] += 1; //increase gold
        } else { //means the host won
            _loser = _challengerId;
            _winner = a.mainArena.hostId;
            a.magicArenaWins[a.mainArena.hostId]++; //add main Arena wins
            a.totalArenaWins[a.mainArena.hostId]++; //add total wins
            a.magicArenaLosses[_challengerId]++; //add main Arena losses
            a.totalArenaLosses[_challengerId]++; //add total losses
            c.goldBalance[a.mainArena.hostAddress] += 2; //increase gold of the host
            c.goldBalance[msg.sender] -= 1; //decrease gold
        }
        a.magicArena.open = true;
        s.players[a.magicArena.hostId].status = 0; // set the host to idle
        uint256[] memory result;
        result[0] = _winner;
        result[1] = _loser;
        return result;
    }

    function _simulateMagicFight(uint256 _hostId, uint256 _challengerId) internal view returns (uint256) {
        PlayerStorage storage s = diamondStoragePlayer();

        Player storage host = s.players[_hostId];
        Player storage challenger = s.players[_challengerId];
        uint hostPoints = (host.health * (_randomMainArena(_hostId) % 5)) - (challenger.magic  * (_randomMainArena(_challengerId) % 4));
        uint challengerPoints = (challenger.health * (_randomMainArena(_challengerId) % 5)) - (host.magic  * (_randomMainArena(_hostId) % 5));
        if ( hostPoints >= challengerPoints ) {
            return _hostId;
        } else {
            return _challengerId;
        }
    }

    function _getMainArena() internal view returns (bool, uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return (a.mainArena.open, a.mainArena.hostId);
    }
    function _getSecondArena() internal view returns (bool, uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return (a.secondArena.open, a.secondArena.hostId) ;
    }
    function _getThirdArena() internal view returns (bool) {
        ArenaStorage storage a = diamondStorageArena();
        return a.thirdArena.open;
    }
    function _getMagicArena() internal view returns (bool, uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return (a.magicArena.open, a.magicArena.hostId);
    }



    function _getTotalWins(uint256 _playerId) internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.totalArenaWins[_playerId];   
    }
    function _getMainArenaWins(uint256 _playerId) internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.mainArenaWins[_playerId];   
    }
    function _getMagicArenaWins(uint256 _playerId) internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.magicArenaWins[_playerId];   
    }
    function _getTotalLosses(uint256 _playerId) internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.totalArenaLosses[_playerId];   
    }
    function _getMainArenaLosses(uint256 _playerId) internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.mainArenaLosses[_playerId];   
    }
    function _getMagicArenaLosses(uint256 _playerId) internal view returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        return a.magicArenaLosses[_playerId];   
    }


    function _openArenas () internal {
        ArenaStorage storage a = diamondStorageArena();
        require(a.open == false);
        a.open = true;
        a.mainArena.open = true;
        a.secondArena.open = true;
        a.thirdArena.open = true;
        a.magicArena.open = true;
    }

}



contract ArenaFacet {

    event MainWin(uint256 indexed _playerId);
    event MagicWin(uint256 indexed _playerId);
    event MainLoss(uint256 indexed _playerId);
    event MagicLoss(uint256 indexed _playerId);
    
    event EnterMain(uint256 indexed _playerId);
    event EnterMagic(uint256 indexed _playerId);

    function openArenas() public {
        StorageLib._openArenas();
    }

    function getMainArena() external view returns(bool, uint256) {
        return StorageLib._getMainArena();
    }
    // function getSecondArena() external view returns(bool) {
    //     return StorageLib._getMainArena();
    // }
    // function getThirdArena() external view returns(bool) {
    //     return StorageLib._getMainArena();
    // }
    function getMagicArena() external view returns(bool, uint256) {
        return StorageLib._getMagicArena();
    }

    function enterMainArena(uint256 _playerId) public {
        StorageLib._enterMainArena(_playerId);
        emit EnterMain(_playerId);
    }

    function fightMainArena(uint256 _challengerId) public {
        uint256[] memory result = StorageLib._fightMainArena(_challengerId);
        emit MainWin(result[0]);
        emit MainLoss(result[1]);
    }

    function enterMagicArena(uint256 _playerId) public {
        StorageLib._enterMagicArena(_playerId);
        emit EnterMagic(_playerId);
    }

    function fightMagicArena(uint256 _challengerId) public {
        uint256[] memory result = StorageLib._fightMagicArena(_challengerId);
        emit MagicWin(result[0]);
        emit MagicLoss(result[1]);
    }


    function getTotalWins(uint256 _playerId) public view returns(uint256) {
        return StorageLib._getTotalWins(_playerId);
    }
    function getMagicArenaWins(uint256 _playerId) public view returns(uint256) {
        return StorageLib._getMagicArenaWins(_playerId);
    }
    function getMainArenaWins(uint256 _playerId) public view returns(uint256) {
        return StorageLib._getMainArenaWins(_playerId);
    }
    function getTotalLosses(uint256 _playerId) public view returns(uint256) {
        return StorageLib._getTotalLosses(_playerId);
    }
    function getMagicArenaLosses(uint256 _playerId) public view returns(uint256) {
        return StorageLib._getMagicArenaLosses(_playerId);
    }
    function getMainArenaLosses(uint256 _playerId) public view returns(uint256) {
        return StorageLib._getMainArenaLosses(_playerId);
    }
    






    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}