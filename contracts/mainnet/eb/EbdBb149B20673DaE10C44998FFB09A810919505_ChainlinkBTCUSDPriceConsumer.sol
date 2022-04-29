pragma solidity ^0.6.0;

import "./AggregatorV3Interface.sol";

contract ChainlinkBTCUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;


    constructor() public {
        priceFeed = AggregatorV3Interface(0xc907E116054Ad103354f2D350FD2514433D57F6f);
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