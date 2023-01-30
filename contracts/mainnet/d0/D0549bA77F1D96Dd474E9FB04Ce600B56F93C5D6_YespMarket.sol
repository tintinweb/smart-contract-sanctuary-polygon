//Custom NFT Marketplace Contract, for trading ERC721 collections on the Yesports Digital Marketplace.

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interface/IWETH.sol";
import "./interface/IYespFeeProcessor.sol";

import "./YespMarketUtils.sol";

//General
error YESP_DelistNotApproved();
error YESP_NotAuthorized();
error YESP_ListingNotActive();
error YESP_TradingPaused();
error YESP_NotOwnerOrAdmin();
error YESP_NoSelfOffer();
error YESP_CollectionNotEnabled();
error YESP_IntegerOverFlow();

//Offers or Listings
error YESP_ZeroPrice();
error YESP_BadPrice();
error YESP_ContractNotApproved();
error YESP_UserTokensLow();
error YESP_OfferArrayPosMismatch();
error YESP_NoCancellableOffer();
error YESP_CallerNotOwner();
error YESP_NotEnoughInEscrow();
error YESP_OrderExpired();
error YESP_BadExpiry();
error YESP_NoOfferFound();
error YESP_TokenNotListed();
error YESP_NotEnoughEthSent();

//Escrow
error YESP_TransferFailed();
error YESP_WithdrawNotEnabled();
error YESP_EscrowOverWithdraw();
error YESP_ZeroInEscrow();

contract YespMarket is ReentrancyGuard, Ownable {
    using YespMarketUtils for bytes32[];
    using YespMarketUtils for address[];

    event TokenListed(address indexed token, uint256 indexed id, uint256 indexed price, uint256 expiry, bytes32 listingHash, uint256 timestamp);
    event TokenDelisted(address indexed token, uint256 indexed id, bytes32 listingHash, uint256 timestamp);
    event TokenPurchased(address indexed oldOwner, address indexed newOwner, uint256 indexed price, address collection, uint256 tokenId, bytes32 tradeHash, uint256 timestamp);
    event OfferPlaced(address indexed token, uint256 indexed id, uint256 indexed price, uint256 expiry, address buyer, bytes32 offerHash, address potentialSeller);
    event OfferCancelled(address indexed token, uint256 indexed id, uint256 indexed price, uint256 expiry, address buyer, bytes32 offerHash, uint256 timestamp);
    event EscrowReturned(address indexed user, uint256 indexed price);
    event CollectionModified(address indexed token, bool indexed enabled, address indexed owner, uint256 collectionOwnerFee, uint256 timestamp);

    uint256 public constant MAX_INT = ~uint256(0);
    uint128 public constant SMOL_MAX_INT = ~uint128(0);

    // Fees are out of 10000, to allow for 0.01 - 9.99% fees.
    uint256 public defaultCollectionOwnerFee; //0%
    uint256 public totalEscrowedAmount;

    IWETH public TOKEN; //WETH, NOVA
    IYespFeeProcessor public YespFeeProcessor;

    mapping(bytes32 => ListingPos) public posInListings;
    mapping(bytes32 => OfferPos) public posInOffers;

    struct ListingPos {
        uint128 posInListingsByLister;
        uint128 posInListingsByContract;
    }

    struct OfferPos {
        uint256 posInOffersByOfferer;
    }

    struct Listing {
        uint256 tokenId;
        uint128 price;
        uint128 expiry;
        address contractAddress;
        address lister;
    }

    struct Offer {
        uint256 tokenId;
        uint128 price;
        uint128 expiry;
        address contractAddress;
        address offerer;
        bool escrowed;
    }

    // Listing-related storage
    mapping(bytes32 => Listing) public listings;
    mapping(address => bytes32[]) public listingsByLister;
    mapping(address => bytes32[]) public listingsByContract;
    mapping(address => mapping(uint256 => bytes32)) public currentListingOrderHash;

    // Offer-relatead storage
    mapping(bytes32 => Offer) public offers;
    mapping(address => bytes32[]) public offerHashesByBuyer;

    // Address-based nonce-counting
    mapping(address => uint256) private userNonces;

    // Admin flags
    bool public tradingPaused = false;
    bool public feesOn = true;
    bool public collectionOwnersCanSetRoyalties = true;
    bool public usersCanWithdrawEscrow = false; // admin controlled manual escape hatch. users can always withdraw by cancelling offers.

    // Collection-related storage ++ misc
    mapping(address => bool) collectionTradingEnabled;
    mapping(address => address) collectionOwners;
    mapping(address => uint256) collectionOwnerFees;
    mapping(address => uint256) totalInEscrow;
    mapping(address => bool) administrators;

    modifier onlyAdmins() {
        if (!(administrators[_msgSender()] || owner() == _msgSender()))
            revert YESP_NotOwnerOrAdmin();
        _;
    }

    constructor(address _TOKEN, address _YESPFEEPROCESSOR) {
        TOKEN = IWETH(_TOKEN);
        YespFeeProcessor = IYespFeeProcessor(_YESPFEEPROCESSOR);
        administrators[msg.sender] = true;
    }

    //---------------------------------
    //
    //            LISTINGS
    //
    //---------------------------------

    // Lists a token at the specified price point.
    function listToken(address ca, uint256 tokenId, uint256 price, uint256 expiry) public {
        IERC721 token = IERC721(ca);

        // Check listing prerequisites. 
        // We require uints <= SMOL_MAX_INT to prevent potential casting issues later.
        if (price > SMOL_MAX_INT || expiry > SMOL_MAX_INT) revert YESP_IntegerOverFlow();
        if (msg.sender != token.ownerOf(tokenId)) revert YESP_CallerNotOwner();
        if (!token.isApprovedForAll(msg.sender, address(this))) revert YESP_ContractNotApproved();
        if (expiry != 0 && expiry < block.timestamp) revert YESP_BadExpiry();

        // Generate unique listing hash, increment nonce.
        bytes32 listingHash = computeOrderHash(msg.sender, ca, tokenId, userNonces[msg.sender]);
        unchecked {++userNonces[msg.sender];}

        // If this token was already listed, handle updating previous listing hash.
        bytes32 oldListingHash = currentListingOrderHash[ca][tokenId];
        if (oldListingHash != bytes32(0)) {
            Listing memory listing = listings[oldListingHash];
            _cleanupListing(oldListingHash, listing.lister, listing.contractAddress, listing.tokenId);
        }

        // Store the new listing.
        listings[listingHash] = Listing(tokenId, uint128(price), uint128(expiry), ca, msg.sender);

        // Stick this new listing at the end of both tracking arrays
        posInListings[listingHash] = ListingPos(
            uint128(listingsByLister[msg.sender].length),
            uint128(listingsByContract[ca].length)
        );
        listingsByLister[msg.sender].push(listingHash);
        listingsByContract[ca].push(listingHash);

        // Keeps track of current listing for this specific token.
        currentListingOrderHash[ca][tokenId] = listingHash;

        // Index me baby
        emit TokenListed(ca, tokenId, price, expiry, listingHash, block.timestamp);
    }

    // *Public* token delisting function, requiring either ownership OR invalidity to delist.
    function delistToken(bytes32 listingId) public {
        Listing memory listing = listings[listingId];
        IERC721 token = IERC721(listing.contractAddress);
        address tknOwner = token.ownerOf(listing.tokenId);

        // If listing is invalid due to expiry, transfer, or approval revoke, (or caller has admin perms), anyone can delist. 
        if (
            msg.sender != tknOwner &&                          // If not owner
            !administrators[msg.sender] &&                     // and not admin
            listing.lister == tknOwner &&                      // and current owner matches og lister
            token.isApprovedForAll(tknOwner, address(this)) && // and token is approved for trade
            listing.expiry > block.timestamp                   // and listing is not expired
        )
            revert YESP_DelistNotApproved();                    // you can't delist, ser

        // Clean up old listing from all lister array, collection array, all listings, and current listings.
        _cleanupListing(listingId, tknOwner, listing.contractAddress, listing.tokenId);

        // Index moi
        emit TokenDelisted(listing.contractAddress, listing.tokenId, listingId, block.timestamp);
    }

    // Allows a buyer to buy at the listed price - sending the purchased token to `to`.
    function fulfillListing(bytes32 listingId, address to) external payable nonReentrant {
        if (tradingPaused) 
            revert YESP_TradingPaused();
        
        Listing memory listing = listings[listingId];
        
        if (!collectionTradingEnabled[listing.contractAddress]) revert YESP_CollectionNotEnabled();
        if (listing.price == 0) revert YESP_TokenNotListed();
        if (msg.value < listing.price) revert YESP_NotEnoughEthSent();
        if (listing.expiry != 0 && block.timestamp > listing.expiry) revert YESP_OrderExpired();

        // Verify that the listing is still valid (current owner is original lister)
        address originalLister = listing.lister;
        IERC721 token = IERC721(listing.contractAddress);

        if(originalLister != token.ownerOf(listing.tokenId)) 
            revert YESP_ListingNotActive();

        // Effects - cleanup listing data structures
        _cleanupListing(listingId, originalLister, listing.contractAddress, listing.tokenId);

        // Interaction - transfer NFT and process fees. Will fail if token no longer approved
        token.safeTransferFrom(originalLister, to, listing.tokenId);

        //Fees
        _processFees(
            listing.contractAddress,
            listing.price,
            originalLister
        );

        // Ty for your business
        emit TokenPurchased(originalLister, msg.sender, listing.price, listing.contractAddress, listing.tokenId, listingId, block.timestamp);
    }

    //---------------------------------
    //
    //            OFFERS
    //
    //---------------------------------

    // Non-escrowed offer (WETH only)
    function makeOffer(address ca, uint256 tokenId, uint256 price, uint256 expiry) public {
        // Same as listings - do all the checks. Make sure uints are < uint128 for casting reasons.
        if (price > SMOL_MAX_INT || expiry > SMOL_MAX_INT) revert YESP_IntegerOverFlow();
        if (tradingPaused) revert YESP_TradingPaused();
        if (price == 0) revert YESP_ZeroPrice();
        if (TOKEN.allowance(msg.sender, address(this)) < price) revert YESP_ContractNotApproved();
        if (TOKEN.balanceOf(msg.sender) < price) revert YESP_UserTokensLow();
        if (expiry != 0 && expiry < block.timestamp) revert YESP_BadExpiry();

        // Calculate and store new offer.
        bytes32 offerHash = computeOrderHash(msg.sender, ca, tokenId, userNonces[msg.sender]);
        unchecked {++userNonces[msg.sender];}
        _storeOffer(offerHash, ca, msg.sender, tokenId, price, expiry, false);

        emit OfferPlaced(ca, tokenId, price, expiry, msg.sender, offerHash, IERC721(ca).ownerOf(tokenId));
    }

    // ETH offer, escrowed.
    function makeEscrowedOfferEth(address ca, uint256 tokenId, uint256 expiry) public payable nonReentrant {
        _processEscrowOffer(ca, tokenId, expiry, msg.value);
    }

    // WETH offer, escrowed.
    function makeEscrowedOfferTokens(address ca, uint256 tokenId, uint256 expiry, uint256 price) public payable nonReentrant {
        bool success = TOKEN.transferFrom(msg.sender, address(this), price);
        if (!success) revert YESP_TransferFailed();
        TOKEN.withdraw(price);
        _processEscrowOffer(ca, tokenId, expiry, price);
    }

    // Cancel an offer (escrowed or not). Callable only by offer maker or token owner.
    function cancelOffer(bytes32 offerHash) external nonReentrant {
        Offer memory offer = offers[offerHash];
        if (offer.offerer != msg.sender && IERC721(offer.contractAddress).ownerOf(offer.tokenId) != msg.sender) revert YESP_NotAuthorized();
        if (offer.price == 0) revert YESP_NoCancellableOffer();

        // Remove the offer from data storage.
        _cleanupOffer(offerHash, offer.offerer);

        // Handle returning escrowed funds
        if (offer.escrowed) {
            if (offer.price > totalInEscrow[offer.offerer]) revert YESP_EscrowOverWithdraw();
            _returnEscrow(offer.offerer, offer.price);
        }
    }

    // Same as above, admin only, no ownership check.
    function cancelOfferAdmin(bytes32 offerHash, bool returnEscrow) external onlyAdmins nonReentrant {
        Offer memory offer = offers[offerHash];
        if (offer.price == 0)  revert YESP_NoCancellableOffer();

        _cleanupOffer(offerHash, offer.offerer);

        if (offer.escrowed && returnEscrow) {
            if (offer.price > totalInEscrow[offer.offerer]) revert YESP_EscrowOverWithdraw();
            _returnEscrow(offer.offerer, offer.price);
        }
    }

    // Accept an active offer.
    function acceptOffer( bytes32 offerHash) external nonReentrant {
        if (tradingPaused) revert YESP_TradingPaused();

        Offer memory offer = offers[offerHash];
        IERC721 _nft = IERC721(offer.contractAddress);

        if (!collectionTradingEnabled[offer.contractAddress]) revert YESP_CollectionNotEnabled();
        if (offer.price == 0) revert YESP_NoOfferFound();
        if (offer.expiry != 0 && block.timestamp > offer.expiry) revert YESP_OrderExpired();
        if(msg.sender != _nft.ownerOf(offer.tokenId)) revert YESP_CallerNotOwner();

        _cleanupOffer(offerHash, offer.offerer);

        // Actually perform trade
        address payable oldOwner = payable(address(msg.sender));
        address payable newOwner = payable(address(offer.offerer));
        if (offer.escrowed) {
            _escrowedPurchase(_nft, offer.contractAddress, offer.tokenId, offer.price, oldOwner, newOwner);
        } else {
            _tokenPurchase(_nft, offer.contractAddress, offer.tokenId, offer.price, oldOwner, newOwner);
        }
        emit TokenPurchased(oldOwner, newOwner, offer.price, offer.contractAddress, offer.tokenId, offerHash, block.timestamp);
    }

    // Just a little hash helper. Used by both listings and orders.
    function computeOrderHash(address user,  address token, uint256 tokenId, uint256 userNonce) public view returns (bytes32 offerHash) {
        return keccak256(abi.encode(user, token, tokenId, userNonce, block.timestamp));
    }


    //---------------------------------
    //
    //            ESCROW
    //
    //---------------------------------

    // Manual functions to only be enabled in case of contract migration, as they will throw off escrowed amount values.
    // Escrowed funds can always be withdrawn by cancelling placed bids.
    function addFundsToEscrow() external payable nonReentrant {
        if (!usersCanWithdrawEscrow) revert YESP_WithdrawNotEnabled();
        totalEscrowedAmount += msg.value;
        totalInEscrow[msg.sender] += msg.value;
    }

    function withdrawFundsFromEscrow(uint256 amount) external nonReentrant {
        if (!usersCanWithdrawEscrow) revert YESP_WithdrawNotEnabled();
        if (totalInEscrow[msg.sender] == 0) revert YESP_ZeroInEscrow();
        if (totalInEscrow[msg.sender] < amount) revert YESP_EscrowOverWithdraw();
        _returnEscrow(msg.sender, amount);
    }

    function getEscrowedAmount(address user) external view returns (uint256) {
        return totalInEscrow[user];
    }

    function _returnEscrow(address depositor, uint256 escrowAmount) private {
        totalEscrowedAmount -= escrowAmount;
        totalInEscrow[depositor] -= escrowAmount;
        _sendEth(depositor, escrowAmount);
    }

    //---------------------------------
    //
    //         FEE PROCESSING
    //
    //---------------------------------
    
    /**
    *   @dev functions for accruing and processing ETH fees.
    */

    function _processFees(address ca, uint256 amount, address oldOwner) private {
        if (feesOn) {
            (uint256 totalAdminFeeAmount, uint256 collectionOwnerFeeAmount, uint256 remainder) = _calculateAmounts(ca, amount);
            _sendEth(oldOwner, remainder);
            _sendEth(collectionOwners[ca], collectionOwnerFeeAmount);
            _sendEth(address(YespFeeProcessor), totalAdminFeeAmount);
        } else {
            _sendEth(oldOwner, amount);
        }
    }

    //---------------------------------
    //
    //     VARIOUS PUBLIC GETTERS
    //
    //---------------------------------
    function getCollectionOwner(address ca) external view returns (address) {
        return collectionOwners[ca];
    }

    function checkEscrowAmount(address user) external view returns (uint256) {
        return totalInEscrow[user];
    }

    function isCollectionTrading(address ca) external view returns (bool) {
        return collectionTradingEnabled[ca];
    }

    function getCollectionFee(address ca) external view returns (uint256) {
        return collectionOwnerFees[ca];
    }

    // Validates a listing's current status. Checks price is != 0, original lister is current lister,
    // token is approved, and that expiry has not passed (or is 0). Anyone can remove invalid listings.
    function isValidListing(bytes32 listingHash) public view returns (bool isValid) {
        Listing memory listing = listings[listingHash];
        IERC721 token = IERC721(listing.contractAddress);
        address tknOwner = token.ownerOf(listing.tokenId);
        isValid = (listing.price != 0 &&
                    token.ownerOf(listing.tokenId) == listing.lister &&
                    token.isApprovedForAll(tknOwner, address(this)) &&
                    (listing.expiry == 0 || (listing.expiry > block.timestamp))
                    );
    }

    // Matches the old isListed function. Maintained for easy front-end backwards compatibility.
    // ONLY checks if a listing exists - NOT if it's a valid listing.
    function isListed(address ca, uint256 tokenId) public view returns (bool listingState) {
        bytes32 listingHash = currentListingOrderHash[ca][tokenId];
        Listing memory listing = listings[listingHash];
        listingState = (listing.price != 0 && (listing.expiry == 0 || (listing.expiry > block.timestamp)));
    }

    function getCurrentListing(address ca, uint256 tokenId) public view returns (Listing memory listing) {
        bytes32 listingHash = currentListingOrderHash[ca][tokenId];
        listing = listings[listingHash];
    }

    //---------------------------------
    //
    //     ADMIN FUNCTIONS
    //
    //---------------------------------
    function setAdmin(address admin, bool value) external onlyOwner {
        administrators[admin] = value;
    }

    function setTrading(bool value) external onlyOwner {
        tradingPaused = value;
    }

    function clearListing(bytes32 listingId) external onlyAdmins {
        Listing memory listing = listings[listingId];
        _cleanupListing(listingId, listing.lister, listing.contractAddress, listing.tokenId);
    }

    // Convenience function for listing / ~Partially~ implements EIP2981
    function listCollection(address ca, bool tradingEnabled, address _royaltyWallet, uint256 _fee) external onlyAdmins {
        uint256 fee = _fee;
        address royaltyWallet = _royaltyWallet;
        if (IERC165(ca).supportsInterface(0x2a55205a)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(ca).royaltyInfo(1, 1 ether);
            royaltyWallet = receiver;
            fee = (10000 * royaltyAmount / 1 ether) >= 1000 ? 1000 : 10000 * royaltyAmount / 1 ether;
        }

        collectionTradingEnabled[ca] = tradingEnabled;
        collectionOwners[ca] = royaltyWallet;
        collectionOwnerFees[ca] = fee;
        emit CollectionModified(ca, tradingEnabled, _royaltyWallet, _fee, block.timestamp);
    }

    function setCollectionTrading(address ca, bool value) external onlyAdmins {
        collectionTradingEnabled[ca] = value;
        emit CollectionModified(ca, value, collectionOwners[ca], collectionOwnerFees[ca], block.timestamp);
    }

    function setCollectionOwner(address ca, address _owner) external onlyAdmins {
        collectionOwners[ca] = _owner;
        emit CollectionModified(ca, collectionTradingEnabled[ca], _owner, collectionOwnerFees[ca], block.timestamp);
    }

    // Either the collection owner or the contract owner can set fees.
    function setCollectionOwnerFee(address ca, uint256 fee) external {
        bool verifiedCollectionOwner = collectionOwnersCanSetRoyalties && (_msgSender() == collectionOwners[ca]);
        require((_msgSender() == owner()) || verifiedCollectionOwner);
        require(fee <= 1000, "Max 10% fee");
        collectionOwnerFees[ca] = fee;
        emit CollectionModified(ca, collectionTradingEnabled[ca], collectionOwners[ca], collectionOwnerFees[ca], block.timestamp);
    }

    function setDefaultCollectionOwnerFee(uint256 fee) external onlyOwner {
        require(fee <= 1000, "Max 10% fee");
        defaultCollectionOwnerFee = fee;
    }

    function setFeesOn(bool _value) external onlyOwner {
        feesOn = _value;
    }

    function setUsersCanWithdrawEscrow(bool _value) external onlyAdmins {
        usersCanWithdrawEscrow = _value;
    }

    function setCollectionOwnersCanSetRoyalties(bool _value) external  onlyOwner {
        collectionOwnersCanSetRoyalties = _value;
    }

    function getListingsByLister(address lister) public view returns(bytes32[] memory) {
        return listingsByLister[lister];
    }

    function getListingsByContract(address contractAddress) public view returns(bytes32[] memory) {
        return listingsByContract[contractAddress];
    }

    function getOffersByOfferer(address offerer) public view returns(bytes32[] memory) {
        return offerHashesByBuyer[offerer];
    }

    function totalAdminFees() public view returns(uint256 totalFee) {
        totalFee = YespFeeProcessor.totalFee();
    }

    // Emergency only - Recover Tokens
    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(owner(), amount);
    }

    // Emergency only - Recover NFTs
    function recoverNFT(address _token, uint256 tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), owner(), tokenId);
    }

    // Emergency only - Recover ETH
    function RecoverETH(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    //---------------------------------
    //
    //     PRIVATE HELPERS
    //
    //---------------------------------

    /**
    * @dev This function requires that listingsByLister[address] and listingsByContract[address] must have
    * a length of at least one. This should always be true, as when listToken() is called it pushes an entry
    * to both arrays. No other functions delete from or manage the ordering of arrays, so for a non-zero
    * listingId, listingsByLister[address] and listingsByContract[address] will ALWAYS have an entry.
    * 
    * @dev Called when an existing active listing needs to be removed or replaced, and cleans up stored listing data.
    */
    function _cleanupListing(bytes32 listingId, address oldOwner, address listingAddress, uint256 listingTokenId) internal {
        //Get the position of this listing in both listing arrays (user/collection)
        ListingPos memory listingPos_ = posInListings[listingId];
        bytes32 listingHashToReplace;

        // 1. Handle updating the array that tracks all of a user's listings.
        uint256 lastListerIndex = listingsByLister[oldOwner].length-1;

        // Get the last listing hash in the array
        listingHashToReplace = listingsByLister[oldOwner][lastListerIndex];
        // Move the last listing hash to the replacement position, and shorten the array.
        listingsByLister[oldOwner].swapPop(listingPos_.posInListingsByLister);

        // If we have something still in the array, need to update posInListings.
        if (listingsByLister[oldOwner].length > 0) {
            posInListings[listingHashToReplace].posInListingsByLister = listingPos_.posInListingsByLister;
        }

        // 2. Handle updating the array that tracks all of a collection's listings.
        uint256 lastContractIndex = listingsByContract[listingAddress].length-1;

        // Get the last listing hash in the array
        listingHashToReplace = listingsByContract[listingAddress][lastContractIndex];
        // Move the last listing hash to the replacement position, and shorten the array.
        listingsByContract[listingAddress].swapPop(listingPos_.posInListingsByContract);

        // If we have something still in the array, need to update posInListings.
        if (listingsByContract[listingAddress].length > 0) {
            posInListings[listingHashToReplace].posInListingsByContract = listingPos_.posInListingsByContract;
        }

        // 3. Finally, delete the listing hash that we no longer care about.
        delete listings[listingId];
        delete currentListingOrderHash[listingAddress][listingTokenId];
        delete posInListings[listingId];
        
    }

    // Handle storing and emitting an event for a new escrowed offer (eth/weth)
    function _processEscrowOffer(address ca, uint256 tokenId, uint256 expiry, uint256 price) internal {
        if (price > SMOL_MAX_INT || expiry > SMOL_MAX_INT) revert YESP_IntegerOverFlow();
        if (tradingPaused) revert YESP_TradingPaused();
        if (price == 0) revert YESP_ZeroPrice();
        if (expiry != 0 && expiry < block.timestamp) revert YESP_BadExpiry();

        totalEscrowedAmount += price;
        totalInEscrow[msg.sender] += price;

        // Calculate and store new offer.
        bytes32 offerHash = computeOrderHash(msg.sender, ca, tokenId, userNonces[msg.sender]);
        unchecked {++userNonces[msg.sender];}
        _storeOffer(offerHash, ca, msg.sender, tokenId, price, expiry, true);

        emit OfferPlaced(ca, tokenId, price, expiry, msg.sender, offerHash, IERC721(ca).ownerOf(tokenId));
    }

    // Process ETH trade (from offer).
    function _escrowedPurchase(IERC721 _nft, address ca, uint256 tokenId, uint256 price, address payable oldOwner, address payable newOwner) private {
        require(totalInEscrow[newOwner] >= price, "Buyer does not have enough money in escrow.");  
        require(totalEscrowedAmount >= price, "Escrow balance too low.");
        totalInEscrow[newOwner] -= price;
        totalEscrowedAmount -= price;

        _nft.safeTransferFrom(oldOwner, newOwner, tokenId);
        _processFees(ca, price, oldOwner);
    }

    // Process WETH trade (from offer).
    function _tokenPurchase(IERC721 _nft, address ca, uint256 tokenId, uint256 price, address payable oldOwner, address payable newOwner) private {
        _nft.safeTransferFrom(oldOwner, newOwner, tokenId);
        TOKEN.transferFrom(newOwner, address(this), price);
        TOKEN.withdraw(price);
        _processFees(ca, price, oldOwner);
    }

    // Add a new offer hash to data storage.
    function _storeOffer(bytes32 offerHash, address ca, address user, uint256 tokenId, uint256 price, uint256 expiry, bool escrowed) private {
        offers[offerHash] = Offer(tokenId, uint128(price), uint128(expiry), ca, user, escrowed);
        posInOffers[offerHash] = OfferPos(offerHashesByBuyer[user].length);
        offerHashesByBuyer[user].push(offerHash);
    }

    // Done dealing with this offer hash - clean up storage.
    function _cleanupOffer(bytes32 offerId, address offerer) internal {
        OfferPos memory offerPos_ = posInOffers[offerId];
        bytes32 offerHashToReplace;
        uint256 lastOffererIndex = offerHashesByBuyer[offerer].length-1;

        //Cleanup accessory mappings. We pass the mapping results directly to the swapPop function to save memory height.
        offerHashToReplace = offerHashesByBuyer[offerer][lastOffererIndex];
        offerHashesByBuyer[offerer].swapPop(offerPos_.posInOffersByOfferer);
        if (offerHashesByBuyer[offerer].length > 0) {
            posInOffers[offerHashToReplace].posInOffersByOfferer = offerPos_.posInOffersByOfferer;
        }
        delete offers[offerId];
        delete posInOffers[offerId];
    }

    // Who gets what
    function _calculateAmounts(address ca, uint256 amount) private view returns (uint256, uint256, uint256) {
        uint256 _collectionOwnerFee = collectionOwnerFees[ca] == 0
            ? defaultCollectionOwnerFee
            : collectionOwnerFees[ca];

        uint256 totalAdminFee = (amount * totalAdminFees()) / 10000;
        uint256 collectionOwnerFeeAmount = (amount * _collectionOwnerFee) / 10000;
        uint256 remainder = amount - (totalAdminFee + collectionOwnerFeeAmount);

        return (totalAdminFee, collectionOwnerFeeAmount, remainder);
    }

    // Pretty self explanatory tbh
    function _sendEth(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

pragma solidity >=0.4.18;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IYespFeeProcessor {
    function devFee() external view returns(uint256);
    function secondaryFee() external view returns(uint256);
    function tertiaryFee() external view returns(uint256);
    function totalFee() external view returns(uint256);
}

pragma solidity ^0.8.14;

library YespMarketUtils {
    function swapPop(bytes32[] storage self, uint256 index) internal {
        self[index] = self[self.length-1];
        self.pop();
    }

    function swapPop(address[] storage self, uint256 index) internal {
        self[index] = self[self.length-1];
        self.pop();
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