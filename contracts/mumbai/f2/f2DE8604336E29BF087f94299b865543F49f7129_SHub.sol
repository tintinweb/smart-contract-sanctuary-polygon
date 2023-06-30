/**
 *Submitted for verification at polygonscan.com on 2023-06-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract SHub {
    struct UserRecord {
        address userAddress;
        uint256 userId;
    }

    struct UserResponse {
        address userAddress;
        uint256 userId;
    }

    UserRecord[] public deployedUsers;

    function createUser(uint256 _userId) public {
        address newUser = address(new User());
        UserRecord memory userRecord = UserRecord(newUser, _userId);
        deployedUsers.push(userRecord);
    }

    function getDeployedUsers(
        uint256 _userId
    ) public view returns (UserRecord[] memory) {
        UserRecord[] memory matchingUsers = new UserRecord[](
            deployedUsers.length
        );
        uint256 matchingCount = 0;

        for (uint256 i = 0; i < deployedUsers.length; i++) {
            if (deployedUsers[i].userId == _userId) {
                matchingUsers[matchingCount] = deployedUsers[i];
                matchingCount++;
            }
        }

        UserRecord[] memory result = new UserRecord[](matchingCount);
        for (uint256 i = 0; i < matchingCount; i++) {
            result[i] = matchingUsers[i];
        }

        return result;
    }

    function getAllUsers()
        public
        view
        returns (UserResponse[] memory userData)
    {
        userData = new UserResponse[](deployedUsers.length);
        for (uint256 i = 0; i < deployedUsers.length; i++) {
            userData[i] = UserResponse({
                userAddress: deployedUsers[i].userAddress,
                userId: deployedUsers[i].userId
            });
        }
        return userData;
    }
}

contract User {
    string public userName;
    string public userStatsFile;
    string public userImage;

    function setUserStatsFile(string memory _hash) public {
        userStatsFile = _hash;
    }

    function getUserStatsFile() public view returns (string memory) {
        return userStatsFile;
    }

    function setUserImage(string memory _hash) public {
        userImage = _hash;
    }

    function getUserImage() public view returns (string memory) {
        return userImage;
    }

    function setUserName(string memory _name) public {
        userName = _name;
    }

    function getUserName() public view returns (string memory) {
        return userName;
    }
}