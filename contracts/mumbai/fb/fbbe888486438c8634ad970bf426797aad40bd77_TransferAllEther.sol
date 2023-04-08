/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransferAllEther {
    address payable public recipient;

    constructor(address payable _recipient) {
        recipient = _recipient;
    }

    function transferAll() public payable {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to transfer.");
        recipient.transfer(balance);
    }
}