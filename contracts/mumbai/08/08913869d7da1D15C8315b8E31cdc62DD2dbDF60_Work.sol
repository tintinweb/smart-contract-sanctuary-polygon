// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Work {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

//   function flip() public view returns (uint256, uint256, bytes32) {
//     bytes32 bh = blockhash(block.number - 1);
//     uint256 blockValue = uint256(blockhash(block.number - 1));

//     uint256 coinFlip = blockValue / FACTOR;

//     return (coinFlip, blockValue, bh);
//   }

  function bhu(uint256 bn) public view returns(uint256) {
      return uint256(blockhash(bn - 1));
  }

  function bh(uint256 bn) public view returns(bytes32) {
      return blockhash(bn-1);
  }

  function bhun() public view returns(uint256) {
      uint256 blockValue = uint256(blockhash(block.number));
      uint256 coinFlip = blockValue / FACTOR;

      return coinFlip;
  }
}