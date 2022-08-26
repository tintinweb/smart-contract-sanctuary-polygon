// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract RecoupAgent {
  function getETHPerUSD()public view returns(int256){
    address _base = 0xF9680D99D6C9589e2a93a78A04A279e509205945;
    ( , int256 basePrice, , , ) = AggregatorV3Interface(_base).latestRoundData();
    uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
    basePrice = basePrice / int256(10**baseDecimals);
    return basePrice;
  }
  function getJPYPerUSD()public view returns(int256){
    address _base = 0xD647a6fC9BC6402301583C91decC5989d8Bc382D;
    ( , int256 basePrice, , , ) = AggregatorV3Interface(_base).latestRoundData();
    uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
    basePrice = basePrice / int256(10**baseDecimals);
    return basePrice;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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