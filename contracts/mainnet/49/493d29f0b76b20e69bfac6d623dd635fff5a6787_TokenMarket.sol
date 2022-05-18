/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.4.21;

interface IERC20Token {
    function totalSupply() external  returns (uint);
    function balanceOf(address tokenlender) external  returns (uint balance);
    function allowance(address tokenlender, address spender) external  returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenlender, address indexed spender, uint tokens);
}



contract TokenMarket {
    struct Listing {
        address seller;
        IERC20Token token;
        uint256 unitsAvailable;

        // wei/unit price as a rational number
        uint256 priceNumerator;
        uint256 priceDenominator;
    }

    Listing[] public listings;

    event ListingChanged(address indexed seller, uint256 indexed index);
    event ListingPrice(address indexed seller, uint256 indexed );

    function list(
        IERC20Token token,
        uint256 units,
        uint256 numerator,
        uint256 denominator
    ) public {
        Listing memory listing = Listing({
            seller: msg.sender,
            token: token,
            unitsAvailable: units,
            priceNumerator: numerator,
            priceDenominator: denominator
        });

        listings.push(listing);
        emit ListingChanged(msg.sender, listings.length-1);
    }

    function cancel(uint256 index) public {
        require(listings[index].seller == msg.sender);
        delete(listings[index]);
        emit ListingChanged(msg.sender, index);
    }

    function buy(uint256 index, uint256 units) public payable {
        Listing storage listing = listings[index];

        require(listing.unitsAvailable >= units);
        listing.unitsAvailable -= units;
        require(listing.token.transferFrom(listing.seller, msg.sender, units));

        uint256 cost = (units * listing.priceNumerator); 
            listing.priceDenominator;
        require(msg.value == cost);
        listing.seller.transfer(cost);

        emit ListingChanged(listing.seller, index);
    }

    function showPrice(uint256 index) public{
        Listing storage listing = listings[index];
        
        require(listings[index].seller == msg.sender);
            listing.priceDenominator;

        emit ListingPrice( listing.seller, index);
        
         }
    
}