// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { SummonTypes } from "../types/Types.sol";
import { ISummoningRestrictions } from "../interfaces/ISummoningRestrictions.sol";
import { ISummoningState, SummonTypes } from "../../../interfaces/ISummoningState.sol";

contract SummoningRestrictions is Base, ISummoningRestrictions {
  address public summoningState;
  uint256 public parentFightEligibleDuration = 2 days;
  uint256 public childFightEligibleDuration = 7 days;

  function bindSummoningState(address _contract) external onlyRoler("bindSummoningState") {
    summoningState = _contract;
  }

  function setParentFightEligibleDurations(uint256 _seconds) external onlyRoler("setParentFightEligibleDurations") {
    parentFightEligibleDuration = _seconds;
  }

  function setChildFightEligibleDurations(uint256 _seconds) external onlyRoler("setChildFightEligibleDurations") {
    childFightEligibleDuration = _seconds;
  }

  function summoningEligibleToFight(uint256 _championID) external view returns (bool) {
    SummonTypes.LineageNode memory summoningChamp = ISummoningState(summoningState).getLineageNode(_championID);
    if (summoningChamp.metadata.summoned_at >= summoningChamp.metadata.latest_summon_time) {
      return summoningChamp.metadata.summoned_at + childFightEligibleDuration <= block.timestamp;
    }
    return summoningChamp.metadata.latest_summon_time + parentFightEligibleDuration <= block.timestamp;
  }
}

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
pragma solidity ^0.8.16;

import "../modules/summoning/interfaces/ISummoningState.sol";

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
pragma solidity 0.8.16;
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
    uint256 _originalMum,
    bytes memory _notes
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
}