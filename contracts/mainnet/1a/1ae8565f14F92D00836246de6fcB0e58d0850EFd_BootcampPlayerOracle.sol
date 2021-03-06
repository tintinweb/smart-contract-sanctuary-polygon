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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// @notice Oracle contract, providing information about MPL Characters
contract BootcampPlayerOracle is Ownable {

  using Strings for uint256;
  using BitMaps for BitMaps.BitMap;

  // @notice struct for Player metadata
  struct Player {
    uint16 playerType;
    uint16 skillLevel;
    uint16 quirks;
    bool pet;
  }

  // @notice Using the Alias method to generate deterministic distributions https://www.keithschwarz.com/darts-dice-coins/
  uint16[][18] public rarities;
  uint16[][18] public aliases;

  // @notice we will manually add pet data on-chain (this was a later addition)
  BitMaps.BitMap private _pets;

  constructor() {
    // Player types
    rarities[0] = [65535, 20000, 394];
    aliases[0] = [0, 0, 0];

    // Skill level
    rarities[1] = [65535, 58327, 21627, 61603, 45875, 18350, 4588];
    aliases[1] = [0, 3, 0, 0, 0, 1, 2 ];

    // Quirks
    rarities[2] = [ 65535, 9831, 32768, 32768, 49152, 32768, 16384, 16384, 16384, 8192, 1639, 1639, 1639, 1639, 1639, 1639, 1639, 1639, 1639, 1639, 1639, 1639, 1639, 1639, 1639 ];
    aliases[2] = [ 0, 0, 0, 0, 0, 1, 2, 3, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  }

  // @notice get the traits for a given character, based on a deterministic seed
  function getCharacterTraits(uint256 id) public view returns (Player memory p) {
    uint256 deterministicRandom = uint256(keccak256(abi.encodePacked("MPLGenesis", id.toString())));
    p = selectTraits(deterministicRandom);
    p.pet = _pets.get(id);
  }

  // @notice get an individual trait based on a seed
  function selectTrait(uint16 seed, uint16 traitType) internal view returns (uint16) {
    uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
    if (seed < rarities[traitType][trait]) return trait;
    return aliases[traitType][trait];
  }

  // @notice Get three traits based on the same seed
  function selectTraits(uint256 seed) internal view returns (Player memory p) {
    p.playerType = selectTrait(uint16(seed & 0xFFFF), 0);
    seed >>= 16;
    p.skillLevel = selectTrait(uint16(seed & 0xFFFF), 1);
    seed >>= 16;
    p.quirks = selectTrait(uint16(seed & 0xFFFF), 2);
  }

  // @notice owner only function to mark a player as having a pet
  function setPets(uint256[] calldata ids) public onlyOwner {
    for (uint256 i = 0; i < ids.length; i++) {
      _pets.set(ids[i]);
    }
  }

  // @notice owner only function to mark a player as not having a pet
  function unsetPets(uint256[] calldata ids) public onlyOwner {
    for (uint256 i = 0; i < ids.length; i++) {
      _pets.unset(ids[i]);
    }
  }

  function bulkSetPets(uint256[] calldata ids, uint256[] calldata values) public onlyOwner {
    for (uint256 i = 0; i < ids.length; i++) {
    BitMaps.BitMap storage pets = _pets;
    mapping(uint256 => uint256) storage petData = pets._data;
    uint256 k = ids[i];
    uint256 v = values[i];
    assembly {
        // Store num in memory scratch space
        mstore(0, k)
        // Store slot number in scratch space after num
        mstore(32, petData.slot)
        // Create hash from previously stored num and slot
        let hash := keccak256(0, 64)
        sstore(hash, v)
    }
    }
  }
}