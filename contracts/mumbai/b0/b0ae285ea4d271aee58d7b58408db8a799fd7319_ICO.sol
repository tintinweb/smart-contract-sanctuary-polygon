/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract ICO {
    address public agTokenAddress;
    address public msTokenAddress;
    uint256 public agTokenPrice;
    uint256 public tokensSold;
    address public admin;
    mapping(address => uint256) public tokenBalance;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 price);
    event OwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);

    constructor() {
        agTokenAddress = 0x61F955B8f5c305AA69e76529a1E2D65EB2AE2451;
        msTokenAddress = 0x3bf15480D5E26d1129610d01a73d5a108f7b544C;
        agTokenPrice = 2;
        admin = msg.sender;
    }

    function buyTokens(uint256 amount) external payable {
        IERC20 agToken = IERC20(agTokenAddress);
        IERC20 msToken = IERC20(msTokenAddress);
        
        uint256 agAmount = amount * agTokenPrice;
        
        require(msToken.balanceOf(msg.sender) >= amount, "Insufficient MS tokens");
        require(msToken.allowance(msg.sender, address(this)) >= amount, "Insufficient MS tokens approved for transfer");
        
        msToken.transferFrom(msg.sender, address(this), amount);
        agToken.transfer(msg.sender, agAmount);
        
        tokenBalance[msg.sender] += agAmount;
        tokensSold += agAmount;
        
        emit TokensPurchased(msg.sender, agAmount, agTokenPrice);
    }

    function withdrawFunds() external {
        require(msg.sender == admin, "Only admin can withdraw funds");
        
        IERC20 msToken = IERC20(msTokenAddress);
        uint256 balance = msToken.balanceOf(address(this));
        msToken.transfer(admin, balance);
    }

    function transferOwnership(address newAdmin) external {
        require(msg.sender == admin, "Only admin can transfer ownership");
        require(newAdmin != address(0), "Invalid address");

        admin = newAdmin;
        emit OwnershipTransferred(msg.sender, newAdmin);
    }
}