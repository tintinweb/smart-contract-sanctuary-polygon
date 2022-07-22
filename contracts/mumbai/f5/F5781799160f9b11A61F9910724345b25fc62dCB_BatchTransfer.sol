// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface NftCollection {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract BatchTransfer {
  function batchTransfer(
    NftCollection contractAdrress,
    address recipient,
    uint256 firstId,
    uint256 lastId
  ) external {
    for (uint256 i = firstId; i <= lastId; i++) {
      contractAdrress.transferFrom(msg.sender, recipient, i);
    }
  }
}