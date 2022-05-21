// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

interface IdentityProgram {
  function fulfill(uint x) external returns (uint);
}

contract IdentityChallenge {
  function challenge(address program) external returns (bool) {
    return (
      IdentityProgram(program).fulfill(0) == 0
      && IdentityProgram(program).fulfill(block.timestamp) == block.timestamp
      && IdentityProgram(program).fulfill(block.number) == block.number
    );
  }
}