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

    error NotProposer();
    error NotExecutor();

    error RewardAboveBudget();
    error NotYourApplication();
    error ApplicationNotAccepted();
    error SubmissionAlreadyJudged();
    error DeadlineDidNotPass();

    /// @notice A container for ERC20 transfer information.
    /// @param tokenContract ERC20 token to transfer.
    /// @param amount How much of this token should be transfered.
    struct ERC20Transfer {
        IERC20 tokenContract;
        uint96 amount;
    }

    /// @notice A container for a task application.
    /// @param metadata Metadata of the application. (IPFS hash)
    /// @param timestamp When the application has been made.
    /// @param applicant Who has submitted this application.
    /// @param accepted If the application has been accepted by the proposer.
    /// @param reward How much rewards the applicant want for completion. (just the amount, in the same order as budget)
    struct Application {
        bytes32 metadata;
        uint64 timestamp;
        address applicant;
        bool accepted;
        mapping(uint8 => uint96) reward;
    }

    struct OffChainApplication {
        bytes32 metadata;
        uint64 timestamp;
        address applicant;
        bool accepted;
        uint96[] reward;
    }

    enum SubmissionJudgement { None, Accepted, Rejected }
    /// @notice A container for a task submission.
    /// @param metadata Metadata of the submission. (IPFS hash)
    /// @param timestamp When the submission has been made.
    /// @param judgement Judgement cast on the submission.
    /// @param judgementTimestamp When the judgement has been made.
    /// @param feedback A response from the proposer. (IPFS hash)
    struct Submission {
        bytes32 metadata;
        uint64 timestamp;
        SubmissionJudgement judgement;
        uint64 judgementTimestamp;
        bytes32 feedback;
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
        bytes32 metadata;

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

        mapping(uint8 => ERC20Transfer) budget;
        mapping(uint16 => Application) applications;
        mapping(uint8 => Submission) submissions;
    }

    struct OffChainTask {
        bytes32 metadata;
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
    }

    /// @notice Retrieves the current amount of created tasks.
    function taskCount() external view returns (uint256);

    /// @notice Retrieves all task information by id.
    /// @param _taskId Id of the task.
    function getTask(
        uint256 _taskId
    ) external view returns (OffChainTask memory);

    /// @notice Create a new task.
    /// @param _metadata Metadata of the task. (IPFS hash)
    /// @param _deadline Block timestamp at which the task expires if not completed.
    /// @param _budget Maximum ERC20 rewards that can be earned by completing the task.
    /// @return taskId Id of the newly created task.
    function createTask(
        bytes32 _metadata,
        uint64 _deadline,
        ERC20Transfer[] calldata _budget
    ) external returns (uint256 taskId);
    
    /// @notice Apply to take the task.
    /// @param _taskId Id of the task.
    /// @param _metadata Metadata of your application.
    /// @param _reward Wanted rewards for completing the task.
    function applyForTask(
        uint256 _taskId,
        bytes32 _metadata,
        uint96[] calldata _reward
    ) external;
    
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
        bytes32 _metadata
    ) external;
    
    /// @notice Review a submission.
    /// @param _taskId Id of the task.
    /// @param _submission Index of the submission that is reviewed.
    /// @param _judgement Outcome of the review.
    /// @param _feedback Reasoning of the reviewer. (IPFS hash)
    function reviewSubmission(
        uint256 _taskId,
        uint8 _submission,
        SubmissionJudgement _judgement,
        bytes32 _feedback
    ) external;

    /// @notice Refund a task. This can be used to close a task and receive back the budget.
    /// @param _taskId Id of the task.
    function refundTask(
        uint256 _taskId
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ITasks, IERC20, Escrow } from "./ITasks.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract Tasks is ITasks {
    /// @notice The incremental ID for tasks.
    uint256 private taskCounter;

    /// @notice A mapping between task IDs and task information.
    mapping(uint256 => Task) internal tasks;

    address private escrowImplementation;

    constructor() {
        escrowImplementation = address(new Escrow());
    }

    /// @inheritdoc ITasks
    function taskCount() external view returns (uint256) {
        return taskCounter;
    }

    /// @inheritdoc ITasks
    function getTask(
        uint256 _taskId
    ) external view returns (OffChainTask memory task) {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task_ = tasks[_taskId];
        task.metadata = task_.metadata;
        task.deadline = task_.deadline;
        task.creationTimestamp = task_.creationTimestamp;
        task.executorConfirmationTimestamp = task_.executorConfirmationTimestamp;
        task.executorApplication = task_.executorApplication;
        task.proposer = task_.proposer;
        task.state = task_.state;
        task.escrow = task_.escrow;

        task.budget = new ERC20Transfer[](task_.budgetCount);
        for (uint8 i; i < task.budget.length; ) {
            task.budget[i] = task_.budget[i];
            unchecked {
                ++i;
            }
        }
        
        task.applications = new OffChainApplication[](task_.applicationCount);
        for (uint8 i; i < task.applications.length; ) {
            Application storage application = task_.applications[i];
            task.applications[i].metadata = application.metadata;
            task.applications[i].timestamp = application.timestamp;
            task.applications[i].applicant = application.applicant;
            task.applications[i].accepted = application.accepted;
            task.applications[i].reward = new uint96[](task_.budgetCount);
            for (uint8 j; j < task.applications[i].reward.length; ) {
                task.applications[i].reward[j] = application.reward[j];
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        task.submissions = new Submission[](task_.submissionCount);
        for (uint8 i; i < task.submissions.length; ) {
            task.submissions[i] = task_.submissions[i];
            unchecked {
                ++i;
            }
        }
        
        return task;
    }

    /// @inheritdoc ITasks
    function createTask(
        bytes32 _metadata,
        uint64 _deadline,
        ERC20Transfer[] calldata _budget
    ) external returns (uint256 taskId) {
        unchecked {
            taskId = taskCounter++;
        }

        Task storage task_ = tasks[taskId];
        task_.metadata = _metadata;
        task_.deadline = _deadline;
        task_.budgetCount = uint8(_budget.length);
        Escrow escrow = Escrow(Clones.clone(escrowImplementation));
        escrow.__Escrow_init();
        task_.escrow = escrow;
        for (uint8 i; i < _budget.length; ) {
            _budget[i].tokenContract.transferFrom(msg.sender, address(escrow), _budget[i].amount);
            task_.budget[i] = _budget[i];
            unchecked {
                ++i;
            }
        }
        
        task_.creationTimestamp = uint64(block.timestamp);
        task_.proposer = msg.sender;

        // Default values are already correct (save gas)
        // task_.state = TaskState.Open;
    }

    /// @inheritdoc ITasks
    function applyForTask(
        uint256 _taskId,
        bytes32 _metadata,
        uint96[] calldata _reward
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task_ = tasks[_taskId];
        if (task_.state != TaskState.Open) {
            revert TaskNotOpen();
        }

        Application storage application = task_.applications[task_.applicationCount];
        unchecked {
            ++task_.applicationCount;
        }
        application.metadata = _metadata;
        application.timestamp = uint64(block.timestamp);
        application.applicant = msg.sender;

        uint8 budgetCount = task_.budgetCount;
        for (uint8 i; i < budgetCount; ) {
            if (_reward[i] > task_.budget[i].amount) {
                revert RewardAboveBudget();
            }
            application.reward[i] = _reward[i];

            unchecked {
                ++i;
            }
        }

    }
    
    /// @inheritdoc ITasks
    function acceptApplications(
        uint256 _taskId,
        uint16[] calldata _applications
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }
        
        Task storage task_ = tasks[_taskId];
        if (task_.state != TaskState.Open) {
            revert TaskNotOpen();
        }
        if (task_.proposer != msg.sender) {
            revert NotProposer();
        }

        for (uint i; i < _applications.length; ) {
            task_.applications[_applications[i]].accepted = true;
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
        
        Task storage task_ = tasks[_taskId];
        if (task_.state != TaskState.Open) {
            revert TaskNotOpen();
        }
        Application storage application_ = task_.applications[_application];
        if (application_.applicant != msg.sender) {
            revert NotYourApplication();
        }
        if (!application_.accepted) {
            revert ApplicationNotAccepted();
        }

        task_.state = TaskState.Taken;
        task_.executorApplication = _application;
        task_.executorConfirmationTimestamp = uint64(block.timestamp);
    }
    
    /// @inheritdoc ITasks
    function createSubmission(
        uint256 _taskId,
        bytes32 _metadata
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }
        
        Task storage task_ = tasks[_taskId];
        if (task_.state != TaskState.Taken) {
            revert TaskNotTaken();
        }
        if (task_.applications[task_.executorApplication].applicant != msg.sender) {
            revert NotExecutor();
        }

        unchecked { 
            Submission storage submission = task_.submissions[task_.submissionCount++];
            submission.metadata = _metadata;
            submission.timestamp = uint64(block.timestamp);
        }
    }
    
    /// @inheritdoc ITasks
    function reviewSubmission(
        uint256 _taskId,
        uint8 _submission,
        SubmissionJudgement _judgement,
        bytes32 _feedback
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }
        
        Task storage task_ = tasks[_taskId];
        if (task_.state != TaskState.Taken) {
            revert TaskNotTaken();
        }
        if (task_.proposer != msg.sender) {
            revert NotProposer();
        }

        Submission storage submission_ = task_.submissions[_submission];
        if (submission_.judgement != SubmissionJudgement.None) {
            revert SubmissionAlreadyJudged();
        }
        // You can judge with judgement None, to give feedback without any judgement yet
        // You can then call this function again to overwrite the feedback (kinda like a draft)
        submission_.judgement = _judgement;
        submission_.judgementTimestamp = uint64(block.timestamp);
        submission_.feedback = _feedback;

        if (_judgement == SubmissionJudgement.Accepted) {
            uint8 budgetCount = task_.budgetCount;
            Application storage executor = task_.applications[task_.executorApplication];
            address proposer = task_.proposer;
            Escrow escrow = task_.escrow;
            for (uint8 i; i < budgetCount; ) {
                ERC20Transfer memory erc20Transfer = task_.budget[i];
                uint256 reward = executor.reward[i];
                escrow.transfer(erc20Transfer.tokenContract, executor.applicant, reward);
                uint256 refund = erc20Transfer.amount - reward;
                if (refund != 0) {
                    escrow.transfer(erc20Transfer.tokenContract, proposer, refund);
                }

                unchecked {
                    ++i;
                }
            }
            task_.state = TaskState.Closed;
        }
    }

    /// @inheritdoc ITasks
    function refundTask(
        uint256 _taskId
    ) external {
        if (_taskId >= taskCounter) {
            revert TaskDoesNotExist();
        }

        Task storage task_ = tasks[_taskId];
        if (task_.state == TaskState.Taken) {
            if (task_.deadline < uint64(block.timestamp)) {
                revert DeadlineDidNotPass();
            }
        }
        else if (task_.state != TaskState.Open) {
            revert TaskNotOpen();
        }

        uint8 budgetCount = task_.budgetCount;
        address proposer = task_.proposer;
        Escrow escrow = task_.escrow;
        for (uint8 i; i < budgetCount; ) {
            ERC20Transfer memory erc20Transfer = task_.budget[i];
            escrow.transfer(erc20Transfer.tokenContract, proposer, erc20Transfer.amount);

            unchecked {
                ++i;
            }
        }
        task_.state = TaskState.Closed;
    }
}