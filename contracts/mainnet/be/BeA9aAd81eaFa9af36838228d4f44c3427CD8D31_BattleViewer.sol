// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Battle.sol";
import "./BattleToken.sol";

/// @author AnAllergyToAnalogy
/// @title Big Head Club Doomies Site Viewer Contract
/// @notice Just some read only stuff for the site
contract BattleViewer {
    constructor(address _battle, address _token) {
        battle = Battle(_battle);
        token = BattleToken(_token);
    }

    Battle battle;
    BattleToken token;

    // returns time in seconds until current turn ends
    function getTimeTilTurnEnds() public view returns (uint256) {
        uint16 game = battle.game();

        (
            uint32 startTime,
            uint16 lastBattle,
            uint8 players,
            uint8 remaining
        ) = battle.games(game);

        lastBattle;
        players;
        remaining;

        uint256 turnTime = battle.turnTime();

        return turnTime - ((block.timestamp - uint256(startTime)) % turnTime);
    }

    //returns full state of the current game
    function getCurrentGameState()
        public
        view
        returns (
            uint32[9][9] memory _board,
            uint16 game,
            uint16 turn,
            bool gameIsActive,
            uint256 timeTilTurnEnds,
            uint32 startTime,
            uint16 lastBattle,
            uint8 players,
            uint8 remaining
        )
    {
        game = battle.game();

        (startTime, lastBattle, players, remaining) = battle.games(game);

        uint256 turnTime = battle.turnTime();

        timeTilTurnEnds =
            turnTime -
            ((block.timestamp - uint256(startTime)) % turnTime);

        return (
            getCurrentBoard(),
            game,
            turnNumber(),
            battle.gameIsActive(),
            timeTilTurnEnds,
            startTime,
            lastBattle,
            players,
            remaining
        );
    }

    // returns a 9x9 array of current board, with ids of pieces
    function getCurrentBoard()
        public
        view
        returns (uint32[9][9] memory _board)
    {
        for (uint256 x = 0; x < 9; x++) {
            for (uint256 y = 0; y < 9; y++) {
                _board[x][y] = battle.getTile(int8(int256(x)), int8(int256(y)));
            }
        }

        return _board;
    }

    // pass an array of pieceIds, it will return an array of Pieces, including stats
    function getPieces(uint32[] calldata pieceIds)
        public
        view
        returns (Piece[] memory pieces)
    {
        pieces = new Piece[](pieceIds.length);

        for (uint256 i = 0; i < pieceIds.length; i++) {
            (
                uint32 id,
                uint32 data,
                uint8 data2,
                uint16 game,
                uint16 lastMove,
                PieceType pieceType,
                int8 x,
                int8 y
            ) = battle.pieces(pieceIds[i]);

            pieces[i] = Piece(
                id,
                data,
                data2,
                game,
                lastMove,
                pieceType,
                x,
                y,
                battle.getStats(pieceIds[i])
            );
        }

        return pieces;
    }

    //returns two arrays of tokenIds of your tokens, one of those which have been used, another of those which havent
    //note you have to pass startId, and limit. for this contract it should be fine to just us 1 and whatever the max
    //  number of tokens are
    // also note, the lengths of the arrays will be the users balance. meaning there will be a bunch of entries with 0
    //  in them at the end of the arrays. ignore these values
    function getMyTokens(uint256 startId, uint256 limit)
        public
        view
        returns (uint256[] memory unused, uint256[] memory used)
    {
        uint256 _totalSupply = battle.lastTokenId();
        uint256 _myBalance = token.balanceOf(msg.sender);

        uint256 _maxId = _totalSupply;

        if (_totalSupply == 0 || _myBalance == 0) {
            uint256[] memory _none;
            return (_none, _none);
        }

        require(startId < _maxId + 1, "Invalid start ID");
        uint256 sampleSize = _maxId - startId + 1;

        if (limit != 0 && sampleSize > limit) {
            sampleSize = limit;
        }

        unused = new uint256[](_myBalance);
        used = new uint256[](_myBalance);

        uint32 _tokenId = uint32(startId);
        uint256 unusedFound = 0;
        uint256 usedFound = 0;

        for (uint256 i = 0; i < sampleSize; i++) {
            try token.ownerOf(_tokenId) returns (address owner) {
                if (msg.sender == owner) {
                    if (battle.tokenIsUnused(_tokenId)) {
                        unused[unusedFound++] = _tokenId;
                    } else {
                        used[usedFound++] = _tokenId;
                    }
                }
            } catch {}
            _tokenId++;
        }
        return (unused, used);
    }

    function getMetadata(uint32 tokenId)
        public
        view
        returns (int8[7] memory playerStats, int8[7] memory weaponStats)
    {
        token.ownerOf(tokenId);
        (
            uint32 id,
            uint32 data,
            uint8 data2,
            uint16 game,
            uint16 lastMove,
            PieceType pieceType,
            int8 x,
            int8 y
        ) = battle.pieces(tokenId);

        id;data2;game;lastMove;pieceType;x;y;


        if (data == 0) {
            return (battle.getStats(tokenId), weaponStats);
        } else {
            return (battle.getStats(tokenId), battle.getStats(data));
        }
    }

    // returns the current turn number of the current game
    function turnNumber() internal view returns (uint16) {
        (
        uint32 startTime,
        uint16 lastBattle,
        uint8 players,
        uint8 remaining
        ) = battle.games(battle.game());
        remaining;lastBattle;players;

        uint256 turnTime = battle.turnTime();
        return uint16((block.timestamp - uint256(startTime)) / turnTime);
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @author AnAllergyToAnalogy
/// @title Big Head Club Doomies Token Contract
/// @notice Handles all the ERC721 token stuff of the Doomies tokens.
/// @dev The actual token address will point at this contract. Mints can only be done via main contract.
contract BattleToken is ERC721, Ownable {
    using Strings for uint256;

    address battle;
    string __uriBase;
    string __uriSuffix;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uriBase,
        string memory _uriSuffix
    ) ERC721(_name, _symbol) {
        __uriBase = _uriBase;
        __uriSuffix = _uriSuffix;
    }

    //Admin
    function setUriComponents(
        string calldata _newBase,
        string calldata _newSuffix
    ) public onlyOwner {
        __uriBase = _newBase;
        __uriSuffix = _newSuffix;
    }

    function setBattle(address _battle) public {
        require(battle == address(0), "already set");
        battle = _battle;
    }

    function mint(address to, uint256 tokenId) public {
        require(msg.sender == battle, "permission");
        _mint(to, tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "exists");
        return
            string(
                abi.encodePacked(__uriBase, _tokenId.toString(), __uriSuffix)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}