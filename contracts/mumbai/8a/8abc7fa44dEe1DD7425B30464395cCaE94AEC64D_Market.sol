// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './Context.sol';

/**
 * @notice Connection's interface with Roles SC
 */
interface IRoles {
  function isVerifiedUser(address user_) external returns (bool);
  function isModerator(address user_) external returns (bool);
  function isUser(address user_) external returns (bool);
}

/**
 * @notice Connection's interface with ERC20 SC
 */
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to,uint256 amount) external returns (bool);
}

/**
 * @notice Connection's interface with ERC721 SC
 */
interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
  function getRoyalties() external view returns (uint); 
  function deployer() external view returns (address);
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
   * @notice Amount of offers (counter)
   */
  uint256 public offersCount;

  /**
   * @notice List of offers
   */
  mapping(uint256 => Offer) public offersList;

  /**
   * @notice List of actions winners
   */
  mapping(uint256 => address) public auctionWinners;

  /**
   * @notice List of approved offers
   */
  mapping(uint256 => bool) public approvedOffers;

  /**
   * @notice If of valid ERC20 tokens
   */
  mapping(address => bool) public validERC20;

  /**
   * @notice List of ERC721 approved
   */
  mapping(address => bool) public approvedERC721;

  //! BORARR
  address public beruWallet;
  //!BORRAR 

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
    uint256 tokenIds;
    address[] collectionAddresses;
    address paymentToken;
    address seller;
  }

  //! --------------------------------------------------------------------------- EVENTS ---------------------------------------------------------------------------

  /**
   * @notice Event triggered when someone bid in an auction
   */
  event BiddedForAuction(address who, uint256 offerId, uint256 amount, string id);

  /**
   * @notice Fired when an auction winner is changed because the wallet has no funds (or not sufficient)
   */
  event ChangedWinner(uint offerId, address newWinner);

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

  /**
   * @notice Event triggered when the founds were sent
   */
  event FoundsSended(uint256 beruRoyalities , uint256 creatorsRoyalities , uint256 sellerFounds);
  //TODO añadir eventos individuales para cada transferencia a cada creator

  /**
   *@notice Event triggered when the royalities wer sent
   */
  event RoyalitiesSended(address to, uint256 amount);
  
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
  modifier onlyUsers {
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
  modifier onlyModerator {
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
  modifier onlyVotationModule {
    require(_msgSender() == moduleManager.getModule(3), 'M133');
    _;
  }

  /**
   * @notice Builder
   * @param module_ Module manager
   */
  constructor(address module_, address wallet_) Context(module_) {
    moduleManager = IModule(module_);
    address roles = moduleManager.getModule(0);
    rolesContract = IRoles(roles);
    beruWallet = wallet_;
  }

  /**
   * @notice Function to refresh the addresses used in this contract
   */
  function refresh() public onlyVotationModule {
    address roles = moduleManager.getModule(0);
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
   * @param paymentToken_ You can ask for USDT, DAI or Matic/Ether
  */
  function _validateCreateParams( 
    bool isAuction_,
    uint48 endTime_,
    uint96 minBid_,
    uint96 value_,
    uint256[] memory tokenIds_,
    address[] memory collectionAddresses_,
    address paymentToken_ 
  ) internal view {
    require (tokenIds_.length == collectionAddresses_.length , 'E806'); // * ADDED
    require(tokenIds_.length < 6,'M127');
    require((value_ > 0) && (isValidERC20(paymentToken_)), 'M102');
    if (isAuction_) require((endTime_ > block.timestamp + 3600) && (value_ > minBid_), 'M103');
  }

  /**
   * @notice function to validate the ownership of the tokens of an offer
   * @param tokenIds_ array of token's ids
   * @param collectionAddresses_ array of collecti's addresesss
   * @return flag true if the offer have unapproved collection addresses
   */
  function _validateOwnership(uint256[] memory tokenIds_, address[] memory collectionAddresses_) internal view returns (bool flag) {
    for (uint256 i; i < collectionAddresses_.length; i++) {
      require(IERC721(collectionAddresses_[i]).ownerOf(tokenIds_[i]) == _msgSender(), 'E413');
      require(IERC721(collectionAddresses_[i]).isApprovedForAll(_msgSender(), address(this)), 'M118');
      // *just once
      if (!approvedERC721[collectionAddresses_[i]] && !flag) flag = true;
    }
  }

  /**
   * @notice Function to create offers 
   * @param isAuction_ If it is auction
   * @param endTime_ time when offers ends (just for auction)
   * @param minBid_ Min bid allowed
   * @param tokenIds_ array of token's ids to sell
   * @param value_ Value of the offer
   * @param collectionAddresses_ array of collections's addresses
   * @param paymentToken_ You can ask for USDT, DAI or Matic/Ether
   * @param hiddenId_ Offre's id in fireBase
   */
  function createOffer(
    bool isAuction_,
    uint48 endTime_,
    uint96 minBid_,
    uint96 value_,
    uint256[] memory tokenIds_,
    address[] memory collectionAddresses_,
    address paymentToken_,
    string memory hiddenId_
  ) public onlyUsers {
    _validateCreateParams(isAuction_, endTime_, minBid_, value_, tokenIds_, collectionAddresses_, paymentToken_);
    bool notApproved = _validateOwnership(tokenIds_, collectionAddresses_);
    if (!notApproved) approvedOffers[offersCount] = true;
    offersList[offersCount] = Offer(
      encodeValues(isAuction_ ? 1 : 0, endTime_, minBid_, value_),
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
      require(_msgSender() == auctionWinners[offerId_], 'M112');
    }
    if (offer.paymentToken == address(0)) {
      require(msg.value >= getValue(offerId_), 'M114'); // Not enought sended
    } else {
      require(IERC20(offer.paymentToken).allowance(_msgSender(), address(this) ) >= getValue(offerId_),'M115'); // Not enought allowance
    }
  }

  /**
   * @notice Function to transanc all tokens bought 
   * @param offerId_ The offer bought
   */
  function _transactAllTokens(uint256 offerId_) internal  {
    Offer memory offer = offersList[offerId_];
    uint256[] memory auxTokenIds = getDecodedTokenIds(offerId_);
    // TODO recorrer arreglo collections (proxys) instanciarlos verificar ownerships y transferir
    for (uint256 i = 0; i < offer.collectionAddresses.length; i++) {
      require(IERC721(offer.collectionAddresses[i]).ownerOf(auxTokenIds[i]) == offer.seller , 'E413');
      require(IERC721(offer.collectionAddresses[i]).isApprovedForAll(offer.seller, address(this)), 'M118');
      IERC721(offer.collectionAddresses[i]).safeTransferFrom(offer.seller, _msgSender(), auxTokenIds[i], '');
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
    _splitFounds(offerId_, getValue(offerId_)); //* ADDED
    _transactAllTokens(offerId_);
    emit OfferCompleted(offerId_, hiddenId_);
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
   * @notice Function to validate if the _msgSender() have enough balance to bid in an auction
   * @param offerId_ The auction to check
   * @param value_ The value to check
   */
  function _validateUserBalance(uint256 offerId_, uint256 value_) internal view {
    uint balance = getActualBalance(_msgSender(), offersList[offerId_].paymentToken);
    require(value_ < balance, 'M123');
  }

  /**
   * @notice function that allows to bid in an auction
   * @param offerId_ The auction id
   * @param value_ The value to bid
   */
  function bidForAuction(uint256 offerId_, uint256 value_, string memory id) public onlyActiveOffers(offerId_) onlyApprovedOffers(offerId_) onlyAuctions(offerId_)  {
    _validateBidParams(offerId_, value_);
    _validateUserBalance(offerId_, value_);
    setMinBid(offerId_, value_);
    auctionWinners[offerId_] = _msgSender();
    emit BiddedForAuction(_msgSender(), offerId_, value_, id);
  }

  //! ------------------------------------------------------------------------- ROYALITIES --------------------------------------------------------------------------

  function _sendFounds(uint256 offerId_,address to_, uint256 value_) internal {
    if (offersList[offerId_].paymentToken == address(0)) {
      (bool success, ) = payable(offersList[offerId_].seller).call{value: value_}('');
      require(success, 'M117');
    } else {
      require(IERC20(offersList[offerId_].paymentToken).transferFrom(_msgSender(), to_, getValue(offerId_)), 'M');
    }
  }

  /**
  * @notice Function to transfer royalities to Beru { wallet }
  * @param value_ amount from which the commission percentage is calculated
  * @return toBeru amount tranfered to beru
  */
  function _sendRoyalitiesToBeru(uint256 offerId_, uint256 value_)  internal returns (uint256 toBeru) {
    toBeru = value_ * 35 / 1000 ; // %3.5
    _sendFounds(offerId_, beruWallet, toBeru); // ?agregar beruWallet
    emit RoyalitiesSended(beruWallet, toBeru); // ?agregar beruWallet
  }


  /**
  * @notice Function to send royalities to the NFT's creators 
  * @param offerId_ offer involved
  * @param value_  price paid for the offer
  * @return toCreators amount of roayalities transfered to creators
  */
  function _sendRoyalitiesToCreators(uint256 offerId_, uint256 value_)  internal returns (uint256 toCreators) {
    address[] memory collectionAddress_ = offersList[offerId_].collectionAddresses;
    uint256 aux = value_ / collectionAddress_.length; // * Poruqe vamos a dividir el valor total de la oferta por la cantidad de tokens
    for(uint i = 0; i < collectionAddress_.length; i++) {
      IERC721 proxy = IERC721(collectionAddress_[i]);
      if (proxy.getRoyalties() > 0) {
        uint256 toTransfer = aux * proxy.getRoyalties();
        _sendFounds(offerId_,proxy.deployer(), value_);
        toCreators += toTransfer;
        emit RoyalitiesSended(proxy.deployer(), toTransfer);
      }
    }
  }

  /**
  * @notice function to send founsd and royalities to collectio's creators, beru and the seller
  * @param offerId_ the offer finished and bought
  * @param value_ price paid for the offer
  */
  function _splitFounds(uint256 offerId_, uint256 value_)  internal {
    uint256 royalitiesToBeru = _sendRoyalitiesToBeru(offerId_,value_);
    uint256 royalitiesToCreators = _sendRoyalitiesToCreators(offerId_,value_);
    uint256 foundsToSeller = value_ - royalitiesToBeru - royalitiesToCreators;
    _sendFounds(offerId_, offersList[offerId_].seller , foundsToSeller);
    emit FoundsSended(royalitiesToBeru , royalitiesToCreators , foundsToSeller);
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
    return offersList[offerId_].info % 1e29;
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

  /**
   * @notice Helper function that returns the balance of {who} in {paymentToken} token
   * @param who Address to check balance
   * @param paymentToken Address of the token to check
   */
  function getActualBalance(address who, address paymentToken) public view returns (uint balance) {
    if (paymentToken == address(0))
      balance = address(who).balance;
    else balance = IERC20(paymentToken).balanceOf(who);
  }

  /**
   * @notice Function to set {bidder_} as winner of the auction {offerId_}
   * @param offerId_ Offer index
   * @param bidder_ The consecuent highest bidder of the auction 
   */
  function setWinner(uint offerId_, address bidder_) public onlyModerator {
    // Get the balance & check that the actual winner is not sufficient
    // Finally, set {bidder_} as winner.
    // Note: This function is intended to be called ONE time.
    // It will not let a moderator set any wallet.
    // {bidder_} MUST have balance
    (uint winnersBalance, uint bidderBalance) = 
      (
        getActualBalance(auctionWinners[offerId_], offersList[offerId_].paymentToken),
        getActualBalance(bidder_, offersList[offerId_].paymentToken)
      );
    require((winnersBalance < getValue(offerId_)) && (getValue(offerId_) <= bidderBalance));
    auctionWinners[offerId_] = bidder_;
    emit ChangedWinner(offerId_, bidder_);
  }

}