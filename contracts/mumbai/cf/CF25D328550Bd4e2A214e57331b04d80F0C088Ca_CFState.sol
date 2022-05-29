// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Base } from "../common/Base.sol";
import { ChampionFightingTypes, TournamentTypes } from "../types/Types.sol";
import { ICFState } from "../interfaces/ICFState.sol";

// champion fighting = CF
contract CFState is Base, ICFState {
  // variables
  uint64 public total;
  mapping(uint256 => ChampionFightingTypes.ChampionInfo) champions;

  /**Set */
  // reviewed
  // position = 0 => set total fought
  // verified
  function increaseRankingsCount(uint256 _championID, uint64 _serviceId, uint32 _position) external onlyRoler("increaseRankingsCount") {
    champions[_championID].rankings[_serviceId][_position] += 1;
  }

  // reviewed
  // set pending count
  // verified
  function increasePendingCount(uint256 _championID, uint64 _serviceID) external onlyRoler("increasePendingCount") {
    champions[_championID].pending[_serviceID] += 1;
  }

  // reviewed
  // verified
  function decreasePendingCount(uint256 _championID, uint64 _serviceID) external onlyRoler("decreasePendingCount") {
    if (champions[_championID].pending[_serviceID] > 0) {
      champions[_championID].pending[_serviceID] -= 1;
    }
  }

  // reviewed
  // set champion elo
  function setChampionElo(uint256 _championID, uint64 _elo) public onlyRoler("setChampionElo") {
    if (!champions[_championID].elo_inited) {
      champions[_championID].elo_inited = true;
      total += 1;
    }
    champions[_championID].elo = _elo;
  }

  // reviewed
  // multiple call
  // verified
  function setMultipleChampionsElo(uint256[] calldata _championIds, uint64[] calldata _elos) external onlyRoler("setMultipleChampionsElo") {
    require(_championIds.length == _elos.length, "Input mismatch");
    for (uint16 i = 0; i < _championIds.length; i++) {
      setChampionElo(_championIds[i], _elos[i]);
    }
  }

  /** View */
  // reviewed
  // position = 0 => get total fought
  // verified
  function getRankingsCount(uint256 _championId, uint64 _serviceId, uint32 _position) public view returns (uint64) {
    return champions[_championId].rankings[_serviceId][_position];
  }

  // reviewed
  // get total pending
  // verified
  function getTotalPending(uint256 _championID, uint64 _start, uint64 _end) public view returns (uint128 sum) {
    for (uint64 i = _start; i <= _end; i++) {
      sum += champions[_championID].pending[i];
    }
  }

  // reviewed
  // position = 0 => get total fought
  // verified
  function getTotalWinByPosition(uint256 _championID, uint64 _start, uint64 _end, uint32 _position) public view returns (uint128 sum) {
    for (uint64 i = _start; i <= _end; i++) {
      sum += champions[_championID].rankings[i][_position];
    }
  }

  // reviewed
  // get elo
  // verified
  function eloInited(uint256 _championID) public view returns (bool) {
    return champions[_championID].elo_inited;
  }

  // reviewed
  // verified
  function getChampionElo(uint256 _championID) public view returns (uint64) {
    if (!champions[_championID].elo_inited) {
      return 1800;
    }
    return champions[_championID].elo;
  }

  // verified
  function getTotal() public view returns (uint64) {
    return total;
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
pragma solidity ^0.8.13;

interface ICFState {
  // increase ranking count by position
  function increaseRankingsCount(
    uint256 _championID,
    uint64 _serviceID,
    uint32 _position
  ) external;

  function increasePendingCount(uint256 _championID, uint64 _serviceID) external;

  function decreasePendingCount(uint256 _championID, uint64 _serviceID) external;

  function setChampionElo(uint256 _championID, uint64 _elo) external;

  // get position count of champion in a service type
  function getRankingsCount(
    uint256 _championID,
    uint64 _serviceID,
    uint32 _position
  ) external view returns (uint64);

  // get total win by position
  function getTotalWinByPosition(
    uint256 _championID,
    uint64 _start,
    uint64 _end,
    uint32 _position
  ) external view returns (uint128 total);

  // get total pending
  function getTotalPending(uint256 _championID, uint64 _start, uint64 _end) external view returns (uint128 total);

  function eloInited(uint256 _championID) external view returns (bool);

  function getChampionElo(uint256 _championID) external view returns (uint64);
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