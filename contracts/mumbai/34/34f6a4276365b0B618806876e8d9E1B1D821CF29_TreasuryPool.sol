// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Declare an interface called ERC20
interface ERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Declare the contract
contract TreasuryPool {
    // Declare variables
    address payable public withdrawalAddress; // Stores the wallet address for withdrawals
    ERC20 public token; // Stores the token contract
    address public owner;
    
    // Constructor function
    constructor(address _token) {
        token = ERC20(_token); // Initializes the token contract
        owner = msg.sender;
    }
    
    //This function call by only owner
    modifier onlyOwner(){
       require(msg.sender == owner ,"Only owner can call this function");
       _;
   }

    // Function to set the withdrawal address
    function setWithdrawalAddressForTreasury(address payable _withdrawalAddress) public onlyOwner{
        require(_withdrawalAddress != address(0),"Invalid Address"); // Check that the address is valid
        withdrawalAddress = _withdrawalAddress; // Set the withdrawal address
    }
    
    // Function to withdraw ETH and tokens
    function withdrawFundsFromTreasuryPool() external  onlyOwner{
        // Check that the withdrawal address is set
        require(withdrawalAddress != address(0),"Wallet address is not set");        
        // Withdraw ETH
        uint256 ethbalance = address(this).balance; // Get the contract's ETH balance
        require(ethbalance > 0 ,"insufficient balance"); // Check that the balance is greater than 0
        withdrawalAddress.transfer(ethbalance); // Transfer ETH to the withdrawal address
        
        // Withdraw tokens
        ERC20 tokenInstance = ERC20(token); // Declare an instance of the token contract
        uint256 tokenBalance = tokenInstance.balanceOf(address(this)); // Get the contract's token balance
        tokenInstance.transfer(withdrawalAddress, tokenBalance); // Transfer tokens to the withdrawal address
    }

    // Fallback function to receive ETH
    receive() external payable {}
}