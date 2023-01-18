/**
 *Submitted for verification at polygonscan.com on 2023-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PayableTest {

    uint public a;
    mapping(address => uint256) public balance;

    function set(uint _a) public payable {
        balance[msg.sender] += msg.value;
        a = _a;
    }

    function withdraw() public {
        payable(msg.sender).transfer(balance[msg.sender]);
    }

}