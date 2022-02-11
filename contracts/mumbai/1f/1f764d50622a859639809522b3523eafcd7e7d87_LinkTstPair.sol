/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// This is a quick iteration for the generic pair of (2 )tokens to have queues of waiting orders at given price..:
contract LinkTstPair {
    // ERC20 tokenA, tokenB
    string tokenA; string tokenB; // mock for the iERC20

    // Single sell or buy order type:
    struct Order {
        uint price;
        uint amount;
        // v2 to add pre-paid callBack on filling.!.
    }
    mapping (uint => Order) private LinkSellersOrderBook; // to be (a clever )linked-list soon
    mapping (uint => Order) private LinkBuyersOrderBook; // to be (a clever )linked-list soon

    constructor(string memory a, string memory b) {
        // some event on creation?
        tokenA = a; tokenB = b;
    }

    function getTopBuy() public view returns (Order memory) { // much dummy yet
        return LinkBuyersOrderBook[0];
    }

}