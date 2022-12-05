// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract T {
    uint public unlockTime;
  function getx() public view returns(uint) {
        return unlockTime;
  }
}