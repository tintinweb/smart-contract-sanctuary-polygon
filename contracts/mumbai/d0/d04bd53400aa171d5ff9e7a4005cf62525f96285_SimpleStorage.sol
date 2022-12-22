/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
contract SimpleStorage {
    string public name;
    uint public age;

    constructor() {}

    function set(string memory _name, uint _age ) public {
        name = _name;
        age = _age;
    }
    function get() public view returns (string memory, uint) {
        return (name, age);
    }
}