/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract InvestmentContract {
    address private owner;
    mapping(address => uint256) private investors;
    mapping(address => InvestmentToken) private investmentTokens;
    address[] private investorAddresses;
    uint256 private totalInvested;
    
    struct InvestmentToken {
        address investor;
        uint256 investmentValue;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    function invest() external payable {
        require(msg.value > 0, "Investment amount must be greater than zero");
        
        if (investmentTokens[msg.sender].investor == address(0)) {
            // Mint and assign a new token to the investor
            InvestmentToken memory token = InvestmentToken(msg.sender, msg.value);
            investmentTokens[msg.sender] = token;
            investorAddresses.push(msg.sender);
        } else {
            // Update the existing token with the increased investment value
            investmentTokens[msg.sender].investmentValue += msg.value;
        }
        
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
            
            InvestmentToken memory token = investmentTokens[investor];
            uint256 investment = token.investmentValue;
            
            int256 payment = (int256(investment) * percentage) / totalPercentage;
            uint256 totalPayment = investment + uint256(payment);
            
            if (percentage < 0) {
                require(totalPayment <= investment, "Cannot distribute more than invested amount");
                investmentTokens[investor].investmentValue -= totalPayment;
            } else {
                investmentTokens[investor].investmentValue += uint256(payment);
            }
            
            payable(investor).transfer(totalPayment);
        }
    }
    
    function getInvestedAmount(address investor) external view returns (uint256) {
        return investmentTokens[investor].investmentValue;
    }
    
    function getTotalInvested() external view returns (uint256) {
        return totalInvested;
    }
    
    function clearAllInvestors() external onlyOwner {
        for (uint256 i = 0; i < investorAddresses.length; i++) {
            delete investmentTokens[investorAddresses[i]];
        }
        delete investorAddresses;
        totalInvested = 0;
    }
}