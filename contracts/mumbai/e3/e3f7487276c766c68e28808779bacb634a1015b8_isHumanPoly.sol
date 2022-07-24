/**
 *Submitted for verification at polygonscan.com on 2022-07-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

contract isHumanPoly is IMessageRecipient {
  address inbox;
  
  event isHumanEth(uint32 _origin, bytes32 _sender, bytes _message);

  /**
   * @notice Emits a HelloWorld event upon receipt of an interchain message
   * @param _origin The chain ID from which the message was sent
   * @param _sender The address that sent the message
   * @param _message The contents of the message
   */
  function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes memory _message
  ) external override {
    emit isHumanEth(_origin, _sender, _message);
  }
}