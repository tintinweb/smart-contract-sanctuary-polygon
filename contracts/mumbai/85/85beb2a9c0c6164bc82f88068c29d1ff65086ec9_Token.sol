/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


contract Token  {

    event Val(uint256 indexed key, uint256 indexed value) anonymous;
    

    function set(uint256 k, uint256 v) external {
        emit Val(k,v);
    }
}