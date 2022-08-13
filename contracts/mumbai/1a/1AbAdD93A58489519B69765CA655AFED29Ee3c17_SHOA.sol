// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "Ownable.sol";
import "ERC721Enumerable.sol";

contract SHOA is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.09 ether;
  uint256 public maxSupply = 50;
  uint256 public maxMintAmount = 10;
  bool public saleIsActive = true;
  address public payoutAddress = 0x3D40e6Bb22d2aedAD327E39a740158B9c1A5f156;
  uint256 public publicSaleStart;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    uint256 _publicSaleStart
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setPublicSaleStart(_publicSaleStart);
    mint(msg.sender, 10);
  }
  function callTime() public view returns(uint){
      return block.timestamp;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
 
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    if (msg.sender != owner()) {
        require(saleIsActive, "Not yet active.");
        require(msg.value >= cost * _mintAmount, "Sold out.");
        require(block.timestamp >= publicSaleStart, "Not started");
    }
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    for (uint256 i = 0; i <= _mintAmount - 1; i++) {
      _safeMint(_to, supply + i);
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setPublicSaleStart(uint256 _timestamp) public onlyOwner {
    publicSaleStart = _timestamp;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
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

  function setSaleIsActive(bool _state) public onlyOwner {
    saleIsActive = _state;
  }

  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(payoutAddress).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}