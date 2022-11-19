// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error UserRegistry__AccountExists();
error UserRegistry__AccountInexisting();

contract UserRegistry {
    uint256 public profileCount = 0;

    struct Profile {
        string username;
        string profileImgUri;
    }

    event ProfileCreated(string username, string profileImgUri);

    event ProfileUpdated(string username, string profileImgUri);

    mapping(address => Profile) private s_profiles;
    mapping(address => bool) private s_profileCreated;

    modifier existingUser() {
        if (s_profileCreated[msg.sender]) {
            revert UserRegistry__AccountExists();
        }
        _;
    }

    modifier inExistingUser() {
        if (!s_profileCreated[msg.sender]) {
            revert UserRegistry__AccountInexisting();
        }
        _;
    }

    function createProfile(
        string memory _username,
        string memory _profileImgUri
    ) external existingUser {
        s_profiles[msg.sender] = Profile(_username, _profileImgUri);
        s_profileCreated[msg.sender] = true;
        emit ProfileCreated(_username, _profileImgUri);
        profileCount++;
    }

    function updateProfile(
        string memory _username,
        string memory _profileImgUri
    ) external inExistingUser {
        s_profiles[msg.sender] = Profile(_username, _profileImgUri);

        emit ProfileUpdated(_username, _profileImgUri);
    }

    function getUserProfile(address _userAddress)
        external
        view
        returns (Profile memory)
    {
        return s_profiles[_userAddress];
    }
}