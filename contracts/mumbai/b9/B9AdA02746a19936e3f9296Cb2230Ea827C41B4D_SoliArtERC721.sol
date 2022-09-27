// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SoliArtERC721 is ERC721URIStorage , Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(string memory name_ , string memory symbol_) ERC721(name_ , symbol_){}

    function mint(string memory _tokenURI)public onlyOwner returns(uint256){
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);

        _setTokenURI(tokenId, _tokenURI);

        return tokenId;
    }

}