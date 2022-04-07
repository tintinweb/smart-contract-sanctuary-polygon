// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

interface IKZBox {
  function transferToUser(
    address to,
    uint32 confId,
    uint32 num
  ) external;
}

contract KZBoxDistributor is Ownable {
  IKZBox public kZBox;

  constructor(address _kzBox) {
    kZBox = IKZBox(_kzBox);
  }

  function multipleTransfer(
    uint32 confId,
    address[] calldata tos,
    uint32[] calldata num
  ) external onlyOwner {
    for (uint256 i; i < num.length; i++) {
      kZBox.transferToUser(tos[i], confId, num[i]);
    }
  }
}