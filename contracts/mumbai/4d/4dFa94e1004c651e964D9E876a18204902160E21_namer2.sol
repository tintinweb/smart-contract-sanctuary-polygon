/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract namer2 {
    string info;

    function setname(string memory _name) public {
        info = _name;
    }

    function getInfo() public view returns (string memory) {
        return info;
    }

    function reyhanehAge() public pure returns(uint8) {
        return 25;
    }
}