// SPDX-License-Identifier: None
pragma solidity ^0.8.9;

import "./ERC721.sol";



contract TuIT is ERC721{
    string public name; // ERC721 metadata
    string public symbol; // ERC721 metadata
    uint256 tokenCount;
    // tokenURI: trả về đường dẫn lưu URI của metadata của NFT (frontend lấy metadata và show lên)
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns(string memory){ // ERC721 metadata
        require(ownerOf(tokenId) != address(0),"Token ID does not exist");
        return _tokenURIs[tokenId];
    }
    
    function mint(string memory _tokenURI) public{
        tokenCount++;
        _balances[msg.sender] = tokenCount;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI;

        emit Transfer(address(0), msg.sender, tokenCount);
    }

    // implement hàm này để mấy thằng như opensea biết mình đúng chuẩn
    function supportsInterface(bytes4 interfaceID) public pure override returns(bool){
         return interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }

}