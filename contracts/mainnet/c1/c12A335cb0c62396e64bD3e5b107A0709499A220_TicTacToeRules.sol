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
    @title TicTacToe Rules
    @notice Our take on the classic game, rules defined on-chain to never be checked
    @notice except by the arbiter when a dispute arises.
    @notice ETHOnline2022 submission by ChainHackers
    @author Gene A. Tsvigun
    @dev The state encodes the board as a 3x3 array of uint8s with 0 for empty, 1 for X, and 2 for O
    @dev explicitly keeping wins as `bool crossesWin` and `bool noughtsWin`
    @dev yes we know the board can be packed more efficiently but we want to keep it simple
  */
contract TicTacToeRules is IGameJutsuRules {

    struct Board {
        uint8[9] cells;
        bool crossesWin;
        bool naughtsWin;
    }

type Move is uint8;

    function isValidMove(GameState calldata _gameState, uint8 playerId, bytes calldata _move) external pure override returns (bool) {
        Board memory b = abi.decode(_gameState.state, (Board));
        uint8 _m = abi.decode(_move, (uint8));
        Move m = Move.wrap(_m);
        bool playerIdMatchesTurn = _gameState.nonce % 2 == playerId;
        return playerIdMatchesTurn && !b.crossesWin && !b.naughtsWin && _isMoveWithinRange(m) && _isCellEmpty(b, m);
    }

    function transition(GameState calldata _gameState, uint8 playerId, bytes calldata _move) external pure override returns (GameState memory) {
        Board memory b = abi.decode(_gameState.state, (Board));
        uint8 _m = abi.decode(_move, (uint8));
        b.cells[_m] = uint8(1 + _gameState.nonce % 2);
        Move move = Move.wrap(_m);
        if (_isWinningMove(b, move)) {
            if (playerId == 0) {
                b.crossesWin = true;
            } else {
                b.naughtsWin = true;
            }
        }
        return GameState(_gameState.gameId, _gameState.nonce + 1, abi.encode(b));
    }

    function defaultInitialGameState() external pure returns (bytes memory) {
        return abi.encode(Board([0, 0, 0, 0, 0, 0, 0, 0, 0], false, false));
    }

    function isFinal(GameState calldata state) external pure returns (bool){
        Board memory b = abi.decode(state.state, (Board));
        return b.crossesWin || b.naughtsWin || _isBoardFull(b);
    }

    function isWin(GameState calldata state, uint8 playerId) external pure returns (bool){
        Board memory b = abi.decode(state.state, (Board));
        return playerId == 0 ? b.crossesWin : b.naughtsWin;
    }

    function _isCellEmpty(Board memory b, Move move) private pure returns (bool) {
        return b.cells[Move.unwrap(move)] == 0;
    }

    function _isMoveWithinRange(Move move) private pure returns (bool){
        return Move.unwrap(move) < 9;
    }

    function _isBoardFull(Board memory b) private pure returns (bool) {
        for (uint8 i = 0; i < 9; i++) {
            if (b.cells[i] == 0) {
                return false;
            }
        }
        return true;
    }

    function _isWinningMove(Board memory b, Move move) private pure returns (bool) {
        uint8 _m = Move.unwrap(move);
        uint8 row = _m / 3;
        uint8 col = _m % 3;
        uint8 player = b.cells[_m];
        return _isRowWin(b, row, player) || _isColWin(b, col, player) || _isDiagonalWin(b, player);
    }

    function _isRowWin(Board memory b, uint8 row, uint8 player) private pure returns (bool) {
        return b.cells[row * 3] == player && b.cells[row * 3 + 1] == player && b.cells[row * 3 + 2] == player;
    }

    function _isColWin(Board memory b, uint8 col, uint8 player) private pure returns (bool) {
        return b.cells[col] == player && b.cells[col + 3] == player && b.cells[col + 6] == player;
    }

    function _isDiagonalWin(Board memory b, uint8 player) private pure returns (bool) {
        return (b.cells[0] == player && b.cells[4] == player && b.cells[8] == player) ||
        (b.cells[2] == player && b.cells[4] == player && b.cells[6] == player);
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