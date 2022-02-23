// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./WhitelistAdminRole.sol";
import "./Ownable.sol";
import "./WhitelistAdminRole.sol";


contract NFT is ERC721Enumerable, Ownable, WhitelistAdminRole {
    using Strings for uint256;

    mapping(uint256 => string) _tokenURIs;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}


    function mint(address to, string memory _tokenURI) public onlyWhitelistAdmin {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function addWhitelistAdmin(address account) public onlyOwner {
        _addWhitelistAdmin(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked("ipfs://", _tokenURI));
        }

        return "";
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }
}