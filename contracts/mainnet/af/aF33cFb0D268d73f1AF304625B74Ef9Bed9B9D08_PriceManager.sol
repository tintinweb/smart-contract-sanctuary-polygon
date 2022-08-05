//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./AggregatorV3Interface.sol";

contract PriceManager {
    AggregatorV3Interface public priceFeed;

    constructor() payable {
        priceFeed = AggregatorV3Interface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        );
    }

    function USD2Matic(uint256 amount, uint8 _decimal)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 feedDecimal = priceFeed.decimals();
        uint256 decimal = _decimal - feedDecimal;

        uint256 fullPrice = uint256(price) * (10**decimal);

        return (amount * (10**18)) / fullPrice;
    }
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