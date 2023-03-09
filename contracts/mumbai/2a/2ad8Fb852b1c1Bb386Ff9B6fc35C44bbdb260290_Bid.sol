/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Bid {
    address public currentWinner;
    uint public currentAuctionPrice;
    uint public deadline;

    constructor() {
        currentWinner = msg.sender;
        deadline = block.timestamp + 15 minutes;
    }

    receive() external payable {
        setCurrentAuctionPrice();
    }

    function setCurrentAuctionPrice() public payable {
        require(msg.value > currentAuctionPrice, "Need to pay more than the currentAuctionPrice");
        (bool sent, ) = currentWinner.call{value: currentAuctionPrice}("");
        if (sent) {
            currentAuctionPrice = msg.value;
            currentWinner = msg.sender;
        }
    }
}