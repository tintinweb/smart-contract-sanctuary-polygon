// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
@author Mbazu Ifeanyichukwu Daniel
@dev Zoe bank

*/

// use safemath later for Arithemetic operations

contract Zoe{

    // State Variables
    address public bankOwner;
    string public bankName;

    // Mapping
    
    mapping(address => uint) public customerBalances; //customer balances

    mapping(address => bool) public registered; // checks if customer is registered

    // Events
    event Registered(address indexed customerAddress);

    event Deposit(address indexed customerAddress, uint depositAmount);

    event Withdraw(address indexed customerAddress, uint withdrawAmount, uint newBalance);

    event Transfer(address from, address to, uint transferAmount);

    // MODIFIERS

    modifier onlyBankOwner() {
        require(msg.sender == bankOwner, "You're not the owner of the bank"); _;
    }


    // Constructor
    constructor() {
        bankOwner = msg.sender;
    }

    // Fallback and Receive function
    receive() external payable {}

    fallback() external payable {}


    // Other function

    /// @dev Set the name of the bank
    function setBankName(string memory _name) external onlyBankOwner {
        bankName = _name;
        
    }

    ///@dev get balance of all deposit made to the bank
    function getBankBalance() external payable onlyBankOwner returns (uint) {
        return address(this).balance;
    }

    ///@dev registered customers into the bank
    function enrollCustomer() public returns(bool) {
        emit Registered(msg.sender);
        return registered[msg.sender] = true;
    }

    /// @dev Get balance of customer
    function getCustomerBalance() external payable returns(uint){
        uint  balances = customerBalances[msg.sender];

        return balances;
    }
    

    ///@notice deposit money into the bank
    ///@return the new balance of the user after deposit
    function depositMoney() external payable returns (uint) {
        // the customer must be registered
        require(registered[msg.sender] == true, "Customer is not registered");
        // you cannot deposit 0 amount
        require(msg.value != 0, "You don't have enough money to deposit");
        
        uint balance;
        customerBalances[msg.sender] = balance;
        customerBalances[msg.sender] += msg.value;

        // log event of the deposit made
        emit Deposit(msg.sender, msg.value);
        return customerBalances[msg.sender];
    }
    
    ///@dev customer withdraw money back to account 
    function withdrawMoney(uint withdrawAmount) external returns(uint) {
        require(customerBalances[msg.sender] >= withdrawAmount, "insufficient funds");

        // subtract withdrawAmount from customerBalances
        customerBalances[msg.sender] -= withdrawAmount;

        // transfer money from the bankAddress to the customer
        payable(bankOwner).transfer(withdrawAmount);

        emit Withdraw(msg.sender, withdrawAmount, customerBalances[msg.sender]);

        return customerBalances[msg.sender];
    }


    ///@dev send money to another account from your bank balances
    function transferMoney(address to, uint transferAmount) external returns(bool) {
       require(customerBalances[msg.sender] >= transferAmount, "insufficient funds");

        // subtract transferAmount from customerBalances
        customerBalances[msg.sender] -= transferAmount;

        // add amount to receivers account
        customerBalances[to] += transferAmount;

        // transfer money from the bankAddress to the customer
        payable(msg.sender).transfer(transferAmount);

        // _transfer(msg.sender, to, transferAmount);

        emit Transfer(msg.sender, to, transferAmount);
        return true;

    }







    



}