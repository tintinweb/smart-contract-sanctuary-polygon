pragma solidity ^0.6.0;

import "./AggregatorV3Interface.sol";

contract ChainlinkDAIUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;


    constructor() public {
        priceFeed = AggregatorV3Interface(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D); // тут нужно будет указать адрес фида
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