/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

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

// File: POC/matcusd.sol


pragma solidity ^0.8.0;


contract MaticPriceContract {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        // Address of the Matic/USD price feed on the Mumbai testnet
        priceFeed = AggregatorV3Interface(0x0bF499444525a23E7Bb61997539725cA2e928138);
    }

    function getMaticPriceInUSD() external view returns (int256) {
        (, int256 price, , ,) = priceFeed.latestRoundData();
        return price;
    }
}