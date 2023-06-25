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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: Marketplace1155.sol


pragma solidity ^0.8.0;



contract Marketplace1155 is ReentrancyGuard{
    address payable public immutable feeAccount;
    uint public immutable feePercent;
    uint public offerCount;
    uint public auctionCount;

    struct Item{
        address payable seller;
        IERC1155 nft;
        uint tokenId;
        uint price;
        uint amount;
        bool sold;
    }
    mapping(IERC1155 => mapping(uint => Item))public items;

    struct Auction{
        address payable seller;
        address highestBider;
        IERC1155 nft;
        uint tokenId;
        uint highestBid;
        uint amount;
        uint auctionStartTime;
        uint auctionEndTime;
        bool ended;
    }
    mapping(IERC1155 => mapping(uint => Auction))public auctions;

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


    function makeOffer(IERC1155 _nft, uint _price, uint _tokenId, uint _amount)external nonReentrant{
        require(_price > 0 && _tokenId > 0 && _amount > 0, "cant be zero");
        require(items[_nft][_tokenId].price == 0, "already listed for sale");
        require(auctions[_nft][_tokenId].highestBid == 0, "item listed for auction");
        offerCount++;
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        items[_nft][_tokenId] = Item(payable(msg.sender), _nft, _tokenId, _price, _amount, false);
        emit offered(msg.sender, address(_nft), _tokenId, _price, _amount);
    }

    function makeAuction(IERC1155 _nft, uint _tokenId, uint _amount, uint _basePrice, uint _duration)external nonReentrant{
        require(_basePrice > 0 && _tokenId > 0 && _amount > 0 && _duration >= 100, "cant be zero");
        require(auctions[_nft][_tokenId].highestBid == 0, "already listed");
        require(items[_nft][_tokenId].price == 0, "item listed for sale");
        auctionCount++;
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        auctions[_nft][_tokenId] =
        Auction(payable(msg.sender), msg.sender, _nft, _tokenId, _basePrice, _amount, block.timestamp, (block.timestamp+_duration), false);
        emit auction(msg.sender, address(_nft), _tokenId, _amount, _basePrice, (block.timestamp + _duration));
    }

    function bid(IERC1155 _nft, uint _tokenId)external payable nonReentrant{
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

    function endAuction(IERC1155 _nft, uint _tokenId)external nonReentrant {
        require(auctions[_nft][_tokenId].seller == msg.sender, "only owner can end this auction");
        auctions[_nft][_tokenId].ended = true;
    }

    function refunds(IERC1155 _nft, uint _tokenId)external nonReentrant{
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

    function parchase(IERC1155 _nft, uint _tokenId, uint _amount)external payable nonReentrant{
        require(items[_nft][_tokenId].price > 0, "item not exist");
        require(!items[_nft][_tokenId].sold && msg.value == getTotalPrice(_nft, _tokenId), "item sold or not enough ETH to buy");
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        items[_nft][_tokenId].seller.transfer(items[_nft][_tokenId].price);
        feeAccount.transfer(getTotalPrice(_nft, _tokenId) - items[_nft][_tokenId].price);
        items[_nft][_tokenId].sold = true;
        emit bought(items[_nft][_tokenId].seller, msg.sender, address(_nft), _tokenId, items[_nft][_tokenId].price);
    }

    function editOffer(IERC1155 _nft, uint _tokenId, uint _newPrice)external nonReentrant{
        require(items[_nft][_tokenId].seller == msg.sender && _newPrice > 0, "youre not owner or new price is zero");
        items[_nft][_tokenId].price = _newPrice;
    }

    function unlist(IERC1155 _nft, uint _tokenId)external nonReentrant{
        require(items[_nft][_tokenId].seller == msg.sender, "youre not owner");
        _nft.safeTransferFrom(address(this), items[_nft][_tokenId].seller, _tokenId, items[_nft][_tokenId].amount, "");
        delete items[_nft][_tokenId];
        offerCount--;
    }
    
    function getTotalPrice(IERC1155 _nft, uint _tokenId)internal view returns(uint){
        return (items[_nft][_tokenId].price * (100 + feePercent) / 100);
    }
}