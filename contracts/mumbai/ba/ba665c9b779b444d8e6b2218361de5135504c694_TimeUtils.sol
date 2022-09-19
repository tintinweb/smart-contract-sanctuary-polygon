/**
 *Submitted for verification at polygonscan.com on 2022-09-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.12.0;

library TimeUtils{

    function getTimestamp() public view returns(uint256){
        return block.timestamp;
    }
}