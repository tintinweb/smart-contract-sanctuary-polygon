// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

import {ERC2771Recipient} from "@opengsn/contracts/src/ERC2771Recipient.sol";
import {IRubixEscrow} from "./IRubixEscrow.sol";
import {IERC20} from "./IERC20.sol";

enum RubixTaskStatus {
    AVAILABLE, // when task is created and no worker is assigned
    READY, // when a worker is assigned to AVAILABLE task
    STARTED, // when a worker has started READY task
    COMPLETED, // when a worker has completed STARTED task
    REJECTED, // when a lead has rejected COMPLETED task
    APPROVED, // when a lead has approved COMPLETED task
    CANCELLED // when a lead has cancelled AVAILABLE, READY, STARTED, COMPLETED task
}

enum RubixProjectStatus {
    AVAILABLE, // when a project is created and no lead is assigned
    READY, // when a lead is assigned to AVAILABLE project
    STARTED, // when a lead has started READY project
    COMPLETED, // when a lead has completed STARTED project
    REJECTED, // when a lead has rejected STARTED project
    APPROVED // when a client has approved COMPLETED project
}

struct RubixTask {
    // Incremental id of a task [0, 65535]
    uint16 id;
    // Name of a task
    string name;
    // Descrpition of a task
    string description;
    // Total pay in USDC assigned to a task
    uint256 totalPay;
    // Remaining pay in USDC assigned to a task
    uint256 currentPay;
    // Address of worker assigned to a task
    address assignedTo;
    // Status of a task
    RubixTaskStatus status;
    // Whether task has been rejected
    bool rejected;
}

contract RubixProject is ERC2771Recipient {
    address private escrowAddress;
    IRubixEscrow private escrowContract;
    address private currencyAddress;
    IERC20 private currencyContract;

    // Name of a project
    string public name;

    // Description of a project
    string public description;

    // Address of a project owner (client)
    address public owner;

    // Address of a project lead
    address public lead;

    // Counter for task id [1, 65535]
    uint16 public counter;

    // Total budget in USDC assigned to the project
    uint256 public totalBudget;

    // Remaining budget in USDC assigned to the project available for tasks (subtract pay for a lead)
    uint256 public taskBudget;

    // IPFS url of logo of the project
    // uint128 public logo;

    // IPFS url of requirements document of the project
    // uint128 public requirements;

    // IPFS url of final outcome of the project (url, image, video, etc.)
    // uint128 public outcome;

    // List of tasks
    mapping(uint32 => RubixTask) public tasks;

    // List of reviewers
    // mapping(uint32 => address) public reviewers;

    // Status of a project
    RubixProjectStatus public status;

    /**
     * Project configurations
     */

    // Pay in USDC that a lead gets when the project is started
    uint256 public startLeaderPay;

    // Pay in USDC that a lead gets when the project is completed
    uint256 public completeLeaderPay;

    // Pay in USDC that a lead gets when the project is approved
    uint256 public approveLeaderPay;

    // Rate of pay in basis point that lead deducts from worker pay
    uint32 public leadPayRate;

    // Rate of pay in basis point that a worker gets when the worker starts a task
    uint32 public startPayRate;

    // Rate of pay in basis point that a worker gets when the worker completes a task
    uint32 public completePayRate;

    // Rate of pay in basis point that a worker gets when the lead approves a task
    uint32 public approvePayRate;

    // uint8 public numberOfReviewers;

    constructor(
        string memory _name,
        string memory _description,
        address _escrowAddress,
        address forwarder,
        address _owner,
        uint256[] memory configs,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        _setTrustedForwarder(forwarder);
        name = _name;
        description = _description;
        owner = _owner;
        totalBudget = configs[0];
        startLeaderPay = configs[1];
        completeLeaderPay = configs[2];
        approveLeaderPay = configs[3];
        leadPayRate = uint32(configs[4]);
        startPayRate = uint32(configs[5]);
        completePayRate = uint32(configs[6]);
        approvePayRate = uint32(configs[7]);
        require(
            startLeaderPay + completeLeaderPay + approveLeaderPay <= totalBudget,
            "Invalid lead pay"
        );
        require(leadPayRate <= 10000, "Invalid lead pay rates");
        require(
            startPayRate + completePayRate + approvePayRate == 10000,
            "Invalid worker pay rates"
        );
        taskBudget = totalBudget - startLeaderPay - completeLeaderPay - approveLeaderPay;
        status = RubixProjectStatus.AVAILABLE;
        counter = 1;
        escrowAddress = _escrowAddress;
        escrowContract = IRubixEscrow(_escrowAddress);
        currencyAddress = escrowContract.getCurrencyAddress();
        currencyContract = IERC20(currencyAddress);
        currencyContract.permit(_owner, escrowAddress, totalBudget, _deadline, v, r, s);
        escrowContract.addFunds(_owner, totalBudget);
    }

    function calcPayByRate(uint256 budget, uint32 rate) internal pure returns (uint256) {
        return (budget * rate) / 10000;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "Owner can call this function");
        _;
    }

    modifier onlyLeader() {
        require(_msgSender() == lead, "Leader can call this function");
        require(lead != address(0), "Leader is not set");
        _;
    }

    modifier onlyWorker(uint32 id) {
        require(tasks[id].assignedTo == _msgSender(), "Worker can call this function");
        _;
    }

    function hireLeader(address _lead) external onlyOwner {
        require(lead == address(0), "Leader is already assigned");
        require(status == RubixProjectStatus.AVAILABLE, "Project is not available");
        lead = _lead;
        status = RubixProjectStatus.READY;
    }

    function fireLeader() external onlyOwner {
        require(lead != address(0), "No leader to fire");
        require(
            status == RubixProjectStatus.AVAILABLE ||
                status == RubixProjectStatus.READY ||
                status == RubixProjectStatus.STARTED ||
                status == RubixProjectStatus.COMPLETED,
            "Task is in invalid state"
        );
        lead = address(0);

        for (uint32 i = 0; i < counter - 1; i++) {
            _cancelTask(i);
        }

        status = RubixProjectStatus.AVAILABLE;
    }

    function startProject() external onlyLeader {
        require(status == RubixProjectStatus.READY, "Project is not ready");
        status = RubixProjectStatus.STARTED;
        currencyContract.transferFrom(escrowAddress, lead, startLeaderPay);
    }

    function completeProject() external onlyLeader {
        require(status == RubixProjectStatus.STARTED, "Project is not started");
        status = RubixProjectStatus.COMPLETED;
        currencyContract.transferFrom(escrowAddress, lead, completeLeaderPay);
    }

    function approveProject() external onlyOwner {
        require(status == RubixProjectStatus.COMPLETED, "Project is not completed");
        status = RubixProjectStatus.APPROVED;
        currencyContract.transferFrom(escrowAddress, lead, approveLeaderPay);
    }

    function rejectProject() external onlyOwner {
        require(status == RubixProjectStatus.COMPLETED, "Project is not completed");
        status = RubixProjectStatus.REJECTED;
    }

    function createTask(
        uint16 taskId,
        string memory taskName,
        string memory taskDescription,
        uint256 pay
    ) external onlyLeader {
        require(tasks[taskId].id == 0, "Task already exists");
        require(counter == taskId, "Task id is not incremental");
        require(taskBudget >= pay, "Not enough budget for tasks");
        RubixTask memory task = RubixTask(
            taskId,
            taskName,
            taskDescription,
            pay,
            pay,
            address(0),
            RubixTaskStatus.AVAILABLE,
            false
        );
        taskBudget -= task.totalPay;
        tasks[taskId] = task;
        counter++;
    }

    function assignTask(uint32 id, address worker) public onlyLeader {
        require(worker != address(0), "Invalid worker");
        require(tasks[id].id > 0, "Task does not exist");
        require(tasks[id].status == RubixTaskStatus.AVAILABLE, "Task is not available");
        tasks[id].assignedTo = worker;
        tasks[id].status = RubixTaskStatus.READY;
    }

    function _cancelTask(uint32 id) internal {
        require(tasks[id].id > 0, "Task does not exist");
        require(tasks[id].status != RubixTaskStatus.APPROVED, "Task is already approved");
        if (tasks[id].status != RubixTaskStatus.CANCELLED) {
            taskBudget += tasks[id].currentPay;
            tasks[id].status = RubixTaskStatus.CANCELLED;
        }
    }

    function cancelTask(uint32 id) external onlyLeader {
        _cancelTask(id);
    }

    function startTask(uint32 id) public onlyWorker(id) {
        require(tasks[id].id > 0, "Task does not exist");
        require(
            tasks[id].status == RubixTaskStatus.READY ||
                tasks[id].status == RubixTaskStatus.REJECTED,
            "Task is not ready"
        );
        if (!tasks[id].rejected) {
            uint256 workerPay = calcPayByRate(tasks[id].totalPay, startPayRate);
            uint256 leadPay = calcPayByRate(workerPay, leadPayRate);
            workerPay = workerPay - leadPay;
            tasks[id].currentPay -= workerPay;
            currencyContract.transferFrom(escrowAddress, tasks[id].assignedTo, workerPay);
            currencyContract.transferFrom(escrowAddress, lead, leadPay);
        }
        tasks[id].status = RubixTaskStatus.STARTED;
    }

    function completeTask(uint32 id) public onlyWorker(id) {
        require(tasks[id].id > 0, "Task does not exist");
        require(tasks[id].status == RubixTaskStatus.STARTED, "Task is not started");
        if (!tasks[id].rejected) {
            uint256 workerPay = calcPayByRate(tasks[id].totalPay, completePayRate);
            uint256 leadPay = calcPayByRate(workerPay, leadPayRate);
            workerPay = workerPay - leadPay;
            tasks[id].currentPay -= workerPay;
            currencyContract.transferFrom(escrowAddress, tasks[id].assignedTo, workerPay);
            currencyContract.transferFrom(escrowAddress, lead, leadPay);
        }
        tasks[id].status = RubixTaskStatus.COMPLETED;
    }

    function approveTask(uint32 id) public onlyLeader {
        require(tasks[id].id > 0, "Task does not exist");
        require(tasks[id].status == RubixTaskStatus.COMPLETED, "Task is not completed");
        uint256 workerPay = calcPayByRate(tasks[id].totalPay, approvePayRate);
        uint256 leadPay = calcPayByRate(workerPay, leadPayRate);
        workerPay = workerPay - leadPay;
        tasks[id].currentPay -= workerPay;
        currencyContract.transferFrom(escrowAddress, tasks[id].assignedTo, workerPay);
        currencyContract.transferFrom(escrowAddress, lead, leadPay);
        tasks[id].status = RubixTaskStatus.APPROVED;
    }

    function rejectTask(uint32 id) public onlyLeader {
        require(tasks[id].id > 0, "Task does not exist");
        require(tasks[id].status == RubixTaskStatus.COMPLETED, "Task is not completed");
        tasks[id].status = RubixTaskStatus.REJECTED;
        tasks[id].rejected = true;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

interface IRubixEscrow {
    function addFunds(address owner, uint256 amount) external;

    function pay(address target, uint256 amount) external;

    function getCurrencyAddress() external view returns (address);
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address owner, address spender, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}