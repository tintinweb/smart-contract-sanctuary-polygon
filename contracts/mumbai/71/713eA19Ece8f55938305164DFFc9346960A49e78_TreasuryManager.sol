// SPDX-License-Identifier: ISC

pragma solidity ^0.8.9;

contract TreasuryManager {
    // TODO: Change me
    address public signer1 = 0x153c06Ce630e38Fc4f04aFB6157f351DA66aEA67;
    address public signer2 = 0x5eE4680F520380e30F5022dfc98C89A20AC031FD;

    // TODO: Change me
    address public recipient1 = 0x153c06Ce630e38Fc4f04aFB6157f351DA66aEA67;
    address public recipient2 = 0x5eE4680F520380e30F5022dfc98C89A20AC031FD;

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
    receive() external payable {
        payable(currentRecipient).transfer(msg.value);
    }

    /**
     * @dev Withdraws all contract funds to the current recipient.
     * @dev Can only be called by a signer.
     */
    function withdraw() external onlySigners(msg.sender) {
        payable(currentRecipient).transfer(address(this).balance);
    }
}