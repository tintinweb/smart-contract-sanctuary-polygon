/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Giveaway {

    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}