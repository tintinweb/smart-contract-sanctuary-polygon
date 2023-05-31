/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract InvestmentContract {
    address private owner;
    mapping(address => uint256) private investors;
    mapping(address => bool) private hasToken;
    address[] private investorAddresses;
    uint256 private totalInvested;
    uint256 private tokenValue = 1; // Value of the ERC20 token representing the investment

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function invest() external payable {
        require(msg.value > 0, "Investment amount must be greater than zero");

        if (!hasToken[msg.sender]) {
            investorAddresses.push(msg.sender);
            hasToken[msg.sender] = true;
        }
        
        investors[msg.sender] += msg.value;
        totalInvested += msg.value;
        
        // Mint ERC20 token to represent the investment
        // Assume the ERC20 contract is already deployed and has a mint function
        ERC20Token(address(0xb9eF5660d2F7a2b8Ad9cE6fFa384aC3FeeE7F196)).mint(msg.sender, msg.value * tokenValue);
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
            
            // Skip investors who don't have the ERC20 token
            if (!hasToken[investor]) {
                continue;
            }
            

            uint256 tokenBalance = ERC20Token(address(0xb9eF5660d2F7a2b8Ad9cE6fFa384aC3FeeE7F196)).balanceOf(investor);
            uint256 investmentValue = tokenBalance / tokenValue;

            int256 payment = (int256(investmentValue) * percentage) / totalPercentage;
            uint256 totalPayment = investmentValue + uint256(payment);

            if (percentage < 0) {
                require(totalPayment <= investmentValue, "Cannot distribute more than invested amount");
                investors[investor] -= totalPayment;
            } else {
                investors[investor] += uint256(payment);
            }

            payable(investor).transfer(totalPayment);
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
            hasToken[investorAddresses[i]] = false;
        }
        delete investorAddresses;
        totalInvested = 0;
    }
}

// ERC20 token contract
contract ERC20Token {
    mapping(address => uint256) public balanceOf;
    
    function mint(address account, uint256 amount) external {
        balanceOf[account] += amount;
    }
}