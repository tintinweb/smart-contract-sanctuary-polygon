// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.17;

contract HelloWorld {
  string message;

  constructor(string memory _message) {
    message = _message;
  }

  function setMessage(string memory _message) external {
    message = _message;
  }

  function getMessage() external view returns (string memory) {
    return message;
  }
}