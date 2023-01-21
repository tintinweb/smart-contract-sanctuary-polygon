/*
  ________                           ____.       __
 /  _____/_____    _____   ____     |    |__ ___/  |_  ________ __
/   \  ___\__  \  /     \_/ __ \    |    |  |  \   __\/  ___/  |  \
\    \_\  \/ __ \|  Y Y  \  ___//\__|    |  |  /|  |  \___ \|  |  /
 \______  (____  /__|_|  /\___  >________|____/ |__| /____  >____/
        \/     \/      \/     \/                          \/
https://gamejutsu.app
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IGameJutsuRules.sol";

/**
    @title Checkers Rules
    @notice https://www.officialgamerules.org/checkers
    @notice GameJutsu's second game example, rules defined on-chain to never be checked
    @notice except by the arbiter when a dispute arises.
    @notice ETHOnline2022 submission by ChainHackers
    @author Gene A. Tsvigun
    @author Vic G. Larson
    @dev The state encodes the board as `uint[32] with 0 for empty, 1 for White, and 2 for Red
    @dev yes we know the board can be packed more efficiently but we want to keep it simple
  */
contract CheckersRules is IGameJutsuRules {

    /**
        @custom cells 32-byte array of uint8s representing the board
        @custom redMoves says whether it is red's turn to move
        @custom winner is 0 for no winner, 1 for white, 2 for red
        @dev cells[i] values:
        @dev 0x01 is White
        @dev 0x02 is Red
        @dev 0xA1 is White King
        @dev 0xA2 is Red King
      */
    struct State {
        uint8[32] cells;
        bool redMoves;
        uint8 winner;
    }

    /**
        @custom from index of the cell to move from
        @custom to index of the cell to move to
        @custom isJump declares if the move is a jump
        @custom passMoveToOpponent declares explicitly if the next move is to be done by the opponent
      */
    struct Move {
        uint8 from;
        uint8 to;
        bool isJump;
        bool passMoveToOpponent;
    }

    //          0       1       2       3
    // 0  │███│ o │███│ o │███│ o │███│ o │ 3
    // 4  │ o │███│ o │███│ o │███│ o │███│ 7
    // 8  │███│ o │███│ o │███│ o │███│ o │ 11
    // 12 │   │███│   │███│   │███│   │███│ 15
    // 16 │███│   │███│   │███│   │███│   │ 19
    // 20 │ x │███│ x │███│ x │███│ x │███│ 23
    // 24 │███│ x │███│ x │███│ x │███│ x │ 27
    // 28 │ x │███│ x │███│ x │███│ x │███│ 31
    //         1C      1D      1E      1F

    /**
        @param _state is the state of the game represented by `abi.encode`d `State` struct
        @param playerId 0 is White, player 1 is Red
        @param _move is the move represented by `abi.encode`d `Move` struct
        */
    function isValidMove(GameState calldata _state, uint8 playerId, bytes calldata _move) external pure override returns (bool) {
        State memory state = abi.decode(_state.state, (State));
        Move memory move = _decodeMove(_move);
        bool isPlayerRed = playerId == 1;
        bool isInBounds = move.from >= 0 && move.from < 32 && move.to >= 0 && move.to < 32;
        bool isCorrectPlayerMove = isPlayerRed == state.redMoves;

        bool isFromOccupied = _isCellOccupied(state, move.from);
        bool isToEmpty = !_isCellOccupied(state, move.to);

        bool isCheckerRed = _isRed(state.cells[move.from]);
        bool isCheckerKing = _isKing(state.cells[move.from]);

        bool isColorCorrect = isCheckerRed == isPlayerRed;
        bool isDirectionCorrect = isCheckerKing || (isCheckerRed ? move.from > move.to : move.from < move.to);

        bool isToCorrect = !move.isJump && _isMoveDestinationCorrect(move.from, move.to, isCheckerRed, isCheckerKing)
        || move.isJump && _isJumpDestinationCorrect(move.from, move.to);
        bool isCaptureCorrect = !move.isJump || _isCaptureCorrect(state.cells, move.from, move.to, isCheckerRed);

        if (!move.isJump) {
            if (_validJumpExists(state.cells, isPlayerRed) || !move.passMoveToOpponent)
                return false;
        } else {
            state.cells[move.to] = state.cells[move.from];
            state.cells[move.from] = 0;
            uint8 jumpedCell = _jumpMiddle(move.from, move.to);
            state.cells[jumpedCell] = 0;

            if (move.passMoveToOpponent == _validJumpExists(state.cells, isPlayerRed)) {
                return false;
            }
        }

        return isCorrectPlayerMove &&
        isInBounds &&
        isFromOccupied &&
        isToEmpty &&
        isColorCorrect &&
        isDirectionCorrect &&
        isFromOccupied &&
        isToEmpty &&
        isToCorrect &&
        isCaptureCorrect;
    }

    /**
        @param state `uint8[32]` array representing board cells, 0: empty, 01:W, 02:R, A1:WK, A2:RK
        @param cell is index of the cell checked
        */
    function _isCellOccupied(State memory state, uint8 cell) private pure returns (bool) {
        return state.cells[cell] != 0;
    }

    /**
        @param from index of the cell from which the checker is moved
        @param to index of the cell to which the checker is moved
        @param isRed is true if the checker doing the move is red
        @param isKing is true if the checker doing the move is king
        */
    function _isMoveDestinationCorrect(uint8 from, uint8 to, bool isRed, bool isKing) private pure returns (bool) {
        uint8 row = from / 4;
        uint8 col = from % 4;

        return _move(row, col, isRed, false) == to || _move(row, col, isRed, true) == to
        || isKing && (_move(row, col, !isRed, false) == to || _move(row, col, !isRed, true) == to);
    }

    /**
        @notice no matter if `from` and `to` represent a valid jump, this function will return the cell in between
        @param from index of the cell from which the checker is moved
        @param to index of the cell to which the checker is moved
        @return index of the cell in between `from` and `to`
        */
    function _jumpMiddle(uint8 from, uint8 to) private pure returns (uint8){
        return (from + to + 1 - ((from) / 4 % 2)) / 2;
    }

    function _move(uint8 row, uint8 col, bool red, bool right) private pure returns (uint8 destination) {
        uint8 dcol = row % 2;
        uint8 newCol = col;
        if (right) {
            if (col + 1 - dcol > 3) {
                return 255;
            }
            newCol = col + 1 - dcol;
        } else {
            if (col < dcol) {
                return 255;
            }
            newCol = col - dcol;
        }
        uint8 newRow;
        if (red) {
            if (row == 0) {
                return 255;
            }
            newRow = row - 1;
        } else {
            if (row > 6) {
                return 255;
            }
            newRow = row + 1;
        }
        destination = newRow * 4 + newCol;
    }

    function _jump(uint8 row, uint8 col, bool red, bool right) private pure returns (uint8 destination) {
        uint8 newCol = col;
        if (right) {
            if (col + 1 > 3) {
                return 255;
            }
            newCol = col + 1;
        } else {
            if (col < 1) {
                return 255;
            }
            newCol = col - 1;
        }
        uint8 newRow;
        if (red) {
            if (row < 2) {
                return 255;
            }
            newRow = row - 2;
        } else {
            if (row > 5) {
                return 255;
            }
            newRow = row + 2;
        }
        destination = newRow * 4 + newCol;
    }


    /**
        @param cells array of 32 `uint8`s representing the board
        @param from index of the cell from which the checker is moved
        @param to index of the cell to which the checker is moved
        @param isPlayerRed is true if the player doing the move plays red
        */
    function _isCaptureCorrect(uint8[32] memory cells, uint8 from, uint8 to, bool isPlayerRed) private pure returns (bool) {
        uint8 opponent = _opponent(isPlayerRed);
        return cells[_jumpMiddle(from, to)] == opponent;
    }

    function _opponent(bool isPlayerRed) private pure returns (uint8) {
        return isPlayerRed ? 1 : 2;
    }


    function _isJumpDestinationCorrect(uint8 from, uint8 to) private pure returns (bool) {
        uint8 diff = to > from ? to - from : from - to;
        return diff == 7 || diff == 9;
    }

    /**
        @notice What the rules say happens when a particular move is made in a particular state by a particular player
        @param _state GameState struct with the current state of the game: id, nonce, encoded game-specific state
        @param playerId 0 is White, player 1 is Red
        @param _move is the move represented by `abi.encode`d `Move` struct
        */
    function transition(GameState calldata _state, uint8 playerId, bytes calldata _move) external pure override returns (GameState memory) {
        State memory state = abi.decode(_state.state, (State));
        Move memory move = _decodeMove(_move);
        uint8 newCellValue = state.cells[move.from];
        bool isRed = state.cells[move.from] % 16 == 2;
        if (_lastRow(move.to, isRed)) {
            newCellValue = newCellValue | 0xA0;
        }
        state.cells[move.to] = newCellValue;
        state.cells[move.from] = 0;
        if (move.isJump) {
            uint8 jumpedCell = _jumpMiddle(move.from, move.to);
            state.cells[jumpedCell] = 0;
            if (!_validJumpExists(state.cells, state.redMoves)) {
                state.redMoves = !state.redMoves;
            }
        } else {
            state.redMoves = !state.redMoves;
        }

        (bool whiteHasMoves, bool redHasMoves) = _validMovesExist(state.cells);
        if (state.redMoves && !redHasMoves && !_validJumpExists(state.cells, state.redMoves)) {//TODO test valid jumps checks for setting the winner
            state.winner = 1;
        } else if (!state.redMoves && !whiteHasMoves && !_validJumpExists(state.cells, state.redMoves)) {
            state.winner = 2;
        }
        return GameState(_state.gameId, _state.nonce + 1, abi.encode(state));
    }

    /**
        @notice returns the traditional checkers starting position
      */
    function defaultInitialGameState() external pure returns (bytes memory) {

        // 0   │███│ o │███│ o │███│ o │███│ o │
        // 4   │ o │███│ o │███│ o │███│ o │███│
        // 8   │███│ o │███│ o │███│ o │███│ o │
        // 12  │   │███│ 14│███│   │███│   │███│
        // 16  │███│   │███│ 18│███│   │███│   │
        // 20  │ x │███│ x │███│ x │███│ x │███│
        // 24  │███│ x │███│ x │███│ x │███│ x │
        // 28  │ x │███│ x │███│ x │███│ x │███│

        return abi.encode(State([
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            0, 0, 0, 0,
            0, 0, 0, 0,
            2, 2, 2, 2,
            2, 2, 2, 2,
            2, 2, 2, 2
            ], false, 0));
    }

    /**
        @notice Check if the destination cell belongs to the last row for the specified color
        @param to Destination cell index
        @param isRed The color of the moving checker
        */
    function _lastRow(uint8 to, bool isRed) private pure returns (bool) {
        return isRed && to <= 3 || !isRed && to >= 28;
    }

    function _validMovesExist(uint8[32] memory cells) private pure returns (bool whiteHasValidMoves, bool redHasValidMoves) {
        whiteHasValidMoves = false;
        redHasValidMoves = false;
        for (uint8 i = 0; i < 32; i++) {
            if (cells[i] == 0)
                continue;
            if (_isRed(cells[i])) {
                redHasValidMoves = redHasValidMoves || _canMove(cells, i);
            } else {
                whiteHasValidMoves = whiteHasValidMoves || _canMove(cells, i);
            }
        }
    }

    function _validJumpExists(uint8[32] memory cells, bool forRed) private pure returns (bool) {
        for (uint8 i = 0; i < 32; i++) {
            if (_isRed(cells[i]) == forRed && _canJump(cells, i)) {
                return true;
            }
        }
        return false;
    }

    /**
        @param cells array of 32 `uint8`s representing the board
        @param from index
      */
    function _canMove(uint8[32] memory cells, uint8 from) private pure returns (bool) {
        bool isRed = _isRed(cells[from]);
        bool isKing = _isKing(cells[from]);
        uint8 row = from / 4;
        uint8 col = from % 4;
        return
        _isCellEmpty(cells, _move(row, col, isRed, false)) ||
        _isCellEmpty(cells, _move(row, col, isRed, true)) ||
        isKing && (
        _isCellEmpty(cells, _move(row, col, !isRed, false)) ||
        _isCellEmpty(cells, _move(row, col, !isRed, true))
        );
    }

    function _isCellEmpty(uint8[32] memory cells, uint8 i) private pure returns (bool) {
        return i < 32 && cells[i] == 0;
    }

    /**
        @param cells array of 32 `uint8`s representing the board
        @param from index
      */
    function _canJump(uint8[32] memory cells, uint8 from) private pure returns (bool) {
        if (cells[from] == 0)
            return false;
        bool isRed = _isRed(cells[from]);
        bool isKing = _isKing(cells[from]);
        uint8 row = from / 4;
        uint8 col = from % 4;

        uint8 opponent = isRed ? 1 : 2;
        uint8 jump = _jump(row, col, isRed, false);
        if (_isCellEmpty(cells, jump) && cells[_jumpMiddle(from, jump)] % 10 == opponent) {
            return true;
        }
        jump = _jump(row, col, isRed, true);
        if (_isCellEmpty(cells, jump) && cells[_jumpMiddle(from, jump)] % 10 == opponent) {
            return true;
        }

        if (isKing) {
            jump = _jump(row, col, !isRed, false);
            if (_isCellEmpty(cells, jump) && cells[_jumpMiddle(from, jump)] % 10 == opponent) {
                return true;
            }
            jump = _jump(row, col, !isRed, true);
            if (_isCellEmpty(cells, jump) && cells[_jumpMiddle(from, jump)] % 10 == opponent) {
                return true;
            }
        }
        return false;
    }


    function isFinal(GameState calldata _gameState) external pure override returns (bool) {
        return _decodeState(_gameState.state).winner != 0;
    }

    function isWin(GameState calldata _gameState, uint8 playerId) external pure override returns (bool) {
        return _decodeState(_gameState.state).winner == playerId + 1;
    }

    function _decodeMove(bytes calldata move) private pure returns (Move memory) {
        Move memory move = abi.decode(move, (Move));
        return move;
    }

    function _decodeState(bytes calldata state) private pure returns (State memory) {
        return abi.decode(state, (State));
    }

    function _isRed(uint8 _piece) private pure returns (bool) {
        return _piece % 16 == 2;
    }

    function _isKing(uint8 _piece) private pure returns (bool) {
        return _piece / 16 == 10;
    }
}

/*
  ________                           ____.       __
 /  _____/_____    _____   ____     |    |__ ___/  |_  ________ __
/   \  ___\__  \  /     \_/ __ \    |    |  |  \   __\/  ___/  |  \
\    \_\  \/ __ \|  Y Y  \  ___//\__|    |  |  /|  |  \___ \|  |  /
 \______  (____  /__|_|  /\___  >________|____/ |__| /____  >____/
        \/     \/      \/     \/                          \/
https://gamejutsu.app
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title GameJutsu Rules
    @notice "The fewer rules a coach has, the fewer rules there are for players to break." (John Madden)
    @notice ETHOnline2022 submission by ChainHackers
    @author Gene A. Tsvigun
  */
interface IGameJutsuRules {
    struct GameState {
        uint256 gameId;
        uint256 nonce;
        bytes state;
    }

    function isValidMove(GameState calldata state, uint8 playerId, bytes calldata move) external pure returns (bool);

    function transition(GameState calldata state, uint8 playerId, bytes calldata move) external pure returns (GameState memory);

    function defaultInitialGameState() external pure returns (bytes memory);

    function isFinal(GameState calldata state) external pure returns (bool);

    function isWin(GameState calldata state, uint8 playerId) external pure returns (bool);
}