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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/TransferHelper.sol";

/**
 * @title NFTMarketplaceV1
 * @dev An NFT marketplace contract that supports listing, buying, and canceling NFTs. The contract also handles royalty distribution.
 */
contract NFTMarketplaceV1 is Pausable, Ownable, ReentrancyGuard {
    struct Offer {
        bool isForSale;
        uint256 tokenId;
        uint256 price;
        address nftCollection;
        address seller;
    }

    struct Royalty {
        address recipient;
        uint256 royaltyPercentageBP;
    }

    // Mapping from NFT collection to NFT tokenId to Listing information
    mapping(address => mapping(uint256 => Offer)) public offers;

    // Mapping for royalty percentage per NFT collection
    // Stores the total royalty percentage (in basis points) for each NFT collection
    mapping(address => uint256) public nftCollectionRoyaltyPercentagesBP;

    // Mapping from NFT collection to Royalty information
    // Stores the royalty recipients and their royalty percentages (in basis points) for each NFT collection
    mapping(address => Royalty[]) public nftRoyalties;

    //The address of the USDC token.
    address public usdc;

    //Event emitted when there is a NFT Listing
    event NFTListed(
        address indexed nftCollection,
        uint256 indexed tokenId,
        uint256 price,
        address seller
    );

    // Event emittied when an NFT is purchased from the marketplace
    event NFTSold(
        address indexed nftCollection,
        uint256 indexed tokenId,
        address buyer,
        address seller,
        uint256 price
    );

    // Event emitted when the price of an NFT listing is changed
    event NFTPriceChanged(address indexed nftCollection, uint256 indexed tokenId, uint256 newPrice);

    // Event emitted when an NFT listing is canceled
    event NFTListingCanceled(address indexed nftCollection, uint256 indexed tokenId);

    // Event emitted when the royalty percentage is set for an NFT collection
    event RoyaltyPercentageSet(address indexed nftCollection, uint256 indexed royaltyPercentageBP);

    /**
     * @dev Initializes the contract with the USDC token address.
     * @param _usdc The address of the USDC token.
     */
    constructor(address _usdc) {
        require(_usdc != address(0), "NFTMarketplaceV1: Invalid USDC token address");
        usdc = _usdc;
    }

    modifier ensureNonZeroAddress(address _addressToCheck) {
        require(_addressToCheck != address(0), "NFTMarketplaceV1: No zero address");
        _;
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraws any required ERC20 tokens from the contract to the owner.
     * @param _token The ERC20 token to withdraw.
     */
    function withdrawERC20(IERC20 _token) external onlyOwner ensureNonZeroAddress(address(_token)) {
        TransferHelper.safeTransfer(address(_token), msg.sender, _token.balanceOf(address(this)));
    }

    /**
     * @dev Sets the NFT collection royalty percentage.
     * @param _nftCollection The address of the NFT collection.
     * @param _nftCollectionRoyaltyPercentageBP The royalty percentage (in basis points) for the NFT collection.
     */
    function setNFTCollectionRoyaltyPercentage(
        address _nftCollection,
        uint256 _nftCollectionRoyaltyPercentageBP
    ) external onlyOwner ensureNonZeroAddress(_nftCollection) {
        require(
            _nftCollectionRoyaltyPercentageBP < 10000 && _nftCollectionRoyaltyPercentageBP >= 100,
            "NFTMarketplaceV1: Invalid royalty percentage"
        );
        nftCollectionRoyaltyPercentagesBP[_nftCollection] = _nftCollectionRoyaltyPercentageBP;
        emit RoyaltyPercentageSet(_nftCollection, _nftCollectionRoyaltyPercentageBP);
    }

    /**
     * @dev Adds or updates royalty recipients and their royalty percentages for a specific NFT collection.
     * @param _nftCollection The address of the NFT collection.
     * @param _royaltyAddresses An array of royalty recipient addresses.
     * @param _royaltyPercentagesBP An array of royalty percentages (in basis points) corresponding to the recipient addresses.
     */
    function addOrUpdateRoyalties(
        address _nftCollection,
        address[] memory _royaltyAddresses,
        uint256[] memory _royaltyPercentagesBP
    ) external onlyOwner ensureNonZeroAddress(_nftCollection) {
        require(
            _royaltyAddresses.length == _royaltyPercentagesBP.length,
            "NFTMarketplaceV1: Input arrays length mismatch"
        );

        uint256 totalPercentageBP = 0;
        for (uint256 i = 0; i < _royaltyPercentagesBP.length; i++) {
            require(_royaltyAddresses[i] != address(0), "NFTMarketplaceV1: No zero address");
            require(
                _royaltyPercentagesBP[i] >= 100,
                "NFTMarketplaceV1: Minimum receipient royalty should be 1 percent"
            );
            totalPercentageBP += _royaltyPercentagesBP[i];
        }
        require(
            totalPercentageBP == 10000,
            "NFTMarketplaceV1: Total percentage must be equal to 10000"
        );

        delete nftRoyalties[_nftCollection];

        for (uint256 i = 0; i < _royaltyAddresses.length; i++) {
            nftRoyalties[_nftCollection].push(
                Royalty({
                    recipient: _royaltyAddresses[i],
                    royaltyPercentageBP: _royaltyPercentagesBP[i]
                })
            );
        }
    }

    /**
     * @dev Lists an NFT for sale.
     * @param _nftCollection The address of the NFT collection.
     * @param _tokenId The ID of the token to list for sale.
     * @param _price The sale price of the NFT is USDC.
     */
    function listNFTForSale(
        address _nftCollection,
        uint256 _tokenId,
        uint256 _price
    ) external whenNotPaused nonReentrant ensureNonZeroAddress(_nftCollection) {
        require(_price >= 1e6, "NFTMarketplaceV1: Price must be greater than or equal than 1 USDC");
        IERC721 nftCollection = IERC721(_nftCollection);
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "NFTMarketplaceV1: Not the NFT owner"
        );

        offers[_nftCollection][_tokenId] = Offer({
            isForSale: true,
            tokenId: _tokenId,
            price: _price,
            nftCollection: _nftCollection,
            seller: msg.sender
        });

        emit NFTListed(_nftCollection, _tokenId, _price, msg.sender);
    }

    /**
     * @dev Changes the listing price of an NFT.
     * @param _nftCollection The address of the NFT collection.
     * @param _tokenId The ID of the token to change the price.
     * @param _newPrice The new listing price of the NFT.
     */
    function changeListingPrice(
        address _nftCollection,
        uint256 _tokenId,
        uint256 _newPrice
    ) external whenNotPaused nonReentrant ensureNonZeroAddress(_nftCollection) {
        Offer storage offer = offers[_nftCollection][_tokenId];
        require(offer.isForSale, "NFTMarketplaceV1: Token not for sale");
        require(
            IERC721(offer.nftCollection).ownerOf(_tokenId) == msg.sender,
            "NFTMarketplaceV1: Not the token owner"
        );
        require(
            _newPrice >= 1e6,
            "NFTMarketplaceV1: Price must be greater than or equal than 1 USDC"
        );
        offer.price = _newPrice;

        emit NFTPriceChanged(_nftCollection, _tokenId, _newPrice);
    }

    /**
     * @dev Cancels the listing of an NFT.
     * @param _nftCollection The address of the NFT collection.
     * @param _tokenId The ID of the token to cancel the listing.
     */
    function cancelListing(
        address _nftCollection,
        uint256 _tokenId
    ) external whenNotPaused nonReentrant {
        Offer storage offer = offers[_nftCollection][_tokenId];
        require(offer.isForSale, "NFTMarketplaceV1: Token not for sale");
        require(
            IERC721(offer.nftCollection).ownerOf(_tokenId) == offer.seller,
            "NFTMarketplaceV1: Not the token owner"
        );

        offer.isForSale = false;

        emit NFTListingCanceled(_nftCollection, _tokenId);
    }

    /**
     * @dev Buys an NFT from the marketplace.
     * @param _nftCollection The address of the NFT collection.
     * @param _tokenId The ID of the token to buy.
     */
    function buyNFT(
        address _nftCollection,
        uint256 _tokenId
    ) external whenNotPaused nonReentrant ensureNonZeroAddress(_nftCollection) {
        Offer storage offer = offers[_nftCollection][_tokenId];
        require(offer.isForSale, "NFTMarketplaceV1: Token not for sale");
        require(offer.seller != msg.sender, "NFTMarketplaceV1: Cannot buy owned NFT");
        require(
            IERC721(offer.nftCollection).ownerOf(_tokenId) == offer.seller,
            "NFTMarketplaceV1: Not the token owner"
        );

        TransferHelper.safeTransferFrom(address(usdc), msg.sender, address(this), offer.price);

        uint256 nftCollectionRoyaltyPercentageBP = nftCollectionRoyaltyPercentagesBP[
            _nftCollection
        ];
        if (nftCollectionRoyaltyPercentageBP > 0) {
            uint256 royaltyAmount = (offer.price * nftCollectionRoyaltyPercentageBP) / 10000;

            Royalty[] memory royalties = nftRoyalties[_nftCollection];
            uint256 totalRoyaltyAmount;
            for (uint256 i = 0; i < royalties.length; i++) {
                uint256 recipientRoyaltyAmount = (royaltyAmount *
                    royalties[i].royaltyPercentageBP) / 10000;
                TransferHelper.safeTransfer(
                    address(usdc),
                    royalties[i].recipient,
                    recipientRoyaltyAmount
                );
                totalRoyaltyAmount += recipientRoyaltyAmount;
            }
            require(
                totalRoyaltyAmount == royaltyAmount,
                "NFTMarketplaceV1: Total royalty amount mismatch"
            );
            TransferHelper.safeTransfer(address(usdc), offer.seller, offer.price - royaltyAmount);
        } else {
            TransferHelper.safeTransfer(address(usdc), offer.seller, offer.price);
        }

        IERC721(_nftCollection).transferFrom(offer.seller, msg.sender, _tokenId);
        offer.isForSale = false;
        emit NFTSold(_nftCollection, _tokenId, msg.sender, offer.seller, offer.price);
    }

    function getOffer(
        address _nftCollection,
        uint256 _tokenId
    ) external view returns (Offer memory) {
        return offers[_nftCollection][_tokenId];
    }

    function isNFTForSale(address _nftCollection, uint256 _tokenId) external view returns (bool) {
        return offers[_nftCollection][_tokenId].isForSale;
    }

    function getNFTPrice(address _nftCollection, uint256 _tokenId) external view returns (uint256) {
        return offers[_nftCollection][_tokenId].price;
    }

    function getNFTSeller(
        address _nftCollection,
        uint256 _tokenId
    ) external view returns (address) {
        return offers[_nftCollection][_tokenId].seller;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}