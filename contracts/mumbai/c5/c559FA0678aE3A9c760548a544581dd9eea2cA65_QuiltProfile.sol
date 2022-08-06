//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuiltProfile {
    struct Profile {
        string image;
        string url;
    }
    mapping(address => Profile) private profiles;

    constructor() {}

    function getProfile(address user) public view returns(string memory, string memory) {
        return (profiles[user].image, profiles[user].url);
    }

    function setProfile(address user, string memory url, string memory image) public {
        profiles[user].image = image;
        profiles[user].url = url;
    }
}