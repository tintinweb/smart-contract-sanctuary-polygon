/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Demo {
    string public name;

    function setData(string memory _name) external {
        name = _name;
    }
}