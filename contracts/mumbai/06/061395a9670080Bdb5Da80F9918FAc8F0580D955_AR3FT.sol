// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Counters.sol";

import "./BaseNFT.sol";

contract AR3FT is BaseNFT {
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIDCounter;

    mapping(address => bool) internal _isAirdroppeds;

    constructor(address firstOwnerProof_)
        BaseNFT("AR3FT", "AR3FT", firstOwnerProof_)
    {}

    function airdrop(address to_) external onlyOwner whenNotPaused {
        require(!_isAirdroppeds[to_], "AR3FT: already airdropped");

        for (uint256 tokenType = 1; tokenType <= 4; tokenType++) {
            uint256 tokenID = _tokenIDCounter.current();

            _mint(to_, tokenID, tokenType);

            _tokenIDCounter.increment();
        }

        _isAirdroppeds[to_] = true;
    }
}