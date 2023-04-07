/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Wallet {
    address public owner;
    address public recipient;

    constructor(address _recipient) {
        owner = msg.sender;
        recipient = _recipient;
    }

    function withdraw(uint256 _amount) public {
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(address(this).balance >= _amount, "Insufficient contract balance");

        payable(msg.sender).transfer(_amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {
        if (msg.sender != owner) {
            payable(recipient).transfer(msg.value);
        }
    }
}