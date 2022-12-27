/**
 *Submitted for verification at polygonscan.com on 2022-12-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract TEST{

    function timestamp() public view returns (uint256){
        return block.timestamp;
    }
}