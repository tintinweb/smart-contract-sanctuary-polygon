/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;
contract BetNow
    {
    address private Owner;

    struct DepositStruct
    {
         address _user;
         uint _numTokens;
    }

    mapping(address=>DepositStruct) private DepositDetails;
    mapping(address=>uint) private Balances;
    event Edeposit(address who,uint _numTokens,uint _TxnFees);
    event EWithdraw(address _who,uint _amount,uint _txnFees);
     
    constructor()                         
    {
         Owner=msg.sender;
    }
    function DepositEth() public payable
    {
         uint TxnFees=0;
         uint TokensToBeDeposit=msg.value-TxnFees;
         Balances[Owner]+=TxnFees;
         DepositDetails[msg.sender]=DepositStruct(msg.sender,TokensToBeDeposit);
         emit Edeposit(msg.sender,TokensToBeDeposit,TxnFees);
    }
    function DepositedTokens(address _user) public view returns(uint)
    {
        return DepositDetails[_user]._numTokens;
    }
    function BalanceOfOwner(address _user) public view returns(uint){
                return Balances[_user];
    }
    function withdrawTokens() public payable
    {
        require(msg.value<=DepositDetails[msg.sender]._numTokens);
        uint TxnFees;
        uint NumWithdrawTokens=msg.value-TxnFees;
        payable(msg.sender).transfer(NumWithdrawTokens);
        DepositDetails[msg.sender]._numTokens=DepositDetails[msg.sender]._numTokens-NumWithdrawTokens;
        emit EWithdraw(msg.sender,NumWithdrawTokens,TxnFees);
     }
     function WithdrawTxnFees() public payable
     {
         require(msg.sender==Owner);
         uint _amount=Balances[Owner];
         payable(Owner).transfer(_amount);
     }
     }