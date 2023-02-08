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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Auction contract which allow to place bids on cascade auctions
 * @dev This is only the auction's order book.
 * The contract implements a set of auctions for different artwork items.
 * Each artwork has one item up for auction at a time.
 * Bidders can place bids on an individual item of an artwork for at least MIN_BID_SPREAD more than the previous one.
 * With each bid, the end time of the auction increases. The auction ends when the block's timestamp exceeds the deadline without any other bid.
 * During the free bid period, the deadline does not increase past 4 days since the start, no matter the amount of bids.
 * Anyone can close the sale (ideally the team) by calling closeSale() after the end, locking in the winner.
 * When the auction of an artwork's item ends, the next auction for the same artwork starts (until the supply is exhausted).
 * Sales are launched for each artwork with a specified starting price and minimum bid spread.
 * When someone gets outbid, they can bid again by sending only the difference with their last bid, their available balance will be deducted accordingly.
 * The contract owner can withdraw the profit from the contract.
 * When you bid on an ended auction, the contract close the auction and start a new one if there are still auctions available
 */
contract AuctionOrderBook is Ownable {
    uint8 public constant ARTWORK_COUNT = 34;
    uint128 public constant NEXT_SALE_PRICE_PERCENTAGE = 75;
    uint8[ARTWORK_COUNT] public SUPPLY;

    uint56 public immutable FREE_BID_PERIOD;
    uint128 public immutable MIN_BID_SPREAD;

    mapping(address => uint128) private availableBalances;
    uint256 private profitAmount;

    struct Auction {
        uint56 endAt;
        uint56 startedAt;
        address highestBidder;
        uint128 highestBid;
    }

    struct Auctions {
        uint8 currentAuction;
        Auction[] auctions;
    }

    Auctions[ARTWORK_COUNT] private artworkToAuctions;

    event Start(
        uint256 artworkId,
        uint8 currentAuction,
        uint128 amount,
        uint56 endAt
    );
    event Bid(
        uint256 artworkId,
        uint8 currentAuction,
        address bidder,
        uint128 amount,
        uint56 endAt
    );
    event End(
        uint256 artworkId,
        uint8 currentAuction,
        address bidder,
        uint128 lastBid
    );

    constructor(
        uint8[ARTWORK_COUNT] memory _supply,
        uint256 _startPrice,
        uint256 _minBidSpread,
        uint256 _freeBidPeriod
    ) {
        SUPPLY = _supply;
        MIN_BID_SPREAD = uint128(_minBidSpread);
        FREE_BID_PERIOD = uint56(_freeBidPeriod);

        for (uint256 i; i < _supply.length; i++) {
            _launchSale(i, _startPrice, block.timestamp);
        }
    }

    /**
     * @dev Allows a user to place a bid on an item up for auction.
     * @param _artworkId The ID of the item to bid on.
     * @param _bidAmount The amount of the bid.
     */
    function bid(uint256 _artworkId, uint256 _bidAmount) external payable {
        Auctions storage auctions = artworkToAuctions[_artworkId];

        for (
            uint256 i = auctions.currentAuction;
            i < SUPPLY[_artworkId] &&
                block.timestamp > auctions.auctions[i].endAt;
            i++
        ) {
            _closeSale(_artworkId);
        }
        require(
            auctions.currentAuction < SUPPLY[_artworkId],
            "No auction for this artwork"
        );

        Auction storage auction = auctions.auctions[auctions.currentAuction];

        uint128 previousBid = auction.highestBid;
        address previousBidder = auction.highestBidder;

        require(
            msg.sender != previousBidder,
            "You are already the best bidder"
        );

        // Must increase by at least MIN_BID_SPREAD
        require(
            uint128(_bidAmount) >= previousBid + MIN_BID_SPREAD,
            "Increase at least MIN_BID_SPREAD"
        );

        uint128 availableBalance = availableBalances[msg.sender] +
            uint128(msg.value);

        require(
            availableBalance >= uint128(_bidAmount),
            "Insufficient funds sent"
        );

        availableBalances[msg.sender] = availableBalance - uint128(_bidAmount);

        // Register the bid
        auction.highestBidder = msg.sender;
        auction.highestBid = uint128(_bidAmount);

        // If free bid period is over, increase the deadline
        if (block.timestamp > auction.startedAt + FREE_BID_PERIOD) {
            auction.endAt = uint56(block.timestamp) + 6 hours;
        }

        if (previousBidder == address(0)) {
            // First bidder should lead auction for 12 hours after free bid period to win
            auction.endAt = auction.startedAt + FREE_BID_PERIOD + 12 hours;
        } else {
            // Give amount back to the previous bidder
            availableBalances[previousBidder] += previousBid;
        }

        emit Bid(
            _artworkId,
            auctions.currentAuction,
            msg.sender,
            uint128(_bidAmount),
            auction.endAt
        );
    }

    /**
     * @dev Allows a user to withdraw their available balance.
     */
    function withdraw() external {
        uint128 availableBalance = availableBalances[msg.sender];
        availableBalances[msg.sender] = 0;
        payable(msg.sender).transfer(availableBalance);
    }

    /**
     * @dev Allows the contract owner to withdraw profit from the contract.
     */
    function withdrawProfit() external onlyOwner {
        payable(msg.sender).transfer(profitAmount);
    }

    /**
     * @dev Returns the available balance of a given user.
     * @param _user The address of the user to check.
     * @return The user's available balance.
     */
    function availableBalanceOf(address _user) external view returns (uint128) {
        return availableBalances[_user];
    }

    /**
     * @dev Returns the total supply of a specific artwork
     * @param _artworkId The ID of the artwork whose supply is being retrieved
     * @return The total supply of the artwork
     */
    function supplyOf(uint256 _artworkId) external view returns (uint8) {
        return SUPPLY[_artworkId];
    }

    /**
     * @dev Returns the current auction details for a specific artwork
     * @param _artworkId The ID of the artwork whose auction details are being retrieved
     * @return The current auction details for the artwork
     */
    function currentAuctionOf(
        uint256 _artworkId
    ) external view returns (Auction memory, uint8) {
        Auctions memory auctions = artworkToAuctions[_artworkId];

        require(
            auctions.currentAuction < SUPPLY[_artworkId],
            "No auction for this artwork"
        );

        for (
            uint8 i = auctions.currentAuction;
            i < auctions.auctions.length;
            i++
        ) {
            if (block.timestamp < auctions.auctions[i].endAt) {
                return (auctions.auctions[i], i);
            }
        }

        // If no auction is currently running, return the last one
        return (
            auctions.auctions[auctions.currentAuction],
            auctions.currentAuction
        );
    }

    /**
     * @dev Returns the current auction details for a specific artwork & version
     * @param _artworkId id of the artwork
     * @param _version version of the artwork
     * @return The current auction details for the artwork
     */
    function auctionOf(
        uint256 _artworkId,
        uint256 _version
    ) external view returns (Auction memory) {
        require(
            _version <= artworkToAuctions[_artworkId].currentAuction,
            "No auction for this artwork"
        );

        return artworkToAuctions[_artworkId].auctions[_version];
    }

    /**
     * @dev Launches a new auction for the given artworkId, setting the initial bid to _startPrice
     * and the initial auction end time to now + FREE_BID_PERIOD.
     * @dev Assumes currentAuction has already been incremented.
     * @param _artworkId The ID of the artwork being auctioned
     * @param _startPrice The initial bid price for the auction
     */
    function _launchSale(
        uint256 _artworkId,
        uint256 _startPrice,
        uint256 _startAt
    ) private {
        Auction[] storage auctions = artworkToAuctions[_artworkId].auctions;

        Auction memory auction;
        uint56 _now = uint56(block.timestamp);
        auction.startedAt = uint56(_startAt);
        auction.endAt = _now + FREE_BID_PERIOD;
        auction.highestBid = uint128(_startPrice);
        auctions.push(auction);

        emit Start(
            _artworkId,
            uint8(auctions.length - 1),
            uint128(_startPrice),
            uint56(block.timestamp) + FREE_BID_PERIOD
        );
    }

    /**
     * @dev Closes the current auction for a given artwork and starts the next one.
     * @param _artworkId The ID of the artwork.
     */
    function _closeSale(uint256 _artworkId) private {
        Auctions storage auctions = artworkToAuctions[_artworkId];

        require(
            auctions.currentAuction < SUPPLY[_artworkId],
            "No auction for this artwork"
        );

        Auction storage auction = auctions.auctions[auctions.currentAuction];

        require(block.timestamp >= auction.endAt, "Auction still running");

        profitAmount += auction.highestBid;

        emit End(
            _artworkId,
            auctions.currentAuction,
            auction.highestBidder,
            auction.highestBid
        );

        // When currentAuction is equal to SUPPLY, there is no item left to auction off
        if (++auctions.currentAuction < SUPPLY[_artworkId]) {
            // The price of the next item starts at NEXT_SALE_PRICE_PERCENTAGE % of the previous item's closing price
            _launchSale(
                _artworkId,
                ((auction.highestBid * NEXT_SALE_PRICE_PERCENTAGE) / 100) -
                    MIN_BID_SPREAD,
                auction.endAt
            );
        }
    }
}