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

/// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IPriceFeed {
    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the current price (if price is > 0)
    /// @return price is the current price of the token (8 decimal)
    function currentPrice() external view returns(uint256 price);
}

/// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";

contract MaticPrice is IPriceFeed {
    /// @dev price feed on mainnet
    address public immutable PRICE_FEED_ADDRESS;

    constructor(address priceFeed_) {
        PRICE_FEED_ADDRESS = priceFeed_;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev see ITokenPrice-{currentPrice}
    function currentPrice() external view returns (uint256 price_) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(PRICE_FEED_ADDRESS).latestRoundData();

        return uint256(price);
    }
}