/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Oracle {
    address public owner;
    uint public btcPrice;
    event NewPrice();

    constructor() {
        owner = msg.sender;
    }

    function getBTCPrice() public {
        emit NewPrice();
    }

    function updateBTCPrice(uint price) public {
        require(msg.sender == owner);
        btcPrice = price;
    }
}