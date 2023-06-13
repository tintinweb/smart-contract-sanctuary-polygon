/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
}

contract AllowanceChecker {
    function getAllowances(address[] memory tokenAddresses, address account, address[] memory spenders) external view returns (uint256[][] memory) {
        uint256[][] memory allowances = new uint256[][](tokenAddresses.length);
        
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            allowances[i] = new uint256[](spenders.length);
            
            for (uint256 j = 0; j < spenders.length; j++) {
                allowances[i][j] = token.allowance(account, spenders[j]);
            }
        }
        
        return allowances;
    }
}