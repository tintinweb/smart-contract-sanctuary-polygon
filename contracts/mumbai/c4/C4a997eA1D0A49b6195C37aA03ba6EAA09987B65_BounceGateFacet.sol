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

contract TestRealmFacet is Modifiers {
  event MockEquipInstallation(uint256 _realmId, uint256 _installationId, uint256 _x, uint256 _y);
  event MockUnequipInstallation(uint256 _realmId, uint256 _installationId, uint256 _x, uint256 _y);
  event MockEquipTile(uint256 _realmId, uint256 _tileId, uint256 _x, uint256 _y);
  event MockUnequipTile(uint256 _realmId, uint256 _tileId, uint256 _x, uint256 _y);

  struct BatchEquipIO {
    uint256[] types; //0 for installation, 1 for tile
    bool[] equip; //true for equip, false for unequip
    uint256[] ids;
    uint256[] x;
    uint256[] y;
  }

  function mockBatchEquip(uint256 _realmId, BatchEquipIO memory _params) external {
    require(_params.ids.length == _params.x.length, "RealmFacet: Wrong length");
    require(_params.x.length == _params.y.length, "RealmFacet: Wrong length");

    // for (uint256 i = 0; i < _params.ids.length; i++) {
    //   if (_params.types[i] == 0 && _params.equip[i]) {
    //     mockEquipInstallation(_realmId, _params.ids[i], _params.x[i], _params.y[i]);
    //   } else if (_params.types[i] == 1 && _params.equip[i]) {
    //     mockEquipTile(_realmId, _params.ids[i], _params.x[i], _params.y[i]);
    //   } else if (_params.types[i] == 0 && !_params.equip[i]) {
    //     mockUnequipInstallation(_realmId, _params.ids[i], _params.x[i], _params.y[i]);
    //   } else if (_params.types[i] == 1 && !_params.equip[i]) {
    //     mockUnequipTile(_realmId, _params.ids[i], _params.x[i], _params.y[i]);
    //   }
    // }
  }

  /// @dev Equip installation without signature or owner checks for testing
  function mockEquipInstallation(
    uint256 _realmId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) public {
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

    emit MockEquipInstallation(_realmId, _installationId, _x, _y);
  }

  /// @dev Unequip an installation without signature or owner checks for testing
  function mockUnequipInstallation(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) public {
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

    emit MockUnequipInstallation(_realmId, _installationId, _x, _y);
  }

  /// @dev Equip a tile without signature or owner checks for testing
  function mockEquipTile(
    uint256 _realmId,
    uint256 _tileId,
    uint256 _x,
    uint256 _y
  ) public {
    //3 - Equip Tile
    // LibRealm.verifyAccessRight(_realmId, _gotchiId, 3);

    LibRealm.placeTile(_realmId, _tileId, _x, _y);
    TileDiamondInterface(s.tileDiamond).equipTile(msg.sender, _realmId, _tileId);

    emit MockEquipTile(_realmId, _tileId, _x, _y);
  }

  /// @dev Unequip a tile without signature or owner checks for testing
  function mockUnequipTile(
    uint256 _realmId,
    uint256 _tileId,
    uint256 _x,
    uint256 _y
  ) public {
    LibRealm.removeTile(_realmId, _tileId, _x, _y);

    TileDiamondInterface(s.tileDiamond).unequipTile(msg.sender, _realmId, _tileId);

    emit MockUnequipTile(_realmId, _tileId, _x, _y);
  }

  /// @notice Allow the owner of a parcel to start surveying his parcel
  /// @dev Will throw if a surveying round has not started
  /// @param _realmId Identifier of the parcel to survey
  function mockStartSurveying(uint256 _realmId) external {
    require(s.parcels[_realmId].altarId > 0, "AlchemicaFacet: Must equip Altar");
    require(!s.parcels[_realmId].surveying, "AlchemicaFacet: Parcel already surveying");
    s.parcels[_realmId].surveying = true;
  }

  function mockRawFulfillRandomWords(
    uint256 tokenId,
    uint256 surveyingRound,
    uint256 seed
  ) external {
    uint256[] memory randomWords = new uint256[](4);
    randomWords[0] = uint256(keccak256(abi.encode(seed)));
    randomWords[1] = uint256(keccak256(abi.encode(randomWords[0])));
    randomWords[2] = uint256(keccak256(abi.encode(randomWords[1])));
    randomWords[3] = uint256(keccak256(abi.encode(randomWords[2])));
    LibRealm.updateRemainingAlchemica(tokenId, randomWords, surveyingRound);
  }

  /// @notice Allow parcel owner to claim available alchemica with his parent NFT(Aavegotchi)
  /// @param _realmId Identifier of parcel to claim alchemica from
  /// @param _gotchiId Identifier of Aavegotchi to use for alchemica collecction/claiming
  function mockClaimAvailableAlchemica(uint256 _realmId, uint256 _gotchiId) external {
    //1 - Empty Reservoir Access Right
    LibRealm.verifyAccessRight(_realmId, _gotchiId, 1, LibMeta.msgSender());
    LibAlchemica.claimAvailableAlchemica(_realmId, _gotchiId);
  }

  struct MintParcelInput {
    uint256 coordinateX;
    uint256 coordinateY;
    uint256 district;
    string parcelId;
    string parcelAddress;
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256[4] boost; //fud, fomo, alpha, kek
  }

  uint256 constant MAX_SUPPLY = 420069;

  /// @notice Allow the diamond owner to mint new parcels
  /// @param _to The address to mint the parcels to
  /// @param _tokenIds The identifiers of tokens to mint
  /// @param _metadata An array of structs containing the metadata of each parcel being minted
  function mockMintParcels(
    address[] calldata _to,
    uint256[] calldata _tokenIds,
    MintParcelInput[] memory _metadata
  ) external {
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      require(s.tokenIds.length < MAX_SUPPLY, "RealmFacet: Cannot mint more than 420,069 parcels");
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
  BounceGate bounceGate;
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
  // parcelId => action: 0 Alchemical Channeling, 1 Emptying Reservoirs => permission: 0 Owner only, 1 Owner + Borrowed Gotchis, 2 Any Gotchi
  mapping(uint256 => mapping(uint256 => uint256)) accessRights;
  // gotchiId => lastChanneledDay
  mapping(uint256 => uint256) lastChanneledDay;
  bool freezeBuilding;
  //NFT DISPLAY STORAGE
  //chainId => contractAddress => allowed
  mapping(uint256 => mapping(address => bool)) nftDisplayAllowed;
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
    // //whitelisted addresses
    // else if (accessRight == 2) {}
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

    require(equippedAltarLevel >= altarPrerequisite, "LibAlchemica: Altar Tech Tree Reqs not met");

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
      require(!s.parcels[_realmId].bounceGate.equipped, "LibAlchemica: Bounce Gate already equipped");
      s.parcels[_realmId].bounceGate.equipped = true;
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
      if (s.parcels[_realmId].harvesterCount > 0) s.parcels[_realmId].harvesterCount--; // TODO: Remove the check for mainnet deployment
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
      require(s.parcels[_realmId].bounceGate.equipped, "LibAlchemica: Bounce Gate not equipped");
      //cannot uninstall a Bounce Gate if an event is ongoing
      if (s.parcels[_realmId].bounceGate.startTime > 0) {
        require(s.parcels[_realmId].bounceGate.endTime < block.timestamp, "LibAlchemica: Ongoing event, cannot unequip Portal");
      }
      s.parcels[_realmId].bounceGate.equipped = false;
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

    require(block.timestamp > s.lastClaimedAlchemica[_realmId] + 60 seconds, "AlchemicaFacet: 8 hours claim cooldown");
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
import "../../interfaces/IERC1155Marketplace.sol";

contract RealmGridFacet is Modifiers {
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

  function fixGridStartPositions(
    uint256[] memory _parcelIds,
    uint256[] memory _x,
    uint256[] memory _y,
    bool _isTile,
    uint256[] memory _ids
  ) external onlyOwner {
    require(_parcelIds.length == _x.length && _parcelIds.length == _y.length, "RealmFacet: Mismatched arrays");
    if (_isTile) {
      for (uint256 i; i < _parcelIds.length; i++) {
        s.parcels[_parcelIds[i]].startPositionTileGrid[_x[i]][_y[i]] = _ids[i];
      }
    } else {
      for (uint256 i; i < _parcelIds.length; i++) {
        s.parcels[_parcelIds[i]].startPositionBuildGrid[_x[i]][_y[i]] = _ids[i];
      }
    }
  }

  function isGridStartPosition(
    uint256 _parcelId,
    uint256 _x,
    uint256 _y,
    bool _isTile,
    uint256 _id
  ) external view returns (bool) {
    if (_isTile) {
      return s.parcels[_parcelId].startPositionTileGrid[_x][_y] == _id;
    } else {
      return s.parcels[_parcelId].startPositionBuildGrid[_x][_y] == _id;
    }
  }
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

  function setIndex(uint256 _tokenId) external onlyOwner {
    address owner = this.ownerOf(_tokenId);
    s.ownerTokenIdIndexes[owner][_tokenId] -= 1;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../libraries/AppStorageTile.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibStrings.sol";
import "../../libraries/LibMeta.sol";
import "../../libraries/LibERC1155Tile.sol";
import "../../interfaces/IERC1155Marketplace.sol";

contract ERC1155TileFacet is Modifiers {
  function isApprovedForAll(address account, address operator) public view returns (bool operators_) {
    operators_ = s.operators[account][operator];
  }

  /**
  @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _value,
    bytes calldata _data
  ) external {
    require(_to != address(0), "ERC1155Facet: Can't transfer to 0 address");
    address sender = LibMeta.msgSender();
    require(sender == _from || s.operators[_from][sender] || sender == address(this), "ERC1155Facet: Not owner and not approved to transfer");
    LibERC1155Tile.removeFromOwner(_from, _id, _value);
    LibERC1155Tile.addToOwner(_to, _id, _value);
    IERC1155Marketplace(s.aavegotchiDiamond).updateERC1155Listing(address(this), _id, _from);
    emit LibERC1155Tile.TransferSingle(sender, _from, _to, _id, _value);
    LibERC1155Tile.onERC1155Received(sender, _from, _to, _id, _value, _data);
  }

  /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes calldata _data
  ) external {
    require(_to != address(0), "ItemsTransfer: Can't transfer to 0 address");
    require(_ids.length == _values.length, "ItemsTransfer: ids not same length as values");
    address sender = LibMeta.msgSender();
    require(sender == _from || s.operators[_from][sender], "ItemsTransfer: Not owner and not approved to transfer");
    for (uint256 i; i < _ids.length; i++) {
      uint256 id = _ids[i];
      uint256 value = _values[i];
      LibERC1155Tile.removeFromOwner(_from, id, value);
      LibERC1155Tile.addToOwner(_to, id, value);
      IERC1155Marketplace(s.aavegotchiDiamond).updateERC1155Listing(address(this), id, _from);
    }
    emit LibERC1155Tile.TransferBatch(sender, _from, _to, _ids, _values);
    LibERC1155Tile.onERC1155BatchReceived(sender, _from, _to, _ids, _values, _data);
  }

  function setApprovalForAll(address _operator, bool _approved) external {
    address sender = LibMeta.msgSender();
    require(sender != _operator, "ERC1155Facet: setting approval status for self");
    s.operators[sender][_operator] = _approved;
    emit LibERC1155Tile.ApprovalForAll(sender, _operator, _approved);
  }

  /// @notice Get the URI for a voucher type
  /// @return URI for token type
  function uri(uint256 _id) external view returns (string memory) {
    require(_id < s.tileTypes.length, "TileFacet: Item _id not found");
    return LibStrings.strWithUint(s.baseUri, _id);
  }

  ///@notice Set the base url for all voucher types
  ///@param _value The new base url
  function setBaseURI(string memory _value) external onlyOwner {
    s.baseUri = _value;
    uint256 _tileTypesLength = s.tileTypes.length;
    for (uint256 i; i < _tileTypesLength; i++) {
      emit LibERC1155Tile.URI(LibStrings.strWithUint(_value, i), i);
    }
  }

  ///@notice Get the balance of an account's tokens.
  ///@param _owner  The address of the token holder
  ///@param _id     ID of the token
  ///@return bal_    The _owner's balance of the token type requested
  function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_) {
    bal_ = s.ownerTileBalances[_owner][_id];
  }

  ///@notice Get the balance of multiple account/token pairs
  ///@param _owners The addresses of the token holders
  ///@param _ids    ID of the tokens
  ///@return bals   The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory bals) {
    require(_owners.length == _ids.length, "TileFacet: _owners length not same as _ids length");
    bals = new uint256[](_owners.length);
    for (uint256 i; i < _owners.length; i++) {
      uint256 id = _ids[i];
      address owner = _owners[i];
      bals[i] = s.ownerTileBalances[owner][id];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import {LibDiamond} from "./LibDiamond.sol";

struct TileType {
  //slot 1
  uint8 width;
  uint8 height;
  bool deprecated;
  uint16 tileType;
  uint32 craftTime; // in blocks
  //slot 2
  uint256[4] alchemicaCost; // [fud, fomo, alpha, kek]
  //slot 3
  string name;
}

struct QueueItem {
  //slot 1
  uint256 id;
  //slot 2
  uint40 readyBlock;
  uint16 tileType;
  bool claimed;
  address owner;
}

struct TileAppStorage {
  address realmDiamond;
  address aavegotchiDiamond;
  address pixelcraft;
  address aavegotchiDAO;
  address gltr;
  address[] alchemicaAddresses;
  string baseUri;
  TileType[] tileTypes;
  QueueItem[] craftQueue;
  uint256 nextCraftId;
  //ERC1155 vars
  mapping(address => mapping(address => bool)) operators;
  //ERC998 vars
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftTileBalances;
  mapping(address => mapping(uint256 => uint256[])) nftTiles;
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftTileIndexes;
  mapping(address => mapping(uint256 => uint256)) ownerTileBalances;
  mapping(address => uint256[]) ownerTiles;
  mapping(address => mapping(uint256 => uint256)) ownerTileIndexes;
  // installationId => deprecateTime
  mapping(uint256 => uint256) deprecateTime;
}

library LibAppStorageTile {
  function diamondStorage() internal pure returns (TileAppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  TileAppStorage internal s;

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyRealmDiamond() {
    require(msg.sender == s.realmDiamond, "LibDiamond: Must be realm diamond");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageTile, TileAppStorage} from "./AppStorageTile.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";

library LibERC1155Tile {
  bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
  bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

  /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
  event URI(string _value, uint256 indexed _tokenId);

  /// @dev Should actually be _owner, _tileId, _queueId
  event MintTile(address indexed _owner, uint256 indexed _tileType, uint256 _tileId);
  event MintTiles(address indexed _owner, uint256 indexed _tileId, uint16 _amount);

  function _safeMint(
    address _to,
    uint256 _tileId,
    uint16 _amount,
    uint256 _queueId
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    if (s.tileTypes[_tileId].craftTime > 0) {
      require(!s.craftQueue[_queueId].claimed, "LibERC1155: tokenId already minted");
      require(s.craftQueue[_queueId].owner == _to, "LibERC1155: wrong owner");
      s.craftQueue[_queueId].claimed = true;
    }

    addToOwner(_to, _tileId, _amount);

    if (_amount == 1) emit MintTile(_to, _tileId, _queueId);
    else emit MintTiles(_to, _tileId, _amount);

    emit LibERC1155Tile.TransferSingle(address(this), address(0), _to, _tileId, _amount);
  }

  function addToOwner(
    address _to,
    uint256 _id,
    uint256 _value
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    s.ownerTileBalances[_to][_id] += _value;
    if (s.ownerTileIndexes[_to][_id] == 0) {
      s.ownerTiles[_to].push(_id);
      s.ownerTileIndexes[_to][_id] = s.ownerTiles[_to].length;
    }
  }

  function removeFromOwner(
    address _from,
    uint256 _id,
    uint256 _value
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    uint256 bal = s.ownerTileBalances[_from][_id];
    require(_value <= bal, "LibERC1155: Doesn't have that many to transfer");
    bal -= _value;
    s.ownerTileBalances[_from][_id] = bal;
    if (bal == 0) {
      uint256 index = s.ownerTileIndexes[_from][_id] - 1;
      uint256 lastIndex = s.ownerTiles[_from].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.ownerTiles[_from][lastIndex];
        s.ownerTiles[_from][index] = lastId;
        s.ownerTileIndexes[_from][lastId] = index + 1;
      }
      s.ownerTiles[_from].pop();
      delete s.ownerTileIndexes[_from][_id];
    }
  }

  function _burn(
    address _from,
    uint256 _tileType,
    uint256 _amount
  ) internal {
    removeFromOwner(_from, _tileType, _amount);
    emit LibERC1155Tile.TransferSingle(address(this), _from, address(0), _tileType, _amount);
  }

  function onERC1155Received(
    address _operator,
    address _from,
    address _to,
    uint256 _id,
    uint256 _value,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data),
        "Wearables: Transfer rejected/failed by _to"
      );
    }
  }

  function onERC1155BatchReceived(
    address _operator,
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data),
        "Wearables: Transfer rejected/failed by _to"
      );
    }
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {TileType, QueueItem, Modifiers} from "../../libraries/AppStorageTile.sol";
import {LibERC1155Tile} from "../../libraries/LibERC1155Tile.sol";
import {LibItems} from "../../libraries/LibItems.sol";
import {RealmDiamond} from "../../interfaces/RealmDiamond.sol";
import {LibERC998Tile, ItemTypeIO} from "../../libraries/LibERC998Tile.sol";
import {LibAppStorageTile, TileType, QueueItem, Modifiers} from "../../libraries/AppStorageTile.sol";
import {LibStrings} from "../../libraries/LibStrings.sol";
import {LibMeta} from "../../libraries/LibMeta.sol";
import {LibERC1155Tile} from "../../libraries/LibERC1155Tile.sol";
import {LibERC20} from "../../libraries/LibERC20.sol";
import {LibTile} from "../../libraries/LibTile.sol";
import {LibItems} from "../../libraries/LibItems.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {RealmDiamond} from "../../interfaces/RealmDiamond.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

contract TileFacet is Modifiers {
  event AddedToQueue(uint256 indexed _queueId, uint256 indexed _tileId, uint256 _readyBlock, address _sender);

  event QueueClaimed(uint256 indexed _queueId);

  event CraftTimeReduced(uint256 indexed _queueId, uint256 _blocksReduced);

  event AddressesUpdated(address _aavegotchiDiamond, address _realmDiamond, address _gltr);

  /***********************************|
   |             Read Functions         |
   |__________________________________*/

  struct TileIdIO {
    uint256 tileId;
    uint256 balance;
  }

  /// @notice Returns balance for each tile that exists for an account
  /// @param _account Address of the account to query
  /// @return bals_ An array of structs,each struct containing details about each tile owned
  function tilesBalances(address _account) external view returns (TileIdIO[] memory bals_) {
    uint256 count = s.ownerTiles[_account].length;
    bals_ = new TileIdIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 tileId = s.ownerTiles[_account][i];
      bals_[i].balance = s.ownerTileBalances[_account][tileId];
      bals_[i].tileId = tileId;
    }
  }

  /// @notice Returns balance for each tile(and their types) that exists for an account
  /// @param _owner Address of the account to query
  /// @return output_ An array of structs containing details about each tile owned(including the tile types)
  function tilesBalancesWithTypes(address _owner) external view returns (ItemTypeIO[] memory output_) {
    uint256 count = s.ownerTiles[_owner].length;
    output_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 tileId = s.ownerTiles[_owner][i];
      output_[i].balance = s.ownerTileBalances[_owner][tileId];
      output_[i].itemId = tileId;
      output_[i].tileType = s.tileTypes[tileId];
    }
  }

  /// @notice Get the balance of a non-fungible parent token
  /// @param _tokenContract The contract tracking the parent token
  /// @param _tokenId The ID of the parent token
  /// @param _id     ID of the token
  /// @return value The balance of the token
  function balanceOfToken(
    address _tokenContract,
    uint256 _tokenId,
    uint256 _id
  ) public view returns (uint256 value) {
    value = s.nftTileBalances[_tokenContract][_tokenId][_id];
  }

  /// @notice Returns the balances for all ERC1155 items for a ERC721 token
  /// @param _tokenContract Contract address for the token to query
  /// @param _tokenId Identifier of the token to query
  /// @return bals_ An array of structs containing details about each item owned
  function tileBalancesOfToken(address _tokenContract, uint256 _tokenId) public view returns (TileIdIO[] memory bals_) {
    uint256 count = s.nftTiles[_tokenContract][_tokenId].length;
    bals_ = new TileIdIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 tileId = s.nftTiles[_tokenContract][_tokenId][i];
      bals_[i].tileId = tileId;
      bals_[i].balance = s.nftTileBalances[_tokenContract][_tokenId][tileId];
    }
  }

  /// @notice Returns the balances for all ERC1155 items for a ERC721 token
  /// @param _tokenContract Contract address for the token to query
  /// @param _tokenId Identifier of the token to query
  /// @return tileBalancesOfTokenWithTypes_ An array of structs containing details about each tile owned(including tile types)
  function tileBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    external
    view
    returns (ItemTypeIO[] memory tileBalancesOfTokenWithTypes_)
  {
    tileBalancesOfTokenWithTypes_ = LibERC998Tile.itemBalancesOfTokenWithTypes(_tokenContract, _tokenId);
  }

  /// @notice Query the tile balances of an ERC721 parent token
  /// @param _tokenContract The token contract of the ERC721 parent token
  /// @param _tokenId The identifier of the ERC721 parent token
  /// @param _ids An array containing the ids of the tileTypes to query
  /// @return An array containing the corresponding balances of the tile types queried
  function tileBalancesOfTokenByIds(
    address _tokenContract,
    uint256 _tokenId,
    uint256[] calldata _ids
  ) external view returns (uint256[] memory) {
    uint256[] memory balances = new uint256[](_ids.length);
    for (uint256 i = 0; i < _ids.length; i++) {
      balances[i] = balanceOfToken(_tokenContract, _tokenId, _ids[i]);
    }
    return balances;
  }

  /// @notice Query the item type of a particular tile
  /// @param _tileTypeId Item to query
  /// @return tileType A struct containing details about the item type of an item with identifier `_itemId`
  function getTileType(uint256 _tileTypeId) external view returns (TileType memory tileType) {
    require(_tileTypeId < s.tileTypes.length, "TileFacet: Item type doesn't exist");
    tileType = s.tileTypes[_tileTypeId];
    tileType.deprecated = s.deprecateTime[_tileTypeId] > 0 ? block.timestamp > s.deprecateTime[_tileTypeId] : s.tileTypes[_tileTypeId].deprecated;
  }

  /// @notice Query the item type of multiple tile types
  /// @param _tileTypeIds An array containing the identifiers of items to query
  /// @return tileTypes_ An array of structs,each struct containing details about the item type of the corresponding item
  function getTileTypes(uint256[] calldata _tileTypeIds) external view returns (TileType[] memory tileTypes_) {
    if (_tileTypeIds.length == 0) {
      tileTypes_ = s.tileTypes;
      for (uint256 i = 0; i < s.tileTypes.length; i++) {
        tileTypes_[i].deprecated = s.deprecateTime[i] == 0 ? s.tileTypes[i].deprecated : block.timestamp > s.deprecateTime[i];
      }
    } else {
      tileTypes_ = new TileType[](_tileTypeIds.length);
      for (uint256 i; i < _tileTypeIds.length; i++) {
        uint256 tileId = _tileTypeIds[i];
        tileTypes_[i] = s.tileTypes[_tileTypeIds[i]];
        tileTypes_[i].deprecated = s.deprecateTime[tileId] > 0 ? block.timestamp > s.deprecateTime[tileId] : s.tileTypes[tileId].deprecated;
      }
    }
  }

  /***********************************|
   |             Write Functions        |
   |__________________________________*/

  /// @notice Allow a user to craft tiles one at a time
  /// @dev Puts the tile into a queue
  /// @param _tileTypes An array containing the identifiers of the tileTypes to craft
  function craftTiles(uint16[] calldata _tileTypes) external {
    address[4] memory alchemicaAddresses = RealmDiamond(s.realmDiamond).getAlchemicaAddresses();

    uint256 _tileTypesLength = s.tileTypes.length;
    uint256 _nextCraftId = s.nextCraftId;
    for (uint256 i = 0; i < _tileTypes.length; i++) {
      require(_tileTypes[i] < _tileTypesLength, "TileFacet: Tile does not exist");

      TileType memory tileType = s.tileTypes[_tileTypes[i]];

      //The preset deprecation time has elapsed
      if (s.deprecateTime[_tileTypes[i]] > 0) {
        require(block.timestamp < s.deprecateTime[_tileTypes[i]], "TileFacet: Tile has been deprecated");
      }
      require(!tileType.deprecated, "TileFacet: Tile has been deprecated");

      //take the required alchemica
      LibItems._splitAlchemica(tileType.alchemicaCost, alchemicaAddresses);

      if (tileType.craftTime == 0) {
        LibERC1155Tile._safeMint(msg.sender, _tileTypes[i], 1, 0);
      } else {
        uint40 readyBlock = uint40(block.number) + tileType.craftTime;

        //put the tile into a queue
        //each tile needs a unique queue id
        s.craftQueue.push(QueueItem(_nextCraftId, readyBlock, _tileTypes[i], false, msg.sender));

        emit AddedToQueue(_nextCraftId, _tileTypes[i], readyBlock, msg.sender);
        _nextCraftId++;
      }
    }
    s.nextCraftId = _nextCraftId;
    //after queue is over, user can claim tile
  }

  struct BatchCraftTilesInput {
    uint16 tileID;
    uint16 amount;
    uint40 gltr;
  }

  function _batchCraftTiles(BatchCraftTilesInput calldata _batchCraftTilesInput) internal {
    address[4] memory alchemicaAddresses = RealmDiamond(s.realmDiamond).getAlchemicaAddresses();
    uint256[4] memory alchemicaCost;
    // uint256 _nextCraftId = s.nextCraftId;

    uint16 tileID = _batchCraftTilesInput.tileID;
    uint16 amount = _batchCraftTilesInput.amount;
    // uint40 gltr = _batchCraftTilesInput.gltr;

    require(amount > 0, "InstallationFacet: Craft amount cannot be zero");

    require(tileID < s.tileTypes.length, "TileFacet: Tile does not exist");
    TileType memory tileType = s.tileTypes[tileID];
    if (s.deprecateTime[tileID] > 0) {
      require(block.timestamp < s.deprecateTime[tileID], "TileFacet: Tile has been deprecated");
    }
    require(!tileType.deprecated, "TileFacet: Tile has been deprecated");

    alchemicaCost[0] = tileType.alchemicaCost[0] * amount;
    alchemicaCost[1] = tileType.alchemicaCost[1] * amount;
    alchemicaCost[2] = tileType.alchemicaCost[2] * amount;
    alchemicaCost[3] = tileType.alchemicaCost[3] * amount;
    //distribute alchemica
    LibItems._splitAlchemica(alchemicaCost, alchemicaAddresses);

    if (tileType.craftTime == 0) {
      LibERC1155Tile._safeMint(msg.sender, tileID, amount, 0);
    }
    //@todo: add back GLTR and queueing
    //  else {
    //   //tiles that are crafted after some time
    //   //for each tile , push to queue after applying individual gltr subtractions
    //   for (uint256 i = 0; i < amount; i++) {
    //     if (gltr > tileType.craftTime) revert("TileFacet: Too much GLTR");
    //     if (tileType.craftTime - gltr == 0) {
    //       LibERC1155Tile._safeMint(msg.sender, tileID, 1, 0);
    //     } else {
    //       uint40 readyBlock = uint40(block.number) + tileType.craftTime;
    //       //put the tile into a queue
    //       //each tile needs a unique queue id
    //       s.craftQueue.push(QueueItem(_nextCraftId, readyBlock, tileID, false, msg.sender));
    //       emit AddedToQueue(_nextCraftId, tileID, readyBlock, msg.sender);
    //       _nextCraftId++;
    //     }
    //   }
  }

  /// @notice Allow a user to craft tiles by batch
  function batchCraftTiles(BatchCraftTilesInput[] calldata _inputs) external {
    for (uint256 i = 0; i < _inputs.length; i++) {
      _batchCraftTiles(_inputs[i]);
    }
  }

  /// @notice Allow a user to claim tiles from ready queues
  /// @dev Will throw if the caller is not the queue owner
  /// @dev Will throw if one of the queues is not ready
  /// @param _queueIds An array containing the identifiers of queues to claim
  function claimTiles(uint256[] calldata _queueIds) external {
    for (uint256 i; i < _queueIds.length; i++) {
      uint256 queueId = _queueIds[i];

      QueueItem memory queueItem = s.craftQueue[queueId];

      require(!queueItem.claimed, "TileFacet: already claimed");

      require(block.number >= queueItem.readyBlock, "TileFacet: tile not ready");

      // mint tile
      LibERC1155Tile._safeMint(queueItem.owner, queueItem.tileType, 1, queueItem.id);
      s.craftQueue[queueId].claimed = true;
      emit QueueClaimed(queueId);
    }
  }

  /// @notice Allow a user to speed up multiple queues(tile craft time) by paying the correct amount of $GLTR tokens
  /// @dev Will throw if the caller is not the queue owner
  /// @dev $GLTR tokens are burnt upon usage
  /// @dev amount expressed in block numbers
  /// @param _queueIds An array containing the identifiers of queues to speed up
  /// @param _amounts An array containing the corresponding amounts of $GLTR tokens to pay for each queue speedup
  function reduceCraftTime(uint256[] calldata _queueIds, uint40[] calldata _amounts) external {
    require(_queueIds.length == _amounts.length, "TileFacet: Mismatched arrays");
    for (uint256 i; i < _queueIds.length; i++) {
      uint256 queueId = _queueIds[i];
      QueueItem storage queueItem = s.craftQueue[queueId];
      require(msg.sender == queueItem.owner, "TileFacet: not owner");

      require(block.number <= queueItem.readyBlock, "TileFacet: tile already done");

      IERC20 gltr = IERC20(s.gltr);

      uint40 blockLeft = queueItem.readyBlock - uint40(block.number);
      uint40 removeBlocks = _amounts[i] <= blockLeft ? _amounts[i] : blockLeft;
      gltr.burnFrom(msg.sender, removeBlocks * 10**18);
      queueItem.readyBlock -= removeBlocks;
      emit CraftTimeReduced(queueId, removeBlocks);
    }
  }

  // /// @notice Allow a user to claim tiles from ready queues
  // /// @dev Will throw if the caller is not the queue owner
  // /// @dev Will throw if one of the queues is not ready
  // /// @param _queueIds An array containing the identifiers of queues to claim
  // function claimTiles(uint256[] calldata _queueIds) external {
  //   for (uint256 i; i < _queueIds.length; i++) {
  //     uint256 queueId = _queueIds[i];

  //     QueueItem memory queueItem = s.craftQueue[queueId];

  //     require(!queueItem.claimed, "TileFacet: already claimed");

  //     require(block.number >= queueItem.readyBlock, "TileFacet: tile not ready");

  //     // mint tile
  //     LibERC1155Tile._safeMint(queueItem.owner, queueItem.tileType, queueItem.id);
  //     s.craftQueue[queueId].claimed = true;
  //     emit QueueClaimed(queueId);
  //   }
  // }

  /// @notice Allow a user to equip a tile to a parcel
  /// @dev Will throw if the caller is not the parcel diamond contract
  /// @dev Will also throw if various prerequisites for the tile are not met
  /// @param _owner Owner of the tile to equip
  /// @param _realmId The identifier of the parcel to equip the tile to
  /// @param _tileId Identifier of the tile to equip
  function equipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) external onlyRealmDiamond {
    LibTile._equipTile(_owner, _realmId, _tileId);
  }

  /// @notice Allow a user to unequip a tile from a parcel
  /// @dev Will throw if the caller is not the parcel diamond contract
  /// @param _realmId The identifier of the parcel to unequip the tile from
  /// @param _tileId Identifier of the tile to unequip
  function unequipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) external onlyRealmDiamond {
    LibTile._unequipTile(_owner, _realmId, _tileId);
  }

  /// @notice Query details about all ongoing craft queues
  /// @param _owner Address to query queue
  /// @return output_ An array of structs, each representing an ongoing craft queue
  function getCraftQueue(address _owner) external view returns (QueueItem[] memory output_) {
    uint256 length = s.craftQueue.length;
    output_ = new QueueItem[](length);
    uint256 counter;
    for (uint256 i; i < length; i++) {
      if (s.craftQueue[i].owner == _owner) {
        output_[counter] = s.craftQueue[i];
        counter++;
      }
    }
    assembly {
      mstore(output_, counter)
    }
  }

  /***********************************|
   |             Owner Functions        |
   |__________________________________*/

  /// @notice Allow the Diamond owner to deprecate a tile
  /// @dev Deprecated tiles cannot be crafted by users
  /// @param _tileIds An array containing the identifiers of tiles to deprecate
  function deprecateTiles(uint256[] calldata _tileIds) external onlyOwner {
    for (uint256 i = 0; i < _tileIds.length; i++) {
      s.tileTypes[_tileIds[i]].deprecated = true;
    }
  }

  /// @notice Allow the diamond owner to set some important contract addresses
  /// @param _aavegotchiDiamond The aavegotchi diamond address
  /// @param _realmDiamond The Realm diamond address
  /// @param _gltr The $GLTR token address
  function setAddresses(
    address _aavegotchiDiamond,
    address _realmDiamond,
    address _gltr,
    address _pixelcraft,
    address _aavegotchiDAO
  ) external onlyOwner {
    s.aavegotchiDiamond = _aavegotchiDiamond;
    s.realmDiamond = _realmDiamond;
    s.gltr = _gltr;
    s.pixelcraft = _pixelcraft;
    s.aavegotchiDAO = _aavegotchiDAO;
    emit AddressesUpdated(_aavegotchiDiamond, _realmDiamond, _gltr);
  }

  /// @notice Allow the diamond owner to add a tile type
  /// @param _tileTypes An array of structs, each struct representing each tileType to be added
  function addTileTypes(TileType[] calldata _tileTypes) external onlyOwner {
    for (uint256 i = 0; i < _tileTypes.length; i++) {
      s.tileTypes.push(
        TileType(
          _tileTypes[i].width,
          _tileTypes[i].height,
          _tileTypes[i].deprecated,
          _tileTypes[i].tileType,
          _tileTypes[i].craftTime,
          _tileTypes[i].alchemicaCost,
          _tileTypes[i].name
        )
      );
      string memory uri = "https://app.aavegotchi.com/metadata/tile/";
      emit LibERC1155Tile.URI(LibStrings.strWithUint(uri, i), i);
    }
  }

  function editDeprecateTime(uint256 _typeId, uint40 _deprecateTime) external onlyOwner {
    s.deprecateTime[_typeId] = _deprecateTime;
  }

  function editTileType(uint256 _typeId, TileType calldata _updatedTile) external onlyOwner {
    s.tileTypes[_typeId] = _updatedTile;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// import {LibERC20} from "../libraries/LibERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {LibAppStorageInstallation, InstallationAppStorage} from "../libraries/AppStorageInstallation.sol";

library LibItems {
  function _splitAlchemica(uint256[4] memory _alchemicaCost, address[4] memory _alchemicaAddresses) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    //take the required alchemica and split it
    for (uint256 i = 0; i < _alchemicaCost.length; i++) {
      //only send onchain when amount > 0
      if (_alchemicaCost[i] > 0) {
        uint256 greatPortal = (_alchemicaCost[i] * 35) / 100;
        uint256 pixelcraftPart = (_alchemicaCost[i] * 30) / 100;
        uint256 aavegotchiDAO = (_alchemicaCost[i] * 30) / 100;
        uint256 burn = (_alchemicaCost[i] * 5) / 100;
        IERC20(_alchemicaAddresses[i]).transferFrom(msg.sender, s.realmDiamond, greatPortal);
        IERC20(_alchemicaAddresses[i]).transferFrom(msg.sender, s.pixelcraft, pixelcraftPart);
        IERC20(_alchemicaAddresses[i]).transferFrom(msg.sender, s.aavegotchiDAO, aavegotchiDAO);
        IERC20(_alchemicaAddresses[i]).transferFrom(msg.sender, 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, burn);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface RealmDiamond {
  struct ParcelOutput {
    string parcelId;
    string parcelAddress;
    address owner;
    uint256 coordinateX; //x position on the map
    uint256 coordinateY; //y position on the map
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256 district;
    uint256[4] boost;
  }

  function getAltarId(uint256 _parcelId) external view returns (uint256);

  function getAlchemicaAddresses() external view returns (address[4] memory);

  function ownerOf(uint256 _tokenId) external view returns (address owner_);

  function tokenIdsOfOwner(address _owner) external view returns (uint256[] memory tokenIds_);

  function checkCoordinates(
    uint256 _tokenId,
    uint256 _coordinateX,
    uint256 _coordinateY,
    uint256 _installationId
  ) external view;

  function upgradeInstallation(
    uint256 _realmId,
    uint256 _prevInstallationId,
    uint256 _nextInstallationId,
    uint256 _coordinateX,
    uint256 _coordinateY
  ) external;

  function getParcelUpgradeQueueLength(uint256 _parcelId) external view returns (uint256);

  function getParcelUpgradeQueueCapacity(uint256 _parcelId) external view returns (uint256);

  function addUpgradeQueueLength(uint256 _realmId) external;

  function subUpgradeQueueLength(uint256 _realmId) external;

  function verifyAccessRight(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _actionRight,
    address _sender
  ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageTile, TileAppStorage, TileType} from "./AppStorageTile.sol";
import {LibERC1155} from "./LibERC1155.sol";

struct ItemTypeIO {
  uint256 balance;
  uint256 itemId;
  TileType tileType;
}

library LibERC998Tile {
  function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    internal
    view
    returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_)
  {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    uint256 count = s.nftTiles[_tokenContract][_tokenId].length;
    itemBalancesOfTokenWithTypes_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 itemId = s.nftTiles[_tokenContract][_tokenId][i];
      uint256 bal = s.nftTileBalances[_tokenContract][_tokenId][itemId];
      itemBalancesOfTokenWithTypes_[i].itemId = itemId;
      itemBalancesOfTokenWithTypes_[i].balance = bal;
      itemBalancesOfTokenWithTypes_[i].tileType = s.tileTypes[itemId];
    }
  }

  function addToParent(
    address _toContract,
    uint256 _toTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    s.nftTileBalances[_toContract][_toTokenId][_id] += _value;
    if (s.nftTileIndexes[_toContract][_toTokenId][_id] == 0) {
      s.nftTiles[_toContract][_toTokenId].push(_id);
      s.nftTileIndexes[_toContract][_toTokenId][_id] = s.nftTiles[_toContract][_toTokenId].length;
    }
  }

  function removeFromParent(
    address _fromContract,
    uint256 _fromTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    uint256 bal = s.nftTileBalances[_fromContract][_fromTokenId][_id];
    require(_value <= bal, "Items: Doesn't have that many to transfer");
    bal -= _value;
    s.nftTileBalances[_fromContract][_fromTokenId][_id] = bal;
    if (bal == 0) {
      uint256 index = s.nftTileIndexes[_fromContract][_fromTokenId][_id] - 1;
      uint256 lastIndex = s.nftTiles[_fromContract][_fromTokenId].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.nftTiles[_fromContract][_fromTokenId][lastIndex];
        s.nftTiles[_fromContract][_fromTokenId][index] = lastId;
        s.nftTileIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
      }
      s.nftTiles[_fromContract][_fromTokenId].pop();
      delete s.nftTileIndexes[_fromContract][_fromTokenId][_id];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import "../interfaces/IERC20.sol";

library LibERC20 {
  function transferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _value
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_token)
    }
    require(size > 0, "LibERC20: Address has no code");
    (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
    handleReturn(success, result);
  }

  function transfer(
    address _token,
    address _to,
    uint256 _value
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_token)
    }
    require(size > 0, "LibERC20: Address has no code");
    (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
    handleReturn(success, result);
  }

  function handleReturn(bool _success, bytes memory _result) internal pure {
    if (_success) {
      if (_result.length > 0) {
        require(abi.decode(_result, (bool)), "LibERC20: contract call returned false");
      }
    } else {
      if (_result.length > 0) {
        // bubble up any reason for revert
        revert(string(_result));
      } else {
        revert("LibERC20: contract call reverted");
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibERC998Tile} from "../libraries/LibERC998Tile.sol";
import {LibERC1155Tile} from "../libraries/LibERC1155Tile.sol";
import {LibAppStorageTile, TileAppStorage} from "../libraries/AppStorageTile.sol";

library LibTile {
  function _equipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    LibERC1155Tile.removeFromOwner(_owner, _tileId, 1);
    LibERC1155Tile.addToOwner(s.realmDiamond, _tileId, 1);
    emit LibERC1155Tile.TransferSingle(address(this), _owner, s.realmDiamond, _tileId, 1);
    LibERC998Tile.addToParent(s.realmDiamond, _realmId, _tileId, 1);
    emit LibERC1155Tile.TransferToParent(s.realmDiamond, _realmId, _tileId, 1);
  }

  function _unequipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) internal {
    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    LibERC998Tile.removeFromParent(s.realmDiamond, _realmId, _tileId, 1);
    emit LibERC1155Tile.TransferFromParent(s.realmDiamond, _realmId, _tileId, 1);
    LibERC1155Tile.addToOwner(_owner, _tileId, 1);
    emit LibERC1155Tile.TransferSingle(address(this), s.realmDiamond, _owner, _tileId, 1);
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC20 interface
/// @dev https://github.com/ethereum/EIPs/issues/20
interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import {LibDiamond} from "./LibDiamond.sol";

struct InstallationType {
  //slot 1
  uint8 width;
  uint8 height;
  uint16 installationType; //0 = altar, 1 = harvester, 2 = reservoir, 3 = gotchi lodge, 4 = wall, 5 = NFT display, 6 = maaker 7 = decoration, 8 = bounce gate
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
  uint256[] prerequisites; //[0,0] altar level, lodge level
  //slot 6
  string name;
}

struct QueueItem {
  address owner;
  uint16 installationType;
  bool claimed;
  uint40 readyBlock;
  uint256 id;
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

struct InstallationTypeIO {
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
  uint256[4] alchemicaCost; // [fud, fomo, alpha, kek]
  uint256 harvestRate;
  uint256 capacity;
  uint256[] prerequisites; //[0,0] altar level, lodge level
  string name;
  uint256 unequipType;
}

struct InstallationAppStorage {
  address realmDiamond;
  address aavegotchiDiamond;
  address pixelcraft;
  address aavegotchiDAO;
  address gltr;
  address[] alchemicaAddresses;
  string baseUri;
  InstallationType[] installationTypes;
  QueueItem[] craftQueue;
  uint256 nextCraftId;
  //ERC1155 vars
  mapping(address => mapping(address => bool)) operators;
  //ERC998 vars
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftInstallationBalances;
  mapping(address => mapping(uint256 => uint256[])) nftInstallations;
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftInstallationIndexes;
  mapping(address => mapping(uint256 => uint256)) ownerInstallationBalances;
  mapping(address => uint256[]) ownerInstallations;
  mapping(address => mapping(uint256 => uint256)) ownerInstallationIndexes;
  UpgradeQueue[] upgradeQueue;
  // installationId => deprecateTime
  mapping(uint256 => uint256) deprecateTime;
  mapping(bytes32 => uint256) upgradeHashes;
  bytes backendPubKey;
  mapping(uint256 => bool) upgradeComplete;
  mapping(uint256 => uint256) unequipTypes; // installationType.id => unequipType
  mapping(uint256 => uint256[]) parcelIdToUpgradeIds; // will not track upgrades before this variable's existence
}

library LibAppStorageInstallation {
  function diamondStorage() internal pure returns (InstallationAppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  InstallationAppStorage internal s;

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyRealmDiamond() {
    require(msg.sender == s.realmDiamond, "LibDiamond: Must be realm diamond");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageInstallation, InstallationAppStorage} from "./AppStorageInstallation.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";

library LibERC1155 {
  bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
  bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
  event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  event TransferFromParent(address indexed _fromContract, uint256 indexed _fromTokenId, uint256 indexed _tokenTypeId, uint256 _value);
  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

  /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be LibMeta.msgSender()).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

  /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
  event URI(string _value, uint256 indexed _tokenId);

  /// @dev Should actually be _owner, _installationId, _queueId
  event MintInstallation(address indexed _owner, uint256 indexed _installationType, uint256 _installationId);

  event MintInstallations(address indexed _owner, uint256 indexed _installationId, uint16 _amount);

  function _safeMint(
    address _to,
    uint256 _installationId,
    uint16 _amount,
    bool _requireQueue,
    uint256 _queueId
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    if (_requireQueue) {
      //Queue is required
      if (s.installationTypes[_installationId].level == 1) {
        require(!s.craftQueue[_queueId].claimed, "LibERC1155: tokenId already minted");
        require(s.craftQueue[_queueId].owner == _to, "LibERC1155: wrong owner");
        s.craftQueue[_queueId].claimed = true;
      } else {
        require(!s.upgradeQueue[_queueId].claimed, "LibERC1155: tokenId already minted");
        require(s.upgradeQueue[_queueId].owner == _to, "LibERC1155: wrong owner");
        s.upgradeQueue[_queueId].claimed = true;
      }
    }

    addToOwner(_to, _installationId, _amount);

    if (_amount == 1) emit MintInstallation(_to, _installationId, _queueId);
    else emit MintInstallations(_to, _installationId, _amount);

    emit LibERC1155.TransferSingle(address(this), address(0), _to, _installationId, 1);
  }

  function addToOwner(
    address _to,
    uint256 _id,
    uint256 _value
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    s.ownerInstallationBalances[_to][_id] += _value;
    if (s.ownerInstallationIndexes[_to][_id] == 0) {
      s.ownerInstallations[_to].push(_id);
      s.ownerInstallationIndexes[_to][_id] = s.ownerInstallations[_to].length;
    }
  }

  function removeFromOwner(
    address _from,
    uint256 _id,
    uint256 _value
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    uint256 bal = s.ownerInstallationBalances[_from][_id];
    require(_value <= bal, "LibERC1155: Doesn't have that many to transfer");
    bal -= _value;
    s.ownerInstallationBalances[_from][_id] = bal;
    if (bal == 0) {
      uint256 index = s.ownerInstallationIndexes[_from][_id] - 1;
      uint256 lastIndex = s.ownerInstallations[_from].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.ownerInstallations[_from][lastIndex];
        s.ownerInstallations[_from][index] = lastId;
        s.ownerInstallationIndexes[_from][lastId] = index + 1;
      }
      s.ownerInstallations[_from].pop();
      delete s.ownerInstallationIndexes[_from][_id];
    }
  }

  function _burn(
    address _from,
    uint256 _installationType,
    uint256 _amount
  ) internal {
    removeFromOwner(_from, _installationType, _amount);
    emit LibERC1155.TransferSingle(address(this), _from, address(0), _installationType, _amount);
  }

  function onERC1155Received(
    address _operator,
    address _from,
    address _to,
    uint256 _id,
    uint256 _value,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data),
        "LibERC1155: Transfer rejected/failed by _to"
      );
    }
  }

  function onERC1155BatchReceived(
    address _operator,
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes memory _data
  ) internal {
    uint256 size;
    assembly {
      size := extcodesize(_to)
    }
    if (size > 0) {
      require(
        ERC1155_BATCH_ACCEPTED == IERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data),
        "LibERC1155: Transfer rejected/failed by _to"
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageInstallation, InstallationType, QueueItem, UpgradeQueue, Modifiers} from "../../libraries/AppStorageInstallation.sol";
import {LibSignature} from "../../libraries/LibSignature.sol";
import {RealmDiamond} from "../../interfaces/RealmDiamond.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {LibItems} from "../../libraries/LibItems.sol";
import {InstallationAdminFacet} from "./InstallationAdminFacet.sol";
import {LibInstallation} from "../../libraries/LibInstallation.sol";
import {LibERC1155} from "../../libraries/LibERC1155.sol";

contract TestInstallationFacet is Modifiers {
  event UpgradeInitiated(
    uint256 indexed _realmId,
    uint256 _coordinateX,
    uint256 _coordinateY,
    uint256 blockInitiated,
    uint256 readyBlock,
    uint256 installationId
  );

  event UpgradeFinalized(uint256 indexed _realmId, uint256 _coordinateX, uint256 _coordinateY, uint256 _newInstallationId);
  event UpgradeQueued(address indexed _owner, uint256 indexed _realmId, uint256 indexed _queueIndex);
  event UpgradeQueueFinalized(address indexed _owner, uint256 indexed _realmId, uint256 indexed _queueIndex);
  event UpgradeTimeReduced(uint256 indexed _queueId, uint256 indexed _realmId, uint256 _coordinateX, uint256 _coordinateY, uint40 _blocksReduced);

  function mockUpgradeInstallation(
    UpgradeQueue memory _upgradeQueue,
    uint256 _gotchiId,
    uint40 _gltr
  ) external {
    // Storing variables in memory needed for validation and execution
    uint256 nextLevelId = s.installationTypes[_upgradeQueue.installationId].nextLevelId;
    InstallationType memory nextInstallation = s.installationTypes[nextLevelId];
    RealmDiamond realm = RealmDiamond(s.realmDiamond);

    // Validation checks
    bytes32 uniqueHash = keccak256(
      abi.encodePacked(_upgradeQueue.parcelId, _upgradeQueue.coordinateX, _upgradeQueue.coordinateY, _upgradeQueue.installationId)
    );
    require(s.upgradeHashes[uniqueHash] == 0, "InstallationUpgradeFacet: Upgrade hash not unique");
    LibInstallation.checkUpgrade(_upgradeQueue, _gotchiId, realm);

    // For easier testing, we min gltr instead of reverting
    _gltr = nextInstallation.craftTime < _gltr ? nextInstallation.craftTime : _gltr;

    if (nextInstallation.craftTime - _gltr == 0) {
      //Confirm upgrade immediately
      emit UpgradeTimeReduced(0, _upgradeQueue.parcelId, _upgradeQueue.coordinateX, _upgradeQueue.coordinateY, _gltr);
      LibInstallation.upgradeInstallation(_upgradeQueue, nextLevelId, realm);
    } else {
      s.upgradeHashes[uniqueHash] = _upgradeQueue.parcelId;

      // Set the ready block and claimed flag before adding to the queue
      _upgradeQueue.readyBlock = uint40(block.number) + nextInstallation.craftTime - _gltr;
      _upgradeQueue.claimed = false;
      LibInstallation.addToUpgradeQueue(_upgradeQueue, realm);
    }
  }

  /// @notice Craft installations without checks
  function mockCraftInstallation(uint16 installationId) external {
    LibERC1155._safeMint(msg.sender, installationId, 1, false, 0);
  }

  function mockGetInstallationsLength() external view returns (uint256) {
    return s.installationTypes.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {InstallationType, InstallationTypeIO, Modifiers, UpgradeQueue} from "../../libraries/AppStorageInstallation.sol";
import {RealmDiamond} from "../../interfaces/RealmDiamond.sol";
import {LibSignature} from "../../libraries/LibSignature.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {LibItems} from "../../libraries/LibItems.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {LibERC1155} from "../../libraries/LibERC1155.sol";
import {LibERC998} from "../../libraries/LibERC998.sol";

contract InstallationAdminFacet is Modifiers {
  event AddressesUpdated(
    address _aavegotchiDiamond,
    address _realmDiamond,
    address _gltr,
    address _pixelcraft,
    address _aavegotchiDAO,
    bytes _backendPubKey
  );

  event AddInstallationType(uint256 _installationId);
  event EditInstallationType(uint256 _installationId);
  event DeprecateInstallation(uint256 _installationId);
  event SetInstallationUnequipType(uint256 _installationId, uint256 _unequipType);
  event EditInstallationUnequipType(uint256 _installationId);
  event UpgradeCancelled(uint256 indexed _realmId, uint256 _coordinateX, uint256 _coordinateY, uint256 _installationId);

  /// @notice Allow the Diamond owner to deprecate an installation
  /// @dev Deprecated installations cannot be crafted by users
  /// @param _installationIds An array containing the identifiers of installations to deprecate
  function deprecateInstallations(uint256[] calldata _installationIds) external onlyOwner {
    for (uint256 i = 0; i < _installationIds.length; i++) {
      s.installationTypes[_installationIds[i]].deprecated = true;
      emit DeprecateInstallation(_installationIds[i]);
    }
  }

  /// @notice Allow the diamond owner to set some important contract addresses
  /// @param _aavegotchiDiamond The aavegotchi diamond address
  /// @param _realmDiamond The Realm diamond address
  /// @param _gltr The $GLTR token address
  /// @param _pixelcraft Pixelcraft address
  /// @param _aavegotchiDAO The Aavegotchi DAO address
  /// @param _backendPubKey The Backend Key
  function setAddresses(
    address _aavegotchiDiamond,
    address _realmDiamond,
    address _gltr,
    address _pixelcraft,
    address _aavegotchiDAO,
    bytes calldata _backendPubKey
  ) external onlyOwner {
    s.aavegotchiDiamond = _aavegotchiDiamond;
    s.realmDiamond = _realmDiamond;
    s.gltr = _gltr;
    s.pixelcraft = _pixelcraft;
    s.aavegotchiDAO = _aavegotchiDAO;
    s.backendPubKey = _backendPubKey;
    emit AddressesUpdated(_aavegotchiDiamond, _realmDiamond, _gltr, _pixelcraft, _aavegotchiDAO, _backendPubKey);
  }

  function getAddresses()
    external
    view
    returns (
      address _aavegotchiDiamond,
      address _realmDiamond,
      address _gltr,
      address _pixelcraft,
      address _aavegotchiDAO,
      bytes memory _backendPubKey
    )
  {
    return (s.aavegotchiDiamond, s.realmDiamond, s.gltr, s.pixelcraft, s.aavegotchiDAO, s.backendPubKey);
  }

  /// @notice Allow the diamond owner to add an installation type
  /// @param _installationTypes An array of structs, each struct representing each installationType to be added
  function addInstallationTypes(InstallationTypeIO[] calldata _installationTypes) external onlyOwner {
    for (uint256 i = 0; i < _installationTypes.length; i++) {
      s.installationTypes.push(
        InstallationType(
          _installationTypes[i].width,
          _installationTypes[i].height,
          _installationTypes[i].installationType,
          _installationTypes[i].level,
          _installationTypes[i].alchemicaType,
          _installationTypes[i].spillRadius,
          _installationTypes[i].spillRate,
          _installationTypes[i].upgradeQueueBoost,
          _installationTypes[i].craftTime,
          _installationTypes[i].nextLevelId,
          _installationTypes[i].deprecated,
          _installationTypes[i].alchemicaCost,
          _installationTypes[i].harvestRate,
          _installationTypes[i].capacity,
          _installationTypes[i].prerequisites,
          _installationTypes[i].name
        )
      );
      s.unequipTypes[s.installationTypes.length - 1] = _installationTypes[i].unequipType;

      emit AddInstallationType(s.installationTypes.length - 1);
      emit SetInstallationUnequipType(s.installationTypes.length - 1, _installationTypes[i].unequipType);
    }
  }

  function editDeprecateTime(uint256 _typeId, uint40 _deprecateTime) external onlyOwner {
    s.deprecateTime[_typeId] = _deprecateTime;
  }

  function editInstallationTypes(uint256[] calldata _ids, InstallationType[] calldata _installationTypes) external onlyOwner {
    require(_ids.length == _installationTypes.length, "InstallationAdminFacet: Mismatched arrays");
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      s.installationTypes[id] = _installationTypes[i];
      emit EditInstallationType(id);
    }
  }

  function editInstallationUnequipTypes(uint256[] calldata _ids, uint256[] calldata _unequipTypes) external onlyOwner {
    require(_ids.length == _unequipTypes.length, "InstallationAdminFacet: Mismatched arrays");
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 id = _ids[i];
      s.unequipTypes[id] = _unequipTypes[i];
      emit EditInstallationUnequipType(id);
    }
  }

  /// @notice Allow the owner to mint installations
  /// @dev This function does not check for deprecation because otherwise the installations could be minted by players.
  /// @dev Make sure that the installation is deprecated when you add it onchain
  /// @param _installationIds An array containing the identifiers of the installationTypes to mint
  /// @param _amounts An array containing the amounts of the installationTypes to mint
  /// @param _toAddress Address to mint installations
  function mintInstallations(
    uint16[] calldata _installationIds,
    uint16[] calldata _amounts,
    address _toAddress
  ) external onlyOwner {
    require(_installationIds.length == _amounts.length, "InstallationFacet: Mismatched arrays");
    for (uint256 i = 0; i < _installationIds.length; i++) {
      uint256 installationId = _installationIds[i];
      require(installationId < s.installationTypes.length, "InstallationFacet: Installation does not exist");

      InstallationType memory installationType = s.installationTypes[installationId];
      require(installationType.deprecated, "InstallationFacet: Not deprecated");
      //level check
      require(installationType.level == 1, "InstallationFacet: Can only craft level 1");

      LibERC1155._safeMint(_toAddress, installationId, _amounts[i], false, 0);
    }
  }

  struct MissingAltars {
    uint256 _parcelId;
    uint256 _oldAltarId;
    uint256 _newAltarId;
  }

  function fixMissingAltars(MissingAltars[] memory _altars) external onlyOwner {
    for (uint256 i = 0; i < _altars.length; i++) {
      MissingAltars memory altar = _altars[i];
      uint256 parcelId = altar._parcelId;
      uint256 oldId = altar._oldAltarId;
      uint256 newId = altar._newAltarId;

      RealmDiamond realm = RealmDiamond(address(s.realmDiamond));

      if (oldId > 0) {
        //remove old id
        LibERC998.removeFromParent(s.realmDiamond, parcelId, oldId, 1);
      }

      //mint new id to owner
      LibERC1155._safeMint(realm.ownerOf(parcelId), newId, 1, false, 0);

      //remove from owner
      LibERC1155.removeFromOwner(realm.ownerOf(parcelId), newId, 1);
      LibERC998.addToParent(s.realmDiamond, parcelId, newId, 1);

      //fix
      LibERC1155.addToOwner(s.realmDiamond, newId, 1);
    }
  }

  ///@notice Used if a parcel has an upgrade that must be deleted.
  function deleteBuggedUpgrades(
    uint256 _parcelId,
    uint256 _coordinateX,
    uint256 _coordinateY,
    uint256 _installationId,
    uint256 _upgradeIndex
  ) external onlyOwner {
    // check unique hash
    bytes32 uniqueHash = keccak256(abi.encodePacked(_parcelId, _coordinateX, _coordinateY, _installationId));
    s.upgradeHashes[uniqueHash] = 0;

    delete s.upgradeQueue[_upgradeIndex];

    RealmDiamond realmDiamond = RealmDiamond(s.realmDiamond);
    realmDiamond.subUpgradeQueueLength(_parcelId);

    //@todo: Remove from parcel if needed
    // LibInstallation._removeFromParcelIdToUpgradeIds(_parcelid, _upgradeIndex);

    emit UpgradeCancelled(_parcelId, _coordinateX, _coordinateY, _installationId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {RealmDiamond} from "../interfaces/RealmDiamond.sol";
import {IERC721} from "../interfaces/IERC721.sol";

import {LibERC998} from "../libraries/LibERC998.sol";
import {LibERC1155} from "../libraries/LibERC1155.sol";
import {LibMeta} from "../libraries/LibMeta.sol";

import {LibAppStorageInstallation, InstallationAppStorage, UpgradeQueue, InstallationType} from "../libraries/AppStorageInstallation.sol";

library LibInstallation {
  event UpgradeInitiated(
    uint256 indexed _realmId,
    uint256 _coordinateX,
    uint256 _coordinateY,
    uint256 blockInitiated,
    uint256 readyBlock,
    uint256 installationId
  );
  event UpgradeFinalized(uint256 indexed _realmId, uint256 _coordinateX, uint256 _coordinateY, uint256 _newInstallationId);
  event UpgradeQueued(address indexed _owner, uint256 indexed _realmId, uint256 indexed _queueIndex);
  event UpgradeQueueFinalized(address indexed _owner, uint256 indexed _realmId, uint256 indexed _queueIndex);

  function _equipInstallation(
    address _owner,
    uint256 _realmId,
    uint256 _installationId
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    LibERC1155.removeFromOwner(_owner, _installationId, 1);
    LibERC1155.addToOwner(s.realmDiamond, _installationId, 1);
    emit LibERC1155.TransferSingle(address(this), _owner, s.realmDiamond, _installationId, 1);
    LibERC998.addToParent(s.realmDiamond, _realmId, _installationId, 1);
    emit LibERC1155.TransferToParent(s.realmDiamond, _realmId, _installationId, 1);
  }

  function _unequipInstallation(
    address _owner,
    uint256 _realmId,
    uint256 _installationId
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    LibERC998.removeFromParent(s.realmDiamond, _realmId, _installationId, 1);
    emit LibERC1155.TransferFromParent(s.realmDiamond, _realmId, _installationId, 1);

    //add to owner for unequipType 1
    if (s.unequipTypes[_installationId] == 1) {
      LibERC1155.addToOwner(_owner, _installationId, 1);
      emit LibERC1155.TransferSingle(address(this), s.realmDiamond, _owner, _installationId, 1);
    } else {
      //default case: burn
      LibERC1155._burn(s.realmDiamond, _installationId, 1);
    }
  }

  /// @dev It is not expected for any of these dynamic arrays to have more than a small number of elements, so we use a naive removal approach
  function _removeFromParcelIdToUpgradeIds(uint256 _parcel, uint256 _upgradeId) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    uint256[] storage upgradeIds = s.parcelIdToUpgradeIds[_parcel];
    uint256 index = containsId(_upgradeId, upgradeIds);

    if (index != type(uint256).max) {
      uint256 last = upgradeIds[upgradeIds.length - 1];
      upgradeIds[index] = last;
      upgradeIds.pop();
    }
  }

  /// @return index The index of the id in the array
  function containsId(uint256 _id, uint256[] memory _ids) internal pure returns (uint256 index) {
    for (uint256 i; i < _ids.length; ) {
      if (_ids[i] == _id) {
        return i;
      }
      unchecked {
        ++i;
      }
    }
    return type(uint256).max;
  }

  function checkUpgrade(
    UpgradeQueue memory _upgradeQueue,
    uint256 _gotchiId,
    RealmDiamond _realmDiamond
  ) internal view {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();

    // // check owner
    // require(IERC721(address(_realmDiamond)).ownerOf(_upgradeQueue.parcelId) == _upgradeQueue.owner, "LibInstallation: Not owner");
    // // check coordinates

    // verify access right
    _realmDiamond.verifyAccessRight(_upgradeQueue.parcelId, _gotchiId, 6, LibMeta.msgSender());

    _realmDiamond.checkCoordinates(_upgradeQueue.parcelId, _upgradeQueue.coordinateX, _upgradeQueue.coordinateY, _upgradeQueue.installationId);

    //current installation
    InstallationType memory prevInstallation = s.installationTypes[_upgradeQueue.installationId];

    //next level
    InstallationType memory nextInstallation = s.installationTypes[prevInstallation.nextLevelId];

    // check altar requirement
    // altar prereq is 0
    if (nextInstallation.prerequisites[0] > 0) {
      uint256 equippedAltarId = _realmDiamond.getAltarId(_upgradeQueue.parcelId);
      uint256 equippedAltarLevel = s.installationTypes[equippedAltarId].level;
      require(equippedAltarLevel >= nextInstallation.prerequisites[0], "LibInstallation: Altar Tech Tree Reqs not met");
    }

    require(prevInstallation.nextLevelId > 0, "LibInstallation: Maximum upgrade reached");
    require(prevInstallation.installationType == nextInstallation.installationType, "LibInstallation: Wrong installation type");
    require(prevInstallation.alchemicaType == nextInstallation.alchemicaType, "LibInstallation: Wrong alchemicaType");
    require(prevInstallation.level == nextInstallation.level - 1, "LibInstallation: Wrong installation level");

    //@todo: check for lodge prereq once lodges are implemented
  }

  function upgradeInstallation(
    UpgradeQueue memory _upgradeQueue,
    uint256 _nextLevelId,
    RealmDiamond _realmDiamond
  ) internal {
    LibInstallation._unequipInstallation(_upgradeQueue.owner, _upgradeQueue.parcelId, _upgradeQueue.installationId);
    // mint new installation
    //mint without queue
    LibERC1155._safeMint(_upgradeQueue.owner, _nextLevelId, 1, false, 0);
    // equip new installation
    LibInstallation._equipInstallation(_upgradeQueue.owner, _upgradeQueue.parcelId, _nextLevelId);

    _realmDiamond.upgradeInstallation(
      _upgradeQueue.parcelId,
      _upgradeQueue.installationId,
      _nextLevelId,
      _upgradeQueue.coordinateX,
      _upgradeQueue.coordinateY
    );

    emit UpgradeFinalized(_upgradeQueue.parcelId, _upgradeQueue.coordinateX, _upgradeQueue.coordinateY, _nextLevelId);
  }

  function addToUpgradeQueue(UpgradeQueue memory _upgradeQueue, RealmDiamond _realmDiamond) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    //check upgradeQueueCapacity
    require(
      _realmDiamond.getParcelUpgradeQueueCapacity(_upgradeQueue.parcelId) > _realmDiamond.getParcelUpgradeQueueLength(_upgradeQueue.parcelId),
      "LibInstallation: UpgradeQueue full"
    );
    s.upgradeQueue.push(_upgradeQueue);

    // update upgradeQueueLength
    _realmDiamond.addUpgradeQueueLength(_upgradeQueue.parcelId);

    // Add to indexing helper to help for efficient getter
    uint256 upgradeIdIndex = s.upgradeQueue.length - 1;
    s.parcelIdToUpgradeIds[_upgradeQueue.parcelId].push(upgradeIdIndex);

    emit UpgradeInitiated(
      _upgradeQueue.parcelId,
      _upgradeQueue.coordinateX,
      _upgradeQueue.coordinateY,
      block.number,
      _upgradeQueue.readyBlock,
      _upgradeQueue.installationId
    );
    emit UpgradeQueued(_upgradeQueue.owner, _upgradeQueue.parcelId, upgradeIdIndex);
  }

  function finalizeUpgrade(address _owner, uint256 index) internal returns (bool) {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();

    if (s.upgradeComplete[index]) return true;
    uint40 readyBlock = s.upgradeQueue[index].readyBlock;
    uint256 parcelId = s.upgradeQueue[index].parcelId;
    uint256 installationId = s.upgradeQueue[index].installationId;
    uint256 coordinateX = s.upgradeQueue[index].coordinateX;
    uint256 coordinateY = s.upgradeQueue[index].coordinateY;

    // check that upgrade is ready
    if (block.number >= readyBlock) {
      // burn old installation
      LibInstallation._unequipInstallation(_owner, parcelId, installationId);
      // mint new installation
      uint256 nextLevelId = s.installationTypes[installationId].nextLevelId;
      LibERC1155._safeMint(_owner, nextLevelId, 1, true, index);
      // equip new installation
      LibInstallation._equipInstallation(_owner, parcelId, nextLevelId);

      RealmDiamond realm = RealmDiamond(s.realmDiamond);
      realm.upgradeInstallation(parcelId, installationId, nextLevelId, coordinateX, coordinateY);

      // update updateQueueLength
      realm.subUpgradeQueueLength(parcelId);

      // clean unique hash
      bytes32 uniqueHash = keccak256(abi.encodePacked(parcelId, coordinateX, coordinateY, installationId));
      s.upgradeHashes[uniqueHash] = 0;

      s.upgradeComplete[index] = true;

      LibInstallation._removeFromParcelIdToUpgradeIds(parcelId, index);

      emit UpgradeFinalized(parcelId, coordinateX, coordinateY, nextLevelId);
      emit UpgradeQueueFinalized(_owner, parcelId, index);
      return true;
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageInstallation, InstallationAppStorage, InstallationType} from "./AppStorageInstallation.sol";
import {LibERC1155} from "./LibERC1155.sol";

struct ItemTypeIO {
  uint256 balance;
  uint256 itemId;
  InstallationType installationType;
}

library LibERC998 {
  function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    internal
    view
    returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_)
  {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    uint256 count = s.nftInstallations[_tokenContract][_tokenId].length;
    itemBalancesOfTokenWithTypes_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 itemId = s.nftInstallations[_tokenContract][_tokenId][i];
      uint256 bal = s.nftInstallationBalances[_tokenContract][_tokenId][itemId];
      itemBalancesOfTokenWithTypes_[i].itemId = itemId;
      itemBalancesOfTokenWithTypes_[i].balance = bal;
      itemBalancesOfTokenWithTypes_[i].installationType = s.installationTypes[itemId];
    }
  }

  function addToParent(
    address _toContract,
    uint256 _toTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    s.nftInstallationBalances[_toContract][_toTokenId][_id] += _value;
    if (s.nftInstallationIndexes[_toContract][_toTokenId][_id] == 0) {
      s.nftInstallations[_toContract][_toTokenId].push(_id);
      s.nftInstallationIndexes[_toContract][_toTokenId][_id] = s.nftInstallations[_toContract][_toTokenId].length;
    }
  }

  function removeFromParent(
    address _fromContract,
    uint256 _fromTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    uint256 bal = s.nftInstallationBalances[_fromContract][_fromTokenId][_id];
    require(_value <= bal, "Items: Doesn't have that many to transfer");
    bal -= _value;
    s.nftInstallationBalances[_fromContract][_fromTokenId][_id] = bal;
    if (bal == 0) {
      uint256 index = s.nftInstallationIndexes[_fromContract][_fromTokenId][_id] - 1;
      uint256 lastIndex = s.nftInstallations[_fromContract][_fromTokenId].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.nftInstallations[_fromContract][_fromTokenId][lastIndex];
        s.nftInstallations[_fromContract][_fromTokenId][index] = lastId;
        s.nftInstallationIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
      }
      s.nftInstallations[_fromContract][_fromTokenId].pop();
      delete s.nftInstallationIndexes[_fromContract][_fromTokenId][_id];
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibAppStorageTile, TileAppStorage} from "../libraries/AppStorageTile.sol";

contract TileDiamond {
  constructor(
    address _contractOwner,
    address _diamondCutFacet,
    address _realmDiamond
  ) payable {
    LibDiamond.setContractOwner(_contractOwner);

    // Add the diamondCut external function from the diamondCutFacet
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
    bytes4[] memory functionSelectors = new bytes4[](1);
    functionSelectors[0] = IDiamondCut.diamondCut.selector;
    cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
    LibDiamond.diamondCut(cut, address(0), "");

    TileAppStorage storage s = LibAppStorageTile.diamondStorage();
    s.realmDiamond = _realmDiamond;
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
    address facet = address(bytes20(ds.facets[msg.sig]));
    require(facet != address(0), "Diamond: Function does not exist");
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";
import {AppStorage} from "../libraries/AppStorage.sol";

contract DiamondInit {
  AppStorage internal s;

  function init() external {
    // adding ERC165 data
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    ds.supportedInterfaces[type(IERC165).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
    ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    ds.supportedInterfaces[type(IERC1155).interfaceId] = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title IERC165
/// @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/// @title ERC-1155 Multi Token Standard
/// @dev ee https://eips.ethereum.org/EIPS/eip-1155
///  The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/AppStorage.sol";

contract SetPubKeyFacet is Modifiers {
  function setPubKey(bytes memory _newPubKey) public {
    s.backendPubKey = _newPubKey;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../libraries/AppStorage.sol";
import "../../libraries/LibERC721.sol";
import "../../libraries/LibRealm.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFFacet is Modifiers {
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    require(LibMeta.msgSender() == s.vrfCoordinator, "Only VRFCoordinator can fulfill");
    uint256 tokenId = s.vrfRequestIdToTokenId[requestId];
    LibRealm.updateRemainingAlchemica(tokenId, randomWords, s.vrfRequestIdToSurveyingRound[requestId]);
  }

  function setConfig(RequestConfig calldata _requestConfig, address _vrfCoordinator) external onlyOwner {
    s.vrfCoordinator = _vrfCoordinator;
    s.requestConfig = RequestConfig(
      _requestConfig.subId,
      _requestConfig.callbackGasLimit,
      _requestConfig.requestConfirmations,
      _requestConfig.numWords,
      _requestConfig.keyHash
    );
  }

  function subscribe() external onlyOwner {
    address[] memory consumers = new address[](1);
    consumers[0] = address(this);
    s.requestConfig.subId = VRFCoordinatorV2Interface(s.vrfCoordinator).createSubscription();
    VRFCoordinatorV2Interface(s.vrfCoordinator).addConsumer(s.requestConfig.subId, consumers[0]);
  }

  // Assumes this contract owns link
  function topUpSubscription(uint256 amount) external {
    LinkTokenInterface(s.linkAddress).transferAndCall(s.vrfCoordinator, amount, abi.encode(s.requestConfig.subId));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../libraries/AppStorage.sol";
import "./RealmFacet.sol";
import "../../libraries/LibRealm.sol";
import "../../libraries/LibMeta.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../../libraries/LibAlchemica.sol";
import "../../libraries/LibSignature.sol";

uint256 constant bp = 100 ether;

contract AlchemicaFacet is Modifiers {
  event StartSurveying(uint256 _realmId, uint256 _round);

  event ChannelAlchemica(
    uint256 indexed _realmId,
    uint256 indexed _gotchiId,
    uint256[4] _alchemica,
    uint256 _spilloverRate,
    uint256 _spilloverRadius
  );

  event ExitAlchemica(uint256 indexed _gotchiId, uint256[] _alchemica);

  event SurveyingRoundProgressed(uint256 indexed _newRound);

  function isSurveying(uint256 _realmId) external view returns (bool) {
    return s.parcels[_realmId].surveying;
  }

  // /// @notice Allow the owner of a parcel to start surveying his parcel
  // /// @dev Will throw if a surveying round has not started
  // /// @param _realmId Identifier of the parcel to survey
  function startSurveying(uint256 _realmId) external onlyParcelOwner(_realmId) gameActive {
    //current round and surveying round both begin at 0.
    //after calling VRF, currentRound increases
    require(s.parcels[_realmId].currentRound <= s.surveyingRound, "AlchemicaFacet: Round not released");
    require(s.parcels[_realmId].altarId > 0, "AlchemicaFacet: Must equip Altar");
    require(!s.parcels[_realmId].surveying, "AlchemicaFacet: Parcel already surveying");
    s.parcels[_realmId].surveying = true;
    // do we need to cancel the listing?
    drawRandomNumbers(_realmId, s.parcels[_realmId].currentRound);

    emit StartSurveying(_realmId, s.parcels[_realmId].currentRound);
  }

  function drawRandomNumbers(uint256 _realmId, uint256 _surveyingRound) internal {
    // Will revert if subscription is not set and funded.
    uint256 requestId = VRFCoordinatorV2Interface(s.vrfCoordinator).requestRandomWords(
      s.requestConfig.keyHash,
      s.requestConfig.subId,
      s.requestConfig.requestConfirmations,
      s.requestConfig.callbackGasLimit,
      s.requestConfig.numWords
    );
    s.vrfRequestIdToTokenId[requestId] = _realmId;
    s.vrfRequestIdToSurveyingRound[requestId] = _surveyingRound;
  }

  function getAlchemicaAddresses() external view returns (address[4] memory) {
    return s.alchemicaAddresses;
  }

  /// @notice Query details about all total alchemicas present
  /// @return output_ A two dimensional array, each representing an alchemica value
  function getTotalAlchemicas() external view returns (uint256[4][5] memory) {
    return s.totalAlchemicas;
  }

  /// @notice Query details about the remaining alchemica in a parcel
  /// @param _realmId The identifier of the parcel to query
  /// @return output_ An array containing details about each remaining alchemica in the parcel
  function getRealmAlchemica(uint256 _realmId) external view returns (uint256[4] memory) {
    return s.parcels[_realmId].alchemicaRemaining;
  }

  /// @notice Allow the diamond owner to increment the surveying round
  function progressSurveyingRound() external onlyOwner {
    s.surveyingRound++;
    emit SurveyingRoundProgressed(s.surveyingRound);
  }

  /// @notice Query details about all alchemica gathered in a surveying round in a parcel
  /// @param _realmId Identifier of the parcel to query
  /// @param _roundId Identifier of the surveying round to query
  /// @return output_ An array representing the numbers of alchemica gathered in a round
  function getRoundAlchemica(uint256 _realmId, uint256 _roundId) external view returns (uint256[] memory) {
    return s.parcels[_realmId].roundAlchemica[_roundId];
  }

  /// @notice Query details about the base alchemica gathered in a surveying round in a parcel
  /// @param _realmId Identifier of the parcel to query
  /// @param _roundId Identifier of the surveying round to query
  /// @return output_ An array representing the numbers of base alchemica gathered in a round
  function getRoundBaseAlchemica(uint256 _realmId, uint256 _roundId) external view returns (uint256[] memory) {
    return s.parcels[_realmId].roundBaseAlchemica[_roundId];
  }

  /// @notice Allow the diamond owner to set some important diamond state variables
  /// @param _alchemicas A nested array containing the amount of alchemicas available
  /// @param _boostMultipliers The boost multiplers applied to each parcel
  /// @param _greatPortalCapacity The individual alchemica capacity of the great portal
  /// @param _installationsDiamond The installations diamond address
  /// @param _vrfCoordinator The chainlink vrfCoordinator address
  /// @param _linkAddress The link token address
  /// @param _alchemicaAddresses The four alchemica token addresses
  /// @param _backendPubKey The Realm(gotchiverse) backend public key
  /// @param _gameManager The address of the game manager
  function setVars(
    uint256[4][5] calldata _alchemicas,
    uint256[4] calldata _boostMultipliers,
    uint256[4] calldata _greatPortalCapacity,
    address _installationsDiamond,
    address _vrfCoordinator,
    address _linkAddress,
    address[4] calldata _alchemicaAddresses,
    address _gltrAddress,
    bytes memory _backendPubKey,
    address _gameManager,
    address _tileDiamond,
    address _aavegotchiDiamond
  ) external onlyOwner {
    for (uint256 i; i < _alchemicas.length; i++) {
      for (uint256 j; j < _alchemicas[i].length; j++) {
        s.totalAlchemicas[i][j] = _alchemicas[i][j];
      }
    }
    s.boostMultipliers = _boostMultipliers;
    s.greatPortalCapacity = _greatPortalCapacity;
    s.installationsDiamond = _installationsDiamond;
    s.vrfCoordinator = _vrfCoordinator;
    s.linkAddress = _linkAddress;
    s.alchemicaAddresses = _alchemicaAddresses;
    s.backendPubKey = _backendPubKey;
    s.gameManager = _gameManager;
    s.gltrAddress = _gltrAddress;
    s.tileDiamond = _tileDiamond;
    s.aavegotchiDiamond = _aavegotchiDiamond;
  }

  function setTotalAlchemicas(uint256[4][5] calldata _totalAlchemicas) external onlyOwner {
    for (uint256 i; i < _totalAlchemicas.length; i++) {
      for (uint256 j; j < _totalAlchemicas[i].length; j++) {
        s.totalAlchemicas[i][j] = _totalAlchemicas[i][j];
      }
    }
  }

  /// @notice Query the available alchemica in a parcel
  /// @param _realmId identifier of parcel to query
  /// @return _availableAlchemica An array representing the available quantity of alchemicas
  function getAvailableAlchemica(uint256 _realmId) public view returns (uint256[4] memory _availableAlchemica) {
    for (uint256 i; i < 4; i++) {
      _availableAlchemica[i] = LibAlchemica.getAvailableAlchemica(_realmId, i);
    }
  }

  struct TransferAmounts {
    uint256 owner;
    uint256 spill;
  }

  function calculateTransferAmounts(uint256 _amount, uint256 _spilloverRate) internal pure returns (TransferAmounts memory) {
    uint256 owner = (_amount * (bp - (_spilloverRate * 10**16))) / bp;
    uint256 spill = (_amount * (_spilloverRate * 10**16)) / bp;
    return TransferAmounts(owner, spill);
  }

  function lastClaimedAlchemica(uint256 _realmId) external view returns (uint256) {
    return s.lastClaimedAlchemica[_realmId];
  }

  /// @notice Allow parcel owner to claim available alchemica with his parent NFT(Aavegotchi)
  /// @param _realmId Identifier of parcel to claim alchemica from
  /// @param _gotchiId Identifier of Aavegotchi to use for alchemica collecction/claiming
  /// @param _signature Message signature used for backend validation
  function claimAvailableAlchemica(
    uint256 _realmId,
    uint256 _gotchiId,
    bytes memory _signature
  ) external gameActive {
    //Check signature
    require(
      LibSignature.isValid(keccak256(abi.encode(_realmId, _gotchiId, s.lastClaimedAlchemica[_realmId])), _signature, s.backendPubKey),
      "AlchemicaFacet: Invalid signature"
    );

    //1 - Empty Reservoir Access Right
    LibRealm.verifyAccessRight(_realmId, _gotchiId, 1, LibMeta.msgSender());
    LibAlchemica.claimAvailableAlchemica(_realmId, _gotchiId);
  }

  function getHarvestRates(uint256 _realmId) external view returns (uint256[] memory harvestRates) {
    harvestRates = new uint256[](4);
    for (uint256 i; i < 4; i++) {
      harvestRates[i] = s.parcels[_realmId].alchemicaHarvestRate[i];
    }
  }

  function getCapacities(uint256 _realmId) external view returns (uint256[] memory capacities) {
    capacities = new uint256[](4);
    for (uint256 i; i < 4; i++) {
      capacities[i] = LibAlchemica.calculateTotalCapacity(_realmId, i);
    }
  }

  function getTotalClaimed(uint256 _realmId) external view returns (uint256[] memory totalClaimed) {
    totalClaimed = new uint256[](4);
    for (uint256 i; i < 4; i++) {
      totalClaimed[i] = LibAlchemica.getTotalClaimed(_realmId, i);
    }
  }

  /// @notice Allow a parcel owner to channel alchemica
  /// @dev This transfers alchemica to the parent ERC721 token with id _gotchiId and also to the great portal
  /// @param _realmId Identifier of parcel where alchemica is being channeled from
  /// @param _gotchiId Identifier of parent ERC721 aavegotchi which alchemica is channeled to
  /// @param _lastChanneled The last time alchemica was channeled in this _realmId
  /// @param _signature Message signature used for backend validation
  function channelAlchemica(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _lastChanneled,
    bytes memory _signature
  ) external gameActive {
    AavegotchiDiamond diamond = AavegotchiDiamond(s.aavegotchiDiamond);

    //0 - alchemical channeling
    LibRealm.verifyAccessRight(_realmId, _gotchiId, 0, LibMeta.msgSender());

    require(_lastChanneled == s.gotchiChannelings[_gotchiId], "AlchemicaFacet: Incorrect last duration");

    //Gotchis can only channel every 24 hrs
    if (s.lastChanneledDay[_gotchiId] == block.timestamp / (60 * 60 * 24)) revert("AlchemicaFacet: Gotchi can't channel yet");
    s.lastChanneledDay[_gotchiId] = block.timestamp / (60 * 60 * 24);

    uint256 altarLevel = InstallationDiamondInterface(s.installationsDiamond).getAltarLevel(s.parcels[_realmId].altarId);

    require(altarLevel > 0, "AlchemicaFacet: Must equip Altar");

    //How often Altars can channel depends on their level
    require(block.timestamp >= s.parcelChannelings[_realmId] + s.channelingLimits[altarLevel], "AlchemicaFacet: Parcel can't channel yet");

    //Use _lastChanneled to ensure that each signature hash is unique
    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_realmId, _gotchiId, _lastChanneled)), _signature, s.backendPubKey),
      "AlchemicaFacet: Invalid signature"
    );

    (uint256 rate, uint256 radius) = InstallationDiamondInterface(s.installationsDiamond).spilloverRateAndRadiusOfId(s.parcels[_realmId].altarId);

    require(rate > 0, "InstallationFacet: Spillover Rate cannot be 0");

    uint256[4] memory channelAmounts = [uint256(20e18), uint256(10e18), uint256(5e18), uint256(2e18)];
    // apply kinship modifier
    uint256 kinship = diamond.kinship(_gotchiId) * 10000;
    for (uint256 i; i < 4; i++) {
      uint256 kinshipModifier = floorSqrt(kinship / 50);
      channelAmounts[i] = (channelAmounts[i] * kinshipModifier) / 100;
    }

    for (uint256 i; i < channelAmounts.length; i++) {
      IERC20Mintable alchemica = IERC20Mintable(s.alchemicaAddresses[i]);

      //Mint new tokens if the Great Portal Balance is less than capacity

      if (alchemica.balanceOf(address(this)) < s.greatPortalCapacity[i]) {
        TransferAmounts memory amounts = calculateTransferAmounts(channelAmounts[i], rate);

        alchemica.mint(LibAlchemica.alchemicaRecipient(_gotchiId), amounts.owner);
        alchemica.mint(address(this), amounts.spill);
      } else {
        TransferAmounts memory amounts = calculateTransferAmounts(channelAmounts[i], rate);

        alchemica.transfer(LibAlchemica.alchemicaRecipient(_gotchiId), amounts.owner);
      }
    }

    //update latest channeling
    s.gotchiChannelings[_gotchiId] = block.timestamp;
    s.parcelChannelings[_realmId] = block.timestamp;
    //finally interact
    AavegotchiDiamond(s.aavegotchiDiamond).realmInteract(_gotchiId);
    emit ChannelAlchemica(_realmId, _gotchiId, channelAmounts, rate, radius);
  }

  /// @notice Return the last timestamp of a channeling
  /// @dev used as a parameter in channelAlchemica
  /// @param _gotchiId Identifier of parent ERC721 aavegotchi
  /// @return last channeling timestamp
  function getLastChanneled(uint256 _gotchiId) public view returns (uint256) {
    return s.gotchiChannelings[_gotchiId];
  }

  /// @notice Return the last timestamp of an altar channeling
  /// @dev used as a parameter in channelAlchemica
  /// @param _parcelId Identifier of ERC721 parcel
  /// @return last channeling timestamp
  function getParcelLastChanneled(uint256 _parcelId) public view returns (uint256) {
    return s.parcelChannelings[_parcelId];
  }

  /// @notice Helper function to batch transfer alchemica
  /// @param _targets Array of target addresses
  /// @param _amounts Nested array of amounts to transfer.
  /// @dev The inner array element order for _amounts is FUD, FOMO, ALPHA, KEK
  function batchTransferAlchemica(address[] calldata _targets, uint256[4][] calldata _amounts) external {
    require(_targets.length == _amounts.length, "AlchemicaFacet: Mismatched array lengths");

    IERC20Mintable[4] memory alchemicas = [
      IERC20Mintable(s.alchemicaAddresses[0]),
      IERC20Mintable(s.alchemicaAddresses[1]),
      IERC20Mintable(s.alchemicaAddresses[2]),
      IERC20Mintable(s.alchemicaAddresses[3])
    ];

    for (uint256 i = 0; i < _targets.length; i++) {
      for (uint256 j = 0; j < _amounts[i].length; j++) {
        if (_amounts[i][j] > 0) {
          alchemicas[j].transferFrom(msg.sender, _targets[i], _amounts[i][j]);
        }
      }
    }
  }

  /// @notice Helper function to batch transfer alchemica to Aavegotchis
  /// @param _gotchiIds Array of Gotchi IDs
  /// @param _tokenAddresses Array of tokens to transfer
  /// @param _amounts Nested array of amounts to transfer.
  function batchTransferTokensToGotchis(
    uint256[] calldata _gotchiIds,
    address[] calldata _tokenAddresses,
    uint256[][] calldata _amounts
  ) external {
    require(_gotchiIds.length == _amounts.length, "AlchemicaFacet: Mismatched array lengths");

    for (uint256 i = 0; i < _gotchiIds.length; i++) {
      for (uint256 j = 0; j < _amounts[i].length; j++) {
        require(_tokenAddresses.length == _amounts[i].length, "RealmFacet: Mismatched array lengths");
        uint256 amount = _amounts[i][j];
        if (amount > 0) {
          IERC20(_tokenAddresses[j]).transferFrom(msg.sender, LibAlchemica.alchemicaRecipient(_gotchiIds[i]), amount);
        }
      }
    }
  }

  /// @notice Owner function to change the altars channeling limits
  /// @param _altarLevel Array of altars level
  /// @param _limits Array of time limits
  function setChannelingLimits(uint256[] calldata _altarLevel, uint256[] calldata _limits) external onlyOwner {
    require(_altarLevel.length == _limits.length, "AlchemicaFacet: array mismatch");
    for (uint256 i; i < _limits.length; i++) {
      s.channelingLimits[_altarLevel[i]] = _limits[i];
    }
  }

  /// @notice Calculate the floor square root of a number
  /// @param n Input number
  function floorSqrt(uint256 n) internal pure returns (uint256) {
    unchecked {
      if (n > 0) {
        uint256 x = n / 2 + 1;
        uint256 y = (x + n / x) / 2;
        while (x > y) {
          x = y;
          y = (x + n / x) / 2;
        }
        return x;
      }
      return 0;
    }
  }
}

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

  // function fixGrid(
  //   uint256 _realmId,
  //   uint256 _installationId,
  //   uint256[] memory _x,
  //   uint256[] memory _y,
  //   bool tile
  // ) external onlyOwner {
  //   require(_x.length == _y.length, "RealmFacet: _x and _y must be the same length");
  //   Parcel storage parcel = s.parcels[_realmId];
  //   for (uint256 i; i < _x.length; i++) {
  //     require(_x[i] < 64 && _y[i] < 64, "RealmFacet: _x and _y must be less than 64");
  //     if (!tile) {
  //       parcel.buildGrid[_x[i]][_y[i]] = _installationId;
  //     } else {
  //       parcel.tileGrid[_x[i]][_y[i]] = _installationId;
  //     }
  //   }
  // }

  function buildingFrozen() external view returns (bool) {
    return s.freezeBuilding;
  }

  function setFreezeBuilding(bool _freezeBuilding) external onlyOwner {
    s.freezeBuilding = _freezeBuilding;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../libraries/AppStorage.sol";

import "../../libraries/LibRealm.sol";
import "../../libraries/LibAlchemica.sol";

import {InstallationDiamondInterface} from "../../interfaces/InstallationDiamondInterface.sol";
import "./ERC721Facet.sol";

contract RealmGettersAndSettersFacet is Modifiers {
  event ParcelAccessRightSet(uint256 _realmId, uint256 _actionRight, uint256 _accessRight);
  event ResyncParcel(uint256 _realmId);
  event SetAltarId(uint256 _realmId, uint256 _altarId);

  /// @notice Return the maximum realm supply
  /// @return The max realm token supply
  function maxSupply() external pure returns (uint256) {
    return LibRealm.MAX_SUPPLY;
  }

  function setParcelsAccessRights(
    uint256[] calldata _realmIds,
    uint256[] calldata _actionRights,
    uint256[] calldata _accessRights
  ) external gameActive {
    require(_realmIds.length == _accessRights.length && _realmIds.length == _actionRights.length, "RealmGettersAndSettersFacet: Mismatched arrays");
    for (uint256 i; i < _realmIds.length; i++) {
      require(LibMeta.msgSender() == s.parcels[_realmIds[i]].owner, "RealmGettersAndSettersFacet: Only Parcel owner can call");
      require(LibRealm.isAccessRightValid(_actionRights[i], _accessRights[i]), "RealmGettersAndSettersFacet: Invalid access rights");
      s.accessRights[_realmIds[i]][_actionRights[i]] = _accessRights[i];
      emit ParcelAccessRightSet(_realmIds[i], _actionRights[i], _accessRights[i]);
    }
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
    require(parcel.buildGrid[_coordinateX][_coordinateY] == _installationId, "RealmGettersAndSettersFacet: wrong coordinates");
    require(parcel.startPositionBuildGrid[_coordinateX][_coordinateY] == _installationId, "RealmGettersAndSettersFacet: wrong coordinates");
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
    require(_parcelIds.length == _actionRights.length, "RealmGettersAndSettersFacet: Mismatched arrays");
    output_ = new uint256[](_parcelIds.length);
    for (uint256 i; i < _parcelIds.length; i++) {
      output_[i] = s.accessRights[_parcelIds[i]][_actionRights[i]];
    }
    return output_;
  }

  function getAltarId(uint256 _parcelId) external view returns (uint256) {
    return s.parcels[_parcelId].altarId;
  }

  function setAltarId(uint256 _parcelId, uint256 _altarId) external onlyOwner {
    s.parcels[_parcelId].altarId = _altarId;
    emit SetAltarId(_parcelId, _altarId);
  }

  function verifyAccessRight(
    uint256 _realmId,
    uint256 _gotchiId,
    uint256 _actionRight,
    address _sender
  ) external view {
    LibRealm.verifyAccessRight(_realmId, _gotchiId, _actionRight, _sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibAppStorageInstallation, InstallationAppStorage} from "../libraries/AppStorageInstallation.sol";

contract InstallationDiamond {
  constructor(
    address _contractOwner,
    address _diamondCutFacet,
    address _realmDiamond
  ) payable {
    LibDiamond.setContractOwner(_contractOwner);

    // Add the diamondCut external function from the diamondCutFacet
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
    bytes4[] memory functionSelectors = new bytes4[](1);
    functionSelectors[0] = IDiamondCut.diamondCut.selector;
    cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
    LibDiamond.diamondCut(cut, address(0), "");

    InstallationAppStorage storage s = LibAppStorageInstallation.diamondStorage();
    s.realmDiamond = _realmDiamond;
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
    address facet = address(bytes20(ds.facets[msg.sig]));
    require(facet != address(0), "Diamond: Function does not exist");
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageInstallation, InstallationType, QueueItem, UpgradeQueue, Modifiers} from "../../libraries/AppStorageInstallation.sol";
import {LibSignature} from "../../libraries/LibSignature.sol";
import {RealmDiamond} from "../../interfaces/RealmDiamond.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {LibItems} from "../../libraries/LibItems.sol";
import {InstallationAdminFacet} from "./InstallationAdminFacet.sol";
import {LibInstallation} from "../../libraries/LibInstallation.sol";
import {LibERC1155} from "../../libraries/LibERC1155.sol";
import {LibERC998} from "../../libraries/LibERC998.sol";
import {LibMeta} from "../../libraries/LibMeta.sol";

contract InstallationUpgradeFacet is Modifiers {
  event UpgradeTimeReduced(uint256 indexed _queueId, uint256 indexed _realmId, uint256 _coordinateX, uint256 _coordinateY, uint40 _blocksReduced);

  /// @notice Allow a user to upgrade an installation in a parcel
  /// @dev Will throw if the caller is not the owner of the parcel in which the installation is installed
  /// @param _upgradeQueue A struct containing details about the queue which contains the installation to upgrade
  /// @param _gotchiId The id of the gotchi which is upgrading the installation
  ///@param _signature API signature
  ///@param _gltr Amount of GLTR to use, can be 0
  function upgradeInstallation(
    UpgradeQueue memory _upgradeQueue,
    uint256 _gotchiId,
    bytes memory _signature,
    uint40 _gltr
  ) external {
    // Check signature
    require(
      LibSignature.isValid(
        keccak256(
          abi.encodePacked(_upgradeQueue.parcelId, _upgradeQueue.coordinateX, _upgradeQueue.coordinateY, _upgradeQueue.installationId, _gotchiId)
        ),
        _signature,
        s.backendPubKey
      ),
      "InstallationUpgradeFacet: Invalid signature"
    );

    // Storing variables in memory needed for validation and execution
    uint256 nextLevelId = s.installationTypes[_upgradeQueue.installationId].nextLevelId;
    InstallationType memory nextInstallation = s.installationTypes[nextLevelId];
    RealmDiamond realm = RealmDiamond(s.realmDiamond);

    // Validation checks
    bytes32 uniqueHash = keccak256(
      abi.encodePacked(_upgradeQueue.parcelId, _upgradeQueue.coordinateX, _upgradeQueue.coordinateY, _upgradeQueue.installationId)
    );
    require(s.upgradeHashes[uniqueHash] == 0, "InstallationUpgradeFacet: Upgrade hash not unique");

    LibInstallation.checkUpgrade(_upgradeQueue, _gotchiId, realm);

    // Take the required alchemica and GLTR
    LibItems._splitAlchemica(nextInstallation.alchemicaCost, realm.getAlchemicaAddresses());
    //prevent underflow if user sends too much GLTR
    require(_gltr <= nextInstallation.craftTime, "InstallationUpgradeFacet: Too much GLTR");

    require(
      IERC20(s.gltr).transferFrom(LibMeta.msgSender(), 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, (uint256(_gltr) * 1e18)),
      "InstallationUpgradeFacet: Failed GLTR transfer"
    ); //should revert if user doesnt have enough GLTR

    if (nextInstallation.craftTime - _gltr == 0) {
      //Confirm upgrade immediately
      emit UpgradeTimeReduced(0, _upgradeQueue.parcelId, _upgradeQueue.coordinateX, _upgradeQueue.coordinateY, _gltr);
      LibInstallation.upgradeInstallation(_upgradeQueue, nextLevelId, realm);
    } else {
      // Add upgrade hash to maintain uniqueness in upgrades
      s.upgradeHashes[uniqueHash] = _upgradeQueue.parcelId;
      // Set the ready block and claimed flag before adding to the queue
      _upgradeQueue.readyBlock = uint40(block.number) + nextInstallation.craftTime - _gltr;
      _upgradeQueue.claimed = false;
      LibInstallation.addToUpgradeQueue(_upgradeQueue, realm);
    }
  }

  /// @notice Allow anyone to finalize any existing queue upgrade
  function finalizeUpgrades(uint256[] memory _upgradeIndexes) external {
    for (uint256 i; i < _upgradeIndexes.length; i++) {
      UpgradeQueue storage upgradeQueue = s.upgradeQueue[_upgradeIndexes[i]];
      LibInstallation.finalizeUpgrade(upgradeQueue.owner, _upgradeIndexes[i]);
    }
  }

  function reduceUpgradeTime(
    uint256 _upgradeIndex,
    uint256 _gotchiId,
    uint40 _blocks,
    bytes memory _signature
  ) external {
    UpgradeQueue storage queue = s.upgradeQueue[_upgradeIndex];

    require(
      LibSignature.isValid(keccak256(abi.encodePacked(_upgradeIndex)), _signature, s.backendPubKey),
      "InstallationUpgradeFacet: Invalid signature"
    );

    RealmDiamond realm = RealmDiamond(s.realmDiamond);
    realm.verifyAccessRight(queue.parcelId, _gotchiId, 6, LibMeta.msgSender());

    //handle underflow / overspend
    uint256 nextLevelId = s.installationTypes[queue.installationId].nextLevelId;
    require(_blocks <= s.installationTypes[nextLevelId].craftTime, "InstallationUpgradeFacet: Too much GLTR");

    //burn GLTR
    uint256 gltrAmount = uint256(_blocks) * 1e18;
    IERC20(s.gltr).transferFrom(LibMeta.msgSender(), 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, gltrAmount);

    //reduce the blocks
    queue.readyBlock -= _blocks;

    //if upgrade should be finalized, call finalizeUpgrade
    if (queue.readyBlock <= block.number) {
      LibInstallation.finalizeUpgrade(queue.owner, _upgradeIndex);
    }

    emit UpgradeTimeReduced(_upgradeIndex, queue.parcelId, queue.coordinateX, queue.coordinateY, _blocks);
  }

  /// @dev TO BE DEPRECATED
  /// @notice Query details about all ongoing upgrade queues
  /// @return output_ An array of structs, each representing an ongoing upgrade queue
  function getAllUpgradeQueue() external view returns (UpgradeQueue[] memory) {
    return s.upgradeQueue;
  }

  /// @dev TO BE REPLACED BY getUserUpgradeQueueNew after the old queue is cleared out
  /// @notice Query details about all pending craft queues
  /// @param _owner Address to query queue
  /// @return output_ An array of structs, each representing a pending craft queue
  /// @return indexes_ An array of IDs, to be used in the new finalizeUpgrades() function
  function getUserUpgradeQueue(address _owner) external view returns (UpgradeQueue[] memory output_, uint256[] memory indexes_) {
    RealmDiamond realm = RealmDiamond(s.realmDiamond);
    uint256[] memory tokenIds = realm.tokenIdsOfOwner(_owner);

    // Only return up to the first 500 upgrades.
    output_ = new UpgradeQueue[](500);
    indexes_ = new uint256[](500);

    uint256 counter;
    for (uint256 i; i < tokenIds.length; i++) {
      uint256[] memory parcelUpgradeIds = s.parcelIdToUpgradeIds[tokenIds[i]];
      for (uint256 j; j < parcelUpgradeIds.length; j++) {
        output_[counter] = s.upgradeQueue[parcelUpgradeIds[j]];
        indexes_[counter] = parcelUpgradeIds[j];
        counter++;
        if (counter >= 500) {
          break;
        }
      }
      if (counter >= 500) {
        break;
      }
    }
    assembly {
      mstore(output_, counter)
      mstore(indexes_, counter)
    }
  }

  /// @notice Query details about all pending craft queues
  /// @param _owner Address to query queue
  /// @return output_ An array of structs, each representing a pending craft queue
  /// @return indexes_ An array of IDs, to be used in the new finalizeUpgrades() function
  function getUserUpgradeQueueNew(address _owner) external view returns (UpgradeQueue[] memory output_, uint256[] memory indexes_) {
    RealmDiamond realm = RealmDiamond(s.realmDiamond);
    uint256[] memory tokenIds = realm.tokenIdsOfOwner(_owner);

    // Only return up to the first 500 upgrades.
    output_ = new UpgradeQueue[](500);
    indexes_ = new uint256[](500);

    uint256 counter;
    for (uint256 i; i < tokenIds.length; i++) {
      uint256[] memory parcelUpgradeIds = s.parcelIdToUpgradeIds[tokenIds[i]];
      for (uint256 j; j < parcelUpgradeIds.length; j++) {
        output_[counter] = s.upgradeQueue[parcelUpgradeIds[j]];
        indexes_[counter] = parcelUpgradeIds[j];
        counter++;
        if (counter >= 500) {
          break;
        }
      }
      if (counter >= 500) {
        break;
      }
    }
    assembly {
      mstore(output_, counter)
      mstore(indexes_, counter)
    }
  }

  function getUpgradeQueueId(uint256 _queueId) external view returns (UpgradeQueue memory) {
    return s.upgradeQueue[_queueId];
  }

  function getParcelUpgradeQueue(uint256 _parcelId) external view returns (UpgradeQueue[] memory output_, uint256[] memory indexes_) {
    indexes_ = s.parcelIdToUpgradeIds[_parcelId];
    output_ = new UpgradeQueue[](indexes_.length);
    for (uint256 i; i < indexes_.length; i++) {
      output_[i] = s.upgradeQueue[indexes_[i]];
    }
  }

  /// @notice For realm to validate whether a parcel has an upgrade queueing before removing an installation
  function parcelQueueEmpty(uint256 _parcelId) external view returns (bool) {
    return s.parcelIdToUpgradeIds[_parcelId].length == 0;
  }

  function parcelInstallationUpgrading(
    uint256 _parcelId,
    uint256 _installationId,
    uint256 _x,
    uint256 _y
  ) external view returns (bool) {
    uint256[] memory parcelQueue = s.parcelIdToUpgradeIds[_parcelId];

    for (uint256 i; i < parcelQueue.length; i++) {
      UpgradeQueue memory queue = s.upgradeQueue[parcelQueue[i]];

      if (queue.installationId == _installationId && queue.coordinateX == _x && queue.coordinateY == _y) {
        return true;
      }
    }
    return false;
  }

  function getUpgradeQueueLength() external view returns (uint256) {
    return s.upgradeQueue.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageInstallation, InstallationType, QueueItem, UpgradeQueue, Modifiers} from "../../libraries/AppStorageInstallation.sol";
import {LibERC1155} from "../../libraries/LibERC1155.sol";
import {RealmDiamond} from "../../interfaces/RealmDiamond.sol";
import {LibItems} from "../../libraries/LibItems.sol";
import {LibERC998, ItemTypeIO} from "../../libraries/LibERC998.sol";
import {LibInstallation} from "../../libraries/LibInstallation.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

contract InstallationFacet is Modifiers {
  event AddedToQueue(uint256 indexed _queueId, uint256 indexed _installationId, uint256 _readyBlock, address _sender);

  event QueueClaimed(uint256 indexed _queueId);

  event CraftTimeReduced(uint256 indexed _queueId, uint256 _blocksReduced);

  event UpgradeTimeReduced(uint256 indexed _queueId, uint256 indexed _realmId, uint256 _coordinateX, uint256 _coordinateY, uint256 _blocksReduced);

  /***********************************|
   |             Read Functions         |
   |__________________________________*/

  struct InstallationIdIO {
    uint256 installationId;
    uint256 balance;
  }

  struct ReservoirStats {
    uint256 spillRate;
    uint256 spillRadius;
    uint256 capacity;
  }

  /// @notice Returns balance for each installation that exists for an account
  /// @param _account Address of the account to query
  /// @return bals_ An array of structs, each struct containing details about each installation owned
  function installationsBalances(address _account) external view returns (InstallationIdIO[] memory bals_) {
    uint256 count = s.ownerInstallations[_account].length;
    bals_ = new InstallationIdIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 installationId = s.ownerInstallations[_account][i];
      bals_[i].balance = s.ownerInstallationBalances[_account][installationId];
      bals_[i].installationId = installationId;
    }
  }

  /// @notice Returns balance for each installation(and their types) that exists for an account
  /// @param _owner Address of the account to query
  /// @return output_ An array of structs containing details about each installation owned(including the installation types)
  function installationsBalancesWithTypes(address _owner) external view returns (ItemTypeIO[] memory output_) {
    uint256 count = s.ownerInstallations[_owner].length;
    output_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 installationId = s.ownerInstallations[_owner][i];
      output_[i].balance = s.ownerInstallationBalances[_owner][installationId];
      output_[i].itemId = installationId;
      output_[i].installationType = s.installationTypes[installationId];
    }
  }

  /// @notice Get the balance of a non-fungible parent token
  /// @param _tokenContract The contract tracking the parent token
  /// @param _tokenId The ID of the parent token
  /// @param _id     ID of the token
  /// @return value The balance of the token
  function balanceOfToken(
    address _tokenContract,
    uint256 _tokenId,
    uint256 _id
  ) public view returns (uint256 value) {
    value = s.nftInstallationBalances[_tokenContract][_tokenId][_id];
  }

  /// @notice Returns the balances for all ERC1155 items for a ERC721 token
  /// @param _tokenContract Contract address for the token to query
  /// @param _tokenId Identifier of the token to query
  /// @return bals_ An array of structs containing details about each item owned
  function installationBalancesOfToken(address _tokenContract, uint256 _tokenId) public view returns (InstallationIdIO[] memory bals_) {
    uint256 count = s.nftInstallations[_tokenContract][_tokenId].length;
    bals_ = new InstallationIdIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 installationId = s.nftInstallations[_tokenContract][_tokenId][i];
      bals_[i].installationId = installationId;
      bals_[i].balance = s.nftInstallationBalances[_tokenContract][_tokenId][installationId];
    }
  }

  /// @notice Returns the balances for all ERC1155 items for a ERC721 token
  /// @param _tokenContract Contract address for the token to query
  /// @param _tokenId Identifier of the token to query
  /// @return installationBalancesOfTokenWithTypes_ An array of structs containing details about each installation owned(including installation types)
  function installationBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    external
    view
    returns (ItemTypeIO[] memory installationBalancesOfTokenWithTypes_)
  {
    installationBalancesOfTokenWithTypes_ = LibERC998.itemBalancesOfTokenWithTypes(_tokenContract, _tokenId);
  }

  /// @notice Check the spillover radius of an installation type
  /// @param _id id of the installationType to query
  /// @return the spillover rate and radius the installation type with identifier _id
  function spilloverRateAndRadiusOfId(uint256 _id) external view returns (uint256, uint256) {
    return (s.installationTypes[_id].spillRate, s.installationTypes[_id].spillRadius);
  }

  /// @notice Query the installation balances of an ERC721 parent token
  /// @param _tokenContract The token contract of the ERC721 parent token
  /// @param _tokenId The identifier of the ERC721 parent token
  /// @param _ids An array containing the ids of the installationTypes to query
  /// @return An array containing the corresponding balances of the installation types queried
  function installationBalancesOfTokenByIds(
    address _tokenContract,
    uint256 _tokenId,
    uint256[] calldata _ids
  ) external view returns (uint256[] memory) {
    uint256[] memory balances = new uint256[](_ids.length);
    for (uint256 i = 0; i < _ids.length; i++) {
      balances[i] = balanceOfToken(_tokenContract, _tokenId, _ids[i]);
    }
    return balances;
  }

  /// @notice Query the item type of a particular installation
  /// @param _installationTypeId Item to query
  /// @return installationType A struct containing details about the item type of an item with identifier `_itemId`
  function getInstallationType(uint256 _installationTypeId) external view returns (InstallationType memory installationType) {
    require(_installationTypeId < s.installationTypes.length, "InstallationFacet: Item type doesn't exist");

    installationType = s.installationTypes[_installationTypeId];
    //If a deprecate time has been set, refer to that. Otherwise, use the manual deprecate.
    installationType.deprecated = s.deprecateTime[_installationTypeId] > 0
      ? block.timestamp > s.deprecateTime[_installationTypeId]
      : installationType.deprecated;
  }

  function getInstallationUnequipType(uint256 _installationId) external view returns (uint256) {
    require(_installationId < s.installationTypes.length, "InstallationFacet: Item type doesn't exist");
    return s.unequipTypes[_installationId];
  }

  /// @notice Query the item type of multiple installation types
  /// @param _installationTypeIds An array containing the identifiers of items to query
  /// @return installationTypes_ An array of structs,each struct containing details about the item type of the corresponding item
  function getInstallationTypes(uint256[] calldata _installationTypeIds) external view returns (InstallationType[] memory installationTypes_) {
    bool isAll = _installationTypeIds.length == 0;
    uint256 length = isAll ? s.installationTypes.length : _installationTypeIds.length;
    installationTypes_ = new InstallationType[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 id = isAll ? i : _installationTypeIds[i];
      installationTypes_[i] = s.installationTypes[id];
      installationTypes_[i].deprecated = s.deprecateTime[id] == 0 ? installationTypes_[i].deprecated : block.timestamp > s.deprecateTime[id];
    }
  }

  /// @notice Query details about all ongoing craft queues
  /// @param _owner Address to query queue
  /// @return output_ An array of structs, each representing an ongoing craft queue
  function getCraftQueue(address _owner) external view returns (QueueItem[] memory output_) {
    uint256 length = s.craftQueue.length;
    output_ = new QueueItem[](length);
    uint256 counter;
    for (uint256 i; i < length; i++) {
      if (s.craftQueue[i].owner == _owner) {
        output_[counter] = s.craftQueue[i];
        counter++;
      }
    }
    assembly {
      mstore(output_, counter)
    }
  }

  function getAltarLevel(uint256 _altarId) external view returns (uint256 altarLevel_) {
    require(_altarId < s.installationTypes.length, "InstallationFacet: Item type doesn't exist");
    require(s.installationTypes[_altarId].installationType == 0, "InstallationFacet: Not Altar");
    altarLevel_ = s.installationTypes[_altarId].level;
  }

  function getLodgeLevel(uint256 _installationId) external view returns (uint256 lodgeLevel_) {
    require(_installationId < s.installationTypes.length, "InstallationFacet: Item type doesn't exist");
    require(s.installationTypes[_installationId].installationType == 3, "InstallationFacet: Not Lodge");
    lodgeLevel_ = s.installationTypes[_installationId].level;
  }

  function getReservoirCapacity(uint256 _installationId) external view returns (uint256 capacity_) {
    require(_installationId < s.installationTypes.length, "InstallationFacet: Item type doesn't exist");
    require(s.installationTypes[_installationId].installationType == 2, "InstallationFacet: Not Reservoir");
    capacity_ = s.installationTypes[_installationId].capacity;
  }

  function getReservoirStats(uint256 _installationId) external view returns (ReservoirStats memory reservoirStats_) {
    require(_installationId < s.installationTypes.length, "InstallationFacet: Item type doesn't exist");
    require(s.installationTypes[_installationId].installationType == 2, "InstallationFacet: Not Reservoir");
    reservoirStats_ = ReservoirStats(
      s.installationTypes[_installationId].spillRate,
      s.installationTypes[_installationId].spillRadius,
      s.installationTypes[_installationId].capacity
    );
  }

  /***********************************|
   |             Write Functions        |
   |__________________________________*/
  struct BatchCraftInstallationsInput {
    uint16 installationID;
    uint16 amount;
    uint40 gltr;
  }

  function _batchCraftInstallation(BatchCraftInstallationsInput calldata _batchCraftInstallationsInput) internal {
    uint16 installationID = _batchCraftInstallationsInput.installationID;
    uint16 amount = _batchCraftInstallationsInput.amount;
    require(amount > 0, "InstallationFacet: Craft amount cannot be zero");
    // uint40 gltr = _batchCraftInstallationsInput.gltr;

    address[4] memory alchemicaAddresses = RealmDiamond(s.realmDiamond).getAlchemicaAddresses();
    uint256[4] memory alchemicaCost;
    // uint256 _nextCraftId = s.nextCraftId;
    //make sure installation exists
    require(installationID < s.installationTypes.length, "InstallationFacet: Installation does not exist");

    InstallationType memory installationType = s.installationTypes[installationID];
    require(installationType.level == 1, "InstallationFacet: can only craft level 1");
    //The preset deprecation time has elapsed
    if (s.deprecateTime[installationID] > 0) {
      require(block.timestamp < s.deprecateTime[installationID], "InstallationFacet: Installation has been deprecated");
    }
    require(!installationType.deprecated, "InstallationFacet: Installation has been deprecated");

    //get required alchemica
    alchemicaCost[0] = installationType.alchemicaCost[0] * amount;
    alchemicaCost[1] = installationType.alchemicaCost[1] * amount;
    alchemicaCost[2] = installationType.alchemicaCost[2] * amount;
    alchemicaCost[3] = installationType.alchemicaCost[3] * amount;
    //distribute alchemica
    LibItems._splitAlchemica(alchemicaCost, alchemicaAddresses);

    //only use for installations that are crafted immediately
    if (installationType.craftTime == 0) {
      LibERC1155._safeMint(msg.sender, installationID, amount, false, 0);
    }

    //@todo: add back GLTR and queueing
    //  else {
    //   //installations crafted after some time
    //   //for each installation , push to queue after applying individual gltr subtractions
    //   for (uint256 i = 0; i < amount; i++) {
    //     if (gltr > installationType.craftTime) revert("InstallationFacet: Too much GLTR");
    //     if (installationType.craftTime - gltr == 0) {
    //       LibERC1155._safeMint(msg.sender, installationID, 1, false, 0);
    //     } else {
    //       uint40 readyBlock = uint40(block.number) + installationType.craftTime;
    //       //put the installation into a queue
    //       //each wearable needs a unique queue id
    //       s.craftQueue.push(QueueItem(msg.sender, installationID, false, readyBlock, _nextCraftId));
    //       emit AddedToQueue(_nextCraftId, installationID, readyBlock, msg.sender);
    //       s.nextCraftId++;
    //     }
    //   }
  }

  function batchCraftInstallations(BatchCraftInstallationsInput[] calldata _inputs) external {
    for (uint256 i = 0; i < _inputs.length; i++) {
      _batchCraftInstallation(_inputs[i]);
    }
  }

  /// @notice Allow a user to craft installations
  /// @dev Will throw even if one of the installationTypes is deprecated
  /// @dev Puts the installation into a queue
  /// @param _installationTypes An array containing the identifiers of the installationTypes to craft
  /// @param _gltr Array of GLTR to spend on each crafting
  function craftInstallations(uint16[] calldata _installationTypes, uint40[] calldata _gltr) external {
    require(_installationTypes.length == _gltr.length, "InstallationFacet: Mismatched arrays");
    address[4] memory alchemicaAddresses = RealmDiamond(s.realmDiamond).getAlchemicaAddresses();

    uint256 _installationTypesLength = s.installationTypes.length;
    uint256 _nextCraftId = s.nextCraftId;
    for (uint256 i = 0; i < _installationTypes.length; i++) {
      uint256 installationId = _installationTypes[i];
      require(installationId < _installationTypesLength, "InstallationFacet: Installation does not exist");

      InstallationType memory installationType = s.installationTypes[installationId];
      //level check
      require(installationType.level == 1, "InstallationFacet: can only craft level 1");
      //The preset deprecation time has elapsed
      if (s.deprecateTime[installationId] > 0) {
        require(block.timestamp < s.deprecateTime[installationId], "InstallationFacet: Installation has been deprecated");
      }
      require(!installationType.deprecated, "InstallationFacet: Installation has been deprecated");

      //take the required alchemica
      LibItems._splitAlchemica(installationType.alchemicaCost, alchemicaAddresses);

      uint40 gltr = _gltr[i];

      if (gltr > installationType.craftTime) revert("InstallationFacet: Too much GLTR");

      if (installationType.craftTime - gltr == 0) {
        //doesn't require queue
        LibERC1155._safeMint(msg.sender, installationId, 1, false, 0);
      } else {
        uint40 readyBlock = uint40(block.number) + installationType.craftTime;

        //put the installation into a queue
        //each wearable needs a unique queue id
        s.craftQueue.push(QueueItem(msg.sender, uint16(installationId), false, readyBlock, _nextCraftId));

        emit AddedToQueue(_nextCraftId, installationId, readyBlock, msg.sender);
        _nextCraftId++;
      }
    }
    s.nextCraftId = _nextCraftId;
    //after queue is over, user can claim installation
  }

  /// @notice Allow a user to claim installations from ready queues
  /// @dev Will throw if the caller is not the queue owner
  /// @dev Will throw if one of the queues is not ready
  /// @param _queueIds An array containing the identifiers of queues to claim
  function claimInstallations(uint256[] calldata _queueIds) external {
    for (uint256 i; i < _queueIds.length; i++) {
      uint256 queueId = _queueIds[i];

      QueueItem memory queueItem = s.craftQueue[queueId];

      require(msg.sender == queueItem.owner, "InstallationFacet: Not owner");
      require(!queueItem.claimed, "InstallationFacet: already claimed");

      require(block.number >= queueItem.readyBlock, "InstallationFacet: Installation not ready");

      // mint installation from queue
      LibERC1155._safeMint(msg.sender, queueItem.installationType, 1, true, queueItem.id);
      s.craftQueue[queueId].claimed = true;
      emit QueueClaimed(queueId);
    }

    // InstallationAdminFacet(address(this)).finalizeUpgrade();
  }

  /// @notice Allow a user to speed up multiple queues(installation craft time) by paying the correct amount of $GLTR tokens
  /// @dev Will throw if the caller is not the queue owner
  /// @dev $GLTR tokens are burnt upon usage
  /// @dev amount expressed in block numbers
  /// @param _queueIds An array containing the identifiers of queues to speed up
  /// @param _amounts An array containing the corresponding amounts of $GLTR tokens to pay for each queue speedup
  function reduceCraftTime(uint256[] calldata _queueIds, uint40[] calldata _amounts) external {
    require(_queueIds.length == _amounts.length, "InstallationFacet: Mismatched arrays");
    for (uint256 i; i < _queueIds.length; i++) {
      uint256 queueId = _queueIds[i];
      QueueItem storage queueItem = s.craftQueue[queueId];
      require(msg.sender == queueItem.owner, "InstallationFacet: Not owner");

      require(block.number <= queueItem.readyBlock, "InstallationFacet: installation already done");

      IERC20 gltr = IERC20(s.gltr);

      uint40 blockLeft = queueItem.readyBlock - uint40(block.number);
      uint40 removeBlocks = _amounts[i] <= blockLeft ? _amounts[i] : blockLeft;
      uint256 burnAmount = uint256(removeBlocks) * 10**18;
      gltr.burnFrom(msg.sender, burnAmount);
      queueItem.readyBlock -= removeBlocks;
      emit CraftTimeReduced(queueId, removeBlocks);
    }
  }

  /// @notice Allow a user to equip an installation to a parcel
  /// @dev Will throw if the caller is not the parcel diamond contract
  /// @dev Will also throw if various prerequisites for the installation are not met
  /// @param _owner Owner of the installation to equip
  /// @param _realmId The identifier of the parcel to equip the installation to
  /// @param _installationId Identifier of the installation to equip
  function equipInstallation(
    address _owner,
    uint256 _realmId,
    uint256 _installationId
  ) external onlyRealmDiamond {
    LibInstallation._equipInstallation(_owner, _realmId, _installationId);
  }

  /// @notice Allow a user to unequip an installation from a parcel
  /// @dev Will throw if the caller is not the parcel diamond contract
  /// @param _realmId The identifier of the parcel to unequip the installation from
  /// @param _installationId Identifier of the installation to unequip
  function unequipInstallation(
    address _owner,
    uint256 _realmId,
    uint256 _installationId
  ) external onlyRealmDiamond {
    LibInstallation._unequipInstallation(_owner, _realmId, _installationId);
  }

  function upgradeComplete(uint256 _queueId) external view returns (bool) {
    return s.upgradeComplete[_queueId];
  }

  // /// @notice Allow a user to reduce the upgrade time of an ongoing queue
  // /// @dev Will throw if the caller is not the owner of the queue
  // /// @param _queueId The identifier of the queue whose upgrade time is to be reduced
  // /// @param _amount The number of $GLTR token to be paid, in blocks
  // function reduceUserUpgradeTime(
  //   address _owner,
  //   uint256 _queueId,
  //   uint40 _amount
  // ) external {
  //   UserUpgradeQueue storage upgradeQueue = s.userUpgradeQueue[_owner][_queueId];
  //   require(msg.sender == _owner, "InstallationFacet: Not owner");

  //   require(block.number <= upgradeQueue.readyBlock, "InstallationFacet: Upgrade already done");

  //   IERC20 gltr = IERC20(s.gltr);

  //   uint40 blockLeft = upgradeQueue.readyBlock - uint40(block.number);
  //   uint40 removeBlocks = _amount <= blockLeft ? _amount : blockLeft;
  //   gltr.burnFrom(msg.sender, removeBlocks * 10**18);
  //   upgradeQueue.readyBlock -= removeBlocks;
  //   emit UpgradeTimeReduced(_queueId, upgradeQueue.parcelId, upgradeQueue.coordinateX, upgradeQueue.coordinateY, removeBlocks);

  // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../libraries/AppStorageInstallation.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibStrings.sol";
import "../../libraries/LibMeta.sol";
import "../../libraries/LibERC1155.sol";
import "../../interfaces/IERC1155Marketplace.sol";

contract ERC1155Facet is Modifiers {
  function isApprovedForAll(address account, address operator) public view returns (bool operators_) {
    operators_ = s.operators[account][operator];
  }

  /**
  @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _value,
    bytes calldata _data
  ) external {
    require(_to != address(0), "ERC1155Facet: Can't transfer to 0 address");
    address sender = LibMeta.msgSender();
    require(sender == _from || s.operators[_from][sender] || sender == address(this), "ERC1155Facet: Not owner and not approved to transfer");
    LibERC1155.removeFromOwner(_from, _id, _value);
    LibERC1155.addToOwner(_to, _id, _value);
    IERC1155Marketplace(s.aavegotchiDiamond).updateERC1155Listing(address(this), _id, _from);
    emit LibERC1155.TransferSingle(sender, _from, _to, _id, _value);
    LibERC1155.onERC1155Received(sender, _from, _to, _id, _value, _data);
  }

  /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes calldata _data
  ) external {
    require(_to != address(0), "ItemsTransfer: Can't transfer to 0 address");
    require(_ids.length == _values.length, "ItemsTransfer: ids not same length as values");
    address sender = LibMeta.msgSender();
    require(sender == _from || s.operators[_from][sender], "ItemsTransfer: Not owner and not approved to transfer");
    for (uint256 i; i < _ids.length; i++) {
      uint256 id = _ids[i];
      uint256 value = _values[i];
      LibERC1155.removeFromOwner(_from, id, value);
      LibERC1155.addToOwner(_to, id, value);
      IERC1155Marketplace(s.aavegotchiDiamond).updateERC1155Listing(address(this), id, _from);
    }
    emit LibERC1155.TransferBatch(sender, _from, _to, _ids, _values);
    LibERC1155.onERC1155BatchReceived(sender, _from, _to, _ids, _values, _data);
  }

  function setApprovalForAll(address _operator, bool _approved) external {
    address sender = LibMeta.msgSender();
    require(sender != _operator, "ERC1155Facet: setting approval status for self");
    s.operators[sender][_operator] = _approved;
    emit LibERC1155.ApprovalForAll(sender, _operator, _approved);
  }

  /// @notice Get the URI for a voucher type
  /// @return URI for token type
  function uri(uint256 _id) external view returns (string memory) {
    require(_id < s.installationTypes.length, "InstallationFacet: Item _id not found");
    return LibStrings.strWithUint(s.baseUri, _id);
  }

  /**
        @notice Set the base url for all voucher types
        @param _value The new base url        
    */
  function setBaseURI(string memory _value) external onlyOwner {
    s.baseUri = _value;
    uint256 _installationTypesLength = s.installationTypes.length;
    for (uint256 i; i < _installationTypesLength; i++) {
      emit LibERC1155.URI(LibStrings.strWithUint(_value, i), i);
    }
  }

  /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return bal_    The _owner's balance of the token type requested
     */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_) {
    bal_ = s.ownerInstallationBalances[_owner][_id];
  }

  /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return bals   The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory bals) {
    require(_owners.length == _ids.length, "InstallationFacet: _owners length not same as _ids length");
    bals = new uint256[](_owners.length);
    for (uint256 i; i < _owners.length; i++) {
      uint256 id = _ids[i];
      address owner = _owners[i];
      bals[i] = s.ownerInstallationBalances[owner][id];
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../libraries/AppStorage.sol";

contract NFTDisplayFacet is Modifiers {
  event NFTDisplayStatusUpdated(address _token, uint256 _chainId, bool _allowed);
  error LengthMisMatch();

  function toggleNftDisplayAllowed(
    address[] calldata _tokens,
    uint256[] calldata _chainIds,
    bool[] calldata _allow
  ) external onlyOwner {
    if (_tokens.length != _chainIds.length && _tokens.length != _allow.length) revert LengthMisMatch();
    for (uint256 i; i < _tokens.length; i++) {
      address token = _tokens[i];
      uint256 chainId = _chainIds[i];
      bool whitelist = _allow[i];

      s.nftDisplayAllowed[chainId][token] = whitelist;
      emit NFTDisplayStatusUpdated(token, chainId, whitelist);
    }
  }

  function nftDisplayAllowed(address _token, uint256 _chainId) public view returns (bool) {
    return s.nftDisplayAllowed[_chainId][_token];
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../libraries/AppStorage.sol";
import "../../libraries/LibBounceGate.sol";

contract BounceGateFacet is Modifiers {
  function createEvent(
    string calldata _title,
    uint64 _startTime,
    uint64 _durationInMinutes,
    uint256[4] calldata _alchemicaSpent,
    uint256 _realmId
  ) external {
    LibBounceGate._createEvent(_title, _startTime, _durationInMinutes, _alchemicaSpent, _realmId);
  }

  function updateEvent(
    uint256 _realmId,
    uint256[4] calldata _alchemicaSpent,
    uint40 _durationExtensionInMinutes
  ) external {
    LibBounceGate._updateEvent(_realmId, _alchemicaSpent, _durationExtensionInMinutes);
  }

  function cancelEvent(uint256 _realmId) external {
    LibBounceGate._cancelEvent(_realmId);
  }

  function viewEvent(uint256 _realmId) public view returns (BounceGate memory b_) {
    BounceGate memory p = s.parcels[_realmId].bounceGate;
    b_.title = p.title;
    b_.startTime = p.startTime;
    b_.endTime = p.endTime;
    b_.priority = LibBounceGate._getUpdatedPriority(_realmId);
    b_.equipped = p.equipped;
    b_.lastTimeUpdated = p.lastTimeUpdated;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
error NotParcelOwner();
error StartTimeError();
error OngoingEvent();
error NoOngoingEvent();
error DurationTooHigh();
error NoBounceGate();
error NoEvent();
error EventEnded();
error TitleLengthOverflow();

uint256 constant GLTR_PER_MINUTE = 30;

// uint256 constant MAX_DURATION_IN_MINUTES = 4320 minutes; //72 hours

library LibBounceGate {
  event EventStarted(uint256 indexed _eventId, BounceGate eventDetails);
  event EventCancelled(uint256 indexed _eventId);
  event EventPriorityAndDurationUpdated(uint256 indexed _eventId, uint120 _newPriority, uint64 _newEndTime);

  function _createEvent(
    string calldata _title,
    uint64 _startTime,
    uint64 _durationInMinutes,
    uint256[4] calldata _alchemicaSpent,
    uint256 _realmId
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    address owner = s.parcels[_realmId].owner;

    //@todo: replace with Access Rights

    //@todo: uncomment for mainnet
    // if (msg.sender != owner) revert NotParcelOwner();
    //validate title length
    if (bytes(_title).length > 35) revert TitleLengthOverflow();

    //REMOVED FOR TESTING ON MUMBAI
    //   if (!s.parcels[_realmId].bounceGate.equipped) revert NoBounceGate();
    //make sure there is no ongoing event
    if (s.parcels[_realmId].bounceGate.endTime > block.timestamp) revert OngoingEvent();
    //validate event
    uint64 endTime = _validateInitialBounceGate(_startTime, _durationInMinutes);
    //calculate event priority
    uint120 priority = _calculatePriorityAndSettleAlchemica(_alchemicaSpent);
    //update storage
    BounceGate storage p = s.parcels[_realmId].bounceGate;
    p.title = _title;
    p.startTime = _startTime;
    p.endTime = endTime;
    p.priority = priority;
    p.lastTimeUpdated = _startTime;
    emit EventStarted(_realmId, p);
  }

  function _updateEvent(
    uint256 _realmId,
    uint256[4] calldata _alchemicaSpent,
    uint40 _durationExtensionInMinutes
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    BounceGate storage p = s.parcels[_realmId].bounceGate;
    address parcelOwner = s.parcels[_realmId].owner;

    //@todo: replace with access rights
    if (msg.sender != parcelOwner) revert NotParcelOwner();
    if (p.startTime == 0) revert NoEvent();

    //@todo: check
    // if (p.endTime < block.timestamp) revert EventEnded();
    if (_durationExtensionInMinutes > 0) {
      // uint256 currentDurationInMinutes = p.endTime - p.startTime;
      // if (currentDurationInMinutes + _durationExtensionInMinutes > MAX_DURATION_IN_MINUTES) revert DurationTooHigh();
      uint256 gltr = _getGltrAmount(_durationExtensionInMinutes);
      //REMOVED FOR TESTING ON MUMBAI

      //@todo: uncomment for mainnet
      //  require(IERC20(s.gltrAddress).transferFrom(msg.sender, address(this), gltr));
      //update storage
      p.endTime += (_durationExtensionInMinutes * 60);
    }
    uint256 addedPriority = _calculatePriorityAndSettleAlchemica(_alchemicaSpent);
    //update storage
    uint120 newPriority = _getUpdatedPriority(_realmId) + uint120(addedPriority);
    p.priority = newPriority;
    //only update if event has started
    if (p.startTime < block.timestamp) p.lastTimeUpdated = uint64(block.timestamp);
    emit EventPriorityAndDurationUpdated(_realmId, newPriority, p.endTime);
  }

  function _cancelEvent(uint256 _realmId) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    BounceGate storage p = s.parcels[_realmId].bounceGate;
    address parcelOwner = s.parcels[_realmId].owner;
    if (msg.sender != parcelOwner) revert NotParcelOwner();
    if (p.endTime <= uint64(block.timestamp)) revert NoOngoingEvent();

    //Cancel event
    //p.startTime = uint64(block.timestamp);
    p.endTime = uint64(block.timestamp);

    emit EventCancelled(_realmId);
  }

  function _getUpdatedPriority(uint256 _realmId) internal view returns (uint120 _newPriority) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    BounceGate storage p = s.parcels[_realmId].bounceGate;

    if (p.startTime <= block.timestamp) {
      //@todo: check
      // if (p.endTime <= uint64(block.timestamp)) {
      //   _newPriority = 0;
      // } else {
      uint256 elapsedMinutesSinceLastUpdated = ((uint64(block.timestamp) - p.lastTimeUpdated)) / 60;

      uint120 currentPriority = p.priority;

      if (elapsedMinutesSinceLastUpdated <= 1) {
        _newPriority = currentPriority;
      } else {
        //reduces by 0.01% of current priority every minute
        uint256 negPriority = (currentPriority) * elapsedMinutesSinceLastUpdated;
        negPriority /= 1000;
        if (currentPriority > negPriority) {
          _newPriority = uint120((currentPriority * 10) - negPriority);
          _newPriority /= 10;
        } else {
          _newPriority = 0;
        }
        // }
      }
    } else {
      _newPriority = p.priority;
    }
  }

  function _validateInitialBounceGate(uint64 _startTime, uint256 _durationInMinutes) private view returns (uint64 endTime_) {
    if (_startTime < block.timestamp) revert StartTimeError();
    //check for Duration
    // if (_durationInMinutes > MAX_DURATION_IN_MINUTES) revert DurationTooHigh();
    AppStorage storage s = LibAppStorage.diamondStorage();
    //calculate gltr needed for duration
    uint256 total = _getGltrAmount(_durationInMinutes);
    //REMOVED FOR TESTING ON MUMBAI

    //@todo: uncomment for prod
    // require(IERC20(s.gltrAddress).transferFrom(msg.sender, address(this), total));
    endTime_ = uint64(_startTime + (_durationInMinutes * 60));
  }

  function _getGltrAmount(uint256 _durationInMinutes) private pure returns (uint256 gltr_) {
    gltr_ = GLTR_PER_MINUTE * _durationInMinutes * 1e18;
  }

  function _calculatePriorityAndSettleAlchemica(uint256[4] calldata _alchemicaSpent) internal returns (uint120 _startingPriority) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    for (uint256 i = 0; i < 4; i++) {
      uint256 amount = _alchemicaSpent[i];
      //each amount must be greater than or equal to 1
      if (amount >= 1e18) {
        amount /= 1e18;
        _startingPriority += uint120(amount * _getAlchemicaRankings()[i]);
        require(IERC20(s.alchemicaAddresses[i]).transferFrom(msg.sender, address(this), amount));
      }
    }
    _startingPriority *= 1000;
  }

  function _getAlchemicaRankings() private pure returns (uint256[4] memory rankings_) {
    rankings_ = [uint256(1), 2, 4, 10];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorageTile, TileType, QueueItem, Modifiers} from "../../../libraries/AppStorageTile.sol";
import {LibERC1155Tile} from "../../../libraries/LibERC1155Tile.sol";

contract TestTileFacet is Modifiers {
  // Craft tiles without deprecation, alchemica cost, craft time
  function testCraftTiles(uint16[] calldata _tileTypes) external {
    for (uint256 i = 0; i < _tileTypes.length; i++) {
      LibERC1155Tile._safeMint(msg.sender, _tileTypes[i], 1, 0);
    }
  }
}