// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IGameJutsuRules.sol";

contract TicTacToeRules is IGameJutsuRules {

    struct Board {
        uint8[9] cells; //TODO pack it into a single uint16
        bool crossWins;
        bool naughtWins;
    }

    type Move is uint8;

    function isValidMove(GameState calldata _gameState, bytes calldata _move) external pure override returns (bool) {
        Board memory b = abi.decode(_gameState.state, (Board));
        uint8 _m = abi.decode(_move, (uint8));
        Move m = Move.wrap(_m);

        return !b.crossWins && !b.naughtWins && isMoveWithinRange(m) && isCellEmpty(b, m);
    }

    function transition(GameState calldata _gameState, bytes calldata _move) external pure override returns (GameState memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameJutsuRules {
    struct GameState {
        uint256 gameId;
        uint256 nonce;
        bytes state;
    }

    function isValidMove(GameState calldata state, bytes calldata move) external pure returns (bool);

    function transition(GameState calldata state, bytes calldata move) external pure returns (GameState memory);

    function defaultInitialGameState() external pure returns (bytes memory);
}