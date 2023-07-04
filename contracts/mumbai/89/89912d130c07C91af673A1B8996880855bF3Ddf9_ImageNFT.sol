/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImageNFT {
    struct Token {
        address owner;
        string tokenURI;
    }

    mapping(uint256 => Token) private tokens;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {}

    function mint(address to, uint256 tokenId) public {
        require(tokens[tokenId].owner == address(0), "Token ID already exists");

        string memory tokenURI = getTokenURIFromAPI(tokenId);
        require(bytes(tokenURI).length > 0, "Failed to fetch tokenURI from API");

        tokens[tokenId] = Token({
            owner: to,
            tokenURI: tokenURI
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

    function getTokenURIFromAPI(uint256 tokenId) internal view returns (string memory) {
        // Native Solidity code to fetch metadata from an API
        // This example uses a static URL for demonstration purposes

        // Define the URL of the API
        string memory apiUrl = "https://api.npoint.io/8c0a6d9914775895aa05";

        // Concatenate the tokenId with the API URL
        string memory tokenUrl = string(abi.encodePacked(apiUrl, uint256ToString(tokenId)));

        // Return the token URL
        return tokenUrl;
    }

    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}