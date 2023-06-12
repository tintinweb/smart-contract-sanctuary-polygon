// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./Ownable.sol";

contract SquetcheNFT is ERC721, Ownable {
    using Strings for uint256;

    //current minted supply
    uint256 public totalSupply;

    //address allowed to mint NFTs
    address public dropperAddress = 0x6d62B07A9B39ec7ddE94a4aFFb55D4359Db2C0Ad;

    //metadatas
    string public baseURI = "https://wagmi.squetche.io/squetche/metadata/polygon/";

    string public contractURI = "https://wagmi.squetche.io/squetche/metadata/contract.json";

    constructor()
    ERC721("Squetche", "SQUETCHE")
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

    function setContractURI(string memory _contractURI) public onlyOwner() {
        contractURI = _contractURI;
    }

}