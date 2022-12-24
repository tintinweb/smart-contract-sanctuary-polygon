// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Game is the base contract with game logic
contract Game is Ownable {
    /// @dev Move - enum with kinds of move
    enum Move {MoveUnknown, MoveRock, MoveScissors, MovePaper}

    /// @dev Round - struct with round information
    struct Round {
        uint256 startedAt;        // when round was started
        bytes32 firstPlayerHash;  // first player hash
        Move firstPlayerMove;     // first player move
        uint256 firstMoveAt;      // first move timestamp
        Move secondPlayerMove;    // second player move
        uint256 secondMoveAt;     // second move timestamp
        uint256 finishedAt;       // round finish timestamp
    }

    /// @dev SingleGame - struct with game parameters
    struct SingleGame {
        address payable firstPlayerAddress;   // first player address
        address payable secondPlayerAddress;  // second player address
        uint256 createdAt;                    // game creation timestamp
        uint256 startedAt;                    // game start timestamp
        uint256 maxMoveDuration;              // max move duration
        uint256 bet;                          // game bet
        uint8 winsRequired;                   // wins required for win
        uint8 firstPlayerWins;                // first player wins
        uint8 secondPlayerWins;               // second player wins
    }

    /// @dev emitted when new game is created
    event GameCreation(
        string gameId,
        address firstPlayer,
        uint256 createdAt,
        uint256 bet,
        uint256 maxMoveDuration,
        uint8 winsRequired
    );

    /// @dev emitted when second player join the game 
    event GameJoin(
        string gameId,
        address secondPlayer
    );

    /// @dev emitted when second player left the game
    event GameLeft(
        string gameId,
        address secondPlayer
    );

    /// @dev emitted when the game is started
    event GameStart(
        string gameId,
        uint256 startedAt
    );

    /// @dev emitted when new round is started
    event GameRoundStart(
        string gameId,
        uint256 roundNum,
        uint256 startedAt
    );

    /// @dev emitted when first move is done
    event FirstMove(
        string gameId,
        uint256 roundNum,
        bytes32 hash,
        uint256 madeAt
    );

    /// @dev emitted when second move is done
    event SecondMove(
        string gameId,
        uint256 roundNum,
        Move move,
        uint256 madeAt
    );

    /// @dev emitted when the round is finished
    event FinishRound(
        string gameId,
        uint256 roundNum,
        Move firstMove,
        address winner,
        uint256 finishedAt
    );

    /// @dev emitted when the round is finished with timeout
    event FinishRoundWithTimeout(
        string gameId,
        uint256 roundNum,
        address winner,
        uint256 finishedAt
    );

    /// @dev emitted when the game is finished
    event FinishGame(
        string gameId,
        address winner
    );

    /// @dev emitted when the game is camceled
    event GameCancellation(
        string gameId
    );

    mapping(string => SingleGame) public games;       // id to game map
    mapping(string => Round[]) public rounds;         // id to rounds map
    uint256 public constant fullCommission = 100000;  // full commission constant
    uint256 public commission = 0;                    // commission (100000==100%)
    uint256 public gameTimeout = 0;                   // game timeout
    uint256 public balance = 0;                       // balance from fees

    /// @dev constructor
    /// @param  _commission - commission of the game
    constructor(uint256 _commission) {
        require(_commission < 100000, "GamePlay: commission must be less than 100%");
        _transferOwnership(_msgSender());
        commission = _commission;
    }

    /// @dev update commission setter-function
    /// @param _commission - commission to set
    function updCommission(uint256 _commission) public onlyOwner {
        require(_commission < 100000, "GamePlay: commission must be less than 100%");
        commission = _commission;
    }

    /// @dev withdraw collected fees
    /// @param receiver - receiver
    /// @param value - value to withdraw
    function withdraw(address payable receiver, uint256 value) public onlyOwner {
        require(value <= balance, "Game: value should be less or equal than current balance");
        receiver.transfer(value);
        balance -= value;
    }

    /// @dev update timeout setter-function
    /// @param _timeout - timeout to set
    function updTimeout(uint256 _timeout) public onlyOwner {
        gameTimeout = _timeout;
    }

    /// @dev function for creating the game
    /// @param gameId - game id
    /// @param maxMoveDuration - max move duration
    /// @param winsRequired - wins required for win
    /// Emits GameCreation event
    function createGame(
        string calldata gameId,
        uint256 maxMoveDuration,
        uint8 winsRequired
    ) external payable {
        require(games[gameId].bet == 0, "GamePlay: game exists");
        require(msg.value > 0, "GamePlay: bet must be positive");
        require(maxMoveDuration <= 5 * 60, "GamePlay: max move duration must be less than 5 minutes");
        uint256 createdAt = block.timestamp;
        SingleGame memory newGame = SingleGame(
            payable(_msgSender()),
            payable(address(0)),
            createdAt,
            0,
            maxMoveDuration,
            msg.value,
            winsRequired,
            0,
            0
        );
        games[gameId] = newGame;
        emit GameCreation(gameId, _msgSender(), createdAt, msg.value, maxMoveDuration, winsRequired);
    }

    /// @dev function for joining the game
    /// @param gameId - game id
    /// Emits GameJoin event
    function joinGame(string calldata gameId) external payable {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.secondPlayerAddress == address(0), "GamePlay: another player has already joined game");
        require(msg.value == game.bet, "GamePlay: tx value must equal bet");
        game.secondPlayerAddress = payable(_msgSender());
        emit GameJoin(gameId, _msgSender());
    }

    /// @dev function for leaving the game
    /// @param gameId - game id
    /// Emits GameLeft event    
    function leaveGame(string calldata gameId) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.secondPlayerAddress == _msgSender(), "GamePlay: you are not second player");
        require(game.startedAt == 0, "GamePlay: game started");
        payable(_msgSender()).transfer(game.bet);
        game.secondPlayerAddress = payable(0);
        emit GameLeft(gameId, _msgSender());
    }

    /// @dev function for canceling the game
    /// @param gameId - game id
    /// Emits GameCancellation event
    function cancelGame(string calldata gameId) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.firstPlayerAddress == _msgSender(), "GamePlay: you are not game creator");
        require(game.startedAt == 0, "GamePlay: game started");
        game.firstPlayerAddress.transfer(game.bet);
        if (game.secondPlayerAddress != address(0)) {
            game.secondPlayerAddress.transfer(game.bet);
        }
        emit GameCancellation(gameId);
        delete games[gameId];
    }

    /// @dev function for starting the game
    /// @param gameId - game id
    /// Emits GameStart event
    /// Emits GameRoundStart event
    function startGame(string calldata gameId) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.firstPlayerAddress == _msgSender(), "GamePlay: you are not game creator");
        require(game.secondPlayerAddress != address(0), "GamePlay: no second player");
        require(game.startedAt == 0, "GamePlay: game started");
        game.startedAt = block.timestamp;
        rounds[gameId].push(Round(block.timestamp, 0x00000000000000000000000000000000,
            Move.MoveUnknown, 0, Move.MoveUnknown, 0, 0));
        emit GameStart(gameId, game.startedAt);
        emit GameRoundStart(gameId, 0, block.timestamp);
    }

    /// @dev function for making the first move
    /// @param gameId - game id
    /// @param moveHash - hash of the move
    /// Emits FirstMove event
    function makeFirstMove(string calldata gameId, bytes32 moveHash) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.startedAt > 0, "GamePlay: not started game");
        Round storage round = rounds[gameId][rounds[gameId].length - 1];
        require(round.firstMoveAt == 0, "GamePlay: move done");
        round.firstPlayerHash = moveHash;
        round.firstMoveAt = block.timestamp;
        emit FirstMove(gameId, rounds[gameId].length - 1, moveHash, block.timestamp);
    }

    /// @dev function for making the second move
    /// @param gameId - game id
    /// @param move - move
    /// Emits SecondMove event
    function makeSecondMove(string calldata gameId, Move move) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.startedAt > 0, "GamePlay: not started game");
        Round storage round = rounds[gameId][rounds[gameId].length - 1];
        require(round.firstMoveAt > 0, "GamePlay: no first move");
        require(round.secondMoveAt == 0, "GamePlay: move done");
        require(move == Move.MoveRock || move == Move.MoveScissors || move == Move.MovePaper, "GamePlay: move unknown");
        round.secondPlayerMove = move;
        round.secondMoveAt = block.timestamp;
        emit SecondMove(gameId, rounds[gameId].length - 1, move, block.timestamp);
    }

    /// @dev function for finishing the round
    /// @param gameId - game id
    /// @param data - salt for hashing the move
    /// @param move - move
    /// Emits FinishRound event
    function finishRound(string calldata gameId, bytes memory data, Move move) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.startedAt > 0, "GamePlay: not started game");
        Round storage round = rounds[gameId][rounds[gameId].length - 1];
        require(round.firstMoveAt > 0, "GamePlay: no first move");
        require(round.secondMoveAt > 0, "GamePlay: no second move");
        require(move == Move.MoveRock || move == Move.MoveScissors || move == Move.MovePaper, "GamePlay: move unknown");
        bytes32 hash = calcMoveHash(data, move);
        round.finishedAt = block.timestamp;

        address winner;
        if (hash == round.firstPlayerHash) {
            round.firstPlayerMove = move;
            winner = determineWinner(
                game.firstPlayerAddress, game.secondPlayerAddress, round.firstPlayerMove, round.secondPlayerMove);
        } else {
            winner = game.secondPlayerAddress;
        }
        emit FinishRound(gameId, rounds[gameId].length - 1, round.firstPlayerMove, winner, block.timestamp);
        processWinner(gameId, game, winner);
    }

    /// @dev function for finishing the round with timeout
    /// @param gameId - game id
    function finishRoundWithTimeout(string calldata gameId) external {
        SingleGame storage game = games[gameId];
        require(game.bet > 0, "GamePlay: game doesn't exist");
        require(game.startedAt > 0, "GamePlay: not started game");
        Round storage round = rounds[gameId][rounds[gameId].length - 1];
        round.finishedAt = block.timestamp;
        if (round.firstMoveAt == 0) {
            require(_msgSender() == game.secondPlayerAddress, "GamePlay: you are not second player");
            require(block.timestamp > round.startedAt + game.maxMoveDuration, "GamePlay: timeout hasn't reached");
            emit FinishRoundWithTimeout(gameId, rounds[gameId].length - 1, game.secondPlayerAddress, block.timestamp);
            processWinner(gameId, game, game.secondPlayerAddress);
        } else if (round.secondMoveAt == 0) {
            require(_msgSender() == game.firstPlayerAddress, "GamePlay: you are not first player");
            require(block.timestamp > round.firstMoveAt + game.maxMoveDuration, "GamePlay: timeout hasn't reached");
            emit FinishRoundWithTimeout(gameId, rounds[gameId].length - 1, game.firstPlayerAddress, block.timestamp);
            processWinner(gameId, game, game.firstPlayerAddress);
        } else {
            require(_msgSender() == game.secondPlayerAddress, "GamePlay: you are not second player");
            require(block.timestamp > round.secondMoveAt + game.maxMoveDuration, "GamePlay: timeout hasn't reached");
            emit FinishRoundWithTimeout(gameId, rounds[gameId].length - 1, game.secondPlayerAddress, block.timestamp);
            processWinner(gameId, game, game.secondPlayerAddress);
        }
    }

    /// @dev function for processing the winner
    /// @param gameId - game id
    /// @param game - game from the storage
    /// @param winner - winner address
    /// Emits GameRoundStart event when there is no winner yet
    function processWinner(string calldata gameId, SingleGame storage game, address winner) internal {
        if (winner == game.firstPlayerAddress) {
            game.firstPlayerWins++;
        } else if (winner == game.secondPlayerAddress) {
            game.secondPlayerWins++;
        }

        if (game.firstPlayerWins == game.winsRequired) {
            finishGame(gameId, game.bet, game.firstPlayerAddress);
        } else if (game.secondPlayerWins == game.winsRequired) {
            finishGame(gameId, game.bet, game.secondPlayerAddress);
        } else {
            rounds[gameId].push(Round(block.timestamp, 0x00000000000000000000000000000000,
                Move.MoveUnknown, 0, Move.MoveUnknown, 0, 0));
            emit GameRoundStart(gameId, rounds[gameId].length - 1, block.timestamp);
        }
    }

    /// @dev function for finishing the game
    /// @param gameId - game id
    /// @param bet - bet
    /// @param winner - winner address
    /// Emits FinishGame event
    function finishGame(string calldata gameId, uint256 bet, address payable winner) internal {
        uint256 win = (bet * (fullCommission - commission)) / fullCommission;
        uint256 fee = bet - win;
        balance += fee;
        winner.transfer(win);
        delete games[gameId];
        delete rounds[gameId];
        emit FinishGame(gameId, winner);
    }

    /// @dev function for calculating move hash
    /// @param data- salt
    /// @param move - move
    function calcMoveHash(bytes memory data, Move move) internal pure returns (bytes32) {
        bytes memory appended = new bytes(data.length + 1);
        for (uint256 i = 0; i < data.length; i++) {
            appended[i] = data[i];
        }
        if (move == Move.MoveRock) {
            appended[data.length] = abi.encodePacked(uint8(0x1))[0];
        } else if (move == Move.MoveScissors) {
            appended[data.length] = abi.encodePacked(uint8(0x2))[0];
        } else {
            appended[data.length] = abi.encodePacked(uint8(0x3))[0];
        }
        return sha256(appended);
    }

    /// @dev function for determining the winner
    /// @param first - address of the first player
    /// @param second - address of the second player
    /// @param firstMove - move of the first player
    /// @param secondMove - move of the second player
    function determineWinner(address first, address second, Move firstMove, Move secondMove) internal pure returns (address) {
        if (isWin(firstMove, secondMove)) {
            return first;
        } else if (isWin(secondMove, firstMove)) {
            return second;
        }
        return address(0);
    }

    /// @dev function for checking the victory
    /// @param firstMove - first player move
    /// @param secondMove - second player move
    /// @return bool - if this is win function return true 
    function isWin(Move firstMove, Move secondMove) internal pure returns (bool) {
        if (firstMove == Move.MoveRock && secondMove == Move.MoveScissors) {
            return true;
        } else if (firstMove == Move.MoveScissors && secondMove == Move.MovePaper) {
            return true;
        } else if (firstMove == Move.MovePaper && secondMove == Move.MoveRock) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}