/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

contract MessageProcessor is IFxMessageProcessor {
    uint256 lastStateId;
    address lastSender;
    bytes lastData;

    event OnNewMessage(uint256 stateId, address rootMessageSender, bytes data);

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external {
        lastStateId = stateId;
        lastSender = rootMessageSender;
        lastData = data;

        emit OnNewMessage(stateId, rootMessageSender, data);
    }
}