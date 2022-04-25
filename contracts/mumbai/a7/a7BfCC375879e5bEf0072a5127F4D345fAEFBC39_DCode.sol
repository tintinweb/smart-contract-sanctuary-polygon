// developer : Solii.sol (soheil vafaei👽)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";

contract DCode is ERC1155 {

    string public name = "DCode";

    string public symbol = "DCE";
    
    uint256 public tokenCount;

    address owner = 0x0742491E2De3bef002F878511223DCE6F9522DD5;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    mapping(uint256 => string) private _tokenURIs;

    function uri(uint256 tokenId) public view returns(string memory) {
        return _tokenURIs[tokenId];
    }

    function mint( uint256 amount) public onlyOwner{
        require(msg.sender != address(0), "Mint to the zero address");
        tokenCount += 1;
        _balances[tokenCount][msg.sender] += amount;
        emit TransferSingle(msg.sender, address(0), msg.sender, tokenCount, amount);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
        return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }

    function setTokenURI (uint tokenId, string memory tokenURI) public 
    {
        _tokenURIs[tokenId] = tokenURI;
    }
}