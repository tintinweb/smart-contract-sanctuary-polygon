// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract TrustedAgencyCertificate is ERC721, Ownable {
    using Strings for uint256;

    //current minted supply
    uint256 public totalSupply;

    //metadatas
    string public baseURI = "ipfs://QmbvciCH9MtCexMRhAyCwQqWtLK26zuDRW1muhyQdfK8TC/";

    constructor()
    ERC721("qTest Kovvv", "Kov10422")
        {
        }

    function setName(string memory name) external onlyOwner {
        _name = name;
    }

    function setSymbol(string memory symbol) external onlyOwner {
        _symbol = symbol;
    }

    function drop(address targetAddress, uint256 tokenId) external onlyOwner {
        _mint(targetAddress, tokenId);
        totalSupply++;
    }

     function burn(uint256 tokenId) external onlyOwner {
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