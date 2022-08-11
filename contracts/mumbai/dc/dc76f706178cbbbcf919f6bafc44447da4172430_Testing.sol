/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Testing {
    uint length;

    struct Order {
        uint price;
        uint id;
        address seller;
        bool accepted;
    }

    event FCalled(Order[]);

    mapping(uint => Order) public Orders;

    function getOrders() public returns(Order[] memory) {
        Order[] memory ArrayOfOrders = new Order[](length);
        for(uint i = 0; i < length; i++) {
            // ArrayOfOrders[i] = Orders[i];
            Order storage order = Orders[i];
            ArrayOfOrders[i] = order;
        }
        emit FCalled(ArrayOfOrders);
        return ArrayOfOrders;
    }

    function getOrdersView() public view returns(Order[] memory) {
        Order[] memory ArrayOfOrders = new Order[](length);
        for(uint i = 0; i < length; i++) {
            // ArrayOfOrders[i] = Orders[i];
            Order storage order = Orders[i];
            ArrayOfOrders[i] = order;
        }
        return ArrayOfOrders;
    }

    function addOrder(uint price, uint id, bool accepted) public {
        Orders[length].price = price;
        Orders[length].id = id;
        Orders[length].seller = msg.sender;
        Orders[length].accepted = accepted;
        length++;
    }
}