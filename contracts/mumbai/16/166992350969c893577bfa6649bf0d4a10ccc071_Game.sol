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

    // struct Attacks {
    //     uint attackNo;
    //     uint 
    // }

    // uint attackCounter = 0;
    // // attackCounter++ in the attacks

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

    function addRound(uint _roundNo, bool _result, uint _score) private {
        Round memory newRound = Round(_roundNo, _result, _score);
        rounds.push(newRound);
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

    function roundDetails(uint _index) public view returns (uint, bool, uint) {
        Round memory roundToReturn = rounds[_index];
        return (roundToReturn.roundNo, roundToReturn.result, roundToReturn.coinsWon);
    }

    function mapPlayer(string memory _name, int _strength, int _agility, int _wisdom) internal returns (uint) {
        addHero(_name, 100, _strength, _agility, _wisdom);
        return players.length-1; // return index of newly mapped player
    }
    
    function battle(string memory _name, int _strength, int _agility, int _wisdom) public {
        // initialize player
        mapPlayer(_name, _strength, _agility, _wisdom);
        uint currentIndex = players.length-1;

        // initialize spawn
        addSpawn(100, getStrength(currentIndex, _name), getAgility(currentIndex, _name), getWisdom(currentIndex, _name));

        // variables
        string memory dodgeString = "DODGED! Lorem, ipsum dolor sit amet consectetur adipisicing elit. Fugiat voluptate autem minima magnam quisquam neque adipisci, doloribus dolores modi porro quam tenetur in reiciendis corrupti ea iure laudantium expedita nesciunt eaque nemo! Animi adipisci, veniam voluptatibus cum natus enim perferendis accusantium expedita dolores laborum perspiciatis blanditiis rerum et quasi quo reiciendis recusandae esse est excepturi aliquid! Iste quos vero aperiam velit explicabo tempore laudantium eaque voluptatibus ab dolorum amet laborum fugiat repellat nulla qui veritatis assumenda, delectus libero consectetur aliquam, inventore deserunt repudiandae. Unde id eius hic aspernatur, quasi nemo qui nam quis. Accusamus, pariatur? Nihil ad laudantium consectetur alias!";
        string memory criticalHitString = "CRITICAL HIT! Lorem, ipsum dolor sit amet consectetur adipisicing elit. Est possimus aspernatur quidem quae ipsam tempora dolor ex quam, porro similique alias reprehenderit, id vero, facilis quisquam! Eum adipisci animi culpa id eos! Eaque velit, labore tempora quasi ex voluptate sapiente fugit, saepe, aut doloremque ipsum aliquam eveniet unde quidem? Aspernatur adipisci temporibus, fuga nesciunt nam quod neque dolores vitae amet id suscipit similique quis. Repudiandae consectetur, unde repellat odio reprehenderit voluptates at atque, rem quasi perspiciatis illo. Vero consequuntur eius assumenda expedita, culpa reiciendis exercitationem praesentium nihil dolores. Minima consequuntur quam, odio sint sapiente non exercitationem! Beatae quaerat dolores incidunt!";

        // start battle
        while (players[currentIndex].health > 0 && spawns[currentIndex].health > 0){
            // player attacks
            // 2%-25% chance for spawn to dodge
            if (4*pluck(currentIndex, "DODGE", randomizerArray, dodgeString) <= 10*spawns[currentIndex].agility){
                // dodge
            } else {
            // 2%-25% chance for player to deal critical damage
                if (4*pluck(currentIndex, "CRITICALHIT", randomizerArray, criticalHitString) <= 10*players[currentIndex].wisdom){
                    // attack w critical hit
                    spawns[currentIndex].health -= 5 + players[currentIndex].strength - spawns[currentIndex].agility/2 + 5 + getStrength(currentIndex, _name);
                } else {
                    // attack w/o critical hit
                    spawns[currentIndex].health -= 5 + players[currentIndex].strength - spawns[currentIndex].agility/2;
                }
            }
            // spawn attacks
            // 2%-25% chance for player to dodge
            if (4*pluck(currentIndex, "DODGE", randomizerArray, dodgeString) <= 10*players[currentIndex].agility){
                // dodge
            } else {
            // 2%-25% chance for spawn to deal critical damage
                if (4*pluck(currentIndex, "CRITICALHIT", randomizerArray, criticalHitString) <= 10*spawns[currentIndex].wisdom){
                    // attack w critical hit
                    players[currentIndex].health -= 5 + spawns[currentIndex].strength - players[currentIndex].agility/2 + 5 + getStrength(currentIndex, _name);
                } else {
                    // attack w/o critical hit
                    players[currentIndex].health -= 5 + spawns[currentIndex].strength - players[currentIndex].agility/2;
                }
            }
        }

        // check winner
        if (players[currentIndex].health <= 0 && spawns[currentIndex].health <= 0){
            addRound(currentIndex, false, 5);
        } else if (players[currentIndex].health > 0 && spawns[currentIndex].health <= 0){
            addRound(currentIndex, true, 20);
        } else if (players[currentIndex].health <= 0 && spawns[currentIndex].health > 0){
            addRound(currentIndex, false, 0);
        }
    }
}