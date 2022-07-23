/**
 *Submitted for verification at polygonscan.com on 2022-07-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/*
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣶⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⠿⠟⠛⠻⣿⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣆⣀⣀⠀⣿⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠻⣿⣿⣿⠅⠛⠋⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢼⣿⣿⣿⣃⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣟⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣛⣛⣫⡄⠀⢸⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⡆⠸⣿⣿⣿⡷⠂⠨⣿⣿⣿⣿⣶⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣾⣿⣿⣿⣿⡇⢀⣿⡿⠋⠁⢀⡶⠪⣉⢸⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⣿⣿⣿⡏⢸⣿⣷⣿⣿⣷⣦⡙⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣇⢸⣿⣿⣿⣿⣿⣷⣦⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀
 * ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣵⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 *
 *                  Lucemans.eth
 *     Seems like you are curious, lets talk!
 */

contract TicTacSo {
    struct GameData {
        address from;
        address to;
        uint8[][] board;
        uint8 size;
        address fromTurn;
        uint8 gameOver;
    }

    // Invite System
    mapping(address => address[]) public invites;
    mapping(address => address[]) public invited;

    uint256 public lastId = 0;
    mapping(uint256 => GameData) public gameData;

    function _contains(address[] memory list, address entry)
        private
        pure
        returns (uint8 index)
    {
        for (uint8 i = 0; i < list.length; i++) {
            if (list[i] == entry) return i;
        }
        require(false, "NO_INVITE");
    }

    function getBoard(uint256 gameId) public view returns (uint8[][] memory) {
        return gameData[gameId].board;
    }

    function getInvites(address to) public view returns (address[] memory) {
        return invites[to];
    }

    function getInvited(address to) public view returns (address[] memory) {
        return invited[to];
    }

    function invite(address to) public {
        for (uint8 i = 0; i < invites[to].length; i++) {
            if (invited[to][i] == msg.sender) {
                revert("ALREADY_INVITE");
            }
        }

        invites[to].push(msg.sender);
        invited[msg.sender].push(to);
    }

    function startGame(address to, uint8 size) public returns (uint256) {
        // require user was invited to begin with
        uint8 index = _contains(invites[msg.sender], to);
        uint8 index2 = _contains(invited[to], msg.sender);

        // remove the invite from invites & invited
        delete invites[msg.sender][index];
        delete invited[to][index2];

        // TODO: delete invite
        lastId++;
        uint8[][] memory gameGrid = new uint8[][](size);

        for (uint8 i = 0; i < size; i++) {
            gameGrid[i] = new uint8[](size);
        }

        gameData[lastId] = GameData(
            to,
            msg.sender,
            gameGrid,
            size,
            msg.sender,
            0
        );

        return lastId;
    }

    function checkWinIn3x(
        uint256 gameId,
        uint8 x,
        uint8 y
    ) private returns (uint8) {
        GameData memory game = gameData[gameId];
        uint8 ry = game.board[y][x];

        // store info in vars
        bool tl = game.board[0][0] == ry;
        bool tr = game.board[0][0] == ry;
        bool centr = game.board[1][1] == ry;
        bool bl = game.board[2][0] == ry;
        bool br = game.board[2][2] == ry;

        // Check row
        if (
            (((x == 0 && game.board[y][1] == ry) ||
                (x == 1 && game.board[y][0] == ry)) &&
                game.board[y][2] == ry) ||
            (x == 2 && game.board[y][0] == ry && game.board[y][1] == ry)
        ) {
            return ry;
        }
        // Check Column
        if (
            (((y == 0 && game.board[1][x] == ry) ||
                (y == 1 && game.board[0][x] == ry)) &&
                game.board[2][x] == ry) ||
            (y == 2 && game.board[0][x] == ry && game.board[1][x] == ry)
        ) {
            return ry;
        }

        if ((tl && centr && br) || (tr && centr && bl)) {
            return ry;
        }

        // check if there are empty spaces
        for (uint8 sy = 0; sy < game.size; sy++) {
            for (uint8 sx = 0; sx < game.size; sx++) {
                if (game.board[y][x] == 0) return 0;
            }
        }

        // throw tie
        return 3;
    }

    function makeMove(
        uint256 gameId,
        uint8 x,
        uint8 y
    ) public returns (bool) {
        // require game not have ended
        require(gameData[gameId].gameOver == 0, "ENDED_GAME");
        // require user is from from or to
        require(
            gameData[gameId].from == msg.sender ||
                gameData[gameId].to == msg.sender,
            "NO_GAME"
        );
        // validate it is their turn
        require(gameData[gameId].fromTurn == msg.sender, "NO_TURN");
        // require the move to be in the grid
        require(
            y <= gameData[gameId].size - 1 &&
                y >= 0 &&
                x >= 0 &&
                x <= gameData[gameId].size - 1,
            "OUT_BOUND"
        );
        // validate the slot is empty
        require(gameData[gameId].board[y][x] == 0, "ALREADY_TAKEN");
        // store the move
        gameData[gameId].board[y][x] = gameData[gameId].from == msg.sender
            ? 1
            : 2;
        // change moves
        gameData[gameId].fromTurn = gameData[gameId].from == msg.sender
            ? gameData[gameId].to
            : gameData[gameId].from;
        // calculate if we have a winner or not
        uint8 result = checkWinIn3x(gameId, x, y);
        if (result != 0) {
            gameData[gameId].gameOver = result;
            return true;
        }
        return false;
    }
}