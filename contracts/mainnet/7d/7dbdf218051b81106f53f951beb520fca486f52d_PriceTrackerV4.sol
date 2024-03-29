/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

}

contract PriceTrackerV4 {

    event Success(uint256 price);
    event Failed();

    uint256 public priceShorted;
    address public pair;

    constructor() {
        pair = 0x65D43B64E3B31965Cd5EA367D4c2b94c03084797;
    }

    function fix() public {
        (priceShorted,,) = getLastTokenPrice();
    }

    function check() public {
        (uint256 currentPrice,,) = getLastTokenPrice();
        require(currentPrice != priceShorted, "same price");
        priceShorted = currentPrice;
        emit Success(currentPrice);
    }

    function getLastTokenPrice() public view returns (uint256 price, uint256 numerator, uint256 denominator){
        (uint112 reserveA, uint112 reserveB, ) = IUniswapV2Pair(pair).getReserves();
        numerator = reserveB * 1e18;
        denominator = reserveA * 1e6;
        price = 1e6 * numerator / denominator;
    }
}