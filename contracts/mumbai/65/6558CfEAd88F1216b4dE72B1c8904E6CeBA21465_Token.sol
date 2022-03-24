// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.10;
import "./ERC721.sol";

contract Token is ERC721 {
    string public name; // ERC721 metadata
    string public symbol; // ERC721 metadata
    uint256 public tokenCount;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // ERC721 metadata
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0)); 
        return _tokenURIs[tokenId];
    }

    function mint(string memory _tokenURI) public {
        tokenCount++;
        _balances[msg.sender]++;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI;
        emit Transfer(address(0), msg.sender, tokenCount);
    }

    function supportInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return interfaceId == 0x5b5e139f;
    }
}