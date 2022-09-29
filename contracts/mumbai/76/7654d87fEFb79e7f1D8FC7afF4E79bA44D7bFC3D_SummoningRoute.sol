// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Base } from "../../../common/Base.sol";
import { SummonTypes } from "../types/Types.sol";
import { ISummoningRoute } from "../interfaces/ISummoningRoute.sol";
import { ISummoningService } from "../interfaces/ISummoningService.sol";

// Pellar + LightLink 2022

contract SummoningRoute is Base, ISummoningRoute {
  address public summoningService;

  function bindService(address _contract) external onlyRoler("bindService") {
    require(_contract != address(0), "Must set non-zero address");
    summoningService = _contract;
  }

  function withdrawPlatformShare(address _currency, address _to) external onlyRoler("withdrawPlatformShare") {
    ISummoningService(summoningService).withdrawPlatformShare(_currency, _to);
  }

  function createSession(string memory _key) external onlyRoler("createSession") {
    ISummoningService(summoningService).createSession(_key);
  }

  function summon(
    bytes memory _verifySignature,
    bytes memory _signature,
    bytes memory _params
  ) public {
    require(summoningService != address(0), "Non-exists service");
    ISummoningService(summoningService).summon(_verifySignature, _signature, _params);
  }

  function batchSummon(
    bytes[] memory _verifySignatures,
    bytes[] memory _signatures,
    bytes[] memory _params
  ) public {
    require(_params.length != _signatures.length, "Input mismatch");
    for (uint256 i = 0; i < _params.length; i++) {
      summon(_verifySignatures[i], _signatures[i], _params[i]);
    }
  }

  function eligibleSummon(SummonTypes.SummonSessionInfo memory _sessionInfo) public view returns (bool, string memory) {
    return ISummoningService(summoningService).eligibleSummon(_sessionInfo);
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

interface ISummoningRoute {
  // bind service processing summon
  function bindService(address _service) external;

  function withdrawPlatformShare(address _currency, address _to) external;

  // summon
  function createSession(string memory _key) external;

  function summon(
    bytes memory _verifySignature,
    bytes memory _signature,
    bytes memory _params
  ) external;

  // batch summon
  function batchSummon(
    bytes[] memory _verifySignatures,
    bytes[] memory _signatures,
    bytes[] memory _params
  ) external;

  function eligibleSummon(SummonTypes.SummonSessionInfo memory _sessionInfo) external view returns (bool, string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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