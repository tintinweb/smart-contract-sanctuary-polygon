// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Bets is Ownable {

    // ID for the next game created
    uint256 private _nextGameID;

    // Royalty for the contract owner from each game bank
    uint256 private _royalty;

    // Minimum bet allowed for all games
    uint256 private _minBet;

    // Mapping game ID to game struct, see `Game`
    mapping(uint256 => Game) private _games;

    // Mapping games ID to result struct, see `Result`
    mapping(uint256 => Result) internal _results;

    // Game stages
    enum Stage{INIT, ROUND1, ROUND2, ROUND3, FINISHED}

    // Games turns
    enum Turn{NO_TURN, USER1, USER2}

    /*
     * Game struct with following fields:
     * - `user1` address of user how started the game
     * - `user2` address of user how joined the game
     * - `betsUser1` all bets made by `user1`
     * - `betsUser2` all bets made by `user2`
     * - `throwing` if true, user should throw dice before make other choices
     * - `winner` address of game winner
     * - `stage` current game stage, see `Stage`
     * - `turn` current game turn, see `Turn`
     *
     */
    struct Game {
        address user1;
        address user2;
        uint256 betsUser1;
        uint256 betsUser2;
        bool throwing;
        address winner;
        Stage stage;
        Turn turn;
    }

    /*
     * Result struct with following fields:
     * - `user1` slice of throwing dice results for `Game-user1`
     * - `user2` slice of throwing dice results for `Game-user2`
     *
     */
    struct Result {
        uint256[] user1;
        uint256[] user2;
    }

    // Triggered whenever game is started
    event GameStarted(uint256 id, address user1);

    // Triggered whenever game status is changed
    event ChangeGameStage(uint256 id, Stage stage);

    // Triggered whenever new min bet is set
    event MinBetChanges(uint256 newBet);

    // Triggered whenever dice is thrown
    event DiceThrown(uint256 id, address player);

    // Triggered whenever new bet is made
    event BetMade(uint256 id, uint256 amount, address player);

    constructor(uint256 minBet){
        _nextGameID = 1;
        _royalty = 10;
        _minBet = minBet;
    }

    // Returns nex game ID
    function nextGameID() external view returns(uint256) {
        return _nextGameID;
    }

    /*
     * Allows to get current minimum bet for all games
     *
     * @return `_mintBet` as uint256
     */
    function getMinBet() external view returns(uint256) {
        return _minBet;
    }

    /*
     * Allows to set new minimum bet for all games
     *
     * Requirements:
     * - bet should be more than 0
     * - caller should be a contract owner
     *
     * @dev sets new `_minBet` storage param
     *
     * @param `bet` - new minimum bet
     *
     * @emits `MinBetChanges` with new bet as arg
     */
    function setMinBet(uint256 newMinBet) external onlyOwner {
        require(newMinBet > 0, "Bets: bet should be more than 0");

        _minBet = newMinBet;

        emit MinBetChanges(newMinBet);
    }

    /*
     * Allows to get game by given game `id` as a `Game` struct
     *
     * @param `id` - game ID
     *
     * @return `Game` struct by given `id`
     */
    function getGame(uint256 id) external view returns(Game memory) {
        return _games[id];
    }

    /*
     * Allows to get game struct and results struct for given game `id`
     *
     * Requirements:
     * - caller should be a contract owner
     *
     * @param `id` - game ID
     *
     * @return `Game` struct and `Result` struct by given `id`
     */
    function getFullGameInfo(uint256 id) external view onlyOwner returns(Game memory, Result memory) {
        return (_games[id], _results[id]);
    }

    /*
     * Allows to create new game. Caller will be `Game-user1` player
     *
     * @dev creates new `Game` instance with `_nextGameID` as a key for `_games` mapping and `user1` as a caller address
     *
     * @emits `GameStarted` event with game `id` and `msg.sender` address
     */
    function startGame() external {
        Game memory game;
        Result memory result;
        game.user1 = msg.sender;

        uint256 id = _nextGameID;

        _games[id] = game;
        _results[id] = result;
        _nextGameID++;

        emit GameStarted(id, msg.sender);
    }

    /*
     * Allows to enter created game. Caller will be `Game-user2` player
     *
     * Requirements:
     * - game should have `user2` field as a zero address
     *
     * @dev sets is `_games` mapping by given `id` fields `user2` to caller address, `stage` to `Stage.ROUND1`, `turn`
     * to `TURN.USER1` and `throwing` to true
     *
     * @param `id` - game ID
     *
     * @emits `ChangeGameStage` event with game `id` and `Stage.ROUND1` stage
     */
    function enterGame(uint256 id) external {
        require(_games[id].user2 == address(0), "Bets: game already has second player");

        _games[id].user2 = msg.sender;
        _games[id].stage = Stage.ROUND1;
        _games[id].turn = Turn.USER1;
        _games[id].throwing = true;

        emit ChangeGameStage(id, Stage.ROUND1);
    }

    /*
     * Allows to throw dice for given game `id`
     *
     * Requirements:
     * - game should have `throwing` field value as true
     * - caller should be a `user1` or `user2` player in the game
     * - `turn` field in the game should not `Turn.NO_TURN` and should be the same value as users game status (`user1` or `user2`)
     *
     * @dev creates random digit from 1 to 6 and writes it to `results` mapping for callers address and given game `id`,
     * changes `throwing` field in `Game` instance to false
     *
     * @param `id` - game ID
     *
     * @emits `DiceThrown` with game `id` and caller address as args
     */
    function throwDice(uint256 id) external {
        require(_games[id].throwing, "Bets: not available");
        require(_isUsersGame(id, msg.sender), "Bets: not your game");
        require(_isUsersTurn(id, msg.sender), "Bets: not your turn");

        uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender))) % 5;

        if (_games[id].user1 == msg.sender) {
            _results[id].user1.push(number + 1);
        } else {
            _results[id].user2.push(number + 1);
        }

        _games[id].throwing = false;

        emit DiceThrown(id, msg.sender);
    }

    /*
     * Allows to see callers current results for given game `id`
     *
     * Requirements:
     * - caller should be a `user1` or `user2` player in the game
     *
     * @dev only returns result for callers address. Other player can also see only his results
     *
     * @param `id` - game ID
     *
     * @return uint256 slice of all game result for user
     */
    function seeResults(uint256 id) external view returns(uint256[] memory) {
        require(_isUsersGame(id, msg.sender), "Bets: not your game");

        if (_games[id].user1 == msg.sender) {
            return _results[id].user1;
        } else {
            return _results[id].user2;
        }
    }

    /*
     * Allows to make a bet for given game `id`
     *
     * Requirements:
     * - bet value should be more than `_minBet`
     * - games turn should not be `Turn.NO_TURN`
     * - caller should be a `user1` or `user2` player in the game
     * - should be players turn
     * - `throwing` game field value should be false
     * - bets for user1 and user should be equal
     *
     * @dev adds a bet to existing callers game bets, if it is a second turn in round, changes round to the next one,
     * if it is a final round, sets winner and transfers to him a game bank if not, sets `throwing` game field to true
     * and changes turn
     *
     * @param `id` - game ID
     *
     * @emits `ChangeGameStage` if it was changed, see {_nextStage}
     * @emits `BetMade` with game `id`, value and callers address as args
     */
    function bet(uint256 id) external payable {
        require(msg.value >= _minBet, "Bets: not enough funds for min bet");
        require(_games[id].turn != Turn.NO_TURN, "Bets: bets not available");
        require(_isUsersGame(id, msg.sender), "Bets: not your game");
        require(_isUsersTurn(id, msg.sender), "Bets: not your turn");
        require(!_games[id].throwing, "Bets: need to throw dice");
        require(_isBetEqual(id, msg.value, msg.sender), "Bets: bets not equal");

        _addBetToGame(id, msg.value, msg.sender);

        if (_games[id].betsUser1 == _games[id].betsUser2) {
            _nextStage(id);

            if (_games[id].stage == Stage.FINISHED) {
                _setWinnerAndTransferBank(id);
                _games[id].turn = Turn.NO_TURN;
            } else {
                _games[id].throwing = true;
            }
        } else {
            _games[id].throwing = true;
            _changeTurn(id);
        }

        emit BetMade(id, msg.value, msg.sender);
    }

    /*
     * Allows to give up game for given game `id`
     *
     * Requirements:
     * - games turn should not be `Turn.NO_TURN`
     * - caller should be a `user1` or `user2` player in the game
     * - should be players turn
     * - `throwing` game field value should be false
     *
     * @dev calculates value as a sum bets for users1 and user2 minus contract owners royalty and transfers it to
     * other user address. Also transfers royalty to owner and sets game `stage` to `Stage.FINISHED`, `turn` to
     * `Turn.NO_TURN` and throwing to false.
     *
     * @param `id` - game ID
     *
     * @emits `ChangeGameStage` with game `id` and `Stage.FINISHED` as args
     */
    function pass(uint256 id) external {
        require(_games[id].turn != Turn.NO_TURN, "Bets: bets not available");
        require(_isUsersGame(id, msg.sender), "Bets: not your game");
        require(_isUsersTurn(id, msg.sender), "Bets: not your turn");
        require(!_games[id].throwing, "Bets: need to throw dice");

        uint256 value = (_games[id].betsUser1 + _games[id].betsUser2) * (100 - _royalty) / 100;
        uint256 royalty = (_games[id].betsUser1 + _games[id].betsUser2) - value;

        payable(owner()).transfer(royalty);

        if (_games[id].user1 == msg.sender) {
            payable(_games[id].user2).transfer(value);
        } else {
            payable(_games[id].user1).transfer(value);
        }

        _games[id].stage = Stage.FINISHED;
        _games[id].turn = Turn.NO_TURN;
        _games[id].throwing = false;

        emit ChangeGameStage(id, Stage.FINISHED);
    }

    // Calculates total value as a sum of all users bets minus contract owner royalty and transfers value to the winner
    // 1/2 of value to each player if there is no winner. Also transfers royalty to contract owner.
    function _setWinnerAndTransferBank(uint256 id) internal {
        uint256 value = (_games[id].betsUser1 + _games[id].betsUser2) * (100 - _royalty) / 100;
        uint256 royalty = (_games[id].betsUser1 + _games[id].betsUser2) - value;

        payable(owner()).transfer(royalty);

        uint256 result1 = _getSumResultUser1(id);
        uint256 result2 = _getSumResultUser2(id);

        if (result1 > result2) {
            payable(_games[id].user1).transfer(value);
            _games[id].winner = _games[id].user1;
            return;
        }

        if (result2 > result1) {
            payable(_games[id].user2).transfer(value);
            _games[id].winner = _games[id].user2;
            return;
        }

        payable(_games[id].user1).transfer(value / 2);
        payable(_games[id].user2).transfer(value / 2);
    }

    // Returns sum of all users1 result
    function _getSumResultUser1(uint256 id) internal view returns(uint256) {
        uint256 result;

        for(uint256 i = 0; i < _results[id].user1.length; i++) {
            result += _results[id].user1[i];
        }

        return result;
    }

    // Returns sum of all users2 result
    function _getSumResultUser2(uint256 id) internal view returns(uint256) {
        uint256 result;

        for(uint256 i = 0; i < _results[id].user2.length; i++) {
            result += _results[id].user2[i];
        }

        return result;
    }

    // Changes game turn to opposite user
    function _changeTurn(uint256 id) internal {
        if (_games[id].turn == Turn.USER1) {
            _games[id].turn = Turn.USER2;
        } else {
            _games[id].turn = Turn.USER1;
        }
    }

    // Sets next stage in the game
    function _nextStage(uint256 id) internal {
        _games[id].stage = Stage(uint256(_games[id].stage) + 1);

        emit ChangeGameStage(id, _games[id].stage);
    }

    // Adds given `value` to `user` bets in given game `id`
    function _addBetToGame(uint256 id, uint256 value, address user) internal {
        if (_games[id].user1 == user) {
            _games[id].betsUser1 = _games[id].betsUser1 + value;
        } else {
            _games[id].betsUser2 = _games[id].betsUser2 + value;
        }
    }

    // Returns true if current bets are equal or true if current bets plus given `amount` for `user` bet are equal and
    // false if not
    function _isBetEqual(uint256 id, uint256 amount, address user) internal view returns(bool) {
        if (_games[id].betsUser1 == _games[id].betsUser2) {
            return true;
        } else {
            if (_games[id].user1 == user) {
                return _games[id].betsUser1 + amount == _games[id].betsUser2;
            } else {
                return _games[id].betsUser2 + amount == _games[id].betsUser1;
            }
        }
    }

    // Return true of `user` is in the game by given game `id` and it is his turn and false if not
    function _isUsersTurn(uint256 id, address user) internal view returns(bool) {
        if (_games[id].user1 == user && _games[id].turn == Turn.USER1) {
            return true;
        }

        if (_games[id].user2 == user && _games[id].turn == Turn.USER2) {
            return true;
        }

        return false;
    }

    // Returns true if `user` is a `user1` or `user2` in given game `id`
    function _isUsersGame(uint256 id, address user) internal view returns(bool) {
        return _games[id].user1 == user || _games[id].user2 == user;
    }

}