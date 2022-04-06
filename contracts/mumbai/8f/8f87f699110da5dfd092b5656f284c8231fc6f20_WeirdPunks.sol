// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract WeirdPunks is ERC721 {
 
  uint256 public maxSupply = 1000;
  mapping(uint256 => uint256) internal migrateTimestamp;

  constructor(
  ) ERC721("Weird Punks", "WP") {}
 
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      if(_exists(currentTokenId)) {
        address currentTokenOwner = ownerOf(currentTokenId);
        if (currentTokenOwner == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;
          ownedTokenIndex++;
        }
        currentTokenId++;
      }
    }
    return ownedTokenIds;
  }

  function getMigrateTimestamp(uint256 _id) public view returns(uint256) {
    return migrateTimestamp[_id];
  }
}