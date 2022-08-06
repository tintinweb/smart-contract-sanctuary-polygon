// SPDX-License-Identifier: MIT

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

pragma solidity ^0.8.7;

contract WhatYouGotInMindGirl is ERC721Enumerable,  Ownable {
  using Strings for uint256;


  string private uriPrefix = "ipfs://QmR4TVTQj4ANHMSZ6DTh6ensZpQr38JNiCRvTXy95NbF6g/";
  string private uriSuffix = ".json";

  uint public maxMintAmountPerTx = 5;
  

  uint public cost = 0.05 ether;
  uint16 public constant maxSupply = 1050;
  
  bool public paused;
  

  constructor() ERC721("What you got in mind today girl", "MIND") {
    
  }
 
  
  function mintForOwner(uint16 _mintAmount, address _receiver) external onlyOwner {
    uint16 totalSupply = uint16(_owners.length);
    require(totalSupply + _mintAmount <= maxSupply, "Excedes max supply.");
    for(uint16 i; i < _mintAmount; i++) {
    _mint(_receiver , totalSupply + i);
     }
     delete _mintAmount;
     delete _receiver;
     delete totalSupply;
  }


   
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
  
    
_tokenId++;
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

 

  function setPause() external onlyOwner {
    paused = !paused;
  }


  function setCost(uint newCost) external onlyOwner {
    cost = newCost;
  }
  

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }



  function withdraw() external onlyOwner {
  uint _balance = address(this).balance;
     payable(msg.sender).transfer(_balance ); 
       
  }

  function _mint(address to, uint256 tokenId) internal virtual override {
    _owners.push(to);
    emit Transfer(address(0), to, tokenId);
  }

  function _baseURI() internal view returns (string memory) {
    return uriPrefix;
  }

  function mint(uint16 _mintAmount) external payable  {
    uint16 totalSupply = uint16(_owners.length);
    require(totalSupply + _mintAmount <= maxSupply, "Excedes max supply.");
    require(_mintAmount <= maxMintAmountPerTx, "Exceeds max per transaction.");

    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
     for(uint8 i; i < _mintAmount; i++) {
    _mint(msg.sender, totalSupply + i);
     }
  }

}