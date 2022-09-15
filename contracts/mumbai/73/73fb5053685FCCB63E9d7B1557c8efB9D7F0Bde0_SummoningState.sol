// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { SummonTypes } from "../types/Types.sol";
import { ISummoningState } from "../interfaces/ISummoningState.sol";

contract SummoningState is Base, ISummoningState {
  // vars
  uint256 public currentSessionId = 1;

  uint256 public eligibleAgeAfterDurations = 2 days;

  mapping(uint256 => SummonTypes.LineageNode) public lineageTree;

  // summon (champion_id => info)
  mapping(uint256 => SummonTypes.ChampionInfo) champions;

  mapping(uint256 => SummonTypes.SessionCheckpoint) public sessionCheckpoints;
  mapping(string => bool) public createdKeys;

  mapping(uint256 => mapping(bytes32 => bool)) public tickSummoned;

  mapping(address => uint256) public platformShare;

  // TODO: events
  event SessionUpdated(uint256 indexed id, string key, uint256 timestamp, SummonTypes.SessionCheckpoint checkpoint);
  event LineageNodeUpdated(uint256 indexed id, uint256 championID, SummonTypes.LineageNode node, uint256[] totalJoinedInSessionByType, uint256[] totalJoinedInLifeByType);

  /**Set */
  // verified
  function createSession(string memory _key) external onlyRoler("createSession") {
    if (createdKeys[_key]) {
      return;
    }
    sessionCheckpoints[currentSessionId].inited = true;
    createdKeys[_key] = true;
    emit SessionUpdated(currentSessionId, _key, block.timestamp, sessionCheckpoints[currentSessionId]);
    currentSessionId += 1;
  }

  // verified
  function setEligibleAgeAfterDurations(uint256 _durations) external onlyRoler("setEligibleAgeAfterDurations") {
    eligibleAgeAfterDurations = _durations;
  }

  // verified
  function setOriginalMum(uint256 _championID, uint256 _mumID) external onlyRoler("setOriginalMum") {
    lineageTree[_championID].original_mum = _mumID;
    uint256 size = lineageTree[_championID].parents.length;
    uint256[] memory totalJoinedInSessionByType = new uint256[](size);
    uint256[] memory totalJoinedInLifeByType = new uint256[](size);

    for (uint256 i = 0; i < size; i++) {
      totalJoinedInSessionByType[i] = getTotalParticipateInSessionByChampionAndType(lineageTree[_championID].parents[i], lineageTree[_championID].metadata.session_id, lineageTree[_championID].metadata.summon_type);
      totalJoinedInLifeByType[i] = getTotalParticipateInLifeByChampionAndType(lineageTree[_championID].parents[i], lineageTree[_championID].metadata.summon_type);
    }
    emit LineageNodeUpdated(lineageTree[_championID].metadata.session_id, _championID, lineageTree[_championID], totalJoinedInSessionByType, totalJoinedInLifeByType);
  }

  // verified
  function setTotalChampionsSummonedInSession(uint256 _sessionId, uint256 _total) external onlyRoler("setTotalChampionsSummonedInSession") {
    sessionCheckpoints[_sessionId].total_champions_summoned = _total;
    emit SessionUpdated(_sessionId, "", block.timestamp, sessionCheckpoints[currentSessionId]);
  }

  // verified
  function increaseTotalChampionsSummonedInSession(uint256 _sessionId) external onlyRoler("increaseTotalChampionsSummonedInSession") {
    sessionCheckpoints[_sessionId].total_champions_summoned += 1;
    emit SessionUpdated(_sessionId, "", block.timestamp, sessionCheckpoints[currentSessionId]);
  }

  // verified
  function decreaseTotalChampionsSummonedInSession(uint256 _sessionId) external onlyRoler("decreaseTotalChampionsSummonedInSession") {
    if (sessionCheckpoints[_sessionId].total_champions_summoned > 0) {
      sessionCheckpoints[_sessionId].total_champions_summoned -= 1;
    }
    emit SessionUpdated(_sessionId, "", block.timestamp, sessionCheckpoints[currentSessionId]);
  }

  // verified
  function setLineageNode(
    uint256 _championID, //
    SummonTypes.LineageMetadata memory _metadata,
    uint256[] memory _parents,
    uint256 _originalMum
  ) external onlyRoler("setLineageNode") {
    require(sessionCheckpoints[_metadata.session_id].inited, "Session not inited");
    SummonTypes.LineageNode storage lineageNode = lineageTree[_championID];

    lineageNode.inited = true;
    lineageNode.metadata = _metadata;
    lineageNode.parents = _parents;
    lineageNode.original_mum = _originalMum;

    uint256 size = _parents.length;

    uint256[] memory totalJoinedInSessionByType = new uint256[](size);
    uint256[] memory totalJoinedInLifeByType = new uint256[](size);

    for (uint256 i = 0; i < size; i++) {
      totalJoinedInSessionByType[i] = getTotalParticipateInSessionByChampionAndType(_parents[i], _metadata.session_id, _metadata.summon_type);
      totalJoinedInLifeByType[i] = getTotalParticipateInLifeByChampionAndType(_parents[i], _metadata.summon_type);
      lineageTree[_parents[i]].metadata.latest_summon_time = block.timestamp;
    }
    emit LineageNodeUpdated(_metadata.session_id, _championID, lineageNode, totalJoinedInSessionByType, totalJoinedInLifeByType);
  }

  function setLatestTimeSummoned(uint256 _championID, uint256 _amount) external onlyRoler("setLatestTimeSummoned") {
    lineageTree[_championID].metadata.latest_summon_time = _amount;
  }

  // session
  // verified
  function setTotalParticipateInSessionByChampions(
    uint256[] memory _championIDs, //
    uint256[] memory _sessionIDs,
    uint256[] memory _types, //
    uint256[] memory _counts
  ) external onlyRoler("setTotalParticipateInSessionByChampions") {
    require(_championIDs.length == _sessionIDs.length, "Input mismatch");
    require(_championIDs.length == _types.length, "Input mismatch");
    require(_championIDs.length == _counts.length, "Input mismatch");

    uint256 size = _championIDs.length;
    for (uint256 i = 0; i < size; i++) {
      champions[_championIDs[i]].session_summoned_count[_sessionIDs[i]][_types[i]] = _counts[i];
    }
  }

  // verified
  function increaseTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external onlyRoler("increaseTotalParticipateInSessionByChampion") {
    champions[_championID].session_summoned_count[_sessionID][_type] += 1;
  }

  // verified
  function decreaseTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external onlyRoler("decreaseTotalParticipateInSessionByChampion") {
    if (champions[_championID].session_summoned_count[_sessionID][_type] > 0) {
      champions[_championID].session_summoned_count[_sessionID][_type] -= 1;
    }
  }

  // life
  // verified
  function setTotalParticipateInLifeByChampions(
    uint256[] memory _championIDs, //
    uint256[] memory _types, //
    uint256[] memory _counts
  ) external onlyRoler("setTotalParticipateInLifeByChampions") {
    require(_championIDs.length == _types.length, "Input mismatch");
    require(_championIDs.length == _counts.length, "Input mismatch");

    uint256 size = _championIDs.length;
    for (uint256 i = 0; i < size; i++) {
      champions[_championIDs[i]].total_summoned_count[_types[i]] = _counts[i];
    }
  }

  // verified
  function increaseTotalParticipateInLifeByChampion(uint256 _championID, uint256 _type) external onlyRoler("increaseTotalParticipateInLifeByChampion") {
    champions[_championID].total_summoned_count[_type] += 1;
  }

  // verified
  function decreaseTotalParticipateInLifeByChampion(uint256 _championID, uint256 _type) external onlyRoler("decreaseTotalParticipateInLifeByChampion") {
    if (champions[_championID].total_summoned_count[_type] > 0) {
      champions[_championID].total_summoned_count[_type] -= 1;
    }
  }

  // verified
  function tickChampionsSummoned(uint256 _sessionID, bytes32 _key) external onlyRoler("tickChampionsSummoned") {
    tickSummoned[_sessionID][_key] = true;
  }

  // verified
  function increasePlatformShare(address _currency, uint256 _amount) external onlyRoler("increasePlatformShare") {
    platformShare[_currency] += _amount;
  }

  // verified
  function decreasePlatformShare(address _currency, uint256 _amount) external onlyRoler("decreasePlatformShare") {
    platformShare[_currency] -= _amount;
  }

  /** View */
  // verified
  function getCurrentSessionId() public view returns (uint256) {
    return currentSessionId;
  }

  // verified
  function getTotalChampionsSummonedInSession(uint256 _sessionId) public view returns (uint256) {
    return sessionCheckpoints[_sessionId].total_champions_summoned;
  }

  // verified
  function getLineageNode(uint256 _championID) public view returns (SummonTypes.LineageNode memory) {
    return lineageTree[_championID];
  }

  // verified
  function getChampionSummonedAtSession(uint256 _championID) public view returns (uint256) {
    return lineageTree[_championID].metadata.session_id;
  }

  // verified
  function getTotalParticipateInSessionByChampionAndType(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) public view returns (uint256) {
    return champions[_championID].session_summoned_count[_sessionID][_type];
  }

  // verified
  function getTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _start,
    uint256 _end
  ) public view returns (uint256 sum) {
    for (uint256 i = _start; i <= _end; i++) {
      sum += champions[_championID].session_summoned_count[_sessionID][i];
    }
  }

  // verified
  function getTotalParticipateInLifeByChampionAndType(uint256 _championID, uint256 _type) public view returns (uint256) {
    return champions[_championID].total_summoned_count[_type];
  }

  // verified
  function getTotalParticipateInLifeByChampion(
    uint256 _championID,
    uint256 _start,
    uint256 _end
  ) public view returns (uint256 sum) {
    for (uint256 i = _start; i <= _end; i++) {
      sum += champions[_championID].total_summoned_count[i];
    }
  }

  // verified
  function getChampionsSummonedTicked(uint256 _sessionID, bytes32 _key) public view returns (bool) {
    return tickSummoned[_sessionID][_key];
  }

  // verified
  function getPlatformShare(address _currency) public view returns (uint256) {
    return platformShare[_currency];
  }

  // verified
  function getSummonedTimestamp(uint256 _championID) public view returns (uint256) {
    return lineageTree[_championID].metadata.summoned_at;
  }

  // verified
  function getLatestSummonedTimestamp(uint256 _championID) public view returns (uint256) {
    return lineageTree[_championID].metadata.latest_summon_time;
  }

  // verified
  function eligibleDurationsAfterSummoned(uint256 _championID) public view returns (bool) {
    return lineageTree[_championID].metadata.latest_summon_time + eligibleAgeAfterDurations <= block.timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Pellar + LightLink 2022

abstract contract Base is Ownable {
  // variable
  address public accessControlProvider = 0x0bF8b07D3A0C83C5DDe4e12143A4203897f55F90;

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
pragma solidity ^0.8.16;

library SummonChampion {
  struct TokenInfo {
    string uri_name;
    uint256 timestamp;
  }
}

library SummonTypes {
  struct LineageMetadata {
    uint256 session_id;
    uint256 summon_type; // private, public, private_by_public, whitelist
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import { SummonTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ISummoningState {
  function createSession(string memory) external;

  function setTotalChampionsSummonedInSession(uint256 _sessionId, uint256 _total) external;

  function increaseTotalChampionsSummonedInSession(uint256 _sessionId) external;

  function decreaseTotalChampionsSummonedInSession(uint256 _sessionId) external;

  function setLineageNode(
    uint256 _championID, //
    SummonTypes.LineageMetadata memory _metadata,
    uint256[] memory _parents,
    uint256 _originalMum
  ) external;

  // session
  function setTotalParticipateInSessionByChampions(
    uint256[] memory _championIDs, //
    uint256[] memory _sessionIDs,
    uint256[] memory _types, //
    uint256[] memory _counts
  ) external;

  function increaseTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external;

  function decreaseTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external;

  // life
  function setTotalParticipateInLifeByChampions(
    uint256[] memory _championIDs, //
    uint256[] memory _types, //
    uint256[] memory _counts
  ) external;

  function increaseTotalParticipateInLifeByChampion(uint256 _championID, uint256 _type) external;

  function decreaseTotalParticipateInLifeByChampion(uint256 _championID, uint256 _type) external;

  function tickChampionsSummoned(uint256 _sessionID, bytes32 _key) external;

  function increasePlatformShare(address _currency, uint256 _amount) external;

  function decreasePlatformShare(address _currency, uint256 _amount) external;

  /** View */
  function getCurrentSessionId() external view returns (uint256);

  function getTotalChampionsSummonedInSession(uint256 _sessionId) external view returns (uint256);

  function getLineageNode(uint256 _championID) external view returns (SummonTypes.LineageNode memory);

  function getChampionSummonedAtSession(uint256 _championID) external view returns (uint256);

  function getTotalParticipateInSessionByChampionAndType(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _type
  ) external view returns (uint256);

  function getTotalParticipateInSessionByChampion(
    uint256 _championID,
    uint256 _sessionID,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256);

  function getTotalParticipateInLifeByChampionAndType(uint256 _championID, uint256 _type) external view returns (uint256);

  function getTotalParticipateInLifeByChampion(
    uint256 _championID,
    uint256 _start,
    uint256 _end
  ) external view returns (uint256);

  function getChampionsSummonedTicked(uint256 _sessionID, bytes32 _key) external view returns (bool);

  function getPlatformShare(address _currency) external view returns (uint256);

  function getSummonedTimestamp(uint256 _championID) external view returns (uint256);

  function getLatestSummonedTimestamp(uint256 _championID) external view returns (uint256);

  function eligibleDurationsAfterSummoned(uint256 _championID) external view returns (bool);
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