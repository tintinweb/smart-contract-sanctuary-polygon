// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MySample {
  string private _message;

  function setMessage(string memory message) public {
    _message = message;
  }
}