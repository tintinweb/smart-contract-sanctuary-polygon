//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "../users/Users.sol";
import "../activity/Activity.sol";

contract Activities {
    Users s_users;
    address[] s_activities;

    event ActivityAdded(address activity);
    event ActivityDeleted(address activity);

    modifier onlyAdmin() {
        require(s_users.getUser(msg.sender).isAdmin, "You are not an admin.");
        _;
    }

    constructor(address _usersAddress) {
        s_users = Users(_usersAddress);
    }

    function createActivity(string memory _name, uint8 _reward)
        external
        onlyAdmin
    {
        address activityAddress = address(
            new Activity(_name, _reward, address(s_users))
        );
        s_activities.push(activityAddress);
        emit ActivityAdded(activityAddress);
    }

    function getActivities() external view returns (address[] memory) {
        return s_activities;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "./../model/Model.sol";

contract Users {
    mapping(address => SharedModel.User) s_users;
    address[] s_addresses;

    event AddedNewUser(address indexed walletAddress, string nick, bool isAdmin);
    event UpdatedUsersPoints(address indexed walletAddress, uint32 current_points);
    event UpdatedUsersNick(address indexed walletAddress, string new_nick);
    event UpdatedUsersAdminRole(address indexed walletAddress, bool isAdmin);

    constructor() {
        addUser(msg.sender, "", true);
    }

    modifier onlyAdmin() {
        require(s_users[msg.sender].isAdmin, "msg sender must be admin");
        _;
    }

    modifier walletExists(address walletAddress) {
        require(
            s_users[walletAddress].walletAddress == walletAddress, 
            "User with passed wallet not exists"
        );
        _;
    }

    function setAdmin(address walletAddress, bool isAdmin) public onlyAdmin walletExists(walletAddress){
        s_users[walletAddress].isAdmin = isAdmin;
        emit UpdatedUsersAdminRole(walletAddress, isAdmin);
    }

    function setNick(address walletAddress, string memory nick) public onlyAdmin walletExists(walletAddress){
        s_users[walletAddress].nick = nick;

        emit UpdatedUsersNick(walletAddress, nick);
    }

    function addUser(address walletAddress, string memory nick, bool isAdmin) public {
        require(
            s_users[walletAddress].walletAddress != walletAddress,
            "Wallet address already exists"
        );

        s_addresses.push(walletAddress);
        s_users[walletAddress] = SharedModel.User(walletAddress, nick, 0, isAdmin);

        emit AddedNewUser(
            walletAddress,
            nick,
            isAdmin
        );
    }

    function getUser(address walletAddress) public view returns (SharedModel.User memory) {
        return s_users[walletAddress];
    }

    function getUsers() public view returns (SharedModel.User[] memory) {
        SharedModel.User[] memory result = new SharedModel.User[](s_addresses.length);
        for (uint256 i = 0; i < s_addresses.length; i++) {
            result[i] = s_users[s_addresses[i]];
        }
        return result;
    }

    function addPoints(address walletAddress, uint32 points) public onlyAdmin walletExists(walletAddress) {
        s_users[walletAddress].points += points;

        emit UpdatedUsersPoints(walletAddress, s_users[walletAddress].points);
    }

    function substractPoints(address walletAddress, uint32 points) public onlyAdmin walletExists(walletAddress) {
        if(s_users[walletAddress].points < points) {
            s_users[walletAddress].points = 0;
        } else {
            s_users[walletAddress].points -= points;
        }
        
        emit UpdatedUsersPoints(walletAddress, s_users[walletAddress].points);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "../users/Users.sol";

contract Activity {
    bool s_active;
    uint8 public s_reward;
    Users s_users;
    string public s_name;

    event RewardChanged(uint8 _oldReward, uint8 _newReward);
    event NameChanged(string _oldName, string _newName);
    event Activated();
    event Deactivated();

    modifier onlyAdmin() {
        require(s_users.getUser(msg.sender).isAdmin, "You are not an admin.");
        _;
    }

    constructor(
        string memory _name,
        uint8 _reward,
        address _usersAddress
    ) {
        require(bytes(_name).length > 0, "Name must be non-empty");
        require(_reward > 0, "Reward must be greater than 0");

        s_active = false;
        s_name = _name;
        s_reward = _reward;
        s_users = Users(_usersAddress);
    }

    function isActive() external view returns (bool) {
        return s_active;
    }

    function setName(string memory _newName) external onlyAdmin {
        require(bytes(_newName).length > 0, "Name must be non-empty");
        emit NameChanged(s_name, _newName);
        s_name = _newName;
    }

    function setReward(uint8 _reward) external onlyAdmin {
        require(_reward > 0, "Reward must be greater than 0");
        require(_reward != s_reward, "Reward must be different");

        emit RewardChanged(s_reward, _reward);
        s_reward = _reward;
    }

    function deactivate() external onlyAdmin {
        s_active = false;
        emit Deactivated();
    }

    function activate() external onlyAdmin {
        s_active = true;
        emit Activated();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

library SharedModel {
    struct User {
        address walletAddress;
        string nick;
        uint32 points;
        bool isAdmin;
    }
}