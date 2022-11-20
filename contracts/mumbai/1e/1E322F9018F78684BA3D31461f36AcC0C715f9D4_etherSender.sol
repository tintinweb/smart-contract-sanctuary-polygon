/**
 *Submitted for verification at polygonscan.com on 2022-11-19
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
        require(owner == msg.sender,"You do not have sufficient rights");
        _;
    }

    //funtion to sent ether amount into the Smart Contract (SM).
    function sendMoney() external payable {
    }

    //funtion "getBalance" that returns the SC balance.
    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    // funtion to send the Smart Contract Balance to the SC owner.
    function withdraw()  external onlyOwner {
        uint256 amount = getBalance();
        owner.transfer(amount); 
       }

    //funtion to send 0.01 ether from the SC to an EOA address call.
    function withdrawFixedAmount() external {
        address payable to = payable(msg.sender);
        uint256 amount = 0.01 ether;
        require(amount <= getBalance(),"not enough balance to be transfered"); 
        to.transfer(amount); 
    }

   //funtion to send the half of the SC balance to an EOA address call.
    function withdrawHalfBalance() external {
        address payable to = payable(msg.sender);
        require(getBalance() > 0,"not enough balance to be transfered"); 
        uint256 amount = getBalance()/2;
        to.transfer(amount); 
    }

 }