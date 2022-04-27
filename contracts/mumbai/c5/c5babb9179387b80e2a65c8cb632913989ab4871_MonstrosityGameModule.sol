// SPDX-License-Identifier: MIT

// solhint-disable not-rely-on-time
pragma solidity ^0.8.10;

import "../shared/MonstrosityGameStructs.sol";
import "../shared/MonstrosityBase.sol";
import "../lib/LibMonstrosity.sol";
import "../lib/LibMonstrosityGameData.sol";
import "./MonstrosityWalletModule.sol";

contract MonstrosityGameModule is MonstrosityBase {
  using LibMonstrosityGameData for GameData;

  event LevelUp(uint256 indexed tokenId);
  event Heal(uint256 indexed tokenId);
  event Retreat(uint256 indexed tokenId);

  function isWinner(uint256 tokenId) external view returns (uint256) {
    return _gameData.winners[tokenId];
  }

  function getMonsters(uint64 _campaign) external view returns (uint128) {
    return _gameData.monsterCount[_campaign];
  }

  function getKilledMonsters(uint64 _campaign) external view returns (uint128) {
    return _gameData.killedMonsters[_campaign];
  }

  function getMonster(uint256 tokenId) external view returns (Monster memory monster) {
    monster = _gameData.monsters[tokenId];

    require(monster.id > 0);
  }

  function getCurrentStartTime() external view returns (uint256) {
    return _gameData.startTime;
  }

  function getCurrentBattle() external view returns (BattleInfo memory) {
    return _gameData.currentBattle;
  }

  function getMonstersInCurrentBattle() external view returns (uint128[] memory) {
    return _gameData.monstersInBattle;
  }

  function stage() public view returns (GameStage) {
    return _gameData._stage();
  }

  function recruitMonster(uint256 tokenId, uint64[4] calldata traits) external payable {
    // create and store monster and monster location
    Monster memory _monster;
    uint256 _locationsLeft = MAP_SIZE**2 - _gameData.monsterCount[0] - _gameData.monsterCount[1];
    // the random location
    uint256 _rs = (LibMonstrosity._blockHash() + tokenId) % _locationsLeft;
    uint256 locationCacheMonster = _gameData.monsterLocationCache[_rs];
    uint256 locationCacheTail = _gameData.monsterLocationCache[_locationsLeft - 1];

    _monster.id = tokenId;

    // if there's a cache at `monsterLocationCache[_rs]` then use it otherwise use `_rs` itself
    _monster.location = locationCacheMonster == 0 ? _rs : locationCacheMonster;
    // grab a number from the tail
    _gameData.monsterLocationCache[_rs] = locationCacheTail == 0 ? _locationsLeft - 1 : locationCacheTail;

    _monster.hp = 4;
    _monster.traits = traits;
    _monster.totalTraits = 40;

    _gameData.traitPoints += 40;
    _gameData.monsters[tokenId] = _monster;
    _gameData.monsterLocations[_monster.location] = tokenId;

    // increase monsters in the correct campaign and in total
    _gameData.monsterCount[_gameData._stage() > GameStage.Recruitment ? 1 : 0] += 1;
    _gameData.totalMonsters += 1;
  }

  function usePotion(uint256 tokenId, uint64[4] memory _traits) external payable nonReentrant {
    Monster memory monster = _gameData.monsters[tokenId];

    require(monster.id > 0 && monster.hp > 0 && monster.inBattle == 0 && _gameData._stage() < GameStage.Princess);
    uint64 _totalTraitPoints;
    uint192 i;

    // validate amounts and cost
    while (i < 4) {
      _totalTraitPoints += _traits[i];
      i += 1;
    }

    require(
      // check cost
      msg.value == 2**monster.potions * TRAIT_POINT_PRICE * _totalTraitPoints &&
        (_totalTraitPoints == 4 || _totalTraitPoints == 8 || _totalTraitPoints == 12)
    );

    i = 0;
    while (i < 4) {
      _gameData.monsters[tokenId].traits[i] += _traits[i];
      i += 1;
    }

    _gameData.monsters[tokenId].totalTraits += _totalTraitPoints;
    _gameData.monsters[tokenId].potions += 1;
    _gameData.traitPoints += _totalTraitPoints;

    _gameData._updatePools(msg.value, false, 0);

    emit LevelUp(tokenId);
  }

  function canHealMonster(uint256 tokenId) public view returns (bool) {
    Monster memory monster = _gameData.monsters[tokenId];
    return monster.id > 0 && monster.hp < 4 && _gameData._stage() == GameStage.Recovery;
  }

  function healMonster(uint256 tokenId) external payable nonReentrant {
    Monster memory monster = _gameData.monsters[tokenId];

    require(canHealMonster(tokenId) && msg.value == (4 - monster.hp) * (MINT_PRICE / 8));

    if (monster.hp == 0) {
      _gameData.monsterCount[1] += 1;
    }

    _gameData.monsters[tokenId].hp = 4;
    _gameData.traitPoints += monster.totalTraits;

    _gameData._updatePools(msg.value, false, 0);

    emit Heal(tokenId);
  }

  function retreatRefund() public view returns (uint256) {
    uint128 _monsterCount = _gameData.monsterCount[1];
    uint128 _killedMonsters = _gameData.killedMonsters[1];
    uint256 total = _gameData.totalMonsters;

    if (
      _monsterCount - _killedMonsters > 10 && // already winner, cannot retreat
      _monsterCount - _killedMonsters <= _monsterCount / 10 && // still more than 10% of the monsters is alive
      _gameData._stage() == GameStage.FinalCampaign
    ) {
      // prizePool(without upgrades!) / remainingMonsters / (totalMonsters / 80);
      uint256 mintPricePrize = (MINT_PRICE * MINT_PERCENT_PRIZE) / 100;
      return (total * mintPricePrize) / (_monsterCount - _killedMonsters) / (total / 80);
    }

    return 0;
  }

  function retreat(uint256 tokenId) external payable nonReentrant returns (uint256 prize) {
    Monster memory monster = _gameData.monsters[tokenId];

    require(monster.id > 0 && monster.hp > 0 && monster.inBattle == 0 && _nftData.owners[tokenId] == msg.sender);

    prize = retreatRefund();
    require(prize > 0 && prize < _gameData.pools.prize);

    // mark the monster as killed, it cannot be claimed against anymore
    _gameData.monsters[tokenId].hp = 0;
    _gameData.killedMonsters[1] += 1;
    _gameData.pools.prize -= prize;

    payable(msg.sender).transfer(prize);
    emit Retreat(tokenId);
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

import "../shared/MonstrosityBase.sol";
import "../lib/LibMonstrosityGameData.sol";
import "./MonstrosityERC721Module.sol";

contract MonstrosityWalletModule is MonstrosityBase {
  using LibMonstrosityGameData for GameData;

  function getPools() external view returns (Pools memory) {
    return _gameData.pools;
  }

  function setWithdrawalAddress(address newWithdrawalAddress) external onlyOwner nonReentrant {
    _withdrawalAddress = payable(newWithdrawalAddress);
  }

  function withdraw(uint256 amount) external payable onlyOwner {
    uint256 devPool = _gameData.pools.dev;
    uint256 balance = address(this).balance;

    require(_withdrawalAddress != address(0) && devPool > 0);

    if (amount == 0 || amount > devPool) {
      amount = devPool;
      _gameData.pools.dev = 0;
    } else {
      _gameData.pools.dev -= amount;
    }

    if (_gameData._stage() == GameStage.Princess) {
      amount += _gameData.pools.fees;
      _gameData.pools.fees = 0;
    }

    if (amount > balance) {
      amount = balance;
      _gameData.pools.dev = 0;
    }

    payable(_withdrawalAddress).transfer(amount);
  }

  function claimPrize(uint256 tokenId) external payable nonReentrant {
    uint256 place = _gameData.winners[tokenId];

    require(place > 0 && _gameData._stage() == GameStage.Princess && _nftData.owners[tokenId] == msg.sender);

    uint8[10] memory payout = [60, 20, 10, 4, 1, 1, 1, 1, 1, 1];
    uint256 prize = (_gameData.pools.prize * payout[place - 1]) / 100;

    if (prize > address(this).balance) {
      prize = address(this).balance;
    }

    // send the princess nft to the final winner
    if (place == 1) {
      (bool success, ) = _ds[MonstrosityERC721Module.transferPrincess.selector].delegatecall(
        abi.encodeWithSelector(MonstrosityERC721Module.transferPrincess.selector)
      );
      require(success, "ERR_TRANSFER_PRINCESS");
    }

    // mark the withdrawal
    _gameData.winners[tokenId] = 0;

    payable(msg.sender).transfer(prize);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../shared/MonstrosityBase.sol";
import "../shared/ERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../lib/LibMonstrosityERC721.sol";

contract MonstrosityERC721Module is MonstrosityBase, ERC165, IERC721, IERC721Metadata {
  using Strings for uint256;
  using LibMonstrosityERC721 for ERC721Data;

  string private constant NAME = "MonstrosityNFT";
  string private constant SYMBOL = "MONSTER";
  string private constant URI_SUFFIX = ".json";

  function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _nftData.balances[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _nftData.owners[tokenId];
    require(owner != address(0));
    return owner;
  }

  function name() external pure returns (string memory) {
    return NAME;
  }

  function symbol() external pure returns (string memory) {
    return SYMBOL;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(_nftData._exists(tokenId));

    string memory baseURI = _nftData.baseUri;
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), URI_SUFFIX)) : "";
  }

  function setBaseUri(string memory newBaseUri) external onlyOwner {
    _nftData.baseUri = newBaseUri;
  }

  function approve(address to, uint256 tokenId) external {
    address owner = ownerOf(tokenId);
    require(to != owner && (msg.sender == owner || isApprovedForAll(owner, msg.sender)));
    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_nftData._exists(tokenId));
    return _nftData.tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) external {
    require(msg.sender != operator);
    _nftData.operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _nftData.operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    // can't transfer if in battle
    require(_gameData.monsters[tokenId].inBattle == 0 && _isApprovedOrOwner(msg.sender, tokenId));
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public {
    transferFrom(from, to, tokenId);
    require(LibMonstrosityERC721._checkOnERC721Received(from, to, tokenId, _data));
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_nftData._exists(tokenId));
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf(tokenId) == from && to != address(0));

    // _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _nftData.balances[from] -= 1;
    _nftData.balances[to] += 1;
    _nftData.owners[tokenId] = to;

    emit Transfer(from, to, tokenId, "");

    // _afterTokenTransfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal {
    _nftData.tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function totalSupply() external view returns (uint256) {
    return _nftData.supply;
  }

  /// @dev Returns all NFTs in the given wallet
  function getTokenIDsInWallet(address walletAddress) external view returns (uint256[] memory _tokenIds) {
    uint256 addressTokenCount = balanceOf(walletAddress);
    _tokenIds = new uint256[](addressTokenCount);

    uint256 currentSupply = _nftData.supply;
    uint256 currentTokenId = 1;
    uint256 tokenIndex;

    while (tokenIndex < addressTokenCount && currentTokenId <= currentSupply) {
      if (ownerOf(currentTokenId) == walletAddress) {
        _tokenIds[tokenIndex] = currentTokenId;
        tokenIndex += 1;
      }

      currentTokenId += 1;
    }
  }

  function transferPrincess() external payable {
    // unlock princess and transfer to owner
    _approve(msg.sender, 1);
    safeTransferFrom(address(this), msg.sender, 1);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.10;

import "../interfaces/IERC165.sol";

abstract contract ERC165 is IERC165 {
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.10;

import "./IERC165.sol";
import "./IERC721TransferEvent.sol";

interface IERC721 is IERC165, IERC721TransferEvent {
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.10;

import "./IERC721.sol";

interface IERC721Metadata is IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "../shared/MonstrosityGameStructs.sol";
import "../shared/ERC721DataStruct.sol";
import "../interfaces/IERC721Receiver.sol";

library LibMonstrosityERC721 {
  function _exists(ERC721Data storage _nftData, uint256 tokenId) internal view returns (bool) {
    return _nftData.owners[tokenId] != address(0);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal returns (bool) {
    if (to.code.length <= 0) {
      return true;
    }

    try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert("ERR_NON_IMPLEMENTER");
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.10;

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC721TransferEvent {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId, bytes32 name);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.10;

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}