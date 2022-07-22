// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IGame.sol";

contract TicTacToken is IGame {
    uint256 public constant EMPTY = 0;
    uint256 public constant X = 1;
    uint256 public constant O = 2;
    uint256 internal constant POINTS_PER_WIN = 5;

    IToken public immutable token;
    INFT public immutable nft;

    uint256 internal nextGameId;

    struct Game {
        address playerX;
        address playerO;
        uint256 prevMove;
        uint16 playerXBitmap;
        uint16 playerOBitmap;
    }

    mapping(uint256 => Game) public games;
    mapping(address => uint256) public wins;
    mapping(address => uint256[]) internal _gamesByPlayer;

    constructor(address _token, address _nft) {
        require(_token != address(0), "Zero token");
        require(_nft != address(0), "Zero NFT");
        token = IToken(_token);
        nft = INFT(_nft);
    }

    modifier isPlayer(uint256 id) {
        require(
            msg.sender == games[id].playerX || msg.sender == games[id].playerO,
            "Unauthorized"
        );
        _;
    }

    function newGame(address playerX, address playerO) public {
        require(playerX != address(0) && playerO != address(0), "Zero player");
        require(playerX != playerO, "Cannot play self");

        uint256 id = ++nextGameId;
        games[id].playerX = playerX;
        games[id].playerO = playerO;
        _gamesByPlayer[playerX].push(id);
        _gamesByPlayer[playerO].push(id);
        (uint256 xTokenId, uint256 oTokenId) = tokenIds(id);

        nft.mint(playerX, xTokenId);
        nft.mint(playerO, oTokenId);
    }

    function gamesByPlayer(address player)
        public
        view
        returns (uint256[] memory)
    {
        return _gamesByPlayer[player];
    }

    function tokenIds(uint256 gameId) public pure returns (uint256, uint256) {
        return (2 * gameId - 1, 2 * gameId);
    }

    function markSpace(uint256 id, uint256 space) public isPlayer(id) {
        require(_validSpace(space), "Invalid space");
        require(_emptySpace(id, space), "Already occupied");
        require(_validTurn(id, _getMarker(id)), "Not your turn");
        require(winner(id) == 0, "Game over");

        _setSymbol(id, space, _getMarker(id));
        games[id].prevMove = _getMarker(id);

        uint256 _winner = winner(id);
        if (winner(id) != 0) {
            address winnerAddress = (_winner == X)
                ? games[id].playerX
                : games[id].playerO;
            wins[winnerAddress]++;
            token.mint(winnerAddress, POINTS_PER_WIN * 1 ether);
        }
    }

    function _setSymbol(
        uint256 gameId,
        uint256 i,
        uint256 symbol
    ) internal {
        Game storage game = games[gameId];
        if (symbol == X) {
            game.playerXBitmap = _setBit(game.playerXBitmap, i);
        }
        if (symbol == O) {
            game.playerOBitmap = _setBit(game.playerOBitmap, i);
        }
    }

    function _readBit(uint16 bitMap, uint256 i) internal pure returns (uint16) {
        return bitMap & (uint16(1) << uint16(i));
    }

    function _setBit(uint16 bitMap, uint256 i) internal pure returns (uint16) {
        return bitMap | (uint16(1) << uint16(i));
    }

    function getBoard(uint256 id) public view returns (uint256[9] memory) {
        Game memory game = games[id];
        uint256[9] memory boardArray;
        for (uint256 i = 0; i < 9; ++i) {
            if (_readBit(game.playerXBitmap, i) != 0) {
                boardArray[i] = X;
            }
            if (_readBit(game.playerOBitmap, i) != 0) {
                boardArray[i] = O;
            }
        }
        return boardArray;
    }

    function winner(uint256 id) public view returns (uint256) {
        uint16[8] memory WIN_ENCODINGS = [7, 56, 448, 292, 146, 73, 273, 84];
        Game memory game = games[id];
        uint16 playerXBitmap = game.playerXBitmap;
        uint16 playerOBitmap = game.playerOBitmap;
        for (uint256 i = 0; i < WIN_ENCODINGS.length; ++i) {
            if (WIN_ENCODINGS[i] == (playerXBitmap & WIN_ENCODINGS[i])) {
                return X;
            } else if (WIN_ENCODINGS[i] == (playerOBitmap & WIN_ENCODINGS[i])) {
                return O;
            }
        }
        return 0;
    }

    function _getMarker(uint256 id) internal view returns (uint256) {
        if (msg.sender == games[id].playerX) return X;
        if (msg.sender == games[id].playerO) return O;
        return 0;
    }

    function _validSpace(uint256 space) internal pure returns (bool) {
        return space < 9;
    }

    function _emptySpace(uint256 id, uint256 space)
        internal
        view
        returns (bool)
    {
        Game memory game = games[id];
        return _readBit(game.playerXBitmap | game.playerOBitmap, space) == 0;
    }

    function _validTurn(uint256 id, uint256 nextMove)
        internal
        view
        returns (bool)
    {
        return nextMove != games[id].prevMove;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface INFT is IERC721 {
    function mint(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

interface IGame {
    function getBoard(uint256 id) external view returns (uint256[9] memory);
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