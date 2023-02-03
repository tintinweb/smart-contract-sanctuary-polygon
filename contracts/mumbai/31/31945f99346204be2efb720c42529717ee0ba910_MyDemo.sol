// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";


contract MyDemo is ERC721Enumerable, Ownable, ReentrancyGuard {
  uint256 private constant START_TOKEN_ID = 1;

  string public baseTokenURI = "https://gateway.pinata.cloud/ipfs/Qmert3kHFGSwCShx1hnc5uikPVbxHUJnDHJdTLnEpsYf88/";

  constructor() ERC721("MyDemo", "MyDemo") {}

  function ownerMint(address toAddr, uint256 amount) public onlyOwner nonReentrant {
    uint256 nextId = totalSupply() + START_TOKEN_ID;
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(toAddr, nextId + i);
    }
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    return bytes(baseTokenURI).length > 0 ? string(
      abi.encodePacked(baseTokenURI, Strings.toString(tokenId), ".json")
    ) : "";
  }
}