/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Wallet {
    address payable public recipient;
    uint256 public threshold;

    constructor(address payable _recipient, uint256 _threshold) {
        recipient = _recipient;
        threshold = _threshold;
    }

    receive () external payable {
        if (address(this).balance >= threshold) {
            recipient.transfer(address(this).balance);
        }
    }
}