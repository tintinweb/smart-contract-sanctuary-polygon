// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ERC721.sol';

contract NFT is ERC721 {
  // Flag
  bool public inicializated;
  bool public URI_FLAG;

  constructor (address module) ERC721(module) {}

  function inicialize(string memory name_, string memory symbol_) public onlyDeployer {
    require(!inicializated, 'Contract already inicializated');
    _name = name_;
    _symbol = symbol_;
    inicializated = true;
  }

  function mint(uint amount) public onlyDeployer {
    _mint(msg.sender, amount);
  }

  function burn(uint tokenId_) public onlyDeployer {
    _burn(tokenId_);
  }

  function setURI(string memory URI) public override onlyDeployer {
    require(!URI_FLAG);
    _URI = URI;
    URI_FLAG = true;
  }
}