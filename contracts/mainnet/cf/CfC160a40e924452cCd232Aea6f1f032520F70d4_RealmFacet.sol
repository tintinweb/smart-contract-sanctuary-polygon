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
import "./ERC721Facet.sol";

contract RealmFacet is Modifiers {
  uint256 constant MAX_SUPPLY = 420069;

  struct MintParcelInput {
    uint256 coordinateX;
    uint256 coordinateY;
    uint256 district;
    string parcelId;
    string parcelAddress;
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256[4] boost; //fud, fomo, alpha, kek
  }

  event ResyncParcel(uint256 _realmId);
  event EquipInstallation(uint256 _realmId, uint256 _installationId, uint256 _x, uint256 _y);
  event UnequipInstallation(uint256 _realmId, uint256 _installationId, uint256 _x, uint256 _y);
  event EquipTile(uint256 _realmId, uint256 _tileId, uint256 _x, uint256 _y);
  event UnequipTile(uint256 _realmId, uint256 _tileId, uint256 _x, uint256 _y);
  event AavegotchiDiamondUpdated(address _aavegotchiDiamond);
  event InstallationUpgraded(uint256 _realmId, uint256 _prevInstallationId, uint256 _nextInstallationId, uint256 _coordinateX, uint256 _coordinateY);

  /// @notice Return the maximum realm supply
  /// @return The max realm token supply
  function maxSupply() external pure returns (uint256) {
    return MAX_SUPPLY;
  }

  /// @notice Allow the diamond owner to mint new parcels
  /// @param _to The address to mint the parcels to
  /// @param _tokenIds The identifiers of tokens to mint
  /// @param _metadata An array of structs containing the metadata of each parcel being minted
  function mintParcels(
    address _to,
    uint256[] calldata _tokenIds,
    MintParcelInput[] memory _metadata
  ) external onlyOwner {
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      require(s.tokenIds.length < MAX_SUPPLY, "RealmFacet: Cannot mint more than 420,069 parcels");
      uint256 tokenId = _tokenIds[index];
      MintParcelInput memory metadata = _metadata[index];
      require(_tokenIds.length == _metadata.length, "Inputs must be same length");

      Parcel storage parcel = s.parcels[tokenId];
      parcel.coordinateX = metadata.coordinateX;
      parcel.coordinateY = metadata.coordinateY;
      parcel.parcelId = metadata.parcelId;
      parcel.size = metadata.size;
      parcel.district = metadata.district;
      parcel.parcelAddress = metadata.parcelAddress;

      parcel.alchemicaBoost = metadata.boost;

      LibERC721.safeMint(_to, tokenId);
    }
  }

  /// @notice Allow a parcel owner to equip an installation
  /// @dev The _x and _y denote the starting coordinates of the installation and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the installation is being equipped on
  /// @param _installationId The identifier of the installation being equipped
  /// @param _x The x(horizontal) coordinate of the installation
  /// @param _y The y(vertical) coordinate of the installation
  function equipInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) external onlyParcelOwner(_realmId) gameActive {
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _installationId, _x, _y)), _signature, s.backendPubKey),
      "RealmFacet: Invalid signature"
    );
    InstallationDiamondInterface.InstallationType memory installation = InstallationDiamondInterface(s.installationsDiamond).getInstallationType(
      _installationId
    );
    if (installation.installationType == 1 || installation.installationType == 2) {
      require(s.parcels[_realmId].currentRound >= 1, "RealmFacet: Must survey before equipping");
    }
    if (installation.installationType == 3) {
      require(s.parcels[_realmId].lodgeId == 0, "RealmFacet: Lodge already equipped");
      s.parcels[_realmId].lodgeId = _installationId;
    }

    LibRealm.placeInstallation(_realmId, _installationId, _x, _y);
    InstallationDiamondInterface(s.installationsDiamond).equipInstallation(msg.sender, _realmId, _installationId);

    LibAlchemica.increaseTraits(_realmId, _installationId, false);

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
    uint256 _installationId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) external onlyParcelOwner(_realmId) gameActive {
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _installationId, _x, _y)), _signature, s.backendPubKey),
      "RealmFacet: Invalid signature"
    );

    InstallationDiamondInterface installationsDiamond = InstallationDiamondInterface(s.installationsDiamond);
    InstallationDiamondInterface.InstallationType memory installation = installationsDiamond.getInstallationType(_installationId);

    LibRealm.removeInstallation(_realmId, _installationId, _x, _y);

    for (uint256 i; i < installation.alchemicaCost.length; i++) {
      IERC20 alchemica = IERC20(s.alchemicaAddresses[i]);

      //@question : include upgrades in refund?
      uint256 alchemicaRefund = installation.alchemicaCost[i] / 2;

      alchemica.transfer(msg.sender, alchemicaRefund);
    }
    InstallationDiamondInterface(s.installationsDiamond).unequipInstallation(_realmId, _installationId);

    LibAlchemica.reduceTraits(_realmId, _installationId, false);

    emit UnequipInstallation(_realmId, _installationId, _x, _y);
  }

  /// @notice Allow a parcel owner to equip a tile
  /// @dev The _x and _y denote the starting coordinates of the tile and are used to make sure that slot is available on a parcel
  /// @param _realmId The identifier of the parcel which the tile is being equipped on
  /// @param _tileId The identifier of the tile being equipped
  /// @param _x The x(horizontal) coordinate of the tile
  /// @param _y The y(vertical) coordinate of the tile
  function equipTile(
    uint256 _realmId,
    uint256 _tileId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) external onlyParcelOwner(_realmId) gameActive {
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _tileId, _x, _y)), _signature, s.backendPubKey),
      "RealmFacet: Invalid signature"
    );
    LibRealm.placeTile(_realmId, _tileId, _x, _y);
    TileDiamondInterface(s.tileDiamond).equipTile(msg.sender, _realmId, _tileId);

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
    uint256 _tileId,
    uint256 _x,
    uint256 _y,
    bytes memory _signature
  ) external onlyParcelOwner(_realmId) gameActive {
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _tileId, _x, _y)), _signature, s.backendPubKey),
      "RealmFacet: Invalid signature"
    );
    LibRealm.removeTile(_realmId, _tileId, _x, _y);

    TileDiamondInterface(s.tileDiamond).unequipTile(msg.sender, _realmId, _tileId);

    emit UnequipTile(_realmId, _tileId, _x, _y);
  }

  function setParcelsAccessRights(
    uint256[] calldata _realmIds,
    uint256[] calldata _actionRights,
    uint256[] calldata _accessRights
  ) external gameActive {
    require(_realmIds.length == _accessRights.length && _realmIds.length == _actionRights.length, "RealmFacet: Mismatched arrays");
    for (uint256 i; i < _realmIds.length; i++) {
      require(LibMeta.msgSender() == s.parcels[_realmIds[i]].owner, "RealmFacet: Only Parcel owner can call");
      s.accessRights[_realmIds[i]][_actionRights[i]] = _accessRights[i];
    }
  }

  struct ParcelOutput {
    string parcelId;
    string parcelAddress;
    address owner;
    uint256 coordinateX; //x position on the map
    uint256 coordinateY; //y position on the map
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256 district;
    uint256[4] boost;
    uint256 timeRemainingToClaim;
  }

  /**
  @dev Used to resync a parcel on the subgraph if metadata is added later 
@param _tokenIds The parcels to resync
  */
  function resyncParcel(uint256[] calldata _tokenIds) external onlyOwner {
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      emit ResyncParcel(_tokenIds[index]);
    }
  }

  function setGameActive(bool _gameActive) external onlyOwner {
    s.gameActive = _gameActive;
  }

  /// @notice Fetch information about a parcel
  /// @param _realmId The identifier of the parcel being queried
  /// @return output_ A struct containing details about the parcel being queried
  function getParcelInfo(uint256 _realmId) external view returns (ParcelOutput memory output_) {
    Parcel storage parcel = s.parcels[_realmId];
    output_.parcelId = parcel.parcelId;
    output_.owner = parcel.owner;
    output_.coordinateX = parcel.coordinateX;
    output_.coordinateY = parcel.coordinateY;
    output_.size = parcel.size;
    output_.parcelAddress = parcel.parcelAddress;
    output_.district = parcel.district;
    output_.boost = parcel.alchemicaBoost;
    output_.timeRemainingToClaim = s.lastClaimedAlchemica[_realmId];
  }

  function checkCoordinates(
    uint256 _realmId,
    uint256 _coordinateX,
    uint256 _coordinateY,
    uint256 _installationId
  ) public view {
    Parcel storage parcel = s.parcels[_realmId];
    require(parcel.buildGrid[_coordinateX][_coordinateY] == _installationId, "RealmFacet: wrong coordinates");
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

  function getHumbleGrid(uint256 _parcelId, uint256 _gridType) external view returns (uint256[8][8] memory output_) {
    require(s.parcels[_parcelId].size == 0, "RealmFacet: Not humble");
    for (uint256 i; i < 8; i++) {
      for (uint256 j; j < 8; j++) {
        if (_gridType == 0) {
          output_[i][j] = s.parcels[_parcelId].buildGrid[j][i];
        } else if (_gridType == 1) {
          output_[i][j] = s.parcels[_parcelId].tileGrid[j][i];
        }
      }
    }
  }

  function getReasonableGrid(uint256 _parcelId, uint256 _gridType) external view returns (uint256[16][16] memory output_) {
    require(s.parcels[_parcelId].size == 1, "RealmFacet: Not reasonable");
    for (uint256 i; i < 16; i++) {
      for (uint256 j; j < 16; j++) {
        if (_gridType == 0) {
          output_[i][j] = s.parcels[_parcelId].buildGrid[j][i];
        } else if (_gridType == 1) {
          output_[i][j] = s.parcels[_parcelId].tileGrid[j][i];
        }
      }
    }
  }

  function getSpaciousVerticalGrid(uint256 _parcelId, uint256 _gridType) external view returns (uint256[32][64] memory output_) {
    require(s.parcels[_parcelId].size == 2, "RealmFacet: Not spacious vertical");
    for (uint256 i; i < 64; i++) {
      for (uint256 j; j < 32; j++) {
        if (_gridType == 0) {
          output_[i][j] = s.parcels[_parcelId].buildGrid[j][i];
        } else if (_gridType == 1) {
          output_[i][j] = s.parcels[_parcelId].tileGrid[j][i];
        }
      }
    }
  }

  function getSpaciousHorizontalGrid(uint256 _parcelId, uint256 _gridType) external view returns (uint256[64][32] memory output_) {
    require(s.parcels[_parcelId].size == 3, "RealmFacet: Not spacious horizontal");
    for (uint256 i; i < 32; i++) {
      for (uint256 j; j < 64; j++) {
        if (_gridType == 0) {
          output_[i][j] = s.parcels[_parcelId].buildGrid[j][i];
        } else if (_gridType == 1) {
          output_[i][j] = s.parcels[_parcelId].tileGrid[j][i];
        }
      }
    }
  }

  function getPaartnerGrid(uint256 _parcelId, uint256 _gridType) external view returns (uint256[64][64] memory output_) {
    require(s.parcels[_parcelId].size == 4, "RealmFacet: Not paartner");
    for (uint256 i; i < 64; i++) {
      for (uint256 j; j < 64; j++) {
        if (_gridType == 0) {
          output_[i][j] = s.parcels[_parcelId].buildGrid[j][i];
        } else if (_gridType == 1) {
          output_[i][j] = s.parcels[_parcelId].tileGrid[j][i];
        }
      }
    }
  }

  struct ParcelCoordinates {
    uint256[64][64] coords;
  }

  function batchGetGrid(uint256[] calldata _parcelIds, uint256 _gridType) external view returns (ParcelCoordinates[] memory) {
    ParcelCoordinates[] memory parcels = new ParcelCoordinates[](_parcelIds.length);
    for (uint256 k; k < _parcelIds.length; k++) {
      for (uint256 i; i < 64; i++) {
        for (uint256 j; j < 64; j++) {
          if (_gridType == 0) {
            parcels[k].coords[i][j] = s.parcels[_parcelIds[k]].buildGrid[j][i];
          } else if (_gridType == 1) {
            parcels[k].coords[i][j] = s.parcels[_parcelIds[k]].tileGrid[j][i];
          }
        }
      }
    }
    return parcels;
  }

  function batchGetDistrictParcels(address _owner, uint256 _district) external view returns (uint256[] memory) {
    uint256 totalSupply = ERC721Facet(address(this)).totalSupply();
    uint256 balance = ERC721Facet(address(this)).balanceOf(_owner);
    uint256[] memory output_ = new uint256[](balance);
    uint256 counter;
    for (uint256 i; i < totalSupply; i++) {
      if (s.parcels[i].district == _district && s.parcels[i].owner == _owner) {
        output_[counter] = i;
        counter++;
      }
    }
    return output_;
  }

  function getParcelUpgradeQueueLength(uint256 _parcelId) external view returns (uint256) {
    return s.parcels[_parcelId].upgradeQueueLength;
  }

  function getParcelUpgradeQueueCapacity(uint256 _parcelId) external view returns (uint256) {
    return s.parcels[_parcelId].upgradeQueueCapacity;
  }

  function getParcelsAccessRights(uint256[] calldata _parcelIds, uint256[] calldata _actionRights) external view returns (uint256[] memory output_) {
    require(_parcelIds.length == _actionRights.length, "RealmFacet: Mismatched arrays");
    output_ = new uint256[](_parcelIds.length);
    for (uint256 i; i < _parcelIds.length; i++) {
      output_[i] = s.accessRights[_parcelIds[i]][_actionRights[i]];
    }
  }

  function fixAltarLevel(uint256[] memory _parcelIds) external onlyOwner {
    InstallationDiamondInterface installationsDiamond = InstallationDiamondInterface(s.installationsDiamond);
    for (uint256 i; i < _parcelIds.length; i++) {
      uint256 parcelId = _parcelIds[i];
      Parcel storage parcel = s.parcels[parcelId];
      // Check that the altar is actually supposed to be level 2
      if (installationsDiamond.balanceOfToken(address(this), parcelId, 11) >= 1 && parcel.altarId == 10) {
        parcel.altarId = 11;
      }
    }
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
  // parcelId => action: 0 Alchemical Channeling, 1 Emptying Reservoirs => permission: 0 Owner only, 1 Owner + Borrowed Gotchis, 2 Any Gotchi
  mapping(uint256 => mapping(uint256 => uint256)) accessRights;
  // gotchiId => lastChanneledDay
  mapping(uint256 => uint256) lastChanneledDay;
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

    //Update indexes and arrays

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

library LibRealm {
  event SurveyParcel(uint256 _tokenId, uint256[] _alchemicas);

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
    for (uint256 indexW = _x; indexW < _x + installation.width; indexW++) {
      for (uint256 indexH = _y; indexH < _y + installation.height; indexH++) {
        parcel.buildGrid[indexW][indexH] = 0;
      }
    }
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
    for (uint256 indexW = _x; indexW < _x + tile.width; indexW++) {
      for (uint256 indexH = _y; indexH < _y + tile.height; indexH++) {
        parcel.tileGrid[indexW][indexH] = 0;
      }
    }
  }

  function calculateAmount(
    uint256 _tokenId,
    uint256[] memory randomWords,
    uint256 i
  ) internal view returns (uint256) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    return (randomWords[i] % s.totalAlchemicas[s.parcels[_tokenId].size][i]);
  }

  function updateRemainingAlchemica(
    uint256 _tokenId,
    uint256[] memory randomWords,
    uint256 _round
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    require(s.parcels[_tokenId].currentRound <= s.surveyingRound, "AlchemicaFacet: Round not released");
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
    emit SurveyParcel(_tokenId, alchemicas);
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {InstallationDiamondInterface} from "../interfaces/InstallationDiamondInterface.sol";
import {LibAppStorage, AppStorage, Parcel} from "./AppStorage.sol";

library LibAlchemica {
  function settleUnclaimedAlchemica(uint256 _tokenId, uint256 _alchemicaType) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    // uint256 capacity = s.parcels[_tokenId].reservoirCapacity[_alchemicaType];
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

  function alchemicaSinceLastUpdate(uint256 _tokenId, uint256 _alchemicaType) internal view returns (uint256) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 amount = s.parcels[_tokenId].alchemicaHarvestRate[_alchemicaType] *
      (block.timestamp - s.parcels[_tokenId].lastUpdateTimestamp[_alchemicaType]);

    return amount;
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

    // uint256 altarPrerequisite = installationType.prerequisites[0];
    uint256 lodgePrerequisite = installationType.prerequisites[1];

    //Temporarily disable Altar check to allow bugged upgrades to be fixed.
    // check altar requirement
    // uint256 equippedAltarId = s.parcels[_realmId].altarId;
    // uint256 equippedAltarLevel = InstallationDiamondInterface(s.installationsDiamond).getInstallationType(equippedAltarId).level;

    // require(equippedAltarLevel >= altarPrerequisite, "RealmFacet: Altar Tech Tree Reqs not met");

    // check lodge requirement
    if (lodgePrerequisite > 0) {
      uint256 equippedLodgeId = s.parcels[_realmId].lodgeId;
      uint256 equippedLodgeLevel = InstallationDiamondInterface(s.installationsDiamond).getInstallationType(equippedLodgeId).level;
      require(equippedLodgeLevel >= lodgePrerequisite, "RealmFacet: Lodge Tech Tree Reqs not met");
    }

    // check harvester requirement
    if (installationType.installationType == 1) {
      require(s.parcels[_realmId].reservoirs[installationType.alchemicaType].length > 0, "RealmFacet: Must equip reservoir of type");
    }

    uint256 alchemicaType = installationType.alchemicaType;

    //unclaimed alchemica must be settled before mutating harvestRate and capacity
    if (installationType.harvestRate > 0 || installationType.capacity > 0) {
      settleUnclaimedAlchemica(_realmId, alchemicaType);
    }

    //handle harvester
    if (installationType.harvestRate > 0) {
      s.parcels[_realmId].alchemicaHarvestRate[alchemicaType] += installationType.harvestRate;
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

    for (uint256 i; i < installationBalances.length; i++) {
      InstallationDiamondInterface.InstallationType memory equippedInstallaion = installationsDiamond.getInstallationType(_installationId);

      // check altar requirement
      require(
        InstallationDiamondInterface(s.installationsDiamond).getInstallationType(s.parcels[_realmId].altarId).level >=
          equippedInstallaion.prerequisites[0],
        "RealmFacet: Altar Tech Tree Reqs not met"
      );

      // check lodge requirement
      if (equippedInstallaion.prerequisites[1] > 0) {
        require(
          InstallationDiamondInterface(s.installationsDiamond).getInstallationType(s.parcels[_realmId].lodgeId).level >=
            equippedInstallaion.prerequisites[1],
          "RealmFacet: Lodge Tech Tree Reqs not met"
        );
      }
    }

    uint256 alchemicaType = installationType.alchemicaType;

    //unclaimed alchemica must be settled before updating harvestRate and capacity
    if (installationType.harvestRate > 0 || installationType.capacity > 0) {
      settleUnclaimedAlchemica(_realmId, alchemicaType);
    }

    //Decrement harvest variables
    if (installationType.harvestRate > 0) {
      s.parcels[_realmId].alchemicaHarvestRate[alchemicaType] -= installationType.harvestRate;
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
      if (s.parcels[_realmId].unclaimedAlchemica[alchemicaType] > calculateTotalCapacity(_realmId, alchemicaType)) {
        //step 1 - unequip all harvesters
        //step 2 - claim alchemica balance
        //step 3 - unequip reservoir
        revert("LibAlchemica: Unclaimed alchemica greater than reservoir capacity");
      }
    }

    // upgradeQueueBoost
    if (installationType.upgradeQueueBoost > 0) {
      s.parcels[_realmId].upgradeQueueCapacity -= installationType.upgradeQueueBoost;
    }
  }

  function calculateTotalCapacity(uint256 _tokenId, uint256 _alchemicaType) internal view returns (uint256 capacity_) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    for (uint256 i; i < s.parcels[_tokenId].reservoirs[_alchemicaType].length; i++) {
      capacity_ += InstallationDiamondInterface(s.installationsDiamond).getReservoirCapacity(s.parcels[_tokenId].reservoirs[_alchemicaType][i]);
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
    uint256 parcelId;
    uint256 coordinateX;
    uint256 coordinateY;
    uint256 installationId;
    uint256 readyBlock;
    bool claimed;
    address owner;
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

  function unequipInstallation(uint256 _realmId, uint256 _installationId) external;

  function addInstallationTypes(InstallationType[] calldata _installationTypes) external;

  function getInstallationType(uint256 _itemId) external view returns (InstallationType memory installationType);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../libraries/AppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibStrings.sol";
import "../../libraries/LibMeta.sol";
import "../../libraries/LibERC721.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {ERC721Marketplace} from "../../interfaces/ERC721Marketplace.sol";

contract ERC721Facet is Modifiers {
  // bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  function tokenIdsOfOwner(address _owner) external view returns (uint256[] memory tokenIds_) {
    return s.ownerTokenIds[_owner];
  }

  function totalSupply() external view returns (uint256) {
    return s.tokenIds.length;
  }

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return tokenId_ The token identifier for the `_index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 _index) external view returns (uint256 tokenId_) {
    require(_index < s.tokenIds.length, "AavegotchiFacet: _index is greater than total supply.");
    tokenId_ = s.tokenIds[_index];
  }

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this.
  ///  function throws for queries about the zero address.
  /// @param _owner An address for whom to query the balance
  /// @return balance_ The number of NFTs owned by `_owner`, possibly zero
  function balanceOf(address _owner) external view returns (uint256 balance_) {
    balance_ = s.ownerTokenIds[_owner].length;
  }

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param _tokenId The identifier for an NFT
  /// @return owner_ The address of the owner of the NFT
  function ownerOf(uint256 _tokenId) external view returns (address owner_) {
    owner_ = s.parcels[_tokenId].owner;
  }

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `_tokenId` is not a valid NFT.
  /// @param _tokenId The NFT to find the approved address for
  /// @return approved_ The approved address for this NFT, or the zero address if there is none
  function getApproved(uint256 _tokenId) external view returns (address approved_) {
    require(s.parcels[_tokenId].owner != address(0), "AavegotchiFacet: tokenId is invalid or is not owned");
    approved_ = s.approved[_tokenId];
  }

  /// @notice Query if an address is an authorized operator for another address
  /// @param _owner The address that owns the NFTs
  /// @param _operator The address that acts on behalf of the owner
  /// @return approved_ True if `_operator` is an approved operator for `_owner`, false otherwise
  function isApprovedForAll(address _owner, address _operator) external view returns (bool approved_) {
    approved_ = s.operators[_owner][_operator];
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `_to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  /// @param _data Additional data with no specified format, sent in call to `_to`
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) public {
    address sender = LibMeta.msgSender();
    LibERC721.transferFrom(sender, _from, _to, _tokenId);
    LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, _data);

    //Update baazaar listing

    if (s.aavegotchiDiamond != address(0)) {
      ERC721Marketplace(s.aavegotchiDiamond).updateERC721Listing(address(this), _tokenId, _from);
    }
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external {
    address sender = LibMeta.msgSender();
    LibERC721.transferFrom(sender, _from, _to, _tokenId);
    LibERC721.checkOnERC721Received(sender, _from, _to, _tokenId, "");

    //Update baazaar listing
    if (s.aavegotchiDiamond != address(0)) {
      ERC721Marketplace(s.aavegotchiDiamond).updateERC721Listing(address(this), _tokenId, _from);
    }
  }

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `msg.sender` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `_from` is
  ///  not the current owner. Throws if `_to` is the zero address. Throws if
  ///  `_tokenId` is not a valid NFT.
  /// @param _from The current owner of the NFT
  /// @param _to The new owner
  /// @param _tokenId The NFT to transfer
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external {
    address sender = LibMeta.msgSender();
    LibERC721.transferFrom(sender, _from, _to, _tokenId);

    if (s.aavegotchiDiamond != address(0)) {
      ERC721Marketplace(s.aavegotchiDiamond).updateERC721Listing(address(this), _tokenId, _from);
    }
  }

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param _approved The new approved NFT controller
  /// @param _tokenId The NFT to approve
  function approve(address _approved, uint256 _tokenId) external {
    address owner = s.parcels[_tokenId].owner;
    address sender = LibMeta.msgSender();
    require(owner == sender || s.operators[owner][sender], "ERC721: Not owner or operator of token.");
    s.approved[_tokenId] = _approved;
    emit LibERC721.Approval(owner, _approved, _tokenId);
  }

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `msg.sender`'s assets
  /// @dev Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param _operator Address to add to the set of authorized operators
  /// @param _approved True if the operator is approved, false to revoke approval
  function setApprovalForAll(address _operator, bool _approved) external {
    address sender = LibMeta.msgSender();
    s.operators[sender][_operator] = _approved;
    emit LibERC721.ApprovalForAll(sender, _operator, _approved);
  }

  function name() external pure returns (string memory) {
    return "Gotchiverse REALM Parcel";
  }

  /// @notice An abbreviated name for NFTs in this contract
  function symbol() external pure returns (string memory) {
    return "REALM";
  }

  /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
  ///  3986. The URI may point to a JSON file that conforms to the "ERC721
  ///  Metadata JSON Schema".
  function tokenURI(uint256 _tokenId) external pure returns (string memory) {
    return LibStrings.strWithUint("https://app.aavegotchi.com/metadata/realm/", _tokenId); //Here is your URL!
  }

  struct MintParcelInput {
    uint256 coordinateX;
    uint256 coordinateY;
    uint256 parcelId;
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256 fomoBoost;
    uint256 fudBoost;
    uint256 kekBoost;
    uint256 alphaBoost;
  }

  function safeBatchTransfer(
    address _from,
    address _to,
    uint256[] calldata _tokenIds,
    bytes calldata _data
  ) external {
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      safeTransferFrom(_from, _to, _tokenIds[index], _data);
    }
  }

  function addSupportForERC165() external onlyOwner {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    ds.supportedInterfaces[type(IERC721).interfaceId] = true;
  }
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
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

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721Marketplace {
  function updateERC721Listing(
    address _erc721TokenAddress,
    uint256 _erc721TokenId,
    address _owner
  ) external;
}