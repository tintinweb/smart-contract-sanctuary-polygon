// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";

contract HEROCOIN is BEP20Detailed, BEP20, BEPOwnable {
  constructor() BEP20Detailed("HEROCOIN", "HEROCOIN", 18) {
    uint256 totalTokens = 100000000 * 10**uint256(decimals());
    _mint(msg.sender, totalTokens);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
}