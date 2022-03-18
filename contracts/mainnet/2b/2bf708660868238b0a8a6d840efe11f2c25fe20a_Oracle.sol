/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface UniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

contract Oracle {
    function getPrice_old(address _input) public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = UniswapV3Pool(_input).slot0();

        return
            (uint256(sqrtPriceX96) * (uint256(sqrtPriceX96)) * (1e18)) >>
            (96 * 2);
    }

    function getPrice(address _input) public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = UniswapV3Pool(_input).slot0();

        return (((2**96)**2) / (uint256(sqrtPriceX96)**2)) * 10e18;
    }

    function getSQrtPrice(address _input) public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = UniswapV3Pool(_input).slot0();

        return uint256(sqrtPriceX96);
    }
}