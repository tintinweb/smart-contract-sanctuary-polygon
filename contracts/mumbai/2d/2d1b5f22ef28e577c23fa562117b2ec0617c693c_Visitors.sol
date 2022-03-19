/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Visitors {
    uint256 public visitors;
    function visitorCame() external {
        visitors++;
    }
}