// SPDX-License-Identifier:  Multiverse Expert
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface NFT_POOL {
    function depositNFT(
        address nftContract,
        uint256 tokenId,
        address ownner
    ) external;

    function transferNFT(
        address nftContract,
        address to,
        uint256 tokenId
    ) external;
}

interface INFT_CORE {
    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);
}

contract UNQSMarket is ReentrancyGuard, Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _orderIds;
    Counters.Counter public _auctionIds;

    uint256 public auctionFees = 1000;
    uint256 public feesRate = 425;

    address public adminWallet;
    address public nftPool;

    constructor() {}

    /************************** Structs *********************/

    struct Order {
        address nftContract;
        uint256 orderId;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        address buyWithTokenContract;
        bool listed;
        bool sold;
    }

    struct Auction {
        address nftContract;
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 startPrice;
        address buyWithTokenContract;
        bool started;
        bool ended;
        uint256 endAt;
        bool sold;
    }

    struct HighestBid {
        address highestBidder;
        uint256 bidAmount;
    }

    /************************** Mappings *********************/

    mapping(uint256 => Order) public idToOrder;
    mapping(uint256 => Auction) public idToAuction;
    mapping(uint256 => mapping(address => uint256)) public bidsToAuction;
    mapping(uint256 => HighestBid) public auctionHighestBid;
    mapping(address => bool) private isWhitelist;

    /************************** Events *********************/

    event OrderCreated(
        address nftContract,
        uint256 indexed orderId,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 price,
        address buyWithTokenContract,
        bool listed,
        bool sold
    );

    event OrderCanceled(
        uint256 orderId,
        uint256 tokenId,
        address seller,
        address owner,
        bool listed
    );

    event OrderSuccessful(
        uint256 orderId,
        uint256 tokenId,
        address seller,
        address owner,
        bool listed,
        bool sold
    );

    event StartAuction(
        address nftContract,
        uint256 auctionId,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 startPrice,
        address buyWithTokenContract,
        bool started,
        bool ended,
        uint256 endAt,
        bool sold
    );

    event Bid(uint256 auctionId, address indexed sender, uint256 amount);
    event End(uint256 auctionId, address winner, uint256 amount, bool ended);
    event Withdraw(address bidder, uint256 auctionId, uint256 amount);

    /******************* Setup Functions *********************/

    //@Admin if something happen Admin can call this function to pause txs
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateNFTPool(address _nftPool)
        public
        onlyOwner
    {
        nftPool = _nftPool;
    }

    //@Admin call to set whitelists
    function setWhitelist(address whitelistAddress)
        public
        onlyOwner
    {
        require(
            !isWhitelist[whitelistAddress],
            "User already exist in whitelist"
        );
        isWhitelist[whitelistAddress] = true;
    }

    //@Admin call to update market fee
    function updateFeesRate(uint256 feeRate)
        public
        onlyOwner
    {
        // feeAmount will be / by 10000
        // if you want 5% feeRate should be 500
        feesRate = feeRate;
    }

    //@Admin call to update market fee
    function updateAdminWallet(address _adminWallet)
        public
        onlyOwner
    {
        // feeAmount will be / by 10000
        // if you want 5% feeRate should be 500
        adminWallet = _adminWallet;
    }

    //@Admin call to update auction fee
    function updateAuctionFeesRate(uint256 newRate)
        public
        onlyOwner
    {
        require(newRate >= 500);
        auctionFees = newRate;
    }

    /*******************Read Functions *********************/

    // for frontend \\
    // Listing Items
    // Items info

    /******************* Buy/Sell/Cancel Functions *********************/

    /* Places an item for sale on the marketplace */
    function createOrder(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address buyWithTokenContract
    ) public nonReentrant {
        // set require ERC721 approve below
        require(price > 100, "Price must be at least 100 wei");
        _orderIds.increment();
        uint256 orderId = _orderIds.current();
        idToOrder[orderId] = Order(
            nftContract,
            orderId,
            tokenId,
            msg.sender,
            nftPool,
            price,
            buyWithTokenContract,
            true,
            false
        );

        // tranfer NFT ownership to Market contract
        IERC721(nftContract).safeTransferFrom(msg.sender, nftPool, tokenId);
        NFT_POOL(nftPool).depositNFT(nftContract, tokenId, msg.sender);

        emit OrderCreated(
            nftContract,
            orderId,
            tokenId,
            msg.sender,
            nftPool,
            price,
            buyWithTokenContract,
            true,
            false
        );
    }

    /* Seller call this to cancel placed order */
    function cancelOrder(uint256 orderId) public {
        require(!idToOrder[orderId].sold, "Sold item");
        require(idToOrder[orderId].listed, "Item is not listed");
        // check if the caller is seller
        require(idToOrder[orderId].seller == msg.sender);

        //Transfer back to the real owner.
        NFT_POOL(nftPool).transferNFT(
            idToOrder[orderId].nftContract,
            msg.sender,
            idToOrder[orderId].tokenId
        );

        //update mapping info
        idToOrder[orderId].owner = msg.sender;
        idToOrder[orderId].seller = address(0);
        idToOrder[orderId].listed = false;

        emit OrderCanceled(
            idToOrder[orderId].orderId,
            idToOrder[orderId].tokenId,
            address(0),
            msg.sender,
            false
        );
    }

    /* Creates the sale of a marketplace order */
    /* Transfers ownership of the order, as well as funds between parties */
    function buyOrder(uint256 orderId) public nonReentrant {
        require(!idToOrder[orderId].sold, "Status: Sold item");
        require(idToOrder[orderId].listed, "Status: It's not listed item");

        uint256 price = idToOrder[orderId].price;
        uint256 tokenId = idToOrder[orderId].tokenId;
        address buyWithTokenContract = idToOrder[orderId].buyWithTokenContract;

        (address creator, uint256 royaltyFee) = INFT_CORE(
            idToOrder[orderId].nftContract
        ).getRoyaltyInfo(tokenId, price);
        uint256 fee = (price * feesRate) / 10000;
        uint256 amount = (price - fee) - royaltyFee;

        //if not the whitelists, transfer fee to platform.
        if (!isWhitelist[msg.sender]) {
            IERC20(buyWithTokenContract).transferFrom(
                msg.sender,
                adminWallet,
                fee
            );
        }

        //transfer Royalty amount
        IERC20(buyWithTokenContract).transferFrom(
            msg.sender,
            creator,
            royaltyFee
        );

        //Transfer token to nft seller.
        IERC20(buyWithTokenContract).transferFrom(
            msg.sender,
            idToOrder[orderId].seller,
            amount
        );

        // call NFT pool to transfer the nft to buyer;
        NFT_POOL(nftPool).transferNFT(
            idToOrder[orderId].nftContract,
            msg.sender,
            tokenId
        );

        //update status of this orderId
        idToOrder[orderId].owner = msg.sender;
        idToOrder[orderId].sold = true;
        idToOrder[orderId].listed = false;

        emit OrderSuccessful(
            orderId,
            tokenId,
            address(0),
            msg.sender,
            false,
            true
        );
    }

    /******************* English Auction Functions *********************/

    //seller call this to start auction
    function startAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        address buyWithTokenContract,
        uint256 dateAmount
    ) external nonReentrant {
        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();

        //lock nft token to the pool
        IERC721(nftContract).transferFrom(msg.sender, nftPool, tokenId);

        //declare the end time.
        uint256 endAt = block.timestamp + dateAmount;
        //insert auction data to mapping
        idToAuction[auctionId] = Auction(
            nftContract,
            auctionId,
            tokenId,
            msg.sender,
            nftPool,
            startPrice,
            buyWithTokenContract,
            true,
            false,
            endAt,
            false
        );

        //the first bidder is auction creator
        auctionHighestBid[auctionId].highestBidder = msg.sender;
        //the first bid is start price
        auctionHighestBid[auctionId].bidAmount = startPrice;

        emit StartAuction(
            nftContract,
            auctionId,
            tokenId,
            msg.sender,
            nftPool,
            startPrice,
            buyWithTokenContract,
            true,
            false,
            endAt,
            false
        );
    }

    // bidder call this to bid
    function bid(uint256 auctionId, uint256 bidAmount) external {
        address buyWithTokenContract = idToAuction[auctionId]
            .buyWithTokenContract;
        uint256 highestBid = auctionHighestBid[auctionId].bidAmount;

        require(idToAuction[auctionId].started, "not started");
        require(block.timestamp < idToAuction[auctionId].endAt, "ended");
        require(bidAmount > highestBid, "bid amount < highest");

        if (msg.sender != address(0)) {
            //calculate left amount
            uint256 transferAmount;
            if (bidsToAuction[auctionId][msg.sender] > 0) {
                transferAmount =
                    bidAmount -
                    bidsToAuction[auctionId][msg.sender];
            } else {
                transferAmount = bidAmount;
            }
            //transfer amount of bid to this contract
            IERC20(buyWithTokenContract).transferFrom(
                msg.sender,
                address(this),
                transferAmount
            );
            // user's lastest bid will always be the highest
            bidsToAuction[auctionId][msg.sender] = bidAmount;
            // Put the hihest bid to mapping
            auctionHighestBid[auctionId].bidAmount = bidAmount;
            auctionHighestBid[auctionId].highestBidder = msg.sender;
        }
        emit Bid(auctionId, msg.sender, bidAmount);
    }

    //seller or winner call this to claim their item/eth
    function end(uint256 auctionId) external nonReentrant {
        require(idToAuction[auctionId].started, "not started");
        require(
            block.timestamp >= idToAuction[auctionId].endAt,
            "Auction's not past end date"
        );
        require(!idToAuction[auctionId].ended, "Auction's already ended");

        //the last bidder is always the highest one.
        uint256 highestBid = auctionHighestBid[auctionId].bidAmount;
        address highestBidder = auctionHighestBid[auctionId].highestBidder;
        address seller = idToAuction[auctionId].seller;
        address buyWithTokenContract = idToAuction[auctionId]
            .buyWithTokenContract;
        uint256 fee = (highestBid * auctionFees) / 10000;
        uint256 transferAmount = highestBid - fee;

        if (highestBidder != address(0)) {
            //transfer nft to winner
            NFT_POOL(nftPool).transferNFT(
                idToAuction[auctionId].nftContract,
                highestBidder,
                idToAuction[auctionId].tokenId
            );
            if (!isWhitelist[msg.sender]) {
                // tranfer winner's bid to seller
                IERC20(buyWithTokenContract).transfer(seller, transferAmount);
            } else {
                IERC20(buyWithTokenContract).transfer(seller, highestBid);
            }
        } else {
            //transfer nft to seller if no winner
            NFT_POOL(nftPool).transferNFT(
                idToAuction[auctionId].nftContract,
                seller,
                idToAuction[auctionId].tokenId
            );
        }

        idToAuction[auctionId].ended = true;

        emit End(auctionId, highestBidder, highestBid, true);
    }

    function bidderWithdraw(uint256 auctionId) external nonReentrant {
        require(
            block.timestamp >= idToAuction[auctionId].endAt,
            "Auction's not past end date"
        );
        require(idToAuction[auctionId].ended, "Auction not ended");
        address buyWithTokenContract = idToAuction[auctionId]
            .buyWithTokenContract;
        uint256 transferAmount = bidsToAuction[auctionId][msg.sender];
        address highestBidder = auctionHighestBid[auctionId].highestBidder;
        require(msg.sender != highestBidder, "Highest Bidder can't withdraw");

        IERC20(buyWithTokenContract).transfer(msg.sender, transferAmount);

        emit Withdraw(msg.sender, auctionId, transferAmount);
    }

    /******************* MUST_HAVE Functions *********************/

    /* tranfer to owner address*/
    function transferERC20(
        address _contractAddress,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20 _token = IERC20(_contractAddress);
        _token.transfer(_to, _amount);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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