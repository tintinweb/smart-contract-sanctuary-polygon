// SPDX-License-Identifier: None
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./Interfaces/IAuctionHouse.sol";
import "./utils/MarketPlaceWhitelist.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC721 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (
            address receiver, //receiver address of the royality info
            uint256 royaltyAmount //amount he need to pay
        );
}

/**
 * @title An open auction house, enabling collectors and curators to run their own auctions
 */
contract MarketPlace is
    ERC2771Context,
    IAuctionHouse,
    ReentrancyGuard,
    Whitelist,
    Pausable,
    ERC721Holder
{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum amount difference between the last bid amount and the current bid.
    uint256 public minBidIncrementAmount;

    // The fee percentage deduct after auction/sale complete.
    uint256 public platformFeePercentage;

    // A mapping of all of the auctions currently running.
    mapping(uint256 => IAuctionHouse.Auction) public auctions;

    // A mapping of all of the sale order currently running.
    mapping(uint256 => IAuctionHouse.Order) public saleOrder;

    //The currency we need to use for this market place is LNQ
    address immutable public LNQTokenAddress;

    bytes4 private constant INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    Counters.Counter private _auctionIdTracker;
    Counters.Counter private _saleOrderTracker;

    // set all platform fee transsfer to this address
    address public treasury;

    // to check auction created by everyone
    bool public isAuctionRestricted;

    /*
     * Constructor
     */
    constructor(address _LNQAddress, address trustedForwarder)
        ERC2771Context(trustedForwarder)
    {
        require(_LNQAddress != address(0) || trustedForwarder != address(0),"MarketPlace: Invalid zero address");
        LNQTokenAddress = _LNQAddress;
        platformFeePercentage = 500; // for 5% fee
        timeBuffer = 0;
        minBidIncrementAmount = 1e18;
    }

    /**
     * @notice Require that the specified whitelisted collection
     */
    modifier isWhitelisted(address tokenAddress) {
        require(
            whitelisted(tokenAddress),
            "MarketPlace: is not whitelisted collection"
        );
        _;
    }

    /**
     * @notice Require that the specified auction exists
     */
    modifier auctionExists(uint256 auctionId) {
        require(_exists(auctionId, true), "MarketPlace: Auction doesn't exist");
        _;
    }

    /**
     * @notice Require that the specified order exists
     */
    modifier orderExists(uint256 orderId) {
        require(_exists(orderId, false), "MarketPlace: Order doesn't exist");
        _;
    }

    /**
     * @notice Require that the specified valid owner
     */
    modifier onlyValidUser() {
        require(
            owner() == _msgSender() || !isAuctionRestricted,
            "MarketPlace: Only Valid user can create auction"
        );
        _;
    }

    // This is matic receive function
    receive() external payable {
        emit MaticReceive(_msgSender(), msg.value);
    }

    /**
     * @notice Create an Sale oder.
     * @param tokenId NFT id want to sale
     * @param tokenContract pass collection address
     * @param reservePrice want to sale NFT on what Price (in wei if 10LNQ than pass 10**Decimal)
     */
    function createSaleOrder(
        uint256 tokenId,
        address tokenContract,
        uint256 reservePrice
    )
        external
        nonReentrant
        whenNotPaused
        isWhitelisted(tokenContract)
        returns (uint256)
    {
        require(
            IERC165(tokenContract).supportsInterface(INTERFACE_ID),
            "MarketPlace: tokenContract does not support ERC721 interface"
        );
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(
            _msgSender() == IERC721(tokenContract).getApproved(tokenId) ||
                _msgSender() == tokenOwner,
            "MarketPlace: Caller must be approved or owner for token id"
        );
        uint256 orderId = _saleOrderTracker.current();
        saleOrder[orderId] = Order({
            tokenId: tokenId,
            tokenContract: tokenContract,
            reservePrice: reservePrice,
            tokenOwner: tokenOwner
        });
        _saleOrderTracker.increment();
        IERC721(tokenContract).safeTransferFrom(
            tokenOwner,
            address(this),
            tokenId
        );
        emit OrderPlaced(
            orderId,
            tokenId,
            tokenContract,
            reservePrice,
            tokenOwner
        );
        return orderId;
    }

    /**
     * @notice Cancel an order.
     * @dev Transfers the NFT back to the auction creator and emits an AuctionCancelled event
     */
    function cancelOrder(uint256 orderId)
        external
        nonReentrant
        orderExists(orderId)
    {
        require(
            saleOrder[orderId].tokenOwner == _msgSender(),
            "MarketPlace: Can only be called by auction creator or curator"
        );
        _cancelOrder(orderId);
    }

    /**
     * @notice change reserve price.
     * @dev change and set new saling price
     */
    function setOrderReservePrice(uint256 orderId, uint256 reservePrice)
        external
        orderExists(orderId)
    {
        require(
            reservePrice != saleOrder[orderId].reservePrice,
            "MarketPlace: price must be difference"
        );
        require(
            _msgSender() == saleOrder[orderId].tokenOwner,
            "MarketPlace: Must be sale order owner can change"
        );
        saleOrder[orderId].reservePrice = reservePrice;
        emit OrderReservePriceUpdated(
            orderId,
            saleOrder[orderId].tokenId,
            saleOrder[orderId].tokenContract,
            reservePrice
        );
    }

    /**
     * @notice buy order.
     * @param orderId pass order id
     * @param amount amount to buy
     */
    function buyOrder(uint256 orderId, uint256 amount)
        external
        orderExists(orderId)
        nonReentrant
    {
        uint256 platformFee = 0;
        uint256 royaltyFee = 0;
        Order memory order = saleOrder[orderId];
        uint256 tokenOwnerProfit = order.reservePrice;
        require(
            amount == tokenOwnerProfit,
            "MarketPlace: amount must be equal to sale order price"
        );
        delete saleOrder[orderId];
        _handleIncomingBid(tokenOwnerProfit, LNQTokenAddress);
        if (treasury != address(0)) {
            platformFee = (tokenOwnerProfit * platformFeePercentage) / (10000);
            _handleOutgoingBid(treasury, platformFee, LNQTokenAddress);
        }
        if (checkRoyalties(order.tokenContract)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(
                order.tokenContract
            ).royaltyInfo(order.tokenId, tokenOwnerProfit);
            if (receiver != address(0)) {
                _handleOutgoingBid(receiver, royaltyAmount, LNQTokenAddress);
                emit RoyaltyTransafer(
                    order.tokenId,
                    order.tokenContract,
                    receiver,
                    royaltyAmount
                );
                royaltyFee = royaltyAmount;
            }
        }
        tokenOwnerProfit = tokenOwnerProfit - (platformFee + (royaltyFee));
        _handleOutgoingBid(order.tokenOwner, tokenOwnerProfit, LNQTokenAddress);
        IERC721(order.tokenContract).safeTransferFrom(
            address(this),
            _msgSender(),
            order.tokenId
        );
        emit OrderSaleEnded(
            orderId,
            order.tokenId,
            order.tokenContract,
            order.tokenOwner,
            _msgSender(),
            tokenOwnerProfit
        );
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the auctions mapping and emit an AuctionCreated event.
     * @param tokenId NFT id want to sale
     * @param tokenContract pass collection address
     * @param startTime at what time auction will start (if zero auction start at create time)
     * @param duration time period in which auction will run
     * @param reservePrice want to sale NFT on what Price (in wei if 10LNQ than pass 10**Decimal)
     */
    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 startTime,
        uint256 duration,
        uint256 reservePrice
    )
        external
        nonReentrant
        isWhitelisted(tokenContract)
        whenNotPaused
        onlyValidUser
        returns (uint256)
    {
        require(
            IERC165(tokenContract).supportsInterface(INTERFACE_ID),
            "MarketPlace: tokenContract does not support ERC721 interface"
        );
        require(
            startTime >= block.timestamp || startTime == 0,
            "MarketPlace: start time must be greater than equal to current time "
        );
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(
            _msgSender() == IERC721(tokenContract).getApproved(tokenId) ||
                _msgSender() == tokenOwner,
            "MarketPlace: Caller must be approved or owner for token id"
        );
        uint256 auctionId = _auctionIdTracker.current();
        auctions[auctionId] = Auction({
            tokenId: tokenId,
            tokenContract: tokenContract,
            amount: 0,
            startTime: startTime,
            duration: duration,
            firstBidTime: 0,
            reservePrice: reservePrice,
            tokenOwner: tokenOwner,
            bidder: payable(address(0))
        });
        _auctionIdTracker.increment();
        IERC721(tokenContract).safeTransferFrom(
            tokenOwner,
            address(this),
            tokenId
        );
        emit AuctionCreated(
            auctionId,
            tokenId,
            tokenContract,
            duration,
            reservePrice,
            tokenOwner
        );
        return auctionId;
    }

    /**
     * @notice change reserve price of auction .
     * @dev change and set new first bid price
     */
    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external
        auctionExists(auctionId)
    {
        require(
            reservePrice != auctions[auctionId].reservePrice,
            "MarketPlace: price must be difference"
        );
        require(
            _msgSender() == auctions[auctionId].tokenOwner,
            "MarketPlace: Must be auction token owner"
        );
        require(
            auctions[auctionId].firstBidTime == 0,
            "MarketPlace: Auction has already started"
        );
        auctions[auctionId].reservePrice = reservePrice;
        emit AuctionReservePriceUpdated(
            auctionId,
            auctions[auctionId].tokenId,
            auctions[auctionId].tokenContract,
            reservePrice
        );
    }

    /**
     * @notice Create a bid on a token, with a given amount.
     * @dev If provided a valid bid, transfers the provided amount to this contract.
     * @param auctionId pass auction id
     * @param amount amount for next bid amount must be greater than last bid amount and minBidIncrementAmount amount
     */
    function createBid(uint256 auctionId, uint256 amount)
        external
        auctionExists(auctionId)
        nonReentrant
        whenNotPaused
    {
        Auction storage auction = auctions[auctionId];
        address payable lastBidder = auction.bidder;
        require(
            auction.startTime <= block.timestamp,
            "MarketPlace: auction is not started yet"
        );
        require(
            block.timestamp < auction.startTime + (auction.duration),
            "MarketPlace: Auction expired"
        );
        require(
            amount >= auction.reservePrice,
            "MarketPlace: Must send at least reservePrice"
        );
        require(
            amount >= auction.amount + ((minBidIncrementAmount)),
            "MarketPlace: Must send more than last bid by minBidIncrementAmount amount"
        );

        if (auction.firstBidTime == 0) {
            auction.firstBidTime = block.timestamp;
        } else if (lastBidder != address(0)) {
            _handleOutgoingBid(lastBidder, auction.amount, LNQTokenAddress);
            emit RefundPreviousBidder(auctionId,lastBidder,auction.amount,amount);
        }
        auction.amount = amount;
        auction.bidder = payable(_msgSender());
        bool extended = false;
        if (
            auction.startTime + (auction.duration) - (block.timestamp) <
            timeBuffer //if the timegap
        ) {
            // Playing code golf for gas optimization:
            // uint256 expectedEnd = auction.firstBidTime.add(auction.duration);//it needs to be ended
            // uint256 timeRemaining = expectedEnd.sub(block.timestamp);
            // uint256 timeToAdd = timeBuffer.sub(timeRemaining);
            // uint256 newDuration = auction.duration.add(timeToAdd);//extend the time by the 15 min
            uint256 oldDuration = auction.duration;
            auction.duration =
                oldDuration +
                (timeBuffer -
                    ((auction.startTime + (oldDuration)) - (block.timestamp)));
            extended = true;
        }
        bool firstBid = lastBidder == address(0);
        _handleIncomingBid(amount, LNQTokenAddress);
        emit AuctionBid(
            auctionId,
            auction.tokenId,
            auction.tokenContract,
            _msgSender(),
            amount,
            firstBid,
            extended
        );
        if (extended) {
            emit AuctionDurationExtended(
                auctionId,
                auction.tokenId,
                auction.tokenContract,
                auction.duration
            );
        }
    }

    /**
     * @notice End an auction, finalizing the bid on Zora if applicable and paying out the respective parties.
     * @dev If for some reason the auction cannot be finalized (invalid token recipient, for example),
     * The auction is reset and the NFT is transferred back to the auction creator.
     */
    function endAuction(uint256 auctionId)
        external
        auctionExists(auctionId)
        nonReentrant
    {
        Auction memory auction = auctions[auctionId];
        require(
            uint256(auction.firstBidTime) != 0,
            "MarketPlace: Auction hasn't begun"
        );
        if (auction.tokenOwner != _msgSender()) {
            require(
                block.timestamp >= auction.startTime + (auction.duration),
                "MarketPlace: Auction hasn't completed"
            );
        }
        uint256 platformFee = 0;
        uint256 royaltiyFee = 0;
        uint256 tokenOwnerProfit = auction.amount;
        delete auctions[auctionId];
        if (treasury != address(0)) {
            platformFee = (tokenOwnerProfit * platformFeePercentage) / (10000);
            _handleOutgoingBid(treasury, platformFee, LNQTokenAddress);
        }
        if (checkRoyalties(auction.tokenContract)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(
                auction.tokenContract
            ).royaltyInfo(auction.tokenId, tokenOwnerProfit);
            if (receiver != address(0)) {
                _handleOutgoingBid(receiver, royaltyAmount, LNQTokenAddress);
                emit RoyaltyTransafer(
                    auction.tokenId,
                    auction.tokenContract,
                    receiver,
                    royaltyAmount
                );
                royaltiyFee = royaltyAmount;
            }
        }
        tokenOwnerProfit = tokenOwnerProfit - (platformFee + royaltiyFee);
        _handleOutgoingBid(
            auction.tokenOwner,
            tokenOwnerProfit,
            LNQTokenAddress
        );
        IERC721(auction.tokenContract).safeTransferFrom(
            address(this),
            auction.bidder,
            auction.tokenId
        );
        emit AuctionEnded(
            auctionId,
            auction.tokenId,
            auction.tokenContract,
            auction.tokenOwner,
            auction.bidder,
            tokenOwnerProfit
        );
    }

    /**
     * @notice Cancel an auction.
     * @dev Transfers the NFT back to the auction creator and emits an AuctionCancelled event
     */
    function cancelAuction(uint256 auctionId)
        external
        nonReentrant
        auctionExists(auctionId)
    {
        require(
            auctions[auctionId].tokenOwner == _msgSender(),
            "MarketPlace: Can only be called by auction creator or curator"
        );
        require(
            uint256(auctions[auctionId].firstBidTime) == 0,
            "MarketPlace: Can't cancel an auction once it's begun"
        );
        _cancelAuction(auctionId);
    }

    //// Addmin Funcions

    /**
     * @dev Triggers smart contract to stopped state
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns smart contract to normal state
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Set the treasury address
     */
    function SetTreasuryAddress(address _treasury) external onlyOwner {
        require(_treasury != address(0),"MarketPlace: invalid zero address");
        emit TreasuryAddressChanged(treasury, _treasury);
        treasury = _treasury;
    }

    /**
     *@dev owner can platform fee percentage
     */
    function changePlatformFeePercentage(uint256 _platformFeePercentage)
        external
        onlyOwner
    {
        require(
            platformFeePercentage != _platformFeePercentage,
            "MarketPlace: platformFeePercentage is already same"
        );
        emit platFormFeeChanged(platformFeePercentage, _platformFeePercentage);
        platformFeePercentage = _platformFeePercentage;
    }

    /**
     *@dev owner can change AuctionCreatorState
     */
    function changeAuctionCreatorState(bool _isAuctionRestricted)
        external
        onlyOwner
    {
        require(
            _isAuctionRestricted != isAuctionRestricted,
            "MarketPlace: state is already same"
        );
        emit AuctionCreatorStateChanged(
            isAuctionRestricted,
            _isAuctionRestricted
        );
        isAuctionRestricted = _isAuctionRestricted;
    }

    /**
     *@dev owner can set buffer time
     */
    function changeBufferTime(uint256 _timeBuffer) external onlyOwner {
        require(
            timeBuffer != _timeBuffer,
            "MarketPlace: _timeBuffer is already same"
        );
        emit BufferTimeChanged(timeBuffer, _timeBuffer);
        timeBuffer = _timeBuffer;
    }

    /**
     *@dev owner change minimum bid increment amount
     */
    function changeMinBidIncrementAmount(uint256 _minBidIncrementAmount)
        external
        onlyOwner
    {
        require(
            minBidIncrementAmount != _minBidIncrementAmount,
            "MarketPlace: minBidIncrementAmount is already same"
        );
        emit MinBidIncrementAmountChanged(
            minBidIncrementAmount,
            _minBidIncrementAmount
        );
        minBidIncrementAmount = _minBidIncrementAmount;
    }

    /// internal Function

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        sender = ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes memory)
    {
        return ERC2771Context._msgData();
    }

    function checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC165(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    /**
     * @dev Given an amount and a currency, transfer the currency to this contract.
     */
    function _handleIncomingBid(uint256 amount, address currency) internal {
        if (amount > 0) {
            //We must check the balance that was actually transferred to the auction,
            // as some tokens impose a transfer fee and would not actually transfer the
            // full amount to the market, resulting in potentally locked funds
            require(currency != address(0),"MarketPlace: invalid currency address");
            IERC20 token = IERC20(currency);
            uint256 beforeBalance = token.balanceOf(address(this));
            token.safeTransferFrom(_msgSender(), address(this), amount);
            uint256 afterBalance = token.balanceOf(address(this));
            require(
                beforeBalance + (amount) == afterBalance,
                "Token transfer call did not transfer expected amount"
            );
        }
    }

    function _handleOutgoingBid(
        address to,
        uint256 amount,
        address currency
    ) internal {
        if (amount > 0) {
            require(currency != address(0),"MarketPlace: Invalid zero address");
            IERC20(currency).safeTransfer(to, amount);
        }
    }

    /**
     * @dev Cancel the Auction by the given auctionId
     */
    function _cancelAuction(uint256 auctionId) internal {
        Auction memory auction = auctions[auctionId];
        address tokenOwner = auction.tokenOwner;
        delete auctions[auctionId];
        IERC721(auction.tokenContract).safeTransferFrom(
            address(this),
            tokenOwner,
            auction.tokenId
        );
        emit AuctionCancelled(
            auctionId,
            auction.tokenId,
            auction.tokenContract,
            tokenOwner
        );
        
    }

    /**
     * @dev Cancel the Order by the the orderId
     */
    function _cancelOrder(uint256 orderId) internal {
        Order memory order = saleOrder[orderId];
        address tokenOwner = order.tokenOwner;
        delete saleOrder[orderId];
        IERC721(order.tokenContract).safeTransferFrom(
            address(this),
            tokenOwner,
            order.tokenId
        );
        emit OrderCancelled(
            orderId,
            order.tokenId,
            order.tokenContract,
            order.tokenOwner
        );
    }

    /**
     * @dev Check if the Auction / order existed or not
     */
    function _exists(uint256 id, bool isAuction) internal view returns (bool) {
        if (isAuction) {
            return auctions[id].tokenOwner != address(0);
        }
        return saleOrder[id].tokenOwner != address(0);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: None
pragma solidity 0.8.11;

/**
 * @title Interface for Auction
 */
interface IAuctionHouse {
    // Auction Struct
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract_msg
        address tokenContract;
        // The current highest bid amount
        uint256 amount;
        // the auction starting Time
        uint256 startTime;
        // The length of time to run the auction for, after the state time
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner; //Owner of the token address
        // The address of the current highest bid
        address payable bidder; //address of current highest bidder
    }

    // simple sale Order struct
    struct Order {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // The minimum price of the sale
        uint256 reservePrice;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
    }
    // emit when order place
    event OrderPlaced(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice,
        address tokenOwner
    );

    //emit when auction created
    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner
    );

    //emit when order price update
    event OrderReservePriceUpdated(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    // emit when auction price update
    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    // emit when auction bid place
    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid,
        bool extended
    );

    // emit when amount is refunded to previous bidder
    event RefundPreviousBidder(
        uint256 indexed auctionId,
        address bidder,
        uint256 amount,
        uint256 nextBidAmount
    );


    // emit when auction duration extended
    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration
    );
    // emit when sale order end
    event OrderSaleEnded(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address Buyer,
        uint256 amount
    );
    // emit when auction ended
    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address winner,
        uint256 amount
    );
    // emit when order canceleed
    event OrderCancelled(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );
    // emit when Auction cancel
    event AuctionCancelled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );

    // emit when Auction cancel
    event RoyaltyTransafer(
        uint256 indexed tokenId,
        address indexed tokenContract,
        address indexed to,
        uint256 amount
    );
    event BufferTimeChanged(uint256 _oldtime, uint256 _newtime);
    event platFormFeeChanged(uint256 _oldFee, uint256 _newFee);
    event AuctionCreatorStateChanged(bool _oldValue, bool _newValue);
    event MinBidIncrementAmountChanged(
        uint256 _oldIncreament,
        uint256 _newIncrement
    );
    event TreasuryAddressChanged(
        address _oldTreasuryAddress,
        address _newTreasuryAddress
    );
    event MaticReceive(address _spender, uint256 amount);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) private whitelistedMap;

    event Whitelisted(address indexed account, bool isWhitelisted);

    /**
     * @dev Whitelist MarketPlace and any token approval contract address.
     */
    function addCollectionAddress(address _address) external onlyOwner {
        require(
            !whitelistedMap[_address],
            "MarketPlace WhiteList: address already whitelisted"
        );
        whitelistedMap[_address] = true;
        emit Whitelisted(_address, true);
    }

    /**
     * @dev remove from Whitelist.
     */
    function removeCollectionAddress(address _address) external onlyOwner {
        require(
            whitelistedMap[_address],
            "MarketPlace WhiteList: address already removed"
        );
        whitelistedMap[_address] = false;
        emit Whitelisted(_address, false);
    }

    /**
     * @dev check address whitelisted or not
     */
    function whitelisted(address _address) public view returns (bool) {
        return whitelistedMap[_address];
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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