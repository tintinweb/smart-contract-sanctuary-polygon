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
    using SafeMath for uint256;

    address private _owner;
    uint256 private _minBetAmount = 1000; // Минимальная сумма ставки
    uint256 private _maxBetAmount = 100000; // Максимальная сумма ставки
    uint8 private _tokenDecimals; // Количество десятичных знаков токена AMBER
    IERC20 private _amberToken;
    mapping(uint256 => mapping(address => uint256)) private _bets; // Ячейки ставок
    uint256 private _totalPot;
    uint256 private _lobbyCounter;
    mapping(uint256 => MiniLobby) private _miniLobbies;

    event BetPlaced(address indexed player, uint256 betAmount, uint256 lobbyId);
    event BetClosed(address indexed winner, uint256 winningAmount, uint256 lobbyId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    struct MiniLobby {
        address creator;
        mapping(address => uint256) bets;
        uint256 totalPot;
        bool isClosed;
    }

    constructor() {
        _owner = msg.sender;
        _amberToken = IERC20(0xf32d5D5FA5d2545071570c0EEf6E2C65A4c7e5c5); // Замените на адрес AMBER токена на Mumbai сети
        _tokenDecimals = 18; // Установите правильное количество десятичных знаков для токена AMBER
    }

    function createEmptyLobby() external gasLimit(50000) {
        require(_miniLobbies[_lobbyCounter].creator == address(0), "Lobby already exists");
        _miniLobbies[_lobbyCounter].creator = msg.sender;
        emit BetPlaced(msg.sender, 0, _lobbyCounter);
        _lobbyCounter++;
    }

    function placeBet(uint256 lobbyId, uint256 betAmount) external gasLimit(200000) {
    require(lobbyId < _lobbyCounter, "Invalid lobby ID");
    require(!_miniLobbies[lobbyId].isClosed, "Lobby is closed");
    require(betAmount >= _minBetAmount && betAmount <= _maxBetAmount, "Invalid bet amount");

    uint256 tokenAmount = betAmount * (10**_tokenDecimals);
    uint256 feeAmount = (betAmount * 10) / 100; // 10% fee

    require(_amberToken.balanceOf(msg.sender) >= tokenAmount, "Insufficient AMBER token balance");

    MiniLobby storage miniLobby = _miniLobbies[lobbyId];
    require(miniLobby.bets[msg.sender] == 0, "Already placed a bet");

    require(_amberToken.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer AMBER tokens");

    miniLobby.bets[msg.sender] = tokenAmount - feeAmount;
    miniLobby.totalPot = miniLobby.totalPot.add(tokenAmount - feeAmount);

    emit BetPlaced(msg.sender, betAmount, lobbyId);

    checkLobbyClosure(lobbyId);
}


    function closeLobby(uint256 lobbyId) external gasLimit(50000) {
        require(lobbyId < _lobbyCounter, "Invalid lobby ID");
        require(_miniLobbies[lobbyId].creator == msg.sender, "Only lobby creator can close it");
        require(!_miniLobbies[lobbyId].isClosed, "Lobby is already closed");

        MiniLobby storage miniLobby = _miniLobbies[lobbyId];
        require(miniLobby.bets[msg.sender] != 0, "No bets placed in this lobby");

        miniLobby.isClosed = true;

        emit BetClosed(msg.sender, 0, lobbyId);

        distributeWinnings(lobbyId);
    }

    function distributeWinnings(uint256 lobbyId) internal {
        MiniLobby storage miniLobby = _miniLobbies[lobbyId];
        require(miniLobby.isClosed, "Lobby is not closed yet");

        uint256 totalBets = miniLobby.totalPot;
        uint256 winningAmount = (totalBets * 80) / 100;
        address winner = address(0);

        for (uint256 i = 0; i < _lobbyCounter; i++) {
            address player = _miniLobbies[i].creator;
            if (_miniLobbies[i].isClosed && player != address(0) && miniLobby.bets[player] > miniLobby.bets[winner]) {
                winner = player;
            }
        }

        require(winner != address(0), "No winner found");

        require(_amberToken.transfer(winner, winningAmount), "Failed to transfer AMBER tokens to the winner");

        _totalPot = _totalPot.sub(winningAmount);

        emit BetClosed(winner, winningAmount / (10**_tokenDecimals), lobbyId);

        delete _miniLobbies[lobbyId];
    }

    function checkLobbyClosure(uint256 lobbyId) internal {
        MiniLobby storage miniLobby = _miniLobbies[lobbyId];
        if (miniLobby.isClosed) {
            distributeWinnings(lobbyId);
        } else {
            address creator = miniLobby.creator;
            if (creator != address(0) && miniLobby.bets[creator] != 0) {
                miniLobby.isClosed = true;
                emit BetClosed(creator, 0, lobbyId);
                distributeWinnings(lobbyId);
            }
        }
    }

    function withdrawFunds() external onlyOwner gasLimit(50000) {
        require(_amberToken.transfer(_owner, _amberToken.balanceOf(address(this))), "Failed to withdraw AMBER tokens");
        emit FundsWithdrawn(_owner, _amberToken.balanceOf(address(this)));
    }

    function getLobbyCount() external view returns (uint256) {
        return _lobbyCounter;
    }

    function getLobbyBet(uint256 lobbyId, address player) external view returns (uint256) {
        return _miniLobbies[lobbyId].bets[player];
    }

    function getMinBetAmount() external view returns (uint256) {
        return _minBetAmount;
    }

    function getMaxBetAmount() external view returns (uint256) {
        return _maxBetAmount;
    }

    function getContractOwner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    modifier gasLimit(uint256 gasAmount) {
        require(gasleft() >= gasAmount, "Not enough gas left to execute");
        _;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}