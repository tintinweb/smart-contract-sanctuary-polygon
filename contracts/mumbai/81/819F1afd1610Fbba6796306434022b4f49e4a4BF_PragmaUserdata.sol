// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract PragmaUserdata {
    struct user {
        string username;
        string pfp;
        string banner;
        string bio;
        uint followers;
        address[] followingArray;
    }

    mapping(address => user) public users;

    function getUserData(address userAddress)
        external
        view
        returns (user memory)
    {
        return users[userAddress];
    }

    function changeName(string memory newUsername) external {
        users[msg.sender].username = newUsername;
    }

    function changePfp(string memory newPfp) external {
        users[msg.sender].pfp = newPfp;
    }

    function changeBanner(string memory newBanner) external {
        users[msg.sender].banner = string.concat("ipfs://", newBanner);
    }

    function changeBio(string memory newBio) external {
        users[msg.sender].bio = newBio;
    }

    function follow(address account) external {
        for (uint i = 0; i < users[msg.sender].followingArray.length; i++) {
            if (users[msg.sender].followingArray[i] == account) return;
        }

        users[msg.sender].followingArray.push(account);
        users[account].followers++;
    }
}