// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Royalty.sol";
import "./Ownable.sol";

contract Ukraine is ERC721Royalty, Ownable {

    uint256 public MAX_NFTS;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply) ERC721(name, symbol) {
        MAX_NFTS = maxNftSupply;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(address[] memory to, uint256[] memory tokenId) public onlyOwner {
        require(to.length == tokenId.length, "to and tokenId length mismatch");
        for(uint256 i = 0; i < to.length; i++) {
            mint(to[i], tokenId[i]);
        }
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        require(tokenId < MAX_NFTS, "Cannot exceed max supply of NFTs");
        _safeMint(to, tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function totalSupply() public view returns (uint256) {
        return MAX_NFTS;
    }
}