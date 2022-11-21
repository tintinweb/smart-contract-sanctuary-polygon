/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {

    // uint score;

    struct Hero { // only to define the structure; not to define any values to elements;
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
    Round [] rounds;

    function addHero(string memory _name, int _health, int _strength, int _agility, int _wisdom) private {
        Hero memory newHero = Hero(_name, _health, _strength, _agility, _wisdom); // Create an `instance` of `Hero`
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

    // TODO: generate pseudo-random nos for attributes

    // function getStrength(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "STRENGTH", strength);
    // }
    
    // function getAgility(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "AGILITY", agility);
    // }
    
    // function getWisdom(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "WISDOM", wisdom);
    // }

    // function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
    //     uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
    //     string memory output = sourceArray[rand % sourceArray.length];
    //     return output;
    // }

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

    // function getScore() public view returns(uint){
    //     return score;
    // }

    function mapPlayer(string memory _name, int _str, int _agi, int _wis) public returns (uint) {
        addHero(_name, 100, _str, _agi, _wis);
        return players.length-1; // return index of newly mapped player
    }

    function mapSpawn(int _str, int _agi, int _wis) public returns (uint) {
        addSpawn(100, _str, _agi, _wis);
        return spawns.length-1; // return index of newly mapped spawn
    }
    
    function battle(uint _index) public {
        // players[_index].health;
        // players[_index].strength;
        // players[_index].agility;
        // players[_index].wisdom;

        // spawns[_index].health;
        // spawns[_index].strength;
        // spawns[_index].agility;
        // spawns[_index].wisdom;

        // addRound(_index, false);
        // rounds[_index].roundNo;

        // start game
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