/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/Verification/interface/IVerification.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @author Polytrade
 * @title IVerification
 */
interface IVerification {
    /**
     * @notice Emits when new kyc Limit is set
     * @dev Emitted when new kycLimit is set by the owner
     * @param kycLimit, new value of kycLimit
     */
    event ValidationLimitUpdated(uint kycLimit);

    function setValidation(address user, bool status) external;

    function updateValidationLimit(uint validationLimit) external;

    /**
     * @notice Returns whether a user's KYC is verified or not
     * @dev returns a boolean if the KYC is valid
     * @param user, address of the user to check
     * @return returns true if user's KYC is valid or false if not
     */
    function isValid(address user) external view returns (bool);

    function isValidationRequired(uint amount) external view returns (bool);
}

// File contracts/Verification/Mock/Verification.sol

pragma solidity ^0.8.12;

/**
 * @author Polytrade
 * @title Verification
 */
contract Verification is IVerification {
    mapping(address => bool) public userValidation;

    uint public validationLimit;

    /**
     * @notice Function for test purpose to approve/revoke Validation for any user
     * @dev Not for PROD
     * @param user, address of the user to set Validation
     * @param status, true = approve Validation and false = revoke Validation
     */
    function setValidation(address user, bool status) external {
        userValidation[user] = status;
    }

    /**
     * @notice Updates the limit for the Validation to be required
     * @dev updates validationLimit variable
     * @param _validationLimit, new value of depositLimit
     *
     * Emits {NewValidationLimit} event
     */
    function updateValidationLimit(uint _validationLimit) external {
        validationLimit = _validationLimit;
        emit ValidationLimitUpdated(_validationLimit);
    }

    /**
     * @notice Returns whether a user's Validation is verified or not
     * @dev returns a boolean if the Validation is valid
     * @param user, address of the user to check
     * @return returns true if user's Validation is valid or false if not
     */
    function isValid(address user) external view returns (bool) {
        return userValidation[user];
    }

    function isValidationRequired(uint amount) external view returns (bool) {
        return amount >= validationLimit;
    }
}