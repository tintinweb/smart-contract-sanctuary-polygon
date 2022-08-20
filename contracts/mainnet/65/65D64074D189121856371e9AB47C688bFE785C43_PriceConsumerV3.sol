// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;
    int256 public myPrice;

    /**
     * Network: Polygon Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5d37E4b374E6907de8Fc7fb33EE3b0af403C7403
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x5d37E4b374E6907de8Fc7fb33EE3b0af403C7403
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function getPrice() public view returns (int256) {
        return myPrice;
    }

    function setPrice(int256 _price) public returns (int256) {
        return myPrice = _price;
    }

    function setPrice2(int256 _price) public returns (int256) {
        getLatestPrice();
        return myPrice = _price;
    }

    function autoSetPrice() public {
        setPrice(getLatestPrice());
    }
}

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