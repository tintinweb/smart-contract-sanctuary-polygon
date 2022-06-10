// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract PernoRicard90NFT is ERC721, Ownable {
    using Strings for uint256;

    //current minted supply
    uint256 public totalSupply;

    //address allowed to mint NFTs
    address public dropperAddress;

    //metadatas
    string public baseURI = "ipfs://QmWsxHTXBkSfsrtDGx2E2wu7aH6gcdM5nsAcq5Yx8eXvb6/";

    constructor()
    ERC721("PerriTest 1", "PR TOKEN 1")
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
    function adminTransfer(address to, uint256 tokenId) external {
        require(msg.sender == owner() ||  msg.sender == dropperAddress, "sender not allowed");
        require(_exists(tokenId),"token id doesn't exists");
        address currentOwner = _owners[tokenId];
        require(currentOwner!=to, "destination is the actual owner");
        _owners[tokenId] = to;
        if(to==address(0)){
            _balances[to] = _balances[to]-1;
            totalSupply = totalSupply-1;
        }else{
            _balances[to] = _balances[to]+1;
            totalSupply = totalSupply+1;
        }
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