/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Addition{
  uint256 public totalValue;
  mapping(address=>bool) add;
   uint public numberOf;

  function addValue(uint256 value) public  {
        
        totalValue += value;
        if(add[msg.sender] == true){
          return ;
        }
        else {
        numberOf+=1;
        add[msg.sender]= true;
        }
  }
  function getData() public view returns(uint256, uint) {
    return(totalValue,numberOf);

  }
}