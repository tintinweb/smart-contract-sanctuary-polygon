// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.11;

import "./CardNFT.sol";
import "./Collection.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "hardhat/console.sol";

/**
 * @title Marketplace
 *
 * @notice ERC721 token marketplace. Includes seller and buyer market
 */
contract Marketplace is ERC721Holder, Ownable {
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
    string name;
    uint256 ask;
    uint256 offerMinPrice;
    uint256 highestOffer;
    address highestOfferor;
    uint256 highestOfferGuarantee;
    uint256 highestOfferExpiration;
  }

  /**
   * @notice Represents a buy order in the marketplace
   *
   * Each buy order has an owner, the creator of the order
   * which cannot be changed and a card type property signifying
   * which type of card the owner wants to buy
   *
   * It also has an bid price the owner wants to pay for the card
   * Users can either fulfil this order at bid price or make a
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
    uint256 lowestOffer;
    address lowestOfferor;
    uint256 lowestOfferCardId;
    uint256 lowestOfferGuarantee;
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
   * @notice Marketplace fee that goes to DAO
   *
   * @dev 3 decimal precision - e.g. 50000 = 50%
   */
  uint256 private daoFee;

  /**
   * @notice Card NFT used in the game
   */
  CardNFT public card;

  /**
   * @notice DAO address where fees are paid
   */
  address payable public daoAddress;

  /**
   * @notice min amount of hours before which offer can not be withdrawn
   */
  uint256 minOfferGuaranteeHours = 48 hours;

  /**
   * @notice Initiates the marketplace
   */
  constructor(address _card, address payable _daoAddress, uint256 _daoFee) {
    card = CardNFT(_card);
    daoAddress = _daoAddress;
    daoFee = _daoFee;
  }

  /**
	 * @dev Fired in changeReserveFee()
   *
   * @param by address that changed the reserve fee
   * @param oldDaoFee old value of reserve fee before change
   * @param newDaoFee new value of reserve fee after change
   */
  event FeesChanged(
    address by,
    uint256 oldDaoFee,
    uint256 newDaoFee
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
	 * @dev Fired in acceptSellOrderHighestOffer(), fulfilSellOrder()
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
	 * @dev Fired in acceptBuyOrderLowestOffer(), sellBuyOrder()
   *
   * @param owner buy order creator
   * @param orderId ID of buy order
   * @param cardCollection collection of card owner wanted to buy
   * @param cardType type of card owner wanted to buy
   * @param seller address selling the buy order
   * @param price price the buy order was fulfilled at
   * @param bid price owner wanted to buy card at
   */
  event BuyOrderFulfilled(
    address indexed owner,
    bytes32 orderId,
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
  event BuyOrderCancelled(
    address indexed owner,
    bytes32 orderId
  );

  /**
* @dev Fired in cancelOfferOnSellOrder()
   *
   * @param orderId ID of sell order
   */
  event SellOrderOfferCancelled(
    bytes32 orderId
  );

  /**
* @dev Fired in cancelOfferOnBuyOrder()
   *
   * @param orderId ID of sell order
   */
  event BuyOrderOfferCancelled(
    bytes32 orderId
  );

  /**
   * @dev Checks whether a provided card type is
   *         valid (in range [1, 53])
   *
   * @param _cardType the card type to check
   */
  modifier validCardType(uint8 _cardType) {
    require(_cardType >= 1 && _cardType <= 53, "card type must be in range [1, 53]");
    _;
  }

  /**
   * @dev Checks whether message sender is not a contract
   */
  modifier onlyIfSenderNotContract() {
    require(!msg.sender.isContract(), "contract caller not allowed");
    _;
  }

  /**
	 * @dev Checks whether sell order exists
   *
   * @param _orderId order ID to check existence
   */
  modifier sellOrderExists(bytes32 _orderId) {
    require(sellOrders[_orderId].owner != address(0), "sell order does not exist");
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
    require(buyOrders[_orderId].owner != address(0), "buy order does not exist");
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
   * @notice Changes marketplace fee that is
   *         sent to the Game reserve and the
   *         DAO
   *
   * @dev 3 decimal precision - e.g. 50000 = 50%
   *
   * @param _daoFee new DAO fee value
   */
  function changeFees(uint256 _daoFee) external onlyOwner {
    // Emit event
    emit FeesChanged(msg.sender,  daoFee, _daoFee);
    // Change storage values to new values
    
    daoFee = _daoFee;
  }

  /**
   * @notice Changes min offer guarantee hours config
   *   *
   * @param _hours number of hours
   */
  function setMinOfferGuaranteeHours(uint256 _hours) external onlyOwner {
    require(_hours >= 24, "can not be less that 24 hours");
    minOfferGuaranteeHours = _hours * 60 * 60;
  }

  /**
   * @dev Pays out fees to reserve and DAO from
   *      amount and returns the amount without
   *      the fees
   *
   * @param _amount amount to deduct fees from
   * @param _collectionAddress the address of collection to get marketplace fee
   * @param _collectionPartnerDaoAddress the address of collection partner to send fees
   * @return amount with fees deducted
   */
  function takeFeesFrom(uint256 _amount, address _collectionAddress, address payable _collectionPartnerDaoAddress) internal returns (uint256) {
    // Get marketplaceFee using smart contract address
    uint marketplaceFee = Collection(_collectionAddress).marketplaceFeePercent();
    uint256 marketplaceFeeValueWithDiscount = 0;
    if (marketplaceFee > 0) {
      //Send % to dao
        uint256 marketplaceFeeValue = _amount * marketplaceFee / 100_000;
        marketplaceFeeValueWithDiscount = Collection(_collectionAddress).checkDiscount(marketplaceFeeValue);
        if(marketplaceFeeValueWithDiscount > 0){
          uint256 partnerMarketplaceFeePercentValue = 0;
              if(_collectionPartnerDaoAddress.isContract()){
                uint partnerMarketplaceFeePercent = Collection(_collectionAddress).partnerMarketplaceFeePercent();
                if (partnerMarketplaceFeePercent > 0) {
                  //Send % to partner Dao
                  partnerMarketplaceFeePercentValue = marketplaceFeeValueWithDiscount * partnerMarketplaceFeePercent / 100_000;
                  (bool success, ) = payable(_collectionPartnerDaoAddress).call{value: partnerMarketplaceFeePercentValue}("");
                  marketplaceFeeValueWithDiscount -= partnerMarketplaceFeePercentValue;
                }
            }   
          //Send % to Dao 
          (bool success, ) = payable(daoAddress).call{value: marketplaceFeeValueWithDiscount}(""); 
      }
    }
    return _amount - marketplaceFeeValueWithDiscount;
  }

  /**
   * @notice Creates a sell order
   *
   * @param _assetIds array of card IDs to sell
   * @param _ask price of cards. if 0 then open to offers
   * @param _name name of cards if bundle. else empty
   *
   * @return the order ID
   */
  function createSellOrder(
    uint256[] calldata _assetIds,
    uint256 _ask,
    uint256 offerMinPrice,
    string memory _name
  ) external onlyIfSenderNotContract returns (bytes32) {
    require(_assetIds.length > 0, "provide at least one card ID");

    if(_assetIds.length == 1) {
      require(bytes(_name).length == 0, "cannot provide name with one card");
    } else {
      require(bytes(_name).length > 0, "please provide a name for the bundle sell order");
    }

    // Transfer each sent card to the Marketplace contract
    for(uint256 i = 0; i < _assetIds.length; i++) {
      // Will revert if user does not own card or if has not approved
      // Marketplace contract for trading
      card.safeTransferFrom(msg.sender, address(this), _assetIds[i]);
    }

    // Generate pseudorandom order ID
    bytes32 orderId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _assetIds, _ask, _name));

    // Insert order in mapping
    sellOrders[orderId] = SellOrder({
      owner: msg.sender,
      assetIds: _assetIds,
      name: _name,
      ask: _ask,
      offerMinPrice: offerMinPrice,
      highestOffer: 0,
      highestOfferor: address(0),
      highestOfferGuarantee: 0,
      highestOfferExpiration: 0
    });

    // Emit event
    emit SellOrderCreated(
      msg.sender,
      orderId,
      _name,
      _assetIds,
      _ask,
      offerMinPrice
    );

    // Return the order ID
    return orderId;
  }


  /**
   * @notice Cancel sell order
   *
   * @dev Restricted to sell order owner
   *
   * @param _orderId order which the owner wants to cancel
  */
  function cancelSellOrder(bytes32 _orderId) external sellOrderExists(_orderId) senderOwnsSellOrder(_orderId) {
    SellOrder memory sellOrder = sellOrders[_orderId];
    delete sellOrders[_orderId];

    if(sellOrder.highestOfferor != address(0) && !sellOrder.highestOfferor.isContract()) {
      // Refund offeror
      payable(sellOrder.highestOfferor).call{value: sellOrder.highestOffer}("");
    }

    for(uint256 i = 0; i < sellOrder.assetIds.length; i++) {
      card.safeTransferFrom(address(this), msg.sender, sellOrder.assetIds[i]);
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
   *         Ether is placed in escrow
   *
   * @param _orderId order ID where the offer is to be placed
   * @param _offerGuarantee offer guaranteed up to this point.
   *                        must be at least minOfferGuaranteeHours hours in the future
  */
  function placeOfferOnSellOrder(
    bytes32 _orderId,
    uint256 _offerGuarantee,
    uint256 _offerExpiration
  ) external payable onlyIfSenderNotContract sellOrderExists(_orderId) {
    // Get sell order
    SellOrder storage sellOrder = sellOrders[_orderId];

    require(msg.value > 0, "offer value must grater than 0");

    // If the sell order is not open to offers without an ask price
    if(sellOrder.ask != 0) {
      // Ensure the offer value is less than the order ask
      require(msg.value < sellOrder.ask, "offer value must be less than order ask");
    }
    if(sellOrder.ask == 0 && sellOrder.offerMinPrice > 0){
      require(msg.value >= sellOrder.offerMinPrice, "offer value must be higher than offer min price");
    }

    // Ensure the value of the new offer is higher than the current
    require(msg.value > sellOrder.highestOffer, "offer value must be higher than current");

    // Ensure the offer guarantee period for which the offeror cannot withdraw
    // is at least minOfferGuaranteeHours hours in the future
    require(_offerGuarantee >= block.timestamp + minOfferGuaranteeHours, "you need to increase offer guarantee");

    // If a previous offer exists and the previous offeror is not a contract
    // (we need to double check here because he might became a contract
    // since he submitted his offer)
    if(sellOrder.highestOfferor != address(0) && !sellOrder.highestOfferor.isContract()) {
      // Refund previous offeror
      payable(sellOrder.highestOfferor).call{value: sellOrder.highestOffer}("");
    }

    // Update highest offer and offeror
    sellOrder.highestOffer = msg.value;
    sellOrder.highestOfferor = msg.sender;
    sellOrder.highestOfferGuarantee = _offerGuarantee;
    sellOrder.highestOfferExpiration = _offerExpiration;

    // Emit event
    emit SellOrderOffer(
      sellOrder.owner,
      _orderId,
      msg.value,
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
  function cancelOfferOnSellOrder (bytes32 _orderId) external payable onlyIfSenderNotContract sellOrderExists(_orderId) {
    SellOrder storage sellOrder = sellOrders[_orderId];

    require(sellOrder.highestOfferor == msg.sender, "forbidden");
    require(sellOrder.highestOfferGuarantee <= block.timestamp, "offer guarantee is not reached yet");
    
    if(!sellOrder.highestOfferor.isContract()) {
      // Refund previous offeror
      payable(sellOrder.highestOfferor).call{value: sellOrder.highestOffer}("");
    }

    sellOrder.highestOffer = 0;
    sellOrder.highestOfferor = address(0);
    sellOrder.highestOfferGuarantee = 0;

    emit SellOrderOfferCancelled(
      _orderId
    );
  }

  /**
   * @notice Accepts higher order by sending the cards
   *         to the buyer and receiving the Ether in escrow
   *
   * @dev Restricted to sell order owner
   *
   * @param _orderId order for which the owner wants to accept
   *                 the highest offer for
  */
  function acceptSellOrderHighestOffer(bytes32 _orderId) external sellOrderExists(_orderId) senderOwnsSellOrder(_orderId) {
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
    require(sellOrder.highestOfferExpiration > block.timestamp, "offer has been expired");

    address collectionAddress;
    address payable partnerDaoAddress;

    // Transfer all the cards in escrow to the highest offeror
    for(uint256 i = 0; i < sellOrder.assetIds.length; i++) {
      if (i == 0) {
        // do this for first card as all cards should be from the same collection
        // TODO check if sellOrder.assetIds[i] is card ID
        (,uint8 cardCollection,,) = card.cardInfo(sellOrder.assetIds[i]);
        (collectionAddress,,partnerDaoAddress,,,,) = card.cardCollectionInfo(cardCollection);
      }
      card.safeTransferFrom(address(this), sellOrder.highestOfferor, sellOrder.assetIds[i]);
    }

    // If sell order owner is not a contract (we need to double check
    // here because he might became a contract since he created his
    // offer)
    if(!sellOrder.owner.isContract()) {
      // Transfer Ether amount without fees to sell order owner
      // (fees are paid to DAO and reserve in the takeFeesFrom function)
      payable(sellOrder.owner).call{value: takeFeesFrom(sellOrder.highestOffer, collectionAddress, partnerDaoAddress)}("");
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
  }

  /**
   * @notice Executes sell order by providing Ether
   *         and receiving escrowed cards
   *
   * @dev Cannot be called when order ask is 0 since
   *      in that case it is open to offers
   */
  function fulfillSellOrder(bytes32 _orderId) external payable onlyIfSenderNotContract sellOrderExists(_orderId) {
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
    require(sellOrder.ask > 0, "cannot fulfil order that's open to offer");

    // Ensure Ether sent is equal to sell order ask value
    require(sellOrder.ask == msg.value, "incorrect amount of ether provided");

    address collectionAddress;
    address payable partnerDaoAddress;
    // Transfer all the cards in escrow to the highest offeror
    for(uint256 i = 0; i < sellOrder.assetIds.length; i++) {
      if (i == 0) {
        // do this for first card as all cards should be from the same collection
        // TODO check if sellOrder.assetIds[i] is card ID
        (,uint8 cardCollection,,) = card.cardInfo(sellOrder.assetIds[i]);
         (collectionAddress,,partnerDaoAddress,,,,) = card.cardCollectionInfo(cardCollection);
      }

      card.safeTransferFrom(address(this), sellOrder.highestOfferor, sellOrder.assetIds[i]);
    }

    // If sell order owner is not a contract (we need to double check
    // here because he might became a contract since he created his
    // offer)
    if(!sellOrder.owner.isContract()) {
      // Transfer Ether amount without fees to sell order owner
      // (fees are paid to DAO and Partner in the takeFeesFrom function)
      payable(sellOrder.owner).call{value: takeFeesFrom(sellOrder.highestOffer, collectionAddress, partnerDaoAddress)}("");
    }

    // If a previous offer exists and the previous offeror is not a contract
    // (we need to double check here because he might became a contract
    // since he submitted his offer)
    if(sellOrder.highestOfferor != address(0) && !sellOrder.highestOfferor.isContract()) {
      // Refund previous offeror
      payable(sellOrder.highestOfferor).call{value: sellOrder.highestOffer}("");
    }

    // Emit event
    emit SellOrderFulfilled(
      sellOrder.owner,
      _orderId,
      sellOrder.name,
      sellOrder.assetIds,
      msg.sender,
      msg.value,
      sellOrder.ask
    );
  }

  /**
   * @notice Executes sell order by providing Ether
   *         and receiving escrowed cards
   *
   * @dev Cannot be called when order ask is 0 since
   *      in that case it is open to offers
   */
function buySellOrder(bytes32 _orderId) external payable onlyIfSenderNotContract sellOrderExists(_orderId) {

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
    require(sellOrder.ask > 0, "cannot fulfil order that's open to offer");

    // Ensure Ether sent is equal to sell order ask value
    require(sellOrder.ask == msg.value, "incorrect amount of ether provided");

    address collectionAddress;
    address payable partnerDaoAddress;

    // Transfer all the cards in escrow to the highest offeror
    for(uint256 i = 0; i < sellOrder.assetIds.length; i++) {
      if (i == 0) {
        // do this for first card as all cards should be from the same collection
        // TODO check if sellOrder.assetIds[i] is card ID
        (,uint8 cardCollection,,) = card.cardInfo(sellOrder.assetIds[i]);
        (collectionAddress,,partnerDaoAddress,,,,) = card.cardCollectionInfo(cardCollection);
      }

      card.safeTransferFrom(address(this), msg.sender, sellOrder.assetIds[i]);
    }

    // If sell order owner is not a contract (we need to double check
    // here because he might became a contract since he created his
    // offer)
    if(!sellOrder.owner.isContract()) {
      // Transfer Ether amount without fees to sell order owner
      // (fees are paid to DAO and Partner in the takeFeesFrom function)
      payable(sellOrder.owner).call{value: takeFeesFrom(msg.value, collectionAddress, partnerDaoAddress)}("");
    }

    // If a previous offer exists and the previous offeror is not a contract
    // (we need to double check here because he might became a contract
    // since he submitted his offer)
    if(sellOrder.highestOfferor != address(0) && !sellOrder.highestOfferor.isContract()) {
      // Refund previous offeror
       payable(sellOrder.highestOfferor).call{value: sellOrder.highestOffer}("");
    }


   // Emit event
    emit SellOrderFulfilled(
      sellOrder.owner,
      _orderId,
      sellOrder.name,
      sellOrder.assetIds,
      msg.sender,
      msg.value,
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
   *
   * @return the order ID
   */
  function createBuyOrder(
    uint8 _cardType, 
    uint8 _cardCollection

  ) external payable validCardType(_cardType) returns (bytes32) {
    // Get bid price from message value
    uint256 bid = msg.value;

    // Generate pseudorandom order ID
    bytes32 orderId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _cardType, bid));

    // Store order in mapping
    buyOrders[orderId] = BuyOrder({
      owner: msg.sender,
      cardCollection: _cardCollection,
      cardType: _cardType,
      bid: bid,
      lowestOffer: 0,
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
      bid
    );

    // Return order ID
    return orderId;
  }


  /**
  * @notice Cancel buy order
   *
   * @dev Restricted to buy order owner
   *
   * @param _orderId order which the owner wants to cancel
   */
  function cancelBuyOrder(bytes32 _orderId) external buyOrderExists(_orderId) senderOwnsBuyOrder(_orderId) {
    BuyOrder memory buyOrder = buyOrders[_orderId];
    delete buyOrders[_orderId];

    if (buyOrder.lowestOfferor != address(0)) {
      card.safeTransferFrom(address(this), buyOrder.lowestOfferor, buyOrder.lowestOfferCardId);
    }

    emit BuyOrderCancelled(
      buyOrder.owner,
      _orderId
    );
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
   */
  function placeOfferOnBuyOrder(
    bytes32 _orderId,
    uint256 _cardId,
    uint256 _offer,
    uint256 _offerGuarantee
  ) external {
    // Get sell order
    BuyOrder storage buyOrder = buyOrders[_orderId];

    // If the buy order is not open to offers without a bid price
    if(buyOrder.bid != 0) {
      // Ensure the offer value is more than the order bid
      require(_offer > buyOrder.bid, "offer value must be more than order bid");
    }

    // Ensure the value of the new offer is lower than the current
    require(_offer < buyOrder.lowestOffer, "offer value must be lower than current");

    // Ensure the offer guarantee period for which the offeror cannot withdraw
    // is at least minOfferGuaranteeHours hours in the future
    require(_offerGuarantee >= block.timestamp + minOfferGuaranteeHours, "you need to increase offer guarantee");

    // Ensure a card of correct type was sent
    (uint8 cardType, uint8 cardCollection,,) = card.cardInfo(_cardId);
    require(cardType == buyOrder.cardType, "invalid card type");

    // Ensure a card of correct collection was sent
    require(cardCollection == buyOrder.cardCollection, "invalid card collection");

    // Transfer card to Marketplace contract for escrow
    // Will revert if user does not own card or if has not approved
    // Marketplace contract for trading
    card.safeTransferFrom(msg.sender, address(this), _cardId);

    // If a previous offer exists and the previous offeror is not a contract
    // (we need to double check here because he might became a contract
    // since he submitted his offer)
    if(buyOrder.lowestOfferor != address(0) && !buyOrder.lowestOfferor.isContract()) {
      // Refund previous offeror
      // Will revert if user does not own card or if has not approved
      // Marketplace contract for trading
      card.safeTransferFrom(address(this), buyOrder.lowestOfferor, buyOrder.lowestOfferCardId);
    }

    // Update lowest offer, offeror and card ID
    buyOrder.lowestOffer = _offer;
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
  function cancelOfferOnBuyOrder(bytes32 _orderId) external onlyIfSenderNotContract buyOrderExists(_orderId) {
    BuyOrder storage buyOrder = buyOrders[_orderId];

    require(buyOrder.lowestOfferor == msg.sender, "forbidden");
    require(buyOrder.lowestOfferGuarantee <= block.timestamp, "offer guarantee is not reached yet");

    card.safeTransferFrom(address(this), msg.sender, buyOrder.lowestOfferCardId);

    buyOrder.lowestOffer = 0;
    buyOrder.lowestOfferor = address(0);
    buyOrder.lowestOfferCardId = 0;
    buyOrder.lowestOfferGuarantee = 0;

    emit BuyOrderOfferCancelled(
      _orderId
    );
  }

  /**
   * @notice Accepts lowest offer by sending the card
   *         to the owner and receiving the Ether in escrow
   *
   * @dev Restricted to buy order owner
   *
   * @param _orderId order for which the owner wants to accept
   *                 the lowest offer for
   */
  function acceptBuyOrderLowestOffer(bytes32 _orderId) external buyOrderExists(_orderId) senderOwnsBuyOrder(_orderId) {
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
    if(!buyOrder.lowestOfferor.isContract()) {
      (,uint8 cardCollection,,) = card.cardInfo(buyOrder.lowestOfferCardId);
      (address collectionAddress,,address payable partnerDaoAddress,,,,) = card.cardCollectionInfo(cardCollection);

      // Transfer Ether amount without fees to sell
      // (fees are paid to DAO and Partner in the takeFeesFrom function)
      payable(buyOrder.lowestOfferor).call{value: takeFeesFrom(buyOrder.lowestOffer, collectionAddress, partnerDaoAddress)}("");
    }

      // Transfer card to buy order owner
      // Will revert if user does not own card or if has not approved
      // Marketplace contract for trading
      card.safeTransferFrom(address(this), buyOrder.owner, buyOrder.lowestOfferCardId);

    // Emit event
    emit BuyOrderFulfilled(
      buyOrder.owner,
      _orderId,
      buyOrder.cardCollection,
      buyOrder.cardType,
      buyOrder.lowestOfferor,
      buyOrder.lowestOffer,
      buyOrder.bid
    );
  }

  /**
   * @notice Executes buy order by providing the card
   *         and receiving escrowed Ether
   *
   * @dev Cannot be called when order ask is 0 since
   *      in that case it is open to offers
   *
   * @param _orderId order ID to be fulfilled
   * @param _cardId card to send and fulfil order with
   */
  function fulfilBuyOrder(bytes32 _orderId, uint256 _cardId) external onlyIfSenderNotContract buyOrderExists(_orderId) {
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
    (uint256 cardType,uint8 cardCollection,,) = card.cardInfo(_cardId);
    require(cardType == buyOrder.cardType, "invalid card type");

    (address collectionAddress,,address payable partnerDaoAddress,,,,) = card.cardCollectionInfo(cardCollection);

    // If buy order owner is not a contract (we need to double check
    // here because he might became a contract since he created his
    // offer)
    if(!buyOrder.owner.isContract()) {
      // Transfer the card to the buy order owner
      // Will revert if user does not own card or if has not approved
      // Marketplace contract for trading
      card.safeTransferFrom(msg.sender, buyOrder.owner, _cardId);
    }

    // Transfer Ether amount without fees to buyer
    // (fees are paid to DAO and reserve in the takeFeesFrom function)
    payable(msg.sender).call{value: takeFeesFrom(buyOrder.bid, collectionAddress, partnerDaoAddress)}("");

    // If a previous offer exists and the previous offeror is not a contract
    // (we need to double check here because he might became a contract
    // since he submitted his offer)
    if(buyOrder.lowestOfferor != address(0) && !buyOrder.lowestOfferor.isContract()) {
      // Refund previous offeror
      payable(buyOrder.lowestOfferor).call{value: buyOrder.lowestOffer}("");
    }

    // Emit event
    emit BuyOrderFulfilled(
      buyOrder.owner,
      _orderId,
      buyOrder.cardCollection,
      buyOrder.cardType,
      msg.sender,
      buyOrder.bid,
      buyOrder.bid
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";
import "base64-sol/base64.sol";

/**
 * @title Eternity deck card
 *
 * @dev Represents a card NFT in the game.
 */
contract CardNFT is ERC721, ERC721Enumerable, AccessControl, Ownable {
  // Makes address.isContract() available
  using Address for address;
  using Strings for uint256;
  using Strings for uint16;
  using Strings for uint8;

  /**
   * @notice AccessControl role that allows to mint tokens
   *
   * @dev Used in mint(), safeMint(), mintBatch(), safeMintBatch()
   */
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @notice AccessControl role that allows to burn tokens
   *
   * @dev Used in burn(), burnBatch()
   */
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  /**
   * @notice AccessControl role that allows to change the baseURI
   *
   * @dev Used in setBaseURI()
   */
  bytes32 public constant URI_MANAGER_ROLE = keccak256("URI_MANAGER_ROLE");

  /**
   * @notice Stores the total values of all cards in existence.
   *
   * @dev Is increased when a new card is minted depending on
   *      the card value and decreased by the same amount when
   *      the card is burned
   */
 // uint256 public totalCardValue = 0;

  /**
   * @notice Stores the amount of cards that were burned in
   *         the duration of the game.
   *
   * @dev Is increased by 1 when a card is burned
   */
  uint256 public totalBurned = 0;

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
    uint256 totalCardValue;
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
  mapping(address => mapping(uint8 => AddressCardType)) public cardTypeByAddress;


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
    uint burnType
  );

  /**
	 * @dev Fired in setBaseURI()
	 *
	 * @param by an address which executed update
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
  event BaseURIChanged(
    address by,
    string oldVal,
    string newVal
  );

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
  constructor() ERC721("Eternity Deck Card", "EDC") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
    _setupRole(URI_MANAGER_ROLE, msg.sender);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory name = string(abi.encodePacked('"name": "Eternity deck: Collection ', cardInfo[tokenId].cardCollection.toString(), ' ', 'Edition ', cardInfo[tokenId].editionNumber.toString(),'",'));
    string memory description = '"description": "Represents a card in the eternity deck game",';
    string memory imageUrl = string(abi.encodePacked('"image_url": "https://eternity-deck.com/card/', cardInfo[tokenId].cardCollection.toString(), '/', cardInfo[tokenId].cardType.toString(), '.png",'));

    string memory cardTypeAttribute = string(abi.encodePacked(
      '{',
        '"trait_type": "Card Type",',
        '"value":', cardInfo[tokenId].cardType.toString(),
      '},'
    ));

    string memory cardCollectionAttribute = string(abi.encodePacked(
      '{',
        '"trait_type": "Card Collection",',
        '"value":', cardInfo[tokenId].cardCollection.toString(),
      '},'
    ));

    string memory serialNumberAttribute = string(abi.encodePacked(
      '{',
        '"trait_type": "Serial Number",',
        '"value":', cardInfo[tokenId].serialNumber.toString(),
      '},'
    ));

    string memory editionNumberAttribute = string(abi.encodePacked(
      '{',
        '"trait_type": "Edition Number",',
        '"value":', cardInfo[tokenId].editionNumber.toString(),
      '}'
    ));

    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{',
                name,
                description,
                imageUrl,
                '"attributes": [',
                  cardTypeAttribute,
                  cardCollectionAttribute,
                  serialNumberAttribute,
                  editionNumberAttribute,
                ']',
              '}'
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
    require(_cardType >= 1 && _cardType <= 53, "card type must be in range [1, 53]");
    _;
  }


  string internal theBaseURI = "";

  function _baseURI() internal view virtual override returns (string memory) {
    return theBaseURI;
  }

  /**
	 * @notice Updates base URI used to construct ERC721Metadata.tokenURI
   *
   * @dev Access restricted by `URI_MANAGER_ROLE` AccessControl role
	 *
	 * @param _newBaseURI new base URI to set
	 */
  function setBaseURI(string memory _newBaseURI) external onlyRole(URI_MANAGER_ROLE) {
    // Fire event
    emit BaseURIChanged(msg.sender, theBaseURI, _newBaseURI);

    // Update base uri
    theBaseURI = _newBaseURI;
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
  function exists(uint160 _tokenId) external view returns(bool) {
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
	 */
  function burn(address _to, uint160 _tokenId, uint _type) public onlyRole(BURNER_ROLE) {
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

    // // Decrease the population of card type
    // // and collection-scoped population
    
    // cardPopulation[_cardType] -= 1;
    // cardCollectionPopulation[_cardCollection][_cardType] -= 1;

    // Decrease the total value of the cards by
    // the card type value
    //cardCollectionInfo[_cardCollection].totalCardValue -= cardValue[_cardType];
 
    cardCollectionInfo[_cardCollection].colBurned += 1;

    // Increase amount of cards burned by 1
    totalBurned += 1;
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
	 */
  function burnBatch(address _to, uint160[] memory _tokenIds, uint _type) public onlyRole(BURNER_ROLE) {
    // Cannot burn 0 tokens
    require(_tokenIds.length != 0, "cannot burn 0 tokens");

    for(uint8 i = 0; i < _tokenIds.length; i++) {
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

      // // Decrease the population of card type
      // // and collection-scoped population
      //DONE: LUSINE Uncommented 
      // cardPopulation[_cardType] -= 1;
      // cardCollectionPopulation[_cardCollection][_cardType] -= 1;

      
      cardCollectionInfo[_cardCollection].colBurned += 1;

      // Decrease the total value of the cards by
      // the card type value
      //totalCardValue -= cardValue[_cardType];
    }

    // Increase amount of cards burned
    totalBurned += _tokenIds.length;

    
  }

  /**
	 * @notice Creates new token with token ID specified
	 *         and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Access restricted by `MINTER_ROLE` AccessControl role
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
   * @param _cardType type of card to mint in range [1, 53]
   * @param _cardCollection the collection of the card to mint
	 */
  
  function mint(address _to, uint160 _tokenId, uint8 _cardType, uint8 _cardCollection, bool _upgrade) public  validCardType(_cardType) onlyRole(MINTER_ROLE){
    
    require(cardCollectionInfo[_cardCollection].collectionAddress != address(0), "collection  doesn't exists");
    
    // Save the card info
    // Must be saved before call to _mint() as that function
    // calls _beforeTokenTransfer() which uses this information
    cardInfo[_tokenId] = Card({
      cardType: _cardType,
      cardCollection: _cardCollection,
      serialNumber: cardPopulation[_cardType] + 1,
      editionNumber: cardCollectionPopulation[_cardCollection][_cardType] + 1
    });
    // console.log("Edition number");
    // console.log(cardCollectionPopulation[_cardCollection][_cardType] + 1);

    // Delegate to internal OpenZeppelin function
    // Calls beforeTokenTransfer() which increases minted
    // and owned card count of _to address for this card type
    _mint(_to, _tokenId);

    // Increase the population of card type
    // and collection-scoped population
    cardPopulation[_cardType] += 1;
    cardCollectionPopulation[_cardCollection][_cardType] += 1;

    // Increase the total value of the cards by
    // the card type value
    //cardCollectionInfo[_cardCollection].totalCardValue += cardValue[_cardType];

    cardCollectionInfo[_cardCollection].colMinted += 1;

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
  function mintBatch(address _to, uint160 _tokenId, uint128 _n, uint8 _cardType, uint8 _cardCollection) public onlyRole(MINTER_ROLE) validCardType(_cardType) {
    bool _upgrade = false;

    // Cannot mint 0 tokens
    require(_n != 0, "_n cannot be zero");

    for(uint256 i = 0; i < _n; i++) {
      // Save the card type and collection of the card
      // Must be saved before call to _mint() as that function
      // calls _beforeTokenTransfer() which uses this information
      cardInfo[_tokenId + i] = Card({
        cardType: _cardType,
        cardCollection: _cardCollection,
        serialNumber: cardPopulation[_cardType] + i + 1,
        editionNumber: cardCollectionPopulation[_cardCollection][_cardType] + i + 1
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
    }

    // Increase the population of card type
    // and collection-scoped population
    // by amount of cards minted
    cardPopulation[_cardType] += _n;
    cardCollectionPopulation[_cardCollection][_cardType] += _n;

    // Increase the total value of the cards by
    // the card type value times the amount of
    // cards minted
    // += cardValue[_cardType] * _n;

    cardCollectionInfo[_cardCollection].colMinted += _n;

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
  function safeMint(address _to, uint160 _tokenId, uint8 _cardType, uint8 _cardCollection, bytes memory _data) public {
    // Delegate to internal mint function (includes AccessControl role check,
    // card type validation and event emission)
    mint(_to, _tokenId, _cardType, _cardCollection, false);

    // If a contract, check if it can receive ERC721 tokens (safe to send)
    if(_to.isContract()) {
      // Try calling the onERC721Received function on the to address
		  try IERC721Receiver(_to).onERC721Received(msg.sender, address(0), _tokenId, _data) returns (bytes4 retval) {
        require(retval == IERC721Receiver.onERC721Received.selector, "invalid onERC721Received response");
      // If onERC721Received function reverts
      } catch (bytes memory reason) {
        // If there is no revert reason, assume function
        // does not exist and revert with appropriate reason
        if (reason.length == 0) {
          revert("mint to non ERC721Receiver implementer");
        // If there is a reason, revert with the same reason
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
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
	 */
  function safeMint(address _to, uint160 _tokenId, uint8 _cardType, uint8 _cardCollection) public {
    // Delegate to internal safe mint function (includes AccessControl role check
    // and card type validation)
    safeMint(_to, _tokenId, _cardType, _cardCollection, "");
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
  function safeMintBatch(address _to, uint160 _tokenId, uint128 _n, uint8 _cardType, uint8 _cardCollection, bytes memory _data) public {
    // Delegate to internal unsafe batch mint function (includes AccessControl role check,
    // card type validation and event emission)
    mintBatch(_to, _tokenId, _n, _cardType, _cardCollection);

    // If a contract, check if it can receive ERC721 tokens (safe to send)
    if(_to.isContract()) {
      // For each token minted
      for(uint256 i = 0; i < _n; i++) {
        // Try calling the onERC721Received function on the to address
        try IERC721Receiver(_to).onERC721Received(msg.sender, address(0), _tokenId + i, _data) returns (bytes4 retval) {
          require(retval == IERC721Receiver.onERC721Received.selector, "invalid onERC721Received response");
        // If onERC721Received function reverts
        } catch (bytes memory reason) {
          // If there is no revert reason, assume function
          // does not exist and revert with appropriate reason
          if (reason.length == 0) {
            revert("mint to non ERC721Receiver implementer");
          // If there is a reason, revert with the same reason
          } else {
            assembly {
              revert(add(32, reason), mload(reason))
            }
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
	 */
  function safeMintBatch(address _to, uint160 _tokenId, uint128 _n, uint8 _cardType, uint8 _cardCollection) external {
    // Delegate to internal safe batch mint function (includes AccessControl role check
    // and card type validation)
    safeMintBatch(_to, _tokenId, _n, _cardType, _cardCollection, "");
  }

  /**
   * @inheritdoc ERC721
   */
  function supportsInterface(bytes4 _interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
    return super.supportsInterface(_interfaceId);
  }

  /**
   * @inheritdoc ERC721
   *
   * @dev Adjusts owned count for `_from` and `_to` addresses
   */
  function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    // Delegate to inheritance chain
    super._beforeTokenTransfer(_from, _to, _tokenId);

    // Get card type of card being transferred
    uint8 _cardType = cardInfo[_tokenId].cardType;

    // Get card type by address values for to and from
    AddressCardType storage actFrom = cardTypeByAddress[_from][_cardType];
    AddressCardType storage actTo = cardTypeByAddress[_to][_cardType];

    // Check if from address is not zero address
    // (when it is zero address, the token is being minted)
    if(_from != address(0)) {
      // Decrease owned card count of from address
      actFrom.owned--;
    } else {
      // If card is being minted, increase to minted count
      actTo.minted++;
    }

    // Check if to address is not zero address
    // (when it is zero address, the token is being burned)
    if(_to != address(0)) {
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

    for(uint8 i = 1; i <= 53; i++) {
      cardIds[i] = cardPopulation[i];
    }

    return (cardIds);
  }

  /**
   * @notice Gets the cards of an account
   *
   * @dev External function only to be used by the front-end
   */
  function cardsOfAccount() external view returns (uint256[] memory, Card[] memory) {
    uint256 n = balanceOf(msg.sender);

    uint256[] memory cardIds = new uint256[](n);
    Card[] memory cards = new Card[](n);


    for(uint32 i = 0; i < n; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);

      cardIds[i] = tokenId;
      cards[i] = cardInfo[tokenId];
    }

    return (
      cardIds,
      cards
    );
  }

  /**
   * @notice Add new collection to cardCollectionInfo mapping
   *
   *
   * Emits a {DaoAddressChanged} event
   * Emits a {CollectionAdded} event
   *
   * @param _collection collection id
   * @param _collectionAddress _collectionAddress
   * @param _collectionBuyBack _collectionBuyBack
   * @param _collectionPartnerDaoAddress _collectionPartnerDaoAddress
   */
  function addCollection(uint8 _collection, address _collectionAddress, uint256 _collectionBuyBack,  address payable _collectionPartnerDaoAddress) external onlyOwner {
    // verify ollection address is set
    require(_collectionAddress != address(0), "collection address is not set");
    if(cardCollectionInfo[_collection].collectionAddress != address(0)){
      cardCollectionInfo[_collection].collectionAddress = _collectionAddress;
      cardCollectionInfo[_collection].partnerDaoAddress = _collectionPartnerDaoAddress;
      cardCollectionInfo[_collection].collectionBuyBack = _collectionBuyBack;
    }else{
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

  // Increase the totalBuyBacksClaimed of collection
  function increaseCollectionBuyBacks(uint8 _collection) external{
      cardCollectionInfo[_collection].totalBuyBacksClaimed ++;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

/**
  * @notice Collection interface for getting collection fees data
   * Collection should have public marketplaceFeePercent value
   * Collection should have public partnerMarketplaceFeePercent value
   *
   * EXAMPLE:
   * 
   * uint public marketplaceFeePercent = 20_000;
   * 
   * uint public partnerMarketplaceFeePercent = 10_000;
   *
   */
interface Collection {
    function marketplaceFeePercent() external view returns(uint);
    function partnerMarketplaceFeePercent() external view returns(uint);
    function checkDiscount(uint256 _fee) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}