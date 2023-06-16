/**
 *Submitted for verification at polygonscan.com on 2023-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Register {
    string private info;

    function getInfo() public view returns (string memory) {
        return info;
    }

    function setInfo(string memory _info) public {
        info = _info;
    }
}