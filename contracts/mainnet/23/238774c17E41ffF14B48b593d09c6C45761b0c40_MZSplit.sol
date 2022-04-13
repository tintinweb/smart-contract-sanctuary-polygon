// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract Admin is Context {
    address private _owner;
    address private _moderator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event ModerationTransferred(address indexed previousModerator, address indexed newModerator);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
        _setModerator(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current moderator.
     */
    function moderator() public view virtual returns (address) {
        return _moderator;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Admin: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner or moderator.
     */
    modifier onlyAdmins() {
        require(owner() == _msgSender() || moderator() == _msgSender(), "Admin: caller is not an admin");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Admin: new owner is the zero address");
        _setOwner(newOwner);
    }

    /**
     * @dev Transfers moderation control of the contract to a new account
     * (`newModerator`). Can only be called by the current owner.
     */
    function transferModeration(address newModerator) public virtual onlyOwner {
        require(newModerator != address(0), "Admin: new moderator is the zero address");
        _setModerator(newModerator);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setModerator(address newModerator) internal {
        address oldModerator = _moderator;
        _moderator = newModerator;
        emit ModerationTransferred(oldModerator, newModerator);
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./Admin.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MZSplit is Admin {
    /**
     * @dev Structure to hold a split portion.
     *
     * @param cut           Number percent from 0 to 100
     * @param markToken     MetaMark token_id receiver of portion of funds
     * @param balance       Remaining funds per supported ERC20 token
     */
    struct Split {
        uint8 cut;
        uint256 markToken;
    }

    // Array of split percentages
    mapping (uint8 => Split) public _splits;
    // How many split percentages
    uint8 public _splitCount = 0;
    // Split cuts added up
    uint8 public _sumCuts = 0;

    /**
     * @dev Initializes the amount of recipients involved, each recipient percentage, and the recipient addresses.
     *
     * @param moderator            Address of additional admin
     * @param count                Amount of recipients
     * @param cuts                 List of percentages for each recipient
     * @param markTokens           Recipient MetaMark token id
     */
    constructor(
        address moderator,
        uint8 count,
        uint8[] memory cuts,
        uint256[] memory markTokens
    ) {
        // Count must be size of cuts and recipients
        require(count == cuts.length && count == markTokens.length, "Lengths do not match");

        // Sender is the owner
        _setOwner(tx.origin);
        // Allow creator to specify a moderator
        _setModerator(moderator);

        // Save splits
        _splitCount = count;
        for(uint8 i=0; i<_splitCount; i++) {
            // Add new split
            Split storage s = _splits[i];
            s.cut = cuts[i];
            s.markToken = markTokens[i];

            // Sum of all cuts
            _sumCuts += cuts[i];
        }

        require(_sumCuts == 100, "Sum of cuts do not equal 100%");
    }

    function getCut(uint8 index) public view returns(uint256) {
        return _splits[index].cut;
    }
    function getRecipient(uint8 index) public view returns(uint256) {
        return _splits[index].markToken;
    }

    function setCut(uint8 index, uint8 newCut) public onlyAdmins {
        require(index < _splitCount, "Invalid index");
        require(newCut >= 0, "New cut must be positive");

        // Adjust cut
        _splits[index].cut = newCut;
    }
    function setRecipient(uint8 index, uint256 newMarkToken) public onlyAdmins {
        require(index < _splitCount, "Invalid index");
        require(newMarkToken >= 0, "New token id must be positive");

        // Update MetaMark token id to the new token id
        _splits[index].markToken = newMarkToken;
    }
}