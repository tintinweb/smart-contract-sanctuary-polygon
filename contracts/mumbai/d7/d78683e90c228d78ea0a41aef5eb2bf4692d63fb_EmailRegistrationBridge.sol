/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface EmailRegistrationInterface {
    function getEmail(address walletAddress) external view returns (string memory);
    // Add other functions from the EmailRegistration contract that you want to interact with
}

contract EmailRegistrationBridge {
    EmailRegistrationInterface private emailRegistrationContract;

    constructor(address emailRegistrationContractAddress) {
        emailRegistrationContract = EmailRegistrationInterface(emailRegistrationContractAddress);
    }

    function getEmail(address walletAddress) external view returns (string memory) {
        return emailRegistrationContract.getEmail(walletAddress);
    }

    // Add other functions and their implementations to interact with the EmailRegistration contract

    // Remember to handle the payable functions and events if required

    // Add modifiers and any other necessary functions or logic

    // Implement the fallback function to receive and process function calls from the other chain
    fallback() external payable {
        revert("Fallback function is not supported");
    }
}