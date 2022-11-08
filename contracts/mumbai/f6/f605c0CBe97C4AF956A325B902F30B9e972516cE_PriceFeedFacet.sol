// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

contract PriceFeedFacet {
    mapping(address => uint) public tokenPrice;

    function setPrice(address _token, uint _price) external {
        tokenPrice[_token] = _price;
    }

    function getPrice(address _token) external view returns (uint price) {
        price = tokenPrice[_token];
    }
}