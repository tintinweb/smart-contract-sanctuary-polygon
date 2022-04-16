// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract LeapToTheFuture is ERC721, Ownable {
    using Strings for uint256;

    //max supply
    uint256 public MAX_SUPPLY = 3210;

    //current minted supply
    uint256 public totalSupply;

    //metadatas
    string public baseURI = "ipfs://QmX85MboewJ6LUqscrGyjENwesxyHAq9S6r5asKSq8Xvrc/";

    constructor()
    ERC721("Leap To The Future by Wagmi Studio", "WAGMI LEAP")
        {
        }

    function drop(address targetAddress) external onlyOwner {
        require(totalSupply<MAX_SUPPLY, "supply limit reached");
        _mint(targetAddress, totalSupply++);
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