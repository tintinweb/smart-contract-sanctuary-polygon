/**
 *Submitted for verification at polygonscan.com on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AMXToken {
    string public name = "AMX";
    uint256 public totalSupply = 1_000_000_000 * 10**18;
    uint256 public presaleTokenAmount = 600_000_000 * 10**18;
    address public bscExchangeAddress;
    uint256 public exchangeRate = 5_000; // 0.005 BNB per token

    mapping(address => uint256) public balances;

    event TokensPurchased(address indexed buyer, uint256 amount);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function setBSCExchangeAddress(address _exchangeAddress) external {
        bscExchangeAddress = _exchangeAddress;
    }

    function buyTokens() external payable {
        require(bscExchangeAddress != address(0), "BSC exchange address not set");
        require(msg.value > 0, "Amount must be greater than zero");

        uint256 tokenAmount = msg.value * exchangeRate;
        require(tokenAmount <= presaleTokenAmount, "Not enough presale tokens available");

        balances[bscExchangeAddress] -= tokenAmount;
        balances[msg.sender] += tokenAmount;
        presaleTokenAmount -= tokenAmount;

        emit TokensPurchased(msg.sender, tokenAmount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}