// SPDX-License-Identifier: GPL-3.0

/// @title NeoWorld User Storage contract

pragma solidity ^0.8.6;

contract UserStorage {
    constructor() {
        owner = msg.sender;
        deployer = msg.sender;
    }

    address public owner;
    address deployer;
    int256 activeUsers;
    int256 deletedUsers;

    struct UserStruct {
        address userAddress;
        string userName;
        string discordId;
        string userEmail;
        bool whitelisted;
        uint256 created;
        uint256 updated;
    }

    struct deletedUserStruct {
        UserStruct data;
        uint256 deleted;
    }

    mapping(address => UserStruct) private userStructs;
    mapping(address => deletedUserStruct) private deletedUserStructs;

    address[] private userIndex;

    event LogNewUser(
        address indexed userAddress,
        string userName,
        string discordId,
        string userEmail,
        bool whitelited,
        uint256 created,
        uint256 updated
    );
    event LogUpdateUser(
        address indexed userAddress,
        string userName,
        string discordId,
        string userEmail,
        uint256 updated
    );
    event LogDeleteUser(address indexed userAddress, uint256 deleted);

    modifier onlyOwner() {
        require(
            msg.sender == owner || msg.sender == deployer,
            "Ownable: caller is not the owner"
        );
        _;
    }

    modifier isWhitelisted(address _userAddress) {
        require(userStructs[_userAddress].whitelisted == true, "Whitelist: You need to be whitelisted");
        _;
    }

    // @notice Check if user exist
    function isUser(address userAddress) public view onlyOwner returns (bool) {
        // if (userIndex.length == 0) return false;
        // require(userIndex.length != 0, "Whitelist: You need to be whitelisted");
        if (userStructs[userAddress].created > 0) {
            return true;
        }
        return false;
    }

    // @notice insert user
    function addUser(
        address userAddress,
        string memory userName,
        string memory discordId,
        string memory userEmail,
        bool whitelisted,
        uint256 created
    ) public onlyOwner returns (bool) {
        require(!isUser(userAddress), "User exists");

        userStructs[userAddress].userAddress = userAddress;
        userStructs[userAddress].userName = userName;
        userStructs[userAddress].discordId = discordId;
        userStructs[userAddress].userEmail = userEmail;
        userStructs[userAddress].whitelisted = whitelisted;
        userStructs[userAddress].created = created;
        userStructs[userAddress].updated = created;
        activeUsers++;

        emit LogNewUser(
            userAddress,
            userName,
            discordId,
            userEmail,
            whitelisted,
            created,
            created
        );
        return true;
    }

    function updateUserName(
        address userAddress,
        string memory userName,
        uint256 updated
    ) public returns (bool) {
        require(isUser(userAddress), "User doesn't exist");
        userStructs[userAddress].userName = userName;

        emit LogUpdateUser(
            userAddress,
            userName,
            userStructs[userAddress].discordId,
            userStructs[userAddress].userEmail,
            updated
        );
        return true;
    }

    function updateDiscordId(
        address userAddress,
        string memory discordId,
        uint256 updated
    ) public returns (bool) {
        require(isUser(userAddress), "User doesn't exist");
        userStructs[userAddress].discordId = discordId;

        emit LogUpdateUser(
            userAddress,
            userStructs[userAddress].userName,
            discordId,
            userStructs[userAddress].userEmail,
            updated
        );
        return true;
    }

    function updateUserEmail(
        address userAddress,
        string memory userEmail,
        uint256 updated
    ) public returns (bool) {
        require(isUser(userAddress), "User doesn't exist");
        userStructs[userAddress].userEmail = userEmail;

        emit LogUpdateUser(
            userAddress,
            userStructs[userAddress].userName,
            userStructs[userAddress].discordId,
            userEmail,
            updated
        );
        return true;
    }

    // @notice delete user
    function deleteUser(address userAddress, uint256 deleted)
        public
        onlyOwner
        returns (bool)
    {
        require(isUser(userAddress), "User doesn't exist");

        // deletedUserStructs[userAddress].userAddress = userStructs[userAddress]
        //     .userAddress;
        // deletedUserStruct[userAddress].userName = userStructs[userAddress]
        //     .userName;
        // deletedUserStruct[userAddress].discordId = userStructs[userAddress]
        //     .discordId;
        // deletedUserStruct[userAddress].userEmail = userStructs[userAddress]
        //     .userEmail;
        // deletedUserStruct[userAddress].whitelited = userStructs[userAddress]
        //     .whitelited;

        deletedUserStructs[userAddress].data = userStructs[userAddress];
        deletedUserStructs[userAddress].deleted = deleted;
        delete userStructs[userAddress];

        activeUsers--;
        deletedUsers++;
        // uint256 rowToDelete = userStructs[userAddress].index;
        // address keyToMove = userIndex[userIndex.length - 1];
        // userIndex[rowToDelete] = keyToMove;
        // userStructs[keyToMove].index = rowToDelete;
        // userIndex.length--;
        emit LogDeleteUser(userAddress, deleted);
        return true;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function verifyUser(address _userAddress) public view returns (bool) {
        return userStructs[_userAddress].whitelisted;
    }

    function getActiveUsers() public view onlyOwner returns (int256) {
        return activeUsers;
    }

    function getDeletedUsers() public view onlyOwner returns (int256) {
        return deletedUsers;
    }

    function getAlpha() public view onlyOwner returns (address) {
        return deployer;
    }
}