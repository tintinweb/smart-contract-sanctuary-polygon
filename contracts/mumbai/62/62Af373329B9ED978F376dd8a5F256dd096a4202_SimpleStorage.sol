/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleStorage {
   struct People {
    uint256 favoriteNumber;
    string name;
   } 

uint256 public favoriteNumber;
   People[] public peoples;

    mapping(string => uint256) public nameTOFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    } 

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        peoples.push(People(_favoriteNumber, _name));
        nameTOFavoriteNumber[_name] = _favoriteNumber;
    }

}