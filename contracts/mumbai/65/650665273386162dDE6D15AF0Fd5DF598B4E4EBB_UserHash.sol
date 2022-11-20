/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract UserHash {
    event hashAdded(User _user);
    event hashVerified(User _user, bool _isVerified);

    struct User {
        string _id;
        string[] _hashes;
    }

    mapping(string => User) users;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function addHash(string memory _userId, string memory _hash)
        external
        onlyOwner
        returns (User memory)
    {
        if (bytes(users[_userId]._id).length == 0) {
            users[_userId]._id = _userId;
        }

        bool includesHash = false;
        for (uint i = 0; i < users[_userId]._hashes.length; i++) {
            if (
                keccak256(abi.encodePacked(users[_userId]._hashes[i])) ==
                keccak256(abi.encodePacked(_hash))
            ) {
                includesHash = true;
            }
        }

        if (!includesHash) {
            users[_userId]._hashes.push(_hash);
        }

        emit hashAdded(users[_userId]);
        return users[_userId];
    }

    function verifyHash(string memory _userId, string memory _hash)
        external
        onlyOwner
        returns (bool)
    {
        require(bytes(users[_userId]._id).length > 0, "User does not exist");

        bool _isVerified = false;

        for (uint i = 0; i < users[_userId]._hashes.length; i++) {
            if (
                keccak256(abi.encodePacked(users[_userId]._hashes[i])) ==
                keccak256(abi.encodePacked(_hash))
            ) {
                _isVerified = true;
            }
        }

        emit hashVerified(users[_userId], _isVerified);
        return _isVerified;
    }

    function getUserHashes(string memory _userId)
        external
        view
        returns (User memory)
    {
        return users[_userId];
    }
}