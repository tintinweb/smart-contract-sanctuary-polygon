// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract PictomatoNFT is ERC721, Ownable {
    using Strings for uint256;

    //current minted supply
    uint256 public totalSupply;

    //address allowed to mint NFTs
    address public dropperAddress;

    //metadatas
    string public baseURI = "https://app-cc57572c-f22c-45ed-b1af-db913b236717.cleverapps.io/pictomato/metadata/";

    constructor()
    ERC721("Pictartatin test 2", "POMME 2")
        {
        }

    function setDropperAddress(address _dropperAddress) external onlyOwner {
        dropperAddress = _dropperAddress;
    }

    function drop(address targetAddress, uint256 tokenId) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "sender not allowed");
        _mint(targetAddress, tokenId);
        totalSupply++;
    }

    
    function burn(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId) || msg.sender == owner()|| msg.sender == dropperAddress);
        _burn(tokenId);
        totalSupply--;
    }
    
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }


}