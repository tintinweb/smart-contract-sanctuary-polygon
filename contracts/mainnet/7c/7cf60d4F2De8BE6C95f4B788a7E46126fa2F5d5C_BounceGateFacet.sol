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

  function recreateEvent(
    uint256 _realmId,
    uint64 _startTime,
    uint64 _durationInMinutes,
    uint256[4] calldata _alchemicaSpent
  ) external {
    LibBounceGate._recreateEvent(_realmId, _startTime, _durationInMinutes, _alchemicaSpent);
  }

  function viewEvent(uint256 _realmId) public view returns (BounceGate memory b_) {
    BounceGate memory p = s.bounceGates[_realmId];
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
  // parcelId => action: 0 Alchemical Channeling, 1 Emptying Reservoirs => permission: 0 Owner only, 1 Owner + Borrowed Gotchis, 2 Any Gotchi
  mapping(uint256 => mapping(uint256 => uint256)) accessRights;
  // gotchiId => lastChanneledDay
  mapping(uint256 => uint256) lastChanneledDay;
  bool freezeBuilding;
  //NFT DISPLAY STORAGE
  //chainId => contractAddress => allowed
  mapping(uint256 => mapping(address => bool)) nftDisplayAllowed;
  mapping(uint256 => BounceGate) bounceGates;
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
pragma solidity 0.8.9;

import "./AppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
error NotParcelOwner();
error StartTimeError();
error OngoingEvent();
error NoOngoingEvent();
error NoBounceGate();
error NoEvent();
error EventEnded();
error TitleLengthOverflow();

uint256 constant GLTR_PER_MINUTE = 30; //roughly 2 seconds per GLTR

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

    if (msg.sender != owner) revert NotParcelOwner();
    //validate title length
    if (bytes(_title).length > 35) revert TitleLengthOverflow();

    if (!s.bounceGates[_realmId].equipped) revert NoBounceGate();
    //make sure there is no ongoing event
    if (s.bounceGates[_realmId].endTime > block.timestamp) revert OngoingEvent();
    //validate event
    uint64 endTime = _validateInitialBounceGate(_startTime, _durationInMinutes);
    //calculate event priority
    uint120 priority = _calculatePriorityAndSettleAlchemica(_alchemicaSpent);
    //update storage
    BounceGate storage p = s.bounceGates[_realmId];
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
    BounceGate storage p = s.bounceGates[_realmId];
    address parcelOwner = s.parcels[_realmId].owner;

    //@todo: replace with access rights
    if (msg.sender != parcelOwner) revert NotParcelOwner();
    if (p.startTime == 0) revert NoEvent();
    if (p.endTime < block.timestamp) revert EventEnded();

    if (_durationExtensionInMinutes > 0) {
      uint256 gltr = _getGltrAmount(_durationExtensionInMinutes);
      require(IERC20(s.gltrAddress).transferFrom(msg.sender, address(this), gltr));
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

  //basically used to create a clone of an ended event
  function _recreateEvent(
    uint256 _realmId,
    uint64 _startTime,
    uint64 _durationInMinutes,
    uint256[4] calldata _alchemicaSpent
  ) internal {
    //make sure there is no ongoing event
    AppStorage storage s = LibAppStorage.diamondStorage();
    //makes sure an event has been created before
    if (s.bounceGates[_realmId].startTime == 0) revert NoEvent();
    if (s.bounceGates[_realmId].endTime > block.timestamp) revert OngoingEvent();
    //validate
    uint64 endTime = _validateInitialBounceGate(_startTime, _durationInMinutes);
    uint120 priority = _calculatePriorityAndSettleAlchemica(_alchemicaSpent);
    //update storage
    BounceGate storage p = s.bounceGates[_realmId];
    p.startTime = _startTime;
    p.endTime = endTime;
    p.priority = priority;
    p.lastTimeUpdated = uint64(block.timestamp);
    emit EventStarted(_realmId, p);
  }

  function _cancelEvent(uint256 _realmId) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    BounceGate storage p = s.bounceGates[_realmId];
    address parcelOwner = s.parcels[_realmId].owner;
    if (msg.sender != parcelOwner) revert NotParcelOwner();
    if (p.endTime <= uint64(block.timestamp)) revert NoOngoingEvent();

    //Cancel event
    p.endTime = uint64(block.timestamp);

    emit EventCancelled(_realmId);
  }

  function _getUpdatedPriority(uint256 _realmId) internal view returns (uint120 _newPriority) {
    AppStorage storage s = LibAppStorage.diamondStorage();
    BounceGate storage p = s.bounceGates[_realmId];

    //If event has started, priority begins dropping
    if (p.startTime <= block.timestamp) {
      //If event has already ended, priority is 0
      if (p.endTime <= uint64(block.timestamp)) {
        _newPriority = 0;
      } else {
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
        }
      }
    } else {
      _newPriority = p.priority;
    }
  }

  function _validateInitialBounceGate(uint64 _startTime, uint256 _durationInMinutes) private returns (uint64 endTime_) {
    if (_startTime < block.timestamp) revert StartTimeError();
    AppStorage storage s = LibAppStorage.diamondStorage();
    //calculate gltr needed for duration
    uint256 total = _getGltrAmount(_durationInMinutes);

    require(IERC20(s.gltrAddress).transferFrom(msg.sender, address(this), total));
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
        require(IERC20(s.alchemicaAddresses[i]).transferFrom(msg.sender, address(this), _alchemicaSpent[i]));
      }
    }
    _startingPriority *= 1000;
  }

  function _getAlchemicaRankings() private pure returns (uint256[4] memory rankings_) {
    rankings_ = [uint256(1), 2, 4, 10];
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