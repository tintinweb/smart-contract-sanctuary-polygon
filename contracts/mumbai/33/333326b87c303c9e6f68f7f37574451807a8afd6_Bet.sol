/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;
contract Bet
   {
   address private Owner;

   constructor()
   {
        Owner=msg.sender;
    }
    struct DepositStruct{
        address _user;
        uint _numTokens;
    }
    mapping(address=>DepositStruct) private DepositDetails;
    mapping(address=>uint) private Balances;
    event Edeposit(address who,uint _numTokens,uint _TxnFees);

    function DepositEth(uint _numTokens) public 
    {
         uint TxnFees;
         uint TokensToBeDeposit=_numTokens-TxnFees;
         Balances[Owner]+=TxnFees;
         DepositDetails[msg.sender]=DepositStruct(msg.sender,TokensToBeDeposit);
         emit Edeposit(msg.sender,TokensToBeDeposit,TxnFees);
    }
    function DepositedTokens(address _user) public view returns(uint){
        return DepositDetails[_user]._numTokens;
    }
    function BalanceOf(address _user) public view returns(uint){
        return Balances[_user];
    }
    function withdrawTokens(uint _numTokens) public 
    {
        require(_numTokens<=DepositDetails[msg.sender]._numTokens);
        uint TxnFees;
        uint NumWithdrawTokens=_numTokens-TxnFees;
        Balances[msg.sender]+=NumWithdrawTokens;
        DepositDetails[msg.sender]._numTokens=DepositDetails[msg.sender]._numTokens-NumWithdrawTokens;

     }
}