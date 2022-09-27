/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

// SPDX-License-Identifier: unlicensed

pragma solidity 0.8.17;

contract task3 {
    mapping(address => bool) public users;

    function interact() public {
        require(users[msg.sender] == false, "you have already interacted");
        users[msg.sender] = true;
    }

    function check() public view returns(bool) {
        return users[msg.sender];
    }
}