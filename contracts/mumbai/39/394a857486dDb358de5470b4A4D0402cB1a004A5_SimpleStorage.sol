//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct Person {
        uint256 favoriteNum;
        string name;
    }

    Person[] public listOfPeople;

    mapping(string => uint256) public personToNum;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    } 

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        Person memory newPerson = Person(_favoriteNumber, _name); 
        listOfPeople.push(newPerson);
        personToNum[_name] = _favoriteNumber;
    }
}