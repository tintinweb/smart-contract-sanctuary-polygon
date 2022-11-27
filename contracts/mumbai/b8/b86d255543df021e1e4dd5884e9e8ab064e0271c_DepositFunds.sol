/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract DepositFunds {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public{
        uint bal = balances[msg.sender];
        require(bal > 0);
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send MATIC");
        balances[msg.sender] = 0;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

}