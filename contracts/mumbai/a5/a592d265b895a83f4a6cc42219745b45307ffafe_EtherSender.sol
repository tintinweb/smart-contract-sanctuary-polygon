/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender {

    address owner;
   
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (owner == msg.sender, "You are not owner");
        _;
    }

    function send() external payable {
        uint amount = msg.value;
        require(amount >= 0.02 ether,"Error, Not enough money for send");
    }
    
    function withdrawEoaSender() external {
        address payable to = payable(msg.sender);
        uint256 amount = 0.01 ether;
        require(getBalance() > 0 ether,"Error, Not enough money for transfer");
        to.transfer(amount);
    }
    
    function withdrawEoaHalfBalance() external {
        address payable to = payable(msg.sender);
        uint256 amount = getBalance()/2;
        require(getBalance() > 0 ether,"Error, Not enough money for transfer");
        to.transfer(amount);
    }

    function withdrawOwner() external onlyOwner {
        uint256 amount = getBalance();
        address payable to = payable(owner);
        require(getBalance() > 0 ether,"Error, Not enough money for transfer");
        to.transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }
}