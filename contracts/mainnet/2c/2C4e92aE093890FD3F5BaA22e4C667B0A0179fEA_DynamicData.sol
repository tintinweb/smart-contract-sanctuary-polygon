// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract DynamicData {
  address public manager;

  string public akashNodeUrl;

  constructor() {
    manager = msg.sender;
  }

  function updateAkashNodeUrl(string memory _newUrl) public {
    require(msg.sender == manager, "only the manager can update");

    akashNodeUrl = _newUrl;
  }
}