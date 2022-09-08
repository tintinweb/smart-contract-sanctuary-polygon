/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Counter {
  uint counter;

  event CounterUpdated(address indexed updater, uint new_value, uint change, string side);

  constructor() {}

  function updateValue(uint _new_value) public {
    uint change;
    string memory side;
    if (_new_value > counter) {
      change = _new_value - counter;
      side = "up";
    } else {
      change = counter - _new_value;
      side = "down";
    }

    counter = _new_value;
    emit CounterUpdated(msg.sender, _new_value, change, side);

  }
}