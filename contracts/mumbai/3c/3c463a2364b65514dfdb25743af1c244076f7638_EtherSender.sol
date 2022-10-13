/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract EtherSender {

    address owner = 0x3d91aE34907b282034283D4b28A3724deC3B3b48;

    modifier onlyOwner {
    require(owner == msg.sender, "Only the Owner can do that mate");
    _;   // <--- note the '_', which represents the modified function's body
    }
    
    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function send() external payable returns(uint256) {
            return msg.value;
    }

    function withdraw001Eth() external {
        address payable to = payable(msg.sender);
        uint256 amount = 0.01 ether;
        require(amount <= getBalance(),"You need more ETH Baby"); 
        to.transfer(amount); 
    }

    function withdrawHalfBalance() external {
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