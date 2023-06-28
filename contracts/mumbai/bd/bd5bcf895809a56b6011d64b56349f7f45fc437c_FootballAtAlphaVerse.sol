// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.19;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
 
contract FootballAtAlphaVerse is ERC721A, ERC2981, Ownable {

  string[] public baseURIs;
  uint256[] public baseURIChangeIndexes;
  address public treasure;
  address public minter;
  string public contractURI = "ipfs://QmTtBLjmVscvYCc1A7AxoQxD4Xk512xbaBqme4pcdnUH8M/contract.json";

  // ERC4906
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  constructor()
    ERC721A("Football at AlphaVerse","FAV")
    {
    }

  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }

  function setMinter(address _minter) external {
    minter = _minter;
  }

  function setBaseURIs(string[] memory _baseURIs, uint256[] memory _changeIndexes) external onlyOwner {
    require(_baseURIs.length == _changeIndexes.length, 'invalid array size');
    baseURIs = _baseURIs;
    baseURIChangeIndexes = _changeIndexes;
    emit BatchMetadataUpdate(1, type(uint256).max);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
      uint256 baseURIIndex = 0;
      for(uint256 i=0; i<baseURIChangeIndexes.length; i++){
        if(tokenId<=baseURIChangeIndexes[i]){
          baseURIIndex = i;
          break;
        }
      }
      string memory baseURI =  baseURIs[baseURIIndex];
      return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
  }

  function setContractURI(string memory _contractURI) external onlyOwner{
    contractURI = _contractURI;
  }

  // 10% => feeNumerator = 1000
  function setTreasureAndDefaultRoyalty(address newTreasure, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(newTreasure, feeNumerator);
    treasure = newTreasure;
  }

  function mint(address to, uint16 count) external {
    require(_msgSender()==owner() || _msgSender()==minter, 'invalid caller');
    _mint(to, count);
  }

  function burn(uint256 tokenId) external{
    _burn(tokenId, true);
  }


  // ERC4906 ERC721A ERC2981
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId) ||
            interfaceId == bytes4(0x49064906);
    }
}