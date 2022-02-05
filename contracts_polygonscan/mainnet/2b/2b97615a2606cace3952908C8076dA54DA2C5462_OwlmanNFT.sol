// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract OwlmanNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 2 ether;
  uint256 public maxSupply = 5555;
  uint256 public onlyLeft;
  bool public paused = false;
  address public lastWinner;
  address payable public payments;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address _payments
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    payments = payable(_payments);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(supply + mintAmount <= maxSupply);

    if (msg.sender != owner()) {
 // require(msg.value >= cost);

     if(supply < 1111){
      onlyLeft = 1111 - supply;
      require (onlyLeft >= mintAmount); 
      require(msg.value >= 2 ether * mintAmount);
     }

    if(1111 <= supply && supply < 2222){
      onlyLeft = 2222 - supply;
      require (onlyLeft >= mintAmount); 
      require(msg.value >= 4 ether * mintAmount);
     }

    if(2222 <= supply && supply < 3333){
      onlyLeft = 3333 - supply;
      require (onlyLeft >= mintAmount); 
      require(msg.value >= 6 ether * mintAmount);
     }

    if(3333 <= supply && supply < 4444){
      onlyLeft = 4444 - supply;
      require (onlyLeft >= mintAmount); 
      require(msg.value >= 8 ether * mintAmount);
     }

    if(4444 <= supply && supply < 5555){
      onlyLeft = 5555 - supply;
      require (onlyLeft >= mintAmount); 
      require(msg.value >= 10 ether * mintAmount);
     }
    

    address payable giftAddress = payable(msg.sender);
    uint256 giftValue = 0;

    if(supply > 0) {
        giftAddress = payable(ownerOf(randomNum(supply, block.timestamp, supply + mintAmount) + mintAmount)); 
        lastWinner = giftAddress;
        giftValue = supply + mintAmount == maxSupply ? address(this).balance * 10 / 100 : msg.value * 10 / 100; 
    } 

  for (uint256 i = 1; i <= mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    
    if(supply > 0) {
        ( bool success, ) = payable(giftAddress).call{value: giftValue}("");
        require(success);

    }

    }else {

  for (uint256 i = 1; i <= mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }

    }



  }

  function randomNum(uint256 _mod, uint256 _seed, uint256 _salt) public view returns(uint256) {
      uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
      return num;
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

   //return the lastWinner

  function getLastWinner() public view returns(address) {
      return lastWinner;
  } 
   
  //only owner

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
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
        (bool success, ) = payable(payments).call{value: address(this).balance}("");
    require(success);
  }
}