// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TokenVault {
    address private owner;
    mapping(address => bool) private supportedTokens;
    mapping(address => Transaction[]) private transactions;
    
    event Deposit(address indexed depositor, address indexed token, uint256 amount);
    event Withdrawal(address indexed recipient, address indexed token, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    struct Transaction {
        address depositor;
        address token;
        uint256 amount;
    }
    
    function addSupportedToken(address tokenContract) external onlyOwner {
        supportedTokens[tokenContract] = true;
    }
    
    function removeSupportedToken(address tokenContract) external onlyOwner {
        supportedTokens[tokenContract] = false;
    }
    
    function depositTokens(address tokenContract, uint256 amount) external {
        require(supportedTokens[tokenContract], "Token not supported.");
        require(amount > 0, "Amount must be greater than zero.");
        uint256 amounts = amount * 10**18;
        
        ERC20 token = ERC20(tokenContract);
        
        // Transfer tokens from the sender to the contract
        require(token.transferFrom(msg.sender, address(this), amounts), "Token transfer failed.");
        
        transactions[msg.sender].push(Transaction(msg.sender, tokenContract, amounts));
        
        emit Deposit(msg.sender, tokenContract, amounts);
    }
    
    function withdrawTokens(address tokenContract, uint256 amount) external {
        require(supportedTokens[tokenContract], "Token not supported.");
        require(amount > 0, "Amount must be greater than zero.");
        uint256 amounts = amount * 10**18;

        ERC20 token = ERC20(tokenContract);

        require(amounts <= token.balanceOf(address(this)), "Insufficient balance in the contract.");

        // Transfer tokens from the contract to the owner
        require(token.transfer(msg.sender, amounts), "Token transfer failed.");

        transactions[msg.sender].push(Transaction(msg.sender, tokenContract, amounts));

        emit Withdrawal(msg.sender, tokenContract, amounts);
    }
    
    function getContractBalance(address tokenContract) external view returns (uint256) {
        ERC20 token = ERC20(tokenContract);
        return token.balanceOf(address(this));
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner address.");
        owner = newOwner;
    }
    
    function isTokenSupported(address tokenContract) external view returns (bool) {
        return supportedTokens[tokenContract];
    }
    
    function getTransactionDetails(address account) external view returns (Transaction[] memory) {
        return transactions[account];
    }
}