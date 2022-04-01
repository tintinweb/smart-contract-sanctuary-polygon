// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IToken.sol";
import "./interfaces/INFT.sol";

contract TicTacToken {
    event NewGame(
        address indexed playerX,
        address indexed playerO,
        uint256 gameId
    );
    event MarkSpace(
        address indexed player,
        uint256 indexed gameId,
        uint256 position,
        uint256 symbol
    );
    event Win(address indexed winner, uint256 gameId);

    struct Game {
        address playerX;
        address playerO;
        uint8 turns;
        uint16 playerXBitmap;
        uint16 playerOBitmap;
    }

    mapping(uint256 => Game) public games;
    mapping(uint256 => uint256) public gameIdByTokenId;
    mapping(address => uint256[]) public gamesByAddress;
    IToken public immutable token;
    INFT public immutable nft;

    uint256 internal constant X = 1;
    uint256 internal constant O = 2;
    uint256 internal constant POINTS_PER_WIN = 300 ether;
    uint256 internal nextGameId;
    mapping(address => uint256) internal winCountByAddress;
    mapping(address => uint256) internal pointCountByAddress;

    constructor(address _token, address _nft) {
        token = IToken(_token);
        nft = INFT(_nft);
    }

    modifier requirePlayers(uint256 gameId) {
        require(
            msg.sender == _game(gameId).playerX ||
                msg.sender == _game(gameId).playerO,
            "Must be authorized player"
        );
        _;
    }

    function newGame(address _playerX, address _playerO) external {
        require(_playerX != _playerO, "Invalid opponent");
        unchecked {
            nextGameId++;
        }
        uint256 id = nextGameId;
        games[id].playerX = _playerX;
        games[id].playerO = _playerO;

        gamesByAddress[_playerX].push(id);
        gamesByAddress[_playerO].push(id);
        emit NewGame(_playerX, _playerO, id);
        mintGameToken(_playerX, _playerO);
    }

    function getGamesByAddress(address playerAddress)
        external
        view
        returns (uint256[] memory)
    {
        return gamesByAddress[playerAddress];
    }

    function mintGameToken(address _playerX, address _playerO) internal {
        uint256 playerOToken = 2 * nextGameId;
        uint256 playerXToken = playerOToken - 1;
        gameIdByTokenId[playerOToken] = gameIdByTokenId[
            playerXToken
        ] = nextGameId;
        nft.mint(_playerO, playerOToken);
        nft.mint(_playerX, playerXToken);
    }

    function markSpace(
        uint256 gameId,
        uint256 i,
        uint256 symbol
    ) external requirePlayers(gameId) {
        require(_validSpace(i), "Invalid space");
        require(_validSymbol(symbol), "Invalid symbol");
        require(_validTurn(gameId, symbol), "Not your turn");
        require(_emptySpace(gameId, i), "Already marked");
        require(winner(gameId) == 0, "Game over");

        unchecked {
            _game(gameId).turns++;
        }
        _setSymbol(gameId, i, symbol);
        emit MarkSpace(msg.sender, gameId, i, symbol);

        uint256 winningSymbol = winner(gameId);
        if (winningSymbol != 0) {
            address winnerAddress = _getPlayerAddress(gameId, winningSymbol);
            _incrementWinCount(winnerAddress);
            _incrementPointCount(winnerAddress);
            emit Win(winnerAddress, gameId);
            token.mintTTT(winnerAddress, POINTS_PER_WIN);
        }
    }

    function board(uint256 gameId) external view returns (uint256[9] memory) {
        Game memory game = _game(gameId);
        uint256[9] memory boardArray;
        for (uint256 i = 0; i < 9; ) {
            if (_readBit(game.playerXBitmap, i) != 0) {
                boardArray[i] = X;
            }
            if (_readBit(game.playerOBitmap, i) != 0) {
                boardArray[i] = O;
            }
            unchecked {
                ++i;
            }
        }
        return boardArray;
    }

    function currentTurn(uint256 gameID) public view returns (uint256) {
        return (_game(gameID).turns % 2 == 0) ? X : O;
    }

    function winner(uint256 gameId) public view returns (uint256) {
        return _checkWins(gameId);
    }

    function winCount(address playerAddress) external view returns (uint256) {
        return winCountByAddress[playerAddress];
    }

    function pointCount(address playerAddress) external view returns (uint256) {
        return pointCountByAddress[playerAddress];
    }

    function _validSpace(uint256 i) internal pure returns (bool) {
        return i < 9;
    }

    function _validTurn(uint256 gameId, uint256 symbol)
        internal
        view
        returns (bool)
    {
        return currentTurn(gameId) == symbol;
    }

    function _readBit(uint16 bitMap, uint256 i) internal pure returns (uint16) {
        return bitMap & (uint16(1) << uint16(i));
    }

    function _setBit(uint16 bitMap, uint256 i) internal pure returns (uint16) {
        return bitMap | (uint16(1) << uint16(i));
    }

    function _setSymbol(
        uint256 gameId,
        uint256 i,
        uint256 symbol
    ) internal {
        Game storage game = _game(gameId);
        if (symbol == X) {
            game.playerXBitmap = _setBit(game.playerXBitmap, i);
        }
        if (symbol == O) {
            game.playerOBitmap = _setBit(game.playerOBitmap, i);
        }
    }

    function _emptySpace(uint256 gameId, uint256 i)
        internal
        view
        returns (bool)
    {
        Game memory game = _game(gameId);
        return _readBit(game.playerXBitmap | game.playerOBitmap, i) == 0;
    }

    function _validSymbol(uint256 symbol) internal pure returns (bool) {
        return symbol == X || symbol == O;
    }

    function _checkWins(uint256 gameId) internal view returns (uint256) {
        uint16[8] memory wins = [7, 56, 448, 292, 146, 73, 273, 84];
        Game memory game = _game(gameId);
        uint16 playerXBitmap = game.playerXBitmap;
        uint16 playerOBitmap = game.playerOBitmap;
        for (uint256 i = 0; i < wins.length; ) {
            if (wins[i] == (playerXBitmap & wins[i])) {
                return X;
            } else if (wins[i] == (playerOBitmap & wins[i])) {
                return O;
            }
            unchecked {
                ++i;
            }
        }
        return 0;
    }

    function _incrementWinCount(address playerAddress) private {
        unchecked {
            winCountByAddress[playerAddress]++;
        }
    }

    function _incrementPointCount(address playerAddress) private {
        unchecked {
            pointCountByAddress[playerAddress] += POINTS_PER_WIN;
        }
    }

    function _getPlayerAddress(uint256 gameId, uint256 playerSymbol)
        private
        view
        returns (address)
    {
        if (playerSymbol == X) {
            return _game(gameId).playerX;
        } else if (playerSymbol == O) {
            return _game(gameId).playerO;
        } else {
            return address(0);
        }
    }

    function _game(uint256 gameId) private view returns (Game storage) {
        return games[gameId];
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
    function mintTTT(address to, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFT is IERC721 {
    function mint(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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