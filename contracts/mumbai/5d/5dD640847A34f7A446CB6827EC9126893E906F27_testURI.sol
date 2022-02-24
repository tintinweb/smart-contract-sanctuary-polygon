// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./testLib.sol";

contract testURI is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    event inTransfer(uint256 indexed _tokenId, string msg);

    constructor(bytes3[16] memory _hex) ERC721("testURI", "tURI") {
        bytes3[16] memory hexnum = _hex;
    }

    function newToken() public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        return newItemId;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI)
        public
        returns (string memory)
    {
        _setTokenURI(tokenId, tokenURI);
        string memory test = testLib.printTest();
        return test;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId);
        string
            memory emitInTransfer = "Transfer was made in safe mode with this event added";
        emit inTransfer(tokenId, emitInTransfer);
    }
}