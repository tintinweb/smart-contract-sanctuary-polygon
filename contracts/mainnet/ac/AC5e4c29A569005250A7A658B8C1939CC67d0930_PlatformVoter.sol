// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/SafeERC20.sol";
import "../interfaces/IForwarder.sol";
import "../interfaces/IPlatformVoter.sol";
import "../interfaces/IVeTetu.sol";
import "../interfaces/IStrategyV2.sol";
import "../proxy/ControllableV3.sol";

/// @title Ve holders can vote for platform attributes values.
/// @author belbix
contract PlatformVoter is ControllableV3, IPlatformVoter {

  // *************************************************************
  //                        CONSTANTS
  // *************************************************************

  /// @dev Version of this contract. Adjust manually on each code modification.
  string public constant PLATFORM_VOTER_VERSION = "1.0.1";
  /// @dev Denominator for different ratios. It is default for the whole platform.
  uint public constant RATIO_DENOMINATOR = 100_000;
  /// @dev Delay between votes.
  uint public constant VOTE_DELAY = 1 weeks;
  /// @dev Maximum votes per veNFT
  uint public constant MAX_VOTES = 20;

  // *************************************************************
  //                        VARIABLES
  //                Keep names and ordering!
  //                 Add only in the bottom.
  // *************************************************************

  /// @dev The ve token that governs these contracts
  address public ve;

  // --- VOTES
  /// @dev veId => votes
  mapping(uint => Vote[]) public votes;
  /// @dev Attribute => Target(zero for not-strategy) => sum of votes weights
  mapping(AttributeType => mapping(address => uint)) public attributeWeights;
  /// @dev Attribute => Target(zero for not-strategy) => sum of weights multiple on values
  mapping(AttributeType => mapping(address => uint)) public attributeValues;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event AttributeChanged(uint _type, uint value);
  event Voted(
    uint tokenId,
    uint _type,
    uint value,
    address target,
    uint veWeight,
    uint veWeightedValue,
    uint totalAttributeWeight,
    uint totalAttributeValue,
    uint newValue
  );
  event VoteReset(
    uint tokenId,
    uint _type,
    address target,
    uint weight,
    uint weightedValue,
    uint timestamp
  );
  event VoteRemoved(uint tokenId, uint _type, uint newValue, address target);

  // *************************************************************
  //                        INIT
  // *************************************************************

  /// @dev Proxy initialization. Call it after contract deploy.
  function init(address controller_, address _ve) external initializer {
    __Controllable_init(controller_);
    _requireInterface(_ve, InterfaceIds.I_VE_TETU);
    ve = _ve;
  }

  // *************************************************************
  //                        VIEWS
  // *************************************************************

  /// @dev Array of votes. Safe to return the whole array until we have MAX_VOTES restriction.
  function veVotes(uint veId) external view returns (Vote[] memory) {
    return votes[veId];
  }

  /// @dev Length of votes array for given id
  function veVotesLength(uint veId) external view override returns (uint) {
    return votes[veId].length;
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_PLATFORM_VOTER || super.supportsInterface(interfaceId);
  }

  function isVotesExist(uint veId) external view override returns (bool) {
    return votes[veId].length > 0;
  }

  // *************************************************************
  //                        VOTES
  // *************************************************************

  /// @dev Resubmit exist votes for given token.
  ///      Need to call it for ve that did not renew votes too long.
  function poke(uint tokenId) external {
    Vote[] memory _votes = votes[tokenId];
    for (uint i; i < _votes.length; ++i) {
      Vote memory v = _votes[i];
      _vote(tokenId, v._type, v.weightedValue / v.weight, v.target);
    }
  }

  /// @dev Vote for multiple attributes in one call.
  function voteBatch(
    uint tokenId,
    AttributeType[] memory types,
    uint[] memory values,
    address[] memory targets
  ) external {
    require(IVeTetu(ve).isApprovedOrOwner(msg.sender, tokenId), "!owner");
    for (uint i; i < types.length; ++i) {
      _vote(tokenId, types[i], values[i], targets[i]);
    }
  }

  /// @dev Vote for given parameter using a vote power of given tokenId. Reset previous vote.
  function vote(uint tokenId, AttributeType _type, uint value, address target) external {
    require(IVeTetu(ve).isApprovedOrOwner(msg.sender, tokenId), "!owner");
    _vote(tokenId, _type, value, target);
  }

  function _vote(uint tokenId, AttributeType _type, uint value, address target) internal {
    require(value <= RATIO_DENOMINATOR, "!value");

    // load maps for reduce gas usage
    mapping(address => uint) storage _attributeWeights = attributeWeights[_type];
    mapping(address => uint) storage _attributeValues = attributeValues[_type];
    Vote[] storage _votes = votes[tokenId];

    uint totalAttributeWeight;
    uint totalAttributeValue;

    //remove votes optimised
    {
      uint oldVeWeight;
      uint oldVeValue;

      uint length = _votes.length;
      if (length != 0) {
        uint i;
        bool found;
        for (; i < length; ++i) {
          Vote memory v = _votes[i];
          if (v._type == _type && v.target == target) {
            require(v.timestamp + VOTE_DELAY < block.timestamp, "delay");
            oldVeWeight = v.weight;
            oldVeValue = v.weightedValue;
            found = true;
            break;
          }
        }
        if (found) {
          if (i != length - 1) {
            _votes[i] = _votes[length - 1];
          }
          _votes.pop();
        } else {
          // it is a new type of vote
          // need to check MAX votes in this case
          require(length < MAX_VOTES, "max");
        }
      }

      totalAttributeWeight = _attributeWeights[target] - oldVeWeight;
      totalAttributeValue = _attributeValues[target] - oldVeValue;
    }

    // get new values for ve
    uint veWeight = IVeTetu(ve).balanceOfNFT(tokenId);
    uint veWeightedValue = veWeight * value;

    if (veWeight != 0) {

      // add ve values to total values
      totalAttributeWeight += veWeight;
      totalAttributeValue += veWeightedValue;

      // store new total values
      _attributeWeights[target] = totalAttributeWeight;
      _attributeValues[target] = totalAttributeValue;

      // set new attribute value
      _setAttribute(_type, totalAttributeValue / totalAttributeWeight, target);

      // write attachments
      _votes.push(Vote(_type, target, veWeight, veWeightedValue, block.timestamp));

      emit Voted(
        tokenId,
        uint(_type),
        value,
        target,
        veWeight,
        veWeightedValue,
        totalAttributeWeight,
        totalAttributeValue,
        totalAttributeValue / totalAttributeWeight
      );
    }
  }

  /// @dev Change attribute value for given type.
  function _setAttribute(AttributeType _type, uint newValue, address target) internal {
    if (_type == AttributeType.INVEST_FUND_RATIO) {
      require(target == address(0), "!target");
      IForwarder(IController(controller()).forwarder()).setInvestFundRatio(newValue);
    } else if (_type == AttributeType.GAUGE_RATIO) {
      require(target == address(0), "!target");
      IForwarder(IController(controller()).forwarder()).setGaugesRatio(newValue);
    } else if (_type == AttributeType.STRATEGY_COMPOUND) {
      // if for some reason the contract is unable to call this function we should not revert for keep poke support
      try IStrategyV2(target).setCompoundRatio(newValue) {} catch {}
    } else {
      revert("!type");
    }
    emit AttributeChanged(uint(_type), newValue);
  }

  /// @dev Remove all votes for given tokenId.
  function reset(uint tokenId, uint[] memory types, address[] memory targets) external {
    require(IVeTetu(ve).isApprovedOrOwner(msg.sender, tokenId) || msg.sender == ve, "!owner");

    Vote[] storage _votes = votes[tokenId];
    uint length = _votes.length;
    for (uint i = length; i > 0; --i) {

      Vote memory v = _votes[i - 1];
      bool found;
      for (uint j; j < types.length; ++j) {
        uint _type = types[j];
        address target = targets[j];
        if (uint(v._type) == _type && v.target == target) {
          found = true;
          break;
        }
      }

      if (found) {
        require(v.timestamp + VOTE_DELAY < block.timestamp, "delay");
        _removeVote(tokenId, v._type, v.target, v.weight, v.weightedValue);
        // with descent loop we remove one by one last elements
        _votes.pop();
        emit VoteReset(
          tokenId,
          uint(v._type),
          v.target,
          v.weight,
          v.weightedValue,
          v.timestamp
        );
      }
    }
  }

  function _removeVote(uint tokenId, AttributeType _type, address target, uint weight, uint veValue) internal {
    uint totalWeights = attributeWeights[_type][target] - weight;
    uint totalValues = attributeValues[_type][target] - veValue;
    attributeWeights[_type][target] = totalWeights;
    if (veValue != 0) {
      attributeValues[_type][target] = totalValues;
    }
    uint newValue;
    if (totalWeights != 0) {
      newValue = totalValues / totalWeights;
    }
    _setAttribute(_type, newValue, target);
    emit VoteRemoved(tokenId, uint(_type), newValue, target);
  }

  function detachTokenFromAll(uint tokenId, address) external override {
    require(msg.sender == ve, "!ve");

    Vote[] storage _votes = votes[tokenId];
    uint length = _votes.length;
    for (uint i = length; i > 0; --i) {
      Vote memory v = _votes[i - 1];
      _removeVote(tokenId, v._type, v.target, v.weight, v.weightedValue);
      _votes.pop();
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IForwarder {

  function tetu() external view returns (address);
  function tetuThreshold() external view returns (uint);

  function tokenPerDestinationLength(address destination) external view returns (uint);

  function tokenPerDestinationAt(address destination, uint i) external view returns (address);

  function amountPerDestination(address token, address destination) external view returns (uint amount);

  function registerIncome(
    address[] memory tokens,
    uint[] memory amounts,
    address vault,
    bool isDistribute
  ) external;

  function distributeAll(address destination) external;

  function distribute(address token) external;

  function setInvestFundRatio(uint value) external;

  function setGaugesRatio(uint value) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IVeVotable.sol";

interface IPlatformVoter is IVeVotable {

  enum AttributeType {
    UNKNOWN,
    INVEST_FUND_RATIO,
    GAUGE_RATIO,
    STRATEGY_COMPOUND
  }

  struct Vote {
    AttributeType _type;
    address target;
    uint weight;
    uint weightedValue;
    uint timestamp;
  }

  function veVotesLength(uint veId) external view returns (uint);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStrategyV2 {

  function NAME() external view returns (string memory);

  function strategySpecificName() external view returns (string memory);

  function PLATFORM() external view returns (string memory);

  function STRATEGY_VERSION() external view returns (string memory);

  function asset() external view returns (address);

  function splitter() external view returns (address);

  function compoundRatio() external view returns (uint);

  function totalAssets() external view returns (uint);

  /// @dev Usually, indicate that claimable rewards have reasonable amount.
  function isReadyToHardWork() external view returns (bool);

  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawAllToSplitter() external returns (uint strategyLoss);

  /// @return strategyLoss Loss should be covered from Insurance
  function withdrawToSplitter(uint amount) external returns (uint strategyLoss);

  /// @notice Stakes everything the strategy holds into the reward pool.
  /// @param amount_ Amount transferred to the strategy balance just before calling this function
  /// @param updateTotalAssetsBeforeInvest_ Recalculate total assets amount before depositing.
  ///                                       It can be false if we know exactly, that the amount is already actual.
  /// @return strategyLoss Loss should be covered from Insurance
  function investAll(
    uint amount_,
    bool updateTotalAssetsBeforeInvest_
  ) external returns (
    uint strategyLoss
  );

  function doHardWork() external returns (uint earned, uint lost);

  function setCompoundRatio(uint value) external;

  /// @notice Max amount that can be deposited to the strategy (its internal capacity), see SCB-593.
  ///         0 means no deposit is allowed at this moment
  function capacity() external view returns (uint);

  /// @notice {performanceFee}% of total profit is sent to the {performanceReceiver} before compounding
  function performanceReceiver() external view returns (address);

  /// @notice A percent of total profit that is sent to the {performanceReceiver} before compounding
  /// @dev use FEE_DENOMINATOR
  function performanceFee() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVeTetu {

  enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
  }

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
  }
  /* We cannot really do block numbers per se b/c slope is per time, not per block
  * and per block could be fairly bad b/c Ethereum changes blocktimes.
  * What we can do is to extrapolate ***At functions */

  function attachments(uint tokenId) external view returns (uint);

  function lockedAmounts(uint veId, address stakingToken) external view returns (uint);

  function lockedDerivedAmount(uint veId) external view returns (uint);

  function lockedEnd(uint veId) external view returns (uint);

//  function voted(uint tokenId) external view returns (uint);
  function isVoted(uint tokenId) external view returns (bool);

  function tokens(uint idx) external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function createLockFor(address _token, uint _value, uint _lockDuration, address _to) external returns (uint);

  function userPointEpoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

  function pointHistory(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function increaseAmount(address _token, uint _tokenId, uint _value) external;

  function attachToken(uint tokenId) external;

  function detachToken(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;

  function totalSupplyAt(uint _block) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVeVotable {

  function isVotesExist(uint veId) external view returns (bool);

  function detachTokenFromAll(uint tokenId, address owner) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for interface IDs
/// @author bogdoslav
library InterfaceIds {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant INTERFACE_IDS_LIB_VERSION = "1.0.1";

  /// default notation:
  /// bytes4 public constant I_VOTER = type(IVoter).interfaceId;

  /// As type({Interface}).interfaceId can be changed,
  /// when some functions changed at the interface,
  /// so used hardcoded interface identifiers

  bytes4 public constant I_VOTER = bytes4(keccak256("IVoter"));
  bytes4 public constant I_BRIBE = bytes4(keccak256("IBribe"));
  bytes4 public constant I_GAUGE = bytes4(keccak256("IGauge"));
  bytes4 public constant I_VE_TETU = bytes4(keccak256("IVeTetu"));
  bytes4 public constant I_SPLITTER = bytes4(keccak256("ISplitter"));
  bytes4 public constant I_FORWARDER = bytes4(keccak256("IForwarder"));
  bytes4 public constant I_MULTI_POOL = bytes4(keccak256("IMultiPool"));
  bytes4 public constant I_CONTROLLER = bytes4(keccak256("IController"));
  bytes4 public constant I_TETU_ERC165 = bytes4(keccak256("ITetuERC165"));
  bytes4 public constant I_STRATEGY_V2 = bytes4(keccak256("IStrategyV2"));
  bytes4 public constant I_STRATEGY_V3 = bytes4(keccak256("IStrategyV3"));
  bytes4 public constant I_CONTROLLABLE = bytes4(keccak256("IControllable"));
  bytes4 public constant I_TETU_VAULT_V2 = bytes4(keccak256("ITetuVaultV2"));
  bytes4 public constant I_PLATFORM_VOTER = bytes4(keccak256("IPlatformVoter"));
  bytes4 public constant I_VE_DISTRIBUTOR = bytes4(keccak256("IVeDistributor"));
  bytes4 public constant I_TETU_CONVERTER = bytes4(keccak256("ITetuConverter"));
  bytes4 public constant I_VAULT_INSURANCE = bytes4(keccak256("IVaultInsurance"));
  bytes4 public constant I_STRATEGY_STRICT = bytes4(keccak256("IStrategyStrict"));
  bytes4 public constant I_ERC4626 = bytes4(keccak256("IERC4626"));

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint256
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  /// @dev Gets a slot array by index as uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function uintAt(bytes32 slot, uint index) internal view returns (uint result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  // ************* ARRAY SETTERS *******************

  /// @dev Sets a slot array at index with address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, address value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets a slot array at index with uint
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function setAt(bytes32 slot, uint index, uint value) internal {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      sstore(pointer, value)
    }
  }

  /// @dev Sets an array length
  function setLength(bytes32 slot, uint length) internal {
    assembly {
      sstore(slot, length)
    }
  }

  /// @dev Pushes an address to the array
  function push(bytes32 slot, address value) internal {
    uint length = arrayLength(slot);
    setAt(slot, length, value);
    setLength(slot, length + 1);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  /**
   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    // Look for revert reason and bubble it up if present
    if (returndata.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
     */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity 0.8.17;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
     */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
     */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
      "Initializable: contract is already initialized"
    );
    _initialized = 1;
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
  modifier reinitializer(uint8 version) {
    require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
  modifier onlyInitializing() {
    require(_initializing, "Initializable: contract is not initializing");
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
  function _disableInitializers() internal virtual {
    require(!_initializing, "Initializable: contract is initializing");
    if (_initialized != type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Permit.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
  unchecked {
    uint256 oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint256 newAllowance = oldAllowance - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../openzeppelin/Initializable.sol";
import "../tools/TetuERC165.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/IController.sol";
import "../lib/SlotsLib.sol";
import "../lib/InterfaceIds.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract ControllableV3 is Initializable, TetuERC165, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "3.0.1";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint256(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint256(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint256(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  /// @dev Prevent implementation init
  constructor() {
    _disableInitializers();
  }

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) internal onlyInitializing {
    require(controller_ != address(0), "Zero controller");
    _requireInterface(controller_, InterfaceIds.I_CONTROLLER);
    require(IController(controller_).governance() != address(0), "Zero governance");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) public override view returns (bool) {
    return _value == controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) public override view returns (bool) {
    return IController(controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  /// @dev See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_CONTROLLABLE || super.supportsInterface(interfaceId);
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() public view override returns (address) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint256) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint256) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    require(msg.sender == address(this), "Increase revision forbidden");
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

  /// @dev Gets a slot as bytes32
  function getSlot(uint slot) external view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../openzeppelin/ERC165.sol";
import "../interfaces/IERC20.sol";
import "../lib/InterfaceIds.sol";

/// @dev Tetu Implementation of the {IERC165} interface extended with helper functions.
/// @author bogdoslav
abstract contract TetuERC165 is ERC165 {

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == InterfaceIds.I_TETU_ERC165 || super.supportsInterface(interfaceId);
  }

  // *************************************************************
  //                        HELPER FUNCTIONS
  // *************************************************************
  /// @author bogdoslav

  /// @dev Checks what interface with id is supported by contract.
  /// @return bool. Do not throws
  function _isInterfaceSupported(address contractAddress, bytes4 interfaceId) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    try IERC165(contractAddress).supportsInterface(interfaceId) returns (bool isSupported) {
      return isSupported;
    } catch {
    }
    return false;
  }

  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireInterface(address contractAddress, bytes4 interfaceId) internal view {
    require(_isInterfaceSupported(contractAddress, interfaceId), "Interface is not supported");
  }

  /// @dev Checks what address is ERC20.
  /// @return bool. Do not throws
  function _isERC20(address contractAddress) internal view returns (bool) {
    require(contractAddress != address(0), "Zero address");
    // check what address is contract
    uint codeSize;
    assembly {
      codeSize := extcodesize(contractAddress)
    }
    if (codeSize == 0) return false;

    bool totalSupplySupported;
    try IERC20(contractAddress).totalSupply() returns (uint) {
      totalSupplySupported = true;
    } catch {
    }

    bool balanceSupported;
    try IERC20(contractAddress).balanceOf(address(this)) returns (uint) {
      balanceSupported = true;
    } catch {
    }

    return totalSupplySupported && balanceSupported;
  }


  /// @dev Checks what interface with id is supported by contract and reverts otherwise
  function _requireERC20(address contractAddress) internal view {
    require(_isERC20(contractAddress), "Not ERC20");
  }
}