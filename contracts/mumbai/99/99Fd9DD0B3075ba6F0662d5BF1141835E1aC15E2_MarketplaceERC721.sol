/**
 *Submitted for verification at polygonscan.com on 2023-06-24
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// File: Marketplace721.sol


pragma solidity ^0.8.0;



contract MarketplaceERC721 is ReentrancyGuard{
    address payable public immutable feeAccount;
    uint public immutable feePercent;
    uint public offerCount;
    uint public auctionCount;

    struct Item{
        address payable seller;
        IERC721 nft;
        uint tokenId;
        uint price;
        bool sold;
    }
    mapping(IERC721 => mapping(uint => Item))public items;

    struct Auction{
        address payable seller;
        address highestBider;
        IERC721 nft;
        uint tokenId;
        uint highestBid;
        uint auctionStartTime;
        uint auctionEndTime;
        bool ended;
    }
    mapping(IERC721 => mapping(uint => Auction))public auctions;

    struct Bid{
        uint bidPrice;
        uint pendingRefunds;
    }
    mapping(address => Bid)public biders;

    event offered(address indexed seller, address indexed nft, uint tokenId, uint price, uint amount);
    event bought(address indexed seller, address indexed buyer, address indexed nft, uint tokenId, uint price);
    event auction(address indexed seller, address indexed nft, uint tokenId, uint amount ,uint basePrice, uint entTimeAuction);
    event bidLog(address indexed bider, address indexed nft, uint tokenId, uint bidPrice, uint pendingRefunds);
    event refundsLog(address indexed refunder, address indexed nft, uint tokenId, uint refund);

    constructor(uint _feePercent){
        feePercent = _feePercent;
        feeAccount = payable(msg.sender);
    }

    function makeOffer(IERC721 _nft, uint _price, uint _tokenId)external nonReentrant{
        require(_price > 0 && _tokenId > 0, "cant be zero");
        require(items[_nft][_tokenId].price == 0, "already listed for sale");
        require(auctions[_nft][_tokenId].highestBid == 0, "item listed for auction");
        offerCount++;
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        items[_nft][_tokenId] = Item(payable(msg.sender), _nft, _tokenId, _price, false);
        emit offered(msg.sender, address(_nft), _tokenId, _price, 1);
    }

    function makeAuction(IERC721 _nft, uint _tokenId, uint _basePrice, uint _duration)external nonReentrant{
        require(_basePrice > 0 && _tokenId > 0 && _duration >= 100, "cant be zero");
        require(auctions[_nft][_tokenId].highestBid == 0, "already started");
        require(items[_nft][_tokenId].price == 0, "item listed for sale");
        auctionCount++;
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        auctions[_nft][_tokenId] = 
        Auction(payable(msg.sender), msg.sender, _nft, _tokenId, _basePrice, block.timestamp, (block.timestamp+_duration), false);
        emit auction(msg.sender, address(_nft), _tokenId, 1, _basePrice, (block.timestamp + _duration));
    }

    function bid(IERC721 _nft, uint _tokenId)external payable nonReentrant{
        require(auctions[_nft][_tokenId].highestBid > 0, "item not on auction");
        require(msg.sender != auctions[_nft][_tokenId].seller, "seller can not bid");
        require(!auctions[_nft][_tokenId].ended && block.timestamp < auctions[_nft][_tokenId].auctionEndTime, "auction ended");
        require(msg.value > auctions[_nft][_tokenId].highestBid, "not enough to set bid");
        auctions[_nft][_tokenId].highestBid = msg.value;
        auctions[_nft][_tokenId].highestBider = msg.sender;
        biders[msg.sender].bidPrice = msg.value;
        biders[msg.sender].pendingRefunds += msg.value;
        emit bidLog(msg.sender, address(_nft), _tokenId, msg.value, biders[msg.sender].pendingRefunds);
    }

    function endAuction(IERC721 _nft, uint _tokenId)external nonReentrant {
        require(auctions[_nft][_tokenId].seller == msg.sender, "only owner can end this auction");
        auctions[_nft][_tokenId].ended = true;
    }

    function refunds(IERC721 _nft, uint _tokenId)external nonReentrant{
        if(msg.sender == auctions[_nft][_tokenId].seller){
            require(auctions[_nft][_tokenId].ended || auctions[_nft][_tokenId].auctionEndTime <= block.timestamp, "auction does not end");
            payable(msg.sender).transfer(auctions[_nft][_tokenId].highestBid);
            emit refundsLog(msg.sender, address(_nft), _tokenId, auctions[_nft][_tokenId].highestBid);

        }
        else if(msg.sender == auctions[_nft][_tokenId].highestBider){
            payable(msg.sender).transfer(biders[msg.sender].pendingRefunds - biders[msg.sender].bidPrice);
            emit refundsLog(msg.sender, address(_nft), _tokenId, biders[msg.sender].pendingRefunds - biders[msg.sender].bidPrice);

        }
        else {
            payable(msg.sender).transfer(biders[msg.sender].pendingRefunds);
            emit refundsLog(msg.sender, address(_nft), _tokenId, biders[msg.sender].pendingRefunds);
        }
    }

    function parchase(IERC721 _nft, uint _tokenId)external payable nonReentrant{
        require(items[_nft][_tokenId].price > 0, "item not exist");
        require(!items[_nft][_tokenId].sold && msg.value == getTotalPrice(_nft, _tokenId), "item sold or not enough ETH to buy");
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId, "");
        items[_nft][_tokenId].seller.transfer(items[_nft][_tokenId].price);
        feeAccount.transfer(getTotalPrice(_nft, _tokenId) - items[_nft][_tokenId].price);
        items[_nft][_tokenId].sold = true;
        emit bought(items[_nft][_tokenId].seller, msg.sender, address(_nft), _tokenId, items[_nft][_tokenId].price);
    }

    function editOffer(IERC721 _nft, uint _tokenId, uint _newPrice)external nonReentrant{
        require(items[_nft][_tokenId].seller == msg.sender && _newPrice > 0, "youre not owner or new price is zero");
        items[_nft][_tokenId].price = _newPrice;
    }

    function unlist(IERC721 _nft, uint _tokenId)external nonReentrant{
        require(items[_nft][_tokenId].seller == msg.sender, "youre not owner");
        _nft.safeTransferFrom(address(this), items[_nft][_tokenId].seller, _tokenId, "");
        delete items[_nft][_tokenId];
        offerCount--;
    }

    function getTotalPrice(IERC721 _nft, uint _tokenId)internal view returns(uint){
        return (items[_nft][_tokenId].price * (100 + feePercent) / 100);
    }
}