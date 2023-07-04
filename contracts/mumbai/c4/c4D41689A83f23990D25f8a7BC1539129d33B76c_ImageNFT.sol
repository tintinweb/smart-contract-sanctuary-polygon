/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImageNFT {
    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => string) private tokenURIs;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event TokenURIUpdated(uint256 indexed tokenId, string tokenURI);

    function mint(address to, uint256 tokenId, string memory tokenURI) public {
        require(tokenOwners[tokenId] == address(0), "Token ID already exists");

        tokenOwners[tokenId] = to;
        tokenURIs[tokenId] = tokenURI;

        emit Transfer(address(0), to, tokenId);
        emit TokenURIUpdated(tokenId, tokenURI);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = tokenOwners[tokenId];
        require(owner != address(0), "Invalid tokenId HE");
        return owner;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenOwners[tokenId] != address(0), "Invalid tokenId");
        return tokenURIs[tokenId];
    }
}