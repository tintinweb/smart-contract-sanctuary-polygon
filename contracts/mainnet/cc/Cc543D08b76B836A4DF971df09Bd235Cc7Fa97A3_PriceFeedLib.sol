// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPriceFeed {
    struct Property {
        uint256 price;
        address currency;
        address priceFeed;
    }

    struct ScalePriceParams {
        int256 price;
        uint8 priceDecimals;
        uint8 decimals;
    }

    struct Storage {
        mapping(string => IPriceFeed.Property) propertyDetails;
        mapping(address => address) currencyToFeed;
        mapping(string => address) nameToFeed;
    }

    struct DerivedPriceParams {
        address base;
        address quote;
        uint8 decimals;
    }

    function feedPriceChainlink(
        address _of
    ) external view returns (uint256 latestPrice);

    function getDerivedPrice(
        DerivedPriceParams memory _params
    ) external view returns (int256);

    function getSharePriceInBaseCurrency(
        string memory _propertySymbol,
        address currency
    ) external view returns (uint256);

    //---------------------------------------------------------------------
    function setPropertyDetails(
        string memory _propertySymbol,
        Property calldata _propertyDetails
    ) external;

    function getPropertyDetail(
        string memory _propertySymbol
    ) external view returns (Property memory property);

    //---------------------------------------------------------------------

    // function setCurrencyToFeed(address _currency, address _feed) external;

    function getCurrencyToFeed(
        address _currency
    ) external view returns (address);
    //---------------------------------------------------------------------
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
error unSupportedCurrency();
error invalidBase();
error MustBeWholeNumber();
error invalidCase();

import "../Interfaces/AggregatorV3Interface.sol";
import "../Interfaces/IPriceFeed.sol";

// This contract uses the library to set and retrieve state variables
library PriceFeedLib {
    function getDerivedPrice(
        IPriceFeed.DerivedPriceParams memory _params
    ) external view returns (int256) {
        require(
            _params.decimals > uint8(0) && _params.decimals <= uint8(18),
            "Invalid _decimals"
        );
        int256 decimals = int256(10 ** uint256(_params.decimals));
        (, int256 basePrice, , , ) = AggregatorV3Interface(_params.base)
            .latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_params.base).decimals();
        basePrice = scalePrice(
            IPriceFeed.ScalePriceParams(
                basePrice,
                baseDecimals,
                _params.decimals
            )
        );

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_params.quote)
            .latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_params.quote).decimals();
        quotePrice = scalePrice(
            IPriceFeed.ScalePriceParams(
                quotePrice,
                quoteDecimals,
                _params.decimals
            )
        );
        return (basePrice * decimals) / quotePrice;
    }

    function scalePrice(
        IPriceFeed.ScalePriceParams memory _params
    ) public pure returns (int256) {
        if (_params.priceDecimals < _params.decimals) {
            return
                _params.price *
                int256(10 ** uint256(_params.decimals - _params.priceDecimals));
        } else if (_params.priceDecimals > _params.decimals) {
            return
                _params.price /
                int256(10 ** uint256(_params.priceDecimals - _params.decimals));
        }
        return _params.price;
    }
}