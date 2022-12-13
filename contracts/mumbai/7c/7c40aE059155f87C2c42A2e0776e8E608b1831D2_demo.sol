/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 < 0.9.0;

contract demo {
    event abcd(string indexed name, uint timestamp);
    function input(string memory name) public {
        emit abcd(name,block.timestamp);
    }
}