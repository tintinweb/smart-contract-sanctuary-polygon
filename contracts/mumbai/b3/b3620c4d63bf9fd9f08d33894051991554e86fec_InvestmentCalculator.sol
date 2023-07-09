/**
 *Submitted for verification at polygonscan.com on 2023-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InvestmentCalculator {
    uint256 public initialInvestment;  // 初始投资金额
    uint256 public annualInterestRate; // 年利率
    uint256 public investmentPeriod;   // 投资期限（年）
    
    constructor(uint256 _initialInvestment, uint256 _annualInterestRate, uint256 _investmentPeriod) {
        initialInvestment = _initialInvestment;
        annualInterestRate = _annualInterestRate;
        investmentPeriod = _investmentPeriod;
    }
    
    // 计算投资回报
    function calculateInvestmentReturn() public view returns (uint256) {
        uint256 totalReturn = initialInvestment;
        for (uint256 i = 0; i < investmentPeriod; i++) {
            uint256 yearlyInterest = (totalReturn * annualInterestRate) / 100;
            totalReturn += yearlyInterest;
        }
        return totalReturn;
    }
}