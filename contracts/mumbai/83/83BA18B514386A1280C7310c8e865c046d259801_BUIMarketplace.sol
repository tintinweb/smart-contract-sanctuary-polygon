// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IBUIMarketplace.sol";
import "./IBUIBlockNFT.sol";
import "./License.sol";
import "./Block.sol";
import "./Listing.sol";

contract BUIMarketplace is IBUIMarketplace, Ownable {

    // Map of tokenIds listed for an account
    mapping(address => uint256[]) private _ownedListings;
    // Map of tokenIds to their Listing
    mapping(uint256 => Listing) private _listings;
    // List of tokenIds for Blocks that are listed.
    uint256[] private _listedTokenIds;

    IBUIBlockNFT private _buiBlockContract;

    uint256 public listingPrice = 0.01 ether;

    constructor(address buiBlockAddress, uint256 listingPrice_) {
        _buiBlockContract = IBUIBlockNFT(buiBlockAddress);
        listingPrice = listingPrice_;
    }

    function withdraw() external onlyOwner() {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function listBlock(
        string memory metaDataURI,
        uint256 pricePerDay,
        uint256 price,
        uint256 tokenId,
        bool licensable
    ) external payable {
        require(msg.value >= listingPrice, "Insufficient listing funds");
        require(_buiBlockContract.ownerOf(tokenId) == msg.sender, "Unauthorized: Not the owner.");
        require(_listings[tokenId].owner == address(0), "Listing already exists");

        Listing memory listing = Listing(
            metaDataURI,
            payable(msg.sender),
            pricePerDay,
            price,
            licensable
        );

        // Save the listing
        _listings[tokenId] = listing;

        // Store the index of the listing for the sender
        _ownedListings[msg.sender].push(tokenId);

        // Add the tokenId to an array for quick retrieval
        _listedTokenIds.push(tokenId);

        // TODO: If the type is a sale then we also need to approve the transfer

        emit BUIListingCreated(_listedTokenIds.length - 1, licensable, tokenId);
    }

    function listingForTokenId(uint256 tokenId) external view returns (Listing memory listing) {
        listing = _listings[tokenId];
    }

    function getListings(uint256 amount, uint256 page) external view returns (Listing[] memory) {
        uint256 max = (amount * page) + amount;

        if (max >= _listedTokenIds.length) {
            max = _listedTokenIds.length;
        }

        Listing[] memory listings = new Listing[](amount);

        uint256 j = 0;
        for (uint256 i = amount * page; i < max; i++) {
            listings[j] = _listings[_listedTokenIds[i]];
            j++;
        }

        return listings;
    }

    function setListingPrice(uint256 listingPrice_) external onlyOwner {
        listingPrice = listingPrice_;
    }

    // TODO: add purchase functionality. Possibly using Seaport and creating a conduit.
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Listing.sol";

interface IBUIMarketplace {
    event BUIListingCreated(uint256 id, bool licensable, uint256 tokenId);

    function listBlock(
        string memory metaDataURI,
        uint256 pricePerDay,
        uint256 price,
        uint256 tokenId,
        bool licensable
    ) external payable;

    function listingForTokenId(uint256 tokenId) external view returns (Listing memory);

    function getListings(uint256 amount, uint256 page) external view returns (Listing[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./Block.sol";

interface IBUIBlockNFT is IERC721 {
    event BUIBlockPublished(
        bytes32 cid,
        Block data
    );

    event BUIBlockDeprecated(uint256 tokenId);
    event BUIBlockMetadataUpdated(uint256 tokenId);

    function blockForToken(uint256 tokenId) external view returns (bytes32);

    function verifyOwner(bytes32 cid, address owner) external view returns (bool);

    function blockExists(bytes32 cid) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Listing {
    string metaDataURI;
    address payable owner;
    uint256 pricePerDay;
    uint256 price;
    bool licensable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct License {
    uint blockId;
    bytes32 cid;
    uint256 expirationDate;
    address owner;
    bytes32 origin;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Block {
    uint256 tokenId;
    uint256 deprecateDate;
    string metaURI;
    address owner;
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