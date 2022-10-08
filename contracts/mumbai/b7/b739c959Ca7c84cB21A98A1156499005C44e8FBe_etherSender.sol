/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// third assignament Smart Contract
contract etherSender {

    address payable owner;

    constructor () {
       owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"You do not have enougth rights");
        _;
    }
    modifier notFunds() {
           require(getBalance() > 0,"without funds");
        _;
    }

    //funtion to sent ether amount into the Smart Contract (SM), minimun must be 0.02 ether.
    function sendMoney() external payable {
        uint256 amount = msg.value;
        require(amount >= 0.02 ether,"The minimun amount must be 0.02 ether"); 
    //    if (amount >= 0.02 ether) {
    //        return;
    //    } else {
    //        revert("The minimun acepted amount must be 0.02 ether");
    //    }    
    }

    // funtion to send the Smart Contract Balance to the SC owner.
    function withdraw()  external onlyOwner notFunds{
         owner.transfer(getBalance()); 
       }

    //funtion to send 0.01 ether from the SC to an EOA address call.
    function withdrawFixedAmount() external {
        address payable to = payable(msg.sender);
        uint256 amount = 0.01 ether;
        require(amount <= getBalance(),"Not enough balance to transfer"); 
        to.transfer(amount); 
    }

   //funtion to send the half of the SC balance to an EOA address call.
    function withdrawHalfBalance() external notFunds {
        address payable to = payable(msg.sender);
        uint256 amount = getBalance()/2;
        to.transfer(amount); 
    }

    //funtion "getBalance" that returns the SC balance.
    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

 }