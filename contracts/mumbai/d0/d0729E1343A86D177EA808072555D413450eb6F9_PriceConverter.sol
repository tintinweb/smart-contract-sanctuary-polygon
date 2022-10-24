// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IPriceConverter.sol";

/**
 * @title PriceConverter
 * @dev Standalone Price Conversion Module for Chainlink Price Feeds
 */

contract PriceConverter is IPriceConverter {
    function getDerivedPrice(
        address _base, // from
        address _quote // to
    ) public view override returns (int) {
        AggregatorV3Interface baseFeed = AggregatorV3Interface(_base);
        AggregatorV3Interface quoteFeed = AggregatorV3Interface(_quote);

        (, int basePrice, , , ) = baseFeed.latestRoundData();
        (, int quotePrice, , , ) = quoteFeed.latestRoundData();

        uint8 baseDec = baseFeed.decimals();
        uint8 quoteDec = quoteFeed.decimals();
        uint8 _decimals = baseDec <= quoteDec ? baseDec : quoteDec;

        basePrice = scalePrice(basePrice, baseDec, _decimals);
        quotePrice = scalePrice(quotePrice, quoteDec, _decimals);

        int dec = int(10**uint(_decimals));
        return (basePrice * dec) / quotePrice;
    }

    function scalePrice(
        int _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int price) {
        int adjustment = int(10**uint(_decimals));

        price = (_priceDecimals < _decimals)
            ? _price * adjustment
            : (_priceDecimals > _decimals)
            ? _price / adjustment
            : _price;
    }

    function decimals() public pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        public
        pure
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 0;
        answer = 1 * (10**8);
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IPriceConverter {
    function getDerivedPrice(address from, address to)
        external
        view
        returns (int);
}

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