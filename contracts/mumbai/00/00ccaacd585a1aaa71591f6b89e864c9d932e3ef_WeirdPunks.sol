// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol"; 
import "./ERC1155Tradable.sol";
import "./TokenIdentifiers.sol";

contract WeirdPunks is ERC721, Ownable {
  using TokenIdentifiers for uint256;
 
  string public baseURI;
  mapping(uint256 => uint256) public weirdMapping;
  mapping(uint256 => bool) internal isMinted;
  ERC1155Tradable public openseaContract;
  uint256 public maxSupply = 1000;
  uint256 public totalSupply = 0;

  constructor(
    string memory _initBaseURI,
    address _openseaContract
  ) ERC721("Weird Punks", "WP") {
    setBaseURI(_initBaseURI);
    openseaContract = ERC1155Tradable(_openseaContract);
  }
 
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
 
  // public
  function burnAndMint(address _to, uint256[] memory _IDs) public {
    require(openseaContract.isApprovedForAll(_to, address(this)), 'not approved');
    require(totalSupply + _IDs.length <= maxSupply);

    for(uint256 i = 0; i < _IDs.length; i++) {
        require(!isMinted[_IDs[i]]);
        uint256 openseaID = weirdMapping[_IDs[i]];
        openseaContract.burn(_to, openseaID, 1);
        

        _safeMint(_to, _IDs[i]);
        totalSupply++;
        isMinted[_IDs[i]] = true;
    }
  } 
 
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }
 
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId)))
        : "";
  }
 
  //only owner
  function overrideMint(address _to, uint256[] memory _IDs) public onlyOwner {
    require(totalSupply + _IDs.length <= maxSupply);
    for(uint256 i = 0; i < _IDs.length; i++) {
        require(!isMinted[_IDs[i]]);
        
        _safeMint(_to, _IDs[i]);
        totalSupply++;
        isMinted[_IDs[i]] = true;
    }
  }

  function addSingleWeirdMapping(uint256 ID, uint256 OSID) onlyOwner private returns(bool success) {
    weirdMapping[ID] = OSID;
    success = true;
  }
 
  function addWeirdMapping(uint256[] memory IDs, uint256[] memory OSIDs) onlyOwner public returns(bool success) {
    require(IDs.length == OSIDs.length);
    for (uint256 i = 0; i < IDs.length; i++) {
      if (addSingleWeirdMapping(IDs[i], OSIDs[i])) {
        success = true;
      }
    }    
  }
 
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setOpenseaContract(address _openseaContract) public onlyOwner {
      openseaContract = ERC1155Tradable(_openseaContract);
  }
}