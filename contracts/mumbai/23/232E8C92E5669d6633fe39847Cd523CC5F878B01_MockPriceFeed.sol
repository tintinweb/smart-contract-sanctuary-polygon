// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IPriceFeed.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
}

/// @notice Chainlink price feed to get the USD/FIL price
contract MockPriceFeed is IPriceFeed {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mumbai
     * Aggregator: LINK/USD
     * Address: 0x1C2252aeeD50e0c9B64bDfF2735Ee3C932F5C408
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x1C2252aeeD50e0c9B64bDfF2735Ee3C932F5C408);
    }

    /**
     * Returns the latest price
     */
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

    /// @notice get USD price in 6 decimals
    /// @param token used to format the return decimals, ex USDC token would format the output with 6 decimals
    /// @param amount amount of FIL to convert (in Wei)
    function consult(
        address token,
        uint256 amount
    ) external view override returns (uint) {
        uint price = uint(getLatestPrice());
        uint amountInWei = price * amount / 10 ** decimals();
        uint amountInTokenDecimals = amountInWei / 10 ** (18 - IERC20(token).decimals());

        return amountInTokenDecimals;
    }

    function decimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function description() public view returns (string memory) {
        return priceFeed.description();
    }

    function version() public view returns (uint) {
        return priceFeed.version();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.6;

interface IPriceFeed {
    /// @notice Returns the amount of swapped token 
    /// 
    /// @return The amount of swapped token
    function consult(
        address token,
        uint256 amount
    ) external view returns (uint256);
}