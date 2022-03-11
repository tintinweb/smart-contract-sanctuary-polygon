// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {
  address public governance;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }
}