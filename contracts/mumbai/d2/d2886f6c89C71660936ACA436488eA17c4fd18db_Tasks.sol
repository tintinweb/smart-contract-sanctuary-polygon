// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {
    error AlreadyInitialized();
    error NotOwner();

    address private owner;

    function __Escrow_init() external {
        if (owner != address(0)) {
            revert AlreadyInitialized();
        }
        
        owner = msg.sender;
    }

    function transfer(IERC20 token, address to, uint256 amount) external {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        token.transfer(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Escrow } from "./Escrow.sol";

interface ITasks {
    error TaskDoesNotExist();
    error TaskNotOpen();
    error TaskNotTaken();
    error TaskNotClosed();
    error TaskClosed();

    error NotProposer();
    error NotExecutor();

    error RewardAboveBudget(uint8 index);
    error ApplicationDoesNotExist();
    error NotYourApplication();
    error ApplicationNotAccepted();
    error SubmissionAlreadyJudged();

    error RequestDoesNotExist();
    error RequestAlreadyAccepted();

    event TaskCreated(uint256 taskId);
    event ApplicationCreated(uint256 taskId, uint256 applicationId);
    event SubmissionCreated(uint256 taskId, uint256 submissionId);

    /// @notice A container for ERC20 transfer information.
    /// @param tokenContract ERC20 token to transfer.
    /// @param amount How much of this token should be transfered.
    struct ERC20Transfer {
        IERC20 tokenContract;
        uint96 amount;
    }

    /// @notice A container for a reward payout.
    /// @param nextToken If this reward is payed out in the next ERC20 token.
    /// @dev IERC20 (address) is a lot of storage, rather just keep those only in budget.
    /// @param to Whom this token should be transfered to.
    /// @param amount How much of this token should be transfered.
    struct Reward {
        bool nextToken;
        address to; // Might change this to index instead of address array, will do some gas testing
        uint88 amount;
    }

    /// @notice A container for a task application.
    /// @param metadata Metadata of the application. (IPFS hash)
    /// @param timestamp When the application has been made.
    /// @param applicant Who has submitted this application.
    /// @param accepted If the application has been accepted by the proposer.
    /// @param reward How much rewards the applicant want for completion.
    struct Application {
        string metadata;
        uint64 timestamp;
        address applicant;
        bool accepted;
        uint8 rewardCount;
        mapping(uint8 => Reward) reward;
    }

    struct OffChainApplication {
        string metadata;
        uint64 timestamp;
        address applicant;
        bool accepted;
        Reward[] reward;
    }

    enum SubmissionJudgement { None, Accepted, Rejected }
    /// @notice A container for a task submission.
    /// @param metadata Metadata of the submission. (IPFS hash)
    /// @param timestamp When the submission has been made.
    /// @param judgement Judgement cast on the submission.
    /// @param judgementTimestamp When the judgement has been made.
    /// @param feedback A response from the proposer. (IPFS hash)
    struct Submission {
        string metadata;
        uint64 timestamp;
        SubmissionJudgement judgement;
        uint64 judgementTimestamp;
        string feedback;
    }

    enum RequestType { ChangeScope, DropExecutor, CancelTask }

    /// @notice A container for a request to change the scope of a task.
    /// @param accepted When the request was accepted (0 = not accepted)
    /// @param metadata New task metadata. (IPFS hash)
    /// @param deadline New deadline for the task.
    /// @param reward New reward for the executor of the task.
    struct ChangeScopeRequest {
        string metadata;
        uint64 accepted;
        uint64 deadline;
        uint8 rewardCount;
        mapping(uint8 => Reward) reward;
    }

    struct OffChainChangeScopeRequest {
        string metadata;
        uint64 accepted;
        uint64 deadline;
        Reward[] reward;
    }

    /// @notice A container for a request to drop the executor of a task.
    /// @param accepted When the request was accepted (0 = not accepted)
    /// @param explanation Why the executor should be dropped.
    struct DropExecutorRequest {
        string explanation;
        uint64 accepted;
    }

    /// @notice A container for a request to cancel the task.
    /// @param accepted When the request was accepted (0 = not accepted)
    /// @param explanation Why the task should be cancelled.
    struct CancelTaskRequest {
        string explanation;
        uint64 accepted;
    }

    enum TaskState { Open, Taken, Closed }
    /// @notice A container for task-related information.
    /// @param metadata Metadata of the task. (IPFS hash)
    /// @param deadline Block timestamp at which the task expires if not completed.
    /// @param budget Maximum ERC20 rewards that can be earned by completing the task.
    /// @param proposer Who has created the task.
    /// @param creationTimestamp When the task has been created.
    /// @param state Current state the task is in.
    /// @param applications Applications to take the job.
    /// @param executorApplication Index of the application that will execture the task.
    /// @param executorConfirmationTimestamp When the executor has confirmed to take the task.
    /// @param submissions Submission made to finish the task.
    struct Task {
        string metadata;

        uint64 creationTimestamp;
        uint64 executorConfirmationTimestamp;
        uint64 deadline;

        Escrow escrow;

        address proposer;
        TaskState state;
        uint16 executorApplication;
        uint8 budgetCount;
        uint16 applicationCount;
        uint8 submissionCount;
        uint8 changeScopeRequestCount;
        uint8 dropExecutorRequestCount;
        uint8 cancelTaskRequestCount;

        mapping(uint8 => ERC20Transfer) budget;
        mapping(uint16 => Application) applications;
        mapping(uint8 => Submission) submissions;
        mapping(uint8 => ChangeScopeRequest) changeScopeRequests;
        mapping(uint8 => DropExecutorRequest) dropExecutorRequests;
        mapping(uint8 => CancelTaskRequest) cancelTaskRequests;
    }

    struct OffChainTask {
        string metadata;
        uint64 deadline;
        uint64 creationTimestamp;
        uint64 executorConfirmationTimestamp;
        uint16 executorApplication;
        address proposer;
        TaskState state;
        Escrow escrow;
        ERC20Transfer[] budget;
        OffChainApplication[] applications;
        Submission[] submissions;
        OffChainChangeScopeRequest[] changeScopeRequests;
        DropExecutorRequest[] dropExecutorRequests;
        CancelTaskRequest[] cancelTaskRequests;
    }

    /// @notice Retrieves the current amount of created tasks.
    function taskCount() external view returns (uint256);
    
    /// @notice Retrieves the current statistics of created tasks.
    function taskStatistics() external view returns (uint256 openTasks, uint256 takenTasks, uint256 successfulTasks);

    /// @notice Retrieves all task information by id.
    /// @param _taskId Id of the task.
    function getTask(
        uint256 _taskId
    ) external view returns (OffChainTask memory);
    
    /// @notice Retrieves multiple tasks.
    /// @param _taskIds Ids of the tasks.
    function getTasks(
        uint256[] calldata _taskIds
    ) external view returns (OffChainTask[] memory);
    
    /// @notice Retrieves all tasks of a proposer. Most recent ones first.
    /// @param _proposer The proposer to fetch tasks of.
    /// @param _fromTaskId What taskId to start from.
    /// @param _max The maximum amount of tasks to return. 0 for no max.
    function getProposingTasks(
        address _proposer,
        uint256 _fromTaskId,
        uint256 _max
    ) external view returns (OffChainTask[] memory);
    
    /// @notice Retrieves all tasks of an executor. Most recent ones first.
    /// @param _executor The executor to fetch tasks of.
    /// @param _fromTaskId What taskId to start from.
    /// @param _max The maximum amount of tasks to return. 0 for no max.
    function getExecutingTasks(
        address _executor,
        uint256 _fromTaskId,
        uint256 _max
    ) external view returns (OffChainTask[] memory);

    /// @notice Create a new task.
    /// @param _metadata Metadata of the task. (IPFS hash)
    /// @param _deadline Block timestamp at which the task expires if not completed.
    /// @param _budget Maximum ERC20 rewards that can be earned by completing the task.
    /// @return taskId Id of the newly created task.
    function createTask(
        string calldata _metadata,
        uint64 _deadline,
        ERC20Transfer[] calldata _budget
    ) external returns (uint256 taskId);
    
    /// @notice Apply to take the task.
    /// @param _taskId Id of the task.
    /// @param _metadata Metadata of your application.
    /// @param _reward Wanted rewards for completing the task.
    function applyForTask(
        uint256 _taskId,
        string calldata _metadata,
        Reward[] calldata _reward
    ) external returns (uint16 applicationId);
    
    /// @notice Accept application to allow them to take the task.
    /// @param _taskId Id of the task.
    /// @param _applications Indexes of the applications to accept.
    function acceptApplications(
        uint256 _taskId,
        uint16[] calldata _applications
    ) external;
    
    /// @notice Take the task after your application has been accepted.
    /// @param _taskId Id of the task.
    /// @param _application Index of application you made that has been accepted.
    function takeTask(
        uint256 _taskId,
        uint16 _application
    ) external;
    
    /// @notice Create a submission.
    /// @param _taskId Id of the task.
    /// @param _metadata Metadata of the submission. (IPFS hash)
    function createSubmission(
        uint256 _taskId,
        string calldata _metadata
    ) external returns (uint8 submissionId);
    
    /// @notice Review a submission.
    /// @param _taskId Id of the task.
    /// @param _submission Index of the submission that is reviewed.
    /// @param _judgement Outcome of the review.
    /// @param _feedback Reasoning of the reviewer. (IPFS hash)
    function reviewSubmission(
        uint256 _taskId,
        uint8 _submission,
        SubmissionJudgement _judgement,
        string calldata _feedback
    ) external;

    /// @notice Change the scope of the task. This updates the description, deadline and reward of the task.
    /// @param _taskId Id of the task.
    /// @param _newMetadata New description of the task. (IPFS hash)
    /// @param _newDeadline New deadline of the task.
    /// @param _newReward New reward of the task.
    function changeTaskScope(
        uint256 _taskId,
        string calldata _newMetadata,
        uint64 _newDeadline,
        Reward[] calldata _newReward
    ) external returns (uint8 changeTaskRequestId);

    /// @notice Drops the current executor of the task
    /// @param _taskId Id of the task.
    /// @param _explanation Why the executor should be dropped.
    function dropExecutor(
        uint256 _taskId,
        string calldata _explanation
    ) external returns (uint8 dropExecutorRequestId);

    /// @notice Cancels a task. This can be used to close a task and receive back the budget.
    /// @param _taskId Id of the task.
    /// @param _explanation Why the task was cancelled. (IPFS hash)
    function cancelTask(
        uint256 _taskId,
        string calldata _explanation
    ) external returns (uint8 cancelTaskRequestId);

    /// @notice Accepts a request, executing the proposed action.
    /// @param _taskId Id of the task.
    /// @param _requestType What kind of request it is.
    /// @param _requestId Id of the request.
    function acceptRequest(
        uint256 _taskId,
        RequestType _requestType,
        uint8 _requestId
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ITasks, IERC20, Escrow } from "./ITasks.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract Tasks is ITasks {
    /// @notice The incremental ID for tasks.
    uint256 private taskCounter;

    /// @notice Various statistics about total tasks.
    uint256 private openTasks;
    uint256 private takenTasks;
    uint256 private successfulTasks;

    /// @notice A mapping between task IDs and task information.
    mapping(uint256 => Task) internal tasks;

    /// @notice The base escrow contract that will be cloned for every task.
    address private escrowImplementation;

    constructor() {
        escrowImplementation = address(new Escrow());
    }

    /// @inheritdoc ITasks
    function taskCount() external view returns (uint256) {
        return taskCounter;
    }
    
    /// @inheritdoc ITasks
    function taskStatistics() external view returns (uint256, uint256, uint256) {
        return (openTasks, takenTasks, successfulTasks);
    }

    /// @inheritdoc ITasks
    function getTask(
        uint256 _taskId
    ) public view returns (OffChainTask memory offchainTask) {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task = tasks[_taskId];
        offchainTask.metadata = task.metadata;
        offchainTask.deadline = task.deadline;
        offchainTask.creationTimestamp = task.creationTimestamp;
        offchainTask.executorConfirmationTimestamp = task.executorConfirmationTimestamp;
        offchainTask.executorApplication = task.executorApplication;
        offchainTask.proposer = task.proposer;
        offchainTask.state = task.state;
        offchainTask.escrow = task.escrow;

        offchainTask.budget = new ERC20Transfer[](task.budgetCount);
        for (uint8 i; i < offchainTask.budget.length; ) {
            offchainTask.budget[i] = task.budget[i];
            unchecked {
                ++i;
            }
        }
        
        offchainTask.applications = new OffChainApplication[](task.applicationCount);
        for (uint8 i; i < offchainTask.applications.length; ) {
            Application storage application = task.applications[i];
            offchainTask.applications[i].metadata = application.metadata;
            offchainTask.applications[i].timestamp = application.timestamp;
            offchainTask.applications[i].applicant = application.applicant;
            offchainTask.applications[i].accepted = application.accepted;
            offchainTask.applications[i].reward = new Reward[](application.rewardCount);
            for (uint8 j; j < offchainTask.applications[i].reward.length; ) {
                offchainTask.applications[i].reward[j] = application.reward[j];
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        offchainTask.submissions = new Submission[](task.submissionCount);
        for (uint8 i; i < offchainTask.submissions.length; ) {
            offchainTask.submissions[i] = task.submissions[i];
            unchecked {
                ++i;
            }
        }

        offchainTask.changeScopeRequests = new OffChainChangeScopeRequest[](task.changeScopeRequestCount);
        for (uint8 i; i < offchainTask.changeScopeRequests.length; ) {
            offchainTask.changeScopeRequests[i].metadata = task.changeScopeRequests[i].metadata;
            offchainTask.changeScopeRequests[i].accepted = task.changeScopeRequests[i].accepted;
            offchainTask.changeScopeRequests[i].deadline = task.changeScopeRequests[i].deadline;
            offchainTask.changeScopeRequests[i].reward = new Reward[](task.changeScopeRequests[i].rewardCount);
            for (uint8 j; j < offchainTask.changeScopeRequests[i].reward.length; ) {
                offchainTask.changeScopeRequests[i].reward[j] = task.changeScopeRequests[i].reward[j];
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        offchainTask.dropExecutorRequests = new DropExecutorRequest[](task.dropExecutorRequestCount);
        for (uint8 i; i < offchainTask.dropExecutorRequests.length; ) {
            offchainTask.dropExecutorRequests[i] = task.dropExecutorRequests[i];
            unchecked {
                ++i;
            }
        }

        offchainTask.cancelTaskRequests = new CancelTaskRequest[](task.cancelTaskRequestCount);
        for (uint8 i; i < offchainTask.cancelTaskRequests.length; ) {
            offchainTask.cancelTaskRequests[i] = task.cancelTaskRequests[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ITasks
    function getTasks(
        uint256[] memory _taskIds
    ) public view returns (OffChainTask[] memory) {
        OffChainTask[] memory offchainTasks = new OffChainTask[](_taskIds.length);
        for (uint i; i < _taskIds.length; ) {
            offchainTasks[i] = getTask(_taskIds[i]);

            unchecked {
                ++i;
            }
        }
        return offchainTasks;
    }
    
    /// @inheritdoc ITasks
    function getProposingTasks(
        address _proposer,
        uint256 _fromTaskId,
        uint256 _max
    ) external view returns (OffChainTask[] memory) {
        uint256 totalTasks = taskCounter;
        uint256[] memory taskIndexes = new uint256[](totalTasks);
        uint256 proposerTasksCount;
        if (_fromTaskId == 0) {
            _fromTaskId = totalTasks - 1;
        }
        for (uint i = _fromTaskId; i != type(uint).max; ) {
            if (tasks[i].proposer == _proposer) {
                taskIndexes[proposerTasksCount] = i;
                unchecked {
                    ++proposerTasksCount;
                }
                if (proposerTasksCount == _max) {
                    // _max == 0 never triggering is on purpose
                    break;
                }
            }

            unchecked {
                --i;
            }
        }
        // decrease length of array to match real entries
        assembly { mstore(taskIndexes, sub(mload(taskIndexes), sub(totalTasks, proposerTasksCount))) }
        return getTasks(taskIndexes);
    }
    
    /// @inheritdoc ITasks
    function getExecutingTasks(
        address _executor,
        uint256 _fromTaskId,
        uint256 _max
    ) external view returns (OffChainTask[] memory) {
        uint256 totalTasks = taskCounter;
        uint256[] memory taskIndexes = new uint256[](totalTasks);
        uint256 executorTasksCount;
        if (_fromTaskId == 0) {
            _fromTaskId = totalTasks - 1;
        }
        for (uint i = _fromTaskId; i != type(uint).max; ) {
            if (tasks[i].state != TaskState.Open && tasks[i].applications[tasks[i].executorApplication].applicant == _executor) {
                taskIndexes[executorTasksCount] = i;
                unchecked {
                    ++executorTasksCount;
                }
                if (executorTasksCount == _max) {
                    // _max == 0 never triggering is on purpose
                    break;
                }
            }

            unchecked {
                --i;
            }
        }
        // decrease length of array to match real entries
        assembly { mstore(taskIndexes, sub(mload(taskIndexes), sub(totalTasks, executorTasksCount))) }
        return getTasks(taskIndexes);
    }

    /// @inheritdoc ITasks
    function createTask(
        string calldata _metadata,
        uint64 _deadline,
        ERC20Transfer[] calldata _budget
    ) external returns (uint256 taskId) {
        unchecked {
            taskId = taskCounter++;
        }

        Task storage task = tasks[taskId];
        task.metadata = _metadata;
        task.deadline = _deadline;
        task.budgetCount = uint8(_budget.length);
        Escrow escrow = Escrow(Clones.clone(escrowImplementation));
        escrow.__Escrow_init();
        task.escrow = escrow;
        for (uint8 i; i < _budget.length; ) {
            _budget[i].tokenContract.transferFrom(msg.sender, address(escrow), _budget[i].amount);
            task.budget[i] = _budget[i];
            unchecked {
                ++i;
            }
        }
        
        task.creationTimestamp = uint64(block.timestamp);
        task.proposer = msg.sender;

        // Default values are already correct (save gas)
        // task.state = TaskState.Open;
        unchecked {
            ++openTasks;
        }

        emit TaskCreated(taskId);
    }

    /// @inheritdoc ITasks
    function applyForTask(
        uint256 _taskId,
        string calldata _metadata,
        Reward[] calldata _reward
    ) external returns (uint16 applicationId) {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task = tasks[_taskId];
        if (task.state != TaskState.Open) {
            revert TaskNotOpen();
        }

        Application storage application = task.applications[task.applicationCount];
        unchecked {
            applicationId = task.applicationCount++;
        }
        application.metadata = _metadata;
        application.timestamp = uint64(block.timestamp);
        application.applicant = msg.sender;
        application.rewardCount = uint8(_reward.length);

        uint8 j;
        ERC20Transfer memory erc20Transfer = task.budget[0];
        uint256 alreadyReserved;
        for (uint8 i; i < uint8(_reward.length); ) {
            // erc20Transfer.amount -= _reward[i].amount (underflow error, but that is not a nice custom once)
            unchecked {
                alreadyReserved += _reward[i].amount;
            }
            if (alreadyReserved > erc20Transfer.amount) {
                revert RewardAboveBudget(i);
            }

            application.reward[i] = _reward[i];

            if (_reward[i].nextToken) {
                alreadyReserved = 0;
                unchecked {
                    erc20Transfer = task.budget[++j];
                }
            }

            unchecked {
                ++i;
            }
        }

        emit ApplicationCreated(_taskId, applicationId);
    }
    
    /// @inheritdoc ITasks
    function acceptApplications(
        uint256 _taskId,
        uint16[] calldata _applications
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }
        
        Task storage task = tasks[_taskId];
        if (task.state != TaskState.Open) {
            revert TaskNotOpen();
        }
        if (task.proposer != msg.sender) {
            revert NotProposer();
        }

        for (uint i; i < _applications.length; ) {
            if (_applications[i] >= task.applicationCount) {
                revert ApplicationDoesNotExist();
            }
            
            task.applications[_applications[i]].accepted = true;
            unchecked {
                ++i;
            }
        }
    }
    
    /// @inheritdoc ITasks
    function takeTask(
        uint256 _taskId,
        uint16 _application
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }
        
        Task storage task = tasks[_taskId];
        if (task.state != TaskState.Open) {
            revert TaskNotOpen();
        }
        Application storage application_ = task.applications[_application];
        if (application_.applicant != msg.sender) {
            revert NotYourApplication();
        }
        if (!application_.accepted) {
            revert ApplicationNotAccepted();
        }

        task.executorApplication = _application;
        task.executorConfirmationTimestamp = uint64(block.timestamp);

        task.state = TaskState.Taken;
        unchecked {
            --openTasks;
            ++takenTasks;
        }
    }
    
    /// @inheritdoc ITasks
    function createSubmission(
        uint256 _taskId,
        string calldata _metadata
    ) external returns (uint8 submissionId) {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }
        
        Task storage task = tasks[_taskId];
        if (task.state != TaskState.Taken) {
            revert TaskNotTaken();
        }
        if (task.applications[task.executorApplication].applicant != msg.sender) {
            revert NotExecutor();
        }

        Submission storage submission = task.submissions[task.submissionCount];
        unchecked { 
            submissionId = task.submissionCount++;
        }
        submission.metadata = _metadata;
        submission.timestamp = uint64(block.timestamp);

        emit SubmissionCreated(_taskId, submissionId);
    }
    
    /// @inheritdoc ITasks
    function reviewSubmission(
        uint256 _taskId,
        uint8 _submission,
        SubmissionJudgement _judgement,
        string calldata _feedback
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }
        
        Task storage task = tasks[_taskId];
        if (task.state != TaskState.Taken) {
            revert TaskNotTaken();
        }
        if (task.proposer != msg.sender) {
            revert NotProposer();
        }

        Submission storage submission_ = task.submissions[_submission];
        if (submission_.judgement != SubmissionJudgement.None) {
            revert SubmissionAlreadyJudged();
        }
        // You can judge with judgement None, to give feedback without any judgement yet
        // You can then call this function again to overwrite the feedback (kinda like a draft)
        submission_.judgement = _judgement;
        submission_.judgementTimestamp = uint64(block.timestamp);
        submission_.feedback = _feedback;

        if (_judgement == SubmissionJudgement.Accepted) {
            Application storage executor = task.applications[task.executorApplication];
            address proposer = task.proposer;
            Escrow escrow = task.escrow;

            uint8 j;
            ERC20Transfer memory erc20Transfer = task.budget[0];
            uint8 rewardCount = executor.rewardCount;
            for (uint8 i; i < rewardCount; ) {
                Reward memory reward = executor.reward[i];
                escrow.transfer(erc20Transfer.tokenContract, executor.applicant, reward.amount);
                unchecked {
                    erc20Transfer.amount -= reward.amount;
                }

                if (reward.nextToken) {
                    if (erc20Transfer.amount > 0) {
                        escrow.transfer(erc20Transfer.tokenContract, proposer, erc20Transfer.amount);
                    }

                    unchecked {
                        erc20Transfer = task.budget[++j];
                    }
                }

                unchecked {
                    ++i;
                }
            }
            uint8 budgetCount = task.budgetCount;
            while (j < budgetCount) {
                escrow.transfer(erc20Transfer.tokenContract, proposer, erc20Transfer.amount);
                
                unchecked {
                    erc20Transfer = task.budget[++j];
                }
            }

            task.state = TaskState.Closed;
            unchecked {
                --takenTasks;
                ++successfulTasks;
            }
        }
    }
    
    /// @inheritdoc ITasks
    function changeTaskScope(
        uint256 _taskId,
        string calldata _newMetadata,
        uint64 _newDeadline,
        Reward[] calldata _newReward
    ) external returns (uint8 changeTaskRequestId) {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task = tasks[_taskId];
        if (task.state != TaskState.Taken) {
            revert TaskNotTaken();
        }
        if (task.proposer != msg.sender) {
            revert NotProposer();
        }

        ChangeScopeRequest storage request = task.changeScopeRequests[task.changeScopeRequestCount];
        request.metadata = _newMetadata;
        request.deadline = _newDeadline;
        request.rewardCount = uint8(_newReward.length);

        uint8 j;
        ERC20Transfer memory erc20Transfer = task.budget[0];
        uint256 needed;
        for (uint8 i; i < uint8(_newReward.length); ) {
            unchecked {
                needed += _newReward[i].amount;
            }

            request.reward[i] = _newReward[i];

            if (_newReward[i].nextToken) {
                if (needed > erc20Transfer.amount) {
                    // Excisting budget in escrow doesnt cover the new reward
                    erc20Transfer.tokenContract.transferFrom(msg.sender, address(task.escrow), needed - erc20Transfer.amount);
                }

                needed = 0;
                unchecked {
                    erc20Transfer = task.budget[++j];
                }
            }

            unchecked {
                ++i;
            }
        }

        unchecked {
            return task.changeScopeRequestCount++;
        }
    }

    /// @inheritdoc ITasks
    function dropExecutor(
        uint256 _taskId,
        string calldata _explanation
    ) external returns (uint8 dropExecutorRequestId) {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task = tasks[_taskId];
        if (task.state != TaskState.Taken) {
            revert TaskNotTaken();
        }
        if (task.proposer != msg.sender) {
            revert NotProposer();
        }

        DropExecutorRequest storage request = task.dropExecutorRequests[task.dropExecutorRequestCount];
        request.explanation = _explanation;
        unchecked {
            return task.dropExecutorRequestCount++;
        }
    }

    /// @inheritdoc ITasks
    function cancelTask(
        uint256 _taskId,
        string calldata _explanation
    ) external returns (uint8 cancelTaskRequestId) {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task = tasks[_taskId];
        if (task.proposer != msg.sender) {
            revert NotProposer();
        }

        if (task.state == TaskState.Taken) {
            if (task.deadline > uint64(block.timestamp)) {
                // Deadline has not passed yet
                CancelTaskRequest storage request = task.cancelTaskRequests[task.cancelTaskRequestCount];
                request.explanation = _explanation;
                unchecked {
                    return task.cancelTaskRequestCount++;
                }
            }
        }
        else if (task.state != TaskState.Open) {
            revert TaskClosed();
        }

        _refundProposer(task);
        // Max means no request
        return type(uint8).max;
    }

    function acceptRequest(
        uint256 _taskId,
        RequestType _requestType,
        uint8 _requestId
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task = tasks[_taskId];
        if (task.state != TaskState.Taken) {
            revert TaskNotTaken();
        }
        if (task.applications[task.executorApplication].applicant != msg.sender) {
            revert NotExecutor();
        }
        
        if (_requestType == RequestType.ChangeScope) {
            if (_requestId >= task.changeScopeRequestCount) {
                revert RequestDoesNotExist();
            }

            ChangeScopeRequest storage request = task.changeScopeRequests[_requestId];
            if (request.accepted != 0) {
                revert RequestAlreadyAccepted();
            }

            task.metadata = request.metadata;
            task.deadline = request.deadline;
            Application storage executor = task.applications[task.executorApplication];
            uint8 rewardCount = request.rewardCount;
            executor.rewardCount = rewardCount;
            for (uint8 i; i < rewardCount; ) {
                executor.reward[i] = request.reward[i];

                unchecked {
                    ++i;
                }
            }

            request.accepted = uint64(block.timestamp);
        } else if (_requestType == RequestType.DropExecutor) {
            if (_requestId >= task.dropExecutorRequestCount) {
                revert RequestDoesNotExist();
            }
            
            DropExecutorRequest storage request = task.dropExecutorRequests[_requestId];
            if (request.accepted != 0) {
                revert RequestAlreadyAccepted();
            }

            task.state = TaskState.Open;
            unchecked {
                --takenTasks;
                ++openTasks;
            }

            request.accepted = uint64(block.timestamp);
        } else { // if (_requestType == RequestType.CancelTask) {
            if (_requestId >= task.cancelTaskRequestCount) {
                revert RequestDoesNotExist();
            }
            
            CancelTaskRequest storage request = task.cancelTaskRequests[_requestId];
            if (request.accepted != 0) {
                revert RequestAlreadyAccepted();
            }

            _refundProposer(task);

            request.accepted = uint64(block.timestamp);
        }
    }
    
    function _refundProposer(Task storage task) internal {
        uint8 budgetCount = task.budgetCount;
        address proposer = task.proposer;
        Escrow escrow = task.escrow;
        for (uint8 i; i < budgetCount; ) {
            ERC20Transfer memory erc20Transfer = task.budget[i];
            escrow.transfer(erc20Transfer.tokenContract, proposer, erc20Transfer.amount);

            unchecked {
                ++i;
            }
        }

        if (task.state == TaskState.Open) {
            unchecked {
                --openTasks;
            }
        } else if (task.state == TaskState.Taken) {
            unchecked {
                --takenTasks;
            }
        }
        task.state = TaskState.Closed;
    }
}