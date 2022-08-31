/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract CalculatorIOT {
  
   // INFO PRICES
   function info()  external pure returns (string memory) {
      return "add price = 10, mul price = 20,  sub price = 50, div price = 100, thankyou!";
   } 

   // function withdraw
   function withdraw(address payable myCount) external {
       if (msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4){            
        }
        uint balance = address(this).balance;

        myCount.transfer(balance);        
    }

   // function check credit
    function getbalance() external view returns (uint) {
        uint balance = address(this).balance;   
        return balance;
    }
  
   // function adding with require 
   function setAdd(int num1, int num2) external payable returns(int){
      require(msg.value >= 10, "wrong price, read the info"); 

      int add = num1 + num2;
      return add;       
   } 

   // function multipluing with require
   function setMul(int num1, int num2) external payable returns(int){  
      require(msg.value >= 20, "wrong price, read the info");

      int mul = num1 * num2;
      return mul;      
   }

   // function subtracting with require
   function setSub(int num1, int num2) external payable returns(int){ 
      require(msg.value >= 50, "wrong price, read the info");

      int sub = num1 - num2;
      return sub;
         
   }

   // function dividing with require
   function setDiv(int num1, int num2) external payable returns(int){
      require(msg.value >= 100, "wrong price, read the info"); 

      int div = num1 / num2;
      return div;
     
   }
}