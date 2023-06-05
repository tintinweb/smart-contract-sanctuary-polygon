// SPDX-License-Identifier: UNLICENSED0
pragma solidity ^0.8.9;


contract Chat {
    struct User {
        string name;
        string email;
        bool exists;
        address walletAddress;
        bool isAdmin;
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
        uint256 shares;
        uint256 views;
        address[] viewedBy;
        uint256 originalMessageId;
        string fileHash;
    }
    // struct Share {
    //     uint256 messageId;
    //     uint256 timestamp;
    //     address sender;
    //     address receiver;
    //     bool read;
    // }

    struct Draft {
        uint256 id;
        address sender;
        string subject;
        string message;
        bool shareable;
        address[] receivers;
        string fileHash;
    }
    Draft[] public drafts;

    // Share[] public shares;
    // event MessageShared(uint256 shareId, uint256 messageId, address sender, address[] receivers);

    uint256 messageCount;
    uint256 draftCount;
    uint256 shareCount;
    mapping(bytes32 => string) public IDs;
    mapping (address => User) public users;
    address[] public userAddresses;
    address public admin;

    Message[] public messages;
    mapping(string => address) usersByName;
    mapping(string => address) usersByEmail;
    
    constructor() {
        admin = 0x15940575e50821CAb60c331A3ccE470a5014c2C0;
        users[0x15940575e50821CAb60c331A3ccE470a5014c2C0] = User("Admin", "[email protected]", true,0x15940575e50821CAb60c331A3ccE470a5014c2C0,true);
        userAddresses.push(0x15940575e50821CAb60c331A3ccE470a5014c2C0);
        usersByName["Admin"] = 0x15940575e50821CAb60c331A3ccE470a5014c2C0;
        usersByEmail["[email protected]"] = 0x15940575e50821CAb60c331A3ccE470a5014c2C0;

        users[0x8E4f09aCF091fD71981E5625Ae0b2E4c6fFd0cb7] = User("H'nifa", "[email protected]", true,0x8E4f09aCF091fD71981E5625Ae0b2E4c6fFd0cb7,false);
        userAddresses.push(0x8E4f09aCF091fD71981E5625Ae0b2E4c6fFd0cb7);
        usersByName["H'nifa"] = 0x8E4f09aCF091fD71981E5625Ae0b2E4c6fFd0cb7;
        usersByEmail["[email protected]"] = 0x8E4f09aCF091fD71981E5625Ae0b2E4c6fFd0cb7;

        users[0xC399F96Fb4f190799b7E59C7Efba022F7AfDA378] = User("lynda", "[email protected]", true,0xC399F96Fb4f190799b7E59C7Efba022F7AfDA378,false);
        userAddresses.push(0xC399F96Fb4f190799b7E59C7Efba022F7AfDA378);
        usersByName["lynda"] = 0xC399F96Fb4f190799b7E59C7Efba022F7AfDA378;
        usersByEmail["[email protected]"] = 0xC399F96Fb4f190799b7E59C7Efba022F7AfDA378;

    }
    
    event LogString(uint message);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
          _;
    }
    //makeAdmin : to make someone an admin we change isAdmin=>true
    function makeAdmin(address userAddress) public onlyAdmin{
        users[userAddress].isAdmin = true;
    }
    
    function createUserId(string memory email, bytes32 Id) public onlyAdmin{
        IDs[Id] = email;
    } 
    // Define a new role for admins
  mapping (address => bool) private admins;

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

  //--------------------------------------------------------------------------------------   

    function stringsEqual(string memory a, string memory b) private pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    
    //Creat user
    function createUser(uint Id, string memory name, string memory email, address walletAddress) public {
        require(stringsEqual(IDs[sha256(abi.encode(Id))], email), "You don't have permission to create an account !");
        require(bytes(name).length > 0, "You have to specify your name !");
        User memory user = User(name, email, true,walletAddress,false);
        users[walletAddress] = user;
        userAddresses.push(walletAddress);
        usersByName[name] = walletAddress;
        usersByEmail[email] = walletAddress;
        delete IDs[sha256(abi.encode(Id))];
       // emit UserCreated(name, walletAddress);
    }
    //Delete user
   function deleteUser(address walletAddress) public onlyAdmin {
   require(walletAddress != address(0), "User with given address does not exist.");
    delete users[walletAddress];
    delete usersByName[users[walletAddress].name];
    delete usersByEmail[users[walletAddress].email];
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
    
    function sendMessage(address[] memory receivers, string calldata subject, string calldata message, bool isShareable, string calldata fileHash) external {
        require(
            checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        
        for (uint i = 0; i < receivers.length; i++) {
            require(checkUserExists(receivers[i]), "Receiver does not exist");
            Message memory newMessage = Message(
                messageCount,
                msg.sender,
                receivers[i],
                subject,
                message,
                block.timestamp,
                false,
                isShareable,
                0,
                0,
                new address[](0),
                messageCount,
                fileHash
            );
            messageCount++;
            messages.push(newMessage);
        }
    }

    function saveDraft(string calldata subject, string calldata message, bool shareable, address[] calldata receivers, string calldata fileHash) external {
        Draft memory newDraft = Draft(draftCount, msg.sender, subject, message, shareable, receivers, fileHash);
        draftCount++;
        drafts.push(newDraft);
    }

    function getDrafts(string memory email) external view returns (Draft[] memory) {
        uint count = 0;
        for (uint i = 0; i < drafts.length; i++) {
            if (drafts[i].sender == getAddress(email)) {
                count++;
            }
        }
        Draft[] memory draft = new Draft[](count);
        uint index = 0;
        for (uint i = 0; i < drafts.length; i++) {
            if (drafts[i].sender == getAddress(email)) {
                draft[index] = drafts[i];
                index++;
            }
        }
        return draft;
        }
    
    function deleteDraft(uint index) public {
        require(index < drafts.length, "Invalid index");

        for (uint i = index; i < drafts.length - 1; i++) {
            drafts[i] = drafts[i + 1];
        }
        drafts.pop();
    }


//     function shareMessage(uint256 messageId, address[] calldata receivers) external {
//     require(messageId < messages.length, "Invalid message ID");
//     require(checkUserExists(msg.sender) == true, "You must have an account");
//     Message storage messageToShare = messages[messageId];
//     uint256 originalMessageid = messages[messageId].originalMessageId;
//     require(messageToShare.shareable == true, "Message is not shareable");

//     for (uint256 i = 0; i < receivers.length; i++) {
//         require(checkUserExists(receivers[i]), "Receiver does not exist");
//         Share memory newShare = Share(messageId, block.timestamp, msg.sender, receivers[i], messages[messageId].read);
//         shares.push(newShare);
//         messageToShare.shares++;
//         messages[originalMessageid].shares++;
        
//         // Set the originalMessageId of the shared message to the ID of the original message
//         Message memory sharedMessage = Message(
//             messageCount,
//             msg.sender,
//             receivers[i],
//             messageToShare.subject,
//             messageToShare.message,
//             block.timestamp,
//             false,
//             true,
//             0,
//             0,
//             new address[](0),
//             messages[messageId].originalMessageId,
//             messageToShare.fileHash
//         );
//         messageCount++;
//         messages.push(sharedMessage);
//     }
//     emit MessageShared(shareCount, messageId, msg.sender, receivers);
//     shareCount++;
// }
//     function getShares(uint256 messageId) external view returns (Share[] memory) {
//         require(messageId < messages.length, "Invalid message ID");

//         uint256 count = 0;
//         for (uint256 i = 0; i < shares.length; i++) {
//             if (messages[messageId].originalMessageId == messageId ) {
//                 count++;
//             }
//         }
//         Share[] memory messageShares = new Share[](count);
//         uint256 index = 0;
//         for (uint256 i = 0; i < shares.length; i++) {
//             if (messages[messageId].originalMessageId == messageId) {
//                 messageShares[index] = shares[i];
//                 index++;
//             }
//         }
//         return messageShares;
//     }

    function getViewedBy(uint256 messageId) public view returns (address[] memory) {
        return messages[messageId].viewedBy;
    }
function viewMessage(uint256 messageId) public {
    uint256 originalMessageid = messages[messageId].originalMessageId;
    messages[messageId].views++;
    messages[originalMessageid].views++;
    messages[messageId].read= true;
    messages[originalMessageid].read= true;
    bool found = false;
    for (uint256 i = 0; i < messages[messageId].viewedBy.length; i++) {
        if (messages[messageId].viewedBy[i] == msg.sender) {
            found = true;
            break;
        }
    }
    if (!found) { messages[messageId].viewedBy.push(msg.sender);}
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
        require(checkUserExists(adresse) == true,"User with given address don't exist");
        return users[adresse].email;
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

    function MessageReceived(string memory email) public view returns (Message[] memory) {  
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



function getAllUsers() public view returns (User[] memory) {
    User[] memory allUsers = new User[](userAddresses.length);
    for (uint i = 0; i < userAddresses.length; i++) {
        allUsers[i] = users[userAddresses[i]];
    }
    return allUsers;
}

function editUser(address walletAddress, string memory name, string memory email, bool isAdmin) public onlyAdmin {
    require(checkUserExists(walletAddress), "User with given address does not exist.");
    User storage user = users[walletAddress];
    user.name = name;
    user.email = email;
    user.isAdmin = isAdmin;
    usersByName[name] = walletAddress;
    usersByEmail[email] = walletAddress;
}
}