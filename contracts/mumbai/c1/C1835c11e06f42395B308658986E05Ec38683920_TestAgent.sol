/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract TestAgent {

address public Owner;
bool public Switch;

modifier onlyOwner {
      require(msg.sender == Owner);
      _;
   }

constructor() {
    Owner = msg.sender;
    Switch = false;
}

function ChangeOwner(address newOwner) public onlyOwner{
  Owner = newOwner;
}

function FlipSwitch() public onlyOwner{
if (Switch==false){
    Switch = true;
    } else {
    Switch = false;
    }    
}

}