// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/*
 * @title ItemsLib
 * @notice ItemsLib can be used to manipulate item ids. Format is:
 *  unused<160> | itemType<32> | randomness<64>
 *
 * itemType also contain information about rarity :
 * unused<8> | rarity<4> | index<20>
 *
 * rarity is encoded as follow
 * 0b0001 : common
 * 0b0010 : uncommon
 * 0b0100 : rare
 * 0b1000 : common
 *
 * index is a number that is used to differentiate each itemType.
 */
library ItemsLib {
  struct Token {
    address token;
    uint256 amount;
  }

  uint public constant ITEMTYPE_SIZE = 32;
  uint public constant SEED_SIZE = 64;

  uint public constant MAX_ITEMTYPE = (2**ITEMTYPE_SIZE)-1;
  uint public constant MAX_SEED = (2**SEED_SIZE)-1;

  function getItemType(uint256 itemId) public pure returns (uint32) {
    return uint32((itemId >> SEED_SIZE) & MAX_ITEMTYPE);
  }

  function getSeed(uint256 itemId) public pure returns (uint64) {
    return uint64(itemId & MAX_SEED);
  }

  function computeItemId(uint32 itemType, uint256 seed) public pure returns (uint256) {
    return (uint256(itemType) << SEED_SIZE) | (seed & MAX_SEED);
  }
}