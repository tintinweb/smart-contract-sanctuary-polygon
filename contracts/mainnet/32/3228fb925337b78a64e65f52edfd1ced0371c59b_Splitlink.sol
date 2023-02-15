/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Splitlink {
    function transfer(address daiToken, address recipient, uint256 amount) external {
        require(IERC20(daiToken).balanceOf(msg.sender) >= amount, "Insufficient Token balance");
        require(IERC20(daiToken).transfer(recipient, amount), "Token transfer failed");
    }
}