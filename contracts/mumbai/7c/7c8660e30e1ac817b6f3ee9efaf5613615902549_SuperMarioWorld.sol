// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import './ERC721.sol';

contract SuperMarioWorld is ERC721 {
  string public name;
  string public symbol;
  uint256 public  tokenCount;
  mapping(uint256 => string) private tokenURIs;

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  /* Returns a URL which points to the metadata */
  function tokeURI(uint256 _tokenId) public view isTokenValid(_tokenId) returns(string memory) {
    return tokenURIs[_tokenId];
  }

  /* Creates a new NFT inside this collection */
  function mint(string memory _tokenURI) external {
    balances[msg.sender] += 1;
    owners[tokenCount] = msg.sender;
    tokenURIs[tokenCount] = _tokenURI;
    emit Transfer(address(0), msg.sender, tokenCount);
    tokenCount += 1;
  }

  /* Implemendted ERC721Metadata so update the interface check funcionality */
  function supportsInterface(bytes4 _interfaceId) public pure override returns(bool) {
    return _interfaceId == 0x80ac58cd || _interfaceId == 0x5b5e139f;
  }
}