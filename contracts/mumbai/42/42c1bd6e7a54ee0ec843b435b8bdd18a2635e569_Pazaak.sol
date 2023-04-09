/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

pragma solidity ^0.8.0;

contract Pazaak {
    
    struct Game {
        uint256 id;
        address player1;
        address player2;
        uint8[9] player1Cards;
        uint8[9] player2Cards;
        uint8 currentPlayer;
        uint8 turnNumber;
        bool gameOver;
        uint8 winner;
    }
    
    Game[] public games;
    
    event GameStarted(uint256 indexed gameId, address indexed player1, address indexed player2);
    event CardPlayed(uint256 indexed gameId, address indexed player, uint8 card);
    event TurnEnded(uint256 indexed gameId, address indexed player);
    event GameEnded(uint256 indexed gameId, address indexed winner);
    
    function startGame(address _player2, uint8[9] memory _player1Cards) public {
        Game memory newGame = Game(games.length, msg.sender, _player2, _player1Cards, [0,0,0,0,0,0,0,0,0], 1, 1, false, 0);
        games.push(newGame);
        emit GameStarted(newGame.id, msg.sender, _player2);
    }
    
    function playCard(uint256 _gameId, uint8 _card) public {
        Game storage game = games[_gameId];
        require(!game.gameOver, "The game is over.");
        require(msg.sender == game.player1 || msg.sender == game.player2, "You are not a player in this game.");
        require(msg.sender == getPlayerInTurn(game), "It is not your turn.");
        require(_card >= 1 && _card <= 10, "Invalid card value.");
        uint8[9] storage cards = getPlayerCards(game);
        uint8 cardIndex = getNextCardIndex(cards);
        cards[cardIndex] = _card;
        emit CardPlayed(_gameId, msg.sender, _card);
        if (isTurnOver(game)) {
            endTurn(_gameId);
        }
    }
    
    function endTurn(uint256 _gameId) public {
        Game storage game = games[_gameId];
        require(!game.gameOver, "The game is over.");
        require(msg.sender == getPlayerInTurn(game), "It is not your turn.");
        uint8[9] storage playerCards = getPlayerCards(game);
        uint8 playerSum = sumCards(playerCards);
        if (playerSum == 20) {
            endGame(game, getPlayerInTurn(game));
        } else if (game.turnNumber == 9) {
            endGame(game, getWinner(game));
        } else {
            game.currentPlayer = getNextPlayer(game);
            game.turnNumber += 1;
            emit TurnEnded(_gameId, msg.sender);
        }
    }
    
    function endGame(Game storage _game, address _winner) internal {
        _game.gameOver = true;
        _game.winner = _winner == _game.player1 ? 1 : 2;
        emit GameEnded(_game.id, _winner);
    }
    
    function getPlayerInTurn(Game storage _game) internal view returns (address) {
        return _game.currentPlayer == 1 ? _game.player1 : _game.player2;
    }
    
    function getNextPlayer(Game storage _game) internal view returns (uint8) {
        return _game.currentPlayer == 1 ? 2 : 1;
    }
    
    function getPlayerCards(Game storage _game) internal view returns (uint8[9] storage) {
        return _game.currentPlayer == 1 ? _game.player1Cards : _game.player2Cards;
    }
function getNextCardIndex(uint8[9] storage _cards) internal view returns (uint8) {
    for (uint8 i = 0; i < 9; i++) {
        if (_cards[i] == 0) {
            return i;
        }
    }
    revert("No more cards can be played.");
}

function isTurnOver(Game storage _game) internal view returns (bool) {
    uint8[9] storage playerCards = getPlayerCards(_game);
    uint8 playerSum = sumCards(playerCards);
    if (playerSum >= 20) {
        return true;
    } else if (_game.turnNumber == 9) {
        return true;
    } else {
        return false;
    }
}

function sumCards(uint8[9] storage _cards) internal view returns (uint8) {
    uint8 sum = 0;
    for (uint8 i = 0; i < 9; i++) {
        sum += _cards[i];
    }
    return sum;
}

function getWinner(Game storage _game) internal view returns (address) {
    uint8 player1Sum = sumCards(_game.player1Cards);
    uint8 player2Sum = sumCards(_game.player2Cards);
    if (player1Sum == player2Sum) {
        return address(0);
    } else if (player1Sum == 20) {
        return _game.player1;
    } else if (player2Sum == 20) {
        return _game.player2;
    } else if (player1Sum > 20 && player2Sum > 20) {
        return address(0);
    } else if (player1Sum > 20) {
        return _game.player2;
    } else if (player2Sum > 20) {
        return _game.player1;
    } else {
        return player1Sum > player2Sum ? _game.player1 : _game.player2;
    }
}

function getGame(uint256 _gameId) public view returns (
    address player1,
    address player2,
    uint8[9] memory player1Cards,
    uint8[9] memory player2Cards,
    uint8 currentPlayer,
    uint8 turnNumber,
    bool gameOver,
    uint8 winner
) {
    Game storage game = games[_gameId];
    player1 = game.player1;
    player2 = game.player2;
    player1Cards = game.player1Cards;
    player2Cards = game.player2Cards;
    currentPlayer = game.currentPlayer;
    turnNumber = game.turnNumber;
    gameOver = game.gameOver;
    winner = game.winner;
}
    }