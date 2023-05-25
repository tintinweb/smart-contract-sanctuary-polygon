/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract EscrowContract {
    address public buyer;
    address public seller;
    address public thirdParty;
    uint256 public feePercentage;
    uint256 public totalAmount;
    address public tokenAddress;
    bool public released;
    
    modifier onlyBuyerOrSeller() {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can call this function");
        _;
    }
    
    modifier onlyThirdParty() {
        require(msg.sender == thirdParty, "Only the third party can call this function");
        _;
    }
    
    constructor(address _buyer, address _seller, address _thirdParty, uint256 _feePercentage, uint256 _amount, address _tokenAddress) {
        buyer = _buyer;
        seller = _seller;
        thirdParty = _thirdParty;
        feePercentage = _feePercentage;
        totalAmount = _amount;
        tokenAddress = _tokenAddress;
        released = false;
    }
    
    function deposit(uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= amount, "Insufficient funds");
        token.transferFrom(msg.sender, address(this), amount);
        totalAmount += amount;
    }
    
    function approveEscrow(uint256 amount) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= amount, "Insufficient funds");
        require(token.approve(address(this), amount), "Approval failed");
    }
    
    function releaseToBuyer() external onlyThirdParty {
        require(released == false, "Funds already released");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 feeAmount = (totalAmount * feePercentage) / 100;
        uint256 releaseAmount = totalAmount - feeAmount;
        
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient funds in escrow contract");
        
        token.transfer(buyer, releaseAmount);
        token.transfer(thirdParty, feeAmount);
        
        released = true;
    }
    
    function releaseToSeller() external onlyThirdParty {
        require(released == false, "Funds already released");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 feeAmount = (totalAmount * feePercentage) / 100;
        uint256 releaseAmount = totalAmount - feeAmount;
        
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient funds in escrow contract");
        
        token.transfer(seller, releaseAmount);
        token.transfer(thirdParty, feeAmount);
        
        released = true;
    }
    
    function claimBuyerTokens() external onlyBuyerOrSeller {
        require(released == true, "Funds not yet released");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 buyerAmount = token.balanceOf(address(this));
        
        require(buyerAmount > 0, "No tokens to claim");
        
        token.transfer(buyer, buyerAmount);
    }
    
    function claimSellerTokens() external onlyBuyerOrSeller {
        require(released == true, "Funds not yet released");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 sellerAmount = token.balanceOf(address(this));
        
        require(sellerAmount > 0, "No tokens to claim");
        
        token.transfer(seller, sellerAmount);
    }
}