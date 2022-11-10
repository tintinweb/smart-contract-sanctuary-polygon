//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//to store favourite number
//to store fav number of individuals in data structure
contract SimpleStorage {
    uint favNum;
    uint id;
    struct Person {
        string name;
        uint favNum;
        uint age;
    }

    // Person[]public person;
    // mapping(string=>uint) public nameToFavNum;
    mapping(uint => Person) public idToPersonDetails;

    function store(uint _favNum) public {
        favNum = _favNum;
    }

    function retrieve() public view returns (uint) {
        return favNum;
    }

    function addPerson(
        string memory _name,
        uint _favNum,
        uint _age
    ) public {
        //    Person memory newPerson=Person(_name,_favNum,_age);
        //    person.push(newPerson);
        //    nameToFavNum[_name]=_favNum;
        idToPersonDetails[id] = Person(_name, _favNum, _age);
        id++;
    }
}