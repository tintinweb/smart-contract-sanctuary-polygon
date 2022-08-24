/**
 *Submitted for verification at polygonscan.com on 2022-08-23
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
        string twitterUri;
        string youtubeUri;
        string facebookUri;
    }

    mapping(address => signUpDetails) private signedDetails;
    address[] public profileAddresses;

    event CreateProfile(
        string logoImageUri,
        string bannerIamgeUri,
        address walletAddress,
        string profileName,
        string description,
        string[] roles
    );
    event UpdateProfile(
        string logoImageUri,
        string bannerIamgeUri,
        string profileName,
        string description,
        string[] roles,
        string twitterUri,
        string youtubeUri,
        string facebookUri
    );
    event DeleteProfile(address user, string isSuccess);

    /* 
      Create Profile 
      we will use address to map details of particular wallet address
    */
    function createProfile(
        address _parentDistributorAddress,
        string[] memory _roles,
        string memory _logoImageUri,
        string memory _bannerIamgeUri,
        string memory _profileName,
        string memory _description,
        address walletAddress
    ) public {
        signUpDetails storage details = signedDetails[walletAddress];
        details.logoImageUri = _logoImageUri;
        details.bannerImageUri = _bannerIamgeUri;
        details.profileName = _profileName;
        details.description = _description;
        details.roles = _roles;
        details.parentDistributorAddress = _parentDistributorAddress;
        details.walletAddress = walletAddress;
        emit CreateProfile(
            _logoImageUri,
            _bannerIamgeUri,
            walletAddress,
            _profileName,
            _description,
            _roles
        );
        profileAddresses.push(walletAddress);
    }

    /* Edit Profile */
    function editProfile(
        string[] memory _roles,
        string memory _logoImageUri,
        string memory _bannerIamgeUri,
        string memory _profileName,
        string memory _description,
        string memory _twitterUri,
        string memory _facebookUri,
        string memory _youtubeUri
    ) public {
        require(
            signedDetails[msg.sender].walletAddress != address(0),
            "No Account Created!"
        );
        signUpDetails storage details = signedDetails[msg.sender];

        if (bytes(_logoImageUri).length != bytes("").length) {
            details.logoImageUri = _logoImageUri;
        }
        if (bytes(_bannerIamgeUri).length != bytes("").length) {
            details.bannerImageUri = _bannerIamgeUri;
        }
        if (bytes(_profileName).length != bytes("").length) {
            details.profileName = _profileName;
        }
        if (bytes(_description).length != bytes("").length) {
            details.description = _description;
        }
        if (bytes(_twitterUri).length != bytes("").length) {
            details.twitterUri = _twitterUri;
        }
        if (bytes(_youtubeUri).length != bytes("").length) {
            details.youtubeUri = _youtubeUri;
        }
        if (bytes(_facebookUri).length != bytes("").length) {
            details.facebookUri = _facebookUri;
        }
        details.roles = _roles;
        emit UpdateProfile(
            _logoImageUri,
            _bannerIamgeUri,
            _profileName,
            _description,
            _roles,
            _twitterUri,
            _youtubeUri,
            _facebookUri
        );
    }

    /* Delete Profile */
    function deleteProfile() public {
        require(
            signedDetails[msg.sender].walletAddress != address(0),
            "No Account Created!"
        );
        delete signedDetails[msg.sender];
        findAndDelete(msg.sender);
        emit DeleteProfile(msg.sender, "User Profile Deleted");
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
            address parentDistributorAddress,
            string memory twitterUri,
            string memory youtubeUri,
            string memory facebookUri
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
            details.parentDistributorAddress,
            details.twitterUri,
            details.youtubeUri,
            details.facebookUri
        );
    }

    function userExists(address user) view external returns(bool){
        for(uint256 i = 0; i < profileAddresses.length ; i++) {
            if (profileAddresses[i] == user) {
                return true;
            }
        }
        return false;
    }

    function findAndDelete(address user) internal {
        uint256 elementPosition;
         for(uint256 i = 0; i < profileAddresses.length ; i++) {
            if (profileAddresses[i] == user) {
               elementPosition = i;
               for(uint j = i; j < profileAddresses.length-1; j++){
                     profileAddresses[j] = profileAddresses[j+1]; 
                     profileAddresses.pop();     
                 }
            }
        }
    }
}