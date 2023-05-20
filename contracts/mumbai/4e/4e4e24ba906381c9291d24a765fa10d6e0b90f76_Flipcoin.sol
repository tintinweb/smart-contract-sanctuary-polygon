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
    uint8 private _tokenDecimals; // Количество десятичных знаков токена AMBER
    IERC20 private _amberToken;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _bets;
    uint256 private _totalPot;
    address[] private _betAddresses;

    event BetPlaced(address indexed player, uint256 betAmount);
    event BetAccepted(address indexed player, uint256 betAmount);
    event BetClosed(address indexed winner, uint256 winningAmount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        _owner = msg.sender;
        _amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5); // Замените на адрес AMBER токена на Mumbai сети
        _tokenDecimals = 18; // Установите правильное количество десятичных знаков для токена AMBER
    }

    function placeBet(uint256 betAmount) external gasLimit(200000) {
        require(betAmount >= _minBetAmount && betAmount <= _maxBetAmount, "Invalid bet amount");
        require(_amberToken.balanceOf(msg.sender) >= betAmount * (10**_tokenDecimals), "Insufficient AMBER token balance");
        require(_bets[msg.sender] == 0, "You already have an active bet");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _bets[msg.sender] = tokenAmount - feeAmount;
        _totalPot += tokenAmount - feeAmount;
        _betAddresses.push(msg.sender);

        emit BetPlaced(msg.sender, betAmount);

        if (_betAddresses.length >= 2) {
            closeBet();
        }
    }

    function closeBet() private {
        address player1 = _betAddresses[0];
        address player2 = _betAddresses[1];

        uint256 player1Bet = _bets[player1];
        uint256 player2Bet = _bets[player2];

        address winner = _determineWinner(player1, player2);

        uint256 winningAmount = (player1Bet + player2Bet) * 9 / 10; // 90% of the total bet amount to the winner

        if (winner != address(0)) {
            require(_amberToken.transfer(winner, winningAmount), "Failed to transfer winning AMBER tokens");
        }

        emit BetClosed(winner, winningAmount);

        // Reset the contract state
        _totalPot = 0;
        delete _betAddresses;
        delete _bets[player1];
        delete _bets[player2];
    }

    function _determineWinner(address player1, address player2) private view returns (address) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, player1, player2)));
        uint256 randomNumber = seed % 2; // Generate a random number between 0 and 1

        if (randomNumber == 0) {
            return player1;
        } else {
            return player2;
        }
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[msg.sender] >= amount * (10**_tokenDecimals), "Insufficient funds");

        _balances[msg.sender] -= amount * (10**_tokenDecimals);
        require(_amberToken.transfer(msg.sender, amount * (10**_tokenDecimals)), "Failed to transfer AMBER tokens");

        emit FundsWithdrawn(msg.sender, amount);
    }

    function getBetInfo(address player) external view returns (uint256) {
        return _bets[player];
    }

    function getContractBalance() external view returns (uint256) {
        return _amberToken.balanceOf(address(this));
    }

    function getTotalPot() external view returns (uint256) {
        return _totalPot;
    }

    function getActiveBetsCount() external view returns (uint256) {
        return _betAddresses.length;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    modifier gasLimit(uint256 limit) {
        require(gasleft() >= limit, "Insufficient gas");
        _;
    }
}