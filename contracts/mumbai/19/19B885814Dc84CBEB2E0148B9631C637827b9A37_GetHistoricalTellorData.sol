// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IValueProvider {
  function getIndexValue() external view returns (uint256);
}

// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later
pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../vendor/tellor/UsingTellor.sol";
import "../interfaces/IValueProvider.sol";

struct Datum {
  uint256 timestamp;
  uint256 value;
}

contract GetHistoricalTellorData is UsingTellor {
  constructor(address payable _tellorAddress) UsingTellor(_tellorAddress) {}

  function bytesToBytes32(bytes memory _bytes) public pure returns (bytes32) {
    uint256 bytesLength = _bytes.length;

    if (bytesLength == 32) {
      return bytes32(_bytes);
    }

    if (bytesLength > 32) {
      revert("Bytes array exceeds max length");
    }

    uint256 padLength = 32 - bytesLength;

    bytes memory _temp = new bytes(32);

    for (uint256 i = 0; i < 32; i++) {
      _temp[i] = i < padLength ? bytes1(0) : _bytes[i - padLength];
    }

    return bytes32(_temp);
  }

  function get7DayData(bytes32 _queryId)
    external
    view
    returns (Datum[] memory)
  {
    uint256 dataPoints = 7 * 24;
    Datum[] memory values = new Datum[](dataPoints);
    uint256 initialTime = block.timestamp - 1 hours;

    for (uint256 i = 0; i < dataPoints; i++) {
      uint256 timestamp = initialTime - (i * 1 hours);

      (bytes memory _value, ) = getDataBefore(_queryId, timestamp);

      bytes32 bytes32value = bytesToBytes32(_value);

      Datum memory datum = Datum(timestamp, uint256(bytes32value));

      values[dataPoints - i - 1] = datum;
    }

    return values;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev EIP2362 Interface for pull oracles
 * https://github.com/tellor-io/EIP-2362
 */
interface IERC2362 {
  /**
   * @dev Exposed function pertaining to EIP standards
   * @param _id bytes32 ID of the query
   * @return int,uint,uint returns the value, timestamp, and status code of query
   */
  function valueFor(bytes32 _id)
    external
    view
    returns (
      int256,
      uint256,
      uint256
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMappingContract {
  function getTellorID(bytes32 _id) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITellor {
  //Controller
  function addresses(bytes32) external view returns (address);

  function uints(bytes32) external view returns (uint256);

  function burn(uint256 _amount) external;

  function changeDeity(address _newDeity) external;

  function changeOwner(address _newOwner) external;

  function changeUint(bytes32 _target, uint256 _amount) external;

  function migrate() external;

  function mint(address _reciever, uint256 _amount) external;

  function init() external;

  function getAllDisputeVars(uint256 _disputeId)
    external
    view
    returns (
      bytes32,
      bool,
      bool,
      bool,
      address,
      address,
      address,
      uint256[9] memory,
      int256
    );

  function getDisputeIdByDisputeHash(bytes32 _hash)
    external
    view
    returns (uint256);

  function getDisputeUintVars(uint256 _disputeId, bytes32 _data)
    external
    view
    returns (uint256);

  function getLastNewValueById(uint256 _requestId)
    external
    view
    returns (uint256, bool);

  function retrieveData(uint256 _requestId, uint256 _timestamp)
    external
    view
    returns (uint256);

  function getNewValueCountbyRequestId(uint256 _requestId)
    external
    view
    returns (uint256);

  function getAddressVars(bytes32 _data) external view returns (address);

  function getUintVar(bytes32 _data) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function isMigrated(address _addy) external view returns (bool);

  function allowance(address _user, address _spender)
    external
    view
    returns (uint256);

  function allowedToTrade(address _user, uint256 _amount)
    external
    view
    returns (bool);

  function approve(address _spender, uint256 _amount) external returns (bool);

  function approveAndTransferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external returns (bool);

  function balanceOf(address _user) external view returns (uint256);

  function balanceOfAt(address _user, uint256 _blockNumber)
    external
    view
    returns (uint256);

  function transfer(address _to, uint256 _amount)
    external
    returns (bool success);

  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) external returns (bool success);

  function depositStake() external;

  function requestStakingWithdraw() external;

  function withdrawStake() external;

  function changeStakingStatus(address _reporter, uint256 _status) external;

  function slashReporter(address _reporter, address _disputer) external;

  function getStakerInfo(address _staker)
    external
    view
    returns (uint256, uint256);

  function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
    external
    view
    returns (uint256);

  function getNewCurrentVariables()
    external
    view
    returns (
      bytes32 _c,
      uint256[5] memory _r,
      uint256 _d,
      uint256 _t
    );

  function getNewValueCountbyQueryId(bytes32 _queryId)
    external
    view
    returns (uint256);

  function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
    external
    view
    returns (uint256);

  function retrieveData(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (bytes memory);

  //Governance
  enum VoteResult {
    FAILED,
    PASSED,
    INVALID
  }

  function setApprovedFunction(bytes4 _func, bool _val) external;

  function beginDispute(bytes32 _queryId, uint256 _timestamp) external;

  function delegate(address _delegate) external;

  function delegateOfAt(address _user, uint256 _blockNumber)
    external
    view
    returns (address);

  function executeVote(uint256 _disputeId) external;

  function proposeVote(
    address _contract,
    bytes4 _function,
    bytes calldata _data,
    uint256 _timestamp
  ) external;

  function tallyVotes(uint256 _disputeId) external;

  function governance() external view returns (address);

  function updateMinDisputeFee() external;

  function verify() external pure returns (uint256);

  function vote(
    uint256 _disputeId,
    bool _supports,
    bool _invalidQuery
  ) external;

  function voteFor(
    address[] calldata _addys,
    uint256 _disputeId,
    bool _supports,
    bool _invalidQuery
  ) external;

  function getDelegateInfo(address _holder)
    external
    view
    returns (address, uint256);

  function isFunctionApproved(bytes4 _func) external view returns (bool);

  function isApprovedGovernanceContract(address _contract)
    external
    returns (bool);

  function getVoteRounds(bytes32 _hash)
    external
    view
    returns (uint256[] memory);

  function getVoteCount() external view returns (uint256);

  function getVoteInfo(uint256 _disputeId)
    external
    view
    returns (
      bytes32,
      uint256[9] memory,
      bool[2] memory,
      VoteResult,
      bytes memory,
      bytes4,
      address[2] memory
    );

  function getDisputeInfo(uint256 _disputeId)
    external
    view
    returns (
      uint256,
      uint256,
      bytes memory,
      address
    );

  function getOpenDisputesOnId(bytes32 _queryId)
    external
    view
    returns (uint256);

  function didVote(uint256 _disputeId, address _voter)
    external
    view
    returns (bool);

  //Oracle
  function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
    external
    view
    returns (uint256);

  function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (bytes memory);

  function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (uint256);

  function getReportingLock() external view returns (uint256);

  function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (address);

  function reportingLock() external view returns (uint256);

  function removeValue(bytes32 _queryId, uint256 _timestamp) external;

  function getTipsByUser(address _user) external view returns (uint256);

  function tipQuery(
    bytes32 _queryId,
    uint256 _tip,
    bytes memory _queryData
  ) external;

  function submitValue(
    bytes32 _queryId,
    bytes calldata _value,
    uint256 _nonce,
    bytes memory _queryData
  ) external;

  function burnTips() external;

  function changeReportingLock(uint256 _newReportingLock) external;

  function getReportsSubmittedByAddress(address _reporter)
    external
    view
    returns (uint256);

  function changeTimeBasedReward(uint256 _newTimeBasedReward) external;

  function getReporterLastTimestamp(address _reporter)
    external
    view
    returns (uint256);

  function getTipsById(bytes32 _queryId) external view returns (uint256);

  function getTimeBasedReward() external view returns (uint256);

  function getTimestampCountById(bytes32 _queryId)
    external
    view
    returns (uint256);

  function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (uint256);

  function getCurrentReward(bytes32 _queryId)
    external
    view
    returns (uint256, uint256);

  function getCurrentValue(bytes32 _queryId)
    external
    view
    returns (bytes memory);

  function getDataBefore(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (
      bool _ifRetrieve,
      bytes memory _value,
      uint256 _timestampRetrieved
    );

  function getTimeOfLastNewValue() external view returns (uint256);

  function depositStake(uint256 _amount) external;

  function requestStakingWithdraw(uint256 _amount) external;

  //Test functions
  function changeAddressVar(bytes32 _id, address _addy) external;

  //parachute functions
  function killContract() external;

  function migrateFor(address _destination, uint256 _amount) external;

  function rescue51PercentAttack(address _tokenHolder) external;

  function rescueBrokenDataReporting() external;

  function rescueFailedUpdate() external;

  //Tellor 360
  function addStakingRewards(uint256 _amount) external;

  function _sliceUint(bytes memory _b) external pure returns (uint256 _number);

  function claimOneTimeTip(bytes32 _queryId, uint256[] memory _timestamps)
    external;

  function claimTip(
    bytes32 _feedId,
    bytes32 _queryId,
    uint256[] memory _timestamps
  ) external;

  function fee() external view returns (uint256);

  function feedsWithFunding(uint256) external view returns (bytes32);

  function fundFeed(
    bytes32 _feedId,
    bytes32 _queryId,
    uint256 _amount
  ) external;

  function getCurrentFeeds(bytes32 _queryId)
    external
    view
    returns (bytes32[] memory);

  function getCurrentTip(bytes32 _queryId) external view returns (uint256);

  function getDataAfter(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (bytes memory _value, uint256 _timestampRetrieved);

  function getDataFeed(bytes32 _feedId)
    external
    view
    returns (Autopay.FeedDetails memory);

  function getFundedFeeds() external view returns (bytes32[] memory);

  function getFundedQueryIds() external view returns (bytes32[] memory);

  function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (bool _found, uint256 _index);

  function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (bool _found, uint256 _index);

  function getMultipleValuesBefore(
    bytes32 _queryId,
    uint256 _timestamp,
    uint256 _maxAge,
    uint256 _maxCount
  )
    external
    view
    returns (uint256[] memory _values, uint256[] memory _timestamps);

  function getPastTipByIndex(bytes32 _queryId, uint256 _index)
    external
    view
    returns (Autopay.Tip memory);

  function getPastTipCount(bytes32 _queryId) external view returns (uint256);

  function getPastTips(bytes32 _queryId)
    external
    view
    returns (Autopay.Tip[] memory);

  function getQueryIdFromFeedId(bytes32 _feedId)
    external
    view
    returns (bytes32);

  function getRewardAmount(
    bytes32 _feedId,
    bytes32 _queryId,
    uint256[] memory _timestamps
  ) external view returns (uint256 _cumulativeReward);

  function getRewardClaimedStatus(
    bytes32 _feedId,
    bytes32 _queryId,
    uint256 _timestamp
  ) external view returns (bool);

  function getTipsByAddress(address _user) external view returns (uint256);

  function isInDispute(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (bool);

  function queryIdFromDataFeedId(bytes32) external view returns (bytes32);

  function queryIdsWithFunding(uint256) external view returns (bytes32);

  function queryIdsWithFundingIndex(bytes32) external view returns (uint256);

  function setupDataFeed(
    bytes32 _queryId,
    uint256 _reward,
    uint256 _startTime,
    uint256 _interval,
    uint256 _window,
    uint256 _priceThreshold,
    uint256 _rewardIncreasePerSecond,
    bytes memory _queryData,
    uint256 _amount
  ) external;

  function tellor() external view returns (address);

  function tip(
    bytes32 _queryId,
    uint256 _amount,
    bytes memory _queryData
  ) external;

  function tips(bytes32, uint256)
    external
    view
    returns (uint256 amount, uint256 timestamp);

  function token() external view returns (address);

  function userTipsTotal(address) external view returns (uint256);

  function valueFor(bytes32 _id)
    external
    view
    returns (
      int256 _value,
      uint256 _timestamp,
      uint256 _statusCode
    );
}

interface Autopay {
  struct FeedDetails {
    uint256 reward;
    uint256 balance;
    uint256 startTime;
    uint256 interval;
    uint256 window;
    uint256 priceThreshold;
    uint256 rewardIncreasePerSecond;
    uint256 feedsWithFundingIndex;
  }

  struct Tip {
    uint256 amount;
    uint256 timestamp;
  }

  function getStakeAmount() external view returns (uint256);

  function stakeAmount() external view returns (uint256);

  function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./iface/ITellor.sol";
import "./iface/IERC2362.sol";
import "./iface/IMappingContract.sol";

/**
 @author Tellor Inc
 @title UsingTellor
 @dev This contract helps smart contracts read data from Tellor
 */
contract UsingTellor is IERC2362 {
  ITellor public tellor;
  IMappingContract public idMappingContract;

  /*Constructor*/
  /**
   * @dev the constructor sets the oracle address in storage
   * @param _tellor is the Tellor Oracle address
   */
  constructor(address payable _tellor) {
    tellor = ITellor(_tellor);
  }

  /*Getters*/
  /**
   * @dev Retrieves the next value for the queryId after the specified timestamp
   * @param _queryId is the queryId to look up the value for
   * @param _timestamp after which to search for next value
   * @return _value the value retrieved
   * @return _timestampRetrieved the value's timestamp
   */
  function getDataAfter(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bytes memory _value, uint256 _timestampRetrieved)
  {
    (bool _found, uint256 _index) = getIndexForDataAfter(_queryId, _timestamp);
    if (!_found) {
      return ("", 0);
    }
    _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _index);
    _value = retrieveData(_queryId, _timestampRetrieved);
    return (_value, _timestampRetrieved);
  }

  /**
   * @dev Retrieves the latest value for the queryId before the specified timestamp
   * @param _queryId is the queryId to look up the value for
   * @param _timestamp before which to search for latest value
   * @return _value the value retrieved
   * @return _timestampRetrieved the value's timestamp
   */
  function getDataBefore(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bytes memory _value, uint256 _timestampRetrieved)
  {
    (, _value, _timestampRetrieved) = tellor.getDataBefore(
      _queryId,
      _timestamp
    );
  }

  /**
   * @dev Retrieves next array index of data after the specified timestamp for the queryId
   * @param _queryId is the queryId to look up the index for
   * @param _timestamp is the timestamp after which to search for the next index
   * @return _found whether the index was found
   * @return _index the next index found after the specified timestamp
   */
  function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bool _found, uint256 _index)
  {
    (_found, _index) = tellor.getIndexForDataBefore(_queryId, _timestamp);
    if (_found) {
      _index++;
    }
    uint256 _valCount = tellor.getNewValueCountbyQueryId(_queryId);
    // no value after timestamp
    if (_valCount <= _index) {
      return (false, 0);
    }
    uint256 _timestampRetrieved = tellor.getTimestampbyQueryIdandIndex(
      _queryId,
      _index
    );
    if (_timestampRetrieved > _timestamp) {
      return (true, _index);
    }
    // if _timestampRetrieved equals _timestamp, try next value
    _index++;
    // no value after timestamp
    if (_valCount <= _index) {
      return (false, 0);
    }
    _timestampRetrieved = tellor.getTimestampbyQueryIdandIndex(
      _queryId,
      _index
    );
    return (true, _index);
  }

  /**
   * @dev Retrieves latest array index of data before the specified timestamp for the queryId
   * @param _queryId is the queryId to look up the index for
   * @param _timestamp is the timestamp before which to search for the latest index
   * @return _found whether the index was found
   * @return _index the latest index found before the specified timestamp
   */
  // slither-disable-next-line calls-loop
  function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bool _found, uint256 _index)
  {
    return tellor.getIndexForDataBefore(_queryId, _timestamp);
  }

  /**
   * @dev Retrieves multiple uint256 values before the specified timestamp
   * @param _queryId the unique id of the data query
   * @param _timestamp the timestamp before which to search for values
   * @param _maxAge the maximum number of seconds before the _timestamp to search for values
   * @param _maxCount the maximum number of values to return
   * @return _values the values retrieved, ordered from oldest to newest
   * @return _timestamps the timestamps of the values retrieved
   */
  function getMultipleValuesBefore(
    bytes32 _queryId,
    uint256 _timestamp,
    uint256 _maxAge,
    uint256 _maxCount
  ) public view returns (bytes[] memory _values, uint256[] memory _timestamps) {
    (bool _ifRetrieve, uint256 _startIndex) = getIndexForDataAfter(
      _queryId,
      _timestamp - _maxAge
    );
    // no value within range
    if (!_ifRetrieve) {
      return (new bytes[](0), new uint256[](0));
    }
    uint256 _endIndex;
    (_ifRetrieve, _endIndex) = getIndexForDataBefore(_queryId, _timestamp);
    // no value before _timestamp
    if (!_ifRetrieve) {
      return (new bytes[](0), new uint256[](0));
    }
    uint256 _valCount = _endIndex - _startIndex + 1;
    // more than _maxCount values found within range
    if (_valCount > _maxCount) {
      _startIndex = _endIndex - _maxCount + 1;
      _valCount = _maxCount;
    }
    bytes[] memory _valuesArray = new bytes[](_valCount);
    uint256[] memory _timestampsArray = new uint256[](_valCount);
    bytes memory _valueRetrieved;
    for (uint256 _i = 0; _i < _valCount; _i++) {
      _timestampsArray[_i] = getTimestampbyQueryIdandIndex(
        _queryId,
        (_startIndex + _i)
      );
      _valueRetrieved = retrieveData(_queryId, _timestampsArray[_i]);
      _valuesArray[_i] = _valueRetrieved;
    }
    return (_valuesArray, _timestampsArray);
  }

  /**
   * @dev Counts the number of values that have been submitted for the queryId
   * @param _queryId the id to look up
   * @return uint256 count of the number of values received for the queryId
   */
  function getNewValueCountbyQueryId(bytes32 _queryId)
    public
    view
    returns (uint256)
  {
    return tellor.getNewValueCountbyQueryId(_queryId);
  }

  /**
   * @dev Returns the address of the reporter who submitted a value for a data ID at a specific time
   * @param _queryId is ID of the specific data feed
   * @param _timestamp is the timestamp to find a corresponding reporter for
   * @return address of the reporter who reported the value for the data ID at the given timestamp
   */
  function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (address)
  {
    return tellor.getReporterByTimestamp(_queryId, _timestamp);
  }

  /**
   * @dev Gets the timestamp for the value based on their index
   * @param _queryId is the id to look up
   * @param _index is the value index to look up
   * @return uint256 timestamp
   */
  function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
    public
    view
    returns (uint256)
  {
    return tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
  }

  /**
   * @dev Determines whether a value with a given queryId and timestamp has been disputed
   * @param _queryId is the value id to look up
   * @param _timestamp is the timestamp of the value to look up
   * @return bool true if queryId/timestamp is under dispute
   */
  function isInDispute(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bool)
  {
    return tellor.isInDispute(_queryId, _timestamp);
  }

  /**
   * @dev Retrieve value from oracle based on queryId/timestamp
   * @param _queryId being requested
   * @param _timestamp to retrieve data/value from
   * @return bytes value for query/timestamp submitted
   */
  function retrieveData(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bytes memory)
  {
    return tellor.retrieveData(_queryId, _timestamp);
  }

  /**
   * @dev allows dev to set mapping contract for valueFor (EIP2362)
   * @param _addy address of mapping contract
   */
  function setIdMappingContract(address _addy) external {
    require(address(idMappingContract) == address(0));
    idMappingContract = IMappingContract(_addy);
  }

  /**
   * @dev Retrieve most recent int256 value from oracle based on queryId
   * @param _id being requested
   * @return _value most recent value submitted
   * @return _timestamp timestamp of most recent value
   * @return _statusCode 200 if value found, 404 if not found
   */
  function valueFor(bytes32 _id)
    external
    view
    override
    returns (
      int256 _value,
      uint256 _timestamp,
      uint256 _statusCode
    )
  {
    _id = idMappingContract.getTellorID(_id);
    uint256 _count = getNewValueCountbyQueryId(_id);
    if (_count == 0) {
      return (0, 0, 404);
    }
    _timestamp = getTimestampbyQueryIdandIndex(_id, _count - 1);
    bytes memory _valueBytes = retrieveData(_id, _timestamp);
    if (_valueBytes.length == 0) {
      return (0, 0, 404);
    }
    uint256 _valueUint = _sliceUint(_valueBytes);
    _value = int256(_valueUint);
    return (_value, _timestamp, 200);
  }

  // Internal functions
  /**
   * @dev Convert bytes to uint256
   * @param _b bytes value to convert to uint256
   * @return _number uint256 converted from bytes
   */
  function _sliceUint(bytes memory _b) internal pure returns (uint256 _number) {
    for (uint256 _i = 0; _i < _b.length; _i++) {
      _number = _number * 256 + uint8(_b[_i]);
    }
  }
}