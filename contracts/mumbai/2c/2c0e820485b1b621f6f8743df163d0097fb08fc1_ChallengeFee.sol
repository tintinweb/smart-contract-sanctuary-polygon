// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Ownable.sol";

contract ChallengeFee is Ownable {
    /**
     * @dev This struct represents various settings related to fees.
     * The SUCCESS_FEE field represents the fee amount for successful operations.
     * The FAIL_FEE field represents the fee amount for failed operations.
     */
    struct Settings {
        uint8 SUCCESS_FEE; // Represents the fee amount for successful operations.
        uint8 FAIL_FEE; // Represents the fee amount for failed operations.
    }

    /**
     * @dev Emitted when the amount of fees is determined.
     * @param successFee Represents the fee amount for successful operations.
     * @param failFee Represents the fee amount for failed operations.
     */
    event AmountFee(
        uint8 successFee, // Represents the fee amount for successful operations.
        uint8 failFee // Represents the fee amount for failed operations.
    );

    /**
     * @dev Represents the global settings for the contract.
     */
    Settings public SETTINGS;

    /**
     * @dev Modifier to check the validity of the amount fee values.
     * @param _amountSuccessFee The amount of success fee.
     * @param _amountFailFee The amount of fail fee.
     */
    modifier checkAmountFee(uint8 _amountSuccessFee, uint8 _amountFailFee) {
        require(
            _amountSuccessFee >= 0 && _amountSuccessFee < 100,
            "Amount success fee is invalid"
        );
        require(
            _amountFailFee >= 0 && _amountFailFee < 100,
            "Amount fail fee is invalid"
        );
        _;
    }

    /**
     * @dev Contract constructor that sets the initial amount of success fee and fail fee.
     * @param _amountSuccessFee The amount of success fee.
     * @param _amountFailFee The amount of fail fee.
     */
    constructor(
        uint8 _amountSuccessFee,
        uint8 _amountFailFee
    ) checkAmountFee(_amountSuccessFee, _amountFailFee) {
        SETTINGS.SUCCESS_FEE = _amountSuccessFee;
        SETTINGS.FAIL_FEE = _amountFailFee;
        emit AmountFee(_amountSuccessFee, _amountFailFee);
    }

    /**
     * @dev Retrieves the current amount fee settings.
     * @return successFee The current amount of success fee.
     * @return failFee The current amount of fail fee.
     */
    function getAmountFee()
        external
        view
        returns (uint8 successFee, uint8 failFee)
    {
        successFee = SETTINGS.SUCCESS_FEE;
        failFee = SETTINGS.FAIL_FEE;
    }

    /**
     * @dev Updates the amount fee settings.
     * @param _amountSuccessFee The new amount of success fee.
     * @param _amountFailFee The new amount of fail fee.
     */
    function setFees(
        uint8 _amountSuccessFee,
        uint8 _amountFailFee
    ) external onlyOwner checkAmountFee(_amountSuccessFee, _amountFailFee) {
        SETTINGS.SUCCESS_FEE = _amountSuccessFee;
        SETTINGS.FAIL_FEE = _amountFailFee;
        emit AmountFee(_amountSuccessFee, _amountFailFee);
    }
}