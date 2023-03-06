/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Message {
  address sender;
  string message;
}

contract MockMessenger {
  address public scribe;
  Message[] public messages;

  event MessageSent(address indexed sender, string message);

  constructor(address _scribe) {
    scribe = _scribe;
  }

  modifier onlyScribe() {
    if (msg.sender != scribe)
      revert("MockDestination: Only scribe can call this function");
    _;
  }

  function writeMessage(string memory _message) external {
    emit MessageSent(msg.sender, _message);
  }

  function getMessages() external view returns (Message[] memory) {
    return messages;
  }

  function handleMessageReceived(bytes calldata _data) external onlyScribe {
    (address _sender, string memory _message) = abi.decode(
      _data,
      (address, string)
    );
    messages.push(Message({sender: _sender, message: _message}));
  }
}