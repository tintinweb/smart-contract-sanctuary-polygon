//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Whitelist {
  uint8 public maxWhitelistedAddresses;
  mapping(address => bool) public whitelistedAddresses;
  uint8 public numAddressesWhitelisted;
  address private _owner;

  constructor(uint8 _maxNumber) {
    maxWhitelistedAddresses = _maxNumber;
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, 'Only owner');
    _;
  }

  function setMaxWhitelistedAddresses(uint8 _maxNumber) external onlyOwner() {
    require(_maxNumber > numAddressesWhitelisted, 'Max number invalid');
    maxWhitelistedAddresses = _maxNumber;
  }

  function joinIntoWhiteList() external {
    require(numAddressesWhitelisted < maxWhitelistedAddresses, 'Maximum members in whitelist');
    require(!whitelistedAddresses[msg.sender], 'Already joined whitelist');
    whitelistedAddresses[msg.sender] = true;
    numAddressesWhitelisted += 1;
  }

  function leaveOutWhiteList() external {
    require(whitelistedAddresses[msg.sender], 'Already left whitelist');
    whitelistedAddresses[msg.sender] = false;
    numAddressesWhitelisted -= 1;
  }
}