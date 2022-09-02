/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IModule {
  function getModule(uint256 module_) external view returns (address);
}

interface IRoles {
  function isVerifiedUser(address user_) external returns (bool);
  function isModerator(address user_) external returns (bool);
  function isUser(address user_) external returns (bool);
}

interface ICollections {
  function hasOwnershipOf(uint256 collection_, uint256 tokenId_, address owner_) external view returns (bool);
  function isApprovedForAll(address account, address operator) external view returns (bool);
  function safeTransferFrom(address from, address to, uint256 collection, uint256 id, bytes memory data) external;
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to,uint256 amount) external returns (bool);
}


interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function getApproved(uint256 tokenId) external view returns (address operator);
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
 * @notice The interface to implement in the market contract
 */
interface IMarket {
  /**
   * 
   */
  enum State {
    CREATED,
    APPROVED,
    CANCELLED,
    COMPLETED
  }

  /**
   * @notice Struct created when a NFT is listed for a fixed price
   * @param id Fixed offer id
   * @param hiddenId The address that sells the NFT (owner or approved)
   */
  event OfferCreated(
    uint256 id,
    string hiddenId
  );

  /**
   * @notice When an offer is completed
   * @param id Offer id
   * @param hiddenId a
   */
  event OfferCompleted(
    uint id,
    string hiddenId
  );

  /**
   * @notice When a fixed offer is approved
   * @param offerId The offer approved
   */
  event OfferApproved(uint256 offerId);

  /**
   * @notice When a fixed offer is cancelled
   * @param offerId The offer cancelled
   */
  event OfferCancelled(uint256 offerId);
}

/**
 * @notice Market logic
 */
contract Market is IMarket {
  /**
   * @notice The module manager interface
   */
  IModule moduleManager;

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
   * @notice Amount of offers
   */
  uint256 public offersCount;

  /**
   * @notice List of offers
   */
  mapping(uint256 => Offer) public offersList;

  /**
   * @notice Winner of the auction
   */
  mapping(uint256 => address) public winner;
  /**
   * @notice List of approved offers
   */
  mapping(uint256 => bool) public approvedOffers;

  /**
   * @notice If the ERC20 is a valid token to accept
   */
  mapping(address => bool) public validERC20;

  /**
   * @notice list ERC721 approved
   */
  mapping(address => bool) public approvedERC721;

  /**
   * @notice Struct created when a NFT is listed for a fixed price
   * @param info
   * @param collection 
   * @param tokenId 
   * @param collectionAddress Address of the NFT
   * @param paymentToken Token to accept for the listing
   * @param seller The address that sells the NFT (owner or approved)
   * @dev If the paymentToken is address(0), pays in native token
   */
  struct Offer {
    uint256 info;
    uint256 collectionIds;
    uint256 tokenIds;
    address[] collectionAddresses;
    address paymentToken;
    address seller;
  }

  /**
   * @notice Event for when someone bid in an auction
   */
  event BidForAuction(address who, uint256 offerId, uint256 amount);

  /**
   * @notice COMPLETAR
   */
  event ChangeStatusERC721(address ERC721, address who, bool newStatus);

  /**
   * @notice COMPLETAR
   */
  event ApprovedOffer(uint offerId, address who);

  /**
   * @notice Event triggered when an ERC20 address is validated (or not)
   */
  event ERC20Validated(address token, bool valid);
  
  /**
   * @notice Only offers that are approved by a moderator/admin
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
   * @notice Only users or verified users
   */
  modifier onlyUsers() {
    require(rolesContract.isUser(msg.sender) || rolesContract.isVerifiedUser(msg.sender), 'E811');
    _;
  }

  modifier onlyActiveOffers(uint256 offerId_) {
    require(isActive(offerId_), 'M113');
    _;
  }

  modifier onlyModerator(){
    require(rolesContract.isModerator(msg.sender), 'M120');
    _;
  }

  modifier onlyAuctions(uint256 offerId_) {
    require(isAuction(offerId_), 'M110');
    _;
  }

  modifier onlyVotationModule(){
    require(msg.sender == moduleManager.getModule(3), 'M133');
    _;
  }

  /**
   * @notice Builder
   * @param module_ Module manager
   */
  constructor(address module_) {
    moduleManager = IModule(module_);
    address roles = moduleManager.getModule(0);
    tokenAddress = moduleManager.getModule(1);
    rolesContract = IRoles(roles);
    tokenContract = ICollections(tokenAddress);
  }

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

  //valida ownership & approvals
  function _validateOwnership( 
    uint256[] memory collections_,
    uint256[] memory tokenIds_,
    address[] memory collectionAddresses_
  ) internal view returns (bool flag, bool mixed) { //address aprovadas y address todas beru
    uint counter;
    for (uint256 i; i < collectionAddresses_.length; i++) {
      if (collectionAddresses_[i] == tokenAddress) {
        require(tokenContract.hasOwnershipOf(collections_[i], tokenIds_[i], msg.sender), 'M104');
        // Solo una vez
        if (counter == 0) require(tokenContract.isApprovedForAll(msg.sender, address(this)), 'M105');
        counter++;
      } else {
        require(IERC721(collectionAddresses_[i]).ownerOf(tokenIds_[i]) == msg.sender , 'E413');
        require(IERC721(collectionAddresses_[i]).getApproved( tokenIds_[i] ) == address(this), 'E407');
        if (!approvedERC721[collectionAddresses_[i]] && !flag) flag = true; //para que no escriba + veces
      }
    }
    mixed = counter != collectionAddresses_.length;
  }

  /**
   * @notice Function to create offers
   * @param isAuction_ If it is auction
   * @param minBid_ Min bid allowed
   * @param tokenIds_ Token to sell
   * @param value_ Value of the token
   * @param collectionAddresses_ Token address
   * @param paymentToken_ You can ask for USDT, DAI or Matic/Ether
   * @dev If the paymentToken is address(0), pays in native token
   * @dev NOTE: Not compatible with ERC1155
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
    // Check ownership
    (bool notApproved, bool mixed) = _validateOwnership(collections_, tokenIds_, collectionAddresses_);
    if (!notApproved || !mixed) approvedOffers[offersCount] = true;
    // Create offer
    offersList[offersCount] = Offer(
      encodeValues(isAuction_ ? 1 : 0, endTime_, minBid_, value_),
      encode(collections_),
      encode(tokenIds_),
      collectionAddresses_,
      paymentToken_,
      msg.sender //seller
    );
    emit OfferCreated(offersCount, hiddenId_);
    offersCount++;
  }

  function encodeValues(uint auction, uint48 endtime, uint96 min, uint96 value) internal pure returns (uint finalValue) {
    finalValue = (1 * (10 ** 75)) + (1 * (10 ** 74)) + (auction * (10 ** 73)) + (uint(endtime) * (10 ** 58)) + (uint(min) * (10 ** 29)) + (value);
  }


  // ---------------------------------------------- SETS
  function setInactive(uint offer) internal { //validar q este inactivo
    offersList[offer].info = offersList[offer].info - (1 * 1e74);
  }

  function setMinBid(uint offer, uint min) internal {
    offersList[offer].info = ((offersList[offer].info / 1e58) * 1e58 ) + (min * 1e29) + (offersList[offer].info % 1e15);
  }

 // ------------------------------------------ ENCODE & DECODE  ---- VIEW METHODS

  function isActive(uint offer) public view returns (bool) {
    return ((offersList[offer].info / 1e74) % 10) == 1 ? true : false;
  }

  function isAuction(uint offer) public view returns (bool) {
    return ((offersList[offer].info / 1e73) % 10) == 1 ? true : false;
  }

  function getEndTime(uint offer) public view returns (uint) {
    return (offersList[offer].info / 1e58) % 1e15;
  }

  function getMinBid(uint offer) public view returns (uint) {
    return (offersList[offer].info / 1e29) % 1e15;
  }

  function getValue(uint offer) public view returns (uint) {
    return offersList[offer].info % 1e15;
  }

  function getEncodedInfo(uint offer) public view returns(uint) {
    return offersList[offer].info;
  }

  function getEncodedTokenIds(uint offer) public view returns (uint) {
    return offersList[offer].tokenIds;
  }

  function getDecodedTokenIds(uint offer) public view returns (uint[] memory) {
     return decode(offersList[offer].tokenIds);
  }

  function getEncodedCollectionIds(uint offer) public view returns (uint) {
    return offersList[offer].collectionIds;
  }

  function getDecodedCollectionIds(uint offer) public view returns (uint[] memory){
    return decode(offersList[offer].collectionIds);
  }

  function _validateBuyParams(uint256 offerId_) internal view {
    Offer memory offer = offersList[offerId_];
    if (isAuction(offerId_)) {
      require(!validateAuctionTime(offerId_), 'M111');  // Check if caller is the winner and if it is ended
      require(msg.sender == winner[offerId_], 'M112');
    }
    if (offer.paymentToken == address(0)) {
      require(msg.value >= getValue(offerId_), 'M114');// Not enought sended
    } else {
      require( IERC20(offer.paymentToken).allowance( msg.sender, address(this) ) >= getValue(offerId_),'M115');   // Not enought allowance
    }
  }

  function _transactAllTokens(uint256 offerId_) internal  {
    Offer memory offer = offersList[offerId_]; //??????????????????????????MODIFICAS??
    uint256[] memory auxCollectionIds = getDecodedCollectionIds(offerId_);
    uint256[] memory auxTokenIds = getDecodedTokenIds(offerId_);
    for (uint256 i = 0; i < offer.collectionAddresses.length; i++) {
      if (offer.collectionAddresses[i] == tokenAddress) {
        require (tokenContract.hasOwnershipOf(auxCollectionIds[i], auxTokenIds[i], offer.seller),'M104');
        require( tokenContract.isApprovedForAll(offer.seller, address(this)), 'M116' );
        tokenContract.safeTransferFrom(
          offer.seller,
          msg.sender,
          auxCollectionIds[i],
          auxTokenIds[i],
          ""
        );
      } else {
        require( IERC721(offer.collectionAddresses[i]).ownerOf(auxTokenIds[i]) == offer.seller , 'E413');
        require( IERC721(offer.collectionAddresses[i]).getApproved( auxTokenIds[i] ) == address(this), "M118" );
        IERC721(offer.collectionAddresses[i]).safeTransferFrom(offer.seller, msg.sender, auxTokenIds[i],'');
      }
    }
  }

  /*
   * @notice For buying a fixed offer & closing an auction
   * @param offerId_ The offer to buy
   * @dev Requires ERC20 allowance
   */
  function buyOffer(uint256 offerId_, string memory hiddenId_) public payable onlyActiveOffers(offerId_) onlyApprovedOffers(offerId_) {
    _validateBuyParams(offerId_);
    setInactive(offerId_);// Set the offer as inactive
    sendFunds(offerId_); // Send funds to user
    _transactAllTokens(offerId_);// Transact all tokens
    emit OfferCompleted( offerId_, hiddenId_ );
  }
  
  /**
   * @notice Internal function to native or ERC20 funds
   * @param offerId_ The offer that will be closed
  */
  function sendFunds(uint256 offerId_) internal {
    // Check if the collection has royalties!
    // Send the funds to the user
    if (offersList[offerId_].paymentToken == address(0)) {
      (bool success, ) = payable(offersList[offerId_].seller).call{
        value: getValue(offerId_)
      }("");
      require(success, "M117");
    } else 
      require ( IERC20(offersList[offerId_].paymentToken).transferFrom(
        msg.sender,
        offersList[offerId_].seller,
        getValue(offerId_)
      ), 'tx sendFounds error');
  }

  /**
   * @notice Deprecate offer, it does not matter if it is a fixed offer or an auction
   * @param offerId_ The offer id to deprecate
   */
  function deprecateOffer(uint256 offerId_) public onlyModerator onlyActiveOffers(offerId_)  {
    setInactive(offerId_);
    emit OfferCancelled(offerId_);
  }

  function _validateBidParams(uint256 offerId_, uint256 value_) internal view {
    require((value_ > 0) || (getMinBid(offerId_) < value_), 'M121');
    require(validateAuctionTime(offerId_));
  }

  function _validateUserBalance(uint256 offerId_, uint256 value_) internal view {
    if (offersList[offerId_].paymentToken == address(0)) {
      require(value_ < msg.sender.balance, 'M123' );
    } else {
      require(value_ < IERC20(offersList[offerId_].paymentToken).balanceOf(msg.sender), 'M124'); /// QUE? chequea el balance del msgSender???
    }
  }

  /**
   * @notice Bid for an auction
   * @param offerId_ The auction
   * @param value_ The value to bid
   */
  function bidForAuction(uint256 offerId_, uint256 value_) public onlyActiveOffers(offerId_) onlyApprovedOffers(offerId_) onlyAuctions(offerId_)  {
    _validateBidParams(offerId_, value_);
    _validateUserBalance(offerId_, value_);
    setMinBid(offerId_, value_);
    winner[offerId_] = msg.sender;
    emit BidForAuction(msg.sender, offerId_, value_);
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
   * @notice Validate an ERC20 token as payment method
   * @param token_ The token address
   * @param validated_ If validated or not
   * @dev Only via votation
   */
  function validateERC20(address token_, bool validated_) public onlyVotationModule {
    validERC20[token_] = validated_;
    emit ERC20Validated(token_, validated_);
  }
  
  /**
   * @notice Function to refresh the addresses used in this contract
   * @dev This must be called by votation module
   */
  function refresh() public onlyVotationModule {
    address roles = moduleManager.getModule(0);
    tokenAddress  = moduleManager.getModule(1);
    tokenContract = ICollections(tokenAddress);
    rolesContract = IRoles(roles);
  }

  /**
   * @notice validate an ERC721 collection
   * @param erc721_ collection address
   * @param validated_ new status of this ERC721 collection
   * @notice status change the status of this ERC721 to true or false
   */
  function validateERC721(address erc721_, bool validated_) public onlyModerator {
    approvedERC721[erc721_] = validated_;
    emit ChangeStatusERC721(erc721_, msg.sender, validated_);
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
   */
  function encode(uint[] memory tokenIds_) public pure returns (uint256 aux) {
    for (uint i; i < tokenIds_.length; ++i) {// Cicla y suma el tokenId con 15 digitos
      aux += tokenIds_[i] * (10 ** (i * 15));
    }
    aux += tokenIds_.length * 1e75;// Pone la cantidad de tokens al principio para poder descomprimir
  }

  /**
  
  */
  function decode(uint encoded_) public pure returns (uint[] memory tokenIds){
    uint cantidad = (encoded_ / 1e75) % 1e15;  // Parseo la cantidad de tokens resultantes
    tokenIds = new uint[](cantidad); 
    for (uint i; i < cantidad; ++i){// Parseo el resto de ids
      tokenIds[i] = encoded_ / (10 ** (i * 15) % 1e15);
    }
  }

  // Crear function SET WINNER (para cambiar el winner de la subasta si el WINNER se gastó los fondos
  // function setAsWinner(address bidder_) public onlyModerators {}
}