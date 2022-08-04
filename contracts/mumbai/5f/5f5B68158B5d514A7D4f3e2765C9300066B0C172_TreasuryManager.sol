// SPDX-License-Identifier: ISC

pragma solidity ^0.8.9;

contract TreasuryManager {
    // TODO: Change me
    address public constant signer1 =
        0x153c06Ce630e38Fc4f04aFB6157f351DA66aEA67;
    address public constant signer2 =
        0x5eE4680F520380e30F5022dfc98C89A20AC031FD;

    // TODO: Change me
    address public constant recipient1 =
        0x153c06Ce630e38Fc4f04aFB6157f351DA66aEA67;
    address public constant recipient2 =
        0x5eE4680F520380e30F5022dfc98C89A20AC031FD;

    address public currentRecipient = recipient1;

    bool[2] public signatures = [false, false];

    constructor() {}

    /*************************************************************************
     ********************************** MODIFIERS ****************************
     *************************************************************************/
    /**
     * @dev Reverts if not all signatures are true.
     */
    modifier allSignatures() {
        require(
            signatures[0] && signatures[1],
            "TreasuryManager: All signers must sign before proceeding."
        );
        _;
    }

    /**
     * @dev Reverts if caller is not currentRecipient.
     * @param caller The address of the caller.
     */
    modifier onlyCurrentRecipient(address caller) {
        require(
            caller == currentRecipient,
            "TreasuryManager: Only current recipient can call this function."
        );
        _;
    }

    /**
     * @dev Reverts if caller is not signer1 or signer2.
     * @param caller The address of the caller.
     */
    modifier onlySigners(address caller) {
        require(
            caller == signer1 || caller == signer2,
            "TreasuryManager: Only signer1 or signer2 can call this function."
        );
        _;
    }

    /*************************************************************************
     ********************************** SETTERS ******************************
     *************************************************************************/
    /**
     * @dev Switches the current recipient.
     * @dev Reverts if not all signers have previously signed.
     * @dev Can only be called by a signer.
     * @dev Reverts if contract balance is not empty.
     */
    function setCurrentRecipient()
        external
        onlySigners(msg.sender)
        allSignatures
    {
        currentRecipient = currentRecipient == recipient1
            ? recipient2
            : recipient1;
        revokeAll();
    }

    /**
     * @dev Allows a signer to revoke their signature.
     * @dev Can only be called by a signer.
     */
    function revoke() external onlySigners(msg.sender) {
        if (msg.sender == signer1) {
            signatures[0] = false;
        } else {
            signatures[1] = false;
        }
    }

    /**
     * @dev Revokes all signatures
     */
    function revokeAll() internal {
        signatures[0] = false;
        signatures[1] = false;
    }

    /**
     * @dev Allows a signer to sign, stating their intent to flip the recipient.
     * @dev Can only be called by a signer.
     */
    function sign() external onlySigners(msg.sender) {
        if (msg.sender == signer1) {
            signatures[0] = true;
        } else {
            signatures[1] = true;
        }
    }

    /*************************************************************************
     ***************************** TREASURY MANAGEMENT ***********************
     *************************************************************************/
    /**
     * @dev Fallback payable function.
     */
    receive() external payable {}

    /**
     * @dev Withdraws all contract funds to the current recipient.
     * @dev Can only be called by a signer.
     */
    function withdrawAllToCurrentRecipient() external onlySigners(msg.sender) {
        withdrawTo(currentRecipient, address(this).balance);
    }

    /**
     * @dev Withdraws all contract funds to the given recipient.
     * @dev Can only be called by currentRecipient.
     */
    function withdrawAllToExternalRecipient(address to)
        external
        onlyCurrentRecipient(msg.sender)
    {
        withdrawTo(to, address(this).balance);
    }

    /**
     * @dev Withdraws some contract funds to the given recipient.
     * @dev Can only be called by currentRecipient.
     * @param to The address of the recipient.
     */
    function withdrawSomeToExternalRecipient(address to, uint256 amount)
        external
        onlyCurrentRecipient(msg.sender)
    {
        withdrawTo(to, amount);
    }

    /**
     * @dev Internal function for withdrawing contract funds to a given recipient.
     * @dev Cannot be called if contract balance is empty.
     * @dev Withdraw amount must be less than or equal to the contract balance.
     * @dev Amount must be positive.
     * @dev Cannot withdraw to the contract.
     * @dev Cannot withdraw to the null address.
     */
    function withdrawTo(address to, uint256 amount) internal {
        require(
            address(this).balance > 0,
            "TreasuryManager: Contract has no funds."
        );
        require(
            amount <= address(this).balance,
            "TreasuryManager: Withdrawal amount exceeds contract balance."
        );
        require(
            amount > 0,
            "TreasuryManager: Withdrawal amount must be greater than 0."
        );
        require(
            to != address(this),
            "TreasuryManager: Withdrawal to self is not allowed."
        );
        require(
            to != address(0),
            "TreasuryManager: Withdrawal to the null address is not allowed."
        );

        // Initiate transfer.
        payable(to).transfer(amount);
    }
}