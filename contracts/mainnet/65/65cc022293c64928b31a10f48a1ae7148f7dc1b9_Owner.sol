/**
 *Submitted for verification at polygonscan.com on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.
pragma solidity ^0.8.11;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

/**
 * @dev  Create a shared wallet, giving to accounts the possibility to deposit, withdraw and transfer their fund.
 */
contract BankAccounts is Owner{

    /** 
     * @dev A payment with its properties (amount and timestamp)
     */
    struct Payment {
        int amount;
        uint timestamp;
    }

    /**
     * @dev The bank-account, with its properties (balance, numPayments, payments)
     * @member balance (uint)
     * @member numPayments (uint) counts the payments executed from the account
     * @member payments (payment[]) lists the payments l'elenco dei pagamenti effettuati (con relativi dettagli)
     */
    struct Account {
        uint balance;
        uint numPayments;
        mapping (uint => Payment) payments;
    }

    /**
     * @dev The list of bank-accounts (each one with its own properties)
     */
    mapping (address => Account) accounts;

    event depositedFunds(uint amount, address account);
    event withdrawnFunds(uint amount, address account);
    event transferredFunds(uint amount, address account, address beneficiary);


/** MODIFIERS */

    modifier checkFunds(uint _amount) {
        require (accounts[msg.sender].balance >= _amount, "Not enough money.");
        _;
    }

/** PUBLIC FUNCTIONS */ 


    /**
     * @dev Deposit funds to sender's bank-account
     * 
    */
    function deposit() public payable {
        accounts[msg.sender].balance += msg.value; // incremento il conto del sender @dev: aggiungere assert per overflow uint
        accounts[msg.sender].numPayments ++; // incremento il contatore dei pagamenti @dev: aggiungere assert per overflow uint
        accounts[msg.sender].payments[accounts[msg.sender].numPayments] = Payment ({
            amount: int(msg.value),
            timestamp: block.timestamp
        });
        emit depositedFunds(msg.value, msg.sender);
    }

    /**
     * @dev Withdraw funds from sender's bank-account to sender's wallet
     * @param _amount (uint) The amount of withdrawing 
     * 
    */
    function withdraw(uint _amount) public checkFunds(_amount) {
        accounts[msg.sender].balance -= _amount;
        accounts[msg.sender].numPayments++;
        accounts[msg.sender].payments[accounts[msg.sender].numPayments] = Payment ({
            amount: int ( 0 - int(_amount) ),
            timestamp: block.timestamp
        });
        emit withdrawnFunds(_amount, msg.sender);
        payable(msg.sender).transfer(_amount);
    }

    /**
     * @dev Transfer funds from sender's bank-account to an external wallet
     * @param _target (payable address) the beneficiary's address
     * @param _amount (uint) the amount of the transfer
     * 
    */
    function transferTo(address payable _target, uint _amount) public checkFunds(_amount) {
        accounts[msg.sender].balance -= _amount;
        _target.transfer(_amount);
        emit transferredFunds(_amount, msg.sender, address(_target));
    }

    /**
     * @dev View the balance of caller's bank-account
     * @return (uint) the balance of caller's bank-account
     * 
    */
    function myBalance() public view returns (uint) {
        return accounts[msg.sender].balance;
    }

/** EXTERNAL FUNCTIONS */ 

    receive() external payable {
        deposit();
    }
}