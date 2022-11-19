// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceDataFeed{

    AggregatorV3Interface internal priceBTC;
    AggregatorV3Interface internal priceETH;
    AggregatorV3Interface internal priceMATIC;
    AggregatorV3Interface internal priceUSDC;
    AggregatorV3Interface internal priceLINK;

    constructor() {
        priceBTC = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b);

        priceETH = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
        
        priceMATIC = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        
        priceUSDC = AggregatorV3Interface(0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0);

        priceLINK = AggregatorV3Interface(0x1C2252aeeD50e0c9B64bDfF2735Ee3C932F5C408);

    }

    function getLatestPriceBTC() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceBTC.latestRoundData();
        return price;
    }

    function getLatestPriceETH() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceETH.latestRoundData();
        return price;
    }

    function getLatestPriceMATIC() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceMATIC.latestRoundData();
        return price;
    }

    function getLatestPriceUSDC() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceUSDC.latestRoundData();
        return price;
    }

    function getLatestPriceLINK() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceLINK.latestRoundData();
        return price;
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