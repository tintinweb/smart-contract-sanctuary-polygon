/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract test {

    string name = "choi";

    function getName() public view returns(string memory) {
        return name;
    }

    function setName(string memory _name) public {
        name = _name;
    }

}