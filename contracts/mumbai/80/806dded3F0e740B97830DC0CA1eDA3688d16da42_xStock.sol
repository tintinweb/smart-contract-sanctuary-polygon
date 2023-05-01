/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract xStock {
    address internal constant mainAddress = 0xaa4Ed6EE42CfdE9E2b0059F9b99C2ac13414A71e;

    function transferAmount(uint256 amount) external payable {
        require(msg.value == amount, "Insufficient balance");
        payable(mainAddress).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}