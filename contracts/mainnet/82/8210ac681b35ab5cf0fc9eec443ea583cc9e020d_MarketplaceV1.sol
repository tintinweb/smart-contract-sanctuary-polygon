// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.11;

import "./CardNFTV1.sol";
import "./ICollection.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title EFT Marketplace
 *
 * @notice marketplace. Includes seller and buyer market
 */
contract MarketplaceV1 is Initializable, ERC721Holder, OwnableUpgradeable {
    // Makes address.isContract() available
    using Address for address;
    using Address for address payable;

    /**
     * @notice Represents a sell order in the marketplace
     *
     * Each sell order has an owner, the creator of the order
     * which cannot be changed and an array of card asset IDs
     * to be sold
     *
     * If more than 1 cards are to be sold, the owner must also include
     * a name for the bundle of cards. If one card is to be sold, the name
     * property remains an empty string
     *
     * Sell orders lso include an ask price the owner wants to sell his
     * cards for
     * Users can either fulfil this order at ask price or make a
     * counteroffer at a lower price
     *
     * Only the highest offer is stored on the blockchain and
     * at each time, a user can only place an offer that is
     * higher than the current one
     *
     * When an new highest offer is placed, the old one is refunded
     * to the previous offeror
     *
     * The offerors can withdraw their offer after their guarantee period
     * and their offer is automatically returned to them if someone fulfils
     * the order at ask price
     */
    struct SellOrder {
        address owner;
        uint256[] assetIds;
        uint8 collectionId;
        string name;
        uint256 ask;
        uint256 marketPlaceFee;
        uint256 sellerFee;
        uint256 offerMinPrice;
        uint256 highestOffer;
        uint256 highestOfferBuyerFee;
        address highestOfferor;
        uint256 highestOfferGuarantee;
        uint256 highestOfferExpiration;
        uint discount;
    }

    /**
     * @notice Represents a buy order in the marketplace
     *
     * Each buy order has an owner, the creator of the order
     * which cannot be changed and a card type property signifying
     * which type of card the owner wants to buy
     *
     * It also has an bid price the owner wants to pay for the card
     * Users can either fulfill this order at bid price or make a
     * counteroffer at a higher price
     *
     * Only the lowest offer is stored on the blockchain and
     * at each time, a user can only place an offer that is
     * lower than the current one
     *
     * When an new lowest offer is placed, the old one is refunded
     * to the previous offeror
     *
     * The offerors can withdraw their offer after their guarantee period
     * and their offer is automatically returned to them if someone fulfils
     * the order at bid price
     */
    struct BuyOrder {
        address owner;
        uint8 cardCollection;
        uint8 cardType;
        uint256 bid;
        uint256 buyerFee;
        uint256 lowestOffer;
        uint256 lowestOfferSellerFee;
        address lowestOfferor;
        uint256 lowestOfferCardId;
        uint256 lowestOfferGuarantee;
    }

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /**
     * @notice Stores sell orders by ID
     */
    mapping(bytes32 => SellOrder) public sellOrders;

    /**
     * @notice Stores buy orders by ID
     */
    mapping(bytes32 => BuyOrder) public buyOrders;

    /**
     * @notice Card NFT used in the game
     */
    CardNFTV1 public card;

    /**
     * @notice DAO address where fees are paid
     */
    address payable public daoAddress;

    /**
     * @notice min amount of hours before which offer can not be withdrawn
     */
    uint8 public minOfferGuaranteeHours;

    //coupon signer address
    address public couponSigner;

    /**
     * @notice Initiates the marketplace
     *
     * @param _card address of card contract
     * @param _daoAddress address of DAO contract
     * @param _minOfferGuaranteeHours minimum offer guarantee
     * @param _couponSigner address of coupon signer
     */
    function initialize(
        address _card,
        address payable _daoAddress,
        uint8 _minOfferGuaranteeHours,
        address _couponSigner
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        card = CardNFTV1(_card);
        daoAddress = _daoAddress;
        minOfferGuaranteeHours = _minOfferGuaranteeHours;
        couponSigner = _couponSigner;
    }


    /**
     * @dev Fired in setMinOfferGuaranteeHours()
     *
     * @param by address that changed the reserve fee
     * @param oldMinOfferGuaranteeHours old value min hours for offers
     * @param newMinOfferGuaranteeHours new value min hours for offers
     */
    event MinOfferGuaranteeHoursChanged(
        address by,
        uint8 oldMinOfferGuaranteeHours,
        uint8 newMinOfferGuaranteeHours
    );

    /**
     * @dev Fired in createSellOrder()
     *
     * @param owner sell order creator
     * @param orderId ID of sell order
     * @param name name of sell order if bundle. empty if single card
     * @param assetIds IDs of cards to be sold
     * @param ask price owner wants to buy card at
     */
    event SellOrderCreated(
        address indexed owner,
        bytes32 indexed orderId,
        string name,
        uint256[] assetIds,
        uint256 ask,
        uint256 offerMinPrice
    );

    /**
     * @dev Fired in placeOfferOnSellOrder()
     *
     * @param owner sell order creator
     * @param orderId ID of sell order
     * @param offer value of new highest offer
     * @param offeror address making the offer
     * @param offerGuarantee offeror cannot withdraw until this time is passed
     */
    event SellOrderOffer(
        address indexed owner,
        bytes32 orderId,
        uint256 offer,
        address indexed offeror,
        uint256 offerGuarantee,
        uint256 offerExpiration
    );

    /**
     * @dev Fired in acceptSellOrderHighestOffer(), fulfillSellOrder()
     *
     * @param owner sell order creator
     * @param orderId ID of sell order
     * @param name name of the order if bundle. else empty string
     * @param assetIds IDs of cards that were sold
     * @param buyer address buying the sell order
     * @param price price the sell order was fulfilled at
     * @param ask price owner wanted to sell card(s) at
     */
    event SellOrderFulfilled(
        address indexed owner,
        bytes32 orderId,
        string name,
        uint256[] assetIds,
        address indexed buyer,
        uint256 price,
        uint256 ask
    );

    /**
     * @dev Fired in cancelSellOrder()
     *
     * @param owner sell order creator
     * @param orderId ID of sell order
     * @param name name of the order if bundle. else empty string
     * @param assetIds IDs of cards that were sold
     */
    event SellOrderCancelled(
        address indexed owner,
        bytes32 orderId,
        string name,
        uint256[] assetIds
    );

    /**
     * @dev Fired in createBuyOrder()
     *
     * @param owner buy order creator
     * @param orderId ID of buy order
     * @param cardCollection collection of card owner wants to buy
     * @param cardType type of card owner wants to buy
     * @param bid price owner wants to buy card at
     */
    event BuyOrderCreated(
        address indexed owner,
        bytes32 orderId,
        uint8 cardCollection,
        uint8 cardType,
        uint256 bid
    );

    /**
     * @dev Fired in placeOfferOnBuyOrder()
     *
     * @param owner buy order creator
     * @param orderId ID of buy order
     * @param offer value of new lowest offer
     * @param offeror address making the offer
     * @param offerCardId card ID in the offer
     * @param offerGuarantee offeror cannot withdraw until this time is passed
     */
    event BuyOrderOffer(
        address indexed owner,
        bytes32 orderId,
        uint256 offer,
        address indexed offeror,
        uint256 indexed offerCardId,
        uint256 offerGuarantee
    );

    /**
     * @dev Fired in acceptBuyOrderLowestOffer(), fulfillBuyOrder()
     *
     * @param owner buy order creator
     * @param orderId ID of buy order
     * @param assetId ID of card that were sold
     * @param cardCollection collection of card owner wanted to buy
     * @param cardType type of card owner wanted to buy
     * @param seller address selling the buy order
     * @param price price the buy order was fulfilled at
     * @param bid price owner wanted to buy card at
     */
    event BuyOrderFulfilled(
        address indexed owner,
        bytes32 orderId,
        uint256 assetId,
        uint8 cardCollection,
        uint8 cardType,
        address indexed seller,
        uint256 price,
        uint256 bid
    );

    /**
     * @dev Fired in cancelBuyOrder()
     *
     * @param owner buy order creator
     * @param orderId ID of buy order
     */
    event BuyOrderCancelled(address indexed owner, bytes32 orderId);

    /**
     * @dev Fired in cancelOfferOnSellOrder()
     *
     * @param orderId ID of sell order
     */
    event SellOrderOfferCancelled(bytes32 orderId);

    /**
     * @dev Fired in cancelOfferOnBuyOrder()
     *
     * @param orderId ID of sell order
     */
    event BuyOrderOfferCancelled(bytes32 orderId);

    /**
     * @dev Checks whether a provided card type is
     *         valid (in range [1, 53])
     *
     * @param _cardType the card type to check
     */
    modifier validCardType(uint8 _cardType) {
        require(_cardType >= 1, "card type must be in range [1, 53]");
        require(_cardType <= 53, "card type must be in range [1, 53]");
        _;
    }

    /**
     * @dev Checks whether message sender is not a contract
     */
    modifier onlyIfSenderNotContract() {
        require(msg.sender == tx.origin, "contract caller not allowed");
        _;
    }

    /**
     * @dev Checks whether sell order exists
     *
     * @param _orderId order ID to check existence
     */
    modifier sellOrderExists(bytes32 _orderId) {
        require(
            sellOrders[_orderId].owner != address(0),
            "sell order does not exist"
        );
        _;
    }

    /**
     * @dev Checks whether sender owns sell order
     *
     * @param _orderId order ID to check ownership of
     */
    modifier senderOwnsSellOrder(bytes32 _orderId) {
        require(sellOrders[_orderId].owner == msg.sender, "not order owner");
        _;
    }

    /**
     * @dev Checks whether buy order exists
     *
     * @param _orderId order ID to check existence
     */
    modifier buyOrderExists(bytes32 _orderId) {
        require(
            buyOrders[_orderId].owner != address(0),
            "buy order does not exist"
        );
        _;
    }

    /**
     * @dev Checks whether sender owns buy order
     *
     * @param _orderId order ID to check ownership of
     */
    modifier senderOwnsBuyOrder(bytes32 _orderId) {
        require(buyOrders[_orderId].owner == msg.sender, "not order owner");
        _;
    }

    /**
     * @notice Changes min offer guarantee hours config
     *
     * @param _hours number of hours
     */
    function setMinOfferGuaranteeHours(uint8 _hours) external onlyOwner {
        require(_hours >= 24, "can not be less that 24 hours");
        emit MinOfferGuaranteeHoursChanged(
            msg.sender,
            minOfferGuaranteeHours,
            _hours
        );
        minOfferGuaranteeHours = _hours;
    }

    /**
     * @dev Pays out fees to reserve and DAO from
     *      amount and returns the amount without
     *      the fees
     *
     * @param _feeValue amount to deduct fees from
     * @param _collectionAddress the address of collection to get marketplace fee
     * @param _collectionPartnerDaoAddress the address of collection partner to send fees
     *
     */
    function _transferFees(
        uint256 _feeValue,
        address _collectionAddress,
        address _collectionPartnerDaoAddress
    ) internal {
        uint32 partnerMarketplaceFeePercent = ICollection(_collectionAddress)
            .partnerMarketplaceFeePercent();

        if (partnerMarketplaceFeePercent > 0) {
            //Send % to partner Dao
            uint256 partnerMarketplaceFeePercentValue = (_feeValue *
                partnerMarketplaceFeePercent) / 100_000;
            (bool success, ) = _collectionPartnerDaoAddress.call{
                value: partnerMarketplaceFeePercentValue
            }("");
            require(success, "Send fees to partner failed.");
            _feeValue = _feeValue - partnerMarketplaceFeePercentValue;
        }

        (bool success, ) = daoAddress.call{value: _feeValue}("");
        require(success, "Send fees to DAO failed.");
    }

    /**
     * @dev Caclculates seller fee based on discount
     *
     * @param _amount amount to deduct fees from
     * @param _collectionId the address of collection to get marketplace fee
     * @param _coupon coupon for discount
     * @param _discount discount value
     *
     * @return marketplaceFee percentage of fee
     * @return marketplaceFeeValue value of fee
     * @return discount discount
     */
    function _getSellerFeeWithDiscount(
        uint256 _amount,
        uint8 _collectionId,
        Coupon memory _coupon,
        uint8 _discount
    )
        internal
        view
        returns (
            uint32 marketplaceFee,
            uint256 marketplaceFeeValue,
            uint8 discount
        )
    {
        require(_discount <= 100, "invalid discount");

        //check discount on fees
        if (_discount > 0) {
            bytes32 digest = keccak256(
                abi.encodePacked(_collectionId, _discount, msg.sender)
            );
            if (!_isVerifiedCoupon(digest, _coupon)) {
                _discount = 0;
            }
        }
        discount = _discount;

        (address collectionAddress,,,,,,) = card.cardCollectionInfo(
            _collectionId
        );

        marketplaceFee = ICollection(collectionAddress)
            .marketplaceSellerFeePercent();
        marketplaceFeeValue = (_amount * marketplaceFee) / 100_000;

        if (discount > 0) {
            marketplaceFeeValue =
                marketplaceFeeValue -
                ((marketplaceFeeValue * discount) / 100);
        }
    }

    /**
     * @dev Caclculates buyer fee based on discount
     *
     * @param _amount amount to deduct fees from
     * @param _collectionId the address of collection to get marketplace fee
     * @param _coupon coupon for discount
     * @param _discount discount value
     *
     * @return marketplaceFee percentage of fee
     * @return marketplaceFeeValue value of fee
     * @return discount discount
     */
    function _getBuyerFeeWithDiscount(
        uint256 _amount,
        uint8 _collectionId,
        Coupon memory _coupon,
        uint8 _discount
    )
        internal
        view
        returns (
            uint32 marketplaceFee,
            uint256 marketplaceFeeValue,
            uint8 discount
        )
    {
        require(_discount <= 100, "invalid discount");

        //check discount on fees
        if (_discount > 0) {
            bytes32 digest = keccak256(
                abi.encodePacked(_collectionId, _discount, msg.sender)
            );
            if (!_isVerifiedCoupon(digest, _coupon)) {
                _discount = 0;
            }
        }
        discount = _discount;

        (address collectionAddress,,,,,,) = card.cardCollectionInfo(
            _collectionId
        );

        marketplaceFee = ICollection(collectionAddress)
            .marketplaceBuyerFeePercent();
        marketplaceFeeValue = (_amount * marketplaceFee) / 100_000;

        if (discount > 0) {
            marketplaceFeeValue = marketplaceFeeValue - ((marketplaceFeeValue * discount) / 100);
        }

        return (marketplaceFee, marketplaceFeeValue, discount);
    }

    /**
     * @dev check that the coupon sent was signed by the admin signer
     *
     * @param _digest digest
     * @param _coupon coupon for discount
     *
     * @return bool is verified
     */
    function _isVerifiedCoupon(
        bytes32 _digest,
        Coupon memory _coupon
    ) internal view returns (bool) {
        address signer = ecrecover(_digest, _coupon.v, _coupon.r, _coupon.s);
        require(signer != address(0), "invalid signature");
        return signer == couponSigner;
    }
   

    /**
     * @notice Creates a sell order
     *
     * @param _assetIds array of card IDs to sell
     * @param _ask price of cards. if 0 then open to offers
     * @param _name name of cards if bundle. else empty
     * @param _offerMinPrice minimum set offer price
     * @param _collectionId collection id of card sold
     * @param _coupon discount coupon of user
     * @param _discount discount percent
     *
     * @return orderId
     */
    function createSellOrder(
        uint256[] calldata _assetIds,
        uint256 _ask,
        uint256 _offerMinPrice,
        string memory _name,
        uint8 _collectionId,
        Coupon memory _coupon,
        uint8 _discount
    ) external onlyIfSenderNotContract returns (bytes32 orderId) {
        require(_assetIds.length > 0, "provide at least one card ID");

        if (_assetIds.length == 1) {
            require(
                bytes(_name).length == 0,
                "cannot provide name with one card"
            );
        } else {
            require(
                bytes(_name).length > 0,
                "please provide a name for the bundle sell order"
            );
        }

        // Transfer each sent card to the Marketplace contract
        for (uint256 i = 0; i < _assetIds.length; ) {
            // Will revert if user does not own card or if has not approved
            // Marketplace contract for trading
            card.safeTransferFrom(msg.sender, address(this), _assetIds[i]);
            unchecked {
                ++i;
            }
        }

        // Generate pseudorandom order ID
        orderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                _assetIds,
                _ask,
                _name
            )
        );

        (
            uint32 marketPlaceFee,
            uint256 marketplaceFeeValue,
            uint8 discount
        ) = _getSellerFeeWithDiscount(_ask, _collectionId, _coupon, _discount);

        // Insert order in mapping
        sellOrders[orderId] = SellOrder({
            owner: msg.sender,
            assetIds: _assetIds,
            collectionId: _collectionId,
            name: _name,
            ask: _ask,
            marketPlaceFee: marketPlaceFee,
            sellerFee: marketplaceFeeValue,
            offerMinPrice: _offerMinPrice,
            highestOffer: 0,
            highestOfferBuyerFee: 0,
            highestOfferor: address(0),
            highestOfferGuarantee: 0,
            highestOfferExpiration: 0,
            discount: discount
        });

        // Emit event
        emit SellOrderCreated(
            msg.sender,
            orderId,
            _name,
            _assetIds,
            _ask,
            _offerMinPrice
        );
    }

    /**
     * @notice Cancel sell order
     *
     * @dev Restricted to sell order owner
     *
     * @param _orderId order which the owner wants to cancel
     */
    function cancelSellOrder(
        bytes32 _orderId
    ) external sellOrderExists(_orderId) senderOwnsSellOrder(_orderId) {
        SellOrder memory sellOrder = sellOrders[_orderId];
        delete sellOrders[_orderId];

        if (
            sellOrder.highestOfferor != address(0) &&
            !sellOrder.highestOfferor.isContract()
        ) {
            // Refund offeror
            (bool success, ) = sellOrder.highestOfferor.call{
                value: (sellOrder.highestOffer + sellOrder.highestOfferBuyerFee)
            }("");
            require(success, "cancelSellOrder failed.");
        }

        uint256 assetsLen = sellOrder.assetIds.length;
        for (uint256 i = 0; i < assetsLen; ) {
            card.safeTransferFrom(
                address(this),
                msg.sender,
                sellOrder.assetIds[i]
            );
            unchecked {
                ++i;
            }
        }

        // Emit event
        emit SellOrderCancelled(
            sellOrder.owner,
            _orderId,
            sellOrder.name,
            sellOrder.assetIds
        );
    }

    /**
     * @notice Places an offer on a sell order
     *         The offer must be higher than the previous
     *         one and guaranteed for at least minOfferGuaranteeHours hours
     *         EFT is placed in escrow
     *
     * @param _orderId order ID where the offer is to be placed
     * @param _offerGuarantee offer guaranteed up to this point.
     *                        must be at least minOfferGuaranteeHours hours in the future
     * @param _offerExpiration expiration date of the offer
     * @param _offerValue value of the offer
     * @param _coupon discount coupon of the user
     * @param _discount discount value
     */
    function placeOfferOnSellOrder(
        bytes32 _orderId,
        uint256 _offerGuarantee,
        uint256 _offerExpiration,
        uint256 _offerValue,
        Coupon memory _coupon,
        uint8 _discount
    ) external payable onlyIfSenderNotContract sellOrderExists(_orderId) {
        // Get sell order
        SellOrder storage sellOrder = sellOrders[_orderId];

        require(msg.sender != sellOrder.owner, "can not be sent by the owner");

        require(_offerValue > 0, "offer value must grater than 0");
        

        (,uint256 marketplaceFeeValue,) = _getBuyerFeeWithDiscount(
            _offerValue,
            sellOrder.collectionId,
            _coupon,
            _discount
        );

        require(
            msg.value == _offerValue + marketplaceFeeValue,
            "incorrect amount provided"
        );

        // If the sell order is not open to offers without an ask price
        if (sellOrder.ask > 0) {
            // Ensure the offer value is less than the order ask
            require(
                _offerValue < sellOrder.ask,
                "offer value must be less than order ask"
            );
        }
        if (sellOrder.ask == 0 && sellOrder.offerMinPrice > 0) {
            require(
                _offerValue >= sellOrder.offerMinPrice,
                "offer value must be higher than offer min price"
            );
        }

        // Ensure the value of the new offer is higher than the current
        require(
            _offerValue > sellOrder.highestOffer,
            "offer value must be higher than current"
        );

        // Ensure the offer guarantee period for which the offeror cannot withdraw
        // is at least minOfferGuaranteeHours hours in the future
        require(
            _offerGuarantee >=
                block.timestamp + uint256(minOfferGuaranteeHours) * 60 * 60,
            "you need to increase offer guarantee"
        );

        // If a previous offer exists and the previous offeror is not a contract
        // (we need to double check here because he might became a contract
        // since he submitted his offer)
        if (
            sellOrder.highestOfferor != address(0) &&
            !sellOrder.highestOfferor.isContract()
        ) {
            // Refund previous offeror
            (bool success, ) = sellOrder.highestOfferor.call{
                value: sellOrder.highestOffer + sellOrder.highestOfferBuyerFee
            }("");
            require(success, "Refund previous offeror failed.");
        }

        // Update highest offer and offeror
        sellOrder.highestOffer = _offerValue;
        sellOrder.highestOfferBuyerFee = marketplaceFeeValue;
        sellOrder.highestOfferor = msg.sender;
        sellOrder.highestOfferGuarantee = _offerGuarantee;
        sellOrder.highestOfferExpiration = _offerExpiration;

        // Emit event
        emit SellOrderOffer(
            sellOrder.owner,
            _orderId,
            _offerValue,
            msg.sender,
            _offerGuarantee,
            _offerExpiration
        );
    }

    /**
     * @notice Cancelles an offer on a sell order
     *
     * @param _orderId order ID where the offer is cancelled
     */
    function cancelOfferOnSellOrder(
        bytes32 _orderId
    ) external onlyIfSenderNotContract sellOrderExists(_orderId) {
        SellOrder storage sellOrder = sellOrders[_orderId];

        require(sellOrder.highestOfferor == msg.sender, "forbidden");
        require(
            sellOrder.highestOfferGuarantee <= block.timestamp,
            "offer guarantee is not reached yet"
        );

        if (
            !sellOrder.highestOfferor.isContract() && sellOrder.highestOffer > 0
        ) {
            // Refund offeror
            (bool success, ) = sellOrder.highestOfferor.call{
                value: (sellOrder.highestOffer + sellOrder.highestOfferBuyerFee)
            }("");
            require(success, "Refund offeror failed.");
        }

        sellOrder.highestOffer = 0;
        sellOrder.highestOfferor = address(0);
        sellOrder.highestOfferBuyerFee = 0;
        sellOrder.highestOfferGuarantee = 0;

        emit SellOrderOfferCancelled(_orderId);
    }

    /**
     * @notice Accepts higher order by sending the cards
     *         to the buyer and receiving the EFT in escrow
     *
     * @dev Restricted to sell order owner
     *
     * @param _orderId order for which the owner wants to accept
     *                 the highest offer for
     */
    function acceptSellOrderHighestOffer(
        bytes32 _orderId
    ) external sellOrderExists(_orderId) senderOwnsSellOrder(_orderId) {
        // Copy sell order in memory
        SellOrder memory sellOrder = sellOrders[_orderId];

        // Delete the sell order early to prevent reentrancy
        // attacks
        // We can use the copy of it in memory to continue
        // with the operation
        // If any errors occur later in the execution of this
        // function, the whole transaction is reverted including
        // this line so in no case will the order be deleted
        // without the exchange happening
        delete sellOrders[_orderId];

        // Ensure the sell order has a current offer
        require(sellOrder.highestOfferor != address(0), "no offers");

        //Check if highestOffer is not expired
        require(
            sellOrder.highestOfferExpiration > block.timestamp,
            "offer has been expired"
        );

        address collectionAddress;
        address payable partnerDaoAddress;

        // Transfer all the cards in escrow to the highest offeror
        uint256 assetsLen = sellOrder.assetIds.length;
        for (uint256 i = 0; i < assetsLen; ) {
            if (i == 0) {
                // do this for first card as all cards should be from the same collection
                (, uint8 cardCollection, , ) = card.cardInfo(
                    sellOrder.assetIds[i]
                );
                (collectionAddress,,partnerDaoAddress,,,,) = card
                    .cardCollectionInfo(cardCollection);
            }
            card.safeTransferFrom(
                address(this),
                sellOrder.highestOfferor,
                sellOrder.assetIds[i]
            );
            unchecked {
                ++i;
            }
        }

        // If sell order owner is not a contract (we need to double check
        // here because he might became a contract since he created his
        // offer)
        if (sellOrder.highestOffer > 0 && !sellOrder.owner.isContract()) {
            // Transfer EFT amount without fees to sell order owner
            // (fees are paid to DAO)
            uint256 marketplaceFeeValue = (sellOrder.highestOffer *
                sellOrder.marketPlaceFee) / 100_000;
            if (sellOrder.discount > 0) {
                marketplaceFeeValue =
                    marketplaceFeeValue -
                    ((marketplaceFeeValue * sellOrder.discount) / 100);
            }

            (bool success, ) = sellOrder.owner.call{
                value: (sellOrder.highestOffer - marketplaceFeeValue)
            }("");
            require(success, "Transfer to sell order owner failed.");
            uint256 totalFee = marketplaceFeeValue +
                sellOrder.highestOfferBuyerFee;
            _transferFees(totalFee, collectionAddress, partnerDaoAddress);
        }

        // Emit event
        emit SellOrderFulfilled(
            sellOrder.owner,
            _orderId,
            sellOrder.name,
            sellOrder.assetIds,
            sellOrder.highestOfferor,
            sellOrder.highestOffer,
            sellOrder.ask
        );

        sellOrder.highestOffer = 0;
        sellOrder.highestOfferor = address(0);
        sellOrder.highestOfferGuarantee = 0;
    }

    /**
     * @notice Executes sell order by providing EFT
     *         and receiving escrowed cards
     *
     * @dev Cannot be called when order ask is 0 since
     *      in that case it is open to offers
     *
     * @param _orderId Id of the irder
     * @param _coupon discount coupon of the user
     * @param _discount discount value
     */
    function fulfillSellOrder(  
        bytes32 _orderId,
        Coupon memory _coupon,
        uint8 _discount
    ) external payable onlyIfSenderNotContract sellOrderExists(_orderId) {
        // Copy sell order in memory
        SellOrder memory sellOrder = sellOrders[_orderId];

        // Delete the sell order early to prevent reentrancy
        // attacks
        // We can use the copy of it in memory to continue
        // with the operation
        // If any errors occur later in the execution of this
        // function, the whole transaction is reverted including
        // this line so in no case will the order be deleted
        // without the exchange happening
        delete sellOrders[_orderId];

        // Require owner set an ask price (card is open to offers
        // if he did not and in that case it cannot be fulfilled)
        require(sellOrder.ask > 0, "cannot fulfill order that's open to offer");

        (,uint256 marketplaceBuyerFeeValue,) = _getBuyerFeeWithDiscount(
            sellOrder.ask,
            sellOrder.collectionId,
            _coupon,
            _discount
        );
        // Ensure ETH sent is equal to sell order ask value with fee
        require(
            sellOrder.ask + marketplaceBuyerFeeValue == msg.value,
            "incorrect amount provided"
        );

        address collectionAddress;
        address payable partnerDaoAddress;

        uint256 assetsLen = sellOrder.assetIds.length;
        // Transfer all the cards in escrow to the highest offeror
        for (uint256 i = 0; i < assetsLen; ) {
            if (i == 0) {
                // do this for first card as all cards should be from the same collection
                (,uint8 cardCollection,,) = card.cardInfo(
                    sellOrder.assetIds[i]
                );
                 (collectionAddress,,partnerDaoAddress,,,,) = card
                    .cardCollectionInfo(cardCollection);
            }

            card.safeTransferFrom(
                address(this),
                msg.sender,
                sellOrder.assetIds[i]
            );
            unchecked {
                ++i;
            }
        }

        // If sell order owner is not a contract (we need to double check
        // here because he might became a contract since he created his
        // offer)
        if (!sellOrder.owner.isContract()) {
            (bool success, ) = sellOrder.owner.call{
                value: (sellOrder.ask - sellOrder.sellerFee)
            }("");
            require(success, "Transfer to sell order owner failed.");

            // (fees are paid to DAO and Partnern)
            _transferFees(
                sellOrder.sellerFee + marketplaceBuyerFeeValue,
                collectionAddress,
                partnerDaoAddress
            );
        }

        // If a previous offer exists and the previous offeror is not a contract
        // (we need to double check here because he might became a contract
        // since he submitted his offer)
        if (
            sellOrder.highestOfferor != address(0) &&
            !sellOrder.highestOfferor.isContract()
        ) {
            // Refund previous offeror
            (bool success, ) = sellOrder.highestOfferor.call{
                value: (sellOrder.highestOffer + sellOrder.highestOfferBuyerFee)
            }("");
            require(success, "Refund previous offeror failed.");
        }

        // Emit event
        emit SellOrderFulfilled(
            sellOrder.owner,
            _orderId,
            sellOrder.name,
            sellOrder.assetIds,
            msg.sender,
            sellOrder.ask,
            sellOrder.ask
        );
    }

    /**
     * @notice Creates a buy order for a card
     *
     * @dev The bid price is derived from the message value
     *
     * @param _cardType type of card owner looks to buy
     * @param _cardCollection collection of card owner looks tu buy
     * @param _bid value of offer
     * @param _coupon discount coupon of the user
     * @param _discount discount value
     *
     * @return orderId
     */
    function createBuyOrder(
        uint8 _cardType,
        uint8 _cardCollection,
        uint256 _bid,
        Coupon memory _coupon,
        uint8 _discount
    ) external payable validCardType(_cardType) returns (bytes32 orderId) {
        // Generate pseudorandom order ID
        orderId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, _cardType, _bid)
        );

        (, uint256 marketplaceFeeValue, ) = _getBuyerFeeWithDiscount(
            _bid,
            _cardCollection,
            _coupon,
            _discount
        );

        require(
            msg.value == _bid + marketplaceFeeValue,
            "incorrect amount provided"
        );

        // Store order in mapping
        buyOrders[orderId] = BuyOrder({
            owner: msg.sender,
            cardCollection: _cardCollection,
            cardType: _cardType,
            bid: _bid,
            buyerFee: marketplaceFeeValue,
            lowestOffer: 0,
            lowestOfferSellerFee: 0,
            lowestOfferor: address(0),
            lowestOfferGuarantee: 0,
            lowestOfferCardId: 0
        });

        // Emit event
        emit BuyOrderCreated(
            msg.sender,
            orderId,
            _cardCollection,
            _cardType,
            _bid
        );
    }

    /**
     * @notice Cancel buy order
     *
     * @dev Restricted to buy order owner
     *
     * @param _orderId order which the owner wants to cancel
     */
    function cancelBuyOrder(
        bytes32 _orderId
    ) external buyOrderExists(_orderId) senderOwnsBuyOrder(_orderId) {
        BuyOrder memory buyOrder = buyOrders[_orderId];
        delete buyOrders[_orderId];

        if (buyOrder.lowestOfferor != address(0)) {
            card.safeTransferFrom(
                address(this),
                buyOrder.lowestOfferor,
                buyOrder.lowestOfferCardId
            );
        }

        //Refund Buy order
        (bool success, ) = buyOrder.owner.call{
            value: (buyOrder.bid + buyOrder.buyerFee)
        }("");
        require(success, "Refund previous offeror failed.");

        emit BuyOrderCancelled(buyOrder.owner, _orderId);
    }

    /**
     * @notice Places an offer on a buy order
     *         The offer must be higher than the previous
     *         one and guaranteed for at least minOfferGuaranteeHours hours
     *         Cards are placed in escrow
     *
     * @param _orderId order ID where the offer is to be placed
     * @param _cardId ID of card to be sent for the offer
     * @param _offer price of offered card
     * @param _offerGuarantee offer guaranteed up to this point.
     *                        must be at least minOfferGuaranteeHours hours in the future
     * @param _coupon discount coupon of the user
     * @param _discount discount value
     */
    function placeOfferOnBuyOrder(
        bytes32 _orderId,
        uint256 _cardId,
        uint256 _offer,
        uint256 _offerGuarantee,
        Coupon memory _coupon,
        uint8 _discount
    ) external {
        // Get sell order
        BuyOrder storage buyOrder = buyOrders[_orderId];

        require(msg.sender != buyOrder.owner, "can not be sent by the owner");

        (uint8 cardType, uint8 cardCollection, , ) = card.cardInfo(_cardId);

        (uint256 marketplaceFeeValue, , ) = _getSellerFeeWithDiscount(
            _offer,
            cardCollection,
            _coupon,
            _discount
        );

        // If the buy order is not open to offers without a bid price
        if (buyOrder.bid > 0) {
            // Ensure the offer value is more than the order bid
            require(
                _offer - marketplaceFeeValue > buyOrder.bid,
                "offer value must be more than order bid"
            );
        }

        // Ensure the value of the new offer is lower than the current
        require(
            _offer < buyOrder.lowestOffer,
            "offer value must be lower than current"
        );

        // Ensure the offer guarantee period for which the offeror cannot withdraw
        // is at least minOfferGuaranteeHours hours in the future
        require(
            _offerGuarantee >=
                block.timestamp + uint256(minOfferGuaranteeHours) * 60 * 60,
            "you need to increase offer guarantee"
        );

        // Ensure a card of correct type was sent

        require(cardType == buyOrder.cardType, "invalid card type");

        // Ensure a card of correct collection was sent
        require(
            cardCollection == buyOrder.cardCollection,
            "invalid card collection"
        );

        // Transfer card to Marketplace contract for escrow
        // Will revert if user does not own card or if has not approved
        // Marketplace contract for trading
        card.safeTransferFrom(msg.sender, address(this), _cardId);

        // If a previous offer exists and the previous offeror is not a contract
        // (we need to double check here because he might became a contract
        // since he submitted his offer)
        if (
            buyOrder.lowestOfferor != address(0) &&
            !buyOrder.lowestOfferor.isContract()
        ) {
            // Refund previous offeror
            // Will revert if user does not own card or if has not approved
            // Marketplace contract for trading
            card.safeTransferFrom(
                address(this),
                buyOrder.lowestOfferor,
                buyOrder.lowestOfferCardId
            );
        }

        // Update lowest offer, offeror and card ID
        buyOrder.lowestOffer = _offer;
        buyOrder.lowestOfferSellerFee = marketplaceFeeValue;
        buyOrder.lowestOfferor = msg.sender;
        buyOrder.lowestOfferCardId = _cardId;
        buyOrder.lowestOfferGuarantee = _offerGuarantee;

        // Emit event
        emit BuyOrderOffer(
            buyOrder.owner,
            _orderId,
            _offer,
            msg.sender,
            _cardId,
            _offerGuarantee
        );
    }

    /**
     * @notice Cancelles an offer on a buy order
     *
     * @param _orderId order ID where the offer is to be cancelled
     */
    function cancelOfferOnBuyOrder(
        bytes32 _orderId
    ) external onlyIfSenderNotContract buyOrderExists(_orderId) {
        BuyOrder storage buyOrder = buyOrders[_orderId];

        require(buyOrder.lowestOfferor == msg.sender, "forbidden");
        require(
            buyOrder.lowestOfferGuarantee <= block.timestamp,
            "offer guarantee is not reached yet"
        );

        card.safeTransferFrom(
            address(this),
            msg.sender,
            buyOrder.lowestOfferCardId
        );

        buyOrder.lowestOffer = 0;
        buyOrder.lowestOfferor = address(0);
        buyOrder.lowestOfferCardId = 0;
        buyOrder.lowestOfferSellerFee = 0;
        buyOrder.lowestOfferGuarantee = 0;

        emit BuyOrderOfferCancelled(_orderId);
    }

    /**
     * @notice Accepts lowest offer by sending the card
     *         to the owner and receiving the EFT in escrow
     *
     * @dev Restricted to buy order owner
     *
     * @param _orderId order for which the owner wants to accept
     *                 the lowest offer for
     */
    function acceptBuyOrderLowestOffer(
        bytes32 _orderId
    ) external buyOrderExists(_orderId) senderOwnsBuyOrder(_orderId) {
        // Copy buy order in memory
        BuyOrder memory buyOrder = buyOrders[_orderId];

        // Delete the buy order early to prevent reentrancy
        // attacks
        // We can use the copy of it in memory to continue
        // with the operation
        // If any errors occur later in the execution of this
        // function, the whole transaction is reverted including
        // this line so in no case will the order be deleted
        // without the exchange happening
        delete buyOrders[_orderId];

        // Ensure the sell order has a current offer
        require(buyOrder.lowestOfferor != address(0), "no offers");

        // If sell order offeror is not a contract (we need to double check
        // here because he might became a contract since he made the offer)
        if (!buyOrder.lowestOfferor.isContract()) {
            (, uint8 cardCollection, , ) = card.cardInfo(
                buyOrder.lowestOfferCardId
            );
           (address collectionAddress,,address payable partnerDaoAddress,,,,) = card.cardCollectionInfo(cardCollection);

            // Transfer amount without fees to sell
            // (fees are paid to DAO and Partner)
            (bool success, ) = buyOrder.lowestOfferor.call{
                value: (buyOrder.lowestOffer - buyOrder.lowestOfferSellerFee)
            }("");
            _transferFees(
                buyOrder.lowestOfferSellerFee + buyOrder.buyerFee,
                collectionAddress,
                partnerDaoAddress
            );

            require(success, "Transfer to sell failed.");
        }

        // Transfer card to buy order owner
        // Will revert if user does not own card or if has not approved
        // Marketplace contract for trading
        card.safeTransferFrom(
            address(this),
            buyOrder.owner,
            buyOrder.lowestOfferCardId
        );

        // Emit event
        emit BuyOrderFulfilled(
            buyOrder.owner,
            _orderId,
            buyOrder.lowestOfferCardId,
            buyOrder.cardCollection,
            buyOrder.cardType,
            buyOrder.lowestOfferor,
            buyOrder.lowestOffer,
            buyOrder.bid
        );
    }

    /**
     * @notice Executes buy order by providing the card
     *         and receiving escrowed EFT
     *
     * @dev Cannot be called when order ask is 0 since
     *      in that case it is open to offers
     *
     * @param _orderId order ID to be fulfilled
     * @param _cardId card to send and fulfil order with
     * @param _coupon discount coupon of the user
     * @param _discount discount value
     */
    function fulfillBuyOrder(
        bytes32 _orderId,
        uint256 _cardId,
        Coupon memory _coupon,
        uint8 _discount
    ) external onlyIfSenderNotContract buyOrderExists(_orderId) {
        // Copy buy order in memory
        BuyOrder memory buyOrder = buyOrders[_orderId];

        // Delete the buy order early to prevent reentrancy
        // attacks
        // We can use the copy of it in memory to continue
        // with the operation
        // If any errors occur later in the execution of this
        // function, the whole transaction is reverted including
        // this line so in no case will the order be deleted
        // without the exchange happening
        delete buyOrders[_orderId];

        // Require owner set a bid price (card is open to offers
        // if he did not and in that case it cannot be fulfilled)
        require(buyOrder.bid > 0, "cannot fulfil order that's open to offer");

        // Ensure a card of correct type was sent
        (uint256 cardType, uint8 cardCollection, , ) = card.cardInfo(_cardId);
        require(cardType == buyOrder.cardType, "invalid card type");
        (address collectionAddress,,address payable partnerDaoAddress,,,,) = card.cardCollectionInfo(cardCollection);

        // If buy order owner is not a contract (we need to double check
        // here because he might became a contract since he created his
        // offer)
        if (!buyOrder.owner.isContract()) {
            // Transfer the card to the buy order owner
            // Will revert if user does not own card or if has not approved
            // Marketplace contract for trading
            card.safeTransferFrom(msg.sender, buyOrder.owner, _cardId);
        }

        (, uint256 marketplaceSellerFeeValue, ) = _getSellerFeeWithDiscount(
            buyOrder.bid,
            cardCollection,
            _coupon,
            _discount
        );

        // Transfer amount without fees to seller
        (bool success, ) = msg.sender.call{
            value: (buyOrder.bid - marketplaceSellerFeeValue)
        }("");

        require(success, "Transfer to sell order owner failed.");

        // (fees are paid to DAO )
        _transferFees(
            marketplaceSellerFeeValue + buyOrder.buyerFee,
            collectionAddress,
            partnerDaoAddress
        );

        // If a previous offer exists and the previous offeror is not a contract
        // (we need to double check here because he might became a contract
        // since he submitted his offer)
        if (
            buyOrder.lowestOfferor != address(0) &&
            !buyOrder.lowestOfferor.isContract()
        ) {
            // Refund previous offeror
            (bool success, ) = buyOrder.lowestOfferor.call{
                value: (buyOrder.lowestOffer + buyOrder.lowestOfferSellerFee)
            }("");
            require(success, "Refund previous offeror failed.");
        }

        // Emit event
        emit BuyOrderFulfilled(
            buyOrder.owner,
            _orderId,
            _cardId,
            buyOrder.cardCollection,
            buyOrder.cardType,
            msg.sender,
            buyOrder.bid,
            buyOrder.bid
        );
    }

    /**
     * @notice Updates couponSigner
     *
     * @param _couponSigner new coupon signer address
     */
    function setCouponSigner(address _couponSigner) external onlyOwner {
        require(_couponSigner != address(0), "invalid address");
        couponSigner = _couponSigner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "base64-sol/base64.sol";

/**
 * @title Eternity deck card
 *
 * @dev Represents a card NFT in the game.
 */
contract CardNFTV1 is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    using Address for address;
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    /**
     * @notice AccessControl role that allows to mint tokens
     *
     * @dev Used in mint(), safeMint(), mintBatch(), safeMintBatch()
     */
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice AccessControl role that allows to burn tokens
     *
     * @dev Used in burn(), burnBatch()
     */
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @notice AccessControl role that allows to change the baseURI
     *
     * @dev Used in setBaseURI()
     */
    bytes32 private constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

    /**
     * @notice Stores the amount of cards that were burned in
     *         the duration of the game.
     *
     * @dev Is increased by 1 when a card is burned
     */
    uint256 public totalBurned;

    /**
     * @dev Represents a card
     */
    struct Card {
        uint8 cardType;
        uint8 cardCollection;
        uint256 serialNumber;
        uint256 editionNumber;
    }

    /**
     * @dev Represents a collection
     */

    struct Collection {
        address collectionAddress; // the address of the collection
        uint256 collectionBuyBack;
        address payable partnerDaoAddress;
        uint256 colMinted;
        uint256 colBurned;
        uint128 totalCardValue;
        uint64 totalBuyBacksClaimed;
    }

    /**
     * @notice Stores information about each card
     */
    mapping(uint256 => Card) public cardInfo;

    /**
     * @notice Stores the number of cards minted for each card type
     *
     * @dev Is increased by 1 when a new card of certain type is minted
     *
     * @dev Returns 0 for values not in range [1, 53]
     */
    mapping(uint8 => uint256) public cardPopulation;

    /**
     * @notice Stores the number of cards in existence on each collection
     *         for each card type
     *
     * @dev Is increased by 1 when a new card of certain type in a collection
     *      is minted
     *
     * @dev Returns 0 for values not in range [1, 53]
     */
    mapping(uint8 => mapping(uint8 => uint256)) public cardCollectionPopulation;

    /**
     * @notice Stores the number of card population, burned, minted on each collection
     *
     *
     * @dev Is increased by 1 when a new card in a collection
     *      is minted or burned
     *
     * @dev Returns 0 for values not in range [1, 53]
     */
    mapping(uint8 => Collection) public cardCollectionInfo;

    /**
     * @notice Stores how many cards of a type were minted
     *         and owned by an address
     *
     * @dev Used to efficiently store both numbers into
     *      one 256-bit unsigned integer using packing
     */
    struct AddressCardType {
        uint128 minted;
        uint128 owned;
    }

    /**
     * @notice Stores how many cards of each type were minted
     *         and owned by an address
     */
    mapping(address => mapping(uint8 => AddressCardType))
        public cardTypeByAddress;

    mapping(uint8 => string) public collectionUri;
    /**
     * @dev Fired in mint(), safeMint()
     *
     * @param by address which executed the mint
     * @param to address which received the mint card
     * @param tokenId minted card id
     * @param cardType type of card that was minted in range [1, 53]
     * @param cardCollection collection of the card that was minted
     * @param upgrade if card is minted by upgrade
     */
    event CardMinted(
        address indexed by,
        address indexed to,
        uint160 tokenId,
        uint8 cardType,
        uint8 cardCollection,
        bool upgrade
    );

    /**
     * @dev Fired in burn()
     *
     * @param by address which executed the burn
     * @param from address whose card was burned
     * @param tokenId burned card id
     * @param cardType type of card that was burned in range [1, 53]
     * @param cardCollection collection of the card that was burned
     * @param burnType burn card type: 0 - upgrade or 1 - buyback
     */
    event CardBurned(
        address indexed by,
        address indexed from,
        uint160 tokenId,
        uint8 cardType,
        uint8 cardCollection,
        uint8 burnType
    );

    /**
     * @dev Fired in setBaseURI()
     *
     * @param by an address which executed update
     * @param oldVal old _baseURI value
     * @param newVal new _baseURI value
     */
    event BaseURIChanged(address by, string oldVal, string newVal);

    /**
     * @dev Fired in addCollection()
     *
     * @param collection the id of collection
     * @param collectionAddress the contract address of collection
     * @param collectionPartnerDaoAddress collection partner DAO address
     */
    event CollectionAdded(
        uint8 collection,
        address collectionAddress,
        address collectionPartnerDaoAddress
    );

    /**
     * @notice Instantiates the contract and gives all roles
     *         to contract deployer
     */
    function initialize() public initializer {
        __ERC721_init("Eternity Deck Card", "EDC");
        OwnableUpgradeable.__Ownable_init();
        __ERC721Enumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(URI_MANAGER_ROLE, msg.sender);

        totalBurned = 0;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory name = string(
            abi.encodePacked(
                '"name": "Eternity Deck: Collection ',
                cardInfo[_tokenId].cardCollection.toString(),
                " ",
                "Edition ",
                cardInfo[_tokenId].editionNumber.toString(),
                '",'
            )
        );
        string
            memory description = '"description": "Represents a card in the eternity deck game",';
        string memory imageUrl = string(
            abi.encodePacked(
                '"image_url": "',
                collectionUri[cardInfo[_tokenId].cardCollection],
                cardInfo[_tokenId].cardType.toString(),
                '.png",'
            )
        );

        string memory cardTypeAttribute = string(
            abi.encodePacked(
                "{",
                '"trait_type": "Card Type",',
                '"value":',
                cardInfo[_tokenId].cardType.toString(),
                "},"
            )
        );

        string memory cardCollectionAttribute = string(
            abi.encodePacked(
                "{",
                '"trait_type": "Card Collection",',
                '"value":',
                cardInfo[_tokenId].cardCollection.toString(),
                "},"
            )
        );

        string memory serialNumberAttribute = string(
            abi.encodePacked(
                "{",
                '"trait_type": "Serial Number",',
                '"value":',
                cardInfo[_tokenId].serialNumber.toString(),
                "},"
            )
        );

        string memory editionNumberAttribute = string(
            abi.encodePacked(
                "{",
                '"trait_type": "Edition Number",',
                '"value":',
                cardInfo[_tokenId].editionNumber.toString(),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                name,
                                description,
                                imageUrl,
                                '"attributes": [',
                                cardTypeAttribute,
                                cardCollectionAttribute,
                                serialNumberAttribute,
                                editionNumberAttribute,
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Checks whether a provided card type is
     *         valid (in range [1, 53])
     *
     * @param _cardType the card type to check
     */
    modifier validCardType(uint8 _cardType) {
        require(
            _cardType >= 1 && _cardType <= 53,
            "card type must be in range [1, 53]"
        );
        _;
    }

    string internal theBaseURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return theBaseURI;
    }

    /**
     * @notice Updates base URI used to construct ERC721Metadata.tokenURI for Collection
     *
     * @dev Access restricted by `URI_MANAGER_ROLE` AccessControl role
     * @param _collectionId ID of the Collection
     * @param _newBaseURI new Base URI
     */
    function setBaseURIForCollection(
        uint8 _collectionId,
        string calldata _newBaseURI
    ) external onlyRole(URI_MANAGER_ROLE) {
        // Update base uri of the collection
        collectionUri[_collectionId] = _newBaseURI;
    }

    /**
     * @notice Checks if specified token exists
     *
     * @dev Returns whether the specified token ID has an ownership
     *      information associated with it
     *
     * @param _tokenId ID of the token to query existence for
     * @return whether the token exists (true - exists, false - doesn't exist)
     */
    function exists(uint160 _tokenId) external view returns (bool) {
        // Delegate to internal OpenZeppelin function
        return _exists(_tokenId);
    }

    /**
     * @notice Burns token with token ID specified
     *
     * @dev Access restricted by `BURNER_ROLE` AccessControl role
     *
     * @param _to address that owns token to burn
     * @param _tokenId ID of the token to burn
     * @param _type upgrade or buyback
     */
    function burn(
        address _to,
        uint160 _tokenId,
        uint8 _type
    ) external onlyRole(BURNER_ROLE) {
        // Require _to be the owner of the token to be burned
        require(ownerOf(_tokenId) == _to, "_to does not own token");

        // Get card type and collection
        uint8 _cardType = cardInfo[_tokenId].cardType;
        uint8 _cardCollection = cardInfo[_tokenId].cardCollection;

        // Emit burned event
        emit CardBurned(
            msg.sender,
            _to,
            _tokenId,
            _cardType,
            _cardCollection,
            _type
        );

        // Delegate to internal OpenZeppelin burn function
        // Calls beforeTokenTransfer() which decreases owned
        // card count of _to address for this card type
        _burn(_tokenId);

        // Delete card information
        // Must be reset after call to _burn() as that function
        // calls _beforeTokenTransfer() which uses this information
        delete cardInfo[_tokenId];

        unchecked {
            cardCollectionInfo[_cardCollection].colBurned += 1;
            // Increase amount of cards burned by 1
            totalBurned += 1;
        }
    }

    /**
     * @notice Burns tokens starting with token ID specified
     *
     * @dev Token IDs to be burned: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 1: `n > 0`
     *
     * @dev Access restricted by `BURNER_ROLE` AccessControl role
     *
     * @param _to address that owns token to burn
     * @param _tokenIds IDs of the tokens to burn
     * @param _type Type of action
     */
    function burnBatch(
        address _to,
        uint160[] calldata _tokenIds,
        uint8 _type
    ) external onlyRole(BURNER_ROLE) {

        uint256 tokenIdsLen = _tokenIds.length;
        // Cannot burn 0 tokens
        require(tokenIdsLen != 0, "cannot burn 0 tokens");

        for (uint8 i = 0; i < tokenIdsLen;) {
            uint160 tokenId = _tokenIds[i];

            // Require _to be the owner of the token to be burned
            require(ownerOf(tokenId) == _to, "_to does not own token");

            // Get card type and collection
            uint8 _cardType = cardInfo[tokenId].cardType;
            uint8 _cardCollection = cardInfo[tokenId].cardCollection;

            // Emit burn event
            emit CardBurned(
                msg.sender,
                _to,
                tokenId,
                _cardType,
                _cardCollection,
                _type
            );

            // Delegate to internal OpenZeppelin burn function
            // Calls beforeTokenTransfer() which decreases owned
            // card count of _to address for this card type
            _burn(tokenId);

            // Delete the card
            // Must be reset after call to _burn() as that function
            // calls _beforeTokenTransfer() which uses this information
            delete cardInfo[tokenId];

            unchecked {
                cardCollectionInfo[_cardCollection].colBurned += 1;
                ++i;
            }
        }

        // Increase amount of cards burned
        unchecked {
            totalBurned += tokenIdsLen;
        }
    }

    /**
     * @notice Creates new token with token ID specified
     *         and assigns an ownership `_to` for this token
     *
     * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
     *      Prefer the use of `safeMint` instead of `mint`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     * @param _upgrade if mint done with upgrade
     */

    function mint(
        address _to,
        uint160 _tokenId,
        uint8 _cardType,
        uint8 _cardCollection,
        bool _upgrade
    ) public validCardType(_cardType) onlyRole(MINTER_ROLE) {
        require(
            cardCollectionInfo[_cardCollection].collectionAddress != address(0),
            "collection  doesn't exists"
        );

        // Save the card info
        // Must be saved before call to _mint() as that function
        // calls _beforeTokenTransfer() which uses this information
        cardInfo[_tokenId] = Card({
            cardType: _cardType,
            cardCollection: _cardCollection,
            serialNumber: cardPopulation[_cardType] + 1,
            editionNumber: cardCollectionPopulation[_cardCollection][_cardType] + 1
        });

        // Delegate to internal OpenZeppelin function
        // Calls beforeTokenTransfer() which increases minted
        // and owned card count of _to address for this card type
        _mint(_to, _tokenId);

        // Increase the population of card type
        // and collection-scoped population
        unchecked {
            cardPopulation[_cardType] += 1;
            cardCollectionPopulation[_cardCollection][_cardType] += 1;
            cardCollectionInfo[_cardCollection].colMinted += 1;
        }

        // Emit minted event
        emit CardMinted(
            msg.sender,
            _to,
            _tokenId,
            _cardType,
            _cardCollection,
            _upgrade
        );
    }

    /**
     * @notice Creates new tokens starting with token ID specified
     *         and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 1: `n > 0`
     *
     * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
     *      Prefer the use of `safeMintBatch` instead of `mintBatch`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint tokens to
     * @param _tokenId ID of the first token to mint
     * @param _n how many tokens to mint, sequentially increasing the _tokenId
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     */
    function mintBatch(
        address _to,
        uint160 _tokenId,
        uint128 _n,
        uint8 _cardType,
        uint8 _cardCollection
    ) public onlyRole(MINTER_ROLE) validCardType(_cardType) {
        bool _upgrade = false;

        // Cannot mint 0 tokens
        require(_n > 0, "_n cannot be zero");

        require(
            cardCollectionInfo[_cardCollection].collectionAddress != address(0),
            "collection  doesn't exists"
        );

        for (uint256 i = 0; i < _n;) {
            // Save the card type and collection of the card
            // Must be saved before call to _mint() as that function
            // calls _beforeTokenTransfer() which uses this information
            cardInfo[_tokenId + i] = Card({
                cardType: _cardType,
                cardCollection: _cardCollection,
                serialNumber: cardPopulation[_cardType] + i + 1,
                editionNumber: cardCollectionPopulation[_cardCollection][ _cardType] + i + 1
            });

            // Delegate to internal OpenZeppelin mint function
            // Calls beforeTokenTransfer() which increases minted
            // and owned card count of _to address for this card type
            _mint(_to, _tokenId + i);

            // Emit mint event
            emit CardMinted(
                msg.sender,
                _to,
                _tokenId,
                _cardType,
                _cardCollection,
                _upgrade
            );

            unchecked {
                ++i;
            }
        }

        // Increase the population of card type
        // and collection-scoped population
        // by amount of cards minted
        unchecked {
            cardPopulation[_cardType] += _n;
            cardCollectionPopulation[_cardCollection][_cardType] += _n;
            cardCollectionInfo[_cardCollection].colMinted += _n;
        }
           
    }

    /**
     * @notice Creates new token with token ID specified
     *         and assigns an ownership `_to` for this token
     *
     * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      `onERC721Received` on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     * @param _data additional data with no specified format, sent in call to `_to`
     */
    function safeMint(
        address _to,
        uint160 _tokenId,
        uint8 _cardType,
        uint8 _cardCollection,
        bytes calldata _data
    ) external {
        // Delegate to internal mint function (includes AccessControl role check,
        // card type validation and event emission)
        mint(_to, _tokenId, _cardType, _cardCollection, false);

        // If a contract, check if it can receive ERC721 tokens (safe to send)
        if (_to.isContract()) {
            // Try calling the onERC721Received function on the to address
            try
                IERC721ReceiverUpgradeable(_to).onERC721Received(
                    msg.sender,
                    address(0),
                    _tokenId,
                    _data
                )
            returns (bytes4 retval) {
                require(
                    retval ==
                        IERC721ReceiverUpgradeable.onERC721Received.selector,
                    "invalid onERC721Received response"
                );
                // If onERC721Received function reverts
            } catch (bytes memory reason) {
                // If there is no revert reason, assume function
                // does not exist and revert with appropriate reason
                if (reason.length == 0) {
                    revert("mint to non ERC721Receiver implementer");
                    // If there is a reason, revert with the same reason
                } else {
                    // using assembly to get the reason from memory
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @notice Creates new tokens starting with token ID specified
     *         and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 1: `n > 0`
     *
     * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      `onERC721Received` on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param _n how many tokens to mint, sequentially increasing the _tokenId
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     * @param _data additional data with no specified format, sent in call to `_to`
     */
    function safeMintBatch(
        address _to,
        uint160 _tokenId,
        uint128 _n,
        uint8 _cardType,
        uint8 _cardCollection,
        bytes memory _data
    ) public {
        // Delegate to internal unsafe batch mint function (includes AccessControl role check,
        // card type validation and event emission)
        mintBatch(_to, _tokenId, _n, _cardType, _cardCollection);

        // If a contract, check if it can receive ERC721 tokens (safe to send)
        if (_to.isContract()) {
            // For each token minted
            for (uint256 i = 0; i < _n;) {
                // Try calling the onERC721Received function on the to address
                try
                    IERC721ReceiverUpgradeable(_to).onERC721Received(
                        msg.sender,
                        address(0),
                        _tokenId + i,
                        _data
                    )
                returns (bytes4 retval) {
                    require(
                        retval ==
                            IERC721ReceiverUpgradeable
                                .onERC721Received
                                .selector,
                        "invalid onERC721Received response"
                    );
                    // If onERC721Received function reverts
                } catch (bytes memory reason) {
                    // If there is no revert reason, assume function
                    // does not exist and revert with appropriate reason
                    if (reason.length == 0) {
                        revert("mint to non ERC721Receiver implementer");
                        // If there is a reason, revert with the same reason
                    } else {
                       // using assembly to get the reason from memory
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Creates new tokens starting with token ID specified
     *         and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 1: `n > 0`
     *
     * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      `onERC721Received` on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @dev Access restricted by `MINTER_ROLE` AccessControl role
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param _n how many tokens to mint, sequentially increasing the _tokenId
     * @param _cardType type of card to mint in range [1, 53]
     * @param _cardCollection the collection of the card to mint
     */
    function safeMintBatch(
        address _to,
        uint160 _tokenId,
        uint128 _n,
        uint8 _cardType,
        uint8 _cardCollection
    ) external {
        // Delegate to internal safe batch mint function (includes AccessControl role check
        // and card type validation)
        safeMintBatch(_to, _tokenId, _n, _cardType, _cardCollection, "");
    }

    /**
     * @inheritdoc ERC721EnumerableUpgradeable
     */
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @inheritdoc ERC721EnumerableUpgradeable
     *
     * @dev Adjusts owned count for `_from` and `_to` addresses
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _batchSize
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        // Delegate to inheritance chain
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);

        // Get card type of card being transferred
        uint8 _cardType = cardInfo[_tokenId].cardType;

        // Get card type by address values for to and from
        AddressCardType storage actFrom = cardTypeByAddress[_from][_cardType];
        AddressCardType storage actTo = cardTypeByAddress[_to][_cardType];

        // Check if from address is not zero address
        // (when it is zero address, the token is being minted)
        if (_from != address(0)) {
            // Decrease owned card count of from address
            actFrom.owned--;
        } else {
            // If card is being minted, increase to minted count
            actTo.minted++;
        }

        // Check if to address is not zero address
        // (when it is zero address, the token is being burned)
        if (_to != address(0)) {
            // Increase owned card count of to address
            actTo.owned++;
        }
    }

    /**
     * @notice Gets the total cards minted by card type
     *
     * @dev External function only to be used by the front-end
     */
    function totalCardTypesMinted() external view returns (uint256[] memory) {
        uint256[] memory cardIds = new uint256[](54);

        for (uint8 i = 1; i <= 53;) {
            cardIds[i] = cardPopulation[i];
            unchecked {
                ++i;
            }
        }

        return (cardIds);
    }

    /**
     * @notice Gets the cards of an account
     *
     * @dev External function only to be used by the front-end
     */
    function cardsOfAccount()
        external
        view
        returns (uint256[] memory, Card[] memory)
    {
        uint256 n = balanceOf(msg.sender);

        uint256[] memory cardIds = new uint256[](n);
        Card[] memory cards = new Card[](n);

        for (uint32 i = 0; i < n;) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);

            cardIds[i] = tokenId;
            cards[i] = cardInfo[tokenId];
            unchecked {
                ++i;
            }
        }

        return (cardIds, cards);
    }

    /**
     * @notice Add new collection to cardCollectionInfo mapping
     *
     *
     * Emits a {DaoAddressChanged} event
     * Emits a {CollectionAdded} event
     *
     * @param _collection collection id
     * @param _collectionAddress Collection Smart contract address
     * @param _collectionBuyBack Collection BuyBack value
     * @param _collectionPartnerDaoAddress Partner Dao Address
     */
    function addCollection(
        uint8 _collection,
        address _collectionAddress,
        uint256 _collectionBuyBack,
        address payable _collectionPartnerDaoAddress
    ) external onlyOwner {
        // verify ollection address is set
        require(
            _collectionAddress != address(0),
            "collection address is not set"
        );
        if (cardCollectionInfo[_collection].collectionAddress != address(0)) {
            cardCollectionInfo[_collection]
                .collectionAddress = _collectionAddress;
            cardCollectionInfo[_collection]
                .partnerDaoAddress = _collectionPartnerDaoAddress;
            cardCollectionInfo[_collection]
                .collectionBuyBack = _collectionBuyBack;
            cardCollectionInfo[_collection]
                .totalCardValue = 0;
        } else {
            cardCollectionInfo[_collection] = Collection({
                collectionAddress: _collectionAddress,
                collectionBuyBack: _collectionBuyBack,
                partnerDaoAddress: _collectionPartnerDaoAddress,
                colMinted: 0,
                colBurned: 0,
                totalCardValue: 0,
                totalBuyBacksClaimed: 0
            });
        }

        // emit collection added event
        emit CollectionAdded(
            _collection,
            _collectionAddress,
            _collectionPartnerDaoAddress
        );
    }

    /**
     * @notice Increase the totalBuyBacksClaimed of collection
     *
     * @param _collection collection id
     */
    function increaseCollectionBuyBacks(
        uint8 _collection
    ) external onlyRole(MINTER_ROLE) {
        require(_collection > 0 &&  _collection < 200, "invalid collection [0,200]");
        cardCollectionInfo[_collection].totalBuyBacksClaimed++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
  * @notice Collection interface for getting collection fees data
   * Collection should have public marketplaceSellerFeePercent value
   * Collection should have public marketplaceBuyerFeePercent value
   * Collection should have public partnerMarketplaceFeePercent value
   *
   * EXAMPLE:
   * 
   * uint32 public marketplaceSellerFeePercent = 5_000;
   * 
   * uint32 public marketplaceBuyerFeePercent = 5_000;
   * 
   * uint32 public partnerMarketplaceFeePercent = 10_000;
   *
   */
   
interface ICollection {
    struct Coupon {
      bytes32 r;
      bytes32 s;
      uint8 v;
    }
    function marketplaceSellerFeePercent() external view returns(uint32);
    function marketplaceBuyerFeePercent() external view returns(uint32);
    function partnerMarketplaceFeePercent() external view returns(uint32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}