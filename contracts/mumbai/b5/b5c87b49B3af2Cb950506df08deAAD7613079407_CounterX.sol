/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
contract CounterX {
    uint public counting = 0;
    
    function increment() public returns(uint) {
        counting += 1;
        return counting;
    }
}