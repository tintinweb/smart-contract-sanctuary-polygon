// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library TestLib2 {

  event TestEvent();

  function test() external {
    emit TestEvent();
  }

}