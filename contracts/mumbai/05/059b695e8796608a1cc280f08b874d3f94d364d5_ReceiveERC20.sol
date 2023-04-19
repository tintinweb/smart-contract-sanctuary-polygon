/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract ReceiveERC20 {
    mapping(address => bool) public supportedTokens;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function addSupportedToken(address _tokenAddress) external {
        require(msg.sender == owner, "Only owner can add supported tokens");
        IERC20 token = IERC20(_tokenAddress);
        supportedTokens[_tokenAddress] = true;
        require(token.approve(address(this), token.balanceOf(address(this))), "Approval failed");
    }
    
    function receiveTokens(address _tokenAddress, uint256 _amount) external {
        require(supportedTokens[_tokenAddress], "Unsupported token");
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), "Transfer failed");
    }
    
    function withdrawTokens(address _tokenAddress) external {
        require(msg.sender == owner, "Only owner can withdraw tokens");
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner, token.balanceOf(address(this))), "Transfer failed");
    }
    
    function getBalance(address _tokenAddress) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }
}