// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";

contract POPA is ERC721 {
    mapping (address => bool) isOwner;
    uint256 nftCount = 0;

    constructor() ERC721("HashTag", "HT") {
        isOwner[msg.sender] = true;
        _mint(msg.sender, nftCount);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }

    function MintNFT(address mintAddress) onlyOwner public {
        nftCount = nftCount + 1;
        _mint(mintAddress, nftCount);
    }

    function changeTokenURI(string memory newURI) onlyOwner public {
        _baseURI = newURI;
    }

    function addOwner(address ownerAddress) onlyOwner public {
        isOwner[ownerAddress] = true;
    }

    function removeOwner(address ownerAddress) onlyOwner public {
        isOwner[ownerAddress] = false;
    }
}