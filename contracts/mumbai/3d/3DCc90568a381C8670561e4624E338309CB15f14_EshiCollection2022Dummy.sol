// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Counters.sol";

import "./BaseNFT.sol";

contract EshiCollection2022Dummy is BaseNFT {
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIDCounter;

    constructor() BaseNFT("Eshi Collection 2022 DUMMY", "EC2022DUMMY") {}

    function airdropByType(address to_, uint256 tokenType_)
        external
        onlyMinter
        whenNotPaused
    {
        uint256 tokenID = _tokenIDCounter.current();

        _mint(to_, tokenID, tokenType_);

        _tokenIDCounter.increment();
    }
}