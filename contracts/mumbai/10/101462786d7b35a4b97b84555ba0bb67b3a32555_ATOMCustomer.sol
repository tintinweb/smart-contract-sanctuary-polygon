/**
 *Submitted for verification at polygonscan.com on 2023-04-29
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
}

contract ATOMCustomer {

    event TransferToken(address indexed from, address indexed to, address indexed token, uint256 amount,string orderId);

    event WithdrawToken(address indexed from, address indexed to, address indexed token, uint256 amount);

    function transferToken(address token, uint256 amount,string memory orderId) public returns (bool) {
        require(token != address(0), "transfer token is the zero address");
        IERC20 erc20 = IERC20(token); 
        bool success = erc20.transferFrom(msg.sender, address(this), amount);
        require(success, "transfer token failed");
        emit TransferToken(msg.sender, address(this), token, amount,orderId); 
        return true;
    }

    function withdrawToken(address to, address token, uint256 amount) public returns (bool) {
        require(to != address(0), "withdraw to the zero address");
        require(token != address(0), "withdraw token is the zero address");
        IERC20 erc20 = IERC20(token); 
        bool success = erc20.transfer(to, amount); 
        require(success, "withdraw token failed");
        emit WithdrawToken(address(this), to, token, amount);
        return true;
    }
}