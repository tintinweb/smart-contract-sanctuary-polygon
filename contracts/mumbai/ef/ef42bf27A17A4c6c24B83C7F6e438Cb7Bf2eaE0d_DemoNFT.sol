// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Counters.sol";

import "./BaseNFT.sol";

contract DemoNFT is BaseNFT {
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIDCounter;

    mapping(address => bool) internal _isAirdroppeds;

    constructor(address firstOwnerProof_)
        BaseNFT("Demo NFT", "DEMONFT", firstOwnerProof_)
    {}

    function airdrop(address to_)
        external
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        require(!_isAirdroppeds[to_], "DemoNFT: already airdropped");

        uint256 tokenID = _tokenIDCounter.current();

        _mint(to_, tokenID, 0);
        _isAirdroppeds[to_] = true;

        _tokenIDCounter.increment();

        return tokenID;
    }
}