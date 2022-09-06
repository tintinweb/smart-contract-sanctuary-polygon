/**
 *Submitted for verification at polygonscan.com on 2022-09-06
*/

// File: contracts/darkmatter.sol



pragma solidity 0.8.10;

contract darkMatter {
    Gravity gravity;
    constructor(address _gravity) {
       gravity = Gravity(_gravity); 
    } 

    function callGravity() public {
       gravity.log(); 

   }
   
}


contract Gravity {
   event Log(string message);

   function log() public{
   emit Log("Gravity function was called");
   
   }  

}