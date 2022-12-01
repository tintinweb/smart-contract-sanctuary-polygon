// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./AggregatorV3Interface.sol";

contract Formule1 is ERC721, Ownable {

    address public minter;

    uint256 public totalSupply;

    uint256[] public tokenIdsToMint;

    string public baseURI;

    string public collectionURI;

    constructor()
    ERC721("F1TESTEST1 NFT", "F1TESTT")
        {
        }

    //PRE SALE MINT FUNCTIONS

    function mint(address to) external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        uint256 tokenId = tokenIdsToMint[tokenIdsToMint.length-1];
        tokenIdsToMint.pop();
        _mint(to, tokenId);
    }

    function addTokensToMint(uint256[] memory tokenIds) external {
        require(msg.sender==minter||msg.sender==owner(), "not allowed");
        for(uint256 i=0;i<tokenIds.length;i++){
            tokenIdsToMint.push(tokenIds[i]);
        }
    }

    //METADATA URI BUILDER

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) external onlyOwner {
        collectionURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

}