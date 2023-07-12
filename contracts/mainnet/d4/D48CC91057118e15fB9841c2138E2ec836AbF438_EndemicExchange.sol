// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./mixins/auction/EndemicAuction.sol";
import "./mixins/EndemicOffer.sol";
import "./mixins/EndemicPrivateSale.sol";

contract EndemicExchange is EndemicAuction, EndemicOffer, EndemicPrivateSale {
    /**
     * @notice Initialized Endemic exchange contract
     * @dev Only called once
     * @param _royaltiesProvider - royalyies provider contract
     * @param _paymentManager - payment manager contract address
     * @param _feeRecipientAddress - address to receive exchange fees
     */
    function __EndemicExchange_init(
        address _royaltiesProvider,
        address _paymentManager,
        address _feeRecipientAddress
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        __EndemicPrivateSale___init_unchained();

        _updateDistributorConfiguration(_feeRecipientAddress);
        _updateExchangeConfiguration(_royaltiesProvider, _paymentManager);
    }

    /**
     * @notice Updated contract internal configuration, callable by exchange owner
     * @param _royaltiesProvider - royalyies provider contract
     * @param _paymentManager - payment manager contract address
     * @param _feeRecipientAddress - address to receive exchange fees
     */
    function updateConfiguration(
        address _royaltiesProvider,
        address _paymentManager,
        address _feeRecipientAddress
    ) external onlyOwner {
        _updateDistributorConfiguration(_feeRecipientAddress);
        _updateExchangeConfiguration(_royaltiesProvider, _paymentManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./EndemicFundsDistributor.sol";
import "./EndemicExchangeCore.sol";

error PrivateSaleExpired();
error InvalidSignature();
error InvalidPrivateSale();

abstract contract EndemicPrivateSale is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    EndemicFundsDistributor,
    EndemicExchangeCore
{
    using AddressUpgradeable for address;

    bytes32 private constant PRIVATE_SALE_TYPEHASH =
        keccak256(
            // solhint-disable-next-line max-line-length
            "PrivateSale(address nftContract,uint256 tokenId,address paymentErc20TokenAddress,address seller,address buyer,uint256 price,uint256 deadline)"
        );

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    bytes32 private constant SALT_HASH = keccak256("Endemic Exchange Salt");

    string private constant DOMAIN_NAME = "Endemic Exchange";

    bytes32 public DOMAIN_SEPARATOR;

    // Maps nftContract -> tokenId -> seller -> buyer -> price -> deadline -> invalidated.
    // solhint-disable-next-line max-line-length
    mapping(address => mapping(uint256 => mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => bool))))))
        private privateSaleInvalidated;

    event PrivateSaleSuccess(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        uint256 price,
        uint256 totalFees,
        address paymentErc20TokenAddress
    );

    function __EndemicPrivateSale___init_unchained() internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes("1")),
                block.chainid,
                address(this),
                SALT_HASH
            )
        );
    }

    function buyFromPrivateSale(
        address paymentErc20TokenAddress,
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        if (deadline < block.timestamp) {
            revert PrivateSaleExpired();
        }

        uint256 takerCut = _calculateTakerCut(paymentErc20TokenAddress, price);

        address buyer = _msgSender();

        _requireSupportedPaymentMethod(paymentErc20TokenAddress);
        _requireSufficientCurrencySupplied(
            price + takerCut,
            paymentErc20TokenAddress,
            buyer
        );

        address payable seller = payable(IERC721(nftContract).ownerOf(tokenId));

        if (
            privateSaleInvalidated[nftContract][tokenId][seller][buyer][price][
                deadline
            ]
        ) {
            revert InvalidPrivateSale();
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PRIVATE_SALE_TYPEHASH,
                        nftContract,
                        tokenId,
                        paymentErc20TokenAddress,
                        seller,
                        buyer,
                        price,
                        deadline
                    )
                )
            )
        );

        if (ecrecover(digest, v, r, s) != seller) {
            revert InvalidSignature();
        }

        _finalizePrivateSale(
            nftContract,
            tokenId,
            paymentErc20TokenAddress,
            seller,
            price,
            deadline
        );
    }

    function _finalizePrivateSale(
        address nftContract,
        uint256 tokenId,
        address paymentErc20TokenAddress,
        address payable seller,
        uint256 price,
        uint256 deadline
    ) internal {
        privateSaleInvalidated[nftContract][tokenId][seller][_msgSender()][
            price
        ][deadline] = true;

        (
            uint256 makerCut,
            ,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut
        ) = _calculateFees(
                paymentErc20TokenAddress,
                nftContract,
                tokenId,
                price
            );

        IERC721(nftContract).transferFrom(seller, _msgSender(), tokenId);

        _distributeFunds(
            price,
            makerCut,
            totalCut,
            royaltieFee,
            royaltiesRecipient,
            seller,
            _msgSender(),
            paymentErc20TokenAddress
        );

        emit PrivateSaleSuccess(
            nftContract,
            tokenId,
            seller,
            _msgSender(),
            price,
            totalCut,
            paymentErc20TokenAddress
        );
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./EndemicFundsDistributor.sol";
import "./EndemicExchangeCore.sol";

error InvalidTokenOwner();
error DurationTooShort();
error OfferExists();
error InvalidOffer();
error NotExpiredOffer();
error AcceptFromSelf();
error ParametersDiffInSize();
error RefundFailed();

abstract contract EndemicOffer is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EndemicFundsDistributor,
    EndemicExchangeCore
{
    using AddressUpgradeable for address;

    uint256 public constant MIN_OFFER_DURATION = 1 hours;

    uint256 private nextOfferId;

    mapping(uint256 => Offer) private offersById;

    /// @dev Offer by token address => token id => offer bidder => offerId
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        private nftOfferIdsByBidder;

    /// @dev Offer by token address => offer bidder => offerId
    mapping(address => mapping(address => uint256))
        private collectionOfferIdsByBidder;

    /// @notice Active offer configuration
    struct Offer {
        /// @notice Id created for this offer
        uint256 id;
        /// @notice The address of the smart contract
        address nftContract;
        /// @notice The address of the supported ERC20 smart contract used for payments
        address paymentErc20TokenAddress;
        /// @notice The address of the offer bidder
        address bidder;
        /// @notice The ID of the NFT
        uint256 tokenId;
        /// @notice Amount bidded
        uint256 price;
        /// @notice Amount bidded including fees
        uint256 priceWithTakerFee;
        /// @notice Timestamp when offer expires
        uint256 expiresAt;
        /// @notice Flag if offer is for collection or for an NFT
        bool isForCollection;
    }

    /// @notice Fired when offer is created
    event OfferCreated(
        uint256 id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 price,
        uint256 expiresAt,
        address paymentErc20TokenAddress,
        bool isForCollection
    );

    /// @notice Fired when offer is accepted by the NFT owner
    event OfferAccepted(
        uint256 id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address bidder,
        address indexed seller,
        uint256 price,
        uint256 totalFees
    );

    /// @notice Fired when offer is canceled
    event OfferCancelled(
        uint256 id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed bidder
    );

    /// @notice Create an offer in ETH for an NFT
    function placeNftOffer(
        address nftContract,
        uint256 tokenId,
        uint256 duration
    ) external payable nonReentrant {
        _requireSufficientEtherSupplied(MIN_PRICE);

        (uint256 takerFee, ) = paymentManager.getPaymentMethodFees(
            ZERO_ADDRESS //ether fees
        );

        uint256 price = (msg.value * MAX_FEE) / (takerFee + MAX_FEE);

        _placeNftOffer(
            nftContract,
            ZERO_ADDRESS,
            tokenId,
            duration,
            price,
            msg.value
        );
    }

    /// @notice Create an offer in ERC20 token for an NFT
    function placeNftOfferInErc20(
        address nftContract,
        address paymentErc20TokenAddress,
        uint256 offerInErc20,
        uint256 tokenId,
        uint256 duration
    )
        external
        nonReentrant
        onlySupportedERC20Payments(paymentErc20TokenAddress)
    {
        _requireSufficientErc20Allowance(
            offerInErc20,
            paymentErc20TokenAddress,
            _msgSender()
        );

        (uint256 takerFee, ) = paymentManager.getPaymentMethodFees(
            paymentErc20TokenAddress
        );

        uint256 price = (offerInErc20 * MAX_FEE) / (takerFee + MAX_FEE);

        _placeNftOffer(
            nftContract,
            paymentErc20TokenAddress,
            tokenId,
            duration,
            price,
            offerInErc20
        );
    }

    /// @notice Create a collection offer in ETH for an NFT
    function placeCollectionOffer(address nftContract, uint256 duration)
        external
        payable
        nonReentrant
    {
        _requireSufficientEtherSupplied(MIN_PRICE);

        (uint256 takerFee, ) = paymentManager.getPaymentMethodFees(
            ZERO_ADDRESS //ether fees
        );

        uint256 price = (msg.value * MAX_FEE) / (takerFee + MAX_FEE);

        _placeCollectionOffer(
            nftContract,
            ZERO_ADDRESS,
            duration,
            price,
            msg.value
        );
    }

    /// @notice Create a collection offer in ERC20 token for an NFT
    function placeCollectionOfferInErc20(
        address nftContract,
        address paymentErc20TokenAddress,
        uint256 offerInErc20,
        uint256 duration
    )
        external
        nonReentrant
        onlySupportedERC20Payments(paymentErc20TokenAddress)
    {
        _requireSufficientErc20Allowance(
            offerInErc20,
            paymentErc20TokenAddress,
            _msgSender()
        );

        (uint256 takerFee, ) = paymentManager.getPaymentMethodFees(
            paymentErc20TokenAddress
        );

        uint256 price = (offerInErc20 * MAX_FEE) / (takerFee + MAX_FEE);

        _placeCollectionOffer(
            nftContract,
            paymentErc20TokenAddress,
            duration,
            price,
            offerInErc20
        );
    }

    /// @notice Cancels offer for ID
    function cancelOffer(uint256 offerId) external nonReentrant {
        Offer memory offer = offersById[offerId];
        if (offer.bidder != _msgSender()) revert InvalidOffer();

        _cancelOffer(offer);
    }

    /// @notice Cancels multiple offers
    function cancelOffers(uint256[] calldata offerIds) external nonReentrant {
        for (uint256 i = 0; i < offerIds.length; i++) {
            Offer memory offer = offersById[offerIds[i]];
            if (offer.bidder != _msgSender()) revert InvalidOffer();
            _cancelOffer(offer);
        }
    }

    /// @notice Accept an offer for NFT
    function acceptNftOffer(uint256 offerId) external nonReentrant {
        Offer memory offer = offersById[offerId];

        if (offer.isForCollection) revert InvalidOffer();

        _acceptOffer(offer, offerId, offer.tokenId);
    }

    /// @notice Accept a collection offer
    function acceptCollectionOffer(uint256 offerId, uint256 tokenId)
        external
        nonReentrant
    {
        Offer memory offer = offersById[offerId];

        if (!offer.isForCollection) revert InvalidOffer();

        _acceptOffer(offer, offerId, tokenId);
    }

    function getOffer(uint256 offerId) external view returns (Offer memory) {
        Offer memory offer = offersById[offerId];
        if (offer.id != offerId) revert InvalidOffer();

        return offer;
    }

    /**
     * @notice Allows owner to cancel offers, refunding eth to bidders
     * @dev This should only be used for extreme cases
     */
    function adminCancelOffers(uint256[] calldata offerIds)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < offerIds.length; i++) {
            Offer memory offer = offersById[offerIds[i]];
            _cancelOffer(offer);
        }
    }

    function _placeNftOffer(
        address nftContract,
        address paymentErc20TokenAddress,
        uint256 tokenId,
        uint256 duration,
        uint256 price,
        uint256 priceWithTakerFee
    ) internal {
        IERC721 nft = IERC721(nftContract);
        address nftOwner = nft.ownerOf(tokenId);

        if (nftOwner == _msgSender()) revert InvalidTokenOwner();
        if (duration < MIN_OFFER_DURATION) revert DurationTooShort();
        if (_bidderHasNftOffer(nftContract, tokenId, _msgSender()))
            revert OfferExists();

        uint256 offerId = ++nextOfferId;

        uint256 expiresAt = block.timestamp + duration;

        nftOfferIdsByBidder[nftContract][tokenId][_msgSender()] = offerId;
        offersById[offerId] = Offer({
            id: offerId,
            bidder: _msgSender(),
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            priceWithTakerFee: priceWithTakerFee,
            expiresAt: expiresAt,
            paymentErc20TokenAddress: paymentErc20TokenAddress,
            isForCollection: false
        });

        emit OfferCreated(
            offerId,
            nftContract,
            tokenId,
            _msgSender(),
            price,
            expiresAt,
            paymentErc20TokenAddress,
            false
        );
    }

    function _placeCollectionOffer(
        address nftContract,
        address paymentErc20TokenAddress,
        uint256 duration,
        uint256 price,
        uint256 priceWithTakerFee
    ) internal {
        if (duration < MIN_OFFER_DURATION) revert DurationTooShort();
        if (_bidderHasCollectionOffer(nftContract, _msgSender()))
            revert OfferExists();

        uint256 offerId = ++nextOfferId;

        uint256 expiresAt = block.timestamp + duration;

        collectionOfferIdsByBidder[nftContract][_msgSender()] = offerId;
        offersById[offerId] = Offer({
            id: offerId,
            bidder: _msgSender(),
            nftContract: nftContract,
            tokenId: 0,
            price: price,
            priceWithTakerFee: priceWithTakerFee,
            expiresAt: expiresAt,
            paymentErc20TokenAddress: paymentErc20TokenAddress,
            isForCollection: true
        });

        emit OfferCreated(
            offerId,
            nftContract,
            0,
            _msgSender(),
            price,
            expiresAt,
            paymentErc20TokenAddress,
            true
        );
    }

    function _acceptOffer(
        Offer memory offer,
        uint256 offerId,
        uint256 tokenId
    ) internal {
        if (offer.id != offerId || offer.expiresAt < block.timestamp) {
            revert InvalidOffer();
        }
        if (offer.bidder == _msgSender()) revert AcceptFromSelf();

        _deleteOffer(offer);

        (
            uint256 makerCut,
            ,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut
        ) = _calculateFees(
                offer.paymentErc20TokenAddress,
                offer.nftContract,
                tokenId,
                offer.price
            );

        // Transfer token to bidder
        IERC721(offer.nftContract).transferFrom(
            _msgSender(),
            offer.bidder,
            tokenId
        );

        _distributeFunds(
            offer.price,
            makerCut,
            totalCut,
            royaltieFee,
            royaltiesRecipient,
            _msgSender(),
            offer.bidder,
            offer.paymentErc20TokenAddress
        );

        emit OfferAccepted(
            offerId,
            offer.nftContract,
            tokenId,
            offer.bidder,
            _msgSender(),
            offer.price,
            totalCut
        );
    }

    function _cancelOffer(Offer memory offer) internal {
        _deleteOffer(offer);

        // Return ETH to bidder
        if (offer.paymentErc20TokenAddress == ZERO_ADDRESS) {
            (bool success, ) = payable(offer.bidder).call{
                value: offer.priceWithTakerFee
            }("");

            if (!success) revert RefundFailed();
        }

        emit OfferCancelled(
            offer.id,
            offer.nftContract,
            offer.tokenId,
            offer.bidder
        );
    }

    function _deleteOffer(Offer memory offer) internal {
        delete offersById[offer.id];

        if (offer.isForCollection) {
            delete collectionOfferIdsByBidder[offer.nftContract][offer.bidder];
        } else {
            delete nftOfferIdsByBidder[offer.nftContract][offer.tokenId][
                offer.bidder
            ];
        }
    }

    function _bidderHasNftOffer(
        address nftContract,
        uint256 tokenId,
        address bidder
    ) internal view returns (bool) {
        uint256 offerId = nftOfferIdsByBidder[nftContract][tokenId][bidder];
        Offer memory offer = offersById[offerId];
        return offer.bidder == bidder;
    }

    function _bidderHasCollectionOffer(address nftContract, address bidder)
        internal
        view
        returns (bool)
    {
        uint256 offerId = collectionOfferIdsByBidder[nftContract][bidder];
        Offer memory offer = offersById[offerId];
        return offer.bidder == bidder;
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../EndemicExchangeCore.sol";
import "./EndemicDutchAuction.sol";
import "./EndemicReserveAuction.sol";

abstract contract EndemicAuction is
    OwnableUpgradeable,
    EndemicDutchAuction,
    EndemicReserveAuction
{
    using AddressUpgradeable for address;

    /**
     * @notice Read active auction by id
     * @dev Reverts if auction doesn't exist
     * @param id id of the auction to read
     */
    function getAuction(bytes32 id)
        external
        view
        returns (
            address seller,
            address paymentErc20TokenAddress,
            uint256 startingPrice,
            uint256 endingPrice,
            uint256 startedAt,
            uint256 endingAt,
            uint256 amount
        )
    {
        Auction memory auction = idToAuction[id];
        if (!_isActiveAuction(auction)) revert InvalidAuction();
        return (
            auction.seller,
            auction.paymentErc20TokenAddress,
            auction.startingPrice,
            auction.endingPrice,
            auction.startedAt,
            auction.endingAt,
            auction.amount
        );
    }

    /**
     * @notice Cancels active auction
     * @dev Reverts if auction doesn't exist or if is listed as reserve and in progress
     * @param id - id of the auction to cancel
     */
    function cancelAuction(bytes32 id) external nonReentrant {
        Auction memory auction = idToAuction[id];
        if (_msgSender() != auction.seller) revert Unauthorized();
        if (auction.auctionType == AuctionType.RESERVE && auction.endingAt != 0)
            revert AuctionInProgress();

        _removeAuction(auction.id);

        emit AuctionCancelled(auction.id);
    }

    /**
     * @notice Allows owner to cancel auctions
     * @dev This should only be used for extreme cases
     */
    function adminCancelAuctions(bytes32[] calldata ids)
        external
        nonReentrant
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            Auction memory auction = idToAuction[ids[i]];
            if (_isActiveAuction(auction)) {
                _removeAuction(auction.id);
                emit AuctionCancelled(auction.id);
            }
        }
    }

    /**
     * @notice Creates auction id based on provided params
     * @param nftContract contract address of the collection
     * @param tokenId NFT token ID
     * @param seller address of the NFT seller
     */
    function createAuctionId(
        address nftContract,
        uint256 tokenId,
        address seller
    ) public pure returns (bytes32) {
        return _createAuctionId(nftContract, tokenId, seller);
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./EndemicExchangeCore.sol";

error FeeTransferFailed();
error RoyaltiesTransferFailed();
error FundsTransferFailed();

abstract contract EndemicFundsDistributor {
    address public feeRecipientAddress;

    function _distributeFunds(
        uint256 price,
        uint256 makerCut,
        uint256 totalCut,
        uint256 royaltieFee,
        address royaltiesRecipient,
        address seller,
        address buyer,
        address paymentErc20TokenAddress
    ) internal {
        uint256 sellerProceeds = price - makerCut - royaltieFee;

        if (
            paymentErc20TokenAddress ==
            address(0x0000000000000000000000000000000000001010)
        ) {
            _distributeEtherFunds(
                royaltieFee,
                totalCut,
                sellerProceeds,
                royaltiesRecipient,
                seller
            );
        } else {
            _distributeErc20Funds(
                royaltieFee,
                totalCut,
                sellerProceeds,
                royaltiesRecipient,
                seller,
                buyer,
                paymentErc20TokenAddress
            );
        }
    }

    function _distributeEtherFunds(
        uint256 royaltieFee,
        uint256 totalCut,
        uint256 sellerProceeds,
        address royaltiesRecipient,
        address seller
    ) internal {
        if (royaltieFee > 0) {
            _transferEtherRoyalties(royaltiesRecipient, royaltieFee);
        }

        if (totalCut > 0) {
            _transferEtherFees(totalCut);
        }

        _transferEtherFunds(seller, sellerProceeds);
    }

    function _distributeErc20Funds(
        uint256 royaltieFee,
        uint256 totalCut,
        uint256 sellerProceeds,
        address royaltiesRecipient,
        address seller,
        address buyer,
        address paymentErc20TokenAddress
    ) internal {
        IERC20 ERC20PaymentToken = IERC20(paymentErc20TokenAddress);

        if (royaltieFee > 0) {
            _transferErc20Royalties(
                ERC20PaymentToken,
                buyer,
                royaltiesRecipient,
                royaltieFee
            );
        }

        if (totalCut > 0) {
            _transferErc20Fees(ERC20PaymentToken, buyer, totalCut);
        }

        _transferErc20Funds(ERC20PaymentToken, buyer, seller, sellerProceeds);
    }

    function _transferEtherFees(uint256 value) internal {
        (bool success, ) = payable(feeRecipientAddress).call{value: value}("");

        if (!success) revert FeeTransferFailed();
    }

    function _transferErc20Fees(
        IERC20 ERC20PaymentToken,
        address sender,
        uint256 value
    ) internal {
        bool success = ERC20PaymentToken.transferFrom(
            sender,
            feeRecipientAddress,
            value
        );

        if (!success) revert FeeTransferFailed();
    }

    function _transferEtherRoyalties(
        address royaltiesRecipient,
        uint256 royaltiesCut
    ) internal {
        (bool success, ) = payable(royaltiesRecipient).call{
            value: royaltiesCut
        }("");

        if (!success) revert RoyaltiesTransferFailed();
    }

    function _transferErc20Royalties(
        IERC20 ERC20PaymentToken,
        address royaltiesSender,
        address royaltiesRecipient,
        uint256 royaltiesCut
    ) internal {
        bool success = ERC20PaymentToken.transferFrom(
            royaltiesSender,
            royaltiesRecipient,
            royaltiesCut
        );

        if (!success) revert RoyaltiesTransferFailed();
    }

    function _transferEtherFunds(address recipient, uint256 value) internal {
        (bool success, ) = payable(recipient).call{value: value}("");

        if (!success) revert FundsTransferFailed();
    }

    function _transferErc20Funds(
        IERC20 ERC20PaymentToken,
        address sender,
        address recipient,
        uint256 value
    ) internal {
        bool success = ERC20PaymentToken.transferFrom(sender, recipient, value);

        if (!success) revert FundsTransferFailed();
    }

    function _updateDistributorConfiguration(
        address _feeRecipientAddress
    ) internal {
        feeRecipientAddress = _feeRecipientAddress;
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../royalties/interfaces/IRoyaltiesProvider.sol";
import "../../manager/interfaces/IPaymentManager.sol";

error InvalidAddress();
error InvalidInterface();
error SellerNotAssetOwner();
error InvalidAssetClass();
error UnsufficientCurrencySupplied();
error InvalidPaymentMethod();

abstract contract EndemicExchangeCore {
    bytes4 public constant ERC721_INTERFACE = bytes4(0x80ac58cd);
    bytes4 public constant ERC1155_INTERFACE = bytes4(0xd9b67a26);

    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));

    IRoyaltiesProvider public royaltiesProvider;
    IPaymentManager public paymentManager;

    uint256 internal constant MAX_FEE = 10000;
    uint256 internal constant MIN_PRICE = 0.0001 ether;
    address internal constant ZERO_ADDRESS =
        address(0x0000000000000000000000000000000000001010);

    modifier onlySupportedERC20Payments(address paymentErc20TokenAddress) {
        if (
            paymentErc20TokenAddress == ZERO_ADDRESS ||
            !paymentManager.isPaymentMethodSupported(paymentErc20TokenAddress)
        ) revert InvalidPaymentMethod();

        _;
    }

    function _calculateFees(
        address paymentMethodAddress,
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        internal
        view
        returns (
            uint256 makerCut,
            uint256 takerCut,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut
        )
    {
        (uint256 takerFee, uint256 makerFee) = paymentManager
            .getPaymentMethodFees(paymentMethodAddress);

        takerCut = _calculateCut(takerFee, price);
        makerCut = _calculateCut(makerFee, price);

        (royaltiesRecipient, royaltieFee) = royaltiesProvider
            .calculateRoyaltiesAndGetRecipient(nftContract, tokenId, price);

        totalCut = takerCut + makerCut;
    }

    function _calculateTakerCut(
        address paymentErc20TokenAddress,
        uint256 price
    ) internal view returns (uint256) {
        (uint256 takerFee, ) = paymentManager.getPaymentMethodFees(
            paymentErc20TokenAddress
        );

        return _calculateCut(takerFee, price);
    }

    function _calculateCut(
        uint256 fee,
        uint256 amount
    ) internal pure returns (uint256) {
        return (amount * fee) / MAX_FEE;
    }

    function _requireCorrectNftInterface(
        bytes4 _assetClass,
        address _nftContract
    ) internal view {
        if (_assetClass == ERC721_ASSET_CLASS) {
            if (!IERC721(_nftContract).supportsInterface(ERC721_INTERFACE))
                revert InvalidInterface();
        } else if (_assetClass == ERC1155_ASSET_CLASS) {
            if (!IERC1155(_nftContract).supportsInterface(ERC1155_INTERFACE))
                revert InvalidInterface();
        } else {
            revert InvalidAssetClass();
        }
    }

    function _requireTokenOwnership(
        bytes4 assetClass,
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address seller
    ) internal view {
        if (assetClass == ERC721_ASSET_CLASS) {
            if (IERC721(nftContract).ownerOf(tokenId) != seller)
                revert SellerNotAssetOwner();
        } else if (assetClass == ERC1155_ASSET_CLASS) {
            if (IERC1155(nftContract).balanceOf(seller, tokenId) < amount)
                revert SellerNotAssetOwner();
        } else {
            revert InvalidAssetClass();
        }
    }

    function _requireSupportedPaymentMethod(
        address paymentMethodAddress
    ) internal view {
        if (paymentMethodAddress == ZERO_ADDRESS) return;

        if (!paymentManager.isPaymentMethodSupported(paymentMethodAddress)) {
            revert InvalidPaymentMethod();
        }
    }

    function _requireSufficientCurrencySupplied(
        uint256 sufficientAmount,
        address paymentMethodAddress,
        address buyer
    ) internal view {
        if (paymentMethodAddress == ZERO_ADDRESS) {
            _requireSufficientEtherSupplied(sufficientAmount);
        } else {
            _requireSufficientErc20Allowance(
                sufficientAmount,
                paymentMethodAddress,
                buyer
            );
        }
    }

    function _requireSufficientEtherSupplied(
        uint256 sufficientAmount
    ) internal view {
        if (msg.value < sufficientAmount) {
            revert UnsufficientCurrencySupplied();
        }
    }

    function _requireSufficientErc20Allowance(
        uint256 sufficientAmount,
        address paymentMethodAddress,
        address buyer
    ) internal view {
        IERC20 ERC20PaymentToken = IERC20(paymentMethodAddress);

        uint256 contractAllowance = ERC20PaymentToken.allowance(
            buyer,
            address(this)
        );

        if (contractAllowance < sufficientAmount) {
            revert UnsufficientCurrencySupplied();
        }
    }

    function _updateExchangeConfiguration(
        address _royaltiesProvider,
        address _paymentManager
    ) internal {
        if (
            _royaltiesProvider == ZERO_ADDRESS ||
            _paymentManager == ZERO_ADDRESS
        ) revert InvalidAddress();

        royaltiesProvider = IRoyaltiesProvider(_royaltiesProvider);
        paymentManager = IPaymentManager(_paymentManager);
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
pragma solidity 0.8.15;

interface IRoyaltiesProvider {
    function calculateRoyaltiesAndGetRecipient(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPaymentManager {
    function getPaymentMethodFees(address paymentMethodAddress)
        external
        view
        returns (uint256 takerFee, uint256 makerFee);

    function isPaymentMethodSupported(address paymentMethodAddress)
        external
        view
        returns (bool);

    function updateSupportedPaymentMethod(
        address paymentMethodAddress,
        bool isEnabled
    ) external;

    function updatePaymentMethodFees(
        address paymentMethodAddress,
        uint256 makerFee,
        uint256 takerFee
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./EndemicAuctionCore.sol";

error InsufficientBid();
error NoPendingWithdrawals();
error ReservePriceAlreadySet();

abstract contract EndemicReserveAuction is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    EndemicAuctionCore
{
    uint256 private constant EXTENSION_DURATION = 15 minutes;
    uint256 private constant RESERVE_AUCTION_DURATION = 24 hours;
    uint256 private constant MIN_BID_PERCENTAGE = 10;

    /// @notice Fired when reserve bid is placed
    event ReserveBidPlaced(
        bytes32 indexed id,
        address indexed bidder,
        uint256 indexed reservePrice,
        uint256 endingAt
    );

    /// @notice Creates reserve auction
    /// @dev Since we don't do escrow, only ERC20 payment is available
    function createReserveAuction(
        address nftContract,
        uint256 tokenId,
        uint256 reservePrice,
        address paymentErc20TokenAddress
    )
        external
        nonReentrant
        onlySupportedERC20Payments(paymentErc20TokenAddress)
    {
        _requireValidAuctionRequest(
            paymentErc20TokenAddress,
            nftContract,
            tokenId,
            1,
            ERC721_ASSET_CLASS
        );

        if (reservePrice < MIN_PRICE) {
            revert InvalidPriceConfiguration();
        }

        bytes32 auctionId = _createAuctionId(
            nftContract,
            tokenId,
            _msgSender()
        );

        //seller cannot recreate auction if it is already in progress
        _requireIdleAuction(auctionId);

        Auction memory auction = Auction({
            auctionType: AuctionType.RESERVE,
            id: auctionId,
            nftContract: nftContract,
            highestBidder: address(0),
            seller: _msgSender(),
            paymentErc20TokenAddress: paymentErc20TokenAddress,
            tokenId: tokenId,
            amount: 1,
            startingPrice: reservePrice,
            endingPrice: 0,
            startedAt: block.timestamp,
            endingAt: 0, //timer is not started yet
            assetClass: ERC721_ASSET_CLASS
        });

        idToAuction[auctionId] = auction;

        emit AuctionCreated(
            nftContract,
            tokenId,
            auctionId,
            reservePrice,
            0,
            RESERVE_AUCTION_DURATION,
            _msgSender(),
            1,
            paymentErc20TokenAddress,
            ERC721_ASSET_CLASS
        );
    }

    /// @notice Place bid for reseve auction
    /// @dev ERC20 allowance is required here
    function bidForReserveAuctionInErc20(bytes32 id, uint256 bidPriceWithFees)
        external
        nonReentrant
    {
        Auction memory auction = idToAuction[id];

        _requireAuctionType(auction, AuctionType.RESERVE);

        _requireValidBidRequest(auction, 1);

        (uint256 takerFee, ) = paymentManager.getPaymentMethodFees(
            auction.paymentErc20TokenAddress
        );

        uint256 bidPrice = (bidPriceWithFees * MAX_FEE) / (takerFee + MAX_FEE);

        if (auction.endingAt != 0) {
            // Auction already started which means it has a bid
            _outBidPreviousBidder(auction, bidPriceWithFees, bidPrice);
        } else {
            // Auction hasn't started yet
            _placeBidAndStartTimer(
                auction,
                bidPriceWithFees,
                bidPrice,
                takerFee
            );
        }

        idToAuction[auction.id] = auction;

        emit ReserveBidPlaced(
            auction.id,
            _msgSender(),
            bidPrice,
            auction.endingAt
        );
    }

    /// @notice Finalizes reserve auction, transfering currency and NFT
    function finalizeReserveAuction(bytes32 id) external nonReentrant {
        Auction memory auction = idToAuction[id];

        if (
            (auction.seller != _msgSender()) &&
            (auction.highestBidder != _msgSender())
        ) revert Unauthorized();

        if (auction.endingAt == 0) revert AuctionNotStarted();
        if (auction.endingAt >= block.timestamp) revert AuctionInProgress();

        _removeAuction(id);

        (
            uint256 makerCut,
            ,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut
        ) = _calculateFees(
                auction.paymentErc20TokenAddress,
                auction.nftContract,
                auction.tokenId,
                auction.endingPrice
            );

        _transferNFT(
            auction.seller,
            auction.highestBidder,
            auction.nftContract,
            auction.tokenId,
            auction.amount,
            auction.assetClass
        );

        _distributeFunds(
            auction.endingPrice,
            makerCut,
            totalCut,
            royaltieFee,
            royaltiesRecipient,
            auction.seller,
            auction.highestBidder,
            auction.paymentErc20TokenAddress
        );

        emit AuctionSuccessful(
            auction.id,
            auction.endingPrice,
            auction.highestBidder,
            auction.amount,
            totalCut
        );
    }

    function getHighestBidder(bytes32 id) external view returns (address) {
        Auction storage auction = idToAuction[id];

        return auction.highestBidder;
    }

    function _placeBidAndStartTimer(
        Auction memory auction,
        uint256 bidPriceWithFees,
        uint256 bidPrice,
        uint256 takerFee
    ) internal view {
        uint256 takerCut = _calculateCut(takerFee, auction.startingPrice);

        if (auction.startingPrice + takerCut > bidPriceWithFees)
            revert UnsufficientCurrencySupplied();

        _requireSufficientErc20Allowance(
            bidPriceWithFees,
            auction.paymentErc20TokenAddress,
            _msgSender()
        );

        //auction will last until 24hours from now
        auction.endingAt = block.timestamp + RESERVE_AUCTION_DURATION;
        auction.endingPrice = bidPrice;

        auction.highestBidder = _msgSender();
    }

    function _outBidPreviousBidder(
        Auction memory auction,
        uint256 bidPriceWithFees,
        uint256 bidPrice
    ) internal view {
        if (auction.endingAt < block.timestamp) revert AuctionEnded();
        // Bidder cannot outbid themself
        if (auction.highestBidder == _msgSender()) revert Unauthorized();

        _requireSufficientOutBid(
            auction.paymentErc20TokenAddress,
            auction.endingPrice,
            bidPriceWithFees
        );

        auction.endingPrice = bidPrice;
        auction.highestBidder = _msgSender();

        // If bidder outbids another bidder in last 15min of auction extend auction by 15mins
        uint256 extendedEndingTime = block.timestamp + EXTENSION_DURATION;
        if (auction.endingAt < extendedEndingTime) {
            auction.endingAt = extendedEndingTime;
        }
    }

    function _requireSufficientOutBid(
        address paymentErc20TokenAddress,
        uint256 currentReservePrice,
        uint256 bidPriceWithFees
    ) internal view {
        //next bid in auction must be at least 10% higher than last one
        uint256 minIncrement = currentReservePrice / MIN_BID_PERCENTAGE;

        uint256 minRequiredBid = currentReservePrice + minIncrement;

        if (minRequiredBid > bidPriceWithFees) revert InsufficientBid();

        _requireSufficientErc20Allowance(
            bidPriceWithFees,
            paymentErc20TokenAddress,
            _msgSender()
        );
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./EndemicAuctionCore.sol";

abstract contract EndemicDutchAuction is
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    EndemicAuctionCore
{
    using AddressUpgradeable for address;

    /**
     * @notice Creates fixed auction for an NFT
     * Fixed auction is variant of dutch auction where startingPrice is equal to endingPrice
     */
    function createFixedDutchAuction(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 amount,
        address paymentErc20TokenAddress,
        bytes4 assetClass
    ) external nonReentrant {
        _createAuction(
            nftContract,
            tokenId,
            price,
            price,
            0,
            amount,
            paymentErc20TokenAddress,
            assetClass
        );
    }

    /**
     * @notice Creates dutch auction for an NFT
     * Dutch auction is auction where price of NFT lineary drops from startingPrice to endingPrice
     */
    function createDutchAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 amount,
        address paymentErc20TokenAddress,
        bytes4 assetClass
    ) external nonReentrant {
        if (duration < MIN_DURATION || duration > MAX_DURATION)
            revert InvalidDuration();

        if (startingPrice <= endingPrice) revert InvalidPriceConfiguration();

        _createAuction(
            nftContract,
            tokenId,
            startingPrice,
            endingPrice,
            duration,
            amount,
            paymentErc20TokenAddress,
            assetClass
        );
    }

    /**
     * @notice Purchase auction
     */
    function bidForDutchAuction(bytes32 id, uint256 tokenAmount)
        external
        payable
        nonReentrant
    {
        Auction memory auction = idToAuction[id];

        _requireAuctionType(auction, AuctionType.DUTCH);

        _requireValidBidRequest(auction, tokenAmount);

        _detractByAssetClass(auction, tokenAmount);

        uint256 currentPrice = _calculateCurrentPrice(auction) * tokenAmount;

        if (currentPrice == 0) revert InvalidPrice();

        (
            uint256 makerCut,
            uint256 takerCut,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut
        ) = _calculateFees(
                auction.paymentErc20TokenAddress,
                auction.nftContract,
                auction.tokenId,
                currentPrice
            );

        currentPrice = _determinePriceByPaymentMethod(
            auction.paymentErc20TokenAddress,
            currentPrice,
            takerCut
        );

        _requireSufficientCurrencySupplied(
            currentPrice + takerCut,
            auction.paymentErc20TokenAddress,
            _msgSender()
        );

        _transferNFT(
            auction.seller,
            _msgSender(),
            auction.nftContract,
            auction.tokenId,
            tokenAmount,
            auction.assetClass
        );

        _distributeFunds(
            currentPrice,
            makerCut,
            totalCut,
            royaltieFee,
            royaltiesRecipient,
            auction.seller,
            _msgSender(),
            auction.paymentErc20TokenAddress
        );

        emit AuctionSuccessful(
            auction.id,
            currentPrice,
            _msgSender(),
            tokenAmount,
            totalCut
        );
    }

    /**
     * @notice Calculates current price for the auction
     */
    function getCurrentPrice(bytes32 id) external view returns (uint256) {
        Auction memory auction = idToAuction[id];

        if (
            !_isActiveAuction(auction) ||
            !_isAuctionType(auction, AuctionType.DUTCH)
        ) revert InvalidAuction();

        return _calculateCurrentPrice(auction);
    }

    /**
     * @notice Creates auction for an NFT
     */
    function _createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 amount,
        address paymentErc20TokenAddress,
        bytes4 assetClass
    ) internal {
        if (startingPrice < MIN_PRICE || endingPrice < MIN_PRICE)
            revert InvalidPriceConfiguration();

        _requireValidAuctionRequest(
            paymentErc20TokenAddress,
            nftContract,
            tokenId,
            amount,
            assetClass
        );

        bytes32 auctionId = _createAuctionId(
            nftContract,
            tokenId,
            _msgSender()
        );

        // Seller cannot recreate auction
        // if it is already listed as reserve auction that is in progress or ended
        _requireIdleAuction(auctionId);

        uint256 endingAt = block.timestamp + duration;

        Auction memory auction = Auction({
            auctionType: AuctionType.DUTCH,
            id: auctionId,
            nftContract: nftContract,
            seller: _msgSender(),
            highestBidder: address(0),
            paymentErc20TokenAddress: paymentErc20TokenAddress,
            tokenId: tokenId,
            amount: amount,
            startingPrice: startingPrice,
            endingPrice: endingPrice,
            startedAt: block.timestamp,
            endingAt: endingAt,
            assetClass: assetClass
        });

        idToAuction[auctionId] = auction;

        emit AuctionCreated(
            nftContract,
            tokenId,
            auctionId,
            startingPrice,
            endingPrice,
            endingAt,
            _msgSender(),
            amount,
            paymentErc20TokenAddress,
            assetClass
        );
    }

    /**
     * @notice Determines auction price by payment method
     * @dev Because of the nature of dutch auction we precalculate auction price in moment of rendering it on UI.
     * When the user bids we calculate the price again at the moment of method execution.
     * This price will be slightly smaller than one rendered on UI, which results in retaining a small amount of ether.
     * Which is the difference between precalculated price and the price calculated in the moment of method execution.
     * This is not the problem in the case of ERC20 payments because the difference will not retain on the contract
     * due to the token allowance technique.
     *
     * With this method in case of ether payments we forward all supplied ethers with the check
     * that it's not supplied less than @param currentPriceWithoutFees.
     * Difference that would retain on the contract is forwarded to the seller, retaining zero ether on this contract.
     *
     * @param paymentErc20TokenAddress - determines payment method for the auction
     * @param currentPriceWithoutFees - auction price calculated in moment of method execution without buyer fees
     * @param takerCut - buyer fees calculated for @param currentPriceWithoutFees
     */
    function _determinePriceByPaymentMethod(
        address paymentErc20TokenAddress,
        uint256 currentPriceWithoutFees,
        uint256 takerCut
    ) internal view returns (uint256) {
        //if auction is in ERC20 we use price calculated in moment of method execution
        if (paymentErc20TokenAddress != ZERO_ADDRESS) {
            return currentPriceWithoutFees;
        }

        //auction is in ether so we use amount of supplied ethers without taker cut as auction price
        uint256 suppliedEtherWithoutFees = msg.value - takerCut;

        //amount of supplied ether without buyer fees must not be smaller than the current price without buyer fees
        if (suppliedEtherWithoutFees < currentPriceWithoutFees) {
            revert UnsufficientCurrencySupplied();
        }

        return suppliedEtherWithoutFees;
    }

    /**
     * @notice Calculates current price depending on block timestamp
     */
    function _calculateCurrentPrice(Auction memory auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;
        uint256 duration = auction.endingAt - auction.startedAt;

        if (block.timestamp > auction.startedAt) {
            secondsPassed = block.timestamp - auction.startedAt;
        }

        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (secondsPassed >= duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return auction.endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(auction.endingPrice) -
                int256(auction.startingPrice);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = (totalPriceChange *
                int256(secondsPassed)) / int256(duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            return uint256(int256(auction.startingPrice) + currentPriceChange);
        }
    }

    /**
     * @notice Makes sure auction token amount is properly reduced for asset class
     */
    function _detractByAssetClass(Auction memory auction, uint256 tokenAmount)
        internal
    {
        if (auction.assetClass == ERC721_ASSET_CLASS) {
            _removeAuction(auction.id);
        } else if (auction.assetClass == ERC1155_ASSET_CLASS) {
            _deductFromAuction(auction, tokenAmount);
        } else {
            revert InvalidAssetClass();
        }
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../EndemicExchangeCore.sol";
import "../EndemicFundsDistributor.sol";

error Unauthorized();

error InvalidAuction();
error InvalidPrice();
error InvalidDuration();
error InvalidPriceConfiguration();
error InvalidAmount();

error AuctionNotStarted();
error AuctionInProgress();
error AuctionEnded();

abstract contract EndemicAuctionCore is
    EndemicFundsDistributor,
    EndemicExchangeCore
{
    using AddressUpgradeable for address;

    uint256 internal constant MAX_DURATION = 1000 days;
    uint256 internal constant MIN_DURATION = 1 minutes;

    mapping(bytes32 => Auction) internal idToAuction;

    /// @notice We support two auction types.
    /// Dutch auction has falling price.
    //  Reseve auction triggeres ascending price after the reserve price has been deposited
    enum AuctionType {
        DUTCH,
        RESERVE
    }

    /// @notice Active auction configuration
    struct Auction {
        /// @notice Type of this auction
        AuctionType auctionType;
        /// @notice Id created for this auction.
        /// @dev Auction for same contract, token ID and seller will always have the same ID
        bytes32 id;
        /// @notice The address of the smart contract
        address nftContract;
        /// @notice The address of the seller
        address seller;
        /// @notice The address of the curretn highst bidder when auction is of type RESERVE
        address highestBidder;
        /// @notice The address of the supported ERC20 smart contract used for payments
        address paymentErc20TokenAddress;
        /// @notice The ID of the NFT
        uint256 tokenId;
        /// @notice Amount of tokens to auction. Useful for ERC-1155
        uint256 amount;
        /// @notice Starting price of the dutch auction
        uint256 startingPrice;
        /// @notice Ending price of the dutch auction
        uint256 endingPrice;
        /// @notice Timestamp when auction started
        uint256 startedAt;
        /// @notice Timestamp when auction will end
        uint256 endingAt;
        /// @notice Type of NFT contract, ERC-721 or ERC-1155
        bytes4 assetClass;
    }

    /// @notice Fired when auction is created
    event AuctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        bytes32 indexed id,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 endingAt,
        address seller,
        uint256 amount,
        address paymentErc20TokenAddress,
        bytes4 assetClass
    );

    /// @notice Fired when auction is sucessfuly complated
    event AuctionSuccessful(
        bytes32 indexed id,
        uint256 indexed totalPrice,
        address winner,
        uint256 amount,
        uint256 totalFees
    );

    /// @notice Fired when auction is sucessfuly canceled
    event AuctionCancelled(bytes32 indexed id);

    /// @notice Deletes auction from the storage
    /// @param auctionId ID of the auction to delete
    function _removeAuction(bytes32 auctionId) internal {
        delete idToAuction[auctionId];
    }

    /// @notice Calculates remaining auction token amount.
    /// @dev It will delete auction for ERC-721 since amount is always 1
    function _deductFromAuction(Auction memory auction, uint256 amount)
        internal
    {
        idToAuction[auction.id].amount -= amount;
        if (idToAuction[auction.id].amount <= 0) {
            _removeAuction(auction.id);
        }
    }

    /// @notice Transfers NFT from seller to buyer
    function _transferNFT(
        address from,
        address receiver,
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        bytes4 assetClass
    ) internal {
        if (assetClass == ERC721_ASSET_CLASS) {
            IERC721(nftContract).transferFrom(from, receiver, tokenId);
        } else if (assetClass == ERC1155_ASSET_CLASS) {
            IERC1155(nftContract).safeTransferFrom(
                from,
                receiver,
                tokenId,
                amount,
                ""
            );
        } else {
            revert InvalidAssetClass();
        }
    }

    /// @notice Validates if asset class and token amount match
    function _validateAssetClass(bytes4 assetClass, uint256 amount)
        internal
        pure
    {
        if (assetClass == ERC721_ASSET_CLASS) {
            if (amount != 1) revert InvalidAmount();
        } else if (assetClass == ERC1155_ASSET_CLASS) {
            if (amount <= 0) revert InvalidAmount();
        } else {
            revert InvalidAssetClass();
        }
    }

    /// @notice Checks if auction is currently active
    function _isActiveAuction(Auction memory auction)
        internal
        pure
        returns (bool)
    {
        return auction.startedAt > 0;
    }

    /// @notice Checks if auction has a desired type
    function _isAuctionType(Auction memory auction, AuctionType auctionType)
        internal
        pure
        returns (bool)
    {
        return auction.auctionType == auctionType;
    }

    /// @notice Checks if auction is listed as reserve and has started or ended
    function _requireIdleAuction(bytes32 id) internal view {
        Auction memory auction = idToAuction[id];

        if (auction.auctionType == AuctionType.DUTCH) return;

        if (auction.endingAt >= block.timestamp) revert AuctionInProgress();
        if (auction.endingAt != 0 && auction.endingAt < block.timestamp)
            revert AuctionEnded();
    }

    /// @notice Overloaded function that validates is requested auction valid
    function _requireValidAuctionRequest(
        address paymentErc20TokenAddress,
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        bytes4 assetClass
    ) internal view {
        _requireSupportedPaymentMethod(paymentErc20TokenAddress);

        _requireValidAuctionRequest(nftContract, tokenId, amount, assetClass);
    }

    /// @notice Overloaded function that validates is requested auction valid
    function _requireValidAuctionRequest(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        bytes4 assetClass
    ) internal view {
        _requireCorrectNftInterface(assetClass, nftContract);

        _requireTokenOwnership(
            assetClass,
            nftContract,
            tokenId,
            amount,
            msg.sender
        );

        _validateAssetClass(assetClass, amount);
    }

    /// @notice Validates bid request for an auction
    function _requireValidBidRequest(
        Auction memory auction,
        uint256 tokenAmount
    ) internal view {
        if (!_isActiveAuction(auction)) revert InvalidAuction();
        if (auction.seller == msg.sender) revert Unauthorized();
        if (auction.amount < tokenAmount) revert InvalidAmount();
    }

    /// @notice Validates is desired auction type
    function _requireAuctionType(
        Auction memory auction,
        AuctionType auctionType
    ) internal pure {
        if (!_isAuctionType(auction, auctionType)) revert InvalidAuction();
    }

    function _createAuctionId(
        address nftContract,
        uint256 tokenId,
        address seller
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(nftContract, "-", tokenId, "-", seller));
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}