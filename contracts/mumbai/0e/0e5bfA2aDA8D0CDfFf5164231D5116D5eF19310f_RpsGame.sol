// SPDX-License-Identifier: None
pragma solidity >=0.8.17;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RpsGame is Ownable, ReentrancyGuard {
    uint16 public cutPercentage;
    uint16 public immutable maxCutPercentage;

    event GameCreated(uint256 indexed gameId, uint256 value);
    event GameWon(
        uint256 indexed gameId,
        address indexed winner,
        Move indexed move,
        uint256 payout
    );
    event GameDrew(uint256 indexed gameId);

    enum Move {
        Rock,
        Paper,
        Scissors
    }

    enum Result {
        CreatorWon,
        OpponentWon,
        Draw
    }

    struct Game {
        address creator;
        address opponent;
        uint256 value;
        bool isOver;
    }

    Game[] public games;
    mapping(uint256 => Move) private _gameToCreatorMove;
    mapping(uint256 => Move) private _gameToOpponentMove;

    constructor(uint16 _maxCutPercentage, uint16 _cutPercentage) {
        maxCutPercentage = _maxCutPercentage;
        cutPercentage = _cutPercentage;
    }

    function createGame(Move move)
        public
        payable
        nonReentrant
        returns (uint256 gameId)
    {
        games.push(Game(msg.sender, address(0), msg.value, false));
        gameId = games.length - 1;
        _gameToCreatorMove[gameId] = move;
        emit GameCreated(gameId, msg.value);
    }

    function joinGame(uint256 gameId, Move move) public payable nonReentrant {
        Game storage game = games[gameId];
        require(msg.value == game.value, "Game value must match.");
        require(!game.isOver, "Game should not be over.");
        require(
            game.opponent == address(0),
            "Game should not have an opponent set."
        );

        game.opponent = msg.sender;
        game.isOver = true;
        _gameToOpponentMove[gameId] = move;

        _settle(gameId);
    }

    // Internal logics
    function _settle(uint256 gameId) internal {
        Game memory game = games[gameId];
        Move creatorMove = _gameToCreatorMove[gameId];
        Move opponentMove = _gameToOpponentMove[gameId];
        Result result = _calculateResult(creatorMove, opponentMove);

        uint256 totalValue = game.value * 2;

        if (result == Result.CreatorWon) {
            _payout(game.creator, totalValue);
            emit GameWon(gameId, game.creator, creatorMove, totalValue);
        } else if (result == Result.OpponentWon) {
            _payout(game.opponent, totalValue);
            emit GameWon(gameId, game.opponent, opponentMove, totalValue);
        } else {
            _payout(game.creator, game.value);
            _payout(game.opponent, game.value);
            emit GameDrew(gameId);
        }
    }

    function _payout(address to, uint256 value) internal {
        uint256 cut = _getCut(value);
        uint256 payout = value - cut;
        (bool cutSuccess, ) = owner().call{value: cut}("");
        require(cutSuccess, "Failed to transfer the cut.");
        (bool payoutSuccess, ) = to.call{value: payout}("");
        require(payoutSuccess, "Failed to transfer the payout.");
    }

    function _calculateResult(Move creatorMove, Move opponentMove)
        internal
        pure
        returns (Result)
    {
        if (creatorMove == opponentMove) {
            return Result.Draw;
        } else if (creatorMove == Move.Rock && opponentMove == Move.Scissors) {
            return Result.CreatorWon;
        } else if (creatorMove == Move.Paper && opponentMove == Move.Rock) {
            return Result.CreatorWon;
        } else if (creatorMove == Move.Scissors && opponentMove == Move.Paper) {
            return Result.CreatorWon;
        } else {
            return Result.OpponentWon;
        }
    }

    function _getCut(uint256 _value) internal view returns (uint256) {
        return (_value * cutPercentage) / 100;
    }

    // Only Onwers
    function setCutPercentage(uint16 _cutPercentage) public onlyOwner {
        require(
            _cutPercentage <= maxCutPercentage,
            "Cut percentage cannot exceed the maxCutPercentage"
        );
        cutPercentage = _cutPercentage;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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