// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Trikl
 * @dev Implements a decentralized version of patreon for crypto traders and content creators
 */

contract TriklV1 {
    address owner;

    // custom error to save gas
    error NotOwner();
    error InsufficientBalance();

    /**
     * @dev Sets the creator the owner of t he smart contract.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Checks if the function is accessed by owner, if not, throws an error .
     */
    modifier ownerOnly() {
        if (owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    /********************************************************
     *                                                       *
     *                    MAIN FUNCTIONS                     *
     *                                                       *
     ********************************************************/

    /**
     * @dev Handles the payment for each subscription. This function is
     * called when the subscriber initiate the transcation to transfer the money to Creator's wallet.
     * 2.5% of the total amount goes to Trikl funds
     *
     * @param _creatorAddress - The address of the creator to whom the amount (97.5%) would be transfered
     * msg.value - The amount of tokens being transferred
     */
    function subscribe(address _creatorAddress) external payable {
        payable(_creatorAddress).transfer((msg.value * 975) / 1000);
    }

    /**
     * @dev Handles the withdrawal of the amount from Smart Contract. This function is only accessible
     * the owner of the smart contract.
     *
     * @param _withdrawTo - The address to which the owner want the funds from smart contract to be transfered
     * @param _amount - The amount of tokens being transferred
     */
    function withdraw(address _withdrawTo, uint256 _amount)
        external
        payable
        ownerOnly
    {
        if (_amount > address(this).balance) {
            revert InsufficientBalance();
        }
        payable(_withdrawTo).transfer(_amount);
    }

    /********************************************************
     *                                                       *
     *                     GET FUNCTIONS                     *
     *                                                       *
     ********************************************************/

    /**
     * @dev get functions to check the owner of the smart contract and
     * to fetch the balance of the smart contract
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}