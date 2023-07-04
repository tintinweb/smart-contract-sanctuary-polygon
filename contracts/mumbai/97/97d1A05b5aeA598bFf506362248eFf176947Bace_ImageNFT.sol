/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImageNFT {
    address private owner;
    mapping(uint256 => string) private tokenURIs;

    event Minted(address indexed to, uint256 indexed tokenId, string tokenURI);

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner, "Only the owner can set a new owner");
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

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