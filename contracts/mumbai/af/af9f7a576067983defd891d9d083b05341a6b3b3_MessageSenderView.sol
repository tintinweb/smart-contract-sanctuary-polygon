/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MessageSenderView {
    mapping(address => uint256) balances;

    function whoAmI() public view returns (address) {
        return msg.sender;
    }

    function setMyBalance(uint256 balance) public {
        balances[msg.sender] = balance;
    }

    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}