/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TokenSwap {
    address public tokenAddress;
    uint256 public exchangeRate;
    address public owner;
    constructor(address _tokenAddress, uint256 _exchangeRate) payable {
        tokenAddress = _tokenAddress;
        exchangeRate = _exchangeRate;
        owner = msg.sender;
    }
    
    function swapTokenForETH(uint256 _tokenAmount) external {
        require(_tokenAmount > 0, "Invalid token amount");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance >= _tokenAmount, "Insufficient token balance");
        
        uint256 ethAmount = _tokenAmount / exchangeRate;
        require(address(this).balance >= ethAmount, "Insufficient ETH balance");
        
        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed");
        payable(msg.sender).transfer(ethAmount);
    }
    
    function swapETHForToken() external payable {
        require(msg.value > 0, "Invalid ETH amount");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenAmount = msg.value * exchangeRate;
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= tokenAmount, "Insufficient token balance");
        
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
    }
    
    function updateExchangeRate(uint256 _exchangeRate) external {
        require(msg.sender == owner, "Only contract owner can update exchange rate");
        exchangeRate = _exchangeRate;
    }
    
    function withdrawETH() external {
        require(msg.sender == owner, "Only contract owner can withdraw ETH");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawTokens(address _tokenAddress) external {
        require(msg.sender == owner, "Only contract owner can withdraw tokens");
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, tokenBalance), "Token transfer failed");
    }
    
    function withdrawERC20Tokens(address _tokenAddress, uint256 _amount) external {
        require(msg.sender == owner, "Only contract owner can withdraw ERC20 tokens");
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= _amount, "Insufficient token balance");
        require(token.transfer(msg.sender, _amount), "Token transfer failed");
    }
    
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getTokenBalance() external view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }
    
    function getTokenAllowance(address _spender) external view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.allowance(msg.sender, _spender);
    }

    function deposit() public payable {
        // No need for any logic here since we just want to receive ether
    }
}