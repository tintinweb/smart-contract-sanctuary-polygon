//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

interface NftContractInterFace {
  function getCreator(uint256) external view returns (address);
}

contract AlterShop is
  Initializable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC2771Recipient
{
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;
  uint256 private _marketplaceFee;
  uint256 private _royaltyFee;
  uint256 private _listingId;
  uint256 private _openListings;
  uint256 public generalNoOfFreeList;

  enum State {
    DEFAULT,
    INITIATED,
    SOLD,
    CANCELLED
  }

  struct Listing {
    uint256 listingId;
    bool isErc721;
    State state;
    address nftAddress;
    address seller;
    address[] creators;
    address erc20Address;
    uint256[] tokenIds;
    uint256 amount;
    uint256 price;
    address buyer;
  }

  mapping(uint256 => Listing) public _listings;
  mapping(address => uint256) private noOfFreeListingsPerWallet;

  struct AllowedContractsList {
    address contractAddress;
    string contractName;
    bool isValid;
  }

  mapping(address => AllowedContractsList) public _allAcceptableContracts;

  /**
   * @dev Emitted when new listing is created by the owner of the contract. Amount is valid only for ERC-1155 tokens
   */
  event ListingCreated(
    bool isErc721,
    address indexed seller,
    address[] creators,
    address nftAddress,
    uint256[] tokenIds,
    uint256 listingId,
    uint256 amount,
    uint256 price,
    address erc20Address,
    uint256 updatedTimeStamp,
    string assetId
  );

  event AllowedContractsAdded(
    address indexed contractAddress,
    string contractName
  );

  /**
   * @dev Emitted when listing assets were sold.
   */
  event ListingSold(
    address indexed buyer,
    address seller,
    address[] creators,
    uint256 indexed listingId,
    uint256 updatedTimeStamp,
    string assetId
  );

  /**
   * @dev Emitted when listing was cancelled and assets were returned to the seller.
   */
  event ListingCancelled(
    uint256 indexed listingId,
    address seller,
    uint256 updatedTimeStamp,
    string assetId
  );

  event ListingPriceUpdation(
    uint256 indexed listingId,
    uint256 price,
    uint256 updatedTimeStamp,
    string assetId
  );

  function initialize(
    uint256 _feePercent,
    uint256 _royaltyPercent,
    address _trustForwarderAddress
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    _setTrustedForwarder(_trustForwarderAddress);
    _marketplaceFee = _feePercent;
    _royaltyFee = _royaltyPercent;
    _listingId = 1;
    generalNoOfFreeList = 10;
  }

  function _msgSender()
    internal
    view
    override(ContextUpgradeable, ERC2771Recipient)
    returns (address sender)
  {
    sender = ERC2771Recipient._msgSender();
  }

  function _msgData()
    internal
    view
    override(ContextUpgradeable, ERC2771Recipient)
    returns (bytes memory)
  {
    return ERC2771Recipient._msgData();
  }

  function setTrustForwarder(address _trustedForwarder)
    public
    virtual
    onlyOwner
  {
    _setTrustedForwarder(_trustedForwarder);
  }

  function versionRecipient() external pure returns (string memory) {
    return "1";
  }

  function getMarketplaceFeePercentage() public view virtual returns (uint256) {
    return _marketplaceFee;
  }

  function getRoyaltyPercentage() public view virtual returns (uint256) {
    return _royaltyFee;
  }

  function getListing(uint256 listingId)
    public
    view
    virtual
    returns (Listing memory)
  {
    return _listings[listingId];
  }

  function getOwner() public view returns (address) {
    return OwnableUpgradeable.owner();
  }

  function getTotalOpenListings() public view virtual returns (uint256) {
    return _openListings;
  }

  function setMarketplaceFee(uint256 fee) public virtual onlyOwner {
    _marketplaceFee = fee;
  }

  function setgeneralNoOfFreeList(uint256 _freeMints) public virtual onlyOwner {
    generalNoOfFreeList = _freeMints;
  }

  function setRoyaltyFee(uint256 fee) public virtual onlyOwner {
    _royaltyFee = fee;
  }

  function CheckfreeListWallet(address _address) public view returns (bool) {
    if (noOfFreeListingsPerWallet[_address] >= generalNoOfFreeList)
      return false;
    return true;
  }

  function CheckFreeListsAvailablePerWallet(address _address)
    public
    view
    returns (uint256)
  {
    return generalNoOfFreeList - noOfFreeListingsPerWallet[_address];
  }

  function getListings() public view returns (Listing[] memory) {
    Listing[] memory listings = new Listing[](_listingId - 1);
    for (uint256 i; i < _listingId - 1; i++) {
      Listing memory listing = _listings[i];
      listings[i] = listing;
    }
    return listings;
  }

  function getOpenListings() public view returns (Listing[] memory) {
    Listing[] memory openListings = new Listing[](_openListings);
    uint256 openListingIndex;
    for (uint256 i; i < _listingId - 1; i++) {
      Listing memory listing = _listings[i];
      if (listing.state == State.INITIATED) {
        openListings[openListingIndex] = listing;
        openListingIndex;
      }
    }
    return openListings;
  }

  function addAcceptableContracts(
    address contractAddress,
    string memory contractName
  ) public virtual nonReentrant {
    if (
      keccak256(
        abi.encodePacked(
          _allAcceptableContracts[contractAddress].contractAddress
        )
      ) == keccak256(abi.encodePacked(contractAddress))
    ) {
      revert("Contract address already added");
    }

    AllowedContractsList memory newContract = AllowedContractsList(
      contractAddress,
      contractName,
      true
    );
    _allAcceptableContracts[contractAddress] = newContract;

    emit AllowedContractsAdded(contractAddress, contractName);
  }

  function isAcceptableContract(address contractAddress)
    public
    view
    returns (bool)
  {
    if (_allAcceptableContracts[contractAddress].isValid) {
      return true;
    }
    return false;
  }

  /*
   * @operation Create new listing of the NFT token in the marketplace.
   * @param listingId - ID of the listing, must be unique
   * @param isErc721 - whether the listing is for ERC721 or ERC1155 token
   * @param nftAddress - address of the NFT token
   * @param tokenId - ID of the NFT token
   * @param price - Price for the token. It could be in wei or smallest ERC20 value, if @param erc20Address is not 0x0 address
   * @param amount - ERC1155 only, number of tokens to sold.
   * @param erc20Address - address of the ERC20 token, which will be used for the payment. If native asset is used, this should be 0x0 address
   */

  function createListing(
    bool isErc721,
    address nftAddress,
    uint256[] memory tokenIds,
    uint256 price,
    uint256 amount,
    address erc20Address,
    string memory assetId,
    uint256[] memory listingIds
  ) public nonReentrant {
    require(
      isAcceptableContract(nftAddress),
      "Nft Contract is not an acceptable contract"
    );
    for (uint256 i; i < listingIds.length; i++) {
      if (
        _listings[listingIds[i]].state == State.INITIATED &&
        _listings[listingIds[i]].seller == _msgSender()
      ) {
        require(
          _listings[listingIds[i]].tokenIds.length == 1,
          "Asset already listed as a structure"
        );

        if (_listings[listingIds[i]].isErc721) {
          IERC721Upgradeable(_listings[listingIds[i]].nftAddress)
            .safeTransferFrom(
              address(this),
              _msgSender(),
              _listings[listingIds[i]].tokenIds[0],
              abi.encodePacked(
                "SafeTransferFrom",
                "'''###'''",
                StringsUpgradeable.toString(_listings[listingIds[i]].price)
              )
            );
        } else {
          IERC1155Upgradeable(_listings[listingIds[i]].nftAddress)
            .safeTransferFrom(
              address(this),
              _msgSender(),
              _listings[listingIds[i]].tokenIds[0],
              _listings[listingIds[i]].amount,
              ""
            );
        }
        _listings[listingIds[i]].state = State.CANCELLED;
        _openListings--;
      }
    }

    if (!isErc721) {
      require(amount > 0);
      for (uint256 i; i < tokenIds.length; i++) {
        require(
          IERC1155Upgradeable(nftAddress).balanceOf(_msgSender(), tokenIds[i]) >=
            amount,
          "ERC1155 token balance is not sufficient for the seller.."
        );
      }
    } else {
      for (uint256 i; i < tokenIds.length; i++) {
        require(
          IERC721Upgradeable(nftAddress).ownerOf(tokenIds[i]) == _msgSender(),
          "ERC721 token does not belong to the author."
        );
      }
    }

    address[] memory _creators = new address[](tokenIds.length);

    for (uint256 i; i < tokenIds.length; i++) {
      _creators[i] = NftContractInterFace(nftAddress).getCreator(tokenIds[i]);
    }

    if (isErc721) {
      for (uint256 i; i < tokenIds.length; i++) {
        IERC721Upgradeable(nftAddress).safeTransferFrom(
          _msgSender(),
          address(this),
          tokenIds[i],
          abi.encodePacked(
            "SafeTransferFrom",
            "'''###'''",
            StringsUpgradeable.toString(price)
          )
        );
      }
    } else {
      for (uint256 i; i < tokenIds.length; i++) {
        IERC1155Upgradeable(nftAddress).safeTransferFrom(
          _msgSender(),
          address(this),
          tokenIds[i],
          amount,
          ""
        );
      }
    }

    Listing memory listing = Listing(
      _listingId,
      isErc721,
      State.INITIATED,
      nftAddress,
      _msgSender(),
      _creators,
      erc20Address,
      tokenIds,
      amount,
      price,
      address(0)
    );
    _listings[_listingId] = listing;
    _openListings++;
    noOfFreeListingsPerWallet[_msgSender()] += 1;

    emit ListingCreated(
      isErc721,
      _msgSender(),
      _creators,
      nftAddress,
      tokenIds,
      _listingId,
      amount,
      price,
      erc20Address,
      block.timestamp,
      assetId
    );
    _listingId++;
  }

  /*
   * @operation Buyer wants to buy NFT from listing. All the required checks must pass.
   * Buyer must either send MATIC with this endpoint, or ERC20 tokens will be deducted from his account to the marketplace contract.
   * @param listingId - id of the listing to buy
   * @param erc20Address - optional address of the ERC20 token to pay for the assets, if listing is listed in ERC20
   */
  function buyAssetFromListing(
    uint256 listingId,
    address erc20Address,
    string memory assetId
  ) public payable nonReentrant {
    Listing memory listing = _listings[listingId];

    require(
      listing.state == State.INITIATED,
      "Listing is in wrong state. Aborting."
    );

    if (listing.isErc721) {
      for (uint256 i; i < listing.tokenIds.length; i++) {
        if (
          IERC721Upgradeable(listing.nftAddress).ownerOf(listing.tokenIds[i]) !=
          address(this)
        ) {
          revert(
            "Asset is not owned by this listing. Probably was not sent to the smart contract, or was already sold."
          );
        }
      }
    } else {
      for (uint256 i; i < listing.tokenIds.length; i++) {
        if (
          IERC1155Upgradeable(listing.nftAddress).balanceOf(
            address(this),
            listing.tokenIds[i]
          ) < listing.amount
        ) {
          revert(
            "Insufficient balance of the asset in this listing. Probably was not sent to the smart contract, or was already sold."
          );
        }
      }
    }
    if (listing.erc20Address != erc20Address) {
      revert(
        "ERC20 token address as a payer method should be the same as in the listing. Either listing, or method call has wrong ERC20 address."
      );
    }
    uint256 fee = (listing.price * _marketplaceFee) / 100000000000000000000;
    uint256 royalityFee = ((listing.price * _royaltyFee) /
      100000000000000000000) / listing.tokenIds.length;

    listing.state = State.SOLD;
    listing.buyer = _msgSender();
    _listings[listingId] = listing;
    _openListings--;

    if (listing.erc20Address == address(0)) {
      if (listing.price > msg.value) {
        revert("Insufficient price paid for the asset.");
      }

      AddressUpgradeable.sendValue(payable(address(this)), fee);
      for (uint256 i; i < listing.tokenIds.length; i++) {
        AddressUpgradeable.sendValue(payable(listing.creators[i]), royalityFee);
      }

      AddressUpgradeable.sendValue(
        payable(listing.seller),
        listing.price - fee - royalityFee
      );
      // Overpaid price is returned back to the sender
      if (msg.value - listing.price > 0) {
        AddressUpgradeable.sendValue(
          payable(_msgSender()),
          msg.value - listing.price
        );
      }
      if (listing.isErc721) {
        for (uint256 i; i < listing.tokenIds.length; i++) {
          IERC721Upgradeable(listing.nftAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            listing.tokenIds[i],
            abi.encodePacked(
              "SafeTransferFrom",
              "'''###'''",
              StringsUpgradeable.toString(listing.price)
            )
          );
        }
      } else {
        for (uint256 i; i < listing.tokenIds.length; i++) {
          IERC1155Upgradeable(listing.nftAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            listing.tokenIds[i],
            listing.amount,
            ""
          );
        }
      }
    } else {
      IERC20Upgradeable token = IERC20Upgradeable(listing.erc20Address);
      if (listing.price > token.allowance(_msgSender(), address(this))) {
        revert(
          "Insufficient ERC20 allowance balance for paying for the asset."
        );
      }
      token.transferFrom(_msgSender(), address(this), fee);
      for (uint256 i; i < listing.tokenIds.length; i++) {
        AddressUpgradeable.sendValue(payable(listing.creators[i]), royalityFee);
        token.transferFrom(_msgSender(), listing.creators[i], royalityFee);
      }

      token.transferFrom(
        _msgSender(),
        listing.seller,
        listing.price - fee - royalityFee
      );
      if (listing.isErc721) {
        bytes memory bytesInput = abi.encodePacked(
          "CUSTOMTOKEN0x",
          _toAsciiString(listing.erc20Address),
          "'''###'''",
          StringsUpgradeable.toString(listing.price)
        );
        for (uint256 i; i < listing.tokenIds.length; i++) {
          IERC721Upgradeable(listing.nftAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            listing.tokenIds[i],
            bytesInput
          );
        }
      } else {
        for (uint256 i; i < listing.tokenIds.length; i++) {
          IERC1155Upgradeable(listing.nftAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            listing.tokenIds[i],
            listing.amount,
            ""
          );
        }
      }
    }

    emit ListingSold(
      _msgSender(),
      listing.seller,
      listing.creators,
      listingId,
      block.timestamp,
      assetId
    );
  }

  function cancelListing(uint256 listingId, string memory assetId)
    public
    virtual
    nonReentrant
  {
    Listing memory listing = _listings[listingId];
    require(
      listing.state == State.INITIATED,
      "Listing is not in INITIATED state. Aborting."
    );
    require(
      listing.seller == _msgSender() || _msgSender() == owner(),
      "Listing can't be cancelled from other then seller or owner. Aborting."
    );
    if (listing.isErc721) {
      for (uint256 i; i < listing.tokenIds.length; i++) {
        IERC721Upgradeable(listing.nftAddress).safeTransferFrom(
          address(this),
          _msgSender(),
          listing.tokenIds[i],
          abi.encodePacked(
            "SafeTransferFrom",
            "'''###'''",
            StringsUpgradeable.toString(listing.price)
          )
        );
      }
    } else {
      for (uint256 i; i < listing.tokenIds.length; i++) {
        IERC1155Upgradeable(listing.nftAddress).safeTransferFrom(
          address(this),
          _msgSender(),
          listing.tokenIds[i],
          listing.amount,
          ""
        );
      }
    }
    listing.state = State.CANCELLED;
    _listings[listingId] = listing;
    _openListings--;

    emit ListingCancelled(listingId, listing.seller, block.timestamp, assetId);
  }

  function updateListingPrice(
    uint256 listingId,
    uint256 _price,
    string memory assetId
  ) public virtual nonReentrant {
    Listing memory listing = _listings[listingId];
    require(
      listing.state == State.INITIATED,
      "Listing is not in INITIATED state. Aborting."
    );
    require(
      listing.seller == _msgSender(),
      "Listing can be modified only by sellers. Aborting."
    );
    listing.price = _price;
    _listings[listingId] = listing;
    emit ListingPriceUpdation(listingId, _price, block.timestamp, assetId);
  }

  function getBalance() public view onlyOwner returns (uint256) {
    return address(this).balance;
  }

  function withdraw() external virtual onlyOwner {
    // This will transfer the remaining contract balance to the owner (contractOwner address).
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = _msgSender().call{ value: address(this).balance }("");
    require(os, "Failed to withdraw funds");
    // =============================================================================
  }

  function _toAsciiString(address x) internal pure returns (bytes memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = _char(hi);
      s[2 * i + 1] = _char(lo);
    }
    return s;
  }

  function _char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  receive() external payable {}

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual returns (bytes4) {
    return this.onERC721Received.selector;
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}