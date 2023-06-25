/**
 *Submitted for verification at polygonscan.com on 2023-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenSwap {
    address public appleTokenAddress;
    address public orangeTokenAddress;
    
    uint256 public exchangeRate = 2; // 2 Orange tokens for 1 Apple token
    
    event TokensSwapped(address indexed sender, uint256 orangeAmount, uint256 appleAmount);

    constructor(address _appleTokenAddress, address _orangeTokenAddress) {
        appleTokenAddress = _appleTokenAddress;
        orangeTokenAddress = _orangeTokenAddress;
    }
    
    function estimateGas(uint256 orangeAmount) external view returns (uint256) {
        IERC20 appleToken = IERC20(appleTokenAddress);
        IERC20 orangeToken = IERC20(orangeTokenAddress);
        
        uint256 orangeAllowance = orangeToken.allowance(msg.sender, address(this));
        uint256 orangeBalance = orangeToken.balanceOf(msg.sender);
        
        uint256 appleAmount = orangeAmount / exchangeRate; // Calculate the amount of Apple tokens
        
        uint256 appleBalance = appleToken.balanceOf(address(this));
        
        if (orangeAllowance >= orangeAmount && orangeBalance >= orangeAmount && appleBalance >= appleAmount) {
            return 500000; // Estimated gas limit for a successful swap
        } else {
            revert("Insufficient tokens or allowances");
        }
    }
    
    function swapTokens(uint256 orangeAmount) external {
        IERC20 appleToken = IERC20(appleTokenAddress);
        IERC20 orangeToken = IERC20(orangeTokenAddress);
        
        uint256 orangeAllowance = orangeToken.allowance(msg.sender, address(this));
        uint256 orangeBalance = orangeToken.balanceOf(msg.sender);
        
        require(orangeAllowance >= orangeAmount, "Insufficient allowance");
        require(orangeBalance >= orangeAmount, "Insufficient balance");
        
        uint256 appleAmount = orangeAmount / exchangeRate; // Calculate the amount of Apple tokens
        
        uint256 appleBalance = appleToken.balanceOf(address(this));
        
        require(appleBalance >= appleAmount, "Insufficient liquidity");
        
        // Transfer tokens
        orangeToken.transferFrom(msg.sender, address(this), orangeAmount);
        appleToken.transfer(msg.sender, appleAmount);
        
        emit TokensSwapped(msg.sender, orangeAmount, appleAmount);
    }
}