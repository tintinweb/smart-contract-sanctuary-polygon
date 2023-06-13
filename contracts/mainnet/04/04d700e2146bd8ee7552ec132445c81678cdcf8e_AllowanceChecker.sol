/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract AllowanceChecker {
    struct TokenData {
        address tokenAddress;
        string symbol;
        uint8 decimals;
    }

    function getAllowances(address[] memory tokenAddresses, address account, address[] memory spenders) external view returns (TokenData[] memory, uint256[][] memory) {
        TokenData[] memory tokens = new TokenData[](tokenAddresses.length);
        uint256[][] memory allowances = new uint256[][](tokenAddresses.length);
        
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            tokens[i] = TokenData(tokenAddresses[i], token.symbol(), token.decimals());
            allowances[i] = new uint256[](spenders.length);
            
            for (uint256 j = 0; j < spenders.length; j++) {
                allowances[i][j] = token.allowance(account, spenders[j]);
            }
        }
        
        return (tokens, allowances);
    }
}