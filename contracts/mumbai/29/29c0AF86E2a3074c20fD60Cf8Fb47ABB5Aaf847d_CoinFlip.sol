/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract CoinFlip {
    uint public num;

    constructor() {
        num = 0;
    }

    function increaseNum(uint amount) external {
        num += amount;
    }
}