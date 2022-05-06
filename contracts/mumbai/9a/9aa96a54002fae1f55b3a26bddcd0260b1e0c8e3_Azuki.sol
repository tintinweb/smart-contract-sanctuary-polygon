// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Azuki is Ownable, ERC721A, ReentrancyGuard {

  uint256 public immutable MAX_SUPPLY=10000;
  uint256 public immutable maxBatchSize_=100; // declared in ERC721A
  uint256 public immutable maxPerAddressDuringMintAuction=1;
  uint256 public immutable maxPerAddressDuringMintPublic=100;
  uint256 public immutable amountForDevs=100;
  uint256 public immutable amountForAuction=50;
  uint256 public immutable MAX_ALLOW_LIST_MINT=3;

  uint256 public immutable MINT_PRICE_PUBLIC=0.06 ether;
  uint256 public immutable MINT_PRICE_ALLOWLIST=0.05 ether;


  bool public publicSaleActive = false;
  bool public allowListSaleActive = false;
  bool public auctionActive = false;
  uint256 public auctionSaleStartTime=0;
  //bool public revealed = false;
  address private _platformAddress = 0x1591C783EfB2Bf91b348B6b31F2B04De1442836c;
  uint256 private PLATFORM_ROYALTY=200; // 1000 = 100%

  bytes32 private _allowListRoot;
  mapping(address => uint256) private _allowListClaimed;


  // CONSTRUCTOR
  constructor() ERC721A("Azuki", "AZUKI", maxBatchSize_, MAX_SUPPLY){}

  // MODIFIERS
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier onlyPlatform() {
    require(
      _platformAddress == _msgSender(),
      "Ownable: caller is not the platform"
    );
    _;
  }

  modifier onlyOwnerOrPlatform() {
    require(
      owner() == _msgSender() || _platformAddress == _msgSender(),
      "Ownable: caller is not the owner neither the platform"
    );
    _;
  }



  // MINT FUNCTIONS
  function auctionMint(uint256 quantity) external payable callerIsUser {
    require(auctionActive, "sale has not started yet");
    require(
      totalSupply() + quantity <= amountForAuction,
      "not enough remaining for auction"
    );
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMintAuction,
      "can not mint this many"
    );
    uint256 totalCost = getAuctionPrice(auctionSaleStartTime) * quantity;
    require(
      msg.value >= totalCost * quantity,
      "not enough Ether sent"
    );
    _safeMint(msg.sender, quantity);
  }

  function mintAllowList(uint256 numTokens, bytes32[] calldata proof) external payable {
    require(
      Address.isContract(msg.sender) == false,
      "Cannot mint from a contract"
    );
    require(
      _verify(_leaf(msg.sender), proof),
      "Address is not on allowlist"
    );
    require(allowListSaleActive, "The pre-sale is not active");
    require(
      _allowListClaimed[msg.sender] + numTokens <= MAX_ALLOW_LIST_MINT,  // max to mint by 1 address
      "Purchase would exceed max pre-sale tokens"
    );
    uint256 ts = totalSupply();
    require(
      ts + numTokens <= MAX_SUPPLY,
      "Purchase would exceed max tokens"
    );
    require(
      msg.value >= MINT_PRICE_ALLOWLIST * numTokens,
      "not enough Ether sent"
    );

    _allowListClaimed[msg.sender] = _allowListClaimed[msg.sender] + numTokens;
    for (uint256 i = 0; i < numTokens; i++) {
      _safeMint(msg.sender, ts + i);
    }
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser
  {
    require(
      msg.value >= MINT_PRICE_PUBLIC * quantity,
      "not enough Ether sent"
    );
    require(publicSaleActive, "public sale has not begun yet");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(
      quantity <= maxPerAddressDuringMintPublic, // max to mint in 1 Tx
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "can not mint this many"
    );
    require(
      quantity % maxBatchSize_ == 0,
      "can only mint a multiple of the maxBatchSize_"
    );
    uint256 numChunks = quantity / maxBatchSize_;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize_);
    }
  }



  // AUCTION CONFIGURATION
  uint256 public constant AUCTION_START_PRICE = 1 ether;
  uint256 public constant AUCTION_END_PRICE = 0.15 ether;
  uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 340 minutes;
  uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
  uint256 public constant AUCTION_DROP_PER_STEP =
    (AUCTION_START_PRICE - AUCTION_END_PRICE) /
      (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);

  function getAuctionPrice(uint256 _saleStartTime) public view returns (uint256)
  {
    if (block.timestamp < _saleStartTime) {
      return AUCTION_START_PRICE;
    }
    if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
      return AUCTION_END_PRICE;
    } else {
      uint256 steps = (block.timestamp - _saleStartTime) /
        AUCTION_DROP_INTERVAL;
      return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
    }
  }



  // metadata URI
  //string private _baseTokenURI;
  string private _baseTokenURI = string(
    abi.encodePacked(
      "https://easylaunchnft.com/api/",
      "CONTRACT_NAME",
      "/"
    )
  );

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }  
  
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }



  // ONLY OWNER


  //function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
  //  _setOwnersExplicit(quantity);
  //}

  function setPublicSaleActive(bool _publicSaleActive) public onlyOwner {
    publicSaleActive = _publicSaleActive;
  }

  function setAuctionActive(bool _auctionActive) public onlyOwner {
    auctionActive = _auctionActive;
    auctionSaleStartTime = block.timestamp;  // start auction right now
  }

  function setAllowListSaleActive(bool _allowListSaleActive) public onlyOwner {
    allowListSaleActive = _allowListSaleActive;
  }  
  
  //function reveal() public onlyOwner {
  //  revealed = true;
  //}

  function setAllowListRoot(bytes32 _root) public onlyOwner {
    _allowListRoot = _root;
  }

  function withdraw() external onlyOwnerOrPlatform nonReentrant {
    address owner_ = owner();
    uint256 balanceUnits = address(this).balance / 1000;
    Address.sendValue(
        payable(_platformAddress),
        PLATFORM_ROYALTY * balanceUnits
    );
    Address.sendValue(
        payable(owner_),
        (1000 - PLATFORM_ROYALTY) * balanceUnits
    );
  }



  // ALLOW LIST - MERKLE PROOF 
  function _leaf(address account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
  }

  function _verify(bytes32 _leafNode, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, _allowListRoot, _leafNode);
  }

}