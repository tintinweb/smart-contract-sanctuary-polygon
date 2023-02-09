// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract CryptoPunk is ERC721, ERC721Burnable, Ownable {
    constructor() ERC721("CryptoPunk", "CPT") {}

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}