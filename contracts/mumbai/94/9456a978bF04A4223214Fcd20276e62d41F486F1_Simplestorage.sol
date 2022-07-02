// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Simplestorage {
    uint256 public favouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint) public nameToFavouriteNumber;

    function retrive() public view returns(uint) {
        return favouriteNumber;
    }

    function store(uint _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function addPeople(string memory _name,uint _favouriteNumber) public {
        people.push(People(_favouriteNumber,_name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}