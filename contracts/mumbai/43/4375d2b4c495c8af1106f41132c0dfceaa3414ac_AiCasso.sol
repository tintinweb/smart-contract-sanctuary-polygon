// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IAiCassoNFTStaking.sol";
import "./ERC2981ContractWideRoyalties.sol";

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
    _mint(address(0xC0a7227819C3e253c73037d8ec0E0782018dE893), 274, '', false);
    _mint(address(0x03c3a50132Ade4600Eb522927e6bc038833251Ef), 76, '', false);
    _mint(address(0x4D4aFeDb99924E9Bcadd8D316770041E586A08EA), 53, '', false);
    _mint(address(0xfAB97f628fdCAd65aa67dF39f9EB0eaf075b636D), 19, '', false);
    _mint(address(0x8797B4Ee93B987f606E3DBeCcc9103EC3d32b2D6), 10, '', false);
    _mint(address(0x0E5e74B274cbf68dECaaec85240805D35C9361DF), 7, '', false);
    _mint(address(0xED2e2c5385d5242fCf71E3671458Ce849EE2c9E7), 6, '', false);
    _mint(address(0xB8ad1597a6795F45237e99438035885AA2A8F769), 5, '', false);
    _mint(address(0x463ecf308dF1061Dc8c36e48c46993b6C523a51f), 4, '', false);
    _mint(address(0x2D1CaB1B697Ba0eb1FfEF9653D3e29B8c631D847), 4, '', false);
    _mint(address(0x9010995cC801d8897e969ADB7e3C86b30bf70353), 4, '', false);
    _mint(address(0x7B5D762BCFD3303bca1fcE30CD3Bc4D416D85757), 3, '', false);
    _mint(address(0x39b2eC93f9296Cbf272aFc3f132DCD669aB61f8F), 3, '', false);
    _mint(address(0x925e716073e15905218264e66Da4Db1147D10a8c), 2, '', false);
    _mint(address(0xebd746FEF9952aeC908DF471b65aCE4E05210ADB), 2, '', false);
    _mint(address(0x8A6ea1e51Ce90F02A8CB94db9721B31355769000), 2, '', false);
    _mint(address(0x30F24484b383655150D5b767b68A891E215B8881), 2, '', false);
    _mint(address(0xb2fe488641228Ea847DECD2776E1E40ff0B37783), 2, '', false);
    _mint(address(0xc7aCaCd1f7790Cd06B5b88413777c6c055C892b3), 2, '', false);
    _mint(address(0x91B85C0aD32f7711fF142771896126ca91Ce522a), 1, '', false);
    _mint(address(0x88c31f648bDbC89ecdfBaBE18b5A800E63ed8eE6), 1, '', false);
    _mint(address(0x689a185c6181Bee755bb824dE547e159D87245aD), 1, '', false);
    _mint(address(0x413158AC3D89DE2716Cc169a219ccBF8a8d3295B), 1, '', false);
    _mint(address(0x4C293D1F0bbb8fB6762f325D250B3582cd0EdAd0), 1, '', false);
    _mint(address(0xD515b88473D9310e63eD6a201Ca79D45E2803536), 1, '', false);
    _mint(address(0x70fadd97fd7513901c566c3C94A2c68f96F59b5f), 1, '', false);
    _mint(address(0x12f6F95Fdd25A9530d7B149B81dc1351baFDdB82), 1, '', false);
    _mint(address(0xb66fd793beBb6D1a3Eb2a5c33b82090a976244F9), 1, '', false);
    _mint(address(0xD13F5ab20CEa9A47B6D92BE737513e7A67926f7a), 1, '', false);
    _mint(address(0x765DFeA3054841351C5603BC7Fc9822aF72AddfD), 1, '', false);
    _mint(address(0xa84546e35B27933F83596838EE958615B7062196), 1, '', false);
    _mint(address(0xb026f92820EbFe16E88132468b32a149D0626b7B), 1, '', false);
    _mint(address(0x9d48176B453d58d163baf8C9B9F884A4AB64B55f), 1, '', false);
    _mint(address(0xe08707eAe41b7a8213175Af061254eE8154A8Fbc), 1, '', false);
    _mint(address(0x648213045D8c2c373cc40F73E13c67C8e0Ff81Bc), 1, '', false);
    _mint(address(0x1EFd12b8e01337CCd4839f9580Fc685C202f1702), 1, '', false);
    _mint(address(0x35065b4a23719CB0D8eB5fF4578374b8E8F423C9), 1, '', false);
    _mint(address(0x9B14e5E96f45995ae74fF491924398A5b02869c4), 1, '', false);
    _mint(address(0xb18A551aeEc4069C85Fe7651C145C6b08e9Ab23e), 1, '', false);
    _mint(address(0xCf6CA3d4155f99e5262c85f1d8ED207a3625E929), 1, '', false);
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
      uint256 _tokenId = tokenOfOwnerByIndex(msg.sender, (balanceOf(msg.sender) - 1));
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