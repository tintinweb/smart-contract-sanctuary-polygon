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
    event Init(uint256 price);  //0x387d06ac3b54c0ade104e08db87887286d162da416d27a605fc64e4f26c01338

    uint256 public priceShorted; //1
    address public pair;
    bool public shortOpened;

    constructor() {
        pair = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;
        shortOpened = false;
    }

    function set() external {
        priceShorted = getLastTokenPrice();
        emit Init(priceShorted);
    }

    function changePair(address _pair) external {
        pair = _pair;
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