/**
 *Submitted for verification at polygonscan.com on 2023-01-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Aggregator {
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    int256 public price;

    function setPrice(int256 newPrice) external {
        price = newPrice;
        emit AnswerUpdated(price, 123, block.timestamp);
    }
}


contract AggregatorProxy {
    address public aggregator;
    string public constant description = 'MAGA / USD';
    uint8 public constant decimals = 8;

    constructor() {
        aggregator = address(new Aggregator());
    }
}