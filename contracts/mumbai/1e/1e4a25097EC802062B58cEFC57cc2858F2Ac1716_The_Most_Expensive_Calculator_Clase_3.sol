/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract The_Most_Expensive_Calculator_Clase_3 {

    uint PRICE1 = 1 ether;
    uint PRICE2 = 2 ether;
    uint PRICE3 = 3 ether;
    uint PRICE4 = 4 ether;
   

    function withdraw(address payable to) external {
       if (msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4){
            
        }
        uint balance = address(this).balance;

        to.transfer(balance);
        
    }

    function getbalance() external view returns (uint) {
        uint balance = address(this).balance;   
        return balance;
    }

    function sum(uint num1, uint num2) external payable returns (uint total1){
        if (msg.value == PRICE1) {
        total1 = num1 + num2;
        
            return total1;
    }
    }
    function sub(uint num1, uint num2) external payable returns (uint total2){
        if (msg.value == PRICE2) {
        total2 = num1 - num2;
        
            return total2;
    }
    }
     function mul(uint num1, uint num2) external payable returns (uint total3){
        if (msg.value == PRICE3) {
        total3 = num1 * num2;
        
            return total3;
    }
    }
    function div(uint num1, uint num2) external payable returns (uint total4){
        if (msg.value == PRICE4) {
        total4 = num1 / num2;
        
            return total4;
        }
    }
  
}