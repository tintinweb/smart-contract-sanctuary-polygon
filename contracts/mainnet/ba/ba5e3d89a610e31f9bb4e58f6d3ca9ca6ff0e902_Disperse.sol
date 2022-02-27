/**
 *Submitted for verification at polygonscan.com on 2022-02-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Disperse {
    function disperseEther(address payable[] memory recipients, uint256 value) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(value);
    }
}