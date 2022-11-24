/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint public favoriteNumber;

    struct People {
        string name;
        uint age;
    }

    People[] public peoples;

    mapping(string => uint) public addressBook;

    // virtual fonksiyonlar override edilebilrler.
    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        favoriteNumber++;
    }

    function addPeople(string memory _name, uint _age) public {
        People memory people = People({name: _name, age: _age});
        peoples.push(people);

        addressBook[_name] = _age;
    }
}