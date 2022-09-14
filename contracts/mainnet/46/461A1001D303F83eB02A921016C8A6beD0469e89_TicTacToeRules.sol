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
  */
contract TicTacToeRules is IGameJutsuRules {

    struct Board {
        uint8[9] cells; //TODO pack it into a single uint16
        bool crossesWin;
        bool naughtsWin;
    }

type Move is uint8;

    function isValidMove(GameState calldata _gameState, uint8 playerId, bytes calldata _move) external pure override returns (bool) {
        Board memory b = abi.decode(_gameState.state, (Board));
        uint8 _m = abi.decode(_move, (uint8));
        Move m = Move.wrap(_m);
        bool playerIdMatchesTurn = _gameState.nonce % 2 == playerId;
        return playerIdMatchesTurn && !b.crossesWin && !b.naughtsWin && isMoveWithinRange(m) && isCellEmpty(b, m);
    }

    function transition(GameState calldata _gameState, uint8 playerId, bytes calldata _move) external pure override returns (GameState memory) {
        Board memory b = abi.decode(_gameState.state, (Board));
        uint8 _m = abi.decode(_move, (uint8));
        b.cells[_m] = uint8(1 + _gameState.nonce % 2);
        return GameState(_gameState.gameId, _gameState.nonce + 1, abi.encode(b));
    }

    function defaultInitialGameState() external pure returns (bytes memory) {
        return abi.encode(Board([0, 0, 0, 0, 0, 0, 0, 0, 0], false, false));
    }

    function isCellEmpty(Board memory b, Move move) private pure returns (bool) {
        return b.cells[Move.unwrap(move)] == 0;
    }


    function isMoveWithinRange(Move move) private pure returns (bool){
        return Move.unwrap(move) < 9;
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
}