// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./Counters.sol";

contract abenturtain is Context, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    bool public tokenURIFrozen = false;
    string private baseTokenURI;
    string public contractURI = "";
    uint256 public max = 3;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri,
        string memory contractURI_
    ) ERC721(name, symbol) {
        baseTokenURI = uri;
        contractURI = contractURI_;
        _tokenIdTracker.increment();
    }

    function mint() public onlyOwner {
        require(
            _tokenIdTracker.current() <= max,
            "Collection max size has been reached"
        );
        _safeMint(_msgSender(), _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        baseTokenURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
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
}