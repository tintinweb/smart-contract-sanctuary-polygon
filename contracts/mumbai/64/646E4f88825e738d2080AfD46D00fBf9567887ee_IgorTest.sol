// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721.sol";
import "ownable.sol";

contract IgorTest is ERC721, Ownable {
    constructor() ERC721("Igor Proskochylo", "IPF") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://sked.mobi/";
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}