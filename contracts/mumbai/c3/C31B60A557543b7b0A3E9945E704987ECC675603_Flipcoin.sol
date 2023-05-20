/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    mapping(uint256 => mapping(address => uint256)) private _lobbies;
    mapping(address => uint256) private _betLobbies;
    uint256 private _lobbyCounter;

    event BetPlaced(address indexed player, uint256 betAmount, uint256 lobbyId);
    event BetAccepted(address indexed player, uint256 betAmount, uint256 lobbyId);
    event BetClosed(address indexed winner, uint256 winningAmount, uint256 lobbyId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        _owner = msg.sender;
        _amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5); // Адрес AMBER токена на сети Mumbai Polygon
        _tokenDecimals = 18; // Установите правильное количество десятичных знаков для токена AMBER
    }

    function placeBet(uint256 betAmount) external {
        require(block.timestamp % 2 == 0, "Bets can only be placed on even block timestamps"); // Проверка времени в блоках
        require(betAmount >= _minBetAmount && betAmount <= _maxBetAmount, "Invalid bet amount");
        require(_amberToken.balanceOf(msg.sender) >= betAmount * (10**_tokenDecimals), "Insufficient AMBER token balance");
        require(_bets[msg.sender] == 0, "You already have an active bet");

        uint256 tokenAmount = betAmount * (10**_tokenDecimals);
        uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

        require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

        _bets[msg.sender] = tokenAmount - feeAmount;
        _totalPot += tokenAmount - feeAmount;
        _betAddresses.push(msg.sender);

        uint256 lobbyId = _lobbyCounter;
        _lobbies[lobbyId][msg.sender] = tokenAmount - feeAmount;
        _betLobbies[msg.sender] = lobbyId;

        emit BetPlaced(msg.sender, tokenAmount - feeAmount, lobbyId);

        _lobbyCounter++;
    }

    function acceptBet(address player) external {
        require(msg.sender == _owner, "Only the contract owner can accept bets");
        require(_bets[player] > 0, "Player does not have an active bet");

        uint256 betAmount = _bets[player];
        _totalPot -= betAmount;

        emit BetAccepted(player, betAmount, _betLobbies[player]);
    }

    function closeBet() external {
        require(block.timestamp % 2 != 0, "Bets can only be closed on odd block timestamps"); // Проверка времени в блоках
        require(_bets[msg.sender] > 0, "You do not have an active bet");

        uint256 lobbyId = _betLobbies[msg.sender];
        address[] storage lobby = _betAddresses;

        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, lobbyId))) % lobby.length;
        address winner = lobby[winnerIndex];
        uint256 winningAmount = _totalPot;

        require(_amberToken.transfer(winner, winningAmount), "Failed to transfer winning amount to the winner");

        // Reset lobby and player bets
        for (uint256 i = 0; i < lobby.length; i++) {
            delete _lobbies[lobbyId][lobby[i]];
        }
        delete _betAddresses;
        delete _betLobbies[msg.sender];

        emit BetClosed(winner, winningAmount, lobbyId);
    }

    function withdrawFunds() external {
        require(msg.sender == _owner, "Only the contract owner can withdraw funds");

        uint256 balance = _amberToken.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");

        require(_amberToken.transfer(_owner, balance), "Failed to transfer funds to the contract owner");

        emit FundsWithdrawn(_owner, balance);
    }

    function getBetAmount(address player) external view returns (uint256) {
        return _bets[player];
    }

    function getTotalPot() external view returns (uint256) {
        return _totalPot;
    }

    function getLobbyId(address player) external view returns (uint256) {
        return _betLobbies[player];
    }
}