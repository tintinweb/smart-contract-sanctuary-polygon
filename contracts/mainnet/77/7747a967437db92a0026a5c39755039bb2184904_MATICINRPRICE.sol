/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// SPDX-License-Identifier: MIT


// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: contracts/MATICINRPRICE.sol


pragma solidity ^0.8.7;


contract MATICINRPRICE{
    AggregatorV3Interface internal inrUsdFeed;
    AggregatorV3Interface internal maticUsdFeed;
/**
     * Network: Polygon Matic Mainnet
     * Aggregator: INR/USD
     * Address: 0xDA0F8Df6F5dB15b346f4B8D1156722027E194E60
     * Aggregator: MATIC/USD
     * Address: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
     */
    constructor() {
        inrUsdFeed = AggregatorV3Interface(0xDA0F8Df6F5dB15b346f4B8D1156722027E194E60);
        maticUsdFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
    }

    function calculateMATICINRPrice() public view returns (int) {
        // Retrieve latest prices for INR/USD and MATIC/USD
        (, int inrUsdPrice, , , ) = inrUsdFeed.latestRoundData();
        (, int maticUsdPrice, , , ) = maticUsdFeed.latestRoundData();

        // Retrieve number of decimal places for INR/USD and MATIC/USD
        uint8 inrUsdDecimals = inrUsdFeed.decimals();
        uint8 maticUsdDecimals = maticUsdFeed.decimals();

        // Divide prices by 10^decimals to get actual prices
        uint inrUsdActualPrice = uint(inrUsdPrice) / (10 ** inrUsdDecimals);
        uint maticUsdActualPrice = uint(maticUsdPrice) / (10 ** maticUsdDecimals);

        // Calculate MATIC/INR price
        int maticInrPrice = int(maticUsdActualPrice / inrUsdActualPrice);

        return maticInrPrice;
    }
}