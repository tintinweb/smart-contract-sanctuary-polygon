/**
 *Submitted for verification at polygonscan.com on 2022-04-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Sum {

    uint256 number;

    function store() external{
        number = block.timestamp;
    }
    function retrieve() public view returns(uint){
        return number;
    }
    
}