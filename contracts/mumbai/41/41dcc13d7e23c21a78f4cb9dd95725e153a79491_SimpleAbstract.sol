/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract SimpleAbstract {
    string public message = '';
    function setMessage(string memory _msg) public {
        message = _msg;
    }
}