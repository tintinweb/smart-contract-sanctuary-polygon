/**
 *Submitted for verification at polygonscan.com on 2022-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage{
    // boolean, uint, int, address, bytes
    uint256 public theFavouriteNumber;
    struct Person{
        string name;
        uint256 favouriteNumber;
    }

    Person[] public people;

    mapping(string => uint256) public nameToFavNumber;
    function store(uint256 _favouriteNumber) public{
        theFavouriteNumber = _favouriteNumber;
        theFavouriteNumber += 1;
    }

    function retrieve() public view returns(uint256){
        return theFavouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favNumber) public{
        Person memory newPerson = Person({name: _name, favouriteNumber: _favNumber});
        people.push(newPerson);
        nameToFavNumber[_name] = _favNumber;
    }
}