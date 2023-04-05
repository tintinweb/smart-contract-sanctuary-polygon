/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Billboard {
    struct Message {
        string text;
        address poster;
        uint timestamp;
        uint bidValue;
    }

    struct Reply {
        string text;
        address poster;
        uint timestamp;
        uint tip;
    }

    Message[] private messages;
    mapping(uint => uint[]) private tips;

    mapping(uint => Reply[]) private replies;
    address public owner;

    mapping(address => string) public addressToUsername;
    mapping(string => address) public usernameToAddress;

    uint private minBidIncrement; // = 1000000000000000; // 0.001 ETH
    uint private bidResetDuration; // = 4 hours;

    /**
     * @dev Set contract deployer as owner
     */
    constructor(string memory _initialMessageText, uint _minBidIncrement, uint _bidResetDuration) {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        messages.push(
            Message({
                text: _initialMessageText,
                poster: msg.sender,
                timestamp: block.timestamp,
                bidValue: 0
            })
        );
        minBidIncrement = _minBidIncrement;
        bidResetDuration = _bidResetDuration;
    }

    function register(string calldata username) external {
        // username must belong to address or be available
        require(usernameToAddress[username] == msg.sender || usernameToAddress[username] == address(0), "Username already taken");
        // clear old username if re-registering
        usernameToAddress[addressToUsername[msg.sender]] = address(0);
        addressToUsername[msg.sender] = username;
        usernameToAddress[username] = msg.sender;
    }

    function getMinBidIncrement() external view returns (uint) {
        return minBidIncrement;
    }

    function setMinBidIncrement(uint newMinBidIncrement) external {
        minBidIncrement = newMinBidIncrement;
    }

    function getBidResetDuration() external view returns (uint) {
        return bidResetDuration;
    }

    function setBidResetDuration(uint newBidResetDuration) external {
        bidResetDuration = newBidResetDuration;
    }

    function setMessage(string calldata messageText) external payable {
        uint lastBid;
        if (block.timestamp - messages[messages.length - 1].timestamp >= bidResetDuration) {
            lastBid = 0; // reset bid if enough time has passed
        } else {
            lastBid = messages[messages.length - 1].bidValue;
        }
        require(
            msg.value >= lastBid + minBidIncrement,
            "Bid is too small"
        );
        messages.push(
            Message({
                text: messageText,
                poster: msg.sender,
                timestamp: block.timestamp,
                bidValue: msg.value
            })
        );
    }

    // Gets message from end of array, returns message, username, replyCount, tips
    function getMessage(uint index) external view returns (Message memory, string memory, uint, uint[] memory) {
        require(index < messages.length, "Index does not exist");
        Message memory message = messages[index];
        return (message, addressToUsername[message.poster], getReplyCount(index), tips[index]);
    }

    // sends a tip to the poster of message at messageIndex
    function sendTip(uint messageIndex) public payable {
        require(messageIndex < messages.length, "Message does not exist");
        require(msg.value > 0, "Can't send 0 tip");
        Message storage message = messages[messageIndex];
        payable(message.poster).transfer(msg.value);
        tips[messageIndex].push(msg.value);
    }

    function getMessageCount() external view returns (uint) {
        return messages.length;
    }

    function sendReply(uint messageIndex, string calldata replyText) external payable {
        require(messageIndex < messages.length, "Message does not exist");
        if (msg.value > 0) {
            sendTip(messageIndex);
        }
        replies[messageIndex].push(
            Reply({
                text: replyText,
                poster: msg.sender,
                timestamp: block.timestamp,
                tip: msg.value
            })
        );
    }

    function getReplyCount(uint messageIndex) public view returns (uint) {
        return replies[messageIndex].length;
    }

    function getReply(
        uint messageIndex,
        uint replyIndex
    ) external view returns (Reply memory, string memory) {
        require(messageIndex < messages.length, "Message does not exist");
        require(
            replyIndex < replies[messageIndex].length,
            "Reply does not exist"
        );
        Reply memory reply = replies[messageIndex][replyIndex];
        return (reply, addressToUsername[reply.poster]);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only contract owner can withdraw");
        uint contractBalance = address(this).balance;
        require(contractBalance > 0, "Nothing to withdraw");
        payable(owner).transfer(contractBalance);
    }
}