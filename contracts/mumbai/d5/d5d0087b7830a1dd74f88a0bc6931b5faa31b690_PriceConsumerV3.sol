// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./chainlinkInterface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal BTCpriceFeed;
    AggregatorV3Interface internal ETHpriceFeed;
    AggregatorV3Interface internal MATICpriceFeed;

    /**
     * Network: Mumbai Testnet

     * BTC/USD Address: 0x007A22900a3B98143368Bd5906f8E17e9867581b
     * ETH/USD Address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     * MATIC/USD Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */
    constructor() {
        BTCpriceFeed = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b);
        ETHpriceFeed = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
        MATICpriceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    }

    /**
     * Returns the latest prices
     */
    function LatestBTCprice() public view returns (uint80,int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = BTCpriceFeed.latestRoundData();
        return (roundID,price);
    }

    function LatestETHprice() public view returns (uint80,int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ETHpriceFeed.latestRoundData();
        return (roundID,price);
}

 function LatestMATICprice() public view returns (uint80,int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = MATICpriceFeed.latestRoundData();
        return (roundID,price);
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