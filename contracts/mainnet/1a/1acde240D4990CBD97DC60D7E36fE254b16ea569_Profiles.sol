/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;


/**
* @title Profiles
* @author Olta
*
* @notice This is a simple way to add profile data to the blockchain.
*/

contract Profiles {

    struct Profile {
        string name;
        string description;
        string thumbnailURI;
        string linkURI;
    }

    event Updated(
        address user,
        Profile profile
    );

    uint256 internal rate = 3600; // 1 hour
    mapping (address => uint) internal lastUpdated;

    modifier limitRate() {
        require(
            (block.timestamp - lastUpdated[msg.sender]) > rate,
            "profiles can only be updated once per hour"
        );
        _;
    }

    modifier limitByteSize(Profile calldata profile) {
        require(bytes(profile.name).length         <= 32,   "name too long");
        require(bytes(profile.description).length  <= 512,  "description too long");
        require(bytes(profile.thumbnailURI).length <= 2048, "thumbnail uri too long");
        require(bytes(profile.linkURI).length      <= 2048, "link uri too long");
        _;
    }

    /**
    * @notice emits updated event with caller along with the profile calldata
    * rate limted to once per hour per address
    * @param profile a struct containing profile data
    *      name: a display name for the user, limited to 32 bytes
    *      description: a description about the user, limited to 512 bytes
    *      thumbnailURI: a URI to a thumbnail image for the user, limited to 2048 bytes
    *      linkURI: a URI to external profile or website, limited to 2048 bytes
    */
    function update(Profile calldata profile)
        external
        limitRate
        limitByteSize(profile)
    {
        lastUpdated[msg.sender] = block.timestamp;

        emit Updated(msg.sender, profile);
    }
}