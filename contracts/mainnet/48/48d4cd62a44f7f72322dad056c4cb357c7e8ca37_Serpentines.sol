// SPDX-License-Identifier: MIT
/////////////////////////////////////////////
//                                         //
//                                         //
//    555555555555555555     1111111       //
//    5::::::::::::::::5    1::::::1       //
//    5::::::::::::::::5   1:::::::1       //
//    5:::::555555555555   111:::::1       //
//    5:::::5                 1::::1       //
//    5:::::5                 1::::1       //
//    5:::::5555555555        1::::1       //
//    5:::::::::::::::5       1::::l       //
//    555555555555:::::5      1::::l       //
//                5:::::5     1::::l       //
//                5:::::5     1::::l       //
//    5555555     5:::::5     1::::l       //
//    5::::::55555::::::5  111::::::111    //
//     55:::::::::::::55   1::::::::::1    //
//       55:::::::::55     1::::::::::1    //
//         555555555       111111111111    //
//                                         //
//                                         //
/////////////////////////////////////////////

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Serpentines is ERC721Enumerable, Ownable {
  using Strings for uint256;
 
  bool public paused = true;
  bool public allowlistPaused = false;
  string public baseURI;
  string public baseExtension;
  uint256 public maxSupply;
  uint256 public mintableSupply;
  bytes32 public merkleRoot;
  uint256 public price;
  uint256 public maxPerTransaction;


  constructor(
    string memory _initBaseURI,
    string memory _initBaseExtension,
    bytes32 _merkleRoot
  ) ERC721("Serpentines", "SERP") {
      setBaseURI(_initBaseURI);
      setBaseExtension(_initBaseExtension);
      setMerkleRoot(_merkleRoot);
      setMintableSupply(0);
      setPrice(5.1 ether);
      maxSupply = 10000;
      maxPerTransaction = 10;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _baseExtension() internal view virtual returns (string memory) {
    return baseExtension;
  }

  function _mintableSupply() internal view virtual returns (uint256) {
    return mintableSupply;
  }

  function _price() internal view virtual returns (uint256) {
      return price;
  }

  function exists(uint256 tokenId) external view returns (bool) {
      return _exists(tokenId);
  }

  function mint(address _to, uint256 quantity) external payable {
    require(!paused, "Paused");
    require(totalSupply() + quantity <= _mintableSupply(), "Exceeds mintable supply");
    require(totalSupply() + quantity <= maxSupply, "Exceeds max supply");
    require(quantity <= maxPerTransaction, "Exceeds max per transaction");
    if (msg.sender != owner()) {
      require(msg.value >= price * quantity);
    }
    for (uint256 i = 0; i < quantity; i++) {
      _mint(_to, totalSupply() + 1);
    }
  }

  function allowlistMint(address _to, uint256 quantity, bytes32[] calldata proof) external payable {
    require(!allowlistPaused, "Paused");
    uint256 mintable = _mintableSupply();
    require(totalSupply() + quantity <= mintable, "Exceeds mintable supply");
    require(totalSupply() + quantity <= maxSupply, "Exceeds max supply");
    require(quantity <= maxPerTransaction, "Exceeds max per transaction");
    if (msg.sender != owner()) {
      require(msg.value >= price * quantity);
    }
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid allowlist address");
    for (uint256 i = 0; i < quantity; i++) {
      _mint(_to, totalSupply() + 1);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "URI query for nonexistent token");

      string memory currentBaseURI = _baseURI();
      string memory currentBaseExtension = _baseExtension();
      return bytes(currentBaseURI).length > 0 
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), currentBaseExtension))
        : "";
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setMintableSupply(uint256 _supply) public onlyOwner {
    require(_supply <= maxSupply, "Exceeds max supply");
    mintableSupply = _supply;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
      merkleRoot = _merkleRoot;
  }

  function setPaused(bool _paused) public onlyOwner {
      paused = _paused;
  }

  function setAllowlistPaused(bool _paused) public onlyOwner {
      allowlistPaused = _paused;
  }

  function setPrice(uint256 _newprice) public onlyOwner {
      price = _newprice;
  }

  function withdraw() public onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}