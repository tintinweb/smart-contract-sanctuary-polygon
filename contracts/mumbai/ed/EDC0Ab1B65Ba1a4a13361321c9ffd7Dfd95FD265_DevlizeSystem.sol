/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: MIT
// File: contracts/DevlizeSystem.sol



pragma solidity >= 0.7.0 < 0.9.0;

contract DevlizeSystem {

    struct Order {
        bool exist;
        uint256 price;
        bool paid;
    }

    struct Seller {
        bool exist;
        string fullName;
    }


    mapping (address => bool) public founders;

    mapping (address => Seller) public sellers;

    address public payTo = 0x24F5Be1aa7E402E2E7a644EF53d10d5780DaA241;

    mapping (uint256 => Order) public orders;


    modifier owners (){
        require(founders[msg.sender]);
        _;
    }

    constructor () {
        founders [0x24F5Be1aa7E402E2E7a644EF53d10d5780DaA241] = true; // Draw To Infinity Address
        founders [0xE403c690E34c7cc4fb43C7d1054A1c6B25B1ecA6] = true; // Lorenzo Address
        founders [0xbAD44655dd777Ef5F084AA60bC5b5430dE0f3A42] = true; // Federico Address
    }


    function setOrder (uint256 _id, uint256 _price) public {
        require(sellers[msg.sender].exist || founders[msg.sender]);
        require(!orders[_id].exist);
        require(_price > 0);
        
        Order memory newOrder = Order(true, _price * 10 ** 18, false);

        orders[_id] = newOrder;
    }


    function payOrder (uint256 _id) public payable {
        require(orders[_id].exist);
        require(!orders[_id].paid);
        require(msg.value >= orders[_id].price);
        
        orders[_id].paid = true;
    }


    function setSeller (address _newAddress, string memory _fullName) public owners {
        Seller memory newSeller = Seller(true, _fullName);

        sellers[_newAddress] = newSeller;
    }

    function removeSeller (address _newAddress) public owners {

        delete sellers[_newAddress];
    }


    function removeOrder (uint256 _id) public owners {
        delete orders[_id];
    }


    function withdraw () public owners {
        payable(payTo).transfer(address(this).balance);
    }

}