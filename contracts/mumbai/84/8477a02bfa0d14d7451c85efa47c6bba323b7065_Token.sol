/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


contract Token  {

    event Event(uint256 indexed k1, uint256 indexed k2, uint256 indexed k3, uint256 indexed k4) anonymous;
    event Event2(uint256 indexed k1, uint256 indexed k2, uint256 indexed k3) anonymous;

    function set() external {
        emit Event(1,2,3,4);
        emit Event2(2,3,4);
    }
}