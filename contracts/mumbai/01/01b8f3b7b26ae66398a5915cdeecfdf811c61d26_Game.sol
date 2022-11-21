/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {

    struct Hero {
        string name;
        int health;
        int strength;
        int agility;
        int wisdom;
    }

    struct Spawn {
        int health;
        int strength;
        int agility;
        int wisdom;
    }

    struct Round {
        uint roundNo;
        bool result;
        uint coinsWon;
    }

    Hero[] players;
    Spawn[] spawns;
    Round[] rounds;

    int[] attributesArray = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10
    ];

    function addHero(string memory _name, int _health, int _strength, int _agility, int _wisdom) private {
        Hero memory newHero = Hero(_name, _health, _strength, _agility, _wisdom);
        players.push(newHero);
    } 

    function addSpawn(int _health, int _strength, int _agility, int _wisdom) private {
        Spawn memory newSpawn = Spawn(_health, _strength, _agility, _wisdom);
        spawns.push(newSpawn);
    } 

    function addRound(uint _roundNo, bool _result, uint _score) private {
        Round memory newRound = Round(_roundNo, _result, _score);
        rounds.push(newRound);
    } 

    // Generate pseudo-random nos for attributes
    // Inspired by Loot contract - MIT license
    // https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code
    function getStrength(uint256 _index) public view returns (int) {
        return pluck(_index, "STRENGTH", attributesArray);
    }
    
    function getAgility(uint256 _index) public view returns (int) {
        return pluck(_index, "AGILITY", attributesArray);
    }
    
    function getWisdom(uint256 _index) public view returns (int) {
        return pluck(_index, "WISDOM", attributesArray);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function pluck(uint256 _index, string memory keyPrefix, int[] memory sourceArray) internal pure returns (int) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(_index))));
        int output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function getHero(uint _index) public view returns (string memory, int, int, int, int) {
        Hero memory heroToReturn = players[_index];
        return (heroToReturn.name, heroToReturn.health, heroToReturn.strength, heroToReturn.agility, heroToReturn.wisdom);
    }

    function getSpawn(uint _index) public view returns (int, int, int, int) {
        Spawn memory spawnToReturn = spawns[_index];
        return (spawnToReturn.health, spawnToReturn.strength, spawnToReturn.agility, spawnToReturn.wisdom);
    }

    function getRound(uint _index) public view returns (uint, bool, uint) {
        Round memory roundToReturn = rounds[_index];
        return (roundToReturn.roundNo, roundToReturn.result, roundToReturn.coinsWon);
    }

    function mapPlayer(string memory _name, int _str, int _agi, int _wis) public returns (uint) {
        addHero(_name, 100, _str, _agi, _wis);
        return players.length-1; // return index of newly mapped player
    }
    
    function battle(uint _index) public {

        addSpawn(100, getStrength(_index), getAgility(_index), getWisdom(_index));

        // start battle
        while (players[_index].health > 0 && spawns[_index].health > 0){
            players[_index].health -= spawns[_index].strength;
            spawns[_index].health -= players[_index].strength;
        }

        // // check winner
        // if (players[_index].health < 0 && spawns[_index].health < 0){
        //     addRound(_index, false, 0);
        // } else if (players[_index].health > 0 && spawns[_index].health <= 0){
        //     addRound(_index, true, 10);
        //     // score++;
        // } else if (players[_index].health <= 0 && spawns[_index].health > 0){
        //     addRound(_index, false, 10);
        // }

        addRound(_index, true, 10);
    }
}