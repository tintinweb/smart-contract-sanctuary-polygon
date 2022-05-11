// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../libraries/ReentrancyGuardStorage.sol";

/** @notice Ultimately optional reentrancy guard init contract
 * @dev Initiates the status variable to 1 to decrease the gas cost
 * of the first transaction that uses the reentracncy guard */
contract ReentrancyGuardInit {
  function init() external {
    ReentrancyGuardStorage.Layout storage s = ReentrancyGuardStorage
      .layout();
    s.status = 1;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
  struct Layout {
    uint256 status;
  }

  bytes32 internal constant STORAGE_SLOT =
    keccak256("solidstate.contracts.storage.ReentrancyGuard");

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}