// SPDX-License-Identifier: UNLICENSED0
pragma solidity ^0.8.9;


contract Chat {
    struct User {
        string name;
        string email;
        bool exists;
    }
    
    struct Message {
        address sender;
        address receiver;
        string subject;
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
    mapping(string => address) usersByEmail;
    
    constructor() {
        admin = 0xadfB6794D98287189e6F2C89C8cbA7323C9B9F87;
        users[0xadfB6794D98287189e6F2C89C8cbA7323C9B9F87] = User("Admin", "[email protected]", true);
        userAddresses.push(0xadfB6794D98287189e6F2C89C8cbA7323C9B9F87);
        users[0x6C9d06565Ab7de6BA3d85A203a0953F3BbF893DD] = User("H'nifa", "[email protected]", true);
        userAddresses.push(0x6C9d06565Ab7de6BA3d85A203a0953F3BbF893DD);
        usersByName["H'nifa"] = 0x6C9d06565Ab7de6BA3d85A203a0953F3BbF893DD;
        usersByName["Admin"] = 0xadfB6794D98287189e6F2C89C8cbA7323C9B9F87;
        usersByEmail["[email protected]"] = 0x6C9d06565Ab7de6BA3d85A203a0953F3BbF893DD;
        usersByEmail["[email protected]"] = 0xadfB6794D98287189e6F2C89C8cbA7323C9B9F87;

    }
    
    event LogString(uint message);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    

    function createUserId(string memory email, bytes32 Id) public onlyAdmin{
        IDs[Id] = email;
    }    

    function stringsEqual(string memory a, string memory b) private pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function createUser(uint Id, string memory name, string memory email, address walletAddress) public  {
        require(stringsEqual(IDs[sha256(abi.encode(Id))], email), "You don't have permission to create an account !");
        require(bytes(name).length > 0, "You have to specify your name !");
        User memory user = User(name, email, true);
        users[walletAddress] = user;
        userAddresses.push(walletAddress);
        usersByName[name] = walletAddress;
        usersByEmail[email] = walletAddress;
        delete IDs[sha256(abi.encode(Id))];
    }

    function checkUserExists(address user) public view returns (bool) {
        return bytes(users[user].email).length > 0;
    }
    
    //event MessageSent(address indexed sender, address indexed receiver, bytes32 encryptedMessage);

    // Send message function
    function sendMessage(address receiver, string calldata subject, string calldata message) external {
        require(
            checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        require(checkUserExists(receiver) == true, "Recipient does not exist");
        Message memory message = Message(msg.sender, receiver, subject, message, block.timestamp, false);
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

    function getEmail(address adresse) external view returns (string memory) {
        require(checkUserExists(adresse) == true,"User with given address don't exist");
        return users[adresse].email;
    }

    function getAddress(string memory email) public view returns (address) {
        return usersByEmail[email];
    }

        function getMessagesCount(string memory email) public view returns (uint){
            uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == getAddress(email)) {
                count++;
            }
        }
        return count;
        }

        function MessageSent(string memory email) public view returns (Message[] memory) {
        uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == getAddress(email)) {
                count++;
            }
        }
        Message[] memory messagesSent = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == getAddress(email)) {
                messagesSent[index] = messages[i];
                index++;
            }
        }
        return messagesSent;
    }

    function MessageReceived(
        string memory email
    ) public view returns (Message[] memory) {  
        uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].receiver == getAddress(email)) {
                count++;
            }
        }
        Message[] memory messagesRecieved = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].receiver == getAddress(email)) {
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