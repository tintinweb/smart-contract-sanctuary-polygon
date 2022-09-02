/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

contract MyContract {
  uint public deployDate;
  uint public finishTime;


  // Will return `true` if 10 minutes have passed since `the contract was deployed
  function GameHavePassed() public view returns (bool) {
    return (block.timestamp >= (deployDate + finishTime));
  }

  function StartGame(uint finish) public {
      deployDate = block.timestamp;
      finishTime = finish;
  }

  function CancelGame() public {
      finishTime = 32524720790;
  }
}