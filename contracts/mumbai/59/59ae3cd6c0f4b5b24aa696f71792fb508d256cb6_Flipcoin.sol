/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Flipcoin {
    address private _owner;
    uint256 private _minBetAmount = 1000; // Минимальная сумма ставки
    uint256 private _maxBetAmount = 100000; // Максимальная сумма ставки
    IERC20 private _amberToken;
    mapping(address => uint256) private _balances;

    event BetPlaced(address indexed player, uint256 betAmount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        _owner = msg.sender;
        _amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5); // Замените на адрес AMBER токена на Mumbai сети
    }

    function bet(uint256 betAmount) external gasLimit(200000) {
        require(betAmount >= _minBetAmount && betAmount <= _maxBetAmount, "Invalid bet amount");
        require(_amberToken.balanceOf(msg.sender) >= betAmount, "Insufficient AMBER token balance");

        uint256 gasFee = _calculateGasFee();
        uint256 totalAmount = betAmount + gasFee;

        require(_amberToken.transferFrom(msg.sender, address(this), totalAmount), "Failed to transfer AMBER tokens");

        // Perform flipcoin logic here
        bool isWin = _flipCoin();

        // Calculate winnings based on the result
        uint256 winnings = _calculateWinnings(betAmount, isWin);

        if (isWin) {
            require(_amberToken.transfer(msg.sender, winnings), "Failed to transfer winnings");
        } else {
            _balances[msg.sender] += betAmount;
        }

        emit BetPlaced(msg.sender, betAmount);
    }

    function depositFunds(uint256 amount) external gasLimit(100000) {
        require(amount > 0, "Amount must be greater than zero");

        require(_amberToken.transferFrom(msg.sender, address(this), amount), "Failed to transfer AMBER tokens");
        require(_amberToken.approve(address(this), amount), "Failed to approve AMBER token transfer");

        emit FundsWithdrawn(msg.sender, amount);
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[msg.sender] >= amount, "Insufficient funds");

        _balances[msg.sender] -= amount;
        require(_amberToken.transfer(msg.sender, amount), "Failed to transfer AMBER tokens");

        emit FundsWithdrawn(msg.sender, amount);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    modifier gasLimit(uint256 limit) {
        require(gasleft() >= limit, "Insufficient gas");
        _;
    }

    function _calculateWinnings(uint256 betAmount, bool isWin) private pure returns (uint256) {
        if (isWin) {
            return betAmount * 2; // Double the bet amount for winnings
        } else {
            return 0; // No winnings
        }
    }

    function _flipCoin() private view returns (bool) {
        // Perform the flipcoin logic here
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase))) % 2;
        return randomNum == 0; // Return true for heads, false for tails
    }

    function _calculateGasFee() private view returns (uint256) {
        uint256 gasPrice = tx.gasprice;
        uint256 gasUsed = gasleft();
        return gasPrice * gasUsed;
    }
}