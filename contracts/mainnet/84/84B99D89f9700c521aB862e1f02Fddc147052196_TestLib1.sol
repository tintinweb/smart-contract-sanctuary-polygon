// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./TestLib2.sol";

library TestLib1 {

  function testDependency() external {
    TestLib2.test();
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library TestLib2 {

  event TestEvent();

  function test() external {
    emit TestEvent();
  }

}