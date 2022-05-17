pragma solidity >=0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later

import "./StringCommon.sol";
import "./ImmutableEntity.sol";
import "./ProductActivate.sol";
import "./CreatorToken.sol";
import "./ActivateToken.sol";

// OpenZepellin upgradable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/*
// OpenZepellin standard contracts
//import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
*/

// OpenZepellin upgradable contracts
contract ProductActivate is Initializable, OwnableUpgradeable
/*
// OpenZepellin standard contracts
contract ProductActivate is Ownable
*/
{
  mapping (uint256 => uint256) private TokenIdToOfferPrice;
  mapping (uint256 => uint256) private TransferSurcharge;

  ActivateToken private activateTokenInterface;
  CreatorToken private creatorTokenInterface;
  ImmutableEntity private entityInterface;
  ImmutableProduct private productInterface;
  StringCommon private commonInterface;

  /// @notice Initialize the ProductActivate smart contract
  ///   Called during first deployment only (not on upgrade) as
  ///   this is an OpenZepellin upgradable contract
  /// @param commonAddr The StringCommon contract address
  /// @param entityContractAddr The ImmutableEntity token contract address
  /// @param productContractAddr The ImmutableProduct token contract address
  /// @param activateTokenAddr The ActivateToken token contract address
  /// @param creatorTokenAddr The CreatorToken token contract address
  function initialize(address commonAddr, address entityContractAddr,
                      address productContractAddr, address activateTokenAddr,
                      address creatorTokenAddr)
    public initializer
  {
    __Ownable_init();

/*
  // OpenZepellin standard contracts
  constructor(address commonAddr, address entityContractAddr,
              address productContractAddr, address activateTokenAddr,
              address creatorTokenAddr)
                                           Ownable()
  {
*/
    // Initialize the contract interfaces
    commonInterface = StringCommon(commonAddr);
    entityInterface = ImmutableEntity(entityContractAddr);
    productInterface = ImmutableProduct(productContractAddr);
    activateTokenInterface = ActivateToken(activateTokenAddr);
    creatorTokenInterface = CreatorToken(creatorTokenAddr);
  }

  ///////////////////////////////////////////////////////////
  /// PRODUCT ACTIVATE LICENSE
  ///////////////////////////////////////////////////////////

  /// @notice Create manual product activation license for end user.
  /// mes.sender must own the entity and product.
  /// Costs 1 IuT token if sender not registered as automatic
  /// @param productIndex The specific ID of the product
  /// @param licenseHash the activation license hash from end user
  /// @param licenseValue the value of the license
  /// @param transferSurcharge the additional cost/surcharge to transfer
  /// @param ricardianParent The Ricardian contract parent (if any)
  function activateCreate(uint256 productIndex, uint256 licenseHash,
                          uint256 licenseValue, uint256 transferSurcharge,
                          uint256 ricardianParent)
    external
  {
    uint256 entityIndex = entityInterface.entityAddressToIndex(msg.sender);
    // Only a validated commercial entity can create an offer
    uint256 entityStatus = entityInterface.entityAddressStatus(msg.sender);
    require(entityStatus > 0, commonInterface.EntityNotValidated());
    require((entityStatus & commonInterface.CustomToken()) == commonInterface.CustomToken(),
            "Entity requires custom");
    require(productInterface.productNumberOf(entityIndex) > productIndex,
            commonInterface.ProductNotFound());
    require((((licenseValue & commonInterface.RicardianReqFlag()) == 0) ||
             (ricardianParent > 0)), "Ricardian flag but no parent");

    uint256 tokenId = activateTokenInterface.mint(msg.sender, entityIndex, productIndex,
                          licenseHash, licenseValue, ricardianParent);
    if (transferSurcharge > 0)
      TransferSurcharge[tokenId] = transferSurcharge;
  }

  struct ActivationOffer
  {
    uint256 priceInTokens;
    uint256 value;
    address erc20token;
    string infoUrl;
    uint256 transferSurcharge;
    uint256 ricardianParent;
  }


  /// @notice Purchase a digital product activation license.
  /// mes.sender is the purchaser.
  /// @param entityIndex The entity offering the product license
  /// @param productIndex The specific ID of the product
  /// @param offerIndex the product activation offer to purchase
  /// @param numPurchases the number of offers to purchase
  /// @param licenseHashes Array of end user identifiers to activate
  /// @param ricardianClients Array of end client agreement contracts
  function activatePurchase(uint256 entityIndex, uint256 productIndex,
                            uint256 offerIndex, uint16 numPurchases,
                            uint256[] memory licenseHashes,
                            uint256[] memory ricardianClients)
    external payable
  {
    // Ensure vendor is registered and product exists
    require(entityInterface.entityIndexStatus(entityIndex) > 0,
            commonInterface.EntityNotValidated());
    require(productInterface.productNumberOf(entityIndex) > productIndex,
            commonInterface.ProductNotFound());
    ActivationOffer memory theOffer;

    (theOffer.erc20token, theOffer.priceInTokens, theOffer.value,
     theOffer.infoUrl, theOffer.transferSurcharge, theOffer.ricardianParent) =
      productInterface.productOfferDetails(entityIndex, productIndex, offerIndex);
    require(theOffer.priceInTokens > 0, commonInterface.OfferNotFound());
    require(numPurchases > 0, "Invalid num purchases");

    uint256 theDuration = ((theOffer.value & commonInterface.ExpirationMask()) >> commonInterface.ExpirationOffset());
    uint256 tokenId;

    // If a bulk offer purchased, create multiples of tokens
    if ((theOffer.value & commonInterface.BulkOffersFlag()) > 0)
      numPurchases *= (uint16)((theOffer.value & commonInterface.UniqueIdMask()) >> commonInterface.UniqueIdOffset());

    // Purchase all the activation licenses
    for (uint i = 0; i < numPurchases; ++i)
    {
      // If expiration then update tokenId to include new expiration
      //  First clear then set expiration based on duration and now
      if ((theDuration > 0) && ((theOffer.value & commonInterface.ExpirationFlag()) > 0))
      {
        theOffer.value &= ~commonInterface.ExpirationMask();
        theOffer.value |= ((theDuration + block.timestamp) << commonInterface.ExpirationOffset()) & commonInterface.ExpirationMask();
      }

      // Check that ricardian client matches the offer's parent
      if (theOffer.ricardianParent > 0)
      {
        require(ricardianClients[i] > 0, "Client required");
        uint parentDepth = creatorTokenInterface.creatorParentOf(
                        ricardianClients[i], theOffer.ricardianParent);
        require(parentDepth > 0, "Parent not found");
      }
      else
        require(ricardianClients[i] == 0, "Client not allowed");

      // Check if this is a renewal (hash exists)
      if (activateTokenInterface.activateIdToTokenId(licenseHashes[i]) > 0)
      {
        // Look up tokenId from the old activation hash
        tokenId = activateTokenInterface.activateIdToTokenId(licenseHashes[i]);

        // Require that caller (msg.sender) is the owner
        require(activateTokenInterface.ownerOf(tokenId) == msg.sender, "Not token owner");

        // Require entity/product id's, flags and limitations match the token
        require((tokenId & (commonInterface.EntityIdMask() | commonInterface.ProductIdMask() | commonInterface.FlagsMask() | commonInterface.ValueMask())) ==
                ((entityIndex << commonInterface.EntityIdOffset()) | (productIndex << commonInterface.ProductIdOffset()) |
                (theOffer.value & (commonInterface.FlagsMask() | commonInterface.ValueMask()))),
                "Token does not match offer");

        // Extend time duration by whatever was remaining, if any
        if (((theDuration > 0) && ((theOffer.value & commonInterface.ExpirationFlag()) > 0)) &&
            (((tokenId & commonInterface.ExpirationMask()) >> commonInterface.ExpirationOffset()) > block.timestamp))
        {
          theDuration += ((tokenId & commonInterface.ExpirationMask()) >> commonInterface.ExpirationOffset()) - block.timestamp;
          theOffer.value &= ~commonInterface.ExpirationMask();
          theOffer.value |= ((theDuration + block.timestamp) << commonInterface.ExpirationOffset()) & commonInterface.ExpirationMask();
        }

        // burn the old token
        activateTokenInterface.burn(tokenId);
      }

      // If a limited amount of offers, inform product offer of purchase
      if ((theOffer.value & commonInterface.LimitedOffersFlag()) > 0)
        productInterface.productOfferPurchased(entityIndex,
                                               productIndex, offerIndex);

      // Create a new ERC721 activate token for the sender
      tokenId = activateTokenInterface.mint(msg.sender, entityIndex, productIndex,
                                  licenseHashes[i], theOffer.value,
          ((theOffer.value & commonInterface.RicardianReqFlag()) > 0) ?
                                  theOffer.ricardianParent : 0);
      if (theOffer.transferSurcharge > 0)
        TransferSurcharge[tokenId] = theOffer.transferSurcharge;
    }

    // If a bulk offer purchased, divide back to original # of tokens
    if ((theOffer.value & commonInterface.BulkOffersFlag()) > 0)
      numPurchases /= (uint16)((theOffer.value & commonInterface.UniqueIdMask()) >> commonInterface.UniqueIdOffset());

    // If purchase offer is not a token, transfer ETH
    if (theOffer.erc20token == address(0))
    {
      uint256 feeAmount = 0;
      require(msg.value >= theOffer.priceInTokens * numPurchases, "Not enough ETH");

      // If entity is manual (pay as you go) add fee of 5%
      if ((entityInterface.entityIndexStatus(entityIndex) &
          (commonInterface.Automatic() | commonInterface.CustomToken()))
           == 0)
        feeAmount = (msg.value * 5) / 100;

      // Transfer the ETH to the entity bank address
      entityInterface.entityPay{value: msg.value - feeAmount}
                                    (entityIndex);

      // Move fee, if any, into ImmutableSoft bank account
      if (feeAmount > 0)
        entityInterface.entityPay{value: feeAmount }(0);
    }

    // Otherwise the purchase is an exchange of ERC20 tokens
    else
    {
      IERC20Upgradeable erc20TokenInterface = IERC20Upgradeable(theOffer.erc20token);

      // Transfer tokens to the sender and revert if failure
      erc20TokenInterface.transferFrom(msg.sender, entityInterface.
          entityIndexToAddress(entityIndex), theOffer.priceInTokens * numPurchases);
    }
  }

  /// @notice Move a digital product activation license.
  /// mes.sender must be the activation license owner.
  /// @param entityIndex The entity who owns the product
  /// @param productIndex The specific ID of the product
  /// @param oldLicenseHash the existing activation identifier
  /// @param newLicenseHash the new activation identifier
  function activateMove(uint256 entityIndex,
                        uint256 productIndex,
                        uint256 oldLicenseHash,
                        uint256 newLicenseHash)
    external
  {
    // Ensure vendor is registered and product exists
    require(entityInterface.entityIndexStatus(entityIndex) > 0, commonInterface.EntityNotValidated());
    uint256 tokenId;

    // Look up tokenId from the old activation hash
    tokenId = activateTokenInterface.activateIdToTokenId(oldLicenseHash);
    require(tokenId > 0, "TokenId invalid");

    // Ensure sender is the token owner
    require(msg.sender == activateTokenInterface.ownerOf(tokenId), "Sender is not owner");

    // Require the entity and product id's match the token
    require((tokenId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset() == entityIndex, commonInterface.TokenEntityNoMatch());
    require((tokenId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset() == productIndex, commonInterface.TokenProductNoMatch());

    // Require the hash matches the token and new one is different
    require(activateTokenInterface.tokenIdToActivateId(tokenId) == oldLicenseHash, "Activate hash mismatch");
    require(activateTokenInterface.tokenIdToActivateId(tokenId) != newLicenseHash, "New hash must differ");

    // Move/Change the activation hash stored in the token
    activateTokenInterface.activateTokenMoveHash(tokenId,
                                       newLicenseHash, oldLicenseHash);
  }

  /// @notice Offer a digital product license for resale.
  /// mes.sender must own the activation license.
  /// @param entityIndex The entity who owns the product
  /// @param productIndex The specific ID of the product
  /// @param licenseHash the existing activation identifier
  /// @param priceInEth The ETH cost to purchase license
  /// @return the tokenId of the activation offered for resale
  function activateOfferResale(uint256 entityIndex, uint256 productIndex,
                               uint256 licenseHash, uint256 priceInEth)
    external returns (uint256)
  {
    // Ensure vendor is registered and product exists
    uint256 entityStatus = entityInterface.entityIndexStatus(entityIndex);
    require(entityStatus > 0, commonInterface.EntityNotValidated());
    uint256 tokenId;

    // Look up tokenId from the activation hash
    tokenId = activateTokenInterface.activateIdToTokenId(licenseHash);
    require(tokenId > 0, "TokenId invalid");
    require(msg.sender == activateTokenInterface.ownerOf(tokenId), "Sender is not owner");

    // Require the entity and product id's match the token
    require((tokenId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset() == entityIndex, commonInterface.TokenEntityNoMatch());
    require((tokenId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset() == productIndex, commonInterface.TokenProductNoMatch());
    require((tokenId & commonInterface.NoResaleFlag()) == 0, "No resale rights");

    // Set activation to "for sale"
    TokenIdToOfferPrice[tokenId] = priceInEth;
    return tokenId;
  }

  /// @notice Transfer/Resell a digital product activation license.
  /// License must be 'for sale' and msg.sender is new owner.
  /// @param entityIndex The entity who owns the product
  /// @param productIndex The specific ID of the product
  /// @param licenseHash the existing activation identifier to purchase
  /// @param newLicenseHash the new activation identifier after purchase
  function activateTransfer(uint256 entityIndex,
                            uint256 productIndex,
                            uint256 licenseHash,
                            uint256 newLicenseHash)
    external payable
  {
    // Ensure vendor is registered and product exists
    uint256 entityStatus = entityInterface.entityIndexStatus(entityIndex);
    require(entityStatus > 0, commonInterface.EntityNotValidated());

    uint256 tokenId;

    // Look up tokenId from the old activation hash
    tokenId = activateTokenInterface.activateIdToTokenId(licenseHash);
    require(tokenId > 0, "TokenId invalid");

    // Require the license is offered for sale and price valid
    require(TokenIdToOfferPrice[tokenId] > 0, "License not for sale");
    if ((tokenId & commonInterface.ExpirationFlag()) == commonInterface.ExpirationFlag())
      require((((tokenId & commonInterface.ExpirationMask()) >> commonInterface.ExpirationOffset()) == 0) ||
              (((tokenId & commonInterface.ExpirationMask()) >> commonInterface.ExpirationOffset()) > block.timestamp), "Resale of expired license invalid");

    // Ensure new identifier is different from current
    require(licenseHash != newLicenseHash, "Identifier identical");

    // Get the old activation license falgs and ensure it is valid
    require(((tokenId & commonInterface.FlagsMask()) >> commonInterface.FlagsOffset()) > 0, "Old license not valid");
    require((tokenId & commonInterface.NoResaleFlag()) == 0, "No resale rights");

    // Require the entity and product id's match the token
    require((tokenId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset() == entityIndex, commonInterface.TokenEntityNoMatch());
    require((tokenId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset() == productIndex, commonInterface.TokenProductNoMatch());

    // Look up the license owner and their entity status
    uint256 fee = 0;
    address licenseOwner = activateTokenInterface.ownerOf(tokenId);
    address payable payableOwner = payable(licenseOwner);
    uint256 ownerStatus = entityInterface.entityAddressStatus(licenseOwner);

    require(msg.value >= TokenIdToOfferPrice[tokenId] + TransferSurcharge[tokenId], "Not enough ETH");

    // Transfer the activate token and update to the new owner
    activateTokenInterface.safeTransferFrom(licenseOwner,
                                            msg.sender, tokenId);

    // Update to the new activation identifier (if any)
    if (newLicenseHash > 0)
      activateTokenInterface.activateTokenMoveHash(tokenId, newLicenseHash, 0);

    // Clear offer price so the token is no longer listed for sale
    TokenIdToOfferPrice[tokenId] = 0;

    // Transfer any surcharge to original creator if required
    if (TransferSurcharge[tokenId] > 0)
      entityInterface.entityPay{value: TransferSurcharge[tokenId]}
               (entityIndex);

    // If activation owner is registered, use lower fee if any
    //   Any additional ETH is a "tip" to creator
    if (ownerStatus > 0)
    {
      if ((ownerStatus & (commonInterface.Automatic() |
                          commonInterface.CustomToken())) == 0)
        fee = (msg.value * 5) / 100;

      // Move fee, if any, into ImmutableSoft bank account
      if (fee > 0)
        entityInterface.entityPay{value: fee }(0);

      // Transfer the ETH payment to the registered bank
      entityInterface.entityPay{value: msg.value - TransferSurcharge[tokenId] - fee}
               (entityInterface.entityAddressToIndex(licenseOwner));
    }

    // Otherwise an unregistered resale has a 5% fee
    else
    {
      fee = (msg.value * 5) / 100;

      // Transfer fee to ImmutableSoft
      entityInterface.entityPay{value: fee }(0);

      // Transfer ETH funds minus the fee if any
      payableOwner.transfer(msg.value - TransferSurcharge[tokenId] - fee);
    }
  }

  /// @notice Query activate token offer price
  /// @param tokenId The activate token identifier
  /// @return The price of the token if for sale
  function activateTokenIdToOfferPrice(uint256 tokenId)
    external view returns (uint256)
  {
    return TokenIdToOfferPrice[tokenId];
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

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later

// OpenZepellin upgradable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

/*
// OpenZepellin standard contracts
//import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
*/

import "./StringCommon.sol";
import "./ImmutableEntity.sol";
import "./ImmutableProduct.sol";

/// @title The Immutable Product - authentic product distribution
/// @author Sean Lawless for ImmutableSoft Inc.
/// @notice Token transfers use the ImmuteToken only
/// @dev Ecosystem is split in three, Entities, Releases and Licenses
contract CreatorToken is Initializable, OwnableUpgradeable,
                         ERC721EnumerableUpgradeable,
                         ERC721BurnableUpgradeable,
                         ERC721URIStorageUpgradeable
/*
contract CreatorToken is  Ownable,
                          ERC721Enumerable,
                          ERC721Burnable,
                          ERC721URIStorage
*/
{
  struct Release
  {
    uint256 hash;
    uint256 version; // version, architecture, languages
    uint256 parent; // Ricardian parent of this file (SHA256 hash)
  }

  mapping(uint256 => Release) private Releases;
  mapping (uint256 => uint256) private HashToRelease;
  mapping (uint256 => mapping (uint256 => uint256)) private ReleasesNumberOf;
  uint256 private AnonProductID;
  uint256 public AnonFee;

  // External contract interfaces
  StringCommon private commonInterface;
  ImmutableEntity private entityInterface;
  ImmutableProduct private productInterface;

  ///////////////////////////////////////////////////////////
  /// PRODUCT RELEASE
  ///////////////////////////////////////////////////////////

  /// @notice Initialize the ImmutableProduct smart contract
  ///   Called during first deployment only (not on upgrade) as
  ///   this is an OpenZepellin upgradable contract
  /// @param commonAddr The StringCommon contract address
  /// @param entityAddr The ImmutableEntity token contract address
  /// @param productAddr The ImmutableProduct token contract address
  function initialize(address commonAddr, address entityAddr,
                      address productAddr) public initializer
  {
    __Ownable_init();
    __ERC721_init("Activate", "ACT");
    __ERC721Enumerable_init();
    __ERC721Burnable_init();
    __ERC721URIStorage_init();
/*
  // OpenZepellin standard contracts
  constructor(address commonAddr, address entityAddr, address productAddr)
                                           Ownable()
                                           ERC721("Creator", "CRT")
                                           ERC721URIStorage()
                                           ERC721Enumerable()
  {
*/
    commonInterface = StringCommon(commonAddr);
    entityInterface = ImmutableEntity(entityAddr);
    productInterface = ImmutableProduct(productAddr);
    AnonFee = 1000000000000000000; //(1 MATIC ~ $2)
  }

  /// @notice Retrieve fee to upgrade.
  /// Administrator only.
  /// @param newFee the new anonymous use fee
  function creatorAnonFee(uint256 newFee)
    external onlyOwner
  {
    AnonFee = newFee;
  }

  /// @notice Anonymous file security (PoE without credentials)
  /// Entity and Product must exist.
  /// @param newHash The file SHA256 CRC hash
  /// @param newFileUri URI/name/reference of the file
  /// @param version The version and flags of the file
  function anonFile(uint256 newHash, string memory newFileUri, uint256 version)
    external payable
  {
    // Create the file PoE/release or revert if any error
    require(newHash != 0, "Hash parameter is zero");
    require(bytes(newFileUri).length != 0, "URI/name cannot be empty");
    require(msg.value >= AnonFee, commonInterface.EntityIsZero());

    // Serialize the entity (0), product and release IDs into unique tokenID
    uint256 tokenId = ((0 << commonInterface.EntityIdOffset()) & commonInterface.EntityIdMask()) |
                ((AnonProductID << commonInterface.ProductIdOffset()) & commonInterface.ProductIdMask()) |
                (((++ReleasesNumberOf[0][0])
                  << commonInterface.ReleaseIdOffset()) & commonInterface.ReleaseIdMask());

    require(HashToRelease[newHash] == 0, "Hash already exists");
    require(Releases[tokenId].hash == 0, "token already exists");

    // Transfer ETH funds to ImmutableSoft
    entityInterface.entityPay{value: msg.value }(0);

    // Populate the release
    Releases[tokenId].hash = newHash;
    Releases[tokenId].version = version |
                           (block.timestamp << 160); // add timestamp

    // Populate the reverse lookup (hash to token id lookup)
    HashToRelease[newHash] = tokenId;

    // Mint the new creator token
    _mint(msg.sender, tokenId);
    _setTokenURI(tokenId, newFileUri);

    // Increment release counter and increment product ID on roll over
    if (ReleasesNumberOf[0][0] >= 0xFFFFFFFF)
    {
      AnonProductID++;
      ReleasesNumberOf[0][0] = 0;
    }
  }

  /// @notice Create new release(s) of an existing product.
  /// Entity and Product must exist.
  /// @param productIndex Array of product IDs of new release(s)
  /// @param newVersion Array of version, architecture and languages
  /// @param newHash Array of file SHA256 CRC hash
  /// @param newFileUri Array of valid URIs of the release binary
  /// @param parentHash Array of SHA256 CRC hash of parent contract
  function creatorReleases(uint256[] memory productIndex, uint256[] memory newVersion,
                           uint256[] memory newHash, string[] memory newFileUri,
                           uint256[] calldata parentHash)
    external
  {
    uint entityIndex = entityInterface.entityAddressToIndex(msg.sender);
    uint256 entityStatus = entityInterface.entityAddressStatus(msg.sender);

    // Only a validated entity can create a release
    require(entityStatus > 0, commonInterface.EntityNotValidated());

    require((productIndex.length == newVersion.length) &&
            (newVersion.length == newHash.length) &&
            (newHash.length == newFileUri.length) &&
            (newFileUri.length == parentHash.length),
            "Parameter arrays must be same size");

    // Create each release or revert if any error
    for (uint i = 0; i < productIndex.length; ++i)
    {
      uint256 version = newVersion[i] | (block.timestamp << 160); // add timestamp

      require(newHash[i] != 0, "Hash parameter is zero");
      require(bytes(newFileUri[i]).length != 0, "URI cannot be empty");
      require(productInterface.productNumberOf(entityIndex) > productIndex[i],
              commonInterface.ProductNotFound());

      // Serialize the entity, product and release IDs into unique tokenID
      uint256 tokenId = ((entityIndex << commonInterface.EntityIdOffset()) & commonInterface.EntityIdMask()) |
                ((productIndex[i] << commonInterface.ProductIdOffset()) & commonInterface.ProductIdMask()) |
                (((ReleasesNumberOf[entityIndex][productIndex[i]])
                  << commonInterface.ReleaseIdOffset()) & commonInterface.ReleaseIdMask());

      require(HashToRelease[newHash[i]] == 0, "Hash already exists");
      require(Releases[tokenId].hash == 0, "token already exists");

      // If a Ricardian leaf ensure the leaf is valid
      if (parentHash[i] > 0)
      {
        uint256 parentId = HashToRelease[parentHash[i]];
        require(parentId > 0, "Parent token not found");

        require(entityIndex ==
          ((parentId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset()),
           "Parent entity no match");
        require(productIndex[i] ==
          ((parentId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset()),
          "Parent product no match");
        require((newVersion[i] > Releases[parentId].version & 0xFFFFFFFFFFFFFFFF),
          "Parent version must be less");
      }

      // Populate the release
      Releases[tokenId].hash = newHash[i];
      Releases[tokenId].version = version;
      if (parentHash[i] > 0)
        Releases[tokenId].parent = parentHash[i];

      // Populate the reverse lookup (hash to token id lookup)
      HashToRelease[newHash[i]] = tokenId;

      // Mint the new creator token
      _mint(msg.sender, tokenId);
      _setTokenURI(tokenId, newFileUri[i]);

      ++ReleasesNumberOf[entityIndex][productIndex[i]];
    }
  }

  /// @notice Return version, URI and hash of existing product release.
  /// Entity, Product and Release must exist.
  /// @param entityIndex The index of the entity owner of product
  /// @param productIndex The product ID of the new release
  /// @param releaseIndex The index of the product release
  /// @return flags , URI, fileHash and parentHash are return values.\
  ///         **flags** The version, architecture and language(s)\
  ///         **URI** The URI to the product release file\
  ///         **fileHash** The SHA256 checksum hash of the file\
  ///         **parentHash** The SHA256 checksum hash of the parent file
  function creatorReleaseDetails(uint256 entityIndex,
                            uint256 productIndex, uint256 releaseIndex)
    external view returns (uint256 flags, string memory URI,
                           uint256 fileHash, uint256 parentHash)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());
    require(productInterface.productNumberOf(entityIndex) > productIndex,
            commonInterface.ProductNotFound());
    require(ReleasesNumberOf[entityIndex][productIndex] > releaseIndex,
            "Release not found");

    // Serialize the entity, product and release IDs into unique tokenID
    uint256 tokenId = ((entityIndex << commonInterface.EntityIdOffset()) & commonInterface.EntityIdMask()) |
              ((productIndex << commonInterface.ProductIdOffset()) & commonInterface.ProductIdMask()) |
              (((releaseIndex) << commonInterface.ReleaseIdOffset()) & commonInterface.ReleaseIdMask());

    // Return the version, URI and hash's for this product
    return (Releases[tokenId].version, tokenURI(tokenId),
            Releases[tokenId].hash, Releases[tokenId].parent);
  }

  /// @notice Reverse lookup, return entity, product, URI of product release.
  /// Entity, Product and Release must exist.
  /// @param fileHash The index of the product release
  /// @return entity , product, release, version, URI and parent are return values.\
  ///         **entity** The index of the entity owner of product\
  ///         **product** The product ID of the release\
  ///         **release** The release ID of the release\
  ///         **version** The version, architecture and language(s)\
  ///         **URI** The URI to the product release file
  ///         **parent** The SHA256 checksum of ricarding parent file
  function creatorReleaseHashDetails(uint256 fileHash)
    public view returns (uint256 entity, uint256 product,
                         uint256 release, uint256 version,
                         string memory URI, uint256 parent)
  {
    uint256 tokenId = HashToRelease[fileHash];

    // Return token information if found
    if (tokenId != 0)
    {
      uint256 entityIndex = ((tokenId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset());
      uint256 productIndex = ((tokenId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset());
      uint256 releaseIndex = ((tokenId & commonInterface.ReleaseIdMask()) >> commonInterface.ReleaseIdOffset());

      // Return entity, product, version, URI and parent for this hash
      return (entityIndex, productIndex, releaseIndex,
              Releases[tokenId].version, tokenURI(tokenId),
              Releases[tokenId].parent);
    }
    else
      return (0, 0, 0, 0, "", 0);
  }

  struct ReleaseInformation
  {
    uint256 index;
    uint256 product;
    uint256 release;
    uint256 version; // version, architecture, languages
    string fileURI;
    uint256 parent; // Ricardian parent of this file
  }

  /// @notice Return depth of ricardian parent relative to child
  ///   The childHash and parentHash must exist as same product
  /// @param childHash SHA256 checksum hash of the child file
  /// @param parentHash SHA256 checksum hash of the parent file
  /// @return the child document depth compared to parent (> 0 is parent)
  function creatorParentOf(uint256 childHash, uint256 parentHash)
    public view returns (uint)
  {

    ReleaseInformation[2] memory childAndParent;
    uint256 currentRicardianHash = childHash;

    ( childAndParent[0].index, childAndParent[0].product, childAndParent[0].release,
      childAndParent[0].version, childAndParent[0].fileURI,
      childAndParent[0].parent ) = creatorReleaseHashDetails(childHash);
    ( childAndParent[1].index, childAndParent[1].product, childAndParent[1].release,
      childAndParent[1].version, childAndParent[1].fileURI,
      childAndParent[1].parent ) = creatorReleaseHashDetails(parentHash);

    // Recursively search up the tree to find the parent
    for (uint i = 1; currentRicardianHash != 0; ++i)
    {
      require((childAndParent[0].index != 0), commonInterface.EntityIsZero());
      require((childAndParent[0].index == childAndParent[1].index), "Entity mismatch");
      require((childAndParent[0].product == childAndParent[1].product), "Product mismatch");

      currentRicardianHash = childAndParent[0].parent;

      // If we found the parent return the ricardian depth
      if (currentRicardianHash == parentHash)
        return i;

      ( childAndParent[0].index, childAndParent[0].product, childAndParent[0].release,
        childAndParent[0].version, childAndParent[0].fileURI,
        childAndParent[0].parent ) = creatorReleaseHashDetails(childAndParent[0].parent);
    }

    // Return not found
    return 0;
  }

  /// @notice Determine if an address owns a client token of parent
  ///   The clientAddress and parentHash must be valid
  /// @param clientAddress Ethereum address of client
  /// @param parentHash SHA256 checksum hash of the parent file
  /// @return The child Ricardian depth to parent (> 0 has child)
  function creatorHasChildOf(address clientAddress, uint256 parentHash)
    public view returns (uint)
  {
    ReleaseInformation memory parentInfo;
    uint256 tokenId;
    uint depth;

    ( parentInfo.index, parentInfo.product, parentInfo.release,
      parentInfo.version, parentInfo.fileURI,
      parentInfo.parent ) = creatorReleaseHashDetails(parentHash);
    require((parentInfo.index != 0), commonInterface.EntityIsZero());
    require((clientAddress != address(0)), "Address is zero");


    // Search through the creator tokens of the client
    for (uint i = 0; i < balanceOf(clientAddress); ++i)
    {
      // Retrieve the token id of this index
      tokenId = tokenOfOwnerByIndex(clientAddress, i);

      // Ensure same entity and product ids before checking parent
      if ((((tokenId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset())
           == parentInfo.index) &&
          (((tokenId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset())
              == parentInfo.product))
      {
        // If we found the parent return the Ricardian depth
        depth = creatorParentOf(Releases[tokenId].hash, parentHash);
        if (depth > 0)
          return depth;
      }
    }

    // Return not found
    return 0;
  }

  /// @notice Retrieve details for all product releases
  /// Status of empty arrays if none found.
  /// @param entityIndex The index of the entity owner of product
  /// @param productIndex The product ID of the new release
  /// @return versions , URIs, hashes, parents are array return values.\
  ///         **versions** Array of version, architecture and language(s)\
  ///         **URIs** Array of URI to the product release files\
  ///         **hashes** Array of SHA256 checksum hash of the files\
  ///         **parents** Aarray of SHA256 checksum hash of the parent files
  function creatorAllReleaseDetails(uint256 entityIndex, uint256 productIndex)
    external view returns (uint256[] memory versions, string[] memory URIs,
                           uint256[] memory hashes, uint256[] memory parents)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());
    require(productInterface.productNumberOf(entityIndex) > productIndex,
            commonInterface.ProductNotFound());

    uint256[] memory resultVersion = new uint256[](ReleasesNumberOf[entityIndex][productIndex]);
    string[] memory resultURI = new string[](ReleasesNumberOf[entityIndex][productIndex]);
    uint256[] memory resultHash = new uint256[](ReleasesNumberOf[entityIndex][productIndex]);
    uint256[] memory resultParent = new uint256[](ReleasesNumberOf[entityIndex][productIndex]);
    uint256 tokenId;

    // Build result arrays for all release information of a product
    for (uint i = 0; i < ReleasesNumberOf[entityIndex][productIndex]; ++i)
    {
      // Serialize the entity, product and release IDs into unique tokenID
      tokenId = ((entityIndex << commonInterface.EntityIdOffset()) & commonInterface.EntityIdMask()) |
              ((productIndex << commonInterface.ProductIdOffset()) & commonInterface.ProductIdMask()) |
              ((i << commonInterface.ReleaseIdOffset()) & commonInterface.ReleaseIdMask());
      resultVersion[i] = Releases[tokenId].version;
      resultURI[i] = tokenURI(tokenId);
      resultHash[i] = Releases[tokenId].hash;
      resultParent[i] = Releases[tokenId].parent;
    }

    return (resultVersion, resultURI, resultHash, resultParent);
  }

  /// @notice Return the number of releases of a product
  /// Entity must exist.
  /// @param entityIndex The index of the entity
  /// @return the current number of products for the entity
  function creatorReleasesNumberOf(uint256 entityIndex, uint256 productIndex)
    external view returns (uint256)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());

    // Return the number of releases for this entity/product
    if (productInterface.productNumberOf(entityIndex) >= productIndex)
      return ReleasesNumberOf[entityIndex][productIndex];
    else
      return 0;
  }

  // Pass through the overrides to inherited super class
  //   To add per-transfer fee's/logic in the future do so here
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal override(ERC721Upgradeable,
                        ERC721EnumerableUpgradeable)
  {

    // Only token owner transfer or master contract exchange
    //   Skip this check when first minting
    if (from != address(0))
      require((msg.sender == ownerOf(tokenId)) ||
              (Releases[tokenId].parent == 0), "Not owner/leaf");

    super._beforeTokenTransfer(from, to, tokenId);
  }


  /// @notice Look up the release URI from the token Id
  /// @param tokenId The unique token identifier
  /// @return the file name and/or URI secured by this token
  function tokenURI(uint256 tokenId) public view virtual override
    (ERC721Upgradeable, ERC721URIStorageUpgradeable)
      returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  /// @notice Burn a product activation license.
  /// Not public, called internally. msg.sender must be the token owner.
  /// @param tokenId The tokenId to burn
  function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable,
                                                       ERC721URIStorageUpgradeable)
  {
    super.burn(tokenId);
  }

  /// @notice Return the type of supported ERC interfaces
  /// @param interfaceId The interface desired
  /// @return TRUE (1) if supported, FALSE (0) otherwise
  function supportsInterface(bytes4 interfaceId) public view virtual
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
      returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

pragma solidity >=0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later

import "./StringCommon.sol";
import "./ImmutableEntity.sol";
import "./CreatorToken.sol";
import "./ProductActivate.sol";

// OpenZepellin upgradable contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/*
// OpenZepellin standard contracts
//import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
*/

/*
  The ActivateToken unique token id is a conglomeration of the entity, product,
  expiration, identifier and license value. The licenseValue portion is 128 bits
  and is product specific, allowing millions of uniquely identifiable sub-products

    uint256 tokenId = entityIndex | (productIndex << 32) | (licenseExpiration << 64) |
                      (activationIdFlags << 96) | (licenseValue << 128);
*/

// OpenZepellin upgradable contracts
contract ActivateToken is Initializable, OwnableUpgradeable,
                          ERC721EnumerableUpgradeable,
                          ERC721BurnableUpgradeable
/*
contract ActivateToken is Ownable,
                          ERC721Enumerable,
                          ERC721Burnable
*/
{
  // Mapping to and from token id and activation id
  mapping (uint256 => uint256) private ActivateIdToTokenId;
  mapping (uint256 => uint256) private TokenIdToActivateId;

  // Mapping the number of activations (used for uniqueness)
  mapping (uint64 => uint64) private NumberOfActivations;

  // Mapping any Ricardian contract requirements
  mapping (uint256 => uint256) private TokenIdToRicardianParent;

  ProductActivate private activateInterface;
  CreatorToken private creatorInterface;
  ImmutableEntity private entityInterface;
  StringCommon private commonInterface;

  /// @notice Initialize the activate token smart contract
  ///   Called during first deployment only (not on upgrade) as
  ///   this is an OpenZepellin upgradable contract
  /// @param commonContractAddr The StringCommon contract address
  /// @param entityContractAddr The ImmutableEntity token contract address
  function initialize(address commonContractAddr, address entityContractAddr)
    public initializer
  {
    __Ownable_init();
    __ERC721_init("Activate", "ACT");
    __ERC721Enumerable_init();
    __ERC721Burnable_init();
/*
  // OpenZepellin standard contracts
  constructor(address commonContractAddr, address entityContractAddr)
                                           Ownable()
                                           ERC721("Activate", "ACT")
                                           ERC721Enumerable()
  {
*/
    // Initialize the contract interfaces
    commonInterface = StringCommon(commonContractAddr);
    entityInterface = ImmutableEntity(entityContractAddr);
  }

  /// @notice Restrict the token to the activate contract
  ///   Called once after deployment to initialize Ecosystem.
  ///   msg.sender must be contract owner
  /// @param activateAddress The ProductActivate contract address
  /// @param creatorAddress The Creator token contract address
  function restrictToken(address activateAddress, address creatorAddress)
    public onlyOwner
  {
    activateInterface = ProductActivate(activateAddress);  
    creatorInterface = CreatorToken(creatorAddress);
  }

  /// @notice Burn a product activation license.
  /// Not public, called internally. msg.sender must be the token owner.
  /// @param tokenId The tokenId to burn
  function burn(uint256 tokenId) public override(ERC721BurnableUpgradeable)
  {
    uint256 activationId = TokenIdToActivateId[tokenId];

    ActivateIdToTokenId[activationId] = 0;
    TokenIdToActivateId[tokenId] = 0;

    // If called from restricted address skip approval check
    if (msg.sender == address(activateInterface))
      super._burn(tokenId);

    // Otherwise ensure caller is approved for the token
    else
      super.burn(tokenId);
  }

  /// @notice Create a product activation license.
  /// Public but internal. msg.sender must be product activate contract
  /// @param entityIndex The local entity index of the license
  /// @param productIndex The specific ID of the product
  /// @param licenseHash The external license activation hash
  /// @param licenseValue The activation value and flags (192 bits)
  /// @param ricardianParent The Ricardian contract parent (if required)
  /// @return tokenId The resulting new unique token identifier
  function mint(address sender, uint256 entityIndex, uint256 productIndex,
                uint256 licenseHash, uint256 licenseValue,
                uint256 ricardianParent)
    public returns (uint256)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());

    uint256 activationId =
      ++NumberOfActivations[(uint64)(entityIndex | (productIndex << 32))];

    uint256 tokenId = ((entityIndex << commonInterface.EntityIdOffset()) & commonInterface.EntityIdMask()) |
                      ((productIndex << commonInterface.ProductIdOffset()) & commonInterface.ProductIdMask()) |
                      ((activationId << commonInterface.UniqueIdOffset()) & commonInterface.UniqueIdMask()) |
                      (licenseValue & (commonInterface.FlagsMask() | commonInterface.ExpirationMask() | commonInterface.ValueMask()));

    // Require the product activate contract be the sender
    require(msg.sender == address(activateInterface), "sender not link");

    // If no expiration to the activation, use those bits for more randomness
    if ((licenseValue & commonInterface.ExpirationFlag() == 0) && (activationId > 0xFFFF))
      tokenId |= ((activationId >> 16) << commonInterface.ExpirationOffset()) & commonInterface.ExpirationMask();

// Do NOT uncomment this, it can potentially infinite loop
//   But the idea is valid, leaving until a better solution
/*
    // If not unique, fudge the values until unique
    while (TokenIdToActivateId[tokenId] != 0)
    {
      // Bump up the activation id
      activationId =
        ++NumberOfActivations[entityIndex | (productIndex << 32)];

      tokenId = ((entityIndex << commonInterface.EntityIdOffset()) & commonInterface.EntityIdMask()) |
                ((productIndex << commonInterface.ProductIdOffset()) & commonInterface.ProductIdMask()) |
                ((activationId << commonInterface.UniqueIdOffset()) & commonInterface.UniqueIdMask()) |
                (licenseValue & (commonInterface.FlagsMask() | commonInterface.ExpirationMask() | commonInterface.ValueMask()));
*/
/*
      // If still not unique, decrease the expiration time slightly
      // Must decrease since zero is unlimited time
      if (TokenIdToActivateId[tokenId] != 0)
      {
        uint256 theDuration = ((licenseValue & ImmutableConstants.ExpirationMask) >> ImmutableConstants.ExpirationOffset);
        theDuration -= block.timestamp % 0xFF;

        // Update tokenId to include new expiration
        //  Clear the expiration
        licenseValue &= ~ImmutableConstants.ExpirationMask;
        licenseValue |= (theDuration << ImmutableConstants.ExpirationOffset) & ImmutableConstants.ExpirationMask;

        tokenId = ((entityIndex << ImmutableConstants.EntityIdOffset) & ImmutableConstants.EntityIdMask) |
                  ((productIndex << ImmutableConstants.ProductIdOffset) & ImmutableConstants.ProductIdMask) |
                  ((activationId << ImmutableConstants.UniqueIdOffset) & ImmutableConstants.UniqueIdMask) |
                  (licenseValue & (ImmutableConstants.FlagsMask | ImmutableConstants.ExpirationMask | ImmutableConstants.ValueMask));
      }
*/
//    }


    // Require a unique tokenId
    require(TokenIdToActivateId[tokenId] == 0, commonInterface.TokenNotUnique());
    require(ActivateIdToTokenId[licenseHash] == 0, commonInterface.TokenNotUnique());

    // Mint the new activate token
    _mint(sender, tokenId);

    // Assign mappings for id-to-hash and hash-to-id
    TokenIdToActivateId[tokenId] = licenseHash;
    if (licenseHash > 0)
      ActivateIdToTokenId[licenseHash] = tokenId;
    if (ricardianParent > 0)
      TokenIdToRicardianParent[tokenId] = ricardianParent;
    return tokenId;
  }

  ///////////////////////////////////////////////////////////
  /// PRODUCT ACTIVATE LICENSE
  ///////////////////////////////////////////////////////////

  /// @notice Change owner for all activate tokens (activations)
  /// Not public, called internally. msg.sender is the license owner.
  /// @param newOwner The new owner to receive transfer of tokens
  function activateOwner(address newOwner)
      external
  {
    // Retrieve the balance of activation tokens
    uint256 numActivations = balanceOf(msg.sender);

    // Safely transfer each token (index 0) to the new owner
    for (uint i = 0; i < numActivations; ++i)
    {
      // Always transfer token index zero, to ensure the same
      // order/index for the new address
      safeTransferFrom(msg.sender, newOwner, tokenOfOwnerByIndex(msg.sender, 0));
    }      
  }

  /// @notice Change activation identifier for an activate token
  ///   Caller must be the ProductActivate contract.
  /// @param tokenId The token identifier to move
  /// @param newHash The new activation hash/identifier
  /// @param oldHash The previous activation hash/identifier
  function activateTokenMoveHash(uint256 tokenId, uint256 newHash,
                                 uint256 oldHash)
    external
  {
    require(address(activateInterface) != address(0));
    require(msg.sender == address(activateInterface));

    // Clear old hash if present
    if (oldHash > 0)
      ActivateIdToTokenId[oldHash] = 0;

    // Clear token-to-activate lookup
    if (TokenIdToActivateId[tokenId] > 0)
      ActivateIdToTokenId[TokenIdToActivateId[tokenId]] = 0;

    // Update tokenId references and new activation on blockchain
    ActivateIdToTokenId[newHash] = tokenId;
    TokenIdToActivateId[tokenId] = newHash;
  }

  /// All activate functions below are view type (read only)

  /// @notice Find token identifier associated with activation hash
  /// @param licenseHash the external unique identifier
  /// @return the tokenId value
  function activateIdToTokenId(uint256 licenseHash)
    external view returns (uint256)
  {
    return ActivateIdToTokenId[licenseHash];
  }

  /// @notice Find activation hash associated with token identifier
  /// @param tokenId is the unique token identifier
  /// @return the license hash/unique activation identifier
  function tokenIdToActivateId(uint256 tokenId)
    external view returns (uint256)
  {
    return TokenIdToActivateId[tokenId];
  }
  
  /// @notice Find end user activation value and expiration for product
  /// Entity and product must be valid.
  /// @param entityIndex The entity the product license is for
  /// @param productIndex The specific ID of the product
  /// @param licenseHash the external unique identifier to activate
  /// @return value (with flags) and price of the activation.\
  ///         **value** The activation value (flags, expiration, value)\
  ///         **price** The price in tokens if offered for resale
  function activateStatus(uint256 entityIndex, uint256 productIndex,
                          uint256 licenseHash)
    external view returns (uint256 value, uint256 price)
  {
    require(entityIndex > 0, commonInterface.EntityIsZero());
    uint256 tokenId = ActivateIdToTokenId[licenseHash];

    if (tokenId > 0)
    {
      require(entityIndex == (tokenId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset(),
              "EntityId does not match");
      require(productIndex == (tokenId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset(),
              "ProductId does not match");
    }

    // Return license flags, value. expiration and price
    return (
             (tokenId & (commonInterface.FlagsMask() |      //flags
                         commonInterface.ExpirationMask() | //expiration
                         commonInterface.ValueMask())),     //value
                         activateInterface.activateTokenIdToOfferPrice(tokenId) //price
           );
  }

  /// @notice Find all license activation details for an address
  /// @param entityAddress The address that owns the activations
  /// @return entities , products, hashes, values and prices as arrays.\
  ///         **entities** Array of entity ids of product\
  ///         **products** Array of product ids of product\
  ///         **hashes** Array of activation identifiers\
  ///         **values** Array of token values\
  ///         **prices** Array of price in tokens if for resale
  function activateAllDetailsForAddress(address entityAddress)
    public view returns (uint256[] memory entities, uint256[] memory products,
                         uint256[] memory hashes, uint256[] memory values,
                         uint256[] memory prices)
  {
    // Allocate result array based on the number of activate tokens
    //   Using tokenId for result length since no more stack space
    uint256 tokenId = balanceOf(entityAddress);
    uint256[] memory resultEntityId = new uint256[](tokenId);
    uint256[] memory resultProductId = new uint256[](tokenId);
    uint256[] memory resultHash = new uint256[](tokenId);
    uint256[] memory resultValue = new uint256[](tokenId);
    uint256[] memory resultPrice = new uint256[](tokenId);

    // Build result arrays for all activations of an Entity
    for (uint i = 0; i < balanceOf(entityAddress); ++i)
    {
      // Retrieve the token id of this index
      tokenId = tokenOfOwnerByIndex(entityAddress, i);

      // Return activate information from tokenId and mappings
      resultEntityId[i] = (tokenId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset(); // entityID
      resultProductId[i] = (tokenId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset(); //productID,
      resultValue[i] = tokenId & (commonInterface.FlagsMask() |      //flags
                                  commonInterface.ExpirationMask() | //expiration
                                  commonInterface.ValueMask());      //value
      resultHash[i] = TokenIdToActivateId[tokenId]; // activation hash
      resultPrice[i] = activateInterface.activateTokenIdToOfferPrice(tokenId); // offer price
    }

    return (resultEntityId, resultProductId, resultHash,
            resultValue, resultPrice);
  }

  /// @notice Find all license activation details for an entity
  /// Entity must be valid.
  /// @param entityIndex The entity to return activations for
  /// @return entities , products, hashes, values and prices as arrays.\
  ///         **entities** Array of entity ids of product\
  ///         **products** Array of product ids of product\
  ///         **hashes** Array of activation identifiers\
  ///         **values** Array of token values (flags, expiration)\
  ///         **prices** Array of price in tokens if for resale
  function activateAllDetails(uint256 entityIndex)
    external view returns (uint256[] memory entities, uint256[] memory products,
                           uint256[] memory hashes, uint256[] memory values,
                           uint256[] memory prices)
  {
    // Convert entityId to address and call details-for-address
    return activateAllDetailsForAddress(
                        entityInterface.entityIndexToAddress(entityIndex));
  }

  /// @notice Return all license activations for sale in the ecosystem
  /// When this exceeds available return size index will be added
  /// @return entities , products, hashes, values and prices as arrays.\
  ///         **entities** Array of entity ids of product\
  ///         **products** Array of product ids of product\
  ///         **hashes** Array of activation identifiers\
  ///         **values** Array of token values (flags, expiration)\
  ///         **prices** Array of price in tokens if for resale
  function activateAllForSaleTokenDetails()
    external view returns (uint256[] memory entities, uint256[] memory products,
                           uint256[] memory hashes, uint256[] memory values,
                           uint256[] memory prices)
  {
    // Allocate result array based on the number of activate tokens
    //   Using tokenId for result length since no more stack space
    uint256 tokenId;
    uint i = 0;
    uint j = 0;


    // First iterate and find how many are for sale
    for (i = 0; i < totalSupply(); ++i)
    {
      // Return the number of activations (number of activate tokens)
      tokenId = tokenByIndex(i);

      if (activateInterface.activateTokenIdToOfferPrice(tokenId) > 0)
        j++;
    }

    // Allocate resulting arrays based on size
    uint256[] memory resultEntityId = new uint256[](j);
    uint256[] memory resultProductId = new uint256[](j);
    uint256[] memory resultHash = new uint256[](j);
    uint256[] memory resultValue = new uint256[](j);
    uint256[] memory resultPrice = new uint256[](j);

    // Build result arrays for all activations of an Entity
    if (j > 0)
    {
      i = 0;
      for (j = 0; i < totalSupply(); ++i)
      {
        // Return the number of activations (number of activate tokens)
        tokenId = tokenByIndex(i);

        if (activateInterface.activateTokenIdToOfferPrice(tokenId) > 0)
        {
          // Return activate information from tokenId and mappings
          resultPrice[j] = activateInterface.activateTokenIdToOfferPrice(tokenId); // offer price
          resultEntityId[j] = (tokenId & commonInterface.EntityIdMask()) >> commonInterface.EntityIdOffset(); // entityID
          resultProductId[j] = (tokenId & commonInterface.ProductIdMask()) >> commonInterface.ProductIdOffset(); //productID,
          resultValue[j] = tokenId & (commonInterface.FlagsMask() |      //flags
                                      commonInterface.ExpirationMask() | //expiration
                                      commonInterface.ValueMask());      //value
          resultHash[j] = TokenIdToActivateId[tokenId]; // activation hash
          j++;
        }
      }
    }

    return (resultEntityId, resultProductId, resultHash,
            resultValue, resultPrice);
  }

  /// @notice Perform validity check before transfer of token allowed.
  /// Called internally before any token transfer and used to enforce
  /// resale rights and Ricardian contract agreement requirements,
  /// even when using third party exchanges.
  /// @param from The token origin address
  /// @param to The token destination address
  /// @param tokenId The token intended for transfer
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
  {

    // Check flags/validity only after the first mint
    if (from != address(0))
    {
      // Only token owner may transfer without resale rights
      require((msg.sender == ownerOf(tokenId)) ||
              ((tokenId & commonInterface.NoResaleFlag()) == 0), "Not owner/resalable");

      // Check any required Ricardian contracts
      if ((msg.sender != ownerOf(tokenId)) &&
          (TokenIdToRicardianParent[tokenId] > 0) &&
          (address(creatorInterface) != address(0)))
      {
        uint hasChild = creatorInterface.creatorHasChildOf(to, TokenIdToRicardianParent[tokenId]);
        require(hasChild > 0, "Ricardian child agreement not found.");
      }
    }

    super._beforeTokenTransfer(from, to, tokenId);
  }

  /// @notice Return the type of supported ERC interfaces
  /// @param interfaceId The interface desired
  /// @return TRUE (1) if supported, FALSE (0) otherwise
  function supportsInterface(bytes4 interfaceId)
      public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal initializer {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721Upgradeable.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
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
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Burnable_init_unchained();
    }

    function __ERC721Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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
    uint256[44] private __gap;
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