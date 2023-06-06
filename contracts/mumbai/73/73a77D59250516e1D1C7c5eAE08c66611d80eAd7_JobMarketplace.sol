// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JobMarketplace is Ownable {
    
    event JobCreated(address indexed _sender, uint jobId, uint256 _reward);
    event JobCancelled(uint jobId);
    event JobFinished(uint jobId);
    event WorkerRegistered(uint jobId, uint workerId);
    event JobSubmitted(uint workerId);
    event JobDoneValidated(uint workerId);

    enum Status { Pending, Active, Finished, Cancelled }

    struct Job {
        Status status; 
        uint reward;
        address owner;
    }
    
    struct Worker {
        bool finished;
        uint jobId;
        bool valid;
        address worker;
    }

    mapping(uint => Job) public jobs;
    mapping(uint => Worker) public workers;
    mapping(uint => address) public rewardsToShare;

    using Counters for Counters.Counter;
    Counters.Counter private _jobIdCounter;
    Counters.Counter private _workerIdCounter;

    constructor() {
    }

    function createJob() payable external {
        uint256 jobId = _jobIdCounter.current();
        jobs[jobId] = Job(Status.Pending, msg.value, msg.sender);
        _jobIdCounter.increment();

        emit JobCreated(msg.sender, jobId, msg.value);
    }

    function cancelJob(uint256 jobId) external {
        require(jobs[jobId].status != Status.Finished && jobs[jobId].status != Status.Cancelled, "status invalid"); // check business rules
        require(jobs[jobId].owner == msg.sender, "owner is diff than sender");

        jobs[jobId].status = Status.Cancelled;

        payable(msg.sender).transfer(jobs[jobId].reward);

        emit JobCancelled(jobId);
    }

    function finishJob(uint256 jobId) external {
        require(jobs[jobId].status != Status.Finished && jobs[jobId].status != Status.Cancelled, "status invalid"); // check business rules
        require(jobs[jobId].owner == msg.sender, "owner is diff than sender");

        jobs[jobId].status = Status.Finished;

        // // share rewards with workers
        // // access reward mapping
        // workers
        // payable(this).transfer(jobs[jobId].reward);

        emit JobFinished(jobId);
    }

    function registerWorker(uint256 jobId) external {
        require(jobs[jobId].status != Status.Finished && jobs[jobId].status != Status.Cancelled, "status invalid"); // check business rules 
        
        uint256 workerId = _workerIdCounter.current();
        workers[workerId] = Worker(false, jobId, false, msg.sender);
        _workerIdCounter.increment();

        jobs[jobId].status = Status.Active; 

        emit WorkerRegistered(jobId, workerId);
    }

    function submitJobTrained(uint256 workerId) external {
        require(workers[workerId].worker == msg.sender, "worker is diff than sender");

        workers[workerId].finished = true;
        workers[workerId].valid = true;

        // rewardsToShare[workers[workerId].jobId] = msg.sender
        payable(msg.sender).transfer(1 ether);

        emit JobSubmitted(workerId);
    }

    // function validateWorkerJob(uint256 workerId) external onlyOwner {
    //     require(!workers[workerId].valid, "worker must be not validated");
    //     workers[workerId].valid = true
    //     // add reward to this worker, maybe create a new dictionary to save all rewards need to be taken

    //     worker.receiveReward = true

    //     emit JobDoneValidated(workerId);
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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