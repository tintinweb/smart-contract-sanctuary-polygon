// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface INFT is IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract TicTacToken {
    uint256 public constant EMPTY = 0;
    uint256 public constant X = 1;
    uint256 public constant O = 2;
    uint256 internal constant POINTS_PER_WIN = 5;

    address public owner;
    IToken public token;
    INFT public nft;
    uint256 internal nextGameId;

    struct Game {
        address playerX;
        address playerO;
        uint256 prevMove;
        uint256[9] board;
    }

    mapping(uint256 => Game) public games;
    mapping(address => uint256) public wins;

    constructor(
        address _owner,
        address _token,
        address _nft
    ) {
        owner = _owner;
        token = IToken(_token);
        nft = INFT(_nft);
    }

    modifier isPlayer() {
        require(
            msg.sender == games[0].playerX || msg.sender == games[0].playerO,
            "Unauthorized"
        );
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    function newGame(address playerX, address playerO) public {
        games[nextGameId].playerX = playerX;
        games[nextGameId].playerO = playerO;
        nextGameId++;

        (uint256 xTokenId, uint256 oTokenId) = tokenIds(nextGameId);
        nft.mint(playerX, xTokenId);
        nft.mint(playerO, oTokenId);
    }

    function tokenIds(uint256 gameId) public pure returns (uint256, uint256) {
        return (2 * gameId - 1, 2 * gameId);
    }

    function markSpace(uint256 id, uint256 space) public isPlayer {
        require(_validSpace(space), "Invalid space");
        require(_emptySpace(id, space), "Space already occupied");
        require(
            _validTurn(id, _getMarker(id)),
            "Turns should alternate between X and O"
        );

        games[id].board[space] = _getMarker(id);
        games[id].prevMove = _getMarker(id);

        uint256 _winner = winner(id);
        if (_winner != 0) {
            address winnerAddress = (_winner == X)
                ? games[id].playerX
                : games[id].playerO;
            wins[winnerAddress]++;
            token.mint(winnerAddress, POINTS_PER_WIN * 1 ether);
        }
    }

    function resetBoard(uint256 id) public isOwner {
        delete games[id].board;
    }

    function getBoard(uint256 id) public view returns (uint256[9] memory) {
        return games[id].board;
    }

    function winner(uint256 id) public view returns (uint256) {
        uint256[8] memory potentialWins = [
            _rowWin(id, 0),
            _rowWin(id, 1),
            _rowWin(id, 2),
            _colWin(id, 0),
            _colWin(id, 1),
            _colWin(id, 2),
            _diagWin(id),
            _antiDiagWin(id)
        ];
        for (uint256 i; i < potentialWins.length; i++) {
            if (potentialWins[i] != 0) {
                return potentialWins[i];
            }
        }
        return 0;
    }

    function _rowWin(uint256 id, uint256 row) internal view returns (uint256) {
        uint256 idx = row * 3;
        uint256 product = games[id].board[idx] *
            games[id].board[idx + 1] *
            games[id].board[idx + 2];
        return _checkWin(product);
    }

    function _colWin(uint256 id, uint256 col) internal view returns (uint256) {
        uint256 product = games[id].board[col] *
            games[id].board[col + 3] *
            games[id].board[col + 6];
        return _checkWin(product);
    }

    function _diagWin(uint256 id) internal view returns (uint256) {
        uint256 product = games[id].board[0] *
            games[id].board[4] *
            games[id].board[8];
        return _checkWin(product);
    }

    function _antiDiagWin(uint256 id) internal view returns (uint256) {
        uint256 product = games[id].board[2] *
            games[id].board[4] *
            games[id].board[6];
        return _checkWin(product);
    }

    function _checkWin(uint256 product) internal pure returns (uint256) {
        if (product == 8) {
            return O;
        }
        if (product == 1) {
            return X;
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

    function _validMarker(uint256 marker) internal pure returns (bool) {
        return marker == X || marker == O;
    }

    function _emptySpace(uint256 id, uint256 space)
        internal
        view
        returns (bool)
    {
        return games[id].board[space] == EMPTY;
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