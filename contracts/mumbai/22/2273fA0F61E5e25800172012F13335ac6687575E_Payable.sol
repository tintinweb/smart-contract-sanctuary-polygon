/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Payable{
    address public immutable owner = msg.sender;
    address[] public transactionWallet;
    uint public count=0;

    struct ledger{
    uint no;
    address sender;
    address reciever;
    uint amount;
    }

     mapping(uint  => ledger) public  datalogger;
   
    constructor() payable {

    }

    function getMoney() payable public{
      
    }

    function sendmoney(address payable _name) payable public{
      
        if(_name == msg.sender){
            revert("you cannot send to yourself");
        }

        datalogger[count] = ledger(transactionWallet.length,msg.sender,_name,msg.value);
       
        _name.transfer(msg.value);

        transactionWallet.push(_name);
        count++;
   
    }
    
    function getmoney()public payable  {
      
      }

   


    function contractBalance () public view returns(uint) {
         return address(this).balance;
    }

    function withdrawEther(uint amount, address payable sendTo) public  {
        require(amount >=address(this).balance, "contract does not have enough balance");
            sendTo.transfer(amount);
    }

   
}