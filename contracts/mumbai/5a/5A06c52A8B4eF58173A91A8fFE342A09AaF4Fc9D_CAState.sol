// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Base } from "../common/Base.sol";
import { ChampionAttributeTypes, CommonTypes } from "../types/Types.sol";

// champion attributes = CA
contract CAState is Base {
  mapping (uint256 => ChampionAttributeTypes.Attributes) champions;
  // string[1] private BACKGROUNDS = ['Black'];
  // string[1] private BLOODLINES = ['Genesis'];
  // string[3] private GENOTYPES = ['R1', 'R2', 'R3'];
  // string[5] private CHARACTER_CLASSES = ['Druid', 'Wizard', 'Barbarian', 'Ranger', 'Paladin'];
  // string[7] private BREEDS = ['Undead', 'Orc', 'Half Dwarf', 'Origin', 'High Born', 'Nordic', 'Elf'];
  // string[47] private ARMOUR_COLORS = [
  //   'Snowfall', 'Meadowlight', 'Rune', 'Emerald', 'Stategreen', 'Forestdeep', 'Frost', 'Coldshade', 'Rainstorm', 'Thundercloud',
  //   'Gloombane', 'Splendid', 'Memorial', 'Winterkill', 'Winterstorm', 'Spectral', 'Thunderstorm', 'Charcoal', 'Chaos', 'Onyx',
  //   'Royal Black', 'Dark of Night', 'Royal White', 'Charlemagne', 'Ivory', 'White Quartz', 'Dynasty', 'Mercia', 'Benedictine', 'Bone',
  //   'Alpensun', 'Coronet', 'Candlelight', 'Duskglow', 'Ochrewash', 'Firefly', 'Polarwind', 'Pennyroyal', 'Mayhem', 'Greatwood',
  //   'Blood', 'Brimstone', 'Crime-of-Passion', 'Red-of-War', 'Ruby Red', 'Sovereign', 'Gloom'
  // ];
  // string[7] private HAIR_COLORS = ['None', 'Tan', 'Blonde', 'Black', 'Gray', 'Brown', 'Auburn'];
  // string[5] private HAIR_CLASSES = ['Druid', 'Wizard', 'Barbarian', 'Ranger', 'Paladin'];
  // string[8] private HAIR_STYLES = ['Braid', 'Short', 'Wartail', 'Mohawk', 'Long', 'Bald', 'Hightail', 'Sidepart'];
  // string[9] private WARPAINT_COLORS = ['None', 'Black', 'White', 'Blue', 'Yellow', 'Green', 'Silver', 'Red', 'Gold'];
  // string[11] private WARPAINT_STYLES = ['None', 'Scar', 'Ragnarok', 'Trident', 'Rogue', 'Vortex', 'Sceptre', 'Hex', 'Mimic', 'Sigil', 'Crest'];

  // reviewed
  // verified
  function setGeneralAttributes(
    uint256[] memory _tokenIds,
    ChampionAttributeTypes.GeneralAttributes[] memory _attributes
  ) external onlyRoler("setGeneralAttributes") {
    require(_tokenIds.length == _attributes.length, "Input mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      champions[_tokenIds[i]].general = _attributes[i];
    }
  }

  // reviewed
  // verified
  function setOtherAttributes(
    uint256[] memory _tokenIds,
    CommonTypes.Object[] memory _attributes
  ) external onlyRoler("setOtherAttributes") {
    require(_tokenIds.length == _attributes.length, "Input mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      champions[_tokenIds[i]].others[_attributes[i].key] = _attributes[i].value;
    }
  }

  // reviewed
  // verified
  function getCharacterClassByChampionId(uint256 _tokenId) public view returns (uint16) {
    return champions[_tokenId].general.character_class;
  }

  // reviewed
  // verified
  function getGeneralAttributesByChampionId(
    uint256 _tokenId
  ) public view returns (ChampionAttributeTypes.GeneralAttributes memory) {
    return champions[_tokenId].general;
  }

  // reviewed
  // verified
  function getOtherAttributeByChampionId(
    uint256 _tokenId,
    bytes memory _key
  ) public view returns (bytes memory) {
    return champions[_tokenId].others[_key];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Base is Ownable {
  // variable
  address public accessControlProvider = 0x0bF8b07D3A0C83C5DDe4e12143A4203897f55F90;

  //
  constructor() {}

  // verified
  modifier onlyRoler(string memory _methodInfo) {
    require(_msgSender() == owner() || IAccessControl(accessControlProvider).hasRole(_msgSender(), address(this), _methodInfo), "Caller does not have permission");
    _;
  }

  // verified
  function setAccessControlProvider(address _contract) external onlyRoler("setAccessControlProvider") {
    accessControlProvider = _contract;
  }
}

interface IAccessControl {
  function hasRole(
    address _account,
    address _contract,
    string memory _methodInfo
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library CommonTypes {
  struct Object {
    bytes key; // convert string to bytes ie: bytes("other_key")
    bytes value; // output of abi.encode(arg);
  }
}

// this is for tournaments (should not change)
library TournamentTypes {
  // status
  enum TournamentStatus {
    AVAILABLE,
    READY,
    COMPLETED,
    CANCELLED
  }

  struct TopupDto {
    uint64 tournament_id;
    uint256 top_up;
  }

  struct EloDto {
    uint256 champion_id;
    uint64 elo;
  }

  // id, owner, stance, position
  struct Warrior {
    address account;
    uint32 win_position;
    uint256 ID;
    uint16 stance;
    bytes data; // <- for dynamic data
  }

  struct TournamentConfigs {
    address creator;
    uint32 size;
    address currency; // address of currency that support
    TournamentStatus status;
    uint16 fee_percentage; // * fee_percentage and div for 10000
    uint256 start_at;
    uint256 buy_in;
    uint256 top_up;
    bytes data;
  }

  struct TournamentRestrictions {
    //
    uint64 elo_min;
    uint64 elo_max;

    //
    uint16 win_rate_percent_min;
    uint16 win_rate_percent_max;
    uint16 win_rate_base_divider;

    //
    uint256[] whitelist;
    uint256[] blacklist;

    //
    uint16[] character_classes;

    bytes data; // <= for dynamic data
  }

  // tournament information
  struct TournamentInfo {
    bool inited;
    TournamentConfigs configs;
    TournamentRestrictions restrictions; 
    Warrior[] warriors;
  }
}

// champion class <- tournamnet type 
library ChampionFightingTypes {
  struct ChampionInfo {
    bool elo_inited;
    uint64 elo;
    mapping(uint64 => uint64) pending;
    mapping(uint64 => mapping(uint32 => uint64)) rankings; // description: count rankings, how many 1st, 2nd, 3rd, 4th, 5th, .... map with index of mapping.
    mapping(bytes => bytes) others; // put type here 
  }
}

// CA contract related
library ChampionAttributeTypes {
  struct GeneralAttributes {
    string name;
    uint16 background;
    uint16 bloodline;
    uint16 genotype;
    uint16 character_class;
    uint16 breed;
    uint16 armor_color; // US Spelling
    uint16 hair_color; // US Spelling
    uint16 hair_class;
    uint16 hair_style;
    uint16 warpaint_color;
    uint16 warpaint_style;
  }

  struct Attributes {
    GeneralAttributes general;
    mapping(bytes => bytes) others;
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