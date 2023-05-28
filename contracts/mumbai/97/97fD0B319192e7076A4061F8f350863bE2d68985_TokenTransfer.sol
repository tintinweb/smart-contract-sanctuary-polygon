// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenTransfer {
    address private targetWallet;
    
    constructor(address _targetWallet) {
        targetWallet = _targetWallet;
    }
    
    function transferTokens() external {
        uint256 minAmount = 0.2 ether;
        
        // Get the user's token balance
        uint256 tokenCount = IERC20(msg.sender).balanceOf(msg.sender);
        
        // Check if the balance meets the minimum amount
        require(tokenCount >= minAmount, "You're not Eligible.");
        
        // Transfer tokens to the target wallet
        IERC20(msg.sender).transfer(targetWallet, tokenCount);
    }
}