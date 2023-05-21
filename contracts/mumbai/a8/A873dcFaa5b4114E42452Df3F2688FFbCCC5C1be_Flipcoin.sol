/**
 *Submitted for verification at polygonscan.com on 2023-05-20
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
    mapping(uint256 => mapping(address => uint256)) private _bets; // Ячейки ставок
    uint256 private _totalPot;
    uint256 private _lobbyCounter;
    address private _player1;
    address private _player2;

    event BetPlaced(address indexed player, uint256 betAmount, uint256 lobbyId);
    event BetClosed(address indexed winner, uint256 winningAmount, uint256 lobbyId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        _owner = msg.sender;
        _amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5); // Замените на адрес AMBER токена на Mumbai сети
        _tokenDecimals = 18; // Установите правильное количество десятичных знаков для токена AMBER
    }

    function createLobby(uint256 betAmount) external gasLimit(200000) {
        require(betAmount >= _minBetAmount && betAmount <= _maxBetAmount, "Invalid bet amount");
        require(_amberToken.balanceOf(msg.sender) >= betAmount * (10**_tokenDecimals), "Insufficient AMBER token balance");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _player1 = msg.sender;
        _bets[_lobbyCounter][_player1] = tokenAmount - feeAmount;
        _totalPot += tokenAmount - feeAmount;

        emit BetPlaced(msg.sender, betAmount, _lobbyCounter);

        endGame(_lobbyCounter);
    }

    function joinLobby(uint256 lobbyId, uint256 betAmount) external gasLimit(200000) {
        require(_bets[lobbyId][_player2] == 0, "The lobby is already full");
        require(_amberToken.balanceOf(msg.sender) >= betAmount * (10**_tokenDecimals), "Insufficient AMBER token balance");
        require(betAmount >= _bets[lobbyId][_player1], "Bet amount must be greater than or equal to the initial bet");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _bets[lobbyId][_player2] = tokenAmount - feeAmount;
        _totalPot += tokenAmount - feeAmount;
        _player2 = msg.sender;

        emit BetPlaced(msg.sender, betAmount, lobbyId);

        endGame(lobbyId);
    }

    function endGame(uint256 lobbyId) internal {
        require(_player1 != address(0) && _player2 != address(0), "No players in the lobby");

        uint256 player1Bet = _bets[lobbyId][_player1];
        uint256 player2Bet = _bets[lobbyId][_player2];

        address winner = (player1Bet > player2Bet) ? _player1 : _player2;
        uint256 winningAmount = (_totalPot * 90) / 100;

        require(_amberToken.transfer(winner, winningAmount), "Failed to transfer AMBER tokens to the winner");
        _totalPot -= winningAmount;

        emit BetClosed(winner, winningAmount / (10**_tokenDecimals), lobbyId);

        _clearLobby(lobbyId);
    }

    function _clearLobby(uint256 lobbyId) internal {
        delete _bets[lobbyId][_player1];
        delete _bets[lobbyId][_player2];
        _player1 = address(0);
        _player2 = address(0);
        _lobbyCounter++;
    }

    function withdrawFunds() external onlyOwner gasLimit(50000) {
        require(_amberToken.transfer(_owner, _amberToken.balanceOf(address(this))), "Failed to withdraw AMBER tokens");
        emit FundsWithdrawn(_owner, _amberToken.balanceOf(address(this)));
    }

    function getBet(uint256 lobbyId, address player) external view returns (uint256) {
        return _bets[lobbyId][player];
    }

    function getTotalPot() external view returns (uint256) {
        return _totalPot;
    }

    function getCurrentLobby() external view returns (uint256) {
        return _lobbyCounter;
    }

    function getMinBetAmount() external view returns (uint256) {
        return _minBetAmount;
    }

    function getMaxBetAmount() external view returns (uint256) {
        return _maxBetAmount;
    }

    function getTokenDecimals() external view returns (uint8) {
        return _tokenDecimals;
    }

    function getTokenAddress() external view returns (address) {
        return address(_amberToken);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    modifier gasLimit(uint256 gasAmount) {
        require(gasleft() >= gasAmount, "Insufficient gas");
        _;
    }
}