/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract EtherSenderUpgrade {

    address payable owner;

    constructor() payable {   
        owner = payable(msg.sender);
    }   

    modifier onlyOwner {
    require(owner == msg.sender, "Only the Owner can do that mate");
    _;   // <--- note the '_', which represents the modified function's body
    }
    
    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function send() external payable returns(uint256) {
        uint256 amount = msg.value;
        require(amount >= 0.02 ether,"You must send 0.02 ether at least");
        return msg.value;
    }

    function withdraw001Eth() external {
        require (getBalance() > 0,"No funds in the SC my darling");
        address payable to = payable(msg.sender);
        uint256 amount = 0.01 ether;
        require(amount <= getBalance(),"You need more ETH Baby"); 
        to.transfer(amount); 
    }

    function withdrawHalfBalance() external {
        require (getBalance() > 0,"No funds in the SC my darling");
        address payable to = payable(msg.sender);
        uint amount = getBalance()/2;
        to.transfer(amount);
    }

    function cleanTheHouse()  external onlyOwner {
        address payable to = payable(msg.sender);
        uint256 amount = getBalance();
        to.transfer(amount); 
    }



}