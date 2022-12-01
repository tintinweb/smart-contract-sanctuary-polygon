/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9; // should be the same as in the hardhat.config.js file

contract Profiles {
    event NewProfileCreated(
        bytes32 profileID,
        address creatorAddress,
        string profileDataCID,
        bool isDisabled
    );

    event DisableProfile(bytes32 profileID, bool isDisabled); // To hide a profile

    struct CreateProfile {
        bytes32 profileID;
        string profileDataCID;
        address profileOwner;
        bool isDisabled;
    }

    mapping(bytes32 => CreateProfile) public idToProfile;

    function createNewProfile(string calldata profileDataCID) external {
        // generate a profileID based on other things passed in to generate a hash
        bytes32 profileId = keccak256(
            abi.encodePacked(msg.sender, address(this))
        );

        idToProfile[profileId] = CreateProfile(
            profileId,
            profileDataCID,
            msg.sender,
            false
        );

        emit NewProfileCreated(profileId, msg.sender, profileDataCID, false);
    }

    function disableProfile(bytes32 profileId) external {
        CreateProfile memory myProfile = idToProfile[profileId];
        require(msg.sender == myProfile.profileOwner, "NOT AUTHORIZED");
        myProfile.isDisabled = true;
        emit DisableProfile(profileId, true);
    }
}