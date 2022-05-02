/**
 *Submitted for verification at polygonscan.com on 2022-05-01
*/

//SPDX-License-Identifier: MIT
// File contracts/Verification/Mock/Verification.sol

pragma solidity ^0.8.12;

/**
 * @author Polytrade
 * @title Verification
 */
contract Verification {
    mapping(address => bool) public userKYC;

    /**
     * @notice Function for test purpose to approve/revoke KYC for any user
     * @dev Not for PROD
     * @param user, address of the user to set KYC
     * @param status, true = approve KYC and false = revoke KYC
     */
    function setKYC(address user, bool status) external {
        userKYC[user] = status;
    }

    /**
     * @notice Returns whether a user's KYC is verified or not
     * @dev returns a boolean if the KYC is valid
     * @param user, address of the user to check
     * @return returns true if user's KYC is valid or false if not
     */
    function isValid(address user) external view returns (bool) {
        return userKYC[user];
    }
}