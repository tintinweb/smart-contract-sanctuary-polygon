// SPDX-License-Identifier:None

pragma solidity 0.8.17;

contract AccessManager {
    address public admin;

    mapping(bytes32 => mapping(address => bool)) public roles;

    event adminChanged(address indexed oldAdmin, address indexed newAdmin);
    event roleGranted(bytes32 indexed role, address indexed addr);
    event roleRevoked(bytes32 indexed role, address indexed addr);

    modifier roleMustExits(bytes32 role, address addr) {
        require(roles[role][addr] == true, "role doesnt exist");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Unauthorized");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function grantRole(bytes32 role, address addr) external onlyAdmin {
        require(roles[role][addr] == false, "role already exits");
        roles[role][addr] = true;
        emit roleGranted(role, addr);
    }

    function revokeRole(bytes32 role, address addr)
        external
        onlyAdmin
        roleMustExits(role, addr)
    {
        roles[role][addr] = false;
        emit roleRevoked(role, addr);
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;
        emit adminChanged(oldAdmin, newAdmin);
    }

    function renounceRole(bytes32 role)
        external
        roleMustExits(role, msg.sender)
    {
        roles[role][msg.sender] = false;
        emit roleRevoked(role, msg.sender);
    }
}