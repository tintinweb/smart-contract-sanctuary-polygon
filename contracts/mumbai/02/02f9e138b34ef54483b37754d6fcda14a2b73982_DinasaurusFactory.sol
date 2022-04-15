// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract DinasaurusFactory is ERC721 {
    string public name;
    string public symbol;
    uint256 public tokenCount;
    mapping(uint256 => string) private _tokenUris; // token ID -> uri

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function tokenUri(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "No Token ID"); // _owners inherited from ERC721.sol
        return _tokenUris[tokenId];
    }

    function mint(string memory _tokenUri) public {
        tokenCount++;
        _balances[msg.sender]++;
        _owners[tokenCount] = msg.sender;
        _tokenUris[tokenCount] = _tokenUri;

        emit Transfer(address(0), msg.sender, tokenCount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
}