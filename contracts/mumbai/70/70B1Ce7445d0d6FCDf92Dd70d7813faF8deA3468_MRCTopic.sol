// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "../security/ownable.sol";

enum TOKEN_EVENT {
    MINT,
    TRANSFER
}

struct TokenEventPayload {
    TOKEN_EVENT event_;
    address from;
    address to;
    uint256 amount;
}

contract MRCTopic is Ownable {
    struct Subscription {
        bytes data;
        function(TokenEventPayload memory) external callback;
        address subscriber;
    }

    Subscription[] private subscriptions;

    event Subscribe(uint256, address);
    event UnSubscribe(uint256, address);
    event Dispatch(uint256, TokenEventPayload);

    function subscribe(
        bytes memory data,
        function(TokenEventPayload memory) external callback
    ) public {
        subscriptions.push(Subscription(data, callback, msg.sender));
        emit Subscribe(subscriptions.length - 1, msg.sender);
    }

    function unsubscribe(uint256 requestID) public {
        require(subscriptions[requestID].subscriber == msg.sender);
        delete subscriptions[requestID];
        emit UnSubscribe(requestID, msg.sender);
    }

    function trigger(TokenEventPayload memory _event) public onlyOwner {
        for (uint256 i; i < subscriptions.length; i++) {
            subscriptions[i].callback(_event);
            emit Dispatch(i, _event);
        }
    }

    function dispatch(uint256 requestID, TokenEventPayload memory response)
        private
    {
        subscriptions[requestID].callback(response);
        emit Dispatch(requestID, response);
    }
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;

abstract contract Ownable {
    address payable internal immutable _owner;

    constructor() {
        _owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Access Denied");
        _;
    }
}