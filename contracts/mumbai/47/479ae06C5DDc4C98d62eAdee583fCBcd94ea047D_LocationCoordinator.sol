//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '../../../utils/SpaceMath.sol';
import '../../../utils/Controllable.sol';
import '../../../utils/Payable.sol';
import './ILocationCoordinator.sol';

contract LocationCoordinator is ILocationCoordinator, Controllable, Payable {
  event BotMoved(uint256 botId, string oldLocation, string newLocation);

  // quick reference for bots' locations
  mapping(uint256 => string) internal bot_locations;
  mapping(string => uint256[]) internal location_bots;

  // keeping track of bots' visits
  mapping(uint256 => mapping(string => bool)) public bot_discovers;

  uint8 public override gridSize = 10;

  uint256[] private assignedBots;

  string public override origin;
  uint8[3] public originCoordinates;

  constructor() Controllable() {
    origin = '050|050|050';
    originCoordinates = [50, 50, 50];
  }

  modifier validCoords(
    uint8 x,
    uint8 y,
    uint8 z
  ) {
    validateCoords(x, y, z);
    _;
  }

  modifier validLocation(string memory location) {
    validateLocation(location);
    _;
  }

  function locationOfBot(uint256 botId)
    public
    view
    override
    returns (string memory _location)
  {
    string memory location = bot_locations[botId];

    if (SpaceMath.compareStrings('', location)) {
      return origin;
    }

    return location;
  }

  function botsAtLocation(string memory location)
    public
    view
    override
    returns (uint256[] memory)
  {
    return location_bots[location];
  }

  function validateLocation(string memory location) internal view {
    uint8[3] memory vals = SpaceMath.stringToCoords(location);
    validateCoords(vals[0], vals[1], vals[2]);
  }

  function validateCoords(
    uint8 x,
    uint8 y,
    uint8 z
  ) internal view {
    //make sure location is in bounds
    require(
      x <= originCoordinates[0] + gridSize / 2 &&
        x >= originCoordinates[0] - gridSize / 2,
      'x value out of bounds'
    );
    require(
      y <= originCoordinates[1] + gridSize / 2 &&
        y >= originCoordinates[1] - gridSize / 2,
      'y value out of bounds'
    );
    require(
      z <= originCoordinates[2] + gridSize / 2 &&
        z >= originCoordinates[2] - gridSize / 2,
      'z value out of bounds'
    );
  }

  function moveBotToCoordinates(
    uint256 botId,
    uint8 x,
    uint8 y,
    uint8 z
  ) external override onlyController validCoords(x, y, z) {
    string memory destination = SpaceMath.coordsToString(x, y, z);
    moveBotToLocation(botId, destination);
  }

  function moveBotToLocation(uint256 botId, string memory destination)
    public
    override
    onlyController
    validLocation(destination)
  {
    string memory botOrigin = bot_locations[botId];

    require(
      !SpaceMath.compareStrings(botOrigin, destination),
      'LocationCoordinator: Bot is already in requested location'
    );

    if (SpaceMath.compareStrings('', botOrigin)) {
      //remove them from their starting point
      uint256[] storage bots = location_bots[botOrigin];
      for (uint256 i = 0; i < bots.length; i++) {
        if (bots[i] == botId) {
          delete bots[i];
        }
      }
    }

    //add them to their destination
    location_bots[destination].push(botId);
    bot_locations[botId] = destination;

    emit BotMoved(botId, botOrigin, destination);
  }

  function setGridSize(uint8 size) external onlyController {
    gridSize = size;
  }

  function setOrigin(string memory location)
    external
    onlyController
    validLocation(location)
  {
    origin = location;
    originCoordinates = SpaceMath.stringToCoords(location);
  }

  function hasBotVisited(uint256 botId, string memory location)
    external
    view
    override
    returns (bool)
  {
    return bot_discovers[botId][location];
  }

  function logBotVisit(uint256 botId, string memory location)
    external
    override
    onlyController
  {
    bot_discovers[botId][location] = true;
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