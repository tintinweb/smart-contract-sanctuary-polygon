// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../IERC721GAME.sol";

contract Slayer {
    IERC721GAME public immutable slayers;

    address private immutable _GameMaster;

    struct Stats {
        uint8 lvl;
        uint64 intellect;
        uint64 strength;
        uint64 agility;
    }

    mapping(uint => Stats) private _tokenStats;
    mapping(uint => bool) private _onGrind;
    mapping(uint => uint) private _lvlPoints;
    mapping(address => bool) private _isGame; // add GrindZone

    constructor(address _slayers) {
        slayers = IERC721GAME(_slayers);
        _GameMaster = msg.sender;
    }

    modifier onlyOperator(uint _id) {
        address _operator = slayers.getOperator(_id);
        require(_operator == msg.sender);
        _;
    }

    modifier onlyGame {
        require(_isGame[msg.sender] == true);
        _;
    }

    modifier onlyGM {
        require(_GameMaster == msg.sender);
        _;
    }

    // GRIND FUNCTIONS

    function onGrind(uint _id) external onlyGame {
        _onGrind[_id] = true;
    }

    function offGrind(uint _id) external onlyGame {
        _onGrind[_id] = false;
    }

    // STATS FUNCTIONS

    function lvlUp(uint _id) external onlyGame {
        Stats storage stat = _tokenStats[_id];
        require(stat.lvl < 85);
        _lvlPoints[_id]++;
        stat.lvl++;
        stat.intellect++;
        stat.strength++;
        stat.intellect++;
    }

    function upgradeIntellect(uint _id) external onlyOperator(_id) {
        require(_lvlPoints[_id] > 0);
        Stats storage stat = _tokenStats[_id];
        _lvlPoints[_id]--;
        stat.intellect++;
    }

    function upgradeStrenght(uint _id) external onlyOperator(_id) {
        require(_lvlPoints[_id] > 0);
        Stats storage stat = _tokenStats[_id];
        _lvlPoints[_id]--;
        stat.strength++;
    }

    function upgradeAgility(uint _id) external onlyOperator(_id) {
        require(_lvlPoints[_id] > 0);
        Stats storage stat = _tokenStats[_id];
        _lvlPoints[_id]--;
        stat.agility++;
    }

    function resetCharacter(uint _id) external payable onlyOperator(_id) {
        require(msg.value >= 1 ether);
        Stats storage stat = _tokenStats[_id];
        uint8 lvl = stat.lvl;
        stat.intellect = lvl;
        stat.agility = lvl;
        stat.strength = lvl;

        _lvlPoints[_id] = lvl;
    }

    function initCharacter(uint _id) external onlyOperator(_id) {
        Stats storage stat = _tokenStats[_id];
        require(stat.lvl == 0);
        stat.lvl = 1;
        stat.intellect = 1;
        stat.strength = 1;
        stat.agility = 1;
        _lvlPoints[_id]++;
    }

    // GM FUNCTIONS

    function addGame(address _game) external onlyGM {
        _isGame[_game] = true;
    }

    // PUBLIC GETTERS

    function getTokenStats(uint _id) external view returns (uint8, uint64, uint64, uint64) {
        Stats memory stat = _tokenStats[_id];
        return (stat.lvl, stat.intellect, stat.strength, stat.agility);
    }

    function getOperator(uint _id) external view returns (address) {
        return slayers.getOperator(_id);
    }

    // PRIVATE FUNCTIONS
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721GAME is IERC165 {
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

    function getOperator(uint _id) external view returns (address);

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