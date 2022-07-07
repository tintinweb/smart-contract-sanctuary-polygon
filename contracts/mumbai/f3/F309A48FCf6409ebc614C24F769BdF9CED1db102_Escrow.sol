/**
 *Submitted for verification at polygonscan.com on 2022-07-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Escrow{
  
  address payable public requesterWallet;
  address public approvalWallet;
  uint public amountReleased;
  struct RequestPayments{
      uint milestone;
      uint amount;
      bool requested;
      bool completed;
      bool approved;
  }
  mapping (uint=>RequestPayments) public paymentsCheck;
  mapping (uint=>bool) public paymentsCheckExist;
  
  
  
  constructor(
    address payable _requestWallet, 
    RequestPayments[] memory _payments) {
    
    requesterWallet= _requestWallet;
    approvalWallet = msg.sender; 
    // payments=_payments;
    for (uint i=0;i<_payments.length;i++){
        paymentsCheck[i]=_payments[i];
        paymentsCheckExist[i]=true;

    }
      
    
        
  }
  modifier onlyApprovalWallet(){
      require(msg.sender==approvalWallet,"You are not allowed to approve funds");
      _;

  }
  modifier onlyRequestedWallet(){
      require(msg.sender==requesterWallet,"You are not allowed to request funds");
      _;

  }
  function requestPayment(uint index) public onlyRequestedWallet{
        require(paymentsCheck[index].completed==false,"Milestones not completed");
        require(paymentsCheck[index].requested==false,"Milestones already requested");

        paymentsCheck[index].requested=true;


  }
  function approvePayment(uint index) public onlyApprovalWallet{
      require(paymentsCheck[index].requested==true,"Payment not requested");
      require(paymentsCheck[index].completed==true,"Milestone not copleted");
      require(paymentsCheck[index].approved==false,"Payment already approved");
      require(address(this).balance>paymentsCheck[index].amount,"You dont have enough fund to approve payments");

      if(index!=0 && paymentsCheck[--index].completed==false){
         revert("Previous milestone not completed");
      }

      paymentsCheck[index].approved=true;
      amountReleased+=paymentsCheck[index].amount;
      requesterWallet.transfer(paymentsCheck[index].amount);
       
  }

  function balanceOf() view public returns(uint) {
    return address(this).balance;
  }
  function updateCompleteMileStone(uint index)public onlyRequestedWallet{
       require(paymentsCheckExist[index],"Payment index not exits");
       paymentsCheck[index].completed=true;

  }
 
  fallback() external payable{

  }
  receive() external payable{

  }
}