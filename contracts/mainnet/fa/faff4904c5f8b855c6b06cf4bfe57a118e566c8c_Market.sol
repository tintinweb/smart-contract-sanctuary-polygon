// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Chainlink
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Openzeppelin
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
// Market Registry
import "../AmberfiManager/MarketRegistry.sol";
// Interfaces
import "../interfaces/IAmberfiKeyStorageUpgradeable.sol";
import "../interfaces/INFTPayoutsUpgradeable.sol";
// Libraries
import "../libs/AmberfiLib.sol";

contract Market is
    Initializable,
    IERC721ReceiverUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ERC165CheckerUpgradeable for address;

    AmberfiLib.Auction[] private _auctions; // All auctions
    AmberfiLib.PaymentToken[] private _paymentTokens; // All payment tokens available
    AmberfiLib.MarketFeeTier[] private _feeTiers;
    CountersUpgradeable.Counter private _auctionIdCounter; // Auction ID counter: Total number of auctions
    address private _marketRegistry;
    uint256 private _minAuctionListingPriceUSD; // Minimum auction price
    uint256 private _minBidIncrementPercent; // Minimum auction bid amount increment percentage (10000 = 100%)
    mapping(uint256 => AmberfiLib.ClaimState) private _claimStatePerAuctionId; // Claim state per auction ID
    mapping(uint256 => AmberfiLib.Bid[]) private _bidsPerAuctionId; // All bids per auction ID
    mapping(uint256 => uint256) private _serviceFeesPerPaymentTokenId; // Service Fees per PaymentToken ID

    error Market_InvalidAuctionID();
    error Market_InvalidMetaTxSignature();
    error Market_InvalidMinAuctionPrice();
    error Market_InvalidWithdrawAmount();
    error Market_AuctionCreateFailed(uint8 errorType);
    error Market_AuctionBuyNowFailed(uint8 errorType);
    error Market_AuctionBidFailed(uint8 errorType);
    error Market_AuctionRedeemNFTFailed(uint8 errorType);
    error Market_AuctionClaimPaymentFailed(uint8 errorType);
    error Market_AuctionCancelFailed(uint8 errorType);
    error Market_PaymentTokenAddFailed();
    error Market_PaymentTokenRemoveFailed(uint8 errorType);
    error Market_TokenNotEnabled();
    error Market_ZeroAddress();
    error Market_Paused();
    error Market_InvalidFeeTierRecipient();
    error Market_InvalidFeeTier();
    error Market_InvalidFeeTiersSum();
    error MarketRegistry_NotAmberfiOwner();
    error MarketRegistry_NotMarketOwner();
    error MarketRegistry_NotAmberfiNorMarketOwner();
    error MarketRegistry_NotKYCVerifier();

    event AuctionCreated(
        uint256 auctionId,
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice,
        uint256 reservedPrice,
        address indexed creator,
        address indexed nftContract,
        uint256 tokenId,
        uint256 paymentTokenIndex
    ); // Event emitted when a new auction created
    event InstantSaleCreated(
        uint256 auctionId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceUSD,
        address indexed creator,
        address indexed nftContract,
        uint256 tokenId,
        uint256[] paymentTokenIndexes
    ); // Event emitted when a new instant sale created
    event BoughtNFT(
        address indexed buyer,
        uint256 amount,
        uint256 paymentTokenIndex
    ); // Event emitted when an instant sale auction item sold
    event BidPlaced(
        address indexed bidder,
        uint256 bid,
        uint256 paymentTokenIndex
    ); // Event emitted when a bid placed
    event NFTRedeemed(address indexed winner); // Event emitted when the auction winner redeem the purchased NFT
    event PaymentClaimed(address indexed owner, uint256 amount); // Event emitted when the auction owner claimed the payment
    event AuctionCanceled(uint256 auctionId); // Event emitted when the auction cancelled
    event MarketFeeTierChanged(AmberfiLib.MarketFeeTier[] feeTiers); // Event emitted when market fee tiers changed
    event MinAuctionListingPriceUSDChanged(
        uint256 newMinAuctionListingPriceUSD
    ); // Event emitted when new min auction listing price in USD changed
    event MinBidIncrementPercentChanged(uint256 percent); // Event emitted when a new bid increment percent is set
    event PaymentTokenAdded(
        uint256 index,
        address indexed token,
        address indexed aggregator,
        uint8 tokenDecimals,
        uint8 aggregatorDecimals,
        bool native
    ); // Event emitted when payment token added
    event PaymentTokenRemoved(uint256 index); // Event emitted when payment token removed

    /**
     * @dev Modifier, check if auction is valid
     * @param auctionId_ (uint256) Auction ID
     */
    modifier isValidAuction(uint256 auctionId_) {
        if (auctionId_ > getAuctionsCount()) {
            revert AmberfiLib.Market_InvalidAuctionID();
        }

        _;
    }

    modifier onlyMarketOwnerRole() {
        if (!MarketRegistry(_marketRegistry).hasMarketOwnerRole(msg.sender)) {
            revert AmberfiLib.MarketRegistry_NotMarketOwner();
        }
        _;
    }

    /**
     * @dev Initializer
     * @param marketRegistry_ (address) Market Registry address
     * @param feeTiers_ (AmberfiLib.MarketFeeTier[] calldata) Auction creation fee
     * @param minAuctionListingPriceUSD_ (uint256) Minimum auction listing price
     */
    function initialize(
        address marketRegistry_,
        AmberfiLib.MarketFeeTier[] calldata feeTiers_,
        uint256 minAuctionListingPriceUSD_
    ) public initializer {
        if (marketRegistry_ == address(0)) {
            revert AmberfiLib.Market_ZeroAddress();
        }

        if (minAuctionListingPriceUSD_ == 0) {
            revert AmberfiLib.Market_InvalidMinAuctionPrice();
        }

        uint256 feeTiersLength = feeTiers_.length;
        uint256 feeTiersSum;

        for (uint256 i; i < feeTiersLength; ) {
            if (feeTiers_[i].feeRecipient == address(0)) {
                revert AmberfiLib.Market_InvalidFeeTierRecipient();
            }

            if (feeTiers_[i].feeTier == 0) {
                revert AmberfiLib.Market_InvalidFeeTier();
            }

            unchecked {
                feeTiersSum = feeTiersSum + feeTiers_[i].feeTier;
                ++i;
            }
        }

        if (feeTiersSum > 9999) {
            revert AmberfiLib.Market_InvalidFeeTiersSum();
        }

        for (uint256 i; i < feeTiersLength; ) {
            _feeTiers.push(
                AmberfiLib.MarketFeeTier(
                    feeTiers_[i].feeRecipient,
                    feeTiers_[i].feeTier
                )
            );

            unchecked {
                ++i;
            }
        }

        __Ownable_init();

        _marketRegistry = marketRegistry_;
        _minAuctionListingPriceUSD = minAuctionListingPriceUSD_;
        _minBidIncrementPercent = 500; // (5%)

        _auctionIdCounter.increment(); // Starts from 1

        emit AmberfiLib.MarketFeeTierChanged(feeTiers_);
        emit AmberfiLib.MinAuctionListingPriceUSDChanged(
            minAuctionListingPriceUSD_
        );
        emit AmberfiLib.MinBidIncrementPercentChanged(500);
    }

    /**
     * @dev Get all active auctions length with specific PaymentToken index
     * @param paymentTokenIndex_ (uint256) PaymentToken index
     * @return length (uint256)
     */
    function _activeAuctionsLength(uint256 paymentTokenIndex_)
        internal
        view
        returns (uint256 length)
    {
        uint256 auctionLength = getAuctionsCount();

        for (uint256 i; i < auctionLength; ++i) {
            AmberfiLib.Auction storage auction = _auctions[i];
            uint256 paymentTokensLength = auction.paymentTokenIndexes.length;

            for (uint256 j; j < paymentTokensLength; ) {
                if (
                    auction.auctionState == AmberfiLib.AuctionState.STARTED &&
                    paymentTokenIndex_ == auction.paymentTokenIndexes[j]
                ) {
                    ++length;
                    break;
                }

                unchecked {
                    ++j;
                }
            }
        }
    }

    function pause() external payable onlyOwner onlyMarketOwnerRole {
        _pause();
    }

    function unpause() external payable onlyOwner onlyMarketOwnerRole {
        _unpause();
    }

    /**
     * @dev Add PaymentToken
     * @param token_ (address) PaymentToken address
     * @param aggregator_ (address) Chainlink aggregator address for the PaymentToken:USD pair
     * @param aggregatorDecimals_ (uint8) Chainlink aggregator decimals
     * @param native_ (bool) Check if PaymentToken is native token
     */
    function addPaymentToken(
        address token_,
        address aggregator_,
        uint8 aggregatorDecimals_,
        bool native_
    ) external payable onlyOwner onlyMarketOwnerRole {
        if (!native_ && token_ == address(0)) {
            revert AmberfiLib.Market_PaymentTokenAddFailed();
        }

        uint8 tokenDecimals = native_
            ? 18
            : IERC20MetadataUpgradeable(token_).decimals();

        uint256 length = _paymentTokens.length;
        for (uint256 i; i < length; ) {
            if (
                (native_ && _paymentTokens[i].native) ||
                (!native_ && token_ == _paymentTokens[i].token)
            ) {
                AmberfiLib.PaymentToken storage paymentToken = _paymentTokens[
                    i
                ];
                paymentToken.token = token_;
                paymentToken.aggregator = aggregator_;
                paymentToken.tokenDecimals = tokenDecimals;
                paymentToken.aggregatorDecimals = aggregatorDecimals_;
                paymentToken.native = native_;
                paymentToken.enabled = true;

                emit AmberfiLib.PaymentTokenAdded(
                    i,
                    token_,
                    aggregator_,
                    tokenDecimals,
                    aggregatorDecimals_,
                    native_
                );
                return;
            }

            unchecked {
                ++i;
            }
        }

        _paymentTokens.push(
            AmberfiLib.PaymentToken(
                token_,
                aggregator_,
                tokenDecimals,
                aggregatorDecimals_,
                native_,
                true
            )
        );

        emit AmberfiLib.PaymentTokenAdded(
            length,
            token_,
            aggregator_,
            tokenDecimals,
            aggregatorDecimals_,
            native_
        );
    }

    /**
     * @dev Remove PaymentToken
     * @param index_ (uint256) PaymentToken index
     */
    function removePaymentToken(uint256 index_)
        external
        payable
        onlyOwner
        onlyMarketOwnerRole
    {
        if (index_ >= _paymentTokens.length) {
            revert AmberfiLib.Market_PaymentTokenRemoveFailed(
                uint8(
                    AmberfiLib
                        .PaymentTokenRemoveErrorType
                        .INVALID_PAYMENT_TOKEN_INDEX
                )
            );
        }

        if (_serviceFeesPerPaymentTokenId[index_] > 0) {
            revert AmberfiLib.Market_PaymentTokenRemoveFailed(
                uint8(
                    AmberfiLib.PaymentTokenRemoveErrorType.WITHDRAW_TOKENS_FIRST
                )
            );
        }

        if (_activeAuctionsLength(index_) > 0) {
            revert AmberfiLib.Market_PaymentTokenRemoveFailed(
                uint8(
                    AmberfiLib.PaymentTokenRemoveErrorType.ACTIVE_AUCTIONS_EXIST
                )
            );
        }

        delete _paymentTokens[index_].enabled;

        emit AmberfiLib.PaymentTokenRemoved(index_);
    }

    /**
     * @dev Set minimum auction bid increment percentage
     * @param percent_ (uint256) New percent
     */
    function setMinBidIncrementPercent(uint256 percent_)
        external
        payable
        onlyOwner
        onlyMarketOwnerRole
    {
        _minBidIncrementPercent = percent_ > 10000 ? 10000 : percent_;

        emit AmberfiLib.MinBidIncrementPercentChanged(_minBidIncrementPercent);
    }

    /**
     * @dev Create an auction
     * @param startTime_ (uint256) Start time in timestamp
     * @param endTime_ (uint256) Aend time in timestamp
     * @param startPrice_ (uint256) Start price in PaymentToken
     * @param reservedPrice_ (uint256) Reserved price in PaymentToken
     * @param nftContract_ (uint256) NFT contract address
     * @param tokenId_ (uint256) NFT token ID
     * @param paymentTokenIndex_ (uint256) PaymentToken index
     */
    function createAuction(
        uint256 startTime_,
        uint256 endTime_,
        uint256 startPrice_,
        uint256 reservedPrice_,
        address nftContract_,
        uint256 tokenId_,
        uint256 paymentTokenIndex_
    ) external nonReentrant whenNotPaused {
        if (startTime_ < block.timestamp || endTime_ <= startTime_) {
            revert AmberfiLib.Market_AuctionCreateFailed(
                uint8(AmberfiLib.AuctionCreateErrorType.INVALID_TIME_RANGE)
            );
        }

        if (
            getRate(startPrice_, paymentTokenIndex_) <
            _minAuctionListingPriceUSD
        ) {
            revert AmberfiLib.Market_AuctionCreateFailed(
                uint8(AmberfiLib.AuctionCreateErrorType.INVALID_START_PRICE)
            );
        }

        if (reservedPrice_ < startPrice_) {
            revert AmberfiLib.Market_AuctionCreateFailed(
                uint8(AmberfiLib.AuctionCreateErrorType.INVALID_RESERVED_PRICE)
            );
        }

        if (
            paymentTokenIndex_ >= _paymentTokens.length ||
            !_paymentTokens[paymentTokenIndex_].enabled
        ) {
            revert AmberfiLib.Market_AuctionCreateFailed(
                uint8(
                    AmberfiLib
                        .AuctionCreateErrorType
                        .INVALID_PAYMENT_TOKEN_INDEX
                )
            );
        }

        if (
            nftContract_ == address(0) ||
            !nftContract_.supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            revert AmberfiLib.Market_AuctionCreateFailed(
                uint8(AmberfiLib.AuctionCreateErrorType.INVALID_NFT_CONTRACT)
            );
        }

        uint256 auctionId = getAuctionsCount() + 1;
        uint256[] memory paymentTokenIndexes = new uint256[](1);
        paymentTokenIndexes[0] = paymentTokenIndex_;

        _auctions.push(
            AmberfiLib.Auction(
                auctionId,
                startTime_,
                endTime_,
                0, // This is not instant sale, so price is zero
                startPrice_,
                reservedPrice_,
                msg.sender,
                nftContract_,
                tokenId_,
                paymentTokenIndexes,
                AmberfiLib.Bid(address(0), 0, paymentTokenIndex_),
                AmberfiLib.AuctionState.STARTED,
                false
            )
        );

        _claimStatePerAuctionId[auctionId] = AmberfiLib.ClaimState.NONE;

        _auctionIdCounter.increment();

        IERC721Upgradeable(nftContract_).transferFrom(
            msg.sender,
            address(this),
            tokenId_
        );

        emit AmberfiLib.AuctionCreated(
            auctionId,
            startTime_,
            endTime_,
            startPrice_,
            reservedPrice_,
            msg.sender,
            nftContract_,
            tokenId_,
            paymentTokenIndex_
        );
    }

    /**
     * @dev Create an instant sale auction
     * @param startTime_ (uint256) Start time in timestamp
     * @param endTime_ (uint256) end time in timestamp
     * @param priceUSD_ (uint256) Price in USD
     * @param nftContract_ (uint256) NFT contract address
     * @param tokenId_ (uint256) NFT token ID
     * @param paymentTokenIndexes_ (uint256[] calldata) Array of PaymentToken indexes
     */
    function createInstantSale(
        uint256 startTime_,
        uint256 endTime_,
        uint256 priceUSD_,
        address nftContract_,
        uint256 tokenId_,
        uint256[] calldata paymentTokenIndexes_
    ) external nonReentrant whenNotPaused {
        if (startTime_ < block.timestamp || endTime_ <= startTime_) {
            revert AmberfiLib.Market_AuctionCreateFailed(
                uint8(AmberfiLib.AuctionCreateErrorType.INVALID_TIME_RANGE)
            );
        }

        if (priceUSD_ < _minAuctionListingPriceUSD) {
            revert AmberfiLib.Market_AuctionCreateFailed(
                uint8(AmberfiLib.AuctionCreateErrorType.INVALID_PRICE_USD)
            );
        }

        uint256 length = paymentTokenIndexes_.length;
        for (uint256 i; i < length; ) {
            if (
                paymentTokenIndexes_[i] >= _paymentTokens.length ||
                !_paymentTokens[paymentTokenIndexes_[i]].enabled
            ) {
                revert AmberfiLib.Market_AuctionCreateFailed(
                    uint8(
                        AmberfiLib
                            .AuctionCreateErrorType
                            .INVALID_PAYMENT_TOKEN_INDEX
                    )
                );
            }

            unchecked {
                ++i;
            }
        }

        if (
            nftContract_ == address(0) ||
            !nftContract_.supportsInterface(
                type(IERC721Upgradeable).interfaceId
            )
        ) {
            revert AmberfiLib.Market_AuctionCreateFailed(
                uint8(AmberfiLib.AuctionCreateErrorType.INVALID_NFT_CONTRACT)
            );
        }

        uint256 auctionId = getAuctionsCount() + 1;

        _auctions.push(
            AmberfiLib.Auction(
                auctionId,
                startTime_,
                endTime_,
                priceUSD_,
                0,
                0,
                msg.sender,
                nftContract_,
                tokenId_,
                paymentTokenIndexes_,
                AmberfiLib.Bid(address(0), 0, 0),
                AmberfiLib.AuctionState.STARTED,
                true
            )
        );

        _claimStatePerAuctionId[auctionId] = AmberfiLib.ClaimState.NONE;

        _auctionIdCounter.increment();

        IERC721Upgradeable(nftContract_).transferFrom(
            msg.sender,
            address(this),
            tokenId_
        );

        emit AmberfiLib.InstantSaleCreated(
            auctionId,
            startTime_,
            endTime_,
            priceUSD_,
            msg.sender,
            nftContract_,
            tokenId_,
            paymentTokenIndexes_
        );
    }

    /**
     * @dev Place bid to an auction
     * @param auctionId_ (uint256) Auction ID
     * @param paymentTokenIndex_ (uint256) PaymentToken index
     * @param paymentAmountWithFee_ (uint256) Payment amount plus buyer fee in PaymentToken
     */
    function buyNow(
        uint256 auctionId_,
        uint256 paymentTokenIndex_,
        uint256 paymentAmountWithFee_
    ) external payable nonReentrant whenNotPaused isValidAuction(auctionId_) {
        AmberfiLib.Auction storage auction = _auctions[auctionId_ - 1];
        AmberfiLib.AuctionState auctionState = auction.auctionState;

        uint256 paymentAmountWithFee = msg.value > 0
            ? msg.value
            : paymentAmountWithFee_;

        if (!auction.instantSale) {
            revert AmberfiLib.Market_AuctionBuyNowFailed(
                uint8(AmberfiLib.AuctionBuyNowErrorType.INSTANTSALE_NOT_ENABLED)
            );
        }

        bool enabled;
        address token = _paymentTokens[paymentTokenIndex_].token;
        IERC20Upgradeable erc20Token = IERC20Upgradeable(token);

        for (uint256 i; i < auction.paymentTokenIndexes.length; ) {
            if (paymentTokenIndex_ == auction.paymentTokenIndexes[i]) {
                enabled = true;
                break;
            }

            unchecked {
                ++i;
            }
        }

        if (!enabled) {
            revert AmberfiLib.Market_AuctionBuyNowFailed(
                uint8(
                    AmberfiLib
                        .AuctionBuyNowErrorType
                        .INVALID_PAYMENT_TOKEN_INDEX
                )
            );
        }

        if (
            getRate(paymentAmountWithFee, paymentTokenIndex_) <
            auction.priceUSD +
                ((auction.priceUSD * (getServiceFeePercent() >> 1)) / 10000)
        ) {
            revert AmberfiLib.Market_AuctionBuyNowFailed(
                uint8(AmberfiLib.AuctionBuyNowErrorType.INVALID_PAYMENT_AMOUNT)
            );
        }

        if (msg.sender == auction.creator) {
            revert AmberfiLib.Market_AuctionBuyNowFailed(
                uint8(AmberfiLib.AuctionBuyNowErrorType.CREATOR_CANNOT_BUY)
            );
        }

        if (
            auctionState == AmberfiLib.AuctionState.COMPLETED ||
            auctionState == AmberfiLib.AuctionState.CANCELLED
        ) {
            revert AmberfiLib.Market_AuctionBuyNowFailed(
                uint8(
                    AmberfiLib
                        .AuctionBuyNowErrorType
                        .AUCTION_COMPLETED_OR_CANCELLED
                )
            );
        }

        if (
            block.timestamp < auction.startTime ||
            block.timestamp >= auction.endTime
        ) {
            revert AmberfiLib.Market_AuctionBuyNowFailed(
                uint8(
                    AmberfiLib
                        .AuctionBuyNowErrorType
                        .AUCTION_ENDED_OR_NOT_STARTED
                )
            );
        }

        AmberfiLib.Bid memory bid = AmberfiLib.Bid(
            msg.sender,
            paymentAmountWithFee,
            paymentTokenIndex_
        );

        _bidsPerAuctionId[auctionId_].push(bid);
        auction.highestBid = bid;
        auction.endTime = block.timestamp;

        if (msg.value == 0) {
            erc20Token.transferFrom(
                msg.sender,
                address(this),
                paymentAmountWithFee
            );
        }

        emit AmberfiLib.BoughtNFT(
            msg.sender,
            paymentAmountWithFee,
            paymentTokenIndex_
        );
    }

    /**
     * @dev Place bid to an auction (Native PaymentToken)
     * @param auctionId_ (uint256) Auction ID
     * @param bidAmountWithFee_ (uint256) Bid amount with fee in PaymentToken
     */
    function placeBid(uint256 auctionId_, uint256 bidAmountWithFee_)
        external
        payable
        nonReentrant
        whenNotPaused
        isValidAuction(auctionId_)
    {
        AmberfiLib.Auction storage auction = _auctions[auctionId_ - 1];
        AmberfiLib.AuctionState auctionState = auction.auctionState;

        uint256 bidAmountWithFee;
        bool isMATIC;

        if (msg.value > 0) {
            bidAmountWithFee = msg.value;
            isMATIC = true;
        } else {
            bidAmountWithFee = bidAmountWithFee_;
        }

        if (auction.instantSale) {
            revert AmberfiLib.Market_AuctionBidFailed(
                uint8(
                    AmberfiLib
                        .AuctionBidErrorType
                        .CANNOT_BID_TO_INSTANT_SALE_AUCTION
                )
            );
        }

        uint256 minBidAmount = auction.highestBid.bidAmount > 0
            ? auction.highestBid.bidAmount
            : auction.startPrice;

        if (auction.highestBid.bidAmount > 0) {
            minBidAmount =
                (minBidAmount * (10000 + _minBidIncrementPercent)) /
                10000;
        }

        uint256 buyerFee = getServiceFeePercent() >> 1;

        if (
            bidAmountWithFee <
            minBidAmount + ((minBidAmount * buyerFee) / 10000)
        ) {
            revert AmberfiLib.Market_AuctionBidFailed(
                uint8(AmberfiLib.AuctionBidErrorType.INVALID_BID_AMOUNT)
            );
        }

        if (msg.sender == auction.creator) {
            revert AmberfiLib.Market_AuctionBidFailed(
                uint8(AmberfiLib.AuctionBidErrorType.CREATOR_CANNOT_BID)
            );
        }

        if (
            auctionState == AmberfiLib.AuctionState.COMPLETED ||
            auctionState == AmberfiLib.AuctionState.CANCELLED
        ) {
            revert AmberfiLib.Market_AuctionBidFailed(
                uint8(
                    AmberfiLib
                        .AuctionBidErrorType
                        .AUCTION_COMPLETED_OR_CANCELLED
                )
            );
        }

        if (
            block.timestamp < auction.startTime ||
            block.timestamp >= auction.endTime
        ) {
            revert AmberfiLib.Market_AuctionBidFailed(
                uint8(
                    AmberfiLib.AuctionBidErrorType.AUCTION_ENDED_OR_NOT_STARTED
                )
            );
        }

        uint256 prevHighestBidAmount = auction.highestBid.bidAmount;
        address prevHighestBidder = auction.highestBid.bidder;

        AmberfiLib.Bid memory bid = AmberfiLib.Bid(
            msg.sender,
            bidAmountWithFee,
            auction.highestBid.paymentTokenIndex
        );

        _bidsPerAuctionId[auctionId_].push(bid);
        auction.highestBid = bid;

        if (
            bidAmountWithFee >=
            auction.reservedPrice + ((auction.reservedPrice * buyerFee) / 10000)
        ) {
            auction.endTime = block.timestamp;
        }

        if (prevHighestBidAmount > 0 && prevHighestBidder != address(0)) {
            if (isMATIC) {
                payable(address(prevHighestBidder)).transfer(
                    prevHighestBidAmount
                ); // Refund previous bid amount
            } else {
                address token = _paymentTokens[
                    auction.highestBid.paymentTokenIndex
                ].token;
                IERC20Upgradeable erc20Token = IERC20Upgradeable(token);
                erc20Token.approve(address(this), prevHighestBidAmount);
                erc20Token.transferFrom(
                    address(this),
                    prevHighestBidder,
                    prevHighestBidAmount
                ); // Refund previous bid
            }
        }

        emit AmberfiLib.BidPlaced(
            msg.sender,
            msg.value,
            auction.highestBid.paymentTokenIndex
        );
    }

    /**
     * @dev Redeem NFT when auction is over
     * @param auctionId_ (uint256) Auction ID
     */
    function redeemNFT(uint256 auctionId_)
        external
        nonReentrant
        whenNotPaused
        isValidAuction(auctionId_)
    {
        AmberfiLib.Auction storage auction = _auctions[auctionId_ - 1];
        AmberfiLib.Bid memory highestBid = auction.highestBid;
        AmberfiLib.AuctionState auctionState = auction.auctionState;

        if (msg.sender != highestBid.bidder) {
            revert AmberfiLib.Market_AuctionRedeemNFTFailed(
                uint8(AmberfiLib.AuctionRedeemNFTErrorType.NOT_AUCTION_WINNER)
            );
        }

        if (
            auctionState == AmberfiLib.AuctionState.COMPLETED ||
            auctionState == AmberfiLib.AuctionState.CANCELLED
        ) {
            revert AmberfiLib.Market_AuctionRedeemNFTFailed(
                uint8(
                    AmberfiLib
                        .AuctionRedeemNFTErrorType
                        .AUCTION_COMPLETED_OR_CANCELLED
                )
            );
        }

        if (block.timestamp < auction.endTime) {
            revert AmberfiLib.Market_AuctionRedeemNFTFailed(
                uint8(AmberfiLib.AuctionRedeemNFTErrorType.AUCTION_NOT_ENDED)
            );
        }

        if (
            _claimStatePerAuctionId[auctionId_] ==
            AmberfiLib.ClaimState.REDEEMED
        ) {
            revert AmberfiLib.Market_AuctionRedeemNFTFailed(
                uint8(AmberfiLib.AuctionRedeemNFTErrorType.NFT_ALREADY_REDEEMED)
            );
        }

        _claimStatePerAuctionId[auctionId_] = AmberfiLib.ClaimState.REDEEMED;

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            highestBid.bidder,
            auction.tokenId
        );

        emit AmberfiLib.NFTRedeemed(highestBid.bidder);
    }

    /**
     * @dev After NFT redeemed, claim the payment
     * @param auctionId_ (uint256) Auction ID
     * @param encryptionKey_ (string calldata) Encrypion key for encrypted content NFT
     */
    function claimPayment(uint256 auctionId_, string calldata encryptionKey_)
        external
        nonReentrant
        whenNotPaused
        isValidAuction(auctionId_)
    {
        AmberfiLib.Auction storage auction = _auctions[auctionId_ - 1];
        AmberfiLib.Bid memory highestBid = auction.highestBid;

        if (msg.sender != auction.creator) {
            revert AmberfiLib.Market_AuctionClaimPaymentFailed(
                uint8(
                    AmberfiLib.AuctionClaimPaymentErrorType.NOT_AUCTION_CREATOR
                )
            );
        }

        if (
            auction.auctionState == AmberfiLib.AuctionState.COMPLETED ||
            auction.auctionState == AmberfiLib.AuctionState.CANCELLED
        ) {
            revert AmberfiLib.Market_AuctionClaimPaymentFailed(
                uint8(
                    AmberfiLib
                        .AuctionClaimPaymentErrorType
                        .AUCTION_COMPLETED_OR_CANCELLED
                )
            );
        }

        if (block.timestamp < auction.endTime) {
            revert AmberfiLib.Market_AuctionClaimPaymentFailed(
                uint8(AmberfiLib.AuctionRedeemNFTErrorType.AUCTION_NOT_ENDED)
            );
        }

        if (
            _claimStatePerAuctionId[auctionId_] !=
            AmberfiLib.ClaimState.REDEEMED
        ) {
            revert AmberfiLib.Market_AuctionClaimPaymentFailed(
                uint8(AmberfiLib.AuctionClaimPaymentErrorType.NFT_NOT_REDEEMED)
            );
        }

        address creator = INFTPayoutsUpgradeable(auction.nftContract).creator(
            auction.tokenId
        );
        uint256 bidAmountWithoutFee = (highestBid.bidAmount * 10000) /
            (10000 + getServiceFeePercent()); // Includes both fee from bidder and auction creator
        uint256 serviceFee = highestBid.bidAmount - bidAmountWithoutFee;
        uint256 payoutCount;

        if (
            auction.nftContract.supportsInterface(
                type(INFTPayoutsUpgradeable).interfaceId
            )
        ) {
            payoutCount = INFTPayoutsUpgradeable(auction.nftContract)
                .payoutCount(auction.tokenId, creator == msg.sender);
        }

        address[] memory payoutReceivers = new address[](payoutCount);
        uint256[] memory payoutShares = new uint256[](payoutCount);

        auction.auctionState = AmberfiLib.AuctionState.COMPLETED;
        _claimStatePerAuctionId[auctionId_] = AmberfiLib.ClaimState.CLAIMED;
        _serviceFeesPerPaymentTokenId[
            highestBid.paymentTokenIndex
        ] += serviceFee;

        if (
            auction.nftContract.supportsInterface(
                type(IAmberfiKeyStorageUpgradeable).interfaceId
            )
        ) {
            bytes memory encryptBytes = bytes(encryptionKey_);
            if (encryptBytes.length > 0) {
                IAmberfiKeyStorageUpgradeable(auction.nftContract)
                    .setEncryptKey(auction.tokenId, encryptionKey_);
            }
        }

        if (_paymentTokens[highestBid.paymentTokenIndex].native) {
            if (payoutCount == 0) {
                payable(auction.creator).transfer(bidAmountWithoutFee);
            } else {
                (payoutReceivers, payoutShares) = INFTPayoutsUpgradeable(
                    auction.nftContract
                ).payoutInfo(
                        auction.tokenId,
                        bidAmountWithoutFee,
                        creator == msg.sender
                    );
                for (uint256 i; i < payoutCount; ) {
                    payable(payoutReceivers[i]).transfer(payoutShares[i]);

                    unchecked {
                        ++i;
                    }
                }
            }

            AmberfiLib.MarketFeeTier[] storage feeTiers = _feeTiers;
            uint256 feeTiersLength = feeTiers.length;
            uint256 feeTiersSum;

            for (uint256 i; i < feeTiersLength; ) {
                unchecked {
                    feeTiersSum = feeTiersSum + _feeTiers[i].feeTier;
                    ++i;
                }
            }

            for (uint256 i; i < feeTiersLength; ) {
                if (_feeTiers[i].feeRecipient == address(this)) continue;

                uint256 fee = (serviceFee * _feeTiers[i].feeTier) / feeTiersSum;
                payable(feeTiers[i].feeRecipient).transfer(fee);

                unchecked {
                    ++i;
                }
            }
        } else {
            address token = _paymentTokens[highestBid.paymentTokenIndex].token;
            IERC20Upgradeable erc20Token = IERC20Upgradeable(token);

            if (payoutCount == 0) {
                erc20Token.transfer(auction.creator, bidAmountWithoutFee);
            } else {
                (payoutReceivers, payoutShares) = INFTPayoutsUpgradeable(
                    auction.nftContract
                ).payoutInfo(
                        auction.tokenId,
                        bidAmountWithoutFee,
                        msg.sender == creator
                    );
                for (uint256 i; i < payoutCount; ) {
                    erc20Token.transfer(payoutReceivers[i], payoutShares[i]);

                    unchecked {
                        ++i;
                    }
                }
            }

            uint256 feeTiersLength = _feeTiers.length;
            uint256 feeTiersSum;

            for (uint256 i; i < feeTiersLength; ) {
                unchecked {
                    feeTiersSum = feeTiersSum + _feeTiers[i].feeTier;
                    ++i;
                }
            }

            for (uint256 i; i < feeTiersLength; ) {
                if (_feeTiers[i].feeRecipient == address(this)) continue;

                uint256 fee = (serviceFee * _feeTiers[i].feeTier) / feeTiersSum;
                erc20Token.transfer(_feeTiers[i].feeRecipient, fee);

                unchecked {
                    ++i;
                }
            }
        }

        emit AmberfiLib.PaymentClaimed(msg.sender, highestBid.bidAmount);
    }

    /**
     * @dev Cancel auction
     * @param auctionId_ (uint256) Auction ID
     */
    function cancelAuction(uint256 auctionId_)
        external
        nonReentrant
        isValidAuction(auctionId_)
    {
        AmberfiLib.Auction storage auction = _auctions[auctionId_ - 1];
        AmberfiLib.Bid memory highestBid = auction.highestBid;
        AmberfiLib.AuctionState auctionState = auction.auctionState;

        if (msg.sender != auction.creator) {
            revert AmberfiLib.Market_AuctionCancelFailed(
                uint8(AmberfiLib.AuctionCancelErrorType.NOT_AUCTION_CREATOR)
            );
        }

        if (
            auctionState == AmberfiLib.AuctionState.COMPLETED ||
            auctionState == AmberfiLib.AuctionState.CANCELLED
        ) {
            revert AmberfiLib.Market_AuctionCancelFailed(
                uint8(
                    AmberfiLib
                        .AuctionCancelErrorType
                        .AUCTION_COMPLETED_OR_ALREADY_CANCELLED
                )
            );
        }

        if (block.timestamp >= auction.endTime) {
            revert AmberfiLib.Market_AuctionCancelFailed(
                uint8(AmberfiLib.AuctionCancelErrorType.AUCTION_ENDED)
            );
        }

        auction.auctionState = AmberfiLib.AuctionState.CANCELLED;

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.creator,
            auction.tokenId
        );

        if (highestBid.bidder != address(0)) {
            if (_paymentTokens[highestBid.paymentTokenIndex].native) {
                payable(highestBid.bidder).transfer(highestBid.bidAmount);
            } else {
                IERC20Upgradeable(
                    _paymentTokens[highestBid.paymentTokenIndex].token
                ).transferFrom(
                        address(this),
                        highestBid.bidder,
                        highestBid.bidAmount
                    );
            }
        }

        emit AmberfiLib.AuctionCanceled(auctionId_);
    }

    /**
     * @dev Withdraw MATIC
     * @param amount_ (uint256) MATIC amount
     */
    function withdrawMATIC(uint256 amount_)
        external
        payable
        nonReentrant
        onlyOwner
        onlyMarketOwnerRole
    {
        if (amount_ > address(this).balance) {
            revert AmberfiLib.Market_InvalidWithdrawAmount();
        }

        (bool result, uint256 paymentTokenIndex) = isPaymentToken(
            address(0),
            true
        );

        if (
            result && _serviceFeesPerPaymentTokenId[paymentTokenIndex] < amount_
        ) {
            revert AmberfiLib.Market_InvalidWithdrawAmount();
        }

        _serviceFeesPerPaymentTokenId[paymentTokenIndex] -= amount_;

        payable(address(msg.sender)).transfer(amount_);
    }

    /**
     * @dev Withdraw tokens
     * @param token_ (address) Token address
     * @param amount_ (uint256) Token amount
     */
    function withdrawTokens(address token_, uint256 amount_)
        external
        payable
        nonReentrant
        onlyOwner
        onlyMarketOwnerRole
    {
        if (amount_ > IERC20Upgradeable(token_).balanceOf(address(this))) {
            revert AmberfiLib.Market_InvalidWithdrawAmount();
        }

        (bool result, uint256 paymentTokenIndex) = isPaymentToken(
            address(token_),
            false
        );

        if (
            result && _serviceFeesPerPaymentTokenId[paymentTokenIndex] < amount_
        ) {
            revert AmberfiLib.Market_InvalidWithdrawAmount();
        }

        _serviceFeesPerPaymentTokenId[paymentTokenIndex] -= amount_;

        IERC20Upgradeable(token_).transferFrom(
            address(this),
            msg.sender,
            amount_
        );
    }

    /**
     * @dev Set service fee percent
     * @param feeTiers_ (AmberfiLib.MarketFeeTier[] calldata ) New service fee percent
     */
    function setFeeTiers(AmberfiLib.MarketFeeTier[] calldata feeTiers_)
        external
        payable
        onlyOwner
    {
        uint256 feeTiersLength = feeTiers_.length;
        uint256 feeTiersSum;

        for (uint256 i; i < feeTiersLength; ) {
            if (feeTiers_[i].feeRecipient == address(0)) {
                revert AmberfiLib.Market_InvalidFeeTierRecipient();
            }

            if (feeTiers_[i].feeTier == 0) {
                revert AmberfiLib.Market_InvalidFeeTier();
            }

            unchecked {
                feeTiersSum = feeTiersSum + feeTiers_[i].feeTier;
                ++i;
            }
        }

        if (feeTiersSum > 9999) {
            revert AmberfiLib.Market_InvalidFeeTiersSum();
        }

        delete _feeTiers;

        for (uint256 i; i < feeTiersLength; ) {
            _feeTiers.push(
                AmberfiLib.MarketFeeTier(
                    feeTiers_[i].feeRecipient,
                    feeTiers_[i].feeTier
                )
            );

            unchecked {
                ++i;
            }
        }

        emit AmberfiLib.MarketFeeTierChanged(feeTiers_);
    }

    /**
     * @dev Set minimum auction listing price in USD
     * @param newMinAuctionListingPriceUSD_ (uint256) New minimum auction listing price
     */
    function setMinAuctionListingPriceUSD(uint256 newMinAuctionListingPriceUSD_)
        external
        payable
        onlyOwner
    {
        _minAuctionListingPriceUSD = newMinAuctionListingPriceUSD_;

        emit AmberfiLib.MinAuctionListingPriceUSDChanged(
            newMinAuctionListingPriceUSD_
        );
    }

    /**
     * @dev Get minimum auction listing price in USD
     * @return (uint256) Minimum auction listingprice
     */
    function getMinAuctionListingPriceUSD() external view returns (uint256) {
        return _minAuctionListingPriceUSD;
    }

    /**
     * @dev Get auction object detail
     * @param auctionId_ (uint256) Auction ID
     * @return (uint256) Start time
     * @return (uint256) End time
     * @return (uint256) Price USD
     * @return (uint256) Start price
     * @return (uint256) Reserved price
     * @return (address) Auction creator
     * @return (address) NFT contract address
     * @return (uint256) Auction token ID
     * @return (uint256[] memory) PaymentToken indexes
     * @return (AuctionState) Auction State
     * @return (bool) Instant sale
     */
    function getAuction(uint256 auctionId_)
        external
        view
        isValidAuction(auctionId_)
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            address,
            uint256,
            uint256[] memory,
            AmberfiLib.AuctionState,
            bool
        )
    {
        AmberfiLib.Auction storage auction = _auctions[auctionId_ - 1];
        return (
            auction.startTime,
            auction.endTime,
            auction.priceUSD,
            auction.startPrice,
            auction.reservedPrice,
            auction.creator,
            auction.nftContract,
            auction.tokenId,
            auction.paymentTokenIndexes,
            auction.auctionState,
            auction.instantSale
        );
    }

    /**
     * @dev Get all auctions for specific NFT contract and token ID
     * @param nftContract_ (address) NFT contract address
     * @param tokenId_ (uint256) NFT contract token ID
     * @return auctionIds (uint256[] memory) Auctions
     */
    function getAuctionsForTokenId(address nftContract_, uint256 tokenId_)
        external
        view
        returns (uint256[] memory auctionIds)
    {
        uint256 length = getAuctionsCount();
        uint256 filtered;

        for (uint256 i; i < length; ++i) {
            if (
                _auctions[i].nftContract == nftContract_ &&
                _auctions[i].tokenId == tokenId_
            ) {
                ++filtered;
            }
        }

        auctionIds = new uint256[](filtered);
        uint256 index;

        for (uint256 i; i < length; ++i) {
            if (
                _auctions[i].nftContract == nftContract_ &&
                _auctions[i].tokenId == tokenId_
            ) {
                auctionIds[index] = _auctions[i].auctionId;
                ++index;
            }
        }
    }

    /**
     * @dev Get a list of all bids of an auction
     * @param auctionId_ (uint256) Auction ID
     * @return bidders (address[] memory) Bid addresses
     * @return bids (uint256[] memory) Bid amounts
     */
    function getAuctionBids(uint256 auctionId_)
        external
        view
        isValidAuction(auctionId_)
        returns (address[] memory, uint256[] memory)
    {
        uint256 length = _bidsPerAuctionId[auctionId_].length;

        address[] memory bidders = new address[](length);
        uint256[] memory bids = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            bidders[i] = _bidsPerAuctionId[auctionId_][i].bidder;
            bids[i] = _bidsPerAuctionId[auctionId_][i].bidAmount;
        }

        return (bidders, bids);
    }

    /**
     * @dev Get auction IDs in an offset with index `offset_` for `length_` length
     * @param offset_ (uint256) Offset index
     * @param length_ (uint256) Length of an offset
     * @return auctionIds (uint256[] memory) Auction IDs
     * @return nextOffset (uint256) Next offset index
     */
    function getAuctions(uint256 offset_, uint256 length_)
        external
        view
        returns (uint256[] memory auctionIds, uint256 nextOffset)
    {
        uint256 length = getAuctionsCount();

        if (length_ > length - offset_) {
            length_ = length - offset_;
        }

        auctionIds = new uint256[](length_);

        for (uint256 i; i < length_; ++i) {
            auctionIds[i] = _auctions[offset_ + i].auctionId;
        }

        nextOffset = offset_ + length_;
    }

    /**
     * @dev Get all auctions
     * @return (Auction[] memory) Auctions
     */
    function getAllAuctions()
        public
        view
        returns (AmberfiLib.Auction[] memory)
    {
        return _auctions;
    }

    /**
     * @dev Get all auctions
     * @return auctionCount (uint256) Auction count
     */
    function getAuctionsCount() public view returns (uint256) {
        return _auctionIdCounter.current() - 1;
    }

    /**
     * @dev Return service fee tiers
     * @return (AmberfiLib.MarketFeeTier[] memory) Fee tiers
     */
    function getFeeTiers()
        external
        view
        returns (AmberfiLib.MarketFeeTier[] memory)
    {
        return _feeTiers;
    }

    /**
     * @dev Get service fee percent
     * @return (uint256) Service fee percent
     */
    function getServiceFeePercent() public view returns (uint256) {
        uint256 feeTiersLength = _feeTiers.length;
        uint256 feeTiersSum;

        unchecked {
            for (uint256 i; i < feeTiersLength; ++i) {
                feeTiersSum = feeTiersSum + _feeTiers[i].feeTier;
            }
        }

        return feeTiersSum;
    }

    /**
     * @dev Get PaymentTokens
     * @return (PaymentToken[] memory) PaymentTokenS
     */
    function getPaymentTokens()
        external
        view
        returns (AmberfiLib.PaymentToken[] memory)
    {
        return _paymentTokens;
    }

    /**
     * @dev Get rate USD:PaymentToken
     * @param usdAmount_ (uint256) USD amount as input
     * @param paymentTokenIndex_ (uint256) PaymentToken index
     * @return pricePaymentToken (uint256) USD price as output (10**aggregator decimals weighted)
     */
    function getPrice(uint256 usdAmount_, uint256 paymentTokenIndex_)
        external
        view
        returns (uint256 pricePaymentToken)
    {
        AmberfiLib.PaymentToken storage paymentToken = _paymentTokens[
            paymentTokenIndex_
        ];

        if (!paymentToken.enabled) {
            revert AmberfiLib.Market_TokenNotEnabled();
        }

        uint8 decimals = paymentToken.tokenDecimals +
            paymentToken.aggregatorDecimals;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            paymentToken.aggregator
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        pricePaymentToken =
            (usdAmount_ * 10**(decimals - 6)) /
            (uint256)(price);
    }

    /**
     * @dev Get rate USD:PaymentToken
     * @param paymentTokenAmount_ (uint256) PaymentToken amount as input
     * @param paymentTokenIndex_ (uint256) PaymentToken index
     * @return priceUSD (uint256) USD price as output (10**aggregator decimals weighted)
     */
    function getRate(uint256 paymentTokenAmount_, uint256 paymentTokenIndex_)
        public
        view
        returns (uint256 priceUSD)
    {
        AmberfiLib.PaymentToken storage paymentToken = _paymentTokens[
            paymentTokenIndex_
        ];

        if (!paymentToken.enabled) {
            revert AmberfiLib.Market_TokenNotEnabled();
        }

        uint8 decimals = paymentToken.tokenDecimals +
            paymentToken.aggregatorDecimals;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            paymentToken.aggregator
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        priceUSD =
            (paymentTokenAmount_ * (uint256)(price)) /
            10**(decimals - 6);
    }

    /**
     * @dev Check if token is PaymentToken
     * @param token_ (address) Token address to check
     * @return result (bool) Check result
     * @return paymentTokenIndex (uint256) PaymentToken index
     */
    function isPaymentToken(address token_, bool native_)
        public
        view
        returns (bool result, uint256 paymentTokenIndex)
    {
        uint256 length = _paymentTokens.length;

        for (uint256 i; i < length; ) {
            if (
                (native_ && _paymentTokens[i].enabled) ||
                (!native_ &&
                    token_ == _paymentTokens[i].token &&
                    _paymentTokens[i].enabled)
            ) {
                result = true;
                paymentTokenIndex = i;
            }

            unchecked {
                ++i;
            }
        }
    }

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
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /**
     * @dev Get contract version
     * @return (string memory) Version string
     */
    function contractVersion() public pure returns (string memory) {
        return "1.0.0";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AmberfiLib {
    enum AuctionCreateErrorType {
        INVALID_TIME_RANGE,
        INVALID_PRICE_USD,
        INVALID_START_PRICE,
        INVALID_RESERVED_PRICE,
        INVALID_NFT_CONTRACT,
        INVALID_TOKEN_ID,
        INVALID_PAYMENT_TOKEN_INDEX
    }

    enum AuctionBuyNowErrorType {
        INSTANTSALE_NOT_ENABLED,
        INVALID_PAYMENT_AMOUNT,
        INVALID_PAYMENT_TOKEN_INDEX,
        CREATOR_CANNOT_BUY,
        AUCTION_COMPLETED_OR_CANCELLED,
        AUCTION_ENDED_OR_NOT_STARTED
    }

    enum AuctionBidErrorType {
        CANNOT_BID_TO_INSTANT_SALE_AUCTION,
        INVALID_BID_AMOUNT,
        INVALID_PAYMENT_TOKEN_INDEX,
        CREATOR_CANNOT_BID,
        AUCTION_COMPLETED_OR_CANCELLED,
        AUCTION_ENDED_OR_NOT_STARTED
    }

    enum AuctionRedeemNFTErrorType {
        NOT_AUCTION_WINNER,
        AUCTION_COMPLETED_OR_CANCELLED,
        AUCTION_NOT_ENDED,
        NFT_ALREADY_REDEEMED
    }

    enum AuctionClaimPaymentErrorType {
        NOT_AUCTION_CREATOR,
        AUCTION_COMPLETED_OR_CANCELLED,
        AUCTION_NOT_ENDED,
        NFT_NOT_REDEEMED
    }

    enum AuctionCancelErrorType {
        NOT_AUCTION_CREATOR,
        AUCTION_COMPLETED_OR_ALREADY_CANCELLED,
        AUCTION_ENDED
    }

    enum PaymentTokenRemoveErrorType {
        INVALID_PAYMENT_TOKEN_INDEX,
        WITHDRAW_TOKENS_FIRST,
        ACTIVE_AUCTIONS_EXIST
    }

    enum AuctionState {
        STARTED, // Auction started
        CANCELLED, // Auction cancelled
        COMPLETED // Auction completed
    }

    enum ClaimState {
        NONE,
        REDEEMED, // Auction ended and NFT redeemed
        CLAIMED // Auction ended and payment claimed
    }

    struct Auction {
        uint256 auctionId; // Auction ID
        uint256 startTime; // Auction start time in timestamp
        uint256 endTime; // Auction end time in timestamp
        uint256 priceUSD; // Auction price in USD (for instant sale)
        uint256 startPrice; // Auction start price in PaymentToken
        uint256 reservedPrice; // Auction reserved price in PaymentToken
        address creator; // Auction creator
        address nftContract; // The address of the NFT contract
        uint256 tokenId; // Token ID
        uint256[] paymentTokenIndexes; // Array of PaymentToken indexes to place bid at this auction
        Bid highestBid;
        AuctionState auctionState; // Auction state
        bool instantSale; // true for instant sale, false for not
    }

    struct Bid {
        address bidder; // Bidder address
        uint256 bidAmount; // Bid amount in PaymentToken
        uint256 paymentTokenIndex; // Bid PaymentToken index
    }

    struct PaymentToken {
        address token; // Token address
        address aggregator; // Chainlink Aggregator address
        uint8 tokenDecimals; // Token decimals
        uint8 aggregatorDecimals; // Aggregator decimals
        bool native; // Check if token is native or ERC-20 (if native, token = 0x0, decimals = 18)
        bool enabled; // Check if token is enabled
    }

    struct MarketContract {
        uint256 marketId;
        address marketContract;
        address marketOwner;
        bool enabled;
    }

    struct MarketFeeTier {
        address feeRecipient;
        uint256 feeTier; // 1% = 100
    }

    error Market_InvalidAuctionID();
    error Market_InvalidMetaTxSignature();
    error Market_InvalidMinAuctionPrice();
    error Market_InvalidWithdrawAmount();
    error Market_AuctionCreateFailed(uint8 errorType);
    error Market_AuctionBuyNowFailed(uint8 errorType);
    error Market_AuctionBidFailed(uint8 errorType);
    error Market_AuctionRedeemNFTFailed(uint8 errorType);
    error Market_AuctionClaimPaymentFailed(uint8 errorType);
    error Market_AuctionCancelFailed(uint8 errorType);
    error Market_PaymentTokenAddFailed();
    error Market_PaymentTokenRemoveFailed(uint8 errorType);
    error Market_TokenNotEnabled();
    error Market_ZeroAddress();
    error Market_Paused();
    error Market_InvalidFeeTierRecipient();
    error Market_InvalidFeeTier();
    error Market_InvalidFeeTiersSum();
    error MarketRegistry_NotAmberfiOwner();
    error MarketRegistry_NotMarketOwner();
    error MarketRegistry_NotAmberfiNorMarketOwner();
    error MarketRegistry_NotKYCVerifier();
    error NFT_ZeroAddress();
    error KYCVerify_ZeroAddress();

    event AuctionCreated(
        uint256 auctionId,
        uint256 startTime,
        uint256 endTime,
        uint256 startPrice,
        uint256 reservedPrice,
        address indexed creator,
        address indexed nftContract,
        uint256 tokenId,
        uint256 paymentTokenIndex
    ); // Event emitted when a new auction created
    event InstantSaleCreated(
        uint256 auctionId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceUSD,
        address indexed creator,
        address indexed nftContract,
        uint256 tokenId,
        uint256[] paymentTokenIndexes
    ); // Event emitted when a new instant sale created
    event BoughtNFT(
        address indexed buyer,
        uint256 amount,
        uint256 paymentTokenIndex
    ); // Event emitted when an instant sale auction item sold
    event BidPlaced(
        address indexed bidder,
        uint256 bid,
        uint256 paymentTokenIndex
    ); // Event emitted when a bid placed
    event NFTRedeemed(address indexed winner); // Event emitted when the auction winner redeem the purchased NFT
    event PaymentClaimed(address indexed owner, uint256 amount); // Event emitted when the auction owner claimed the payment
    event AuctionCanceled(uint256 auctionId); // Event emitted when the auction cancelled
    event MarketFeeTierChanged(MarketFeeTier[] feeTiers); // Event emitted when market fee tiers changed
    event MinAuctionListingPriceUSDChanged(
        uint256 newMinAuctionListingPriceUSD
    ); // Event emitted when new min auction listing price in USD changed
    event MinBidIncrementPercentChanged(uint256 percent); // Event emitted when a new bid increment percent is set
    event PaymentTokenAdded(
        uint256 index,
        address indexed token,
        address indexed aggregator,
        uint8 tokenDecimals,
        uint8 aggregatorDecimals,
        bool native
    ); // Event emitted when payment token added
    event PaymentTokenRemoved(uint256 index); // Event emitted when payment token removed
    event AmberfiPaused(); // Amberfi Registry contract paused
    event AmberfiUnpaused(); // Amberfi Registry contract unpaused
    event MarketPaused(uint256 marketId); // Market contract paused
    event MarketUnpaused(uint256 marketId); // Market contract unpaused
    event AmberfiOwnerRoleGranted(address indexed account);
    event AmberfiOwnerRoleRevoked(address indexed account);
    event MarketOwnerRoleGranted(address indexed account);
    event MarketOwnerRoleRevoked(address indexed account);
    event KYCVerifierRoleGranted(address indexed account);
    event KYCVerifierRoleRevoked(address indexed account);
    event MarketRegistered(
        uint256 marketId,
        address indexed marketContract,
        address indexed marketOwner,
        bool enabled
    );
    event MarketUnregistered(uint256 marketId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev TODO: Interface for the Multiple NFT Payouts Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 */
interface INFTPayoutsUpgradeable is IERC165Upgradeable {
    struct PayoutInfo {
        address receiver;
        uint96 payoutFraction;
    }

    /**
     * @dev TODO
     */
    function creator(uint256 tokenId) external view returns (address);

    /**
     * @dev TODO
     */
    function payoutCount(uint256 tokenId, bool isPayout)
        external
        view
        returns (uint256);

    /**
     * @dev TODO
     */
    function payoutInfo(
        uint256 tokenId,
        uint256 salePrice,
        bool isPayout
    )
        external
        view
        returns (address[] memory receivers, uint256[] memory payoutAmounts);
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IAmberfiKeyStorageUpgradeable
/// @dev Interface for the Key Storage. Store and retrieve Encrypted Key
interface IAmberfiKeyStorageUpgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId_`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId_)
        external
        view
        returns (bool);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param tokenId_ - the NFT asset queried for key information
    /// @return encryptKey - the royalty payment amount for value sale price
    function getEncryptKey(uint256 tokenId_)
        external
        view
        returns (string memory encryptKey);

    function setEncryptKey(uint256 tokenId_, string calldata encryptKey_)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
// Libraries
import "../libs/AmberfiLib.sol";

contract MarketRegistry is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _marketIdsCounter;
    AmberfiLib.MarketContract[] private _marketContracts;
    mapping(address => uint256) private _marketIds;

    bytes32 public constant AMBERFI_OWNER = keccak256("AMBERFI_OWNER");
    bytes32 public constant MARKET_OWNER = keccak256("MARKET_OWNER");
    bytes32 public constant KYC_VERIFIER = keccak256("KYC_VERIFIER");

    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(AMBERFI_OWNER, _msgSender());

        _marketIdsCounter.increment(); // Starts from 1

        emit AmberfiLib.MarketOwnerRoleGranted(_msgSender());
    }

    function pauseAmberfi() external onlyRole(AMBERFI_OWNER) {
        _pause();

        emit AmberfiLib.AmberfiPaused();
    }

    function unpauseAmberfi() external onlyRole(AMBERFI_OWNER) {
        _unpause();

        emit AmberfiLib.AmberfiUnpaused();
    }

    function registerMarket(address market_, address marketOwner_)
        external
        onlyRole(AMBERFI_OWNER)
    {
        uint256 id = marketIdCounter();

        if (!hasRole(MARKET_OWNER, marketOwner_)) {
            revert AmberfiLib.MarketRegistry_NotMarketOwner();
        }

        AmberfiLib.MarketContract memory marketContract = AmberfiLib
            .MarketContract(id, market_, marketOwner_, true);
        _marketContracts.push(marketContract);

        _marketIds[market_] = id;

        _marketIdsCounter.increment();

        emit AmberfiLib.MarketRegistered(id, market_, marketOwner_, true);
    }

    function unregisterMarket(uint256 marketId_)
        external
        onlyRole(AMBERFI_OWNER)
    {
        AmberfiLib.MarketContract storage marketContract = _marketContracts[
            marketId_
        ];
        marketContract.enabled = false;

        _marketIds[marketContract.marketContract] = 0;

        emit AmberfiLib.MarketUnregistered(marketId_);
    }

    /**
     * @dev Get contract version
     * @return (string memory) Version string
     */
    function contractVersion() public pure returns (string memory) {
        return "1.0.0";
    }

    function hasAmberfiOwnerRole(address account_) public view returns (bool) {
        return hasRole(AMBERFI_OWNER, account_);
    }

    function hasMarketOwnerRole(address account_) public view returns (bool) {
        return hasRole(MARKET_OWNER, account_);
    }

    function hasKYCVerifierRole(address account_) public view returns (bool) {
        return hasRole(KYC_VERIFIER, account_);
    }

    function marketId(address market_) public view returns (uint256) {
        return _marketIds[market_];
    }

    function marketIdCounter() public view returns (uint256) {
        return _marketIdsCounter.current();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165Upgradeable).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}