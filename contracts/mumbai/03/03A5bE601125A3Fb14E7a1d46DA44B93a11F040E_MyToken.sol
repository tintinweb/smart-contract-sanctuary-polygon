// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Developer = Solii.sol (Soheil Vafaei 🐱‍👤)

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract MyToken is ERC721, ERC721URIStorage, Ownable {

    // Base URI
    string baseUri = "https://ipfs.io/ipfs/QmfP4UQHc5F6h5YtvsKFcvWhLZ67GKZMCEtcGkHePzJMb7/";

    // save tokenID
    uint256 tokenCount;

    // mint function 
    function safeMint()
        public
        onlyOwner
    {
        tokenCount += 1;
        _safeMint(_msgSender() , tokenCount);
    }

    // The following functions are overrides required by Solidity.

    // burn function 
    function _burn(uint256 tokenId) 
    internal override
    (ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
    }

    // view token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}