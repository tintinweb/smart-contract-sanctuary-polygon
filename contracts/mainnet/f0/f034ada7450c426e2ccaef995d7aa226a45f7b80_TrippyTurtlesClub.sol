// SPDX-License-Identifier: MIT

/*
 ______  ____   ____  ____  ____  __ __      ______  __ __  ____  ______  _        ___  _____
|      ||    \ |    ||    \|    \|  |  |    |      ||  |  ||    \|      || |      /  _]/ ___/
|      ||  D  ) |  | |  o  )  o  )  |  |    |      ||  |  ||  D  )      || |     /  [_(   \_ 
|_|  |_||    /  |  | |   _/|   _/|  ~  |    |_|  |_||  |  ||    /|_|  |_|| |___ |    _]\__  |
  |  |  |    \  |  | |  |  |  |  |___, |      |  |  |  :  ||    \  |  |  |     ||   [_ /  \ |
  |  |  |  .  \ |  | |  |  |  |  |     |      |  |  |     ||  .  \ |  |  |     ||     |\    |
  |__|  |__|\_||____||__|  |__|  |____/       |__|   \__,_||__|\_| |__|  |_____||_____| \___|
                                                                                                                                                                    
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract TrippyTurtlesClub is ERC721, Ownable {
  using Strings for uint256;
 
  string public baseURI;
  string public baseExtension = '';
  uint256 public maxSupply = 10000;
  uint256 public totalSupply = 0;
  uint256 public maxMintAmount = 5;
  bool public paused = true;
  mapping(address => uint256) internal withdrawalShares;
  mapping(uint256 => bool) internal claimedBitMap;
  address[] public withdrawalAddresses;
  bytes32 public MERKLE_ROOT;
  uint256 internal phase1amount = 700;
  uint256 internal phase2amount = 1200;
  uint256 internal phase3amount = 2500;
  uint256 internal phase4amount = 7500;
  uint256 internal pricePhase1 = 10 ether;
  uint256 internal pricePhase2 = 15 ether;
  uint256 internal pricePhase3 = 20 ether;
  uint256 internal pricePhase4 = 25 ether;

  constructor(
    string memory _initBaseURI,
    bytes32 _MERKLE
  ) ERC721("Trippy Turtles Club", "TTC") {
    setBaseURI(_initBaseURI);
    setMerkleRoot(_MERKLE);
  }
 
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public 
  function mint(address _to, uint256 _mintAmount) payable public {
    require(_mintAmount > 0);
    require(totalSupply + _mintAmount <= maxSupply);
 
    if (msg.sender != owner()) {
      require(!paused);
      require(_mintAmount <= maxMintAmount);
      uint256 singlePrice = price();
      require(singlePrice != 0); 
      require(msg.value >= singlePrice * _mintAmount);
    }
 
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, totalSupply + i);
    }
    totalSupply += _mintAmount;
  }

  function freeMintPhase(address _to, uint256 index, bytes32[] memory proof) public {
    require(!paused);
    require(totalSupply + 2 <= maxSupply, "max supply reached");
    require(!claimedBitMap[index], "index already claimed");
    require(totalSupply <= phase1amount);

    bytes32 node = keccak256(abi.encodePacked(index, _to));
    require(MerkleProof.verify(proof, MERKLE_ROOT, node), 'MerkleDistributor: Invalid proof.');
    claimedBitMap[index] = true;
    
    for (uint256 i = 1; i <= 2; i++) {
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

  function checkClaimed(uint256 index) public view returns (bool){
      return claimedBitMap[index];
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

  function price() public view returns(uint256) {
    if(totalSupply > phase4amount) return 25 ether;
    else if(totalSupply > phase3amount) return 20 ether;
    else if(totalSupply > phase2amount) return 15 ether;
    else if(totalSupply > phase1amount) return 10 ether;
    else return 0;
  }
 
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    for (uint256 i = 0; i < withdrawalAddresses.length; i++) {
      uint256 userShare = withdrawalShares[withdrawalAddresses[i]];
      payable(withdrawalAddresses[i]).transfer(balance * userShare / 100);
    }
  }

  function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
    MERKLE_ROOT = _newMerkleRoot;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setPhaseAmount(uint256 phase, uint256 amount) public onlyOwner{
    if(phase == 1) phase1amount = amount;
    else if(phase == 2) phase2amount = amount;
    else if(phase == 3) phase3amount = amount;
    else if(phase == 4) phase4amount = amount;
  }

  function setPhasePrice(uint256 phase, uint256 _price) public onlyOwner{
    if(phase == 1) pricePhase1 = _price;
    else if(phase == 2) pricePhase2 = _price;
    else if(phase == 3) pricePhase3 = _price;
    else if(phase == 4) pricePhase4 = _price;
  }

  function setWithdrawalAddresses(address[] memory _addresses, uint256[] memory _share) public onlyOwner{
    require(_addresses.length == _share.length);
    withdrawalAddresses = _addresses;
    for (uint256 i = 0; i < _share.length; i++) {
      withdrawalShares[_addresses[i]] = _share[i];
    }
  }
}