/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


contract Demomen {
    function getEthBalance(address addr, uint256 bolck) public view returns (uint256 balance) {
        balance = addr.balance + bolck;
        return balance;
    }
}