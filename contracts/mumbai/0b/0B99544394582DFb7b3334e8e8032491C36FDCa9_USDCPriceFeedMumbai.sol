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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//@review againsnt chainlink reference PriceConverter https://docs.chain.link/docs/get-the-latest-price/ 
//@review decimals for individual feeds
contract USDCPriceFeedMumbai {

    AggregatorV3Interface internal priceFeed1;
    AggregatorV3Interface internal priceFeed2;


    constructor() {
        // todo // do not hard code // polygon values
        priceFeed1 = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);     // matic usd 
        priceFeed2 = AggregatorV3Interface(0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0);     // usdc usd
    }

    function decimals() public view returns (uint8) { 
      return 18;
    }

    function getThePrice() public view returns (int) {   

      // Review: If either of the base or quote price feeds have mismatch in decimal then it could be a problem  
         
      /**
       * Returns the latest price of MATIC-USD
      */
    
      (             
       uint80 roundID1,              
       int price1,            
       uint startedAt1,             
       uint timeStamp1,
       uint80 answeredInRound1        
       ) = priceFeed1.latestRoundData();  
     
     /**
      * Returns the latest price of USDC-USD
     */
    
      (             
       uint80 roundID2,              
       int price2,            
       uint startedAt2,             
       uint timeStamp2,
       uint80 answeredInRound2        
       ) = priceFeed2.latestRoundData();  
     
    
    // Always using decimals 18 for derived price feeds
    int usdcMatic = price2*(10**18)/price1;
    return usdcMatic;
    }
     
}