/**
 *Submitted for verification at polygonscan.com on 2022-03-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title 
 * @dev Implements a streaming message transfer contract
 */
contract Ballot {
   
    struct Message {
        uint amount;
        string message;
        uint256 timestamp;
    }

    struct Stream {
        uint id;
        mapping(uint => Message) messages;
        uint messageSize;
        address payable owner;
    }

   event MessageAdded(address indexed _from, uint _streamId, uint _amount, string _message);    
   event StreamCreated(uint index);

    Stream[] public streams;

    constructor() public payable {

    }

    function addStream () public payable returns (uint) {
        Stream storage newStream = streams.push();
        newStream.id = streams.length - 1;
        newStream.owner = payable(msg.sender);
        newStream.messageSize = 0;
        emit StreamCreated(newStream.id);
    }

     function sendMessage(uint stream_id, string memory messageStr, uint amount) public payable {
        streams[stream_id].owner.transfer(amount * 1000000000);
        uint messageSize = streams[stream_id].messageSize;
        streams[stream_id].messages[messageSize].amount = amount;
        streams[stream_id].messages[messageSize].message = messageStr;
        streams[stream_id].messages[messageSize].timestamp = Time_call();
        streams[stream_id].messageSize = streams[stream_id].messageSize + 1;
        emit MessageAdded(msg.sender, stream_id, amount, messageStr);
    }

    function getStream(uint stream_id) public returns (uint) {
        return streams[stream_id].id;
    }

    function getMessage(uint stream_id, uint message_id) external view returns (string memory) {
        return streams[stream_id].messages[message_id].message;
    }

    function Time_call()  public returns (uint256){
        return block.timestamp;
    }
}