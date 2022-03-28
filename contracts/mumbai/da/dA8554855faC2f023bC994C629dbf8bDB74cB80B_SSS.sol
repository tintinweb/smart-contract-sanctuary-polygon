pragma solidity ^0.8.4;

import "./ERC721.sol";

contract SSS is ERC721 {

    string public name;

    string public symbol;

    uint256 public tokenCount;

    mapping(uint256 => string) private _tokenURIs;

    constructor() {
        name = "ss";
        symbol = "dr";
    }

    function uri(uint256 tokenId) public view returns(string memory) {
        return _tokenURIs[tokenId];
    }

    function mint(string memory _uri) public {
        require(msg.sender != address(0), "Mint to the zero address");
        tokenCount += 1;
        _tokenURIs[tokenCount] = _uri;
        emit Transfer(address(0), msg.sender, tokenCount);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
        return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }

}