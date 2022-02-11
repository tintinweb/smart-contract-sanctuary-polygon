// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract MALETAS is Context, Ownable, ERC721Enumerable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bool public tokenURIFrozen = false;
    string private baseTokenURI;
    string private _contractURI;

    uint256 public max = 400;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    ) ERC721(name, symbol) {
        baseTokenURI = uri;
        _tokenIdTracker.increment();
    }

    function airdrop(address[] memory _address) external onlyOwner {
        uint256 count = _address.length;
        for (uint256 i = 0; i < count; i++) {
            require(_tokenIdTracker.current() <= max, "Max mints have been reached");
            _mint(_address[i], _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        baseTokenURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}