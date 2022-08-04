// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UPIToAddress {
    struct UserAccount {
        string name;
        string upi;
        address accountAddress;
        bool isRegistered;
    }

    // mapping(bytes32 => address) private upiIds;
    mapping(bytes32 => UserAccount) private userAccounts;

    event UPIAdded(
        string indexed upiId,
        bytes32 indexed hash,
        address indexed linkedAddress
    );

    function linkUPI(string memory _upi, string memory _name) external {
        bytes32 _hash = keccak256(abi.encodePacked(_upi));
        require(!userAccounts[_hash].isRegistered, "UPI already registered");
        userAccounts[_hash] = UserAccount(_name, _upi, msg.sender, true);
        emit UPIAdded(_upi, _hash, msg.sender);
    }

    function changeAddress(string memory _upi, address _to) external {
        bytes32 _hash = keccak256(abi.encodePacked(_upi));
        require(
            userAccounts[_hash].accountAddress == msg.sender,
            "You are not the owner of this UPI"
        );
        userAccounts[_hash].accountAddress = _to;
    }

    function getUserDetails(string memory _upi) external view returns (UserAccount memory) {
        bytes32 _hash = keccak256(abi.encodePacked(_upi));
        return userAccounts[_hash];
    }

    function getAddress(string memory _upi) external view returns (address) {
        bytes32 _hash = keccak256(abi.encodePacked(_upi));
        return userAccounts[_hash].accountAddress;
    }

    function getUPIHash(string memory _upi) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_upi));
    }
}