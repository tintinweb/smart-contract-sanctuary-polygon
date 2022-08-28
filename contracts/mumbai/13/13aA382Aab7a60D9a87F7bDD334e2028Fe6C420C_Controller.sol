// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./interface/IController.sol";

contract Controller is IController {

  address public governance;
  address public pendingGovernance;

  address public veFars;
  address public voter;

  event SetGovernance(address value);
  event SetVeFars(address value);
  event SetVoter(address value);

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGov() {
    require(msg.sender == governance, "Not gov");
    _;
  }

  function setGovernance(address _value) external onlyGov {
    pendingGovernance = _value;
    emit SetGovernance(_value);
  }

  function acceptGovernance() external {
    require(msg.sender == pendingGovernance, "Not pending gov");
    governance = pendingGovernance;
  }

  function setVeFars(address _value) external onlyGov {
    veFars = _value;
    emit SetVeFars(_value);
  }

  function setVoter(address _value) external onlyGov {
    voter = _value;
    emit SetVoter(_value);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IController {

  function veFars() external view returns (address);

  function voter() external view returns (address);

}