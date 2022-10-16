/**
 *Submitted for verification at polygonscan.com on 2022-10-15
*/

// SPDX-License-Identifier: undefined

pragma solidity 0.8.0;

contract task3 {
    
    mapping(address => bool) public users;

    function interact() public {
        require(users[msg.sender] == false, "you have already interacted");
        users[msg.sender] = true;
    }

    function check(address toVerify) public view returns(bool) {
        return users[toVerify];
    }
}