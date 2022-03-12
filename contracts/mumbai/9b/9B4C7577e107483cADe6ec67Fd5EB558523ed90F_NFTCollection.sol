//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";

contract NFTCollection is ERC721 {
    string public name; //ERC721 metadata
    string public symbol; //ERC721 metadata
    mapping(uint256 => string) private _tokenURIs;
    uint256 public tokenCount;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // tokenURI la dia chi URI cua cai anh ban muon mint
    function tokenURI(uint256 tokenID) public view returns (string memory) {
        require(_owners[tokenID] != address(0), "Token ID does not exist");
        return _tokenURIs[tokenID];
    }

    function mint(string memory _tokenURI) public {
        tokenCount += 1; // tokenID
        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI;
        emit Transfer(address(0), msg.sender, tokenCount);
    }

    function supportInterface(bytes4 interfaceID)
        public
        pure
        override
        returns (bool)
    {
        return interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }
}