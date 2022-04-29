pragma solidity ^0.6.0;

import "./AggregatorV3Interface.sol";

contract ChainlinkUSDTUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;


    constructor() public {
        priceFeed = AggregatorV3Interface(0x0A6513e40db6EB1b165753AD52E80663aeA50545);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}

pragma solidity ^0.6.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  
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