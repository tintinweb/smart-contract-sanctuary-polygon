// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBattleToken.sol";
import "./interfaces/IBattleDice.sol";

enum PieceType {
    PLAYER,
    WEAPON
}

struct Piece {
    uint32 id; // tokenId of player, or ID of weapon
    uint32 data; // id of weapon if held by player
    uint8 data2; // kills
    uint16 game; // game that this piece belongs to
    uint16 lastMove; // last move if it a player
    PieceType pieceType; // PLAYER, WEAPON
    int8 x; // x pos
    int8 y; // y pos
    int8[7] stats; // array of weapon or player stats
}

struct Game {
    uint32 startTime; // timestamp of beginning of game
    uint16 lastBattle; // turn number of the last battle
    uint8 players; // number of players
    uint8 remaining; // number of remaining players
    mapping(int8 => mapping(int8 => uint32)) board; // board game
}

uint256 constant FEE_ENTRY = 0 ether;
uint256 constant STALEMATE_TURNS = 6;
uint256 constant PERCENT_OWNER = 51;
uint32 constant TOKEN_MAX = 800;

/// @author AnAllergyToAnalogy
/// @title Big Head Club Doomies Main Contract
/// @notice Main Doomies contract, it has all the externally-facing battle and mint functions (not ERC721 stuff tho)
contract Battle is Ownable {

    event NewGame(uint16 indexed game);

    event Move(
        uint32 indexed tokenId,
        int8 x,
        int8 y,
        uint16 indexed game,
        uint16 turn,
        uint32 data
    );
    event BattleLog(
        uint32 indexed player1,
        uint32 indexed player2,
        int256[8] rolls1,
        int256[8] rolls2,
        uint32 winner,
        uint16 indexed game,
        uint16 turn
    );
    event Mint(
        uint32 indexed tokenId,
        int8[7] stats
    );
    event NewWeapon(
        uint32 indexed pieceId,
        int8[7] stats,
        uint16 indexed game
    );
    event WithdrawWinnings(
        uint32 tokenId,
        uint16 indexed game,
        uint256 amount
    );

    uint256 public turnTime = 1 days;
    address token;
    address dice;
    uint32 ownerWithdrawn;
    uint32 public lastTokenId;
    uint32 lastWeaponId = TOKEN_MAX;

    //This exposes a public method like this:
    // function game() public view returns(uint);
    //  returns the current game number
    uint16 public game;

    //This exposes a public method like this:
    // function games(uint _game) public view returns(Game);
    //  it will return the Game struct for the given game number, not including the board
    mapping(uint256 => Game) public games;

    //This exposes a public method like this:
    // function pieces(uint _pieceId) public view returns(Piece);
    //  it will return the Piece struct for the given id, not including the stats array
    mapping(uint32 => Piece) public pieces;




    constructor(address _token, address _dice) {
        token = _token;
        dice = _dice;
    }

    // Enters token into game
    //  takes the following params:
    //      tokenId: id of token
    //      startX:  x coord to start form
    //      startY:  y coord to start form

    //  player must own the token
    //  token can't have been entered into this or a previous game
    //  game has to be active,
    //  has to be entry time of the game (ie, turn = 0)
    //  has to be on the edge of map, only on every second space
    //  has to be on an empty tile

    //Emits the following events
    // from main contract
    //   event Move(tokenId, startX, startY, game number, turn number, type(uint32).max - 1);
    //    you can infer that a Move event is an 'enter game' event by either lookin at turn number == 0
    //                                                          or the data property = type(uint32).max - 1
    function enterGame(
        uint32 tokenId,
        int8 startX,
        int8 startY
    ) public {
        require(IBattleToken(token).ownerOf(tokenId) == msg.sender, "owner");

        require(pieces[tokenId].game == 0, "entered");

        require(gameIsActive(), "game not active");
        require(turnNumber() == 0, "not entry time");

        require(
            startX == 0 || startY == 0 || startX == 8 || startY == 8,
            "edge"
        );
        require(startX % 2 == 0 && startY % 2 == 0, "position");
        require(games[game].board[startX][startY] == 0, "occupied");

        games[game].board[startX][startY] = tokenId;
        ++games[game].players;
        ++games[game].remaining;

        pieces[tokenId].game = game;
        pieces[tokenId].x = startX;
        pieces[tokenId].y = startY;

        emit Move(
            tokenId,
            startX,
            startY,
            game,
            turnNumber(),
            type(uint32).max - 1
        );

        if (games[game].players == 16) {
            games[game].startTime = uint32(block.timestamp - turnTime);
        }
    }

    //Mints token,
    // Requires msg value of FEE_ENTRY
    //  will fail if token max has been reached
    //  this rolls the stats of the token

    //Emits the following events
    // from Token contract:
    //      Transfer( 0x0, msg.sender, tokenId)
    // from main contract
    //      event Mint(tokenId, int8[7] stats );
    function mint() public payable {
        require(gasleft() > 200000, "gas failsafe");

        require(msg.sender == tx.origin, "no contracts");
        require(msg.value == FEE_ENTRY, "FEE_ENTRY");
        require(lastTokenId < TOKEN_MAX, "supply limit");

        IBattleToken(token).mint(msg.sender, ++lastTokenId);

        pieces[lastTokenId] = Piece(
            lastTokenId,
            0,
            0,
            0,
            0,
            PieceType.PLAYER,
            0,
            0,
            IBattleDice(dice).rollPlayerStats()
        );

        emit Mint(lastTokenId, pieces[lastTokenId].stats);
    }

    //Moves a token
    //  takes the following params:
    //      tokenId: id of the token
    //      dx: how far to move in x direction
    //      dy: how far to move in y direction

    //  player must own the token
    //  game must be active
    //  can't be in entry time (ie turnNumber = 0)
    //  can't have moved this turn
    //  can't do it if token has died
    //  can't do it if not in this game
    //  can't do it if sender is a contract
    //  can't do it trying to move more than 1 square away
    //  can't not move at all in tx
    //  can't move off map

    //Emits the following events
    // from main contract

    // if the player moves to an empty square, a weapon square, or an occupied square and then succeeds at the battle:
    //  emit Move(tokenId, toX, toY, game number, turn number, 0);

    // if there is a battle, it will emit the following event BEFORE the Move event
    //  emit BattleLog(player id, opponent id, player's rolls,  opponent's rolls, id of victor, turn number, game number);
    //   where rolls are arrays of the dice rolls for each player for each stat.
    //      in the case where it's a draw, the winner will have a 1 in their final slot. otherwise that's unused.

    function move(
        uint32 tokenId,
        int8 dx,
        int8 dy
    ) public {
        require(gasleft() > 200000, "gas failsafe");
        require(IBattleToken(token).ownerOf(tokenId) == msg.sender, "owner");

        require(gameIsActive(), "game not active");
        require(turnNumber() != 0, "still entry time");
        require(pieces[tokenId].lastMove < turnNumber(), "already moved");
        require(pieces[tokenId].game == game, "not in game");
        require(pieces[tokenId].data != type(uint32).max, "token dead");

        require(msg.sender == tx.origin, "no contracts");
        require(dx >= -1 && dx <= 1 && dy >= -1 && dy <= 1, "range");
        require(!(dx == 0 && dy == 0), "stationary");

        Piece memory piece = pieces[tokenId];

        int8 toX = piece.x + dx;
        int8 toY = piece.y + dy;

        require(toX >= 0 && toX <= 8 && toY >= 0 && toY <= 8, "bounds");

        delete games[game].board[piece.x][piece.y];

        uint32 target = games[game].board[toX][toY];

        if (target == 0) {
            //space empty, Just move
            games[game].board[toX][toY] = tokenId;
            pieces[tokenId].x = toX;
            pieces[tokenId].y = toY;
            pieces[tokenId].lastMove = turnNumber();

            emit Move(tokenId, toX, toY, game, turnNumber(), 0);
        } else if (pieces[target].pieceType == PieceType.WEAPON) {
            //Weapon, pickup
            if (piece.data != 0) {
                //kill the current weapon
                delete pieces[piece.data];
            }
            pieces[tokenId].data = target;

            games[game].board[toX][toY] = tokenId;
            pieces[tokenId].x = toX;
            pieces[tokenId].y = toY;
            pieces[tokenId].lastMove = turnNumber();

            emit Move(tokenId, toX, toY, game, turnNumber(), target);
        } else {
            //Player, battle

            games[game].lastBattle = turnNumber();

            uint32 victor = _battle(tokenId, target);

            if (tokenId == victor) {
                //player wins

                //flag enemy token as dead
                pieces[target].data = type(uint32).max;

                games[game].board[toX][toY] = tokenId;
                pieces[tokenId].x = toX;
                pieces[tokenId].y = toY;
                pieces[tokenId].lastMove = turnNumber();

                ++pieces[tokenId].data2;

                emit Move(tokenId, toX, toY, game, turnNumber(), 0);
            } else {
                //enemy wins
                pieces[tokenId].data = type(uint32).max;

                ++pieces[target].data2;
            }
            --games[game].remaining;
        }
    }

    function withdrawWinnings(uint32 tokenId) public {
        require(IBattleToken(token).ownerOf(tokenId) == msg.sender, "owner");

        Piece memory piece = pieces[tokenId];

        require(piece.game < game || !gameIsActive(), "not yet winner");
        require(pieces[tokenId].data < type(uint32).max, "no winnings");

        uint256 toWithdraw;

        if (games[piece.game].remaining == 1) {
            //Single Winner
            toWithdraw =
            (games[piece.game].players *
            FEE_ENTRY *
            (100 - PERCENT_OWNER)) /
            100;
        } else {
            uint256 eliminated = games[piece.game].players -
            games[piece.game].remaining;
            if (eliminated > 0) {
                toWithdraw =
                (((uint256(piece.data2) *
                games[piece.game].players *
                FEE_ENTRY) / eliminated) * (100 - PERCENT_OWNER)) /
                100;
            } else {
                toWithdraw =
                (games[piece.game].players *
                FEE_ENTRY *
                (100 - PERCENT_OWNER)) /
                100;
            }
        }

        pieces[tokenId].data = type(uint32).max;

        emit WithdrawWinnings(tokenId, piece.game, toWithdraw);

        payable(msg.sender).transfer(toWithdraw);
    }

    function ownerWithdraw() public onlyOwner {
        require(ownerWithdrawn < lastTokenId, "withdrawn");

        uint256 toWithdraw = (uint256(lastTokenId - ownerWithdrawn) *
        FEE_ENTRY *
        PERCENT_OWNER) / 100;

        ownerWithdrawn = lastTokenId;

        payable(msg.sender).transfer(toWithdraw);
    }

    function updateTurnTime(uint256 _turnTime) public onlyOwner {
        require(!gameIsActive(), "game active");
        turnTime = _turnTime;
    }

    // call this to start the game
    //  can't be called by non contract owner
    //  cant be called if game in progress
    function startGame() public {
        require(gasleft() > 1250000, "gas failsafe");

        require(!gameIsActive(), "game active");
        game++;

        games[game].startTime = uint32(block.timestamp);

        for (int8 x = 3; x <= 5; x++) {
            for (int8 y = 3; y <= 5; y++) {
                if (x == 4 && y == 4) continue;

                games[game].board[x][y] = ++lastWeaponId;
                games[game].lastBattle = 1;

                pieces[lastWeaponId] = Piece(
                    lastWeaponId,
                    0,
                    0,
                    game,
                    0,
                    PieceType.WEAPON,
                    x,
                    y,
                    IBattleDice(dice).rollWeaponStats(lastWeaponId)
                );

                emit NewWeapon(lastWeaponId, pieces[lastWeaponId].stats, game);
            }
        }
        emit NewGame(game);
    }

    // returns true if game is currently active
    function gameIsActive() public view returns (bool) {
        return
        game != 0 &&
        (turnNumber() == 0 ||
        !(turnNumber() > games[game].lastBattle + STALEMATE_TURNS ||
        games[game].remaining < 2));
    }

    // returns a 9x9 array of current board, with ids of pieces
    function getTile(int8 x, int8 y) public view returns (uint32) {
        return games[game].board[x][y];

    }

    // return stats array of a given piece
    function getStats(uint32 pieceId) public view returns (int8[7] memory) {
        return pieces[pieceId].stats;
    }

    // returns true if a token hasnt been put in a game
    function tokenIsUnused(uint32 tokenId) public view returns (bool) {
        return pieces[tokenId].game == 0;
    }

    function _battle(uint32 player1, uint32 player2) internal returns (uint32) {
        (
            uint32 victor,
            int256[8] memory rolls1,
            int256[8] memory rolls2
        ) = IBattleDice(dice).battle(
                player1,
                player2,
                pieces[player1].stats,
                pieces[pieces[player1].data].stats,
                pieces[player2].stats,
                pieces[pieces[player2].data].stats
            );
        emit BattleLog(
            player1,
            player2,
            rolls1,
            rolls2,
            victor,
            turnNumber(),
            game
        );

        return victor;
    }

    // returns the current turn number of the current game
    function turnNumber() private view returns (uint16) {
        return
            uint16(
                (block.timestamp - uint256(games[game].startTime)) / turnTime
            );
    }


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBattleDice {
    function rollPlayerStats() external view returns (int8[7] memory stats);

    function rollWeaponStats(uint32 salt)
        external
        view
        returns (int8[7] memory stats);

    function battle(
        uint32 player1,
        uint32 player2,
        int8[7] memory stats1,
        int8[7] memory weapon1,
        int8[7] memory stats2,
        int8[7] memory weapon2
    )
        external
        view
        returns (
            uint32 victor,
            int256[8] memory rolls1,
            int256[8] memory rolls2
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBattleToken {
    function mint(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
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