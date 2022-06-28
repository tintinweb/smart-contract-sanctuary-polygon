// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/** 
1. Create a Decentralized MarketPlace ✅
    1. `listItem`: List NFTs on the Marketplace. ✅
    2. `buyItem`: Buy NFTs directly on the Marketplace. ✅
    3. `cancelItem`: Cancel item listing. ✅
    4. `updateListing`: Update listing price. ✅
    5. `withdrawProceeds`: Withdraw funds from sold NFTs. ✅
*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error StarsMarketPlace__PriceMustBeAboveZero();
error StarsMarketPlace__NotApprovedForMarketPlace();
error StarsMarketPlace__NotOwner();
error StarsMarketPlace__AlreadyListed(uint256 tokenId);
error StarsMarketPlace__NotListed(uint256 tokenId);
error StarsMarketPlace__PriceNotMet(uint256 tokenId, uint256 price);
error StarsMarketPlace__TransferFailed();
error StarsMarketPlace__NoRoyalties();


contract StarsMarketplace is ReentrancyGuard, Ownable {

    /// @notice MetaStar NFT
    IERC721 MetaStarNFTs;

    /// @notice Types
    struct Listing {
        uint256 price;
        address seller;
    }

    /// @notice NFT variables
    mapping(uint256 => Listing) private s_listings;
    mapping(address => bool) private isAdmin;
    uint256 internal s_royalties_amount;
    uint256 private s_royalties;

    /// @notice Events
    event ItemListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event ItemCanceled(address indexed seller, uint256 indexed tokenId);
    event ItemBought(address indexed buyer, uint256 indexed tokenId, uint256 price);
    
    constructor(address _metaStarNFTsAddress) {
        MetaStarNFTs = IERC721(_metaStarNFTsAddress);
        s_royalties = 10;
    }

    //////////////////////
    //    Modifiers    // 
    /////////////////////

    /// @notice Check that user is the owner of tokenId
    modifier isOwner(uint256 tokenId, address spender) {
        address owner = MetaStarNFTs.ownerOf(tokenId);
        if (spender != owner) {
            revert StarsMarketPlace__NotOwner();
        }
        _;
    }
    
    /// @notice Check that item is not listed
    modifier notListed(uint256 tokenId, address owner) {
        Listing memory listing = s_listings[tokenId];
        if (listing.price > 0) {
            revert StarsMarketPlace__AlreadyListed(tokenId);
        }
        _;
    }

    /// @notice Check that item is listed
    modifier isListed(uint256 tokenId) {
        Listing memory listing = s_listings[tokenId];
        if (listing.price <= 0) {
            revert StarsMarketPlace__NotListed(tokenId);
        }
        _;
    }

     /// @notice Check if user is Admin
     modifier onlyAdmin {
        require(msg.sender == owner() || isAdmin[msg.sender], "User not owner or admin.");
        _;
    }


    //////////////////////
    //  Main Functions // 
    /////////////////////

    /**
    * @notice Function to list an NFT on sell
    * @dev
    * - Should include notListed and isOwner modifiers
    * - Should check that NFT price is >= 0, if not -> revert
    * - Should check that contract address has approve on the NFT to be transfered, if not -> revert
    * - Update mapping
    * - Emit event
    */
    function listItem(uint256 tokenId, uint256 price) external notListed(tokenId, msg.sender) isOwner(tokenId, msg.sender) {
        if (price <= 0) {
            revert StarsMarketPlace__PriceMustBeAboveZero();
        }
        if (MetaStarNFTs.getApproved(tokenId) != address(this)){
            revert StarsMarketPlace__NotApprovedForMarketPlace();
        }
        s_listings[tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, tokenId, price);
    }

    /**
    * @notice Function to buy an NFT
    * @dev
    * - Payable to be able to receive ETH
    * - Should include nonReentrant modifier from Openzeppelin (avoid Reentrancy attack)
    * - Should include isListed modifier
    * - Should check if msg.value > price
    * - Update mappings
    * - Delete listing mapping (item is not listed anymore)
    * - Transfer NFT (using OpenZeppeling safeTransferFrom function)
    * - Emit event
    * - ✅  Send Ether directly to seller 
    */
    function buyItem(uint256 tokenId) external payable nonReentrant isListed(tokenId) {
        Listing memory listedItem = s_listings[tokenId];
        if (msg.value < listedItem.price) {
            revert StarsMarketPlace__PriceNotMet(tokenId, listedItem.price);
        }
        (bool success, ) = payable(listedItem.seller).call{value: msg.value * (1 - (s_royalties/100))}("");
        if (!success) {
            revert StarsMarketPlace__TransferFailed();
        }
        s_royalties_amount += msg.value * (s_royalties/100);
        delete(s_listings[tokenId]);
        MetaStarNFTs.safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, tokenId, listedItem.price);
    }

    /**
    * @notice Function cancel NFT sell listing
    * @dev
    * - Should include isListed modifier
    * - Should include isOwner
    * - Delete listing mapping (item is not listed anymore)
    * - Emit event
    */
    function cancelListing(uint256 tokenId) external isOwner(tokenId, msg.sender) isListed (tokenId) {
        delete (s_listings[tokenId]);
        emit ItemCanceled(msg.sender, tokenId);
    }

    /**
    * @notice Function update selling NFT price
    * @dev
    * - Should include nonReentrant modifier from Openzeppelin (avoid Reentrancy attack)
    * - Should include isListed modifier
    * - Should include isOwner
    * - Update mapping
    * - Emit event
    */
    function updateListing(uint256 tokenId, uint256 newPrice) external nonReentrant isOwner(tokenId, msg.sender) isListed (tokenId) {
        s_listings[tokenId].price = newPrice;
        emit ItemListed(msg.sender, tokenId, newPrice);
    }

    //////////////////////////
    //  Royalties functions // 
    /////////////////////////

    /**
    * @notice Function used to add contract Admins
    * @dev Only callable by the Owner 
    */
    function addAdmin(address admin) external onlyOwner {
        isAdmin[admin] = true;
    }

    /**
    * @notice Function used to change royalties
    * @dev Only callable by Admins
    */
    function changeRoyalties(uint256 newRoyalties) external onlyAdmin {
        require(newRoyalties > 0 && newRoyalties <= 100, "Royalties % must be between 0 and 100.");
        s_royalties = newRoyalties;
    }

     /**
    * @notice Function to withdraw royalties
    * @dev
    * - Should check that royalties are > 0, if not -> revert
    * - Update mapping
    * - Transfer funds
    * - Check transfer is correctly done, if not -> revert
    */
    function withdrawRoyalties() external onlyAdmin {
        uint256 royalties = s_royalties_amount;
        if (royalties <= 0) {
            revert StarsMarketPlace__NoRoyalties();
        }
        s_royalties = 0;
        (bool success, ) = payable(msg.sender).call{value: royalties}("");
        if (!success) {
            revert StarsMarketPlace__TransferFailed();
        }
    }


    //////////////////////
    //  Getter Functions // 
    /////////////////////

    function getListing(uint256 tokenId) external view returns (Listing memory) {
        return s_listings[tokenId];
    }

    function getRoyaltiesPercentage() external view returns (uint256) {
        return s_royalties;
    }

    function getRoyaltiesAmount() external view returns (uint256) {
        return s_royalties_amount;
    }

    function getisAdmin(address user) public view returns(bool) {
        return isAdmin[user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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