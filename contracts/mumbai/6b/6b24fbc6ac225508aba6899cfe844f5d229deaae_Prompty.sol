// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

import {IPrompty} from "./IPrompty.sol";

contract Prompty is IPrompty {
    uint256 public currentPromptId = 0;
    mapping(uint256 => Prompt) public prompts;

    mapping(uint256 => PromptyInstance) public instances;
    uint256 instanceCount;

    function createInstance(
        address[] memory allowedResponders,
        string memory name,
        string memory description,
        bool isVisible
    ) public {
        PromptyInstance storage instance = instances[instanceCount];

        instance.name = name;
        instance.isVisible = isVisible;

        emit InstanceCreated(
            instanceCount,
            name,
            description,
            instance.isVisible
        );

        for (uint256 i = 0; i < allowedResponders.length; i++) {
            instance.allowedResponders[allowedResponders[i]] = true;
            emit ResponderAdded(instanceCount, allowedResponders[i]);
        }

        unchecked {
            instanceCount++;
        }
    }

    function addResponders(
        uint256 instanceID,
        address[] memory allowedResponders
    ) public {
        PromptyInstance storage instance = instances[instanceID];

        for (uint256 i = 0; i < allowedResponders.length; i++) {
            instance.allowedResponders[allowedResponders[i]] = true;
            emit ResponderAdded(instanceCount, allowedResponders[i]);
        }
    }

    function updateSettings(
        uint256 instanceId,
        string memory newName,
        string memory newDescription,
        bool newIsVisible,
        address[] memory newAllowedResponders
    ) public {
        PromptyInstance storage instance = instances[instanceId];

        if (instances[instanceId].allowedResponders[msg.sender] == false) {
            revert NotAllowed();
        }

        instance.name = newName;
        instance.description = newDescription;
        instance.isVisible = newIsVisible;
        addResponders(instanceId, newAllowedResponders);

        emit InstanceUpdated(
            instanceId,
            instance.name,
            instance.description,
            instance.isVisible
        );
    }

    function createPrompt(
        uint256 instanceId,
        string memory prompt,
        uint256 endTime,
        uint128 minChars,
        uint128 maxChars
    ) public {
        if (instances[instanceId].allowedResponders[msg.sender] == false) {
            revert NotAllowed();
        }

        if (bytes(prompt).length == 0) revert InvalidPrompt();
        if (minChars > maxChars) revert InvalidPromptParams();
        if (minChars <= 0) revert InvalidPromptParams();
        if (maxChars >= 4096) revert InvalidPromptParams();

        Prompt storage p = prompts[currentPromptId];
        p.startTime = block.timestamp;
        p.endTime = endTime;
        p.minChars = minChars;
        p.maxChars = maxChars;

        emit PromptCreated(
            instanceId,
            currentPromptId,
            msg.sender,
            prompt,
            block.timestamp,
            endTime,
            minChars,
            maxChars
        );
        currentPromptId += 1;
    }

    function respond(
        uint256 instanceId,
        uint256 promptId,
        string memory response
    ) public {
        if (instances[instanceId].allowedResponders[msg.sender] == false) {
            revert NotAllowed();
        }

        if (promptId >= currentPromptId) revert InvalidPromptID();
        if (prompts[promptId].endTime < block.timestamp) revert PromptExpired();
        if (prompts[promptId].responses[msg.sender]) revert AlreadyResponded();
        if (bytes(response).length < prompts[promptId].minChars)
            revert ResponseTooShort();
        if (bytes(response).length > prompts[promptId].maxChars)
            revert ResponseTooLong();

        prompts[promptId].responses[msg.sender] = true;
        emit PromptResponse(promptId, msg.sender, response);
    }

    // TODO - add in signer thingy
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

interface IPrompty {
    struct PromptyInstance {
        uint256 id;
        string name;
        bool isVisible;
        string description;
        mapping(address => bool) allowedResponders;
    }

    struct Prompt {
        uint256 startTime;
        uint256 endTime;
        uint128 minChars;
        uint128 maxChars;
        mapping(address => bool) responses;
    }

    event PromptCreated(
        uint256 instanceId,
        uint256 promptId,
        address creator,
        string prompt,
        uint256 startTime,
        uint256 endTime,
        uint128 minChars,
        uint128 maxChars
    );

    event PromptResponse(uint256 promptId, address responder, string response);
    event ResponderAdded(uint256 instanceId, address responder);
    event InstanceCreated(
        uint256 id,
        string name,
        string description,
        bool isVisible
    );
    event InstanceUpdated(
        uint256 id,
        string name,
        string description,
        bool isVisible
    );

    error InvalidPrompt();
    error InvalidPromptParams();
    error InvalidPromptID();
    error PromptExpired();
    error AlreadyResponded();
    error ResponseTooShort();
    error ResponseTooLong();
    error NotAllowed();

    function createInstance(
        address[] memory allowedResponders,
        string memory name,
        string memory description,
        bool isVisible
    ) external;

    function updateSettings(
        uint256 instanceId,
        string memory newName,
        string memory newDescription,
        bool newIsVisible,
        address[] memory newAllowedResponders
    ) external;

    function addResponders(
        uint256 instanceID,
        address[] memory allowedResponders
    ) external;

    function createPrompt(
        uint256 instanceId,
        string memory prompt,
        uint256 endTime,
        uint128 minChars,
        uint128 maxChars
    ) external;

    function respond(
        uint256 instanceId,
        uint256 promptId,
        string memory response
    ) external;
}