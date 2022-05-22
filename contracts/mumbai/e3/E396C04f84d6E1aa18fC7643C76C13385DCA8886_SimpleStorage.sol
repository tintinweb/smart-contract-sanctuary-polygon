/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract SimpleStorage {
    //this will get initialized to 0 if we dont initialize the Default
    //we are saving variables on chain
    uint256 favoriteNumber;
    bool favoriteBool;

    //struct is basically a new object depends on what we want to create
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // 1-type[]  2- permissions  3- name of the array
    //its helpful to remember this sorting solidity
    People[] public people;

    //Mapping is to iterate through an array
    // 1-type()  2- permissions  3- name of the mapping (result will be saved in)

    mapping(string => uint256) public nameToFavoriteNumber;

    //string is technically a special array  ,we use "memory" keyword to have access only through the function exection

    //we need it only in execution time and its not available later ,we can use "storage" for be able to
    //using it even after exection
    function addperson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    //we create person object from people which is public and everyone can see who interact with blokchcain
    //People public person = People({favoriteNumber: 2,name : "Sako"});

    //we are changing a state on blockhcain in store that why you see it as orange
    function store(uint256 _favoriteNumber) public returns (uint256) {
        favoriteNumber = _favoriteNumber;
        return _favoriteNumber;
    }

    //view & pure are blue because this retrieve function is reading from blockchain and not changing a state in blockhcain
    //basically view return a state of blockchain!!
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //pure is doing some type of math
    function profit() public pure returns (uint256 sum) {
        sum = 1 + 3;
    }
}