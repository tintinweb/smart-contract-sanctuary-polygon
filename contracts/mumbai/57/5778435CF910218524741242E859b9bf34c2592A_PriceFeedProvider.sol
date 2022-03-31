// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IPriceFeedProvider.sol";

contract PriceFeedProvider is IPriceFeedProvider {

    address admin;

    mapping(uint16 => address) private priceFeeds;

    constructor() {
        admin = msg.sender;
    }

    /**
     * Returns the latest price for a price feed.
     * It reverts if the feed id is invalid: there was no price feed address provided for the given id yet
     */
    function getLatestPrice(uint16 _priceFeedId)
        external
        view
        override
        returns (int256)
    {
        require(
            priceFeeds[_priceFeedId] != address(0),
            "invalid price feed id"
        );
        AggregatorV3Interface priceFeed;
        priceFeed = AggregatorV3Interface(priceFeeds[_priceFeedId]);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * Inserts or updates the price feed address for the given price feed id
     */
    function upsertFeed(uint16 _id, address _dataFeedAddress) external {
        require(msg.sender == admin, "admin only");
        priceFeeds[_id] = _dataFeedAddress;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

pragma solidity ^0.8.3;

interface IPriceFeedProvider {
    /**
     * Returns the latest price for a price feed.
     * It reverts if the feed id is invalid: there was no price feed address provided for the given id yet
     */
    function getLatestPrice(uint16 _priceFeedId)
        external
        view
        returns (int256);
}