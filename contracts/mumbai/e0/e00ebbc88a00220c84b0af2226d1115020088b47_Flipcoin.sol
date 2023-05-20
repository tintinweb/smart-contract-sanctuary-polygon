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
    }

    function acceptBet() external gasLimit(200000) {
        require(_bets[msg.sender] == 0, "You already have an active bet");

        address[] memory players = _getPlayers();
        require(players.length == 2, "Not enough players for the bet");

        address opponent;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] != msg.sender) {
                opponent = players[i];
                break;
            }
        }
        require(opponent != address(0), "Opponent not found");

        uint256 opponentBet = _bets[opponent];
        require(opponentBet > 0, "Opponent has no active bet");

        uint256 betAmount = opponentBet / (10**_tokenDecimals);
        uint256 tokenAmount = opponentBet + _bets[msg.sender];

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _bets[msg.sender] = tokenAmount;
        _totalPot += tokenAmount;
        delete _bets[opponent];

        emit BetAccepted(msg.sender, betAmount);
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[msg.sender] >= amount * (10**_tokenDecimals), "Insufficient funds");

        _balances[msg.sender] -= amount * (10**_tokenDecimals);
        require(_amberToken.transfer(msg.sender, amount * (10**_tokenDecimals)), "Failed to transfer AMBER tokens");

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

    function _getPlayers() private view returns (address[] memory) {
        address[] memory players = new address[](2);
        uint256 count;
        for (uint256 i = 0; i < _betAddresses.length; i++) {
            if (_bets[_betAddresses[i]] > 0) {
                players[count] = _betAddresses[i];
                count++;
                if (count >= 2) {
                    break;
                }
            }
        }
        return players;
    }
}