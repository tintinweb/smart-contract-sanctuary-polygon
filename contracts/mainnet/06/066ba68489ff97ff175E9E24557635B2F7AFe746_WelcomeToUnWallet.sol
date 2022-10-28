// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Counters.sol";

import "./BaseNFT.sol";

contract WelcomeToUnWallet is BaseNFT {
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIDCounter;

    mapping(address => bool) internal _isAirdroppeds;

    constructor(address firstOwnerProof_)
        BaseNFT("Welcome to unWallet", "WELCOME", firstOwnerProof_)
    {}

    function airdrop(address to_) external onlyMinter whenNotPaused {
        require(!_isAirdroppeds[to_], "WelcomeToUnWallet: already airdropped");

        _isAirdroppeds[to_] = true;

        uint256 tokenID = _tokenIDCounter.current();

        _mint(to_, tokenID, 0);

        _tokenIDCounter.increment();
    }
}