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
    uint256 private _closingTimestamp;
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
        require(_lobbyCounter == 0, "A lobby is already in progress");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _bets[_lobbyCounter][_player1] = tokenAmount - feeAmount;
        _totalPot += tokenAmount - feeAmount;
        _player1 = msg.sender;

        emit BetPlaced(msg.sender, betAmount, _lobbyCounter);
    }

    function joinLobby(uint256 lobbyId, uint256 betAmount) external gasLimit(200000) {
        require(_bets[lobbyId][_player2] == 0, "The lobby is already full");
        require(_player1 != address(0), "No lobby exists");
        require(_player1 != msg.sender, "You cannot join your own lobby");
        require(_amberToken.balanceOf(msg.sender) >= betAmount * (10**_tokenDecimals), "Insufficient AMBER token balance");
        require(betAmount >= _bets[lobbyId][_player1] && betAmount <= _bets[lobbyId][_player1] + _maxBetAmount, "Invalid bet amount");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (tokenAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _bets[lobbyId][_player2] = tokenAmount - feeAmount;
        _totalPot += tokenAmount - feeAmount;
        _player2 = msg.sender;
        _closingTimestamp = block.timestamp + 60; // Закрытие лобби через 60 секунд

        emit BetPlaced(msg.sender, betAmount, lobbyId);

        if (block.timestamp >= _closingTimestamp) {
            _distributePrize(lobbyId);
        }
    }

    function closeLobby() external gasLimit(200000) {
        require(_player2 != address(0), "No second player in the lobby");
        require(block.timestamp >= _closingTimestamp, "The lobby is still open");

        uint8 winningNumber = uint8(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))) % 2 + 1;
        address winner = (winningNumber == 1) ? _player1 : _player2;
        uint256 winningAmount = _totalPot;

        emit BetClosed(winner, winningAmount / (10**_tokenDecimals), _lobbyCounter);

        _distributePrize(_lobbyCounter);
    }

    function _distributePrize(uint256 lobbyId) internal {
        require(_player1 != address(0) && _player2 != address(0), "No players in the lobby");

        address winner = (_bets[lobbyId][_player1] > _bets[lobbyId][_player2]) ? _player1 : _player2;
        uint256 winningAmount = (_totalPot * 90) / 100;

        require(_amberToken.transfer(winner, winningAmount), "Failed to transfer AMBER tokens to the winner");
        require(_amberToken.transfer(_owner, _totalPot - winningAmount), "Failed to transfer AMBER tokens to the contract");

        emit FundsWithdrawn(winner, winningAmount / (10**_tokenDecimals));
        emit FundsWithdrawn(_owner, (_totalPot - winningAmount) / (10**_tokenDecimals));

        _clearLobby(lobbyId);
    }

    function _clearLobby(uint256 lobbyId) internal {
        delete _bets[lobbyId][_player1];
        delete _bets[lobbyId][_player2];
        _totalPot = 0;
        _lobbyCounter++;
        _closingTimestamp = 0;
        _player1 = address(0);
        _player2 = address(0);
    }

    function withdrawFunds() external onlyOwner gasLimit(50000) {
        require(_amberToken.transfer(_owner, _amberToken.balanceOf(address(this))), "Failed to withdraw AMBER tokens");
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