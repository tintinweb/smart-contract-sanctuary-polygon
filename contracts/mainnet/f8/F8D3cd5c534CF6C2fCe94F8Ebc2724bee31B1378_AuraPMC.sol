//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuraPMC {
    struct Profile {
        string bannerImageHash;
        string profileImageHash;
    }

    mapping(address => Profile) public profiles;

    function setBannerImageHash(string memory _bannerImageHash) public {
        profiles[msg.sender].bannerImageHash = _bannerImageHash;
    }

    function setProfileImageHash(string memory _profileImageHash) public {
        profiles[msg.sender].profileImageHash = _profileImageHash;
    }

    function getProfile(
        address userAddress
    ) public view returns (Profile memory) {
        return profiles[userAddress];
    }
}