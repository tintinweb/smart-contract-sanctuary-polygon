//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

import "./ERC721.sol";

contract HauDev is ERC721 {
    string public name; // ERC721 metadata
    string public symbol; // ERC721 metadata

    uint256 public tokenCount;

    mapping(uint256 => string) private _tokenURIs;

    constructor (string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns(string memory){  // trả về URI của tokenId
        require(_owners[tokenId] != address(0), "Token ID does not exist");
        return _tokenURIs[tokenId];
    }

    function mint() public {
        tokenCount += 1; //tokenID
        string memory mockTokenURI = "https://madlads.s3.us-west-2.amazonaws.com/json/9966.json";

        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = mockTokenURI;

        emit Transfer(address(0), msg.sender, tokenCount);

    }
    function supportInterface(bytes4 interfaceId) public pure override returns(bool){
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
}