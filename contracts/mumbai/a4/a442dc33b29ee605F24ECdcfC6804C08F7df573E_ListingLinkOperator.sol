// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

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
  address private constant _WETH_POLYGON_CONTRACT = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1; // Wrapped-ETH (WETH) contract on Polygon Network
  address private constant _USDT_POLYGON_CONTRACT = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1; // Tether (USDT) contract on Polygon Network
  address private constant _USDC_POLYGON_CONTRACT = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1; // USD Coin (USDC) contract on Polygon Network

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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