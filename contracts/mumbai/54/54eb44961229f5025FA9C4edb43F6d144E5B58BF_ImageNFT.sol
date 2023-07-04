/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImageNFT {
    mapping(uint256 => string) private tokenURIs;

    event Minted(address indexed to, uint256 indexed tokenId, string tokenURI);

    function mint(uint256 tokenId, string memory tokenURI) public {
        require(bytes(tokenURI).length > 0, "Token URI cannot be empty");
        require(bytes(tokenURIs[tokenId]).length == 0, "Token ID already exists");

        tokenURIs[tokenId] = tokenURI;
        emit Minted(msg.sender, tokenId, tokenURI);
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(bytes(tokenURIs[tokenId]).length > 0, "Invalid tokenId");
        return tokenURIs[tokenId];
    }
}