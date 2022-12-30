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

contract AuctionOrderBook is Ownable {
    uint8[] private SUPPLY;
    uint128 public constant FREE_BID_PERIOD = 3 days;
    uint128 public immutable START_PRICE;

    struct Item {
        uint128 endAt;
        uint128 startedAt;
        address highestBidder;
        uint128 highestBid;
        uint128 bidCount;
    }

    struct Items {
        uint8 currentAuction;
        Item[] items;
    }

    mapping(uint256 => Items) public tokenIdToItems;

    event Start(uint256 tokenId, uint8 currentAuction, uint256 startPrice);
    event Bid(
        uint256 tokenId,
        uint8 currentAuction,
        address indexed bidder,
        uint128 amount,
        uint128 endAt
    );
    event End(
        uint256 tokenId,
        uint8 currentAuction,
        address indexed bidder,
        uint128 lastBid
    );

    constructor(uint8[] memory _supply, uint128 _startPrice) {
        SUPPLY = _supply;
        START_PRICE = _startPrice;

        for (uint256 i; i < _supply.length; i++) {
            _launchSale(i);
            emit Bid(
                i,
                0,
                address(0),
                START_PRICE,
                uint128(block.timestamp) + FREE_BID_PERIOD
            );
        }
    }

    function bid(uint256 _tokenId) external payable {
        uint8 currentAuction = tokenIdToItems[_tokenId].currentAuction;
        Item storage item = tokenIdToItems[_tokenId].items[currentAuction];

        uint128 previousBid = item.highestBid;
        address previousBidder = item.highestBidder;

        require(
            msg.value >= previousBid + 0.5 ether,
            "must be superior by at least 0.5 ETH than previous bid"
        );

        // register bid
        item.highestBidder = msg.sender;
        item.highestBid = uint128(msg.value);

        // if free bid period is over -> increase deadline
        if (block.timestamp > item.startedAt + FREE_BID_PERIOD) {
            require(block.timestamp < item.endAt, "ended");
            item.bidCount++;
            _increaseDeadline(item);
        }
        // if the deadline was never set -> we set the deadline
        else if (item.bidCount == 0) {
            item.bidCount++;
            item.endAt = item.startedAt + FREE_BID_PERIOD + 24 hours;
        }

        // if it's not the first bid -> give eth back to the previous bidder
        if (previousBidder != address(0)) {
            payable(previousBidder).transfer(previousBid);
        }

        emit Bid(
            _tokenId,
            currentAuction,
            msg.sender,
            uint128(msg.value),
            item.endAt
        );
    }

    function _launchSale(uint256 _tokenId) private {
        Item memory item;
        uint128 _now = uint128(block.timestamp);
        item.startedAt = _now;
        item.endAt = _now + FREE_BID_PERIOD;
        item.highestBid = START_PRICE;
        tokenIdToItems[_tokenId].items.push(item);
    }

    function closeSale(uint256 _tokenId) external {
        uint8 currentAuction = tokenIdToItems[_tokenId].currentAuction;
        Item storage item = tokenIdToItems[_tokenId].items[currentAuction];

        require(item.startedAt > 0, "not started");
        require(block.timestamp >= item.endAt, "not ended");

        if (currentAuction < SUPPLY[_tokenId]) {
            currentAuction++;
            _launchSale(_tokenId);
            emit Bid(
                _tokenId,
                currentAuction + 1,
                address(0),
                START_PRICE,
                uint128(block.timestamp) + FREE_BID_PERIOD
            );
        }

        emit End(_tokenId, currentAuction, item.highestBidder, item.highestBid);
    }

    function _increaseDeadline(Item storage _nftItem) private {
        uint256 _bidCount = _nftItem.bidCount;

        if (_bidCount > 3) {
            _nftItem.endAt = uint128(block.timestamp) + 6 hours;
        } else if (_bidCount == 2) {
            _nftItem.endAt = uint128(block.timestamp) + 12 hours;
        } else if (_bidCount == 1) {
            _nftItem.endAt = uint128(block.timestamp) + 24 hours;
        }
    }

    function supplyOf(uint256 _tokenId) public view returns (uint8) {
        return SUPPLY[_tokenId];
    }

    function currentAuctionOf(
        uint256 _tokenId
    ) public view returns (Item memory, uint8) {
        uint8 currentAuction = tokenIdToItems[_tokenId].currentAuction;

        require(
            currentAuction < SUPPLY[_tokenId],
            "no currentAuction for this id"
        );

        return (tokenIdToItems[_tokenId].items[currentAuction], currentAuction);
    }
}