/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract InvestmentContract {
    address private owner;
    mapping(address => uint256) private investors;
    mapping(address => bool) private investorTokens;
    address[] private investorAddresses;
    uint256 private totalInvested;
    
    struct InvestmentToken {
        uint256 value;
        address owner;
    }
    
    mapping(address => InvestmentToken) private investmentTokens;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    function invest() external payable {
        require(msg.value > 0, "Investment amount must be greater than zero");
        
        InvestmentToken memory token = InvestmentToken(msg.value, msg.sender);
        investmentTokens[msg.sender] = token;
        
        if (!investorTokens[msg.sender]) {
            investorAddresses.push(msg.sender);
            investorTokens[msg.sender] = true;
        }
        
        investors[msg.sender] += msg.value;
        totalInvested += msg.value;
    }
    
    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no funds to withdraw");
        payable(owner).transfer(contractBalance);
    }
    
    function deposit() external onlyOwner payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
    }
    
    function distributeProfitsAndLosses(int256 percentage) external onlyOwner {
        require(totalInvested > 0, "No investments made yet");
        int256 totalPercentage = 100;
        
        for (uint256 i = 0; i < investorAddresses.length; i++) {
            address investor = investorAddresses[i];
            
            if (investorTokens[investor]) {
                uint256 investment = investors[investor];
                
                int256 payment = (int256(investment) * percentage) / totalPercentage;
                uint256 totalPayment = investment + uint256(payment);
                
                if (percentage < 0) {
                    require(totalPayment <= investment, "Cannot distribute more than invested amount");
                    investors[investor] -= totalPayment;
                } else {
                    investors[investor] += uint256(payment);
                }
                
                payable(investor).transfer(totalPayment);
            }
        }
    }
    
    function getInvestedAmount(address investor) external view returns (uint256) {
        return investors[investor];
    }
    
    function getTotalInvested() external view returns (uint256) {
        return totalInvested;
    }
    
    function clearAllInvestors() external onlyOwner {
        for (uint256 i = 0; i < investorAddresses.length; i++) {
            delete investors[investorAddresses[i]];
            delete investmentTokens[investorAddresses[i]];
            investorTokens[investorAddresses[i]] = false;
        }
        delete investorAddresses;
        totalInvested = 0;
    }
    
    function transferToken(address newOwner) external {
        require(investorTokens[msg.sender], "Only investors can transfer tokens");
        require(newOwner != address(0), "Invalid recipient address");
        require(newOwner != msg.sender, "Cannot transfer tokens to yourself");
        
        InvestmentToken memory token = investmentTokens[msg.sender];
        delete investmentTokens[msg.sender];
        investorTokens[msg.sender] = false;
        
        investmentTokens[newOwner] = token;
        investorTokens[newOwner] = true;
    }
    
    function getInvestmentToken(address investor) external view returns (uint256, address) {
        require(investorTokens[investor], "Wallet does not hold an investment token");
        InvestmentToken memory token = investmentTokens[investor];
        return (token.value, token.owner);
    }
}