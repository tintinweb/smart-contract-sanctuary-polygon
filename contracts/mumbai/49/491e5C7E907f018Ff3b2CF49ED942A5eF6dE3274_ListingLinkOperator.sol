// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165Checker.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Pausable.sol";

/**
 * @title ListingLink Operator
 * @author DarkCenobyte
 * @notice Use by ListingLink plateform for buying and selling NFT through links
 */
contract ListingLinkOperator is Pausable {
  using Address for address;
  using Counters for Counters.Counter;

  struct ListingLink {
    address nftAddress;
    uint256 nftId;
    uint8 nftType;
    address nftRoyaltyReceiver;
    uint256 nftRoyaltyAmount;
    address ftAddress;
    uint256 ftAmount;
    address sellerAddress;
    address buyerAddress;
    uint256 expirationTimestamp;
    bool isClosed;
    uint8 statusCode; 
  }

  // Listing expire after a delay restricted between 1 and 30 days
  uint8 public constant LISTING_EXPIRATION_MIN_DELAY = 1;
  uint8 public constant LISTING_EXPIRATION_MAX_DELAY = 30;
  uint8 public constant LISTING_EXPIRATION_DEFAULT_DELAY = 10;

  // Status code for Listings
  uint8 public constant OPEN_CODE = 0;
  uint8 public constant CANCEL_BY_OWNER_CODE = 1;
  uint8 public constant CANCEL_BY_AUTHORIZATION_REMOVED_CODE = 2;
  uint8 public constant CLOSED_BY_SUCCESS_CODE = 3;

  // NFT types
  uint8 public constant ERC721_TYPE = 0;
  uint8 public constant ERC1155_TYPE = 1;

  // ListingLink Fees
  uint8 public constant LISTING_LINK_FEE = 1; // in percent

  // private constant for internal use
  uint8 private constant _SUPPORTED_INTERFACE_COUNT = 3;
  uint8 private constant _ERC721_INTERFACE_IDX = 0;
  uint8 private constant _ERC1155_INTERFACE_IDX = 1;
  uint8 private constant _ERC2981_INTERFACE_IDX = 2;

  // ERC165 interface signatures
  bytes4 private constant _ERC721_INTERFACE = 0x80ac58cd;
  bytes4 private constant _ERC1155_INTERFACE = 0xd9b67a26;
  bytes4 private constant _ERC2981_INTERFACE = 0x2a55205a;

  // Supported ERC20 contracts (considered as trustable)
  address private constant _WETH_POLYGON_CONTRACT = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1; // Dummy ERC20 (DERC20) for Mumbai Network
  address private constant _USDT_POLYGON_CONTRACT = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1; // Dummy ERC20 (DERC20) for Mumbai Network
  address private constant _USDC_POLYGON_CONTRACT = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1; // Dummy ERC20 (DERC20) for Mumbai Network

  // Admin addresses (only able to pause/unpause the contract)
  address private constant _ADMIN_ADDRESS_1 = 0xb212650B5c61E4e0DF61c0ADf2D06AD42E2547A5; // Main address
  address private constant _ADMIN_ADDRESS_2 = 0xC1B7bc593456a5BF9d2bBF55B85Fe26EF4C06fCa; // Fallback address

  // Fees receiver address
  address private constant _FEES_ADDRESS_1 =  0x11C54c395C3c8FB1229Fc0d60f6fbE8192680819;

  Counters.Counter private _listingLinkIdTracker;

  uint256[] private _allListingLinks;

  // Mapping from listingLink ID to ListingLink struct
  mapping(uint256 => ListingLink) private _listingLinks;
  
  // events
  event PublicListingLinkAdded(address indexed seller, uint256 indexed listingLinkId);
  event PrivateListingLinkAdded(address indexed seller, uint256 indexed listingLinkId);
  event ListingLinkClosed(uint256 indexed listingLinkId, uint8 statusCode);
  event ListingLinkSaleSuccess(address indexed seller, address indexed buyer, uint256 indexed listingLinkId);

  // modifier
  modifier isAdmin() {
    require(msg.sender == _ADMIN_ADDRESS_1 || msg.sender == _ADMIN_ADDRESS_2, "ListingLinkOperator: Not allowed to perform this action");
    _;
  }

  modifier isExisting(uint256 listingLinkId) {
    require(exist(listingLinkId), "ListingLinkOperator: The listingLink specified does not exist");
    _;
  }

  // throwable private views helpers
  function _throwIfUnsupportedFungibleTokenContract(address ftAddress) private pure {
    require(ftAddress == _WETH_POLYGON_CONTRACT || ftAddress == _USDC_POLYGON_CONTRACT || ftAddress == _USDT_POLYGON_CONTRACT, "ListingLinkOperator: Unsupported fungible contract");
  }

  function _throwIfClosed(uint256 listingLinkId) private view {
    require(false == isClosed(listingLinkId), "ListingLinkOperator: The listingLink has been canceled/closed");
  }

  function _throwIfSenderIsNotSeller(uint256 listingLinkId) private view {
    require(msg.sender == _listingLinks[listingLinkId].sellerAddress, "ListingLinkOperator: The msg.sender isn't seller of the specified listingLinkId");
  }

  function _throwIfExpired(uint256 listingLinkId) private view {
    require(! isExpired(listingLinkId), "ListingLinkOperator: The listingLink specified is expired");
  }

  function _throwIfSenderIsUnauthorizedBuyer(uint256 listingLinkId) private view {
    require(address(0) == _listingLinks[listingLinkId].buyerAddress || msg.sender == _listingLinks[listingLinkId].buyerAddress, "ListingLinkOperator: This listing is limited and you are not allowed to purchase this NFT");
  }

  function _throwIfMissingApprovalNft(address nftAddress, address nftOwner) private view {
    require(true == _isApprovedNft(nftAddress, nftOwner), "ListingLinkOperator: The operator contract isn't approved to manage caller assets for the NFT contract");
  }

  function _throwIfUnexpectedFailureAtErc721Owning(address nftAddress, uint256 tokenId) private view {
    require(msg.sender == abi.decode(
      Address.functionStaticCall(
        nftAddress,
        abi.encodeWithSignature(
          "ownerOf(uint256)",
          tokenId
        )
      ),
      (address)
    ), "ListingLinkOperator: Failure during NFT ownership control");
  }

  function _throwIfUnexpectedFailureAtErc1155Transfer(address nftAddress, uint256 tokenId, uint256 expectedAmount) private view {
    require(expectedAmount == abi.decode(
      Address.functionStaticCall(
        nftAddress,
        abi.encodeWithSignature(
          "balanceOf(address,uint256)",
          msg.sender,
          tokenId
        )
      ),
      (uint256)
    ), "ListingLinkOperator: Failure during NFT ownership transfer");
  }

  function _throwIfUnexpectedFailureAtErc1155Owning(address nftAddress, uint256 tokenId) private view {
    require(1 <= abi.decode(
      Address.functionStaticCall(
        nftAddress,
        abi.encodeWithSignature(
          "balanceOf(address,uint256)",
          msg.sender,
          tokenId
        )
      ),
      (uint256)
    ), "ListingLinkOperator: Failure during NFT ownership control");
  }

  function _throwIfMissingApprovalFt(address ftAddress, uint256 ftAmount) private view {
    require(ftAmount <= abi.decode(
      Address.functionStaticCall(
        ftAddress,
        abi.encodeWithSignature(
          "allowance(address,address)",
          msg.sender,
          address(this)
        )
      ),
      (uint256)
    ), "ListingLinkOperator: The operator contract isn't allowed to spend enough amount of the asset for the sale");
  }

  // private views
  /**
   * @notice Check that the nftAddress smartcontract is EIP165 compliant
   * and then check and return whose interfaces is compatible
   * is the following list:
   * - ERC721 (0x80ac58cd)
   * - ERC1155 (0xd9b67a26)
   * - ERC2981 (0x2a55205a) (Royalty-support)
   * @param nftAddress The address of the NFT smartcontract to contact
   * @return bool[] corresponding to the supported interfaces. (e.g. [true, false, false] for a simple ERC721 smartcontract)
   * @dev Will throw an error if the address doesn't support ERC-165 and neither ERC721 nor ERC1155 interfaces
   */
  function _getNftSupportedInterfaces(address nftAddress) private view returns (bool[] memory) {
    bytes4[] memory expectedInterfaces = new bytes4[](_SUPPORTED_INTERFACE_COUNT);
    expectedInterfaces[0] = _ERC721_INTERFACE;
    expectedInterfaces[1] = _ERC1155_INTERFACE;
    expectedInterfaces[2] = _ERC2981_INTERFACE;
    bool[] memory supportedInterfaces = ERC165Checker.getSupportedInterfaces(nftAddress, expectedInterfaces);
    require(supportedInterfaces.length == _SUPPORTED_INTERFACE_COUNT && (supportedInterfaces[_ERC721_INTERFACE_IDX] == true || supportedInterfaces[_ERC1155_INTERFACE_IDX] == true), "ListingLinkOperator: nftAddress isn't compatible with ERC721 nor ERC1155");
    return supportedInterfaces;
  }

  /**
   * @notice Get NFT RoyaltyInfo, following the EIP-2918 implementation: https://eips.ethereum.org/EIPS/eip-2981
   * @param nftAddress The address of the NFT smartcontract to contact
   * @param tokenId The tokenId we want to consult
   * @param salePrice As expected by EIP-2981, we send the expected salePrice in order to receive the exact royaltyAmount
   * @return (address, uint256) return the royaltyReceiver address and the royaltyAmount
   * @dev Will throw an error if the royaltyAmount is > to the salePrice, as the implementation seems free enough to produce that unwanted case
   */
  function _getNftRoyaltyInfo(address nftAddress, uint256 tokenId, uint256 salePrice) private view returns (address, uint256) {
    (address royaltyReceiver, uint256 royaltyAmount) = abi.decode(
      Address.functionStaticCall(
        nftAddress,
        abi.encodeWithSignature(
          "royaltyInfo(uint256,uint256)",
          tokenId,
          salePrice
        )
      ),
      (address, uint256)
    );
    require(royaltyAmount <= salePrice, "ListingLinkOperator: Incorrect implementation of ERC2981");

    return (royaltyReceiver, royaltyAmount);
  }

  /**
   * @notice Proceed to the buy/sell transaction by swapping assets (/!\ Untrusted contracts calls /!\)
   * The priority in fees processing follow this logic:
   *    1- Creator royalties applied on the total sell price
   *    2- ListingLink fees applied on the remaining amount (total sell price - creator royalties)
   * @param listingLink The listingLink struct corresponding to the listing we want to execute
   * @dev Call an untrusted contract (NFT contracts)
   * Will throw an error if the effect isn't applied on the NFT side
   * (checked by verifying owner post-call for ERC721; checked by verifying balance before and after call for ERC1155)
   * or if the ERC20 contract failed to perform any transfer (for royalties or seller)
   */
  function _untrustedSwap(ListingLink memory listingLink) private {
    // Fungible Token spending
    uint256 amountToPay = listingLink.ftAmount;

    // Royalty (through a trustable contract)
    if (listingLink.nftRoyaltyAmount > 0) {
      require(true == abi.decode(
        Address.functionCall(
          listingLink.ftAddress,
          abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            msg.sender,
            listingLink.nftRoyaltyReceiver,
            listingLink.nftRoyaltyAmount
          )
        ),
        (bool)
      ), "ListingLinkOperator: Failure during payment of royalty transfer");
      unchecked {
        amountToPay -= listingLink.nftRoyaltyAmount;
      }
    }

    // ListingLink Fee (through a trustable contract)
    uint256 listingLinkFee = _processCommission(amountToPay);
    if (listingLinkFee > 0) {
      require(true == abi.decode(
        Address.functionCall(
          listingLink.ftAddress,
          abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            msg.sender,
            _FEES_ADDRESS_1,
            listingLinkFee
          )
        ),
        (bool)
      ), "ListingLinkOperator: Failure during payment of fees to ListingLink");
      unchecked {
        amountToPay -= listingLinkFee;
      }
    }

    // Payment (through a trustable contract)
    require(true == abi.decode(
      Address.functionCall(
        listingLink.ftAddress,
        abi.encodeWithSignature(
          "transferFrom(address,address,uint256)",
          msg.sender,
          listingLink.sellerAddress,
          amountToPay
        )
      ),
      (bool)
    ), "ListingLinkOperator: Failure during payment transfer");

    // NFT transfer (using untrustable contract)
    if (listingLink.nftType == ERC1155_TYPE) {
      uint256 expectedAmount = abi.decode(
        Address.functionStaticCall(
          listingLink.nftAddress,
          abi.encodeWithSignature(
            "balanceOf(address,uint256)",
            msg.sender,
            listingLink.nftId
          )
        ),
        (uint256)
      );
      // Untrustable call (to an unknown contract)
      Address.functionCall(
        listingLink.nftAddress,
        abi.encodeWithSignature(
          "safeTransferFrom(address,address,uint256,uint256,bytes)",
          listingLink.sellerAddress,
          msg.sender,
          listingLink.nftId,
          1,
          ""
        )
      );
      _throwIfUnexpectedFailureAtErc1155Transfer(listingLink.nftAddress, listingLink.nftId, expectedAmount + 1);
    } else if (listingLink.nftType == ERC721_TYPE) {
      // Untrustable call (to an unknown contract)
      Address.functionCall(
        listingLink.nftAddress,
        abi.encodeWithSignature(
          "safeTransferFrom(address,address,uint256)",
          listingLink.sellerAddress,
          msg.sender,
          listingLink.nftId
        )
      );
      _throwIfUnexpectedFailureAtErc721Owning(listingLink.nftAddress, listingLink.nftId);
    } else {
      revert("ListingLinkOperator: Unexpected nftType");
    }
  }

  /**
   * @notice Check if this contract is approved for the NFT contract
   * @param nftAddress The NFT contract address
   * @param nftOwner The NFT owner address
   * @return bool return if address(this) is an approved operator for the contract and the nftOwner
   */
  function _isApprovedNft(address nftAddress, address nftOwner) private view returns (bool) {
    return abi.decode(
      Address.functionStaticCall(
        nftAddress,
        abi.encodeWithSignature(
          "isApprovedForAll(address,address)",
          nftOwner,
          address(this)
        )
      ),
      (bool)
    );
  }

  /**
   * @notice Calculate the fees over each sales that ListingLink will keep
   * @param salePrice The price sale
   * @return bool return if address(this) is an approved operator for the contract and the nftOwner
   */
  function _processCommission(uint256 salePrice) private pure returns (uint256) {
    unchecked {
      return (salePrice * LISTING_LINK_FEE) / 100;
    }
  }

  /**
   * @notice Convert a delay in days (uint8) to timestamp (uint256)
   * @param dayAmount The amount of days we want to convert
   * @return uint256 the timestamp representing the delay for further calculations
   * @dev Can revert if the requested amount is > 30 or < 1
   */
  function _getExpirationDelay(uint8 dayAmount) private pure returns (uint256) {
    require(dayAmount >= LISTING_EXPIRATION_MIN_DELAY && dayAmount <= LISTING_EXPIRATION_MAX_DELAY, 'ListingLinkOperator: Invalid expiration delay, must be between 1 and 30 days');
    unchecked {
      return dayAmount * 1 days;
    }
  }

  // admin external functions
  function pause() isAdmin external {
    _pause();
  }

  function unpause() isAdmin external {
    _unpause();
  }

  // public functions
    /**
   * @notice Create a new ListingLink
   * @param nftAddress The NFT contract address
   * @param tokenId The NFT tokenId
   * @param ftAddress The fongible token contract address
   * @param ftAmount The sell price
   * @param buyerAddress (optional, set address(0) to ignore) The authorized buyer address
   * @param daysBeforeExpiration (optional, will be 10 days per default) The amount of days before expiration of the listing
   * @return uint256 The created ListingLink ID
   * @dev Will throw an error if the ftAddress isn't a supported contract (WETH, USDC or USDT on Polygon),
   * if this contract isn't an approved operator, if the lister isn't owner of the NFT, or (if present) if the royaltyInfo value isn't correctly implemented
   */
  function createLink(address nftAddress, uint256 tokenId, address ftAddress, uint256 ftAmount, address buyerAddress, uint8 daysBeforeExpiration) public whenNotPaused returns (uint256) {
    _throwIfUnsupportedFungibleTokenContract(ftAddress);
    bool[] memory supportedInterfaces = _getNftSupportedInterfaces(nftAddress);
    _throwIfMissingApprovalNft(nftAddress, msg.sender);
    uint8 nftType = supportedInterfaces[_ERC1155_INTERFACE_IDX] ? ERC1155_TYPE : ERC721_TYPE;
    if (nftType == ERC1155_TYPE) {
      _throwIfUnexpectedFailureAtErc1155Owning(nftAddress, tokenId);
    } else if (nftType == ERC721_TYPE) {
      _throwIfUnexpectedFailureAtErc721Owning(nftAddress, tokenId);
    }
    address nftRoyaltyReceiver = address(0);
    uint256 nftRoyaltyAmount = 0;
    uint256 currentListingLinkId = _listingLinkIdTracker.current();
    if (supportedInterfaces[_ERC2981_INTERFACE_IDX]) {
      // royalty supported
      (nftRoyaltyReceiver, nftRoyaltyAmount) = _getNftRoyaltyInfo(nftAddress, tokenId, ftAmount);
      if (nftRoyaltyReceiver == address(0)) {
        nftRoyaltyAmount = 0;
      }
    }
    _listingLinks[currentListingLinkId] = ListingLink(
      nftAddress,
      tokenId,
      nftType,
      nftRoyaltyReceiver,
      nftRoyaltyAmount,
      ftAddress,
      ftAmount,
      msg.sender,
      buyerAddress,
      block.timestamp + _getExpirationDelay(daysBeforeExpiration),
      false,
      OPEN_CODE
    );
    _allListingLinks.push(currentListingLinkId);
    _listingLinkIdTracker.increment();
    if (buyerAddress == address(0)) {
      emit PublicListingLinkAdded(msg.sender, currentListingLinkId);
    } else {
      emit PrivateListingLinkAdded(msg.sender, currentListingLinkId);
    }
    return currentListingLinkId;
  }

  // external functions
  /**
   * @notice Same as {createLink(address,uint256,address,uint256,address,uint8)}.
   */
  function createLink(address nftAddress, uint256 tokenId, address ftAddress, uint256 ftAmount) external returns (uint256) {
    return createLink(nftAddress, tokenId, ftAddress, ftAmount, address(0), LISTING_EXPIRATION_DEFAULT_DELAY);
  }

  /**
   * @notice Same as {createLink(address,uint256,address,uint256,address,uint8)}.
   */
  function createLink(address nftAddress, uint256 tokenId, address ftAddress, uint256 ftAmount, address buyerAddress) external returns (uint256) {
    return createLink(nftAddress, tokenId, ftAddress, ftAmount, buyerAddress, LISTING_EXPIRATION_DEFAULT_DELAY);
  }

  /**
   * @notice Same as {createLink(address,uint256,address,uint256,address,uint8)}.
   */
  function createLink(address nftAddress, uint256 tokenId, address ftAddress, uint256 ftAmount, uint8 daysBeforeExpiration) external returns (uint256) {
    return createLink(nftAddress, tokenId, ftAddress, ftAmount, address(0), daysBeforeExpiration);
  }

  /**
   * @notice Cancel an existing ListingLink (define the statusCode "CANCEL_BY_OWNER_CODE")
   * @param listingLinkId The ID from the ListingLink to cancel
   * @dev Will throw an error if the listingLink doesn't exist, of if the caller isn't the seller of the ListingLink
   */
  function cancelLink(uint256 listingLinkId) isExisting(listingLinkId) external {
    _throwIfSenderIsNotSeller(listingLinkId);
    _listingLinks[listingLinkId].isClosed = true;
    _listingLinks[listingLinkId].statusCode = CANCEL_BY_OWNER_CODE;
    emit ListingLinkClosed(listingLinkId, CANCEL_BY_OWNER_CODE);
  }

  /**
   * @notice Buy an NFT through an existing ListingLink
   * @param listingLinkId The ID from the ListingLink to cancel
   * @return bool set to TRUE if the transaction correctly occurs, FALSE if this transaction is cancelled due to missing rights on the NFT contract for this contract
   * @dev Will throw an error if:
   * - The ListingLink doesn't exist
   * - The ListingLink is cancelled
   * - The ListingLink is expired
   * - The caller isn't an authorized buyers (if restriction apply on the ListingLink)
   * - The caller didn't allow this contract to spend his fungible token
   * Also, if this contract isn't approved anymore to transfer the NFT, we automatically cancel the listing with a specific statusCode "CANCEL_BY_AUTHORIZATION_REMOVED_CODE"
   * If everying is fine, we perform the {_untrustedSwap(uint256)} action and close succesfully the listingLink
   */
  function buy(uint256 listingLinkId) external whenNotPaused isExisting(listingLinkId) returns (bool) {
    _throwIfClosed(listingLinkId);
    _throwIfExpired(listingLinkId);
    _throwIfSenderIsUnauthorizedBuyer(listingLinkId);
    ListingLink memory listingLink = _listingLinks[listingLinkId];
    if (! _isApprovedNft(listingLink.nftAddress, listingLink.sellerAddress)) {
      _listingLinks[listingLinkId].isClosed = true;
      _listingLinks[listingLinkId].statusCode = CANCEL_BY_AUTHORIZATION_REMOVED_CODE;
      emit ListingLinkClosed(listingLinkId, CANCEL_BY_AUTHORIZATION_REMOVED_CODE);
      return false;
    }
    _throwIfMissingApprovalFt(listingLink.ftAddress, listingLink.ftAmount);
    _listingLinks[listingLinkId].isClosed = true;
    _listingLinks[listingLinkId].statusCode = CLOSED_BY_SUCCESS_CODE;
    _untrustedSwap(listingLink); // Untrusted calls occurs in _swap function
    emit ListingLinkClosed(listingLinkId, CLOSED_BY_SUCCESS_CODE);
    emit ListingLinkSaleSuccess(listingLink.sellerAddress, msg.sender, listingLinkId);
    return true;
  }

  // external views
  function getDetails(uint256 listingLinkId) external view isExisting(listingLinkId) returns (ListingLink memory) {
    return _listingLinks[listingLinkId];
  }

  // public views
  function exist(uint256 listingLinkId) public view returns (bool) {
    return listingLinkId < _listingLinkIdTracker.current();
  }
  function isClosed(uint256 listingLinkId) public view returns (bool) {
    return _listingLinks[listingLinkId].isClosed;
  }
  function isExpired(uint256 listingLinkId) public view isExisting(listingLinkId) returns (bool) {
    return _listingLinks[listingLinkId].expirationTimestamp <= block.timestamp;
  }
}