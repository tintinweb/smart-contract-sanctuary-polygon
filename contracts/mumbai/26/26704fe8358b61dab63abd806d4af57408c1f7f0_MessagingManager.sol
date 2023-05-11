/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

contract MessagingManager{

    struct Message {
        address owner;
        string body;
        bool read;
    }

    Message[] private messages;
    

    function getAllMessages() public view returns (Message[] memory){
        return messages;
    }

    function writeMessage(string memory message) public {
        uint messageLength = bytes(message).length;
        assert(messageLength > 0 && messageLength <=300);
        messages.push(Message({owner:msg.sender, body:message, read:false}));
    }

    function markAllMessagesAsRead() public {
        assert(messages.length > 0);
        for(uint i=0; i<messages.length; i++){
            if(!messages[i].read){
              messages[i].read = true;
            }
        }
    }
}