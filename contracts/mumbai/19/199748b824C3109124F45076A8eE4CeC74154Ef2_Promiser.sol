//  $$$$$$/                                $$/                $$/
// $$  __$$/                               $$ |               $$ |
// $$ /  $$ | $$$$$$$/ $$/   $$/ $$$$$$$/  $$ |      $$$$$$/  $$$$$$$/   $$$$$$$/
// $$$$$$$$ |$$  _____|$$ |  $$ |$$  __$$/ $$ |      /____$$/ $$  __$$/ $$  _____|
// $$  __$$ |/$$$$$$/  $$ |  $$ |$$ |  $$ |$$ |      $$$$$$$ |$$ |  $$ |/$$$$$$/
// $$ |  $$ | /____$$/ $$ |  $$ |$$ |  $$ |$$ |     $$  __$$ |$$ |  $$ | /____$$/
// $$ |  $$ |$$$$$$$  |/$$$$$$  |$$ |  $$ |$$$$$$$$//$$$$$$$ |$$$$$$$  |$$$$$$$  |
// /__|  /__|/_______/  /______/ /__|  /__|/________|/_______|/_______/ /_______/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Promiser {
    uint256 private _MAXIMUM_RUNNING_TIME = 12 weeks;
    uint256 private _PLATFORM_FEE = 10 * 1e18; // 10 matic
    uint256 private _MAXIMUM_PANALTY = 1000 * 1e18; // 1000 matic
    uint256 private _COLLECTED_PLATFORM_FEE = 0;
    uint256 private _TOTAL_PROMISE_MADE = 0;
    address private _CREATOR;
    address[100] private _TOP_PROMISERS;

    mapping(address => mapping(uint256 => Promise)) private _promiseByWallet;
    mapping(address => mapping(uint256 => bool)) private _historyByWallet;
    mapping(address => Trust) private _trustByWallet;

    event Received(address from, uint256 value);
    event MakePromise(uint256 index, uint256 timestamp, address madeAt);
    event StartPromise(uint256 index, uint256 timestamp, address startedBy);
    event SubmitAction(uint256 index, uint256 timestamp, bytes32 description, uint256 totalAction);
    event EndPromise(uint256 index, uint256 timestamp, address endedBy);
    event DeliverFunds(address to, uint256 amount);

    // Status of Promise
    enum State {
        PENDING,
        FULFILLED,
        REJECTED
    }

    struct Promise {
        bytes32 title; // goal setting: e.g "lose weight 2kg for 2 weeks"
        uint256 runningTime; // time period for promise
        uint256 activeAt; // when promises starts: block.timestamp
        uint256 deadline; // activeAt + running time
        uint256 target; // target action count that fulfills a promise
        uint256 current; // current action count by submitted actions
        uint256 penalty; // reward for supervisor, ether
        address promiser;
        address supervisor;
        bool started;
        bool ended;
        State state;
        Action[] actions;
    }

    struct Action {
        uint256 timestamp;
        bytes32 description; // content for action e.g "did running for 30 mins"
    }

    struct Trust {
        uint256 created; // number of Promises
        uint256 fulfilled; // number of success
        uint256 rejected; // number of failure
        uint256 submitted; // number of Actions
    }

    modifier onlyCreator() {
        require(msg.sender == _CREATOR, "Promiser: Only creator");
        _;
    }

    constructor() {
        _CREATOR = msg.sender;
    }

    // ================================================================== //
    // ============================== core ============================== //
    // ================================================================== //
    // msg.value = penalty + platform fee
    function makePromise(uint256 index, Promise calldata _promise) public payable {
        require(_guardDuplicates(index, _promise.promiser) == true, "Promiser: Duplicate index for Promise");
        require(msg.value >= _PLATFORM_FEE, "Promiser: Insufficient funds for platform fee");
        require(msg.value == _promise.penalty + _PLATFORM_FEE, "Promiser: Penalty should match");
        require(_promise.penalty != 0, "Promiser: Reward for supervisor can't be zero");
        require(_promise.penalty <= _MAXIMUM_PANALTY, "Promiser: Panelty can't be bigger than 0.05 ether");
        require(_promise.promiser != address(0), "Promiser: Promiser must be set");
        require(_promise.supervisor != address(0), "Promiser: Supervistor must be set");
        require(_promise.supervisor != _promise.promiser, "Promiser: Promiser and Supervistor can't be the same");
        require(_promise.runningTime <= _MAXIMUM_RUNNING_TIME, "Promiser: maximum running time is 12 weeks");

        uint256 feeByPromise = msg.value - _promise.penalty;
        _COLLECTED_PLATFORM_FEE += feeByPromise;

        _promiseByWallet[msg.sender][index] = _promise;
        _trustByWallet[msg.sender].created += 1;
        _TOTAL_PROMISE_MADE += 1;

        _historyByWallet[_promise.promiser][index] = true;

        emit MakePromise(index, block.timestamp, msg.sender);
    }

    function startPromise(uint256 index) public {
        require(_promiseByWallet[msg.sender][index].promiser == msg.sender, "Promiser: Invalid promiser");
        require(_promiseByWallet[msg.sender][index].started == false, "Promiser: promise already started");
        require(_promiseByWallet[msg.sender][index].ended == false, "Promiser: Promise already ended");

        uint256 runningTime = _promiseByWallet[msg.sender][index].runningTime;

        _promiseByWallet[msg.sender][index].state = State.PENDING;
        _promiseByWallet[msg.sender][index].started = true;
        _promiseByWallet[msg.sender][index].activeAt = block.timestamp;
        _promiseByWallet[msg.sender][index].deadline = block.timestamp + runningTime;

        emit StartPromise(index, block.timestamp, msg.sender);
    }

    function submitAction(uint256 index, Action calldata action) public {
        require(_promiseByWallet[msg.sender][index].started == true, "Promiser: Promise not started");
        require(_promiseByWallet[msg.sender][index].deadline > block.timestamp, "Promiser: Deadline already passed");
        require(_promiseByWallet[msg.sender][index].promiser == msg.sender, "Promiser: Invalid promiser");

        _promiseByWallet[msg.sender][index].current += 1;
        _promiseByWallet[msg.sender][index].actions.push(action);
        _trustByWallet[msg.sender].submitted += 1;

        emit SubmitAction(index, block.timestamp, action.description, _promiseByWallet[msg.sender][index].actions.length);
    }

    function endPromise(address promiser, uint256 index) public {
        require(_promiseByWallet[promiser][index].started == true, "Promiser: Can't end. Promise not started");
        require(_promiseByWallet[promiser][index].ended == false, "Promiser: Can't end. Promise arleady ended");
        require(_promiseByWallet[promiser][index].deadline <= block.timestamp, "Promiser: Can't end. Deadline not reached");
        require(promiser != address(0), "Promiser: Can't end. Promiser can't be zero address");
        require(promiser == _promiseByWallet[promiser][index].promiser, "Promiser: Can't end. Invalid promiser");
        require(_promiseByWallet[promiser][index].supervisor == msg.sender, "Promiser: Can't end. Invalid supervisor");

        uint256 targetCount = _promiseByWallet[promiser][index].target;
        uint256 actualCount = _promiseByWallet[promiser][index].current;

        _promiseByWallet[promiser][index].ended = true;

        if (targetCount > actualCount) {
            _promiseByWallet[promiser][index].state = State.REJECTED;
            _trustByWallet[promiser].rejected += 1;

            _deliverFunds(_promiseByWallet[promiser][index].supervisor, _promiseByWallet[promiser][index].penalty);
        }

        if (targetCount <= actualCount) {
            _promiseByWallet[promiser][index].state = State.FULFILLED;
            _trustByWallet[promiser].fulfilled += 1;

            _deliverFunds(promiser, _promiseByWallet[promiser][index].penalty);
        }

        _updateRank(promiser);

        // solhint-disable
        emit EndPromise(index, block.timestamp, msg.sender);
    }

    function _guardDuplicates(uint256 index, address promiser) private view returns (bool) {
        return _historyByWallet[promiser][index] == false;
    }

    function _deliverFunds(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Promiser: Fund delivery failure");

        emit DeliverFunds(to, amount);
    }

    function _updateRank(address wallet) private {
        address[100] memory rankers = _TOP_PROMISERS;

        for (uint256 index = 0; index < rankers.length; index++) {
            address ranker = rankers[index];
            bool isHigher = _trustByWallet[wallet].fulfilled > _trustByWallet[ranker].fulfilled ? true : false;

            if (isHigher) {
                _TOP_PROMISERS[index] = wallet;
                break;
            }
        }
    }

    // ================================================================== //
    // ============================= getter ============================= //
    // ================================================================== //
    function getCreator() public view returns (address creator) {
        return _CREATOR;
    }

    function getTotalPromises() public view returns (uint256) {
        return _TOTAL_PROMISE_MADE;
    }

    function getMaximumRunningTime() public view returns (uint256) {
        return _MAXIMUM_RUNNING_TIME;
    }

    function getPlatformFee() public view returns (uint256) {
        return _PLATFORM_FEE;
    }

    function getMaximumPenalty() public view returns (uint256) {
        return _MAXIMUM_PANALTY;
    }

    function getCollectedPlatformFee() public view returns (uint256) {
        return _COLLECTED_PLATFORM_FEE;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPromiseByIndex(address promiser, uint256 index) public view returns (Promise memory) {
        return _promiseByWallet[promiser][index];
    }

    function getTrustByWallet(address wallet) public view returns (Trust memory) {
        return _trustByWallet[wallet];
    }

    function getTopPromisers() public view returns (address[100] memory) {
        return _TOP_PROMISERS;
    }

    // ================================================================== //
    // =========================== platform ============================= //
    // ================================================================== //
    function setCreator(address _newCreator) external onlyCreator {
        require(_newCreator != address(0), "Promiser: Creator can't be zero address");
        _CREATOR = _newCreator;
    }

    function setPlatformFee(uint256 _newFee) external onlyCreator {
        require(_newFee != 0, "Promiser: Fee can't be zero");
        _PLATFORM_FEE = _newFee;
    }

    function collectPlatformFee() external onlyCreator {
        require(_COLLECTED_PLATFORM_FEE != 0, "Promiser: Insufficient collected fee");
        uint256 amount = _COLLECTED_PLATFORM_FEE;

        _COLLECTED_PLATFORM_FEE = 0;
        _deliverFunds(msg.sender, amount);
    }

    function collectUntrackedFunds() external onlyCreator {
        uint256 balance = address(this).balance;
        uint256 trackedAmount = _COLLECTED_PLATFORM_FEE;
        uint256 untrackedAmount = balance - trackedAmount;

        require(untrackedAmount != 0, "Promiser: No untracked funds");
        _deliverFunds(msg.sender, untrackedAmount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}