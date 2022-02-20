// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Burnable.sol";
import "Ownable.sol";
import "INonFungibleDomains.sol";

// Burnable, ownable and mintable ERC721 (contract owner can only modify base URI and minter address).
contract NonFungibleDomains is INonFungibleDomains, ERC721Burnable, Ownable {

    // Base URI for tokens.
    string private _customBaseURI;

    // Contract address allowed to mint new tokens.
    address private _minter;

    // Calls ERC721 constructor, sets initial base URI and initial minter contract address.
    constructor (string memory name_, string memory symbol_, string memory baseURI_, address minter_) ERC721(name_, symbol_) {
        _customBaseURI = baseURI_;
        _minter = minter_;
    }

    // Changes base URI.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _customBaseURI = baseURI_;
    }

    // Returns minter address.
    function getMinter() public view returns (address) {
        return _minter;
    }

    // Changes minter address.
    function setMinter(address minter_) public onlyOwner {
        _minter = minter_;
    }

    // Mints specific token when called by minter contract address.
    function mint(address to, uint256 tokenId) public override {
        require(_msgSender() == _minter, "caller is not a minter");
        _mint(to, tokenId);
    }

    // Returns token owner if token exists or zero address otherwise.
    function getPhysicalOwner(uint256 tokenId) public view override returns (address) {
        return _exists(tokenId) ? ownerOf(tokenId) : address(0);
    }

    // See {ERC721-_baseURI}.
    function _baseURI() internal view override returns (string memory) {
        return _customBaseURI;
    }
}