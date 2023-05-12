/**
 *Submitted for verification at polygonscan.com on 2023-05-12
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

// File: contracts/PriceConsumerV3.sol


pragma solidity ^0.8.0;



contract PriceConsumerV3 {
    AggregatorV3Interface internal MaticpriceFeed;
    AggregatorV3Interface internal UsdtpriceFeed;

    /**
     * Network: Mumbai
     * Aggregator: Matic/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada

     * Aggregator: USDT/USD
     * Address: 0x92C09849638959196E976289418e5973CC96d645

     */
    constructor() {
        MaticpriceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        UsdtpriceFeed = AggregatorV3Interface(
            0x92C09849638959196E976289418e5973CC96d645
        );

    }


    /**
     * Returns the latest price.
     */
    function getLatestMATICPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int Maticprice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = MaticpriceFeed.latestRoundData();

        return Maticprice;
    }
    function getLatestUSDTPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int Usdtprice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = UsdtpriceFeed.latestRoundData();
    
        return Usdtprice;
    }
}