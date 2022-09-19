/**
 *Submitted for verification at polygonscan.com on 2022-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoingeckoBNBOracle {
    uint256 public bnbUsdPrice;
    uint256 private lastUpdated;

    event PriceUpdated(uint256 indexed timeStamp, uint256 price);

    function updatePrice(uint256 _price) external {
        bnbUsdPrice = _price;
        lastUpdated = block.timestamp;

        emit PriceUpdated(block.timestamp, _price);
    }

    function getLastUpdated() external view returns(uint256) {
        return lastUpdated;
    }
}