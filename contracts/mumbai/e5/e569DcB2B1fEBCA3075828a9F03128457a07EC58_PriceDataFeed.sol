// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceDataFeed{

    AggregatorV3Interface internal priceBTC;
    AggregatorV3Interface internal priceETH;
    AggregatorV3Interface internal priceMATIC;
    AggregatorV3Interface internal priceUSDC;
    AggregatorV3Interface internal priceLINK;
    AggregatorV3Interface internal priceSNX;
    AggregatorV3Interface internal priceXRP;

    constructor() {
        priceBTC = AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);

        priceETH = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        priceMATIC = AggregatorV3Interface(0x7794ee502922e2b723432DDD852B3C30A911F021);
        
        priceUSDC = AggregatorV3Interface(0xdCA36F27cbC4E38aE16C4E9f99D39b42337F6dcf);

        priceLINK = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);

        priceSNX = AggregatorV3Interface(0xE96C4407597CD507002dF88ff6E0008AB41266Ee);

        priceXRP = AggregatorV3Interface(0xc3E76f41CAbA4aB38F00c7255d4df663DA02A024);
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

    function getLatestPriceSNX() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceSNX.latestRoundData();
        return price;
    }

    function getLatestPriceXRP() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceXRP.latestRoundData();
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