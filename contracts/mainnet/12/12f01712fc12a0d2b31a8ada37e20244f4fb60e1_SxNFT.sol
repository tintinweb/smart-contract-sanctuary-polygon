// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721URIStorage.sol";
import "Counters.sol";

contract SxNFT is ERC721URIStorage { 
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("SxNFT", "SXNFT") {}

  function createNFT(string memory tokenURI) public returns (uint256)
  {
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _mint(msg.sender, newItemId);
    _setTokenURI(newItemId, tokenURI);

    return newItemId;
  }
}