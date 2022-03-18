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
    function getSQrtPrice(address _input) public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = UniswapV3Pool(_input).slot0();

        return uint256(sqrtPriceX96);
    }

    function getSQrtPrice32(address _input) public view returns (uint32) {
        (uint160 sqrtPriceX96, , , , , , ) = UniswapV3Pool(_input).slot0();

        return uint32(sqrtPriceX96);
    }

    function getSQrtPriceX(address _input) public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = UniswapV3Pool(_input).slot0();

        return uint256(uint32(sqrtPriceX96));
    }
}