// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Base2.sol";
import { ISummoningRestrictions } from "../../../interfaces/ISummoningRestrictions.sol";

// Pellar + LightLink 2022

contract BloodingService is BaseTournamentService {
  constructor() {
    serviceID = BLOODING_ID;
    currentTournamentID = 50000;
  }

  // reviewed
  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) public view virtual override returns (bool, string memory) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);

    if (_isAlreadyJoin(tournament.warriors, _championID)) {
      return (false, "TRV: Already joined"); // check if join or not
    }

    if (!ISummoningRestrictions(summoningRestrictionAddr).summoningEligibleToFight(_championID)) {
      return (false, "TRV: Require reach time after summoning");
    }

    if (ICFState(cFState).getTotalPending(_championID, SOLO_ID, SOLO_ID) > 0) {
      return (false, "TRV: Having bet NFT pending");
    }

    if (ICFState(cFState).getTotalPending(_championID, BLOODING_ID, BLOODING_ID) > 0) {
      return (false, "TRV: Only 1 blooding at the same time");
    }

    if (ICFState(cFState).getRankingsCount(_championID, serviceID, 1) > 0) {
      return (false, "TRV: Require unblooded"); // 1 => first win
    }

    if (ICFState(cFState).getTotalPending(_championID, BLOODING_ID, 30) >= IChampionUtils(championUtils).maxFightPerChampion()) {
      return (false, "TRV: Exceed max fight per champion");
    }

    if (!_isInCharacterClassList(tournament.restrictions.character_classes, _championID)) {
      return (false, "TRV: character class required");
    }

    if (!_isInWhitelist(tournament.restrictions.whitelist, _championID)) {
      return (false, "TRV: whitelist required");
    }

    if (_isInBlacklist(tournament.restrictions.blacklist, _championID)) {
      return (false, "TRV: non-blacklist required");
    }
    return (true, "");
  }

  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    uint256 amount = platformShare[_currency];
    platformShare[_currency] = 0;
    IZooKeeper(zooKeeper).transferERC20Out(_currency, _to, amount);
  }
}

contract BloodbathService is BaseTournamentService {
  constructor() {
    serviceID = BLOODBATH_ID;
    currentTournamentID = 50000;
  }

  // reviewed
  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) public view virtual override returns (bool, string memory) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);

    if (_isAlreadyJoin(tournament.warriors, _championID)) {
      return (false, "TRV: Already joined"); // check if join or not
    }

    if (!ISummoningRestrictions(summoningRestrictionAddr).summoningEligibleToFight(_championID)) {
      return (false, "TRV: Require reach time after summoning");
    }

    if (ICFState(cFState).getTotalPending(_championID, SOLO_ID, SOLO_ID) > 0) {
      return (false, "TRV: Having bet NFT pending");
    }

    uint128 totalFought;
    for (uint8 i = BLOODING_ID; i <= 30; i++) {
      totalFought += ICFState(cFState).getRankingsCount(_championID, i, 0);
    }

    if (requireBlooded && !(ICFState(cFState).getRankingsCount(_championID, BLOODING_ID, 1) > 0 || totalFought >= 5)) {
      // => 1 => first win, service ID = 1 => blooding
      // => 0 => total fought, service ID = 1
      return (false, "TRV: Require blooded");
    }

    if (ICFState(cFState).getTotalPending(_championID, BLOODING_ID, 30) >= IChampionUtils(championUtils).maxFightPerChampion()) {
      return (false, "TRV: Exceed max fight per champion");
    }

    if (!_validWinRate(_championID, BLOODING_ID, 30, 1, tournament.restrictions.win_rate_percent_min, tournament.restrictions.win_rate_percent_max, tournament.restrictions.win_rate_base_divider)) {
      return (false, "TRV: require win rate eligible");
    }

    if (!_isInCharacterClassList(tournament.restrictions.character_classes, _championID)) {
      return (false, "TRV: character class required");
    }

    if (!_isInWhitelist(tournament.restrictions.whitelist, _championID)) {
      return (false, "TRV: whitelist required");
    }

    if (_isInBlacklist(tournament.restrictions.blacklist, _championID)) {
      return (false, "TRV: non-blacklist required");
    }
    return (true, "");
  }

  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    uint256 amount = platformShare[_currency];
    platformShare[_currency] = 0;
    IZooKeeper(zooKeeper).transferERC20Out(_currency, _to, amount);
  }
}

contract BloodEloService is BaseTournamentService {
  constructor() {
    serviceID = BLOOD_ELO_ID;
    currentTournamentID = 50000;
  }

  // reviewed
  function eligibleJoinTournament(uint64 _tournamentID, uint256 _championID) public view virtual override returns (bool, string memory) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);

    if (_isAlreadyJoin(tournament.warriors, _championID)) {
      return (false, "TRV: Already joined"); // check if join or not
    }

    if (!ISummoningRestrictions(summoningRestrictionAddr).summoningEligibleToFight(_championID)) {
      return (false, "TRV: Require reach time after summoning");
    }

    if (ICFState(cFState).getTotalPending(_championID, SOLO_ID, SOLO_ID) > 0) {
      return (false, "TRV: Having bet NFT pending");
    }

    uint128 totalFought;
    for (uint8 i = BLOODING_ID; i <= 30; i++) {
      totalFought += ICFState(cFState).getRankingsCount(_championID, i, 0);
    }

    if (requireBlooded && !(ICFState(cFState).getRankingsCount(_championID, BLOODING_ID, 1) > 0 || totalFought >= 5)) {
      // => 1 => first win, service ID = 1 => blooding
      // => 0 => total fought, service ID = 1
      return (false, "TRV: Require blooded");
    }

    if (ICFState(cFState).getTotalPending(_championID, BLOODING_ID, 30) >= IChampionUtils(championUtils).maxFightPerChampion()) {
      return (false, "TRV: Exceed max fight per champion");
    }

    uint64 elo = ICFState(cFState).getChampionElo(_championID);

    if (!(tournament.restrictions.elo_min <= elo && elo < tournament.restrictions.elo_max)) {
      return (false, "TRV: elo required");
    }

    if (!_validWinRate(_championID, BLOODING_ID, 30, 1, tournament.restrictions.win_rate_percent_min, tournament.restrictions.win_rate_percent_max, tournament.restrictions.win_rate_base_divider)) {
      return (false, "TRV: require win rate eligible");
    }

    if (!_isInCharacterClassList(tournament.restrictions.character_classes, _championID)) {
      return (false, "TRV: character class required");
    }

    if (!_isInWhitelist(tournament.restrictions.whitelist, _championID)) {
      return (false, "TRV: whitelist required");
    }

    if (_isInBlacklist(tournament.restrictions.blacklist, _championID)) {
      return (false, "TRV: non-blacklist required");
    }
    return (true, "");
  }

  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    uint256 amount = platformShare[_currency];
    platformShare[_currency] = 0;
    IZooKeeper(zooKeeper).transferERC20Out(_currency, _to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { IChampionUtils } from "../../../interfaces/IChampionUtils.sol";
import { TournamentTypes } from "../types/Types.sol";
import { ITournamentService } from "../interfaces/ITournamentService.sol";
import { ITournamentState } from "../interfaces/ITournamentState.sol";
import { IZooKeeper } from "../interfaces/IZooKeeper.sol";
import { ICAState } from "../interfaces/ICAState.sol";
import { ICFState } from "../interfaces/ICFState.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Pellar + LightLink 2022

contract BaseService is Base {
  bool public requireBlooded = false;
  // constants
  uint8 public SOLO_ID = 0;
  uint8 public BLOODING_ID = 1;
  uint8 public BLOODBATH_ID = 2;
  uint8 public BLOOD_ELO_ID = 3;

  // variables
  address public tournamentState;
  address public cFState;
  address public cAState;
  address public championUtils;
  address public summoningRestrictionAddr;
  address public zooKeeper;

  function toggleRequireBlooded(bool _state) external onlyRoler("toggleRequireBlooded") {
    requireBlooded = _state;
  }

  // reviewed
  function bindTournamentState(address _contract) external onlyRoler("bindTournamentState") {
    tournamentState = _contract;
  }

  // reviewed
  function bindChampionFightingState(address _contract) external onlyRoler("bindChampionFightingState") {
    cFState = _contract;
  }

  // reviewed
  function bindChampionAttributesState(address _contract) external onlyRoler("bindChampionAttributesState") {
    cAState = _contract;
  }

  // reviewed
  function bindChampionUtils(address _contract) external onlyRoler("bindChampionUtils") {
    championUtils = _contract;
  }

  function bindSummoningRestriction(address _contract) external onlyRoler("bindSummoningRestriction") {
    summoningRestrictionAddr = _contract;
  }

  function bindZooKeeper(address _contract) external onlyRoler("bindZooKeeper") {
    zooKeeper = _contract;
  }

  // reviewed
  // verified
  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  // reviewed
  // verified
  function getSigner(bytes memory _message, bytes memory _signature) internal pure returns (address) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(_message.length), _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s);
  }
}

contract BaseTournamentService is BaseService, ITournamentService {
  uint8 public serviceID;
  uint64 public currentTournamentID;
  mapping(address => uint256) public platformShare;
  mapping(string => bool) public createdKeys;

  function _updateFightingForJoin(uint256 _championID) internal {
    ICFState(cFState).increasePendingCount(_championID, serviceID);
  }

  // reviewed
  function _payForJoin(
    address _currency,
    uint256 _buyIn,
    address _payer
  ) internal virtual {
    if (_buyIn == 0) return;
    IZooKeeper(zooKeeper).transferERC20In(_currency, _payer, _buyIn);
  }

  function _refundByCancel(uint64 _serviceID, uint64 _tournamentID) internal virtual {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(_serviceID, _tournamentID);

    uint64 size = uint64(tournament.warriors.length);
    for (uint256 i = 0; i < size; i++) {
      ICFState(cFState).decreasePendingCount(tournament.warriors[i].ID, _serviceID);
      if (tournament.configs.buy_in > 0) {
        address receiver = tournament.warriors[i].account;
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, receiver, tournament.configs.buy_in);
      }
    }
  }

  // reviewed
  function _canChangeBuyIn(
    uint64 _serviceID,
    uint64 _tournamentID,
    uint256 _newBuyIn
  ) internal view returns (bool) {
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(_serviceID, _tournamentID);
    return _newBuyIn == tournament.configs.buy_in || tournament.warriors.length == 0;
  }

  // reviewed
  function _isAlreadyJoin(TournamentTypes.Warrior[] memory _warriors, uint256 _championID) internal pure returns (bool) {
    uint256 size = _warriors.length;
    for (uint256 i = 0; i < size; i++) {
      if (_warriors[i].ID == _championID) return true;
    }
    return false;
  }

  // reviewed
  function _isInWhitelist(uint256[] memory _whitelist, uint256 _id) internal pure returns (bool) {
    uint16 size = uint16(_whitelist.length);
    if (size == 0) {
      return true;
    }
    for (uint16 i = 0; i < size; i++) {
      if (_id == _whitelist[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _isInBlacklist(uint256[] memory _blacklist, uint256 _id) internal pure returns (bool) {
    uint16 size = uint16(_blacklist.length);
    if (size == 0) {
      return false;
    }
    for (uint16 i = 0; i < size; i++) {
      if (_id == _blacklist[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _isInCharacterClassList(uint16[] memory _characterClasses, uint256 _id) internal view returns (bool) {
    uint16 size = uint16(_characterClasses.length);
    if (size == 0) {
      return true;
    }
    uint16 characterClass = ICAState(cAState).getCharacterClassByChampionId(_id);
    for (uint16 i = 0; i < size; i++) {
      if (characterClass == _characterClasses[i]) {
        return true;
      }
    }
    return false;
  }

  // reviewed
  function _validWinRate(
    uint256 _championID,
    uint16 _start,
    uint16 _end,
    uint32 _position,
    uint16 _minRate,
    uint16 _maxRate,
    uint16 _baseDivider
  ) internal view returns (bool) {
    if (_minRate == 0 && _maxRate == 0) {
      return true;
    }
    uint128 totalFought = ICFState(cFState).getTotalWinByPosition(_championID, _start, _end, 0);

    if (totalFought == 0) {
      return false;
    }

    uint128 totalWin = ICFState(cFState).getTotalWinByPosition(_championID, _start, _end, _position);

    uint256 precision = 10**18;

    return
      ((precision * _minRate) / _baseDivider) <= ((totalWin * precision) / totalFought) && //
      ((totalWin * precision) / totalFought) < ((precision * _maxRate) / _baseDivider);
  }

  // reviewed
  function createTournament(
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory _configs, //
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external virtual override onlyRoler("createTournament") {
    require(_configs.length == _restrictions.length, "Input mismatch");
    uint64 size = uint64(_configs.length);
    uint64 currentID = currentTournamentID;
    for (uint64 i = 0; i < size; i++) {
      if (createdKeys[_key[i]]) {
        continue;
      }
      TournamentTypes.TournamentConfigs memory data = _configs[i];
      data.status = TournamentTypes.TournamentStatus.AVAILABLE; // override
      data.creator = tx.origin;
      ITournamentState(tournamentState).createTournament(serviceID, currentID, _key[i], data, _restrictions[i]);
      createdKeys[_key[i]] = true;
      currentID += 1;
    }
    currentTournamentID += size;
  }

  // reviewed
  function updateTournamentConfigs(uint64 _tournamentID, TournamentTypes.TournamentConfigs memory _configs) external virtual override onlyRoler("updateTournamentConfigs") {
    require(_canChangeBuyIn(serviceID, _tournamentID, _configs.buy_in), "TRV: Can not update buy in with player joined");
    ITournamentState(tournamentState).updateTournamentConfigs(serviceID, _tournamentID, _configs);
  }

  // reviewed
  function updateTournamentRestrictions(uint64 _tournamentID, TournamentTypes.TournamentRestrictions memory _restrictions) external virtual override onlyRoler("updateTournamentRestrictions") {
    ITournamentState(tournamentState).updateTournamentRestrictions(serviceID, _tournamentID, _restrictions);
  }

  function updateTournamentTopUp(TournamentTypes.TopupDto[] memory _tournaments) external virtual override onlyRoler("updateTournamentTopUp") {
    uint256 size = _tournaments.length;
    for (uint256 i = 0; i < size; i++) {
      ITournamentState(tournamentState).updateTournamentTopUp(serviceID, _tournaments[i].tournament_id, _tournaments[i].top_up);
    }
  }

  // reviewed
  function cancelTournament(uint64 _tournamentID, bytes memory) external virtual override onlyRoler("cancelTournament") {
    _refundByCancel(serviceID, _tournamentID);
    ITournamentState(tournamentState).cancelTournament(serviceID, _tournamentID);
  }

  function eligibleJoinTournament(uint64, uint256) public view virtual override returns (bool, string memory) {
    return (true, "");
  }

  // _signature
  function joinTournament(bytes memory _signature, bytes memory _params) external virtual override onlyRoler("joinTournament") {
    address signer = tx.origin;
    // service ID, tournamentID, ...
    (uint64 _serviceID, uint64 tournamentID, address joiner, uint256 championID, uint16 stance) = abi.decode(_params, (uint64, uint64, address, uint256, uint16));

    if (_signature.length > 0) {
      bytes memory message = abi.encodePacked(
        "Tournament Type: ", //
        Strings.toString(_serviceID),
        ",",
        " Tournament ID: ",
        Strings.toString(tournamentID),
        ",",
        " Champion ID: ",
        Strings.toString(championID),
        ",",
        " Stance: ",
        Strings.toString(stance)
      );
      signer = getSigner(message, _signature);
    }

    require(_serviceID == serviceID, "TRV: Non-relay attack");
    require(signer == joiner, "TRV: Signer mismatch"); // require signature match with joiner
    require(IChampionUtils(championUtils).isOwnerOf(signer, championID), "TRV: Require owner"); // require owner of token

    (bool eligible, string memory errMsg) = eligibleJoinTournament(tournamentID, championID);
    require(eligible, errMsg);

    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, tournamentID);
    require(tournament.configs.status == TournamentTypes.TournamentStatus.AVAILABLE, "TRV: Tournament not available");

    _payForJoin(tournament.configs.currency, tournament.configs.buy_in, joiner);
    _updateFightingForJoin(championID);

    ITournamentState(tournamentState).joinTournament(serviceID, tournamentID, TournamentTypes.Warrior({ account: signer, ID: championID, stance: stance, win_position: 0, data: "" }));
  }

  // reviewed
  function completeTournament(
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory _additionalInfo
  ) external virtual override onlyRoler("completeTournament") {
    require(_warriors.length == _championsElo.length, "Array mismatch");
    TournamentTypes.TournamentInfo memory tournament = ITournamentState(tournamentState).getTournamentsByClassAndId(serviceID, _tournamentID);
    for (uint256 i = 0; i < _championsElo.length; i++) {
      ICFState(cFState).setChampionElo(_championsElo[i].champion_id, _championsElo[i].elo);
    }

    uint256 prizePool = tournament.configs.buy_in * tournament.configs.size + tournament.configs.top_up;
    uint256 share = ((prizePool * tournament.configs.fee_percentage) / 10000);
    platformShare[tournament.configs.currency] += share;

    uint256 winnings = prizePool - share;

    // double up type
    if (_additionalInfo.length > 0) {
      address[] memory receivers = abi.decode(_additionalInfo, (address[]));
      if (receivers.length > 0) {
        for (uint8 i; i < receivers.length; i++) {
          IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, receivers[i], winnings / receivers.length);
        }

        winnings = 0;
      }
    }

    for (uint256 i = 0; i < _warriors.length; i++) {
      require(_warriors[i].win_position > 0, "Invalid position");
      _warriors[i].account = tournament.warriors[i].account;
      _warriors[i].stance = tournament.warriors[i].stance;

      if (_warriors[i].win_position == 1) {
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, _warriors[i].account, (winnings * 70) / 100);
      }
      if (_warriors[i].win_position == 2) {
        IZooKeeper(zooKeeper).transferERC20Out(tournament.configs.currency, _warriors[i].account, (winnings * 30) / 100);
      }
      ICFState(cFState).increaseRankingsCount(_warriors[i].ID, serviceID, 0); // update total fought
      ICFState(cFState).increaseRankingsCount(_warriors[i].ID, serviceID, _warriors[i].win_position); // update ranking
      ICFState(cFState).decreasePendingCount(_warriors[i].ID, serviceID);
    }
    ITournamentState(tournamentState).completeTournament(serviceID, _tournamentID, _warriors);
  }
}

interface ITRVBPToken {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IStaking {
  function getStaker(uint256 _championID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../modules/summoning/interfaces/ISummoningRestrictions.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Pellar + LightLink 2022

abstract contract Base is Ownable {
  // variable
  address public accessControlProvider = 0x3f0B50B7A270de536D5De35C11C2613284C4304e;

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
pragma solidity 0.8.16;

interface IChampionUtils {
  function isOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function isOriginalOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function getTokenContract(uint256 _championID) external view returns (address);

  function maxFightPerChampion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Pellar + LightLink 2022

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
    uint64 elo_min;
    uint64 elo_max;

    uint16 win_rate_percent_min;
    uint16 win_rate_percent_max;
    uint16 win_rate_base_divider;

    uint256[] whitelist;
    uint256[] blacklist;

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
pragma solidity ^0.8.16;
import { TournamentTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

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
pragma solidity ^0.8.16;
import { TournamentTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ITournamentState {
  // create tournament
  function createTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    string memory _key,
    TournamentTypes.TournamentConfigs memory _data,
    TournamentTypes.TournamentRestrictions memory _restrictions
  ) external;

  // update tournament
  function updateTournamentConfigs(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory _data
  ) external;

  function updateTournamentRestrictions(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _data
  ) external;

  function updateTournamentTopUp(
    uint64 _serviceID,
    uint64 _tournamentID,
    uint256 _topUp
  ) external;

  function joinTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior memory _warrior
  ) external;

  function completeTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors
  ) external;

  function cancelTournament(
    uint64 _serviceID,
    uint64 _tournamentID
  ) external;

  function getTournamentsByClassAndId(uint64 _serviceID, uint64 _tournamentID) external view returns (TournamentTypes.TournamentInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";

// Pellar + LightLink 2022

interface IZooKeeper {
  function transferERC20In(
    address _currency,
    address _from,
    uint256 _amount
  ) external;

  function transferERC20Out(
    address _currency,
    address _to,
    uint256 _amount
  ) external;

  function transferERC721In(
    address _currency,
    address _from,
    uint256 _tokenId
  ) external;

  function transferERC721Out(
    address _currency,
    address _to,
    uint256 _tokenId
  ) external;

  function transferERC1155In(
    address _currency,
    address _from,
    uint256 _id,
    uint256 _amount
  ) external;

  function transferERC1155Out(
    address _currency,
    address _to,
    uint256 _id,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Pellar + LightLink 2022

import { ChampionAttributeTypes, CommonTypes } from "../types/Types.sol";

interface ICAState {
  function setGeneralAttributes(
    uint256[] memory _tokenIds,
    ChampionAttributeTypes.GeneralAttributes[] memory _attributes
  ) external;

  function setOtherAttributes(
    uint256[] memory _tokenIds,
    CommonTypes.Object[] memory _attributes
  ) external;

  // get
  function getCharacterClassByChampionId(uint256 _tokenId) external view returns (uint16);

  function getGeneralAttributesByChampionId(
    uint256 _tokenId
  ) external view returns (ChampionAttributeTypes.GeneralAttributes memory);

  function getOtherAttributeByChampionId(
    uint256 _tokenId,
    bytes memory _key
  ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Pellar + LightLink 2022

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { SummonTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ISummoningRestrictions {
  function setParentFightEligibleDurations(uint256 _seconds) external;

  function setChildFightEligibleDurations(uint256 _seconds) external;

  function summoningEligibleToFight(uint256 _championID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library SummonChampion {
  struct TokenInfo {
    string uri_name;
    uint256 timestamp;
  }
}

library SummonTypes {
  struct LineageMetadata {
    uint256 session_id;
    uint256 summon_type; // private, public, etc
    uint256 summoned_at;
    uint256 latest_summon_time;
  }

  struct LineageNode {
    bool inited;
    LineageMetadata metadata;
    uint256[] parents;
    uint256 original_mum;
  }

  struct ChampionInfo {
    // (session id => (summon_type => total_count)) // maximum summon times count in a session by summon types
    mapping(uint256 => mapping(uint256 => uint256)) session_summoned_count;

    // (type => total_count) // maximum summon times count in champion lifes by summon types
    mapping(uint256 => uint256) total_summoned_count;

    mapping(bytes => bytes) others; // put type here
  }

  struct SessionCheckpoint {
    bool inited;
    uint256 total_champions_summoned;
  }

  struct SummonSessionInfo {
    uint256 id;
    uint256 max_champions_summoned;
    uint256 summon_type;
    uint8 lineage_level;
    ParentSummonChampions[] parents;
    FixedFeeInfo fees;
  }

  struct ParentSummonChampions {
    uint256 champion_id;
    address owner;
    uint256 summon_eligible_after_session;
    uint256 max_per_life;
    uint256 max_per_session_by_type;
    uint256 max_per_session;
  }

  struct FixedFeeInfo {
    address currency;
    uint256 total_fee;

    address donor_receiver;
    uint256 donor_amount;

    uint256 platform_amount;

    DynamicFeeReceiver[] dynamic_fee_receivers;
  }

  struct DynamicFeeReceiver {
    address receiver;
    uint256 amount;
  }
}