/**
 *Submitted for verification at polygonscan.com on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Random {
   
   uint[4] somevalue;

   constructor(){}

   function setValExample1() public {
      uint a=1;
      somevalue = [
         uint(a & 0xF0) >> 4,
         uint(a & 0xF),
         uint(a + 2 & 0xF0) >> 4,
         uint(a + 2 & 0xF)
      ];
   }

   function setValExample2(uint8 x, uint8 y) public pure returns(uint16){
      return uint16(x)*uint16(y);
   }

   function getValueExample1() public view returns(uint[4] memory){
       return somevalue;
   }

   function getValueExample2() public pure returns(uint){
      return 0xA0 >> 4;
   }

   function shift(uint v, uint n, bool dir) public pure returns(uint){
      if(!dir) return v >> n;
      else     return v << n;
   }
}