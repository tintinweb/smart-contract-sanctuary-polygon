/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


/**
 * @title LensportAuction
 * @author Lensport + Avo Labs. (Modified auction contract by that was originally written by Avo Labs)
 *
 **/

contract LensportAuction is Ownable, Pausable, ReentrancyGuard {
    // When someone signs a message, the message must include a nonce which is greater
    // than this value. This is to prevent someone from submitting the same signed transacation twice.
    mapping(address => uint256) public sigTransactionNonce;

    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    //Each Auction is unique to each NFT (contract + id pairing).
    struct Auction {
        // Map token ID to
        uint32 bidIncreasePercentage;
        uint64 auctionEnd;
        uint128 minPrice;
        uint128 buyNowPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address whitelistedBuyer;   // The seller can specify a whitelisted address for a sale (this is effectively a direct sale).
        address nftRecipient;       // The bidder can specify a recipient for the NFT if their bid is successful.
        address ERC20Token;         // The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
        address[] feeRecipients;
        uint32[] feePercentages;
    }

    mapping(address => mapping(uint256 => mapping(address => Offer))) public nftOffers;
    mapping(address => mapping(address => Offer)) public collectionOffers;
    // Can change how auction is now to be more like original
    struct Offer {
        uint64 expiration;
        uint128 amount;
        address ERC20Token;
    }

    /*
     * Default values that are used if not specified by the NFT seller.
     */
    uint32 public defaultBidIncreasePercentage;
    uint32 public minimumSettableIncreasePercentage;
    address public defaultERC20Token;

    address public marketplaceFeeRecipient;
    uint256 public marketplaceFeePercentage;

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event NftAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        uint64 auctionEnd,
        uint32 bidIncreasePercentage,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event SaleCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 buyNowPrice,
        address whitelistedBuyer,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 tokenAmount
    );

    event OfferMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        uint64 expiration,
        uint128 tokenAmount,
        address erc20Token
    );

    event OfferWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address bidder
    );

    event OfferTaken(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address nftRecipient,
        uint128 tokenAmount,
        address erc20Token
    );

    event CollectionOfferMade(
        address nftContractAddress,
        address bidder,
        uint64 expiration,
        uint128 tokenAmount,
        address erc20Token
    );

    event CollectionOfferWithdrawn(
        address nftContractAddress,
        address bidder
    );

    event CollectionOfferTaken(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address nftRecipient,
        uint128 tokenAmount,
        address erc20Token
    );

    event AuctionPeriodUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint64 auctionEndPeriod
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 nftHighestBid,
        address nftHighestBidder,
        address nftRecipient
    );

    event AuctionSettled(
        address nftContractAddress,
        uint256 tokenId,
        address auctionSettler
    );

    event AuctionWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event BidWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address highestBidder
    );

    event WhitelistedBuyerUpdated(
        address nftContractAddress,
        uint256 tokenId,
        address newWhitelistedBuyer
    );

    event MinimumPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newMinPrice
    );

    event BuyNowPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint128 newBuyNowPrice
    );
    event HighestBidTaken(address nftContractAddress, uint256 tokenId);
    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    modifier isAuctionNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId,
        address _user
    ) {
        require(
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller !=
                msg.sender,
            "Auction already started by owner"
        );

        if (
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller !=
            address(0)
        ) {
            require(
                _user == IERC721(_nftContractAddress).ownerOf(_tokenId),
                "Sender doesn't own NFT"
            );

            _resetAuction(_nftContractAddress, _tokenId);
        }
        _;
    }

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            _isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction has ended"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    modifier minPriceDoesNotExceedLimit(
        uint128 _buyNowPrice,
        uint128 _minPrice
    ) {
        require(
            _buyNowPrice == 0 || _buyNowPrice >= _minPrice,
            "MinPrice > buyNowPrice"
        );
        _;
    }

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender !=
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Owner cannot bid on own NFT"
        );
        _;
    }

    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId, address _user) {
        require(_user == nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            "Only nft seller"
        );
        _;
    }

    modifier onlyNftOwner(address _nftContractAddress, uint256 _tokenId, address _user) {
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == _user, 
            "Only nft owner"
        );
        _;
    }

    /*
     * The bid amount was either equal the buyNowPrice or it must be higher than the previous
     * bid by the specified bid increase percentage.
     */
    modifier bidAmountMeetsBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) {
        require(
            _doesBidMeetBidRequirements(
                _nftContractAddress,
                _tokenId,
                _tokenAmount
            ),
            "Not enough funds to bid on NFT"
        );
        _;
    }
    // check if the highest bidder can purchase this NFT.
    modifier onlyApplicableBuyer(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            !_isWhitelistedSale(_nftContractAddress, _tokenId) ||
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .whitelistedBuyer ==
                msg.sender,
            "Only the whitelisted buyer"
        );
        _;
    }

    modifier minimumBidNotMade(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isMinimumBidMade(_nftContractAddress, _tokenId),
            "The auction has a valid bid made"
        );
        _;
    }

    /*
     * Payment is accepted if the payment is made in the ERC20 token specified by the seller.
     * Early bids on NFTs not yet up for auction must be made in ETH.
     */
    modifier paymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    ) {
        require(
            _isPaymentAccepted(
                _nftContractAddress,
                _tokenId,
                _erc20Token,
                _tokenAmount
            ),
            "Bid to be in specified ERC20/Eth"
        );
        _;
    }

    modifier isAuctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isAuctionOngoing(_nftContractAddress, _tokenId),
            "Auction is not yet over"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(
            _recipientsLength == _percentagesLength,
            "Recipients != percentages"
        );
        _;
    }

    modifier isNotASale(address _nftContractAddress, uint256 _tokenId) {
        require(
            !_isASale(_nftContractAddress, _tokenId),
            "Not applicable for a sale"
        );
        _;
    }

    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
    /**********************************/
    // constructor
    constructor(address _defaultERC20Token) {
        defaultERC20Token = _defaultERC20Token;
        
        defaultBidIncreasePercentage = 100;
        minimumSettableIncreasePercentage = 100;
    }

    /*╔══════════════════════════════╗
      ║    AUCTION CHECK FUNCTIONS   ║
      ╚══════════════════════════════╝*/
    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint64 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].auctionEnd;
        //if the auctionEnd is set to 0, the auction is technically on-going, however
        //the minimum bid price (minPrice) has not yet been met.
        return (auctionEndTimestamp == 0 ||
            block.timestamp < auctionEndTimestamp);
    }

    /*
     * Check if a bid has been made. This is applicable in the early bid scenario
     * to ensure that if an auction is created after an early bid, the auction
     * begins appropriately or is settled if the buy now price is met.
     */
    function _isABidMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBid > 0);
    }

    /*
     *if the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
     */
    function _isMinimumBidMade(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint128 minPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .minPrice;
        return
            minPrice > 0 &&
            (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >=
                minPrice);
    }

    /*
     * If the buy now price is set by the seller, check that the highest bid meets that price.
     */
    function _isBuyNowPriceMet(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        uint128 buyNowPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice;
        return
            buyNowPrice > 0 &&
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >=
            buyNowPrice;
    }

    /*
     * Check that a bid is applicable for the purchase of the NFT.
     * In the case of a sale: the bid needs to meet the buyNowPrice.
     * In the case of an auction: the bid needs to be a % higher than the previous bid.
     */
    function _doesBidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        uint128 buyNowPrice = nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice;
        //if buyNowPrice is met, ignore increase percentage
        if (buyNowPrice > 0 && _tokenAmount >= buyNowPrice) {
            return true;
        }
        //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid *
            (10000 +
                _getBidIncreasePercentage(_nftContractAddress, _tokenId))) /
            10000;
        return (_tokenAmount >= bidIncreaseAmount);
    }

    /*
     * An NFT is up for sale if the buyNowPrice is set, but the minPrice is not set.
     * Therefore the only way to conclude the NFT sale is to meet the buyNowPrice.
     */
    function _isASale(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice >
            0 &&
            nftContractAuctions[_nftContractAddress][_tokenId].minPrice == 0);
    }

    function _isWhitelistedSale(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId]
            .whitelistedBuyer != address(0));
    }

    /*
     * The highest bidder is allowed to purchase the NFT if
     * no whitelisted buyer is set by the NFT seller.
     * Otherwise, the highest bidder must equal the whitelisted buyer.
     */
    function _isHighestBidderAllowedToPurchaseNFT(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return
            (!_isWhitelistedSale(_nftContractAddress, _tokenId)) ||
            _isHighestBidderWhitelisted(_nftContractAddress, _tokenId);
    }

    function _isHighestBidderWhitelisted(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return (nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBidder ==
            nftContractAuctions[_nftContractAddress][_tokenId]
                .whitelistedBuyer);
    }

    /**
     * Payment is accepted in the following scenarios:
     * (1) Auction already created - can accept Specified Token
     * (2) Auction not created
     * (3) Cannot make a zero bid (no Token amount)
     */
    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidERC20Token,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        return
            msg.value == 0 &&
            auctionERC20Token == _bidERC20Token &&
            _tokenAmount > 0;
    }

    /*
     * Returns the percentage of the total bid (used to calculate fee payments)
     */
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    AUCTION CHECK FUNCTIONS   ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /*****************************************************************
     * These functions check if the applicable auction parameter has *
     * been set by the NFT seller. If not, return the default value. *
     *****************************************************************/

    function _getBidIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint32) {
        uint32 bidIncreasePercentage = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].bidIncreasePercentage;

        if (bidIncreasePercentage == 0) {
            return defaultBidIncreasePercentage;
        } else {
            return bidIncreasePercentage;
        }
    }

    /*
     * The default value for the NFT recipient is the highest bidder
     */
    function _getNftRecipient(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (address)
    {
        address nftRecipient = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftRecipient;

        if (nftRecipient == address(0)) {
            return
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .nftHighestBidder;
        } else {
            return nftRecipient;
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║  TRANSFER NFTS TO CONTRACT   ║
      ╚══════════════════════════════╝*/
    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller) {
            IERC721(_nftContractAddress).transferFrom(
                _nftSeller,
                address(this),
                _tokenId
            );
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "nft transfer failed"
            );
        } else {
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "Seller doesn't own NFT"
            );
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║  TRANSFER NFTS TO CONTRACT   ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       AUCTION CREATION       ║
      ╚══════════════════════════════╝*/

    /**
     * Setup parameters applicable to all auctions and whitelised sales:
     * -> ERC20 Token for payment (if specified by the seller) : _erc20Token
     * -> minimum price : _minPrice
     * -> buy now price : _buyNowPrice
     * -> the nft seller: msg.sender
     * -> The fee recipients & their respective percentages for a sucessful auction/sale
     */
    function _setupAuction(
        address _user,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _minPrice,
        uint128 _buyNowPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        internal
        minPriceDoesNotExceedLimit(_buyNowPrice, _minPrice)
        correctFeeRecipientsAndPercentages(
            _feeRecipients.length,
            _feePercentages.length
        )
        isFeePercentagesLessThanMaximum(_feePercentages)
    {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        else {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .ERC20Token = defaultERC20Token;
        }
        nftContractAuctions[_nftContractAddress][_tokenId]
            .feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice = _buyNowPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = _user;
    }

    function _createNewNftAuction(
        address _user,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _minPrice,
        uint128 _buyNowPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) internal {
        // Sending the NFT to this contract
        _setupAuction(
            _user,
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            _feeRecipients,
            _feePercentages
        );
        emit NftAuctionCreated(
            _nftContractAddress,
            _tokenId,
            _user,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            nftContractAuctions[_nftContractAddress][_tokenId]
            .auctionEnd,
            _getBidIncreasePercentage(_nftContractAddress, _tokenId),
            _feeRecipients,
            _feePercentages
        );
        _updateOngoingAuction(_nftContractAddress, _tokenId);
    }

    function createNewNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _minPrice,
        uint128 _buyNowPrice,
        uint32 _auctionBidPeriod, // How long the auction/buy now lasts.
        uint32 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    )
        external
    {
        require(_minPrice > 0, "Price cannot be 0");
        require(
            _bidIncreasePercentage >= minimumSettableIncreasePercentage,
            "Bid increase percentage too low"
        );
        require(
            (nftContractAuctions[_nftContractAddress][_tokenId].nftSeller != _user || _isAuctionOngoing(_nftContractAddress, _tokenId) == false),
            "Auction already started by owner"
        );

        if (
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller !=
            address(0)
        ) {
            require(
                _user == IERC721(_nftContractAddress).ownerOf(_tokenId),
                "Sender doesn't own NFT"
            );

            _resetAuction(_nftContractAddress, _tokenId);
        }

        verifyUserCreateAuction(_nftContractAddress, _tokenId, _user, _nonce, _sig);

        nftContractAuctions[_nftContractAddress][_tokenId]
            .auctionEnd = _auctionBidPeriod + uint64(block.timestamp);
        nftContractAuctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage = _bidIncreasePercentage;
        _createNewNftAuction(
            _user,
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _minPrice,
            _buyNowPrice,
            _feeRecipients,
            _feePercentages
        );
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       AUCTION CREATION       ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║            SALES             ║
      ╚══════════════════════════════╝*/

    /********************************************************************
     * Allows for a standard sale mechanism where the NFT seller can    *
     * can select an address to be whitelisted. This address is then    *
     * allowed to make a bid on the NFT. No other address can bid on    *
     * the NFT.                                                         *
     ********************************************************************/
    function _setupSale(
        address _user,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _buyNowPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
        internal
        correctFeeRecipientsAndPercentages(
            _feeRecipients.length,
            _feePercentages.length
        )
        isFeePercentagesLessThanMaximum(_feePercentages)
    {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .ERC20Token = _erc20Token;
        }
        else {
            nftContractAuctions[_nftContractAddress][_tokenId]
                .ERC20Token = defaultERC20Token;
        }
        nftContractAuctions[_nftContractAddress][_tokenId]
            .feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice = _buyNowPrice;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .whitelistedBuyer = _whitelistedBuyer;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = _user;
    }

    function createSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _buyNowPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    )
        external
        nonReentrant()
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId, _user)
        priceGreaterThanZero(_buyNowPrice)
    {

        verifyUserCreateSale(_nftContractAddress, _tokenId, _user, _nonce, _sig);

        //min price = 0
        _setupSale(
            _user,
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _buyNowPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );

        emit SaleCreated(
            _nftContractAddress,
            _tokenId,
            _user,
            _erc20Token,
            _buyNowPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );
        //check if buyNowPrice is meet and conclude sale, otherwise reverse the early bid
        if (_isABidMade(_nftContractAddress, _tokenId)) {
            if (
                //we only revert the underbid if the seller specifies a different
                //whitelisted buyer to the highest bidder
                _isHighestBidderAllowedToPurchaseNFT(
                    _nftContractAddress,
                    _tokenId
                )
            ) {
                if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
                    _transferNftToAuctionContract(
                        _nftContractAddress,
                        _tokenId
                    );
                    _transferNftAndPaySeller(_nftContractAddress, _tokenId);
                }
            } else {
                _reverseAndResetPreviousBid(_nftContractAddress, _tokenId);
            }
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║            SALES             ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       OFFER FUNCTIONS        ║
      ╚══════════════════════════════╝*/

    function makeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        uint64 _expiration,
        uint128 _amount,
        address _erc20Token
    )
        external
        notNftSeller(_nftContractAddress, _tokenId)
    {
        require(_amount != 0);
        require(_expiration > block.timestamp);
        require(_erc20Token != address(0));
        nftOffers[_nftContractAddress][_tokenId][msg.sender].expiration = _expiration;
        nftOffers[_nftContractAddress][_tokenId][msg.sender].amount = _amount;
        nftOffers[_nftContractAddress][_tokenId][msg.sender].ERC20Token = _erc20Token;
        emit OfferMade(_nftContractAddress, _tokenId, msg.sender, _expiration, _amount, _erc20Token);
    }

    function withdrawOffer(
        address _nftContractAddress,
        uint256 _tokenId
    )
        external
    {
        require(nftOffers[_nftContractAddress][_tokenId][msg.sender].amount != 0);
        delete nftOffers[_nftContractAddress][_tokenId][msg.sender];
        emit OfferWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    function takeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidder,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages,
        address _user,
        uint256 _nonce, 
        bytes memory _sig
    )
        external
        nonReentrant()
        onlyNftOwner(_nftContractAddress, _tokenId, _user)
    {
        verifyUserTakeOffer(_nftContractAddress, _tokenId, _bidder, _user, _nonce, _sig);
        require(nftOffers[_nftContractAddress][_tokenId][_bidder].expiration >= block.timestamp, "Offer expired.");

        // Can't take an offer if the minimum bid has already been made
        require(!_isMinimumBidMade(_nftContractAddress, _tokenId));

        IERC721(_nftContractAddress).transferFrom(
            _user,
            _bidder,
            _tokenId
        );
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == _bidder,
            "nft transfer failed"
        );

        uint128 amount = nftOffers[_nftContractAddress][_tokenId][_bidder].amount;
        address erc20Token = nftOffers[_nftContractAddress][_tokenId][_bidder].ERC20Token;
        _payFeesAndSellerForOffer(
            _nftContractAddress,
            _tokenId,
            _user,
            amount,
            _bidder,
            _feeRecipients,
            _feePercentages
        );

        delete nftOffers[_nftContractAddress][_tokenId][_bidder];
        _resetBids(_nftContractAddress, _tokenId);
        _resetAuction(_nftContractAddress, _tokenId);

        emit OfferTaken(
            _nftContractAddress,
            _tokenId,
            _user,
            _bidder,
            amount,
            erc20Token
        );
    }

    function makeCollectionOffer(
        address _nftContractAddress,
        uint64 _expiration,
        uint128 _amount,
        address _erc20Token
    )
        external
    {
        require(_amount != 0);
        require(_expiration > block.timestamp);
        require(_erc20Token != address(0));
        collectionOffers[_nftContractAddress][msg.sender].expiration = _expiration;
        collectionOffers[_nftContractAddress][msg.sender].amount = _amount;
        collectionOffers[_nftContractAddress][msg.sender].ERC20Token = _erc20Token;
        emit CollectionOfferMade(_nftContractAddress, msg.sender, _expiration, _amount, _erc20Token);
    }

    function withdrawCollectionOffer(
        address _nftContractAddress
    )
        external
    {
        require(collectionOffers[_nftContractAddress][msg.sender].amount != 0);
        delete collectionOffers[_nftContractAddress][msg.sender];
        emit CollectionOfferWithdrawn(_nftContractAddress, msg.sender);
    }

    function takeCollectionOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidder,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages,
        address _user,
        uint256 _nonce, 
        bytes memory _sig
    )
        external
        nonReentrant()
        onlyNftOwner(_nftContractAddress, _tokenId, _user)
    {
        verifyUserTakeCollectionOffer(_nftContractAddress, _tokenId, _bidder, _user, _nonce, _sig);
        require(collectionOffers[_nftContractAddress][_bidder].expiration >= block.timestamp, "Offer expired.");

        // Can't take an offer if the minimum bid has already been made on an active auction
        require(!_isMinimumBidMade(_nftContractAddress, _tokenId));

        IERC721(_nftContractAddress).transferFrom(
            _user,
            _bidder,
            _tokenId
        );
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == _bidder,
            "nft transfer failed"
        );

        uint128 amount = collectionOffers[_nftContractAddress][_bidder].amount;
        address erc20Token = collectionOffers[_nftContractAddress][_bidder].ERC20Token;
        _payFeesAndSellerForCollectionOffer(
            _nftContractAddress,
            _user,
            amount,
            _bidder,
            _feeRecipients,
            _feePercentages
        );

        delete collectionOffers[_nftContractAddress][_bidder];
        _resetBids(_nftContractAddress, _tokenId);
        _resetAuction(_nftContractAddress, _tokenId);

        emit OfferTaken(
            _nftContractAddress,
            _tokenId,
            _user,
            _bidder,
            amount,
            erc20Token
        );
        emit CollectionOfferTaken(
            _nftContractAddress,
            _tokenId,
            _user,
            _bidder,
            amount,
            erc20Token
        );
    }


    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║            OFFER             ║
      ╚══════════════════════════════╝*/
    /**********************************/


    /*╔═════════════════════════════╗
      ║        BID FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /********************************************************************
     * Make bids with an ERC20 Token specified by the NFT seller.*
     * Additionally, a buyer can pay the asking price to conclude a sale*
     * of an NFT.                                                      *
     ********************************************************************/

    function _makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
        internal
        notNftSeller(_nftContractAddress, _tokenId)
        paymentAccepted(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _tokenAmount
        )
        bidAmountMeetsBidRequirements(
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        )
    {
        _reversePreviousBidAndUpdateHighestBid(
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        );
        emit BidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _tokenAmount
        );
        _updateOngoingAuction(_nftContractAddress, _tokenId);
    }

    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external
        auctionOngoing(_nftContractAddress, _tokenId)
        onlyApplicableBuyer(_nftContractAddress, _tokenId)
    {
        _makeBid(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
    }

    function makeCustomBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount,
        address _nftRecipient
    )
        external
        auctionOngoing(_nftContractAddress, _tokenId)
        notZeroAddress(_nftRecipient)
        onlyApplicableBuyer(_nftContractAddress, _tokenId)
    {
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftRecipient = _nftRecipient;
        _makeBid(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║        BID FUNCTIONS         ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       UPDATE AUCTION         ║
      ╚══════════════════════════════╝*/

    /***************************************************************
     * Settle an auction or sale if the buyNowPrice is met or set  *
     *  auction period to begin if the minimum price has been met. *
     ***************************************************************/
    function _updateOngoingAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) 
        internal 
        nonReentrant()
    {
        if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
            return;
        }
        //min price not set, nft not up for auction yet
        if (_isMinimumBidMade(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    function _updateAuctionEnd(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        // The auction length is set if it hasn't been set yet.
        if (nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd < uint64(block.timestamp) + 600 && 
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd != 0
        ) {
            // In last 10 minutes, extend it by another 10 if a bid is made.
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd += 600;
        }
        
        emit AuctionPeriodUpdated(
            _nftContractAddress,
            _tokenId,
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd
        );
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       UPDATE AUCTION         ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/

    /*
     * Reset all auction related parameters for an NFT.
     * This effectively removes an NFT as an item up for auction
     */
    function _resetAuction(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = 0;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .bidIncreasePercentage = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(
            0
        );
        nftContractAuctions[_nftContractAddress][_tokenId]
            .whitelistedBuyer = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = address(
            0
        );
    }

    /*
     * Reset all bid related parameters for an NFT.
     * This effectively sets an NFT as having no active bids.
     */
    function _resetBids(address _nftContractAddress, uint256 _tokenId)
        internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftRecipient = address(0);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║         UPDATE BIDS          ║
      ╚══════════════════════════════╝*/
    /******************************************************************
     * Internal functions that update bid parameters and reverse bids *
     * to ensure contract only holds the highest bid.                 *
     ******************************************************************/
    function _updateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        IERC20(auctionERC20Token).transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBid = _tokenAmount;
        nftContractAuctions[_nftContractAddress][_tokenId]
            .nftHighestBidder = msg.sender;
    }

    function _reverseAndResetPreviousBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;

        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);
    }

    function _reversePreviousBidAndUpdateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;

        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        _updateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);

        if (prevNftHighestBidder != address(0)) {
            _payout(
                _nftContractAddress,
                _tokenId,
                prevNftHighestBidder,
                prevNftHighestBid
            );
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║         UPDATE BIDS          ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) 
        internal 
    {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        address _erc20Token = nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;
        _resetBids(_nftContractAddress, _tokenId);

        _payFeesAndSeller(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid
        );
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            _nftRecipient,
            _tokenId
        );

        _resetAuction(_nftContractAddress, _tokenId);
        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _erc20Token,
            _nftHighestBid,
            _nftHighestBidder,
            _nftRecipient
        );
    }

    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _highestBid
    ) 
        internal 
    {
        uint256 feesPaid;
        for (
            uint256 i = 0;
            i <
            nftContractAuctions[_nftContractAddress][_tokenId]
                .feeRecipients
                .length;
            i++
        ) {
            uint256 fee = _getPortionOfBid(
                _highestBid,
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .feePercentages[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                _nftContractAddress,
                _tokenId,
                nftContractAuctions[_nftContractAddress][_tokenId]
                    .feeRecipients[i],
                fee
            );
        }
        if (marketplaceFeePercentage != 0) {
            uint256 marketplaceFee = _getPortionOfBid(
                _highestBid,
                marketplaceFeePercentage
            );
            feesPaid = feesPaid + marketplaceFee;
            _payout(
                _nftContractAddress,
                _tokenId,
                marketplaceFeeRecipient,
                marketplaceFee
            );
        }
        _payout(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            (_highestBid - feesPaid)
        );
    }

    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].ERC20Token;
        IERC20(auctionERC20Token).transfer(_recipient, _amount);
    }

    function _offerPayout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount,
        address _bidder
    ) internal {
        address offerERC20Token = nftOffers[_nftContractAddress][_tokenId][_bidder].ERC20Token;
        IERC20(offerERC20Token).transferFrom(_bidder, _recipient, _amount);
    }

    function _payFeesAndSellerForOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint256 _offerAmount,
        address _bidder,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) 
        internal 
    {
        uint256 feesPaid;
        for (uint256 i = 0; i < _feeRecipients.length; i++ ) {
            uint256 fee = _getPortionOfBid(
                _offerAmount,
                _feePercentages[i]
            );
            feesPaid = feesPaid + fee;
            _offerPayout(
                _nftContractAddress,
                _tokenId,
                _feeRecipients[i],
                fee,
                _bidder
            );
        }
        if (marketplaceFeePercentage != 0) {
            uint256 marketplaceFee = _getPortionOfBid(
                _offerAmount,
                marketplaceFeePercentage
            );
            feesPaid = feesPaid + marketplaceFee;
            _offerPayout(
                _nftContractAddress,
                _tokenId,
                marketplaceFeeRecipient,
                marketplaceFee,
                _bidder
            );
        }
        _offerPayout(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            (_offerAmount - feesPaid),
            _bidder
        );
    }

    function _collectionOfferPayout(
        address _nftContractAddress,
        address _recipient,
        uint256 _amount,
        address _bidder
    ) internal {
        address offerERC20Token = collectionOffers[_nftContractAddress][_bidder].ERC20Token;
        IERC20(offerERC20Token).transferFrom(_bidder, _recipient, _amount);
    }
    
    function _payFeesAndSellerForCollectionOffer(
        address _nftContractAddress,
        address _nftSeller,
        uint256 _offerAmount,
        address _bidder,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) 
        internal 
    {
        uint256 feesPaid;
        for (uint256 i = 0; i < _feeRecipients.length; i++ ) {
            uint256 fee = _getPortionOfBid(
                _offerAmount,
                _feePercentages[i]
            );
            feesPaid = feesPaid + fee;
            _collectionOfferPayout(
                _nftContractAddress,
                _feeRecipients[i],
                fee,
                _bidder
            );
        }
        if (marketplaceFeePercentage != 0) {
            uint256 marketplaceFee = _getPortionOfBid(
                _offerAmount,
                marketplaceFeePercentage
            );
            feesPaid = feesPaid + marketplaceFee;
            _collectionOfferPayout(
                _nftContractAddress,
                marketplaceFeeRecipient,
                marketplaceFee,
                _bidder
            );
        }
        _collectionOfferPayout(
            _nftContractAddress,
            _nftSeller,
            (_offerAmount - feesPaid),
            _bidder
        );
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║      SETTLE & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
        nonReentrant()
        isAuctionOver(_nftContractAddress, _tokenId)
    {
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit AuctionSettled(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawAuction(address _nftContractAddress, uint256 _tokenId, address _user, uint256 _nonce, bytes memory _sig)
        external
    {
        verifyUserWithdrawAuction(_nftContractAddress, _tokenId, _user, _nonce, _sig);

        //only the NFT owner can prematurely close and auction
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == _user,
            "Not NFT owner"
        );
        _resetAuction(_nftContractAddress, _tokenId);
        emit AuctionWithdrawn(_nftContractAddress, _tokenId, _user);
    }

    function withdrawBid(address _nftContractAddress, uint256 _tokenId)
        external
        minimumBidNotMade(_nftContractAddress, _tokenId)
    {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;
        require(msg.sender == nftHighestBidder, "Cannot withdraw funds");

        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);

        emit BidWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║      SETTLE & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       UPDATE AUCTION         ║
      ╚══════════════════════════════╝*/
    function updateWhitelistedBuyer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _newWhitelistedBuyer,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) external onlyNftSeller(_nftContractAddress, _tokenId, _user) {
        require(_isASale(_nftContractAddress, _tokenId), "Not a sale");

        verifyUserUpdateWhitelistedBuyer(_nftContractAddress, _tokenId, _newWhitelistedBuyer, _user, _nonce, _sig);

        nftContractAuctions[_nftContractAddress][_tokenId]
            .whitelistedBuyer = _newWhitelistedBuyer;
        // If an underbid is by a non whitelisted buyer, reverse that bid
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBidder;
        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][
            _tokenId
        ].nftHighestBid;
        if (nftHighestBid > 0 && !(nftHighestBidder == _newWhitelistedBuyer)) {
            //we only revert the underbid if the seller specifies a different
            //whitelisted buyer to the highest bider

            _resetBids(_nftContractAddress, _tokenId);

            _payout(
                _nftContractAddress,
                _tokenId,
                nftHighestBidder,
                nftHighestBid
            );
        }

        emit WhitelistedBuyerUpdated(
            _nftContractAddress,
            _tokenId,
            _newWhitelistedBuyer
        );
    }

    function updateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newMinPrice,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    )
        external
        onlyNftSeller(_nftContractAddress, _tokenId, _user)
        minimumBidNotMade(_nftContractAddress, _tokenId)
        minPriceDoesNotExceedLimit(
            nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice,
            _newMinPrice
        )
    {
        require(_newMinPrice > 0, "Price cannot be 0");
        require(
            !_isASale(_nftContractAddress, _tokenId),
            "Not applicable for a sale"
        );

        verifyUserUpdateMinimumPrice(_nftContractAddress, _tokenId, _newMinPrice, _user, _nonce, _sig);

        nftContractAuctions[_nftContractAddress][_tokenId]
            .minPrice = _newMinPrice;

        emit MinimumPriceUpdated(_nftContractAddress, _tokenId, _newMinPrice);

        if (_isMinimumBidMade(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    function updateBuyNowPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newBuyNowPrice,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    )
        external
        nonReentrant()
        onlyNftSeller(_nftContractAddress, _tokenId, _user)
        priceGreaterThanZero(_newBuyNowPrice)
        minPriceDoesNotExceedLimit(
            _newBuyNowPrice,
            nftContractAuctions[_nftContractAddress][_tokenId].minPrice
        )
    {
        verifyUserUpdateBuyNowPrice(_nftContractAddress, _tokenId, _newBuyNowPrice, _user, _nonce, _sig);
        nftContractAuctions[_nftContractAddress][_tokenId]
            .buyNowPrice = _newBuyNowPrice;
        emit BuyNowPriceUpdated(_nftContractAddress, _tokenId, _newBuyNowPrice);
        if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        }
    }

    /*
     * The NFT seller can opt to end an auction by taking the current highest bid.
     */
    function takeHighestBid(
            address _nftContractAddress, 
            uint256 _tokenId, 
            address _user,
            uint256 _nonce, 
            bytes memory _sig
        )
        external
        nonReentrant()
        onlyNftSeller(_nftContractAddress, _tokenId, _user)
    {
        verifyUserTakeHighestBid(_nftContractAddress, _tokenId, _user, _nonce, _sig);
        require(
            _isABidMade(_nftContractAddress, _tokenId),
            "cannot payout 0 bid"
        );
        _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        emit HighestBidTaken(_nftContractAddress, _tokenId);
    }

    /*
     * Query the owner of an NFT deposited for auction
     */
    function ownerOfNFT(address _nftContractAddress, uint256 _tokenId)
        external
        view
        returns (address)
    {
        address nftSeller = nftContractAuctions[_nftContractAddress][_tokenId]
            .nftSeller;
        require(nftSeller != address(0), "NFT not deposited");

        return nftSeller;
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       UPDATE AUCTION         ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
           SIGNATURE VERIFICATION    ║
      ╚══════════════════════════════╝*/

    function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
        return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
        v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function verifyUserCreateAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashCreateAuctionTransaction(address(this), _nftContractAddress, _tokenId, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    function verifyUserCreateSale(
        address _nftContractAddress,
        uint256 _tokenId,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashCreateSaleTransaction(address(this), _nftContractAddress, _tokenId, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    function verifyUserWithdrawAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashWithdrawAuctionTransaction(address(this), _nftContractAddress, _tokenId, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    function verifyUserUpdateWhitelistedBuyer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _newWhitelistedBuyer,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashUpdateWhitelistedBuyerTransaction(address(this), _nftContractAddress, _tokenId, _newWhitelistedBuyer, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    function verifyUserUpdateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newMinPrice,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashUpdateMinimumPriceTransaction(address(this), _nftContractAddress, _tokenId, _newMinPrice, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    function verifyUserUpdateBuyNowPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newBuyNowPrice,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashUpdateBuyNowPriceTransaction(address(this), _nftContractAddress, _tokenId, _newBuyNowPrice, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    function verifyUserTakeHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashTakeHighestBidTransaction(address(this), _nftContractAddress, _tokenId, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    function verifyUserTakeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidder,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashTakeOfferTransaction(address(this), _nftContractAddress, _tokenId, _bidder, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    function verifyUserTakeCollectionOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidder,
        address _user,
        uint256 _nonce,
        bytes memory _sig
    ) internal
    {
        if (_sig.length > 0) {
            address signer = recover(HashTransaction.hashTakeCollectionOfferTransaction(address(this), _nftContractAddress, _tokenId, _bidder, _user, _nonce), _sig);
            require(_nonce > sigTransactionNonce[signer], "NonceErr");
            sigTransactionNonce[signer] = _nonce;
            require(signer == _user, "ApproveErr1");
        }
        else {
            require(msg.sender == _user, "ApproveErr2");
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║   Signature  Verification    ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /**********************************/
    /*╔══════════════════════════════╗
      ║    Set Contract Defaults     ║
      ╚══════════════════════════════╝*/
    /**********************************/

    function setDefaultERC20Token(address defaultTokenAddress) public onlyOwner
    {
        defaultERC20Token = defaultTokenAddress;
    }

    function setMarketplaceFeeRecipient(address recipient) public onlyOwner
    {
        marketplaceFeeRecipient = recipient;
    }

    function setMarketplaceFeePercentage(uint256 feePercentage) public onlyOwner
    {
        marketplaceFeePercentage = feePercentage;
    }   
}

library HashTransaction {
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant CREATE_AUCTION_TYPEHASH = keccak256("CreateAuction(address nftContractAddress,uint256 tokenId,address user,uint256 nonce)");
    bytes32 private constant CREATE_SALE_TYPEHASH = keccak256("CreateSale(address nftContractAddress,uint256 tokenId,address user,uint256 nonce)");
    bytes32 private constant WITHDRAW_AUCTION_TYPEHASH = keccak256("WithdrawAuction(address nftContractAddress,uint256 tokenId,address user,uint256 nonce)");
    bytes32 private constant UPDATE_WHITELISTED_BUYER_TYPEHASH = keccak256("UpdateWhitelistedBuyer(address nftContractAddress,uint256 tokenId,address newWhitelistedBuyer,address user,uint256 nonce)");
    bytes32 private constant UPDATE_MINIMUM_PRICE_TYPEHASH = keccak256("UpdateMinimumPrice(address nftContractAddress,uint256 tokenId,uint128 newMinPrice,address user,uint256 nonce)");
    bytes32 private constant UPDATE_BUY_NOW_PRICE_TYPEHASH = keccak256("UpdateBuyNowPrice(address nftContractAddress,uint256 tokenId,uint128 newBuyNowPrice,address user,uint256 nonce)");
    bytes32 private constant TAKE_HIGHEST_BID_TYPEHASH = keccak256("TakeHighestBid(address nftContractAddress,uint256 tokenId,address user,uint256 nonce)");
    bytes32 private constant TAKE_OFFER_TYPEHASH = keccak256("TakeOffer(address nftContractAddress,uint256 tokenId,address bidder,address user,uint256 nonce)");
    bytes32 private constant TAKE_COLLECTION_OFFER_TYPEHASH = keccak256("TakeCollectionOffer(address nftContractAddress,uint256 tokenId,address bidder,address user,uint256 nonce)");
    uint256 constant chainId = 137;

    function getDomainSeperator(address verifyingContract) public pure returns (bytes32) {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("Lensport Marketplace Domain")),    // name
                keccak256(bytes("6")),                              // version
                chainId,
                verifyingContract
            ));
        return DOMAIN_SEPARATOR;
    }

    function hashCreateAuctionTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(CREATE_AUCTION_TYPEHASH, nftContractAddress, tokenId, user, nonce))));
    }

    function hashCreateSaleTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(CREATE_SALE_TYPEHASH, nftContractAddress, tokenId, user, nonce))));
    }

    function hashWithdrawAuctionTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(WITHDRAW_AUCTION_TYPEHASH, nftContractAddress, tokenId, user, nonce))));
    }

    function hashUpdateWhitelistedBuyerTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address newWhitelistedBuyer, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPDATE_WHITELISTED_BUYER_TYPEHASH, nftContractAddress, tokenId, newWhitelistedBuyer, user, nonce))));
    }

    function hashUpdateMinimumPriceTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, uint128 newMinPrice, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPDATE_MINIMUM_PRICE_TYPEHASH, nftContractAddress, tokenId, newMinPrice, user, nonce))));
    }

    function hashUpdateBuyNowPriceTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, uint128 newBuyNowPrice, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(UPDATE_BUY_NOW_PRICE_TYPEHASH, nftContractAddress, tokenId, newBuyNowPrice, user, nonce))));
    }

    function hashTakeHighestBidTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(TAKE_HIGHEST_BID_TYPEHASH, nftContractAddress, tokenId, user, nonce))));
    }

    function hashTakeOfferTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address bidder, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(TAKE_OFFER_TYPEHASH, nftContractAddress, tokenId, bidder, user, nonce))));
    }

    function hashTakeCollectionOfferTransaction(address verifyingContract, address nftContractAddress, uint256 tokenId, address bidder, address user, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(verifyingContract), keccak256(abi.encode(TAKE_COLLECTION_OFFER_TYPEHASH, nftContractAddress, tokenId, bidder, user, nonce))));
    }

}