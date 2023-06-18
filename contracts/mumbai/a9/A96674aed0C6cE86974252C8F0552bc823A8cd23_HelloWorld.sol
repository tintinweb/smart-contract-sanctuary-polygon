// SPDX-License-Identifier: Unlicensed
pragma solidity^0.8.0;

contract HelloWorld {
    event updatedMessages(string oldstr, string newstr);
    string public message;
    constructor(string memory initMessage){
        message=initMessage;
    }
    function updateMessage(string memory  newMessage)public{
        string memory oldMsg=message;
        message=newMessage;
        emit updatedMessages(oldMsg,newMessage);
        
    }
}