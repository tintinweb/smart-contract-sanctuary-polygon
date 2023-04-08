// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MyToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
        safeMint(msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeibkwiwpu2645f32uowydes3sv6c24ptwnqxwdafplmb2ujxs3aitq";
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
}