//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Prices {
    AggregatorV3Interface internal ethUsdPriceFeed;

    mapping(address => uint256) public userBalance;

    constructor(address _priceFeedAddress) {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function getAmountOfTokens(uint256 nativeAmount)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();

        // costOfTokens = amountOfTokens * srgTokenCost / matic usd

        uint256 adjustedPrice = uint256(price) * 10**18; // 18 decimals

        // every srg token costs 0.12 USD

        uint256 srgTokenCost = 12 * 10**16;
        uint256 amountOfTokens = (nativeAmount * adjustedPrice) / srgTokenCost;

        return amountOfTokens;
    }

    function buyTokensNative() public payable {
        // TODO Integrate ERC20 SRG and buying with BUSD

        userBalance[msg.sender] += getAmountOfTokens(msg.value);
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