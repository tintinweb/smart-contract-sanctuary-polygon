// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Base } from "../common/Base.sol";
import { TournamentTypes } from "../types/Types.sol";
import { ITournamentRoute } from "../interfaces/ITournamentRoute.sol";
import { ITournamentService } from "../interfaces/ITournamentService.sol";

contract TRVTournamentRoute is Base, ITournamentRoute {
  mapping(uint64 => address) public services;

  // reviewed
  // verified
  function bindService(uint64 _ID, address _service) external onlyRoler("bindService") {
    require(services[_ID] == address(0), "Already exists");
    require(_service != address(0), "Must set non-zero address");
    services[_ID] = _service;
  }

  // reviewed
  // verified
  function updateService(uint64 _ID, address _service) external onlyRoler("updateService") {
    require(services[_ID] != address(0), "Not exists");
    services[_ID] = _service;
  }

  // reviewed
  // join tournament
  // verified
  function joinTournament(
    uint64 _serviceID,
    bytes memory _signature,
    bytes memory _params
  ) external { // dont add roler here :D
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).joinTournament(_signature, _params);
  }

  // reviewed
  // create tournament
  // verified
  function createTournament(
    uint64 _serviceID,
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory _configs,
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external onlyRoler("createTournament") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).createTournament(_key, _configs, _restrictions);
  }

  // reviewed
  // update tournament
  // verified
  function updateTournamentConfigs(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory _configs
  ) external onlyRoler("updateTournamentConfigs") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).updateTournamentConfigs(_tournamentID, _configs);
  }

  // reviewed
  // verified
  function updateTournamentRestrictions(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _restrictions
  ) external onlyRoler("updateTournamentRestrictions") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).updateTournamentRestrictions(_tournamentID, _restrictions);
  }

  function updateTournamentTopUp(uint64 _serviceID, TournamentTypes.TopupDto[] memory _tournaments) external onlyRoler("updateTournamentTopUp") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).updateTournamentTopUp(_tournaments);
  }

  // reviewed
  // cancel tournament
  // verified
  function cancelTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    bytes memory _params
  ) external onlyRoler("cancelTournament") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).cancelTournament(_tournamentID, _params);
  }

  function eligibleJoinTournament(uint64 _serviceID, uint64 _tournamentID, uint256 _championID) public view returns (bool, string memory) {
    return ITournamentService(services[_serviceID]).eligibleJoinTournament(_tournamentID, _championID);
  }

  // reviewed
  // verified
  function completeTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory _data
  ) external onlyRoler("completeTournament") {
    require(services[_serviceID] != address(0), "Non-exists service");
    ITournamentService(services[_serviceID]).completeTournament(_tournamentID, _warriors, _championsElo, _data);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Base is Ownable {
  // variable
  address public accessControlProvider = 0xFf8434fDA67fb91BF315D3a78A1Af9f001495C88;

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
pragma solidity 0.8.13;
import { TournamentTypes } from "../types/Types.sol";

interface ITournamentRoute {
  // bind service processing tournament
  function bindService(uint64 _ID, address _service) external;

  // join tournament
  function joinTournament(
    uint64 _serviceID,
    bytes memory _signature,
    bytes memory _params
  ) external;

  // create tournament
  function createTournament(
    uint64 _serviceID,
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory configs,
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external;

  // update tournament
  function updateTournamentConfigs(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory configs
  ) external;

  function updateTournamentRestrictions(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _restrictions
  ) external;

  function updateTournamentTopUp(uint64 _serviceID, TournamentTypes.TopupDto[] memory _tournaments) external;

  // cancel tournament
  function cancelTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    bytes memory _params
  ) external;

  function eligibleJoinTournament(uint64 _serviceID, uint64 _tournamentID, uint256 _championID) external view returns (bool, string memory);

  function completeTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import { TournamentTypes } from "../types/Types.sol";

interface ITournamentService {
  // join tournament
  function joinTournament(bytes memory _signature, bytes memory _params) external;

  // create tournament
  function createTournament(string[] memory _key, TournamentTypes.TournamentConfigs[] memory configs, TournamentTypes.TournamentRestrictions[] memory _restrictions) external;

  // update tournament
  function updateTournamentConfigs(
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory _data
  ) external;

  function updateTournamentRestrictions(
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _data
  ) external;

  function updateTournamentTopUp(TournamentTypes.TopupDto[] memory _tournaments) external;

  // cancel tournament
  function cancelTournament(uint64 _tournamentID, bytes memory _params) external;

  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) external view returns (bool, string memory);

  function completeTournament(
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory
  ) external;
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