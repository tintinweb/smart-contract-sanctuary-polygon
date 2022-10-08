/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


contract simpleContract {

    struct Person {
        string name;
        uint256 pin;
    }

    Person[] public people;
    uint256 public totalPeople = 0;
    mapping (string => uint256) public nameToID;

    function addPerson (Person memory p) private {
        people.push (p);
        nameToID[p.name]=totalPeople;
        totalPeople++;
    }

    function newPerson (string memory _name, uint256 _num) private pure returns  (Person memory){

        return Person({name:_name , pin:_num});

    }

    function addPerson (string memory _name, uint256 _num) public {
        addPerson (newPerson(_name,_num));
    }
}