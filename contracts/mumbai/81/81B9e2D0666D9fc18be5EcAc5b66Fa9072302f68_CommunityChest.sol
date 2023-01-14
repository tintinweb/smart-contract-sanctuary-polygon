/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract CommunityChest {

    function deposit(uint256 amount, address payable  reciever) payable public {
        require(msg.value == amount);
         reciever.transfer(amount);
        // nothing else to do!
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}