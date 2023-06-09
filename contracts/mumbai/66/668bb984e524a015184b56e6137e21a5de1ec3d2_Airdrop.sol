/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Airdrop {
    address public admin;
    IERC20 public token;
    uint256 public claimLimit;
    uint256 public claimCost;
    uint256 public maxTokensPerClaim;
    uint256 public maxClaimCount;

    mapping(address => uint256) public claimCount;

    event AirdropClaimed(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        admin = msg.sender;
        token = IERC20(_tokenAddress);
        claimLimit = 10;  // Default claim limit
        claimCost = 1;    // Default claim cost
        maxTokensPerClaim = 100; // Default maximum tokens per claim
        maxClaimCount = 5; // Default maximum claim count
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function claimAirdrop() external payable {
        require(claimCount[msg.sender] < claimLimit, "You have reached the maximum claim limit");
        require(msg.value == claimCost, "Incorrect claim cost");

        // Check if the maximum tokens per claim is not exceeded
        uint256 tokensToClaim = claimCost;
        require(tokensToClaim <= maxTokensPerClaim, "Exceeded maximum tokens per claim");

        // Check if the maximum claim count is not exceeded
        require(claimCount[msg.sender] < maxClaimCount, "Exceeded maximum claim count");

        // Transfer tokens to the user
        token.transfer(msg.sender, tokensToClaim);

        // Increment the claim count for the user
        claimCount[msg.sender]++;

        emit AirdropClaimed(msg.sender, tokensToClaim);
    }

    function setClaimLimit(uint256 _limit) external onlyAdmin {
        claimLimit = _limit;
    }

    function setClaimCost(uint256 _cost) external onlyAdmin {
        claimCost = _cost;
    }

    function setMaxTokensPerClaim(uint256 _maxTokens) external onlyAdmin {
        maxTokensPerClaim = _maxTokens;
    }

    function setMaxClaimCount(uint256 _maxCount) external onlyAdmin {
        maxClaimCount = _maxCount;
    }

    function withdrawFunds(uint256 amount) external onlyAdmin {
        require(amount <= address(this).balance, "Insufficient contract balance");

        payable(admin).transfer(amount);
    }

    function withdrawTokens(uint256 amount) external onlyAdmin {
        require(amount <= token.balanceOf(address(this)), "Insufficient token balance");

        token.transfer(admin, amount);
    }
}