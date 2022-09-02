// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract Cupckie is ERC721, ERC721Enumerable, ERC721URIStorage{

    constructor() ERC721("Cupckie", "CUP") {}

    function safeMint(uint256 start, uint256 end, string memory uri) public{
        for(uint256 i = start; i <= end; i++){
            string memory fullUri = string(abi.encodePacked(uri, Strings.toString(i), ".json"));
            _safeMint(msg.sender, i);
            _setTokenURI(i, fullUri);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}