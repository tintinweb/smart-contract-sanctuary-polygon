/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Crowdfunding {
    address payable public controller;
    uint256 public totalDeposits;
    mapping(address => uint256) public contributions;
    
    constructor() {
        controller = payable(msg.sender);
    }
    
    function deposit() public payable {
        totalDeposits += msg.value;
        contributions[msg.sender] += msg.value;
    }
    
    function withdraw() public {
        require(msg.sender == controller, "Only the controller can withdraw funds");
        uint256 balance = address(this).balance;
        controller.transfer(balance);
    }
    
    function getTotalDeposits() public view returns (uint256) {
        return totalDeposits;
    }
    
    function getController() public view returns (address) {
        return controller;
    }
    
    function getContribution(address contributor) public view returns (uint256) {
        return contributions[contributor];
    }
}