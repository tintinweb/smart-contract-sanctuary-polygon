// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract Artcare is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public notRevealedUri;
  uint256 public cost = 0.006 ether;
  uint256 public maxSupply = 50000;
  uint256 public maxMintAmount = 1;
  uint256 public nftPerAddressLimit = 3;
  bool public paused = false;
  bool public revealed = false;
  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
      uint256 ownerMintedCount = addressMintedBalance[msg.sender];
      require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
      require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
      require(msg.value >= cost * _mintAmount, "insufficient funds");    
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function airdrop(address payable to, uint256 amount) public payable onlyOwner{
    uint256 supply = totalSupply();
    require(supply  <= maxSupply, "max NFT limit exceeded");

    for (uint256 i = 1; i <= amount; i++) {
      addressMintedBalance[to]++;
      _safeMint(to, supply + i);
    }
  } 

  function walletOfOwner(address _owner)
  public
  view
  returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if(revealed == false) {
      return bytes(notRevealedUri).length > 0
      ? string(abi.encodePacked(notRevealedUri, tokenId.toString(),".json"))
      : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),".json"))
      : "";
  }

  //only owner
  function reveal() public onlyOwner {
    revealed = true;
  }

  function airdropTo(address wallet, uint256 nb_NFT) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + nb_NFT <= maxSupply, "max NFT limit exceeded");
    for (uint256 i = 1; i <= nb_NFT; i++) {
      addressMintedBalance[wallet]++;
      _safeMint(wallet, supply + i);
    }
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setmaxSupply(uint256 _newmaxSupply) public onlyOwner {
    maxSupply = _newmaxSupply;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw(uint256 _partial) public payable onlyOwner {
    uint256 _total = address(this).balance / _partial;
    (bool artcare, ) = payable(0x9ba109EE14F5AC66ce4A19C7B5c27C2F73B7c952).call{value: _total}("");
    require(artcare);
  }
}