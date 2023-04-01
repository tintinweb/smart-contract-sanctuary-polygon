/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSwap {
    mapping(address => uint256) public balances;

    address public owner;
    uint256 public swapFee = 5 ether;
    uint256 public minTokenId = 0;
    uint256 public maxTokenId = 10000;
    address public tokenAddress;

    event TokensSwapped(address indexed sender, uint256 amount, uint256 tokenId);

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function swapTokens(uint256 amount, uint256 tokenId) external payable {
        require(msg.value == swapFee, "Swap fee not provided");
        require(tokenId > minTokenId && tokenId < maxTokenId, "Invalid token ID");

        balances[msg.sender] += amount;

        // Emit event to notify token swap
        emit TokensSwapped(msg.sender, amount, tokenId);

        // Transfer the new token to the sender
        IERC20(tokenAddress).transferFrom(owner, msg.sender, tokenId + 1);
    }
}