// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LandRecord {
  address contractOwner;

  constructor() {
    contractOwner = msg.sender;
  }

  function isContractOwner(address _addr) public view returns (bool) {
    return (_addr == contractOwner);
  }
}