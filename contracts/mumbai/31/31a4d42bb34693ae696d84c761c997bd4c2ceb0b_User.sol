/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract User {
    struct signUpDetails {
        string[] roles;
        string logoImageUri;
        string bannerImageUri;
        string profileName;
        string description;
        address walletAddress;
        address parentDistributorAddress;
    }
    mapping(address => signUpDetails) private signedDetails;

    /* 
      Create Profile 
      we will use address to map details of particular wallet address
    */
    function createProfile(
        address _parentDistributorAddress,
        string[] memory role,
        string memory _logoImageUri,
        string memory _bannerIamgeUri,
        string memory _profileName,
        string memory _description
    ) public returns (bool) {
        signUpDetails storage details = signedDetails[msg.sender];
        details.logoImageUri = _logoImageUri;
        details.bannerImageUri = _bannerIamgeUri;
        details.profileName = _profileName;
        details.description = _description;
        details.roles = role;
        details.parentDistributorAddress = _parentDistributorAddress;
        details.walletAddress = msg.sender;

        return true;
    }

    /* Edit Profile */
    function editProfile(
        string[] memory role,
        string memory _logoImageUri,
        string memory _bannerIamgeUri,
        string memory _profileName,
        string memory _description
    ) public returns (bool) {
        require(
            signedDetails[msg.sender].walletAddress != address(0),
            "No Account Created!"
        );
        signUpDetails storage details = signedDetails[msg.sender];
        details.logoImageUri = _logoImageUri;
        details.bannerImageUri = _bannerIamgeUri;
        details.profileName = _profileName;
        details.description = _description;
        details.roles = role;
        return true;
    }

    /* Delete Profile */
    function deleteProfile() public returns (bool) {
        require(
            signedDetails[msg.sender].walletAddress != address(0),
            "No Account Created!"
        );
        delete signedDetails[msg.sender];
        return true;
    }

    /* To get user details */
    function getUserDetails(address userAddress)
        public
        view
        returns (
            string memory logoUri,
            string memory bannerUri,
            string memory profileName,
            string memory profileDescription,
            string[] memory rolesGot,
            address walletAddress,
            address parentDistributorAddress
        )
    {
        signUpDetails memory details = signedDetails[userAddress];
        return (
            details.logoImageUri,
            details.bannerImageUri,
            details.profileName,
            details.description,
            details.roles,
            details.walletAddress,
            details.parentDistributorAddress
        );
    }
}