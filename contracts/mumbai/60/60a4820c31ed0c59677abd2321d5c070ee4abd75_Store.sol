// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import {IStore} from "./interfaces/IStore.sol";
import {IStoreDeployer} from "./interfaces/IStoreDeployer.sol";
import {IStoreFactory} from "./interfaces/IStoreFactory.sol";
import {IDomainOracle} from "./interfaces/IDomainOracle.sol";
import {IAdminControl} from "../access/interfaces/IAdminControl.sol";

import {IContractRegistry} from "./interfaces/IContractRegistry.sol";
import {IStoreTiers} from "./interfaces/IStoreTiers.sol";

/// @title Shoply Store
contract Store is IStore, UUPSUpgradeable, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using SafeCast for int256;

    uint256 private constant INTERVAL_LENGTH = 30 days;
    address private constant NATIVE_CURRENCY = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    bytes32 private constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 private constant FULFILLER_ROLE = keccak256("FULFILLER_ROLE");

    // Functionalities
    bytes32 private constant SUBSCRIPTIONS_HASH = keccak256("SUBSCRIPTIONS");

    /// @notice The store name
    bytes32 public storeName;
    /// @notice The owner public key
    string public ownerPubKey;

    /// @notice The store's accepted currency
    address public acceptedCurrency;
    /// @notice USD price data feed for the store's accepted currency
    AggregatorV2V3Interface public priceDataFeed;

    /// @notice Array of all orders
    Order[] public orders;
    /// @notice Array of all products
    Product[] public products;
    /// @notice Array of all digital products
    address[] public digitalProducts;
    /// @notice Array of all subscriptions
    Subscription[] public subscriptions;

    /// @notice Array of all buy now product ids
    uint256[] private buyNowProducts;
    /// @notice Array of all subscription product ids
    /// @dev This is a subset of `buyNowProducts`
    uint256[] private subscriptionProducts;
    /// @notice Array of all auction product ids
    uint256[] private auctionProducts;

    /// @notice Mapping of active products
    mapping(uint256 => bool) private isActiveProduct;
    /// @notice Number of active products
    uint256 private activeProductCount;

    /// @notice Mapping of top bids for each auction product
    mapping(uint256 => Bid) public topBids;

    /// @notice Mapping of buyer public keys
    mapping(address => string) public pubKeys; // Move to external storage contract

    /// @notice Mapping of product reviews
    mapping(uint256 => Review[]) private productReviews;
    /// @notice Mapping of product ratings
    /// @dev Product ratings are between 100 and 500 (ex. 4.5/5 = 450)
    mapping(uint256 => uint256) private productRating;
    /// @notice Mapping of rating quantityƒ
    mapping(uint256 => uint256) private reviewCount;

    /// @notice Mapping of order reviews
    mapping(uint256 => uint256) private orderReviews;
    /// @notice Whether the order has been reviewed or not
    mapping(uint256 => bool) private orderReviewed;
    /// @notice Whether the owner has responded to the review or not
    mapping(uint256 => bool) private ownerResponded;

    /// @notice Mapping of owner responses
    mapping(uint256 => string) private ownerResponses;
    /// @notice Get the tracking information for order `orderId`
    mapping(uint256 => Tracking) private orderTracking;
    /// @notice Mapping of product to mode of purchase (buy now or auction)
    mapping(uint256 => bool) public purchaseType;
    /// @notice Mapping of product types (digital or physical)
    mapping(uint256 => ProductType) public productType;
    /// @notice Mapping of prices for buy now products
    mapping(uint256 => uint256) public buyNowPrice;
    /// @notice Mapping of start prices for auction products
    mapping(uint256 => uint256) public auctionStartPrice;
    /// @notice Mapping of auction expirations
    mapping(uint256 => uint256) private auctionExpiration;
    /// @notice Mapping of auction time extension settings
    mapping(uint256 => bool) private auctionTimeExtension;
    /// @notice Mapping of subscribable products
    mapping(uint256 => bool) public isSubscribable;
    /// @notice Mapping of intervals remaining for each subscription
    mapping(uint256 => uint256) private intervalsRemaining;
    /// @notice Mapping of intervals fulfilled for each subscription
    mapping(uint256 => uint256) private intervalsFulfilled;
    /// @notice Whether express shipping is available for the product
    mapping(uint256 => bool) public expressShipping;

    /// @notice The Store Factory contract address
    address private storeFactory;

    /// @notice The Contract Registry contract address
    IContractRegistry private contractRegistry;

    /// @notice The standard shipping cost by product id
    mapping(uint256 => uint256) public standardShippingCost;

    /// @notice The express shipping cost by product id
    mapping(uint256 => uint256) public expressShippingCost;

    /// @notice Mapping of accepted countries using ISO 3166-1 numeric codes
    /// @dev ISO country codes found here: https://www.iban.com/country-codes
    mapping(uint256 => bool) public acceptedShippingCountries;

    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the store
    /// @dev Called during the deployment transaction
    function init() external initializer {
        address _storeFactory;
        address _contractRegistry;
        (_storeFactory, _contractRegistry, storeName, acceptedCurrency) = IStoreDeployer(msg.sender).parameters();
        contractRegistry = IContractRegistry(_contractRegistry);
        storeFactory = _storeFactory;
    }

    /// @notice Add an array of accepted shipping countries
    /// @param countries An array of ISO 3166-1 numeric country codes
    function addAcceptedShippingCountries(uint256[] calldata countries) external {
        _onlyOwnerOrEditor();
        for (uint256 i = 0; i < countries.length; i++) {
            acceptedShippingCountries[countries[i]] = true;
        }
        emit AcceptedShippingCountriesAdded(countries);
    }

    /// @notice Remove an array of accepted shipping countries
    /// @param countries An array of ISO 3166-1 numeric country codes
    function removeAcceptedShippingCountries(uint256[] calldata countries) external {
        _onlyOwnerOrEditor();
        for (uint256 i = 0; i < countries.length; i++) {
            acceptedShippingCountries[countries[i]] = false;
        }
        emit AcceptedShippingCountriesRemoved(countries);
    }

    /// @notice Create a new product for the store
    /// @dev Can only be called by the store owner
    /// @dev Emits a ProductCreated event
    /// @param variantQuantities The number of items available for each variant
    /// @param standardShipping The standard shipping cost of the product
    /// @param _expressShipping The express shipping cost of the product
    /// @param isBuyNow True if the product is buy now, false if auction
    /// @param url The IPFS hash of the JSON file containing the product details
    function createPhysicalProduct(
        uint256[] calldata variantQuantities,
        uint256 standardShipping,
        uint256 _expressShipping,
        uint256 price,
        bool isBuyNow,
        bool isFixedValue,
        string memory url
    ) external {
        _ownerInitialized();
        _onlyOwnerOrEditor();
        _activeStore();
        if (isFixedValue && address(priceDataFeed) == address(0)) {
            revert PriceDataFeedNotSet();
        }

        uint256 totalQuantity;
        for (uint256 i = 0; i < variantQuantities.length; i++) {
            totalQuantity += variantQuantities[i];
        }

        if (!isBuyNow && totalQuantity != 1) {
            revert InvalidQuantity();
        }

        uint256 activeProductLimit =
            IStoreTiers(contractRegistry.addressOf("StoreTiers")).activeProductLimit(address(this));

        if (activeProductCount >= activeProductLimit) {
            revert ActiveProductLimitReached();
        }
        ++activeProductCount;
        products.push(Product(totalQuantity, variantQuantities.length, variantQuantities, isBuyNow, isFixedValue, url));
        uint256 productId = products.length - 1;
        if (isBuyNow) {
            buyNowProducts.push(productId);
            buyNowPrice[productId] = price;
            purchaseType[productId] = true;
        } else {
            auctionProducts.push(productId);
            auctionStartPrice[productId] = price;
        }
        standardShippingCost[productId] = standardShipping;
        expressShippingCost[productId] = _expressShipping;
        isActiveProduct[productId] = true;
        emit ProductCreated(productId, totalQuantity, isBuyNow, url);
    }

    /// @notice Create a new digital product for the store
    /// @param collectionAddress The address of the NFT collection
    function createDigitalProduct(address collectionAddress, bool isFixedValue) external {
        _ownerInitialized();
        _onlyOwnerOrEditor();
        _activeStore();

        if (isFixedValue && address(priceDataFeed) == address(0)) {
            revert PriceDataFeedNotSet();
        }

        uint256 activeProductLimit =
            IStoreTiers(contractRegistry.addressOf("StoreTiers")).activeProductLimit(address(this));
        if (activeProductCount >= activeProductLimit) {
            revert ActiveProductLimitReached();
        }
        ++activeProductCount;

        digitalProducts.push(collectionAddress);

        emit DigitalProductCreated(digitalProducts.length - 1, collectionAddress);
    }

    /// @notice Activate a product
    /// @dev Can only be called by the store owner
    /// @dev Emits a ProductActivated event
    /// @param productId The product id
    function activateProduct(uint256 productId) external {
        _onlyOwnerOrEditor();
        _activeStore();
        if (productId >= products.length) {
            revert ProductDoesNotExist();
        }
        if (isActiveProduct[productId]) {
            revert ProductAlreadyActive();
        }
        isActiveProduct[productId] = true;
        activeProductCount++;
        emit ProductActivated(productId);
    }

    /// @notice Deactivate a product
    /// @dev Can only be called by the store owner
    /// @dev Emits a ProductDeactivated event
    /// @param productId The product id
    function deactivateProduct(uint256 productId) external {
        _onlyOwnerOrEditor();
        _activeStore();
        if (!isActiveProduct[productId]) {
            revert ProductNotActive();
        }
        isActiveProduct[productId] = false;
        activeProductCount--;
        emit ProductDeactivated(productId);
    }

    /// @notice Set the duration of an auction
    /// @param productId The product id
    /// @param duration The duration of the auction in seconds
    function setAuctionDetails(uint256 productId, uint256 duration, bool timeExtending) external {
        _onlyOwnerOrEditor();
        _activeStore();
        if (productId >= products.length) {
            revert ProductDoesNotExist();
        }
        if (!isActiveProduct[productId]) {
            revert ProductNotActive();
        }
        if (products[productId].isBuyNow) {
            revert IncorrectPurchaseType();
        }
        if (auctionExpiration[productId] != 0) {
            revert ExpirationAlreadySet();
        }
        auctionExpiration[productId] = block.timestamp + duration;
        auctionTimeExtension[productId] = timeExtending;
        emit AuctionDurationSet(productId, duration);
    }

    /// @notice Allow subscriptions to a product
    /// @dev Can only be called by the store owner
    /// @dev Only buy now products can be used for subscriptions
    /// @param productId The product id
    function setSubscriptionProduct(uint256 productId) external {
        _onlyOwnerOrEditor();
        _activeStore();
        require(acceptedCurrency != NATIVE_CURRENCY);
        if (!IStoreTiers(contractRegistry.addressOf("StoreTiers")).hasFeature(address(this), SUBSCRIPTIONS_HASH)) {
            revert FeatureNotEnabled();
        }

        if (productId >= products.length) {
            revert ProductDoesNotExist();
        }
        if (!purchaseType[productId]) {
            revert IncorrectPurchaseType();
        }
        if (isSubscribable[productId]) {
            revert ProductAlreadySubscribable();
        }
        isSubscribable[productId] = true;
        subscriptionProducts.push(productId);
        emit SubscriptionProductSet(productId);
    }

    /// @notice Disallow future subscriptions for a product
    /// @dev Can only be called by the store owner
    /// @param productId The product id
    function removeSubscriptionProduct(uint256 productId) external {
        _onlyOwnerOrEditor();
        _activeStore();
        if (!isSubscribable[productId]) {
            revert ProductNotSubscribable();
        }
        isSubscribable[productId] = false;
        emit SubscriptionProductRemoved(productId);
    }

    /// @notice Order a product listed to buy now
    /// @notice WARNING: Consumer should check if their country is accepted before calling this function
    /// @param productId The id of the product to order
    /// @param variant The index of the variant to order
    /// @param quantity The number of items to order
    /// @param _expressShipping Whether or not to use express shipping
    /// @param encryptedName The encrypted name of the buyer (encrypted with the owner's public key)
    /// @param encryptedShippingAddress The encrypted shipping address of the buyer (encrypted with the owner's public key)
    function orderBuyNowProduct(
        uint256 productId,
        uint256 variant,
        uint256 quantity,
        bool _expressShipping,
        string memory encryptedName,
        string memory encryptedShippingAddress
    ) external payable {
        _buyerInitialized();
        _activeStore();
        require(isActiveProduct[productId], "Product is not active");
        Product memory product = products[productId];
        if (!expressShipping[productId] && _expressShipping) {
            revert ExpressShippingDisabled();
        }
        if (product.variantCount <= variant) {
            revert InvalidVariant();
        }
        if (quantity == 0 || quantity > product.variantQuantities[variant]) {
            revert InvalidQuantity();
        }
        if (!purchaseType[productId]) {
            revert IncorrectPurchaseType();
        }
        if (products[productId].quantity < quantity) {
            revert InsufficientQuantity();
        }

        products[productId].quantity -= quantity; // decrement from total product quantity
        products[productId].variantQuantities[variant] -= quantity; // decrement from variant quantity

        uint256 paymentAmount;
        if (product.isFixedValue) {
            int256 price = priceDataFeed.latestAnswer();
            if (price <= 0) {
                revert PriceDataFeedError();
            }
            paymentAmount = buyNowPrice[productId] * quantity / price.toUint256();
        } else {
            paymentAmount = buyNowPrice[productId] * quantity;
        }
        if (_expressShipping) {
            paymentAmount += expressShippingCost[productId];
        } else {
            paymentAmount += standardShippingCost[productId];
        }

        orders.push(
            Order(
                msg.sender,
                encryptedName,
                encryptedShippingAddress,
                productId,
                variant,
                quantity,
                paymentAmount,
                OrderStatus.PENDING
            )
        );

        // submit payment
        _submitPayment(paymentAmount);

        emit OrderPlaced(msg.sender, orders.length - 1, productId, quantity);
    }

    /// @notice Set a recurring subscription for a product
    /// @notice WARNING: Consumer should check if their country is accepted before calling this function
    /// @param productId The id of the product to order
    /// @param subQuantity The number of items to order every period
    /// @param intervals The number of intervals for the subscription
    /// @param _expressShipping Whether or not to use express shipping
    /// @param encryptedName The encrypted name of the buyer (encrypted with the owner's public key)
    /// @param encryptedShippingAddress The encrypted shipping address of the buyer (encrypted with the owner's public key)
    function setRecurringSubscription(
        uint256 productId,
        uint256 variant,
        uint256 subQuantity,
        uint256 intervals,
        bool _expressShipping,
        string memory encryptedName,
        string memory encryptedShippingAddress
    ) external payable nonReentrant {
        _buyerInitialized();
        _activeStore();
        require(isActiveProduct[productId]);
        if (!IStoreTiers(contractRegistry.addressOf("StoreTiers")).hasFeature(address(this), SUBSCRIPTIONS_HASH)) {
            revert FeatureNotEnabled();
        }

        if (!expressShipping[productId] && _expressShipping) {
            revert ExpressShippingDisabled();
        }

        // Check if product is subscribable
        if (!isSubscribable[productId]) {
            revert ProductNotSubscribable();
        }
        // There must be sufficient quantity to make the subscription
        if (products[productId].variantQuantities[variant] < subQuantity) {
            revert InsufficientQuantity();
        }

        products[productId].quantity -= subQuantity; // decrement from total product quantity
        products[productId].variantQuantities[variant] -= subQuantity; // decrement from variant quantity

        // Add subscription to subscriptions array
        subscriptions.push(
            Subscription(
                msg.sender,
                productId,
                variant,
                subQuantity,
                block.timestamp,
                _expressShipping,
                encryptedName,
                encryptedShippingAddress
            )
        );

        // Set the intervals remaining for the subscription
        intervalsRemaining[subscriptions.length - 1] = intervals;

        uint256 paymentAmount;
        if (products[productId].isFixedValue) {
            int256 price = priceDataFeed.latestAnswer();
            if (price <= 0) {
                revert PriceDataFeedError();
            }
            paymentAmount = buyNowPrice[productId] * subQuantity / price.toUint256();
        } else {
            paymentAmount = buyNowPrice[productId] * subQuantity;
        }

        if (_expressShipping) {
            paymentAmount += expressShippingCost[productId];
        } else {
            paymentAmount += standardShippingCost[productId];
        }

        // Create an order for the first interval of the subscription
        orders.push(
            Order(
                msg.sender,
                encryptedName,
                encryptedShippingAddress,
                productId,
                variant,
                subQuantity,
                paymentAmount,
                OrderStatus.PENDING
            )
        );

        _submitPayment(paymentAmount);

        emit OrderPlaced(msg.sender, orders.length - 1, productId, subQuantity);
        emit SubscriptionCreated(subscriptions.length - 1, msg.sender, productId, subQuantity, intervals);
    }

    /// @notice Called by store owner to fulfill a subscription order
    /// @dev Subscriber must have sufficient balance and set sufficent allowance (erc-20) for the store to transfer the funds
    /// @param subscriptionId The id of the subscription to fulfill
    function fulfillSubscription(uint256 subscriptionId) external nonReentrant {
        _onlyFulfiller();
        _activeStore();
        Subscription memory subscription = subscriptions[subscriptionId];
        require(isActiveProduct[subscription.productId]);

        uint256 intervalsReady =
            (block.timestamp - subscription.startTime) / INTERVAL_LENGTH - intervalsFulfilled[subscriptionId];
        intervalsFulfilled[subscriptionId]++;

        if (intervalsReady == 0) {
            revert SubscriptionNotReady();
        }

        if (intervalsRemaining[subscriptionId] == 0) {
            revert SubscriptionIntervalsExceeded();
        }
        intervalsRemaining[subscriptionId]--;

        // There must be sufficient quantity to make the subscription
        if (products[subscription.productId].variantQuantities[subscription.variant] < subscription.quantity) {
            revert InsufficientQuantity();
        }

        products[subscription.productId].quantity -= subscription.quantity; // decrement from total product quantity
        products[subscription.productId].variantQuantities[subscription.variant] -= subscription.quantity; // decrement from variant quantity

        uint256 paymentAmount;
        if (products[subscription.productId].isFixedValue) {
            int256 price = priceDataFeed.latestAnswer();
            if (price <= 0) {
                revert PriceDataFeedError();
            }
            paymentAmount = buyNowPrice[subscription.productId] * subscription.quantity / price.toUint256();
        } else {
            paymentAmount = buyNowPrice[subscription.productId] * subscription.quantity;
        }

        if (subscription.expressShipping) {
            paymentAmount += expressShippingCost[subscription.productId];
        } else {
            paymentAmount += standardShippingCost[subscription.productId];
        }

        orders.push(
            Order(
                subscription.subscriber,
                subscription.encryptedName,
                subscription.encryptedShippingAddress,
                subscription.productId,
                subscription.variant,
                subscription.quantity,
                paymentAmount,
                OrderStatus.PENDING
            )
        );
        uint256 orderId = orders.length - 1;

        IERC20(acceptedCurrency).safeTransferFrom(
            subscription.subscriber,
            IDomainOracle(contractRegistry.addressOf("DomainRegistry")).domainOwner(storeName),
            paymentAmount
        );

        emit SubscriptionFulfilled(subscriptionId, orderId);
    }

    /// @notice Make a bid for a product being auctioned
    /// @notice WARNING: Consumer should check if their country is accepted before calling this function
    /// @param productId The id of the product to bid on
    /// @param bidAmount The amount of the bid
    function makeAuctionBid(uint256 productId, uint256 bidAmount) external payable nonReentrant {
        _buyerInitialized();
        _activeStore();
        require(isActiveProduct[productId]);
        if (auctionExpiration[productId] == 0) {
            revert AuctionNotStarted();
        }
        if (block.timestamp > auctionExpiration[productId]) {
            revert AuctionEnded();
        }

        // if auction is time extending -- extend auction by 5 minutes when a bid is made within 5 minutes of auction end
        if (auctionTimeExtension[productId] && block.timestamp >= auctionExpiration[productId] - 5 minutes) {
            auctionExpiration[productId] += 5 minutes;
        }

        Bid storage topBid = topBids[productId];

        if (bidAmount <= topBid.bidAmount || bidAmount < auctionStartPrice[productId]) {
            revert BidTooSmall();
        }

        // refund previous top bid
        if (topBid.bidder != address(0)) {
            if (acceptedCurrency == NATIVE_CURRENCY) {
                _transfer(payable(topBid.bidder), topBid.bidAmount);
            } else {
                IERC20(acceptedCurrency).safeTransfer(topBid.bidder, topBid.bidAmount);
            }
        }

        topBid.bidAmount = bidAmount;
        topBid.bidder = msg.sender;

        Product memory product = products[productId];

        if (product.isBuyNow) {
            revert IncorrectPurchaseType();
        }

        // handle bid payment
        if (acceptedCurrency == NATIVE_CURRENCY) {
            if (msg.value != bidAmount) {
                revert InsufficientValue();
            }
        } else {
            IERC20(acceptedCurrency).safeTransferFrom(msg.sender, address(this), bidAmount);
        }

        emit AuctionBid(msg.sender, productId, bidAmount);
    }

    /// @notice Send order information to store after winning an auction
    /// @notice WARNING: Consumer should check if their country is accepted before calling this function
    /// @param productId The id of the product to order
    /// @param encryptedName The encrypted name of the buyer (encrypted with the owner's public key)
    /// @param encryptedShippingAddress The encrypted shipping address of the buyer (encrypted with the owner's public key)
    function sendAuctionOrder(uint256 productId, string memory encryptedName, string memory encryptedShippingAddress)
        external
        payable
    {
        _buyerInitialized();
        if (auctionExpiration[productId] > block.timestamp) {
            revert AuctionNotEnded();
        }
        Bid memory topBid = topBids[productId];
        if (topBid.bidder != msg.sender) {
            revert NotBuyer();
        }
        // send payment to store owner
        if (acceptedCurrency == NATIVE_CURRENCY) {
            _transfer(
                payable(IDomainOracle(contractRegistry.addressOf("DomainRegistry")).domainOwner(storeName)),
                topBid.bidAmount
            );
        } else {
            IERC20(acceptedCurrency).safeTransferFrom(
                msg.sender,
                IDomainOracle(contractRegistry.addressOf("DomainRegistry")).domainOwner(storeName),
                topBid.bidAmount
            );
        }

        orders.push(
            Order(
                msg.sender,
                encryptedName,
                encryptedShippingAddress,
                productId,
                0,
                1,
                topBid.bidAmount,
                OrderStatus.PENDING
            )
        );
        // decrement from total product quantity
        products[productId].quantity -= 1;
        emit OrderPlaced(msg.sender, orders.length - 1, productId, 1);
    }

    /// @notice Write a review for a product
    /// @param orderId The id of the order to review
    /// @param rating The rating of the product (1-5)
    /// @param reviewURI The IPFS hash of the product review
    function writeReview(uint256 orderId, uint8 rating, string memory reviewURI) external {
        Order memory order = orders[orderId];
        if (msg.sender != order.buyer) {
            revert NotBuyer();
        }
        if (orderReviewed[orderId]) {
            revert AlreadyReviewed();
        }

        if (rating < 1 || rating > 5) {
            revert InvalidRating();
        }

        uint256 productId = order.productId;

        orderReviews[orderId] = productReviews[productId].length;
        productReviews[productId].push(Review(rating, reviewURI, ""));

        reviewCount[productId]++;

        uint256 factoredRating = uint256(rating) * 100;

        // update productRating
        if (reviewCount[productId] == 1) {
            productRating[productId] = factoredRating;
        } else {
            productRating[productId] =
                (productRating[productId] * (reviewCount[productId] - 1) + factoredRating) / reviewCount[productId];
        }

        orderReviewed[orderId] = true;
        emit ReviewWritten(orderId, rating, reviewURI);
    }

    /// @notice Write the owner response to a review
    /// @param orderId The id of the order attached to the review
    /// @param response The response to the review
    function writeOwnerResponse(uint256 orderId, string memory response) external {
        _onlyOwner();

        if (!orderReviewed[orderId]) {
            revert NotReviewed();
        }
        if (ownerResponded[orderId]) {
            revert AlreadyResponded();
        }

        ownerResponded[orderId] = true;
        ownerResponses[orderId] = response;
        emit OwnerResponse(orderId, response);
    }

    /// @notice Update the quantity of a product
    /// @param productId The id of the product to update
    /// @param variantQuantities The new variant quantities of the product
    function updateProductAvailability(uint256 productId, uint256[] calldata variantQuantities) external {
        _onlyFulfiller();
        _activeStore();
        Product storage product = products[productId];

        if (variantQuantities.length != product.variantQuantities.length) {
            revert InvalidQuantityInput();
        }

        if (!isActiveProduct[productId]) {
            revert ProductNotActive();
        }

        if (!product.isBuyNow) {
            revert CannotRemoveLiveAuction();
        }

        uint256 totalQuantity;
        for (uint256 i = 0; i < variantQuantities.length; i++) {
            totalQuantity += variantQuantities[i];
        }

        products[productId].variantQuantities = variantQuantities;
        products[productId].quantity = totalQuantity;
        emit ProductAvailabilityUpdated(productId, totalQuantity);
    }

    /// @notice Add tracking information for an order
    /// @param orderId The id of the order to update
    /// @param encryptedProvider The shipping provider (encrypted with the buyer's public key)
    /// @param encryptedTrackingNumber The tracking number (encrypted with the buyer's public key)
    function addOrderTracking(uint256 orderId, string memory encryptedProvider, string memory encryptedTrackingNumber)
        external
    {
        _onlyFulfiller();
        if (orderId >= orders.length) {
            revert InvalidOrderId();
        }
        Tracking storage tracking = orderTracking[orderId];
        tracking.provider = encryptedProvider;
        tracking.trackingNumber = encryptedTrackingNumber;
        orders[orderId].status = OrderStatus.SHIPPED;
        emit OrderTrackingAdded(orderId, encryptedProvider, encryptedTrackingNumber);
    }

    /// @notice Set the public key for msg.sender
    /// @dev Use setOwnerPubKey to set the owner's public key
    /// @param _buyerPubKey The public key to set
    function initializeBuyer(string calldata _buyerPubKey) external {
        if (bytes(_buyerPubKey).length == 0) {
            revert InvalidPubKey();
        }
        pubKeys[msg.sender] = _buyerPubKey;
    }

    /// @notice Set the owner's public key
    /// @param _ownerPubKey The owner's public key
    function setOwnerPubKey(string calldata _ownerPubKey) external {
        _onlyOwner();
        if (bytes(_ownerPubKey).length == 0) {
            revert InvalidPubKey();
        }
        ownerPubKey = _ownerPubKey;
        emit OwnerPubKeySet(_ownerPubKey);
    }

    /// @notice Update the role of an account
    /// @param role The role to update
    /// @param account The account to update
    /// @param hasRole Whether the account has the role
    function updateRole(bytes32 role, address account, bool hasRole) external {
        _onlyOwner();
        IStoreFactory(storeFactory).updateRole(role, account, hasRole);
    }

    /// @notice Set the buy not price of a product
    /// @param productId The id of the product to update
    /// @param _buyNowPrice The new buy now price
    /// @param isFixedValue Whether the price is a USD amount (true) or a token amount (false)
    function setProductBuyNowPrice(uint256 productId, uint256 _buyNowPrice, bool isFixedValue) external {
        _onlyOwnerOrEditor();
        _activeStore();
        if (!isActiveProduct[productId]) {
            revert InvalidProductId();
        }
        if (!products[productId].isBuyNow) {
            revert IncorrectPurchaseType();
        }
        if (isFixedValue && address(priceDataFeed) == address(0)) {
            revert PriceDataFeedNotSet();
        }
        products[productId].isFixedValue = isFixedValue;
        buyNowPrice[productId] = _buyNowPrice;
    }

    /// @notice Sets the store tier
    /// @notice WARNING: This will change the date the store ownership is set to lapse.
    /// @param _tier The new store tier
    function setStoreTier(uint8 _tier) external {
        _onlyOwnerOrEditor();
        IStoreTiers(contractRegistry.addressOf("StoreTiers")).setStoreTier(_tier);
    }

    /// @notice Set the price data feed
    function setPriceDataFeed() external {
        _onlyOwnerOrEditor();
        address _priceDataFeed = contractRegistry.priceDataFeed(acceptedCurrency);
        if (_priceDataFeed == address(0)) {
            revert PriceDataFeedNotSet();
        }
        priceDataFeed = AggregatorV2V3Interface(_priceDataFeed);
    }

    /// @notice Add express shipping for a product
    /// @param productId The product id
    function addProductExpressShipping(uint256 productId) external {
        _onlyOwnerOrEditor();
        _activeStore();
        expressShipping[productId] = true;
    }

    /// @notice Remove express shipping for a product
    /// @param productId The product id
    function removeProductExpressShipping(uint256 productId) external {
        _onlyOwnerOrEditor();
        _activeStore();
        expressShipping[productId] = false;
    }

    /// @notice Get all the store's products
    /// @return An array of all the store's products
    function getAllProducts() external view returns (Product[] memory) {
        return products;
    }

    /// @notice Get all the store's buy now products
    /// @return An array of all the store's buy now products
    function getAllBuyNowProducts() external view returns (uint256[] memory) {
        return buyNowProducts;
    }

    /// @notice Get all the store's subsciption products
    /// @return An array of all the store's subscription products
    function getAllSubscriptionProducts() external view returns (uint256[] memory) {
        return subscriptionProducts;
    }

    /// @notice Get all the store's auction products
    /// @return An array of all the store's auction products
    function getAllAuctionProducts() external view returns (uint256[] memory) {
        return auctionProducts;
    }

    function _submitPayment(uint256 paymentAmount) internal {
        if (acceptedCurrency == NATIVE_CURRENCY) {
            require(msg.value == paymentAmount);
            _transfer(
                payable(IDomainOracle(contractRegistry.addressOf("DomainRegistry")).domainOwner(storeName)),
                paymentAmount
            );
        } else {
            IERC20(acceptedCurrency).safeTransfer(
                IDomainOracle(contractRegistry.addressOf("DomainRegistry")).domainOwner(storeName), paymentAmount
            );
        }
    }

    /// @notice Function to transfer Ether from this contract to address from input
    /// @param _to address of transfer recipient
    /// @param _amount amount of ether to be transferred
    function _transfer(address payable _to, uint256 _amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = _to.call{value: _amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function _onlyOwner() internal view {
        if (IDomainOracle(contractRegistry.addressOf("DomainOracle")).domainOwner(storeName) != msg.sender) {
            revert AccessControl();
        }
    }

    function _onlyOwnerOrEditor() internal view {
        if (
            IDomainOracle(contractRegistry.addressOf("DomainOracle")).domainOwner(storeName) != msg.sender
                && !IStoreFactory(storeFactory).hasRole(address(this), EDITOR_ROLE, msg.sender)
        ) {
            revert AccessControl();
        }
    }

    // owner and editors are always "fulfillers" even without the role
    function _onlyFulfiller() internal view {
        if (
            IDomainOracle(contractRegistry.addressOf("DomainOracle")).domainOwner(storeName) != msg.sender
                && !IStoreFactory(storeFactory).hasRole(address(this), EDITOR_ROLE, msg.sender)
                && !IStoreFactory(storeFactory).hasRole(address(this), FULFILLER_ROLE, msg.sender)
        ) {
            revert AccessControl();
        }
    }

    function _ownerInitialized() internal view {
        if (bytes(ownerPubKey).length == 0) {
            revert OwnerNotInitialized();
        }
    }

    function _buyerInitialized() internal view {
        if (bytes(pubKeys[msg.sender]).length == 0) {
            revert BuyerNotInitialized();
        }
    }

    function _activeStore() internal view {
        uint256 storeExpiration = IStoreTiers(contractRegistry.addressOf("StoreTiers")).storeExpiration(address(this));
        if (storeExpiration < block.timestamp) {
            revert InactiveStore();
        }
    }

    // override from UUPSUpgradeable, added onlyOwner modifier for access control
    function _authorizeUpgrade(address) internal view override {
        _onlyOwner();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Interface for a Shoply store
interface IStore {
    /// @notice Not enough quantity to fulfill order
    error InsufficientQuantity();
    /// @notice Insufficient msg.value
    error InsufficientValue();
    /// @notice Product cannot be purchased with this type
    error IncorrectPurchaseType();
    /// @notice The product id does not exist
    error InvalidProductId();
    /// @notice Invalid variant input
    error InvalidVariantInput();
    /// @notice Invalid quantity input
    error InvalidQuantityInput();
    /// @notice The order id does not exist
    error InvalidOrderId();
    /// @notice Quantity cannot be 0
    error InvalidQuantity();
    /// @notice The product variant does not exist
    error InvalidVariant();
    /// @notice Rating must be between 1 and 5
    error InvalidRating();
    /// @notice Caller is not a valid admin
    error OnlyAdmin();
    /// @notice Caller is not the owner of the store
    error OnlyOwner();
    /// @notice Buyer has not initialized their public key
    error BuyerNotInitialized();
    /// @notice Attempted bid is less than the top bid
    error BidTooSmall();
    /// @notice Caller is not the buyer of the order
    error NotBuyer();
    /// @notice A review has not yet been placed for this order
    error NotReviewed();
    /// @notice A review has already been placed for this order
    error AlreadyReviewed();
    /// @notice The owner has already responded to the product review
    error AlreadyResponded();
    /// @notice Cannot remove a product that is live in an auction
    error CannotRemoveLiveAuction();
    /// @notice The owner's public key has not been initialized
    error OwnerNotInitialized();
    /// @notice The public key cannot be bytes zero
    error InvalidPubKey();
    /// @notice The active product limit has been reached
    error ActiveProductLimitReached();
    /// @notice The product is not active
    error ProductNotActive();
    /// @notice The product does not exist
    error ProductDoesNotExist();
    /// @notice The product is already active
    error ProductAlreadyActive();
    /// @notice Order is not pending
    error OrderNotPending();
    /// @notice Subscription has ended
    error SubscriptionIntervalsExceeded();
    /// @notice Invalid subscription interval
    error SubscriptionNotReady();
    /// @notice A price data feed is not set
    error PriceDataFeedNotSet();
    /// @notice Product is already subscribable
    error ProductAlreadySubscribable();
    /// @notice Cannot subscribe to this product
    error ProductNotSubscribable();
    /// @notice Price data feed returned invalid price
    error PriceDataFeedError();
    /// @notice Store does not have the correct tier for the feature
    error FeatureNotEnabled();
    /// @notice Transfer failed
    error TransferFailed();
    /// @notice Sender does not have function access
    error AccessControl();
    /// @notice Store subscription is not active
    error InactiveStore();
    /// @notice Auction expiration has already been set
    error ExpirationAlreadySet();
    /// @notice Auction has not started
    error AuctionNotStarted();
    /// @notice Auction has not ended
    error AuctionNotEnded();
    /// @notice Auction has already ended
    error AuctionEnded();
    /// @notice Express shipping is not enabled for this product
    error ExpressShippingDisabled();

    struct Product {
        uint256 quantity; // number of available items for sale (should be updateable by the owner)
        uint256 variantCount; // number of variants for the product
        uint256[] variantQuantities; // number of available items for each variant
        bool isBuyNow; // true if buy now, false if auction
        bool isFixedValue; // true if fixed value, false if fixed price
        string mediaUrl; // IPFS hash of JSON file
    }

    struct Review {
        uint8 rating; // rating from 1 to 5
        string comment; // comment from the buyer
        string response; // response from the owner
    }

    struct Rating {
        uint8 currentRating;
        uint256 points;
        uint256 totalWeight;
    }

    struct Order {
        address buyer; // buyer evm address
        string encryptedName; // buyer's name encrypted with owner's public key
        string encryptedShippingAddress; // buyer's shipping address encrypted with owner's public key
        uint256 productId; // product id
        uint256 variant; // product variant
        uint256 quantity; // quantity of items to purchase
        uint256 amount; // amount of payment
        OrderStatus status; // order status
    }

    struct Tracking {
        string provider;
        string trackingNumber;
    }

    struct Bid {
        address bidder;
        uint256 bidAmount;
    }

    struct Subscription {
        address subscriber; // address of the subscriber
        uint256 productId; // the product to purchase
        uint256 variant; // the variant of the product to purchase
        uint256 quantity; // quantity of items to purchase per interval
        uint256 startTime; // the subscription's start time
        bool expressShipping; // true if express shipping is enabled
        string encryptedName; // buyer's name encrypted with owner's public key
        string encryptedShippingAddress; // buyer's shipping address encrypted with owner's public key
    }

    struct Buyer {
        bytes32 pubKey; // buyer public key
        string encryptedName; // buyer's name encrypted with owner's public key
        string encryptedShippingAddress; // buyer's shipping address encrypted with owner's public key
        uint256[] orders; // list of orders
        uint256[] subscriptions; // list of subscriptions
    }

    enum OrderStatus {
        PENDING,
        REFUNDED,
        SHIPPED
    }

    enum ProductType {
        DIGITAL,
        PHYSICAL
    }

    /// @notice Emitted when accepted shipping countries are added
    /// @param countryCodes An array of ISO 3166-1 numeric country codes
    event AcceptedShippingCountriesAdded(uint256[] countryCodes);

    /// @notice Emitted when accepted shipping countries are removed
    /// @param countryCodes An array of ISO 3166-1 numeric country codes
    event AcceptedShippingCountriesRemoved(uint256[] countryCodes);

    /// @notice Emitted when the owner's public key is set
    /// @param pubKey The owner's public key
    event OwnerPubKeySet(string pubKey);

    /// @notice Emitted when an order is placed
    /// @param buyer The address of the buyer
    /// @param orderId The id of the order
    /// @param productId The id of the product
    /// @param quantity The purchased quantity
    event OrderPlaced(address indexed buyer, uint256 indexed orderId, uint256 productId, uint256 quantity);

    /// @notice Emitted when the owner responds to a review
    /// @param orderId The id of the order
    /// @param response The response to the review
    event OwnerResponse(uint256 indexed orderId, string response);

    /// @notice Emitted when an auction bid is made
    /// @param bidder The address of the bidder
    /// @param auctionProductId The id of the auction product
    /// @param bidAmount The bid amount
    event AuctionBid(address indexed bidder, uint256 indexed auctionProductId, uint256 indexed bidAmount);

    /// @notice Emitted when tracking information is added to an order
    /// @param orderId The id of the order
    /// @param encryptedProvider The encrypted tracking provider
    /// @param encryptedTrackingNumber The encrypted tracking number
    event OrderTrackingAdded(uint256 indexed orderId, string encryptedProvider, string encryptedTrackingNumber);

    /// @notice Emitted when a product is deactivated
    /// @param productId The id of the product
    event ProductDeactivated(uint256 indexed productId);

    /// @notice Emitted when a product is activated
    /// @param productId The id of the product
    event ProductActivated(uint256 indexed productId);

    /// @notice Emitted when a new product is created
    /// @param productId The id of the product
    /// @param quantity The quantity available for the product
    /// @param isBuyNow True if the product is buy now, false if auction
    /// @param url The IPFS hash of the product description
    event ProductCreated(uint256 indexed productId, uint256 indexed quantity, bool isBuyNow, string url);

    /// @notice Emitted when a digital product is created
    /// @param digitalProductId The id of the digital product
    /// @param collectionAddress The address of the NFT collection
    event DigitalProductCreated(uint256 indexed digitalProductId, address indexed collectionAddress);

    /// @notice Emitted when a product review is writted
    /// @param orderId The id of the order
    /// @param rating The rating of the product
    /// @param review The IPFS hash of the review
    event ReviewWritten(uint256 indexed orderId, uint8 indexed rating, string review);

    /// @notice Emitted when the product quantity is updated
    /// @param productId The id of the product
    /// @param quantity The new quantity
    event ProductAvailabilityUpdated(uint256 indexed productId, uint256 indexed quantity);

    /// @notice Emitted when an order is refunded
    /// @param orderId The id of the order
    event OrderRefunded(uint256 indexed orderId);

    /// @notice Emitted when a product is made subscribable
    /// @param productId The id of the product
    event SubscriptionProductSet(uint256 indexed productId);

    /// @notice Emitted when a product is made unsubscribable
    /// @param productId The id of the product
    event SubscriptionProductRemoved(uint256 indexed productId);

    /// @notice Emitted when a subscription is created
    /// @param subscriptionId The id of the subscription
    /// @param subscriber The address of the subscriber
    /// @param productId The id of the product
    /// @param quantity The quantity to be purchased each interval
    /// @param intervals The number of intervals of the subscription
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        address subscriber,
        uint256 indexed productId,
        uint256 indexed quantity,
        uint256 intervals
    );

    /// @notice Emitted when a subscription is fulfilled
    /// @param subscriptionId The id of the subscription
    /// @param orderId The id of the order
    event SubscriptionFulfilled(uint256 indexed subscriptionId, uint256 indexed orderId);

    /// @notice Emitted when an auction expiration is set
    /// @param auctionProductId The id of the auction product
    /// @param duration The duration of the auction
    event AuctionDurationSet(uint256 indexed auctionProductId, uint256 duration);

    function getAllProducts() external view returns (Product[] memory);
    function getAllBuyNowProducts() external view returns (uint256[] memory);
    function getAllSubscriptionProducts() external view returns (uint256[] memory);
    function getAllAuctionProducts() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// Interface for the Shoply store deployer
interface IStoreDeployer {

    function parameters() external view returns (
        address storeFactory,
        address contractRegistry,
        bytes32 storeName,
        address acceptedCurrency
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Contract Registry cannot be the zero address
error InvalidAddress();

/// @notice Caller is not the domain owner
error NotDomainOwner();

/// @notice Accepted currency cannot be address zero
error InvalidCurrency();

/// @notice Referrer cannot be address zero or the store owner
error InvalidReferrer();

/// @notice Sender is not a valid store address
error NotStore();

/// @notice Store version is inactive
error VersionInactive();

/// @title Interface for the Shoply store factory
interface IStoreFactory {

    /// @notice Emitted when a store is created
    /// @param store The address of the store
    /// @param domain The domain of the store
    event StoreCreated(address indexed store, bytes32 indexed domain);

    /// @notice Emitted when the contract registry is set
    /// @param contractRegistry The contract registry address
    event ContractRegistrySet(address indexed contractRegistry);

    /// @notice Emitted when a role is granted
    /// @param store The store address
    /// @param role The role
    /// @param account The account
    /// @param hasRole The role status
    event RoleUpdated(address indexed store, bytes32 indexed role, address indexed account, bool hasRole);
    
    function updateRole(bytes32 role, address account, bool hasRole) external;
    function isStore(address store) external view returns (bool status);
    function hasRole(address store, bytes32 role, address user) external view returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Interface for the Shoply Domain Oracle
/// @dev Domain Oracle interface
interface IDomainOracle {

    /// The input arrays must be the same length
    error InvalidInput();
    /// The domain is already registered
    error DomainAlreadyRegistered();

    /// @notice Emitted when a domain is registered
    /// @param domain The domain
    /// @param owner The domain owner
    event DomainRegistered(bytes32 indexed domain, address indexed owner);

    /// @notice Emitted when a domain is transferred
    /// @param domain The domain
    /// @param newOwner The new domain owner
    event DomainTransferred(bytes32 indexed domain, address indexed newOwner);

    function domainOwner(bytes32 domain) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IAdminControl {
    function isAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ZeroAddress();
error InvalidAddress();
error InvalidName();
/// @notice Input arrays must be the same length
error InvalidArrayLengths();

/// @dev Contract Registry interface
interface IContractRegistry {

    /// @notice Emitted when an address pointed to by a contract name is modified
    /// @param contractName The contract name
    /// @param contractAddress The contract address
    event AddressUpdate(bytes32 indexed contractName, address contractAddress);
    
    /// @notice Emitted when the fee address is set
    /// @param feeAddress The fee address
    event FeeAddressSet(address feeAddress);

    /// @notice Emitted when price data feeds are set
    /// @param tokens An array of tokens
    /// @param feeds An array of data feeds
    event PriceDataFeedsSet(address[] tokens, address[] feeds);

    /// @notice Emitted when the wrapped native address is set
    /// @param wrappedNative The wrapped native address (e.g. weth)
    event WrappedNativeSet(address wrappedNative);

    function addressOf(bytes32 contractName) external view returns (address);
    function feeAddress() external view returns (address);
    function priceDataFeed(address token) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Not a valid store
error InvalidStore();
/// @notice The fee address cannot be the zero address
error InvalidFeeAddress();
/// @notice Store Factory cannot be the zero address
error InvalidStoreFactory();
/// @notice Intervals cannot be greater than 12
error InvalidIntervals();
/// @notice The fee token is not supported
error InvalidFeeToken();
/// @notice No allowance for the given discount code
error InvalidDiscountCode();
/// @notice Array lengths are not equal
error InvalidArrayLengths();
/// @notice Payment Failed
error PaymentFailed();
/// @notice Eth Transfer Failed
error EthTransferFailed();

/// @title The interface for the StoreTiers contract
interface IStoreTiers {

    /// @notice Emitted when the fee address is set
    /// @param feeAddress The address of the store platform fee recipient
    event FeeAddressSet(address feeAddress);

    /// @notice Emitted when a store platform fee is paid
    /// @param store The address of the store
    /// @param user The address of the user paying the fee
    /// @param intervals The number of 30 day intervals paid
    /// @param tier The tier of the store
    event StorePlatformFeePaid(address indexed store, address indexed user,uint256 intervals, uint256 tier);

    /// @notice Emitted when the story factory is set
    /// @param storeFactory The address of the store factory
    event StoreFactorySet(address storeFactory);

    /// @notice Emitted when a store tier is set
    /// @param store The address of the store
    /// @param tier The new store tier
    /// @param expiration The new store expiration
    event StoreTierSet(address indexed store, uint8 indexed tier, uint256 indexed expiration);

    /// @notice Emitted when a tier cost is set
    /// @param tier The tier
    /// @param cost The cost of the tier
    event TierCostSet(uint8 indexed tier, uint256 indexed cost);

    /// @notice Emitted when a store referrer is set
    /// @param store The address of the store
    /// @param referrer The address of the referrer
    event StoreReferrerSet(address indexed store, address indexed referrer);

    /// @notice Emitted when a referral fee is paid
    /// @param store The address of the store
    /// @param referrer The address of the referrer
    /// @param amount The amount of the referral fee
    event ReferralFeePaid(address indexed store, address indexed referrer, uint256 amount);

    /// @notice Emitted when a fee token is set
    /// @param feeToken The address of the fee token
    /// @param priceFeed The address of the price feed
    event FeeTokenSet(address indexed feeToken, address indexed priceFeed);

    /// @notice Emitted when the contract registry is set
    /// @param contractRegistry The address of the contract registry
    event ContractRegistrySet(address contractRegistry);

    /// @notice Emitted when a store duration is increased without platform fee payment
    /// @param store The address of the store
    /// @param intervals The number of intervals added
    event AdminStoreDurationIncreased(address indexed store, uint256 indexed intervals);

    /// @notice Emitted when discount codes are added
    /// @param hashedCodes The hashed codes
    /// @param discounts The discounts
    event HashedDiscountCodesAdded(bytes32[] hashedCodes, uint256[] discounts);

    /// @notice Emitted when a tier active product limit is set
    /// @param tier The tier
    /// @param activeProductLimit The active product limit for store's in the tier
    event TierActiveProductLimitSet(uint8 indexed tier, uint256 indexed activeProductLimit);

    /// @notice Emitted when new features are added for store tiers
    /// @param tiers An array of tiers
    /// @param features An array of features
    event TierFeaturesAdded(uint8[] tiers, bytes32[] features);

    /// @notice Emitted when features are removed from store tiers
    /// @param tiers An array of tiers
    /// @param features An array of features
    event TierFeaturesRemoved(uint8[] tiers, bytes32[] features);

    function setInitialMonth(address store) external;
    function setStoreReferrer(address store, address referrer) external;
    function setStoreTier(uint8 _tier) external;
    function hasFeature(address store, bytes32 feature) external view returns (bool);
    function storeTiers(address store) external view returns (uint8);
    function activeProductLimit(address store) external view returns (uint256);
    function storeExpiration(address store) external view returns (uint256);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}