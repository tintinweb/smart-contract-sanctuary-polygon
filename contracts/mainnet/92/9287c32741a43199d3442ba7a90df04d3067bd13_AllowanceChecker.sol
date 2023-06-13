/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
}

contract AllowanceChecker {
    function getAllowances(address tokenAddress, address account, address[] memory spenders) external view returns (uint256[] memory) {
        IERC20 token = IERC20(tokenAddress);
        uint256[] memory allowances = new uint256[](spenders.length);
        
        for (uint256 i = 0; i < spenders.length; i++) {
            allowances[i] = token.allowance(account, spenders[i]);
        }
        
        return allowances;
    }
}