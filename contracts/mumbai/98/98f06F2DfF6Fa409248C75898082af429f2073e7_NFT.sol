// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Counters.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";


contract NFT is ERC721 {

  using Counters for Counters.Counter;

  Counters.Counter private currentTokenId;

  /// @dev Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;
  mapping (uint256 => string) private _tokenURIs;

  constructor() ERC721("DkNft", "DNFT") {}

  function mint(address recipient, string memory uri) public returns (uint256) {
    currentTokenId.increment();
    uint256 newItemId = currentTokenId.current();
    _tokenURIs[newItemId] = uri;
    _safeMint(recipient, newItemId);
    return newItemId;
  }

  // function _setTokenURI(uint256 _tokenId, string memory _tokenURI) public {
  //   require(_exists(_tokenId), "ERC721Metadata: setTokenURI request for nonexistent token");
  //   require(ownerOf(_tokenId) == msg.sender, "Invalid token owner");
  //   _tokenURIs[_tokenId] = _tokenURI;
  // }

  bool approval = true;

  function setApprovalForAll(bool v) external returns(bool) {
    approval = v;
    return true;
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
    return approval;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return _tokenURIs[tokenId];
  }

}