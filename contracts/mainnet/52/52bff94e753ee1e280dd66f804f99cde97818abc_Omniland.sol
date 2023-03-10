// SPDX-License-Identifier: No License
pragma solidity ^0.8.9;

import "./Payout.sol";

contract Omniland is Payout {
    constructor(address _token, address _nft) TokenConfig(_token, _nft) {
        cutoffEntries = 30 * 60; // cutoff race entries after 30 minutes before race
        cutoffWagers = 10 * 60; // cutoff wagers after 10 minutes before race
    }
}