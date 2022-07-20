pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../libraries/NftStorage.sol";
import "../../libraries/PackStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/sales/LibSales.sol";

/// @title Facet for functions related to all sales types.
/// @dev See also LibSales
contract SalesCommonFacet is ReentrancyGuard {
  enum SaleRole { PRIMARY_CREATOR, COLLAB, RESELLER, GALLERY }

  event SalesGlobalsSet(
    uint16 mintPortionProtocol,
    uint16 resalePortionProtocol,
    uint16 mintPortionGallery,
    uint16 resalePortionGallery
  );

  event MaxPriceSet(uint256 maxPrice);
  event MinMintPortionSioSet(uint16 minMintPortionSio);
  event MaxMintPortionSioSet(uint16 maxMintPortionSio);
  event MinResalePortionSioSet(uint16 minResalePortionSio);
  event MaxResalePortionSioSet(uint16 maxResalePortionSio);
  event MinResalePortionCreatorSet(uint16 minResalePortionCreator);
  event MaxResalePortionCreatorSet(uint16 maxResalePortionCreator);
  event MinCombinedResalePortionsSioCreatorSet(uint16 minCombinedResalePortionsSioCreator);
  event MaxCombinedResalePortionsSioCreator(uint16 maxCombinedResalePortionsSioCreator);
  event MinMinHigherBidSet(uint16 minMinHigherBid);
  event MaxMinHigherBidSet(uint16 maxMinHigherBid);
  event MinExtendBidTimeSet(int40 minExtendBidTime);
  event MaxExtendBidTimeSet(int40 maxExtendBidTime);
  event MinExtendSpanSet(uint40 minExtendSpan);
  event MaxExtendSpanSet(uint40 maxExtendSpan);
  event HopAmountOutMinPortionSet(uint16 hopAmountOutMinPortion);
  event HopDeadlineDiffSet(uint40 hopDeadlineDiff);

  event SalesLimitsSet(SalesLimitsParams params);

  event SharesClaimed(
    address recipient,
    uint256[] nftSaleIds,
    SaleRole[] saleRoles,
    uint8[] collabIdxs,
    uint256 total
  );
  event SioSharesClaimed(uint32 sioId, uint256[] nftSaleIds, uint256 bonderFee, uint256 total);
  event ProtocolSharesClaimed(uint256[] nftSaleIds, uint256 total);

  error InvalidSaleRole(SaleRole saleRole);
  error UnsupportedTokenClass(uint256 tokenId);
  error UnsupportedChainId(uint256 chainId);
  error AlreadyClaimed(uint256 claimIdx);
  error WrongRecipient(uint256 claimIdx);
  error Erc20TransferFailed();
  error ZeroAddressRecipient();
  error InvalidLength();
  error InvalidMinMaxExtendBidTime();
  error FacetLocked();
  error NotController();
  error NotApprovedClaimer();

  /// @param maxPrice Maximum sale price
  /// @param minMintPortionSio Minimum SIO portion for a mint
  /// @param maxMintPortionSio Maximum SIO portion for a mint
  /// @param minResalePortionSio Minimum SIO portion for a resale
  /// @param maxResalePortionSio Maximum SIO portion for a resale
  /// @param minResalePortionCreator Minimum creator portion for a resale
  /// @param maxResalePortionCreator Maximum creator portion for a resale
  /// @param minCombinedResalePortionsSioCreator Minimum combined SIO/creator portion for a resale
  /// @param maxCombinedResalePortionsSioCreator Maximum combined SIO/creator portion for a resale
  struct SalesLimitsParams {
    uint256 maxPrice;
    uint16 minMintPortionSio;
    uint16 maxMintPortionSio;
    uint16 minResalePortionSio;
    uint16 maxResalePortionSio;
    uint16 minResalePortionCreator;
    uint16 maxResalePortionCreator;
    uint16 minCombinedResalePortionsSioCreator;
    uint16 maxCombinedResalePortionsSioCreator;
    uint16 minMinHigherBid;
    uint16 maxMinHigherBid;
    int40 minExtendBidTime;
    int40 maxExtendBidTime;
    uint40 minExtendSpan;
    uint40 maxExtendSpan;
    uint16 hopAmountOutMinPortion;
    uint40 hopDeadlineDiff;
  }

  struct Portions {
    uint256 creators;
    uint256 reseller;
    uint256 gallery;
    uint256 sio;
    uint256 protocol;
  }

  struct ClaimAmounts {
    uint256 primaryCreator;
    uint256[] collabs;
    uint256 reseller;
    uint256 gallery;
    uint256[] sios;
    uint256 protocol;
  }

  modifier lockable {
    if (!LibSales.salesData().facetUnlocked) {
      revert FacetLocked();
    }
    _;
  }

  function initSalesCommonFacet(
    address salesController,
    address usdc,
    address payable hopBridgeL2,
    uint16 mintPortionProtocol,
    uint16 resalePortionProtocol,
    uint16 mintPortionGallery,
    uint16 resalePortionGallery,
    SalesLimitsParams calldata salesLimits
  ) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.SalesData storage salesData = LibSales.salesData();
    salesData.salesController = salesController;
    salesData.usdc = usdc;
    salesData.hopBridgeL2 = hopBridgeL2;
    _setSalesGlobals(mintPortionProtocol, resalePortionProtocol, mintPortionGallery, resalePortionGallery);
    _setSalesLimits(salesLimits);
    salesData.facetUnlocked = true;
  }

  function _setSalesGlobals(
    uint16 mintPortionProtocol,
    uint16 resalePortionProtocol,
    uint16 mintPortionGallery,
    uint16 resalePortionGallery
  ) private {
    LibSales.SalesData storage salesData = LibSales.salesData();
    uint32 newSalesGlobalIdx = salesData.currentSalesGlobalsIdx + 1;
    salesData.currentSalesGlobalsIdx = newSalesGlobalIdx;
    salesData.salesGlobals[newSalesGlobalIdx] = LibSales.SalesGlobals(
      mintPortionProtocol,
      resalePortionProtocol,
      mintPortionGallery,
      resalePortionGallery
    );

    emit SalesGlobalsSet(mintPortionProtocol, resalePortionProtocol, mintPortionGallery, resalePortionGallery);
  }

  /// @notice Sets global values that apply to all sales
  /// @param mintPortionProtocol the protocol's portion of each mint
  /// @param resalePortionProtocol the protocol's portion of each resale
  /// @param mintPortionGallery the gallery's portion of each mint
  /// @param resalePortionGallery the gallery's portion of each resale
  function setSalesGlobals(
    uint16 mintPortionProtocol,
    uint16 resalePortionProtocol,
    uint16 mintPortionGallery,
    uint16 resalePortionGallery
  ) external {
    LibDiamond.enforceIsContractOwner();
    _setSalesGlobals(mintPortionProtocol, resalePortionProtocol, mintPortionGallery, resalePortionGallery);
  }

  /// @notice Sets the maximum sale price
  function setMaxPrice(uint256 maxPrice) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().maxPrice = maxPrice;
    emit MaxPriceSet(maxPrice);
  }

  /// @notice Sets the minimum SIO portion for a mint
  function setMinMintPortionSio(uint16 minMintPortionSio) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().minMintPortionSio = minMintPortionSio;
    emit MinMintPortionSioSet(minMintPortionSio);
  }

  /// @notice Sets the maximum SIO portion for a mint
  function setMaxMintPortionSio(uint16 maxMintPortionSio) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().maxMintPortionSio = maxMintPortionSio;
    emit MaxMintPortionSioSet(maxMintPortionSio);
  }

  /// @notice Sets the minimum SIO portion for a resale
  function setMinResalePortionSio(uint16 minResalePortionSio) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().minResalePortionSio = minResalePortionSio;
    emit MinResalePortionSioSet(minResalePortionSio);
  }

  /// @notice Sets the maximum SIO portion for a resale
  function setMaxResalePortionSio(uint16 maxResalePortionSio) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().maxResalePortionSio = maxResalePortionSio;
    emit MaxResalePortionSioSet(maxResalePortionSio);
  }

  /// @notice Sets the minimum creator portion for a resale
  function setMinResalePortionCreator(uint16 minResalePortionCreator) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().minResalePortionCreator = minResalePortionCreator;
    emit MinResalePortionCreatorSet(minResalePortionCreator);
  }

  /// @notice Sets the maximum creator portion for a resale
  function setMaxResalePortionCreator(uint16 maxResalePortionCreator) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().maxResalePortionCreator = maxResalePortionCreator;
    emit MaxResalePortionCreatorSet(maxResalePortionCreator);
  }

  /// @notice Sets the minimum combined SIO/creator portion for a resale
  function setMinCombinedPortionsSioCreator(uint16 minCombinedPortionsSioCreator) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().minCombinedResalePortionsSioCreator = minCombinedPortionsSioCreator;
    emit MinCombinedResalePortionsSioCreatorSet(minCombinedPortionsSioCreator);
  }

  /// @notice Sets the maximum combined SIO/creator portion for a resale
  function setMaxCombinedPortionsSioCreator(uint16 maxCombinedPortionsSioCreator) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().maxCombinedResalePortionsSioCreator = maxCombinedPortionsSioCreator;
    emit MaxCombinedResalePortionsSioCreator(maxCombinedPortionsSioCreator);
  }

  function setMinMinHigherBid(uint16 minMinHigherBid) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().minMinHigherBid = minMinHigherBid;
    emit MinMinHigherBidSet(minMinHigherBid);
  }

  function setMaxMinHigherBid(uint16 maxMinHigherBid) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().maxMinHigherBid = maxMinHigherBid;
    emit MaxMinHigherBidSet(maxMinHigherBid);
  }

  function setMinExtendBidTime(int40 minExtendBidTime) external {
    LibDiamond.enforceIsContractOwner();
    if (minExtendBidTime < 0) {
      revert InvalidMinMaxExtendBidTime();
    }
    LibSales.salesData().minExtendBidTime = minExtendBidTime;
    emit MinExtendBidTimeSet(minExtendBidTime);
  }

  function setMaxExtendBidTime(int40 maxExtendBidTime) external {
    LibDiamond.enforceIsContractOwner();
    if (maxExtendBidTime < 0) {
      revert InvalidMinMaxExtendBidTime();
    }
    LibSales.salesData().maxExtendBidTime = maxExtendBidTime;
    emit MaxExtendBidTimeSet(maxExtendBidTime);
  }

  function setMinExtendSpan(uint40 minExtendSpan) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().minExtendSpan = minExtendSpan;
    emit MinExtendSpanSet(minExtendSpan);
  }

  function setMaxExtendSpan(uint40 maxExtendSpan) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().maxExtendSpan = maxExtendSpan;
    emit MaxExtendSpanSet(maxExtendSpan);
  }

  function setHopAmountOutMinPortion(uint16 hopAmountOutMinPortion) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().hopAmountOutMinPortion = hopAmountOutMinPortion;
    emit HopAmountOutMinPortionSet(hopAmountOutMinPortion);
  }

  function setHopDeadlineDiff(uint40 hopDeadlineDiff) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().hopDeadlineDiff = hopDeadlineDiff;
    emit HopDeadlineDiffSet(hopDeadlineDiff);
  }

  function _setSalesLimits(SalesLimitsParams calldata params) private {
    if (params.minExtendBidTime < 0 || params.maxExtendBidTime < 0) {
      revert InvalidMinMaxExtendBidTime();
    }

    LibSales.SalesData storage salesData = LibSales.salesData();
    salesData.maxPrice = params.maxPrice;
    salesData.minMintPortionSio = params.minMintPortionSio;
    salesData.maxMintPortionSio = params.maxMintPortionSio;
    salesData.minResalePortionSio = params.minResalePortionSio;
    salesData.maxResalePortionSio = params.maxResalePortionSio;
    salesData.minResalePortionCreator = params.minResalePortionCreator;
    salesData.maxResalePortionCreator = params.maxResalePortionCreator;
    salesData.minCombinedResalePortionsSioCreator = params.minCombinedResalePortionsSioCreator;
    salesData.maxCombinedResalePortionsSioCreator = params.maxCombinedResalePortionsSioCreator;
    salesData.minMinHigherBid = params.minMinHigherBid;
    salesData.maxMinHigherBid = params.maxMinHigherBid;
    salesData.minExtendBidTime = params.minExtendBidTime;
    salesData.maxExtendBidTime = params.maxExtendBidTime;
    salesData.minExtendSpan = params.minExtendSpan;
    salesData.maxExtendSpan = params.maxExtendSpan;
    salesData.hopAmountOutMinPortion = params.hopAmountOutMinPortion;
    salesData.hopDeadlineDiff = params.hopDeadlineDiff;

    emit SalesLimitsSet(params);
  }

  /// @notice Sets sales parameter limits
  function setSalesLimits(SalesLimitsParams calldata params) external {
    LibDiamond.enforceIsContractOwner();
    _setSalesLimits(params);
  }

  /// @notice Sets the privileged sales controller
  function setSalesController(address newController) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().salesController = newController;
  }

  /// @notice Registers a sales facet
  function registerSalesFacet(
    uint16 saleTypeId,
    bytes4 sellFunctionSelector,
    bytes4 revokeSaleFunctionSelector,
    bytes4 buyFunctionSelector,
    address facetAddress
  ) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().salesFacetRegistry[saleTypeId] = LibSales.SalesFacetRegistryEntry(
      sellFunctionSelector,
      revokeSaleFunctionSelector,
      buyFunctionSelector,
      facetAddress
    );
  }

  /// @notice Batch register sales facets
  function registerSalesFacetBatch(
    uint16[] calldata saleTypeIds,
    bytes4[] calldata sellFunctionSelectors,
    bytes4[] calldata revokeSaleFunctionSelectors,
    bytes4[] calldata buyFunctionSelectors,
    address[] calldata facetAddresses
  ) external {
    LibDiamond.enforceIsContractOwner();
    if (
      saleTypeIds.length != sellFunctionSelectors.length
      || saleTypeIds.length != revokeSaleFunctionSelectors.length
      || saleTypeIds.length != buyFunctionSelectors.length
      || saleTypeIds.length != facetAddresses.length
    ) {
      revert InvalidLength();
    }
    mapping(uint16 => LibSales.SalesFacetRegistryEntry) storage salesFacetRegistry =
    LibSales.salesData().salesFacetRegistry;
    for (uint256 i = 0; i < saleTypeIds.length; ++i) {
      salesFacetRegistry[saleTypeIds[i]] = LibSales.SalesFacetRegistryEntry(
        sellFunctionSelectors[i],
        revokeSaleFunctionSelectors[i],
        buyFunctionSelectors[i],
        facetAddresses[i]
      );
    }
  }

  /// @notice Deregister a sales facet
  function deregisterSalesFacet(uint16 saleTypeId) external {
    LibDiamond.enforceIsContractOwner();
    LibSales.salesData().salesFacetRegistry[saleTypeId].facetAddress = address(0);
  }

  /// @notice Batch deregister sales facets
  function deregisterSalesFacetBatch(uint16[] calldata saleTypeIds) external {
    LibDiamond.enforceIsContractOwner();
    mapping(uint16 => LibSales.SalesFacetRegistryEntry) storage salesFacetRegistry =
    LibSales.salesData().salesFacetRegistry;
    for (uint256 i = 0; i < saleTypeIds.length; ++i) {
      salesFacetRegistry[saleTypeIds[i]].facetAddress = address(0);
    }
  }

  function calculateNftPortions(
    NftStorage.NftType storage nftType,
    address gallery,
    address reseller,
    LibSales.SalesGlobals storage salesGlobals
  ) private view returns (Portions memory portions) {
    if (reseller == address(0)) {
      portions.protocol = salesGlobals.mintPortionProtocol;
      portions.sio = nftType.mintPortionSio;
      if (gallery != address(0)) {
        portions.gallery = salesGlobals.mintPortionGallery;
      }
      portions.creators = 10_000 - portions.protocol - portions.gallery - portions.sio;
    } else {
      portions.protocol = salesGlobals.resalePortionProtocol;
      portions.sio = nftType.resalePortionSio;
      if (gallery != address(0)) {
        portions.gallery = salesGlobals.resalePortionGallery;
      }
      portions.creators = nftType.resalePortionCreator;
      portions.reseller = 10_000 - portions.protocol - portions.gallery - portions.sio - portions.creators;
    }
  }

  function calculateNftClaimAmounts(
    address creator,
    uint32 creatorTypeId,
    address gallery,
    bool isResale,
    uint256 price
  ) external view returns (ClaimAmounts memory claimAmounts) {
    LibSales.SalesData storage salesData = LibSales.salesData();
    NftStorage.NftType storage nftType = NftStorage.creatorCreatorTypeIdToNftType(creator, creatorTypeId);
    Portions memory portions = calculateNftPortions(
      nftType,
      gallery,
      isResale ? address(1) : address(0),
      salesData.salesGlobals[salesData.currentSalesGlobalsIdx]
    );

    claimAmounts.reseller = price * portions.reseller / 10_000;
    claimAmounts.gallery = price * portions.gallery / 10_000;
    claimAmounts.protocol = price * portions.protocol / 10_000;

    claimAmounts.primaryCreator = 10_000;
    claimAmounts.collabs = new uint256[](nftType.collabPortions.length);
    for (uint i = 0; i < claimAmounts.collabs.length; ++i) {
      claimAmounts.primaryCreator -= nftType.collabPortions[i];
      claimAmounts.collabs[i] = price * portions.creators * nftType.collabPortions[i] / 100_000_000;
    }
    claimAmounts.primaryCreator = price * portions.creators * claimAmounts.primaryCreator / 100_000_000;

    if (nftType.sioId == SioStorage.MULTI_SIO_ID) {
      SioStorage.SioData storage sioData = SioStorage.sioData();
      SioStorage.MultiSio storage userMultiSio = sioData.userMultiSios[creator][sioData.numUserMultiSios[creator]];
      claimAmounts.sios = new uint256[](userMultiSio.portions.length);
      for (uint i = 0; i < userMultiSio.portions.length; ++i) {
        claimAmounts.sios[i] = price * portions.sio * userMultiSio.portions[i] / 100_000_000;
      }
    } else {
      claimAmounts.sios = new uint256[](1);
      claimAmounts.sios[0] = price * portions.sio / 10_000;
    }
  }

  function calculatePackPortions(
    LibSales.TokenSale storage sale,
    PackStorage.PackSubtype storage packSubtype,
    address gallery,
    LibSales.SalesData storage salesData
  ) private view returns (Portions memory portions) {
    LibSales.SalesGlobals storage salesGlobals = salesData.salesGlobals[sale.salesGlobalsIdx];

    if (sale.reseller == address(0)) {
      portions.protocol = salesGlobals.mintPortionProtocol;
      portions.sio = packSubtype.mintPortionSio;
      if (gallery != address(0)) {
        portions.gallery = salesGlobals.mintPortionGallery;
      }
      portions.creators = 10_000 - portions.protocol - portions.gallery - portions.sio;
    } else {
      portions.protocol = salesGlobals.resalePortionProtocol;
      portions.reseller = 10_000 - portions.protocol;
    }
  }

  function claimShares(
    address recipient,
    uint256[] calldata nftSaleIds,
    SaleRole[] calldata saleRoles,
    uint8[] calldata collabIdxs
  ) external nonReentrant lockable {
    LibSales.SalesData storage salesData = LibSales.salesData();
    mapping(uint256 => NftStorage.Nft) storage nfts = NftStorage.nftData().nfts;
    mapping(uint256 => PackStorage.PackSubtype) storage packSubtypes = PackStorage.packData().packSubtypes;

    uint256 total = 0;
    for (uint i = 0; i < nftSaleIds.length; ++i) {
      LibSales.TokenSale storage sale = salesData.tokenSales[nftSaleIds[i]];

      if (sale.tokenId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_NFT) {
        NftStorage.NftType storage nftType = NftStorage.nftIdToType(sale.tokenId);
        Portions memory portions = calculateNftPortions(
          nftType,
          nfts[sale.tokenId].gallery,
          sale.reseller,
          salesData.salesGlobals[sale.salesGlobalsIdx]
        );

        if (saleRoles[i] == SaleRole.PRIMARY_CREATOR) {
          if (sale.sellerCreatorGalleryProtocolClaims & LibSales.BIT_CLAIMED_CREATOR != 0) {
            revert AlreadyClaimed(i);
          }
          if (NftStorage.nftIdToCreator(sale.tokenId) != recipient) {
            revert WrongRecipient(i);
          }

          sale.sellerCreatorGalleryProtocolClaims |= LibSales.BIT_CLAIMED_CREATOR;

          uint256 primaryCreatorPortion = 10_000;
          for (uint j = 0; j < nftType.collabPortions.length; ++j) {
            primaryCreatorPortion -= nftType.collabPortions[j];
          }
          total += sale.price * portions.creators * primaryCreatorPortion / 100_000_000;
        } else if (saleRoles[i] == SaleRole.COLLAB) {
          uint256 collabBit = 1 << collabIdxs[i];
          if (sale.collabClaims & collabBit != 0) {
            revert AlreadyClaimed(i);
          }
          if (nftType.collabs[collabIdxs[i]] != recipient) {
            revert WrongRecipient(i);
          }

          sale.collabClaims |= collabBit;

          total += sale.price * portions.creators * nftType.collabPortions[collabIdxs[i]] / 100_000_000;
        } else if (saleRoles[i] == SaleRole.RESELLER) {
          if (sale.sellerCreatorGalleryProtocolClaims & LibSales.BIT_CLAIMED_RESELLER != 0) {
            revert AlreadyClaimed(i);
          }
          if (sale.reseller != recipient) {
            revert WrongRecipient(i);
          }

          sale.sellerCreatorGalleryProtocolClaims |= LibSales.BIT_CLAIMED_RESELLER;

          total += sale.price * portions.reseller / 10_000;
        } else if (saleRoles[i] == SaleRole.GALLERY) {
          if (sale.sellerCreatorGalleryProtocolClaims & LibSales.BIT_CLAIMED_GALLERY != 0) {
            revert AlreadyClaimed(i);
          }
          if (nfts[sale.tokenId].gallery != recipient) {
            revert WrongRecipient(i);
          }

          sale.sellerCreatorGalleryProtocolClaims |= LibSales.BIT_CLAIMED_GALLERY;

          total += sale.price * portions.gallery / 10_000;
        } else {
          revert InvalidSaleRole(saleRoles[i]);
        }
      } else if (sale.tokenId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK) {
        Portions memory portions = calculatePackPortions(
          sale,
          packSubtypes[sale.tokenId],
          PackStorage.packSubtypeIdToGallery(sale.tokenId),
          salesData
        );

        if (saleRoles[i] == SaleRole.COLLAB) {
          PackStorage.PackType storage packType = PackStorage.packSubtypeIdToType(sale.tokenId);

          uint256 collabBit = 1 << collabIdxs[i];
          if (sale.collabClaims & collabBit != 0) {
            revert AlreadyClaimed(i);
          }
          if (packType.nftTypeCreators[collabIdxs[i]] != recipient) {
            revert WrongRecipient(i);
          }

          sale.collabClaims |= collabBit;

          total += sale.price * portions.creators * packType.creatorPortions[collabIdxs[i]] / 100_000_000;
        } else if (saleRoles[i] == SaleRole.RESELLER) {
          if (sale.sellerCreatorGalleryProtocolClaims & LibSales.BIT_CLAIMED_RESELLER != 0) {
            revert AlreadyClaimed(i);
          }
          if (sale.reseller != recipient) {
            revert WrongRecipient(i);
          }

          sale.sellerCreatorGalleryProtocolClaims |= LibSales.BIT_CLAIMED_RESELLER;

          total += sale.price * portions.reseller / 10_000;
        } else if (saleRoles[i] == SaleRole.GALLERY) {
          if (sale.sellerCreatorGalleryProtocolClaims & LibSales.BIT_CLAIMED_GALLERY != 0) {
            revert AlreadyClaimed(i);
          }
          if (nfts[sale.tokenId].gallery != recipient) {
            revert WrongRecipient(i);
          }

          sale.sellerCreatorGalleryProtocolClaims |= LibSales.BIT_CLAIMED_GALLERY;

          total += sale.price * portions.gallery / 10_000;
        } else {
          revert InvalidSaleRole(saleRoles[i]);
        }
      } else {
        revert UnsupportedTokenClass(sale.tokenId);
      }
    }

    if (total > 0 && !IERC20(salesData.usdc).transfer(recipient, total)) {
      revert Erc20TransferFailed();
    }
    emit SharesClaimed(recipient, nftSaleIds, saleRoles, collabIdxs, total);
  }

  /// @notice Claim the portion of NFT sales owed to the SIO beneficiary
  /// @param tokenSaleIds IDs of the sales
  function claimSioShares(
    uint32 sioId,
    uint256[] calldata tokenSaleIds,
    uint256 bonderFee
  ) external nonReentrant lockable {
    LibSales.SalesData storage salesData = LibSales.salesData();
    mapping(uint256 => NftStorage.Nft) storage nfts = NftStorage.nftData().nfts;
    mapping(uint256 => PackStorage.PackSubtype) storage packSubtypes = PackStorage.packData().packSubtypes;
    SioStorage.SioData storage sioData = SioStorage.sioData();
    SioStorage.Sio storage sio = sioData.sios[sioId];

    if (msg.sender != sio.sioAddress && !sio.claimers[msg.sender]) {
      revert NotApprovedClaimer();
    }

    uint256 total = 0;

    for (uint i = 0; i < tokenSaleIds.length; ++i) {
      LibSales.TokenSale storage sale = salesData.tokenSales[tokenSaleIds[i]];
      uint32 saleSioId;
      Portions memory portions;

      if (sale.tokenId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_NFT) {
        NftStorage.NftType storage nftType = NftStorage.nftIdToType(sale.tokenId);
        saleSioId = nftType.sioId;
        portions = calculateNftPortions(
          nftType,
          nfts[sale.tokenId].gallery,
          sale.reseller,
          salesData.salesGlobals[sale.salesGlobalsIdx]
        );
      } else if (sale.tokenId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK) {
        PackStorage.PackSubtype storage packSubtype = packSubtypes[sale.tokenId];
        saleSioId = packSubtype.sioId;
        portions = calculatePackPortions(
          sale,
          packSubtype,
          PackStorage.packSubtypeIdToGallery(sale.tokenId),
          salesData
        );
      } else {
        revert UnsupportedTokenClass(sale.tokenId);
      }

      if (saleSioId == SioStorage.MULTI_SIO_ID) {
        SioStorage.MultiSio storage userMultiSio = sioData.userMultiSios[NftStorage.nftIdToCreator(sale.tokenId)][nfts[sale.tokenId].userMultiSioIdx];
        uint256 sioIdx = 0;
        while (sioIdx < userMultiSio.sios.length) {
          if (userMultiSio.sios[sioIdx] == sioId) {
            break;
          }
          ++sioIdx;
        }

        uint256 sioBit = 1 << sioIdx;

        if (sale.sioClaims & sioBit != 0) {
          revert AlreadyClaimed(i);
        }
        if (sioIdx == userMultiSio.sios.length) {
          revert WrongRecipient(i);
        }

        total += sale.price * portions.sio * userMultiSio.portions[sioIdx] / 100_000_000;
      } else {
        if (sale.sioClaims != 0) {
          revert AlreadyClaimed(i);
        }
        if (saleSioId != sioId) {
          revert WrongRecipient(i);
        }

        sale.sioClaims = 1;
        total += sale.price * portions.sio / 10_000;
      }
    }

    if (sio.sioAddress == address(0)) {
      revert ZeroAddressRecipient();
    }
    if (sio.chainId == block.chainid) {
      if (!IERC20(salesData.usdc).transfer(sio.sioAddress, total)) {
        revert Erc20TransferFailed();
      }
    } else if (sio.chainId == 1) {
      LibSales.hopBridgeUsdc(sio.sioAddress, total, bonderFee);
    } else {
      revert UnsupportedChainId(sio.chainId);
    }
    emit SioSharesClaimed(sioId, tokenSaleIds, bonderFee, total);
  }

  function claimProtocolShares(uint256[] calldata tokenSaleIds) external nonReentrant lockable {
    LibSales.SalesData storage salesData = LibSales.salesData();

    uint256 total = 0;

    for (uint i = 0; i < tokenSaleIds.length; ++i) {
      LibSales.TokenSale storage sale = salesData.tokenSales[tokenSaleIds[i]];
      LibSales.SalesGlobals storage salesGlobals = salesData.salesGlobals[sale.salesGlobalsIdx];

      if (sale.sellerCreatorGalleryProtocolClaims & LibSales.BIT_CLAIMED_PROTOCOL != 0) {
        revert AlreadyClaimed(i);
      }

      sale.sellerCreatorGalleryProtocolClaims |= LibSales.BIT_CLAIMED_PROTOCOL;

      total += sale.price * (sale.reseller == address(0) ? salesGlobals.mintPortionProtocol : salesGlobals.resalePortionProtocol) / 10_000;
    }

    if (total > 0 && !IERC20(salesData.usdc).transfer(salesData.salesController, total)) {
      revert Erc20TransferFailed();
    }
    emit ProtocolSharesClaimed(tokenSaleIds, total);
  }


  function lockSalesCommonFacet(bool lock) external {
    if (msg.sender != LibSales.salesData().salesController && msg.sender != LibDiamond.diamondStorage().contractOwner) {
      revert NotController();
    }
    LibSales.salesData().facetUnlocked = !lock;
  }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT


import "./LibToken.sol";
import "./SioStorage.sol";

library NftStorage {
  bytes32 constant NFT_STORAGE_POSITION = 0x558ce899909183d3957f0d9db37c5fe712ca6e67ef183e0d82be1a0969537859;

  /// @notice Emitted when a new NFT type definition is added
  event NftTypeCreated(NftTypeDefinition nftTypeDefinition);
  /// @notice Emitted when a new NFT token is minted
  event NftCreated(uint256 nftId, address to, address gallery, uint32 userMultiSioIdx);
  /// @notice Emitted when new NFT tokens are minted
  event NftsCreated(uint256 firstNftId, uint32 amount, address to, address gallery, uint32 userMultiSioIdx);

  event MaxEditionsReduced(address creator, uint48 creatorTypeId, uint32 newMax);

  error InsufficientEditionsAvailable();
  error InsufficientMintsByAddressAvailable(uint32 amount, address minter);

  /**
   * @notice Defines an NFT type
   * @param creator The NFT type's primary creator (e.g. the main artist)
   * @param collabs List of collaborators in addition to the primary creator
   * @param collabPortions The portion of creator payments each collaborator receives, in parts per 10,000
  */
  struct NftType {
    address[] collabs;
    uint16[] collabPortions;
    uint32 sioId;
    uint32 maxEditions;
    uint16 mintPortionSio;
    uint16 resalePortionSio;
    uint16 resalePortionCreator;

    uint32 numReservedEditions;
    uint32 nextId;
    uint40 firstSaleTime;
    bool sioClaimedSinceSet;

    bytes ipfsCid;

    // deployed

    uint32 maxMintsPerAddress; // 0 = infinity, unfortunately
    mapping(address => uint32) numMintsByAddress;
  }

  struct NftTypeDefinition {
    address creator;
    uint48 creatorTypeId;
    address[] collabs;
    uint16[] collabPortions;
    uint32 sioId;
    uint32 maxEditions;
    uint32 maxMintsPerAddress;
    uint16 mintPortionSio;
    uint16 resalePortionSio;
    uint16 resalePortionCreator;
    bytes ipfsCid;
  }

  /**
   * @notice Defines an individual NFT (i.e. an instance of an NFT type)
   * @param typeId The NFT's type ID
   * @param creatorRoyalty The portion of the original sale that belongs to the primary creator and collaborators
   * @param gallery The gallery for the original sale, or address(this) if none
   * @param sioId ID for the SIO beneficiary of this NFT
   * @dev By design, no more than one of any individual NFT should be minted
  */
  struct Nft {
    address gallery;
    uint32 userMultiSioIdx;
  }

  struct NftData {
    // NFT type ID => NftType
    mapping(uint208 => NftType) nftTypes;
    // NFT ID => Nft
    mapping(uint256 => Nft) nfts;
    bytes32 domainSeparator;
    bool facetUnlocked;
  }

  //noinspection NoReturn
  function nftData() internal pure returns (NftData storage ds) {
    bytes32 position = NFT_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function constructNftTypeId(address creator, uint48 creatorTypeId) internal pure returns (uint208 nftTypeId) {
    return (uint208(uint160(creator)) << TokenConstants.BITS_NFT_CREATOR_TYPE) | creatorTypeId;
  }

  function constructNftZeroEdition(uint208 nftTypeId) internal pure returns (uint256 nftZeroId) {
    return uint256(nftTypeId) << TokenConstants.BITS_NFT_EDITION;
  }

  function constructNftZeroEdition(address creator, uint48 creatorTypeId) internal pure returns (uint256) {
    return constructNftZeroEdition((uint208(uint160(creator)) << TokenConstants.BITS_NFT_CREATOR_TYPE) | creatorTypeId);
  }

  function setOrVerifyNftType(NftTypeDefinition calldata nftTypeDefinition) internal returns (NftType storage nftType) {
    nftType = nftData().nftTypes[constructNftTypeId(nftTypeDefinition.creator, nftTypeDefinition.creatorTypeId)];
    if (nftType.nextId == 0) {
      // Type has not been defined yet
      require(nftTypeDefinition.collabs.length == nftTypeDefinition.collabPortions.length, "Invalid NFT type parameters");
      require(nftTypeDefinition.maxEditions <= type(uint32).max - 1, "Max max editions is 2^32 - 2");
      nftType.collabs = nftTypeDefinition.collabs;
      nftType.collabPortions = nftTypeDefinition.collabPortions;
      nftType.sioId = nftTypeDefinition.sioId;
      nftType.maxEditions = nftTypeDefinition.maxEditions;
      nftType.maxMintsPerAddress = nftTypeDefinition.maxMintsPerAddress;
      nftType.mintPortionSio = nftTypeDefinition.mintPortionSio;
      nftType.resalePortionSio = nftTypeDefinition.resalePortionSio;
      nftType.resalePortionCreator = nftTypeDefinition.resalePortionCreator;
      nftType.ipfsCid = nftTypeDefinition.ipfsCid;

      nftType.nextId = 1;
      emit NftTypeCreated(nftTypeDefinition);
    } else {
      // Type has been defined. Verify parameters.
      require(
        nftTypeDefinition.collabs.length == nftType.collabs.length
        && nftTypeDefinition.collabPortions.length == nftType.collabPortions.length
        && nftTypeDefinition.sioId == nftType.sioId
        && nftTypeDefinition.maxEditions == nftType.maxEditions
        && nftTypeDefinition.maxMintsPerAddress == nftType.maxMintsPerAddress
        && nftTypeDefinition.mintPortionSio == nftType.mintPortionSio
        && nftTypeDefinition.resalePortionSio == nftType.resalePortionSio
        && nftTypeDefinition.resalePortionCreator == nftType.resalePortionCreator
        && keccak256(abi.encodePacked(nftTypeDefinition.ipfsCid)) == keccak256(abi.encodePacked(nftType.ipfsCid)),
        "NFT type parameters mismatch"
      );
      for (uint i = 0; i < nftTypeDefinition.collabs.length; ++i) {
        require(
          nftTypeDefinition.collabs[i] == nftType.collabs[i]
          && nftTypeDefinition.collabPortions[i] == nftType.collabPortions[i],
          "NFT type parameters mismatch"
        );
      }
      reduceMaxEditions(
        nftType,
        nftTypeDefinition.maxEditions,
        nftTypeDefinition.creator,
        nftTypeDefinition.creatorTypeId
      );
    }
  }

  function mintNft(
    address to,
    uint208 nftTypeId,
    address creator,
    address gallery,
    uint32 edition
  ) internal returns (uint256 nftId) {
    NftData storage nftData = nftData();

    nftId = (uint256(nftTypeId) << TokenConstants.BITS_NFT_EDITION) | edition;
    uint32 userMultiSioIdx = SioStorage.sioData().numUserMultiSios[creator];
    nftData.nfts[nftId] = Nft(gallery, userMultiSioIdx);
    LibToken._mint(to, nftId, 1, "");

    ++nftData.nftTypes[nftTypeId].numMintsByAddress[to];

    emit NftCreated(nftId, to, gallery, userMultiSioIdx);
  }

  function mintNft(
    address to,
    uint208 nftTypeId,
    address gallery,
    uint32 edition
  ) internal returns (uint256) {
    return mintNft(to, nftTypeId, address(uint160(nftTypeId >> TokenConstants.BITS_NFT_CREATOR_TYPE)), gallery, edition);
  }

  function mintNft(
    address to,
    address creator,
    uint48 creatorTypeId,
    address gallery,
    uint32 edition
  ) internal returns (uint256) {
    return mintNft(to, constructNftTypeId(creator, creatorTypeId), creator, gallery, edition);
  }

  function mintNfts(
    address to,
    uint208 nftTypeId,
    address creator,
    address gallery,
    uint32 amount
  ) internal returns (uint256 firstNftId) {
    NftData storage nftData = nftData();
    NftType storage nftType = nftData.nftTypes[nftTypeId];

    if (numAvailableMints(nftType, to) < amount) {
      revert InsufficientMintsByAddressAvailable(amount, to);
    }

    uint32 userMultiSioIdx = SioStorage.sioData().numUserMultiSios[creator];
    uint256 nftIdBase = uint256(nftTypeId) << TokenConstants.BITS_NFT_EDITION;
    uint32 edition = nftType.nextId;
    nftType.nextId += amount;
    for (; edition < nftType.nextId; ++edition) {
      uint256 nftId = nftIdBase | edition;
      nftData.nfts[nftId] = Nft(gallery, userMultiSioIdx);
      LibToken._mint(to, nftId, 1, "");
    }

    nftType.numMintsByAddress[to] += amount;

    firstNftId = nftIdBase | (nftType.nextId - amount);
    emit NftsCreated(firstNftId, amount, to, gallery, userMultiSioIdx);
  }

  function mintNfts(
    address to,
    uint208 nftTypeId,
    address gallery,
    uint32 amount
  ) internal returns (uint256) {
    return mintNfts(to, nftTypeId, address(uint160(nftTypeId >> TokenConstants.BITS_NFT_CREATOR_TYPE)), gallery, amount);
  }

  function mintNfts(
    address to,
    address creator,
    uint48 creatorTypeId,
    address gallery,
    uint32 amount
  ) internal returns (uint256) {
    return mintNfts(to, constructNftTypeId(creator, creatorTypeId), creator, gallery, amount);
  }

  function reduceMaxEditions(NftType storage nftType, uint32 newMax, address creator, uint48 creatorTypeId) internal {
    if (newMax < nftType.maxEditions) {
      uint32 difference = nftType.maxEditions - newMax;
      uint32 availableEditions = numAvailableEditions(nftType);
      nftType.maxEditions -= difference < availableEditions ? difference : availableEditions;
      emit MaxEditionsReduced(creator, creatorTypeId, newMax);
    }
  }

  /// @dev Note that an underflow caused by an undefined NFT type still produces the correct result (0)
  function numAvailableEditions(NftType storage nftType) internal view returns (uint32) {
    uint32 mintedPlusReserved = nftType.nextId + nftType.numReservedEditions - 1;
    if (nftType.maxEditions <= mintedPlusReserved) {
      return 0;
    }
    return nftType.maxEditions - mintedPlusReserved;
  }

  function numAvailableMints(NftType storage nftType, address minter) internal view returns (uint32) {
    uint32 availableEditions = numAvailableEditions(nftType);
    if (nftType.maxMintsPerAddress == 0) {
      return availableEditions;
    }
    uint32 availableMints = nftType.maxMintsPerAddress - nftType.numMintsByAddress[minter];
    return availableMints < availableEditions ? availableMints : availableEditions;
  }

  function reserveEditions(NftType storage nftType, uint32 numEditions) internal {
    if (NftStorage.numAvailableEditions(nftType) < numEditions) {
      revert InsufficientEditionsAvailable();
    }
    nftType.numReservedEditions += numEditions;
  }

  function nftTypeIdToCreator(uint208 nftTypeId) internal pure returns (address creator) {
    creator = address(uint160(nftTypeId >> TokenConstants.BITS_NFT_CREATOR_TYPE));
  }

  function nftIdToTypeId(uint256 nftId) internal view returns (uint208 nftTypeId) {
    require(nftId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_NFT, "Not an NFT");
    return uint208(nftId >> TokenConstants.BITS_NFT_EDITION);
  }

  function nftIdToType(uint256 nftId) internal view returns (NftType storage nftType) {
    return nftData().nftTypes[nftIdToTypeId(nftId)];
  }

  function nftIdToCreator(uint256 nftId) internal pure returns (address creator) {
    require(
      nftId & TokenConstants.MASK_CLASS == 0 || nftId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK,
      "Not an NFT"
    );
    return address(uint160(nftId >> 80));
  }

  function creatorCreatorTypeIdToNftType(
    address creator,
    uint48 creatorTypeId
  ) internal view returns (NftType storage nftType) {
    return nftData().nftTypes[constructNftTypeId(creator, creatorTypeId)];
  }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT


import "../interfaces/IERC1155Receiver.sol";
import "../interfaces/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./TokenConstants.sol";
import "./sales/ResaleStorage.sol";

/**
 * @dev Implementation of Multi-Token Standard contract. This implementation of the ERC-1155 standard
 *      utilizes the fact that balances of different token ids can be concatenated within individual
 *      uint256 storage slots. This allows the contract to batch transfer tokens more efficiently at
 *      the cost of limiting the maximum token balance each address can hold. This limit is
 *      2^IDS_BITS_SIZE, which can be adjusted below. In practice, using IDS_BITS_SIZE smaller than 16
 *      did not lead to major efficiency gains.
 */
library LibToken {
  using Address for address;

  bytes32 constant TOKEN_STORAGE_POSITION = 0xd7ccbcf52a690ce680df9e1a1e59108ec60ca83e5ca92ba8aa44abb859fa2197;

  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _amount
  );

  event TransferBatch(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  error InvalidBinWriteOperation();

  struct TokenData {
    mapping(address => mapping(uint256 => uint256)) balances;
    mapping(address => mapping(address => bool)) operators;
  }

  //noinspection NoReturn
  function tokenData() internal pure returns (TokenData storage ds) {
    bytes32 position = TOKEN_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Constants regarding bin sizes for balance packing
  // IDS_BITS_SIZE **MUST** be a power of 2 (e.g. 2, 4, 8, 16, 32, 64, 128)
  uint256 internal constant IDS_BITS_SIZE = 32; // Max balance amount in bits per token ID
  uint256 internal constant IDS_PER_UINT256 = 256 / IDS_BITS_SIZE; // Number of ids per uint256

  // Operations for _updateIDBalance
  enum Operations {Add, Sub}

  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal
  {
    // Requirements
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      "ERC1155PackedBalance#safeTransferFrom: INVALID_OPERATOR"
    );
    require(_to != address(0), "ERC1155PackedBalance#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances);  Not necessary since checked with _viewUpdateBinValue() checks

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) internal
  {
    // Requirements
    require(
      (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
      "ERC1155PackedBalance#safeBatchTransferFrom: INVALID_OPERATOR"
    );
    require(_to != address(0), "ERC1155PackedBalance#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal {
    require(_to != address(0), "ERC1155PackedBalance#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances);  Not necessary since checked with _viewUpdateBinValue() checks

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount
  ) internal {
    //Update balances
    _updateIDBalance(_from, _id, _amount, Operations.Sub);
    // Subtract amount from sender
    _updateIDBalance(_to, _id, _amount, Operations.Add);
    // Add amount to recipient

    ResaleStorage.sanitizeResaleOffers(_from, _id);

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval =
      IERC1155Receiver(_to).onERC1155Received{gas : _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(
        retval == ERC1155_RECEIVED_VALUE,
        "ERC1155PackedBalance#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE"
      );
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    uint256 nTransfer = _ids.length;
    // Number of transfer to execute
    require(nTransfer == _amounts.length, "ERC1155PackedBalance#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    if (_from != _to && nTransfer > 0) {
      TokenData storage tokenData = tokenData();

      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balFrom =
      _viewUpdateBinValue(tokenData.balances[_from][bin], index, _amounts[0], Operations.Sub);
      uint256 balTo =
      _viewUpdateBinValue(tokenData.balances[_to][bin], index, _amounts[0], Operations.Add);

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          tokenData.balances[_from][lastBin] = balFrom;
          tokenData.balances[_to][lastBin] = balTo;

          balFrom = tokenData.balances[_from][bin];
          balTo = tokenData.balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balFrom = _viewUpdateBinValue(balFrom, index, _amounts[i], Operations.Sub);
        balTo = _viewUpdateBinValue(balTo, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      tokenData.balances[_from][bin] = balFrom;
      tokenData.balances[_to][bin] = balTo;

      // If transfer to self, just make sure all amounts are valid
    } else {
      for (uint256 i = 0; i < nTransfer; i++) {
        require(balanceOf(_from, _ids[i]) >= _amounts[i], "ERC1155PackedBalance#_safeBatchTransferFrom: UNDERFLOW");
      }
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    uint256 _gasLimit,
    bytes memory _data
  ) internal {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval =
      IERC1155Receiver(_to).onERC1155BatchReceived{gas : _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(
        retval == ERC1155_BATCH_RECEIVED_VALUE,
        "ERC1155PackedBalance#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE"
      );
    }
  }

  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external /*override*/
  {
    // Update operator status
    tokenData().operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
  internal
  view
  returns (bool isOperator)
  {
    return tokenData().operators[_owner][_operator];
  }

  /***********************************|
  |     Public Balance Functions      |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
  internal
  view
  returns (
    uint256
  )
  {
    uint256 bin;
    uint256 index;

    //Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);
    return getValueInBin(tokenData().balances[_owner][bin], index);
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders (sorted owners will lead to less gas usage)
   * @param _ids    ID of the Tokens (sorted ids will lead to less gas usage
   * @return The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
  internal
  view
  returns (
    uint256[] memory
  )
  {
    TokenData storage tokenData = tokenData();

    uint256 n_owners = _owners.length;
    require(n_owners == _ids.length, "ERC1155PackedBalance#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // First values
    (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);
    uint256 balance_bin = tokenData.balances[_owners[0]][bin];
    uint256 last_bin = bin;

    // Initialization
    uint256[] memory batchBalances = new uint256[](n_owners);
    batchBalances[0] = getValueInBin(balance_bin, index);

    // Iterate over each owner and token ID
    for (uint256 i = 1; i < n_owners; i++) {
      (bin, index) = getIDBinIndex(_ids[i]);

      // SLOAD if bin changed for the same owner or if owner changed
      if (bin != last_bin || _owners[i - 1] != _owners[i]) {
        balance_bin = tokenData.balances[_owners[i]][bin];
        last_bin = bin;
      }

      batchBalances[i] = getValueInBin(balance_bin, index);
    }

    return batchBalances;
  }

  /***********************************|
  |      Packed Balance Functions     |
  |__________________________________*/

  /**
   * @notice Update the balance of a id for a given address
   * @param _address    Address to update id balance
   * @param _id         Id to update balance of
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to id balance
   *   Operations.Sub: Substract _amount from id balance
   */
  function _updateIDBalance(
    address _address,
    uint256 _id,
    uint256 _amount,
    Operations _operation
  ) internal {
    TokenData storage tokenData = tokenData();

    uint256 bin;
    uint256 index;

    // Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);

    // Update balance
    tokenData.balances[_address][bin] = _viewUpdateBinValue(
      tokenData.balances[_address][bin],
      index,
      _amount,
      _operation
    );
  }

  /**
   * @notice Update a value in _binValues
   * @param _binValues  Uint256 containing values of size IDS_BITS_SIZE (the token balances)
   * @param _index      Index of the value in the provided bin
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to value in _binValues at _index
   *   Operations.Sub: Substract _amount from value in _binValues at _index
   */
  function _viewUpdateBinValue(
    uint256 _binValues,
    uint256 _index,
    uint256 _amount,
    Operations _operation
  ) internal pure returns (uint256 newBinValues) {
    uint256 shift = IDS_BITS_SIZE * _index;
    uint256 mask = (uint256(1) << IDS_BITS_SIZE) - 1;

    if (_operation == Operations.Add) {
      newBinValues = _binValues + (_amount << shift);
      require(newBinValues >= _binValues, "ERC1155PackedBalance#_viewUpdateBinValue: OVERFLOW");
      require(
        ((_binValues >> shift) & mask) + _amount < 2 ** IDS_BITS_SIZE, // Checks that no other id changed
        "ERC1155PackedBalance#_viewUpdateBinValue: OVERFLOW"
      );
    } else if (_operation == Operations.Sub) {
      newBinValues = _binValues - (_amount << shift);
      require(newBinValues <= _binValues, "ERC1155PackedBalance#_viewUpdateBinValue: UNDERFLOW");
      require(
        ((_binValues >> shift) & mask) >= _amount, // Checks that no other id changed
        "ERC1155PackedBalance#_viewUpdateBinValue: UNDERFLOW"
      );
    } else {
      revert InvalidBinWriteOperation();
      // Bad operation
    }

    return newBinValues;
  }

  /**
   * @notice Return the bin number and index within that bin where ID is
   * @param _id  Token id
   * @return bin index (Bin number, ID"s index within that bin)
   */
  function getIDBinIndex(uint256 _id) internal pure returns (uint256 bin, uint256 index) {
    bin = _id / IDS_PER_UINT256;
    index = _id % IDS_PER_UINT256;
    return (bin, index);
  }

  /**
   * @notice Return amount in _binValues at position _index
   * @param _binValues  uint256 containing the balances of IDS_PER_UINT256 ids
   * @param _index      Index at which to retrieve amount
   * @return amount at given _index in _bin
   */
  function getValueInBin(uint256 _binValues, uint256 _index) internal pure returns (uint256) {
    // require(_index < IDS_PER_UINT256) is not required since getIDBinIndex ensures `_index < IDS_PER_UINT256`

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << IDS_BITS_SIZE) - 1;

    // Shift amount
    uint256 rightShift = IDS_BITS_SIZE * _index;
    return (_binValues >> rightShift) & mask;
  }

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) internal {
    //Add _amount
    _updateIDBalance(_to, _id, _amount, Operations.Add);
    // Add amount to recipient

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each (_ids[i], _amounts[i]) pair
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) internal {
    TokenData storage tokenData = tokenData();

    require(_ids.length == _amounts.length, "ERC1155MintBurnPackedBalance#_batchMint: INVALID_ARRAYS_LENGTH");

    if (_ids.length > 0) {
      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balTo =
      _viewUpdateBinValue(tokenData.balances[_to][bin], index, _amounts[0], Operations.Add);

      // Number of transfer to execute
      uint256 nTransfer = _ids.length;

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          tokenData.balances[_to][lastBin] = balTo;
          balTo = tokenData.balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balTo = _viewUpdateBinValue(balTo, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      tokenData.balances[_to][bin] = balTo;
    }

    // //Emit event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }

  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(
    address _from,
    uint256 _id,
    uint256 _amount
  ) internal {
    // Substract _amount
    _updateIDBalance(_from, _id, _amount, Operations.Sub);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @dev This batchBurn method does not implement the most efficient way of updating
   *      balances to reduce the potential bug surface as this function is expected to
   *      be less common than transfers. EIP-2200 makes this method significantly
   *      more efficient already for packed balances.
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(
    address _from,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) internal {
    // Number of burning to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurnPackedBalance#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all burning
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      _updateIDBalance(_from, _ids[i], _amounts[i], Operations.Sub);
      // Add amount to recipient
    }

    // Emit batch burn event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
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

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


library TokenConstants {
    uint8 internal constant BITS_CLASS = 16;

    // uint8 internal constant BITS_NFT_CREATOR_ADDRESS = 160;
    uint8 internal constant BITS_NFT_CREATOR_TYPE = 48;
    uint8 internal constant BITS_NFT_TYPE = 208;
    uint8 internal constant BITS_NFT_EDITION = 32;

    // uint8 internal constant BITS_PACK_GALLERY_ADDRESS = 160;
    uint8 internal constant BITS_PACK_GALLERY_TYPE = 48;
    uint8 internal constant BITS_PACK_TYPE = 208;
    uint8 internal constant BITS_PACK_SUBTYPE = 32;

    // Token ID bit masks
    uint256 internal constant MASK_CLASS = uint256(type(uint16).max) << 240;
    // uint256 internal constant MASK_NFT_CREATOR_ADDRESS = uint256(uint160(~0)) << 80;
    // uint256 internal constant MASK_NFT_TYPE = uint256(uint208(~0)) << BITS_NFT_EDITION;
    // uint256 internal constant MASK_PACK_TYPE = uint160(~0);
    uint256 internal constant MASK_PACK_SUBTYPE = type(uint32).max;

    uint256 private constant PACK_MAX_NFTS_PER_POOL = 2 ** 16;

    // NFTs are class 0. Packs are class 1.
    uint256 internal constant CLASS_NFT = 0;
    uint256 internal constant CLASS_PACK = 1766847064778384329583297500742918515827483896875618958121606201292619776;

    address internal constant ADDRESS_CLAIMED = address(1);
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


import "../LibToken.sol";

library ResaleStorage {
  bytes32 constant EXCHANGE_STORAGE_POSITION = 0xb95856e0b0a09e2419a62d029dc73f7716cd660f05f29b43ede3a5a605f79a6c;

  event ResaleSaleOffered(address seller, uint256 tokenId, uint256 price, uint256 amount);
  event ResaleSaleBought(address seller, address buyer, uint256 tokenId, uint256 amount);
  event ResaleBuyOffered(address seller, address buyer, uint256 tokenId, uint256 totalPrice, uint256 amount);
  event ResaleBuyCanceled(address seller, address buyer, uint256 tokenId);
  event ResaleBuysCanceled(address seller, uint256 tokenId);
  event ResaleBuyAccepted(address seller, address buyer, uint256 tokenId);
  event ResaleGlobalBuyOffered(address buyer, address creator, uint32 creatorTypeId, uint256 price, uint256 amount);
  event ResaleGlobalBuyAccepted(address seller, address buyer, address creator, uint32 creatorTypeId, uint256 amount);

  struct SaleOffer {
    uint256 price;
    uint256 amount;
  }

  struct BuyOffer {
    address buyer;
    uint256 totalPrice;
    uint256 amount;
  }

  struct ResaleData {
    mapping(address /*seller*/ => mapping(uint256 /*tokenId*/ => SaleOffer)) saleOffers;
    mapping(address /*seller*/ => mapping(uint256 /*tokenId*/ => BuyOffer[])) buyOffers;
    mapping(address /*buyer*/ => mapping(uint208 /*nftTypeId*/ => SaleOffer)) globalBuyOffers;
    bool facetUnlocked;
  }

  //noinspection NoReturn
  function resaleData() internal pure returns (ResaleData storage ds) {
    bytes32 position = EXCHANGE_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function sanitizeResaleOffers(address seller, uint256 tokenId) internal {
    ResaleData storage resaleData = resaleData();
    uint256 balance = LibToken.balanceOf(seller, tokenId);

    SaleOffer storage saleOffer = resaleData.saleOffers[seller][tokenId];
    if (saleOffer.amount > balance) {
      if (balance == 0) {
        delete resaleData.saleOffers[seller][tokenId];
        delete resaleData.buyOffers[seller][tokenId];
        emit ResaleSaleOffered(seller, tokenId, 0, 0);
        emit ResaleBuysCanceled(seller, tokenId);
      } else {
        saleOffer.amount = balance;
        emit ResaleStorage.ResaleSaleOffered(seller, tokenId, saleOffer.price, balance);
      }
    }

    BuyOffer[] storage buyOffers = resaleData.buyOffers[seller][tokenId];
    uint i = 0;
    while (i < buyOffers.length) {
      ResaleStorage.BuyOffer storage buyOffer = buyOffers[i];
      if (buyOffer.amount > balance) {
        emit ResaleBuyCanceled(seller, buyOffer.buyer, tokenId);
        buyOffers[i] = buyOffers[buyOffers.length - 1];
        buyOffers.pop();
      } else {
        ++i;
      }
    }
  }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


import "../interfaces/IDiamondCut.sol";

library SioStorage {
  // Only Approved or Pending SIO IDs can be used in NFT sales. All SIOs are Disapproved by default.
  enum ApprovalStatus { NOT_APPROVED, PENDING, APPROVED }

  error NotSioManager();

  bytes32 constant SIO_STORAGE_POSITION = 0x57721d86412869ddac8f2dda9da4727c2c60272593ae3ee129a6b23718917493;

  struct Sio {
    uint256 chainId;
    address sioAddress;
    ApprovalStatus approvalStatus;
    bool acceptsAnonymous;
    // DEPLOYED
    mapping(address => bool) claimers;
  }

  struct MultiSio {
    uint32[] sios;
    uint16[] portions;
  }

  struct SioData {
    mapping(uint32 => Sio) sios;
    mapping(uint32 /* SDG */ => uint32[] /* SIO */) sdgSios;
    mapping(address => mapping(uint32 => MultiSio)) userMultiSios;
    uint40 claimTime;
    bytes32 domainSeparator;
    mapping(address => bool) sioManagers;

    // DEPLOYED?

    mapping(address => uint32) numUserMultiSios;
    bool facetUnlocked;
  }

  //noinspection NoReturn
  function sioData() internal pure returns (SioData storage ds) {
    bytes32 position = SIO_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function enforceIsSioManager() internal view {
    if (!sioData().sioManagers[msg.sender]) {
      revert NotSioManager();
    }
  }

  // these constants moved to bottom until the IntelliJ Solidity plugin gets updated
  uint32 constant FIRST_RESERVED_SIO_ID = type(uint32).max - 1000;
  uint32 constant MULTI_SIO_ID = FIRST_RESERVED_SIO_ID;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
  enum FacetCutAction {Add, Replace, Remove}
  // Add=0, Replace=1, Remove=2

  struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
  }

  /// @notice Add/replace/remove any number of functions and optionally execute
  ///         a function with delegatecall
  /// @param _diamondCut Contains the facet addresses and function selectors
  /// @param _init The address of the contract or facet to execute _calldata
  /// @param _calldata A function call, including function selector and arguments
  ///                  _calldata is executed with delegatecall on _init
  function diamondCut(
    FacetCut[] calldata _diamondCut,
    address _init,
    bytes calldata _calldata
  ) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT


import "../libraries/TokenConstants.sol";

library PackStorage {
  bytes32 constant PACK_STORAGE_POSITION = 0xc8b2b23032da989b72046564fa86b67345d70bd6a2992230a8fd96f35b5e8acf;

  /**
   * @title Defines a pack type
   * Conceptually, pack types define a list of lists of NFT type IDs.
   * Each sublist defines the pool of NFT types for a given "rarity".
   * Instead of storing the sublists in the contract, we store only their merkle tree root hashes
   * @param roots Root hashes for each rarity pool
   * @param poolSizes The length of each rarity pool
  */
  struct PackType {
    bytes32 poolsRoot;
    uint32[] poolSizes;
    uint32[] numUnclaimed; // TODO?: turn into map
    uint32 numPackSubtypes;
    uint40 mintTimeStart;
    uint40 mintTimeEnd;
    uint40 openTime;
    uint256 maxMintBuysPerAddress;
    address[] nftTypeCreators;
    uint16[] creatorPortions;
    bytes ipfsCid;
    mapping(uint32 => uint32)[] indexMap;
    mapping(address => uint256) numPacksBought;
  }

  /**
   * @title A pack of NFTs, contents unknown
   * @param guaranteedCounts The number of NFTs from each rarity pool guaranteed to be in the pack
   * @param bonusProbabilities The probability of gaining one extra NFT from each rarity pool, in fractions of 10,000
   * @param sioId ID for the SIO beneficiary for all NFTs minted
   * @dev Unlike with NFTs, multiple copies of each pack can be minted. The contents of each copy are not determined until it is opened (and burned)
  */
  struct PackSubtype {
    uint32 sioId;
    uint16 mintPortionSio;
    uint40 firstSaleTime;
    bool sioClaimedSinceSet;
    uint256 price;
    uint16[] guaranteedCounts;
    uint16[] bonusProbabilities;
    uint256 maxMintBuysPerAddress;
    mapping(address => uint256) numPacksBought;
  }

  /**
   * @title A list of opened (burned but unclaimed) packs and their owner
   * @param packIds IDs of the opened packs
   * @param amounts The corresponding numbers of opened packs for each type
   * @param owner The owner of the opened packs
  */
  struct OpenedPacks {
    uint256[] packIds;
    uint256[] amounts;
    address owner;
  }

  struct PackData {
    // Pack type ID => PackType
    mapping(uint208 => PackType) packTypes;
    // Pack ID => PackSubtype
    mapping(uint256 => PackSubtype) packSubtypes;
    // Chainlink VRF request ID => OpenedPacks
    mapping(bytes32 => OpenedPacks) openedPacks;
    bytes32 domainSeparator;
    bool facetUnlocked;
  }

  //noinspection NoReturn
  function packData() internal pure returns (PackData storage ds) {
    bytes32 position = PACK_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function constructPackTypeId(address gallery, uint48 galleryTypeId) internal pure returns (uint208 packTypeId) {
    return (uint208(uint160(gallery)) << TokenConstants.BITS_PACK_GALLERY_TYPE) | galleryTypeId;
  }

  function packSubtypeIdToType(uint256 packSubtypeId) internal view returns (PackType storage packType) {
    require(packSubtypeId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK, "Not a pack");
    return packData().packTypes[uint208(packSubtypeId >> TokenConstants.BITS_PACK_SUBTYPE)];
  }

  function packSubtypeIdToGallery(uint256 packSubtypeId) internal pure returns (address gallery) {
    require(packSubtypeId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK, "Not a pack");
    return address(uint160(packSubtypeId >> (TokenConstants.BITS_PACK_SUBTYPE + TokenConstants.BITS_PACK_GALLERY_TYPE)));
  }

  function galleryGalleryTypeIdToPackSubtype(
    address gallery,
    uint48 galleryTypeId
  ) internal view returns (PackSubtype storage packSubtype) {
    return packData().packSubtypes[constructPackTypeId(gallery, galleryTypeId)];
  }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT


/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import "../interfaces/IDiamondCut.sol";

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = 0x28efbe39207ff5bd7b3f1c182622c996a7f144e2c137e868541e6b7881f98b1a;

  error IncorrectFacetCutAction(IDiamondCut.FacetCutAction);
  error InitLibDiamondReverted();

  struct FacetAddressAndSelectorPosition {
    address facetAddress;
    uint16 selectorPosition;
  }

  struct DiamondStorage {
    // function selector => facet address and selector position in selectors array
    mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
    bytes4[] selectors;
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
  }

  //noinspection NoReturn
  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
  }

  event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  // Internal function version of diamondCut
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else {
        revert IncorrectFacetCutAction(action);
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    uint16 selectorCount = uint16(ds.selectors.length);
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
      require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
      ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
      ds.selectors.push(selector);
      selectorCount++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
    enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
      // can't replace immutable functions -- functions defined directly in the diamond
      require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
      require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
      require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
      // replace old facet address
      ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    uint256 selectorCount = ds.selectors.length;
    require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
      require(oldFacetAddressAndSelectorPosition.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
      // can't remove immutable functions -- functions defined directly in the diamond
      require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
      // replace selector with last selector
      selectorCount--;
      if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
        bytes4 lastSelector = ds.selectors[selectorCount];
        ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
        ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
      }
      // delete last selector
      ds.selectors.pop();
      delete ds.facetAddressAndSelectorPosition[selector];
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
    } else {
      require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
      if (_init != address(this)) {
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert InitLibDiamondReverted();
        }
      }
    }
  }

  function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


import "../NftStorage.sol";
import "../SioStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC2612.sol";
import "../../interfaces/IHopL2_AmmWrapper.sol";
import "../GalleryStorage.sol";
import "../PackStorage.sol";

library LibSales {
  bytes32 constant SALES_STORAGE_POSITION = 0x59c2d70bedf2d9fe50f7e93af796c01a2f4691e02623ba988fd0fc6865532bc3;

  uint8 constant BIT_CLAIMED_RESELLER = 1;
  uint8 constant BIT_CLAIMED_CREATOR = 2;
  uint8 constant BIT_CLAIMED_GALLERY = 4;
  uint8 constant BIT_CLAIMED_PROTOCOL = 8;

  event NftSaleCompleted(TokenSale nftSale, uint256 nftSaleId);

  error InvalidPortionTotal();
  error InvalidPortion();
  error SioNotApproved();
  error UserMultiSioNotSet();
  error InvalidLength();
  error InvalidPrice();
  error GalleryNotApproved();
  error NotSalesController();
  error Erc20TransferFailed();

  struct SalesGlobals {
    uint16 mintPortionProtocol;
    uint16 resalePortionProtocol;
    uint16 mintPortionGallery;
    uint16 resalePortionGallery;
  }

  /**
  @title Data for an individual token sale
  @param tokenId ID of the token sold
  @param price Price of sale
  @param donation Extra SIO donation
  @param reseller Previous owner
  @param salesGlobalsIdx Index of the SalesGlobals struct at time of sale
  @param sioPortion The portion of this sale that belongs to the token's SIO beneficiary
  @param sellerCreatorGalleryProtocolClaims Whether the seller, primary creator, gallery and SIO have claimed their portion of the sale
  @param collabClaims Whether collaborators have claimed their portion of the sale
  @param sioClaims Whether SIOs have claimed, for multi-SIO tokens
  */
  struct TokenSale {
    uint256 tokenId;
    uint256 price;
    uint256 donation;
    address reseller;
    uint32 salesGlobalsIdx;
    uint8 sellerCreatorGalleryProtocolClaims;
    uint256 collabClaims;
    uint256 sioClaims;
  }

  struct SalesFacetRegistryEntry {
    bytes4 sellFunctionSelector;
    bytes4 revokeSaleFunctionSelector;
    bytes4 buyFunctionSelector;
    address facetAddress;
  }

  struct SalesData {
    mapping(uint256 /*saleId*/ => TokenSale) tokenSales;
    mapping(uint16 => SalesFacetRegistryEntry) salesFacetRegistry;
    mapping(uint32 => SalesGlobals) salesGlobals;
    uint256 numNftSales;
    uint32 currentSalesGlobalsIdx;

    uint256 maxPrice;

    uint16 minMintPortionSio;
    uint16 maxMintPortionSio;
    uint16 minResalePortionSio;
    uint16 maxResalePortionSio;

    uint16 minResalePortionCreator;
    uint16 maxResalePortionCreator;

    uint16 minCombinedResalePortionsSioCreator;
    uint16 maxCombinedResalePortionsSioCreator;

    uint16 minMinHigherBid;
    uint16 maxMinHigherBid;
    int40 minExtendBidTime;
    int40 maxExtendBidTime;
    uint40 minExtendSpan;
    uint40 maxExtendSpan;

    uint16 hopAmountOutMinPortion;
    uint40 hopDeadlineDiff;

    address salesController;
    address usdc;
    address payable hopBridgeL2;

    bool facetUnlocked;
  }

  struct PaymentPermit {
    uint256 amount;
    uint256 deadline;
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  function galleryPortion(address gallery, uint256 galleryPortion) internal pure returns (uint256) {
    if (gallery == address(0)) {
      return 0;
    }
    return galleryPortion;
  }

  /**
  @dev Ensures that sales parameters are valid and within predefined limits
  */
  function enforceValidSaleParams(
    uint256 price,
    NftStorage.NftTypeDefinition calldata nftTypeDefinition,
    address gallery
  ) internal view {
    SalesData storage salesData = salesData();
    SalesGlobals storage salesGlobals = salesData.salesGlobals[salesData.currentSalesGlobalsIdx];
    SioStorage.SioData storage sioData = SioStorage.sioData();

    uint256 combinedResalePortion = uint256(nftTypeDefinition.resalePortionSio) + uint256(nftTypeDefinition.resalePortionCreator);
    uint256 totalCollabsPortion;
    for (uint16 i = 0; i < nftTypeDefinition.collabPortions.length; i++) {
      totalCollabsPortion += nftTypeDefinition.collabPortions[i];
    }

    if (
      uint256(salesGlobals.mintPortionProtocol) + galleryPortion(gallery, uint256(salesGlobals.mintPortionGallery)) + uint256(nftTypeDefinition.mintPortionSio) > 10_000
      || uint256(salesGlobals.resalePortionProtocol) + galleryPortion(gallery, uint256(salesGlobals.resalePortionGallery)) + uint256(nftTypeDefinition.resalePortionSio) + uint256(nftTypeDefinition.resalePortionCreator) > 10_000
      || totalCollabsPortion > 10_000
    ) {
      revert InvalidPortionTotal();
    }

    if (
      nftTypeDefinition.mintPortionSio < salesData.minMintPortionSio
      || nftTypeDefinition.mintPortionSio > salesData.maxMintPortionSio
      || nftTypeDefinition.resalePortionSio < salesData.minResalePortionSio
      || nftTypeDefinition.resalePortionSio > salesData.maxResalePortionSio
      || nftTypeDefinition.resalePortionCreator < salesData.minResalePortionCreator
      || nftTypeDefinition.resalePortionCreator > salesData.maxResalePortionCreator
      || combinedResalePortion < salesData.minCombinedResalePortionsSioCreator
      || combinedResalePortion > salesData.maxCombinedResalePortionsSioCreator
    ) {
      revert InvalidPortion();
    }

    if (sioData.sios[nftTypeDefinition.sioId].approvalStatus == SioStorage.ApprovalStatus.NOT_APPROVED) {
      revert SioNotApproved();
    }
    if (
      nftTypeDefinition.sioId == SioStorage.MULTI_SIO_ID
      && sioData.numUserMultiSios[nftTypeDefinition.creator] == 0
    ) {
      revert UserMultiSioNotSet();
    }

    if (
      nftTypeDefinition.collabs.length != nftTypeDefinition.collabPortions.length
      || nftTypeDefinition.collabs.length > 256
    ) {
      revert InvalidLength();
    }

    if (price > salesData.maxPrice) {
      revert InvalidPrice();
    }

    if (!GalleryStorage.galleryData().whitelist[gallery]) {
      revert GalleryNotApproved();
    }
  }

  /**
  @notice Records data about an NFT sale
  @dev Called during all NFT sales
  */
  function completeTokenSale(
    uint256 tokenId,
    uint256 price,
    uint256 donation,
    address reseller
  ) internal {
    SalesData storage salesData = salesData();
    TokenSale storage nftSale = salesData.tokenSales[++salesData.numNftSales];

    nftSale.tokenId = tokenId;
    nftSale.price = price;
    nftSale.donation = donation;
    nftSale.reseller = reseller;
    nftSale.salesGlobalsIdx = salesData.currentSalesGlobalsIdx;

    if (tokenId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_NFT) {
      NftStorage.NftType storage nftType = NftStorage.nftIdToType(tokenId);
      if (nftType.firstSaleTime == 0) {
        nftType.firstSaleTime = uint40(block.timestamp);
      }
    } else if (tokenId & TokenConstants.MASK_CLASS == TokenConstants.CLASS_PACK) {
      PackStorage.PackSubtype storage packSubtype = PackStorage.packData().packSubtypes[tokenId];
      if (packSubtype.firstSaleTime == 0) {
        packSubtype.firstSaleTime = uint40(block.timestamp);
      }
    }

    emit NftSaleCompleted(nftSale, salesData.numNftSales);
  }

  function enforceIsSalesController() internal view {
    if (msg.sender != salesData().salesController) {
      revert NotSalesController();
    }
  }

  function transferUsdc(
    address from,
    address to,
    uint256 transferAmount,
    PaymentPermit calldata paymentPermit
  ) internal {
    if (transferAmount == 0) {
      return;
    }

    SalesData storage salesData = salesData();

    if (IERC20(salesData.usdc).allowance(from, address(this)) < transferAmount) {
      IERC2612(salesData.usdc).permit(
        from,
        address(this),
        paymentPermit.amount,
        paymentPermit.deadline,
        paymentPermit.v,
        paymentPermit.r,
        paymentPermit.s
      );
    }

    if (!IERC20(salesData.usdc).transferFrom(from, to, transferAmount)) {
      revert Erc20TransferFailed();
    }
  }

  function hopBridgeUsdc(address to, uint256 amount, uint256 bonderFee) internal {
    SalesData storage salesData = salesData();
    IERC20(salesData.usdc).approve(salesData.hopBridgeL2, amount);
    IHopL2_AmmWrapper(salesData.hopBridgeL2).swapAndSend(
      1,
      to,
      amount,
      bonderFee,
      amount * salesData.hopAmountOutMinPortion / 10_000,
      block.timestamp + salesData.hopDeadlineDiff,
      0,
      0
    );
  }

  //noinspection NoReturn
  function salesData() internal pure returns (SalesData storage ds) {
    bytes32 position = SALES_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



interface IHopL2_AmmWrapper {
  /// @notice amount is the amount the user wants to send plus the Bonder fee
  function swapAndSend(
    uint256 chainId,
    address recipient,
    uint256 amount,
    uint256 bonderFee,
    uint256 amountOutMin,
    uint256 deadline,
    uint256 destinationAmountOutMin,
    uint256 destinationDeadline
  )
  external
  payable;

  function attemptSwap(
    address recipient,
    uint256 amount,
    uint256 amountOutMin,
    uint256 deadline
  )
  external;
}

pragma solidity 0.8.9;

// SPDX-License-Identifier: UNLICENSED


library GalleryStorage {
  bytes32 constant GALLERY_STORAGE_POSITION = 0xb8fd946709372f7279ccac0ddc20bb94dd6cbc3cc74ac28fdb12985deffd39c3;

  struct GalleryData {
    mapping(address /*gallery */ => bool) whitelist;
  }

  //noinspection NoReturn
  function galleryData() internal pure returns (GalleryData storage ds) {
    bytes32 position = GALLERY_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC2612 is IERC20Permit {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}