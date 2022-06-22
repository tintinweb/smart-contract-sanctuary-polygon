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

    function likeMessage(uint256 messageId) public returns (bool, uint256) {
        (bool hasLiked, uint256 index) = judgeHasLiked(msg.sender, messageId);
        if (hasLiked) {
            uint256[] storage likedMessageIds = likedMessageIdsOf[msg.sender];
            uint256 lastId = likedMessageIds[likedMessageIds.length - 1];
            likedMessageIds[index] = lastId;
            likedMessageIds.pop();
            Message storage likedMessage = messages[messageId];
            likedMessage.conutOfLikes -= 1;
        } else {
            likedMessageIdsOf[msg.sender].push(messageId);
            Message storage likedMessage = messages[messageId];
            likedMessage.conutOfLikes += 1;
        }
        return (hasLiked, index);
    }

    function likedMessageIdOf() public view returns (uint256[] memory) {
        return likedMessageIdsOf[msg.sender];
    }

    function createMessage(string memory content) public {
        require(bytes(content).length <= 200);
        Message memory message = Message(
            messageCount,
            content,
            block.timestamp,
            msg.sender,
            0
        );
        messages.push(message);
        messageCount++;
    }
}