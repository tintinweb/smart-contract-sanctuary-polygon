// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../alloyx/interfaces/IBackedOracle.sol";

contract BackedOracle is IBackedOracle {
  function latestAnswer() external view override returns (int256) {
    return 2 * 10**8;
  }

  function decimals() external view override returns (uint8) {
    return 8;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IBackedOracle
 * @author AlloyX
 */
interface IBackedOracle {
  function latestAnswer() external view returns (int256);

  function decimals() external view returns (uint8);
}