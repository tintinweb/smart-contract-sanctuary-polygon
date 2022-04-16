pragma solidity ^0.8.0;

// SPDX-License-Identifier: Gaming




contract PaymentGateway{


address public owner_;

uint256 public balance = 0;
address public devwallet;




  constructor(){

    owner_ = msg.sender;


  }



function setDev(address dev) public{

require(msg.sender == owner_, "Must be owner to call this function");


devwallet = dev;


}



function Pay() payable public{

require(msg.value > 0, "Invalid amount sent");

uint256 devs = msg.value * 40 / 100;

balance += msg.value-devs;


payable(devwallet).transfer(devs);



}


function Payout(address winner, uint256 amount) public {

require(msg.sender == owner_, "Must be the owner");

require(amount < balance, "Insufficient balance");

payable(winner).transfer(amount);

balance -= amount;



}

















}