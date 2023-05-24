/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CoinFlip {
    string public name;
    string public symbol;

    uint256 public constant HOUSE_EDGE_PERCENT = 5;
    uint256 public constant MAX_BET_AMOUNT = 100 ether;

    event BetPlaced(address indexed player, uint256 amount, bool bet);
    event BetResolved(address indexed player, uint256 amount, bool bet, bool win);

    struct Game {
        uint256 gameId;
        address player1;
        address player2;
        uint256 betAmount;
        bool player1Bet;
        bool player2Bet;
        bool resolved;
    }



    struct GameHistory {
        uint256 gameId;
        address player;
        uint256 betAmount;
        bool playerBet;
        bool win;
    }

    mapping(address => uint256) public balances;
    Game[] public games;
    mapping(address => GameHistory[]) public gameHistory;

    constructor() {
        name = "CoinFlip Token";
        symbol = "CFT";
    }

    // Rest of your contract code...

    function createGame(bool bet) external payable {
        require(msg.value > 0, "Bet amount must be greater than 0");
        require(msg.value <= MAX_BET_AMOUNT, "Bet amount exceeds maximum limit");
        balances[msg.sender] += msg.value;
        games.push(Game(games.length, msg.sender, address(0), msg.value, bet, false, false));
        emit BetPlaced(msg.sender, msg.value, bet);
    }

 function joinGame(uint256 gameId) external payable {
    require(gameId < games.length, "Invalid game ID");
    Game storage game = games[gameId];
    require(game.player2 == address(0), "Game already has two players");
    require(msg.value >= game.betAmount, "Insufficient bet amount");
    require(game.player1 != msg.sender, "You cannot join your own game");

    balances[msg.sender] += msg.value - game.betAmount;
    game.player2 = msg.sender;
    game.player2Bet = !game.player1Bet;
    game.resolved = true;

    uint256 winningAmount = game.betAmount * 195 / 100;
    bool player1Wins = (uint256(blockhash(block.number - 1)) % 2 == 0);

    if (game.player1Bet == player1Wins) {
        balances[game.player1] += winningAmount;
        emit BetResolved(game.player1, game.betAmount, game.player1Bet, true);
        gameHistory[game.player1].push(GameHistory(gameId, game.player1, game.betAmount, game.player1Bet, true));
    } else {
        balances[game.player2] += winningAmount;
        emit BetResolved(game.player2, game.betAmount, game.player2Bet, true);
        gameHistory[game.player2].push(GameHistory(gameId, game.player2, game.betAmount, game.player2Bet, true));
    }

    // Distribute house edge to the contract
    uint256 houseEdge = game.betAmount * HOUSE_EDGE_PERCENT / 100;
    balances[address(this)] += houseEdge;
}



    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getGameCount() external view returns (uint256) {
        return games.length;
    }

  function getActiveGames() external view returns (Game[] memory) {
    uint256 activeCount = 0;
    for (uint256 i = 0; i < games.length; i++) {
        if (games[i].player2 == address(0)) {
            activeCount++;
        }
    }

    Game[] memory activeGames = new Game[](activeCount);
    uint256 index = 0;
    for (uint256 i = 0; i < games.length; i++) {
        if (games[i].player2 == address(0)) {
            activeGames[index] = games[i];
            activeGames[index].gameId = i; // Assign the gameId to the corresponding index
            index++;
        }
    }

    return activeGames;
}


    function getGameHistory(address player) external view returns (GameHistory[] memory) {
        return gameHistory[player];
    }

    function getAllGameHistory() external view returns (GameHistory[] memory) {
        uint256 totalGames = 0;
        for (uint256 i = 0; i < games.length; i++) {
            totalGames += gameHistory[games[i].player1].length;
            totalGames += gameHistory[games[i].player2].length;
        }

        GameHistory[] memory allGameHistory = new GameHistory[](totalGames);
        uint256 index = 0;
        for (uint256 i = 0; i < games.length; i++) {
            GameHistory[] memory player1History = gameHistory[games[i].player1];
            GameHistory[] memory player2History = gameHistory[games[i].player2];

            for (uint256 j = 0; j < player1History.length; j++) {
                allGameHistory[index] = player1History[j];
                index++;
            }

            for (uint256 j = 0; j < player2History.length; j++) {
                allGameHistory[index] = player2History[j];
                index++;
            }
        }

        return allGameHistory;
    }
}