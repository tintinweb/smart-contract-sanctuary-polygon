// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DSNS {
    uint256 internal messageCount;

    struct Message {
        uint256 id;
        string content;
        uint256 createdAt;
        address owner;
        uint256 conutOfLikes;
    }

    Message[] internal messages;

    mapping(address => uint256[]) internal likedMessageIdsOf;

    constructor() {}

    /// @notice Sort (quicksort) messages by number of likes
    /// @dev The value of messages passed by reference is rewritten in the function.
    function quickSortByCountOfLikes(
        Message[] memory _messages,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = _messages[uint256(left + (right - left) / 2)]
            .conutOfLikes;
        while (i <= j) {
            while (_messages[uint256(i)].conutOfLikes > pivot) i++;
            while (pivot > _messages[uint256(j)].conutOfLikes) j--;
            if (i <= j) {
                (_messages[uint256(i)], _messages[uint256(j)]) = (
                    _messages[uint256(j)],
                    _messages[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSortByCountOfLikes(_messages, left, j);
        if (i < right) quickSortByCountOfLikes(_messages, i, right);
    }

    /// @notice Sort (quicksort) messages by number of createdAt
    /// @dev The value of messages passed by reference is rewritten in the function.
    function quickSortByCreatedAt(
        Message[] memory _messages,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = _messages[uint256(left + (right - left) / 2)].createdAt;
        while (i <= j) {
            while (_messages[uint256(i)].createdAt > pivot) i++;
            while (pivot > _messages[uint256(j)].createdAt) j--;
            if (i <= j) {
                (_messages[uint256(i)], _messages[uint256(j)]) = (
                    _messages[uint256(j)],
                    _messages[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSortByCreatedAt(_messages, left, j);
        if (i < right) quickSortByCreatedAt(_messages, i, right);
    }

    /// @notice Judge if the liker has already liked the message of messageId
    /// @return result of the judge, index in the likedMessageIds (if judge is true)
    function judgeHasLiked(address liker, uint256 messageId)
        internal
        view
        returns (bool, uint256)
    {
        uint256[] memory likedMessageIds = likedMessageIdsOf[liker];
        for (uint256 index = 0; index < likedMessageIds.length; index++) {
            if (likedMessageIds[index] == messageId) {
                return (true, index);
            }
        }
        return (false, 0);
    }

    /// @notice Get a list of messages sorted according to sortKey
    function listMessages(bytes32 sortKey)
        public
        view
        returns (Message[] memory)
    {
        Message[] memory _messages = messages;
        if (sortKey == "createdAt") {
            quickSortByCreatedAt(
                _messages,
                int256(0),
                int256(messages.length - 1)
            );
        } else if (sortKey == "countOfLikes") {
            quickSortByCountOfLikes(
                _messages,
                int256(0),
                int256(messages.length - 1)
            );
        }
        return _messages;
    }

    /// @notice Execute like or cancel to like for a message with messageId
    function likeMessage(uint256 messageId) public {
        (bool hasLiked, uint256 index) = judgeHasLiked(msg.sender, messageId);
        if (hasLiked) {
            // Transaction to cancel a like
            // Pop the id of the message to be unliked from the sender's likedMessageIds
            uint256[] storage likedMessageIds = likedMessageIdsOf[msg.sender];
            uint256 lastId = likedMessageIds[likedMessageIds.length - 1];
            likedMessageIds[index] = lastId;
            likedMessageIds.pop();
            // Reduce the number of likes for a message by 1.
            Message storage likedMessage = messages[messageId];
            likedMessage.conutOfLikes -= 1;
        } else {
            // Transaction to like
            likedMessageIdsOf[msg.sender].push(messageId);
            Message storage likedMessage = messages[messageId];
            likedMessage.conutOfLikes += 1;
        }
    }

    /// @notice Get a list of id's of messages that the sender has liked
    function likedMessageId() public view returns (uint256[] memory) {
        return likedMessageIdsOf[msg.sender];
    }

    /// @notice Create a message (message must be no more than 200 characters)
    function postMessage(string memory content) public {
        require(bytes(content).length <= 200);
        Message memory message = Message(
            messageCount,
            content,
            block.timestamp,
            msg.sender,
            0
        );
        messages.push(message);
        messageCount += 1;
    }
}