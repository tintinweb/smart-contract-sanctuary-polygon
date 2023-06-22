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
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Library_PriceConverter.sol";

// 0xfd00fC30C549df2b32aF84aF6D5B9b414759b130

contract FR_getExchangeRate {
    using PriceConverter for uint256;

    mapping(string => mapping(string => AggregatorV3Interface))
        public priceFeeds;
    mapping(string => mapping(string => uint256)) public hardCodedPriceFeeds;

    function setPriceFeed(
        string memory fromCurrency,
        string memory toCurrency,
        address priceFeedAddress
    ) public {
        // Set the price feed address for the currency pair
        priceFeeds[fromCurrency][toCurrency] = AggregatorV3Interface(
            priceFeedAddress
        );
    }

    function getPriceFeed(
        string memory fromCurrency,
        string memory toCurrency
    ) public view returns (AggregatorV3Interface) {
        return priceFeeds[fromCurrency][toCurrency];
    }

    function setHardCodedPriceFeed(
        string memory fromCurrency,
        string memory toCurrency,
        uint256 rate
    ) public {
        hardCodedPriceFeeds[fromCurrency][toCurrency] = rate;
    }

    function getHardCodedPriceFeed(
        string memory fromCurrency,
        string memory toCurrency
    ) public view returns (uint256) {
        return hardCodedPriceFeeds[fromCurrency][toCurrency];
    }

    function checkAndUpdateConversionRate(
        string memory fromCurrency,
        string memory toCurrency
    ) internal view returns (uint256) {
        AggregatorV3Interface selectedPriceFeed = priceFeeds[fromCurrency][
            toCurrency
        ];
        if (address(selectedPriceFeed) != address(0)) {
            uint256 conversionRate = PriceConverter.getConversionRate(
                1,
                selectedPriceFeed
            );
            require(conversionRate > 0, "No conversion available");
            return conversionRate;
        }
        return 0;
    }

    function getExchangeRate(
        string memory fromCurrency,
        string memory toCurrency
    ) public view returns (uint256) {
        uint256 conversionRate;
        uint256 updatedToCurrencyToUSDRate;
        uint256 updatedFromCurrencyToUSDRate;

        conversionRate = checkAndUpdateConversionRate(fromCurrency, toCurrency);
        if (conversionRate > 0) {
            return conversionRate;
        }

        conversionRate = checkAndUpdateConversionRate(toCurrency, fromCurrency);
        if (conversionRate > 0) {
            return (10 ** 36) / conversionRate; // Calculate inverse conversion rate
        }

        conversionRate = checkAndUpdateConversionRate(toCurrency, "USD");
        if (conversionRate > 0) {
            updatedToCurrencyToUSDRate = conversionRate;
        }

        conversionRate = checkAndUpdateConversionRate(fromCurrency, "USD");
        if (conversionRate > 0) {
            updatedFromCurrencyToUSDRate = conversionRate;
        }

        if (
            updatedFromCurrencyToUSDRate > 0 && updatedToCurrencyToUSDRate > 0
        ) {
            return
                (updatedFromCurrencyToUSDRate * 10 ** 18) /
                updatedToCurrencyToUSDRate;
        }

        // Check if hard-coded conversion rate is available
        conversionRate = hardCodedPriceFeeds[fromCurrency][toCurrency];
        if (conversionRate > 0) {
            return conversionRate;
        }

        conversionRate = hardCodedPriceFeeds[toCurrency]["USD"];
        if (conversionRate > 0) {
            updatedToCurrencyToUSDRate = conversionRate;
        }

        conversionRate = hardCodedPriceFeeds[fromCurrency]["USD"];
        if (conversionRate > 0) {
            updatedFromCurrencyToUSDRate = conversionRate;
        }

        if (
            updatedFromCurrencyToUSDRate > 0 && updatedToCurrencyToUSDRate > 0
        ) {
            return
                (updatedFromCurrencyToUSDRate * 10 ** 18) /
                updatedToCurrencyToUSDRate;
        }

        revert("No conversion available");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digits
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 amount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 amountInUsd = (ethPrice * amount);
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return amountInUsd;
    }
}