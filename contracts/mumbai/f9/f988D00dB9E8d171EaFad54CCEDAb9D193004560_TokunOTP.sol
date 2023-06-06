/**
 *Submitted for verification at polygonscan.com on 2023-06-06
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
    mapping(address => mapping(string => mapping(uint256 => OTP))) multipleOTPMapping;

    // Empty Constructor
    constructor() {

    }

    // View Function
    function getOTP(string memory contractAddress, uint256 tokenID) public view returns(OTP memory) {
        return multipleOTPMapping[msg.sender][contractAddress][tokenID];
    }

    ///////////////////////////
	// OTP Functionality
	///////////////////////////

    // Initialize a new OTP for an address for token redeeming
    // Only need to init OTP one time for each token
    function initOTP(string memory contractAddress, uint256 tokenID, string memory tokenMetadata, string memory proverToken) public {
        // Requires the current OTPToken be 0x0 / the otp is not initialized yet
        require(multipleOTPMapping[msg.sender][contractAddress][tokenID].OTPToken == 0x0, "You already initialize an OTP for this token.");

        // Requires the proverToken not to be an empty stringg
        require(bytes(proverToken).length != 0, "The token can't be empty");

        // if the check passes, call the internal OTP initialization function
        _initOTP(contractAddress, tokenID, tokenMetadata, proverToken);
    }

    // Verifies an OTP Token to redeem the token
    function verifyOTP(string memory contractAddress, uint256 tokenID, address ownerAddress, string memory verifierToken) public returns(string memory) {
        // Requires the token to be already set up to be redeemed
        require(multipleOTPMapping[ownerAddress][contractAddress][tokenID].OTPToken != 0x0, "this token hasn't been set to be redeemed yet");
        
        // Requires the token has not been redeemed yet
        require(multipleOTPMapping[ownerAddress][contractAddress][tokenID].redeemStatus == false, "This token has been redeemed");

        // if the check passes, call the internal OTP verification function
        return _verifyOTP(contractAddress, tokenID, ownerAddress, verifierToken);
    }

    function _initOTP(string memory contractAddress, uint256 tokenID, string memory tokenMetadata, string memory proverToken) internal {
        multipleOTPMapping[msg.sender][contractAddress][tokenID].tokenMetadata = tokenMetadata;
        multipleOTPMapping[msg.sender][contractAddress][tokenID].OTPToken = keccak256(abi.encode(proverToken));
        multipleOTPMapping[msg.sender][contractAddress][tokenID].redeemStatus = false;
    }

    function _verifyOTP(string memory contractAddress, uint256 tokenID, address ownerAddress, string memory verifierToken) internal returns(string memory) {
        if (multipleOTPMapping[ownerAddress][contractAddress][tokenID].OTPToken == keccak256(abi.encode(verifierToken))) {
            emit OTPVerificationSuccessful(true);
            multipleOTPMapping[ownerAddress][contractAddress][tokenID].redeemStatus = true;
            return multipleOTPMapping[ownerAddress][contractAddress][tokenID].tokenMetadata;
        } else {
            emit OTPVerificationSuccessful(false);
            return "Verification Failed";
        }
    }

}