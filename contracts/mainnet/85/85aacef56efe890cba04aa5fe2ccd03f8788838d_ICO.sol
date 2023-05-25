/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ICO {
    address public tokenAddress;
    address payable public beneficiary;
    uint256 public tokenPrice;
    uint256 public targetAmount;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public totalContributions;
    uint256 public totalTokensSold;
    bool public isActive;

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public refundAmounts;

    event Contribution(address indexed contributor, uint256 amount);
    event RefundClaimed(address indexed contributor, uint256 amount);
    event ICOCompleted(uint256 totalContributions, uint256 totalTokensSold);

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the beneficiary can perform this action");
        _;
    }

    constructor(
        address _tokenAddress,
        address payable _beneficiary,
        uint256 _tokenPrice,
        uint256 _targetAmount,
        uint256 _minContribution,
        uint256 _maxContribution
    ) {
        tokenAddress = _tokenAddress;
        beneficiary = _beneficiary;
        tokenPrice = _tokenPrice;
        targetAmount = _targetAmount;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        isActive = true;
    }

    function getTokenBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function contribute() external payable {
        require(isActive, "ICO is currently not active");
        require(msg.value >= minContribution, "Contribution amount is below the minimum");
        require(msg.value <= maxContribution, "Contribution amount exceeds the maximum");

        uint256 tokensToTransfer = msg.value * tokenPrice;
        require(getTokenBalance() >= tokensToTransfer, "Insufficient tokens in the contract");

        totalContributions += msg.value;
        contributions[msg.sender] += msg.value;
        totalTokensSold += tokensToTransfer;

        emit Contribution(msg.sender, msg.value);

        if (totalContributions >= targetAmount) {
            emit ICOCompleted(totalContributions, totalTokensSold);
            isActive = false;
        }

        require(IERC20(tokenAddress).transfer(msg.sender, tokensToTransfer), "Token transfer failed");
    }

    function claimRefund() external {
        require(!isActive, "ICO is still active");
        require(totalContributions < targetAmount, "Target amount reached, no refunds available");
        require(contributions[msg.sender] > 0, "No contribution made");

        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        refundAmounts[msg.sender] += refundAmount;

        emit RefundClaimed(msg.sender, refundAmount);

        payable(msg.sender).transfer(refundAmount);
    }

    function withdrawFunds() external onlyBeneficiary {
        require(address(this).balance > 0, "No funds available to withdraw");
        beneficiary.transfer(address(this).balance);
    }

    function end() external onlyBeneficiary {
        isActive = false;
    }

    function balanceOf(address account) external view returns (uint256) {
        return contributions[account];
    }
}