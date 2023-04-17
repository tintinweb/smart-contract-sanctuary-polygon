/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

contract MumbaiCollector {
    mapping(address => bool) public hasCollected;
    
    function collect() public {
        require(!hasCollected[msg.sender], "You have already collected ether from this contract.");
        payable(msg.sender).transfer(0.2 ether);
        hasCollected[msg.sender] = true;
    }
    function withdraw(uint256 amount) public {
        require(address(this).balance >= amount, "Insufficient contract balance.");
        payable(msg.sender).transfer(amount);
    }
    
    receive() external payable {}
    
    fallback() external payable {}
}