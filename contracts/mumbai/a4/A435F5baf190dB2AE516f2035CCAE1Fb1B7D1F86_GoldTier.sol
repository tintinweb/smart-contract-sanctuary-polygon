// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GoldTier is Ownable, ERC721A{

    string private _baseTokenURI;
    uint256 public totalMint;
    
    constructor() ERC721A("Third Wave Club Gold", "TWCG") {
      totalMint=9500;
    }

  function mint(uint256 quantity) external onlyOwner payable {
    // _safeMint's second argument now takes in a quantity, not a tokenId.
    require(totalSupply()+quantity <=totalMint,"can't mint ");
    _safeMint(msg.sender, quantity);
  }
 
   function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
}