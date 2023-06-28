/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
contract MinerPlusGift {
    address public owner;
    ERC20 public tokenContract;
    event TokensSent(address indexed sender, address[] recipients, uint256 amount);
    constructor(address _tokenContract) {
        owner = msg.sender;
        tokenContract = ERC20(_tokenContract);
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }
    function sendTokens(address[] memory recipients, uint256 amount) external onlyOwner {
        require(recipients.length > 0, "No recipients specified");
        require(amount > 0, "Amount must be greater than zero");
        ERC20 token = tokenContract;
        uint256 totalAmount = amount * recipients.length;
        uint256 balance = token.balanceOf(address(this));
        require(balance >= totalAmount, "Insufficient contract balance");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amount), "Token transfer failed");
        }
        emit TokensSent(msg.sender, recipients, amount);
    }
    function withdrawTokens(address recipient, uint256 amount) external onlyOwner {
        ERC20 token = tokenContract;
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Insufficient contract balance");
        require(token.transfer(recipient, amount), "Token transfer failed");
    }
    function withdrawETH(address payable recipient, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        recipient.transfer(amount);
    }
    function contractBalance() external view returns (uint256) {
        ERC20 token = tokenContract;
        return token.balanceOf(address(this));
    }
}