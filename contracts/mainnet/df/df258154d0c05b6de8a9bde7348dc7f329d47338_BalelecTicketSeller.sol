/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


contract BalelecTicketSeller {
    uint public price = 30;
    mapping(address => bool) public tickets;
    event Purchase(address buyer);

    function SetPrice(uint newPrice) public onlyOwner {
        require(newPrice < 100, "The price is too high");
        price = newPrice;
    }

    //custom modifier
    modifier onlyOwner() {
        require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, "Only admin can change the price");
        _;
    }

    function BuyTicket() payable public {
        require(msg.value == price, "You're not paying the correct amount");
        tickets[msg.sender] = true;
        emit Purchase(msg.sender);
    }
}