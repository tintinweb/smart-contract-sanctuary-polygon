// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Base } from "../../../common/Base.sol";
import { ICAState } from "../../../interfaces/ICAState.sol";
import { IZooKeeper } from "../../../interfaces/IZooKeeper.sol";
import { IChampionUtils } from "../../../interfaces/IChampionUtils.sol";
import { SummonTypes } from "../types/Types.sol";
import { ChampionAttributeTypes } from "../../../types/Types.sol";
import { ISummoningService } from "../interfaces/ISummoningService.sol";
import { ISummoningState } from "../interfaces/ISummoningState.sol";
import { ISummonChampion } from "../interfaces/ISummonChampion.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SummoningService is Base, ISummoningService {
  address public cAState;
  address public summonChampion;
  address public summoningState;
  address public championUtils;
  address public zooKeeper;
  address public verifier = 0x9f6B54d48AD2175e56a1BA9bFc74cd077213B68D;

  /* Setup */
  // verified
  function bindChampionAttributesState(address _contract) external onlyRoler("bindChampionAttributesState") {
    cAState = _contract;
  }

  // verified
  function bindSummoningChampionContract(address _contract) external onlyRoler("bindSummoningChampionContract") {
    summonChampion = _contract;
  }

  // verified
  function bindSummoningState(address _contract) external onlyRoler("bindSummoningState") {
    summoningState = _contract;
  }

  // verified
  function bindChampionUtils(address _contract) external onlyRoler("bindChampionUtils") {
    championUtils = _contract;
  }

  // verified
  function bindZooKeeper(address _contract) external onlyRoler("bindZooKeeper") {
    zooKeeper = _contract;
  }

  // verified
  function updateVerifier(address _newAccount) external onlyRoler("updateVerifier") {
    verifier = _newAccount;
  }

  // verified
  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    uint256 amount = ISummoningState(summoningState).getPlatformShare(_currency);
    IZooKeeper(zooKeeper).transferERC20Out(
      _currency, //
      _to,
      amount
    );
    ISummoningState(summoningState).decreasePlatformShare(_currency, amount);
  }

  /* Logic */
  // verified
  function createSession(string memory _key) external onlyRoler("createSession") {
    ISummoningState(summoningState).createSession(_key);
  }

  // verified
  function paidFees(SummonTypes.SummonSessionInfo memory _sessionInfo, address _payer) internal {
    // transfer fee before update data
    uint256 _totalFee = _sessionInfo.fees.donor_amount + _sessionInfo.fees.platform_amount;

    uint256 dyFeeSize = _sessionInfo.fees.dynamic_fee_receivers.length;
    for (uint256 i; i < dyFeeSize; i++) {
      _totalFee += _sessionInfo.fees.dynamic_fee_receivers[i].amount;
    }

    require(_totalFee == _sessionInfo.fees.total_fee, "TRV: Fee mismatch");

    // paid fee
    IZooKeeper(zooKeeper).transferERC20In(
      _sessionInfo.fees.currency, //
      _payer,
      _sessionInfo.fees.total_fee
    );

    // transfer fee to donor
    IZooKeeper(zooKeeper).transferERC20Out(
      _sessionInfo.fees.currency, //
      _sessionInfo.fees.donor_receiver,
      _sessionInfo.fees.donor_amount
    );

    // fee to platform
    ISummoningState(summoningState).increasePlatformShare(_sessionInfo.fees.currency, _sessionInfo.fees.platform_amount);

    // other parties
    for (uint256 i; i < dyFeeSize; i++) {
      IZooKeeper(zooKeeper).transferERC20Out(
        _sessionInfo.fees.currency, //
        _sessionInfo.fees.dynamic_fee_receivers[i].receiver,
        _sessionInfo.fees.dynamic_fee_receivers[i].amount
      );
    }
  }

  // verified
  function updateStateInfo(SummonTypes.SummonSessionInfo memory _sessionInfo, bytes32 _key) internal returns (uint256[] memory) {
    // update timer to avoid relay attack
    ISummoningState(summoningState).tickChampionsSummoned(_sessionInfo.id, _key);

    // update total champions in session
    ISummoningState(summoningState).increaseTotalChampionsSummonedInSession(_sessionInfo.id);

    uint256[] memory _parents = new uint256[](_sessionInfo.parents.length);
    for (uint256 i; i < _sessionInfo.parents.length; i++) {
      // update total participate of champion in session
      ISummoningState(summoningState).increaseTotalParticipateInSessionByChampion(
        _sessionInfo.parents[i].champion_id, //
        _sessionInfo.id,
        _sessionInfo.summon_type
      );

      // update total participate of champion in life
      ISummoningState(summoningState).increaseTotalParticipateInLifeByChampion(
        _sessionInfo.parents[i].champion_id, //
        _sessionInfo.summon_type
      );

      // store parents
      _parents[i] = _sessionInfo.parents[i].champion_id;
    }

    return _parents;
  }

  // verified
  function summonNewChampion(
    SummonTypes.SummonSessionInfo memory _sessionInfo,
    address _owner, //
    ChampionAttributeTypes.GeneralAttributes memory _attributes,
    uint256[] memory _parents,
    bytes memory _notes
  ) internal {
    // mint champion
    uint256 newChampionId = ISummonChampion(summonChampion).getCurrentId();
    ISummonChampion(summonChampion).mintTo(_owner, string(abi.encodePacked(Strings.toString(newChampionId), ".json")));
    // create champion attributes
    uint256[] memory tokenIds = new uint256[](1);
    ChampionAttributeTypes.GeneralAttributes[] memory champAttributes = new ChampionAttributeTypes.GeneralAttributes[](1);
    tokenIds[0] = newChampionId;
    champAttributes[0] = _attributes;
    ICAState(cAState).setGeneralAttributes(tokenIds, champAttributes);
    // create lineageNode
    ISummoningState(summoningState).setLineageNode(
      newChampionId, //
      SummonTypes.LineageMetadata({
        session_id: _sessionInfo.id, //
        summon_type: _sessionInfo.summon_type,
        summoned_at: block.timestamp,
        latest_summon_time: block.timestamp
      }),
      _parents,
      getOriginalMum(_parents[1]),
      _notes
    );
  }

  // verified
  function summon(
    bytes calldata _verifySignature,
    bytes memory _signature,
    bytes memory _params
  ) public onlyRoler("summon") {
    address signer = tx.origin;

    (
      SummonTypes.SummonSessionInfo memory sessionInfo, //
      address summonOwner,
      uint256 timer,
      bytes memory notes
    ) = abi.decode(_params, (SummonTypes.SummonSessionInfo, address, uint256, bytes));

    (uint8 gifts, ChampionAttributeTypes.GeneralAttributes memory attributes) = abi.decode(notes, (uint8, ChampionAttributeTypes.GeneralAttributes));
    require(sessionInfo.parents.length == 2, "TRV: Not enough parents");
    require(sessionInfo.fees.donor_receiver == sessionInfo.parents[0].owner, "TRV: Donor mismatch");

    if (_signature.length > 0) {
      bytes memory message = abi.encodePacked(
        "Summoning ID: ", //
        Strings.toString(sessionInfo.id),
        ",",
        " Champion IDs: ",
        Strings.toString(sessionInfo.parents[0].champion_id),
        " # ",
        Strings.toString(sessionInfo.parents[1].champion_id),
        ",",
        " Timer: ",
        Strings.toString(timer)
      );
      signer = getSigner(message, _signature);
    }

    // check admin signature is ok
    require(verifier == getSigner(_params, _verifySignature), "TRV: Require verified");

    // check signature ok - gasless or not
    require(signer == summonOwner, "TRV: Signer mismatch"); // require signature match with joiner
    require(IChampionUtils(championUtils).isOriginalOwnerOf(signer, sessionInfo.parents[1].champion_id), "TRV: Require owner");
    require(IChampionUtils(championUtils).isOriginalOwnerOf(sessionInfo.parents[0].owner, sessionInfo.parents[0].champion_id), "TRV: Donor delisted");
    bytes32 key = keccak256(abi.encodePacked(Strings.toString(sessionInfo.parents[0].champion_id), " # ", Strings.toString(sessionInfo.parents[1].champion_id), " Timer: ", Strings.toString(timer)));
    require(!ISummoningState(summoningState).getChampionsSummonedTicked(sessionInfo.id, key), "TRV: Already summoned");

    // check eligible
    (bool eligible, string memory errMsg) = eligibleSummon(sessionInfo);
    require(eligible, errMsg);

    // pay fee
    paidFees(sessionInfo, signer);

    uint256[] memory _parents = updateStateInfo(sessionInfo, key);

    for (uint8 i; i < gifts; i++) {
      summonNewChampion(sessionInfo, summonOwner, attributes, _parents, notes);
    }
  }

  // verified
  function eligibleSummon(SummonTypes.SummonSessionInfo memory _sessionInfo) public view returns (bool, string memory) {
    // check if exceed max champions per session
    if (ISummoningState(summoningState).getTotalChampionsSummonedInSession(_sessionInfo.id) >= _sessionInfo.max_champions_summoned) {
      return (false, "TRV: Error 1");
    }

    for (uint256 i; i < _sessionInfo.parents.length; i++) {
      // check if exceed max per champion in session
      if (
        ISummoningState(summoningState).getTotalParticipateInSessionByChampionAndType(
          _sessionInfo.parents[i].champion_id, //
          _sessionInfo.id,
          _sessionInfo.summon_type
        ) >= _sessionInfo.parents[i].max_per_session_by_type
      ) {
        return (false, string(abi.encodePacked("TRV: Error 2 by #", Strings.toString(_sessionInfo.parents[i].champion_id))));
      }

      // check if exceed max per champion in session
      if (
        ISummoningState(summoningState).getTotalParticipateInSessionByChampion(
          _sessionInfo.parents[i].champion_id, //
          _sessionInfo.id,
          0,
          30
        ) >= _sessionInfo.parents[i].max_per_session
      ) {
        return (false, string(abi.encodePacked("TRV: Error 5 by #", Strings.toString(_sessionInfo.parents[i].champion_id))));
      }

      // check if exceed max per champion in life
      if (
        ISummoningState(summoningState).getTotalParticipateInLifeByChampion(
          _sessionInfo.parents[i].champion_id, //
          0,
          30
        ) >= _sessionInfo.parents[i].max_per_life
      ) {
        return (false, string(abi.encodePacked("TRV: Error 3 by #", Strings.toString(_sessionInfo.parents[i].champion_id))));
      }

      // check if parent summoned before
      if ((ISummoningState(summoningState).getChampionSummonedAtSession(_sessionInfo.parents[i].champion_id) + _sessionInfo.parents[i].summon_eligible_after_session) > _sessionInfo.id) {
        return (
          false,
          string(
            abi.encodePacked(
              "TRV: Error 4 by #", //
              Strings.toString(_sessionInfo.parents[i].champion_id),
              " wait for *",
              Strings.toString(_sessionInfo.parents[i].summon_eligible_after_session)
            )
          )
        );
      }
    }

    // check lineage
    if (!lineageEligible(_sessionInfo.parents[0].champion_id, _sessionInfo.parents[1].champion_id, _sessionInfo.lineage_level)) {
      return (false, "TRV: Lineage ineligible");
    }

    return (true, "");
  }

  // verified
  function lineageEligible(
    uint256 _firstChampionID,
    uint256 _secondChampionID,
    uint8 _level
  ) public view returns (bool) {
    // list ancestors
    uint256[] memory firstAncestors = getAncestors(_firstChampionID, _level, new uint256[](0));
    uint256[] memory secondAncestors = getAncestors(_secondChampionID, _level, new uint256[](0));

    // check if same at least 1 ancestor return false
    for (uint256 i; i < firstAncestors.length; i++) {
      for (uint256 j; j < secondAncestors.length; j++) {
        if (firstAncestors[i] == secondAncestors[j]) return false;
      }
    }

    return true;
  }

  function getOriginalMum(uint256 _championMumID) public view returns (uint256) {
    if (isNodeLeaf(_championMumID)) {
      return _championMumID;
    }
    SummonTypes.LineageNode memory node = ISummoningState(summoningState).getLineageNode(_championMumID);

    return node.original_mum;
  }

  // verified
  function getAncestors(
    uint256 _championID,
    uint8 _level,
    uint256[] memory _ancestors
  ) public view returns (uint256[] memory) {
    _ancestors = new uint256[](1);
    _ancestors[0] = _championID;
    if (isNodeLeaf(_championID) || _level == 0) {
      return _ancestors;
    }

    SummonTypes.LineageNode memory node = ISummoningState(summoningState).getLineageNode(_championID);
    uint256 size = node.parents.length;
    for (uint256 i; i < size; i++) {
      uint256[] memory newAncestors = getAncestors(node.parents[i], _level - 1, _ancestors);
      _ancestors = concatenateArrays(_ancestors, newAncestors);
    }
    return _ancestors;
  }

  // verified
  function concatenateArrays(uint256[] memory _first, uint256[] memory _second) public pure returns (uint256[] memory) {
    uint256 newSize = _first.length + _second.length;
    uint256[] memory output = new uint256[](newSize);

    for (uint256 j; j < _first.length; j++) {
      output[j] = _first[j];
    }

    uint256 currentIdx = _first.length;
    for (uint256 j; j < _second.length; j++) {
      output[currentIdx + j] = _second[j];
    }
    return output;
  }

  // verified
  function isNodeLeaf(uint256 _championID) public pure returns (bool) {
    if (_championID < 28000) return true;
    return false;
  }

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
pragma solidity ^0.8.16;

import "../modules/tournament_v2/interfaces/ICAState.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../modules/tournament_v2/interfaces/IZooKeeper.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IChampionUtils {
  function isOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function isOriginalOwnerOf(address _account, uint256 _championID) external view returns (bool);

  function getTokenContract(uint256 _championID) external view returns (address);

  function maxFightPerChampion() external view returns (uint256);
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
pragma solidity ^0.8.16;

import "../modules/tournament_v2/types/Types.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SummonTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ISummoningService {
  function withdrawPlatformShare(address _currency, address _to) external;

  function createSession(string memory _key) external;

  function summon(
    bytes calldata _verifySignature,
    bytes memory _signature,
    bytes memory _params
  ) external;

  function eligibleSummon(SummonTypes.SummonSessionInfo memory _sessionInfo) external view returns (bool, string memory);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// Pellar + LightLink 2022

interface ISummonChampion {
  // mint
  function mintTo(address _owner, string memory _uri) external returns (uint256);

  function getCurrentId() external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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