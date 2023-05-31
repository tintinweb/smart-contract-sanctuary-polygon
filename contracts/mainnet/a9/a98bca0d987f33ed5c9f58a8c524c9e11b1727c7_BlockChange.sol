/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
contract BlockChange {

    event WorldBits(bytes data);

    function editWorld(bytes memory data) public {
        emit WorldBits(data);
    }
}