/**
 *Submitted for verification at polygonscan.com on 2022-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SavingAccount {
    string private issuer;
    string private bankAccountNumber;
    address private bank;
    string private savingsAccoutNumber;
    string private timeCreated;
    string private interestRate; // how should we address the problem of float?
    string private savingType;
    int private savingPeriod; // months
    int private savingAmount;
    string private transactionUnit;
    int private interestAmount;
    int private totalReturnAmount;

    // mapping(string => SavingAccount[]) private txnOfBankAccount;

    constructor (
        string memory _issuer,
        string memory _bankAccountNumber,
        string memory _savingsAccountNumber,
        string memory _interestRate,
        string memory _savingType,
        int _savingPeriod,
        int _savingAmount,
        string memory _transactionUnit
    ) {
        // checkers

        require(_savingPeriod > 1, "Invalid saving period");
        require(_savingAmount > 500000, "Invalid saving amount");

        bank = msg.sender;

        issuer = _issuer;
        bankAccountNumber = _bankAccountNumber;
        savingAmount = _savingAmount;
        savingsAccoutNumber = _savingsAccountNumber;
        interestRate = _interestRate;
        savingType = _savingType;
        savingPeriod = _savingPeriod;
        savingAmount = _savingAmount;
        transactionUnit = _transactionUnit;
    }

    function setInterestAmount(int _interestAmount) public {
        require(_interestAmount > 0, "Invalid interest amount");
        interestAmount = _interestAmount;
    }

    function setTotalReturnAmount(int _totalReturnAmount) public {
        require(_totalReturnAmount >= savingAmount, "Invalid total return amount");
        totalReturnAmount = _totalReturnAmount;
    }

    event OpenSavingsAccount (
        string indexed _bankAccountNumber,
        string indexed _savingsAccountNumber,
        string indexed _timeIssued,
        int _savingAmount,
        int _savingPeriod,
        string _interestRate,
        string _savingType
    );

    event SettleSavingsAccount (
        string indexed _bankAccountNumber,
        string indexed _savingsAccountNumber,
        string indexed _timeIssued
    );

    function registerSavingAccount(
        string memory _bankAccountNumber,
        string memory _savingsAccountNumber,
        int _savingAmount,
        int _savingPeriod,
        string memory _interestRate,
        string memory _savingType,
        string memory _timeIssued
    ) public {
        emit OpenSavingsAccount(_bankAccountNumber, _savingsAccountNumber, _timeIssued, _savingAmount, _savingPeriod, _interestRate, _savingType);
    }

    function settleSavingAccount(
        string memory _bankAccountNumber,
        string memory _savingsAccountNumber,
        string memory _timeIssued
    ) public {
        emit SettleSavingsAccount(_bankAccountNumber, _savingsAccountNumber, _timeIssued);
    }
}