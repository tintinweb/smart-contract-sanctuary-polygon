// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../libraries/AppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibStrings.sol";
import "../../libraries/LibMeta.sol";
import "../../libraries/LibERC721.sol";
import "../../libraries/LibRealm.sol";
import "../../libraries/LibAlchemica.sol";
import {InstallationDiamondInterface} from "../../interfaces/InstallationDiamondInterface.sol";
import "../../libraries/LibSignature.sol";
import "../../interfaces/IERC1155Marketplace.sol";

contract RealmFacet is Modifiers {
  struct MintParcelInput {
    uint256 coordinateX;
    uint256 coordinateY;
    uint256 district;
    string parcelId;
    string parcelAddress;
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256[4] boost; //fud, fomo, alpha, kek
  }

  event EquipInstallation(uint256 _realmId, uint256 _installationId, uint256 _x, uint256 _y);
  event UnequipInstallation(uint256 _realmId, uint256 _installationId, uint256 _x, uint256 _y);
  event EquipTile(uint256 _realmId, uint256 _tileId, uint256 _x, uint256 _y);
  event UnequipTile(uint256 _realmId, uint256 _tileId, uint256 _x, uint256 _y);
  event AavegotchiDiamondUpdated(address _aavegotchiDiamond);
  event InstallationUpgraded(uint256 _realmId, uint256 _prevInstallationId, uint256 _nextInstallationId, uint256 _coordinateX, uint256 _coordinateY);

  /// @notice Allow the diamond owner to mint new parcels
  /// @param _to The address to mint the parcels to
  /// @param _tokenIds The identifiers of tokens to mint
  /// @param _metadata An array of structs containing the metadata of each parcel being minted
  function mintParcels(
    address[] calldata _to,
    uint256[] calldata _tokenIds,
    MintParcelInput[] memory _metadata
  ) external onlyOwner {
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      require(s.tokenIds.length < LibRealm.MAX_SUPPLY, "RealmFacet: Cannot mint more than 420,069 parcels");
      uint256 tokenId = _tokenIds[index];
      address toAddress = _to[index];
      MintParcelInput memory metadata = _metadata[index];
      require(_tokenIds.length == _metadata.length, "Inputs must be same length");
      require(_to.length == _tokenIds.length, "Inputs must be same length");

      Parcel storage parcel = s.parcels[tokenId];
      parcel.coordinateX = metadata.coordinateX;
      parcel.coordinateY = metadata.coordinateY;
      parcel.parcelId = metadata.parcelId;
      parcel.size = metadata.size;
      parcel.district = metadata.district;
      parcel.parcelAddress = metadata.parcelAddress;
      parcel.alchemicaBoost = metadata.boost;

      LibERC721.safeMint(toAddress, tokenId);
    }
  }

  struct BatchEquipIO {
    uint256[] types; //0 for installation, 1 for tile
    bool[] equip; //true for equip, false for unequip
    uint256[] ids;
    uint256[] x;
    uint256[] y;
  }

  function batchEquip(
    uint256 _realmId,
    uint256 _gotchiId,
    BatchEquipIO memory _params,
    bytes[] memory _signatures
  ) external gameActive canBuild {
    require(_params.ids.length == _params.x.length, "RealmFacet: Wrong length");
    require(_params.x.length == _params.y.length, "RealmFacet: Wrong length");

    for (uint256 i = 0; i < _params.ids.length; i++) {
      if (_params.types[i] == 0 && _params.equip[i]) {
        equipInstallation(_realmId, _gotchiId, _params.ids[i], _params.x[i], _params.y[i], _signatures[i]);
      } else if (_params.types[i] == 1 && _params.equip[i]) {
        equipTile(_realmId, _gotchiId, _params.ids[i], _params.x[i], _params.y[i], _signatures[i]);
      } else if (_params.types[i] == 0 && !_params.equip[i]) {
        unequipInstallation(_realmId, _gotchiId, _params.ids[i], _params.x[i], _params.y[i], _signatures[i]);
      } else if (_params.types[i] == 1 && !_params.equip[i]) {
        unequipTile(_realmId, _gotchiId, _params.ids[i], _params.x[i], _params.y[i], _signatures[i]);
      }
    }
  }

  /// @notice Allow a parcel owner to equip an installation
  /// @dev The _x and _y denote the starting coordinates of the installation and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the installation is being equipped on
  /// @param _gotchiId The Gotchi ID of the Aavegotchi being played. Must be verified by the backend API.
  /// @param _installationId The identifier of the installation being equipped
  /// @param _x The x(horizontal) coordinate of the installation
  /// @param _y The y(vertical) coordinate of the installation

  function equipInstallation(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) public gameActive canBuild {
    //2 - Equip Installations
    LibRealm.verifyAccessRight(_realmId, _gotchiId, 2, LibMeta.msgSender());
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _gotchiId, _installationId, _x, _y)), _signature, s.backendPubKey),
      "RealmFacet: Invalid signature"
    );

    InstallationDiamondInterface.InstallationType memory installation = InstallationDiamondInterface(s.installationsDiamond).getInstallationType(
      _installationId
    );

    require(installation.level == 1, "RealmFacet: Can only equip lvl 1");

    if (installation.installationType == 1 || installation.installationType == 2) {
      require(s.parcels[_realmId].currentRound >= 1, "RealmFacet: Must survey before equipping");
    }
    if (installation.installationType == 3) {
      require(s.parcels[_realmId].lodgeId == 0, "RealmFacet: Lodge already equipped");
      s.parcels[_realmId].lodgeId = _installationId;
    }
    if (installation.installationType == 6)
      require(s.parcels[_realmId].upgradeQueueCapacity == 1, "RealmFacet: Maker already equipped or altar not equipped");

    LibRealm.placeInstallation(_realmId, _installationId, _x, _y);
    InstallationDiamondInterface(s.installationsDiamond).equipInstallation(msg.sender, _realmId, _installationId);

    LibAlchemica.increaseTraits(_realmId, _installationId, false);

    IERC1155Marketplace(s.aavegotchiDiamond).updateERC1155Listing(s.installationsDiamond, _installationId, msg.sender);

    emit EquipInstallation(_realmId, _installationId, _x, _y);
  }

  /// @notice Allow a parcel owner to unequip an installation
  /// @dev The _x and _y denote the starting coordinates of the installation and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the installation is being unequipped from
  /// @param _installationId The identifier of the installation being unequipped
  /// @param _x The x(horizontal) coordinate of the installation
  /// @param _y The y(vertical) coordinate of the installation
  function unequipInstallation(
    uint256 _realmId,
    uint256 _gotchiId, //will be used soon
    uint256 _installationId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) public onlyParcelOwner(_realmId) gameActive canBuild {
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _gotchiId, _installationId, _x, _y)), _signature, s.backendPubKey),
      "RealmFacet: Invalid signature"
    );

    //@todo: Prevent unequipping if an upgrade is active for this installationId on the parcel

    InstallationDiamondInterface installationsDiamond = InstallationDiamondInterface(s.installationsDiamond);
    InstallationDiamondInterface.InstallationType memory installation = installationsDiamond.getInstallationType(_installationId);

    require(!LibRealm.installationInUpgradeQueue(_realmId, _installationId, _x, _y), "RealmFacet: Can't unequip installation in upgrade queue");
    require(
      installation.installationType != 0 || s.parcels[_realmId].upgradeQueueCapacity == 1,
      "RealmFacet: Cannot unequip altar when there is a maker"
    );

    LibRealm.removeInstallation(_realmId, _installationId, _x, _y);
    InstallationDiamondInterface(s.installationsDiamond).unequipInstallation(msg.sender, _realmId, _installationId);
    LibAlchemica.reduceTraits(_realmId, _installationId, false);

    //Process refund
    if (installationsDiamond.getInstallationUnequipType(_installationId) == 0) {
      //Loop through each level of the installation.
      //@todo: For now we can use the ID order to get the cost of previous upgrades. But in the future we'll need to add some data redundancy.
      uint256 currentLevel = installation.level;
      uint256[] memory alchemicaRefund = new uint256[](4);
      for (uint256 index = 0; index < currentLevel; index++) {
        InstallationDiamondInterface.InstallationType memory prevInstallation = installationsDiamond.getInstallationType(_installationId - index);

        //Loop through each Alchemica cost
        for (uint256 i; i < prevInstallation.alchemicaCost.length; i++) {
          //Only half of the cost is refunded
          alchemicaRefund[i] += prevInstallation.alchemicaCost[i] / 2;
        }
      }

      for (uint256 j = 0; j < alchemicaRefund.length; j++) {
        //don't send 0 refunds
        if (alchemicaRefund[j] > 0) {
          IERC20 alchemica = IERC20(s.alchemicaAddresses[j]);
          alchemica.transfer(msg.sender, alchemicaRefund[j]);
        }
      }
    }

    emit UnequipInstallation(_realmId, _installationId, _x, _y);
  }

  /// @notice Allow a parcel owner to move an installation
  /// @param _realmId The identifier of the parcel which the installation is being moved on
  /// @param _installationId The identifier of the installation being moved
  /// @param _x0 The x(horizontal) coordinate of the installation
  /// @param _y0 The y(vertical) coordinate of the installation
  /// @param _x1 The x(horizontal) coordinate of the installation to move to
  /// @param _y1 The y(vertical) coordinate of the installation to move to
  function moveInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x0,
    uint256 _y0,
    uint256 _x1,
    uint256 _y1
  ) external onlyParcelOwner(_realmId) gameActive canBuild {
    //Check if upgrade is in progress
    InstallationDiamondInterface installation = InstallationDiamondInterface(s.installationsDiamond);

    require(installation.parcelInstallationUpgrading(_realmId, _installationId, _x0, _y0) == false, "RealmFacet: Installation is upgrading");

    LibRealm.removeInstallation(_realmId, _installationId, _x0, _y0);
    emit UnequipInstallation(_realmId, _installationId, _x0, _y0);
    LibRealm.placeInstallation(_realmId, _installationId, _x1, _y1);
    emit EquipInstallation(_realmId, _installationId, _x1, _y1);
  }

  /// @notice Allow a parcel owner to equip a tile
  /// @dev The _x and _y denote the starting coordinates of the tile and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the tile is being equipped on
  /// @param _tileId The identifier of the tile being equipped
  /// @param _x The x(horizontal) coordinate of the tile
  /// @param _y The y(vertical) coordinate of the tile
  function equipTile(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _tileId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) public gameActive canBuild {
    //3 - Equip Tile
    LibRealm.verifyAccessRight(_realmId, _gotchiId, 3, LibMeta.msgSender());
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _gotchiId, _tileId, _x, _y)), _signature, s.backendPubKey),
      "RealmFacet: Invalid signature"
    );
    LibRealm.placeTile(_realmId, _tileId, _x, _y);
    TileDiamondInterface(s.tileDiamond).equipTile(msg.sender, _realmId, _tileId);

    IERC1155Marketplace(s.aavegotchiDiamond).updateERC1155Listing(s.tileDiamond, _tileId, msg.sender);

    emit EquipTile(_realmId, _tileId, _x, _y);
  }

  /// @notice Allow a parcel owner to unequip a tile
  /// @dev The _x and _y denote the starting coordinates of the tile and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the tile is being unequipped from
  /// @param _tileId The identifier of the tile being unequipped
  /// @param _x The x(horizontal) coordinate of the tile
  /// @param _y The y(vertical) coordinate of the tile
  function unequipTile(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _tileId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) public onlyParcelOwner(_realmId) gameActive canBuild {
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _gotchiId, _tileId, _x, _y)), _signature, s.backendPubKey),
      "RealmFacet: Invalid signature"
    );
    LibRealm.removeTile(_realmId, _tileId, _x, _y);

    TileDiamondInterface(s.tileDiamond).unequipTile(msg.sender, _realmId, _tileId);

    emit UnequipTile(_realmId, _tileId, _x, _y);
  }

  /// @notice Allow a parcel owner to move a tile
  /// @param _realmId The identifier of the parcel which the tile is being moved on
  /// @param _tileId The identifier of the tile being moved
  /// @param _x0 The x(horizontal) coordinate of the tile
  /// @param _y0 The y(vertical) coordinate of the tile
  /// @param _x1 The x(horizontal) coordinate of the tile to move to
  /// @param _y1 The y(vertical) coordinate of the tile to move to
  function moveTile(
    uint256 _realmId,
    uint256 _tileId,
    uint256 _x0,
    uint256 _y0,
    uint256 _x1,
    uint256 _y1
  ) external onlyParcelOwner(_realmId) gameActive canBuild {
    LibRealm.removeTile(_realmId, _tileId, _x0, _y0);
    emit UnequipTile(_realmId, _tileId, _x0, _y0);
    LibRealm.placeTile(_realmId, _tileId, _x1, _y1);
    emit EquipTile(_realmId, _tileId, _x1, _y1);
  }

  function upgradeInstallation(
    uint256 _realmId,
    uint256 _prevInstallationId,
    uint256 _nextInstallationId,
    uint256 _coordinateX,
    uint256 _coordinateY
  ) external onlyInstallationDiamond {
    LibRealm.removeInstallation(_realmId, _prevInstallationId, _coordinateX, _coordinateY);
    LibRealm.placeInstallation(_realmId, _nextInstallationId, _coordinateX, _coordinateY);
    LibAlchemica.reduceTraits(_realmId, _prevInstallationId, true);
    LibAlchemica.increaseTraits(_realmId, _nextInstallationId, true);
    emit InstallationUpgraded(_realmId, _prevInstallationId, _nextInstallationId, _coordinateX, _coordinateY);
  }

  function addUpgradeQueueLength(uint256 _realmId) external onlyInstallationDiamond {
    s.parcels[_realmId].upgradeQueueLength++;
  }

  function subUpgradeQueueLength(uint256 _realmId) external onlyInstallationDiamond {
    s.parcels[_realmId].upgradeQueueLength--;
  }

  function fixGrid(
    uint256 _realmId,
    uint256 _installationId,
    uint256[] memory _x,
    uint256[] memory _y,
    bool tile
  ) external onlyOwner {
    require(_x.length == _y.length, "RealmFacet: _x and _y must be the same length");
    Parcel storage parcel = s.parcels[_realmId];
    for (uint256 i; i < _x.length; i++) {
      require(_x[i] < 64 && _y[i] < 64, "RealmFacet: _x and _y must be less than 64");
      if (!tile) {
        parcel.buildGrid[_x[i]][_y[i]] = _installationId;
      } else {
        parcel.tileGrid[_x[i]][_y[i]] = _installationId;
      }
    }
  }

  function buildingFrozen() external view returns (bool) {
    return s.freezeBuilding;
  }

  function setFreezeBuilding(bool _freezeBuilding) external onlyOwner {
    s.freezeBuilding = _freezeBuilding;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.9;
import {LibDiamond} from "./LibDiamond.sol";
import {LibMeta} from "./LibMeta.sol";
import "../interfaces/AavegotchiDiamond.sol";

uint256 constant HUMBLE_WIDTH = 8;
uint256 constant HUMBLE_HEIGHT = 8;
uint256 constant REASONABLE_WIDTH = 16;
uint256 constant REASONABLE_HEIGHT = 16;
uint256 constant SPACIOUS_WIDTH = 32;
uint256 constant SPACIOUS_HEIGHT = 64;
uint256 constant PAARTNER_WIDTH = 64;
uint256 constant PAARTNER_HEIGHT = 64;

uint256 constant FUD = 0;
uint256 constant FOMO = 1;
uint256 constant ALPHA = 2;
uint256 constant KEK = 3;

struct Parcel {
  address owner;
  string parcelAddress; //looks-like-this
  string parcelId; //C-4208-3168-R
  uint256 coordinateX; //x position on the map
  uint256 coordinateY; //y position on the map
  uint256 district;
  uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
  uint256[64][64] buildGrid; //x, then y array of positions - for installations
  uint256[64][64] tileGrid; //x, then y array of positions - for tiles under the installations (floor)
  uint256[4] alchemicaBoost; //fud, fomo, alpha, kek
  uint256[4] alchemicaRemaining; //fud, fomo, alpha, kek
  uint256 currentRound; //begins at 0 and increments after surveying has begun
  mapping(uint256 => uint256[]) roundBaseAlchemica; //round alchemica not including boosts
  mapping(uint256 => uint256[]) roundAlchemica; //round alchemica including boosts
  // // alchemicaType => array of reservoir id
  mapping(uint256 => uint256[]) reservoirs;
  uint256[4] alchemicaHarvestRate;
  uint256[4] lastUpdateTimestamp;
  uint256[4] unclaimedAlchemica;
  uint256 altarId;
  uint256 upgradeQueueCapacity;
  uint256 upgradeQueueLength;
  uint256 lodgeId;
  bool surveying;
  uint256[64][64] startPositionBuildGrid;
  uint256[64][64] startPositionTileGrid;
  uint16 harvesterCount;
}

struct BounceGate {
  string title;
  uint64 startTime;
  uint64 endTime;
  uint120 priority;
  bool equipped;
  uint64 lastTimeUpdated;
}

struct RequestConfig {
  uint64 subId;
  uint32 callbackGasLimit;
  uint16 requestConfirmations;
  uint32 numWords;
  bytes32 keyHash;
}

struct AppStorage {
  uint256[] tokenIds;
  mapping(uint256 => Parcel) parcels;
  mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
  mapping(address => uint256[]) ownerTokenIds;
  mapping(address => mapping(address => bool)) operators;
  mapping(uint256 => address) approved;
  address aavegotchiDiamond;
  address[4] alchemicaAddresses; //fud, fomo, alpha, kek
  address installationsDiamond;
  uint256 surveyingRound;
  uint256[4][5] totalAlchemicas;
  uint256[4] boostMultipliers;
  uint256[4] greatPortalCapacity;
  // VRF
  address vrfCoordinator;
  address linkAddress;
  RequestConfig requestConfig;
  mapping(uint256 => uint256) vrfRequestIdToTokenId;
  mapping(uint256 => uint256) vrfRequestIdToSurveyingRound;
  bytes backendPubKey;
  address gameManager;
  mapping(uint256 => uint256) lastExitTime; //for aavegotchis exiting alchemica
  // gotchiId => lastChanneledGotchi
  mapping(uint256 => uint256) gotchiChannelings;
  // parcelId => lastChanneledParcel
  mapping(uint256 => uint256) parcelChannelings;
  // altarLevel => cooldown hours in seconds
  mapping(uint256 => uint256) channelingLimits;
  // parcelId => lastClaimedAlchemica
  mapping(uint256 => uint256) lastClaimedAlchemica;
  address gltrAddress;
  address tileDiamond;
  bool gameActive;
  // parcelId => action: 0 Alchemical Channeling, 1 Emptying Reservoirs => permission: 0 Owner only, 1 Owner + Borrowed Gotchis, 2 whitelisted addresses, 3 blacklisted addresses, 4 Any Gotchi
  mapping(uint256 => mapping(uint256 => uint256)) accessRights;
  // gotchiId => lastChanneledDay
  mapping(uint256 => uint256) lastChanneledDay;
  bool freezeBuilding;
  //NFT DISPLAY STORAGE
  //chainId => contractAddress => allowed
  mapping(uint256 => mapping(address => bool)) nftDisplayAllowed;
  mapping(uint256 => BounceGate) bounceGates;
  // parcelId => action: 0 Alchemical Channeling, 1 Emptying Reservoirs => whitelistIds
  mapping(uint256 => mapping(uint256 => uint32)) whitelistIds;
}

library LibAppStorage {
  function diamondStorage() internal pure returns (AppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  AppStorage internal s;

  modifier onlyParcelOwner(uint256 _tokenId) {
    require(LibMeta.msgSender() == s.parcels[_tokenId].owner, "AppStorage: Only Parcel owner can call");
    _;
  }

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyGotchiOwner(uint256 _gotchiId) {
    AavegotchiDiamond diamond = AavegotchiDiamond(s.aavegotchiDiamond);
    require(LibMeta.msgSender() == diamond.ownerOf(_gotchiId), "AppStorage: Only Gotchi Owner can call");
    _;
  }

  modifier onlyGameManager() {
    require(msg.sender == s.gameManager, "AlchemicaFacet: Only Game Manager");
    _;
  }

  modifier onlyInstallationDiamond() {
    require(LibMeta.msgSender() == s.installationsDiamond, "AppStorage: Only Installation diamond can call");
    _;
  }

  modifier gameActive() {
    require(s.gameActive, "AppStorage: game not active");
    _;
  }

  modifier canBuild() {
    require(!s.freezeBuilding, "AppStorage: Building temporarily disabled");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct DiamondStorage {
    // maps function selectors to the facets that execute the functions.
    // and maps the selectors to their position in the selectorSlots array.
    // func selector => address facet, selector position
    mapping(bytes4 => bytes32) facets;
    // array of slots of function selectors.
    // each slot holds 8 function selectors.
    mapping(uint256 => bytes32) selectorSlots;
    // The number of function selectors in selectorSlots
    uint16 selectorCount;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
  }

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

  bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
  bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

  // Internal function version of diamondCut
  // This code is almost the same as the external diamondCut,
  // except it is using 'Facet[] memory _diamondCut' instead of
  // 'Facet[] calldata _diamondCut'.
  // The code is duplicated to prevent copying calldata to memory which
  // causes an error for a two dimensional array.
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    DiamondStorage storage ds = diamondStorage();
    uint256 originalSelectorCount = ds.selectorCount;
    uint256 selectorCount = originalSelectorCount;
    bytes32 selectorSlot;
    // Check if last selector slot is not full
    if (selectorCount & 7 > 0) {
      // get last selectorSlot
      selectorSlot = ds.selectorSlots[selectorCount >> 3];
    }
    // loop through diamond cut
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
        selectorCount,
        selectorSlot,
        _diamondCut[facetIndex].facetAddress,
        _diamondCut[facetIndex].action,
        _diamondCut[facetIndex].functionSelectors
      );
    }
    if (selectorCount != originalSelectorCount) {
      ds.selectorCount = uint16(selectorCount);
    }
    // If last selector slot is not full
    if (selectorCount & 7 > 0) {
      ds.selectorSlots[selectorCount >> 3] = selectorSlot;
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addReplaceRemoveFacetSelectors(
    uint256 _selectorCount,
    bytes32 _selectorSlot,
    address _newFacetAddress,
    IDiamondCut.FacetCutAction _action,
    bytes4[] memory _selectors
  ) internal returns (uint256, bytes32) {
    DiamondStorage storage ds = diamondStorage();
    require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    if (_action == IDiamondCut.FacetCutAction.Add) {
      enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
      for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
        bytes4 selector = _selectors[selectorIndex];

        bytes32 oldFacet = ds.facets[selector];

        require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
        // add facet for selector
        ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
        uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
        // clear selector position in slot and add selector
        _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
        // if slot is full then write it to storage
        if (selectorInSlotPosition == 224) {
          ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
          _selectorSlot = 0;
        }
        _selectorCount++;
      }
    } else if (_action == IDiamondCut.FacetCutAction.Replace) {
      enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
      for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
        bytes4 selector = _selectors[selectorIndex];
        bytes32 oldFacet = ds.facets[selector];
        address oldFacetAddress = address(bytes20(oldFacet));

        // only useful if immutable functions exist
        require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
        require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
        require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
        // replace old facet address
        ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
      }
    } else if (_action == IDiamondCut.FacetCutAction.Remove) {
      require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
      uint256 selectorSlotCount = _selectorCount >> 3;
      uint256 selectorInSlotIndex = _selectorCount & 7;
      for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
        if (_selectorSlot == 0) {
          // get last selectorSlot
          selectorSlotCount--;
          _selectorSlot = ds.selectorSlots[selectorSlotCount];
          selectorInSlotIndex = 7;
        } else {
          selectorInSlotIndex--;
        }
        bytes4 lastSelector;
        uint256 oldSelectorsSlotCount;
        uint256 oldSelectorInSlotPosition;
        // adding a block here prevents stack too deep error
        {
          bytes4 selector = _selectors[selectorIndex];
          bytes32 oldFacet = ds.facets[selector];
          require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
          // only useful if immutable functions exist
          require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
          // replace selector with last selector in ds.facets
          // gets the last selector
          lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
          if (lastSelector != selector) {
            // update last selector slot position info
            ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
          }
          delete ds.facets[selector];
          uint256 oldSelectorCount = uint16(uint256(oldFacet));
          oldSelectorsSlotCount = oldSelectorCount >> 3;
          oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
        }
        if (oldSelectorsSlotCount != selectorSlotCount) {
          bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
          // clears the selector we are deleting and puts the last selector in its place.
          oldSelectorSlot =
            (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
            (bytes32(lastSelector) >> oldSelectorInSlotPosition);
          // update storage with the modified slot
          ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
        } else {
          // clears the selector we are deleting and puts the last selector in its place.
          _selectorSlot =
            (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
            (bytes32(lastSelector) >> oldSelectorInSlotPosition);
        }
        if (selectorInSlotIndex == 0) {
          delete ds.selectorSlots[selectorSlotCount];
          _selectorSlot = 0;
        }
      }
      _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
    } else {
      revert("LibDiamondCut: Incorrect FacetCutAction");
    }
    return (_selectorCount, _selectorSlot);
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
          revert("LibDiamondCut: _init function reverted");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library LibStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function strWithUint(string memory _str, uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        bytes memory buffer;
        unchecked {
            if (value == 0) {
                return string(abi.encodePacked(_str, "0"));
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            buffer = new bytes(digits);
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + (temp % 10)));
                temp /= 10;
            }
        }
        return string(abi.encodePacked(_str, buffer));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IERC721TokenReceiver.sol";
import {LibAppStorage, AppStorage} from "./AppStorage.sol";
import "./LibMeta.sol";

library LibERC721 {
  /// @dev This emits when ownership of any NFT changes by any mechanism.
  ///  This event emits when NFTs are created (`from` == 0) and destroyed
  ///  (`to` == 0). Exception: during contract creation, any number of NFTs
  ///  may be created and assigned without emitting Transfer. At the time of
  ///  any transfer, the approved address for that NFT (if any) is reset to none.
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  /// @dev This emits when the approved address for an NFT is changed or
  ///  reaffirmed. The zero address indicates there is no approved address.
  ///  When a Transfer event emits, this also indicates that the approved
  ///  address for that NFT (if any) is reset to none.
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  /// @dev This emits when an operator is enabled or disabled for an owner.
  ///  The operator can manage all NFTs of the owner.
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  event MintParcel(address indexed _owner, uint256 indexed _tokenId);

  event ParcelAccessRightSet(uint256 _realmId, uint256 _actionRight, uint256 _accessRight);

  function checkOnERC721Received(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC721_RECEIVED == IERC721TokenReceiver(_to).onERC721Received(_operator, _from, _tokenId, _data),
        "LibERC721: Transfer rejected/failed by _to"
      );
    }
  }

  // This function is used by transfer functions
  function transferFrom(
    address _sender,
    address _from,
    address _to,
    uint256 _tokenId
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(_to != address(0), "ER721: Can't transfer to 0 address");
    address owner = s.parcels[_tokenId].owner;
    require(owner != address(0), "ERC721: Invalid tokenId or can't be transferred");
    require(_sender == owner || s.operators[owner][_sender] || s.approved[_tokenId] == _sender, "LibERC721: Not owner or approved to transfer");
    require(_from == owner, "ERC721: _from is not owner, transfer failed");
    s.parcels[_tokenId].owner = _to;

    //Update indexes and arrays if _to is a different address
    if (_from != _to) {
      //Get the index of the tokenID to transfer
      uint256 transferIndex = s.ownerTokenIdIndexes[_from][_tokenId];
      uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
      uint256 lastTokenId = s.ownerTokenIds[_from][lastIndex];
      uint256 newIndex = s.ownerTokenIds[_to].length;

      //Move the last element of the ownerIds array to replace the tokenId to be transferred
      s.ownerTokenIdIndexes[_from][lastTokenId] = transferIndex;
      s.ownerTokenIds[_from][transferIndex] = lastTokenId;
      delete s.ownerTokenIdIndexes[_from][_tokenId];

      //pop from array
      s.ownerTokenIds[_from].pop();

      //update index of new token
      s.ownerTokenIdIndexes[_to][_tokenId] = newIndex;
      s.ownerTokenIds[_to].push(_tokenId);

      if (s.approved[_tokenId] != address(0)) {
        delete s.approved[_tokenId];
        emit LibERC721.Approval(owner, address(0), _tokenId);
      }

      //reset the parcel access rights on transfer to 0
      for (uint256 i; i < 7; ) {
        if (s.accessRights[_tokenId][i] > 0) {
          s.accessRights[_tokenId][i] = 0;
          emit ParcelAccessRightSet(_tokenId, i, 0);
        }
        unchecked {
          ++i;
        }
      }
    }

    emit LibERC721.Transfer(_from, _to, _tokenId);
  }

  function safeMint(address _to, uint256 _tokenId) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    require(s.parcels[_tokenId].owner == address(0), "LibERC721: tokenId already minted");
    s.parcels[_tokenId].owner = _to;
    s.tokenIds.push(_tokenId);
    s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
    s.ownerTokenIds[_to].push(_tokenId);

    emit MintParcel(_to, _tokenId);
    emit LibERC721.Transfer(address(0), _to, _tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {InstallationDiamondInterface} from "../interfaces/InstallationDiamondInterface.sol";
import {TileDiamondInterface} from "../interfaces/TileDiamond.sol";
import "./AppStorage.sol";
import "./BinomialRandomizer.sol";

library LibRealm {
  event SurveyParcel(uint256 _tokenId, uint256 _round, uint256[] _alchemicas);

  uint256 constant MAX_SUPPLY = 420069;

  //Place installation
  function placeInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256[5] memory widths = getWidths();

    uint256[5] memory heights = getHeights();

    InstallationDiamondInterface installationsDiamond = InstallationDiamondInterface(s.installationsDiamond);
    InstallationDiamondInterface.InstallationType memory installation = installationsDiamond.getInstallationType(_installationId);

    Parcel storage parcel = s.parcels[_realmId];

    //Check if these slots are available onchain
    require(_x <= widths[parcel.size] - installation.width, "LibRealm: x exceeding width");
    require(_y <= heights[parcel.size] - installation.height, "LibRealm: y exceeding height");

    // Track the start position of the build grid
    parcel.startPositionBuildGrid[_x][_y] = _installationId;

    for (uint256 indexW = _x; indexW < _x + installation.width; indexW++) {
      for (uint256 indexH = _y; indexH < _y + installation.height; indexH++) {
        require(parcel.buildGrid[indexW][indexH] == 0, "LibRealm: Invalid spot");
        parcel.buildGrid[indexW][indexH] = _installationId;
      }
    }
  }

  function removeInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    InstallationDiamondInterface installationsDiamond = InstallationDiamondInterface(s.installationsDiamond);
    InstallationDiamondInterface.InstallationType memory installation = installationsDiamond.getInstallationType(_installationId);
    Parcel storage parcel = s.parcels[_realmId];
    require(parcel.buildGrid[_x][_y] == _installationId, "LibRealm: wrong installationId");
    require(parcel.startPositionBuildGrid[_x][_y] == _installationId, "LibRealm: wrong startPosition");
    for (uint256 indexW = _x; indexW < _x + installation.width; indexW++) {
      for (uint256 indexH = _y; indexH < _y + installation.height; indexH++) {
        parcel.buildGrid[indexW][indexH] = 0;
      }
    }
    parcel.startPositionBuildGrid[_x][_y] = 0;
  }

  function placeTile(
    uint256 _realmId,
    uint256 _tileId,
    uint256 _x,
    uint256 _y
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256[5] memory widths = getWidths();

    uint256[5] memory heights = getHeights();

    TileDiamondInterface tilesDiamond = TileDiamondInterface(s.tileDiamond);
    TileDiamondInterface.TileType memory tile = tilesDiamond.getTileType(_tileId);

    Parcel storage parcel = s.parcels[_realmId];

    //Check if these slots are available onchain
    require(_x <= widths[parcel.size] - tile.width, "LibRealm: x exceeding width");
    require(_y <= heights[parcel.size] - tile.height, "LibRealm: y exceeding height");

    parcel.startPositionTileGrid[_x][_y] = _tileId;

    for (uint256 indexW = _x; indexW < _x + tile.width; indexW++) {
      for (uint256 indexH = _y; indexH < _y + tile.height; indexH++) {
        require(parcel.tileGrid[indexW][indexH] == 0, "LibRealm: Invalid spot");
        parcel.tileGrid[indexW][indexH] = _tileId;
      }
    }
  }

  function removeTile(
    uint256 _realmId,
    uint256 _tileId,
    uint256 _x,
    uint256 _y
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    TileDiamondInterface tilesDiamond = TileDiamondInterface(s.tileDiamond);
    TileDiamondInterface.TileType memory tile = tilesDiamond.getTileType(_tileId);
    Parcel storage parcel = s.parcels[_realmId];

    require(parcel.tileGrid[_x][_y] == _tileId, "LibRealm: wrong tileId");
    require(parcel.startPositionTileGrid[_x][_y] == _tileId, "LibRealm: wrong startPosition");

    for (uint256 indexW = _x; indexW < _x + tile.width; indexW++) {
      for (uint256 indexH = _y; indexH < _y + tile.height; indexH++) {
        parcel.tileGrid[indexW][indexH] = 0;
      }
    }
    parcel.startPositionTileGrid[_x][_y] = 0;
  }

  function calculateAmount(
    uint256 _tokenId,
    uint256[] memory randomWords,
    uint256 i
  ) internal view returns (uint256) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return BinomialRandomizer.calculateAlchemicaSurveyAmount(randomWords[i], s.totalAlchemicas[s.parcels[_tokenId].size][i]);
  }

  function updateRemainingAlchemica(
    uint256 _tokenId,
    uint256[] memory randomWords,
    uint256 _round
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    s.parcels[_tokenId].currentRound++;
    s.parcels[_tokenId].surveying = false;

    uint256[] memory alchemicas = new uint256[](4);
    uint256[] memory roundAmounts = new uint256[](4);
    for (uint256 i; i < 4; i++) {
      uint256 baseAmount = calculateAmount(_tokenId, randomWords, i); //100%;

      //first round is 25%, rounds after are 8.3%
      uint256 roundAmount = _round == 0 ? baseAmount / 4 : (baseAmount - (baseAmount / 4)) / 9;
      uint256 boost = s.parcels[_tokenId].alchemicaBoost[i] * s.boostMultipliers[i];

      s.parcels[_tokenId].alchemicaRemaining[i] += roundAmount + boost;
      roundAmounts[i] = roundAmount;
      alchemicas[i] = roundAmount + boost;
    }
    //update round alchemica
    s.parcels[_tokenId].roundAlchemica[_round] = alchemicas;
    s.parcels[_tokenId].roundBaseAlchemica[_round] = roundAmounts;
    emit SurveyParcel(_tokenId, _round, alchemicas);
  }

  function getWidths() internal pure returns (uint256[5] memory) {
    uint256[5] memory widths = [
      HUMBLE_WIDTH, //humble
      REASONABLE_WIDTH, //reasonable
      SPACIOUS_WIDTH, //spacious vertical
      SPACIOUS_HEIGHT, //spacious horizontal
      PAARTNER_WIDTH //partner
    ];
    return widths;
  }

  function getHeights() internal pure returns (uint256[5] memory) {
    uint256[5] memory heights = [
      HUMBLE_HEIGHT, //humble
      REASONABLE_HEIGHT, //reasonable
      SPACIOUS_HEIGHT, //spacious vertical
      SPACIOUS_WIDTH, //spacious horizontal
      PAARTNER_HEIGHT //partner
    ];
    return heights;
  }

  function isAccessRightValid(uint256 actionRight, uint256 accessRight) internal pure returns (bool) {
    // 0: Channeling
    // 1: Empty Reservoir
    // 2: Equip Installations
    // 3: Equip Tiles
    // 4: Unequip Installations
    // 5: Unequip Tiles
    // 6: Upgrade Installations
    if (actionRight <= 6) {
      // 0: Only Owner
      // 1: Owner + Lent Out
      // 2: Whitelisted Only
      // 3: Allow blacklisted
      // 4: Anyone
      return accessRight <= 4;
    }
    return false;
  }

  function verifyAccessRight(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _actionRight,
    address _sender
  ) internal view {
    AppStorage storage s = LibAppStorage.diamondStorage();
    AavegotchiDiamond diamond = AavegotchiDiamond(s.aavegotchiDiamond);

    uint256 accessRight = s.accessRights[_realmId][_actionRight];
    address parcelOwner = s.parcels[_realmId].owner;

    //Only owner
    if (accessRight == 0) {
      require(_sender == parcelOwner, "LibRealm: Access Right - Only Owner");
    }
    //Owner or borrowed gotchi
    else if (accessRight == 1) {
      if (diamond.isAavegotchiLent(uint32(_gotchiId))) {
        AavegotchiDiamond.GotchiLending memory listing = diamond.getGotchiLendingFromToken(uint32(_gotchiId));
        require(
          _sender == parcelOwner || (_sender == listing.borrower && listing.lender == parcelOwner),
          "LibRealm: Access Right - Only Owner/Borrower"
        );
      } else {
        require(_sender == parcelOwner, "LibRealm: Access Right - Only Owner");
      }
    }
    //whitelisted addresses
    else if (accessRight == 2) {
      require(diamond.isWhitelisted(s.whitelistIds[_realmId][_actionRight], _sender) > 0, "LibRealm: Access Right - Only Whitelisted");
    }
    // //blacklisted addresses
    // else if (accessRight == 3) {}
    //anyone
    else if (accessRight == 4) {
      //do nothing! anyone can perform this action
    }
  }

  function installationInUpgradeQueue(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) internal view returns (bool) {
    AppStorage storage s = LibAppStorage.diamondStorage();

    InstallationDiamondInterface installationsDiamond = InstallationDiamondInterface(s.installationsDiamond);

    (InstallationDiamondInterface.UpgradeQueue[] memory parcelUpgrades, ) = installationsDiamond.getParcelUpgradeQueue(_realmId);
    for (uint256 i; i < parcelUpgrades.length; i++) {
      // Checking whether x and y match is sufficient when start positions are checked in a separate check
      if (
        parcelUpgrades[i].installationId == _installationId &&
        parcelUpgrades[i].coordinateX == uint16(_x) &&
        parcelUpgrades[i].coordinateY == uint16(_y)
      ) {
        return true;
      }
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {InstallationDiamondInterface} from "../interfaces/InstallationDiamondInterface.sol";
import {LibAppStorage, AppStorage, Parcel} from "./AppStorage.sol";
import "../interfaces/IERC20Mintable.sol";
import "../interfaces/AavegotchiDiamond.sol";

library LibAlchemica {
  uint256 constant bp = 100 ether;

  event AlchemicaClaimed(
    uint256 indexed _realmId,
    uint256 indexed _gotchiId,
    uint256 indexed _alchemicaType,
    uint256 _amount,
    uint256 _spilloverRate,
    uint256 _spilloverRadius
  );

  function settleUnclaimedAlchemica(uint256 _tokenId, uint256 _alchemicaType) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    //todo: only do this every 8 hrs

    uint256 capacity = calculateTotalCapacity(_tokenId, _alchemicaType);

    uint256 alchemicaSinceUpdate = alchemicaSinceLastUpdate(_tokenId, _alchemicaType);

    if (alchemicaSinceUpdate > 0) {
      //Cannot settle more than capacity
      if (s.parcels[_tokenId].unclaimedAlchemica[_alchemicaType] + alchemicaSinceUpdate > capacity) {
        s.parcels[_tokenId].unclaimedAlchemica[_alchemicaType] = capacity;
      } else {
        //Increment alchemica
        s.parcels[_tokenId].unclaimedAlchemica[_alchemicaType] += alchemicaSinceUpdate;
      }
    }

    s.parcels[_tokenId].lastUpdateTimestamp[_alchemicaType] = block.timestamp;
  }

  function increaseTraits(
    uint256 _realmId,
    uint256 _installationId,
    bool isUpgrade
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    //First save the current harvested amount
    InstallationDiamondInterface.InstallationType memory installationType = InstallationDiamondInterface(s.installationsDiamond).getInstallationType(
      _installationId
    );

    uint256 altarPrerequisite = installationType.prerequisites[0];
    uint256 lodgePrerequisite = installationType.prerequisites[1];

    // check altar requirement
    uint256 equippedAltarId = s.parcels[_realmId].altarId;
    uint256 equippedAltarLevel = InstallationDiamondInterface(s.installationsDiamond).getInstallationType(equippedAltarId).level;

    if (altarPrerequisite > 0) {
      require(equippedAltarLevel >= altarPrerequisite, "LibAlchemica: Altar Tech Tree Reqs not met");
    }

    // check lodge requirement
    if (lodgePrerequisite > 0) {
      uint256 equippedLodgeId = s.parcels[_realmId].lodgeId;
      uint256 equippedLodgeLevel = InstallationDiamondInterface(s.installationsDiamond).getInstallationType(equippedLodgeId).level;
      require(equippedLodgeLevel >= lodgePrerequisite, "LibAlchemica: Lodge Tech Tree Reqs not met");
    }

    // check harvester requirement
    if (installationType.installationType == 1) {
      require(s.parcels[_realmId].reservoirs[installationType.alchemicaType].length > 0, "LibAlchemica: Must equip reservoir of type");
    }

    uint256 alchemicaType = installationType.alchemicaType;

    //unclaimed alchemica must be settled before mutating harvestRate and capacity
    if (installationType.harvestRate > 0 || installationType.capacity > 0) {
      settleUnclaimedAlchemica(_realmId, alchemicaType);
    }

    //handle harvester
    if (installationType.harvestRate > 0) {
      s.parcels[_realmId].alchemicaHarvestRate[alchemicaType] += installationType.harvestRate;
      addHarvester(_realmId);
    }

    //reservoir
    if (installationType.capacity > 0) {
      s.parcels[_realmId].reservoirs[alchemicaType].push(_installationId);
    }

    //Altar
    if (installationType.installationType == 0) {
      require(isUpgrade || s.parcels[_realmId].altarId == 0, "LibAlchemica: Cannot equip two altars");
      s.parcels[_realmId].altarId = _installationId;
    }

    // upgradeQueueBoost
    if (installationType.upgradeQueueBoost > 0) {
      s.parcels[_realmId].upgradeQueueCapacity += installationType.upgradeQueueBoost;
    }
    //Bounce Gate
    if (installationType.installationType == 8 && !isUpgrade) {
      require(!s.bounceGates[_realmId].equipped, "LibAlchemica: Bounce Gate already equipped");
      s.bounceGates[_realmId].equipped = true;
    }
  }

  function reduceTraits(
    uint256 _realmId,
    uint256 _installationId,
    bool isUpgrade
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    InstallationDiamondInterface installationsDiamond = InstallationDiamondInterface(s.installationsDiamond);
    InstallationDiamondInterface.InstallationType memory installationType = InstallationDiamondInterface(s.installationsDiamond).getInstallationType(
      _installationId
    );
    InstallationDiamondInterface.InstallationIdIO[] memory installationBalances = installationsDiamond.installationBalancesOfToken(
      address(this),
      _realmId
    );

    uint256 alchemicaType = installationType.alchemicaType;

    //unclaimed alchemica must be settled before updating harvestRate and capacity
    if (installationType.harvestRate > 0 || installationType.capacity > 0) {
      settleUnclaimedAlchemica(_realmId, alchemicaType);
    }

    //Decrement harvest variables
    if (installationType.harvestRate > 0) {
      s.parcels[_realmId].alchemicaHarvestRate[alchemicaType] -= installationType.harvestRate;
      s.parcels[_realmId].harvesterCount--;
    }

    //Altar
    if (installationType.installationType == 0 && !isUpgrade) {
      s.parcels[_realmId].altarId = 0;
    }

    // Lodge
    if (installationType.installationType == 3) {
      s.parcels[_realmId].lodgeId = 0;
    }

    //Decrement reservoir variables
    if (installationType.capacity > 0) {
      for (uint256 i; i < s.parcels[_realmId].reservoirs[alchemicaType].length; i++) {
        if (s.parcels[_realmId].reservoirs[alchemicaType][i] == _installationId) {
          popArray(s.parcels[_realmId].reservoirs[alchemicaType], i);
          break;
        }
      }
      if (!isUpgrade && s.parcels[_realmId].unclaimedAlchemica[alchemicaType] > calculateTotalCapacity(_realmId, alchemicaType)) {
        //step 1 - unequip all harvesters
        //step 2 - claim alchemica balance
        //step 3 - unequip reservoir

        revert("LibAlchemica: Claim Alchemica before reducing capacity");
      }
    }
    //Bounce Gate
    if (installationType.installationType == 8 && !isUpgrade) {
      require(s.bounceGates[_realmId].equipped, "LibAlchemica: Bounce Gate not equipped");
      //cannot uninstall a Bounce Gate if an event is ongoing
      if (s.bounceGates[_realmId].startTime > 0) {
        require(s.bounceGates[_realmId].endTime < block.timestamp, "LibAlchemica: Ongoing event, cannot unequip Portal");
      }
      s.bounceGates[_realmId].equipped = false;
    }

    // Reduce upgrade queue boost. Handle underflow exception for bugged parcels
    if (installationType.upgradeQueueBoost > 0 && s.parcels[_realmId].upgradeQueueCapacity >= installationType.upgradeQueueBoost) {
      s.parcels[_realmId].upgradeQueueCapacity -= installationType.upgradeQueueBoost;
    }

    //Verify tech tree requirements for remaining installations
    for (uint256 i; i < installationBalances.length; i++) {
      uint256 installationId = installationBalances[i].installationId;

      // tech tree requirements are checked at the beginning of the upgradeInstallation function, so we can skip them during an upgrade
      if (!isUpgrade) {
        InstallationDiamondInterface.InstallationType memory equippedInstallation = installationsDiamond.getInstallationType(installationId);

        require(
          InstallationDiamondInterface(s.installationsDiamond).getInstallationType(s.parcels[_realmId].altarId).level >=
            equippedInstallation.prerequisites[0],
          "LibAlchemica: Altar Tech Tree Reqs not met"
        );

        // check lodge requirement
        if (equippedInstallation.prerequisites[1] > 0) {
          require(
            InstallationDiamondInterface(s.installationsDiamond).getInstallationType(s.parcels[_realmId].lodgeId).level >=
              equippedInstallation.prerequisites[1],
            "LibAlchemica: Lodge Tech Tree Reqs not met"
          );
        }
      }
    }
  }

  function alchemicaSinceLastUpdate(uint256 _tokenId, uint256 _alchemicaType) internal view returns (uint256) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 amount = (s.parcels[_tokenId].alchemicaHarvestRate[_alchemicaType] *
      (block.timestamp - s.parcels[_tokenId].lastUpdateTimestamp[_alchemicaType])) / (1 days);

    return amount;
  }

  function addHarvester(uint256 _realmId) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(addHarvesterAllowed(s.parcels[_realmId].size, s.parcels[_realmId].harvesterCount), "LibAlchemica: Too many harvesters");
    s.parcels[_realmId].harvesterCount++;
  }

  function addHarvesterAllowed(uint256 _realmSize, uint16 _harvesterCount) internal pure returns (bool) {
    if (_realmSize == 0) return _harvesterCount < 4;
    else if (_realmSize == 1) return _harvesterCount < 16;
    else if (_realmSize == 2 || _realmSize == 3) return _harvesterCount < 128;
    else if (_realmSize == 4) return _harvesterCount < 256;
    else return false;
  }

  function calculateTotalCapacity(uint256 _tokenId, uint256 _alchemicaType) internal view returns (uint256 capacity_) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    for (uint256 i; i < s.parcels[_tokenId].reservoirs[_alchemicaType].length; i++) {
      capacity_ += InstallationDiamondInterface(s.installationsDiamond).getReservoirCapacity(s.parcels[_tokenId].reservoirs[_alchemicaType][i]);
    }
  }

  function getAvailableAlchemica(uint256 _realmId, uint256 _alchemicaType) internal view returns (uint256) {
    AppStorage storage s = LibAppStorage.diamondStorage();

    uint256 remaining = s.parcels[_realmId].alchemicaRemaining[_alchemicaType];

    if (remaining == 0) return remaining;

    //First get the onchain amount
    uint256 available = s.parcels[_realmId].unclaimedAlchemica[_alchemicaType];
    //Then get the floating amount
    available += alchemicaSinceLastUpdate(_realmId, _alchemicaType);

    uint256 capacity = calculateTotalCapacity(_realmId, _alchemicaType);

    //ensure that available alchemica is not higher than available reservoir capacity
    return available < capacity ? available : capacity;
  }

  function calculateTransferAmounts(uint256 _amount, uint256 _spilloverRate) internal pure returns (uint256 owner, uint256 spill) {
    owner = (_amount * (bp - (_spilloverRate * 10**16))) / bp;
    spill = (_amount * (_spilloverRate * 10**16)) / bp;
  }

  function calculateSpilloverForReservoir(uint256 _realmId, uint256 _alchemicaType)
    internal
    view
    returns (uint256 spilloverRate, uint256 spilloverRadius)
  {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 capacityXspillrate;
    uint256 capacityXspillradius;
    uint256 totalCapacity;
    for (uint256 i; i < s.parcels[_realmId].reservoirs[_alchemicaType].length; i++) {
      InstallationDiamondInterface.ReservoirStats memory reservoirStats = InstallationDiamondInterface(s.installationsDiamond).getReservoirStats(
        s.parcels[_realmId].reservoirs[_alchemicaType][i]
      );
      totalCapacity += reservoirStats.capacity;

      capacityXspillrate += reservoirStats.capacity * reservoirStats.spillRate;
      capacityXspillradius += reservoirStats.capacity * reservoirStats.spillRadius;
    }
    if (totalCapacity == 0) return (0, 0);

    spilloverRate = capacityXspillrate / totalCapacity;
    spilloverRadius = capacityXspillradius / totalCapacity;
  }

  function getAllRoundAlchemica(uint256 _realmId, uint256 _alchemicaType) internal view returns (uint256 alchemica) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    for (uint256 i; i < s.parcels[_realmId].currentRound; i++) {
      alchemica += s.parcels[_realmId].roundAlchemica[i][_alchemicaType];
    }
  }

  function getTotalClaimed(uint256 _realmId, uint256 _alchemicaType) internal view returns (uint256 totalClaimed) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    totalClaimed = getAllRoundAlchemica(_realmId, _alchemicaType) - s.parcels[_realmId].alchemicaRemaining[_alchemicaType];
  }

  function claimAvailableAlchemica(uint256 _realmId, uint256 _gotchiId) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    require(block.timestamp > s.lastClaimedAlchemica[_realmId] + 8 hours, "AlchemicaFacet: 8 hours claim cooldown");
    s.lastClaimedAlchemica[_realmId] = block.timestamp;

    for (uint256 i; i < 4; i++) {
      uint256 remaining = s.parcels[_realmId].alchemicaRemaining[i];
      uint256 available = getAvailableAlchemica(_realmId, i);
      available = remaining < available ? remaining : available;

      s.parcels[_realmId].alchemicaRemaining[i] -= available;
      s.parcels[_realmId].unclaimedAlchemica[i] = 0;
      s.parcels[_realmId].lastUpdateTimestamp[i] = block.timestamp;

      (uint256 spilloverRate, uint256 spilloverRadius) = calculateSpilloverForReservoir(_realmId, i);
      (uint256 ownerAmount, uint256 spillAmount) = calculateTransferAmounts(available, spilloverRate);

      //Mint new tokens
      mintAvailableAlchemica(i, _gotchiId, ownerAmount, spillAmount);

      emit AlchemicaClaimed(_realmId, _gotchiId, i, available, spilloverRate, spilloverRadius);
    }
  }

  function mintAvailableAlchemica(
    uint256 _alchemicaType,
    uint256 _gotchiId,
    uint256 _ownerAmount,
    uint256 _spillAmount
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    IERC20Mintable alchemica = IERC20Mintable(s.alchemicaAddresses[_alchemicaType]);

    if (_ownerAmount > 0) alchemica.mint(alchemicaRecipient(_gotchiId), _ownerAmount);
    if (_spillAmount > 0) alchemica.mint(address(this), _spillAmount);
  }

  function alchemicaRecipient(uint256 _gotchiId) internal view returns (address) {
    AppStorage storage s = LibAppStorage.diamondStorage();

    AavegotchiDiamond diamond = AavegotchiDiamond(s.aavegotchiDiamond);
    if (diamond.isAavegotchiLent(uint32(_gotchiId))) {
      return diamond.gotchiEscrow(_gotchiId);
    } else {
      return diamond.ownerOf(_gotchiId);
    }
  }

  function popArray(uint256[] storage _array, uint256 _index) internal {
    _array[_index] = _array[_array.length - 1];
    _array.pop();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface InstallationDiamondInterface {
  struct InstallationType {
    //slot 1
    uint8 width;
    uint8 height;
    uint16 installationType; //0 = altar, 1 = harvester, 2 = reservoir, 3 = gotchi lodge, 4 = wall, 5 = NFT display, 6 = buildqueue booster
    uint8 level; //max level 9
    uint8 alchemicaType; //0 = none 1 = fud, 2 = fomo, 3 = alpha, 4 = kek
    uint32 spillRadius;
    uint16 spillRate;
    uint8 upgradeQueueBoost;
    uint32 craftTime; // in blocks
    uint32 nextLevelId; //the ID of the next level of this installation. Used for upgrades.
    bool deprecated; //bool
    //slot 2
    uint256[4] alchemicaCost; // [fud, fomo, alpha, kek]
    //slot 3
    uint256 harvestRate;
    //slot 4
    uint256 capacity;
    //slot 5
    uint256[] prerequisites; //IDs of installations that must be present before this installation can be added
    //slot 6
    string name;
  }

  struct UpgradeQueue {
    address owner;
    uint16 coordinateX;
    uint16 coordinateY;
    uint40 readyBlock;
    bool claimed;
    uint256 parcelId;
    uint256 installationId;
  }

  struct InstallationIdIO {
    uint256 installationId;
    uint256 balance;
  }

  struct ReservoirStats {
    uint256 spillRate;
    uint256 spillRadius;
    uint256 capacity;
  }

  function craftInstallations(uint256[] calldata _installationTypes) external;

  function claimInstallations(uint256[] calldata _queueIds) external;

  function equipInstallation(
    address _owner,
    uint256 _realmTokenId,
    uint256 _installationId
  ) external;

  function unequipInstallation(
    address _owner,
    uint256 _realmId,
    uint256 _installationId
  ) external;

  function addInstallationTypes(InstallationType[] calldata _installationTypes) external;

  function getInstallationType(uint256 _itemId) external view returns (InstallationType memory installationType);

  function getInstallationUnequipType(uint256 _installationId) external view returns (uint256);

  function getInstallationTypes(uint256[] calldata _itemIds) external view returns (InstallationType[] memory itemTypes_);

  function getAlchemicaAddresses() external view returns (address[] memory);

  function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_);

  function balanceOfToken(
    address _tokenContract,
    uint256 _tokenId,
    uint256 _id
  ) external view returns (uint256 value);

  function installationBalancesOfTokenByIds(
    address _tokenContract,
    uint256 _tokenId,
    uint256[] calldata _ids
  ) external view returns (uint256[] memory);

  function installationBalancesOfToken(address _tokenContract, uint256 _tokenId) external view returns (InstallationIdIO[] memory bals_);

  function spilloverRatesOfIds(uint256[] calldata _ids) external view returns (uint256[] memory);

  function upgradeInstallation(UpgradeQueue calldata _upgradeQueue, bytes memory _signature) external;

  function finalizeUpgrade() external;

  function installationsBalances(address _account) external view returns (InstallationIdIO[] memory bals_);

  function spilloverRateAndRadiusOfId(uint256 _id) external view returns (uint256, uint256);

  function getAltarLevel(uint256 _altarId) external view returns (uint256 altarLevel_);

  function getLodgeLevel(uint256 _installationId) external view returns (uint256 lodgeLevel_);

  function getReservoirCapacity(uint256 _installationId) external view returns (uint256 capacity_);

  function getReservoirStats(uint256 _installationId) external view returns (ReservoirStats memory reservoirStats_);

  function parcelQueueEmpty(uint256 _parcelId) external view returns (bool);

  function getParcelUpgradeQueue(uint256 _parcelId) external view returns (UpgradeQueue[] memory output_, uint256[] memory indexes_);

  function parcelInstallationUpgrading(
    uint256 _parcelId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibSignature {

    function isValid(bytes32 messageHash, bytes memory signature, bytes memory pubKey) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == address(uint160(uint256(keccak256(pubKey))));
    }

    function getEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC1155Marketplace {
  function updateERC1155Listing(
    address _erc1155TokenAddress,
    uint256 _erc1155TypeId,
    address _owner
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

interface AavegotchiDiamond {
  struct GotchiLending {
    // storage slot 1
    address lender;
    uint96 initialCost; // GHST in wei, can be zero
    // storage slot 2
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId; // can be zero
    // storage slot 3
    address originalOwner; // if original owner is lender, same as lender
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    // storage slot 4
    address thirdParty; // can be address(0)
    uint8[3] revenueSplit; // lender/original owner, borrower, thirdParty
    uint40 lastClaimed; //timestamp
    uint32 period; //in seconds
    // storage slot 5
    address[] revenueTokens;
  }

  function ownerOf(uint256 _tokenId) external view returns (address owner_);

  function gotchiEscrow(uint256 _tokenId) external view returns (address);

  function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);

  function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);

  function addGotchiLending(
    uint32 _erc721TokenId,
    uint96 _initialCost,
    uint32 _period,
    uint8[3] calldata _revenueSplit,
    address _originalOwner,
    address _thirdParty,
    uint32 _whitelistId,
    address[] calldata _revenueTokens
  ) external;

  function agreeGotchiLending(
    uint32 _listingId,
    uint32 _erc721TokenId,
    uint96 _initialCost,
    uint32 _period,
    uint8[3] calldata _revenueSplit
  ) external;

  function kinship(uint256 _tokenId) external view returns (uint256 score_);

  function realmInteract(uint256 _tokenId) external;

  // whitelist functions
  function createWhitelist(string calldata _name, address[] calldata _whitelistAddresses) external;

  function whitelistOwner(uint32 _whitelistId) external view returns (address);

  function isWhitelisted(uint32 _whitelistId, address _whitelistAddress) external view returns (uint256);

  function getWhitelistsLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title IERC721TokenReceiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721. Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface TileDiamondInterface {
  struct TileType {
    uint256 width;
    uint256 height;
    bool deprecated;
    uint16 tileType;
    uint256[4] alchemicaCost; // [fud, fomo, alpha, kek]
    uint256 craftTime; // in blocks
    string name;
  }

  struct TileIdIO {
    uint256 tileId;
    uint256 balance;
  }

  function craftTiles(uint256[] calldata _tileTypes) external;

  function claimTiles(uint256[] calldata _queueIds) external;

  function equipTile(
    address _owner,
    uint256 _realmTokenId,
    uint256 _tileId
  ) external;

  function unequipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) external;

  function addTileTypes(TileType[] calldata _tileTypes) external;

  function getTileType(uint256 _itemId) external view returns (TileType memory tileType);

  function getTileTypes(uint256[] calldata _itemIds) external view returns (TileType[] memory itemTypes_);

  function getAlchemicaAddresses() external view returns (address[] memory);

  function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_);

  function tileBalancesOfTokenByIds(
    address _tokenContract,
    uint256 _tokenId,
    uint256[] calldata _ids
  ) external view returns (uint256[] memory);

  function tilesBalances(address _account) external view returns (TileIdIO[] memory bals_);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library BinomialRandomizer {
  uint256 private constant BASE_DENOMINATOR = 10_000;

  /// @notice Calculates the alchemica amount of parcels
  /// @param seed The seed to use for the randomization
  /// @param average The average value of the randomization
  /// @return totalPull A random value calculated by the binomial distribution
  /// @dev Arbitrary fields are chosen to make the distribution meet the average
  /// and provide a desirable distribution curve
  // prettier-ignore
  function calculateAlchemicaSurveyAmount(uint256 seed, uint256 average) internal pure returns (uint256 totalPull) {
    totalPull =
      (simulateBinomial(
        seed, 
        30, // Number of rolls 
        4, // Reciprocal of the chance to win
        13, // The amount of tail to cut off to prevent a heavy tail
        60_000_000, // The floor is 60% of the average 
        73_000_000, // Arbitrary
        14_000) //Arbitrary
        * average) /  100_000_000;
  }

  function simulateBinomial(
    uint256 seed,
    uint256 n,
    uint256 divisor,
    uint256 rightTailCutoff,
    uint256 floor,
    uint256 base,
    uint256 multiplier
  ) internal pure returns (uint256 value) {
    uint256 rolls = countRolls(seed, n, divisor);
    if (rolls > n - rightTailCutoff) rolls = n - rightTailCutoff;
    value = (base * getMultiplierResult(rolls, multiplier)) / (n * BASE_DENOMINATOR) + floor;
  }

  /// @notice Helper function to exponentiate the result based on the number of successful rolls
  /// @param rolls The number of successful rolls
  /// @param multiplier The multiplier to use for exponentiation
  function getMultiplierResult(
    uint256 rolls,
    uint256 multiplier // scaled by BASE_DENOMINATOR
  ) internal pure returns (uint256 result) {
    // Start at multiplier^0 = 1
    result = BASE_DENOMINATOR;
    // For each roll, multiply
    for (uint256 i = 0; i < rolls; ) {
      result = (result * multiplier) / BASE_DENOMINATOR;
      unchecked {
        ++i;
      }
    }
    result -= BASE_DENOMINATOR;
  }

  /// @notice Helper function that uses the random seed to generate and count a sequence of rolls
  /// @param seed The seed to use for the randomization
  /// @param n The number of rolls to generate
  /// @param divisor The reciprocal of the chance to win
  function countRolls(
    uint256 seed,
    uint256 n,
    uint256 divisor
  ) internal pure returns (uint256 rolls) {
    uint256 workingSeed = seed; // We keep the old seed around to generate a new seed.
    for (uint256 i = 0; i < n; ) {
      if (workingSeed % divisor == 0) {
        unchecked {
          ++rolls;
        }
      }
      // If there is not enough value left for the next roll, we make a new seed.
      if ((workingSeed /= divisor) < divisor**4) {
        workingSeed = uint256(keccak256(abi.encode(seed, i)));
      }
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
  function mint(address _to, uint256 _amount) external;
}