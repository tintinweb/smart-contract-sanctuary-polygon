/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EthersBank {
    mapping(address => uint256) private balances;

    function deposit() public payable {
        require(msg.value > 0, "Invalid deposit amount");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = amount + msg.value;
    }

    function withdraw(uint256 amount, address payable to) public returns (bool) {
        uint256 ethAmount = amount * 10 ** 18;
        require(ethAmount <= balances[to], "Insufficient balance");
        return to.send(ethAmount);
    }
}