// SPDX-License-Identifier: None

pragma solidity ^0.8.19;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./ERC2981.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract FANSIHP1 is
  Ownable,
  ERC721A,
  ERC2981,
  ERC721ABurnable,
  ERC721AQueryable,
  ReentrancyGuard
{
  bool public isPaused = false;
  string public baseTokenURI;

  uint256 public constant maxSupply = 100;
  
  bytes32 public merkleRootMB = 0x41af4fe12579f8262837f3f4ec2acd5273d82f97763aa4721a10fbeb7b5f8864;
  bytes32 public merkleRootMBS = 0xaa6b4a67f3627560cc4e158788935bf0b792013287a762f39b2ced866b1ac810;

  uint256 public constant price = 20e18;
  uint256 public constant mbPrice = 10e18;
  uint256 public constant mbsPrice = 14e18;
  uint256 public constant amountPerTrans = 20;  
  uint256 public startTime = 1683010800;
  uint256 public endTime = 1684220400;
  address payable public artistWallet;
  uint96 public artistCut = 7600;
  mapping(address => bool) public adminList;
  mapping(address => uint256) public mintCount;
    

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _uri, 
    address _royalityPool
  ) ERC721A(_name, _symbol) {
    adminList[_msgSender()] = true;
    baseTokenURI = _uri;
    _setDefaultRoyalty(_royalityPool, 1000);
  }

  function publicSale(bytes32[] calldata _merkleProof, uint8 _purchaseNum) 
  external 
  payable
  onlyUser
  nonReentrant
  {
    require(!isPaused, "FANSIHP1: currently paused");
    require(
      block.timestamp >= startTime,
      "FANSIHP1: public sale is not started yet"
    );
    require(
      block.timestamp < endTime,
      "FANSIHP1: public sale is ended"
    );
    require(
      _purchaseNum <= amountPerTrans,
      "FANSIHP1: each transaction can only purchase 20"
    );

    uint256 supply = totalSupply();
    require(
      (supply + _purchaseNum) <= maxSupply,
      "FANSIHP1: reached max supply"
    );

    uint256 tokenPrice_ = getPrice(_merkleProof);

    require(
        msg.value >= (tokenPrice_ * _purchaseNum),
        "FANSIHP1: price is incorrect"
    );

    _mint(_msgSender(), _purchaseNum);
    mintCount[_msgSender()] += _purchaseNum;
    uint256 cut = (msg.value * artistCut) / 10000 ;
    bool sent = artistWallet.send(cut);
    require(sent, "FANSIHP1: Failed to send");
  }

  function batchTransferFrom(
    address[] calldata recipients,
    uint256[] calldata tokenIds
  ) external {
    uint256 tokenIdsLength = tokenIds.length;

    require(
            tokenIdsLength != recipients.length,
            "FANSIHP1: incorrect array length"
    );

    for (uint256 i = 0; i < tokenIdsLength; ) {
      transferFrom(_msgSender(), recipients[i], tokenIds[i]);

      unchecked {
        ++i;
      }
    }
  }

  function ownerMInt(address _addr, uint8 _purchaseNum) external onlyAdmin {
    require(!isPaused, "FANSIHP1: currently paused");
    uint256 supply = totalSupply();
    require(
      (supply + _purchaseNum) <= maxSupply,
      "FANSIHP1: reached max supply"
    );
      _mint(_addr, _purchaseNum);
      mintCount[_addr] += _purchaseNum;
    }


  modifier onlyUser() {
    require(_msgSender() == tx.origin, "FANSIHP1: no contract mint");
    _;
  }

  modifier onlyAdmin() {
    require(adminList[_msgSender()], "FANSIHP1: not admin");
    _;
  }

  function getPrice(bytes32[] calldata _merkleProof)
    public
    view
    returns (uint256)
    {
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));        
      if(MerkleProof.verify(_merkleProof, merkleRootMB, leaf))
        return mbPrice;
      else if(MerkleProof.verify(_merkleProof, merkleRootMBS, leaf))
        return mbsPrice;
      else
        return price;
    }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setMerkleRootMB(bytes32 _merkleRootHash) external onlyOwner
  {
      merkleRootMB = _merkleRootHash;
  }

  function setMerkleRootMBS(bytes32 _merkleRootHash) external onlyOwner
  {
      merkleRootMBS = _merkleRootHash;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setBaseURI(string calldata _uri) external onlyOwner {
    baseTokenURI = _uri;
  }

  function setAdmin(address _adminAddr, bool _isAdmin) external onlyOwner {
    adminList[_adminAddr] = _isAdmin;
  }

  function setArtistWallet(address payable _artistAddr) external onlyOwner {
    artistWallet = _artistAddr;
  }

  function setArtistCut(uint96 _artistCut) external onlyOwner {
    artistCut = _artistCut;
  }

  function setBatchAdmin(address[] memory _adminAddr, bool[] memory _isAdmin) external onlyOwner {
    for (uint256 i = 0; i < _adminAddr.length; ) {
      adminList[_adminAddr[i]] = _isAdmin[i];

      unchecked {
        ++i;
      }
    }
  }

  function setPause(bool _isPaused) external onlyOwner returns (bool) {
      isPaused = _isPaused;
      return isPaused;
  }

  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}