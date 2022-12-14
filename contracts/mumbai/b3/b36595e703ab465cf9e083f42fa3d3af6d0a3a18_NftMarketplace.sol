// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '../interfaces/IBEP20.sol';

contract NftMarketplace is
	AccessControlUpgradeable,
	ReentrancyGuardUpgradeable,
	ERC721HolderUpgradeable,
	ERC1155ReceiverUpgradeable
{
	using Counters for Counters.Counter;

	/*
   =======================================================================
   ======================== Structures ===================================
   =======================================================================
 */
	enum OrderType {
		SALE,
		AUCTION
	}

	enum ListingStatus {
		CLOSED,
		ACTIVE,
		CANCELED
	}

	enum TokenType {
		ERC721,
		ERC1155
	}

	enum OfferStatus {
		ACCEPTED,
		ACTIVE,
		CANCELED,
		REJECTED,
		CLAIMED
	}

	struct AuctionData {
		uint256 initialPrice; //base price for bid
		uint256 duration;
		uint256 winningBidId;
		uint256[] bidIds;
	}

	struct SaleData {
		uint256 sellingPrice;
	}

	struct BaseOrder {
		uint8 listingType; // 0 = SALE,  1 = AUCTION
		uint8 tokenType; // 0 = ERC721. 1 = ERC1155
		address nftAddress;
	}

	struct TimeStamps {
		uint256 buyTimestamp; // here, if buyTimestamp is zero it means nft is available to purchase
		uint256 cancelTimeStamp;
		uint256 listingTimestamp;
	}

	struct ListingBase {
		address seller;
		address buyer;
		uint256 tokenId;
		uint256 totalCopies;
		uint256 remainingCopies;
		address currency; // Token address in which seller will get paid
		uint8 status; // Active = 1, Closed = 0, Canceled = 2
	}

	struct Order {
		BaseOrder baseOrder;
		ListingBase listingBase;
		AuctionData auctionData;
		SaleData saleData;
		TimeStamps timestamps;
	}

	struct Bid {
		uint256 listingId;
		address bidderAddress;
		uint256 bidAmount;
		uint256 timestamp;
	}

	struct NFTOffer {
		address nftAddress;
		uint8 tokenType;
		uint256 nftId;
		address nftHolder;
		uint256 price;
		address currency;
		address requestor;
		uint256 status; //  0-accepted 1-active, 2-canceled, 3-rejected
	}

	/*
   =======================================================================
   ======================== Private Variables ============================
   =======================================================================
 */
	Counters.Counter internal listingIdCounter;
	Counters.Counter internal bidIdCounter;
	Counters.Counter internal offerCounter;

	/*
   =======================================================================
   ======================== Public Variables ============================
   =======================================================================
 */
	uint256 public constant MAX_SERVICE_FEE = 250; // 25%

	/// @notice platform fee
	uint256 public serviceFee;

	/// @notice service fee receiver
	address public feeReceiver;

	/// @notice minimum duration for auction period
	uint256 public minDuration;

	/// @notice listingId -> Order
	mapping(uint256 => Order) public NftListings;

	/// @notice userAddress -> user`s listing ids
	mapping(address => uint256[]) public userListingIds;

	/// @notice bidId -> Bid
	mapping(uint256 => Bid) public bid;

	/// @notice BidderAddress -> bidIds
	mapping(address => uint256[]) public userBidIds;

	/// @notice tokenAddress => supported or not
	mapping(address => bool) public supportedTokens;

	/// @notice offerId => NFTOffer
	mapping(uint256 => NFTOffer) public offers;

	/// @notice nftToken => tokenType => tokenHolder => nftId => offerIds
	mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256[]))))
		public nftOffersList;

	/// @notice nftToken => tokenType => tokenHolder => nftId => total offers
	mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256))))
		public nftOfferCount;

	/*
   =======================================================================
   ======================== Events =======================================
   =======================================================================
 */

	event NftListing(
		address indexed nftAddress,
		uint8 indexed listingType,
		uint8 indexed tokenType,
		address seller,
		uint256 listingId
	);

	event CancelListing(
		address indexed nftAddress,
		uint8 indexed tokenType,
		uint256 indexed listingId
	);

	event BuyListedNFT(
		address indexed nftAddress,
		uint8 indexed tokenType,
		address indexed buyer,
		uint256 listingId,
		uint256 tokenId
	);

	event PlaceBid(
		address indexed nftAddress,
		uint8 indexed tokenType,
		uint256 indexed listingId,
		uint256 bidId
	);

	event MakeOffer(
		address indexed nftAddress,
		uint8 indexed tokenType,
		uint256 indexed offerId,
		uint256 timestamp
	);

	event AcceptOffer(
		address indexed nftAddress,
		uint8 indexed tokenType,
		uint256 indexed offerId,
		address acceptor,
		uint256 timestamp
	);

	event CancelOffer(address indexed nftAddress, uint8 indexed tokenType, uint256 indexed offerId);

	event RejectOffer(
		address indexed nftAddress,
		uint8 indexed tokenType,
		uint256 indexed offerId,
		address rejecter
	);

	event UpdateBid(uint256 listingId, uint256 bidId, address bidder, uint256 oldBid, uint256 newBid);

	/*
   =======================================================================
   ======================== Constructor/Initializer ======================
   =======================================================================
 */

	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 */
	function initialize(address _feeReceiver, uint256 _serviceFee) public virtual initializer {
		assert(_feeReceiver != address(0));
		__AccessControl_init();
		__ReentrancyGuard_init();
		__ERC721Holder_init();
		__ERC1155Receiver_init();

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		feeReceiver = _feeReceiver;
		serviceFee = _serviceFee;
		minDuration = 1 days;
	}

	/*
   =======================================================================
   ======================== Modifiers ====================================
   =======================================================================
 */
	modifier onlyAdmin() {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Market: ONLY_ADMIN_CAN_CALL');
		_;
	}

	modifier onlySupportedTokens(address _tokenAddress) {
		require(supportedTokens[_tokenAddress], 'Market: UNSUPPORTED_TOKEN');
		_;
	}

	modifier onlyValidListingId(uint256 _listingId) {
		require(
			_listingId > 0 && _listingId <= listingIdCounter.current(),
			'Market: INVALID_LISTING_ID'
		);
		_;
	}

	modifier onlyValidOfferId(uint256 _offerId) {
		require(_offerId > 0 && _offerId <= offerCounter.current(), 'Market: INVALID_OFFER_ID');
		_;
	}

	modifier onlyValidTokenType(uint8 _tokenType) {
		require(
			_tokenType == uint8(TokenType.ERC721) || _tokenType == uint8(TokenType.ERC1155),
			'Market: INVALID_TOKEN_TYPE'
		);
		_;
	}

	modifier onlyActiveListing(uint256 _listingId) {
		require(
			NftListings[_listingId].listingBase.status == uint8(ListingStatus.ACTIVE),
			'Market: INACTIVE_LISTING'
		);
		_;
	}

	modifier onlyValidBidId(uint256 _bidId) {
		require(_bidId > 0 && _bidId <= bidIdCounter.current(), 'Market: INVALID_BID_ID');
		_;
	}

	modifier onlyValidNFTAddress(uint8 _tokenType, address _nftAddress) {
		if (_tokenType == uint8(TokenType.ERC721)) {
			require(
				IERC721Upgradeable(_nftAddress).supportsInterface(bytes4(0x80ac58cd)),
				'Market: INVALID_ERC721_TOKEN'
			);
		} else {
			require(
				IERC1155(_nftAddress).supportsInterface(bytes4(0xd9b67a26)),
				'Market: INVALID_ERC1155_TOKEN'
			);
		}
		_;
	}

	/*
   =======================================================================
   ======================== Public Methods ===============================
   =======================================================================
 */
	/**
	 * @notice This method allows the NFT owner/seller to sell his nft at a fix price. owner needs to approve his nft to this contract first. anyone with nft can call this method.
	 * @param _nftAddress 	- indicates the ERC721/ERC1155 NFT token address
	 * @param _tokenType		- indicates the NFT token type. 0-ERC721, 1-ERC1155
	 * @param _tokenId 			- indicates the nft id which user wants to sell
	 * @param _totalCopies	- indicates the no of copies of NFTs to sell. should be 1 for ERC721 NFT.
	 * @param _nftPrice 		- indicates the fix price for the NFT at which user wants to sell his NFT.
	 * @param _currency 		- indicates the the ERC20/BEP20 token address in which nft seller/owner wants to get paid in
	 * @return listingId 		- indicates the new sale id in which owners nft is sold
	 */
	function sellNFT(
		address _nftAddress,
		uint8 _tokenType, // 0 - erc721 1- erc1155
		uint256 _tokenId,
		uint256 _totalCopies,
		uint256 _nftPrice,
		address _currency
	)
		external
		virtual
		onlyValidTokenType(_tokenType)
		onlyValidNFTAddress(_tokenType, _nftAddress)
		onlySupportedTokens(_currency)
		nonReentrant
		returns (uint256 listingId)
	{
		require(_nftPrice > 0, 'Market: INVALID_NFT_PRICE');

		//get NFT tokens from seller
		require(
			_tokenType == uint8(TokenType.ERC721) ? _totalCopies == 1 : _totalCopies > 0,
			'Market: INVALID_TOTAL_COPIES'
		);

		_transferNfts(_nftAddress, _tokenType, msg.sender, address(this), _tokenId, _totalCopies);

		listingId = _ListNFT(
			_nftAddress,
			0,
			_tokenType,
			_tokenId,
			_totalCopies,
			_currency,
			_nftPrice,
			0
		);
	}

	/**
	 * @notice This method allows anyone with NFT to put his NFT in Auction.
	 * @param _nftAddress 		- indicates the ERC721/ERC1155 NFT token address
	 * @param _tokenType			- indicates the NFT token type. 0-ERC721, 1-ERC1155
	 * @param _tokenId				- indicates the NFT id for which user wants to creat auction.
	 * @param _initialPrice 	- indicates the startting price for the auction. all the bids should be greater than the initial price.
	 * @param _currency 			- indicates the the ERC20/BEP20 token address in which nft seller/owner wants to get paid in
	 * @param _duration 			- indicates the duration after which auction will get closed.
	 * @return listingId 			- indicates the auctionId in which owner puts his nft for sale.
	 */
	function createNFTAuction(
		address _nftAddress,
		uint8 _tokenType,
		uint256 _tokenId,
		uint256 _initialPrice,
		address _currency,
		uint256 _duration
	)
		external
		virtual
		onlyValidTokenType(_tokenType)
		onlyValidNFTAddress(_tokenType, _nftAddress)
		onlySupportedTokens(_currency)
		nonReentrant
		returns (uint256 listingId)
	{
		require(_initialPrice > 0, 'Market: INVALID_INITIAL_NFT_PRICE');
		require(_duration >= minDuration, 'Market: INVALID_DURATION');

		//get nft copy from sender and put it in auction
		_transferNfts(_nftAddress, _tokenType, msg.sender, address(this), _tokenId, 1);

		listingId = _ListNFT(
			_nftAddress,
			1,
			_tokenType,
			_tokenId,
			1,
			_currency,
			_initialPrice,
			_duration
		);
	}

	/**
	 * @notice This method allows NFT sale creator to cancel the sale and claim back the nft token
	 */
	function cancelListingAndClaimToken(uint256 _listingId)
		external
		virtual
		onlyValidListingId(_listingId)
		onlyActiveListing(_listingId)
		nonReentrant
	{
		Order memory _order = NftListings[_listingId];
		ListingBase memory listinBase = _order.listingBase;
		BaseOrder memory baseOrder = _order.baseOrder;

		require(listinBase.seller == msg.sender, 'Market: ONLY_SELLER_CAN_CANCEL');

		// TODO: do we need this check?
		if (baseOrder.listingType == uint8(OrderType.AUCTION)) {
			require(_order.auctionData.bidIds.length == 0, 'Market: AUCTION_WITH_NON_ZERO_BIDS');
		}

		_transferNfts(
			baseOrder.nftAddress,
			baseOrder.tokenType,
			address(this),
			msg.sender,
			listinBase.tokenId,
			listinBase.remainingCopies
		);

		NftListings[_listingId].timestamps.cancelTimeStamp = block.timestamp;
		NftListings[_listingId].listingBase.status = uint8(ListingStatus.CANCELED);

		emit CancelListing(baseOrder.nftAddress, baseOrder.tokenType, _listingId);
	}

	/**
	 * @notice This method allows auction creator to update the auction starting price and extend the auction only if auction is ended with no bids.
	 * @param _listingId 			- indicates the id of auction whose details needs to update
	 * @param _newPrice 			- indicates the new starting price for the auction.
	 * @param _timeExtension 	- indicates the extended time for the auction. it can be zero if user only wants to update the auction price.
	 */
	function updateAuction(
		uint256 _listingId,
		uint256 _newPrice,
		uint256 _timeExtension
	) external virtual onlyValidListingId(_listingId) onlyActiveListing(_listingId) {
		Order memory _order = NftListings[_listingId];
		AuctionData memory auctionData = _order.auctionData;

		require(_order.baseOrder.listingType == uint8(OrderType.AUCTION), 'Market: NOT_AN_AUCTION');
		require(msg.sender == _order.listingBase.seller, 'Market:ONLY_SELLER_CAN_UPDATE');
		require(
			_newPrice > 0 && _newPrice != auctionData.initialPrice,
			'Market: INVALID_INITIAL_PRICE'
		);

		require(auctionData.bidIds.length == 0, 'Market: AUCTION_WITH_NON_ZERO_BIDS');

		NftListings[_listingId].auctionData.duration = auctionData.duration + _timeExtension;
		NftListings[_listingId].auctionData.initialPrice = _newPrice;
	}

	/**
	 * @notice This method allows sale creator to update the sale starting price and extend the auction only if auction is ended with no bids.
	 * @param _listingId 	- indicates the id of sale whose details needs to update
	 * @param _newPrice 	- indicates the new starting price for the auction.
	 */
	function updateSale(uint256 _listingId, uint256 _newPrice)
		external
		virtual
		onlyValidListingId(_listingId)
		onlyActiveListing(_listingId)
	{
		Order memory _order = NftListings[_listingId];

		require(_order.baseOrder.listingType == uint8(OrderType.SALE), 'Market: NOT_A_SALE');
		require(msg.sender == _order.listingBase.seller, 'Market:ONLY_SELLER_CAN_UPDATE');
		require(
			_newPrice > 0 && _newPrice != _order.saleData.sellingPrice,
			'Market: INVALID_SELLING_PRICE'
		);

		NftListings[_listingId].saleData.sellingPrice = _newPrice;
	}

	/**
	 * @notice This method allows auction creator to move his NFT in sale only if auction has zero bids.
	 * @param _listingId 			- indicates the auction id
	 * @param _sellingPrice 	- indicates the fix selling price for the nft
	 * @return saleId 				- indicates the sale id in which nft will be available for sale.
	 */
	function moveNftInSale(uint256 _listingId, uint256 _sellingPrice)
		external
		virtual
		onlyValidListingId(_listingId)
		onlyActiveListing(_listingId)
		returns (uint256 saleId)
	{
		require(_sellingPrice > 0, 'Market: INVALID_SELLING_PRICE');

		Order memory _order = NftListings[_listingId];
		BaseOrder memory baseOrder = _order.baseOrder;
		ListingBase memory listingBase = _order.listingBase;

		require(baseOrder.listingType == uint8(OrderType.AUCTION), 'Market: NOT_AN_AUCTION');
		require(msg.sender == listingBase.seller, 'Market: CALLER_NOT_THE_AUCTION_CREATOR');
		require(_order.auctionData.bidIds.length == 0, 'Market: CANNOT_UPDATE_AUCTION');

		//cancel the auction
		NftListings[_listingId].listingBase.status = uint8(ListingStatus.CANCELED);

		saleId = _ListNFT(
			baseOrder.nftAddress,
			0,
			baseOrder.tokenType,
			listingBase.tokenId,
			listingBase.totalCopies,
			listingBase.currency,
			_sellingPrice,
			0
		);
	}

	/**
	 * @notice This method allows anyone with accepted tokens to purchase the NFT from the particular sale.
	 * @notice user needs to approve his ERC20/BEP20 tokens to this contract.
	 * @param _listingId  - indicates the saleId from which buyer buys required NFT at specified price.
	 */
	function buyNFT(uint256 _listingId)
		external
		virtual
		onlyValidListingId(_listingId)
		onlyActiveListing(_listingId)
		nonReentrant
	{
		Order memory _sale = NftListings[_listingId];
		BaseOrder memory baseOrder = _sale.baseOrder;
		ListingBase memory listingBase = _sale.listingBase;
		require(baseOrder.listingType == uint8(OrderType.SALE), 'Market: NOT_A_SALE');
		require(listingBase.seller != msg.sender, 'Market: INVALID_BUYER');

		_transferTokens(
			msg.sender,
			listingBase.seller,
			listingBase.currency,
			_sale.saleData.sellingPrice
		);

		_transferNfts(
			baseOrder.nftAddress,
			baseOrder.tokenType,
			address(this),
			msg.sender,
			listingBase.tokenId,
			1
		);

		Order storage _order = NftListings[_listingId];
		ListingBase storage base = _order.listingBase;
		base.buyer = msg.sender; // TODO- here in case of ERC1155 latest buyer` address will be set
		_order.timestamps.buyTimestamp = block.timestamp; // TODO - incase of ERC1155 latest selltimestamp will be set
		base.remainingCopies -= 1;

		if (base.remainingCopies == 0) {
			base.status = uint8(ListingStatus.CLOSED);
		}

		emit BuyListedNFT(
			baseOrder.nftAddress,
			baseOrder.tokenType,
			msg.sender,
			_listingId,
			listingBase.tokenId
		);
	}

	/**
	 * @notice This method allows anyone with accepted token to place the bid on auction to buy NFT. bidder need to approve his accepted payment tokens.
	 * @param _listingId 	- indicates the auctionId for which user wants place bid.
	 * @param _bidAmount 	- indicates the bidAmount which must be greater than the existing winning bid amount or startingPrice in case of first bid.
	 */
	function placeBid(uint256 _listingId, uint256 _bidAmount)
		external
		virtual
		onlyValidListingId(_listingId)
		onlyActiveListing(_listingId)
		returns (uint256 bidId)
	{
		Order memory _auction = NftListings[_listingId];
		ListingBase memory listingBase = _auction.listingBase;
		AuctionData memory auctionData = _auction.auctionData;

		require(_auction.baseOrder.listingType == uint256(OrderType.AUCTION), 'Market: NOT_AN_AUCTION');
		require(listingBase.seller != msg.sender, 'Market: OWNER_CANNOT_PLACE_BID');
		require(
			block.timestamp >= _auction.timestamps.listingTimestamp,
			'Market: CANNOT_BID_BEFORE_AUCTION_STARTS'
		);
		require(
			block.timestamp <= (_auction.timestamps.listingTimestamp + auctionData.duration),
			'Market: CANNOT_BID_AFTER_AUCTION_ENDS'
		);
		require(_bidAmount >= auctionData.initialPrice, 'Market: INVALID_BID_AMOUNT');
		require(
			IBEP20(listingBase.currency).allowance(msg.sender, address(this)) >= _bidAmount,
			'Market: INSUFFICIENT_ALLOWANCE'
		);

		//place bid
		bidIdCounter.increment();
		bidId = bidIdCounter.current();

		bid[bidId] = Bid(_listingId, msg.sender, _bidAmount, block.timestamp);
		NftListings[_listingId].auctionData.bidIds.push(bidId);

		userBidIds[msg.sender].push(bidId);

		emit PlaceBid(_auction.baseOrder.nftAddress, _auction.baseOrder.tokenType, _listingId, bidId);
	}

	/**
	 * @notice This method allows bidder to update the bid amount
	 * @param _bidId 				- indicates the id of bid which to update
	 * @param _newBidAmount - indicates new bid amount
	 */
	function updateBid(uint256 _bidId, uint256 _newBidAmount)
		external
		virtual
		onlyValidBidId(_bidId)
	{
		Bid memory _bid = bid[_bidId];
		Order memory order = NftListings[_bid.listingId];
		require(_bid.bidderAddress == msg.sender, 'Market: INVALID_UPDATOR');
		require(_newBidAmount >= order.auctionData.initialPrice, 'Market: INVALID_BID_AMOUNT');
		require(
			IBEP20(order.listingBase.currency).allowance(msg.sender, address(this)) >= _newBidAmount,
			'Market: INSUFFICIENT_ALLOWANCE'
		);
		require(order.listingBase.status == uint8(ListingStatus.ACTIVE), 'Market: INVACTIVE_LISTING');

		emit UpdateBid(_bid.listingId, _bidId, _bid.bidderAddress, _bid.bidAmount, _newBidAmount);

		bid[_bidId].bidAmount = _newBidAmount;
	}

	/**
	 * @notice This method allows auction creator to select a bid and transfer nft to selected bidder.
	 * @param _listingId 	- indicates the auctionId which is to be resolve
	 * @param _bidId			- indicates the bid id which auction creator wants to accept.
	 */
	function resolveAuction(uint256 _listingId, uint256 _bidId)
		external
		virtual
		onlyValidListingId(_listingId)
		onlyActiveListing(_listingId)
		onlyValidBidId(_bidId)
		nonReentrant
	{
		Order memory _auction = NftListings[_listingId];
		Bid memory _bid = bid[_bidId];
		ListingBase memory listingBase = _auction.listingBase;
		AuctionData memory auctionData = _auction.auctionData;

		require(_auction.baseOrder.listingType == uint256(OrderType.AUCTION), 'Market: NOT_AN_AUCTION');
		require(listingBase.seller == msg.sender, 'Market: INVALID_RESOLVER');

		// TODO - should we keep this check?
		require(
			block.timestamp > (_auction.timestamps.listingTimestamp + auctionData.duration),
			'Market: CANNOT_RESOLVE_DURING_AUCTION'
		);
		require(_bid.listingId == _listingId, 'Market: INVALID_BID');

		_transferTokens(_bid.bidderAddress, listingBase.seller, listingBase.currency, _bid.bidAmount);

		_transferNfts(
			_auction.baseOrder.nftAddress,
			_auction.baseOrder.tokenType,
			address(this),
			_bid.bidderAddress,
			listingBase.tokenId,
			1
		);

		//close auction
		NftListings[_listingId].listingBase.status = uint8(ListingStatus.CLOSED);
		NftListings[_listingId].timestamps.buyTimestamp = block.timestamp;
		NftListings[_listingId].auctionData.winningBidId = _bidId;

		emit BuyListedNFT(
			_auction.baseOrder.nftAddress,
			_auction.baseOrder.tokenType,
			_bid.bidderAddress,
			_listingId,
			listingBase.tokenId
		);
	}

	/**
	 * @notice This method allows any user to request for NFT from nft owner
	 * @param _nftAddress - indicates the ERC721/ERC1155 NFT token address
	 * @param _tokenType	- indicates the NFT token type. 0-ERC721, 1-ERC1155
	 * @param _nftHolder	-	indicates the nft holder address to which user makes the offer
	 * @param _nftId 			- indicates the erc721 nft token id which user wants to purchase
	 * @param _price 			- indicates the offer amount
	 * @param _currency		- indicates the BEP20/ERC20 token address in which user will pay offer amount
	 * @return offerId 		- indicates the newly generated offerId
	 */
	function makeOffer(
		address _nftAddress,
		uint8 _tokenType,
		address _nftHolder,
		uint256 _nftId,
		uint256 _price,
		address _currency
	)
		external
		onlyValidTokenType(_tokenType)
		onlyValidNFTAddress(_tokenType, _nftAddress)
		onlySupportedTokens(_currency)
		returns (uint256 offerId)
	{
		require(_price > 0, 'Market: INLVALID_PRICE');
		require(
			IBEP20(_currency).allowance(msg.sender, address(this)) >= _price,
			'Market: INSUFFICIENT_ALLOWANCE'
		);

		if (_tokenType == uint8(TokenType.ERC721)) {
			require(
				IERC721Upgradeable(_nftAddress).ownerOf(_nftId) == _nftHolder,
				'Market: INVALID_USER_FOR_TOKEN'
			);
			require(
				IERC721Upgradeable(_nftAddress).ownerOf(_nftId) != msg.sender,
				'Market: INVALID_REQUESTOR'
			);
		} else {
			require(
				IERC1155(_nftAddress).balanceOf(_nftHolder, _nftId) > 0,
				'Market: INSUFFICIENT_TOKENS'
			);
		}

		offerCounter.increment();
		offerId = offerCounter.current();

		//add active offer
		offers[offerId] = NFTOffer(
			_nftAddress,
			_tokenType,
			_nftId,
			_nftHolder,
			_price,
			_currency,
			msg.sender,
			uint256(OfferStatus.ACTIVE)
		);

		nftOffersList[_nftAddress][_tokenType][_nftHolder][_nftId].push(offerId);
		nftOfferCount[_nftAddress][_tokenType][_nftHolder][_nftId] += 1;

		emit MakeOffer(_nftAddress, _tokenType, offerId, block.timestamp);
	}

	/**
	 * @notice This method allows nft owner to accept the nft offer
	 * @param _offerId - indicates the id of offer which nft owner wants to accept
	 */
	function acceptOffer(uint256 _offerId) external onlyValidOfferId(_offerId) {
		NFTOffer memory offer = offers[_offerId];
		require(offer.status == uint256(OfferStatus.ACTIVE), 'Market: INACTIVE_OFFER');
		require(offer.nftHolder == msg.sender, 'Market: INVALID_ACCEPTOR');

		require(
			IBEP20(offer.currency).transferFrom(offer.requestor, address(this), offer.price),
			'MarketWithRoyalty: TRANSFER_FROM_FAILED'
		);

		_transferTokens(offer.requestor, offer.nftHolder, offer.currency, offer.price);
		_transferNfts(offer.nftAddress, offer.tokenType, msg.sender, offer.requestor, offer.nftId, 1);

		// delete all offers
		delete nftOffersList[offer.nftAddress][offer.tokenType][offer.nftHolder][offer.nftId];

		nftOfferCount[offer.nftAddress][offer.tokenType][offer.nftHolder][offer.nftId] = 0;
		offers[_offerId].status = uint256(OfferStatus.CLAIMED);

		emit AcceptOffer(offer.nftAddress, offer.tokenType, _offerId, msg.sender, block.timestamp);
	}

	/**
	 * @notice This method allows nft requestor to cancel his offer
	 * @param _offerId - indicates the offer id
	 */
	function cancelOffer(uint256 _offerId) external onlyValidOfferId(_offerId) {
		NFTOffer memory offer = offers[_offerId];

		require(offer.status == uint256(OfferStatus.ACTIVE), 'Market: INACTIVE_OFFER');
		require(offer.requestor == msg.sender, 'Market: INVALID_REQUESTOR');

		offers[_offerId].status = uint256(OfferStatus.CANCELED); // cancelled offer

		emit CancelOffer(offer.nftAddress, offer.tokenType, _offerId);
	}

	/**
	 * @notice This method allows nft owner to reject offer
	 * @param _offerId - indicates the offer id
	 */
	function rejectOffer(uint256 _offerId) external onlyValidOfferId(_offerId) {
		NFTOffer memory offer = offers[_offerId];

		require(offer.status == uint256(OfferStatus.ACTIVE), 'Market: INACTIVE_OFFER');
		require(offer.nftHolder == msg.sender, 'Market: INVALID_REJECTER');

		offers[_offerId].status = uint256(OfferStatus.REJECTED); // reject offer

		emit RejectOffer(offer.nftAddress, offer.tokenType, _offerId, msg.sender);
	}

	/**
	 * @notice This method allows admin to add the ERC20/BEP20 token which will be acceted for purchasing/selling NFT.
	 * @param _tokenAddress indicates the ERC20/BEP20 token address
	 */
	function addSupportedToken(address _tokenAddress) external virtual onlyAdmin {
		require(!supportedTokens[_tokenAddress], 'Market: TOKEN_ALREADY_ADDED');
		supportedTokens[_tokenAddress] = true;
	}

	/**
	 * @notice This method allows admin to remove the ERC20/BEP20 token from the accepted token list.
	 * @param _tokenAddress indicates the ERC20/BEP20 token address
	 */
	function removeSupportedToken(address _tokenAddress) external virtual onlyAdmin {
		require(supportedTokens[_tokenAddress], 'Market: TOKEN_DOES_NOT_EXISTS');
		supportedTokens[_tokenAddress] = false;
	}

	/**
	 * @notice This method allows admin to update minimum duration for the auction period.
	 * @param _newDuration indicates the new mint limit
	 */
	function updateMinimumDuration(uint256 _newDuration) external virtual onlyAdmin {
		require(_newDuration > 0 && _newDuration != minDuration, 'Market: INVALID_MINIMUM_DURATION');
		minDuration = _newDuration;
	}

	/**
	 * @notice This method allows admin to update the service fee.
	 * Note: service fee should be less than 25%
	 * @param _newFee - new service fee
	 */
	function updateServiceFee(uint256 _newFee) external virtual onlyAdmin {
		require(_newFee <= MAX_SERVICE_FEE, 'Market: INVALID_SERVICE_FEE');
		serviceFee = _newFee;
	}

	/**
	 * @notice This method allows admin to update the fee receiver address
	 * @param _newReceiver - indicates new fee receiver address
	 */
	function updateFeeReceiver(address _newReceiver) external virtual onlyAdmin {
		require(_newReceiver != address(0), 'Market: INVALID_FEE_RECEIVER');
		feeReceiver = _newReceiver;
	}

	/*
   =======================================================================
   ======================== Getter Methods ===============================
   =======================================================================
 */

	/**
	 * @notice This method allows user to get the winning bid of the particular auction.
	 * @param _listingId indicates the id of auction.
	 * @return returns the details of winning bid.
	 */
	// function getAuctionWinningBid(uint256 _listingId)
	// 	external
	// 	view
	// 	virtual
	// 	onlyValidListingId(_listingId)
	// 	returns (Bid memory)
	// {
	// 	Order memory order = NftListings[_listingId];
	// 	require(order.baseOrder.listingType == uint8(OrderType.AUCTION), 'Market: NOT_AN_AUCTION');
	// 	require(order.listingBase.status == uint8(ListingStatus.CLOSED), 'Market: NOT_RESOLVED_YET');

	// 	return bid[order.auctionData.winningBidId];
	// }

	/**
	 * @notice This method returns the current listing id
	 */
	function getCurrentListingId() external view virtual returns (uint256) {
		return listingIdCounter.current();
	}

	/**
	 * @notice This method returns the current bid Id
	 */
	function getCurrentBidId() external view virtual returns (uint256) {
		return bidIdCounter.current();
	}

	/**
	 * @notice This method returns the current offer Id
	 */
	function getCurrentOfferId() external view virtual returns (uint256) {
		return offerCounter.current();
	}

	/**
	 * @notice Returns the listing details.
	 */
	function getListing(uint256 _listingId) external view virtual returns (Order memory) {
		return NftListings[_listingId];
	}

	/**
	 * @notice Returns the total listings made by user.
	 */
	function getUserTotalListings(address _userAddress) external view virtual returns (uint256) {
		return userListingIds[_userAddress].length;
	}

	/*
   =======================================================================
   ======================== Internal Methods ===============================
   =======================================================================
 */

	function _transferTokens(
		address _from,
		address _to,
		address _currency,
		uint256 _paymentAmount
	) internal {
		IBEP20 _paymentToken = IBEP20(_currency);

		require(
			_paymentToken.transferFrom(_from, address(this), _paymentAmount),
			'MarketWithRoyalty: TRANSFER_FROM_FAILED'
		);

		uint256 _serviceCharge = (_paymentAmount * serviceFee) / 1000;
		require(_paymentToken.transfer(feeReceiver, _serviceCharge), 'Market: TRANSFER_FAILED');
		uint256 sellerAmount = _paymentAmount - _serviceCharge;

		require(_paymentToken.transfer(_to, sellerAmount), 'Market: TRANSFER_FAILED');
	}

	function _transferNfts(
		address _nftAddress,
		uint8 _tokenType,
		address _seller,
		address _buyer,
		uint256 _tokenId,
		uint256 _copies
	) internal {
		if (_tokenType == uint8(TokenType.ERC721)) {
			// transfer nft to requestor
			IERC721Upgradeable(_nftAddress).transferFrom(_seller, _buyer, _tokenId);
		} else {
			IERC1155(_nftAddress).safeTransferFrom(_seller, _buyer, _tokenId, _copies, '0x');
		}
	}

	function _ListNFT(
		address _nftAddress,
		uint8 _listingType,
		uint8 _tokenType,
		uint256 _tokenId,
		uint256 _totalCopies,
		address _currency,
		uint256 _nftPrice,
		uint256 _duration
	) internal returns (uint256 listingId) {
		listingIdCounter.increment();
		listingId = listingIdCounter.current();

		uint256[] memory bidIds;
		NftListings[listingId] = Order(
			BaseOrder(
				_listingType, // 0 = SALE,  1 = AUCTION
				_tokenType, // 0 = ERC721. 1 = ERC1155
				_nftAddress
			),
			ListingBase(msg.sender, address(0), _tokenId, _totalCopies, _totalCopies, _currency, 1),
			_listingType == 1
				? AuctionData(_nftPrice, _duration, 0, bidIds)
				: AuctionData(0, 0, 0, bidIds),
			SaleData(_listingType == 0 ? _nftPrice : 0),
			TimeStamps(0, 0, block.timestamp)
		);

		userListingIds[msg.sender].push(listingId);
		emit NftListing(_nftAddress, _listingType, _tokenType, msg.sender, listingId);
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes memory
	) public virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] memory,
		uint256[] memory,
		bytes memory
	) public virtual override returns (bytes4) {
		return this.onERC1155BatchReceived.selector;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external view returns (uint8);

	/**
	 * @dev Returns the token symbol.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Returns the token name.
	 */
	function name() external view returns (string memory);

	/**
	 * @dev Returns the bep token owner.
	 */
	function getOwner() external view returns (address);

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256);

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address recipient, uint256 amount) external returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address _owner, address spender) external view returns (uint256);

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
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 * allowance mechanism. `amount` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(
		address sender,
		address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(uint160(account), 20),
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