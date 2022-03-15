// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IAiCassoNFTStaking.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./IERC721Enumerable.sol";

contract AiCasso is
ERC721A,
Ownable,
ERC2981ContractWideRoyalties
{
  using Strings for uint256;

  enum Status { SALE_NOT_LIVE, SALE_LIVE }

  uint256 public constant SUPPLY_MAX = 10_000;
  uint256 public constant GENERATOR_SUPPLY_MAX = 10_000;
  uint256 public WHITELIST_PRICE = 0.95 ether;
  uint256 public PRICE = 0.001 ether;

  Status public state;
  bool public revealed;
  string public baseURI;

  mapping(address => bool) public whitelist;
  mapping(uint256 => string) private _generatorImage;

  address private _generator;
  address private _stake;
  uint256 private totalGeneratorSupply;
  string private baseGeneratorURI;

  modifier onlyGenerator() {
    require(_generator == msg.sender);
    _;
  }

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  constructor() ERC721A("AiCasso V2", "AiC") {
    _mint(address(this), 1, '', false);
    _mint(address(0x6cf0B584E90679EAa3766aCDCDb5904d719e20b7), 274, '', false);
    _burn(0);
  }

  function setGeneratorContract(address generator) external onlyOwner {
    require(generator != address(0), "AiCasso: Can't add the null address");
    _generator = generator;
  }

  function setStakeContract(address stakeContract) external onlyOwner {
    require(stakeContract != address(0), "AiCasso: Can't add the null address");
    _stake = stakeContract;
  }

  function purchase(uint256 quantity) external payable {
    require(state == Status.SALE_LIVE, "AiCasso: Sale Not Live");
    require(msg.sender == tx.origin, "AiCasso: Contract Interaction Not Allowed");
    require(totalSupply() + quantity <= SUPPLY_MAX, "AiCasso: Exceed Max Supply");
    require(quantity <= 10, "AiCasso: Exceeds Max Per TX");

    if(whitelist[msg.sender]) {
      require(msg.value >= WHITELIST_PRICE * quantity, "AiCasso: Insufficient ETH");
    } else {
      require(msg.value >= PRICE * quantity, "AiCasso: Insufficient ETH");
    }

    _safeMint(msg.sender, quantity);
  }

  function mintGenerator(string memory uri, address buyer) external onlyGenerator {
    require(totalGeneratorSupply < GENERATOR_SUPPLY_MAX, "AiCasso: All tokens have been minted");
  unchecked {
    totalGeneratorSupply += 1;
    _generatorImage[_currentIndex] = uri;
  }
    _safeMint(buyer, 1);
  }

  function stake(uint256 quantity) external {
    require(_stake != address(0), "AiCasso: Stake Not Active");
    require(quantity <= balanceOf(msg.sender));

  unchecked {
    while(quantity > 0) {
      quantity--;
      uint256 _tokenId = IERC721Enumerable(address(this)).tokenOfOwnerByIndex(msg.sender, (IERC721Enumerable(address(this)).balanceOf(msg.sender) - 1));
      IAiCassoNFTStaking(_stake).stake(_tokenId, msg.sender);
      transferFrom(
        msg.sender,
        _stake,
        _tokenId
      );
    }
  }
  }

  function setSaleState(Status _state) external onlyOwner {
    state = _state;
  }

  function updateBaseURI(string memory newURI, bool reveal) external onlyOwner {
    baseURI = newURI;
    if(reveal) {
      revealed = reveal;
    }
  }

  function updateGeneratorBaseURI(string memory newURI) external onlyOwner {
    baseGeneratorURI = newURI;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (!revealed) return _baseURI();

    if (bytes(_generatorImage[tokenId]).length != 0) {
      return bytes(baseGeneratorURI).length != 0 ? string(abi.encodePacked(baseGeneratorURI, _generatorImage[tokenId])) : _generatorImage[tokenId];
    }

    return string(abi.encodePacked(_baseURI(), tokenId.toString()));
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setPrice(uint256 _price, uint256 _wl_price) external onlyOwner {
    require(_price >= 0.01 ether);
    require(_wl_price >= 0.01 ether);
    PRICE = _price;
    WHITELIST_PRICE = _wl_price;
  }

  function addAddressToWhitelist(address user) onlyOwner public returns(bool success) {
    if (!whitelist[user]) {
      whitelist[user] = true;
      emit WhitelistedAddressAdded(user);
      success = true;
    }
  }

  function addAddressesToWhitelist(address[] calldata users) onlyOwner external returns(bool success) {
  unchecked {
    for (uint256 i = 0; i < users.length; i++) {
      if (addAddressToWhitelist(users[i])) {
        success = true;
      }
    }
  }
  }

  function removeAddressFromWhitelist(address user) onlyOwner public returns(bool success) {
    if (whitelist[user]) {
      whitelist[user] = false;
      emit WhitelistedAddressRemoved(user);
      success = true;
    }
  }

  function removeAddressesFromWhitelist(address[] calldata users) onlyOwner external returns(bool success) {
  unchecked {
    for (uint256 i = 0; i < users.length; i++) {
      if (removeAddressFromWhitelist(users[i])) {
        success = true;
      }
    }
  }
  }

  function setRoyalties(address recipient, uint256 value) onlyOwner external {
    _setRoyalties(recipient, value);
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC721A, ERC2981Base)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}