/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract HelloWorld {
    function getPairs() external view returns (address[] memory pair) {
        uint256 max = 1000;
        address[] memory a = new address[](max);
        for (uint i = 0; i < max; i++) {
            a[i] = IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32).allPairs(i);
        }
        return a;
    }
}