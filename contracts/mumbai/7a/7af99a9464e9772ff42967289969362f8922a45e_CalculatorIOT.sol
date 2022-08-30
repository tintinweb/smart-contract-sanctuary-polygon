/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract CalculatorIOT {
  
   // INFO PRICES
   function info()  public pure returns (string memory) {
      return "add price = 10, mul price = 20,  sub price = 50, div price = 100, thankyou!";
   } 
  
   // function adding
   function setAdd(int num1, int num2) external payable returns(int){
      if (msg.value >= 10) {    
         int add = num1 + num2;
         return add;
      }
      return 0;
   }   
   // function multipluing
   function setMul(int num1, int num2) external payable returns(int){  
      if (msg.value >= 20) {  
         int mul = num1 * num2;
         return mul;
      }
      return 0;
   }
   // function subtracting
   function setSub(int num1, int num2) external payable returns(int){ 
      if (msg.value >= 50) {   
         int sub = num1 - num2;
         return sub;
      }
      return 0;      
   }
   // function dividing
   function setDiv(int num1, int num2) external payable returns(int){
      if (msg.value >= 100) {    
         int div = num1 / num2;
         return div;
      }
      return 0;
   }
}