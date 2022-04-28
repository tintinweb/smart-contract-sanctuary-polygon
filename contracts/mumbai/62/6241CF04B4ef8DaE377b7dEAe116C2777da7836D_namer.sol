/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract namer {
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