/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IERC20.sol


pragma solidity 0.8.3;

interface IERC20 {
  function transfer(address _to, uint256 _amount) external returns(bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns(bool);
}

// File: usingtellor/contracts/interface/ITellor.sol


pragma solidity >=0.8.0;

interface ITellor{
    //Controller
    function addresses(bytes32) external view returns(address);
    function uints(bytes32) external view returns(uint256);
    function burn(uint256 _amount) external;
    function changeDeity(address _newDeity) external;
    function changeOwner(address _newOwner) external;
    function changeTellorContract(address _tContract) external;
    function changeControllerContract(address _newController) external;
    function changeGovernanceContract(address _newGovernance) external;
    function changeOracleContract(address _newOracle) external;
    function changeTreasuryContract(address _newTreasury) external;
    function changeUint(bytes32 _target, uint256 _amount) external;
    function migrate() external;
    function mint(address _reciever, uint256 _amount) external;
    function init() external;
    function getAllDisputeVars(uint256 _disputeId) external view returns (bytes32,bool,bool,bool,address,address,address,uint256[9] memory,int256);
    function getDisputeIdByDisputeHash(bytes32 _hash) external view returns (uint256);
    function getDisputeUintVars(uint256 _disputeId, bytes32 _data) external view returns(uint256);
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256);
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function isMigrated(address _addy) external view returns (bool);
    function allowance(address _user, address _spender) external view  returns (uint256);
    function allowedToTrade(address _user, uint256 _amount) external view returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function approveAndTransferFrom(address _from, address _to, uint256 _amount) external returns(bool);
    function balanceOf(address _user) external view returns (uint256);
    function balanceOfAt(address _user, uint256 _blockNumber)external view returns (uint256);
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool success) ;
    function depositStake() external;
    function requestStakingWithdraw() external;
    function withdrawStake() external;
    function changeStakingStatus(address _reporter, uint _status) external;
    function slashReporter(address _reporter, address _disputer) external;
    function getStakerInfo(address _staker) external view returns (uint256, uint256);
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index) external view returns (uint256);
    function getNewCurrentVariables()external view returns (bytes32 _c,uint256[5] memory _r,uint256 _d,uint256 _t);
    function getNewValueCountbyQueryId(bytes32 _queryId) external view returns(uint256);
    function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function retrieveData(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    //Governance
    enum VoteResult {FAILED,PASSED,INVALID}
    function setApprovedFunction(bytes4 _func, bool _val) external;
    function beginDispute(bytes32 _queryId,uint256 _timestamp) external;
    function delegate(address _delegate) external;
    function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);
    function executeVote(uint256 _disputeId) external;
    function proposeVote(address _contract,bytes4 _function, bytes calldata _data, uint256 _timestamp) external;
    function tallyVotes(uint256 _disputeId) external;
    function updateMinDisputeFee() external;
    function verify() external pure returns(uint);
    function vote(uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function voteFor(address[] calldata _addys,uint256 _disputeId, bool _supports, bool _invalidQuery) external;
    function getDelegateInfo(address _holder) external view returns(address,uint);
    function isFunctionApproved(bytes4 _func) external view returns(bool);
    function isApprovedGovernanceContract(address _contract) external returns (bool);
    function getVoteRounds(bytes32 _hash) external view returns(uint256[] memory);
    function getVoteCount() external view returns(uint256);
    function getVoteInfo(uint256 _disputeId) external view returns(bytes32,uint256[9] memory,bool[2] memory,VoteResult,bytes memory,bytes4,address[2] memory);
    function getDisputeInfo(uint256 _disputeId) external view returns(uint256,uint256,bytes memory, address);
    function getOpenDisputesOnId(bytes32 _queryId) external view returns(uint256);
    function didVote(uint256 _disputeId, address _voter) external view returns(bool);
    //Oracle
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getReportingLock() external view returns(uint256);
    function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(address);
    function reportingLock() external view returns(uint256);
    function removeValue(bytes32 _queryId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function tipQuery(bytes32 _queryId, uint256 _tip, bytes memory _queryData) external;
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function burnTips() external;
    function changeReportingLock(uint256 _newReportingLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getReporterLastTimestamp(address _reporter) external view returns(uint256);
    function getTipsById(bytes32 _queryId) external view returns(uint256);
    function getTimeBasedReward() external view returns(uint256);
    function getTimestampCountById(bytes32 _queryId) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _queryId, uint256 _timestamp) external view returns(uint256);
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function getCurrentValue(bytes32 _queryId) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
    //Treasury
    function issueTreasury(uint256 _maxAmount, uint256 _rate, uint256 _duration) external;
    function payTreasury(address _investor,uint256 _id) external;
    function buyTreasury(uint256 _id,uint256 _amount) external;
    function getTreasuryDetails(uint256 _id) external view returns(uint256,uint256,uint256,uint256);
    function getTreasuryFundsByUser(address _user) external view returns(uint256);
    function getTreasuryAccount(uint256 _id, address _investor) external view returns(uint256,uint256,bool);
    function getTreasuryCount() external view returns(uint256);
    function getTreasuryOwners(uint256 _id) external view returns(address[] memory);
    function wasPaid(uint256 _id, address _investor) external view returns(bool);
    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;

    //parachute functions
    function killContract() external;
    function migrateFor(address _destination,uint256 _amount) external;
    function rescue51PercentAttack(address _tokenHolder) external;
    function rescueBrokenDataReporting() external;
    function rescueFailedUpdate() external;
}

// File: usingtellor/contracts/UsingTellor.sol


pragma solidity >=0.8.0;


/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor public tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the tellor address in storage
     * @param _tellor is the TellorMaster address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Allows the user to get the latest value for the queryId specified
     * @param _queryId is the id to look up the value for
     * @return _ifRetrieve bool true if non-zero value successfully retrieved
     * @return _value the value retrieved
     * @return _timestampRetrieved the retrieved value's timestamp
     */
    function getCurrentValue(bytes32 _queryId)
        public
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        )
    {
        uint256 _count = tellor.getNewValueCountbyQueryId(_queryId);
        if (_count == 0) {
          return (false, bytes(""), 0);
        }
        uint256 _time = tellor.getTimestampbyQueryIdandIndex(
            _queryId,
            _count - 1
        );
        _value = tellor.retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), _time);
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
        public
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
        uint256 _time = tellor.getTimestampbyQueryIdandIndex(_queryId, _index);
        _value = tellor.retrieveData(_queryId, _time);
        if (keccak256(_value) != keccak256(bytes("")))
            return (true, _value, _time);
        return (false, bytes(""), 0);
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
        uint256 _count = tellor.getNewValueCountbyQueryId(_queryId);
        if (_count > 0) {
            uint256 middle;
            uint256 start = 0;
            uint256 end = _count - 1;
            uint256 _time;

            //Checking Boundaries to short-circuit the algorithm
            _time = tellor.getTimestampbyQueryIdandIndex(_queryId, start);
            if (_time >= _timestamp) return (false, 0);
            _time = tellor.getTimestampbyQueryIdandIndex(_queryId, end);
            if (_time < _timestamp) return (true, end);

            //Since the value is within our boundaries, do a binary search
            while (true) {
                middle = (end - start) / 2 + 1 + start;
                _time = tellor.getTimestampbyQueryIdandIndex(_queryId, middle);
                if (_time < _timestamp) {
                    //get imeadiate next value
                    uint256 _nextTime = tellor.getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle + 1
                    );
                    if (_nextTime >= _timestamp) {
                        //_time is correct
                        return (true, middle);
                    } else {
                        //look from middle + 1(next value) to end
                        start = middle + 1;
                    }
                } else {
                    uint256 _prevTime = tellor.getTimestampbyQueryIdandIndex(
                        _queryId,
                        middle - 1
                    );
                    if (_prevTime < _timestamp) {
                        // _prevtime is correct
                        return (true, middle - 1);
                    } else {
                        //look from start to middle -1(prev value)
                        end = middle - 1;
                    }
                }
                //We couldn't found a value
                //if(middle - 1 == start || middle == _count) return (false, 0);
            }
        }
        return (false, 0);
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

    // /**
    //  * @dev Gets the timestamp for the value based on their index
    //  * @param _queryId is the id to look up
    //  * @param _index is the value index to look up
    //  * @return uint256 timestamp
    //  */
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
        ITellor _governance = ITellor(
            tellor.addresses(
                keccak256(abi.encodePacked("_GOVERNANCE_CONTRACT"))
            )
        );
        return
            _governance
                .getVoteRounds(
                keccak256(abi.encodePacked(_queryId, _timestamp))
            )
                .length >
            0;
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
}

// File: contracts/Autopay.sol


pragma solidity 0.8.3;

/**
 @author Tellor Inc.
 @title Autopay
 @dev This is contract for automatically paying for Tellor oracle data at
 * specific time intervals. Any non-rebasing ERC20 token can be used for payment.
 * Only the first data submission within each time window gets a reward.
*/



contract Autopay is UsingTellor {
    // Storage
    ITellor public master; // Tellor contract address
    address public owner;
    uint256 public fee; // 1000 is 100%, 50 is 5%, etc.

    mapping(bytes32 => mapping(bytes32 => Feed)) dataFeed; // mapping queryID to dataFeedID to details
    mapping(bytes32 => bytes32[]) currentFeeds; // mapping queryID to dataFeedIDs array
    mapping(bytes32 => mapping(address => Tip[])) public tips; // mapping queryID to token address to tips
    // Structs
    struct FeedDetails {
        address token; // token used for tipping
        uint256 reward; // amount paid for each eligible data submission
        uint256 balance; // account remaining balance
        uint256 startTime; // time of first payment window
        uint256 interval; // time between pay periods
        uint256 window; // amount of time data can be submitted per interval
    }

    struct Feed {
        FeedDetails details;
        mapping(uint256 => bool) rewardClaimed; // tracks which tips were already paid out
    }

    struct Tip {
        uint256 amount;
        uint256 timestamp;
    }

    // Events
    event NewDataFeed(
        address _token,
        bytes32 _queryId,
        bytes32 _feedId,
        bytes _queryData
    );
    event DataFeedFunded(bytes32 _queryId, bytes32 _feedId, uint256 _amount);
    event OneTimeTipClaimed(bytes32 _queryId, address _token, uint256 _amount);
    event TipAdded(
        address _token,
        bytes32 _queryId,
        uint256 _amount,
        bytes _queryData
    );
    event TipClaimed(
        bytes32 _feedId,
        bytes32 _queryId,
        address _token,
        uint256 _amount
    );

    // Functions
    /**
     * @dev Initializes system parameters
     * @param _tellor address of Tellor contract
     * @param _owner address of fee recipient
     * @param _fee percentage, 1000 is 100%, 50 is 5%, etc.
     */
    constructor(
        address payable _tellor,
        address _owner,
        uint256 _fee
    ) UsingTellor(_tellor) {
        master = ITellor(_tellor);
        owner = _owner;
        fee = _fee;
    }

    /**
     * @dev Function to claim singular tip
     * @param _token address of token tipped
     * @param _queryId id of reported data
     * @param _timestamps ID of timestamps you reported for
     */
    function claimOneTimeTip(
        address _token,
        bytes32 _queryId,
        uint256[] calldata _timestamps
    ) external {
        require(
            tips[_queryId][_token].length > 0,
            "no tips submitted for this token and queryId"
        );
        uint256 _reward;
        uint256 _cumulativeReward;
        for (uint256 _i = 0; _i < _timestamps.length; _i++) {
            (_reward) = _claimOneTimeTip(_token, _queryId, _timestamps[_i]);
            _cumulativeReward += _reward;
        }
        IERC20(_token).transfer(
            msg.sender,
            _cumulativeReward - ((_cumulativeReward * fee) / 1000)
        );
        IERC20(_token).transfer(owner, (_cumulativeReward * fee) / 1000);
        emit OneTimeTipClaimed(_queryId, _token, _cumulativeReward);
    }

    /**
     * @dev Allows Tellor reporters to claim their tips in batches
     * @param _reporter address of Tellor reporter
     * @param _feedId unique dataFeed Id
     * @param _queryId id of reported data
     * @param _timestamps[] timestamps array of reported data eligible for reward
     */
    function claimTip(
        address _reporter,
        bytes32 _feedId,
        bytes32 _queryId,
        uint256[] calldata _timestamps
    ) external {
        uint256 _reward;
        uint256 _cumulativeReward;
        FeedDetails storage _feed = dataFeed[_queryId][_feedId].details;
        for (uint256 _i = 0; _i < _timestamps.length; _i++) {
            _reward = _claimTip(_feedId, _queryId, _timestamps[_i]);
            require(
                master.getReporterByTimestamp(_queryId, _timestamps[_i]) ==
                    _reporter,
                "reporter mismatch"
            );
            _cumulativeReward += _reward;
        }
        IERC20(_feed.token).transfer(
            _reporter,
            _cumulativeReward - ((_cumulativeReward * fee) / 1000)
        );
        IERC20(_feed.token).transfer(owner, (_cumulativeReward * fee) / 1000);
        emit TipClaimed(_feedId, _queryId, _feed.token, _cumulativeReward);
    }

    /**
     * @dev Allows dataFeed account to be filled with tokens
     * @param _feedId unique dataFeed Id for queryId
     * @param _queryId id of reported data associated with feed
     * @param _amount quantity of tokens to fund feed account
     */
    function fundFeed(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _amount
    ) external {
        FeedDetails storage _feed = dataFeed[_queryId][_feedId].details;
        require(_feed.reward > 0, "feed not set up");
        _feed.balance += _amount;
        require(
            IERC20(_feed.token).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "ERC20: transfer amount exceeds balance"
        );
        emit DataFeedFunded(_feedId, _queryId, _amount);
    }

    /**
     * @dev Initializes dataFeed parameters.
     * @param _token address of ERC20 token used for tipping
     * @param _queryId id of specific desired data feet
     * @param _reward tip amount per eligible data submission
     * @param _startTime timestamp of first autopay window
     * @param _interval amount of time between autopay windows
     * @param _window amount of time after each new interval when reports are eligible for tips
     * @param _queryData the data used by reporters to fulfill the query
     */
    function setupDataFeed(
        address _token,
        bytes32 _queryId,
        uint256 _reward,
        uint256 _startTime,
        uint256 _interval,
        uint256 _window,
        bytes calldata _queryData
    ) external {
        require(
            _queryId == keccak256(_queryData) || uint256(_queryId) <= 100,
            "id must be hash of bytes data"
        );
        bytes32 _feedId = keccak256(
            abi.encode(
                _queryId,
                _token,
                _reward,
                _startTime,
                _interval,
                _window
            )
        );
        FeedDetails storage _feed = dataFeed[_queryId][_feedId].details;
        require(_feed.reward == 0, "feed must not be set up already");
        require(_reward > 0, "reward must be greater than zero");
        require(
            _window < _interval,
            "window must be less than interval length"
        );
        _feed.token = _token;
        _feed.reward = _reward;
        _feed.startTime = _startTime;
        _feed.interval = _interval;
        _feed.window = _window;
        currentFeeds[_queryId].push(_feedId);
        emit NewDataFeed(_token, _queryId, _feedId, _queryData);
    }

    /**
     * @dev Function to run a single tip
     * @param _token address of token to tip
     * @param _queryId id of tipped data
     * @param _amount amount to tip
     * @param _queryData the data used by reporters to fulfill the query
     */
    function tip(
        address _token,
        bytes32 _queryId,
        uint256 _amount,
        bytes calldata _queryData
    ) external {
        require(
            _queryId == keccak256(_queryData) || uint256(_queryId) <= 100,
            "id must be hash of bytes data"
        );
        Tip[] storage _tips = tips[_queryId][_token];
        if (_tips.length == 0) {
            _tips.push(Tip(_amount, block.timestamp));
        } else {
            (, , uint256 _timestampRetrieved) = getCurrentValue(_queryId);
            if (_timestampRetrieved < _tips[_tips.length - 1].timestamp) {
                _tips[_tips.length - 1].timestamp = block.timestamp;
                _tips[_tips.length - 1].amount += _amount;
            } else {
                _tips.push(Tip(_amount, block.timestamp));
            }
        }
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "ERC20: transfer amount exceeds balance"
        );
        emit TipAdded(_token, _queryId, _amount, _queryData);
    }

    /**
     * @dev Getter function to read current data feeds
     * @param _queryId id of reported data
     * @return feedIds array for queryId
     */
    function getCurrentFeeds(bytes32 _queryId)
        external
        view
        returns (bytes32[] memory)
    {
        return currentFeeds[_queryId];
    }

    /**
     * @dev Getter function to current oneTime tip by queryId
     * @param _queryId id of reported data
     * @param _token address of tipped token
     * @return amount of tip
     */
    function getCurrentTip(bytes32 _queryId, address _token)
        external
        view
        returns (uint256)
    {
        (, , uint256 _timestampRetrieved) = getCurrentValue(_queryId);
        Tip memory _lastTip = tips[_queryId][_token][
            tips[_queryId][_token].length - 1
        ];
        if (_timestampRetrieved < _lastTip.timestamp) {
            return _lastTip.amount;
        } else {
            return 0;
        }
    }

    /**
     * @dev Getter function to read a specific dataFeed
     * @param _feedId unique feedId of parameters
     * @param _queryId id of reported data
     * @return FeedDetails details of specified feed
     */
    function getDataFeed(bytes32 _feedId, bytes32 _queryId)
        external
        view
        returns (FeedDetails memory)
    {
        return (dataFeed[_queryId][_feedId].details);
    }

    /**
     * @dev Getter function to get number of past tips
     * @param _queryId id of reported data
     * @param _token address of tipped token
     * @return count of tips available
     */
    function getPastTipCount(bytes32 _queryId, address _token)
        external
        view
        returns (uint256)
    {
        return tips[_queryId][_token].length;
    }

    /**
     * @dev Getter function for past tips
     * @param _queryId id of reported data
     * @param _token address of tipped token
     * @return Tip struct (amount/timestamp) of all past tips
     */
    function getPastTips(bytes32 _queryId, address _token)
        external
        view
        returns (Tip[] memory)
    {
        return tips[_queryId][_token];
    }

    /**
     * @dev Getter function for past tips by index
     * @param _queryId id of reported data
     * @param _token address of tipped token
     * @param _index uint index in the Tip array
     * @return amount/timestamp of specific tip
     */
    function getPastTipByIndex(
        bytes32 _queryId,
        address _token,
        uint256 _index
    ) external view returns (Tip memory) {
        return tips[_queryId][_token][_index];
    }

    /**
     * @dev Getter function to read if a reward has been claimed
     * @param _feedId feedId of dataFeed
     * @param _queryId id of reported data
     * @param _timestamp id or reported data
     * @return bool rewardClaimed
     */
    function getRewardClaimedStatus(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _timestamp
    ) external view returns (bool) {
        return dataFeed[_queryId][_feedId].rewardClaimed[_timestamp];
    }

    // Internal functions
    /**
     * @dev Internal function which allows Tellor reporters to claim their autopay tips
     * @param _feedId of dataFeed
     * @param _queryId id of reported data
     * @param _timestamp timestamp of reported data eligible for reward
     * @return uint256 reward amount
     */
    function _claimTip(
        bytes32 _feedId,
        bytes32 _queryId,
        uint256 _timestamp
    ) internal returns (uint256) {
        Feed storage _feed = dataFeed[_queryId][_feedId];
        require(_feed.details.balance > 0, "insufficient feed balance");
        require(!_feed.rewardClaimed[_timestamp], "reward already claimed");
        require(
            block.timestamp - _timestamp > 12 hours,
            "buffer time has not passed"
        );
        require(
            block.timestamp - _timestamp < 12 weeks,
            "timestamp too old to claim tip"
        );
        bytes memory _valueRetrieved = retrieveData(_queryId, _timestamp);
        require(
            keccak256(_valueRetrieved) != keccak256(bytes("")),
            "no value exists at timestamp"
        );
        uint256 _n = (_timestamp - _feed.details.startTime) /
            _feed.details.interval; // finds closest interval _n to timestamp
        uint256 _c = _feed.details.startTime + _feed.details.interval * _n; // finds timestamp _c of interval _n
        require(
            _timestamp - _c < _feed.details.window,
            "timestamp not within window"
        );
        (, , uint256 _timestampBefore) = getDataBefore(_queryId, _timestamp);
        require(
            _timestampBefore < _c,
            "timestamp not first report within window"
        );
        uint256 _rewardAmount;
        if (_feed.details.balance >= _feed.details.reward) {
            _rewardAmount = _feed.details.reward;
            _feed.details.balance -= _feed.details.reward;
        } else {
            _rewardAmount = _feed.details.balance;
            _feed.details.balance = 0;
        }
        _feed.rewardClaimed[_timestamp] = true;
        return _rewardAmount;
    }

    /**
     ** @dev Internal function which allows Tellor reporters to claim their one time tips
     * @param _token address of tipped token
     * @param _queryId id of reported data
     * @param _timestamp timestamp of one time tip
     * @return amount of tip
     */
    function _claimOneTimeTip(
        address _token,
        bytes32 _queryId,
        uint256 _timestamp
    ) internal returns (uint256) {
        Tip[] storage _tips = tips[_queryId][_token];
        require(
            block.timestamp - _timestamp > 12 hours,
            "buffer time has not passed"
        );
        require(
            msg.sender == master.getReporterByTimestamp(_queryId, _timestamp),
            "message sender not reporter for given queryId and timestamp"
        );
        bytes memory _valueRetrieved = retrieveData(_queryId, _timestamp);
        require(
            keccak256(_valueRetrieved) != keccak256(bytes("")),
            "no value exists at timestamp"
        );
        uint256 _min;
        uint256 _max = _tips.length;
        uint256 _mid;
        while (_max - _min > 1) {
            _mid = (_max + _min) / 2;
            if (_tips[_mid].timestamp > _timestamp) {
                _max = _mid;
            } else {
                _min = _mid;
            }
        }
        (, , uint256 _timestampBefore) = getDataBefore(_queryId, _timestamp);
        require(
            _timestampBefore < _tips[_min].timestamp,
            "tip earned by previous submission"
        );
        require(
            _timestamp > _tips[_min].timestamp,
            "timestamp not eligible for tip"
        );
        require(_tips[_min].amount > 0, "tip already claimed");
        uint256 _tipAmount = _tips[_min].amount;
        _tips[_min].amount = 0;
        return _tipAmount;
    }
}