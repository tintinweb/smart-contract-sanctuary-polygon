/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Events 
{
    event transfer(address , address , uint);

    function test () public 
    {
        emit transfer (msg.sender , msg.sender , 5);
    }
}