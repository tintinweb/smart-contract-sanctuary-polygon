/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Bank {
    mapping(address => uint256) public balanceOf;

    // Deploying more capital, steady lads
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(balanceOf[msg.sender] > 0, "Insufficient funds");
        (bool success,) = payable(msg.sender).call{value: balanceOf[msg.sender]}("");
        require(success, "Transfer failed");
        balanceOf[msg.sender] = 0;
    }
}