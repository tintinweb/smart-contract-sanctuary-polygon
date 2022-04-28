/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract namer2 {
    string name;

    function setname(string memory _name) public {
        name = _name;
    }

    function indicate() public view returns (string memory) {
        return name;
    }

    function reyhanehAge() public pure returns(uint8) {
        return 25;
    }
}