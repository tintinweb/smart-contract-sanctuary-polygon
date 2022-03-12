/**
 *Submitted for verification at polygonscan.com on 2022-03-11
*/

pragma solidity >=0.7.3;

contract TicTacToe
{
    struct Game {
	address player1;
	address player2;
	address[9] board;
	address next;
	address winner;
	bool full;
    }

    uint index;
    mapping (address => uint) players;
    mapping (uint => Game) games;

    constructor() {
	index = 1;
    }

    function isEmpty(Game memory g) private returns (bool) {
	return g.player1 == address(0);
    }

    function emptyGame() public returns (Game memory) {
	return Game(address(0),
		    address(0),
		    [address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0), address(0)],
		    address(0),
		    address(0),
		    false);
    }

    function createGame(address player) private returns (Game memory) {
	Game memory result = emptyGame();
	result.player1 = result.next = player;
	return result;
    }

    function getGame(address a) public view returns (Game memory) {
	return games[players[a]];
    }

    function join(address a) public {
	if (players[a] == 0 || isFull(games[players[a]]) || getWinner(games[players[a]]) != address(0)) {
	    if (games[index].player1 == address(0)) {
		games[index].player1 = games[index].next = a;
		players[a] = index;
	    }
	    else if (games[index].player2 == address(0)) {
		games[index].player2 = a;
		if (games[index].next == address(0)) games[index].next = a;
		players[a] = index;
	    }
	    else {
		++index;
		games[index] = createGame(a);
		players[a] = index;
	    }
	}
    }

    function play(address a, uint8 i) public {
	Game memory game = games[players[a]];
	if (isEmpty(games[players[a]])) revert("player not in game");
	if (games[players[a]].next != a) revert("not your turn to play");
	if (games[players[a]].board[i] != address(0)) revert("you need to select an empty slot");
	if (a == games[players[a]].player1) games[players[a]].next = games[players[a]].player2;
	else games[players[a]].next = games[players[a]].player1;
	games[players[a]].board[i] = a;
	games[players[a]].winner = getWinner(games[players[a]]);
	games[players[a]].full = isFull(games[players[a]]);
    }

    function getWinner(Game memory game) private returns (address) {
	if (game.board[0] == game.board[1] && game.board[0] == game.board[2]) return game.board[0];
	if (game.board[3] == game.board[4] && game.board[3] == game.board[5]) return game.board[3];
	if (game.board[6] == game.board[7] && game.board[6] == game.board[8]) return game.board[6];

	if (game.board[0] == game.board[3] && game.board[0] == game.board[6]) return game.board[0];
	if (game.board[1] == game.board[4] && game.board[1] == game.board[7]) return game.board[1];
	if (game.board[2] == game.board[5] && game.board[2] == game.board[8]) return game.board[2];

	if (game.board[0] == game.board[4] && game.board[0] == game.board[8]) return game.board[0];
	if (game.board[2] == game.board[4] && game.board[2] == game.board[6]) return game.board[2];

	return address(0);
    }

    function isFull(Game memory game) private returns (bool) {
	for (uint i = 0; i < 9; ++i) {
	    if (game.board[i] == address(0)) {
		return false;
	    }
	}
	return true;
    }
}