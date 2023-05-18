/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

}

contract PriceTrackerV5 {

    event Opened(uint256 price);
    event Closed(uint256 price);
    event Init(uint256 price);

    uint256 public priceShorted; //1
    address public pair;
    bool public shortOpened;

    constructor() {
        pair = 0x65D43B64E3B31965Cd5EA367D4c2b94c03084797;
        shortOpened = false;
    }

    function set() external {
        priceShorted = getLastTokenPrice();
        emit Init(priceShorted);
    }

    function check() external {
        uint256 currentPrice = getLastTokenPrice();
        if (currentPrice < priceShorted && !shortOpened) {
            shortOpened = true;
            emit Opened(currentPrice);
        } else if (priceShorted <= currentPrice && shortOpened) {
            shortOpened = false;
            emit Closed(currentPrice);
        }
    }

    function getLastTokenPrice() public view returns (uint256 price){
        (uint112 reserveA, uint112 reserveB, ) = IUniswapV2Pair(pair).getReserves();
        uint numerator = reserveB * 1e18;
        uint denominator = reserveA * 1e6;
        price = 1e6 * numerator / denominator;
    }
}