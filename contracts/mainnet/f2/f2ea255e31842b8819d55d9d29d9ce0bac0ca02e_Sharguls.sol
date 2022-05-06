// SPDX-License-Identifier: MIT

/*
  _____ __ __   ____  ____    ____  __ __  _     _____
 / ___/|  |  | /    ||    \  /    ||  |  || |   / ___/
(   \_ |  |  ||  o  ||  D  )|   __||  |  || |  (   \_ 
 \__  ||  _  ||     ||    / |  |  ||  |  || |___\__  |
 /  \ ||  |  ||  _  ||    \ |  |_ ||  :  ||     /  \ |
 \    ||  |  ||  |  ||  .  \|     ||     ||     \    |
  \___||__|__||__|__||__|\_||___,_| \__,_||_____|\___|
                                                      
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./PaymentSplitter.sol";

contract Sharguls is ERC721, Ownable, PaymentSplitter {
  using Strings for uint256;
 
  string public baseURI;
  string public baseExtension = '';
  uint256 public maxSupply = 10000;
  uint256 public totalSupply = 0;
  uint256 public maxMintAmount = 5;
  uint256 public price = 5 ether;
  bool public paused = true;
  mapping(address => bool) internal whitelist;
  uint256 public currentMaxSupply;
  uint256 internal whitelistTimestamp;

  constructor(
    string memory _initBaseURI,
    uint256 _currentMaxSupply,
    address[] memory _payees,
    uint256[] memory _shares
  ) ERC721("Sharguls", "SHGL") PaymentSplitter(_payees, _shares) {
    setBaseURI(_initBaseURI);
    setCurrentMaxSupply(_currentMaxSupply);
  }
 
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public 
  function mint(address _to, uint256 _mintAmount) payable public {
    require(_mintAmount > 0);
    require(totalSupply + _mintAmount <= currentMaxSupply);
    require(totalSupply + _mintAmount <= maxSupply);
 
    if (msg.sender != owner()) {
      require(!paused);
      require(_mintAmount <= maxMintAmount);
      require(msg.value >= price * _mintAmount);
    }
 
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, totalSupply + i);
    }
    totalSupply += _mintAmount;
  }

  function whitelistMint(address _to) public {
    require(!paused);
    require(totalSupply + 2 <= currentMaxSupply, "max supply reached");
    require(whitelist[_to] == true, "You are not whitelisted");
    require(block.timestamp < whitelistTimestamp, "Whitelist mint already closed");

    whitelist[_to] = false;
    
    for (uint256 i = 1; i <= 2 ; i++) {
      _safeMint(_to, totalSupply + i);
    }
    totalSupply += 2;
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
    require(_exists(tokenId), "URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function getWhitelist(address user) public view returns(bool){
      return whitelist[user];
  }
 
  //only owner
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setMaxMint(uint256 _maxMint) public onlyOwner {
    maxMintAmount = _maxMint;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setCurrentMaxSupply(uint256 newCurrentMaxSupply) public onlyOwner {
    currentMaxSupply = newCurrentMaxSupply;
  }

  function addPayee(address account, uint256 shares) public onlyOwner {
    _addPayee(account, shares);
  }

  function removePayee(address account) public onlyOwner {
    _removePayee(account);
  }
  
  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function addWhitelist(address[] memory wallets) public onlyOwner {
    for (uint256 i = 0; i < wallets.length; i++) {
      whitelist[wallets[i]] = true;
    }    
  }

  function setWhitelistTimestamp(uint256 newWhitelistTimestamp) public onlyOwner {
    whitelistTimestamp = newWhitelistTimestamp;
  }
}