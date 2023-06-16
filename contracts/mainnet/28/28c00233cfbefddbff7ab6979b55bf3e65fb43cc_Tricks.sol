// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.7;

import './Ownable.sol';
import './ERC2981.sol';
import './ERC721A.sol';
import './Address.sol';
import "./Strings.sol";

contract Tricks is ERC721A, ERC2981, Ownable {

  uint16 public collectionSize = 50;

  string public baseURI;  
  
  event BaseURIUpdated(string newURI);
  
  // ERC4906
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  constructor()
    ERC721A("Remparts de Tours NFT","RDT")
    {
      
    }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  //
  // Collection settings
  //

  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
    emit BaseURIUpdated(_newBaseURI);
    emit BatchMetadataUpdate(1, type(uint256).max);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
      return string(abi.encodePacked(_baseURI(), "contract.json"));
  }
  

  function _batchMint(address to, uint16 count) private {
    require(_totalMinted() + count <= collectionSize, "Collection is sold out");
    _safeMint(to, count);
  }

  function mint(address to, uint16 count) external onlyOwner {
    _batchMint(to, count);
  }
  
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}