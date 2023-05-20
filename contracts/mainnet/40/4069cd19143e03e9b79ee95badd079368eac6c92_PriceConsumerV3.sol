// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
contract PriceConsumerV3{
    AggregatorV3Interface public priceFeed;
    constructor(){
        priceFeed = AggregatorV3Interface(0x18E4058491C3F58bC2f747A9E64cA256Ed6B318d);
    }
    function getLatestPrice() public view returns (int){
        (,int latestRoundData,,,) = priceFeed.latestRoundData();
        return latestRoundData;
    }
    function getDecimals() public view returns (uint8){
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }
}