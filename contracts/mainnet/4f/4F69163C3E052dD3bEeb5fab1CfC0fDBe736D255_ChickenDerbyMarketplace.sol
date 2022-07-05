// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./BaseRelayRecipient.sol";

import {ICollectionManager} from "../Interfaces/ICollectionManager.sol";
import {IExchange} from "../Interfaces/IExchange.sol";
import {Errors} from "../Libraries/Errors.sol";
import {MarketItem, Trade, TradeOffer} from "../Libraries/Structs.sol";
import {TradeType} from "../Libraries/Constants.sol";

contract ChickenDerbyMarketplace is
    IExchange,
    Initializable,
    BaseRelayRecipient,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    address public wethContract;
    uint256 public floorPrice;
    uint256 private _marketFee;
    address private _marketFeeRecipient;

    ICollectionManager public collectionManager;

    Counters.Counter private _tradeIndexCounter;
    mapping(bytes32 => MarketItem) public idToMarketItems;
    mapping(bytes32 => TradeOffer) public idToOffers;
    mapping(uint256 => Trade) public releasedTrades;
    EnumerableSet.Bytes32Set private _openItems;
    EnumerableSet.Bytes32Set private _openOffers;

    function initialize(
        address _trustedForwarder,
        address _collectionManager,
        address _wethContract,
        uint256 _floorPrice,
        address _recipient,
        uint256 _feeAmount
    ) public virtual initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        trustedForwarder = _trustedForwarder;
        collectionManager = ICollectionManager(_collectionManager);
        wethContract = _wethContract;
        floorPrice = _floorPrice;
        _marketFeeRecipient = _recipient;
        _marketFee = _feeAmount;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual override returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract.
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0";
    }

    function setTrustedForwarder(address _forwarder) external onlyOwner {
        trustedForwarder = _forwarder;
    }

    function setFloorPrice(uint256 _floorPrice) public override onlyOwner {
        floorPrice = _floorPrice;
    }

    function getMarketFee() public view override returns (uint256) {
        return _marketFee;
    }

    function setMarketFee(uint256 _feeAmount) public override onlyOwner {
        _marketFee = _feeAmount;
    }

    function setMarketFeeRecipient(address _recipient)
        public
        virtual
        override
        onlyOwner
    {
        _marketFeeRecipient = _recipient;
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 minimum,
        TradeType tradeType
    ) external override nonReentrant {
        // To check if the collection is for ChickenDerby
        if (!collectionManager.isCollectionWhitelisted(nftContract))
            revert Errors.CollectionNotExists();
        // Price should be le than floor price
        if (price < floorPrice) revert Errors.LowFloorPrice();
        // To check if the msg sender owns the token
        if (IERC721(nftContract).ownerOf(tokenId) != _msgSender())
            revert Errors.NotTokenOwner();
        // To check if the token is approved to this marketplace
        if (IERC721(nftContract).getApproved(tokenId) != address(this))
            revert Errors.TokenNotApproved();
        // To create market item
        bytes32 itemId = keccak256(
            abi.encodePacked(nftContract, tokenId, _msgSender())
        );
        if (_openItems.contains(itemId)) revert Errors.ItemAlreadyExists();
        idToMarketItems[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            _msgSender(),
            address(0),
            price,
            tradeType,
            minimum,
            false
        );
        // To add item id to the active items list
        _openItems.add(itemId);
        // To emit an event to notify that
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            _msgSender(),
            address(0),
            price,
            tradeType,
            minimum,
            false
        );
    }

    function editMarketItem(
        bytes32 _itemId,
        uint256 _newPrice,
        uint256 _minimum,
        TradeType _tradeType
    ) external override nonReentrant {
        // Get the market item from the item id
        MarketItem memory item = idToMarketItems[_itemId];
        // To check if the item is on market
        if (item.itemId != _itemId) revert Errors.NotOnMarket();
        // Confirm the market item is not sold
        if (item.isSold) revert Errors.NotForSale();
        // msg sender should be item seller
        if (item.seller != _msgSender()) revert Errors.NotSeller();

        item.price = _newPrice;
        if (_tradeType == TradeType.None && item.tradeType != _tradeType)
            _cancelMultiOffersByItemId(_itemId);
        item.tradeType = _tradeType;
        item.minimum = _minimum;
        idToMarketItems[_itemId] = item;

        emit MarketItemUpdated(_itemId, _newPrice, _minimum, _tradeType);
    }

    function cancelMarketItem(bytes32 _itemId) external override nonReentrant {
        MarketItem memory item = idToMarketItems[_itemId];
        // To check if the item is on market
        if (item.itemId != _itemId) revert Errors.NotOnMarket();
        // Confirm the market item is not sold
        if (item.isSold) revert Errors.NotForSale();
        // msg sender should be item seller
        if (item.seller != _msgSender()) revert Errors.NotSeller();
        delete item;
        idToMarketItems[_itemId] = item;
        if (_openItems.contains(_itemId)) _openItems.remove(_itemId);
        _cancelMultiOffersByItemId(_itemId);

        emit MarketItemCancelled(_itemId);
    }

    function purchaseMarketItem(bytes32 _itemId)
        external
        override
        nonReentrant
    {
        MarketItem memory item = idToMarketItems[_itemId];

        address nftContract = item.nftContract;
        uint256 tokenId = item.tokenId;
        // To check if the item is on market
        if (item.itemId != _itemId) revert Errors.NotOnMarket();
        // Check if the item is for sale
        if (item.isSold) revert Errors.NotForSale();
        // Check if the collection is whitelisted
        if (!collectionManager.isCollectionWhitelisted(nftContract))
            revert Errors.CollectionNotWhitelisted();
        // priceWithFee = price + fee
        uint256 priceWithFee = item.price.mul(_marketFee.add(10000)).div(10000);
        if (
            IERC20(wethContract).allowance(_msgSender(), address(this)) <
            priceWithFee
        ) revert Errors.InsufficientAllowance();

        if (IERC721(nftContract).ownerOf(tokenId) != item.seller)
            revert Errors.NotOwnedBySeller();

        if (IERC721(nftContract).getApproved(tokenId) != address(this))
            revert Errors.TokenNotApproved();

        if (item.seller == _msgSender()) revert Errors.SellerNotAllowedToBuy();
        item.buyer = _msgSender();
        IERC20(wethContract).transferFrom(
            item.buyer,
            _marketFeeRecipient,
            priceWithFee - item.price
        );
        IERC20(wethContract).transferFrom(item.buyer, item.seller, item.price);

        IERC721(nftContract).safeTransferFrom(item.seller, item.buyer, tokenId);

        item.isSold = true;
        idToMarketItems[_itemId] = item;
        _openItems.remove(_itemId);

        uint256[] memory tokensAttached = new uint256[](0);
        _tradeIndexCounter.increment();
        uint256 tradeIndex = _tradeIndexCounter.current();
        releasedTrades[tradeIndex] = Trade(
            _itemId,
            0,
            item.nftContract,
            item.tokenId,
            item.seller,
            item.buyer,
            item.price,
            address(0),
            tokensAttached,
            _marketFee,
            block.timestamp
        );

        emit TradeReleased(
            _itemId,
            0,
            item.nftContract,
            item.tokenId,
            item.seller,
            item.buyer,
            item.price,
            address(0),
            tokensAttached,
            _marketFee,
            block.timestamp
        );
    }

    function makeOffer(
        bytes32 _itemId,
        address _nftContract,
        uint256[] memory _tokensAttached,
        uint256 _amount
    ) external override nonReentrant {
        bytes32 offerId = keccak256(abi.encodePacked(_itemId, _msgSender()));
        if (_openOffers.contains(offerId)) revert Errors.OfferAlreadyExists();
        if (!_openItems.contains(_itemId)) revert Errors.NotForSale();

        MarketItem memory item = idToMarketItems[_itemId];
        if (item.tradeType == TradeType.None) revert Errors.NotForTrade();
        if (!collectionManager.isCollectionWhitelisted(_nftContract))
            revert Errors.CollectionNotWhitelisted();

        if (_amount < item.minimum) revert Errors.LowMinimumPrice();

        if (
            IERC20(wethContract).allowance(_msgSender(), address(this)) <
            _amount
        ) revert Errors.InsufficientAllowance();

        for (uint256 i = 0; i < _tokensAttached.length; i++) {
            if (
                IERC721(_nftContract).ownerOf(_tokensAttached[i]) !=
                _msgSender()
            ) revert Errors.NotTokenOwner();
            if (
                IERC721(_nftContract).getApproved(_tokensAttached[i]) !=
                address(this)
            ) revert Errors.TokenNotApproved();
        }
        idToOffers[offerId] = TradeOffer(
            offerId,
            _itemId,
            _msgSender(),
            _nftContract,
            _tokensAttached,
            _amount
        );
        _openOffers.add(offerId);

        emit TradeOfferCreated(
            offerId,
            _itemId,
            _msgSender(),
            _nftContract,
            _tokensAttached,
            _amount
        );
    }

    function editOffer(
        bytes32 _offerId,
        uint256 _amount,
        address _nftContract,
        uint256[] memory _tokensAttached
    ) external override nonReentrant {
        if (!_openOffers.contains(_offerId)) revert Errors.NotActiveOffer();
        TradeOffer memory offer = idToOffers[_offerId];
        if (offer.offerMaker != _msgSender()) revert Errors.NotOfferMaker();

        MarketItem memory item = idToMarketItems[offer.marketItemId];
        if (_amount < item.minimum) revert Errors.LowMinimumPrice();
        if (
            IERC20(wethContract).allowance(_msgSender(), address(this)) <
            _amount
        ) revert Errors.InsufficientAllowance();

        if (!collectionManager.isCollectionWhitelisted(_nftContract))
            revert Errors.CollectionNotWhitelisted();
        for (uint256 i = 0; i < _tokensAttached.length; i++) {
            if (
                IERC721(_nftContract).ownerOf(_tokensAttached[i]) !=
                _msgSender()
            ) revert Errors.NotTokenOwner();
            if (
                IERC721(_nftContract).getApproved(_tokensAttached[i]) !=
                address(this)
            ) revert Errors.TokenNotApproved();
        }

        offer.amount = _amount;
        offer.nftContract = _nftContract;
        offer.tokensAttached = _tokensAttached;
        idToOffers[_offerId] = offer;

        emit TradeOfferUpdated(
            offer.offerId,
            offer.nftContract,
            offer.tokensAttached,
            offer.amount
        );
    }

    function fulfillOffer(bytes32 _offerId) external override nonReentrant {
        if (!_openOffers.contains(_offerId)) revert Errors.NotActiveOffer();

        TradeOffer memory offer = idToOffers[_offerId];
        MarketItem memory item = idToMarketItems[offer.marketItemId];
        if (!_openItems.contains(item.itemId)) {
            _openOffers.remove(_offerId);
            revert Errors.NotForSale();
        }

        if (item.seller != _msgSender()) revert Errors.NotSeller();

        if (IERC721(item.nftContract).ownerOf(item.tokenId) != item.seller) {
            _openOffers.remove(_offerId);
            revert Errors.NotOwnedBySeller();
        }

        if (
            IERC721(item.nftContract).getApproved(item.tokenId) != address(this)
        ) revert Errors.TokenNotApproved();

        uint256 amountWithFee = offer.amount.mul(_marketFee.add(10000)).div(
            10000
        );
        if (
            IERC20(wethContract).allowance(offer.offerMaker, address(this)) <
            amountWithFee
        ) revert Errors.InsufficientAllowance();

        for (uint256 i = 0; i < offer.tokensAttached.length; i++) {
            if (
                IERC721(offer.nftContract).ownerOf(offer.tokensAttached[i]) !=
                offer.offerMaker
            ) revert Errors.NotTokenOwner();
            if (
                IERC721(offer.nftContract).getApproved(
                    offer.tokensAttached[i]
                ) != address(this)
            ) revert Errors.TokenNotApproved();
        }
        // transfer offered tokens to the owner(seller) of the target token
        for (uint256 i = 0; i < offer.tokensAttached.length; i++) {
            IERC721(offer.nftContract).transferFrom(
                offer.offerMaker,
                item.seller,
                offer.tokensAttached[i]
            );
        }
        // transfer market fee to the fee recipient
        IERC20(wethContract).transferFrom(
            offer.offerMaker,
            _marketFeeRecipient,
            amountWithFee - offer.amount
        );
        // transfer WETH to the seller
        IERC20(wethContract).transferFrom(
            offer.offerMaker,
            item.seller,
            offer.amount
        );
        // transfer the target chicken to the offer maker
        IERC721(item.nftContract).transferFrom(
            item.seller,
            offer.offerMaker,
            item.tokenId
        );
        item.buyer = offer.offerMaker;
        item.isSold = true;
        idToMarketItems[item.itemId] = item;
        _openItems.remove(offer.marketItemId);
        _openOffers.remove(_offerId);
        _cancelMultiOffersByItemId(item.itemId);

        _tradeIndexCounter.increment();
        uint256 tradeIndex = _tradeIndexCounter.current();
        releasedTrades[tradeIndex] = Trade(
            item.itemId,
            offer.offerId,
            item.nftContract,
            item.tokenId,
            item.seller,
            offer.offerMaker,
            offer.amount,
            offer.nftContract,
            offer.tokensAttached,
            getMarketFee(),
            block.timestamp
        );

        emit TradeReleased(
            item.itemId,
            offer.offerId,
            item.nftContract,
            item.tokenId,
            item.seller,
            offer.offerMaker,
            offer.amount,
            offer.nftContract,
            offer.tokensAttached,
            getMarketFee(),
            block.timestamp
        );
    }

    function cancelOrDeclineOffer(bytes32 _offerId)
        external
        override
        nonReentrant
    {
        if (!_openOffers.contains(_offerId)) revert Errors.NotActiveOffer();

        TradeOffer memory offer = idToOffers[_offerId];
        MarketItem memory item = idToMarketItems[offer.marketItemId];
        if (offer.offerMaker != _msgSender() && item.seller != _msgSender())
            revert Errors.NotOfferMakerOrReceiver();

        _openOffers.remove(_offerId);
        if (_msgSender() == offer.offerMaker) emit TradeOfferCanceled(_offerId);
        else if (_msgSender() == item.seller) emit TradeOfferDeclined(_offerId);
    }

    function _cancelMultiOffersByItemId(bytes32 _itemId) internal nonReentrant {
        uint256 total = _openOffers.length();

        uint256 offerCount = 0;
        TradeOffer memory offer;
        for (uint256 i = 0; i < total; i++) {
            offer = idToOffers[_openOffers.at(i)];
            if (offer.marketItemId == _itemId) offerCount++;
        }

        uint256 index = 0;
        bytes32[] memory results = new bytes32[](offerCount);
        while (index < _openOffers.length()) {
            offer = idToOffers[_openOffers.at(index)];
            if (offer.marketItemId == _itemId) {
                results[index] = offer.offerId;
                _openOffers.remove(offer.offerId);
                continue;
            }
            index++;
        }

        emit MultiTradeOffersDeclined(results);
    }

    function fetchMarketItems()
        external
        view
        override
        returns (MarketItem[] memory)
    {
        MarketItem[] memory results = new MarketItem[](_openItems.length());
        for (uint256 i = 0; i < _openItems.length(); i++) {
            results[i] = idToMarketItems[_openItems.at(i)];
        }
        return results;
    }

    function fetchMarketItemsByOwner(address _owner)
        external
        view
        override
        returns (MarketItem[] memory)
    {
        uint256 total = _openItems.length();

        uint256 itemCount = 0;
        MarketItem memory item;
        for (uint256 i = 0; i < total; i++) {
            item = idToMarketItems[_openItems.at(i)];
            if (item.seller == _owner) itemCount++;
        }

        uint256 index = 0;
        MarketItem[] memory results = new MarketItem[](itemCount);
        for (uint256 i = 0; i < total; i++) {
            item = idToMarketItems[_openItems.at(i)];
            if (item.seller == _owner) {
                results[index] = item;
                index++;
            }
        }
        return results;
    }

    function fetchMarketItemById(bytes32 _itemId)
        external
        view
        override
        returns (MarketItem memory)
    {
        return idToMarketItems[_itemId];
    }

    function fetchReleasedTrades()
        external
        view
        override
        returns (Trade[] memory)
    {
        uint256 count = _tradeIndexCounter.current();
        Trade[] memory results = new Trade[](count);
        for (uint256 i = 0; i < count; i++) {
            results[i] = releasedTrades[i + 1];
        }
        return results;
    }

    function fetchReleasedTradeByIndex(uint256 index)
        external
        view
        override
        returns (Trade memory)
    {
        return releasedTrades[index];
    }

    function fetchTradeOffers()
        external
        view
        override
        returns (TradeOffer[] memory)
    {
        TradeOffer[] memory results = new TradeOffer[](_openOffers.length());
        for (uint256 i = 0; i < _openOffers.length(); i++) {
            results[i] = idToOffers[_openOffers.at(i)];
        }
        return results;
    }

    function fetchTradeOffersByMaker(address _maker)
        external
        view
        override
        returns (TradeOffer[] memory)
    {
        uint256 total = _openOffers.length();

        uint256 offerCount = 0;
        TradeOffer memory offer;
        for (uint256 i = 0; i < total; i++) {
            offer = idToOffers[_openOffers.at(i)];
            if (offer.offerMaker == _maker) offerCount++;
        }

        uint256 index = 0;
        TradeOffer[] memory results = new TradeOffer[](offerCount);
        for (uint256 i = 0; i < total; i++) {
            offer = idToOffers[_openOffers.at(i)];
            if (offer.offerMaker == _maker) {
                results[index] = offer;
                index++;
            }
        }
        return results;
    }

    function fetchTradeOffersByRecipient(address _recipient)
        external
        view
        override
        returns (TradeOffer[] memory)
    {
        uint256 total = _openOffers.length();

        uint256 offerCount = 0;
        TradeOffer memory offer;
        MarketItem memory item;
        for (uint256 i = 0; i < total; i++) {
            offer = idToOffers[_openOffers.at(i)];
            item = idToMarketItems[offer.marketItemId];
            if (item.seller == _recipient) offerCount++;
        }

        uint256 index = 0;
        TradeOffer[] memory results = new TradeOffer[](offerCount);
        for (uint256 i = 0; i < total; i++) {
            offer = idToOffers[_openOffers.at(i)];
            item = idToMarketItems[offer.marketItemId];
            if (item.seller == _recipient) {
                results[index] = offer;
                index++;
            }
        }
        return results;
    }

    function fetchTradeOfferById(bytes32 _offerId)
        external
        view
        override
        returns (TradeOffer memory)
    {
        return idToOffers[_offerId];
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import "../Interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICollectionManager {
    function addCollection(address _nftContract) external;

    function removeCollection(address _nftContract) external;

    function isCollectionWhitelisted(address _nftContract)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TradeType, MarketItem, Trade, TradeOffer} from "../Libraries/Structs.sol";

interface IExchange {
    event MarketItemCreated(
        bytes32 itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        TradeType tradeType,
        uint256 minimum,
        bool isSold
    );

    event MarketItemUpdated(
        bytes32 indexed itemId,
        uint256 price,
        uint256 minimum,
        TradeType tradeType
    );

    event MarketItemCancelled(bytes32 itemId);

    event TradeReleased(
        bytes32 marketItemId,
        bytes32 tradeOfferId,
        address nftContract,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price,
        address offeredNftContract,
        uint256[] tokensAttached,
        uint256 marketFee,
        uint256 timestamp
    );


    event TradeOfferCreated(
        bytes32 indexed offerId,
        bytes32 marketItemId,
        address offerMaker,
        address nftContract,
        uint256[] tokensAttached,
        uint256 amount
    );

    event TradeOfferUpdated(
        bytes32 indexed offerId,
        address nftContract,
        uint256[] tokensAttached,
        uint256 amount
    );

    event TradeOfferCanceled(bytes32 offerId);
    event TradeOfferDeclined(bytes32 offerId);

    event MultiTradeOffersDeclined(bytes32[] offerIds);

    function setFloorPrice(uint256 _floorPrice) external;

    function getMarketFee() external view returns (uint256);

    function setMarketFee(uint256 _feeAmount) external;

    function setMarketFeeRecipient(address _recipient) external;

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 minimum,
        TradeType tradeType
    ) external;

    function editMarketItem(
        bytes32 _itemId,
        uint256 _newPrice,
        uint256 _minimum,
        TradeType _tradeType
    ) external;

    function cancelMarketItem(bytes32 _itemId) external;

    function purchaseMarketItem(bytes32 _itemId) external;

    function makeOffer(
        bytes32 _itemId,
        address _nftContract,
        uint256[] memory _tokensAttached,
        uint256 _amount
    ) external;

    function editOffer(
        bytes32 _offerId,
        uint256 _amount,
        address _nftContract,
        uint256[] memory _tokensAttached
    ) external;

    function cancelOrDeclineOffer(bytes32 _offerId) external;

    function fulfillOffer(bytes32 _offerId) external;

    function fetchMarketItems() external view returns (MarketItem[] memory);

    function fetchMarketItemsByOwner(address _owner)
        external
        view
        returns (MarketItem[] memory);

    function fetchMarketItemById(bytes32 _itemId)
        external
        view
        returns (MarketItem memory);

    function fetchReleasedTrades() external view returns (Trade[] memory);

    function fetchReleasedTradeByIndex(uint256 index)
        external
        view
        returns (Trade memory);

    function fetchTradeOffers() external view returns (TradeOffer[] memory);

    function fetchTradeOffersByMaker(address _maker)
        external
        view
        returns (TradeOffer[] memory);

    function fetchTradeOffersByRecipient(address _recipient)
        external
        view
        returns (TradeOffer[] memory);

    function fetchTradeOfferById(bytes32 _offerId)
        external
        view
        returns (TradeOffer memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Errors{
    error LowFloorPrice();
    error LowMinimumPrice();
    error InsufficientFund();
    error NotTokenOwner();
    error TokenNotApproved();
    error NotOnMarket();
    error NotForSale();
    error NotSeller();
    error InsufficientAllowance();
    error NotOwnedBySeller();
    error SellerNotAllowedToBuy();
    error NotExistOffer();
    error NotActiveOffer();
    error NotOfferMakerOrReceiver();
    error NotOfferMaker();
    error CollectionExists();
    error CollectionNotExists();
    error CollectionNotWhitelisted();
    error ItemAlreadyExists();
    error OfferAlreadyExists();
    error NotForTrade();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TradeType} from "./Constants.sol";

struct MarketItem {
    bytes32 itemId;
    address nftContract;
    uint256 tokenId;
    address seller;
    address buyer;
    uint256 price;
    TradeType tradeType;
    uint256 minimum;
    bool isSold;
}

struct Trade {
    bytes32 marketItemId;
    bytes32 tradeOfferId;
    address nftContract;
    uint256 tokenId;
    address seller;
    address buyer;
    uint256 price;
    address offeredNftContract;
    uint256[] tokensAttached;
    uint256 marketFee;
    uint256 timestamp;
}

struct TradeOffer {
    bytes32 offerId;
    bytes32 marketItemId;
    address offerMaker;
    address nftContract;
    uint256[] tokensAttached;
    uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum TradeType {
    None,
    Any,
    Preference
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

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

    function versionRecipient() external virtual view returns (string memory);
}