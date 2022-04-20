/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

pragma solidity >=0.8.0 <0.9.0;

contract Battleship {
    uint gamesCount = 1;
    uint firstAvailableGameID = 1;

    struct Game {
        bytes32 board0;
        bytes32 board1;
        address player0;
        address player1;
        uint turn;
    }

    event GameJoined (
        address awaitingPlayer
    );

    event GameOver (
        address victorious,
        address defeated
    );

    mapping(uint => Game) gameIDtoGame;
    mapping(address => uint) playerToGameID;
    
    function _createGame(bytes32 board) internal
    {
        gameIDtoGame[gamesCount] = Game(board, bytes32(0), msg.sender, address(0), 0);
        playerToGameID[msg.sender] = gamesCount;
        gamesCount++;
    }

    function joinGame(bytes32 board)
        public
    {
        if (gamesCount == firstAvailableGameID) {
            _createGame(board);
        }
        else {
            address player0 = gameIDtoGame[firstAvailableGameID].player0;
            require(player0 != msg.sender, "No playing with yourself!");

            gameIDtoGame[firstAvailableGameID].player1 = msg.sender;
            gameIDtoGame[firstAvailableGameID].board1 = board;
            playerToGameID[msg.sender] = firstAvailableGameID;
            firstAvailableGameID++;
            emit GameJoined(player0);
        }
    }

    function endGame()
        public
    {
        Game memory deletedGame = gameIDtoGame[playerToGameID[msg.sender]];
        delete playerToGameID[deletedGame.player0];
        delete playerToGameID[deletedGame.player1];
        delete gameIDtoGame[playerToGameID[msg.sender]];
        if (deletedGame.player1 == address(0)) firstAvailableGameID++;
    }

    function attackCell(uint16 row, uint16 col)
        public
        RequiresGame()
        RequiresOpponent()
        OnlyOnPlayersTurn()
    {
        uint gameID = playerToGameID[msg.sender];
        Game memory game = gameIDtoGame[gameID];
        bytes32 board = game.turn == 0 ? game.board1 : game.board0;
        uint bitIndex = (16 * row) + col;
        if ((board & bytes32(uint(1 << bitIndex))) > 0) board = board ^ bytes32(uint(1 << bitIndex));
        if (board > 0) {
            if (game.turn == 1) game.board0 = board;
            if (game.turn == 0) game.board1 = board;
            game.turn = game.turn ^ 1;
            gameIDtoGame[gameID] = game;
        } else {
            endGame();
            emit GameOver(msg.sender, game.turn == 0 ? game.player1 : game.player0);
        }
    }

    function printMyBoard() public view returns(string memory) {

    }

    function myGame() public view returns (Game memory) {
        return gameIDtoGame[playerToGameID[msg.sender]];
    }

    modifier OnlyOnPlayersTurn() {
        uint gameID = playerToGameID[msg.sender];
        Game memory game = gameIDtoGame[gameID];
        bool player0sTurnPlayer0isSender = msg.sender == game.player0 && game.turn == 0;
        bool player1sTurnPlayer1isSender = msg.sender == game.player1 && game.turn == 1;
        require(player0sTurnPlayer0isSender || player1sTurnPlayer1isSender, "It's not your turn.");
        _;
    }

    modifier RequiresOpponent() {
        uint gameID = playerToGameID[msg.sender];
        Game memory game = gameIDtoGame[gameID];
        require(game.player0 != address(0) && game.player1 != address(0), "You need an opponent.");
        _;
    }
    
    modifier RequiresGame() {
        uint gameID = playerToGameID[msg.sender];
        require(gameID > 0, "You need a game.");
        _;
    }
}