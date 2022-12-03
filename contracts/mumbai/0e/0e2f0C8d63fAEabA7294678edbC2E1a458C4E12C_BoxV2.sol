// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BoxV2 {
    uint public num;

    function increment()
        public
    {
        num = num + 1;
    }
}