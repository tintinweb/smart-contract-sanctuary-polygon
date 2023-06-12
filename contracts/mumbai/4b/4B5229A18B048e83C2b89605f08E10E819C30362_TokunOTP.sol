/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TokunOTP {
    // A Struct for an OTP
    struct OTP {
        string tokenMetadata;
        bytes32 OTPToken;
        bool redeemStatus;
    }

    event OTPVerificationSuccessful(bool success);

    // Mapping of address => contractAddress => tokenID => OTP Struct
    mapping(address => mapping(string => mapping(uint256 => OTP))) OTPMapping;

    // Empty Constructor
    constructor() {}

    // View Function
    function getOTP(address ownerAddress, string memory contractAddress, uint256 tokenID, string memory otpToken) public view returns(OTP memory) {
        if (OTPMapping[ownerAddress][contractAddress][tokenID].OTPToken != 0x0) {
            require(OTPMapping[ownerAddress][contractAddress][tokenID].OTPToken == sha256(bytes(otpToken)), "OTP Token doesn't match");
            return OTPMapping[ownerAddress][contractAddress][tokenID];
        } else {
            return OTPMapping[ownerAddress][contractAddress][tokenID];
        }
    }

    ///////////////////////////
	// OTP Functionality
	///////////////////////////

    // Initialize a new OTP for an address for token redeeming
    // Only need to init OTP one time for each token
    function initOTP(
        address ownerAddress,
        string memory contractAddress,
        uint256 tokenID,
        string memory tokenMetadata,
        bytes32 proverToken
        ) 
        public
        {
        // Requires the current OTPToken be 0x0 / the otp is not initialized yet
        require(OTPMapping[ownerAddress][contractAddress][tokenID].OTPToken == 0x0, "You already initialize an OTP for this token.");

        // Requires the proverToken not to be an empty stringg
        require(proverToken.length != 0x0, "The token can't be empty");

        // if the check passes, call the internal OTP initialization function
        _initOTP(ownerAddress, contractAddress, tokenID, tokenMetadata, proverToken);
    }

    // Verifies an OTP Token to redeem the token
    function verifyOTP(
        address ownerAddress,
        string memory contractAddress,
        uint256 tokenID,
        string memory verifierToken
        )
        public
        {
        // Requires the token to be already set up to be redeemed
        require(OTPMapping[ownerAddress][contractAddress][tokenID].OTPToken != 0x0, "this token hasn't been set to be redeemed yet");
        
        // Requires the token has not been redeemed yet
        require(OTPMapping[ownerAddress][contractAddress][tokenID].redeemStatus == false, "This token has been redeemed");

        // if the check passes, call the internal OTP verification function
        _verifyOTP(ownerAddress, contractAddress, tokenID, verifierToken);
    }

    function _initOTP(
        address ownerAddress,
        string memory contractAddress,
        uint256 tokenID,
        string memory tokenMetadata,
        bytes32 proverToken
        ) 
        internal
        {
        OTPMapping[ownerAddress][contractAddress][tokenID].tokenMetadata = tokenMetadata;
        OTPMapping[ownerAddress][contractAddress][tokenID].OTPToken = proverToken;
        OTPMapping[ownerAddress][contractAddress][tokenID].redeemStatus = false;
    }

    function _verifyOTP(
        address ownerAddress,
        string memory contractAddress,
        uint256 tokenID,
        string memory verifierToken
        ) 
        internal
        {
        if (OTPMapping[ownerAddress][contractAddress][tokenID].OTPToken == sha256(bytes(verifierToken))) {
            emit OTPVerificationSuccessful(true);
            OTPMapping[ownerAddress][contractAddress][tokenID].redeemStatus = true;
        } else {
            emit OTPVerificationSuccessful(false);
        }
    }
}