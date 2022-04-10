// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {

    string baseUri = "https://ipfs.io/ipfs/Qmd2apB3eD2hXPuzNat8cD25CETjQDNHDCeWNjr1infRVG/";
    uint256 tokenCount;

    function safeMint(address to, string memory uri)
        public
        onlyOwner
    {
        tokenCount += 1;
        _safeMint(to, tokenCount);
        _setTokenURI(tokenCount, uri);
    }

    // The following functions are overrides required by Solidity.

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
}