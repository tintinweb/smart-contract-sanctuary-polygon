// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC1155Supply.sol";
import "./Strings.sol";
import "./Whitelist.sol";

contract GFC_Collabs is ERC1155Supply, Whitelist {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) internal _tokenUriMapping;

    constructor(string memory path) ERC1155(path){}

    function airdrop(address[] calldata wallets, uint256 tokenId) external isWhitelisted {
        for (uint256 i = 0; i < wallets.length; i++) {
            _mint(wallets[i], tokenId, 1, "");
        }
    }

    function batchAirdrop(uint256 tokenId, address[] calldata wallets, uint256[] calldata amounts) external isWhitelisted {
        for (uint256 i = 0; i < wallets.length; i++) {
            _mint(wallets[i], tokenId, amounts[i], "");
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory _tokenURI = _tokenUriMapping[tokenId];
        
        //return tokenURI if it is set
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        string memory baseURI = ERC1155.uri(tokenId);
        //If tokenURI is not set, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function name() external pure returns (string memory) {
        return "GFC Collabs";
    }

    function symbol() external pure returns (string memory) {
        return "GFCCollabs";
    }

    /*
     * Only the owner can do these things
     */

    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        require(exists(tokenId), "ERC1155 Supply: URI set of nonexistent token");
        _tokenUriMapping[tokenId] = _tokenURI;
    }
}