/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface EmailRegistration {
    function getEmail(address walletAddress) external view returns (string memory);
    // Add other function signatures you want to interact with
}

contract MyEthereumContract {
    EmailRegistration private emailRegistrationContract;
    
    constructor(address emailRegistrationContractAddress) {
        emailRegistrationContract = EmailRegistration(emailRegistrationContractAddress);
    }

    function getEmailFromPolygon(address walletAddress) public view returns (string memory) {
        return emailRegistrationContract.getEmail(walletAddress);
    }
}