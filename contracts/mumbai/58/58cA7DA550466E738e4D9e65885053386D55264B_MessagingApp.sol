// SPDX-License-Identifier: UNLICENSED0
pragma solidity ^0.8.9;


contract MessagingApp {
    struct User {
        string name;
        bool exists;
    }
    
    struct Message {
        address sender;
        address receiver;
        string message;
        uint256 timestamp;
        bool read;
    }

    
    mapping(bytes32 => string) public IDs;
    mapping (address => User) public users;
    address[] public userAddresses;
    address public admin;

    Message[] public messages;
    mapping(string => address) usersByName;
    
    constructor() {
        admin = 0x7B60eD2A82267aB814256d3aB977ae5434d01d8b;
        users[0x7B60eD2A82267aB814256d3aB977ae5434d01d8b] = User("Admin", true);
        users[0x8455022A4Ef3044A3B0949517D8aA0006054403d] = User("H'nifa", true);
        usersByName["H'nifa"] = 0x8455022A4Ef3044A3B0949517D8aA0006054403d;
        usersByName["Admin"] = 0x7B60eD2A82267aB814256d3aB977ae5434d01d8b;
    }
    
    event LogString(uint message);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    

    function createUserId(string memory name, bytes32 Id) public onlyAdmin{
        IDs[Id] = name;
    }    

    function stringsEqual(string memory a, string memory b) private pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function createUser(uint Id, string memory name, address walletAddress) public  {
        require(stringsEqual(IDs[sha256(abi.encode(Id))], name), "You don't have permission to create an account !");
        User memory user = User(name, true);
        users[walletAddress] = user;
        userAddresses.push(walletAddress);
        usersByName[name] = walletAddress;
        delete IDs[sha256(abi.encode(Id))];
    }

    function checkUserExists(address user) public view returns (bool) {
        return bytes(users[user].name).length > 0;
    }
    
    //event MessageSent(address indexed sender, address indexed receiver, bytes32 encryptedMessage);

    // Send message function
    function sendMessage(address receiver, string calldata message) external {
        require(
            checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        require(checkUserExists(receiver) == true, "Recipient does not exist");
        bytes32 messageHash = sha256(bytes(message)); // Create message hash
        Message memory message = Message(msg.sender, receiver, message, block.timestamp, false);
        messages.push(message);
        //emit MessageSent(msg.sender, receiver, messageHash);
        }

        function getName(address adresse) external view returns (string memory) {
        require(
            checkUserExists(adresse) == true,
            "User with given address don't exist"
        );
        return users[adresse].name;
    }

    function getAddress(string memory name) public view returns (address) {
        return usersByName[name];
    }

        function getMessagesCount(string memory name) public view returns (uint){
            uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == getAddress(name)) {
                count++;
            }
        }
        return count;
        }

        function MessageSent(string memory name) public view returns (Message[] memory) {
        uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == getAddress(name)) {
                count++;
            }
        }
        Message[] memory messagesSent = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == getAddress(name)) {
                messagesSent[index] = messages[i];
                index++;
            }
        }
        return messagesSent;
    }

    function MessageReceived(
        string memory name
    ) public view returns (Message[] memory) {  
        uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].receiver == getAddress(name)) {
                count++;
            }
        }
        Message[] memory messagesRecieved = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].receiver == getAddress(name)) {
                messagesRecieved[index] = messages[i];
                index++;
            }
        }
        return messagesRecieved;
    }




    // Get sent messages function
    /*function getSentMessages() public view returns (Message[] memory) {
        return sentMessages[msg.sender];
    }
    
    // Get received messages function
    function getReceivedMessages() public view returns (Message[] memory) {
        return receivedMessages[msg.sender];
    }*/
    
    // Decrypt and read message function
    /*function readMessage(uint256 _index, bytes32 _key, RSA.PrivateKey memory _privateKey) public {
        Message memory message = receivedMessages[msg.sender][_index];
        require(message.receiver == msg.sender, "You are not the intended recipient of this message.");
        
        bytes memory decryptedKey = decryptMessageRSA(message.encryptedKey, _privateKey);
        bytes32 decryptedKey32 = bytesToBytes32(decryptedKey);
        
        string memory decryptedMessage = decryptMessage(message.encryptedMessage, decryptedKey32);
        
        emit MessageReceived(message.sender, message.receiver, message.encryptedMessage);
    }
    
    // Utility function to convert bytes to bytes32
    function bytesToBytes32(bytes memory _bytes) private pure returns (bytes32 result) {
    	require(_bytes.length >= 32, "Byte array must be at least 32 bytes long.");
    	assembly {
        result := mload(add(_bytes, 32))
    	}
   }*/

}