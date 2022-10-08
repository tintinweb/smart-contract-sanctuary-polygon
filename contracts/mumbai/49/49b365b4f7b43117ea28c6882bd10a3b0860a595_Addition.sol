/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.0;

contract Addition{
  int256 public totalValue;
  mapping(address=>bool) add;
   int public numberOf;

  function set (int256 value) public  {
        
        totalValue += value;
        if(add[msg.sender] == true){
          return ;
        }else {
        numberOf+=1;
        add[msg.sender]= true;}
  }
  function getData() public view returns(int256, int) {
    return(totalValue,numberOf);

  }
}