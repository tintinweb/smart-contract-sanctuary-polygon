/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestSummer {
    uint public total;
    mapping(address => uint) public userTotals;

    event AmountAdded(address indexed adder, uint amount);

    function add(uint x) external {
        total += x;
        userTotals[msg.sender] += x;

        emit AmountAdded(msg.sender, x);
    }

    function addFail(uint x) external {
        total += x;

        revert("failed to add");
    }
}