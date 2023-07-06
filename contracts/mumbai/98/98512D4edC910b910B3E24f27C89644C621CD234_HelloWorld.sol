/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract HelloWorld {
    uint amount = 0;

    function sumAmount(uint a, uint b) external pure returns (uint) {
        return a + b;
    }

    function setAmount(uint _x) external {
        amount = _x;
    }

    function getAmount() external view returns (uint) {
        return amount;
    }

    function getAddress() external view returns (address) {
        return msg.sender;
    }
}