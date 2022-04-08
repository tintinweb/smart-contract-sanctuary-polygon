// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "./interfaces/IILCalculator.sol";

contract ILCalculator is IILCalculator {
    function calculateILPrice(uint256 weSellAt, uint256 weBuyAt)
        external
        pure
        override
        returns (uint256 result)
    {
        result = (weSellAt + weBuyAt) / 2;
    }

    function isItVolatile(uint256 tngblOraclePrice, uint256 tngblSushiPrice)
        external
        pure
        override
        returns (bool result)
    {
        uint256 absDiff = tngblOraclePrice >= tngblSushiPrice
            ? (tngblOraclePrice - tngblSushiPrice)
            : (tngblSushiPrice - tngblOraclePrice);
        //calculate how much absDiff is in percentages from tngblSushiPrice
        uint256 percentage = (absDiff * tngblSushiPrice) / 10000;
        result = percentage > 500;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IILCalculator {
    function calculateILPrice(uint256 weSellAt, uint256 weBuyAt)
        external
        view
        returns (uint256 result);

    function isItVolatile(uint256 tngblOraclePrice, uint256 tngblSushiPrice)
        external
        view
        returns (bool result);
}