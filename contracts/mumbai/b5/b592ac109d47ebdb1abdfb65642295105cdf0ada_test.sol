/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract test {

    event TestEvent(address indexed user, uint amount );

    function check() public {
        for(uint i = 0; i < 10 ; i++) {
            emit TestEvent(msg.sender, i);
        }
    }
}