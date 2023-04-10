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
    bytes32 constant TRAIN_STORAGE_POSITION = keccak256("train.test.storage.a");

    struct PlayerStorage {
        uint256 totalSupply;
        uint256 playerCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => Player) players;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(string => bool) usedNames;
        mapping(address => uint256[]) addressToPlayers;
    }

    struct TrainStorage {
        mapping(uint256 => uint256) combat;
        mapping(uint256 => uint256) magic;
        mapping(uint256 => uint256) meditation;
        mapping(uint256 => uint256) education;
        mapping(uint256 => uint256) cooldown;
    }

    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function diamondStorageTrain() internal pure returns (TrainStorage storage ds) {
        bytes32 position = TRAIN_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _startTrainingCombat(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.players[_tokenId].status == 0); //is idle
        require(s.owners[_tokenId] == msg.sender); // ownerOf

        s.players[_tokenId].status = 1;
        t.combat[_tokenId] = block.timestamp;
        delete t.cooldown[_tokenId];
    }

    function _endTrainingCombat(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.owners[_tokenId] == msg.sender);
        require(s.players[_tokenId].status == 1);
        require(
            block.timestamp >= t.combat[_tokenId] + 120,
            "it's too early to pull out"
        );
        s.players[_tokenId].status = 0;
        delete t.combat[_tokenId]; 
        s.players[_tokenId].strength++; 
    }

    function _startTrainingMagic(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.players[_tokenId].status == 0); //is idle
        require(s.owners[_tokenId] == msg.sender); // ownerOf
        require(block.timestamp >= t.cooldown[_tokenId] + 1); //check time requirement

        s.players[_tokenId].status = 1;
        t.magic[_tokenId] = block.timestamp;
        delete t.cooldown[_tokenId];
    }

    function _endTrainingMagic(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.owners[_tokenId] == msg.sender);
        require(s.players[_tokenId].status == 1); //require that they are training
        require(
            block.timestamp >= t.magic[_tokenId] + 1,
            "it's too early to pull out"
        );
        s.players[_tokenId].status = 0;
        delete t.magic[_tokenId]; 
        s.players[_tokenId].mana++; 
        t.cooldown[_tokenId] = block.timestamp; //reset the cool down
    }


    function _startMeditation(uint256 _tokenId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        TrainStorage storage t = diamondStorageTrain();
        require(s.players[_tokenId].status == 0); //is idle
        require(s.owners[_tokenId] == msg.sender); // ownerOf

        s.players[_tokenId].status = 1;
        t.combat[_tokenId] = block.timestamp;
        delete t.cooldown[_tokenId];
    }


}


contract TrainFacet {

    event BeginTraining(address indexed _playerAddress, uint256 _id);
    event EndTraining(address indexed _playerAddress, uint256 _id);

    function startTrainingCombat(uint256 _tokenId) external {
        StorageLib._startTrainingCombat(_tokenId);
        emit BeginTraining(msg.sender, _tokenId);
    }

    function endTrainingCombat(uint256 _tokenId) external {
        StorageLib._endTrainingCombat(_tokenId);
        emit EndTraining(msg.sender, _tokenId);
    }
    function startTrainingMagic(uint256 _tokenId) external {
        StorageLib._startTrainingMagic(_tokenId);
        emit BeginTraining(msg.sender, _tokenId);
    }

    function endTrainingMagic(uint256 _tokenId) external {
        StorageLib._endTrainingMagic(_tokenId);
        emit EndTraining(msg.sender, _tokenId);
    }

    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}