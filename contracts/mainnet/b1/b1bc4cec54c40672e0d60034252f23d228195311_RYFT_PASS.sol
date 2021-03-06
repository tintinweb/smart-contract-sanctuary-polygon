// SPDX-License-Identifier: GPL v3.0
// developed by Dinozaver959#2328 (discord), @citizen1525 (twitter)
// Inspired by Azuki Project

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract RYFT_PASS is Ownable, ERC721A, ReentrancyGuard {

  uint256 public immutable MAX_SUPPLY=1000;
  uint256 public immutable MAX_PER_ADDRESS_DURING_MINT=10;
  uint256 public immutable AMOUNT_FOR_DEVS=50;
  uint256 public immutable MINT_PRICE=0.05 ether;

  // sale active flags (default = false)
  bool public publicSaleActive;

  // CONSTRUCTOR
  constructor() ERC721A("ManaManiacsNFT", "MM", 10, 1000){}    // 3rd argument adjust based on the max number of tokens allowed to mint (take in account multipliers), but 10 is not a bad number

  // MODIFIERS
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier onlyTeam() {
    require(
      _msgSender() == owner() || _msgSender() == 0x1591C783EfB2Bf91b348B6b31F2B04De1442836c,  //... add more addresses that will get royalties (fail-safe so that anyone on the team can initiate the withdrawal)
      "Ownable: caller is not the owner neither the platform"
    );
    _;
  }


  // PUBLIC MINT FUNCTIONS
  function publicSaleMint(uint256 numTokens) external payable callerIsUser {
    require(msg.value >= MINT_PRICE * numTokens,"not enough Ether sent");
    require(publicSaleActive, "public sale is not active");
    require(totalSupply() + numTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(numTokens <= MAX_PER_ADDRESS_DURING_MINT,"can not mint this many");
    _safeMint(msg.sender, numTokens);
  }

  // DEV MINT FUNCTIONS - For marketing etc.
  function devMint(uint256 numTokens) external onlyOwner {
    require(totalSupply() + numTokens <= AMOUNT_FOR_DEVS,"can not mint this many");

    uint256 numChunks = numTokens / MAX_PER_ADDRESS_DURING_MINT;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, MAX_PER_ADDRESS_DURING_MINT);
    }

    uint256 left = numTokens % MAX_PER_ADDRESS_DURING_MINT;
    if(left > 0){
      _safeMint(msg.sender, left);
    }
  }



  // metadata URI
  string private _baseTokenURI = "https://app.easylaunchnft.com/api/CONTRACT_NAME/";          // update this,  added paths are:  'rare' and 'common' -> just manually upload them to the IPFS

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
  function setPublicSaleActive(bool _publicSaleActive) public onlyOwner {
    publicSaleActive = _publicSaleActive;
  }

  function withdraw() external onlyTeam nonReentrant {

    address user1=0x1591C783EfB2Bf91b348B6b31F2B04De1442836c;
    uint256 user1_ROYALTY=150;
    address user2=0x1591C783EfB2Bf91b348B6b31F2B04De1442836c;
    uint256 user2_ROYALTY=250;
    address user3=0x1591C783EfB2Bf91b348B6b31F2B04De1442836c;
    uint256 user3_ROYALTY=100;
    address user4=0x1591C783EfB2Bf91b348B6b31F2B04De1442836c;
    uint256 user4_ROYALTY=500;

    uint256 balanceUnits = address(this).balance / 1000;

    Address.sendValue(
      payable(user1),
      user1_ROYALTY * balanceUnits
    );

    Address.sendValue(
      payable(user2),
      user2_ROYALTY * balanceUnits
    );

    Address.sendValue(
      payable(user3),
      user3_ROYALTY * balanceUnits
    );

    Address.sendValue(
      payable(user4),
      user4_ROYALTY * balanceUnits
    );
  }

}