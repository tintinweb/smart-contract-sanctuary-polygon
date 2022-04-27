// SPDX-License-Identifier: MIT

// solhint-disable not-rely-on-time
pragma solidity ^0.8.10;

import "../shared/MonstrosityGameStructs.sol";
import "../shared/MonstrosityBase.sol";
import "../lib/LibMonstrosity.sol";
import "../lib/LibMonstrosityGameData.sol";

contract MonstrosityBattleModule is MonstrosityBase {
  using LibMonstrosityGameData for GameData;

  event Battle(uint256 indexed id);
  event MonsterInjured(uint256 indexed tokenId, uint64 hp);
  event Winner(uint256 indexed place, uint256 indexed tokenId);

  function _markMonstersInBattle(BattleInfo memory battle) internal {
    uint128 xOffset = battle.location % MAP_SIZE;
    uint128 yOffset = (battle.location - xOffset) / MAP_SIZE;
    uint128 x1 = xOffset < battle.area ? 0 : xOffset - battle.area;
    uint128 x2 = xOffset + battle.area + 1 >= MAP_SIZE ? MAP_SIZE : xOffset + battle.area + 1;
    uint128 y = yOffset < battle.area ? 0 : yOffset - battle.area;
    uint128 y2 = yOffset + battle.area + 1 >= MAP_SIZE ? MAP_SIZE : yOffset + battle.area + 1;
    uint128 tokenId;
    uint128 x;

    while (y < y2) {
      x = x1;
      while (x < x2) {
        tokenId = uint128(_gameData.monsterLocations[(y * MAP_SIZE + x)]);

        if (tokenId > 0 && _gameData.monsters[tokenId].hp > 0) {
          _gameData.monstersInBattle.push(tokenId);
          _gameData.monsters[tokenId].inBattle = 1;
        }
        x += 1;
      }
      y += 1;
    }
  }

  function _newBattle() internal {
    BattleInfo memory battle;
    BattleInfo memory _currentBattle = _gameData.currentBattle;
    uint256 _hash = LibMonstrosity._blockHash();
    uint64 _campaign = _gameData.campaign;
    /// @dev if battle count is >1000, after every 100th battle the radius will increase by 1
    uint64 _extraArea = _currentBattle.id > 1000 ? (_currentBattle.id - 1000) / 100 : 0;
    uint128 _monsterCount = _gameData.monsterCount[_campaign];
    uint128 _monsterCalc = ((_monsterCount - _gameData.killedMonsters[_campaign]) * 100) / _monsterCount;
    uint128 _maxArea = (MAP_SIZE * 8) / 100 + _extraArea;
    uint64 _maxMinArea = (MAP_SIZE * 3) / 100 + _extraArea;
    uint64 _battleInt = 2 minutes;
    uint64 _maxAreaAdd = _campaign == 0 ? 6 : 4;
    uint64 _minArea = (100 - uint64(_monsterCalc))**2 / 800 + (MAP_SIZE / 100) + _extraArea;

    battle.id = _currentBattle.id + 1;

    // battle can be ended starting FROM this block, but it's already in effect!
    battle.timestamp =
      uint128(block.timestamp < _currentBattle.timestamp + _battleInt ? _currentBattle.timestamp : block.timestamp) +
      _battleInt;

    if (_minArea > _maxMinArea) {
      _minArea = _maxMinArea;
    }

    battle.area = uint64(_hash % (_minArea + _maxAreaAdd > _maxArea ? _maxArea : _minArea + _maxAreaAdd));

    if (battle.area < _minArea) {
      battle.area = _minArea;
    }

    battle.location = uint128(_hash % (MAP_SIZE**2));

    _markMonstersInBattle(battle);

    // build opponent
    // sum of all trait points / remaining monsters + weight (weight increases)
    // base weight on area
    uint256 opponentTotalPoints = _gameData.traitPoints /
      (_monsterCount - _gameData.killedMonsters[_campaign]) +
      battle.area *
      2;

    for (uint8 i; i < 3; i += 1) {
      battle.opponentTraits[(_hash + i) % 4] = uint32(_hash % opponentTotalPoints);
      opponentTotalPoints -= battle.opponentTraits[(_hash + i) % 4];
    }
    battle.opponentTraits[(_hash + 3) % 4] = uint32(opponentTotalPoints);

    _gameData.currentBattle = battle;

    emit Battle(battle.id);
  }

  function startCampaign() external {
    GameStage stage = _gameData._stage();

    require(
      _gameData.currentBattle.timestamp == 0 && (stage == GameStage.InitialCampaign || stage == GameStage.FinalCampaign)
    );

    _newBattle();
  }

  /**
   * Finds the last remaining monster and adds it to the winners array
   */
  function _findLastMonster() internal {
    if (_gameData.monsterCount[1] - _gameData.killedMonsters[1] == 0) {
      return;
    }

    uint64 total = _gameData.totalMonsters;
    uint192 i = 2;

    while (i <= total) {
      if (_gameData.monsters[i].hp > 0) {
        _gameData.winners[i] = 1;
        emit Winner(1, i);
        return;
      }

      i += 1;
    }
  }

  /**
   * Checks if a new battle is ready to be ended, or we still need to wait
   */
  function canEndBattle() public view returns (bool) {
    GameStage stage = _gameData._stage();

    return
      block.timestamp >= _gameData.currentBattle.timestamp &&
      (stage == GameStage.InitialCampaign || stage == GameStage.FinalCampaign);
  }

  /**
   * Ends the current battle (register damage) and creates the next one
   */
  function endBattle() external payable nonReentrant {
    require(canEndBattle());

    uint256 reward = (MINT_PRICE * (_gameData.currentBattle.area + 1)) / 200;
    uint256 maxReward = (MINT_PRICE * 10) / 100;
    uint128[] memory inBattle = _gameData.monstersInBattle;

    if (inBattle.length > 0) {
      uint128 _campaign = _gameData.campaign;
      uint128 _monsters = _gameData.monsterCount[_campaign];
      uint64 i;
      uint64 injured;
      uint128 tokenId;
      uint128[2] memory killed = _gameData.killedMonsters;
      Monster memory monster;

      while (i < inBattle.length) {
        tokenId = inBattle[i];
        injured = 0;
        monster = _gameData.monsters[tokenId];

        // update monster HP
        for (uint8 t; t < 4; t += 1) {
          if (monster.hp > 0 && _gameData.currentBattle.opponentTraits[t] > monster.traits[t]) {
            _gameData.monsters[tokenId].hp -= 1;
            monster.hp -= 1;
            injured = 1;
          }
        }

        _gameData.monsters[tokenId].inBattle = 0;

        if (monster.hp == 0) {
          // final campaign, add to winners
          if (_campaign == 1 && _monsters - killed[1] < 11) {
            _gameData.winners[tokenId] = _monsters - killed[1];
            emit Winner(_monsters - killed[1], tokenId);
          }

          _gameData.killedMonsters[_campaign] += 1;
          killed[_campaign] += 1;
          // remove monster's trait point from global counter
          _gameData.traitPoints -= monster.totalTraits;
        }

        if (injured == 1) {
          emit MonsterInjured(tokenId, monster.hp);
        }

        i += 1;
      }

      delete _gameData.monstersInBattle;

      // initial campaign is done
      if (_campaign == 0 && _monsters - killed[0] <= (_monsters * 25) / 100) {
        _gameData.startTime = block.timestamp;
        _gameData.campaign = 1;
        _gameData.currentBattle.timestamp = 0;
        _gameData.monsterCount[1] += _monsters - killed[0];
        return;
      }

      // the game is over
      if (_campaign == 1 && _monsters - killed[1] < 2) {
        // at this point if there's one remaining monster, we need to find it, to put it in the winners array
        _findLastMonster();
        return;
      }
    }

    _newBattle();

    // max 10% of mint price
    if (reward > maxReward) {
      reward = maxReward;
    }

    if (_gameData.pools.fees >= reward) {
      _gameData.pools.fees -= reward;
      payable(msg.sender).transfer(reward);
    }
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

pragma solidity ^0.8.10;

library LibMonstrosity {
  function _verifyProof(
    address to,
    bytes32[] memory proof,
    bytes32 root
  ) internal pure returns (bool) {
    // verify Merkle proof
    bytes32 computedHash = keccak256(abi.encodePacked(to));

    for (uint256 i = 0; i < proof.length; i++) {
      if (computedHash <= proof[i]) {
        // hash (current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proof[i]));
        continue;
      }

      // hash (current element of the proof + current computed hash)
      computedHash = keccak256(abi.encodePacked(proof[i], computedHash));
    }

    // check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }

  function _blockHash() internal view returns (uint256) {
    return (uint256(blockhash(block.number - (block.number % 150) - 5)) % uint256(type(int256).max)) / block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../shared/MonstrosityGameStructs.sol";

library LibMonstrosityGameData {
  function _stage(GameData storage _gameData) internal view returns (GameStage) {
    uint256 start = _gameData.startTime;
    uint128[2] memory count = _gameData.monsterCount;

    // game hasn't been initialized yet
    if (start < 1) {
      return GameStage.Preparation;
    }

    // initial campaign
    if (_gameData.campaign == 0) {
      // 2 weeks haven't passed OR less then 4K monsters
      // ! @todo change to 14 days and the count back to 4K tokens !!!
      if (block.timestamp < start + 30 minutes || count[0] < 200) {
        return GameStage.Recruitment;
      }

      return GameStage.InitialCampaign;
    }

    // campaign is already 1 (final), _gameData.startTime was set to the end of the initial campaign
    // we need to wait for the recovery period to pass
    if (block.timestamp < start + 2 hours) {
      return GameStage.Recovery;
    }

    // game has ended
    if (count[1] - _gameData.killedMonsters[1] <= 1) {
      return GameStage.Princess;
    }

    return GameStage.FinalCampaign;
  }

  function _updatePools(
    GameData storage _gameData,
    uint256 amount,
    bool isMint,
    uint256 mintPercentPrize
  ) internal {
    if (isMint) {
      // after the game starts, the token is not participating in it anymore
      if (_stage(_gameData) > GameStage.Recovery) {
        _gameData.pools.dev += amount;
        return;
      }

      _gameData.pools.prize += (amount * mintPercentPrize) / 100;
      _gameData.pools.fees += (amount * 10) / 100;
      _gameData.pools.dev += (amount * 30) / 100;
      return;
    }

    _gameData.pools.prize += (amount * 70) / 100;
    _gameData.pools.dev += (amount * 30) / 100;
  }
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