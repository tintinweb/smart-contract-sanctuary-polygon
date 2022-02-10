// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract Name is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("MyName", "MNM") {}

    function mint() public returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(_msgSender(), newItemId);
        _setTokenURI(newItemId, append("https://localhost:1234/token/", newItemId));

        return newItemId;
    }

    function append(
        string memory a,
        uint b
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}