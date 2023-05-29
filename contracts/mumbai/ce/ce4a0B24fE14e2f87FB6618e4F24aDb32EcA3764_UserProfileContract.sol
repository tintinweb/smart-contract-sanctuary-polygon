// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract UserProfileContract {
    struct Profile {
        address wallet;
        string name;
        string email;
        string phone;
        string twitterHandle;
        string[] skills;
        Project[] projects;
        WorkExperience[] workExperience;
        uint256 upvote_count;
        uint lastClaimed;
    }

    struct Project {
        string name;
        string description;
        string duration;
        string link;
        string[] techStack;
    }

    struct WorkExperience {
        string companyName;
        string role;
        string duration;
        string description;
    }

    mapping(address => Profile) public profiles;

    uint256 public numberOfUsers = 0;

    function createProfile(
        string memory _name,
        string memory _email,
        string memory _phone,
        string memory _twitterHandle,
        string[] memory _skills,
        Project[] memory _projects,
        WorkExperience[] memory _workExperience
    ) public returns (Profile memory) {
        require(
            profiles[msg.sender].wallet == address(0),
            "Profile already exists"
        );

        Profile storage newProfile = profiles[msg.sender];
        newProfile.wallet = msg.sender;
        newProfile.name = _name;
        newProfile.email = _email;
        newProfile.phone = _phone;
        newProfile.twitterHandle = _twitterHandle;
        newProfile.skills = _skills;
        newProfile.upvote_count = 0;
        newProfile.lastClaimed = 0;

        // Split the _projects array into individual elements
        for (uint i = 0; i < _projects.length; i++) {
            newProfile.projects.push(
                Project(
                    _projects[i].name,
                    _projects[i].description,
                    _projects[i].duration,
                    _projects[i].link,
                    _projects[i].techStack
                )
            );
        }

        // Split the _workExperience array into individual elements
        for (uint i = 0; i < _workExperience.length; i++) {
            newProfile.workExperience.push(
                WorkExperience(
                    _workExperience[i].companyName,
                    _workExperience[i].role,
                    _workExperience[i].duration,
                    _workExperience[i].description
                )
            );
        }

        profiles[msg.sender] = newProfile;

        numberOfUsers++;

        return newProfile;
    }

    function editProfile(
        string memory _name,
        string memory _email,
        string memory _phone,
        string memory _twitterHandle,
        string[] memory _skills,
        Project[] memory _projects,
        WorkExperience[] memory _workExperience
    ) public returns (Profile memory) {
        require(
            profiles[msg.sender].wallet != address(0),
            "Profile doesn't exist"
        );

        Profile storage profileToUpdate = profiles[msg.sender];
        profileToUpdate.name = _name;
        profileToUpdate.email = _email;
        profileToUpdate.phone = _phone;
        profileToUpdate.twitterHandle = _twitterHandle;
        profileToUpdate.skills = _skills;

        // Split the _projects array into individual elements
        for (uint i = 0; i < _projects.length; i++) {
            profileToUpdate.projects.push(
                Project(
                    _projects[i].name,
                    _projects[i].description,
                    _projects[i].duration,
                    _projects[i].link,
                    _projects[i].techStack
                )
            );
        }

        // Split the _workExperience array into individual elements
        for (uint i = 0; i < _workExperience.length; i++) {
            profileToUpdate.workExperience.push(
                WorkExperience(
                    _workExperience[i].companyName,
                    _workExperience[i].role,
                    _workExperience[i].duration,
                    _workExperience[i].description
                )
            );
        }

        return profileToUpdate;
    }

    function changeLastClaimed() public {
        require(
            profiles[msg.sender].wallet != address(0),
            "Profile doesn't exist"
        );
        profiles[msg.sender].lastClaimed = block.timestamp;
    }

    function getProfileByAddress(
        address _wallet
    ) public view returns (Profile memory) {
        return profiles[_wallet];
    }

    function getProfile() public view returns (Profile memory) {
        return profiles[msg.sender];
    }

    function getNumberOfUsers() public view returns (uint256) {
        return numberOfUsers;
    }

    function getAllProfiles() public view returns (Profile[] memory) {
        Profile[] memory allProfiles = new Profile[](numberOfUsers);
        for (uint256 i = 0; i < numberOfUsers; i++) {
            allProfiles[i] = profiles[msg.sender];
        }
        return allProfiles;
    }

    function upvoteProfile(address _wallet) public {
        require(
            profiles[_wallet].wallet != address(0),
            "Profile doesn't exist"
        );
        profiles[_wallet].upvote_count++;
    }
}