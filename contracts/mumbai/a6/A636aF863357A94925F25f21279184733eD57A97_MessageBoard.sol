/**
 *Submitted for verification at polygonscan.com on 2023-02-11
*/

pragma solidity >=0.5.0 <0.7.0;
//SPDX-License-Identifier: UNLICENSED
contract MessageBoard {
    struct Message {
        string text;
        address sender;
    }

    Message[] public messages;

    function addMessage(string memory _text) public {
        messages.push(Message({
            text: _text,
            sender: msg.sender
        }));
    }

    function getMessage(uint index) public view returns (string memory, address) {
        return (messages[index].text, messages[index].sender);
    }

    function getMessageCount() public view returns (uint) {
        return messages.length;
    }
}