/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IModule {
  function getModule(uint256 module_) external view returns (address);
}

interface IRoles {
  function isVerifiedUser(address user_) external returns (bool);

  function isModerator(address user_) external returns (bool);

  function isAdmin(address user_) external returns (bool);

  function isUser(address user_) external returns (bool);
}

interface ICollections {
  function hasOwnershipOf(
    uint256 collection_,
    uint256 tokenId_,
    address owner_
  ) external view returns (bool);

  function setApprovalForAll(address operator, bool approval) external;

  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 collection,
    uint256 id,
    bytes memory data
  ) external;
}

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

/**
 * @notice The interface to implement in the market contract
 */
interface IMarket {
  /**
   * @notice Struct created when a NFT is listed for a fixed price
   * @param active If this offer is active or not
   * @param minBid Min bid valid
   * @param collection NFT collection. If the token is ERC721, set to 0
   * @param tokenId Token id (in the collection given)
   * @param value Value required to complete the offer
   * @param collectionAddress Address of the NFT
   * @param paymentToken Token to accept for the listing
   * @param seller The address that sells the NFT (owner or approved)
   * @dev If the paymentToken is address(0), pays in native token
   */
  struct Offer {
    bool active;
    bool isAuction;
    uint256 endTime;
    uint256 minBid;
    uint256[] collections;
    uint256[] tokenIds;
    uint256 value;
    address[] collectionAddresses;
    address paymentToken;
    address seller;
  }

  /**
   * @notice Struct created when a NFT is listed for a fixed price
   * @param id Fixed offer id
   * @param isAuction If the offer is an auction
   * @param collections NFT collection. If the token is ERC721, set to 0
   * @param tokenIds Token id (in the collection given)
   * @param value Value required to complete the offer
   * @param collectionAddresses Address of the NFT
   * @param paymentToken Token to accept for the listing
   * @param seller The address that sells the NFT (owner or approved)
   * @dev If the paymentToken is address(0), pays in native token
   */
  event OfferCreated(
    uint256 id,
    bool isAuction,
    uint256[] collections,
    uint256[] tokenIds,
    uint256 value,
    address[] collectionAddresses,
    address paymentToken,
    address seller
  );

  /**
   * @notice When an offer is completed
   * @param seller The address that sells the NFT (owner or approved)
   * @param buyer Who bought the offer
   * @param collectionAddresses Contract addresses of the tokens selled
   * @param collections Collection
   */
  event OfferCompleted(
    bool isAuction,
    address seller,
    address buyer,
    address[] collectionAddresses,
    uint256[] collections,
    uint256[] tokenIds,
    uint256 value
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

  /**
   * @notice Creates a fixed offer
   * @param isAuction_ If the offer is an auction
   * @param endTime If it is an auction, the time to be valid
   * @param minBid_ If it is an auction, min bid valid
   * @param collections_ NFT collection. If the token is ERC721, set to 0
   * @param tokenIds_ Token id (in the collection given)
   * @param value_ Value required to complete the offer
   * @param collectionAddresses_ Address of the NFT
   * @param paymentToken_ Token to accept for the listing
   * @dev If the paymentToken is address(0), pays in native token
   */
  function createOffer(
    bool isAuction_,
    uint256 endTime,
    uint256 minBid_,
    uint256[] memory collections_,
    uint256[] memory tokenIds_,
    uint256 value_,
    address[] memory collectionAddresses_,
    address paymentToken_
  ) external;
}

/**
 * @notice Market logic
 */
contract Market is IMarket {
  /**
   * @notice List of offers
   */
  mapping(uint256 => Offer) public offersList;

  /**
   * @notice Winner of the auction
   */
  mapping(uint256 => address) public winner;

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
   * @notice List of approved offers
   */
  mapping(uint256 => bool) public approvedOffers;

  /**
   * @notice If the ERC20 is a valid token to accept
   */
  mapping(address => bool) public validERC20;

  /**
   * @notice Event for when someone bid in an auction
   */
  event BidForAuction(address who, uint256 offerId, uint256 amount);

  /**
   * @notice Only offers that are approved by a moderator/admin
   * @param offerId_ Offer id to check if approved
   */
  modifier onlyApprovedOffers(uint256 offerId_) {
    require(
      (approvedOffers[offerId_] == true) || (rolesContract.isVerifiedUser(offersList[offerId_].seller)),
    "M101");
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
    uint256 endTime_,
    uint256 minBid_,
    uint256[] memory collections_,
    uint256[] memory tokenIds_,
    uint256 value_,
    address[] memory collectionAddresses_,
    address paymentToken_
  ) public {
    require(
      rolesContract.isUser(msg.sender) ||
        rolesContract.isVerifiedUser(msg.sender),
      "E811"
    );
    require(
      (collections_.length == tokenIds_.length) &&
        (collections_.length == collectionAddresses_.length),
      "E806"
    );
    require((value_ > 0) && (isValidERC20(paymentToken_)), "M102");
    if (isAuction_)
      require(
        (endTime_ > block.timestamp + 3600) && (value_ > minBid_),
        "M103"
      );

    // Check for ownership and approved
    for (uint256 i = 0; i < collectionAddresses_.length; i++) {
      if (collectionAddresses_[i] == tokenAddress) {
        require(
          tokenContract.hasOwnershipOf(
            collections_[i],
            tokenIds_[i],
            msg.sender
          ),
          "M104"
        );
        require(
          tokenContract.isApprovedForAll(msg.sender, address(this)),
          "M105"
        );
      } else {
        require(
          IERC721(collectionAddresses_[i]).ownerOf(tokenIds_[i]) ==
            msg.sender,
          "E413"
        );
        require(
          IERC721(collectionAddresses_[i]).getApproved(
            tokenIds_[i]
          ) != address(this),
          "E407"
        );
      }
    }

    // Create offer
    offersList[offersCount] = Offer(
      true, // active
      isAuction_,
      endTime_,
      minBid_,
      collections_,
      tokenIds_,
      value_,
      collectionAddresses_,
      paymentToken_,
      msg.sender //seller
    );
    emit OfferCreated(
      offersCount,
      isAuction_,
      collections_,
      tokenIds_,
      value_,
      collectionAddresses_,
      paymentToken_,
      msg.sender
    );
    offersCount++;
  }

  /**
   * @notice For buying a fixed offer & closing an auction
   * @param offerId_ The offer to buy
   * @dev Requires ERC20 allowance
   */
  function buyOffer(uint256 offerId_)
    public
    payable
    onlyApprovedOffers(offerId_)
  {
    Offer storage offer = offersList[offerId_];
    if (offer.isAuction) {
      // Check if caller is the winner and if it is ended
      require(!validateAuctionTime(offerId_), ""); ////////////////////////////////////////////FALTA COD ERROR
      require(msg.sender == winner[offerId_], "");
    }
    require(offer.active, ""); ///////////////////////////////////////////////////////////////////falta cod error
    if (offer.paymentToken == address(0)) {
      // Not enought sended
      require(msg.value >= offer.value, "");
    } else {
      // Not enought allowance
      require(
        IERC20(offer.paymentToken).allowance(
          msg.sender,
          address(this)
        ) >= offer.value,
        ""
      );
    }
    // Set the offer as inactive
    offer.active = false;

    // Send funds to user
    sendFunds(offerId_);

    // Transact all tokens
    for (uint256 i = 0; i < offer.collectionAddresses.length; i++) {
      if (offer.collectionAddresses[i] == tokenAddress) {
        require(
          tokenContract.isApprovedForAll(offer.seller, address(this)),
          ""
        );
        tokenContract.safeTransferFrom(
          offer.seller,
          msg.sender,
          offer.collections[i],
          offer.tokenIds[i],
          ""
        );
      } else {
        require(
          IERC721(offer.collectionAddresses[i]).getApproved(
            offer.tokenIds[i]
          ) == address(this),
          ""
        );
        IERC721(offer.collectionAddresses[i]).safeTransferFrom(
          offer.seller,
          msg.sender,
          offer.tokenIds[i]
        );
      }
    }

    // Emit event
    emit OfferCompleted(
      offer.isAuction,
      offer.seller,
      msg.sender,
      offer.collectionAddresses,
      offer.collections,
      offer.tokenIds,
      offer.value
    );
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
        value: offersList[offerId_].value
      }("");
      require(success, ""); ////////////////////////////////////////////////////////////////////////////FALTA COD
    } else
      IERC20(offersList[offerId_].paymentToken).transferFrom(
        msg.sender,
        offersList[offerId_].seller,
        offersList[offerId_].value
      );
  }

  /**
   * @notice This is made to approve a valid offer
   * @param offerId_ The offer id to validate
   */
  function approveOffer(uint256 offerId_) public {
    require(rolesContract.isModerator(msg.sender), "");
    require(offersList[offerId_].active, "");
    approvedOffers[offerId_] = true;
    emit OfferApproved(offerId_);
  }

  /**
   * @notice Deprecate offer, it does not matter if it is a fixed offer or an auction
   * @param offerId_ The offer id to deprecate
   */
  function deprecateOffer(uint256 offerId_) public {
    require(rolesContract.isModerator(msg.sender), "");
    offersList[offerId_].active = false;
    emit OfferCancelled(offerId_);
  }

  /**
   * @notice Bid for an auction
   * @param offerId_ The auction
   * @param value_ The value to bid
   */
  function bidForAuction(uint256 offerId_, uint256 value_)
    public
    onlyApprovedOffers(offerId_)
  {
    require(offersList[offerId_].active, '');
    require(offersList[offerId_].isAuction, '');
    require((value_ > 0) || (offersList[offerId_].minBid < value_), '');
    require(validateAuctionTime(offerId_));

    if (offersList[offerId_].paymentToken == address(0)) {
      require(value_ < msg.sender.balance, "");
    } else {
      require(value_ < IERC20(offersList[offerId_].paymentToken).balanceOf(msg.sender), '');
    }
    offersList[offerId_].minBid = value_;
    winner[offerId_] = msg.sender;
    // Emit event
    emit BidForAuction(msg.sender, offerId_, value_);
  }

  /**
   * @notice Get offer info
   * @param offerId_ Offer to get info from
   * @return All the info from the offer given
   * @dev Revert if offerId is an inexistent offer
   */
  function getOfferInfo(uint256 offerId_)
    public
    view
    returns (
      bool,
      uint256,
      address[] memory,
      uint256[] memory,
      uint256[] memory,
      address,
      uint256
    )
  {
    // Validate if offer exists
    require(offerId_ < offersCount, "");
    return (
      offersList[offerId_].isAuction
        ? validateAuctionTime(offerId_)
        : offersList[offerId_].active,
      offersList[offerId_].endTime,
      offersList[offerId_].collectionAddresses,
      offersList[offerId_].collections,
      offersList[offerId_].tokenIds,
      offersList[offerId_].paymentToken,
      offersList[offerId_].value
    );
  }

  /**
   * @notice Validates if an auction is still valid or not
   * @param offerId_ The auction
   * @return valid if it is valid or not
   */
  function validateAuctionTime(uint256 offerId_) public view returns (bool) {
    require(offersList[offerId_].isAuction, "");
    return offersList[offerId_].endTime > block.timestamp;
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
  function validateERC20(address token_, bool validated_) public {
    require(msg.sender == moduleManager.getModule(3), "");
    validERC20[token_] = validated_;
    ////// Emit event
  }

  // Crear function SET WINNER (para cambiar el winner de la subasta si el WINNER se gastó los fondos
  // function setAsWinner(address bidder_) public onlyModerators {}
}