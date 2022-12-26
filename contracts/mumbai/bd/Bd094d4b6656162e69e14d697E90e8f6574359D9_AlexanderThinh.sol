//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";

contract AlexanderThinh is ERC721 {
    string public name; // ERC721 metadata
    string public symbol; // ERC721 metadata
    uint256 public tokenCount;

    mapping(uint256 => string) private tokenURIs; // return URI's tokenID

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // return URI's tokenID where we save NFT's metadata for FE get data and show
    function tokenURI(uint256 _tokenID) public view returns(string memory) { // ERC721 metadata
        // Check if token exist?
        address _owner = owner[_tokenID];
        require(_owner != address(0), "Error: Token ID doesn't exist");

        return tokenURIs[_tokenID];
    }   

    // Mint NFT
    function mint(string memory _tokenURI) public {
        tokenCount += 1; // ~ tokenID
        balances[msg.sender] += 1;
        owner[tokenCount] = msg.sender;
        tokenURIs[tokenCount] = _tokenURI;

        emit Transfer(address(0), msg.sender, tokenCount);
    }

    // EIP165 proposal 
    // Function support when we wanna deploy NFT to Open Sea
    function supportInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }
}