/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FreeMoney {

    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}