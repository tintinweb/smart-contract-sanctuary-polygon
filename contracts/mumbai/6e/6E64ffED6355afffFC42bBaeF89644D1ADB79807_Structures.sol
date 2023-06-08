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
        admin = 0xadfB6794D98287189e6F2C89C8cbA7323C9B9F87;
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

    //Change password
    function changePasswordUser(address walletAddress, bytes32 password) public {
        require(
            walletAddress != address(0),
            "User with given address does not exist."
        );

        Keys[walletAddress].password = password;

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