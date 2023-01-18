// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./FeeCollector.sol";
import "./Transfers.sol";
import "./interfaces/IAuctionHandler.sol";
import "./interfaces/ICollection.sol";
import "./interfaces/ISalesHandler.sol";
import "./interfaces/IWhitelist.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract AuctionHandler is
    Initializable,
    OwnableUpgradeable,
    BaseRelayRecipient,
    FeeCollector,
    IAuctionHandler,
    IERC721ReceiverUpgradeable
{
    IERC20Upgradeable public bidToken;
    uint16 public minBidIncreasePerMille;
    uint256 public endAuctionBuffer;
    IWhitelist public whitelist;
    string public override versionRecipient;
    mapping(address => uint256) public lockedFunds;
    ISalesHandler public salesHandler;
    mapping(uint256 => IAuctionHandler.Auction) private auctions;

    function initialize(
        IERC20Upgradeable bidToken_,
        uint16 minBidIncreasePerMille_,
        uint256 endAuctionBuffer_,
        address trustedForwarder_,
        IWhitelist whitelist_,
        uint16 secondaryFeePerMille_,
        ISalesHandler salesHandler_,
        address feeCollector_
    ) external initializer {
        __Ownable_init();
        feeCollectorInit(secondaryFeePerMille_, feeCollector_);

        bidToken = bidToken_;
        minBidIncreasePerMille = minBidIncreasePerMille_;
        endAuctionBuffer = endAuctionBuffer_;
        _setTrustedForwarder(trustedForwarder_);
        versionRecipient = "1";
        whitelist = whitelist_;
        salesHandler = salesHandler_;
    }

    function setMinBidIncreasePerMille(uint16 minBidIncreasePerMille_)
        external
        onlyOwner
    {
        minBidIncreasePerMille = minBidIncreasePerMille_;
        emit BidThresholdUpdated(minBidIncreasePerMille_);
    }

    function setEndAuctionBuffer(uint256 endAuctionBuffer_) external onlyOwner {
        endAuctionBuffer = endAuctionBuffer_;
        emit EndAuctionBufferUpdated(endAuctionBuffer_);
    }

    function setTrustedForwarder(address trustedForwarder_) external onlyOwner {
        _setTrustedForwarder(trustedForwarder_);
    }

    function setSalesHandler(ISalesHandler salesHandler_) external onlyOwner {
        salesHandler = salesHandler_;
    }

    function setWhitelist(IWhitelist whitelist_) external onlyOwner {
        require(whitelist_ != IWhitelist(address(0)), "address is zero");
        whitelist = whitelist_;
    }

    function createMintAuction(
        ICollection collection,
        uint256 tokenID,
        uint256 duration,
        uint256 reservePrice
    ) external onlyOwner {
        require(!collection.exists(tokenID), "token already exists");
        require(
            !salesHandler.listingExists(collection, tokenID),
            "sale listing exists"
        );
        createAuction(collection, tokenID, duration, reservePrice, true);
    }

    function createSecondaryAuction(
        ICollection collection,
        uint256 tokenID,
        uint256 duration,
        uint256 reservePrice,
        IWhitelist.Coupon memory coupon
    ) external onlyWhitelistedUser(coupon) {
        createAuction(collection, tokenID, duration, reservePrice, false);
    }

    function createAuction(
        ICollection collection,
        uint256 tokenID,
        uint256 duration,
        uint256 reservePrice,
        bool mint
    ) internal {
        require(duration > endAuctionBuffer, "duration <= endAuctionBuffer");
        require(
            whitelist.isWhitelisted(address(collection)),
            "collection is not whitelisted"
        );
        require(
            collection.supportsInterface(type(IERC721).interfaceId),
            "contract does not support ERC721"
        );

        uint256 auctionID = getAuctionID(collection, tokenID);

        require(
            auctions[auctionID].seller == address(0),
            "auction already exists"
        );

        address seller = _msgSender();
        auctions[auctionID] = Auction({
            seller: seller,
            tokenID: tokenID,
            collection: collection,
            duration: duration,
            startTimestamp: 0,
            reservePrice: reservePrice,
            highestBidder: address(0),
            highestBid: 0,
            mint: mint
        });

        emit AuctionCreated(
            collection,
            tokenID,
            seller,
            duration,
            reservePrice,
            mint
        );

        if (!mint) {
            collection.safeTransferFrom(seller, address(this), tokenID);
        }
    }

    function placeBid(
        ICollection collection,
        uint256 tokenID,
        uint256 newBid,
        IWhitelist.Coupon memory coupon
    ) external onlyWhitelistedUser(coupon) {
        uint256 auctionID = getAuctionID(collection, tokenID);
        Auction storage auction = auctions[auctionID];
        require(auction.seller != address(0), "auction does not exist");

        uint256 endTimestamp;

        // Start timestamp will be 0 if this is the very first bid placed in
        // the auction.
        if (auction.startTimestamp == 0) {
            require(
                auction.highestBid == 0 && auction.highestBidder == address(0),
                "invalid auction state"
            );
            require(newBid >= auction.reservePrice, "newBid < reservePrice");

            auction.startTimestamp = block.timestamp;
            endTimestamp = block.timestamp + auction.duration;

            emit AuctionStarted(
                collection,
                tokenID,
                auction.duration,
                auction.startTimestamp
            );
        } else {
            endTimestamp = auction.startTimestamp + auction.duration;
            require(block.timestamp <= endTimestamp, "auction has ended");
            uint256 minBid = (auction.highestBid *
                (1000 + minBidIncreasePerMille)) / 1000;
            require(newBid >= minBid, "newBid < minBid");
        }

        uint256 prevBid = auction.highestBid;
        address prevBidder = auction.highestBidder;
        address bidder = _msgSender();

        auction.highestBid = newBid;
        auction.highestBidder = bidder;
        lockedFunds[auction.highestBidder] += newBid;

        if (prevBid > 0) {
            uint256 locked = lockedFunds[prevBidder];

            require(locked >= prevBid, "insufficient locked funds");
            if (locked == prevBid) {
                delete lockedFunds[prevBidder];
            } else {
                lockedFunds[prevBidder] -= prevBid;
            }
        }

        uint256 extendTimestamp = endTimestamp - endAuctionBuffer;
        if (block.timestamp > extendTimestamp) {
            uint256 newEndTimestamp = block.timestamp + endAuctionBuffer;
            auction.duration = newEndTimestamp - auction.startTimestamp;
            emit AuctionExtended(collection, tokenID, newEndTimestamp);
        }

        emit AuctionBid(
            collection,
            tokenID,
            bidder,
            newBid,
            prevBidder,
            prevBid,
            auction.seller
        );

        CheckedTransfers.checkTransferFrom(
            bidToken,
            bidder,
            address(this),
            newBid
        );

        if (prevBid > 0) {
            CheckedTransfers.checkTransfer(bidToken, prevBidder, prevBid);
        }
    }

    function endAuction(ICollection collection, uint256 tokenID) external {
        uint256 auctionID = getAuctionID(collection, tokenID);
        Auction memory auction = auctions[auctionID];

        require(auction.seller != address(0), "auction does not exist");
        require(auction.startTimestamp != 0, "auction has not yet started");
        uint256 endTimestamp = auction.startTimestamp + auction.duration;
        require(block.timestamp > endTimestamp, "auction is not ready to end");

        delete auctions[auctionID];

        uint256 fee = calculateSaleFee(auction.highestBid, auction.mint);
        require(fee <= auction.highestBid, "invalid fee");
        uint256 sellerTransfer = auction.highestBid - fee;

        emit AuctionEnded(
            collection,
            tokenID,
            auction.highestBidder,
            auction.highestBid,
            auction.seller,
            auction.mint,
            fee
        );

        CheckedTransfers.checkTransfer(
            bidToken,
            auction.seller,
            sellerTransfer
        );
        if (fee > 0) {
            CheckedTransfers.checkTransfer(bidToken, feeCollector, fee);
        }

        if (auction.mint) {
            auction.collection.mintItem(auction.tokenID, auction.highestBidder);
        } else {
            auction.collection.safeTransferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenID
            );
        }
    }

    function cancelAuction(ICollection collection, uint256 tokenID) external {
        uint256 auctionID = getAuctionID(collection, tokenID);
        Auction memory auction = auctions[auctionID];

        require(auction.startTimestamp == 0, "auction has started");
        require(_msgSender() == auction.seller, "caller is not seller");

        delete auctions[auctionID];
        emit AuctionCancelled(collection, tokenID, auction.seller);

        if (!auction.mint) {
            auction.collection.safeTransferFrom(
                address(this),
                auction.seller,
                auction.tokenID
            );
        }
    }

    function getAuction(ICollection collection, uint256 tokenID)
        external
        view
        returns (Auction memory)
    {
        uint256 auctionID = getAuctionID(collection, tokenID);
        Auction memory auction = auctions[auctionID];
        require(auction.seller != address(0), "auction not found");
        return auction;
    }

    function auctionExists(ICollection collection, uint256 tokenID)
        external
        view
        returns (bool)
    {
        uint256 auctionID = getAuctionID(collection, tokenID);
        return auctions[auctionID].seller != address(0);
    }

    function getAuctionID(ICollection collection, uint256 tokenID)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(address(collection), tokenID)));
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        require(operator == address(this), "transfer rejected");
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, BaseRelayRecipient)
        returns (address)
    {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, BaseRelayRecipient)
        returns (bytes calldata)
    {
        return BaseRelayRecipient._msgData();
    }

    modifier onlyWhitelistedUser(IWhitelist.Coupon memory coupon) {
        require(
            whitelist.isVerifiedCoupon(_msgSender(), coupon),
            "coupon is not valid"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWhitelist {
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function addToWhitelist(address addr) external;

    function deleteFromWhitelist(address addr) external;

    function setCouponSigner(address couponSigner_) external;

    function isWhitelisted(address addr) external view returns (bool);

    function isVerifiedCoupon(address sender, Coupon memory coupon)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAuctionHandler.sol";
import "./ICollection.sol";
import "./IWhitelist.sol";

interface ISalesHandler {
    // Listing objects represent a sales listing for a particular asset.
    struct Listing {
        // Collection of an ERC721 token contract.
        ICollection collection;
        // ID of the token being sold.
        uint256 tokenID;
        // Seller address.
        address seller;
        // Sale price, denominated in the contract's global sale token.
        uint256 price;
        // Flag indicating whether this represents a primary mint auction or
        // secondary sale.
        bool mint;
    }

    // Offer objects represent an offer to purchase a particular asset.
    struct Offer {
        // Collection of an ERC721 token contract.
        ICollection collection;
        // ID of the token being sold.
        uint256 tokenID;
        // Address of the potential buyer.
        address buyer;
        // Price offered by the potential buyer.
        uint256 price;
    }

    // Emitted when a listing is created.
    event ListingCreated(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address seller,
        uint256 price,
        bool mint
    );

    // Emitted when a sale is made.
    event ListingSold(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address seller,
        address buyer,
        uint256 price,
        bool mint,
        uint256 fee
    );

    // Emitted when a listing is cancelled by its creator.
    event ListingCancelled(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address seller,
        uint256 price
    );

    event OfferCreated(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address buyer,
        uint256 price
    );

    event OfferAccepted(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address seller,
        address buyer,
        uint256 price,
        uint256 fee
    );

    event OfferCancelled(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address buyer,
        uint256 price
    );

    // Set the trusted forwarder address used by Biconomy.
    function setTrustedForwarder(address trustedForwarder_) external;

    // Set the address of the AuctionHandler contract.
    function setAuctionHandler(IAuctionHandler auctionHandler_) external;

    // Set the address of the Whitelist contract.
    function setWhitelist(IWhitelist whitelist_) external;

    // List an item for primary mint sale at a fixed price.
    function listItemMint(
        ICollection collection,
        uint256 tokenID,
        uint256 price
    ) external;

    // List an item for secondary sale at a fixed price.
    function listItemSecondary(
        ICollection collection,
        uint256 tokenID,
        uint256 price,
        IWhitelist.Coupon memory coupon
    ) external;

    // Buy an item currently on sale.
    function buyItem(
        ICollection collection,
        uint256 tokenID,
        IWhitelist.Coupon memory coupon
    ) external;

    // Cancel an unsold listing.
    function cancelListing(ICollection collection, uint256 tokenID) external;

    // Get information on a particular listing.
    function getListing(ICollection collection, uint256 tokenID)
        external
        view
        returns (Listing memory);

    // Check if a listing exists.
    function listingExists(ICollection collection, uint256 tokenID)
        external
        view
        returns (bool);

    // Make an offer to purchase an item.
    function makeOffer(
        ICollection collection,
        uint256 tokenID,
        uint256 price,
        IWhitelist.Coupon memory coupon
    ) external;

    // Accept an offer made on an owned item.
    function acceptOffer(
        ICollection collection,
        uint256 tokenID,
        IWhitelist.Coupon memory coupon
    ) external;

    // Cancel an offer made on an item.
    function cancelOffer(ICollection collection, uint256 tokenID) external;

    // Get information on a particular item's offer.
    function getOffer(ICollection collection, uint256 tokenID)
        external
        view
        returns (Offer memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICollection is IERC721 {
    function mintItem(uint256 mintIndex, address recipient) external;

    function exists(uint256 tokenID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ICollection.sol";
import "./ISalesHandler.sol";
import "./IWhitelist.sol";

interface IAuctionHandler {
    // Auction objects represent an auction of a particular asset.
    struct Auction {
        // Address for ERC721 token.
        ICollection collection;
        // ID of ER721 compliant token
        uint256 tokenID;
        // Seller who created the auction, will receive the winning bid on completion.
        address seller;
        // Duration for the auction. Note that auctions may be extended if bids
        // are placed within a buffer period from the end.
        uint256 duration;
        // Start timestamp for this auction.
        uint256 startTimestamp;
        // Minimum price at which a bid may be made.
        uint256 reservePrice;
        // Highest bidder so far.
        address highestBidder;
        // Highest bid value so far.
        uint256 highestBid;
        // Flag indicating that the token should be minted on completion of
        // the auction. If false, it is required that the token is already
        // minted and owned by the auction creator.
        bool mint;
    }

    // Emitted when a new auction is created.
    event AuctionCreated(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address seller,
        uint256 duration,
        uint256 reservePrice,
        bool mint
    );

    // Emitted every time a new bid is placed.
    event AuctionBid(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address bidder,
        uint256 bid,
        address previousBidder,
        uint256 previousBid,
        address seller
    );

    // Emitted when the first bid is placed on an auction. After the first bid,
    // the auction timer is started and it may no longer be cancelled by its
    // creator.
    event AuctionStarted(
        ICollection indexed collection,
        uint256 indexed tokenID,
        uint256 duration,
        uint256 startTimestamp
    );

    // Emitted when an auction is extended due to a bid placed too close to the end.
    event AuctionExtended(
        ICollection indexed collection,
        uint256 indexed tokenID,
        uint256 newEndTimestamp
    );

    // Emitted when an auction has ended and the contract owner has withdrawn
    // the proceeds.
    event AuctionEnded(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address highestBidder,
        uint256 highestBid,
        address seller,
        bool mint,
        uint256 fee
    );

    // Emitted when an auction is cancelled, prior to any valid bids being placed.
    event AuctionCancelled(
        ICollection indexed collection,
        uint256 indexed tokenID,
        address seller
    );

    // Emiited when the minimum bid increase threshold is updated by the owner.
    event BidThresholdUpdated(uint16 minBidIncreasePerMille);

    // Emitted when the end auction buffer period is updated by the owner.
    event EndAuctionBufferUpdated(uint256 endAuctionBuffer);

    // Set a new minimum bid increase threshold, as a per-mille value.
    function setMinBidIncreasePerMille(uint16 newMinIncrease) external;

    // Set a new auction end buffer, in seconds.
    function setEndAuctionBuffer(uint256 endAuctionBuffer_) external;

    // Set the trusted forwarder address used by Biconomy.
    function setTrustedForwarder(address trustedForwarder_) external;

    // Set the address of the SalesHandler contract.
    function setSalesHandler(ISalesHandler salesHandler_) external;

    // Set the whitelist contract address.
    function setWhitelist(IWhitelist whitelist_) external;

    // Create a new mint auction.
    function createMintAuction(
        ICollection collection,
        uint256 tokenID,
        uint256 duration,
        uint256 reservePrice
    ) external;

    function createSecondaryAuction(
        ICollection collection,
        uint256 tokenID,
        uint256 duration,
        uint256 reservePrice,
        IWhitelist.Coupon memory coupon
    ) external;

    // Place a new bid on an auction.
    function placeBid(
        ICollection collection,
        uint256 tokenID,
        uint256 newBid,
        IWhitelist.Coupon memory coupon
    ) external;

    // Ends an auction and transfers proceeds to the contract owner.
    function endAuction(ICollection collection, uint256 tokenID) external;

    // Cancel an auction, only possible if no valid bids have been placed.
    // Returns ERC721 to original owner for secondary auctions.
    function cancelAuction(ICollection collection, uint256 tokenID) external;

    // Retrieve current auction state.
    function getAuction(ICollection collection, uint256 tokenID)
        external
        view
        returns (Auction memory);

    // Checks if an auction exists.
    function auctionExists(ICollection collection, uint256 tokenID)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library CheckedTransfers {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function checkTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal {
        uint256 initBalance = token.balanceOf(address(this));
        token.safeTransfer(to, amount);

        uint256 newBalance = token.balanceOf(address(this));
        uint256 balanceDelta = initBalance - newBalance;
        require(balanceDelta == amount, "requested amount not transferred");
    }

    function checkTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 initBalance = token.balanceOf(to);
        token.safeTransferFrom(from, to, amount);

        uint256 newBalance = token.balanceOf(to);
        uint256 balanceDelta = newBalance - initBalance;
        require(balanceDelta == amount, "requested amount not transferred");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FeeCollector is Initializable, OwnableUpgradeable {
    uint16 public secondaryFeePerMille;
    uint16 public constant FEE_UPPER_LIMIT = 300; // Hardcode limit for fees to 30%
    address public feeCollector;

    // Emitted when the fee for secondary sales is updated by the owner.
    event FeeUpdated(uint16 secondaryFeePerMille);

    function feeCollectorInit(
        uint16 secondaryFeePerMille_,
        address feeCollector_
    ) internal onlyInitializing {
        __Ownable_init();
        setSecondaryFeePerMille(secondaryFeePerMille_);
        feeCollector = feeCollector_;
    }

    function setSecondaryFeePerMille(uint16 secondaryFeePerMille_)
        public
        onlyOwner
    {
        require(secondaryFeePerMille_ <= FEE_UPPER_LIMIT, "invalid fee");
        secondaryFeePerMille = secondaryFeePerMille_;
        emit FeeUpdated(secondaryFeePerMille_);
    }

    function setFeeCollector(address feeCollector_) external onlyOwner {
        require(feeCollector_ != address(0), "feeCollector is zero");
        feeCollector = feeCollector_;
    }

    function calculateSaleFee(uint256 value, bool mint)
        internal
        view
        returns (uint256)
    {
        if (mint) {
            return 0;
        }

        return (value * secondaryFeePerMille) / 1000;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}