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

    function __AKXPriceOracle_init() public {
        chainId = block.chainid;
        if(chainId == 1) {
            priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        }
       
        else if(chainId == 137) {
            priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
        }
        else if(chainId == 80001) {
            priceFeed = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
        } else {
             priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        }

    }

     function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}

contract AKXPriceOracleMATICUSD {
  AggregatorV3Interface internal priceFeed;

    uint256 chainId;

    function __AKXPriceOracle_init() public {
        chainId = block.chainid;
       
         if(chainId == 1) {
            priceFeed = AggregatorV3Interface(0x7794ee502922e2b723432DDD852B3C30A911F021);
        }
        else  {
            priceFeed = AggregatorV3Interface(0x7794ee502922e2b723432DDD852B3C30A911F021);
        }

    }

     function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}

contract AKXPriceOracle  {

    uint public ethUSD;
    uint public maticETH;
    uint public maticUSD;
    uint public AkxETH;
    uint public AkxMatic;
    uint public AkxUSD;

    address public ethUSDOracle;
    address public maticEthOracle; // only on polygon
    address public maticUSDOracle;

    constructor(address[2] memory oracles) {
        ethUSDOracle = oracles[0];
        maticUSDOracle = oracles[1];
    }

    function _getEthUSDPrice() internal {
        AKXPriceOracleETHUSD(ethUSDOracle).__AKXPriceOracle_init();
        ethUSD = uint(AKXPriceOracleETHUSD(ethUSDOracle).getLatestPrice()) * 1e8;
    }

    function _getMaticUSDPrice() internal {
        AKXPriceOracleMATICUSD(maticUSDOracle).__AKXPriceOracle_init();
        maticUSD = uint(AKXPriceOracleETHUSD(ethUSDOracle).getLatestPrice()) * 1e8;

    }

}