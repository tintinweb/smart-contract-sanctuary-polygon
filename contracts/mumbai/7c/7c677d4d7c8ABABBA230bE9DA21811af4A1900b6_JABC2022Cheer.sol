// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Counters.sol";

import "./BaseNFT.sol";

contract JABC2022Cheer is BaseNFT {
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIDCounter;

    mapping(address => bool) internal _isAirdroppeds;

    constructor(address firstOwnerProof_)
        BaseNFT(
            "Japan Amateur Baseball Championship 2022 Cheer",
            "JABC2022C",
            firstOwnerProof_
        )
    {}

    function airdrop(address to_)
        external
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        require(!_isAirdroppeds[to_], "JABC2022Cheer: already airdropped");

        uint256 tokenID = _tokenIDCounter.current();

        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp,
                    tokenID
                )
            )
        ) % 100;

        uint256 tokenType;
        if (rand < 9) {
            tokenType = 1; // 9%
        } else if (rand < 24) {
            tokenType = 2; // 15%
        } else if (rand < 44) {
            tokenType = 3; // 20%
        } else if (rand < 70) {
            tokenType = 4; // 26%
        } else {
            tokenType = 5; // 30%
        }

        _mint(to_, tokenID, tokenType);
        _isAirdroppeds[to_] = true;

        _tokenIDCounter.increment();

        return tokenID;
    }
}