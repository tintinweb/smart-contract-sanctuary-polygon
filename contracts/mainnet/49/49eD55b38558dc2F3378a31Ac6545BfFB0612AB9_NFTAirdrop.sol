//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NFTAirdrop is Pausable {
    struct AirdropItem {
        address nft;
        uint256 id;
    }
    address public admin;
    address public dropperAddress;
    uint256 public nextAirdropId = 0;
    uint256 public airdropItemsIndex = 0;
    uint256 public recipientsIndex = 0;
    mapping(uint256 => AirdropItem) public airdrops;
    mapping(address => bool) public recipients;
    event Claimed(uint256 nftId, address nftContract, address claimer);

    constructor() {
        admin = msg.sender;
        dropperAddress = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "not authorized");
        _;
    }

    // ------------------
    // Public functions
    // -----------------

    function claim() external whenNotPaused {
        require(recipients[msg.sender] == true, "recipient not registered");
        recipients[msg.sender] = false;
        AirdropItem storage airdrop = airdrops[nextAirdropId];

        IERC721(airdrop.nft).transferFrom(
            address(this),
            msg.sender,
            airdrop.id
        );
        nextAirdropId++;
        recipientsIndex--;
        emit Claimed(airdrop.id, airdrop.nft, msg.sender);
    }

    // ------------------
    // Admin functions
    // -----------------

    function setDropperAddress(address _newDropper) external onlyAdmin {
        dropperAddress = _newDropper;
    }

    function addAirdropItems(AirdropItem[] memory _airdropItems) external {
        require(msg.sender == dropperAddress, "not authorized");
        uint256 _nextAirdropId = nextAirdropId;

        for (uint256 i = 0; i < _airdropItems.length; i++) {
            airdrops[_nextAirdropId] = _airdropItems[i];

            IERC721(_airdropItems[i].nft).transferFrom(
                msg.sender,
                address(this),
                _airdropItems[i].id
            );
            _nextAirdropId++;
            airdropItemsIndex++;
        }
    }

    function addRecipients(address[] memory _recipients) external onlyAdmin {
        for (uint256 i = 0; i < _recipients.length; i++) {
            recipients[_recipients[i]] = true;
            recipientsIndex++;
        }
    }

    function removeRecipients(address[] memory _recipients) external onlyAdmin {
        for (uint256 i = 0; i < _recipients.length; i++) {
            recipients[_recipients[i]] = false;
            recipientsIndex--;
        }
    }

    // for resetting when airdrop finishes
    function closeAirdrop(address[] memory _unclaimedAddresses)
        external
        onlyAdmin
    {
        require(
            recipientsIndex == _unclaimedAddresses.length,
            "include all addresses to reset"
        );
        for (uint256 i = 0; i < _unclaimedAddresses.length; i++) {
            recipients[_unclaimedAddresses[i]] = false;
            recipientsIndex--;
        }

        for (uint256 i = 0; i < airdropItemsIndex; i++) {
            delete airdrops[airdropItemsIndex];
        }

        airdropItemsIndex = 0;
        nextAirdropId = 0;
    }

    // for a different kind of airdrop
    // in case we want an airdrop without making the user claim
    function bulkTransfer(
        address _nftContract,
        address _from,
        address[] calldata _to,
        uint256[] calldata _id
    ) external whenNotPaused {
        require(
            msg.sender == admin || msg.sender == dropperAddress,
            "not authorized"
        );
        require(
            _to.length == _id.length,
            "receivers and IDs are different length"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            IERC721(_nftContract).transferFrom(_from, _to[i], _id[i]);
        }
    }

    // ------------------
    // Other
    // -----------------

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function withdraw(address _to) external payable onlyAdmin {
        require(_to != address(0), "Invalid 0 address");
        payable(_to).transfer(address(this).balance);
    }

    receive() external payable {}
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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