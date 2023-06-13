// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PlayerSlotLib.sol";

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

library StorageLib {
    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");
    bytes32 constant ARENA_STORAGE_POSITION = keccak256("Arena.test.storage.a");

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
        mapping(uint256 => PlayerSlotLib.Slot) slots;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
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

    function _fightMainArena(uint256 _challengerId) internal returns (uint256, uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(!a.mainArena.open, "arena is empty");
        require(s.players[_challengerId].status == 0); //make sure player is idle
        require(c.goldBalance[msg.sender] >= 1, "not enough gold"); //check to make sure the user has enough gold
        uint256 winner = _simulateAlternateFight(a.mainArena.hostId, _challengerId);
        uint256 _winner;
        uint256 _loser;
        if (winner == _challengerId) {
            //means the challenger won
            _winner = _challengerId;
            _loser = a.mainArena.hostId;
            a.mainArenaWins[_challengerId]++; //add main Arena wins
            a.totalArenaWins[_challengerId]++; //add total wins
            a.mainArenaLosses[a.mainArena.hostId]++; //add main Arena losses
            a.totalArenaLosses[a.mainArena.hostId]++; //add total losses
            c.goldBalance[msg.sender] += 1; //increase gold
        } else {
            //means the host won
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
        a.mainArena.hostId = 0; //set the id to 0
        return (_winner, _loser);
    }

    function _enterSecondArena(uint256 _playerId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(a.secondArena.open, "arena is closed"); //check that the arena is open
        require(c.goldBalance[msg.sender] >= 1, "not enough gold"); //check to make sure the user has enough gold
        require(s.players[_playerId].status == 0); //make sure player is idle
        require(s.owners[_playerId] == msg.sender); //ownerOf
        c.goldBalance[msg.sender] -= 1; //deduct one gold from their balance
        s.players[_playerId].status = 4; //set the host's status to being in the arena
        a.secondArena.open = false;
        a.secondArena.hostId = _playerId;
        a.secondArena.hostAddress = payable(msg.sender);
    }

    function _fightSecondArena(uint256 _challengerId) internal returns (uint256, uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(!a.secondArena.open, "arena is empty");
        require(s.players[_challengerId].status == 0); //make sure player is idle
        require(c.goldBalance[msg.sender] >= 1, "not enough gold"); //check to make sure the user has enough gold
        uint256 winner = _simulateAlternateFight(a.secondArena.hostId, _challengerId);
        uint256 _winner;
        uint256 _loser;
        if (winner == _challengerId) {
            //means the challenger won
            _winner = _challengerId;
            _loser = a.secondArena.hostId;
            a.secondArenaWins[_challengerId]++; //add main Arena wins
            a.totalArenaWins[_challengerId]++; //add total wins
            a.secondArenaLosses[a.secondArena.hostId]++; //add main Arena losses
            a.totalArenaLosses[a.secondArena.hostId]++; //add total losses
            c.goldBalance[msg.sender] += 1; //increase gold
        } else {
            //means the host won
            _loser = _challengerId;
            _winner = a.secondArena.hostId;
            a.secondArenaWins[a.secondArena.hostId]++; //add main Arena wins
            a.totalArenaWins[a.secondArena.hostId]++; //add total wins
            a.secondArenaLosses[_challengerId]++; //add main Arena losses
            a.totalArenaLosses[_challengerId]++; //add total losses
            c.goldBalance[a.secondArena.hostAddress] += 2; //increase gold of the host
            c.goldBalance[msg.sender] -= 1; //decrease gold
        }
        a.secondArena.open = true;
        s.players[a.secondArena.hostId].status = 0; // set the host to idle
        a.secondArena.hostId = 0; //set the id to 0
        return (_winner, _loser);
    }

    function _simulateFight(uint256 _hostId, uint256 _challengerId) internal view returns (uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        PlayerSlotLib.Player storage host = s.players[_hostId];
        PlayerSlotLib.Player storage challenger = s.players[_challengerId];
        uint256 hostPoints = (host.health * (_randomMainArena(_hostId) % 5))
            - (challenger.strength * (_randomMainArena(_challengerId) % 4));
        uint256 challengerPoints = (challenger.health * (_randomMainArena(_challengerId) % 5))
            - (host.strength * (_randomMainArena(_hostId) % 5));
        if (hostPoints >= challengerPoints) {
            return _hostId;
        } else {
            return _challengerId;
        }
    }

    function _simulateAlternateFight(uint256 _hostId, uint256 _challengerId) internal returns (uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        PlayerSlotLib.Player storage host = s.players[_hostId];
        PlayerSlotLib.Player storage challenger = s.players[_challengerId];
        uint256 hostPoints = host.health + host.strength;
        uint256 challengerPoints = challenger.health + challenger.strength;
        uint256 winner = _fightCalc(hostPoints, challengerPoints);
        if (winner == hostPoints) {
            return _hostId;
        } else {
            return _challengerId;
        }
    }

    function probs(uint256 nonce) internal returns (uint256 output) {
        uint256 rand = _random(nonce);
        output = rand % 10;
    }

    function _random(uint256 nonce) internal returns (uint256) {
        ArenaStorage storage a = diamondStorageArena();
        a.arenaCounter++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nonce, a.arenaCounter)));
    }

    function _fightCalc(uint256 x, uint256 y) internal returns (uint256) {
        if (x > y) {
            if (x / y == 1) {
                if (probs(x) >= 4) {
                    //60% higher odds wins
                    return x;
                } else {
                    return y;
                }
            } else if (x / y == 2) {
                if (probs(x) >= 3) {
                    //70% higher odds wins
                    return x;
                } else {
                    return y;
                }
            } else if (x / y == 3) {
                if (probs(x) >= 2) {
                    //80% higher odds wins
                    return x;
                } else {
                    return y;
                }
            } else {
                if (probs(x) >= 1) {
                    //90% higher odds wins
                    return x;
                } else {
                    return y;
                }
            }
        } else {
            if (y / x == 1) {
                if (probs(y) >= 4) {
                    //60% higher odds wins
                    return y;
                } else {
                    return x;
                }
            } else if (y / x == 2) {
                if (probs(y) >= 3) {
                    //70% higher odds wins
                    return y;
                } else {
                    return x;
                }
            } else if (y / x == 3) {
                //80% higher odds
                if (probs(y) >= 2) {
                    //80% higher odds wins
                    return y;
                } else {
                    return x;
                }
            } else {
                if (probs(y) >= 1) {
                    //90% higher odds wins
                    return y;
                } else {
                    return x;
                }
            }
        }
    }

    function _randomMainArena(uint256 _tokenId) internal view returns (uint256) {
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

    function _fightMagicArena(uint256 _challengerId) internal returns (uint256, uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        ArenaStorage storage a = diamondStorageArena();
        require(!a.magicArena.open, "arena is empty");
        require(s.players[_challengerId].status == 0); //make sure player is idle
        require(c.goldBalance[msg.sender] >= 1, "not enough gold"); //check to make sure the user has enough gold
        uint256 winner = _simulateMagicFight(a.magicArena.hostId, _challengerId);
        uint256 _winner;
        uint256 _loser;
        if (winner == _challengerId) {
            //means the challenger won
            _winner = _challengerId;
            _loser = a.mainArena.hostId;
            a.magicArenaWins[_challengerId]++; //add main Arena wins
            a.totalArenaWins[_challengerId]++; //add total wins
            a.magicArenaLosses[a.mainArena.hostId]++; //add main Arena losses
            a.totalArenaLosses[a.mainArena.hostId]++; //add total losses
            c.goldBalance[msg.sender] += 1; //increase gold
        } else {
            //means the host won
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
        return (_winner, _loser);
    }

    function _simulateMagicFight(uint256 _hostId, uint256 _challengerId) internal returns (uint256) {
        PlayerStorage storage s = diamondStoragePlayer();
        PlayerSlotLib.Player storage host = s.players[_hostId];
        PlayerSlotLib.Player storage challenger = s.players[_challengerId];
        uint256 hostPoints = host.health + host.magic;
        uint256 challengerPoints = challenger.health + challenger.magic;
        uint256 winner = _fightCalc(hostPoints, challengerPoints);
        if (winner == hostPoints) {
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
        return (a.secondArena.open, a.secondArena.hostId);
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

    function _leaveMainArena(uint256 _hostId) internal {
        ArenaStorage storage a = diamondStorageArena();
        PlayerStorage storage s = diamondStoragePlayer();
        CoinStorage storage c = diamondStorageCoin();
        require(a.mainArena.hostId == _hostId, "you are not the host"); //plerys is the current host
        require(s.players[_hostId].status == 4, "you are not in the arena"); //check if they are in arena
        a.mainArena.hostId = 0; //reset the id of arena
        a.mainArena.open = true; //reopen the arena
        s.players[_hostId].status = 0; //set satus og host back to idle
        c.goldBalance[msg.sender] += 1; //increase gold
    }

    function _openArenas() internal {
        ArenaStorage storage a = diamondStorageArena();
        // require(a.open == false);
        // a.open = true;
        a.mainArena.open = true;
        // a.secondArena.open = true;
        // a.thirdArena.open = true;
        // a.magicArena.open = true;
    }

    function _getPlayerAddress(uint256 _id) internal view returns (address player) {
        PlayerStorage storage s = diamondStoragePlayer();
        player = s.owners[_id];
    }
}

contract ArenaFacet {
    event MainWin(uint256 indexed _playerId);
    event SecondWin(uint256 indexed _playerId);
    event MagicWin(uint256 indexed _playerId);
    event MainLoss(uint256 indexed _playerId);
    event SecondLoss(uint256 indexed _playerId);
    event MagicLoss(uint256 indexed _playerId);

    event EnterMain(uint256 indexed _playerId);
    event EnterSecond(uint256 indexed _playerId);
    event EnterMagic(uint256 indexed _playerId);

    function openArenas() public {
        StorageLib._openArenas();
    }

    function getMainArena() external view returns (bool, uint256) {
        return StorageLib._getMainArena();
    }

    function getSecondArena() external view returns (bool, uint256) {
        return StorageLib._getSecondArena();
    }
    // function getThirdArena() external view returns(bool) {
    //     return StorageLib._getMainArena();
    // }

    function getMagicArena() external view returns (bool, uint256) {
        return StorageLib._getMagicArena();
    }

    function enterMainArena(uint256 _playerId) public {
        StorageLib._enterMainArena(_playerId);
        emit EnterMain(_playerId);
    }

    function fightMainArena(uint256 _challengerId) public {
        uint256 _winner;
        uint256 _loser;
        (_winner, _loser) = StorageLib._fightMainArena(_challengerId);
        emit MainWin(_winner);
        emit MainLoss(_loser);
    }

    function enterSecondArena(uint256 _playerId) public {
        StorageLib._enterSecondArena(_playerId);
        emit EnterSecond(_playerId);
    }

    function fightSecondArena(uint256 _challengerId) public {
        uint256 _winner;
        uint256 _loser;
        (_winner, _loser) = StorageLib._fightSecondArena(_challengerId);
        emit SecondWin(_winner);
        emit SecondLoss(_loser);
    }

    function enterMagicArena(uint256 _playerId) public {
        StorageLib._enterMagicArena(_playerId);
        emit EnterMagic(_playerId);
    }

    function fightMagicArena(uint256 _challengerId) public {
        uint256 _winner;
        uint256 _loser;
        (_winner, _loser) = StorageLib._fightMagicArena(_challengerId);
        emit MagicWin(_winner);
        emit MagicLoss(_loser);
    }

    function leaveMainArena(uint256 _playerId) public {
        StorageLib._leaveMainArena(_playerId);
    }

    function getTotalWins(uint256 _playerId) public view returns (uint256) {
        return StorageLib._getTotalWins(_playerId);
    }

    function getMagicArenaWins(uint256 _playerId) public view returns (uint256) {
        return StorageLib._getMagicArenaWins(_playerId);
    }

    function getMainArenaWins(uint256 _playerId) public view returns (uint256) {
        return StorageLib._getMainArenaWins(_playerId);
    }

    function getTotalLosses(uint256 _playerId) public view returns (uint256) {
        return StorageLib._getTotalLosses(_playerId);
    }

    function getMagicArenaLosses(uint256 _playerId) public view returns (uint256) {
        return StorageLib._getMagicArenaLosses(_playerId);
    }

    function getMainArenaLosses(uint256 _playerId) public view returns (uint256) {
        return StorageLib._getMainArenaLosses(_playerId);
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