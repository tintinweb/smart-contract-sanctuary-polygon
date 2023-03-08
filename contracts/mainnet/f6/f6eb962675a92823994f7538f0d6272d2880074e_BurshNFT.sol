// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract BurshNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string private _uri;

    constructor(string memory _url) ERC721("Bursh2NFT", "B2NFT") {
        _uri = _url;
    }

    function _setURI(string memory newuri) external onlyOwner {
        _uri = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function multipleSafeMint(uint256 _numOfTokens) external onlyOwner {
        for (uint256 i = 0; i < _numOfTokens; i++) {
            safeMint(msg.sender, '');
        }
    }

    function transferOwner(
        uint256 tokenId,
        address from,
        address to
    ) external onlyOwner {
        _transferOwner(from, to, tokenId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}