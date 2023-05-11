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

    enum DeletionStatus {
        NotDeleted,
        DeletedBySender,
        DeletedByReceiver,
        DeletedBoth
    }
    struct Secure{
        bytes32 seed;
        bytes32 password;
        bytes pubKey; 
    }
    
    struct Message {
        uint256 id;
        address sender;
        address receiver;
        string subject;
        string message;
        uint256 timestamp;
        bool read;
        string fileHash;
        string receiversGroup;
        DeletionStatus deleted;
    }

    uint256 messageCount;

    mapping(bytes32 => string) public IDs;
    mapping(address => Secure) public Keys;
    mapping (address => User) public users;
    address[] public userAddresses;
    address public admin;

    Message[] public messages;
    mapping(string => address) usersByName;
    mapping(string => address) usersByEmail;
    
    constructor() {
        admin = 0x7B60eD2A82267aB814256d3aB977ae5434d01d8b;
        /*users[0x7B60eD2A82267aB814256d3aB977ae5434d01d8b] = User("Admin", "[email protected]", true, 0x7B60eD2A82267aB814256d3aB977ae5434d01d8b, true);
        userAddresses.push(0x7B60eD2A82267aB814256d3aB977ae5434d01d8b);
        users[0x8455022A4Ef3044A3B0949517D8aA0006054403d] = User("H'nifa", "[email protected]", true, 0x8455022A4Ef3044A3B0949517D8aA0006054403d, false);
        userAddresses.push(0x8455022A4Ef3044A3B0949517D8aA0006054403d);
        usersByName["H'nifa"] = 0x8455022A4Ef3044A3B0949517D8aA0006054403d;
        usersByName["Admin"] = 0x7B60eD2A82267aB814256d3aB977ae5434d01d8b;
        usersByEmail["[email protected]"] = 0x8455022A4Ef3044A3B0949517D8aA0006054403d;
        usersByEmail["[email protected]"] = 0x7B60eD2A82267aB814256d3aB977ae5434d01d8b;*/

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

    function verifyUser(uint id, string memory email) public view returns (bool) {
        require(stringsEqual(IDs[sha256(abi.encode(id))], email), "You don't have permission to create an account !");
        return true;
    }

    //Creat user
    function createUser(uint Id, string memory name, string memory email, address walletAddress, bytes32 seed, bytes32 password, bytes memory pubKey) public {
        require(bytes(name).length > 0, "You have to specify your name !");
        User memory user = User(name, email, true,walletAddress,false);
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
   require(walletAddress != address(0), "User with given address does not exist.");
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

    function getRecieverPubKey(address receiver) public view returns (bytes memory){
        bytes memory pubKey = Keys[receiver].pubKey;
        return pubKey;
    }

    function verifyPassword(address sender, bytes32 password) public view returns(bool) {
        require(Keys[sender].password == password, "Invalid Password");
        return true;
    }

    function verifySeed(address sender, bytes32 seed) public view returns(bool) {
        require(Keys[sender].seed == seed, "Invalid Seed");
        return true;
    }

    // Send message function
    function sendMessage(address receiver, string calldata subject, string memory message, string memory fileHash, string memory receiverGroup) external {
        require(
            checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        require(checkUserExists(receiver) == true, "Recipient does not exist");
        //address[] memory receivers = new address[](1);
        //receivers[0] = receiver;
        Message memory message = Message(messageCount, msg.sender, receiver, subject, message, block.timestamp, false, fileHash, receiverGroup, DeletionStatus.NotDeleted);
        messages.push(message);
        //emit MessageSent(msg.sender, receiver, messageHash);
        messageCount++;
        }        

        function sendMessageToGroup(address[] memory receiver, string calldata subject, string []memory message, string memory fileHash, string memory emailGroup) external {
        require(
            checkUserExists(msg.sender) == true,
            "You must have an account"
        );
        for(uint i = 0; i<receiver.length; i++){
            require(checkUserExists(receiver[i]) == true, "Recipient does not exist");
            Message memory message = Message(messageCount, msg.sender, receiver[i], subject, message[i], block.timestamp, false, fileHash, emailGroup,DeletionStatus.NotDeleted);
        messages.push(message);
        messageCount++;
        }
        
        //emit MessageSent(msg.sender, receiver, messageHash);
        }      

    function deleteMessage(address walletAddress, uint256 id) public {
        require(checkUserExists(walletAddress), "User with given address does not exist.");
        Message storage message = messages[id];
        //Message storage message = getMessageById(id);
        if(message.sender == walletAddress){
            if(message.deleted==DeletionStatus.DeletedByReceiver){
                message.deleted = DeletionStatus.DeletedBoth;
            }
            else{
                message.deleted = DeletionStatus.DeletedBySender;
            }
        }
        if(message.receiver == walletAddress){
            if(message.deleted==DeletionStatus.DeletedBySender){
                message.deleted = DeletionStatus.DeletedBoth;
            }
            else{
                message.deleted =  DeletionStatus.DeletedByReceiver;
            }
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
            if ((messages[i].sender == getAddress(email)) && (messages[i].deleted != DeletionStatus.DeletedBySender) && (messages[i].deleted != DeletionStatus.DeletedBoth)) {
                count++;
            }
        }
        Message[] memory messagesSent = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if ((messages[i].sender == getAddress(email)) && (messages[i].deleted != DeletionStatus.DeletedBySender) && (messages[i].deleted != DeletionStatus.DeletedBoth)) {
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
            if ((messages[i].receiver == getAddress(email)) && (messages[i].deleted != DeletionStatus.DeletedByReceiver) && (messages[i].deleted != DeletionStatus.DeletedBoth)) {
                count++;
            }
        }
        Message[] memory messagesRecieved = new Message[](count);
        uint index = 0;
        for (uint i = 0; i < messages.length; i++) {
            if ((messages[i].receiver == getAddress(email)) && (messages[i].deleted != DeletionStatus.DeletedByReceiver) && (messages[i].deleted != DeletionStatus.DeletedBoth)) {
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