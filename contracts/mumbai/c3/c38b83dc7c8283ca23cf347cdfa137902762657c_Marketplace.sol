// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct EIP712Listing {
  address owner;
  // enum listingType { HUNTER, ARTIFACT, SHARD, EQUIPMENT }
  uint256 listingType;
  uint256 id;
  uint256 amount;
  uint256 price;
  uint256 expiryTimestamp;
  uint256 nonce;
}

bytes32 constant EIP712LISTING_SIGNATURE = keccak256(
  "EIP712Listing(address owner,uint256 listingType,uint256 id,uint256 amount,uint256 price,uint256 expiryTimestamp,uint256 nonce)"
);

struct ERC721Listing {
  bool active;
  uint256 price;
}

struct ERC1155Listing {
  bool active;
  address owner;
  uint256 id;
  uint256 amount;
  uint256 price;
}

/// @title Marketplace
/// @notice List, buy, sell, lend and borrow game assets
/// @author zetsub0ii.eth
contract Marketplace is AccessControl, Pausable, EIP712 {
  bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 constant PLATFORM_ROLE = keccak256("PLATFORM_ROLE");

  IERC20 public immutable bgem;
  IERC20 public immutable boom;
  IERC721 public immutable hunters;
  IERC1155 public immutable artifacts;
  IERC1155 public immutable equipments;
  IERC1155 public immutable shards;

  address private studio;

  // Base precision of 10**5 gives us 3 decimals to work with
  uint256 constant BASE_PRECISION = 100_000;

  // All initialized to 0
  uint256 artifactCounter;
  uint256 shardCounter;
  uint256 equipmentCounter;
  uint256 studioBalance;
  uint256 studioCommission;
  uint256 boomCut; // Must be between [0, 100*BASE_PRECISION]

  // Hunter ID => Listing
  mapping(uint256 => ERC721Listing) public hunterListings;

  // Listing Hash => Listing
  mapping(uint256 => ERC1155Listing) public artifactListings;
  mapping(uint256 => ERC1155Listing) public shardListings;
  mapping(uint256 => ERC1155Listing) public equipmentListings;

  // ERC1155 Address => ListedAmount
  mapping(IERC1155 => mapping(address => uint256)) public erc1155ListingAmts;

  // Used signatures, as we can't use the same signature twice
  mapping(bytes => bool) public usedSignatures;

  mapping(uint256 => uint256) public accruedBoomCut;

  // Events
  event HunterListed(address lister, uint256 id, uint256 price);
  event HunterPriceChanged(uint256 id, uint256 newPrice);
  event HunterDelisted(uint256 id);
  event HunterBought(uint256 id, uint256 price);

  event ArtifactListed(
    uint256 listingHash, address user, uint256 id, uint256 amount, uint256 price
  );
  event ArtifactPriceChanged(uint256 listingHash, uint256 newPrice);
  event ArtifactDelisted(uint256 listingHash);
  event ArtifactBought(uint256 listingHash, uint256 price);

  event EquipmentListed(
    uint256 listingHash, address user, uint256 id, uint256 amount, uint256 price
  );
  event EquipmentPriceChanged(uint256 listingHash, uint256 newPrice);
  event EquipmentDelisted(uint256 listingHash);
  event EquipmentBought(uint256 listingHash, uint256 price);

  event ShardListed(uint256 listingHash, address user, uint256 id, uint256 amount, uint256 price);
  event ShardPriceChanged(uint256 listingHash, uint256 newPrice);
  event ShardDelisted(uint256 listingHash);
  event ShardBought(uint256 listingHash, uint256 price);

  //	 ██████╗███╗   ██╗███████╗████████╗ ██████╗ ██████╗
  //	██╔════╝████╗  ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
  //	██║     ██╔██╗ ██║███████╗   ██║   ██║   ██║██████╔╝
  //	██║     ██║╚██╗██║╚════██║   ██║   ██║   ██║██╔══██╗
  //	╚██████╗██║ ╚████║███████║   ██║   ╚██████╔╝██║  ██║
  //	 ╚═════╝╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

  constructor(
    address initStudio,
    IERC20 initBgem,
    IERC20 initBoom,
    IERC721 initHunters,
    IERC1155 initArtifacts,
    IERC1155 initShards,
    IERC1155 initEquipments,
    uint256 initCommission,
    uint256 initBoomCut
  ) EIP712("BoombitMarketplace", "1") {
    studio = initStudio;
    bgem = initBgem;
    boom = initBoom;
    hunters = initHunters;
    artifacts = initArtifacts;
    shards = initShards;
    equipments = initEquipments;
    studioCommission = initCommission;

    require(
      boomCut <= 100 * BASE_PRECISION, "Boom cut must be less or equal than 100 * BASE_PRECISION"
    );
    boomCut = initBoomCut;
  }

  //	███████╗███████╗████████╗████████╗███████╗██████╗ ███████╗
  //	██╔════╝██╔════╝╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝
  //	███████╗█████╗     ██║      ██║   █████╗  ██████╔╝███████╗
  //	╚════██║██╔══╝     ██║      ██║   ██╔══╝  ██╔══██╗╚════██║
  //	███████║███████╗   ██║      ██║   ███████╗██║  ██║███████║
  //	╚══════╝╚══════╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝

  function setStudio(address newStudio) external onlyRole(PLATFORM_ROLE) {
    studio = newStudio;
  }

  function setCommission(uint256 newCommission) external onlyRole(PLATFORM_ROLE) {
    studioCommission = newCommission;
  }

  function setBoomCut(uint256 newBoomCut) external onlyRole(PLATFORM_ROLE) {
    require(
      newBoomCut <= 100 * BASE_PRECISION, "boomCut must be less or equal than 100 * BASE_PRECISION"
    );
    boomCut = newBoomCut;
  }

  /// @notice Pauses the contract
  /// @dev Requires PAUSER_ROLE
  function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
    _pause();
  }

  /// @notice Resumes the contract
  /// @dev Requires PAUSER_ROLE
  function resume() external onlyRole(PAUSER_ROLE) whenPaused {
    _unpause();
  }

  //	██╗     ██╗███████╗████████╗
  //	██║     ██║██╔════╝╚══██╔══╝
  //	██║     ██║███████╗   ██║
  //	██║     ██║╚════██║   ██║
  //	███████╗██║███████║   ██║
  //	╚══════╝╚═╝╚══════╝   ╚═╝

  /// @notice Lists a hunter
  /// @param hunterId ID of the hunter
  /// @param price    Price of the listing
  function listHunter(uint256 hunterId, uint256 price) external whenNotPaused {
    require(!hunterListings[hunterId].active, "Hunter is already on sale");
    require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the asset");

    hunterListings[hunterId] = ERC721Listing({active: true, price: price});

    emit HunterListed(msg.sender, hunterId, price);
  }

  /// @notice Lists an artifact
  /// @param artifactId ID of the aritfact
  /// @param amount Amount of aritfacts
  /// @param price  Price of the listing
  function listArtifact(uint256 artifactId, uint256 amount, uint256 price) external whenNotPaused {
    uint256 availableBalance =
      artifacts.balanceOf(msg.sender, artifactId) - erc1155ListingAmts[artifacts][msg.sender];

    require(availableBalance >= amount, "Not enough of asset");

    // Since ERC1155 are fungible we can't store listing info the way we
    // store ERC721 hunters. We'll produce a listing hash using information
    // about the listing. Timestamp and the owner should be enough, but keep
    // in mind that if user were to create the same listing (id and amount)
    // within the same timestamp would fail as it'd create the same hash.
    uint256 listingHash =
      uint256(keccak256(abi.encodePacked(artifactId, amount, tx.origin, block.timestamp)));
    require(!artifactListings[listingHash].active, "Already on sale");

    artifactListings[listingHash] = ERC1155Listing({
      active: true,
      id: artifactId,
      owner: msg.sender,
      amount: amount,
      price: price
    });
    erc1155ListingAmts[artifacts][msg.sender] += amount;

    emit ArtifactListed(listingHash, msg.sender, artifactId, amount, price);
  }

  /// @notice Lists a equipment
  /// @param equipmentId ID of the equipment
  /// @param amount Amount of equipments
  /// @param price  Price of the listing
  function listEquipment(uint256 equipmentId, uint256 amount, uint256 price) external whenNotPaused {
    uint256 availableBalance =
      equipments.balanceOf(msg.sender, equipmentId) - erc1155ListingAmts[equipments][msg.sender];
    require(availableBalance >= amount, "Not enough of asset");

    // see listArtifact
    uint256 listingHash =
      uint256(keccak256(abi.encodePacked(equipmentId, amount, tx.origin, block.timestamp)));
    require(!equipmentListings[listingHash].active, "Already on sale");

    equipmentListings[listingHash] = ERC1155Listing({
      active: true,
      id: equipmentId,
      owner: msg.sender,
      amount: amount,
      price: price
    });
    erc1155ListingAmts[equipments][msg.sender] += amount;

    emit EquipmentListed(listingHash, msg.sender, equipmentId, amount, price);
  }

  /// @notice Lists a shard
  /// @param shardId ID of the shard
  /// @param amount Amount of shards
  /// @param price  Price of the listing
  function listShard(uint256 shardId, uint256 amount, uint256 price) external whenNotPaused {
    uint256 availableBalance =
      shards.balanceOf(msg.sender, shardId) - erc1155ListingAmts[shards][msg.sender];
    require(availableBalance >= amount, "Not enough of asset");

    // see listArtifact
    uint256 listingHash =
      uint256(keccak256(abi.encodePacked(shardId, amount, tx.origin, block.timestamp)));
    require(!shardListings[listingHash].active, "Already on sale");

    shardListings[listingHash] =
      ERC1155Listing({active: true, id: shardId, owner: msg.sender, amount: amount, price: price});
    erc1155ListingAmts[shards][msg.sender] += amount;

    emit ShardListed(listingHash, msg.sender, shardId, amount, price);
  }

  //	███████╗██████╗ ██╗████████╗
  //	██╔════╝██╔══██╗██║╚══██╔══╝
  //	█████╗  ██║  ██║██║   ██║
  //	██╔══╝  ██║  ██║██║   ██║
  //	███████╗██████╔╝██║   ██║
  //	╚══════╝╚═════╝ ╚═╝   ╚═╝

  /// @notice Edits price of a hunter listing
  /// @param hunterId ID of the hunter
  /// @param newPrice New price for the listing
  function editHunter(uint256 hunterId, uint256 newPrice) external whenNotPaused {
    require(hunterListings[hunterId].active, "Not on sale");
    require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the listing");

    // Change price
    hunterListings[hunterId].price = newPrice;
    emit HunterPriceChanged(hunterId, newPrice);
  }

  /// @notice Edits price of a artifact listing
  /// @param listingHash  Hash of the listing
  /// @param newPrice     New price for the listing
  function editArtifact(uint256 listingHash, uint256 newPrice) external whenNotPaused {
    ERC1155Listing memory listing = artifactListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Change price
    artifactListings[listingHash].price = newPrice;
    emit ArtifactPriceChanged(listingHash, newPrice);
  }

  /// @notice Edits price of an equipment listing
  /// @param listingHash  Hash of the listing
  /// @param newPrice     New price for the listing
  function editEquipment(uint256 listingHash, uint256 newPrice) external whenNotPaused {
    ERC1155Listing memory listing = equipmentListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Change price
    equipmentListings[listingHash].price = newPrice;
    emit EquipmentPriceChanged(listingHash, newPrice);
  }

  /// @notice Edits price of a shard listing
  /// @param listingHash  Hash of the listing
  /// @param newPrice     New price for the listing
  function editShard(uint256 listingHash, uint256 newPrice) external whenNotPaused {
    ERC1155Listing memory listing = shardListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Change price
    shardListings[listingHash].price = newPrice;
    emit ShardPriceChanged(listingHash, newPrice);
  }

  //	██████╗ ███████╗██╗     ██╗███████╗████████╗
  //	██╔══██╗██╔════╝██║     ██║██╔════╝╚══██╔══╝
  //	██║  ██║█████╗  ██║     ██║███████╗   ██║
  //	██║  ██║██╔══╝  ██║     ██║╚════██║   ██║
  //	██████╔╝███████╗███████╗██║███████║   ██║
  //	╚═════╝ ╚══════╝╚══════╝╚═╝╚══════╝   ╚═╝

  /// @notice Delists a hunter listing
  /// @param hunterId ID of the hunter
  function delistHunter(uint256 hunterId) external {
    require(hunterListings[hunterId].active, "Not on sale");
    require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the listing");

    // Delete listing
    delete hunterListings[hunterId];
    emit HunterDelisted(hunterId);
  }

  /// @notice Delists a artifact listing
  /// @param listingHash Hash of the artifact listing
  function delistArtifact(uint256 listingHash) external {
    ERC1155Listing memory listing = artifactListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Decrement listed amount
    erc1155ListingAmts[artifacts][msg.sender] -= listing.amount;

    // Delete listing
    delete artifactListings[listingHash];
    emit ArtifactDelisted(listingHash);
  }

  /// @notice Delists a equipment listing
  /// @param listingHash Hash of the equipment listing
  function delistEquipment(uint256 listingHash) external {
    ERC1155Listing memory listing = equipmentListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Decrement listed amount
    erc1155ListingAmts[equipments][msg.sender] -= listing.amount;

    // Delete listing
    delete equipmentListings[listingHash];
    emit EquipmentDelisted(listingHash);
  }

  /// @notice Delists a shard listing
  /// @param listingHash Hash of the shard listing
  function delistShard(uint256 listingHash) external {
    ERC1155Listing memory listing = shardListings[listingHash];

    require(listing.active, "Not on sale");
    require(listing.owner == msg.sender, "Not owner of the listing");

    // Decrement listed amount
    erc1155ListingAmts[shards][msg.sender] -= listing.amount;

    // Delete listing
    delete shardListings[listingHash];
    emit ShardDelisted(listingHash);
  }

  /// @notice Revokes signature so that it won't be used again
  /// @param listing EIP712 Listing
  /// @param signature Owner's signature
  /// @dev Used to cancel listings
  function revokeSignature(EIP712Listing calldata listing, bytes calldata signature) external {
    require(verifyMarketplaceSignature(listing, signature), "Invalid signature");
    require(listing.owner == msg.sender, "Not the listing owner");

    usedSignatures[signature] = true;
  }

  //	██████╗ ██╗   ██╗██╗   ██╗
  //	██╔══██╗██║   ██║╚██╗ ██╔╝
  //	██████╔╝██║   ██║ ╚████╔╝
  //	██╔══██╗██║   ██║  ╚██╔╝
  //	██████╔╝╚██████╔╝   ██║
  //	╚═════╝  ╚═════╝    ╚═╝

  /// @notice Buys a hunter listing
  /// @param hunterId         ID of the hunter
  /// @param expectedPrice    Price at the moment of purchase
  function buyHunter(uint256 hunterId, uint256 expectedPrice) external whenNotPaused {
    ERC721Listing memory listing = hunterListings[hunterId];
    address listingOwner = hunters.ownerOf(hunterId);

    require(listing.active, "Not on sale");
    require(msg.sender != listingOwner, "Owner of the listing");

    // This might be required as it would be possible to front-run buyHunter
    // and increase the price so if it was just "buy whatever the price is"
    // kind of function buyer could pay much more than the expected
    require(listing.price == expectedPrice, "Price mismatch");

    // Update boom cut of the hunter
    accruedBoomCut[hunterId] += (expectedPrice * boomCut) / BASE_PRECISION;

    uint256 commission = (expectedPrice * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    require(
      boom.transferFrom(msg.sender, listingOwner, expectedPrice - commission),
      "BOOM transfer failed"
    );
    hunters.safeTransferFrom(listingOwner, msg.sender, hunterId);

    // Delete listing
    delete hunterListings[hunterId];
    emit HunterBought(hunterId, expectedPrice);
  }

  /// @notice Buys a artifact listing
  /// @param listingHash      Hash of the artifact listing
  /// @param expectedPrice    Price at the moment of purchase
  function buyArtifact(uint256 listingHash, uint256 expectedPrice) external whenNotPaused {
    ERC1155Listing memory listing = artifactListings[listingHash];

    require(listing.active, "Not on sale");
    require(msg.sender != listing.owner, "Owner of the listing");

    // see buyHunter about this
    require(listing.price == expectedPrice, "Price mismatch");

    uint256 commission = (expectedPrice * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    require(
      boom.transferFrom(msg.sender, listing.owner, expectedPrice - commission),
      "BOOM transfer failed"
    );
    artifacts.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");

    // Decrement listed amount
    erc1155ListingAmts[artifacts][msg.sender] -= listing.amount;

    // Delete listing
    delete artifactListings[listingHash];
    emit ArtifactBought(listingHash, expectedPrice);
  }

  /// @notice Buys a equipment listing
  /// @param listingHash      Hash of the equipment listing
  /// @param expectedPrice    Price at the moment of purchase
  function buyEquipment(uint256 listingHash, uint256 expectedPrice) external whenNotPaused {
    ERC1155Listing memory listing = equipmentListings[listingHash];

    require(listing.active, "Not on sale");
    require(msg.sender != listing.owner, "Owner of the listing");

    // see buyHunter about this
    require(listing.price == expectedPrice, "Price mismatch");

    uint256 commission = (expectedPrice * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    require(
      boom.transferFrom(msg.sender, listing.owner, expectedPrice - commission),
      "BOOM transfer failed"
    );
    equipments.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");

    // Decrement listed amount
    erc1155ListingAmts[equipments][msg.sender] -= listing.amount;

    // Delete listing
    delete equipmentListings[listingHash];
    emit EquipmentBought(listingHash, expectedPrice);
  }

  /// @notice Buys a shard listing
  /// @param listingHash      Hash of the shard listing
  /// @param expectedPrice    Price at the moment of purchase
  function buyShard(uint256 listingHash, uint256 expectedPrice) external whenNotPaused {
    ERC1155Listing memory listing = shardListings[listingHash];

    require(listing.active, "Not on sale");
    require(msg.sender != listing.owner, "Owner of the listing");

    // see buyHunter about this
    require(listing.price == expectedPrice, "Price mismatch");

    uint256 commission = (expectedPrice * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    require(
      boom.transferFrom(msg.sender, listing.owner, expectedPrice - commission),
      "BOOM transfer failed"
    );
    shards.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");

    // Decrement listed amount
    erc1155ListingAmts[shards][msg.sender] -= listing.amount;

    // Delete listing
    delete shardListings[listingHash];
    emit ShardBought(listingHash, expectedPrice);
  }

  /// @notice Buys item with signature
  /// @param listing EIP712 Listing
  /// @param signature Owner's signature
  function buyWithSignature(EIP712Listing calldata listing, bytes calldata signature)
    external
    whenNotPaused
  {
    require(verifyMarketplaceSignature(listing, signature), "Invalid signature");
    require(listing.listingType < 4, "Invalid listing type");

    uint256 commission = (listing.price * studioCommission) / BASE_PRECISION;
    studioBalance += commission;

    usedSignatures[signature] = true;

    require(
      boom.transferFrom(msg.sender, listing.owner, listing.price - commission),
      "BOOM transfer failed"
    );

    if (listing.listingType == 0) {
      // HUNTER
      require(listing.amount == 1, "Invalid listing amount");

      // Update boom cut of the hunter
      accruedBoomCut[listing.id] += (listing.price * boomCut) / BASE_PRECISION;

      hunters.safeTransferFrom(listing.owner, msg.sender, listing.id);
    } else if (listing.listingType == 1) {
      // ARTIFACT
      artifacts.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");
    } else if (listing.listingType == 2) {
      // SHARD
      shards.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");
    } else if (listing.listingType == 3) {
      // EQUIPMENT
      equipments.safeTransferFrom(listing.owner, msg.sender, listing.id, listing.amount, "");
    }
  }

  //	███████╗██╗██████╗ ███████╗ ██╗██████╗
  //	██╔════╝██║██╔══██╗╚════██║███║╚════██╗
  //	█████╗  ██║██████╔╝    ██╔╝╚██║ █████╔╝
  //	██╔══╝  ██║██╔═══╝    ██╔╝  ██║██╔═══╝
  //	███████╗██║██║        ██║   ██║███████╗
  //	╚══════╝╚═╝╚═╝        ╚═╝   ╚═╝╚══════╝

  function hashListingStruct(EIP712Listing calldata listing)
    internal
    view
    returns (bytes32 structHash)
  {
    structHash = _hashTypedDataV4(
      keccak256(
        abi.encode(
          EIP712LISTING_SIGNATURE,
          listing.owner,
          listing.listingType,
          listing.id,
          listing.amount,
          listing.price,
          listing.expiryTimestamp,
          listing.nonce
        )
      )
    );
  }

  function verifyMarketplaceSignature(EIP712Listing calldata listing, bytes calldata signature)
    internal
    view
    returns (bool)
  {
    require(listing.expiryTimestamp >= block.timestamp, "Signature expired");
    require(!usedSignatures[signature], "Signature is used");

    bytes32 structHash = hashListingStruct(listing);
    address recoveredAddress = ECDSA.recover(structHash, signature);

    return recoveredAddress == listing.owner;
  }

  //	██╗    ██╗██╗████████╗██╗  ██╗██████╗ ██████╗  █████╗ ██╗    ██╗
  //	██║    ██║██║╚══██╔══╝██║  ██║██╔══██╗██╔══██╗██╔══██╗██║    ██║
  //	██║ █╗ ██║██║   ██║   ███████║██║  ██║██████╔╝███████║██║ █╗ ██║
  //	██║███╗██║██║   ██║   ██╔══██║██║  ██║██╔══██╗██╔══██║██║███╗██║
  //	╚███╔███╔╝██║   ██║   ██║  ██║██████╔╝██║  ██║██║  ██║╚███╔███╔╝
  //	 ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝

  /// @notice Allows studio to withdraw platform fees
  function withdrawStudio() external {
    require(msg.sender == studio, "Only studio");

    uint256 tmpBal = studioBalance;
    studioBalance = 0;
    boom.transfer(msg.sender, tmpBal);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}