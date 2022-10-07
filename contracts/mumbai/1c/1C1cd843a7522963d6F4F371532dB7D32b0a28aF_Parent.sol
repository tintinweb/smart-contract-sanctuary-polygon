/**
 *Submitted for verification at polygonscan.com on 2022-10-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Child {
    string public name;
    string public gender;

    constructor(string memory _name, string memory _gender) {
        name = _name;
        gender = _gender;
    }

    function get() public view returns (string memory, string memory) {
        return (name, gender);
    }
}

contract Parent {

    Child public childContract; 

    function createChild(string memory _name, string memory _gender) public returns(Child) {
       childContract = new Child(_name, _gender); // creating new contract inside another parent contract
       return childContract;
    }
}