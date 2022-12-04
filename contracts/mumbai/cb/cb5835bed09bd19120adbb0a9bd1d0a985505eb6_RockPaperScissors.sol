/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// SPDX-License-Identifier: MIT

// 2171445 -> 2043935 -> 1828247
// 1888213 -> 1777334 -> 1589780

pragma solidity 0.8.17;

/**
 * @author Siarhei Hamanovich
 * @title Rock, Paper & Scissors game
 * @dev Have fun and play Rock, Paper or Scissors game
 */
contract RockPaperScissors {
    enum State {
        IDLE,
        CREATED,
        JOINED,
        COMMITED,
        REVEALED
    }

    struct Game {
        uint256 id;
        uint256 bet;
        address payable[] players;
        State state;
    }

    struct Move {
        bytes32 hash;
        uint256 value;
    }

    mapping(uint256 => mapping(address => Move)) private moves;
    mapping(uint256 => uint256) private winningMoves;
    mapping(uint256 => Game) private games;
    uint256[] private gamesLib;
    uint256 private gameId;

    error SendFailure();
    error NotFound();
    error AlreadyMoved();
    error WrongParticipant();
    error WrongMove();
    error WrongPlayer();
    error WrongComittment();
    error WrongState(State gameState, State requiredState);

    constructor() {
        winningMoves[1] = 3;
        winningMoves[2] = 1;
        winningMoves[3] = 2;
    }

    function createGame(address payable participant) external payable {
        if (msg.value <= 0) revert SendFailure();

        if (msg.sender == participant) revert WrongParticipant();

        address payable[] memory players = new address payable[](2);
        players[0] = payable(msg.sender);
        players[1] = participant;

        games[gameId] = Game(gameId, msg.value, players, State.CREATED);
        gamesLib.push(gameId);
        gameId++;
    }

    function joinGame(uint256 _gameId) external payable {
        Game storage game = games[_gameId];

        if (msg.sender != game.players[1]) revert WrongParticipant();

        if (msg.value < game.bet) revert SendFailure();

        if (game.state != State.CREATED)
            revert WrongState(game.state, State.CREATED);

        if (msg.value > game.bet) {
            (bool sent, ) = msg.sender.call{value: msg.value - game.bet}("");
            if (!sent) revert SendFailure();
        }

        game.state = State.JOINED;
    }

    function commitMove(
        uint256 _gameId,
        uint256 moveId,
        uint256 salt
    ) external {
        Game storage game = games[_gameId];

        if (game.state != State.JOINED)
            revert WrongState(game.state, State.JOINED);

        if (msg.sender != game.players[0] || msg.sender != game.players[1])
            revert WrongPlayer();

        if (moves[_gameId][msg.sender].hash != 0) revert AlreadyMoved();

        if (moveId != 1 || moveId != 2 || moveId != 3) revert WrongMove();

        moves[_gameId][msg.sender] = Move(
            keccak256(abi.encodePacked(moveId, salt, msg.sender)),
            0
        );

        if (
            moves[_gameId][game.players[0]].hash != 0 &&
            moves[_gameId][game.players[1]].hash != 0
        ) {
            game.state = State.COMMITED;
        }
    }

    function revealMove(
        uint256 _gameId,
        uint256 moveId,
        uint256 salt
    ) external {
        Game storage game = games[_gameId];
        Move storage move1 = moves[_gameId][game.players[0]];
        Move storage move2 = moves[_gameId][game.players[1]];
        Move storage move = moves[_gameId][msg.sender];

        if (game.state != State.COMMITED)
            revert WrongState(game.state, State.COMMITED);

        if (msg.sender != game.players[0] || msg.sender != game.players[1])
            revert WrongPlayer();

        if (move.hash != keccak256(abi.encodePacked(moveId, salt, msg.sender)))
            revert WrongComittment();

        move.value = moveId;

        if (move1.value != 0 && move2.value != 0) {
            if (move1.value == move2.value) {
                (bool sent1, ) = game.players[0].call{value: game.bet}("");
                if (!sent1) revert SendFailure();

                (bool sent2, ) = game.players[1].call{value: game.bet}("");
                if (!sent2) revert SendFailure();

                game.state = State.REVEALED;

                return;
            }

            address payable winner = winningMoves[move1.value] == move2.value
                ? game.players[0]
                : game.players[1];

            (bool sentWinner, ) = winner.call{value: 2 * game.bet}("");
            if (!sentWinner) revert SendFailure();

            game.state = State.REVEALED;
        }
    }

    function getGame(uint256 _gameId)
        external
        view
        returns (
            uint256,
            uint256,
            address[] memory,
            State
        )
    {
        for (uint256 i; i < gamesLib.length; i++) {
            if (gamesLib[i] == _gameId) {
                Game storage game = games[_gameId];
                address[] memory players = new address[](2);
                players[0] = game.players[0];
                players[1] = game.players[1];

                return (game.id, game.bet, players, game.state);
            }
        }

        revert NotFound();
    }
}