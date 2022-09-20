//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../../src/oracle/ITweetRelayerClient.sol";
import "../../src/oracle/ITweetRelayer.sol";


contract MockTweetRelayerClient is ITweetRelayerClient {
    bytes32 public requestId;
    uint public value;
    uint public value2;

    ITweetRelayer private immutable _tweetRelayer;

    constructor(address tweetRelayer_) {
        _tweetRelayer = ITweetRelayer(tweetRelayer_);
    }

    function onTweetInfoReceived(bytes32 requestId_, uint value_) public {
        requestId = requestId_;
        value = value_;
    }

    function onTweetPosted(bytes32 requestId_, uint createdAt_, uint tweetId_) public{
        requestId = requestId_;
        value = createdAt_;
        value2 = tweetId_;
    }

    function requestLikeCount(uint tweetId) public {
        requestId = _tweetRelayer.requestTweetLikeCount(tweetId);
    }

    function requestTweetPublication(bytes20 postId, bytes20 adId) public {
        requestId = _tweetRelayer.requestTweetPublication(postId, adId);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

interface ITweetRelayerClient {
    /** 
    /* @notice ensure that these functions can only be called by the Twitter Relayer. Also, note that these function needs to use less than 400000 gas.
    */
    function onTweetInfoReceived(bytes32 requestId_, uint value_) external;
    function onTweetPosted(bytes32 requestId_, uint createdAt_, uint tweetId_) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

interface ITweetRelayer {
    function requestTweetData(string memory tweetId_, string memory fields_, string memory path_) external returns (bytes32 requestId);
    function requestTweetLikeCount(uint tweetId_) external returns (bytes32 requestId);
    function requestTweetPublication(bytes20 postId_, bytes20 adId_) external returns (bytes32 requestId);
}