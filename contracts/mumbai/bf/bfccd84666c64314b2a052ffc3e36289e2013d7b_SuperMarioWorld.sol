// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.2;

import "./ERC721.sol";

contract SuperMarioWorld is ERC721 {
    string public name; // ERC721 Metadata
    string public symbol; // ERC721 Metadata
    uint256 public tokenCount; // ERC721 Metadata
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // Returns a URL that points to the metadata
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_owners[_tokenId] != address(0), "TokenID does not exist");
        return _tokenURIs[_tokenId];
    }

    // Creates a new NFT inside our collection
    function mint(string memory _tokenURI) public {
        tokenCount += 1; // tokenId
        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI;

        emit Transfer(address(0), msg.sender, tokenCount);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
}