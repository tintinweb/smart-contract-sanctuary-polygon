// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './Context.sol';

/**
  @notice Connection's interface with Roles SC
*/
interface IRoles {
  function isVerifiedUser(address user_) external returns (bool);
  function isModerator(address user_) external returns (bool);
  function isUser(address user_) external returns (bool);
}

/**
  @notice Connection's interface with Collections SC
*/
interface ICollections {
  function hasOwnershipOf(uint256 collection_, uint256 tokenId_, address owner_) external view returns (bool);
  function isApprovedForAll(address account, address operator) external view returns (bool);
  function safeTransferFrom(address from, address to, uint256 collection, uint256 id, bytes memory data) external;
}

/**
  @notice Connection's interface with ERC20 SC
*/
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to,uint256 amount) external returns (bool);
}

/**
  @notice Connection's interface with ERC721 SC
*/
interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function getApproved(uint256 tokenId) external view returns (address operator);
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
 * @notice The interface to implement in the market contract
 */
interface IMarket {
  event OfferCreated(uint256 id, string hiddenId);
  event OfferCompleted(uint id, string hiddenId);
  event OfferApproved(uint256 offerId);
  event OfferCancelled(uint256 offerId);
}

/**
 * @notice Market logic
 */
contract Market is IMarket, Context {
  /**
   * @notice The roles interface
   */
  IRoles rolesContract;

  /**
   * @notice The token contract
   */
  ICollections tokenContract;

  /**
   * @notice The address of the token
   */
  address public tokenAddress;

  /**
   * @notice Amount of offers (counter)
   */
  uint256 public offersCount;

  /**
   * @notice List of offers
   */
  mapping(uint256 => Offer) public offersList;

  /**
   * @notice List of winners
   */
  mapping(uint256 => address) public winner;
  /**
   * @notice List of approved offers
   */
  mapping(uint256 => bool) public approvedOffers;

  /**
   * @notice If of valid ERC20 tokens
   */
  mapping(address => bool) public validERC20;

  /**
   * @notice list of ERC721 approved
   */
  mapping(address => bool) public approvedERC721;

  /**
   * @notice Struct created when at leas an ERC721 is put up for { sell / auction }
   * @param info encoded params {} 
   * @param collection  encoded collection's Ids
   * @param tokenId  encoded token's Ids
   * @param collectionAddress array of collectionAddreses 
   * @param paymentToken Token to accept for the listing
   * @param seller The address that sells the NFT (owner or approved)
   */
  struct Offer {
    uint256 info;
    uint256 collectionIds;
    uint256 tokenIds;
    address[] collectionAddresses;
    address paymentToken;
    address seller;
  }

  //! --------------------------------------------------------------------------- EVENTS ---------------------------------------------------------------------------

  /**
   * @notice Event triggered when someone bid in an auction
   */
  event BidForAuction(address who, uint256 offerId, uint256 amount);

  /**
   * @notice Event triggered when an offer changes status { approved / deprecated }
   */
  event ChangeStatusERC721(address ERC721, address who, bool newStatus);

  /**
   * @notice Event triggered when an offer is activated
   */
  event ApprovedOffer(uint offerId, address who);

  /**
   * @notice Event triggered when an ERC20 address is validated (or not)
   */
  event ERC20Validated(address token, bool valid);
  
  //! --------------------------------------------------------------------------- MODIFIERS ---------------------------------------------------------------------------

  /**
   * @notice Only offers that are approved or created by a moderator
   * @param offerId_ Offer id to check if approved
   */
  modifier onlyApprovedOffers(uint256 offerId_) {
    require(
      (approvedOffers[offerId_] == true) || 
      (rolesContract.isVerifiedUser(offersList[offerId_].seller)),
      'M101'
    );
    _;
  }

  /**
   * @notice Only users or verified users can call
   */
  modifier onlyUsers() {
    require(rolesContract.isUser(_msgSender()) || rolesContract.isVerifiedUser(_msgSender()), 'E811');
    _;
  }

  /**
   *@notice the offer must be active
   *@param offerId_ the offer to check if is active
   */
  modifier onlyActiveOffers(uint256 offerId_) {
    require(isActive(offerId_), 'M113');
    _;
  }

  /**
   * @notice Only a moderator can call
   */
  modifier onlyModerator(){
    require(rolesContract.isModerator(_msgSender()), 'M120');
    _;
  }

  /**
   * @notice only offer must be an auction
   * @param offerId_ the offer to check if is an auction 
   */
  modifier onlyAuctions(uint256 offerId_) {
    require(isAuction(offerId_), 'M110');
    _;
  }

  /**
   *@notice only Votation Module can call 
   */
  modifier onlyVotationModule() {
    require(_msgSender() == moduleManager.getModule(3), 'M133');
    _;
  }

  /**
   * @notice Builder
   * @param module_ Module manager
   */
  constructor(address module_) Context(module_) {
    moduleManager = IModule(module_);
    address roles = moduleManager.getModule(0);
    tokenAddress = moduleManager.getModule(1);
    rolesContract = IRoles(roles);
    tokenContract = ICollections(tokenAddress);
  }


  /**
   * @notice Function to refresh the addresses used in this contract
   */
  function refresh() public onlyVotationModule {
    address roles = moduleManager.getModule(0);
    tokenAddress  = moduleManager.getModule(1);
    tokenContract = ICollections(tokenAddress);
    rolesContract = IRoles(roles);
  }

  //! --------------------------------------------------------------------------- CREATE OFFER ---------------------------------------------------------------------------

  /**
   * @notice function to validate the params { all params } sent for create an offer
   * @param isAuction_ indicate if the offer is going to be an auction or not
   * @param endTime_ indicate the time when the offer will be end (just if is acution)
   * @param minBid_ Min bid allowed
   * @param tokenIds_ array of token's ids to sell
   * @param value_ Value of the offer
   * @param collectionAddresses_ array of collections's addresses
   * @param collections_ array of collection's ids
   * @param paymentToken_ You can ask for USDT, DAI or Matic/Ether
  */
  function _validateCreateParams( 
    bool isAuction_,
    uint48 endTime_,
    uint96 minBid_,
    uint96 value_,
    uint256[] memory collections_,
    uint256[] memory tokenIds_,
    address[] memory collectionAddresses_,
    address paymentToken_ 
  ) internal view {
    require((collections_.length == tokenIds_.length) && (collections_.length == collectionAddresses_.length), 'E806');
    require(tokenIds_.length < 6,'M127');
    require((value_ > 0) && (isValidERC20(paymentToken_)), 'M102');
    if (isAuction_) require((endTime_ > block.timestamp + 3600) && (value_ > minBid_), 'M103');
  }

  /**
   * @notice function to validate the ownership of the tokens of an offer
   * @param collections_ array of collection's Ids
   * @param tokenIds_ array of token's ids
   * @param collectionAddresses_ array of collecti's addresesss
   * @return flag true if the offer have unapproved collection addresses
   * @return mixed true if have at least an exeternal collection's address
   */
  function _validateOwnership( 
    uint256[] memory collections_,
    uint256[] memory tokenIds_,
    address[] memory collectionAddresses_
  ) internal view returns (bool flag, bool mixed) {
    uint counter;
    for (uint256 i; i < collectionAddresses_.length; i++) {
      if (collectionAddresses_[i] == tokenAddress) {
        require(tokenContract.hasOwnershipOf(collections_[i], tokenIds_[i], _msgSender()), 'M104');
        // *just once
        if (counter == 0) require(tokenContract.isApprovedForAll(_msgSender(), address(this)), 'M105');
        counter++;
      } else {
        require(IERC721(collectionAddresses_[i]).ownerOf(tokenIds_[i]) == _msgSender(), 'E413');
        require(IERC721(collectionAddresses_[i]).getApproved( tokenIds_[i] ) == address(this), 'E407');
        // *just once
        if (!approvedERC721[collectionAddresses_[i]] && !flag) flag = true;
      }
    }
    mixed = counter != collectionAddresses_.length;
  }

  /**
   * @notice Function to create offers 
   * @param isAuction_ If it is auction
   * @param endTime_ time when offers ends (just for auction)
   * @param minBid_ Min bid allowed
   * @param tokenIds_ array of token's ids to sell
   * @param value_ Value of the offer
   * @param collectionAddresses_ array of collections's addresses
   * @param collections_ array of collection's ids
   * @param paymentToken_ You can ask for USDT, DAI or Matic/Ether
   * @param hiddenId_ Offre's id in fireBase
   */
  function createOffer(
    bool isAuction_,
    uint48 endTime_,
    uint96 minBid_,
    uint96 value_,
    uint256[] memory collections_,
    uint256[] memory tokenIds_,
    address[] memory collectionAddresses_,
    address paymentToken_,
    string memory hiddenId_
  ) public onlyUsers {
    _validateCreateParams(isAuction_,endTime_,minBid_,value_,collections_,tokenIds_,collectionAddresses_,paymentToken_);
    (bool notApproved, bool mixed) = _validateOwnership(collections_, tokenIds_, collectionAddresses_);
    if (!notApproved || !mixed) approvedOffers[offersCount] = true;
    offersList[offersCount] = Offer(
      encodeValues(isAuction_ ? 1 : 0, endTime_, minBid_, value_),
      encode(collections_),
      encode(tokenIds_),
      collectionAddresses_,
      paymentToken_,
      _msgSender()
    );
    emit OfferCreated(offersCount, hiddenId_);
    offersCount++;
  }

  //! --------------------------------------------------------------------------- BUY OFFER ---------------------------------------------------------------------------

  /**
  * @notice function to validate params from a purchase
  * @param offerId_ The offer id to check
  * @param directBuy_ Indicate if is a direct purchase {just for auctions} 
  */
  function _validateBuyParams(uint256 offerId_, bool directBuy_) internal view {
    Offer memory offer = offersList[offerId_];
    if (isAuction(offerId_) && !directBuy_) {
      require(!validateAuctionTime(offerId_), 'M111');  // Check if caller is the winner and if it is ended
      require(_msgSender() == winner[offerId_], 'M112');
    }
    if (offer.paymentToken == address(0)) {
      require(msg.value >= getValue(offerId_), 'M114');// Not enought sended
    } else {
      require(IERC20(offer.paymentToken).allowance(_msgSender(), address(this) ) >= getValue(offerId_),'M115');   // Not enought allowance
    }
  }

  /**
   * @notice Function to transanc all tokens bought 
   * @param offerId_ The offer bought
   */
  function _transactAllTokens(uint256 offerId_) internal  {
    Offer memory offer = offersList[offerId_];
    uint256[] memory auxCollectionIds = getDecodedCollectionIds(offerId_);
    uint256[] memory auxTokenIds = getDecodedTokenIds(offerId_);
    for (uint256 i = 0; i < offer.collectionAddresses.length; i++) {
      if (offer.collectionAddresses[i] == tokenAddress) {
        require (tokenContract.hasOwnershipOf(auxCollectionIds[i], auxTokenIds[i], offer.seller),'M104');
        require( tokenContract.isApprovedForAll(offer.seller, address(this)), 'M116' );
        tokenContract.safeTransferFrom(
          offer.seller,
          _msgSender(),
          auxCollectionIds[i],
          auxTokenIds[i],
          ""
        );
      } else {
        require( IERC721(offer.collectionAddresses[i]).ownerOf(auxTokenIds[i]) == offer.seller , 'E413');
        require( IERC721(offer.collectionAddresses[i]).getApproved(auxTokenIds[i] ) == address(this), "M118" );
        IERC721(offer.collectionAddresses[i]).safeTransferFrom(offer.seller, _msgSender(), auxTokenIds[i],'');
      }
    }
  }

  /** 
   * @notice For buying a fixed offer & closing an auction
   * @param offerId_ The offer to buy
   * @param directBuy_ This is just for auctions. Indicate if the if is a direct purchase
   * @param hiddenId_ The Offer's fireBase Id.
   */
  function buyOffer(uint256 offerId_, bool directBuy_, string memory hiddenId_) public payable onlyActiveOffers(offerId_) onlyApprovedOffers(offerId_) {
    _validateBuyParams(offerId_, directBuy_);
    setInactive(offerId_);
    _sendFunds(offerId_); 
    _transactAllTokens(offerId_);
    emit OfferCompleted( offerId_, hiddenId_ );
  }
  
  /**
   * @notice Function to send founds {native or ERC20} to the user who create the offer
   * @param offerId_ The offer that wil be closed
  */
  function _sendFunds(uint256 offerId_) internal {
    /**
     * TODO  -- if the collection has royalties!
     * TODO  -- Send the funds to the user 
     */
    if (offersList[offerId_].paymentToken == address(0)) {
      (bool success, ) = payable(offersList[offerId_].seller).call{ value: getValue(offerId_) }("");
      require(success, "M117");
    } else 
      require ( IERC20(offersList[offerId_].paymentToken).transferFrom(
        _msgSender(),
        offersList[offerId_].seller,
        getValue(offerId_)
      ), 'tx sendFounds error');
  }

  //! --------------------------------------------------------------------------- BID IN AUCTION ---------------------------------------------------------------------------

  /**
   * @notice Function to validate bid parameters to bid in an auction
   * @param offerId_ The auction to check
   * @param value_ The value to chek
   */
  function _validateBidParams(uint256 offerId_, uint256 value_) internal view {
    require((value_ > 0) && (getMinBid(offerId_) < value_), 'M121');
    require(validateAuctionTime(offerId_));
  }

  /**
   * @notice Function to validate if the msg.sender have enougth balance to bid in an auction
   * @param offerId_ The auction to check
   * @param value_ The value to check
   */
  function _validateUserBalance(uint256 offerId_, uint256 value_) internal view {
    if (offersList[offerId_].paymentToken == address(0)) {
      require(value_ < _msgSender().balance, 'M123' );
    } else {
      require(value_ < IERC20(offersList[offerId_].paymentToken).balanceOf(_msgSender()), 'M124');
    }
  }

  /**
   * @notice function that allows to bid in an auction
   * @param offerId_ The auction id
   * @param value_ The value to bid
   */
  function bidForAuction(uint256 offerId_, uint256 value_) public onlyActiveOffers(offerId_) onlyApprovedOffers(offerId_) onlyAuctions(offerId_)  {
    _validateBidParams(offerId_, value_);
    _validateUserBalance(offerId_, value_);
    setMinBid(offerId_, value_);
    winner[offerId_] = _msgSender();
    emit BidForAuction(_msgSender(), offerId_, value_);
  }

  //! --------------------------------------------------------------------------- Encode  & Decode ---------------------------------------------------------------------------

   /**
   * @notice Function to encode {auction, endtime, min, value} in info's encoded parameter
   * @param auctionId_ ?
   * @param endTime_ time when auctions ends (just for auctions)
   * @param min_ min bid (just for auctions)
   * @param value_ the offer's value for purchase
   * @return finalValue_ the params encoded in a uint
   */
  function encodeValues(
    uint auctionId_,
    uint48 endTime_,
    uint96 min_,
    uint96 value_
  ) internal pure returns (uint finalValue_) {
    finalValue_ = (1 * (10 ** 75)) + (1 * (10 ** 74)) + (auctionId_ * (10 ** 73)) + (uint(endTime_) * (10 ** 58)) + (uint(min_) * (10 ** 29)) + (value_);
  }

  /**
   * @notice This is made to encode an array of uints and return just a uint
   * @param array_ is an array that has the ids to encode
   * @return aux have the ids encoded
   */
  function encode(uint[] memory array_) public pure returns (uint256 aux) {
    for (uint i; i < array_.length; ++i) {
      aux += array_[i] * (10 ** (i * 15));
    }
    aux += array_.length * 1e75;
  }


  /** 
   * @notice This is made to decode a uint an retunrn an array of ids
   * @param encoded_ This uint has encoded up to 5 ids that correspond to an array
   * @return tokenIds This array have the ids decoded
   */
  function decode(uint encoded_) public pure returns (uint[] memory tokenIds){
    uint cantidad = (encoded_ / 1e75) % 1e15;
    tokenIds = new uint[](cantidad); 
    for (uint i; i < cantidad; ++i){
      tokenIds[i] = (encoded_ / (10 ** (i * 15)) % 1e15);
    }
  }

  //! --------------------------------------------------------------------------- SETTERS ---------------------------------------------------------------------------

  /**
   * @notice validate an ERC721 collection
   * @param erc721_ collection address
   * @param validated_ new status of this ERC721 collection
   */
  function validateERC721(address erc721_, bool validated_) public onlyModerator {
    approvedERC721[erc721_] = validated_;
    emit ChangeStatusERC721(erc721_, _msgSender(), validated_);
  }
 
  /**
   * @notice This is made to approve a valid offer
   * @param offerId_ The offer id to validate
   */
  function approveOffer(uint offerId_) public onlyModerator onlyActiveOffers(offerId_) {
    approvedOffers[offerId_] = true;
    emit OfferApproved(offerId_);
  }

  /**
   * @notice function to set status active in an offer
   * @param offerId_ offerId to set active
   */
  function setInactive(uint offerId_) internal { 
    // TODO validar q este inactivo
    offersList[offerId_].info = offersList[offerId_].info - (1 * 1e74);
  }

  /**
   * @notice function to set the minBid in an auction
   * @param offerId_ the offer id to set the minBid
   * @param min the value to set
   */
  function setMinBid(uint offerId_, uint min) internal {
    offersList[offerId_].info = ((offersList[offerId_].info / 1e58) * 1e58 ) + (min * 1e29) + (offersList[offerId_].info % 1e15);
  }

   /**
   * @notice Function to deprecate any active offer
   * @param offerId_ The offer id to deprecate
   */
  function deprecateOffer(uint256 offerId_) public onlyModerator onlyActiveOffers(offerId_)  {
    setInactive(offerId_);
    emit OfferCancelled(offerId_);
  }

  /**
   * @notice Validate an ERC20 token as payment method
   * @param token_ The token address
   * @param validated_ If is validated or not
   */
  function validateERC20(address token_, bool validated_) public onlyVotationModule {
    validERC20[token_] = validated_;
    emit ERC20Validated(token_, validated_);
  }

//! --------------------------------------------------------------------------- GETTERS ---------------------------------------------------------------------------

   /**
   * @notice function to return the {isActive} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function isActive(uint offerId_) public view returns (bool) {
    return ((offersList[offerId_].info / 1e74) % 10) == 1 ? true : false;
  }

  /**
   * @notice function to return the {isAuction} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function isAuction(uint offerId_) public view returns (bool) {
    return ((offersList[offerId_].info / 1e73) % 10) == 1 ? true : false;
  }

  /**
   * @notice function to return the {endTime} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function getEndTime(uint offerId_) public view returns (uint) {
    return (offersList[offerId_].info / 1e58) % 1e15;
  }

  /**
   * @notice function to return the {minBid} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function getMinBid(uint offerId_) public view returns (uint) {
    return (offersList[offerId_].info / 1e29) % 1e15;
  }

  /**
   * @notice function to return the {value} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function getValue(uint offerId_) public view returns (uint) {
    return offersList[offerId_].info % 1e15;
  }

  /**
   * @notice Function to return the uitn that have the info encoded
   * @param offerId_ the offerId where we get the data
   */
  function getEncodedInfo(uint offerId_) public view returns(uint) {
    return offersList[offerId_].info;
  }

  /**
   * @notice Function to return the uint that have the tokenIds encoded
   * @param offerId_ the offerId where we get the data
   */
  function getEncodedTokenIds(uint offerId_) public view returns (uint) {
    return offersList[offerId_].tokenIds;
  }

  /**
   * @notice function to return an array of token Ids previusly encoded
   * @param offerId_ the offerId where we get the data
   */
  function getDecodedTokenIds(uint offerId_) public view returns (uint[] memory) {
     return decode(offersList[offerId_].tokenIds);
  }

  /**
   * @notice function to return the uint thah have the collectionIds encoded
   * @param offerId_ the offerId where we get the data
   */
  function getEncodedCollectionIds(uint offerId_) public view returns (uint) {
    return offersList[offerId_].collectionIds;
  }

  /**
   * @notice function to return an array of collection Ids previously encoded
   * @param offerId_ the offerId where we get the data
   */
  function getDecodedCollectionIds(uint offerId_) public view returns (uint[] memory){
    return decode(offersList[offerId_].collectionIds);
  }  
  
  /**
   * @notice Validates if an auction is still valid or not
   * @param offerId_ The auction
   * @return valid if it is valid or not
   */
  function validateAuctionTime(uint256 offerId_) public view onlyAuctions(offerId_) returns (bool) {
    return getEndTime(offerId_) > block.timestamp;
  }

  /**
   * @notice Function to check if {token_} is a validERC20 for payment method
   * @param token_ The token address
   * @return bool if {token_} is valid
   */
  function isValidERC20(address token_) public view returns (bool) {
    return validERC20[token_];
  }

  // TODO ---- Crear function SET WINNER (para cambiar el winner de la subasta si el WINNER se gastó los fondos
  // TODO ---- Function setAsWinner(address bidder_) public onlyModerators {}
}