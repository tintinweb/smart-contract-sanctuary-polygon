/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract lottery{

// save owner,contract address,time,tickets price and fee 
   constructor(uint8 fee_ ,uint8 day ,uint ticket_price)
    {
        owner = msg.sender; 
        bank = address(this); 
        time = day; 
        starttime = block.timestamp;
        ticketprice = ticket_price;
        fee = fee_ ; 
    }
//state variables
    address owner;
    address bank;
    uint fee;
    uint time;
    uint starttime;
    uint ticketprice;

// list of users and 
  struct user{

     address id;
     string name ;
     }

     user [] ticket ;
    
    
//modifier for checking owner
     modifier Owner(){ 

         require (msg.sender == owner , "you're not the owner");
         _;

         }

// modifier for checking days left 
     modifier timelimit(){

         require (block.timestamp <= starttime + time * 86400 , "time's over");
         _;

         }

// buying ticket 
     function buy_ticket( string memory name_ , uint number ) public timelimit payable{
     
         require(msg.value == number*ticketprice, "Value is over or under price."); 
         for (uint i; i < number; i++) ticket.push(user(msg.sender,name_));

         }
     
//make a random choice
     function random() private view returns(uint){

         return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, '1')));

         }
    
//who's the winner
     function winner () public Owner payable returns ( user memory ){

         require(block.timestamp >= starttime + time * 86400 , "time has not been ended");

         uint index = (random() % ticket.length)+1 ;

         _withdraw(ticket[index].id , uint256(bank_balance() - bank_balance()/(fee*1000)));

         return ticket[index];

         }

//giveaway the reward
     function _withdraw(address _address, uint256 _amount) private returns (bool) {

         (bool success, ) = _address.call{value: _amount}("");
         require(success, "Transfer failed.");
         return true;

         }

// show how much value has been deposited
     function bank_balance () public view returns (uint){

         return bank.balance;

         }

}