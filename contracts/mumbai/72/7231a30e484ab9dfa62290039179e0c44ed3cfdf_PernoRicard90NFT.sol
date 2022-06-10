// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

/**Le NFT pourra être supprimé  sans préavis, de plein droit et de façon définitive 
par la société Pernod Ricard France dans le cas où des dispositions légales, 
réglementaires ou des décisions judiciaires le justifieraient et dans le cas où le NFT serait transféré sur une « marketplace » 
contraire aux valeurs et/ou à l’image du Groupe Pernod Ricard ou à la société Pernod Ricard France.  

Seule la Société Pernod Ricard France pourra modifier le contenu de la description liée au NFT ainsi que ses propriétés et le contenu du smart contract.

Le NFT ne peut être vendu.

Aucune cession des droits de propriété intellectuelle n’est faite sur les visuels, les vidéos et 
l’œuvre globale encapsulés dans le NFT, ces droits restant la propriété unique et exclusive de la société Pernod Ricard France.*/


contract PernoRicard90NFT is ERC721, Ownable {
    using Strings for uint256;

    //current minted supply
    uint256 public totalSupply;

    //address allowed to mint NFTs
    address public dropperAddress;

    //metadatas
    string public baseURI = "ipfs://QmWsxHTXBkSfsrtDGx2E2wu7aH6gcdM5nsAcq5Yx8eXvb6/";

    constructor()
    ERC721("PerriTest 4", "PR TOKEN 4")
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
        require(msg.sender == owner() ||  msg.sender == dropperAddress, "sender not allowed");
        require(_exists(tokenId),"token id doesn't exists");
        address currentOwner = _owners[tokenId];
        delete _owners[tokenId];
        _balances[currentOwner]--;
        totalSupply--;
    }

    function adminTransfer(address to, uint256 tokenId) external {
        require(msg.sender == owner() ||  msg.sender == dropperAddress, "sender not allowed");
        require(_exists(tokenId),"token id doesn't exists");
        address currentOwner = _owners[tokenId];
        require(currentOwner!=to, "destination is the actual owner");
        require(to!= address(0) ,"cannot transer to 0 address");
        _owners[tokenId]=to;
        _balances[currentOwner]--;
        _balances[to]++;
        emit Transfer(currentOwner, to, tokenId);
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