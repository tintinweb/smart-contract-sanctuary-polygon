// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract PresaleA {
  uint public val;

  // Los contratos actualizables no utilizan contructor
  // solo se llama una vez cuando se implementa el primer deploy
  function initialize(uint _val) external {
    val = _val;
  }
}