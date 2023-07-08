/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

contract TokenDistribution {
    function distribute(address[] memory recipients, uint256[] memory amounts, address token) public {
        require(recipients.length == amounts.length, "Invalid input");
        IERC20 erc20 = IERC20(token);
        for (uint256 i = 0; i < recipients.length; i++) {
            erc20.transfer(recipients[i], amounts[i]);
        }
    }
}