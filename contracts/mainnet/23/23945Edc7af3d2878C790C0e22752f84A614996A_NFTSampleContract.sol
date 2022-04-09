// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./MerkleProof.sol";
import './Strings.sol';

/*
* ERC721A Clarifications:
* - used to optimize mint prices,
* - burn functionality is internal and not exposed nor used in this contract, therefore it cannot be used.
*/
contract NFTSampleContract is ERC721A, Ownable, IERC2981 {
  
  // EVENTS -----
  event Revealed(); // will be called when metadata are revealed
  // -----

  // MINT -----
  uint256 public _price = 0.25 ether; // mint price per one
  uint256 public _quantityPerMintMax = 2; // how many max you mint in each mint
  uint256 public _totalSupply = 100;
  // -----

  // ROYALTIES -----
  uint256 public _royaltiesPercent = 5;
  address public _royaltyReceiver;  
  // -----

  // METADATA -----
  // Full URI to the unrevealed placeholder.
  string public _unrevealedURI;
  // Base URI for our revealed images and metadata.
  string public _revealedURI;
  // -----

  // WHITELIST -----
  bytes32 public _merkleRoot;
  mapping(address => bool) public _whitelistUsed;  
  // -----
  
  constructor() ERC721A("Shapes", "SHAPES") Ownable() {
      _unrevealedURI = "https://gateway.pinata.cloud/ipfs/QmcWnxD7hNWAXaVYM9A3DahpJUpPHVHsY8daee8pTZ9TST";
      _royaltyReceiver = msg.sender;
      _currentIndex = 0;
  }

  /// METADATA -----

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
      string memory baseURI = _baseURI();
      bytes memory uriBytes = bytes(baseURI);
      // return unrevealed URI if baseURI has length zero
      return uriBytes.length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : _unrevealedURI;
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() override internal view virtual returns (string memory) {
      return _revealedURI;
  }

  /**
  * Allows the contract owner to set the reveal base URI.
  * This also serves as the reveal function, until the revealedURI is set default unrevealed URI will be used instead.
  */
  function reveal(string memory revealURI) external onlyOwner {
      _revealedURI = revealURI;
      emit Revealed();
  }

  // -----

  // WHITELIST -----
  /**
  * Activates the whitelist mint - until this is called, nobody apart from the owner can mint.
  */
  function setWhitelistRoot(bytes32 root) external onlyOwner {
      _merkleRoot = root;
  } 
  // -----

  /**
  * Allows the team to mint NFTs for project partners, moderators, etc.
  * Unlike some other NFTs, the option for the contract owner to mint more than the total supply is not here.
  */
  function partnerMint(address to, uint256 quantity) external onlyOwner {
      require(_currentIndex + quantity < _totalSupply, "Cannot mint more tokens than total supply!");
      _safeMint(to, quantity);
  }

  /**
  * Public mint function.
  * Each whitelist-approved wallet will have a proof generated and stored in our API.
  * When the mint comes, our web3 minting application will fetch the proof for the given address and provide it in the
  * mint function call.
  */
  function mint(bytes32[] calldata merkleProof, uint quantity) external payable {
    require(quantity <= _quantityPerMintMax, "Quantity per mint limit reached");
    require(_currentIndex + quantity < _totalSupply, "Cannot mint more tokens than total supply!");
    require(!_whitelistUsed[msg.sender], "This address has already minted!");
    require(msg.value >= quantity * _price, "Insufficient funds in transaction.");

    // check if the proof sent in the mint function (from our web3 app, fetched from our API) is consistent with the provided root
    // this prevents non-whitelisted users from minting
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "Invalid proof, your address may not be whitelisted.");
    _whitelistUsed[msg.sender] = true;
    
    _safeMint(msg.sender, quantity);
  }

  // ROYALTIES -----
  
  /**
  * NFT royalty standard implementation.
  */
  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
      require(_exists(tokenId), "Non-existent token");
      return (_royaltyReceiver, salePrice *_royaltiesPercent / 100);
  }
  
  /**
  * Allows contract owner to change royalty percentage.
  */
  function setRoyaltyPercent(uint256 percentage) public onlyOwner {
      _royaltiesPercent = percentage;
  }
  
  /**
  * Specify the ETH wallet address to send royalties to.
  * By default the royalty address is the creator of the contract.
  */
  function setRoyaltyAddress(address royaltyAddress) public onlyOwner {
      _royaltyReceiver = royaltyAddress;
  }
  
  /**
  * Allows the owner of the contract to withdraw royalties.
  */
  function withdraw() public onlyOwner {
      uint256 withdrawBalance = address(this).balance;
      (bool success, ) = owner().call{value: withdrawBalance}("");
      require(success, "Could not withdraw royalties");
  }

  // ------

  // MISC ------  
  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
      return interfaceId == type(IERC2981).interfaceId          ||
            interfaceId == type(IERC721).interfaceId            ||
            interfaceId == type(IERC721Metadata).interfaceId    ||
            interfaceId == type(IERC721Enumerable).interfaceId  ||
            super.supportsInterface(interfaceId);
  }
  // -----
}