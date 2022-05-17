pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later

import "./StringCommon.sol";
import "./ImmutableEntity.sol";

// OpenZepellin upgradable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/*
// OpenZepellin standard contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
*/

/// @title Entity self-managed product interface
/// @author Sean Lawless for ImmutableSoft Inc.
/// @notice Entity requires registration and approval
contract ImmutableProduct is Initializable, OwnableUpgradeable
{
  // Product activation offer
  struct Offer
  {
    address tokenAddr; // ERC20 token address of offer. Zero (0) is ETH
    uint256 price; // the offer price in tokens/ETH
    uint256 value; // duration, flags/resellability and
                   // product feature (languages, version, game item, etc.)
    string  infoURL;// Offer information details
    uint256 transferSurcharge; // transfer fee in ETH
    uint256 ricardianParent; // required ricardian parent contract
  }

  // Product information
  struct Product
  {
    string name;
    string infoURL;
    string logoURL;
    uint256 details; // category, flags/restrictions, languages
    uint256 numberOfOffers;
    mapping(uint256 => Offer) offers;
  }

  // Mapping between external entity id and array of products
  mapping (uint256 => mapping (uint256 => Product)) private Products;
  mapping (uint256 => uint256) private NumberOfProducts;

  // Product interface events
  event productEvent(uint256 entityIndex, uint256 productIndex,
                     string name, string infoUrl, uint256 details);

  event productOfferEvent(uint256 entityIndex, uint256 productIndex,
                          string productName, address erc20token,
                          uint256 price, uint256 value, string infoUrl);

  // External contract interfaces
  ImmutableEntity private entityInterface;
  StringCommon private commonInterface;

  ///////////////////////////////////////////////////////////
  /// PRODUCT RELEASE
  ///////////////////////////////////////////////////////////

  /// @notice Product contract initializer/constructor.
  /// Executed on contract creation only.
  /// @param entityAddr the address of the ImmutableEntity contract
  /// @param commonAddr the address of the StringCommon contract
  function initialize(address entityAddr,
                      address commonAddr) public initializer
  {
    __Ownable_init();
/*
  constructor(address entityAddr, address commonAddr)
  {
*/
    entityInterface = ImmutableEntity(entityAddr);
    commonInterface = StringCommon(commonAddr);
  }

  /// @notice Create a new product for an entity.
  /// Entity must exist and be validated by Immutable.
  /// @param productName The name of the new product
  /// @param productURL The primary URL of the product
  /// @param logoURL The logo URL of the product
  /// @param details the product category, languages, etc.
  /// @return the new (unique per entity) product identifier (index)
  function productCreate(string calldata productName,
                         string calldata productURL,
                         string calldata logoURL,
                         uint256 details)
    external returns (uint256)
  {
    uint256 entityIndex = entityInterface.entityAddressToIndex(msg.sender);
    uint256 productID;
    uint256 lastProduct = NumberOfProducts[entityIndex];

    // Only a validated entity can create a product
    require(entityInterface.entityAddressStatus(msg.sender) > 0,
            commonInterface.EntityNotValidated());
    require(bytes(productName).length != 0, "name invalid");
    require(bytes(productURL).length != 0, "URL invalid");

    // If product name exists exactly revert the transaction
    for (productID = 0; productID < NumberOfProducts[entityIndex];
         ++productID)
    {
      // Check if the product name matches
      if (commonInterface.stringsEqual(Products[entityIndex][productID].name,
                                       productName))
        revert("name exists");
    }

    // Populate information for new product and increment index
    Products[entityIndex][lastProduct].name = productName;
    Products[entityIndex][lastProduct].infoURL = productURL;
    Products[entityIndex][lastProduct].logoURL = logoURL;
    Products[entityIndex][lastProduct].details = details;
    NumberOfProducts[entityIndex]++;

    // Emit an new product event and return the product index
    emit productEvent(entityIndex, productID, productName,
                      productURL, details);
    return lastProduct;
  }

  /// @notice Offer a software product license for sale.
  /// mes.sender must have a valid entity and product.
  /// @param productIndex The specific ID of the product
  /// @param erc20token Address of ERC 20 token offer
  /// @param price The token cost to purchase activation
  /// @param feature The product feature value/item (128 LSB only)
  ///              (128 MSB only) is duration, flags/resallability
  /// @param expiration activation expiration, (0) forever/unexpiring
  /// @param limited number of offers, (0) unlimited, 65535 max
  /// @param bulk number of activions per offer, > 0 to 65535 max
  /// @param infoUrl The official URL for more information about offer
  /// @param noResale Flag to disable resale capabilities for purchaser
  /// @param transferSurcharge Surcharged levied upon resale of purchase
  /// @param requireRicardian parent of required Ricardian client contract
  function productOfferFeature(uint256 productIndex, address erc20token,
                               uint256 price, uint256 feature,
                               uint256 expiration, uint16 limited,
                               uint16 bulk, string calldata infoUrl,
                               bool noResale,
                               uint256 transferSurcharge,
                               uint256 requireRicardian)
    external
  {
    if (noResale)
      require(expiration > 0, "Resale requires expiration");
    if (limited > 0)
      require(bulk == 0, "No Bulk when Limited");

    return productOffer(productIndex, erc20token, price,
                        (commonInterface.FeatureFlag() | commonInterface.ExpirationFlag() |
                        (noResale ? commonInterface.NoResaleFlag() : 0) |
                        ((limited > 0)? commonInterface.LimitedOffersFlag() : 0) |
                        ((bulk > 0) ? commonInterface.BulkOffersFlag() : 0) |
                         ((expiration << commonInterface.ExpirationOffset()) & commonInterface.ExpirationMask())  |
                         (((uint256)(limited | bulk) << commonInterface.UniqueIdOffset()) & commonInterface.UniqueIdMask()) |
                         ((feature << commonInterface.ValueOffset()) & commonInterface.ValueMask())),
                         infoUrl, transferSurcharge, requireRicardian);
  }

  /// @notice Offer a software product license for sale.
  /// mes.sender must have a valid entity and product.
  /// @param productIndex The specific ID of the product
  /// @param erc20token Address of ERC 20 token offer
  /// @param price The token cost to purchase activation
  /// @param limitation The version and language limitations
  /// @param expiration activation expiration, (0) forever/unexpiring
  /// @param limited number of offers, (0) unlimited, 65535 max
  /// @param bulk number of activions per offer, > 0 to 65535 max
  /// @param infoUrl The official URL for more information about offer
  /// @param noResale Prevent the resale of any purchased activation
  /// @param transferSurcharge Surcharged levied upon resale of purchase
  /// @param requireRicardian parent of required Ricardian client contract
  function productOfferLimitation(uint256 productIndex, address erc20token,
                                  uint256 price, uint256 limitation,
                                  uint256 expiration, uint16 limited,
                                  uint16 bulk, string calldata infoUrl,
                                  bool noResale,
                                  uint256 transferSurcharge,
                                  uint256 requireRicardian)
    external
  {
    if (noResale)
      require(expiration > 0, "Resale requires expiration");
    if (limited > 0)
      require(bulk == 0, "No Bulk when Limited");

    return productOffer(productIndex, erc20token, price,
                        (commonInterface.LimitationFlag() | commonInterface.ExpirationFlag() |
                        (noResale ? commonInterface.NoResaleFlag() : 0) |
                        ((limited > 0)? commonInterface.LimitedOffersFlag() : 0) |
                        ((bulk > 0) ? commonInterface.BulkOffersFlag() : 0) |
                         ((expiration << commonInterface.ExpirationOffset()) & commonInterface.ExpirationMask())  |
                         (((uint256)(limited | bulk) << commonInterface.UniqueIdOffset()) & commonInterface.UniqueIdMask()) |
                         ((limitation << commonInterface.ValueOffset()) & commonInterface.ValueMask())),
                         infoUrl, transferSurcharge, requireRicardian);
  }

  /// @notice Offer a software product license for sale.
  /// mes.sender must have a valid entity and product.
  /// @param productIndex The specific ID of the product
  /// @param erc20token Address of ERC 20 token offer
  /// @param price The token cost to purchase activation
  /// @param value The product activation value/item (128 LSB only)
  ///              (128 MSB only) is duration, flags/resallability
  ///              Zero (0) duration is forever/unexpiring
  /// @param infoUrl The official URL for more information about offer
  /// @param transferSurcharge ETH to creator for each transfer
  /// @param requireRicardian Ricardian leaf required for purchase
  function productOffer(uint256 productIndex, address erc20token,
                        uint256 price, uint256 value,
                       string memory infoUrl, uint256 transferSurcharge,
                        uint256 requireRicardian)
    private
  {
    uint256 entityStatus = entityInterface.entityAddressStatus(msg.sender);
    uint256 entityIndex = entityInterface.entityAddressToIndex(msg.sender);
    uint256 offerId = 0;

    // Only a validated commercial entity can create an offer
    require(entityStatus > 0, commonInterface.EntityNotValidated());
    require((entityStatus & commonInterface.Nonprofit()) != commonInterface.Nonprofit(), "Nonprofit prohibited");

    // Sanity check the input parameters
    require(NumberOfProducts[entityIndex] > productIndex,
            commonInterface.ProductNotFound());
    require(price >= 0, "Offer requires price");

    // If token configured specified, do a quick validity check
    if (erc20token != address(0))
    {
      require((entityStatus & commonInterface.CustomToken()) == commonInterface.CustomToken(),
              "Token offers require custom status.");
      IERC20Upgradeable theToken = IERC20Upgradeable(erc20token);

      require(theToken.totalSupply() > 0,
              "Not ERC20 token or no supply");
    }

    // Check if any offer has been exhausted/revoked
    for (;offerId < Products[entityIndex][productIndex].numberOfOffers; ++offerId)
      if (Products[entityIndex][productIndex].offers[offerId].price == 0)
        break;

    // Assign new digital product offer
    Products[entityIndex][productIndex].offers[offerId].tokenAddr = erc20token;
    Products[entityIndex][productIndex].offers[offerId].price = price;
    Products[entityIndex][productIndex].offers[offerId].value = value;
    Products[entityIndex][productIndex].offers[offerId].infoURL = infoUrl;
    Products[entityIndex][productIndex].offers[offerId].transferSurcharge = transferSurcharge;
    Products[entityIndex][productIndex].offers[offerId].ricardianParent = requireRicardian;

    // If creating a new offer update the offer count
    if (offerId >= Products[entityIndex][productIndex].numberOfOffers)
      offerId = Products[entityIndex][productIndex].numberOfOffers++;

    emit productOfferEvent(entityIndex, productIndex,
                           Products[entityIndex][productIndex].name,
                           erc20token, price, value, infoUrl);
  }

  /// @notice Change a software product license offer price
  /// mes.sender must have a valid entity and product
  /// @param productIndex The specific ID of the product
  /// @param offerIndex the index of the offer to change
  /// @param price The token cost to purchase activation
  function productOfferEditPrice(uint256 productIndex,
                                 uint256 offerIndex, uint256 price)
    public
  {
    uint256 entityStatus = entityInterface.entityAddressStatus(msg.sender);
    uint256 entityIndex = entityInterface.entityAddressToIndex(msg.sender);

    // Only a validated commercial entity can create an offer
    require(entityStatus > 0, commonInterface.EntityNotValidated());
    require((entityStatus & commonInterface.Nonprofit()) != commonInterface.Nonprofit(), "Nonprofit prohibited");
    require(NumberOfProducts[entityIndex] > productIndex,
            commonInterface.ProductNotFound());
    require(Products[entityIndex][productIndex].numberOfOffers > offerIndex,
            "Offer out of range");

    // Update the offer price, zero revokes the offer
    Products[entityIndex][productIndex].offers[offerIndex].price = price;
    if (price == 0)
      Products[entityIndex][productIndex].offers[offerIndex].value = 0;

    // While the last offer and empty, remove index
    while ((Products[entityIndex][productIndex].numberOfOffers > 0) &&
           (offerIndex == Products[entityIndex][productIndex].numberOfOffers - 1) &&
           (Products[entityIndex][productIndex].offers[offerIndex].price == 0))
    {
      offerIndex--;
      Products[entityIndex][productIndex].numberOfOffers--;
    }
  }

  /// @notice Count a purchase of a product activation license.
  /// Entity, Product and Offer must exist.
  /// @param entityIndex The index of the entity with offer
  /// @param productIndex The product ID of the offer
  /// @param offerIndex The per-product offer ID
  function productOfferPurchased(uint256 entityIndex,
                                 uint256 productIndex,
                                 uint256 offerIndex)
    public
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());

    require(NumberOfProducts[entityIndex] > productIndex,
            commonInterface.ProductNotFound());

    require(Products[entityIndex][productIndex].numberOfOffers > offerIndex,
            commonInterface.OfferNotFound());

    uint256 value =
      Products[entityIndex][productIndex].offers[offerIndex].value;

    uint256 count = (value & commonInterface.UniqueIdMask()) >> commonInterface.UniqueIdOffset();
    require(count > 0, "Count required");

    value = value & ~(commonInterface.UniqueIdMask());
    value = value | (((count - 1) << commonInterface.UniqueIdOffset()) & commonInterface.UniqueIdMask());

    // Update the offer value with the new lower count
    Products[entityIndex][productIndex].offers[offerIndex].value = value;

    // If no more offers available, remove this offer
    if (count - 1 == 0)
    {
      Products[entityIndex][productIndex].offers[offerIndex].value = 0;
      Products[entityIndex][productIndex].offers[offerIndex].price = 0;

      // While the last offer and empty, remove index
      while ((Products[entityIndex][productIndex].numberOfOffers > 0) &&
             (offerIndex == Products[entityIndex][productIndex].numberOfOffers - 1) &&
             (Products[entityIndex][productIndex].offers[offerIndex].price == 0))
      {
        offerIndex--;
        Products[entityIndex][productIndex].numberOfOffers--;
      }
    }
  }

  /// @notice Edit an existing product of an entity.
  /// Entity must exist and be validated by Immutable.
  /// @param productName The name of the new product
  /// @param productURL The primary URL of the product
  /// @param logoURL The logo URL of the product
  /// @param details the product category, languages, etc.
  function productEdit(uint256 productIndex,
                       string calldata productName,
                       string calldata productURL,
                       string calldata logoURL,
                       uint256 details)
    external
  {
    uint256 entityIndex = entityInterface.entityAddressToIndex(msg.sender);
    uint256 productID;

    // Only a validated entity can create a product
    require(entityInterface.entityAddressStatus(msg.sender) > 0, commonInterface.EntityNotValidated());
    require((bytes(productName).length == 0) || (bytes(productURL).length != 0), "URL required");
    require(NumberOfProducts[entityIndex] > productIndex,
            commonInterface.ProductNotFound());

    // Check the product name for duplicates if present
    if (bytes(productName).length > 0)
    {
      // If product exists with same name then fatal error so revert
      for (productID = 0; productID < NumberOfProducts[entityIndex];
           ++productID)
      {
        if (productIndex != productID)
        {
          // Check if the product name matches an existing product
          if (commonInterface.stringsEqual(Products[entityIndex][productID].name, productName))
          {
            // Revert the transaction as product already exists
            revert("name already exists");
          }
        }
      }
    }

    // Update the product information
    Products[entityIndex][productIndex].name = productName;
    Products[entityIndex][productIndex].infoURL = productURL;
    Products[entityIndex][productIndex].logoURL = logoURL;
    Products[entityIndex][productIndex].details = details;

    // Emit new product event and return the product index
    emit productEvent(entityIndex, productIndex, productName,
                      productURL, details);
    return;
  }

  /// @notice Return the number of products maintained by an entity.
  /// Entity must exist.
  /// @param entityIndex The index of the entity
  /// @return the current number of products for the entity
  function productNumberOf(uint256 entityIndex)
    external view returns (uint256)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());

    // Return the number of products for this entity
    if (NumberOfProducts[entityIndex] > 0)
      return NumberOfProducts[entityIndex];
    else
      return 0;
  }

  /// @notice Retrieve existing product name, info and details.
  /// Entity and product must exist.
  /// @param entityIndex The index of the entity
  /// @param productIndex The specific ID of the product
  /// @return name , infoURL, logoURL and details are return values.\
  ///         **name** The name of the product\
  ///         **infoURL** The primary URL for information about the product\
  ///         **logoURL** The URL for the product logo\
  ///         **details** The detail flags (category, language) of product
  function productDetails(uint256 entityIndex, uint256 productIndex)
    external view returns (string memory name, string memory infoURL,
                           string memory logoURL, uint256 details)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());
    string memory resultName;
    string memory resultInfoURL;
    string memory resultLogoURL;

    require(NumberOfProducts[entityIndex] > productIndex,
            commonInterface.ProductNotFound());

    // Return the hash for this organizations product and version
    resultInfoURL = Products[entityIndex][productIndex].infoURL;
    resultLogoURL = Products[entityIndex][productIndex].logoURL;
    resultName = Products[entityIndex][productIndex].name;
    return (resultName, resultInfoURL, resultLogoURL,
            Products[entityIndex][productIndex].details);
  }

  /// @notice Retrieve details for all products of an entity.
  /// Empty arrays if no products are found.
  /// @return names , infoURLs, logoURLs, details and offers are returned as arrays.\
  ///         **names** Array of names of the product\
  ///         **infoURLs** Array of primary URL about the product\
  ///         **logoURLs** Array of URL for the product logos\
  ///         **details** Array of detail flags (category, etc.)\
  ///         **offers** Array of number of Activation offers
  function productAllDetails(uint256 entityIndex)
    external view returns (string[] memory names, string[] memory infoURLs,
                           string[] memory logoURLs, uint256[] memory details,
                           uint256[] memory offers)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());

    string[] memory resultName = new string[](NumberOfProducts[entityIndex]);
    string[] memory resultInfoURL = new string[](NumberOfProducts[entityIndex]);
    string[] memory resultLogoURL = new string[](NumberOfProducts[entityIndex]);
    uint256[] memory resultDetails = new uint256[](NumberOfProducts[entityIndex]);
    uint256[] memory resultNumOffers = new uint256[](NumberOfProducts[entityIndex]);

    // Build result arrays for all product information of an Entity
    for (uint i = 0; i < NumberOfProducts[entityIndex]; ++i)
    {
      resultName[i] = Products[entityIndex][i].name;
      resultInfoURL[i] = Products[entityIndex][i].infoURL;
      resultLogoURL[i] = Products[entityIndex][i].logoURL;
      resultDetails[i] = Products[entityIndex][i].details;
      resultNumOffers[i] = Products[entityIndex][i].numberOfOffers;
    }

    return (resultName, resultInfoURL, resultLogoURL, resultDetails,
            resultNumOffers);
  }

  /// @notice Return the offer price of a product activation license.
  /// Entity, Product and Offer must exist.
  /// @param entityIndex The index of the entity with offer
  /// @param productIndex The product ID of the offer
  /// @param offerIndex The per-product offer ID
  /// @return erc20Token , price, value, offerURL, surcharge and parent are return values.\
  ///         **erc20Token** The address of ERC20 token offer (zero is ETH)\
  ///         **price** The price (ETH or ERC20) for the activation license\
  ///         **value** The duration, flags and value of activation\
  ///         **offerURL** The URL to more information about the offer\
  ///         **surcharge** The transfer surcharge of offer\
  ///         **parent** The required ricardian contract parent (if any)
  function productOfferDetails(uint256 entityIndex,
                               uint256 productIndex,
                               uint256 offerIndex)
    public view returns (address erc20Token, uint256 price, uint256 value,
                         string memory offerURL, uint256 surcharge,
                         uint256 parent)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());
    require(NumberOfProducts[entityIndex] > productIndex,
            commonInterface.ProductNotFound());

    require(Products[entityIndex][productIndex].numberOfOffers > offerIndex,
            commonInterface.OfferNotFound());

    // Return price, value/duration/flags and ERC token of offer
    return (Products[entityIndex][productIndex].offers[offerIndex].tokenAddr,
            Products[entityIndex][productIndex].offers[offerIndex].price,
            Products[entityIndex][productIndex].offers[offerIndex].value,
            Products[entityIndex][productIndex].offers[offerIndex].infoURL,
            Products[entityIndex][productIndex].offers[offerIndex].transferSurcharge,
            Products[entityIndex][productIndex].offers[offerIndex].ricardianParent);
  }

  struct OfferResult
  {
      address[] resultAddr;
      uint256[] resultPrice;
      uint256[] resultValue;
      string[] resultInfoUrl;
      uint256[] resultSurcharge;
      uint256[] resultParent;
  }

  /// @notice Return all the product activation offers
  /// Entity and Product must exist.
  /// @param entityIndex The index of the entity with offer
  /// @param productIndex The product ID of the offer
  /// @return erc20Tokens , prices, values, offerURLs, surcharges and parents are array return values.\
  ///         **erc20Tokens** Array of addresses of ERC20 token offer (zero is ETH)\
  ///         **prices** Array of prices for the activation license\
  ///         **values** Array of duration, flags, and value of activation\
  ///         **offerURLs** Array of URLs to more information on the offers\
  ///         **surcharges** Array of transfer surcharge of offers\
  ///         **parents** Array of ricardian contract parent (if any)
  function productAllOfferDetails(uint256 entityIndex,
                                  uint256 productIndex)
    public view returns (address[] memory erc20Tokens, uint256[] memory prices,
                    uint256[] memory values, string[] memory offerURLs,
                    uint256[] memory surcharges, uint256[] memory parents)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());

    require(NumberOfProducts[entityIndex] > productIndex,
            commonInterface.ProductNotFound());
    OfferResult memory theResult;

    {
      theResult.resultAddr = new address[](Products[entityIndex][productIndex].numberOfOffers);
      theResult.resultPrice = new uint256[](Products[entityIndex][productIndex].numberOfOffers);
      theResult.resultValue = new uint256[](Products[entityIndex][productIndex].numberOfOffers);
      theResult.resultInfoUrl = new string[](Products[entityIndex][productIndex].numberOfOffers);
      theResult.resultSurcharge = new uint256[](Products[entityIndex][productIndex].numberOfOffers);
      theResult.resultParent = new uint256[](Products[entityIndex][productIndex].numberOfOffers);
    }

    // Build result arrays for all offer information of a product
    for (uint i = 0; i < Products[entityIndex][productIndex].numberOfOffers; ++i)
    {
      theResult.resultAddr[i] = Products[entityIndex][productIndex].offers[i].tokenAddr;
      theResult.resultPrice[i] = Products[entityIndex][productIndex].offers[i].price;
      theResult.resultValue[i] = Products[entityIndex][productIndex].offers[i].value;
      theResult.resultInfoUrl[i] = Products[entityIndex][productIndex].offers[i].infoURL;
      theResult.resultSurcharge[i] = Products[entityIndex][productIndex].offers[i].transferSurcharge;
      theResult.resultParent[i] = Products[entityIndex][productIndex].offers[i].ricardianParent;
    }

    // Return array of ERC20 token address, price, value/duration/flags and URL
    return (theResult.resultAddr, theResult.resultPrice, theResult.resultValue,
            theResult.resultInfoUrl, theResult.resultSurcharge, theResult.resultParent);
  }
}

pragma solidity >=0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later

// OpenZepellin upgradable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title Immutable String - common constants and string routines
/// @author Sean Lawless for ImmutableSoft Inc.
/// @dev StringCommon is string related general/pure functions
contract StringCommon is Initializable, OwnableUpgradeable
{
  // Entity Status
  // Type is first 32 bits (bits 0 through 31)
  uint256 public constant Unknown =         0;
  uint256 public constant Creator =         1;
  uint256 public constant Distributor =     2;
  uint256 public constant EndUser =         3;

  // Flags begin at bit 32 and go until bit 63
  uint256 public constant Nonprofit =       (1 << 32);
  uint256 public constant Automatic =       (1 << 33);
  uint256 public constant CustomToken =     (1 << 34);

  // Country of origin
  uint256 public constant CoutryCodeOffset =64;
  uint256 public constant CoutryCodeMask =  (0xFFFF << CoutryCodeOffset);

  // Product Details
  // Category is first 32 bits (bits 0 through 31)
  uint256 public constant Tools =          0;
  uint256 public constant System =         1;
  uint256 public constant Platform =       2;
  uint256 public constant Education =      3;
  uint256 public constant Entertainment =  4;
  uint256 public constant Communications = 5;
  uint256 public constant Professional =   6;
  uint256 public constant Manufacturing =  7;
  uint256 public constant Business =       8;
  // Room here for expansion

  // Flags begin at bit 32 and go until bit 63
  uint256 public constant Hazard =         (1 << 32);
  uint256 public constant Adult =          (1 << 33);
  uint256 public constant Restricted =     (1 << 34);
  // Distribution restricted by export laws of orgin country?
  uint256 public constant USCryptoExport = (1 << 35);
  uint256 public constant EUCryptoExport = (1 << 36);

  // Languages begin at bit 64 and go until bit 127
  //   Ordered by percentage of native speakers
  //   https://en.wikipedia.org/wiki/List_of_languages_by_number_of_native_speakers
  uint256 public constant Mandarin =       (1 << 64);
  uint256 public constant Spanish =        (1 << 65);
  uint256 public constant English =        (1 << 66);
  uint256 public constant Hindi =          (1 << 67);
  uint256 public constant Bengali =        (1 << 68);
  uint256 public constant Portuguese =     (1 << 69);
  uint256 public constant Russian =        (1 << 70);
  uint256 public constant Japanese =       (1 << 71);
  uint256 public constant Punjabi =        (1 << 71);
  uint256 public constant Marathi =        (1 << 72);
  uint256 public constant Teluga =         (1 << 73);
  uint256 public constant Wu =             (1 << 74);
  uint256 public constant Turkish =        (1 << 75);
  uint256 public constant Korean =         (1 << 76);
  uint256 public constant French =         (1 << 77);
  uint256 public constant German =         (1 << 78);
  uint256 public constant Vietnamese =     (1 << 79);
  // Room here for 47 additional languages (bit 127)
  // Bits 128 - 255 Room here for expansion
  //   Up to 128 additional languages for example

  // Product Release Version
  // Version is first four 16 bit values (first 64 bits)
  // Version 0.0.0.0

  // Language bits from above form bits 64 to 127

  // The Platform Type begins at bit 128 and goes until bit 159
  uint256 public constant Windows_x86 =    (1 << 128);
  uint256 public constant Windows_amd64 =  (1 << 129);
  uint256 public constant Windows_aarch64 =(1 << 130);
  uint256 public constant Linux_x86 =      (1 << 131);
  uint256 public constant Linux_amd64 =    (1 << 132);
  uint256 public constant Linux_aarch64 =  (1 << 133);
  uint256 public constant Android_aarch64 =(1 << 134);
  uint256 public constant iPhone_arm64 =   (1 << 135);
  uint256 public constant BIOS_x86 =       (1 << 136);
  uint256 public constant BIOS_amd64 =     (1 << 137);
  uint256 public constant BIOS_aarch32 =   (1 << 138);
  uint256 public constant BIOS_aarch64 =   (1 << 139);
  uint256 public constant BIOS_arm64 =     (1 << 140);
  uint256 public constant Mac_amd64 =      (1 << 141);
  uint256 public constant Mac_arm64 =      (1 << 142);
  // Room here for expansion

  // End with general types
  uint256 public constant SourceCode =     (1 << 156);
  uint256 public constant Agnostic =       (1 << 157);
  uint256 public constant NotApplicable =  (1 << 158);
  uint256 public constant Other =          (1 << 159);
  // Room for expansion up to value (255 << 152) (last byte of type)

  // Bits 160 through 256 are available for expansion

  // Product License Activation Flags
  
  // Flags begin at bit 160 and go until bit 191
  uint256 public constant ExpirationFlag =     (1 << 160); // Activation expiration
  uint256 public constant LimitationFlag =     (1 << 161); // Version/language limitations
                                                    // Cannot be used with feature
  uint256 public constant NoResaleFlag =       (1 << 162); // Disallow resale after purchase
                                                    // Per EU "first sale" law, cannot
                                                    // be set if expiration NOT set
  uint256 public constant FeatureFlag =        (1 << 163); // Specific application feature
                                                    // ie. Value is feature specific
                                                    // CANNOT be used with Limitation
                                                    // flag

  uint256 public constant LimitedOffersFlag =  (1 << 164); // Limited number of offers
                                                    // UniqueId is used for number
                                                    // Offer flag only, not used in
                                                    // activate token id
  uint256 public constant BulkOffersFlag =     (1 << 165); // Limited number of offers
                                                    // UniqueId is used for number
                                                    // Offer flag only, not used in
                                                    // activate token id. Cannot be
                                                    // used with LimitedOffersFlag
  uint256 public constant RicardianReqFlag =   (1 << 166); // Ricardian client token
                                                    // ownership required before
                                                    // transfer or activation is allowed

  // Offset and mask of entity and product identifiers
  uint256 public constant EntityIdOffset = 224;
  uint256 public constant EntityIdMask =  (0xFFFFFFFF << EntityIdOffset);
  uint256 public constant ProductIdOffset = 192;
  uint256 public constant ProductIdMask =  (0xFFFFFFFF << ProductIdOffset);

  // CreatorToken only: Release id 32 bits
  uint256 public constant ReleaseIdOffset = 160;
  uint256 public constant ReleaseIdMask =  (0xFFFFFFFF << ReleaseIdOffset);

  // ActivateToken only: 16 bits to enforce unique token
  uint256 public constant UniqueIdOffset = 176;
  uint256 public constant UniqueIdMask =  (0xFFFF << UniqueIdOffset);

  // Flags allow different activation types and Value layout
  uint256 public constant FlagsOffset = 160;
  uint256 public constant FlagsMask =  (0xFFFF << FlagsOffset);

  // Expiration is common, last before common 128 bit Value
  uint256 public constant ExpirationOffset = 128;
  uint256 public constant ExpirationMask = (0xFFFFFFFF <<
                                     ExpirationOffset);

  // If limitation flag set, the Value is entirely utilized
/* NOT USED BY SMART CONTRACTS - Dapp only - here for reference
  // Bits 64 - 127 are for language (as defined above)
  uint256 public constant LanguageOffset = 64;
  uint256 public constant LanguageMask =  (0xFFFFFFFFFFFFFFFF <<
                                    LanguageOffset);

  // Final 64 bits of value is version (4 different 16 bit values)
  uint256 public constant LimitVersionOffset = 0;
  uint256 public constant LimitVersionMask =  (0xFFFFFFFFFFFFFFFF <<
                                        LimitVersionOffset);
*/

  // The value is the 128 LSBs
  //   32 bits if limitations flag set (96 bits version/language)
  //   All 128 bits if limitations flag not set
  //   
  uint256 public constant ValueOffset = 0;
  uint256 public constant ValueMask =  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  // Error strings
  string public constant EntityIsZero = "EntityID zero";
  string public constant OfferNotFound = "Offer not found";
  string public constant EntityNotValidated = "Entity not validated";

  string public constant ProductNotFound = "Product not found";

  string public constant TokenEntityNoMatch = "Token entity does not match";
  string public constant TokenProductNoMatch = "Token product id does not match";
  string public constant TokenNotUnique = "TokenId is NOT unique";

  /// @notice Initialize the StringCommon smart contract
  ///   Called during first deployment only (not on upgrade) as
  ///   this is an OpenZepellin upgradable contract
  function initialize() public initializer
  {
    __Ownable_init();
/*
  constructor() Ownable()
  {
*/
  }

/*
  /// @notice Convert a base ENS node and label to a node (namehash).
  /// ENS nodes are represented as bytes32.
  /// @param node The ENS subnode the label is a part of
  /// @param label The bytes32 of end label
  /// @return The namehash in bytes32 format
  function namehash(bytes32 node, bytes32 label)
    public pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(node, label));
  }

  /// @notice Convert an ASCII string to a normalized string.
  /// Oversimplified, removes many legitimate characters.
  /// @param str The string to normalize
  /// @return The normalized string
  function normalizeString(string memory str)
    public pure returns (string memory)
  {
    bytes memory bStr = bytes(str);
    uint j = 0;
    uint i = 0;

    // Loop to count number of characters result will have
    for (i = 0; i < bStr.length; i++) {
      // Skip if character is not a letter
      if ((bStr[i] < 'A') || (bStr[i] > 'z') ||
          ((bStr[i] > 'Z') && (bStr[i] < 'a')))
        continue;
      ++j;
    }

    // Allocate the resulting string
    bytes memory bLower = new bytes(j);

    // Loop again converting characters to normalized equivalent
    j = 0;
    for (i = 0; i < bStr.length; i++)
    {
      // Skip if character is not a letter
      if ((bStr[i] < 'A') || (bStr[i] > 'z') ||
          ((bStr[i] > 'Z') && (bStr[i] < 'a')))
        continue;

      // Convert uppercase to lower
      if ((bStr[i] >= 'A') && (bStr[i] <= 'Z')) {
        // So we add 32 to make it lowercase
        bLower[j] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[j] = bStr[i];
      }
      ++j;
    }
    return string(bLower);
  }
*/

  /// @notice Compare strings and return true if equal.
  /// Case sensitive.
  /// @param _a The string to be compared
  /// @param _b The string to compare
  /// @return true if strings are equal, otherwise false
  function stringsEqual(string memory _a, string memory _b)
    public pure virtual returns (bool)
  {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);

    // Return false if length mismatch
    if (a.length != b.length)
      return false;

    // Loop and return false if any character does not match
    for (uint i = 0; i < a.length; i ++)
      if (a[i] != b[i])
        return false;

    // Otherwise strings match so return true
    return true;
  }

/*
  /// @notice Convert a string to a bytes32 equivalent.
  /// Case sensitive.
  /// @param source The source string
  /// @return the bytes32 equivalent of 'source'
  function stringToBytes32(string memory source)
    public pure returns (bytes32 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0)
      return 0x0;

    assembly
    {
      result := mload(add(source, 32))
    }
  }
*/
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later

import "./StringCommon.sol";

// OpenZepellin upgradable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/*
// OpenZepellin standard contracts
import "@openzeppelin/contracts/access/Ownable.sol";
*/

/* //ENS integration (old/deprecated)
import "./ImmutableResolver.sol";
import "@ensdomains/ens/contracts/ENS.sol";
import "./AddrResolver.sol";
*/

/// @title Immutable Entity trust zone used by ecosystem members
/// @author Sean Lawless for ImmutableSoft Inc.
/// @notice Member entities can accept ETH escrow payments and change
///         or configure a recovery wallet address. Only after new
///         members create their Entity (with a blockchain transaction)
///         is ownership of the wallet address proven to ImmutableSoft
///         which then allows us to approve the new member.
contract ImmutableEntity is Initializable, OwnableUpgradeable
/*
contract ImmutableEntity is Initializable, Ownable*/
{
  address payable private Bank;
  uint256 UpgradeFee;

  // Mapping between the organization address and the global entity index
  mapping (address => uint256) private EntityIndex;

  // Mapping between the entity index and the entity status
  mapping (uint256 => uint256) private EntityStatus;

  // Organizational entity
  struct Entity
  {
    address payable bank;
    address prevAddress;
    address nextAddress;
    string name;
    string infoURL;
    uint256 createTime;
//    string entityEnsName;
  }

  // Array of current entity addresses, indexable by entity index
  mapping (uint256 => address) private EntityArray;

  // Array of entities, indexable by entity index
  mapping (uint256 => Entity) private Entities;
  uint256 NumberOfEntities;

  // External contract interfaces
  StringCommon private commonInterface;
  // Ethereum Name Service contract and variables
//  ImmutableResolver private resolver;

  // Entity interface events
  event entityEvent(uint256 entityIndex,
                    string name, string url);

  /// @notice Initialize the ImmutableEntity smart contract
  ///   Called during first deployment only (not on upgrade) as
  ///   this is an OpenZepellin upgradable contract
  /// @param commonAddr The StringCommon contract address
  function initialize(address commonAddr) public initializer
  {
    __Ownable_init();
/*
  // OpenZepellin standard contracts
  constructor(address commonAddr) Ownable()
  {
*/
    // Initialize string and token contract interfaces
    commonInterface = StringCommon(commonAddr);
    Bank = payable(msg.sender);
    UpgradeFee = 10000000000000000000; //10 MATIC ~ $20)
  }

  ///////////////////////////////////////////////////////////
  /// ADMIN (onlyOwner)
  ///////////////////////////////////////////////////////////
/*
  /// @notice Set ENS resolver. Zero address disables resolver.
  /// Administrator (onlyOwner)
  /// @param resolverAddr the address of the immutable resolver
  function entityResolver(address resolverAddr, bytes32 rootNode)
    external onlyOwner
  {
    resolver = ImmutableResolver(resolverAddr);
    resolver.setRootNode(rootNode);
  }
*/
  /// @notice Change bank that contract pays ETH out too.
  /// Administrator only.
  /// @param newBank The Ethereum address of new ecosystem bank
  function entityOwnerBank(address payable newBank)
    external onlyOwner
  {
    require(newBank != address(0), "invalid address");
    Bank = newBank;
  }

  /// @notice Retrieve fee to upgrade.
  /// Administrator only.
  /// @param newFee the new upgrade fee
  function entityOwnerUpgradeFee(uint256 newFee)
    external onlyOwner
  {
    UpgradeFee = newFee;
  }

  /// @notice Update an entity status, non-zero value is approval.
  /// See ImmutableConstants.sol for status values and flags.
  /// Administrator (onlyOwner)
  /// @param entityIndex index of entity to change status
  /// @param status The new complete status aggregate value
  function entityStatusUpdate(uint256 entityIndex, uint256 status)
    external onlyOwner
  {
    uint256 newStatus = status;

    // If not disable, add expiration timestamp (one year from now)
    if (status != 0)
      newStatus |= ((block.timestamp + 365 days) << commonInterface.ExpirationOffset());

    // Update the organization status
    EntityStatus[entityIndex] = newStatus;

/*
    // If ENS configured, add resolver
    if (address(resolver) != address(0))
    {
      // Register entity with ENS: <entityName>.immutablesoft.eth
      string memory normalName = commonInterface.normalizeString(entity.name);
      bytes32 subnode = commonInterface.namehash(entityRootNode(),
                          commonInterface.stringToBytes32(normalName));

      // Set address for node, owner to entity address and name to
      //   normalized name string.
      resolver.setAddr(subnode, EntityArray[entityIndex]);
//      setName(subnode, normalName);
      entity.entityEnsName = normalName;
    }
*/
  }

  ///////////////////////////////////////////////////////////
  /// Ecosystem is split into entity, product and license
  ///////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////
  /// ENTITY
  ///////////////////////////////////////////////////////////

  /// @notice Create an organization.
  /// Entities require approval (entityStatusUpdate) after create.
  /// @param entityName The legal name of the entity
  /// @param entityURL The valid URL of the entity
  /// @return the new entity unique identifier (index)
  function entityCreate(string memory entityName,
                        string memory entityURL)
    public returns (uint256)
  {
    require(bytes(entityName).length != 0, "name empty");
    require(bytes(entityURL).length != 0, "URL empty");
    uint256 entityIndex = NumberOfEntities + 1;
    require(EntityIndex[msg.sender] == 0, "already created");

    // Require the entity name be unique
    for (uint256 i = 1; i < NumberOfEntities + 1; ++i)
      require(!commonInterface.stringsEqual(Entities[i].name, entityName),
              "name exists");

    // Push the entity to permenant storage on the blockchain
    Entities[entityIndex].bank = payable(msg.sender);
    Entities[entityIndex].name = entityName;
    Entities[entityIndex].infoURL = entityURL;
    Entities[entityIndex].createTime = block.timestamp;

    // Push the address to the entity array and clear status
    EntityArray[entityIndex] = msg.sender;
    EntityStatus[entityIndex] = 0;
    EntityIndex[msg.sender] = entityIndex; // global entity id
    NumberOfEntities++;

    // Emit entity event: id, name and URL
    emit entityEvent(entityIndex, entityName, entityURL);
    return entityIndex;
  }

  /// @notice Update an organization.
  /// Entities require reapproval (entityStatusUpdate) after update.
  /// @param entityName The legal name of the entity
  /// @param entityURL The valid URL of the entity
  function entityUpdate(string calldata entityName,
                        string calldata entityURL)
    external
  {
    require(bytes(entityName).length != 0, "name empty");
    require(bytes(entityURL).length != 0, "URL empty");
    uint256 entityIndex = EntityIndex[msg.sender];
    require(entityIndex > 0, "Sender unknown");

    // Require the new entity name be unique
    for (uint256 i = 0; i < NumberOfEntities; ++i)
    {
      // Skip the duplicate name check for sender entity
      //   ie. Allow only URL to be changed
      if (i != entityIndex)
        require(!commonInterface.stringsEqual(Entities[i].name,
                entityName), "name exists");
    }

    // Update entity name and/or URL
    Entities[entityIndex].name = entityName;
    Entities[entityIndex].infoURL = entityURL;

    // Not required, will monitor for fraud

    // Clear the entity status as re-validation required
/*    EntityStatus[entityIndex] &= 0xFF;*/

    // Emit entity event
    emit entityEvent(entityIndex, entityName, entityURL);
  }

  /// @notice Change bank address that contract pays out to.
  /// msg.sender must be a registered entity.
  /// @param newBank payable Ethereum address owned by entity
  function entityBankChange(address payable newBank)
    external
  {
    uint256 entityIndex = EntityIndex[msg.sender];
    require(entityIndex > 0, commonInterface.EntityIsZero());
    Entity storage entity = Entities[entityIndex];

    // Only a validated entity can configue a bank address
    require(entityAddressStatus(msg.sender) > 0, commonInterface.EntityNotValidated());
    require(newBank != address(0), "Bank cannot be zero");
    entity.bank = newBank;
  }

  /// @notice Propose to move an entity (change addresses).
  /// To complete move, call entityMoveAddress with new address.
  /// msg.sender must be a registered entity.
  /// @param nextAddress The next address of the entity
  function entityAddressNext(address nextAddress)
    external
  {
    uint256 entityIndex = EntityIndex[msg.sender];
    require(entityIndex > 0, commonInterface.EntityIsZero());
    Entity storage entity = Entities[entityIndex];

    // Ensure next address and status and status are valid
    require(msg.sender != nextAddress, "Next not different");
    require(nextAddress != address(0), "Next is zero");
    require(entityAddressStatus(msg.sender) > 0, commonInterface.EntityNotValidated());

    // Require next address to have no entity configured
    require(EntityIndex[nextAddress] == 0, "Next in use");

    // Assign the new address to the organization
    entity.nextAddress = nextAddress;
  }

  /// @notice Admin override for moving an entity (change addresses).
  /// To complete move call entityMoveAddress with new address.
  /// msg.sender must be Administrator (owner).
  /// @param entityAddress The address of the entity to move
  /// @param nextAddress The next address of the entity
  function entityAdminAddressNext(address entityAddress,
                                  address nextAddress)
    external onlyOwner
  {
    uint256 entityIndex = EntityIndex[entityAddress];
    require(entityIndex > 0, commonInterface.EntityIsZero());
    Entity storage entity = Entities[entityIndex];

    // Ensure next address is valid
    require(entityAddress != nextAddress, "Next not different");
    require(nextAddress != address(0), "Next is zero");
    // Require next address to have no entity configured
    require(EntityIndex[nextAddress] == 0, "Next in use");

    // Assign the new address to the organization
    entity.nextAddress = nextAddress;
  }

  /// @notice Finish moving an entity (change addresses).
  /// First call entityNextAddress with previous address.
  /// msg.sender must be new entity address set with entityNextAddress.
  /// @param oldAddress The previous address of the entity
  function entityAddressMove(address oldAddress)
    external
  {
    uint256 entityIndex = EntityIndex[oldAddress];
    require(entityIndex > 0, commonInterface.EntityIsZero());
    Entity storage entity = Entities[entityIndex];
    require(entity.nextAddress == msg.sender, "Next not sender");
    uint256 entityStatus = entityAddressStatus(oldAddress);
    require(entityStatus > 0, commonInterface.EntityNotValidated());

    // Assign the indexing for the new address
    EntityIndex[msg.sender] = entityIndex;
    // Clear the old address
    EntityIndex[oldAddress] = 0;
    EntityArray[entityIndex] = msg.sender;
    entity.prevAddress = oldAddress;

    // If old bank address was adminstrator, move bank to new address
    if (entity.bank == oldAddress)
      entity.bank = payable(msg.sender);
  }

  /// @notice Pay (transfer ETH to ImmutableSoft) for an upgrade.
  /// msg.sender must be registered Entity in good standing.
  /// Payable, requires ETH transfer. Current status of Manual upgrades
  /// to Automatic, Automatic upgrades to Custom. Upgrading Custom only
  /// extends your membership.
  function entityUpgrade()
    public payable
  {
    uint256 entityIndex = EntityIndex[msg.sender];
    require(entityIndex > 0, commonInterface.EntityIsZero());
    require(msg.value >= UpgradeFee, "Payment required");

    uint256 entityStatus = EntityStatus[entityIndex];
    require(entityStatus > 0, commonInterface.EntityNotValidated());

    // Deserialize the expiration date/time
    uint256 expiration = ((entityStatus & commonInterface.ExpirationMask()) >>
                           commonInterface.ExpirationOffset());

    // If unexpired then upgrade AND extend
    if (expiration > block.timestamp)
    {
      // If manual, upgrade to automatic flags
      if ((entityStatus & (commonInterface.Automatic() |
                           commonInterface.CustomToken())) == 0)
        entityStatus |= commonInterface.Automatic();

      // Otherwise upgrade to Custom token flags
      else
        entityStatus |= commonInterface.CustomToken();
    }

    // Otherwise entity expired so set to Automatic and current time
    else
    {
      entityStatus &= ~(commonInterface.Automatic() | commonInterface.CustomToken());
      entityStatus |= commonInterface.Automatic();
      expiration = block.timestamp;
    }

    // All upgrades are given a one year expiration (or extended one year)
    entityStatus &= ~(commonInterface.ExpirationMask() << commonInterface.ExpirationOffset());
    entityStatus |= ((expiration + 365 days) << commonInterface.ExpirationOffset());

    // Write new status on-chain
    EntityStatus[entityIndex] = entityStatus;

    // Transfer ETH funds to ImmutableSoft
    Bank.transfer(msg.value);
  }

  /// @notice Pay (transfer ETH to) an entity.
  /// Entity must exist and have bank configured.
  /// Payable, requires ETH transfer.
  /// msg.sender is the payee (could be ProductActivate contract)
  /// @param entityIndex The index of entity recipient bank
  function entityPay(uint256 entityIndex)
    public payable
  {
    uint256 entityStatus = entityIndexStatus(entityIndex);
    if (entityIndex > 0)
    {
      Entity storage entity = Entities[entityIndex];

      require(entityStatus > 0, commonInterface.EntityNotValidated());
      require(msg.value > 0, "ETH required");
      require(entity.bank != address(0), "Bank not configured");

      // Transfer ETH funds
      entity.bank.transfer(msg.value);
    }

    // Otherwise transfer ETH funds to ImmutableSoft
    else
      Bank.transfer(msg.value);
  }

  /// @notice Retrieve official entity status.
  /// Status of zero (0) return if entity not found.
  /// @param entityIndex The index of the entity
  /// @return the entity status as maintained by Immutable
  function entityIndexStatus(uint256 entityIndex)
    public view returns (uint256)
  {
    if ((entityIndex > 0) && (entityIndex <= NumberOfEntities))
      return EntityStatus[entityIndex];
    else
      return 0;
  }

  /// @notice Retrieve official entity status.
  /// Status of zero (0) return if entity not found.
  /// @param entityAddress The address of the entity
  /// @return the entity status as maintained by Immutable
  function entityAddressStatus(address entityAddress)
    public view returns (uint256)
  {
    uint256 entityIndex = EntityIndex[entityAddress];

    return entityIndexStatus(entityIndex);
  }

  /// @notice Retrieve official global entity index.
  /// Return index of zero (0) is not found.
  /// @param entityAddress The address of the entity
  /// @return the entity index as maintained by Immutable
  function entityAddressToIndex(address entityAddress)
    public view returns (uint256)
  {
    return EntityIndex[entityAddress];
  }

  /// @notice Retrieve current global entity address.
  /// Return address of zero (0) is not found.
  /// @param entityIndex The global index of the entity
  /// @return the current entity address as maintained by Immutable
  function entityIndexToAddress(uint256 entityIndex)
    public view returns (address)
  {
    if ((entityIndex == 0) || (entityIndex > NumberOfEntities))
      return (address(0));
    return EntityArray[entityIndex];
  }

  /// @notice Retrieve entity details from index.
  /// @param entityIndex The index of the entity
  /// @return name and URL are return values.\
  ///         **name** the entity name\
  ///         **URL** the entity name\
  function entityDetailsByIndex(uint256 entityIndex)
    public view returns (string memory name, string memory URL)
  {
    if ((entityIndex == 0) || (entityIndex > NumberOfEntities))
      return ("", "");
    Entity storage entity = Entities[entityIndex];

    // Return the name and URL for this organization
    return (entity.name, entity.infoURL);
  }

  /// @notice Retrieve number of entities.
  /// @return the number of entities
  function entityNumberOf()
    public view returns (uint256)
  {
    return NumberOfEntities;
  }

  /// @notice Retrieve fee to upgrade.
  /// @return the number of entities
  function entityUpgradeFee()
    public view returns (uint256)
  {
    return UpgradeFee;
  }

/*
  /// @notice Return ENS immutablesoft root node.
  /// @return the bytes32 ENS root node for immutablesoft.eth
  function entityRootNode()
    public view returns (bytes32)
  {
    if (address(resolver) != address(0))
      return resolver.rootNode();
    else
      return 0;
  }
*/

  /// @notice Retrieve bank address that contract pays out to
  /// @param entityIndex The index of the entity
  /// @return bank Ethereum address to pay out entity
  function entityBank(uint256 entityIndex)
    external view returns (address bank) 
  {
    if (entityIndex > 0)
      return Entities[entityIndex].bank;
    else
      return Bank;
  }

  /// @notice Retrieve all entity details
  /// Status of empty arrays if none found.
  /// @return status , name and URL arrays are return values.\
  ///         **status** Array of entity status\
  ///         **name** Array of entity names\
  ///         **URL** Array of entity URLs
  function entityAllDetails()
    external view returns (uint256[] memory status, string[] memory name,
                           string[] memory URL)
  {
    uint256[] memory resultStatus = new uint256[](NumberOfEntities);
    string[] memory resultName = new string[](NumberOfEntities);
    string[] memory resultURL = new string[](NumberOfEntities);

    for (uint i = 1; i <= NumberOfEntities; ++i)
    {
      resultStatus[i - 1] = EntityStatus[i];
      resultName[i- 1] = Entities[i].name;
      resultURL[i - 1] = Entities[i].infoURL;
    }

    return (resultStatus, resultName, resultURL);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}