/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract SimpleEventContract {
  event SimpleEvent(address sender, string message);


  function EmitEvent(string calldata _msg) public {
    emit SimpleEvent(msg.sender, _msg);
  }
}