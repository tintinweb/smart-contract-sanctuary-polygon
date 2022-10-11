/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

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

// File contracts/NFTMarketOA/AuctionsOA/IAuctionsOA.sol
pragma solidity ^0.8.4;

interface IAuctionsOA {
  struct Collect {
    bool collected;
    uint256 amount;
    address currency;
    uint256 endTime;
  }

  function activateAuction(
    uint256 itemId,
    uint256 endTime,
    uint256 minBid,
    address currency,
    address seller
  ) external;

  /* Allow users to bid */
  function bid(
    uint256 itemId,
    uint256 bidAmount,
    address bidder
  ) external;

  /* Ends auction when time is done and sends the funds to the beneficiary */
  function getProfits(uint256 itemId, address collector) external;

  /* Allows user to transfer the earned NFT */
  function collectNFT(uint256 itemId, address winner) external;

  /* Get collects of user */
  function getCollectItem(uint256 itemId, address sender) external view returns (Collect memory);
}

// File contracts/NFTMarketOA/SalesOA/ISalesOA.sol
pragma solidity ^0.8.4;

interface ISalesOA {
  /* Return allowance in a specific ERC20 token */
  function myallowance(address currency) external returns (uint256);

  /* Returns the listing price of the contract */
  function getListingPrice() external view returns (uint256);

  /* Transfers ownership of the item, as well as funds between parties */
  function createMarketSale(uint256 itemId, address buyer) external payable;

  /* Change listing price in hundredths*/
  function setListingPrice(uint256 percent) external;

  /* Put on sale */
  function activateSale(
    uint256 itemId,
    uint256 price,
    address currency,
    address seller
  ) external;

  /* Remove from sale */
  function deactivateSale(uint256 itemId, address seller) external;

  /* Set storage address */
  function setStorageAddress(address addressStorage) external;
}

// File contracts/NFTMarketOA/StorageOA/IStorageOA.sol
pragma solidity ^0.8.4;

interface IStorageOA {
  // Structur of items stored
  struct StorageItem {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    address payable owner;
    uint256 price;
    bool onAuction;
    bool onSale;
    uint256 endTime;
    address highestBidder;
    uint256 highestBid;
    address currency;
    bool isActive;
    address stored;
    bool firstSold;
  }

  // Method to get all actives items
  function getItems() external view returns (StorageItem[] memory);

  // Method to get actives items by collection
  function getItemsByCollection(address collectionAddress) external view returns (StorageItem[] memory);

  // Method to get items by owner
  function getItemsByOwner(address addressOwner) external view returns (StorageItem[] memory);

  // Method to get disabled items by owner
  function getDisabledItemsByOwner(address addressOwner) external view returns (StorageItem[] memory);

  function getItem(uint256 itemId) external view returns (StorageItem memory);

  /* Allows other contract to send this contract's nft */
  function transferItem(uint256 itemId, address to) external;

  function setItem(uint256 itemId, StorageItem memory item) external;

  function setItemAuction(
    uint256 itemId,
    address highestBidder,
    uint256 highestBid
  ) external;

  function createItem(
    address nftContract,
    uint256 tokenId,
    bool isActive,
    address ownerItem,
    bool onSale,
    bool onAuction,
    uint256 endTime,
    address currency,
    uint256 price
  ) external;

  function setActiveItem(uint256 itemId, bool isActive) external;
}

// File contracts/NFTMarketOA/OffersOA/IOffersOA.sol
pragma solidity ^0.8.4;

interface IOffersOA {
  struct Offer {
    uint256 offerId;
    uint256 itemId;
    uint256 amount;
    address bidder;
    address currency;
    uint256 endTime;
    bool accepted;
    bool collected;
  }

  /* Allow users to make an offer */
  function makeOffer(
    uint256 itemId,
    uint256 bidAmount,
    address bidder,
    uint256 endTime,
    address currency
  ) external;

  /* Allow item's owner to accept offer and recive his profit */
  function acceptOffer(uint256 offerId, address approval) external;

  /* Allows user to claim items */
  function claimItem(uint256 offerId, address claimer) external;

  /* Returns item's offers */
  function getOffersByItem(uint256 itemId) external view returns (Offer[] memory);

  /* Return item's offers currently active */
  function getActiveOffersByItem(uint256 itemId) external view returns (Offer[] memory);

  /* Set storage address */
  function setStorageAddress(address addressStorage) external;
}

// File contracts/NFTMarketOA/main.sol
pragma solidity ^0.8.4;

contract OpenArtMarketPlace is ReentrancyGuard {
  address private _addressStorage;
  address private _addressSales;
  address private _addressAuctions;
  address private _addressOffers;
  address private owner;

  constructor(
    address addressStorage,
    address addressSales,
    address addressAuctions,
    address addressOffers
  ) {
    _addressStorage = addressStorage;
    _addressSales = addressSales;
    _addressAuctions = addressAuctions;
    _addressOffers = addressOffers;
    owner = msg.sender;
  }

  /* Modifier to only allow owner to execute function */
  modifier onlyOwner() {
    require(msg.sender == owner, "You are not allowed to execute this method");
    _;
  }

  /* Change storage contract address */
  function setStorageAddress(address addressStorage) external onlyOwner {
    _addressStorage = addressStorage;
  }

  /* Change sales contract address */
  function setSalesAddress(address addressSales) external onlyOwner {
    _addressSales = addressSales;
  }

  /* Change offers contract address */
  function setOffersAddress(address addressOffers) external onlyOwner {
    _addressOffers = addressOffers;
  }

  /* Change auctions contract address */
  function setAuctionsAddress(address addressAuctions) external onlyOwner {
    _addressAuctions = addressAuctions;
  }

  /* Returns the listing price of the contract */
  function getListingPrice() external view returns (uint256) {
    return ISalesOA(_addressSales).getListingPrice();
  }

  /* Places an item for sale on the marketplace */
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    bool isActive,
    bool onSale,
    bool onAuction,
    uint256 endTime,
    address currency,
    uint256 price
  ) external {
    IStorageOA(_addressStorage).createItem(
      nftContract,
      tokenId,
      isActive,
      msg.sender,
      onSale,
      onAuction,
      endTime,
      currency,
      price
    );
  }

  /* Creates the sale of a marketplace item */
  function createMarketSale(uint256 itemId) external payable nonReentrant {
    ISalesOA(_addressSales).createMarketSale{value: msg.value}(itemId, msg.sender);
  }

  /* Returns all unsold market items */
  function fetchMarketItems() external view returns (IStorageOA.StorageItem[] memory) {
    return IStorageOA(_addressStorage).getItems();
  }

  /* Return items by collections */
  function fetchCollectionItems(address collectionAddress) external view returns (IStorageOA.StorageItem[] memory) {
    return IStorageOA(_addressStorage).getItemsByCollection(collectionAddress);
  }

  /* Returns onlyl items that a user has purchased */
  function fetchMyNFTs() external view returns (IStorageOA.StorageItem[] memory) {
    return IStorageOA(_addressStorage).getItemsByOwner(msg.sender);
  }

  /* Returns only disabled items that user owns */
  function fetchMyDisabledNFTs() external view returns (IStorageOA.StorageItem[] memory) {
    return IStorageOA(_addressStorage).getDisabledItemsByOwner(msg.sender);
  }

  /* Returns an element by its ID */
  function getItem(uint256 itemId) external view returns (IStorageOA.StorageItem memory) {
    return IStorageOA(_addressStorage).getItem(itemId);
  }

  /* Put on sale */
  function activateSale(
    uint256 itemId,
    uint256 price,
    address currency
  ) external {
    ISalesOA(_addressSales).activateSale(itemId, price, currency, msg.sender);
  }

  /* Remove from sale */
  function deactivateSale(uint256 itemId) external {
    ISalesOA(_addressSales).deactivateSale(itemId, msg.sender);
  }

  /* put up for auction */
  function activateAuction(
    uint256 itemId,
    uint256 endTime,
    uint256 minBid,
    address currency
  ) external {
    IAuctionsOA(_addressAuctions).activateAuction(itemId, endTime, minBid, currency, msg.sender);
  }

  /* Allow users to bid */
  function bid(uint256 itemId, uint256 bidAmount) external {
    IAuctionsOA(_addressAuctions).bid(itemId, bidAmount, msg.sender);
  }

  /* Ends auction when time is done and sends the funds to the beneficiary */
  function auctionEnd(uint256 itemId) external {
    IAuctionsOA(_addressAuctions).getProfits(itemId, msg.sender);
  }

  /* Allows user to transfer the earned NFT */
  function collectNFT(uint256 itemId) external {
    IAuctionsOA(_addressAuctions).collectNFT(itemId, msg.sender);
  }

  /* Allow users to make an offer */
  function makeOffer(
    uint256 itemId,
    uint256 bidAmount,
    uint256 endTime,
    address currency
  ) external {
    IOffersOA(_addressOffers).makeOffer(itemId, bidAmount, msg.sender, endTime, currency);
  }

  /* Allow item's owner to accept offer and recive his profit */
  function acceptOffer(uint256 offerId) external {
    IOffersOA(_addressOffers).acceptOffer(offerId, msg.sender);
  }

  /* Allows user to claim items */
  function claimItem(uint256 offerId) external {
    IOffersOA(_addressOffers).claimItem(offerId, msg.sender);
  }

  /* Returns item's offers */
  function getOffersByItem(uint256 itemId) external view returns (IOffersOA.Offer[] memory) {
    return IOffersOA(_addressOffers).getOffersByItem(itemId);
  }

  /* Return item's offers currently active */
  function getActiveOffersByItem(uint256 itemId) external view returns (IOffersOA.Offer[] memory) {
    return IOffersOA(_addressOffers).getActiveOffersByItem(itemId);
  }

  /* Get collects of user */
  function getCollectItem(uint256 itemId, address sender) external view returns (IAuctionsOA.Collect memory) {
    return IAuctionsOA(_addressAuctions).getCollectItem(itemId, sender);
  }

  /* Collect profit */
  function collectProfit(uint256 itemId) external {
    IAuctionsOA(_addressAuctions).getProfits(itemId, msg.sender);
  }

  /* Events from external contracts */
  event ItemCreated(uint256 indexed itemId, address indexed nftContract, uint256 indexed tokenId, address owner);
}