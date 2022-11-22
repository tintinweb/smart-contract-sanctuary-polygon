//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoritenumber;
    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;
    struct People {
        uint256 favoritenumber;
        string name;
    }

    function retrieve() public view returns (uint256) {
        return favoritenumber;
    }

    function addperson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoritenumber = _favoriteNumber;
    }
}