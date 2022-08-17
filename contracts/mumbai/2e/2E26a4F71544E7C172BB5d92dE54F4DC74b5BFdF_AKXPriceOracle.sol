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
pragma solidity ^0.8.15;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";



contract AKXPriceOracleETHUSD {
  AggregatorV3Interface internal priceFeed;

    uint256 chainId;

    constructor() {
        chainId = block.chainid;
     
            priceFeed = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
       
    }

     function getLatestPriceETH() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price * 1e18;
    }
}

contract AKXPriceOracleMATICUSD {
  AggregatorV3Interface internal priceFeedMatic;

    uint256 chainIdMatic;

    constructor() {
        chainIdMatic = block.chainid;
       
    priceFeedMatic = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        }

    

     function getLatestPriceMatic() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeedMatic.latestRoundData();
        return price * 1e18;
    }
}

contract AKXPriceOracle is AKXPriceOracleETHUSD(), AKXPriceOracleMATICUSD()  {

    uint public ethUSD;
    uint public maticETH;
    uint public maticUSD;
    uint public AkxETH;
    uint public AkxMatic;
    uint public AkxUSD;

    address public owner;


    constructor() {
        getPrice();
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized");
        _;
    }

    function getPrice() public {
       
        ethUSD = uint256(getLatestPriceETH());
        maticUSD = uint256(getLatestPriceMatic());
        AkxUSD = (maticUSD / 20);
        AkxMatic = 20;
    }

    // function to be used only AFTER vip sale as price stays stable because no sell is allowed and no token released before the end.

    function updateAkxPrice(uint256 base) public onlyOwner {
        getPrice();
        AkxUSD = base;
        AkxMatic = maticUSD / AkxUSD;
    }

}