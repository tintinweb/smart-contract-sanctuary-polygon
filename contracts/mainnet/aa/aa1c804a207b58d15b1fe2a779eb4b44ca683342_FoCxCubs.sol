// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract FoCxCubs is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";

  uint256 public cost;
  uint256 public costHodlr;
  uint256 public maxSupply;
  uint256 public maxMintAmount;

  bool public paused = true;

  mapping(address => bool) public hodlrAddresses;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    uint256 _cost,
    uint256 _costHodlr,
    uint256 _maxSupply,
    uint256 _maxMintAmount
  ) ERC721(_name, _symbol) {
    cost = _cost;
    costHodlr = _costHodlr;
    maxSupply = _maxSupply;
    maxMintAmount = _maxMintAmount;
    setBaseURI(_initBaseURI);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "CONTRACT IS PAUSED");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "INVALID MINT AMOUNT");
    if (hodlrAddresses[msg.sender] == true) {
        require(msg.value >= costHodlr * _mintAmount, "INSUFFICIENT FUNDS");
    } else {
        require(msg.value >= cost * _mintAmount, "INSUFFICIENT FUNDS");
    }
    _;
  }

  modifier supplyCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "MAX SUPPLY EXCEEDED");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) supplyCompliance(_mintAmount) {  
    uint256 supply = totalSupply();

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function airdrop(uint256 _mintAmount, address _receiver) public supplyCompliance(_mintAmount) onlyOwner {
    uint256 supply = totalSupply();

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_receiver, supply + i);
    }
  }

  function batchAirdrop(uint[] memory _mintAmounts, address[] memory _receivers) public onlyOwner {
    uint256 batch = _receivers.length;
    require(batch == _mintAmounts.length, "ARRAY LENGTH DOES NOT MATCH");
    require(batch > 1, "BATCH MUST HAVE MORE THAN ONE RECEIVER");

    for (uint256 i = 0; i <= batch - 1; i++) {
    uint256 supply = totalSupply();
    uint256 airdropAmount = _mintAmounts[i];
    require(airdropAmount > 0, "INVALID MINT AMOUNT");
    require(supply + airdropAmount <= maxSupply, "MAX SUPPLY EXCEEDED");

        for (uint256 k = 1; k <= airdropAmount; k++) {
         _safeMint(_receivers[i], supply + k);
        }
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

  function setHodlrCost(uint256 _newHodlrCost) public onlyOwner {
    costHodlr = _newHodlrCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
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

  function addHodlr(address _user) public onlyOwner {
    hodlrAddresses[_user] = true;
  }

  function removeHodlr(address _user) public onlyOwner {
    hodlrAddresses[_user] = false;
  }

  function batchHodlrs(address[] calldata _users) public onlyOwner {
    require(_users.length > 1, "MUST ADD MORE THAN ONE USER");
    for (uint256 h; h < _users.length; h++) {
        hodlrAddresses[_users[h]] = true;
    }
  }
 
   function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}