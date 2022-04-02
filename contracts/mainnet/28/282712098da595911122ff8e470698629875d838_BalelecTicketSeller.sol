/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


contract BalelecTicketSeller {
    uint public price = 30;
    mapping(address => bool) public tickets;
    event Purchase(address buyer);
    address immutable owner;
    
    constructor(address _owner) {
        owner = _owner;
    }

    function SetPrice(uint newPrice) public onlyOwner {
        require(newPrice < 100, "The price is too high");
        price = newPrice;
    }

    //custom modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only admin can change the price");
        _;
    }

    function BuyTicket() payable public {
        require(msg.value == price, "You're not paying the correct amount");
        tickets[msg.sender] = true;
        emit Purchase(msg.sender);
    }
}