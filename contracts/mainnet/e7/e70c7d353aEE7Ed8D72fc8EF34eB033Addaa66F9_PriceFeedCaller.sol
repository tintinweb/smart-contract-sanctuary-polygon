/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// File: contracts/polygon/PriceFeedCaller.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IContractPriceFeed {
    function getPriceByTimestamp(string memory _tokenPair, int256 _timestamp) external view returns (int256);
}

contract PriceFeedCaller {
    
    IContractPriceFeed PriceFeed;

    constructor() {
        PriceFeed = IContractPriceFeed(0x4717dc3b5A39cf4F3E7d89746A3Ad881258EA4E5);
    }

    function priceByTimestamp(string memory _tokenPair, int256 _timestamp) public view returns (int256) {
        return PriceFeed.getPriceByTimestamp(_tokenPair, _timestamp);
    }
}