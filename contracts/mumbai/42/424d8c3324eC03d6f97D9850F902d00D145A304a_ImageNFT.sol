/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImageNFT {
    struct Token {
        address owner;
        string tokenURI;
        string photoURL;
    }

    mapping(uint256 => Token) private tokens;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(address to, uint256 tokenId, string memory tokenURI, string memory photoURL) public {
        require(tokens[tokenId].owner == address(0), "Token ID already exists");

        tokens[tokenId] = Token({
            owner: to,
            tokenURI: tokenURI,
            photoURL: photoURL
        });

        emit Transfer(address(0), to, tokenId);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = tokens[tokenId].owner;
        require(owner != address(0), "Invalid tokenId");
        return owner;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokens[tokenId].owner != address(0), "Invalid tokenId");
        return tokens[tokenId].tokenURI;
    }

    function getPhotoURL(uint256 tokenId) public view returns (string memory) {
        require(tokens[tokenId].owner != address(0), "Invalid tokenId");
        return tokens[tokenId].photoURL;
    }
}