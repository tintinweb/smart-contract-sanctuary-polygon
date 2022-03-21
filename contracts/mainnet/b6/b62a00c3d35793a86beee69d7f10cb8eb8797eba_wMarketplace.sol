// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2; 

import "Ownable.sol";
import "Counters.sol";
import "ReentrancyGuard.sol";
import "ERC721.sol";
import "ERC20.sol";
 
contract wMarketplace is Ownable, ReentrancyGuard {

  // Market-Item Status 
  enum MarketItemStatus {  
    Active,     // 0: market-item is active and can be sold
    Sold,       // 1: market-item is already sold 
    Cancelled,  // 2: market-item is cancelled by NFT owner
    Deleted     // 3: market-item is deleted by wMarketplace owner 
  }

  // Market-Rate structure
  struct MarketRate{
    bool isActive;         // is market-rate is active (is valid for specific address)
    uint256 listingPrice;  // listing price of a new market-item (for seller to create market-item)
    uint256 cancelPrice;   // the price for cancelling market-item on the market (by NFT owner)
    uint feePercent;       // fee % to charge from market-item price (seller will receive (100-feePercent)/100 * price)
  }

  // Market-Item structure
  struct MarketItem {
    uint256 itemId;           // id of the market-item
    address tokenContract;    // original (sellable) NFT token contract address
    uint256 tokenId;          // original (sellable) NFT token Id
    address payable seller;   // seller of the original NFT
    address payable buyer;    // buyer of the market-item - new owner of the sellable NFT
    address priceContract;    // ERC-20 price token address (Zero address => native token)
    uint256 price;            // price = amount of ERC-20 (or native token) price tokens to buy market-item
    MarketItemStatus status;  // status of the market-item
    uint256 fee;              // amount of fee (in ERC-20 price tokens) that were charged during the sale
  }


  // Events of Marketplace
  event MarketItemPlaced(uint256 indexed marketItemId, address indexed tokenContract, uint256 tokenId, address indexed seller, address priceContract, uint256 price);
  event MarketItemSold(uint256 indexed marketItemId, address indexed buyer);
  event MarketItemRemoved(uint256 indexed marketItemId, MarketItemStatus status);


  // counter for market items Id
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;

  // beneficiary, receiver of the commission - the address where the commission funds will be sent
  address payable _beneficiary;

  // collection of market-items
  mapping(uint256 => MarketItem) private _items;

  // collection of market-rates
  mapping(address => MarketRate) private _rates;

  constructor() {
    _beneficiary = payable(_msgSender());
    _rates[address(0)] = MarketRate(true, 0, 0, 3);
  }



  // ===========================================
  // ====== MAIN wMarketplace functions ========
  // ===========================================

  // create new market-item - listing of original NFT on Marketplace
  function placeMarketItem(address tokenContract, uint256 tokenId, address priceContract, uint256 price) public payable {
    require(price > 0, "Price must be positive (at least 1 wei)");

    // check if token is already placed in the market
    uint256 existingMarketItemId = findActiveMarketItem(tokenContract, tokenId);
    require(existingMarketItemId == 0, "That token is already placed on the market");

    // seller of the Token
    address seller = msg.sender; 

    // token validation
    int validation = _checkTokenValidity(seller, tokenContract, tokenId);
    require(validation != -1, "Only owner of the NFT can place it to the Marketplace");
    require(validation != -2, "NFT should be approved to the Marketplace");
    require(validation == 0, "NFT is not valid to be sold on the Marketplace");

    // market-rate for seller
    uint256 listingPrice = _getValidRate(seller).listingPrice;

    // check payment for listing price (if it is set up)
    if (listingPrice > 0) {
      require(msg.value >= listingPrice, "Listing Price should be sent to place NFT on the Marketplace");

      // send fee funds to _beneficiary
      if (_beneficiary != address(0))
        _beneficiary.transfer(msg.value);
    }

    // new market-item ID
    _itemIds.increment();
    uint256 marketItemId = _itemIds.current();

    // create new market-item
    _items[marketItemId] = MarketItem(
      marketItemId,
      tokenContract,
      tokenId,
      payable(seller),
      payable(address(0)),
      priceContract,
      price,
      MarketItemStatus.Active,
      0
    );

    emit MarketItemPlaced(marketItemId, tokenContract, tokenId, seller, priceContract, price);
  }

  // make deal on sell market-item, receive payment and transfer original NFT
  function makeMarketSale(uint256 marketItemId) public payable nonReentrant {
    // address of the buyer for nft
    address buyer = msg.sender;
    // address of the market-item seller
    address payable seller = _items[marketItemId].seller;
    // price amount
    uint256 priceAmount = _items[marketItemId].price;
    // price contract
    address priceContract = _items[marketItemId].priceContract;
    // original nft tokenId
    uint256 tokenId = _items[marketItemId].tokenId;
    // market-rate for seller
    uint feePercent = _getValidRate(seller).feePercent;

    // check market-item is in Active state
    require(_items[marketItemId].status != MarketItemStatus.Sold, "Market Item is already sold");
    require(_items[marketItemId].status != MarketItemStatus.Cancelled, "Market Item is cancelled");
    require(_items[marketItemId].status == MarketItemStatus.Active, "Market Item is not Active");

    // nft token contract && approval for nft
    ERC721 hostTokenContract = ERC721(_items[marketItemId].tokenContract);
    address approvedAddress = hostTokenContract.getApproved(tokenId);
    require(approvedAddress == address(this), "Market Item (NFT) should be approved to the Marketplace");

    // commission fee amount
    uint256 feeAmount = feePercent * priceAmount / 100;

    // price set in Native Token
    if (priceContract == address(0))
      _chargePriceInNative(priceAmount, msg.value, seller, feeAmount);
    // price set in ERC-20 Token
    else
      _chargePriceInERC20(priceAmount, priceContract, buyer, seller, feeAmount);

    // update market-item info
    _items[marketItemId].status = MarketItemStatus.Sold;
    _items[marketItemId].buyer = payable(buyer);
    _items[marketItemId].fee = feeAmount;

    // transfer original nft from seller to buyer
    hostTokenContract.safeTransferFrom(seller, buyer, tokenId);

    emit MarketItemSold(marketItemId, buyer);
    emit MarketItemRemoved(marketItemId, MarketItemStatus.Sold); 
  }

  // cancel market-item placement on wMarket
  function cancelMarketItem(uint256 marketItemId) public payable nonReentrant {
    // address of the market-item seller
    address payable seller = _items[marketItemId].seller;
    // check market-item Seller is cancelling the market-item
    require(msg.sender == seller, "Only Seller can cancel Market Item");
    // market-rate for seller
    uint256 cancelPrice = _getValidRate(seller).cancelPrice;

    // check market-item is in Active state
    require(_items[marketItemId].status != MarketItemStatus.Sold, "Market Item is already sold");
    require(_items[marketItemId].status != MarketItemStatus.Cancelled, "Market Item is cancelled");
    require(_items[marketItemId].status == MarketItemStatus.Active, "Market Item is not Active");

    // check payment for cancel price (if it is set up)
    if (cancelPrice > 0) {
      require(msg.value >= cancelPrice, "Cancel Price should be sent to cancel NFT placement on the Marketplace");

      // send funds to _beneficiary
      if (_beneficiary != address(0))
        _beneficiary.transfer(msg.value);
    }

    // update market-item info
    _items[marketItemId].status = MarketItemStatus.Cancelled;

    emit MarketItemRemoved(marketItemId, MarketItemStatus.Cancelled);
  }


  // ===========================================
  // ======= Secondary public functions ========
  // ===========================================

  // get Rate for sender address
  function getRate() public view returns (MarketRate memory) {
    return _getValidRate(msg.sender);
  }

  // get Marketplace contract beneficiary
  function getBeneficiary() public view returns (address){
    return _beneficiary;
  }
 
  // get market-item info by id
  function getMarketItem(uint256 marketItemId) public view returns (MarketItem memory) {
    return _items[marketItemId];
  }

  // get count of all market-items
  function getAllMarketItemsCount() public view returns (uint256) {
    return _itemIds.current();
  }

  // get count of active (not sold and not removed) market-items
  function getActiveMarketItemsCount() public view returns (uint256) {
    uint256 itemsCount = _itemIds.current();
    uint256 activeCount = 0;
    for (uint256 i = 1; i <= itemsCount; i++) {
      if (_items[i].status == MarketItemStatus.Active)
        activeCount++;
    }

    return activeCount;
  }

    // get active active market-item by index (1 based)
  function getActiveMarketItem(uint256 index) public view returns (MarketItem memory) {
    require(index >= 1, "Index should be positive number (more or equal to 1)");
    
    uint256 itemsCount = _itemIds.current();
    require(index <= itemsCount, "Index should be in Items count range");

    uint256 activeIndex = 0;
    uint256 resultIndex = 0;
    for (uint256 i = 1; i <= itemsCount; i++) {
      if (_items[i].status == MarketItemStatus.Active) {
        activeIndex += 1;
        if (activeIndex == index) {
          resultIndex = i;
          break;
        }
      }
    }

    require(resultIndex > 0, "There is no such active Market Item with specified index");
    return _items[resultIndex];
  }


  // get all active (not sold and not removed) market-items
  function getActiveMarketItems() public view returns (MarketItem[] memory) {
    uint256 itemsCount = _itemIds.current();
    uint256 activeCount = getActiveMarketItemsCount();
    uint256 activeIndex = 0;

    MarketItem[] memory activeItems = new MarketItem[](activeCount);
    for (uint256 i = 1; i <= itemsCount; i++) {
      if (_items[i].status == MarketItemStatus.Active) {
        MarketItem storage currentItem = _items[i];
        activeItems[activeIndex] = currentItem;
        activeIndex += 1;
      }
    }

    return activeItems;
  }

  // find existing active market-item by tokenContract & tokenId
  function findActiveMarketItem(address tokenContract, uint256 tokenId) public view returns (uint256){
    uint256 itemsCount = _itemIds.current();
    for (uint256 i = 1; i <= itemsCount; i++) {
      if (_items[i].status == MarketItemStatus.Active && _items[i].tokenContract == tokenContract && _items[i].tokenId == tokenId)
        return i;
    }
    return 0;
  }


  // ===========================================
  // =========== Owner's functions =============
  // ===========================================

  // get Rate for specific address
  function getCustomRate(address adr) public view onlyOwner returns (MarketRate memory){
    return _getCustomRate(adr);
  }

  // set market-rate for specific address
  function setCustomRate(address adr, uint256 newListingPrice, uint256 newCancelPrice, uint newFeePercent) public onlyOwner {
    _rates[adr] = MarketRate(true, newListingPrice, newCancelPrice, newFeePercent);
  }

  // remove market-rate for specific address
  function removeCustomRate(address adr) public onlyOwner {
    if (adr == address(0))
      return;

    delete _rates[adr];
  }

  // remove market-item placement on wMarket
  function deleteMarketItem(uint256 marketItemId) public onlyOwner nonReentrant {
    // check market-item is in Active state
    require(_items[marketItemId].status == MarketItemStatus.Active, "Market Item is not Active");

    // update market-item info
    _items[marketItemId].status = MarketItemStatus.Deleted;

    emit MarketItemRemoved(marketItemId, MarketItemStatus.Deleted);
  }

  // change the fee percent of the wMarketplace
  function changeBeneficiary(address payable newBeneficiary) public onlyOwner {
    _beneficiary = newBeneficiary;
  }

  // send accumulated fee funds of the Marketplace to recipient (native-token = zero tokenContract)
  function sendFunds(address payable recipient, uint256 amount, address tokenContract) public onlyOwner {
    require(amount > 0, "Send Amount should be positive!");
    require(recipient != address(0), "Recipient should not be zero-address!");

    // address of the wMarketplace
    address marketplace = address(this);

    if (tokenContract == address(0)) {
      // get wMarketplace balance in native token
      uint256 balance = marketplace.balance;
      require(balance >= amount, "Send Amount exceeds Marketplace's native token balance!");
      // send native token amount to recipient
      recipient.transfer(amount);
    }
    else {
      // get ERC-20 Token Contract
      ERC20 hostTokenContract = ERC20(tokenContract);
      // get wMarketplace balance in ERC-20 Token
      uint256 balance = hostTokenContract.balanceOf(marketplace);
      require(balance >= amount, "Send Amount exceeds Marketplace's ERC-20 token balance!");
      // send ERC-20 token amount to recipient
      hostTokenContract.transfer(recipient, amount);
    }
  }



  // ===========================================
  // ======= Internal helper functions =========
  // ===========================================
  // get Rate for specific address
  function _getCustomRate(address adr) private view returns (MarketRate memory) {
    return _rates[adr];
  }

  // get Rate for specific address
  function _getValidRate(address adr) private view returns (MarketRate memory) {
    // get active market-rate for specific address
    if (_rates[adr].isActive)
      return _rates[adr];

    // return default market-rate  
    return _rates[address(0)];
  }

  // check if original NFT is valid to be placed on Marketplace
  function _checkTokenValidity(address seller, address tokenContract, uint256 tokenId) private view returns (int) {
    ERC721 hostTokenContract = ERC721(tokenContract);

    // get owner of the NFT (seller should be the owner of the NFT)
    address tokenOwner = hostTokenContract.ownerOf(tokenId);
    if (tokenOwner != seller)
      return -1;

    // get approved address of the NFT (NFT should be approved to Marketplace)
    address tokenApproved = hostTokenContract.getApproved(tokenId);
    if (tokenApproved != address(this))
      return -2;

    return 0;
  }

  // charge price and fees in Native Token
  function _chargePriceInNative(
    uint256 priceAmount,
    uint256 incomeAmount,
    address payable seller,
    uint256 feeAmount)
  private {
    require(incomeAmount >= priceAmount, "Please submit the Price amount in order to complete the purchase");
    //require(feeAmount >= 0, "Invalid Fee Amount calculated!");

    // amount that should be send to Seller
    uint256 sellerAmount = priceAmount - feeAmount;
    require(sellerAmount > 0, "Invalid Seller Amount calculated!");

    // transfer seller-amount (=price-fee) to seller
    seller.transfer(sellerAmount);

    // send fee funds to _beneficiary
    if (_beneficiary != address(0) && feeAmount > 0)
      _beneficiary.transfer(feeAmount);
  }

  // charge price and fees in ERC20 Token
  function _chargePriceInERC20(
    uint256 priceAmount,
    address priceContract,
    address buyer,
    address seller,
    uint256 feeAmount)
  private {
    //require(feeAmount >= 0, "Invalid Fee Amount calculated!");

    // amount that should be send to Seller
    uint256 sellerAmount = priceAmount - feeAmount;
    require(sellerAmount > 0, "Invalid Seller Amount calculated!");

    // address of the wMarketplace
    address marketplace = address(this);

    // check price amount allowance to marketplace
    ERC20 hostPriceContract = ERC20(priceContract);
    uint256 priceAllowance = hostPriceContract.allowance(buyer, marketplace);
    require(priceAllowance >= priceAmount, "Please allow Price amount of ERC-20 Token in order to complete purchase");

    // transfer price amount to marketplace
    bool priceTransfered = hostPriceContract.transferFrom(buyer, marketplace, priceAmount);
    require(priceTransfered, "Could not withdraw Price amount of ERC-20 Token from buyers wallet");

    // transfer seller-amount (=price-fee) to seller
    hostPriceContract.transfer(seller, sellerAmount);

    // send fee funds to _beneficiary
    if (_beneficiary != address(0) && feeAmount > 0)
      hostPriceContract.transfer(_beneficiary, feeAmount);
  }
}