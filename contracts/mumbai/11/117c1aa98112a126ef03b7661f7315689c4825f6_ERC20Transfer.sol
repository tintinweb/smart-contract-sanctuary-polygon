/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract ERC20Transfer {
    IERC20 public token;
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function transfer(address _recipient, uint256 _amount) external {
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(token.approve(address(this), _amount), "Approval failed");
        require(token.transferFrom(msg.sender, _recipient, _amount), "Transfer failed");
    }
}