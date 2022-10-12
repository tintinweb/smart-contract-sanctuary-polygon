/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract etherSender {

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Wallet error");
        _;
    }

    function withdrawAmount() external {
        uint256 amount = getBalance();
        require(amount >= 0.01 ether, "Not suficient balance");
        address payable to = payable(msg.sender);
        to.transfer(0.01 ether);
    }
    
    function withdrawHalf() external {
        uint256 halfBalance = getBalance()/2;
        require(halfBalance > 0 ether, "Not suficient balance");
        address payable to = payable(msg.sender);
        to.transfer(halfBalance);
    }

    function withdrawOwner() external onlyOwner {
        uint256 totalBalance = getBalance();
        require(totalBalance > 0, "Not suficient balance");
        owner.transfer(totalBalance);
    }
    
    function reciveEther() external payable {
        uint256 amount = msg.value;
        require(amount >= 0.02 ether,"Enought money");
    }
    
    function getBalance() public view returns(uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

}