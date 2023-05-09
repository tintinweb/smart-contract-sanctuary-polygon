/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Damn {
    uint updates;
    constructor(uint startValue){
        updates = startValue;
        update(); 
    }

    function update() public{
        updates++;
    }

    function updatesAmount() external view returns(uint){
        return updates;
    }
}