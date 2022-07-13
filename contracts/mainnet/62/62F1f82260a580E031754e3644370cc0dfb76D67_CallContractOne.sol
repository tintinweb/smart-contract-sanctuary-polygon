// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract CallContractOne {

function setValueXByInitializing( address _contractOneAddress, uint _x ) public {
     ContractOne(_contractOneAddress).setX(_x);
  }

function setValueXByType(ContractOne _contract, uint _x ) public {
     _contract.setX(_x);
  }

function setValueXByPassingValue(ContractOne _contract, uint _x ) public payable {
     _contract.setXAndReceiveEther{value: msg.value }(_x);
  }
}

contract ContractOne {
  uint public x;
  uint public value;

 function setX(uint _x ) external {
  //we will want to set the value of x from CallContractOne
  x = _x;
 }

function setXAndReceiveEther(uint _x ) external payable {
  //we will want to set the value of x from CallContractOne
   x = _x;
   value = msg.value;
 }

}