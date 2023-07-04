/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImageNFT {
    address private owner;
    uint256 private tokenIdCounter;
    string private baseTokenURI;

    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => string) private tokenURIs;

    event Minted(address indexed to, uint256 indexed tokenId, string tokenURI);

    constructor(string memory _baseTokenURI) {
        owner = msg.sender;
        tokenIdCounter = 1;
        baseTokenURI = _baseTokenURI;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    function mint(address to, string memory tokenURI) public onlyOwner {
        uint256 tokenId = tokenIdCounter;
        tokenOwners[tokenId] = to;
        tokenURIs[tokenId] = tokenURI;
        tokenIdCounter++;
        emit Minted(to, tokenId, tokenURI);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenOwners[tokenId] != address(0), "Invalid tokenId");
        return tokenURIs[tokenId];
    }
}