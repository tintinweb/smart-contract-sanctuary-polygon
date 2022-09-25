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
    @dev The state encodes the board as a 3x3 array of uint8s with 0 for empty, 1 for X, and 2 for O
    @dev explicitly keeping wins as `bool crossesWin` and `bool noughtsWin`
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
        @custom from 1-based index of the cell to move from
        @custom to 1-based index of the cell to move to
        @custom isJump declares if the move is a jump
        @custom passMoveToOpponent declares explicitly if the next move is to be done by the opponent
      */
    struct Move {
        uint8 from;
        uint8 to;
        bool isJump;
        bool passMoveToOpponent;
    }

    //    bytes public constant MOVE_01 = hex"0506060707080800";
    //    bytes public constant MOVE_05 = hex"0900090A0A0B0B0C";
    //    bytes public constant MOVE_09 = hex"0D0E0E0F0F101000";
    //    bytes public constant MOVE_0D = hex"1100111212131314";
    //    bytes public constant MOVE_11 = hex"1516161717181800";
    //    bytes public constant MOVE_15 = hex"1900191A1A1B1B1C";
    //    bytes public constant MOVE_19 = hex"1D1E1E1F1F202000";
    //    bytes public constant MOVE_1D = hex"0000000000000000";
    bytes public constant MOVES = hex"05060607070808000900090A0A0B0B0C0D0E0E0F0F101000110011121213131415161617171818001900191A1A1B1B1C1D1E1E1F1F2020000000000000000000";

    //    bytes public constant RMOV_01 = hex"0000000000000000";
    //    bytes public constant RMOV_05 = hex"0100010202030304";
    //    bytes public constant RMOV_09 = hex"0506060707080800";
    //    bytes public constant RMOV_0D = hex"0900090A0A0B0B0C";
    //    bytes public constant RMOV_11 = hex"0D0E0E0F0F101000";
    //    bytes public constant RMOV_15 = hex"1100111212131314";
    //    bytes public constant RMOV_19 = hex"1516161717181800";
    //    bytes public constant RMOV_1D = hex"1900191A1A1B1B1C";
    bytes public constant RMOVS = hex"0000000000000000010001020203030405060607070808000900090A0A0B0B0C0D0E0E0F0F101000110011121213131415161617171818001900191A1A1B1B1C";

    //    bytes public constant JUMP_01 = hex"0A00090B0A0C0B00";
    //    bytes public constant JUMP_05 = hex"0E000D0F0E101F00";
    //    bytes public constant JUMP_09 = hex"1200111312141300";
    //    bytes public constant JUMP_0D = hex"1600151716181700";
    //    bytes public constant JUMP_11 = hex"1A00191B1A1C1B00";
    //    bytes public constant JUMP_15 = hex"1E001D1F1E201F00";
    //    bytes public constant JUMP_19 = hex"0000000000000000";
    //    bytes public constant JUMP_1D = hex"0000000000000000";
    bytes public constant JUMPS = hex"0A00090B0A0C0B000E000D0F0E101F00120011131214130016001517161817001A00191B1A1C1B001E001D1F1E201F0000000000000000000000000000000000";

    //    bytes public constant RJMP_01 = hex"0000000000000000";
    //    bytes public constant RJMP_05 = hex"0000000000000000";
    //    bytes public constant RJMP_09 = hex"0200010302040300";
    //    bytes public constant RJMP_0D = hex"0600050706080708";
    //    bytes public constant RJMP_11 = hex"0A00090B0A0C0B00";
    //    bytes public constant RJMP_15 = hex"0E000D0F0E101F00";
    //    bytes public constant RJMP_19 = hex"1200111312141300";
    //    bytes public constant RJMP_1D = hex"1600151716181700";
    bytes public constant RJUMP = hex"00000000000000000000000000000000020001030204030006000507060807080A00090B0A0C0B000E000D0F0E101F0012001113121413001600151716181700";

    //             1       2       3       4
    // 1     │███│ o │███│ o │███│ o │███│ o │ 04
    // 5     │ o │███│ o │███│ o │███│ o │███│ 08
    // 9     │███│ o │███│ o │███│ o │███│ o │ 0C
    // 13 0D │   │███│   │███│   │███│   │███│ 10
    // 17 11 │███│   │███│   │███│   │███│   │ 14
    // 21 15 │ x │███│ x │███│ x │███│ x │███│ 18
    // 25 19 │███│ x │███│ x │███│ x │███│ x │ 1C
    // 29 1D │ x │███│ x │███│ x │███│ x │███│ 20
    //        1D      1E      1F      20

    /**
        @param _state is the state of the game represented by `abi.encode`d `State` struct
        @param playerId 0 is White, player 1 is Red
        @param _move is the move represented by `abi.encode`d `Move` struct
        */
    function isValidMove(GameState calldata _state, uint8 playerId, bytes calldata _move) external pure override returns (bool) {
        State memory state = abi.decode(_state.state, (State));
        Move memory move = abi.decode(_move, (Move));
        bool isPlayerRed = playerId == 1;
        bool isInBounds = move.from > 0 && move.from <= 32 && move.to > 0 && move.to <= 32;
        bool isCorrectPlayerMove = isPlayerRed == state.redMoves;

        bool isFromOccupied = _isCellOccupied(state, move.from);
        bool isToEmpty = !_isCellOccupied(state, move.to);

        bool isCheckerRed = _isCheckerRed(state, move.from);
        bool isCheckerKing = _isCheckerKing(state, move.from);

        bool isColorCorrect = isCheckerRed == isPlayerRed;
        bool isDirectionCorrect = isCheckerKing || isCheckerRed ? move.from > move.to : move.from < move.to;

        bool isToCorrect = !move.isJump && _isMoveDestinationCorrect(move.from, move.to, isCheckerRed, isCheckerKing) ||
        move.isJump && _isJumpDestinationCorrect(move.from, move.to, isCheckerRed, isCheckerKing);
        bool isJumpCorrect = !move.isJump || _isCaptureCorrect(state, move.from, move.to, isCheckerRed, isCheckerKing);
        bool isCaptureCorrect = !move.isJump || _isCaptureCorrect(state, move.from, move.to, isCheckerRed, isCheckerKing);

        return isCorrectPlayerMove &&
        isInBounds &&
        isFromOccupied &&
        isToEmpty &&
        isColorCorrect &&
        isDirectionCorrect &&
        isFromOccupied &&
        isToEmpty &&
        isToCorrect &&
        isJumpCorrect &&
        isCaptureCorrect;
    }

    /**
        @param state `uint8[32]` array representing board cells, 0: empty, 01:W, 02:R, A1:WK, A2:RK
        @param cell is 1-based index of the cell checked
        */
    function _isCellOccupied(State memory state, uint8 cell) private pure returns (bool) {
        return state.cells[cell - 1] != 0;
    }

    /**
        @param cell is 1-based index of the cell checked
        */
    function _isCheckerRed(State memory state, uint8 cell) private pure returns (bool) {
        return state.cells[cell - 1] % 16 == 2;
    }

    function _isCheckerKing(State memory state, uint8 cell) private pure returns (bool) {
        return state.cells[cell - 1] / 16 == 10;
    }

    /**
        @param _from 1-based index of the cell from which the checker is moved
        @param _to 1-based index of the cell to which the checker is moved
        @param isRed is true if the checker doing the move is red
        @param isKing is true if the checker doing the move is king
        */
    function _isMoveDestinationCorrect(uint8 _from, uint8 _to, bool isRed, bool isKing) private pure returns (bool) {
        uint8 from = _from - 1;
        bytes1 to = bytes1(_to);
        bool isRedMove = (
        RMOVS[from * 2] == to ||
        RMOVS[from * 2 + 1] == to
        );
        bool isWhiteMove = (
        MOVES[from * 2] == to ||
        MOVES[from * 2 + 1] == to
        );

        return (isRed || isKing) && isRedMove || (!isRed || isKing) && isWhiteMove;
    }

    /**
        @param state `abi.encode`d `State` struct
        @param from 1-based index of the cell from which the checker is moved
        @param to 1-based index of the cell to which the checker is moved
        @param isPlayerRed is true if the player doing the move plays red
        @param isKing is true if the checker doing the move is king
        */
    function _isCaptureCorrect(State memory state, uint8 from, uint8 to, bool isPlayerRed, bool isKing) private pure returns (bool) {
        bytes1 jump = bytes1(to);
        uint8 f2 = (from - 1) * 2;
        uint8 opponent = _opponent(isPlayerRed);
        if (JUMPS[f2] == jump) {
            return state.cells[uint8(MOVES[f2])] == opponent;
        } else if (JUMPS[f2 + 1] == jump) {
            return state.cells[uint8(MOVES[f2 + 1])] == opponent;
        } else if (RJUMP[f2] == jump) {
            return state.cells[uint8(RMOVS[f2])] == opponent;
        } else if (RJUMP[f2 + 1] == jump) {
            return state.cells[uint8(RMOVS[f2 + 1])] == opponent;
        } else {
            return false;
        }
    }

    function _opponent(bool isPlayerRed) private pure returns (uint8) {
        return isPlayerRed ? 1 : 2;
    }


    function _isJumpDestinationCorrect(uint8 _from, uint8 _to, bool isRed, bool isKing) internal pure returns (bool) {
        bytes1 to = bytes1(_to);
        uint8 from = _from - 1;
        bool isRedJump = (
        RJUMP[from * 2] == to ||
        RJUMP[from * 2 + 1] == to
        );
        bool isWhiteJump = (
        JUMPS[from * 2] == to ||
        JUMPS[from * 2 + 1] == to
        );

        return (isRed || isKing) && isRedJump || (!isRed || isKing) && isWhiteJump;
    }

    function transition(GameState calldata _state, uint8 playerId, bytes calldata _move) external pure override returns (GameState memory) {
        State memory state = abi.decode(_state.state, (State));
        Move memory move = abi.decode(_move, (Move));
        state.cells[move.to - 1] = state.cells[move.from - 1];
        state.cells[move.from - 1] = 0;
        if (move.isJump) {
            state.cells[(move.from + move.to) / 2] = 0;
            state.redMoves = _validJumpExist(state.cells, state.redMoves);
        } else {
            state.redMoves = !state.redMoves;
        }
        return GameState(_state.gameId, _state.nonce + 1, abi.encode(state));
    }

    function defaultInitialGameState() external pure returns (bytes memory) {

        // 1   │███│ o │███│ o │███│ o │███│ o │
        // 5   │ o │███│ o │███│ o │███│ o │███│
        // 9   │███│ o │███│ o │███│ o │███│ o │
        // 13  │   │███│ 14│███│   │███│   │███│
        // 17  │███│   │███│ 18│███│   │███│   │
        // 21  │ x │███│ x │███│ x │███│ x │███│
        // 25  │███│ x │███│ x │███│ x │███│ x │
        // 29  │ x │███│ x │███│ x │███│ x │███│

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

    function _validMovesExist(uint8[32] memory cells) private view returns (bool whiteHasValidMoves, bool redHasValidMoves) {
        whiteHasValidMoves = false;
        redHasValidMoves = false;
        for (uint8 i = 0; i < 32; i++) {
            bool isRed = cells[i] % 16 == 2;
            if (isRed) {
                redHasValidMoves = redHasValidMoves || _canMove(cells, i);
            } else {
                whiteHasValidMoves = whiteHasValidMoves || _canMove(cells, i);
            }
        }
    }

    function _validJumpExist(uint8[32] memory cells, bool forRed) private pure returns (bool) {
        for (uint8 i = 0; i < 32; i++) {
            bool isRed = cells[i] % 16 == 2;
            if (isRed == forRed && _canJump(cells, i)) {
                return true;
            }
        }
        return false;
    }

    /**
        @param from 0-based index
      */
    function _canMove(uint8[32] memory cells, uint8 from) private view returns (bool) {
        if (cells[from] == 0)
            return false;
        bool isRed = cells[from] % 16 == 2;
        //TODO deduplicate
        bool isKing = cells[from] / 16 == 10;
        uint8 f2 = from * 2;
        bool redCanMove = RMOVS[from * 2] > 0 && cells[uint8(RMOVS[from * 2]) - 1] == 0 || RMOVS[from * 2 + 1] > 0 && cells[uint8(RMOVS[from * 2 + 1]) - 1] == 0;
        bool whiteCanMove = MOVES[from * 2] > 0 && cells[uint8(MOVES[from * 2]) - 1] == 0 || MOVES[from * 2 + 1] > 0 && cells[uint8(MOVES[from * 2 + 1]) - 1] == 0;
        return isRed && redCanMove || !isRed && whiteCanMove || isKing && (redCanMove || whiteCanMove);
    }


    /**
        @param from 0-based index
      */
    function _canJump(uint8[32] memory cells, uint8 from) private pure returns (bool) {
        bytes memory MOVS = hex"05060607070808000900090A0A0B0B0C0D0E0E0F0F101000110011121213131415161617171818001900191A1A1B1B1C1D1E1E1F1F2020000000000000000000";
        bytes memory RMVS = hex"0000000000000000010001020203030405060607070808000900090A0A0B0B0C0D0E0E0F0F101000110011121213131415161617171818001900191A1A1B1B1C";
        bytes memory JMPS = hex"0A00090B0A0C0B000E000D0F0E101F00120011131214130016001517161817001A00191B1A1C1B001E001D1F1E201F0000000000000000000000000000000000";
        bytes memory RJMP = hex"00000000000000000000000000000000020001030204030006000507060807080A00090B0A0C0B000E000D0F0E101F0012001113121413001600151716181700";

        if (cells[from] == 0)
            return false;
        bool isRed = cells[from] % 16 == 2;
        //TODO deduplicate
        bool isKing = cells[from] / 16 == 10;
        uint8 f2 = from * 2;
        bool redCanJump = RJMP[f2] > 0 && cells[uint8(RJMP[f2]) - 1] == 0 && cells[uint8(RMVS[f2]) - 1] % 16 == 1 ||
        RJMP[f2 + 1] > 0 && cells[uint8(RJMP[f2 + 1]) - 1] == 0 && cells[uint8(RMVS[f2 + 1]) - 1] % 16 == 1;
        bool whtCanJump = JMPS[f2] > 0 && cells[uint8(JMPS[f2]) - 1] == 0 && cells[uint8(MOVS[f2]) - 1] % 16 == 2 ||
        JMPS[f2 + 1] > 0 && cells[uint8(JMPS[f2 + 1]) - 1] == 0 && cells[uint8(MOVS[f2 + 1]) - 1] % 16 == 2;
        return isRed && redCanJump || !isRed && whtCanJump || isKing && (redCanJump || whtCanJump);
    }


    function isFinal(GameState calldata _gameState) external pure override returns (bool) {
        return false;
    }

    function isWin(GameState calldata _gameState, uint8 playerId) external pure override returns (bool) {
        return false;
    }

    function _decodeMove(bytes calldata move) private pure returns (Move memory) {
        return abi.decode(move, (Move));
    }

    function _decodeState(bytes calldata state) private pure returns (State memory) {
        return abi.decode(state, (State));
    }

    function _isRed(uint8 _piece) private pure returns (bool) {
        return _piece == 1;
    }

    function _isKing(uint8 _piece) private pure returns (bool) {
        return _piece % 16 == 10;
    }

    function _canMoveTo(uint8 i) private pure returns (uint8[4] memory) {
        return [0, 0, 0, 0];
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