/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;

contract Bikers{
    address owner;
    constructor(){
        owner=msg.sender;
    }
    //add yourself as a renter
    struct Renter{
        address payable walletAddress;
        string firstName;
        string lastName;
        bool canRent;
        bool active;
        uint balance;
        uint due;
        uint start;
        uint end;
    }
    mapping (address=>Renter)public renters;

    function addRenter(address payable walletAddress,string memory firstName,string memory lastName,bool canRent,bool active,uint balance,uint due,uint start,uint end) public{
       //link to the mapping
       renters[walletAddress] =Renter(walletAddress,firstName,lastName,canRent,active,balance,due,start,end) ;
    }
    //CheckOutbike
    function checkOut(address walletAddress)public{
        require (renters[walletAddress].due==0,"You have pending balance");
        require (renters[walletAddress].canRent==true, "You cannot rent at this time");
        renters[walletAddress].active=true;
        renters[walletAddress].start=block.timestamp;
        renters[walletAddress].canRent=false;
        //

    }
    //CheckIn bike
    function CheckIn(address walletAddress) public{
        require (renters[walletAddress].active==true,"You dont have a bike yet(you need to checkOut a bike first");

        renters[walletAddress].active=false;
        renters[walletAddress].end=block.timestamp;
        renters[walletAddress].canRent=true;

        //TODO set amount due
        setDue(walletAddress);

    }

    //set total duration of the bike
    function renterTimeSpan(uint start,uint end)internal pure returns(uint){
        return end -start;
    }

    function getTotalDuration(address walletAddress) public view returns (uint){
        require (renters[walletAddress].active==true,"Bike is currently checked out");

        uint timespan =renterTimeSpan(renters[walletAddress].start,renters[walletAddress].end);
        uint timespanInMinutes = timespan /60;
        return timespanInMinutes;

    }
    //Get contract balance
    function balanceOf() view public returns(uint){
        return address(this).balance;
        }
    //Get renter's Balance
    function renterBanlance(address walletAddress) public view returns(uint){
        return renters[walletAddress].balance;
    }

    //Set Due amount 
    function setDue(address walletAddress) internal {
        uint timespanInMinutes=getTotalDuration(walletAddress);
        uint fiveMinutesIncreaments = timespanInMinutes /5 ;
        renters[walletAddress].due = fiveMinutesIncreaments* 5000000000000000;
    }
   function canRentBike(address walletAddress) public view returns(bool){
       return renters[walletAddress].canRent;
   }
  
   
   function Deposit(address walletAddress) payable public {
       renters[walletAddress].balance+=msg.value;
   }
    //make payment

    function makePayment(address walletAddress)payable public{
        
        require (renters[walletAddress].due>0,"You dont have any due at this time");
        require (renters[walletAddress].balance>msg.value,"You do not have enough funds to make deposit.");

        renters[walletAddress].balance-=  msg.value;
        renters[walletAddress].canRent = true;
        renters[walletAddress].due = 0;
        renters[walletAddress].start = 0;
        renters[walletAddress].end = 0;
    }


}