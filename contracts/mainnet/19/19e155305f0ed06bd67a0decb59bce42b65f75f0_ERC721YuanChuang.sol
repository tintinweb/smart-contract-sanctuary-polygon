// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ERC721YuanChuang is ERC721Enumerable, Ownable {

  using Strings for uint256;

  address public factory;

  string private baseURI;

  constructor() {
    factory = msg.sender;
  }

  function initialize(string memory name_, string memory symbol_,string memory _uri, address _owner) external {
    require(msg.sender == factory, 'ERC721YuanChuang: FORBIDDEN');
    _name = name_;
    _symbol = symbol_;
    baseURI = _uri;
    _transferOwnership(_owner);
  }


  // public
  function mint(address owner,uint256 id) public onlyOwner {
    _safeMint(owner,id);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    return currentBaseURI;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

}