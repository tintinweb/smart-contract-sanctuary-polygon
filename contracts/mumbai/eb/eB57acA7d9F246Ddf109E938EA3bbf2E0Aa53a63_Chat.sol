// SPDX-License-Identifier: UNLICENSED0
pragma solidity ^0.8.9;

import "./Structures.sol";
contract Chat {
    Structures structures;
     constructor() {
    structures = Structures(0x0A59Cd020A2FAB1039E9CA910A1f12c3C47feC86);
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
        //uint256 shares;
        //uint256 views;
        address[] viewedBy;
        uint256 originalMessageId;
        string fileHash;
        string receiversGroup;
        DeletionStatus deleted;
    }
    struct Share {
        uint256 messageId;
        uint256 timestamp;
        address sender;
        address receiver;
    }
    uint256 messageCount;
    uint256 shareCount;

     Share[] public shares;
    event MessageShared(
        uint256 shareId,
        uint256 messageId,
        address sender,
        address[] receivers
    );
      Message[] public messages;

      function sendMessage(
        address receiver,
        string calldata subject,
        string memory message,
        bool isShareable,
        string memory fileHash,
        string memory receiverGroup
    ) external {
        require(
            structures.checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        require(structures.checkUserExists(receiver) == true, "Recipient does not exist");
        //address[] memory receivers = new address[](1);
        //receivers[0] = receiver;
        Message memory message = Message(
            messageCount,
            msg.sender,
            receiver,
            subject,
            message,
            block.timestamp,
            false,
            isShareable,
               // 0,
               // 0,
                new address[](0),
                messageCount,
            fileHash,
            receiverGroup,
            DeletionStatus.NotDeleted
        );
        messages.push(message);
        //emit MessageSent(msg.sender, receiver, messageHash);
        messageCount++;
    }

    function sendMessageToGroup(
        address[] memory receiver,
        string calldata subject,
        string[] memory message,
        bool isShareable,
        string memory fileHash,
        string memory emailGroup
    ) external {
        require(
            structures.checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        for (uint i = 0; i < receiver.length; i++) {
            require(
                structures.checkUserExists(receiver[i]) == true,
                "Recipient does not exist"
            );
            Message memory message = Message(
                messageCount,
                msg.sender,
                receiver[i],
                subject,
                message[i],
                block.timestamp,
                false,
                isShareable,
                //0,
                //0,
                new address[](0),
                messageCount,
                fileHash,
                emailGroup,
                DeletionStatus.NotDeleted
            );
            messages.push(message);
            messageCount++;
        }

            //emit MessageSent(msg.sender, receiver, messageHash);
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
        //messageToShare.shares++;
       // messages[originalMessageid].shares++;
        
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
           // 0,
            //0,
            new address[](0),
            messages[messageId].originalMessageId,
            messageToShare.fileHash,
            messageToShare.receiversGroup,
            DeletionStatus.NotDeleted
        );
        messageCount++;
        messages.push(sharedMessage);
    }
    emit MessageShared(shareCount, messageId, msg.sender, receivers);
    shareCount++;
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

    function getViewedBy(uint256 messageId) public view returns (address[] memory) {
        return messages[messageId].viewedBy;
    }

function viewMessage(uint256 messageId) public {
    uint256 originalMessageid = messages[messageId].originalMessageId;
   // messages[messageId].views++;
    //messages[originalMessageid].views++;
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



    function deleteMessage(address walletAddress, uint256 id) public {
        require(
            structures.checkUserExists(walletAddress),
            "User with given address does not exist."
        );
        Message storage message = messages[id];
        //Message storage message = getMessageById(id);
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
     function getMessagesCount(string memory email) public view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (messages[i].sender == structures.getAddress(email)) {
                count++;
            }
        }
        return count;
    }

    function MessageSent(
        string memory email
    ) public view returns (Message[] memory) {
        uint count = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (
                (messages[i].sender == structures.getAddress(email)) &&
                (messages[i].deleted != DeletionStatus.DeletedBySender) &&
                (messages[i].deleted != DeletionStatus.DeletedBoth)
            ) {
                count++;
            }
        }
        Message[] memory messagesSent = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (
                (messages[i].sender == structures.getAddress(email)) &&
                (messages[i].deleted != DeletionStatus.DeletedBySender) &&
                (messages[i].deleted != DeletionStatus.DeletedBoth)
            ) {
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
            if (
                (messages[i].receiver == structures.getAddress(email)) &&
                (messages[i].deleted != DeletionStatus.DeletedByReceiver) &&
                (messages[i].deleted != DeletionStatus.DeletedBoth)
            ) {
                count++;
            }
        }
        Message[] memory messagesRecieved = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if (
                (messages[i].receiver == structures.getAddress(email)) &&
                (messages[i].deleted != DeletionStatus.DeletedByReceiver) &&
                (messages[i].deleted != DeletionStatus.DeletedBoth)
            ) {
                messagesRecieved[index] = messages[i];
                index++;
            }
        }
        return messagesRecieved;
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

   mapping(bytes32 => string) public IDs;
    mapping(address => Secure) public Keys;
    mapping(address => User) public users;
    address[] public userAddresses;
    address public admin;
     constructor() {
        admin = 0xCcb7d89fC2e6B1e5b4b1410a32CB28f1d6e46bE3;
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
        IDs[Id] = email;
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

    function verifyUser(
        uint id,
        string memory email
    ) public view returns (bool) {
        require(
            stringsEqual(IDs[sha256(abi.encode(id))], email),
            "You don't have permission to create an account !"
        );
        return true;
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
        delete IDs[sha256(abi.encode(Id))];
        // emit UserCreated(name, walletAddress);
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