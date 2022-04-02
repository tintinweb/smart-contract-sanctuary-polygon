//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract MockNFT20Factory {
  mapping(address => address) public nftToToken;

  function setMapping(address _nft, address _token) public {
    nftToToken[_nft] = _token;
  }
}