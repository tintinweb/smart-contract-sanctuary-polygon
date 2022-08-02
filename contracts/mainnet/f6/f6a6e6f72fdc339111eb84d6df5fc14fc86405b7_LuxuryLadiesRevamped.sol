// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LuxuryLadiesRevamped is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmount;
  uint256 public maxPerAddress;

  mapping(address => uint256) public addressTotalMinted;

  bool public paused = true;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmount,
    uint256 _maxPerAddress
  ) ERC721(_name, _symbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmount = _maxMintAmount;
    maxPerAddress = _maxPerAddress;
    setBaseURI(_initBaseURI);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "CONTRACT IS PAUSED");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "INVALID MINT AMOUNT");
    require(msg.value >= cost * _mintAmount, "INSUFFICIENT FUNDS");
    require(addressTotalMinted[msg.sender] + _mintAmount <= maxPerAddress, "NFT MINT LIMIT REACHED");
    _;
  }

  modifier supplyCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "MAX SUPPLY EXCEEDED");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) supplyCompliance(_mintAmount) {  
    uint256 supply = totalSupply();

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressTotalMinted[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function airdrop(uint256 _mintAmount, address _receiver) public supplyCompliance(_mintAmount) onlyOwner {
    uint256 supply = totalSupply();

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_receiver, supply + i);
    }
  }

  function mintOwner(uint256 _mintAmount) public supplyCompliance(_mintAmount) onlyOwner {
    uint256 supply = totalSupply();

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setmaxPerAddress(uint256 _newmaxPerAddress) public onlyOwner {
    maxPerAddress = _newmaxPerAddress;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
   function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}