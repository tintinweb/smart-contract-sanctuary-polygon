/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Context {
  address relayer;

  function setRelayer(address relayer_) public {
    relayer = relayer_;
  }

  /**
   * @notice Context mixing for meta transactions
   */
  function _msgSender() public view returns (address sender) {
    if (msg.sender == relayer) {
      assembly {
        /* Get the msg.sender */
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else sender = msg.sender;
  }
}

contract Simple is Context {
  event callReceived(address who);

  function changeNumber() public {
    emit callReceived(_msgSender());
  }
}