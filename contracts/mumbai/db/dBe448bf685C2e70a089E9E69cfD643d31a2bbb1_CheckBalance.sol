/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CheckBalance {
    address payable public owner;

    constructor ()  {
        owner = payable(msg.sender);
    }

    receive () external payable{}

    function withdraw(uint _amount) external {
        require(msg.sender==owner, "caller is not a owner");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }
}