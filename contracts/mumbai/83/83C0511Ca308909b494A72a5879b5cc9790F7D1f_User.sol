// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Role {
    mapping(address => string) private roles;

    event RoleSet(address indexed user, string role);

    function setRole(address _user, string memory _role) public {
        require(_user != address(0), "User address can't be zero");
        require(bytes(_role).length > 0, "Role can't be empty");
        roles[_user] = _role;
        emit RoleSet(_user, _role);
    }

    function getRole(address _user) public view returns (string memory) {
        return roles[_user];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Role.sol";

contract User {
    address public userAddress;

    struct UserStruct {
        string name;
        string role;
        // address roleAddress;
    }

    mapping(address => UserStruct) public users;

    event UserCreated(address indexed userAddress, string role, string name);
    event UserRemoved(address indexed userAddress);

    constructor() {
        userAddress = msg.sender;
    }

    function createUser(address _user, string memory _role, string memory _name) public {
        require(_user != address(0), "User address can't be zero");
        require(bytes(_role).length > 0, "Role can't be empty");
        require(bytes(_name).length > 0, "Name can't be empty");

        Role role = new Role();
        users[_user] = UserStruct(_name, _role);
        role.setRole(_user, _role);

        emit UserCreated(_user, _role, _name);
    }

    function removeUser(address _user) public {
        require(_user != address(0), "User address can't be zero");

        Role role = new Role();
        delete users[_user];
        role.setRole(_user, "");

        emit UserRemoved(_user);
    }

    function getName(address _user) public view returns (string memory) {
        return users[_user].name;
    }

    function getRole(address _user) public view returns (string memory) {
        return users[_user].role;
    }

    function userExists(address _user) public view returns (bool) {
        return bytes(users[_user].name).length != 0;
    }
}