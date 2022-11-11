/**
 *Submitted for verification at polygonscan.com on 2022-11-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSenderImproved {

    address payable owner;

    constructor () {
       owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"You do not have enougth rights");
        _;
    }
    modifier notFunds() {
           require(getBalance() > 0,"SC without funds");
        _;
    }

    function sendMoney() external payable {
        uint256 amount = msg.value;
        require(amount >= 0.02 ether,"The minimun amount must be 0.02 ether"); 
    }

    function withdrawAll()  external onlyOwner notFunds {
         owner.transfer(getBalance()); 
       }

    function withdrawFixedAmount() external {
        address payable to = payable(msg.sender);
        uint256 amount = 0.01 ether;
        require(amount <= getBalance(),"Not enough balance in SC to transfer"); 
        to.transfer(amount); 
    }

     function withdrawHalfBalance() external notFunds {
        address payable to = payable(msg.sender);
        uint256 amount = getBalance()/2;
        to.transfer(amount); 
    }

    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

 }