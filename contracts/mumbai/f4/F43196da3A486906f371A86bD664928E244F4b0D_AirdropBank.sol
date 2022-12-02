/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AirdropBank {

    event withdrawdeposit(address to, uint256 ammount,uint256 balance);
    event deposit(address deposited,  uint256 balance);

     address public contractOwner;
     uint256 public ammountToDeposit;
     mapping (address=>bool) receivedDeposit;

     constructor(){
         contractOwner = msg.sender;
         ammountToDeposit = 10000000000000000; //.1
     }

     function depositMoney() public payable{
         emit deposit(msg.sender, address(this).balance);
     }

     function getBalance() public view returns (uint256 ret){
         return address(this).balance;
     }

     function withdrawDeposit(address payable _to) public{
         require(msg.sender == contractOwner, "Caller is not verified sender");
         require(receivedDeposit[_to]!=true, "Address has already recieved deposit");
         _to.transfer(ammountToDeposit);
         receivedDeposit[_to] = true;
         emit withdrawdeposit(_to, ammountToDeposit, address(this).balance);

     }

     function withdrawAll(address payable _to) public{
         require(msg.sender == contractOwner, "Caller is not verified sender");
         _to.transfer(address(this).balance);
         emit withdrawdeposit(_to, address(this).balance, address(this).balance);

     }


}