// SPDX-License-Identifier: UNLICENSED0
pragma solidity ^0.8.9;

import "./Structures.sol";
contract Chat {
    Structures structures;
     constructor() {
    structures = Structures(0x6C330e24A6BDfDf8017994C134E20FE35C38D03A);
}
    enum DeletionStatus {
        NotDeleted,
        DeletedBySender,
        DeletedByReceiver,
        DeletedBoth
    }

     struct Message {
        uint256 id;
        address sender;
        address receiver;
        string subject;
        string message;
        uint256 timestamp;
        bool read;
        bool shareable;
        address[] viewedBy;
        uint256 originalMessageId;
        string fileHash;
        string receiversGroup;
        DeletionStatus deleted;
    }
    
    mapping(uint256 => bool) public rep;

    struct Reply {
       Message [] responses;
       bool rep;
    }

    mapping (uint256 => Reply) public replies;
    Message[] public messages;

function getAllArays() public view returns(Message[] memory) {
    return messages;
}

function getReplies(uint256 id) public view returns(Reply memory) {
    return replies[id];
}

    function replyTo(uint256 messageId, string memory response, Message memory messageOriginal, uint256 timestamp) external {
    if (replies[messageId].responses.length == 0) {
        replies[messageId].responses.push(messageOriginal);
        addReply(messageId, response, messageOriginal, true, timestamp);
    } else {
        addReply(messageId, response, messageOriginal, false, timestamp);
    }
}

function addReply(uint256 messageId, string memory response, Message memory messageOriginal, bool setRep, uint256 timestamp) private {
    uint256 messageTimestamp = (timestamp != 0) ? timestamp : block.timestamp;
    Message memory message = Message(
        messageCount,
        msg.sender,
        messageOriginal.sender,
        messageOriginal.subject,
        response,
        messageTimestamp,
        false,
        false,
        new address[](0),
        messageCount,
        messageOriginal.fileHash,
        messageOriginal.receiversGroup,
        DeletionStatus.NotDeleted
    );
    rep[messageCount] = true;
    messages.push(message);
    replies[messageId].responses.push(message);

    if (setRep) {
        replies[messageId].rep = true;
    }

    messageCount++;
}

    


    uint256 messageCount;
    uint256 shareCount;

      struct Share {
        uint256 messageId;
        uint256 timestamp;
        address sender;
        address receiver;
    }
    

     Share[] public shares;
    event MessageShared(
        uint256 shareId,
        uint256 messageId,
        address sender,
        address[] receivers
    );
     

      function sendMessage(
        address receiver,
        string calldata subject,
        string memory message,
        bool isShareable,
        string memory fileHash,
        string memory receiverGroup,
        uint256 timestamp
    ) external {
        require(
            structures.checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        require(structures.checkUserExists(receiver) == true, "Recipient does not exist");

        uint256 messageTimestamp = (timestamp != 0) ? timestamp : block.timestamp;

        Message memory message = Message(
            messageCount,
            msg.sender,
            receiver,
            subject,
            message,
            messageTimestamp,
            false,
            isShareable,
                new address[](0),
                messageCount,
            fileHash,
            receiverGroup,
            DeletionStatus.NotDeleted
        );
        rep[messageCount] = false;
        messages.push(message);
        messageCount++;
    }

   function sendMessageToGroup(address[] memory receiver, string calldata subject, string []memory message, string []memory cciMessages,bool isShareble, string memory fileHash, string memory emailGroup, address[] memory cciReceivers, uint256 timestamp) external {
        require(
            structures.checkUserExists(msg.sender) == true,
            "You must have an account"
        );

        uint256 messageTimestamp = (timestamp != 0) ? timestamp : block.timestamp;

        for(uint i = 0; i<receiver.length; i++){
            require(structures.checkUserExists(receiver[i]) == true, "Recipient does not exist");
            Message memory message = Message(messageCount, msg.sender, receiver[i], subject, message[i], messageTimestamp, false, isShareble,
                new address[](0),
                messageCount, fileHash, emailGroup,DeletionStatus.NotDeleted);
                rep[messageCount] = false;
        messages.push(message);
        messageCount++;
        }
        for(uint i = 0; i<cciReceivers.length; i++){
            require(structures.checkUserExists(cciReceivers[i]) == true, "Recipient does not exist");
            Message memory message = Message(messageCount, msg.sender, cciReceivers[i], subject, cciMessages[i], messageTimestamp, false, isShareble,
                new address[](0),
                messageCount,fileHash, '',DeletionStatus.NotDeleted);
                rep[messageCount] = false;
        messages.push(message);
        messageCount++;
        }

        }      

         function shareMessage(uint256 messageId, address[] calldata receivers) external {
    require(messageId < messages.length, "Invalid message ID");
    require(structures.checkUserExists(msg.sender) == true, "You must have an account");
    Message storage messageToShare = messages[messageId];
    uint256 originalMessageid = messages[messageId].originalMessageId;
    require(messageToShare.shareable == true, "Message is not shareable");

    for (uint256 i = 0; i < receivers.length; i++) {
        require(structures.checkUserExists(receivers[i]), "Receiver does not exist");
        Share memory newShare = Share(messageId, block.timestamp, msg.sender, receivers[i]);
        shares.push(newShare);
        
        // Set the originalMessageId of the shared message to the ID of the original message
        Message memory sharedMessage = Message(
            messageCount,
            msg.sender,
            receivers[i],
            messageToShare.subject,
            messageToShare.message,
            block.timestamp,
            false,
            true,
            new address[](0),
            messages[messageId].originalMessageId,
            messageToShare.fileHash,
            messageToShare.receiversGroup,
            DeletionStatus.NotDeleted
        );
        messageCount++;
        messages.push(sharedMessage);
        rep[messageCount] = false;
    }
    emit MessageShared(shareCount, messageId, msg.sender, receivers);
    shareCount++;
}


    function getViewedBy(uint256 messageId) public view returns (address[] memory) {
        return messages[messageId].viewedBy;
    }

function viewMessage(uint256 messageId) public {
    uint256 originalMessageid = messages[messageId].originalMessageId;
    messages[messageId].read= true;
    messages[originalMessageid].read= true;

    bool found = false;
    for (uint256 i = 0; i < messages[messageId].viewedBy.length; i++) {
        if (messages[messageId].viewedBy[i] == msg.sender) {
            found = true;
            break;
        }
    }
    if (!found) {
        messages[messageId].viewedBy.push(msg.sender);
    }

    found = false;
    for (uint256 i = 0; i < messages[originalMessageid].viewedBy.length; i++) {
        if (messages[originalMessageid].viewedBy[i] == msg.sender) {
            found = true;
            break;
        }
    }
    if (!found) {
        messages[originalMessageid].viewedBy.push(msg.sender);
    }
}

function getShares(uint256 messageId) external view returns (Share[] memory) {
        require(messageId < messages.length, "Invalid message ID");

        uint256 count = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            if (messages[messageId].originalMessageId == messageId ) {
                count++;
            }
        }
        Share[] memory messageShares = new Share[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            if (messages[messageId].originalMessageId == messageId) {
                messageShares[index] = shares[i];
                index++;
            }
        }
        return messageShares;
    }

    function deleteMessage(address walletAddress, uint256 id) public {
        require(
            structures.checkUserExists(walletAddress),
            "User with given address does not exist."
        );
        Message storage message = messages[id];
        if (message.sender == walletAddress) {
            if (message.deleted == DeletionStatus.DeletedByReceiver) {
                message.deleted = DeletionStatus.DeletedBoth;
            } else {
                message.deleted = DeletionStatus.DeletedBySender;
            }
        }
        if (message.receiver == walletAddress) {
            if (message.deleted == DeletionStatus.DeletedBySender) {
                message.deleted = DeletionStatus.DeletedBoth;
            } else {
                message.deleted = DeletionStatus.DeletedByReceiver;
            }
        }
    }


   
}

// SPDX-License-Identifier: UNLICENSED0
pragma solidity ^0.8.9;

import "./Structures.sol";
import { Chat } from "./Chat.sol";

contract Operations {
    Structures structures;
    Chat chat;

    constructor() {
        structures = Structures(0x6C330e24A6BDfDf8017994C134E20FE35C38D03A);
        chat = Chat(0x1690926D949E258f61b9095EFAA0bF0D34A71171);
    }

    function getMessagesCount(string memory email) public view returns (uint) {
        uint count = 0;
        Chat.Message[] memory messages = chat.getAllArays();

        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == structures.getAddress(email)) {
                count++;
            }
        }

        return count;
    }


    function MessageSent(string memory email) public view returns (Chat.Message[] memory) {
        uint count = 0;
        Chat.Message[] memory messages = chat.getAllArays();

        for (uint i = 0; i < messages.length; i++) {
            if (
                (messages[i].sender == structures.getAddress(email)) &&
                (messages[i].deleted != Chat.DeletionStatus.DeletedBySender) &&
                (messages[i].deleted != Chat.DeletionStatus.DeletedBoth)
            ) {
                count++;
            }
        }

        Chat.Message[] memory messagesSent = new Chat.Message[](count);
        uint index = 0;

        for (uint i = 0; i < messages.length; i++) {
            if (
                (messages[i].sender == structures.getAddress(email)) &&
                (messages[i].deleted != Chat.DeletionStatus.DeletedBySender) &&
                (messages[i].deleted != Chat.DeletionStatus.DeletedBoth)
            ) {
                messagesSent[index] = messages[i];
                index++;
            }
        }

        return messagesSent;
    }

    function MessageReceived(string memory email) public view returns (Chat.Message[] memory) {
        uint count = 0;
        Chat.Message[] memory messages = chat.getAllArays();

        for (uint i = 0; i < messages.length; i++) {
            if (
                (messages[i].receiver == structures.getAddress(email)) &&
                (messages[i].timestamp <= block.timestamp) &&
                (messages[i].deleted != Chat.DeletionStatus.DeletedByReceiver) &&
                (messages[i].deleted != Chat.DeletionStatus.DeletedBoth)
            ) {
                count++;
            }
        }

        Chat.Message[] memory messagesReceived = new Chat.Message[](count);
        uint index = 0;

        for (uint i = 0; i < messages.length; i++) {
            if (
                (messages[i].receiver == structures.getAddress(email)) &&
                (messages[i].timestamp <= block.timestamp) &&
                (messages[i].deleted != Chat.DeletionStatus.DeletedByReceiver) &&
                (messages[i].deleted != Chat.DeletionStatus.DeletedBoth)
            ) {
                messagesReceived[index] = messages[i];
                index++;
            }
        }

        return messagesReceived;
    }
    
}

// SPDX-License-Identifier: UNLICENSED0
pragma solidity ^0.8.9;

contract Structures {
    struct User {
        string name;
        string email;
        bool exists;
        address walletAddress;
        bool isAdmin;
    }
    struct Secure {
        bytes32 seed;
        bytes32 password;
        bytes pubKey;
    }

    struct ID {
        bytes32 ID;
        string email;
    }

    ID[] public IDs;

   //mapping(bytes32 => string) public IDs;
    mapping(address => Secure) public Keys;
    mapping(address => User) public users;
    address[] public userAddresses;
    address public admin;
     constructor() {
        admin = 0x7B60eD2A82267aB814256d3aB977ae5434d01d8b;
    }

    event LogString(uint message);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    //makeAdmin : to make someone an admin we change isAdmin=>true
    function makeAdmin(address userAddress) public onlyAdmin {
        users[userAddress].isAdmin = true;
    }

    function createUserId(string memory email, bytes32 Id) public onlyAdmin {
        ID memory id =  ID(Id, email);
        IDs.push(id);
    }

    // Define a new role for admins
    mapping(address => bool) private admins;

    function isAdmin(address user) public view returns (bool) {
        return admins[user];
    }

    function addAdmin(address userAddress) public onlyAdmin {
        admins[userAddress] = true;
    }

    function removeAdmin(address userAddress) public onlyAdmin {
        admins[userAddress] = false;
        users[userAddress].isAdmin = false;
    }
   mapping(string => address) usersByName;
    mapping(string => address) usersByEmail;
    //--------------------------------------------------------------------------------------

    function stringsEqual(
        string memory a,
        string memory b
    ) private pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function verifyUser(uint id, string memory email) public view returns (bool) {
    bytes32 idHash = sha256(abi.encode(id));
    for (uint256 i = 0; i < IDs.length; i++) {
        if (IDs[i].ID == idHash && stringsEqual(IDs[i].email, email)) {
            return true;
        }
    }
    revert("You don't have permission to create an account!");
}


    //Creat user
    function createUser(
        uint Id,
        string memory name,
        string memory email,
        address walletAddress,
        bytes32 seed,
        bytes32 password,
        bytes memory pubKey
    ) public {
        require(bytes(name).length > 0, "You have to specify your name !");
        User memory user = User(name, email, true, walletAddress, false);
        Secure memory secure = Secure(seed, password, pubKey);
        users[walletAddress] = user;
        userAddresses.push(walletAddress);
        usersByName[name] = walletAddress;
        usersByEmail[email] = walletAddress;
        Keys[walletAddress] = secure;
        bytes32 idHash = sha256(abi.encode(Id));
    for (uint256 i = 0; i < IDs.length; i++) {
        if (IDs[i].ID == idHash) {
            uint256 lastIndex = IDs.length - 1;
            if (i != lastIndex) {
                IDs[i] = IDs[lastIndex];
            }
            IDs.pop();
            return;
        }
    }
    revert("ID not found");
    }

    //Delete user
    function deleteUser(address walletAddress) public onlyAdmin {
        require(
            walletAddress != address(0),
            "User with given address does not exist."
        );
        delete users[walletAddress];
        delete usersByName[users[walletAddress].name];
        delete usersByEmail[users[walletAddress].email];
        delete Keys[walletAddress];
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == walletAddress) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break;
            }
        }
        //emit UserDeleted(walletAddress);
    }

    function checkUserExists(address user) public view returns (bool) {
        return bytes(users[user].email).length > 0;
    }

    //event MessageSent(address indexed sender, address indexed receiver, bytes32 encryptedMessage);

    function getRecieverPubKey(
        address receiver
    ) public view returns (bytes memory) {
        bytes memory pubKey = Keys[receiver].pubKey;
        return pubKey;
    }

    function verifyPassword(
        address sender,
        bytes32 password
    ) public view returns (bool) {
        require(Keys[sender].password == password, "Invalid Password");
        return true;
    }

    function verifySeed(
        address sender,
        bytes32 seed
    ) public view returns (bool) {
        require(Keys[sender].seed == seed, "Invalid Seed");
        return true;
    }

    function getAddress(string memory email) public view returns (address) {
        return usersByEmail[email];
    }

    function getName(address adresse) external view returns (string memory) {
        require(
            checkUserExists(adresse) == true,
            "User with given address don't exist"
        );
        return users[adresse].name;
    }

    function getEmail(address adresse) external view returns (string memory) {
        require(
            checkUserExists(adresse) == true,
            "User with given address don't exist"
        );
        return users[adresse].email;
    }
   function getAllUsers() public view returns (User[] memory) {
        User[] memory allUsers = new User[](userAddresses.length);
        for (uint i = 0; i < userAddresses.length; i++) {
            allUsers[i] = users[userAddresses[i]];
        }
        return allUsers;
    }

     function getAllUsersIDsBackup() public view returns (ID[] memory) {
        ID[] memory IDsBackup = new ID[](IDs.length);
        for (uint i = 0; i < IDs.length; i++) {
            IDsBackup[i] = IDs[i];
        }
        return IDsBackup;
    }

    function getAllUsersIDs() public view returns (ID[] memory) {
        return IDs;
    }

    function editUser(
        address walletAddress,
        string memory name,
        string memory email,
        bool isAdmin
    ) public onlyAdmin {
        require(
            checkUserExists(walletAddress),
            "User with given address does not exist."
        );
        User storage user = users[walletAddress];
        user.name = name;
        user.email = email;
        user.isAdmin = isAdmin;
        usersByName[name] = walletAddress;
        usersByEmail[email] = walletAddress;
    
    }

}