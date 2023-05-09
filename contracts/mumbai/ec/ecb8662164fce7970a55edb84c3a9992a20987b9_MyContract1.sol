//SPDX-License-Identifier: MIT
// Specify the Solidity version
pragma solidity ^0.8.0;

// Import the necessary libraries and interfaces
import "./IERC20.sol";

// Create the smart contract
contract MyContract1 {
    // Define the Matic token address
    address public constant MATIC_TOKEN_ADDRESS = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;
    
    // Define the Metamask signup event
    event SignUp(address user);
    
    // Define the deposit event
    event Deposit(address user, uint256 amount);
    
    // Define the withdraw event
    event Withdraw(address user, uint256 amount);
    
    // Define the mapping for user balances
    mapping(address => uint256) public balances;
    
    // Define the function for signing up with Metamask
    function signUp() public {
        // Emit the signup event
        emit SignUp(msg.sender);
    }
    
    // Define the function for depositing Matic tokens
    function deposit(uint256 amount) public {
        // Transfer Matic tokens from the user to the contract
        IERC20(MATIC_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount);
        
        // Increase the user's balance
        balances[msg.sender] += amount;
        
        // Emit the deposit event
        emit Deposit(msg.sender, amount);
    }
    
    // Define the function for withdrawing Matic tokens
    function withdraw(uint256 amount) public {
        // Check that the user has enough tokens to withdraw
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Transfer Matic tokens from the contract to the user
        IERC20(MATIC_TOKEN_ADDRESS).transfer(msg.sender, amount);
        
        // Decrease the user's balance
        balances[msg.sender] -= amount;
        
        // Emit the withdraw event
        emit Withdraw(msg.sender, amount);
    }
}