/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PriceFeed {
    uint256 public price;

    event PriceChanged(uint256 newPrice);

    function priceChanged(uint256 _price) external view returns (bool changed) {
        return price != _price;
    }

    function updatePrice(uint256 _price) external {
        price = _price;

        emit PriceChanged(_price);
    }
}