/**
 *Submitted for verification at polygonscan.com on 2022-09-27
*/

pragma solidity ^0.4.18;

//Contract is just like classes
contract MessageBoard {
    //Defining User structure. address is a variable type from solidity
    struct User {
        address _address;
        string name;
        bool isValue;
    }

    //Defining Message structure. You can see it have User type member
    struct Message {
        string text;
        User _user;
    }
    
    //Declaring an event

    event MessageCreated (Message message);

    //Constructor
    function MessageBoard() public {

    }

    //mapping is a key value store. We are specified type of key and value
    mapping (address => User) users;

    // public function, which is returning boolean
    function setUsername(string name) public returns (bool) {
        //require() is throwing error, if the input is not true
        //require(userExists(msg.sender) == false);
        //msg.sender is the address, from where the signUp was called.
        users[msg.sender] = User(msg.sender, name, true);
        return true;
    }

    //8 bit unsigned integer (so no negative values).
    uint8 public messageCount;
    
    //it is creating an event Message with text and user.
    function sendMessage (string text) public returns (bool) {
        //require() is throwing error, if the input is not true
        //require(userExists(msg.sender));
        messageCount++;
        MessageCreated(Message(text, users[msg.sender]));
        return true;
    }
    
    //We are using view keyword, to specify that it is not modified the state of contract. It will consume less resources. 
    function userExists(address userAddress) view public returns (bool) {
        return users[userAddress].isValue;
    }
}