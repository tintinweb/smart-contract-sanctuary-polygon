// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FakeNFTMarketplace {
  mapping(uint256 => address) public tokens;
  uint256 private nftPrice = 0.1 ether;

  function getPrice() public view returns (uint256) {
    return nftPrice;
  }

  function purchase(uint256 _tokenId) public payable {
    require(msg.value == nftPrice, "Not enough money");
    tokens[_tokenId] = msg.sender;
  }

  function available(uint256 _tokenId) public view returns (bool) {
    if(tokens[_tokenId] == address(0)) return true;
    return false;
  }
}