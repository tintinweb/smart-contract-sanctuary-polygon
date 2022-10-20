// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    address public weth = 0x4220238D6db027D74995B12f3796c0a530FE0006;

    constructor() {
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function getAllPairs() external view returns (address[] memory) {
        return allPairs;
    }

    function addPair(address tokenA, address tokenB, address pair) public {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
    }

    function setPair(address) public { //dummie function for compatibleness 
    }

    function setPairExist(bool) public { //dummie function for compatibleness 
    }
}