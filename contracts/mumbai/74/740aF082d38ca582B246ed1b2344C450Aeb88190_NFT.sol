pragma solidity ^0.8.2;

import "./ERC721.sol";

contract NFT is ERC721 {
    string public name; // ERC721 metaData;
    string public symbol; // ERC721 metaData;
    uint public tokenCount;

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenID) public view returns(string memory) { // ERC721 metaData;
        require(_owner[tokenID] != address(0), "token does not exists");
        return _tokenURIs[tokenID];
    }

    function mint(string memory _tokenURI) public {
        tokenCount += 1; // tokenID
        _banlance[msg.sender] += 1;
        _owner[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI;

        emit Transfer(address(0), msg.sender,tokenCount);
    } 

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }   
}