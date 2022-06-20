// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract User {

    uint256 number;
    mapping (address => string) public firstnames;
    mapping (address => string) public lastnames;

    function store(uint256 num) public {
        number = num;
    }

    function saveFirstName(string memory firstName) public {
        firstnames[msg.sender] = firstName;
    }

    function saveLastName(string memory lastName) public {
        lastnames[msg.sender] = lastName;
    }

    function getFirstName() public view returns (string memory){
        return firstnames[msg.sender];
    }

    function getLastName() public view returns (string memory){
        return lastnames[msg.sender];
    }
}