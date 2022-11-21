/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {

    int score;

    struct Person { // only to define the structure; not to define any values to elements;
        string name;
        uint health;
        uint strength;
        uint agility;
        uint wisdom;
    }

    Person[] people;

    function addPerson(string memory _name, uint _health, uint _strength, uint _agility, uint _wisdom) public {
        Person memory newPerson = Person(_name, _health, _strength, _agility, _wisdom); // Create an `instance` of `Person`
        people.push(newPerson);
    } 

    function getPerson(uint _index) public view returns (string memory, uint, uint, uint, uint) {
        Person memory personToReturn = people[_index];
        return (personToReturn.name, personToReturn.health, personToReturn.strength, personToReturn.agility, personToReturn.wisdom);
    }
    
    // function hello() public pure returns(string memory) {
    //     string memory message = "Hello World!"; 
    //     return message;
    // }

    function battle() public returns (string memory) {
        // Person[] memory people; // Create `Person[]` type for variable `people`

        addPerson("Hero", 100, 10, 9, 8);
        addPerson("Enemy", 100, 7, 6, 5);

        if (people[0].health > 0 && people[1].health > 0){

            people[0].health -= 7;
            people[1].health -= 10;

        }
        score++;
        string memory message = "Game ended!";

        people[0].health = 100;
        people[1].health = 100;

        return message;
    }

    function getScore() public view returns(int){
        return score;
    }

}