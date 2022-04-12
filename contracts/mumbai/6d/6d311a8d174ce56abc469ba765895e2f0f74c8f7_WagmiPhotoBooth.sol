// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract WagmiPhotoBooth is ERC721, Ownable {
    using Strings for uint256;

    //current minted supply
    uint256 public totalSupply;

    //metadatas
    string public baseURI = "https://server.wagmi-studio.com/photo/nft/pbws2022/";

    constructor()
    ERC721("Wagmi-Studio Photo Booth PBWS 2022", "Wagmi PB")
        {
        }

    function drop(address targetAddress, uint256 tokenId) external onlyOwner {
        _mint(targetAddress, tokenId);
        totalSupply++;
    }

     function burn(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId) || msg.sender == owner());
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