// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

struct Message {
    address to;
    uint256 toChainId;
    bytes data;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "./IMessage.sol";

interface MessageDispatcher {
    event MessageDispatched(
        bytes32 indexed messageId,
        address indexed from,
        uint256 indexed toChainId,
        address to,
        bytes data
    );

    function dispatchMessages(Message[] memory messages) external payable returns (bytes32[] memory messageIds);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

interface IMessageRelay {
    function relayMessages(uint256[] memory messageIds, address adapter) external payable returns (bytes32 receipts);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "../interfaces/IMessage.sol";

contract MessageHashCalculator {
    /// @dev Calculates the ID of a given message.
    /// @param chainId ID of the chain on which the message was/will be dispatched.
    /// @param id ID of the message that was/will be dispatched.
    /// @param origin Contract that did/will dispatch the given message.
    /// @param sender Sender of the message that was/will be dispatched.
    /// @param message Message that was/will be dispatched.
    function calculateHash(
        uint256 chainId,
        uint256 id,
        address origin,
        address sender,
        Message memory message
    ) public pure returns (bytes32 calculatedHash) {
        calculatedHash = keccak256(abi.encode(chainId, id, origin, sender, message));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "./interfaces/IMessageRelay.sol";
import "./interfaces/IMessageDispatcher.sol";
import "./utils/MessageHashCalculator.sol";

contract Yaho is MessageDispatcher, MessageHashCalculator {
    mapping(uint256 => bytes32) public hashes;
    uint256 private count;

    error NoMessagesGiven(address emitter);
    error NoMessageIdsGiven(address emitter);
    error NoAdaptersGiven(address emitter);
    error UnequalArrayLengths(address emitter);

    /// @dev Dispatches a batch of messages, putting their into storage and emitting their contents as an event.
    /// @param messages An array of Messages to be dispatched.
    /// @return messageIds An array of message IDs corresponding to the dispatched messages.
    function dispatchMessages(Message[] memory messages) public payable returns (bytes32[] memory) {
        if (messages.length == 0) revert NoMessagesGiven(address(this));
        bytes32[] memory messageIds = new bytes32[](messages.length);
        for (uint i = 0; i < messages.length; i++) {
            uint256 id = count;
            hashes[id] = calculateHash(block.chainid, id, address(this), msg.sender, messages[i]);
            messageIds[i] = bytes32(id);
            emit MessageDispatched(bytes32(id), msg.sender, messages[i].toChainId, messages[i].to, messages[i].data);
            count++;
        }
        return messageIds;
    }

    /// @dev Relays hashes of the given messageIds to the given adapters.
    /// @param messageIds Array of IDs of the message hashes to relay to the given adapters.
    /// @param adapters Array of relay adapter addresses to which hashes should be relayed.
    /// @param destinationAdapters Array of oracle adapter addresses to receive hashes.
    /// @return adapterReciepts Reciepts from each of the relay adapters.
    function relayMessagesToAdapters(
        uint256[] memory messageIds,
        address[] memory adapters,
        address[] memory destinationAdapters
    ) external payable returns (bytes32[] memory) {
        if (messageIds.length == 0) revert NoMessageIdsGiven(address(this));
        if (adapters.length == 0) revert NoAdaptersGiven(address(this));
        if (adapters.length != destinationAdapters.length) revert UnequalArrayLengths(address(this));
        uint256[] memory uintIds = new uint256[](messageIds.length);
        for (uint i = 0; i < messageIds.length; i++) {
            uintIds[i] = messageIds[i];
        }
        bytes32[] memory adapterReciepts = new bytes32[](adapters.length);
        for (uint i = 0; i < adapters.length; i++) {
            adapterReciepts[i] = IMessageRelay(adapters[i]).relayMessages(uintIds, destinationAdapters[i]);
        }
        return adapterReciepts;
    }

    /// @dev Dispatches an array of messages and relays their hashes to an array of relay adapters.
    /// @param messages An array of Messages to be dispatched.
    /// @param adapters Array of relay adapter addresses to which hashes should be relayed.
    /// @param destinationAdapters Array of oracle adapter addresses to receive hashes.
    /// @return messageIds An array of message IDs corresponding to the dispatched messages.
    /// @return adapterReciepts Reciepts from each of the relay adapters.
    function dispatchMessagesToAdapters(
        Message[] memory messages,
        address[] memory adapters,
        address[] memory destinationAdapters
    ) external payable returns (bytes32[] memory messageIds, bytes32[] memory) {
        if (adapters.length == 0) revert NoAdaptersGiven(address(this));
        messageIds = dispatchMessages(messages);
        uint256[] memory uintIds = new uint256[](messageIds.length);
        for (uint i = 0; i < messageIds.length; i++) {
            uintIds[i] = uint256(messageIds[i]);
        }
        bytes32[] memory adapterReciepts = new bytes32[](adapters.length);
        for (uint i = 0; i < adapters.length; i++) {
            adapterReciepts[i] = IMessageRelay(adapters[i]).relayMessages(uintIds, destinationAdapters[i]);
        }
        return (messageIds, adapterReciepts);
    }
}