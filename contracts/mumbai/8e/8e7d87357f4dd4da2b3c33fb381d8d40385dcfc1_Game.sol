/**
 *Submitted for verification at polygonscan.com on 2022-11-21
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
        // add pray() function; // TODO
    }

    struct Spawn {
        int health;
        int strength;
        int agility;
        int wisdom;
    }

    struct Round {
        uint roundNo;
        uint totalAttacks;
        uint firstAttackIndex;
        uint lastAttackIndex;
        bool result;
        uint coinsWon;
    }

    // Record all attacks of every battle
    struct Attack {
        uint roundIndex;
        uint attackIndex;
        int heroHealth;
        int heroDamageDealt;
        int spawnHealth;
        int spawnDamageDealt;
    }

    Hero[] players;
    Spawn[] spawns;
    Round[] rounds;
    Attack[] attacks;

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

    int[] randomizerArray = [
        1,2,3,4,5,6,7,8,9,10,
        11,12,13,14,15,16,17,18,19,20,
        21,22,23,24,25,26,27,28,29,30,
        31,32,33,34,35,36,37,38,39,40,
        41,42,43,44,45,46,47,48,49,50,
        51,52,53,54,55,56,57,58,59,60,
        61,62,63,64,65,66,67,68,69,70,
        71,72,73,74,75,76,77,78,79,80,
        81,82,83,84,85,86,87,88,89,90,
        91,92,93,94,95,96,97,98,99,100
    ];

    function addHero(string memory _name, int _health, int _strength, int _agility, int _wisdom) private {
        Hero memory newHero = Hero(_name, _health, _strength, _agility, _wisdom);
        players.push(newHero);
    }

    function addSpawn(int _health, int _strength, int _agility, int _wisdom) private {
        Spawn memory newSpawn = Spawn(_health, _strength, _agility, _wisdom);
        spawns.push(newSpawn);
    }

    function addRound(uint _roundNo, uint _totalAttacks, uint _firstAttackIndex, uint _lastAttackIndex, bool _result, uint _score) private {
        Round memory newRound = Round(_roundNo, _totalAttacks, _firstAttackIndex, _lastAttackIndex, _result, _score);
        rounds.push(newRound);
    }

    function addAttack(uint _roundIndex, uint _attackIndex, int _heroHealth, int _heroDamageDealt, int _spawnHealth, int _spawnDamageDealt) private {
        Attack memory newAttack = Attack(_roundIndex, _attackIndex, _heroHealth, _heroDamageDealt, _spawnHealth, _spawnDamageDealt);
        attacks.push(newAttack);
    }

    // Generate pseudo-random nos for attributes
    // Inspired by Loot contract - MIT license
    // https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code
    function getStrength(uint256 _index, string memory _name) internal view returns (int) {
        return pluck(_index, "STRENGTH", attributesArray, _name);
    }
    
    function getAgility(uint256 _index, string memory _name) internal view returns (int) {
        return pluck(_index, "AGILITY", attributesArray, _name);
    }
    
    function getWisdom(uint256 _index, string memory _name) internal view returns (int) {
        return pluck(_index, "WISDOM", attributesArray, _name);
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

    function pluck(uint256 _index, string memory keyPrefix, int[] memory sourceArray, string memory _name) internal pure returns (int) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(_index), _name)));
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

    function roundDetails(uint _index) public view returns (uint, uint, uint, uint, bool, uint) {
        Round memory roundToReturn = rounds[_index];
        return (roundToReturn.roundNo, roundToReturn.totalAttacks, roundToReturn.firstAttackIndex, roundToReturn.lastAttackIndex, roundToReturn.result, roundToReturn.coinsWon);
    }

    function attackDetails(uint _index) public view returns (uint, uint, int, int, int, int) {
        Attack memory attackToReturn = attacks[_index];
        return (attackToReturn.roundIndex, attackToReturn.attackIndex, attackToReturn.heroHealth, attackToReturn.heroDamageDealt, attackToReturn.spawnHealth, attackToReturn.spawnDamageDealt);
    }

    function lastGameIndex() public view returns (uint) {
        return rounds.length-1;
    }

    function mapPlayer(string memory _name, int _strength, int _agility, int _wisdom) internal returns (uint) {
        addHero(_name, 100, _strength, _agility, _wisdom);
        return players.length-1; // return index of newly mapped player
    }
    
    function battle(string memory _name, int _strength, int _agility, int _wisdom) public returns (uint) {
        // initialize player
        mapPlayer(_name, _strength, _agility, _wisdom);
        uint256 currentIndex = players.length-1;

        // initialize spawn
        addSpawn(100, getStrength(currentIndex, _name), getAgility(currentIndex, _name), getWisdom(currentIndex, _name));

        // initialize variables used for entire battle (round)
        uint attackCounter = 0;
        uint startAttackIndex = 0 + attacks.length;

        // start battle
        while (players[currentIndex].health > 0 && spawns[currentIndex].health > 0){
        
            // initialize variables only used in 1 attack
            int heroDamageDealt = 0;
            int spawnDamageDealt = 0;

            // TODO: Add CRITICAL HIT
            // TODO: Add DODGE ATTACK

            // player attacks
            heroDamageDealt = 5 + players[currentIndex].strength - spawns[currentIndex].agility/2 + players[currentIndex].wisdom/spawns[currentIndex].wisdom;
            spawns[currentIndex].health -= heroDamageDealt;

            // spawn attacks
            spawnDamageDealt = 5 + spawns[currentIndex].strength - players[currentIndex].agility/2 + spawns[currentIndex].wisdom/players[currentIndex].wisdom;
            players[currentIndex].health -= spawnDamageDealt;
            
            // log attack
            addAttack(currentIndex, attackCounter, players[currentIndex].health, heroDamageDealt, spawns[currentIndex].health, spawnDamageDealt);

            // increment attack counter
            attackCounter++;
        }

        // check winner
        if (players[currentIndex].health <= 0 && spawns[currentIndex].health <= 0){
            addRound(currentIndex, attackCounter, startAttackIndex, attacks.length-1, false, 5);
        } else if (players[currentIndex].health > 0 && spawns[currentIndex].health <= 0){
            addRound(currentIndex, attackCounter, startAttackIndex, attacks.length-1, true, 20);
        } else if (players[currentIndex].health <= 0 && spawns[currentIndex].health > 0){
            addRound(currentIndex, attackCounter, startAttackIndex, attacks.length-1, false, 0);
        }

        // end game
        return rounds.length-1; // return index of this battle
    }
}