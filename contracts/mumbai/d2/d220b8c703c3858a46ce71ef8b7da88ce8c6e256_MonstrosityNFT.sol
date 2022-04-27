// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./shared/MonstrosityBase.sol";

contract MonstrosityNFT is MonstrosityBase {
  mapping(address => bytes4[]) private _modules;

  function addModule(address contractAddress, bytes4[] calldata methods) external onlyOwner {
    // cannot add new contract after mint has started!
    require(_gameData.startTime == 0);

    uint256 i;

    while (i < methods.length) {
      _ds[methods[i]] = contractAddress;
      i += 1;
    }

    _modules[contractAddress] = methods;
  }

  function removeModule(address module) external onlyOwner {
    // cannot remove contract after mint has started!
    require(_gameData.startTime == 0);

    bytes4[] memory methods = _modules[module];

    for (uint256 i; i < methods.length; i++) {
      delete _ds[methods[i]];
    }

    delete _modules[module];
  }

  // Find module for function that is called and execute the
  // function if a module is found and return any value.
  fallback() external payable {
    // get module from function selector
    address module = _ds[msg.sig];
    require(module != address(0), "ERR_FUNC_NOT_FOUND");
    // Execute external function from module using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the module
      let result := delegatecall(gas(), module, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
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

pragma solidity ^0.8.10;

import "../shared/MonstrosityGameStructs.sol";
import "../shared/ERC721DataStruct.sol";

abstract contract MonstrosityBase {
  address internal _owner;
  address internal _withdrawalAddress;
  uint256 internal _status;
  ERC721Data internal _nftData;
  GameData internal _gameData;
  mapping(bytes4 => address) internal _ds;

  // @todo SET THIS BEFORE DEPLOYMENT!!!!!!!!!!
  uint256 internal constant MINT_PRICE = 0.01 ether;
  uint256 internal constant MINT_PRICE_DISCOUNT = 75;
  uint256 internal constant MINT_PERCENT_PRIZE = 60;
  uint256 internal constant TRAIT_POINT_PRICE = 0.0025 ether;
  uint96 internal constant _NOT_ENTERED = 1;
  uint96 internal constant _ENTERED = 2;
  uint64 internal constant MAP_SIZE = 120;

  constructor() {
    _status = _NOT_ENTERED;
    _owner = msg.sender;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "ERR_NOT_OWNER");
    _;
  }

  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ERR_REEANTRANCY");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

enum GameStage {
  Preparation,
  Recruitment,
  InitialCampaign,
  Recovery,
  FinalCampaign,
  Princess
}

struct Monster {
  uint256 id;
  uint256 location;
  uint64[4] traits; // 0: armor, 1: speed, 2: stamina, 3: agility
  uint64 totalTraits;
  uint64 potions;
  uint64 hp;
  uint64 inBattle;
}

struct BattleInfo {
  uint128 timestamp;
  uint128 location;
  uint64 id;
  uint64 area;
  uint32[4] opponentTraits;
}

struct Pools {
  uint256 prize;
  uint256 fees;
  uint256 dev;
}

struct GameData {
  uint256 startTime;
  /// @dev current campaign (0: initial, 1: final)
  uint64 campaign;
  /// @dev number of monsters ever entered to the game (not supply!)
  uint64 totalMonsters;
  /// @dev the total amount of trait points from all monsters
  uint128 traitPoints;
  /// @dev the count of the monsters IN the game (!= supply()!!!), one for each campaign
  uint128[2] monsterCount;
  uint128[2] killedMonsters;
  /// @dev save attributes for each monster (tokenId => monsterData)
  mapping(uint256 => Monster) monsters;
  /// @dev monster to location mapping (locationId => tokenId)
  mapping(uint256 => uint256) monsterLocations;
  /// @dev random location allocation cache
  mapping(uint256 => uint256) monsterLocationCache;
  mapping(uint256 => uint256) winners;
  /// @dev stores the list of monsters in the current battle
  uint128[] monstersInBattle;
  /// @dev current battle information
  BattleInfo currentBattle;
  Pools pools;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ERC721Data {
  uint256 supply;
  // URI prefix
  string baseUri;
  // Mapping from token ID to owner address
  mapping(uint256 => address) owners;
  // Mapping owner address to token count
  mapping(address => uint256) balances;
  // Mapping from token ID to approved address
  mapping(uint256 => address) tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) operatorApprovals;
  // Merkle Tree roots
  mapping(uint256 => bytes32) merkleRoot;
  // whitelist mint count
  mapping(uint256 => mapping(address => uint256)) whitelistMints;
}