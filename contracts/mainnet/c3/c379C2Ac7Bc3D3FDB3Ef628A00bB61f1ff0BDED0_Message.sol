//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title Message Contract
 * @author Daniel Jimenez
 * @notice A contract that stores a message and allows it to be changed
 */
contract Message {
  /**
   * @notice the message is stored in the message variable
   * @return message
   */
  string public message;

  /**
   * @notice event that is emitted when the message is changed
   * @param oldMessage the old message
   * @param newMessage the new message
   */
  event MessageChanged(string oldMessage, string newMessage);


  /**
   * @param _message is the initial message
   * @notice the constructor is called when the contract is deployed and sets initial message
   */
  constructor(string memory _message) {
    message = _message;
  }

  /**
   * @param _message is the new message
   * @notice the setMessage function changes the message and emits MessageChanged Event
   */
  function setMessage(string calldata _message) external {
      string memory oldMessage = message;
      message = _message;
      emit MessageChanged(oldMessage, _message);
  }
}