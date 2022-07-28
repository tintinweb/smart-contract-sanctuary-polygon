// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract PragmaUserdata {
    struct user {
        string username;
        string pfp;
        string banner;
        string bio;
        address[] followersArray;
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

    function getBulkUserData(address[] memory addresses)
        external
        view
        returns (user[] memory)
    {
        user[] memory theUsers = new user[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            theUsers[i] = users[addresses[i]];
        }
        return theUsers;
    }

    function changeName(string memory newUsername) external {
        users[msg.sender].username = newUsername;
    }

    function changePfp(string memory newPfp) external {
        users[msg.sender].pfp = string.concat("ipfs://", newPfp);
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
        users[account].followersArray.push(msg.sender);
    }

    // function unFollow(address account) external {
    //     // Loops through users followings
    //     for (uint i = 0; i < users[msg.sender].followingArray.length; i++) {
    //         if (users[msg.sender].followingArray[i] == account) {
    //             users[msg.sender].followingArray[i] = users[msg.sender]
    //                 .followingArray[
    //                     users[msg.sender].followingArray.length - 1
    //                 ];
    //             users[msg.sender].followingArray.pop();
    //         }
    //         // If none of the users followings are the address they want to unfollow, nothing will happen
    //     }

    //     // Loops through unfollow accounts followers
    //     for (uint i = 0; i < users[account].followersArray.length; i++) {
    //         if (users[account].followersArray[i] == msg.sender) {
    //             users[account].followersArray[i] = users[account]
    //                 .followersArray[
    //                     users[account].followersArray.length - 1
    //                 ];
    //             users[account].followersArray.pop();
    //         }
    //     }
    // }
}