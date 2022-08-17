/**
 *Submitted for verification at polygonscan.com on 2022-08-16
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

    modifier rateLimit() {
        require(
            (block.timestamp - lastUpdated[msg.sender]) > rate,
            "profiles can only be updated once per hour"
        );
        _;
    }

    /**
    * @notice emits updated event with caller along with the profile calldata
    * rate limted to once per hour
    * @param profile a struct containing profile data
    *      name: a display name for the user
    *      description: a description about the user
    *      thumbnailURI: a URI to a thumnail image for the user
    *      linkURI: a URI to external profile or website
    */
    function update(Profile calldata profile)
        external
        rateLimit
    {
        require(bytes(profile.name).length         < 32,   "name too long");
        require(bytes(profile.description).length  < 512,  "description too long");
        require(bytes(profile.thumbnailURI).length < 2048, "thumbnail uri too long");
        require(bytes(profile.linkURI).length      < 2048, "link uri too long");

        lastUpdated[msg.sender] = block.timestamp;

        emit Updated(msg.sender, profile);
    }
}