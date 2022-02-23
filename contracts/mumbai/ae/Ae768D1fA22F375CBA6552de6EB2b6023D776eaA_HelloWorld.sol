/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

contract HelloWorld {

    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    constructor(string memory initMessage){
        message = initMessage;
    }

    function update(string memory newMessage) public{
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}