//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../coordinators/LocationCoordinator/ILocationCoordinator.sol';
import '../../coordinators/StarbaseCoordinator/IStarbaseCoordinator.sol';
import '../MissionBudgets/IMissionBudget.sol';
import '../../coordinators/MissionCoordinator/IMissionCoordinator.sol';
import './AirdroppedLocationMission.sol';

//TODO this contract doesn't do anything unique; it needs to be able to handle items or be different somehow than a travel mission

contract TransportMission is AirdroppedLocationMission {
  mapping(uint256 => string) public botItems;
  string[] private items;

  constructor(
    ILocationCoordinator _locationCoordinator,
    IStarbaseCoordinator _starbaseCoordinator,
    IMissionBudget _budget,
    IMissionBudget _erc721Reward,
    IMissionCoordinator _missionCoordinator,
    IPxlbot _pxlbot
  )
    AirdroppedLocationMission(
      _locationCoordinator,
      _starbaseCoordinator,
      _budget,
      _erc721Reward,
      _missionCoordinator,
      _pxlbot
    )
  {
    factors.push('distance');
    weights['distance'] = 1;
  }

  function updateAvailableItems(string[] memory _items)
    external
    onlyController
  {
    items = _items;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../../utils/SpaceMath.sol';
import '../../../utils/Controllable.sol';
import '../../../utils/Payable.sol';

interface ILocationCoordinator {
  function origin() external view returns (string memory);

  function locationOfBot(uint256 botId) external view returns (string memory);

  function botsAtLocation(string memory location)
    external
    view
    returns (uint256[] memory);

  function gridSize() external view returns (uint8);

  // These should only be callable by a controller contract
  function moveBotToCoordinates(
    uint256 botId,
    uint8 x,
    uint8 y,
    uint8 z
  ) external;

  function moveBotToLocation(uint256 botId, string memory destination) external;

  function hasBotVisited(uint256 botId, string memory location)
    external
    view
    returns (bool);

  function logBotVisit(uint256 botId, string memory location) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../InventoryCoordinator/IInventoryEntityContract.sol';

interface IStarbaseCoordinator is IInventoryEntityContract {
  struct Starbase {
    bool init;
    string name;
    uint256 namePrice;
    uint256[] nameBuyers;
    uint256 numBuyers;
    string location;
  }

  function PRICE_MULTIPLIER() external returns(uint256);

  function BASE_STARBASE_NAME_PRICE() external returns(uint256);

  function getStarbase(string memory location) external returns(Starbase memory);

  function initializeStarbaseIfNeeded(string memory location) external;

  function renameStarbase(uint256 botId, string memory name) external;

  function starbaseId(string memory location) external pure returns(uint32 id);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../models/Missions.sol';

interface IMissionBudget is MissionTypesUser {
  function getReward(
    uint256 botId,
    uint256 missionId,
    uint256 score,
    uint256 totalPossible,
    uint256 bounty,
    int16 loot_index
  ) external returns (Reward memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../missions/IMission.sol';
import '../../models/Missions.sol';

interface IMissionCoordinator is MissionTypesUser {
  function missionStarted(uint256 botId, uint256 missionId) external;

  function missionCompleted(
    uint256 botId,
    Result memory result,
    Reward memory reward
  ) external;

  function missionCanceled(uint256 botId, Result memory result) external;

  function botMissions(uint256 botId) external returns (uint256);

  function isBotOnMission(uint256 botId) external returns (bool);

  function airdroppedMissions()
    external
    view
    returns (AirdropMissionData[] memory);

  function getAirdroppedMission(uint256 mission_id)
    external
    view
    returns (AirdropMissionData memory);

  function addAirdroppedMission(
    string memory origin,
    string memory destination,
    uint8 reward,
    string memory metadata,
    int16 loot_index
  ) external;

  function addAirdroppedMissions(
    string[] memory origins,
    string[] memory destinations,
    uint8[] memory rewards,
    string[] memory metadata,
    int16[] memory loot_indices
  ) external;

  function availableMissionsAtStarbase(string memory location)
    external
    view
    returns (uint256[] memory);

  function startAirdroppedMission(uint256 botId, uint256 missionId)
    external
    returns (AirdropMissionData memory);

  function getAirdropMissionDistance(uint256 botId)
    external
    view
    returns (uint256, uint256);

  function getBotCurrentAirdropMission(uint256 botId)
    external
    view
    returns (AirdropMissionData memory);

  function calculateMinimumAirdropMissionDuration(uint256 botId)
    external
    view
    returns (uint80);

  function completeAirdroppedMission(uint256 botId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../coordinators/LocationCoordinator/ILocationCoordinator.sol';
import '../../coordinators/StarbaseCoordinator/IStarbaseCoordinator.sol';
import '../MissionBudgets/IMissionBudget.sol';
import '../../coordinators/MissionCoordinator/IMissionCoordinator.sol';
import '../BaseStakingMission.sol';
import '../BotAttributeWeighted.sol';

abstract contract AirdroppedLocationMission is
  BaseStakingMission,
  BotAttributeWeighted
{
  ILocationCoordinator locationCoordinator;
  IStarbaseCoordinator starbaseCoordinator;
  IMissionBudget pxl_budget;
  IMissionBudget lootCoordinator;

  constructor(
    ILocationCoordinator _locationCoordinator,
    IStarbaseCoordinator _starbaseCoordinator,
    IMissionBudget _pxl_budget,
    IMissionBudget _loot_coordinator,
    IMissionCoordinator _missionCoordinator,
    IPxlbot _pxlbot
  )
    BaseStakingMission(_missionCoordinator, _pxlbot)
    BotAttributeWeighted(_pxlbot)
  {
    locationCoordinator = _locationCoordinator;
    starbaseCoordinator = _starbaseCoordinator;
    pxl_budget = _pxl_budget;
    lootCoordinator = _loot_coordinator;
  }

  function startMission(uint256 botId, uint256 missionId)
    public
    onlyBotOwner(botId)
    returns (uint80 eta)
  {
    AirdropMissionData memory mission = missionCoordinator
      .startAirdroppedMission(botId, missionId);
    starbaseCoordinator.initializeStarbaseIfNeeded(mission.destination);
    _start(botId);
    return missionETA(botId);
  }

  function missionHasEnded(uint256 botId) internal override {
    missionCoordinator.completeAirdroppedMission(botId);
  }

  function calculateReward(uint256 botId)
    internal
    virtual
    override
    returns (Reward memory)
  {
    (uint256 score, uint256 totalPossible) = getWeightedScore(botId);
    AirdropMissionData memory mission = missionCoordinator
      .getBotCurrentAirdropMission(botId);
    uint256 bounty = mission.reward;
    int16 loot_index = mission.loot_index;
    Reward memory reward = pxl_budget.getReward(
      botId,
      missionId,
      score,
      totalPossible,
      bounty,
      loot_index
    );

    return reward;
  }

  function getFactorValue(uint256 botId, string memory _factor)
    internal
    view
    override
    returns (uint256 _value, uint256 _totalPossible)
  {
    if (SpaceMath.compareStrings(_factor, 'distance')) {
      return missionCoordinator.getAirdropMissionDistance(botId);
    }
    if (SpaceMath.compareStrings(_factor, 'bounty')) {
      AirdropMissionData memory mission = missionCoordinator
        .getBotCurrentAirdropMission(botId);
      return (mission.reward, mission.reward);
    } else {
      revert('StarbaseDiscovery: Unknown weighted score factor');
    }
  }

  function areMissionRequirementsComplete(uint256 botId)
    public
    view
    override
    returns (bool)
  {
    return block.timestamp - activeMissions[botId] >= minDuration[botId];
  }

  function calculateMinimumDuration(uint256 botId)
    public
    view
    override
    returns (uint80)
  {
    return missionCoordinator.calculateMinimumAirdropMissionDuration(botId);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './Strings.sol';

library SpaceMath {
  using strings for *;

  // easier for calculating mission length
  uint256 constant coeff_time = 3456; //*100
  uint256 constant min_travel_time = 1;

  // easier for calculating PXL
  // based on total available starbases, min yield, max coin supply
  // *10000
  uint256 constant coefficient_supply = 38024;
  uint256 constant tens_round = 100000;

  uint256 constant origin_x = 0;
  uint256 constant origin_y = 0;
  uint256 constant origin_z = 0;

  function pxlAvailableAtLocation(
    uint8 x,
    uint8 y,
    uint8 z
  ) public pure returns (uint256) {
    //get distance from origin/center of map
    uint256 d2 = distance2(origin_x, origin_y, origin_z, x, y, z);

    uint256 coin = 1 + ((d2 * coefficient_supply) / tens_round);
    return coin;
  }

  function coordsToString(
    uint8 x,
    uint8 y,
    uint8 z
  ) public pure returns (string memory) {
    return
      append3(
        append2(stringTo3Digit(uint2str(x)), '|'),
        append2(stringTo3Digit(uint2str(y)), '|'),
        stringTo3Digit(uint2str(z))
      );
  }

  function stringToCoords(string memory location)
    public
    pure
    returns (uint8[3] memory)
  {
    string[] memory parts = stringToArray(location);
    uint8[3] memory vals;
    vals[0] = uint8(parseInt(parts[0]));
    vals[1] = uint8(parseInt(parts[1]));
    vals[2] = uint8(parseInt(parts[2]));
    return vals;
  }

  function stringToArray(string memory myStr)
    public
    pure
    returns (string[] memory)
  {
    strings.slice memory slice = myStr.toSlice();
    strings.slice memory d = '|'.toSlice();
    string[] memory parts = new string[](slice.count(d) + 1);
    for (uint256 i = 0; i < parts.length; i++) {
      parts[i] = slice.split(d).toString();
    }
    return parts;
  }

  function stringTo3Digit(string memory str)
    public
    pure
    returns (string memory)
  {
    strings.slice memory strS = str.toSlice();
    uint8 numZeroesToAdd = 0;
    uint256 len = strS.len();
    string memory returnStr;
    if (len == 1) {
      numZeroesToAdd = 2;
    } else if (len == 2) {
      numZeroesToAdd = 1;
    }
    if (numZeroesToAdd > 0) {
      strings.slice memory zeroes = '0'.toSlice();
      numZeroesToAdd--;
      while (numZeroesToAdd > 0) {
        zeroes = zeroes.concat('0'.toSlice()).toSlice();
        numZeroesToAdd--;
      }
      returnStr = zeroes.concat(strS);
    } else {
      returnStr = strS.toString();
    }
    return returnStr;
  }

  function ensureMatch(uint256 num, string memory str)
    public
    pure
    returns (bool)
  {
    strings.slice memory coord1slice = uint2str(num).toSlice();
    string memory coord1 = coord1slice.toString();
    uint8 numZeroesToAdd = 0;
    uint256 c1len = coord1slice.len();
    if (c1len == 1) {
      numZeroesToAdd = 2;
    } else if (c1len == 2) {
      numZeroesToAdd = 1;
    }
    if (numZeroesToAdd > 0) {
      strings.slice memory zeroes = '0'.toSlice();
      numZeroesToAdd--;
      while (numZeroesToAdd > 0) {
        zeroes = zeroes.concat('0'.toSlice()).toSlice();
        numZeroesToAdd--;
      }
      coord1 = zeroes.concat(coord1slice);
    } else {
      coord1 = coord1slice.toString();
    }
    return compareStrings(coord1, str);
  }

  function parseInt(string memory _a) public pure returns (uint256 _parsedInt) {
    return parseInt(_a, 0);
  }

  function parseInt(string memory _a, uint256 _b)
    public
    pure
    returns (uint256 _parsedInt)
  {
    bytes memory bresult = bytes(_a);
    uint256 mint = 0;
    bool decimals = false;
    for (uint256 i = 0; i < bresult.length; i++) {
      if (
        (uint256(uint8(bresult[i])) >= 48) && (uint256(uint8(bresult[i])) <= 57)
      ) {
        if (decimals) {
          if (_b == 0) {
            break;
          } else {
            _b--;
          }
        }
        mint *= 10;
        mint += uint256(uint8(bresult[i])) - 48;
      } else if (uint256(uint8(bresult[i])) == 46) {
        decimals = true;
      }
    }
    if (_b > 0) {
      mint *= 10**_b;
    }
    return mint;
  }

  function append2(string memory a, string memory b)
    public
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(a, b));
  }

  function append3(
    string memory a,
    string memory b,
    string memory c
  ) public pure returns (string memory) {
    return string(abi.encodePacked(a, b, c));
  }

  function compareStrings(string memory a, string memory b)
    public
    pure
    returns (bool)
  {
    return (keccak256(abi.encodePacked((a))) ==
      keccak256(abi.encodePacked((b))));
  }

  function uint2str(uint256 _i)
    public
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function minSq(int256 a, int256 b) public pure returns (int256 c) {
    return (a - b) * (a - b);
  }

  function sq(int256 a) public pure returns (int256 b) {
    return a * a;
  }

  function sqrt(int256 y) public pure returns (int256 z) {
    if (y > 3) {
      z = y;
      int256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  // distance^2 between two 3d coordinates
  function distance2(
    uint256 ox,
    uint256 oy,
    uint256 oz,
    uint256 x,
    uint256 y,
    uint256 z
  ) public pure returns (uint256 d) {
    return
      uint256(
        minSq(int256(ox), int256(x)) +
          minSq(int256(oy), int256(y)) +
          minSq(int256(oz), int256(z))
      );
  }

  function pxlDistance(
    uint8[3] memory a,
    uint8[3] memory b
  ) public pure returns (uint256 d) {
    return uint256(abs(int(int8(a[0]) - int8(b[0]))) + abs(int(int8(a[1]) - int8(b[1]))) + abs(int(int8(a[2]) - int8(b[2]))));
  }

  function abs(int x) private pure returns (int) {
    return x >= 0 ? x : -x;
  }

  function pxlDistance(
    string memory a,
    string memory b
  ) public pure returns (uint256 d) {
    uint8[3] memory aCoords = stringToCoords(a);
    uint8[3] memory bCoords = stringToCoords(b);
    return pxlDistance(aCoords, bCoords);
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) public view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
          )
        )
      );
  }

  function travelTime(string memory origin, string memory destination) public pure returns (uint80) {
    uint8[3] memory originCoords = stringToCoords(origin);
    uint8[3] memory destinationCoords = stringToCoords(destination);

    uint256 distance = pxlDistance(originCoords, destinationCoords);
    uint256 time = min_travel_time +
      (distance *
        coeff_time) / 100;
    return uint80(time);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Controllable is Ownable {
  mapping(address => bool) private _controllers;
  /**
   * @dev Initializes the contract setting the deployer as a controller.
   */
  constructor() {
    _addController(_msgSender());
  }

  modifier mutualControllersOnly(address _caller) {
    Controllable caller = Controllable(_caller);
    require(_controllers[_caller] && caller.isController(address(this)), 'Controllable: not mutual controllers');
    _;
  }

  /**
   * @dev Returns true if the address is a controller.
   */
  function isController(address controller) public view virtual returns (bool) {
    return _controllers[controller];
  }

  /**
   * @dev Throws if called by any account that isn't a controller
   */
  modifier onlyController() {
    require(_controllers[_msgSender()], "Controllable: not controller");
    _;
  }

  modifier nonZero(address a) {
    require(a != address(0), "Controllable: input is zero address");
    _;
  }

  /**
   * @dev Adds a new controller.
   * Can only be called by the current owner.
   */
  function addController(address c) public virtual onlyOwner nonZero(c) {
     _addController(c);
  }

  /**
   * @dev Adds a new controller.
   * Internal function without access restriction.
   */
  function _addController(address newController) internal virtual {
    _controllers[newController] = true;
  }

    /**
   * @dev Removes a controller.
   * Can only be called by the current owner.
   */
  function removeController(address c) public virtual onlyOwner nonZero(c) {
     _removeController(c);
  }
  
  /**
   * @dev Removes a controller.
   * Internal function without access restriction.
   */
  function _removeController(address controller) internal virtual {
    delete _controllers[controller];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract Payable is Ownable {
  /**
   * @dev Sends entire balance to contract owner.
   */
  function withdrawAll() external {
    payable(owner()).transfer(address(this).balance);
  }

    /**
   * @dev Sends entire balance of a given ERC20 token to contract owner.
   */
  function withdrawAllERC20(IERC20 _erc20Token) external virtual {
    _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
  }
}

//SPDX-License-Identifier: Apache
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 * retrieved from https://github.com/smartcontractkit/solidity-stringutils
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
  struct slice {
    uint256 _len;
    uint256 _ptr;
  }

  function memcpy(
    uint256 dest,
    uint256 src,
    uint256 ilen
  ) private pure {
    // Copy word-length chunks while possible
    for (; ilen >= 32; ilen -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint256 mask = type(uint256).max;
    if (ilen > 0) {
      mask = 256**(32 - ilen) - 1;
    }
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /*
   * @dev Returns a slice containing the entire string.
   * @param self The string to make a slice from.
   * @return A newly allocated slice containing the entire string.
   */
  function toSlice(string memory self) internal pure returns (slice memory) {
    uint256 ptr;
    assembly {
      ptr := add(self, 0x20)
    }
    return slice(bytes(self).length, ptr);
  }

  /*
   * @dev Returns the length of a null-terminated bytes32 string.
   * @param self The value to find the length of.
   * @return The length of the string, from 0 to 32.
   */
  function len(bytes32 self) internal pure returns (uint256) {
    uint256 ret;
    if (self == 0) return 0;
    if (uint256(self) & type(uint128).max == 0) {
      ret += 16;
      self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
    }
    if (uint256(self) & type(uint64).max == 0) {
      ret += 8;
      self = bytes32(uint256(self) / 0x10000000000000000);
    }
    if (uint256(self) & type(uint32).max == 0) {
      ret += 4;
      self = bytes32(uint256(self) / 0x100000000);
    }
    if (uint256(self) & type(uint16).max == 0) {
      ret += 2;
      self = bytes32(uint256(self) / 0x10000);
    }
    if (uint256(self) & type(uint8).max == 0) {
      ret += 1;
    }
    return 32 - ret;
  }

  /*
   * @dev Returns a slice containing the entire bytes32, interpreted as a
   *      null-terminated utf-8 string.
   * @param self The bytes32 value to convert to a slice.
   * @return A new slice containing the value of the input argument up to the
   *         first null.
   */
  function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
    // Allocate space for `self` in memory, copy it there, and point ret at it
    assembly {
      let ptr := mload(0x40)
      mstore(0x40, add(ptr, 0x20))
      mstore(ptr, self)
      mstore(add(ret, 0x20), ptr)
    }
    ret._len = len(self);
  }

  /*
   * @dev Returns a new slice containing the same data as the current slice.
   * @param self The slice to copy.
   * @return A new slice containing the same data as `self`.
   */
  function copy(slice memory self) internal pure returns (slice memory) {
    return slice(self._len, self._ptr);
  }

  /*
   * @dev Copies a slice to a new string.
   * @param self The slice to copy.
   * @return A newly allocated string containing the slice's text.
   */
  function toString(slice memory self) internal pure returns (string memory) {
    string memory ret = new string(self._len);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    memcpy(retptr, self._ptr, self._len);
    return ret;
  }

  /*
   * @dev Returns the length in runes of the slice. Note that this operation
   *      takes time proportional to the length of the slice; avoid using it
   *      in loops, and call `slice.empty()` if you only need to know whether
   *      the slice is empty or not.
   * @param self The slice to operate on.
   * @return The length of the slice in runes.
   */
  function len(slice memory self) internal pure returns (uint256 l) {
    // Starting at ptr-31 means the LSB will be the byte we care about
    uint256 ptr = self._ptr - 31;
    uint256 end = ptr + self._len;
    for (l = 0; ptr < end; l++) {
      uint8 b;
      assembly {
        b := and(mload(ptr), 0xFF)
      }
      if (b < 0x80) {
        ptr += 1;
      } else if (b < 0xE0) {
        ptr += 2;
      } else if (b < 0xF0) {
        ptr += 3;
      } else if (b < 0xF8) {
        ptr += 4;
      } else if (b < 0xFC) {
        ptr += 5;
      } else {
        ptr += 6;
      }
    }
  }

  /*
   * @dev Returns true if the slice is empty (has a length of 0).
   * @param self The slice to operate on.
   * @return True if the slice is empty, False otherwise.
   */
  function empty(slice memory self) internal pure returns (bool) {
    return self._len == 0;
  }

  /*
   * @dev Returns a positive number if `other` comes lexicographically after
   *      `self`, a negative number if it comes before, or zero if the
   *      contents of the two slices are equal. Comparison is done per-rune,
   *      on unicode codepoints.
   * @param self The first slice to compare.
   * @param other The second slice to compare.
   * @return The result of the comparison.
   */
  function compare(slice memory self, slice memory other)
    internal
    pure
    returns (int256)
  {
    uint256 shortest = self._len;
    if (other._len < self._len) shortest = other._len;

    uint256 selfptr = self._ptr;
    uint256 otherptr = other._ptr;
    for (uint256 idx = 0; idx < shortest; idx += 32) {
      uint256 a;
      uint256 b;
      assembly {
        a := mload(selfptr)
        b := mload(otherptr)
      }
      if (a != b) {
        // Mask out irrelevant bytes and check again
        uint256 mask = type(uint256).max; // 0xffff...
        if (shortest < 32) {
          mask = ~(2**(8 * (32 - shortest + idx)) - 1);
        }
        unchecked {
          uint256 diff = (a & mask) - (b & mask);
          if (diff != 0) return int256(diff);
        }
      }
      selfptr += 32;
      otherptr += 32;
    }
    return int256(self._len) - int256(other._len);
  }

  /*
   * @dev Returns true if the two slices contain the same text.
   * @param self The first slice to compare.
   * @param self The second slice to compare.
   * @return True if the slices are equal, false otherwise.
   */
  function equals(slice memory self, slice memory other)
    internal
    pure
    returns (bool)
  {
    return compare(self, other) == 0;
  }

  /*
   * @dev Extracts the first rune in the slice into `rune`, advancing the
   *      slice to point to the next rune and returning `self`.
   * @param self The slice to operate on.
   * @param rune The slice that will contain the first rune.
   * @return `rune`.
   */
  function nextRune(slice memory self, slice memory rune)
    internal
    pure
    returns (slice memory)
  {
    rune._ptr = self._ptr;

    if (self._len == 0) {
      rune._len = 0;
      return rune;
    }

    uint256 l;
    uint256 b;
    // Load the first byte of the rune into the LSBs of b
    assembly {
      b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
    }
    if (b < 0x80) {
      l = 1;
    } else if (b < 0xE0) {
      l = 2;
    } else if (b < 0xF0) {
      l = 3;
    } else {
      l = 4;
    }

    // Check for truncated codepoints
    if (l > self._len) {
      rune._len = self._len;
      self._ptr += self._len;
      self._len = 0;
      return rune;
    }

    self._ptr += l;
    self._len -= l;
    rune._len = l;
    return rune;
  }

  /*
   * @dev Returns the first rune in the slice, advancing the slice to point
   *      to the next rune.
   * @param self The slice to operate on.
   * @return A slice containing only the first rune from `self`.
   */
  function nextRune(slice memory self)
    internal
    pure
    returns (slice memory ret)
  {
    nextRune(self, ret);
  }

  /*
   * @dev Returns the number of the first codepoint in the slice.
   * @param self The slice to operate on.
   * @return The number of the first codepoint in the slice.
   */
  function ord(slice memory self) internal pure returns (uint256 ret) {
    if (self._len == 0) {
      return 0;
    }

    uint256 word;
    uint256 length;
    uint256 divisor = 2**248;

    // Load the rune into the MSBs of b
    assembly {
      word := mload(mload(add(self, 32)))
    }
    uint256 b = word / divisor;
    if (b < 0x80) {
      ret = b;
      length = 1;
    } else if (b < 0xE0) {
      ret = b & 0x1F;
      length = 2;
    } else if (b < 0xF0) {
      ret = b & 0x0F;
      length = 3;
    } else {
      ret = b & 0x07;
      length = 4;
    }

    // Check for truncated codepoints
    if (length > self._len) {
      return 0;
    }

    for (uint256 i = 1; i < length; i++) {
      divisor = divisor / 256;
      b = (word / divisor) & 0xFF;
      if (b & 0xC0 != 0x80) {
        // Invalid UTF-8 sequence
        return 0;
      }
      ret = (ret * 64) | (b & 0x3F);
    }

    return ret;
  }

  /*
   * @dev Returns the keccak-256 hash of the slice.
   * @param self The slice to hash.
   * @return The hash of the slice.
   */
  function keccak(slice memory self) internal pure returns (bytes32 ret) {
    assembly {
      ret := keccak256(mload(add(self, 32)), mload(self))
    }
  }

  /*
   * @dev Returns true if `self` starts with `needle`.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return True if the slice starts with the provided text, false otherwise.
   */
  function startsWith(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
    if (self._len < needle._len) {
      return false;
    }

    if (self._ptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let selfptr := mload(add(self, 0x20))
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
    }
    return equal;
  }

  /*
   * @dev If `self` starts with `needle`, `needle` is removed from the
   *      beginning of `self`. Otherwise, `self` is unmodified.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return `self`
   */
  function beyond(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    if (self._len < needle._len) {
      return self;
    }

    bool equal = true;
    if (self._ptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let selfptr := mload(add(self, 0x20))
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
      }
    }

    if (equal) {
      self._len -= needle._len;
      self._ptr += needle._len;
    }

    return self;
  }

  /*
   * @dev Returns true if the slice ends with `needle`.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return True if the slice starts with the provided text, false otherwise.
   */
  function endsWith(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
    if (self._len < needle._len) {
      return false;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;

    if (selfptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
    }

    return equal;
  }

  /*
   * @dev If `self` ends with `needle`, `needle` is removed from the
   *      end of `self`. Otherwise, `self` is unmodified.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return `self`
   */
  function until(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    if (self._len < needle._len) {
      return self;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;
    bool equal = true;
    if (selfptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
      }
    }

    if (equal) {
      self._len -= needle._len;
    }

    return self;
  }

  // Returns the memory address of the first byte of the first occurrence of
  // `needle` in `self`, or the first byte after `self` if not found.
  function findPtr(
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr = selfptr;
    uint256 idx;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        uint256 end = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly {
          ptrdata := and(mload(ptr), mask)
        }

        while (ptrdata != needledata) {
          if (ptr >= end) return selfptr + selflen;
          ptr++;
          assembly {
            ptrdata := and(mload(ptr), mask)
          }
        }
        return ptr;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly {
          hash := keccak256(needleptr, needlelen)
        }

        for (idx = 0; idx <= selflen - needlelen; idx++) {
          bytes32 testHash;
          assembly {
            testHash := keccak256(ptr, needlelen)
          }
          if (hash == testHash) return ptr;
          ptr += 1;
        }
      }
    }
    return selfptr + selflen;
  }

  // Returns the memory address of the first byte after the last occurrence of
  // `needle` in `self`, or the address of `self` if not found.
  function rfindPtr(
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        ptr = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly {
          ptrdata := and(mload(ptr), mask)
        }

        while (ptrdata != needledata) {
          if (ptr <= selfptr) return selfptr;
          ptr--;
          assembly {
            ptrdata := and(mload(ptr), mask)
          }
        }
        return ptr + needlelen;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly {
          hash := keccak256(needleptr, needlelen)
        }
        ptr = selfptr + (selflen - needlelen);
        while (ptr >= selfptr) {
          bytes32 testHash;
          assembly {
            testHash := keccak256(ptr, needlelen)
          }
          if (hash == testHash) return ptr + needlelen;
          ptr -= 1;
        }
      }
    }
    return selfptr;
  }

  /*
   * @dev Modifies `self` to contain everything from the first occurrence of
   *      `needle` to the end of the slice. `self` is set to the empty slice
   *      if `needle` is not found.
   * @param self The slice to search and modify.
   * @param needle The text to search for.
   * @return `self`.
   */
  function find(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    self._len -= ptr - self._ptr;
    self._ptr = ptr;
    return self;
  }

  /*
   * @dev Modifies `self` to contain the part of the string from the start of
   *      `self` to the end of the first occurrence of `needle`. If `needle`
   *      is not found, `self` is set to the empty slice.
   * @param self The slice to search and modify.
   * @param needle The text to search for.
   * @return `self`.
   */
  function rfind(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
    self._len = ptr - self._ptr;
    return self;
  }

  /*
   * @dev Splits the slice, setting `self` to everything after the first
   *      occurrence of `needle`, and `token` to everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function split(
    slice memory self,
    slice memory needle,
    slice memory token
  ) internal pure returns (slice memory) {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = self._ptr;
    token._len = ptr - self._ptr;
    if (ptr == self._ptr + self._len) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
      self._ptr = ptr + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the slice, setting `self` to everything after the first
   *      occurrence of `needle`, and returning everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and the entirety of `self` is returned.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` up to the first occurrence of `delim`.
   */
  function split(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory token)
  {
    split(self, needle, token);
  }

  /*
   * @dev Splits the slice, setting `self` to everything before the last
   *      occurrence of `needle`, and `token` to everything after it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function rsplit(
    slice memory self,
    slice memory needle,
    slice memory token
  ) internal pure returns (slice memory) {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = ptr;
    token._len = self._len - (ptr - self._ptr);
    if (ptr == self._ptr) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the slice, setting `self` to everything before the last
   *      occurrence of `needle`, and returning everything after it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and the entirety of `self` is returned.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` after the last occurrence of `delim`.
   */
  function rsplit(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory token)
  {
    rsplit(self, needle, token);
  }

  /*
   * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
   * @param self The slice to search.
   * @param needle The text to search for in `self`.
   * @return The number of occurrences of `needle` found in `self`.
   */
  function count(slice memory self, slice memory needle)
    internal
    pure
    returns (uint256 cnt)
  {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
      needle._len;
    while (ptr <= self._ptr + self._len) {
      cnt++;
      ptr =
        findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) +
        needle._len;
    }
  }

  /*
   * @dev Returns True if `self` contains `needle`.
   * @param self The slice to search.
   * @param needle The text to search for in `self`.
   * @return True if `needle` is found in `self`, false otherwise.
   */
  function contains(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
    return
      rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
  }

  /*
   * @dev Returns a newly allocated string containing the concatenation of
   *      `self` and `other`.
   * @param self The first slice to concatenate.
   * @param other The second slice to concatenate.
   * @return The concatenation of the two strings.
   */
  function concat(slice memory self, slice memory other)
    internal
    pure
    returns (string memory)
  {
    string memory ret = new string(self._len + other._len);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }
    memcpy(retptr, self._ptr, self._len);
    memcpy(retptr + self._len, other._ptr, other._len);
    return ret;
  }

  /*
   * @dev Joins an array of slices, using `self` as a delimiter, returning a
   *      newly allocated string.
   * @param self The delimiter to use.
   * @param parts A list of slices to join.
   * @return A newly allocated string containing all the slices in `parts`,
   *         joined with `self`.
   */
  function join(slice memory self, slice[] memory parts)
    internal
    pure
    returns (string memory)
  {
    if (parts.length == 0) return '';

    uint256 length = self._len * (parts.length - 1);
    for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

    string memory ret = new string(length);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    for (uint256 i = 0; i < parts.length; i++) {
      memcpy(retptr, parts[i]._ptr, parts[i]._len);
      retptr += parts[i]._len;
      if (i < parts.length - 1) {
        memcpy(retptr, self._ptr, self._len);
        retptr += self._len;
      }
    }

    return ret;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//defines an "Entity" that can hold an item in inventory (e.g. a pxlbot; consisting of pxlbot contract address and a token ID)
interface IInventoryEntityContract {
  // Base id is determined by the contract. Examples might be tokenId in an ERC721 or simply putting 1 for ERC20
  function irlOwner(uint256 _baseId) external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './Inventory.sol';

interface MissionTypesUser is InventoryTypesUser {
  enum Status {
    COMPLETED,
    CANCELED
  }

  struct Result {
    uint256 missionId;
    uint80 start;
    uint80 end;
    Status status;
  }

  struct RewardHistoryItem {
    Item item;
    uint256 missionId;
  }

  struct Reward {
    Entity from;
    Entity to;
    Item[] items;
    uint256[] amounts;
    bool subject_to_tribute;
  }

  struct AirdropMissionData {
    uint256 _id;
    string origin;
    string destination;
    uint8 reward;
    int16 loot_index;
    string metadata;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../coordinators/InventoryCoordinator/IInventoryEntityContract.sol';
import '../coordinators/InventoryCoordinator/IInventoryItemContract.sol';

//Entity is a contract that can "hold" an inventory (doesn't actually hold it, it's represented in the InventoryCoordinator)
// In the case of PXL, it's the MissionPxlBudget contract. In the case of ERC721 rewards, it's the LootCoordinator.
//item is the thing that goes in the inventory (e.g. PXL or ERC721 token)
interface InventoryTypesUser {
  struct Entity {
    IInventoryEntityContract _contract;
    uint256 id;
  }

  struct Item {
    IInventoryItemContract _contract;
    uint256 id;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//defines contracts for "Items" that can be held in inventory (e.g. PXL, an ERC721 token, etc.)
interface IInventoryItemContract {
  // Base id is determined by the contract. Examples might be tokenId in an ERC721 or simply putting 1 for ERC20
  function irlBalance(uint256 baseId, address owner) external returns (uint256);

  function inventoryItemTransfer(
    uint256 baseId,
    uint256 amount,
    address from,
    address to
  ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../coordinators/InventoryCoordinator/IInventoryCoordinator.sol';

interface IMission {
  function missionId() external view returns (uint256);

  function isBotOnMission(uint256 botId) external view returns (bool);

  function missionStartTime(uint256 botId) external view returns (uint80);

  function areMissionRequirementsComplete(uint256 botId)
    external
    view
    returns (bool);

  function setMissionId(uint256 _missionId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './IInventoryEntityContract.sol';
import './IInventoryItemContract.sol';
import '../../models/Inventory.sol';

interface IInventoryCoordinator is InventoryTypesUser {
  function addItemToGame(
    Item memory game_item,
    Entity memory owner_entity,
    uint256 amount
  ) external;

  function removeItemFromGame(
    Item memory game_item,
    Entity memory owner_entity,
    uint256 amount
  ) external;

  function inGameTransfer(
    Entity memory _from,
    Entity memory _to,
    Item memory _item,
    uint256 _amount
  ) external;

  function balance(Entity memory _entity, Item memory item)
    external
    returns (uint256);

  function addApprovedItemType(IInventoryItemContract collection) external;

  function removeApprovedItemType(IInventoryItemContract collection) external;

  function addApprovedEntityType(IInventoryEntityContract entity) external;

  function removeApprovedEntityType(IInventoryEntityContract entity) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../utils/Payable.sol';
import '../../utils/Controllable.sol';
import '../coordinators/MissionCoordinator/IMissionCoordinator.sol';
import './IMission.sol';
import '../../tokens/IPxlbot.sol';

abstract contract BaseStakingMission is
  IMission,
  MissionTypesUser,
  Payable,
  Controllable
{
  IMissionCoordinator missionCoordinator;
  IPxlbot pxlbot;
  uint256 public override missionId;

  mapping(uint256 => uint80) internal activeMissions;
  mapping(uint256 => bool) internal completionOverride;
  mapping(uint256 => address) internal botOwners;
  mapping(uint256 => uint80) internal minDuration;

  constructor(IMissionCoordinator _missionCoordinator, IPxlbot _pxlbot) {
    missionCoordinator = _missionCoordinator;
    pxlbot = _pxlbot;
  }

  modifier onlyActiveBots(uint256 botId) {
    require(
      activeMissions[botId] != 0,
      'BaseStakingMission: bot not on mission'
    );
    _;
  }

  modifier onlyBotOwner(uint256 botId) {
    require(
      pxlbot.ownerOf(botId) == _msgSender() || botOwners[botId] == _msgSender(),
      'BaseStakingMission: not bot owner'
    );
    _;
  }

  modifier isControllerOrBotOwner(uint256 botId) {
    require(
      pxlbot.ownerOf(botId) == _msgSender() ||
        botOwners[botId] == _msgSender() ||
        isController(_msgSender()),
      'BaseStakingMission: not bot owner'
    );
    _;
  }

  function setMissionId(uint256 _missionId) external override onlyController {
    missionId = _missionId;
  }

  function startOverride(uint256 botId) public onlyController {
    _start(botId);
  }

  function _start(uint256 botId) internal virtual {
    activeMissions[botId] = uint80(block.timestamp);

    botOwners[botId] = _msgSender();

    missionCoordinator.missionStarted(botId, missionId);

    minDuration[botId] = calculateMinimumDuration(botId);
  }

  function endMission(uint256 botId)
    public
    virtual
    isControllerOrBotOwner(botId)
    onlyActiveBots(botId)
  {
    if (!completionOverride[botId]) {
      require(
        areMissionRequirementsComplete(botId),
        'BaseStakingMission: mission requirements not complete'
      );
    }

    _end(botId);
  }

  function _end(uint256 botId) internal virtual {
    uint80 start = activeMissions[botId];

    delete activeMissions[botId];
    delete completionOverride[botId];
    delete minDuration[botId];

    uint80 end = uint80(block.timestamp);

    Reward memory reward = calculateReward(botId);

    delete botOwners[botId];

    missionCoordinator.missionCompleted(
      botId,
      Result({
        missionId: missionId,
        start: start,
        end: end,
        status: Status.COMPLETED
      }),
      reward
    );
    missionHasEnded(botId);
  }

  function missionHasEnded(uint256 botId) internal virtual;

  function calculateReward(uint256 botId)
    internal
    virtual
    returns (Reward memory reward);

  function calculateMinimumDuration(uint256 botId)
    public
    virtual
    returns (uint80);

  function cancelMission(uint256 botId)
    public
    virtual
    isControllerOrBotOwner(botId)
    onlyActiveBots(botId)
  {
    _cancel(botId);
  }

  function _cancel(uint256 botId)
    internal
    virtual
    isControllerOrBotOwner(botId)
    onlyActiveBots(botId)
  {
    uint80 start = activeMissions[botId];
    uint80 end = uint80(block.timestamp);

    delete activeMissions[botId];
    delete completionOverride[botId];
    delete botOwners[botId];

    missionCoordinator.missionCanceled(
      botId,
      Result({
        missionId: missionId,
        start: start,
        end: end,
        status: Status.CANCELED
      })
    );
  }

  function isBotOnMission(uint256 botId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return activeMissions[botId] != 0;
  }

  function missionStartTime(uint256 botId)
    public
    view
    override
    onlyActiveBots(botId)
    returns (uint80)
  {
    return activeMissions[botId];
  }

  function missionETA(uint256 botId)
    public
    view
    onlyActiveBots(botId)
    returns (uint80)
  {
    return activeMissions[botId] + minDuration[botId];
  }

  // admin function for accelerating mission completion
  // lowers the length of the mission so when someone comes to complete it, it's done
  function completeMissionOverride(uint256 botId)
    external
    onlyController
    onlyActiveBots(botId)
  {
    completionOverride[botId] = true;
  }

  function areMissionRequirementsComplete(uint256 botId)
    public
    view
    virtual
    override
    returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../coordinators/AttributeCoordinator/IAttributeCoordinator.sol';
import './WeightedFactorScorable.sol';

abstract contract BotAttributeWeighted is WeightedFactorScorable {
  IAttributeCoordinator attributeCoordinator;
  string[] attrIds;
  mapping(string => uint256) attrWeights;
  uint256 public totalAttrWeight;

  constructor(IAttributeCoordinator _attributeCoordinator) {
    attributeCoordinator = _attributeCoordinator;
  }

  function getWeightedScore(uint256 botId)
    internal
    override
    returns (uint256 _score, uint256 _totalPossible)
  {
    (uint256 score, uint256 total) = super.getWeightedScore(botId);
    uint256 totalAttrPossible = attributeCoordinator.totalPossible();
    uint32[] memory attrValues = attributeCoordinator.attributeValues(
      botId,
      attrIds
    );

    for (uint256 i = 0; i < attrIds.length; i++) {
      string storage attrId = attrIds[i];
      uint256 attrValue = attrValues[i];
      uint256 attrWeight = attrWeights[attrId];
      uint256 normalizedAttrValue = (attrValue * totalPossible) /
        totalAttrPossible;
      score += normalizedAttrValue * attrWeight;
    }

    return (score, total + (totalPossible * totalAttrWeight));
  }

  function setAttributeWeights(
    string[] memory _attrIds,
    uint256[] memory _weights
  ) public onlyController {
    require(
      _attrIds.length == _weights.length,
      'MissionWeights: attribute ids and weights must be the same length'
    );

    for (uint256 i = 0; i < attrIds.length; i++) {
      delete attrWeights[attrIds[i]];
    }

    delete attrIds;
    delete totalAttrWeight;
    attrIds = _attrIds;

    for (uint256 i = 0; i < _attrIds.length; i++) {
      attrWeights[_attrIds[i]] = _weights[i];
      totalAttrWeight += _weights[i];
    }
  }

  function getFactorValue(uint256, string memory)
    internal
    virtual
    override
    returns (uint256, uint256)
  {
    revert('BotAttributeWeighted: getFactorValue not implemented');
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import 'erc721a/contracts/interfaces/IERC721AQueryable.sol';
import '../gameplay/coordinators/InventoryCoordinator/IInventoryEntityContract.sol';
import '../gameplay/coordinators/AttributeCoordinator/IAttributeCoordinator.sol';
import './IERC721APlayable.sol';

interface IPxlbot is
  IInventoryEntityContract,
  IAttributeCoordinator,
  IERC721AQueryable,
  IERC721APlayable
{
  function mint(uint256 amount, address to) external payable;

  function mintScion(
    address to,
    uint256 parent_id,
    string[] memory attrsIds,
    uint32[] memory attrsVals
  ) external payable;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../extensions/IERC721AQueryable.sol';

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAttributeCoordinator {
    function attributeValues(uint256 botId, string[] memory attrIds) external returns(uint32[] memory);
    function setAttributeValues(uint256 botId, string[] memory attrIds, uint32[] memory values) external;
    function totalPossible() external returns(uint32);
    function getAttrIds() external returns (string[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import 'erc721a/contracts/interfaces/IERC721AQueryable.sol';
import '../gameplay/coordinators/GameplayCoordinator/IGameplayCoordinator.sol';

interface IERC721APlayable is IERC721AQueryable {
    function addTokenToGameplay(uint256 id) external;
    function removeTokenFromGameplay(uint256 id) external;
    function isTokenInPlay(uint256 tokenId) external view returns(bool);
    function setGameplayCoordinator(IGameplayCoordinator c) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IGameplayCoordinator {
    function isBotBusy(uint256 id) external returns(bool);
    function makeBotBusy(uint256 botId) external;
    function makeBotUnbusy(uint256 botId) external;
    function isBotInGame(uint256 botId) external returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../utils/Controllable.sol';

abstract contract WeightedFactorScorable is Controllable {
  string[] factors;
  mapping(string => uint256) weights;
  uint256 totalPossible = 1000000000;

  function addFactor(string memory _factor, uint256 _weight)
    external
    onlyController
  {
    factors.push(_factor);
    weights[_factor] = _weight;
  }

  function updateFactorWeight(string memory _factor, uint256 _weight)
    external
    onlyController
  {
    weights[_factor] = _weight;
  }

  //this function takes each factor, adds its weight to a total, and gives a total score based on the weighted average of each score
  //for example, if you have two factors, each equal in weight (e.g. 1); each gets up to 50% of the total mission budget for this mission (see MissionPxlBudget)
  //when the two factors' scores are calculated, they are each given a weighted score based on 1) each of their score out of a total (e.g. 25% and 75%) and 2) their factor weights (e.g. 1, 1 or 1, 2)
  //in the end, each factor gets a % of the total budget (e.g. 100) based on that weighted score that really looks like a percentage
  //so, if you have two factors, each with a weight of 1, each will share _up to_ 50% of the total mission budget. if one scored 25% and the other scored 75%, then the first weighted score would be 12.5 (25% of 50; half of the budget) added to 37.5 (75% of 50; half of the budget) for a total of 50 points. this gets translated into PXL in MissionPxlBudget
  function getWeightedScore(uint256 botId)
    internal
    virtual
    returns (uint256 _score, uint256 _totalPossible)
  {
    uint256 totalWeight = 0;

    for (uint256 i = 0; i < factors.length; i++) {
      string storage factor = factors[i];
      (uint256 score, uint256 total) = getFactorValue(botId, factor);
      uint256 normalizedScore = (score * totalPossible) / total;
      _score += normalizedScore * weights[factor];
      totalWeight += weights[factor];
    }
    _totalPossible = totalPossible * totalWeight;
  }

  function getFactorValue(uint256 botId, string memory _factor)
    internal
    virtual
    returns (uint256 _value, uint256 _totalPossible);
}