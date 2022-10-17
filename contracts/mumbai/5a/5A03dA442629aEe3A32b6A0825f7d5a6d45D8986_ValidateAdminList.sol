// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

contract ValidateAdminList {
    address owner;

    mapping(address => bool) _ownerAddress;
    mapping(address => bool) _adminAddresses;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || _ownerAddress[msg.sender], 'Caller is not the owner!');
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), 'Ownable: new owner is the zero address');
        _ownerAddress[_newOwner] = true;
    }

    function addAdmin(address _address) external onlyOwner {
        require(_adminAddresses[_address] != true, 'Address is already admin');

        _adminAddresses[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner {
        require(_adminAddresses[_address] == true, 'Address is not an admin');

        _adminAddresses[_address] = false;
    }

    function isAdmin(address _address) external view returns (bool) {
        if (_adminAddresses[_address] == true) return true;
        else return false;
    }
}