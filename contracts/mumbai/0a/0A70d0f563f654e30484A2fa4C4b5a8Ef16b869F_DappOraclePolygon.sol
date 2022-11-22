/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
// import "hardhat/console.sol";

contract DappOraclePolygon {
    uint public lastUsdDappPrice;
    uint lastUpdateTime;

    constructor(uint _lastUsdDappPrice) {
        // USD/DAPP means how much DAPP for 1 USD
        lastUsdDappPrice = _lastUsdDappPrice;
        lastUpdateTime = block.timestamp;
    }

    function updatePrice(uint _lastUsdDappPrice) external {
        require(block.timestamp >= lastUpdateTime + 1 days, "last call <24 hours");
        require(_lastUsdDappPrice > 0, "> 0");
        lastUsdDappPrice = (lastUsdDappPrice * 13 + _lastUsdDappPrice) / 14; // TWAP
        lastUpdateTime = block.timestamp;
    }
}