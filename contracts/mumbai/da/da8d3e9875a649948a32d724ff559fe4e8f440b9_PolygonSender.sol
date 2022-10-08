/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract PolygonSender {
    address payable public owner;
    
    constructor () {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Knock, knock, who's there? Not the owner :) ");
        _;
    }

    function send() external payable {
        require(msg.value >= 0.02 ether, "Send me more");
    }

    function withdrawEOA() external {
        address payable to = payable(msg.sender);
        uint amount = getBalance();
        
        require(amount >= 0.01 ether, "Insufficient balance");
        to.transfer(0.01 ether);    
    }   

    function withdrawHalf() external {
        address payable to = payable(msg.sender);
        uint halfBalance = getBalance()/2;
        
        require(halfBalance > 0, "Insufficient balance");
        to.transfer(halfBalance);    
    }

    function withdrawAll() external onlyOwner {
        uint amount = getBalance();
        
        require(amount > 0, "Empty SC");
        owner.transfer(amount);    
    }

    function getBalance() public view returns(uint256){
        uint256 balance = address(this).balance;
        return balance;
    }

}