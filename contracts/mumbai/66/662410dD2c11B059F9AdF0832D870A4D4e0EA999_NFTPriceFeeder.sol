// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "usingtellor/contracts/UsingTellor.sol";
import "usingtellor/contracts/TellorPlayground.sol";
import "usingtellor/contracts/interface/ITellor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

string constant DATA_SPEC_NAME = "MimicryCollectionStat";

struct FeedQuery {
  uint256 chainId;
  address collectionAddress;
  uint256 metric;
}

error OnlyOwner();
error FeedQueryNotFound();
error MinimumTRBNotMet();
error InsufficientAllowance();

contract NFTPriceFeeder is UsingTellor {
  address owner;

  mapping(bytes32 => bool) existingQueryIdMap;
  FeedQuery[] public feedQueries;

  uint256 minCreateFeedTRBAmount = 1 ether;

  ITellor autopay;
  TellorPlayground playground;

  event FeedCreated(
    bytes32 feedId,
    uint256 chainId,
    address collectionAddress,
    uint256 metric,
    uint256 amount,
    uint256 createdAt,
    address createdBy
  );
  event FeedFunded(
    bytes32 feedId,
    uint256 chainId,
    address collectionAddress,
    uint256 metric,
    uint256 amount,
    uint256 fundedAt,
    address fundedBy
  );

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert OnlyOwner();
    }
    _;
  }

  constructor(
    address payable _tellorAddress,
    address _autopayAddress,
    address _playgroundAddress
  ) UsingTellor(_tellorAddress) {
    owner = msg.sender;
    autopay = ITellor(_autopayAddress);
    playground = TellorPlayground(_playgroundAddress);
  }

  function setMinCreateFeedTRBAmount(uint256 _amount) external onlyOwner {
    minCreateFeedTRBAmount = _amount;
  }

  function createFeed(
    uint256 _chainId,
    address _collectionAddress,
    uint256 _metric,
    uint256 _trbReward,
    uint256 _rewardIncreasePerSecond,
    uint256 _autopayInterval,
    uint256 _window,
    uint256 _priceVariabilityThreshold,
    uint256 _amount
  ) external {
    if (_amount < minCreateFeedTRBAmount) {
      revert MinimumTRBNotMet();
    }

    if (
      IERC20(autopay.token()).allowance(msg.sender, address(this)) < _amount
    ) {
      revert InsufficientAllowance();
    }

    IERC20(autopay.token()).transferFrom(msg.sender, address(this), _amount);
    IERC20(autopay.token()).approve(address(autopay), _amount);

    (bytes memory _queryData, bytes32 _queryId) = _buildQuery(
      _chainId,
      _collectionAddress,
      _metric
    );

    // If we don't have an entry for this query in the mapping, add it
    if (existingQueryIdMap[_queryId] == false) {
      existingQueryIdMap[_queryId] = true;

      FeedQuery memory _feedQuery = FeedQuery(
        _chainId,
        _collectionAddress,
        _metric
      );

      feedQueries.push(_feedQuery);
    }

    autopay.setupDataFeed(
      _queryId,
      _trbReward,
      block.timestamp,
      _autopayInterval,
      _window,
      _priceVariabilityThreshold,
      _rewardIncreasePerSecond,
      _queryData,
      _amount
    );

    bytes32 _feedId = keccak256(
      abi.encode(
        _queryId,
        _trbReward,
        block.timestamp,
        _autopayInterval,
        _window,
        _priceVariabilityThreshold,
        _rewardIncreasePerSecond
      )
    );

    emit FeedCreated(
      _feedId,
      _chainId,
      _collectionAddress,
      _metric,
      _amount,
      block.timestamp,
      msg.sender
    );
  }

  function fundFeed(
    uint256 _chainId,
    address _collectionAddress,
    uint256 _metric,
    bytes32 _feedId,
    uint256 _amount
  ) external {
    if (
      IERC20(autopay.token()).allowance(msg.sender, address(this)) < _amount
    ) {
      revert InsufficientAllowance();
    }

    IERC20(autopay.token()).transferFrom(msg.sender, address(this), _amount);
    IERC20(autopay.token()).approve(address(autopay), _amount);

    (, bytes32 _queryId) = _buildQuery(_chainId, _collectionAddress, _metric);

    emit FeedFunded(
      _feedId,
      _chainId,
      _collectionAddress,
      _metric,
      _amount,
      block.timestamp,
      msg.sender
    );

    autopay.fundFeed(_feedId, _queryId, _amount);
  }

  function getSpotPrice(
    uint256 _chainId,
    address _collectionAddress,
    uint256 _metric
  ) external view returns (uint256, uint256) {
    (, bytes32 _queryId) = _buildQuery(_chainId, _collectionAddress, _metric);

    if (existingQueryIdMap[_queryId] == false) {
      revert FeedQueryNotFound();
    }

    uint256 _timestamp;
    bytes memory _value;

    /// @notice This is using the playground to read values
    (, _value, _timestamp) = playground.getDataBefore(
      _queryId,
      block.timestamp - 1 hours
    );
    uint256 _decodedValue = abi.decode(_value, (uint256));

    return (_decodedValue, _timestamp);
  }

  function getFeedQueries() external view returns (FeedQuery[] memory) {
    return feedQueries;
  }

  function getFeedsForQuery(
    uint256 _chainId,
    address _collectionAddress,
    uint256 _metric
  ) public view returns (Autopay.FeedDetails[] memory) {
    (, bytes32 _queryId) = _buildQuery(_chainId, _collectionAddress, _metric);
    bytes32[] memory _feedIds = tellor.getCurrentFeeds(_queryId);
    uint256 _feedsCount = _feedIds.length;

    Autopay.FeedDetails[] memory _feedDetailsArray = new Autopay.FeedDetails[](
      _feedsCount
    );

    for (uint256 i = 0; i < _feedsCount; i++) {
      bytes32 _feedId = _feedIds[i];
      _feedDetailsArray[i] = tellor.getDataFeed(_feedId);
    }

    return _feedDetailsArray;
  }

  function getAllFeeds() external view returns (Autopay.FeedDetails[] memory) {
    uint256 _feedCount = _getCountOfFeeds();

    Autopay.FeedDetails[] memory _allFeeds = new Autopay.FeedDetails[](
      _feedCount
    );

    uint256 _allFeedsIndex = 0;

    for (uint256 i = 0; i < feedQueries.length; i++) {
      Autopay.FeedDetails[] memory _feedsForQuery = getFeedsForQuery(
        feedQueries[i].chainId,
        feedQueries[i].collectionAddress,
        feedQueries[i].metric
      );

      for (uint256 j = 0; j < _feedsForQuery.length; j++) {
        _allFeeds[_allFeedsIndex] = _feedsForQuery[j];
        _allFeedsIndex += 1;
      }
    }

    return _allFeeds;
  }

  function _getCountOfFeeds() internal view returns (uint256) {
    uint256 _feedCount = 0;

    for (uint256 i = 0; i < feedQueries.length; i++) {
      Autopay.FeedDetails[] memory _feeds = getFeedsForQuery(
        feedQueries[i].chainId,
        feedQueries[i].collectionAddress,
        feedQueries[i].metric
      );

      _feedCount += _feeds.length;
    }

    return _feedCount;
  }

  function _buildQuery(
    uint256 _chainId,
    address _collectionAddress,
    uint256 _metric
  ) internal pure returns (bytes memory, bytes32) {
    bytes memory _queryData = abi.encode(
      DATA_SPEC_NAME,
      abi.encode(_chainId, _collectionAddress, _metric)
    );
    bytes32 _queryId = keccak256(_queryData);
    return (_queryData, _queryId);
  }

  function _mockWriteToPlayground(
    bytes32 _queryId,
    bytes calldata _value,
    uint256 _nonce,
    bytes memory _queryData
  ) external {
    playground.submitValue(_queryId, _value, _nonce, _queryData);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
    * @dev EIP2362 Interface for pull oracles
    * https://github.com/tellor-io/EIP-2362
*/
interface IERC2362
{
	/**
	 * @dev Exposed function pertaining to EIP standards
	 * @param _id bytes32 ID of the query
	 * @return int,uint,uint returns the value, timestamp, and status code of query
	 */
	function valueFor(bytes32 _id) external view returns(int256,uint256,uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMappingContract{
    function getTellorID(bytes32 _id) external view returns(bytes32);
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
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;

    function changeReportingLock(uint256 _newReportingLock) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getDataBefore(bytes32 _queryId, uint256 _timestamp) external view returns(bool _ifRetrieve, bytes memory _value, uint256 _timestampRetrieved);
    function getTimeOfLastNewValue() external view returns(uint256);
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

    function _sliceUint(bytes memory _b)
        external
        pure
        returns (uint256 _number);

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
    function getStakeAmount() external view returns(uint256);
    function stakeAmount() external view returns(uint256);
    function token() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TellorPlayground {
    // Events
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event NewReport(
        bytes32 _queryId,
        uint256 _time,
        bytes _value,
        uint256 _nonce,
        bytes _queryData,
        address _reporter
    );
    event NewStaker(address _staker, uint256 _amount);
    event StakeWithdrawRequested(address _staker, uint256 _amount);
    event StakeWithdrawn(address _staker);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Storage
    mapping(bytes32 => mapping(uint256 => bool)) public isDisputed; //queryId -> timestamp -> value
    mapping(bytes32 => mapping(uint256 => address)) public reporterByTimestamp;
    mapping(address => StakeInfo) stakerDetails; //mapping from a persons address to their staking info
    mapping(bytes32 => uint256[]) public timestamps;
    mapping(bytes32 => uint256) public tips; // mapping of data IDs to the amount of TRB they are tipped
    mapping(bytes32 => mapping(uint256 => bytes)) public values; //queryId -> timestamp -> value
    mapping(bytes32 => uint256[]) public voteRounds; // mapping of vote identifier hashes to an array of dispute IDs
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    uint256 public stakeAmount;
    uint256 public constant timeBasedReward = 5e17; // time based reward for a reporter for successfully submitting a value
    uint256 public tipsInContract; // number of tips within the contract
    uint256 public voteCount;
    address public token;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // Structs
    struct StakeInfo {
        uint256 startDate; //stake start date
        uint256 stakedBalance; // staked balance
        uint256 lockedBalance; // amount locked for withdrawal
        uint256 reporterLastTimestamp; // timestamp of reporter's last reported value
        uint256 reportsSubmitted; // total number of reports submitted by reporter
    }

    // Functions
    /**
     * @dev Initializes playground parameters
     */
    constructor() {
        _name = "TellorPlayground";
        _symbol = "TRBP";
        _decimals = 18;
        token = address(this);
    }

    /**
     * @dev Mock function for adding staking rewards. No rewards actually given to stakers
     * @param _amount Amount of TRB to be added to the contract
     */
    function addStakingRewards(uint256 _amount) external {
        require(_transferFrom(msg.sender, address(this), _amount));
    }

    /**
     * @dev Approves amount that an address is alowed to spend of behalf of another
     * @param _spender The address which is allowed to spend the tokens
     * @param _amount The amount that msg.sender is allowing spender to use
     * @return bool Whether the transaction succeeded
     *
     */
    function approve(address _spender, uint256 _amount) external returns (bool){
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev A mock function to create a dispute
     * @param _queryId The tellorId to be disputed
     * @param _timestamp the timestamp of the value to be disputed
     */
    function beginDispute(bytes32 _queryId, uint256 _timestamp) external {
        values[_queryId][_timestamp] = bytes("");
        isDisputed[_queryId][_timestamp] = true;
        voteCount++;
        voteRounds[keccak256(abi.encodePacked(_queryId, _timestamp))].push(
            voteCount
        );
    }

    /**
     * @dev Allows a reporter to submit stake
     * @param _amount amount of tokens to stake
     */
    function depositStake(uint256 _amount) external {
        StakeInfo storage _staker = stakerDetails[msg.sender];
        if (_staker.lockedBalance > 0) {
            if (_staker.lockedBalance >= _amount) {
                _staker.lockedBalance -= _amount;
            } else {
                require(
                    _transferFrom(
                        msg.sender,
                        address(this),
                        _amount - _staker.lockedBalance
                    )
                );
                _staker.lockedBalance = 0;
            }
        } else {
            require(_transferFrom(msg.sender, address(this), _amount));
        }
        _staker.startDate = block.timestamp; // This resets their stake start date to now
        _staker.stakedBalance += _amount;
        emit NewStaker(msg.sender, _amount);
    }

    /**
     * @dev Public function to mint tokens to the given address
     * @param _user The address which will receive the tokens
     */
    function faucet(address _user) external {
        _mint(_user, 1000 ether);
    }

    /**
     * @dev Allows a reporter to request to withdraw their stake
     * @param _amount amount of staked tokens requesting to withdraw
     */
    function requestStakingWithdraw(uint256 _amount) external {
        StakeInfo storage _staker = stakerDetails[msg.sender];
        require(
            _staker.stakedBalance >= _amount,
            "insufficient staked balance"
        );
        _staker.startDate = block.timestamp;
        _staker.lockedBalance += _amount;
        _staker.stakedBalance -= _amount;
        emit StakeWithdrawRequested(msg.sender, _amount);
    }

    /**
     * @dev A mock function to submit a value to be read without reporter staking needed
     * @param _queryId the ID to associate the value to
     * @param _value the value for the queryId
     * @param _nonce the current value count for the query id
     * @param _queryData the data used by reporters to fulfill the data query
     */
    // slither-disable-next-line timestamp
    function submitValue(
        bytes32 _queryId,
        bytes calldata _value,
        uint256 _nonce,
        bytes memory _queryData
    ) external {
        require(keccak256(_value) != keccak256(""), "value must be submitted");
        require(
            _nonce == timestamps[_queryId].length || _nonce == 0,
            "nonce must match timestamp index"
        );
        require(
            _queryId == keccak256(_queryData) || uint256(_queryId) <= 100,
            "id must be hash of bytes data"
        );
        values[_queryId][block.timestamp] = _value;
        timestamps[_queryId].push(block.timestamp);
        reporterByTimestamp[_queryId][block.timestamp] = msg.sender;
        stakerDetails[msg.sender].reporterLastTimestamp = block.timestamp;
        stakerDetails[msg.sender].reportsSubmitted++;
        emit NewReport(
            _queryId,
            block.timestamp,
            _value,
            _nonce,
            _queryData,
            msg.sender
        );
    }

    /**
     * @dev Transfer tokens from one user to another
     * @param _recipient The destination address
     * @param _amount The amount of tokens, including decimals, to transfer
     * @return bool If the transfer succeeded
     */
    function transfer(address _recipient, uint256 _amount)
        public
        returns (bool)
    {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /**
     * @dev Transfer tokens from user to another
     * @param _sender The address which owns the tokens
     * @param _recipient The destination address
     * @param _amount The quantity of tokens to transfer
     * @return bool Whether the transfer succeeded
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(
            _sender,
            msg.sender,
            _allowances[_sender][msg.sender] - _amount
        );
        return true;
    }

    /**
     * @dev Withdraws a reporter's stake
     */
    function withdrawStake() external {
        StakeInfo storage _s = stakerDetails[msg.sender];
        // Ensure reporter is locked and that enough time has passed
        require(block.timestamp - _s.startDate >= 7 days, "7 days didn't pass");
        require(_s.lockedBalance > 0, "reporter not locked for withdrawal");
        _transfer(address(this), msg.sender, _s.lockedBalance);
        _s.lockedBalance = 0;
        emit StakeWithdrawn(msg.sender);
    }

    // Getters
    /**
     * @dev Returns the amount that an address is alowed to spend of behalf of another
     * @param _owner The address which owns the tokens
     * @param _spender The address that will use the tokens
     * @return uint256 The amount of allowed tokens
     */
    function allowance(address _owner, address _spender) external view returns (uint256){
        return _allowances[_owner][_spender];
    }

    /**
     * @dev Returns the balance of a given user.
     * @param _account user address
     * @return uint256 user's token balance
     */
    function balanceOf(address _account) external view returns (uint256) {
        return _balances[_account];
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * @return uint8 the number of decimals; used only for display purposes
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _ifRetrieve bool true if able to retrieve a non-zero value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        (bool _found, uint256 _index) = getIndexForDataBefore(
            _queryId,
            _timestamp
        );
        if (!_found) return (false, bytes(""), 0);
        _timestampRetrieved = getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = values[_queryId][_timestampRetrieved];
        return (true, _value, _timestampRetrieved);
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
        uint256 _count = getNewValueCountbyQueryId(_queryId);
        if (_count > 0) {
            uint256 _middle;
            uint256 _start = 0;
            uint256 _end = _count - 1;
            uint256 _time;
            //Checking Boundaries to short-circuit the algorithm
            _time = getTimestampbyQueryIdandIndex(_queryId, _start);
            if (_time >= _timestamp) return (false, 0);
            _time = getTimestampbyQueryIdandIndex(_queryId, _end);
            if (_time < _timestamp) {
                while (isInDispute(_queryId, _time) && _end > 0) {
                    _end--;
                    _time = getTimestampbyQueryIdandIndex(_queryId, _end);
                }
                if (_end == 0 && isInDispute(_queryId, _time)) {
                    return (false, 0);
                }
                return (true, _end);
            }
            //Since the value is within our boundaries, do a binary search
            while (true) {
                _middle = (_end - _start) / 2 + 1 + _start;
                _time = getTimestampbyQueryIdandIndex(_queryId, _middle);
                if (_time < _timestamp) {
                    //get immediate next value
                    uint256 _nextTime = getTimestampbyQueryIdandIndex(
                        _queryId,
                        _middle + 1
                    );
                    if (_nextTime >= _timestamp) {
                        if (!isInDispute(_queryId, _time)) {
                            // _time is correct
                            return (true, _middle);
                        } else {
                            // iterate backwards until we find a non-disputed value
                            while (
                                isInDispute(_queryId, _time) && _middle > 0
                            ) {
                                _middle--;
                                _time = getTimestampbyQueryIdandIndex(
                                    _queryId,
                                    _middle
                                );
                            }
                            if (_middle == 0 && isInDispute(_queryId, _time)) {
                                return (false, 0);
                            }
                            // _time is correct
                            return (true, _middle);
                        }
                    } else {
                        //look from middle + 1(next value) to end
                        _start = _middle + 1;
                    }
                } else {
                    uint256 _prevTime = getTimestampbyQueryIdandIndex(
                        _queryId,
                        _middle - 1
                    );
                    if (_prevTime < _timestamp) {
                        if (!isInDispute(_queryId, _prevTime)) {
                            // _prevTime is correct
                            return (true, _middle - 1);
                        } else {
                            // iterate backwards until we find a non-disputed value
                            _middle--;
                            while (
                                isInDispute(_queryId, _prevTime) && _middle > 0
                            ) {
                                _middle--;
                                _prevTime = getTimestampbyQueryIdandIndex(
                                    _queryId,
                                    _middle
                                );
                            }
                            if (
                                _middle == 0 && isInDispute(_queryId, _prevTime)
                            ) {
                                return (false, 0);
                            }
                            // _prevtime is correct
                            return (true, _middle);
                        }
                    } else {
                        //look from start to middle -1(prev value)
                        _end = _middle - 1;
                    }
                }
            }
        }
        return (false, 0);
    }

    /**
     * @dev Counts the number of values that have been submitted for a given ID
     * @param _queryId the ID to look up
     * @return uint256 count of the number of values received for the queryId
     */
    function getNewValueCountbyQueryId(bytes32 _queryId)
        public
        view
        returns (uint256)
    {
        return timestamps[_queryId].length;
    }

    /**
     * @dev Returns the reporter for a given timestamp and queryId
     * @param _queryId bytes32 version of the queryId
     * @param _timestamp uint256 timestamp of report
     * @return address of data reporter
     */
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (address)
    {
        return reporterByTimestamp[_queryId][_timestamp];
    }

    /**
     * @dev Returns mock stake amount
     * @return uint256 stake amount
     */
    function getStakeAmount() external view returns (uint256) {
        return stakeAmount;
    }

    /**
     * @dev Allows users to retrieve all information about a staker
     * @param _stakerAddress address of staker inquiring about
     * @return uint startDate of staking
     * @return uint current amount staked
     * @return uint current amount locked for withdrawal
     * @return uint reward debt used to calculate staking reward
     * @return uint reporter's last reported timestamp
     * @return uint total number of reports submitted by reporter
     * @return uint governance vote count when first staked
     * @return uint number of votes case by staker when first staked
     * @return uint whether staker is counted in totalStakers
     */
    function getStakerInfo(address _stakerAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        StakeInfo storage _staker = stakerDetails[_stakerAddress];
        return (
            _staker.startDate,
            _staker.stakedBalance,
            _staker.lockedBalance,
            0, // reward debt
            _staker.reporterLastTimestamp,
            _staker.reportsSubmitted,
            0, // start vote count
            0, // start vote tally
            false
        );
    }

    /**
     * @dev Gets the timestamp for the value based on their index
     * @param _queryId is the queryId to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
        public
        view
        returns (uint256)
    {
        uint256 _len = timestamps[_queryId].length;
        if (_len == 0 || _len <= _index) return 0;
        return timestamps[_queryId][_index];
    }

    /**
     * @dev Returns an array of voting rounds for a given vote
     * @param _hash is the identifier hash for a vote
     * @return uint256[] memory dispute IDs of the vote rounds
     */
    function getVoteRounds(bytes32 _hash) public view returns (uint256[] memory){
        return voteRounds[_hash];
    }

    /**
     * @dev Returns the governance address of the contract
     * @return address (this address)
     */
    function governance() external view returns (address) {
        return address(this);
    }

    /**
     * @dev Returns whether a given value is disputed
     * @param _queryId unique ID of the data feed
     * @param _timestamp timestamp of the value
     * @return bool whether the value is disputed
     */
    function isInDispute(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bool)
    {
        return isDisputed[_queryId][_timestamp];
    }

    /**
     * @dev Returns the name of the token.
     * @return string name of the token
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Retrieves value from oracle based on queryId/timestamp
     * @param _queryId being requested
     * @param _timestamp to retrieve data/value from
     * @return bytes value for queryId/timestamp submitted
     */
    function retrieveData(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory)
    {
        return values[_queryId][_timestamp];
    }

    /**
     * @dev Returns the symbol of the token.
     * @return string symbol of the token
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the total supply of the token.
     * @return uint256 total supply of token
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // Internal functions
    /**
     * @dev Internal function to approve tokens for the user
     * @param _owner The owner of the tokens
     * @param _spender The address which is allowed to spend the tokens
     * @param _amount The amount that msg.sender is allowing spender to use
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @dev Internal function to burn tokens for the user
     * @param _account The address whose tokens to burn
     * @param _amount The quantity of tokens to burn
     */
    function _burn(address _account, uint256 _amount) internal{
        require(_account != address(0), "ERC20: burn from the zero address");
        _balances[_account] -= _amount;
        _totalSupply -= _amount;
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Internal function to create new tokens for the user
     * @param _account The address which receives minted tokens
     * @param _amount The quantity of tokens to min
     */
    function _mint(address _account, uint256 _amount) internal{
        require(_account != address(0), "ERC20: mint to the zero address");
        _totalSupply += _amount;
        _balances[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Internal function to perform token transfer
     * @param _sender The address which owns the tokens
     * @param _recipient The destination address
     * @param _amount The quantity of tokens to transfer
     */
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal{
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require( _recipient != address(0),"ERC20: transfer to the zero address");
        _balances[_sender] -= _amount;
        _balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
    }

    /**
     * @dev Allows this contract to transfer tokens from one user to another
     * @param _sender The address which owns the tokens
     * @param _recipient The destination address
     * @param _amount The quantity of tokens to transfer
     * @return bool Whether the transfer succeeded
     */
    function _transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(
            _sender,
            msg.sender,
            _allowances[_sender][address(this)] - _amount
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interface/ITellor.sol";
import "./interface/IERC2362.sol";
import "./interface/IMappingContract.sol";

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
        (bool _found, uint256 _index) = getIndexForDataAfter(
            _queryId,
            _timestamp
        );
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
    )
        public
        view
        returns (bytes[] memory _values, uint256[] memory _timestamps)
    {
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
     function setIdMappingContract(address _addy) external{
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
    function _sliceUint(bytes memory _b) internal pure returns(uint256 _number){
        for (uint256 _i = 0; _i < _b.length; _i++) {
            _number = _number * 256 + uint8(_b[_i]);
        }
    }
}