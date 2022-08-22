// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction  {
    mapping(address => uint) public bidders;

    function make_bid() public payable{
        require(msg.value > 0);
        bidders[msg.sender] += msg.value;
    }


    function return_money(address to) public payable{
        payable(to).transfer(bidders[to]);
        bidders[to] = 0;
    }

}


// Contract Address - 0x6350DAEF24A15c6d05Da50D9E83F7cfd8C08BDdc