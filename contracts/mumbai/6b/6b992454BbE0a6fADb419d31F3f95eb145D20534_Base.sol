/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.18;

contract Base{

    address public owner;
    constructor() {
      owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    receive() external payable {}


    uint256 public i = 1;
    uint256 public j = 100;
    event Start(uint number);

    function b() public returns (uint){
      emit Start(i);
      return ++i;

    }

    function c() public onlyOwner returns (uint){
      return ++j;

    }

  
    
}