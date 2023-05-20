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
mapping(uint256 => mapping(address => uint256)) private _lobbies;
mapping(address => uint256) private _betLobbies;
uint256 private _lobbyCounter;

    event BetPlaced(address indexed player, uint256 betAmount, uint256 lobbyId);
event BetAccepted(address indexed player, uint256 betAmount, uint256 lobbyId);
event BetClosed(address indexed winner, uint256 winningAmount, uint256 lobbyId);
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

    uint256 lobbyId = _lobbyCounter;
    _lobbies[lobbyId][msg.sender] = tokenAmount - feeAmount;
    _betLobbies[msg.sender] = lobbyId;
    _lobbyCounter++;

    emit BetPlaced(msg.sender, betAmount, lobbyId);
}

function acceptBet(uint256 lobbyId) external gasLimit(200000) {
    require(_bets[msg.sender] == 0, "You already have an active bet");

    address[] memory players = _getPlayers(lobbyId);
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
    delete _betLobbies[opponent];
    _removeAddress(opponent, lobbyId);

    emit BetAccepted(msg.sender, betAmount, lobbyId);
}

function closeBet(uint256 lobbyId) external onlyOwner {
    require(_betAddresses.length >= 2, "Not enough bets to close");

    address[] memory players = _getPlayers(lobbyId);
    require(players.length == 2, "Not enough players for the bet");

    uint256 winnerIndex = _generateRandomNumber(lobbyId) % 2;
    address winner = players[winnerIndex];
    address loser = players[1 - winnerIndex];

    uint256 winningAmount = (_totalPot * 9) / 10; // 90% of the total pot

    _balances[winner] += winningAmount;
    emit BetClosed(winner, winningAmount, lobbyId);

    _totalPot = 0;
    delete _bets[winner];
    delete _bets[loser];
    _removeAddress(winner, lobbyId);
    _removeAddress(loser, lobbyId);
}

function withdrawFunds(uint256 amount) external {
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

function _getPlayers(uint256 lobbyId) private view returns (address[] memory) {
    address[] memory players = new address[](2);
    uint256 count;
    for (uint256 i = 0; i < _betAddresses.length; i++) {
        if (_lobbies[lobbyId][_betAddresses[i]] > 0) {
            players[count] = _betAddresses[i];
            count++;
            if (count >= 2) {
                break;
            }
        }
    }
    return players;
}

function _removeAddress(address addr, uint256 lobbyId) private {
    for (uint256 i = 0; i < _betAddresses.length; i++) {
        if (_betAddresses[i] == addr) {
            delete _betAddresses[i];
            break;
        }
    }
    delete _lobbies[lobbyId][addr];
}

function _generateRandomNumber(uint256 seed) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed)));
}

}