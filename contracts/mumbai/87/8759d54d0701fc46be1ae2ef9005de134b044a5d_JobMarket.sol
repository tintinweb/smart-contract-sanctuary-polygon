/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts/Accountable.sol


pragma solidity >=0.8.4 <0.9.0;


abstract contract Accountable {
    using EnumerableSet for EnumerableSet.UintSet;
    //events
    //Job Owner
    event JobRegistered(
        address indexed _jobOwner,
        uint256 indexed _jobBudget,
        string indexed _jobName,
        uint256 _jobId
    );

    event BidAccepted(
        address indexed _jobOwner,
        address indexed _jobWorker,
        uint256 _jobId,
        uint256 _bidAmount
    );

    event FundWithdrawSuccessfully(address indexed _jobOwner, uint256 _amount);

    //Worker
    event WorkerRegisterSuccessfully(
        address indexed _worker,
        string _workerName,
        uint256 _workerId
    );

    event SuccessfullyBid(
        address indexed _workerAdd,
        uint256 indexed _jobId,
        uint256 indexed _bidAmount
    );

    event BidModifiedSuccessfully(
        address indexed _workerAdd,
        uint256 indexed _jobId,
        uint256 indexed _bidAmount,
        uint256 _prevBidAmount
    );

    event jobCompleted(
        address indexed _jobWorker,
        uint256 indexed _jobId,
        uint256 _amount
    );

    struct Worker {
        uint256 workerId;
        string workerName;
        bool isWorking;
        uint32 workerRegisteredDate;
        uint256 jobsCompleted;
        uint256 totalEarned;
    }

    struct Job {
        uint256 jobId;
        string jobName;
        string jobDescription;
        address jobOwner;
        address jobWorker;
        bool isCompleted;
        bool isJobValid;
        uint32 jobRegisteredDate;
        uint32 jobStartedDate;
        uint32 jobCompletedDate;
        uint256 jobBudget;
        uint256 jobSettledAmount;
    }

    struct Bidder {
        uint256 jobId;
        address bidderAddress;
        uint256 bidAmount;
    }

    uint256 public _jobIds;

    mapping(uint256 => Job) public _jobs;

    EnumerableSet.UintSet internal _liveJobs;

    mapping(address => uint256) public _fundByJobOwner;

    mapping(address => uint256) public _jobOwnerFundLocked;

    uint256 public _workerIds;

    mapping(address => Worker) public _workers;

    mapping(address => bool) public _validWorkers;

    mapping(uint256 => Bidder[]) public _biddersDetails;


    //modifiers
    modifier onlyJobOwner(uint256 _jobId) {
        Job memory _job = _jobs[_jobId];
        require(
            msg.sender == _job.jobOwner,
            "Only owner of the job will accept the bid."
        );
        _;
    }

    modifier onlyJobWorker(uint256 _jobId) {
        Job memory _job = _jobs[_jobId];
        require(msg.sender == _job.jobWorker, "Only job worker allowed.");
        _;
    }

    modifier newJob(uint256 _jobId) {
        Job memory _job = _jobs[_jobId];
        require(_job.jobWorker == address(0x0), "Worker already assigned.");
        _;
    }

    modifier validJob(uint256 _jobId) {
        require(_jobId <= _jobIds, "Job does not exists.");
        _;
    }

    modifier notOwner(uint256 _jobId) {
        Job memory _job = _jobs[_jobId];
        require(
            msg.sender != _job.jobOwner,
            "Job owner not allowed to place bid."
        );
        _;
    }

    //functions
    function extraFund() public view returns (uint256) {
        return (_fundByJobOwner[msg.sender] - _jobOwnerFundLocked[msg.sender]);
    }

    function seeJob(uint256 _jobId) public view returns (Job memory) {
        return _jobs[_jobId];
    }

    function seeWorker(address _worker) public view returns (Worker memory) {
        return _workers[_worker];
    }

    function isJobActive(uint256 _jobId)
        public
        view
        validJob(_jobId)
        returns (bool)
    {
        return (_liveJobs.contains(_jobId));
    }

    function activeJobsLen() external view returns (uint256) {
        return _liveJobs.length();
    }

    function activeJobs() external view returns (bytes32[] memory) {
        return _liveJobs._inner._values;
    }

    function allBidders(uint256 _jobId) external view validJob(_jobId) returns (Bidder[] memory) {
        return _biddersDetails[_jobId];
    }
}

// File: contracts/workers/WorkerJobs.sol


pragma solidity >=0.8.4 <0.9.0;


abstract contract WorkerJobs is Accountable {
    using EnumerableSet for EnumerableSet.UintSet;

    function bidJob(uint256 _jobId, uint256 _bidAmount)
        external
        notOwner(_jobId)
        validJob(_jobId)
        newJob(_jobId)
    {
        if (!_validWorkers[msg.sender]) revert("InvalidWorker");
        if(_bidAmount == 0) revert("BidAmountShouldNotZero");

        for (uint256 i = 0; i < _biddersDetails[_jobId].length; i++) {
            if (_biddersDetails[_jobId][i].bidderAddress == msg.sender)
                revert("AlreadyBided");
        }

        Worker memory _worker = _workers[msg.sender];
        if (_worker.isWorking) revert("AlreadyWorking");

        Job storage _job = _jobs[_jobId];
        if (_bidAmount > _job.jobBudget) revert("OverBudget");
        

        _biddersDetails[_jobId].push(Bidder(_jobId, msg.sender, _bidAmount));

        emit SuccessfullyBid(msg.sender, _jobId, _bidAmount);
    }

    function modifyBid(uint256 _jobId, uint256 _bidAmount)
        external
        notOwner(_jobId)
        validJob(_jobId)
        newJob(_jobId)
        returns (bool)
    {
        require(_jobId <= _jobIds, "Job does not exist.");

        if (!_validWorkers[msg.sender]) revert("InvalidWorker");
        if(_bidAmount == 0) revert("BidAmountShouldNotZero");

        for (uint256 i = 0; i < _biddersDetails[_jobId].length; i++) {
            if (_biddersDetails[_jobId][i].bidderAddress != msg.sender) {
                continue;
            } else {
                if (_bidAmount >= _biddersDetails[_jobId][i].bidAmount)
                    revert("GreaterThanPreviousBid");

                uint256 _prevBidAmount = _biddersDetails[_jobId][i].bidAmount;

                _biddersDetails[_jobId][i].bidAmount = _bidAmount;
                emit BidModifiedSuccessfully(
                    msg.sender,
                    _jobId,
                    _bidAmount,
                    _prevBidAmount
                );
                return true;
            }
        }
        revert("NotBided");
    }

    function jobDone(uint256 _jobId) external onlyJobWorker(_jobId) {
        require(isJobActive(_jobId), "Job already completed.");
        uint32 timeNow = uint32(block.timestamp);

        Job storage _job = _jobs[_jobId];
        _job.isCompleted = true;
        _job.jobCompletedDate = timeNow;

        uint256 _amountToBePaid;
        for (uint256 i = 0; i < _biddersDetails[_jobId].length; i++) {
            if (_biddersDetails[_jobId][i].bidderAddress == msg.sender)
                _amountToBePaid = _biddersDetails[_jobId][i].bidAmount;
        }
        _jobOwnerFundLocked[_job.jobOwner] -= _amountToBePaid;
        _fundByJobOwner[_job.jobOwner] -= _amountToBePaid;

        Worker storage _worker = _workers[msg.sender];
        _worker.isWorking = false;
        _worker.jobsCompleted++;
        _worker.totalEarned += _amountToBePaid;

        _liveJobs.remove(_jobId);
        payable(msg.sender).transfer(_amountToBePaid);
        emit jobCompleted(msg.sender, _jobId, _amountToBePaid);
    }
}

// File: contracts/workers/WorkerManager.sol


pragma solidity >=0.8.4 <0.9.0;


abstract contract WorkerManager is Accountable{

    function registerWorker(string memory _workerName)external {
        if(_validWorkers[msg.sender]) revert("AlreadyWorker");

        uint32 timeNow = uint32(block.timestamp);
        _workerIds++;

        _workers[msg.sender] = Worker(
            _workerIds,
            _workerName,
            false,
            timeNow,
            0,
            0
        );

        _validWorkers[msg.sender] = true;
        emit WorkerRegisterSuccessfully(msg.sender, _workerName, _workerIds);
    }
}
// File: contracts/workers/Workers.sol


pragma solidity >=0.8.4 <0.9.0;



abstract contract Workers is WorkerManager, WorkerJobs{}
// File: contracts/jobs/JobWorkers.sol


pragma solidity >=0.8.4 <0.9.0;


abstract contract JobWorkers is Accountable {
    function acceptBid(uint256 _jobId, address _workerAdd)
        external
        validJob(_jobId)
        onlyJobOwner(_jobId)
        newJob(_jobId)
    {
        if (!_validWorkers[_workerAdd]) revert("InvalidWorker");

        Worker memory __worker = _workers[_workerAdd];

        if (__worker.isWorking) revert("AlreadyWorking");

        uint32 timeNow = uint32(block.timestamp);

        Job storage _job = _jobs[_jobId];
        _job.jobWorker = _workerAdd;
        _job.jobStartedDate = timeNow;
        for (uint256 i = 0; i < _biddersDetails[_jobId].length; i++) {
            if (_biddersDetails[_jobId][i].bidderAddress == _workerAdd)
                _job.jobSettledAmount = _biddersDetails[_jobId][i].bidAmount;
        }


        uint256 _amountToBeUnlock = (_job.jobBudget - _job.jobSettledAmount);
        _jobOwnerFundLocked[msg.sender] -= _amountToBeUnlock;

        Worker storage _worker = _workers[_workerAdd];
        _worker.isWorking = true;

        emit BidAccepted(msg.sender, _workerAdd, _jobId, _job.jobSettledAmount);
    }

    function withdrawExtraFund() external {
        uint256 _amount = extraFund();
        require(_amount > 0, "No extra Fund.");

        _fundByJobOwner[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit FundWithdrawSuccessfully(msg.sender, _amount);
    }
}

// File: contracts/jobs/JobManager.sol


pragma solidity >=0.8.4 <0.9.0;


abstract contract JobManager is Accountable {
    using EnumerableSet for EnumerableSet.UintSet;
    
    function registerJob(
        string memory _jobName,
        string memory _jobDescription,
        uint256 _jobBudget
    ) external payable {
        require(extraFund() + msg.value >= _jobBudget, "Insufficient Balance.");

        uint32 timeNow = uint32(block.timestamp);
        _jobIds++;

        Job storage _job = _jobs[_jobIds];
        _job.jobId = _jobIds;
        _job.jobName = _jobName;
        _job.jobDescription = _jobDescription;
        _job.jobOwner = payable(msg.sender);
        _job.jobWorker = payable(0x0);
        _job.isCompleted = false;
        _job.isJobValid = true;
        _job.jobRegisteredDate = timeNow;
        _job.jobStartedDate = 0;
        _job.jobCompletedDate = 0;
        _job.jobBudget = _jobBudget;
        _job.jobSettledAmount = 0;

        _liveJobs.add(_jobIds);
        _fundByJobOwner[msg.sender] += msg.value;
        _jobOwnerFundLocked[msg.sender] += _jobBudget;
        emit JobRegistered(msg.sender, _jobBudget, _jobName, _jobIds);
    }
}

// File: contracts/jobs/Jobs.sol


pragma solidity >=0.8.4 <0.9.0;



abstract contract Jobs is JobManager, JobWorkers{}
// File: contracts/JobMarket.sol


pragma solidity >=0.8.4 <0.9.0;



contract JobMarket is Jobs, Workers{

    constructor() Jobs() Workers(){}
}