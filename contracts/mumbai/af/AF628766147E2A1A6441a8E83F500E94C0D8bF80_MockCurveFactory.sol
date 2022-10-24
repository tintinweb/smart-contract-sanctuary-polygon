// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;


interface ICurveFactory {

    function get_underlying_balances(address pool)
        external
        view
        returns (uint256[8] memory);

    function get_underlying_decimals(address pool)
        external
        view
        returns (uint256[8] memory);

    function get_meta_n_coins(address pool)
        external
        view
        returns (uint256, uint256);
}

contract MockCurveFactory is ICurveFactory {
    uint256 public amount = 10000000000000000000000;
    function get_underlying_balances(address pool)
        external
        view
        override
        returns (uint256[8] memory result)
    {
        result[0] = amount;
    }

    function get_underlying_decimals(address pool)
        external
        view
        override
        returns (uint256[8] memory result)
    {
        result[0] = 18;
    }

    function get_meta_n_coins(address pool)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (0, 1);
    }
}