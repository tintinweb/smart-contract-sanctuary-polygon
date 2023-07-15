// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Task Control contract
/// @author BARA
interface IKPITaskControl {
    /// @notice Get the task contract of this task control contract
    function taskContract() external view returns (address);

    /// @notice Get the owner of this task control contract
    function owner() external view returns (address);

    /// @notice Get the factory contract address
    function factory() external view returns (address);

    /// @notice get number of tasks in project
    function taskCount() external view returns (uint256);

    /// @notice get number of tasks by a user, start with 1
    function tasksByUser(address user) external view returns (uint256);

    /// @notice map index to task with tasksByUser mapping
    function mapIndexToTask(
        address user,
        uint256 index
    ) external view returns (uint256);

    /// @notice get in progress task by a user
    /// @param user The address of user
    function inProgress(address user) external view returns (uint256);

    /// @notice get number of late tasks
    /// @param user address of the member
    function late(address user) external view returns (uint256);

    /// @notice get number of completed tasks
    /// @param user address of the member
    function completed(address user) external view returns (uint256);

    /// @notice get number of penalized tasks
    /// @param user address of the member
    function penalized(address user) external view returns (uint256);

    /// @notice get completed task by a user
    /// @dev index is always start with 1, user mapping to get the task id
    /// @param user The address of user
    /// @param index The index of completed task in user struct
    /// @return taskID The id of task
    function getCompleted(
        address user,
        uint256 index
    ) external view returns (uint256 taskID);

    /// @notice get penalized task by a user
    /// @dev index is always start with 1, user mapping to get the task id
    /// @param user The address of user
    /// @param index The index of penalized task in user struct
    /// @return taskID The id of task
    function getPenalized(
        address user,
        uint256 index
    ) external view returns (uint256 taskID);

    /// @notice get late task by a user
    /// @dev index is always start with 1, user mapping to get the task id
    /// @param user The address of user
    /// @param index The index of late task in user struct
    /// @return taskID The id of task
    function getLate(
        address user,
        uint256 index
    ) external view returns (uint256 taskID);

    /// @notice The amount of reward that user has earned with this project
    /// @param user user of this project
    /// @return amount The earned amount
    function earned(
        address user,
        uint8 whichToken
    ) external view returns (uint256 amount);

    /// @notice The amount of guarantee that user has deposited
    /// @param user user of this project
    function guarantee(address user) external view returns (uint256);

    /// @notice Map a completed task with index for a user
    /// @param user The address of the member
    /// @param taskID The ID of the task
    /// @param amount1 The amount of token1
    /// @param amount2 The amount of token2
    /// @dev only Contract can call this function
    function mapIndexToCompletedTask(
        address user,
        uint256 taskID,
        uint256 amount1,
        uint256 amount2
    ) external;

    /// @notice Map a penalized task with index for a user
    /// @param user The address of the member
    /// @param taskID The ID of the task
    /// @dev only Contract can call this function
    function mapIndexToPenalizedTask(address user, uint256 taskID) external;

    /// @notice Change a user guarantee amount
    /// @dev only Contract can call this function
    /// @param user The address of user
    /// @param amount The new guarantee amount
    function changeMemberGuarantee(address user, uint256 amount) external;

    /// @notice create task called by task contract
    /// @param newTaskID new task id
    function createTask(uint256 newTaskID) external;

    /// @notice Get task by user
    /// @param user The address of the member
    /// @return isOwned The task is owned by the user, isInProgress The task is in progress, isDone The task is done, isPenalized The task is penalized,
    /// isCanceled The task is canceled, isWaitingForApproval The task is waiting for approval, isDropped The task is dropped
    function assignTask(
        address user,
        uint256 taskID
    )
        external
        view
        returns (
            bool isOwned,
            bool isInProgress,
            bool isDone,
            bool isPenalized,
            bool isCanceled,
            bool isWaitingForApproval,
            bool isDropped
        );

    /// @notice Change the task status when a user receive a task
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function receiveTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a user finish a task
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function finishTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a user is penalized for a task
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function penalizeTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a task is canceled
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function cancelTask(address user, uint256 taskID) external;

    /// @notice Change the task status when a task is reset
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function resetTask(address user, uint256 taskID) external;

    /// @notice User drop task
    /// @param user The address of the member
    /// @param taskID The ID of the task
    function dropTask(address user, uint256 taskID) external;

    /// @notice Increase the completed tasks of a user
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function increaseCompleted(address user) external returns (uint256);

    /// @notice Increase the penalized tasks of a user
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function increasePenalized(address user) external returns (uint256);

    /// @notice Increase the tasks that a user is working on
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function increaseInProgress(address user) external;

    /// @notice Decrease the tasks that a user is working on
    /// @param user The address of the member
    /// @dev only Contract can call this function
    function decreaseInProgress(address user) external;

    /// @notice Get tasks by user address
    /// @param user The address of the member
    /// @param cursor The cursor position to get tasks
    /// @param quantity The quantity of the task
    function getTasksByUser(
        address user,
        uint256 cursor,
        uint256 quantity
    ) external view returns (uint256[] memory taskIDs, uint256 nextCursor);

    /// @notice Get task ids
    /// @param cursor The index to start getting task ids
    /// @param quantity The number of task ids to get
    /// @return taskIDs The array of task ids, nextCursor The index to start getting next task ids
    function getTasks(
        uint256 cursor,
        uint256 quantity
    ) external view returns (uint256[] memory taskIDs, uint256 nextCursor);

    /// @notice get list of completed tasks
    /// @param user address of a user
    function getCompletedTasks(
        address user
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title An interface for a contract that is capable of deploying KPI Task Control Contract
/// @notice A contract that constructs task control for a task contract
/// @author BARA
interface IKPITaskControlDeployer {
    /// @notice Get the parameters to be used in constructing a new task control contract.
    /// @dev Called by the task contract constructor to fetch the parameters of the new task control contract
    /// @return factory The factory contract, taskContract Task contract address, owner The owner address
    function controlParameters()
        external
        view
        returns (
            address factory,
            address taskContract,
            address owner
        );

    /// @notice Function to deploys a new task control contract
    /// @dev This function is used from KPITask to deploy a new task control contract
    /// @param factory The factory contract
    /// @param taskContract The address of the task contract
    /// @param owner The address of the owner
    /// @return taskControl The task control address
    function deploy(
        address factory,
        address taskContract,
        address owner
    ) external returns (address taskControl);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title TaskStatus
/// @notice A library for KPI Task status
/// @dev Used in KPITask.sol
library TaskStatus {
    uint256 internal constant TODO = 0;
    uint256 internal constant IN_PROGRESS = 1;
    uint256 internal constant WAITING_FOR_APPROVAL = 2;
    uint256 internal constant DONE = 3;
    uint256 internal constant LATE = 4;
    /// @dev This nearly done status is that the task is almost done or the task is late
    /// due to some problems and the task owner still want to give all the rewards to the task assignee
    uint256 internal constant NEARLY_DONE = 5;
    uint256 internal constant CANCELED = 6;
    uint256 internal constant PENALIZED = 7;
    uint256 internal constant REJECTED = 8;

    /// @notice check if the task can be claim reward by a user
    /// @dev call this function to check when a member claim reward from a task
    /// @param status The task status
    function canClaimTask(uint256 status) external pure returns (bool) {
        if (status == DONE || status == LATE || status == NEARLY_DONE) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be received by a user
    /// @dev call this function to check when a member receive a task
    /// @param status The task status
    /// @param assignee The current task assignee
    /// @param user The user address
    function checkFreeTask(
        uint256 status,
        address assignee,
        address user
    ) external pure returns (bool) {
        if (
            checkAvailableTask(status) &&
            (assignee == address(0) || assignee == user)
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task is available to be received
    /// @dev call this function to check if status is TODO
    /// @param status The task status
    function checkAvailableTask(uint256 status) public pure returns (bool) {
        if (status == TODO) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be finished
    /// @dev call this function to check if a task can be finish by its status
    /// @param status The task status
    function canFinishTask(uint256 status) external pure returns (bool) {
        if (status == TODO || status == IN_PROGRESS) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be penalized
    /// @dev call this function to check if a task can be penalized by its status
    /// @param status The task status
    function canPenalizeTask(uint256 status) external pure returns (bool) {
        if (status == IN_PROGRESS || status == WAITING_FOR_APPROVAL) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be canceled
    /// @dev call this function to check if a task can be canceled by its status
    /// @param status The task status
    function canCancelTask(uint256 status) external pure returns (bool) {
        if (
            status == TODO ||
            status == IN_PROGRESS ||
            status == WAITING_FOR_APPROVAL
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be approved
    /// @dev call this function to check if a task can be approved by its status
    /// @param status The task status
    function canApproveTask(uint256 status) external pure returns (bool) {
        if (status == WAITING_FOR_APPROVAL || status == IN_PROGRESS) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be reset
    /// @dev call this function to check if a task can be reset by its status
    /// @param status The task status
    function canResetTask(uint256 status) external pure returns (bool) {
        if (status == CANCELED || status == PENALIZED || status == REJECTED) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be forced finish
    /// @dev call this function to check if a task can be forced finish by its status
    /// @param status The task status
    function canForceDone(uint256 status) external pure returns (bool) {
        if (
            status == IN_PROGRESS ||
            status == WAITING_FOR_APPROVAL ||
            status == LATE
        ) {
            return true;
        } else {
            return false;
        }
    }

    function canDepositTask(uint256 status) external pure returns (bool) {
        if (
            status == TODO ||
            status == IN_PROGRESS ||
            status == WAITING_FOR_APPROVAL
        ) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if the task can be assigned
    /// @dev call this function to check if a task can be assigned by its status
    /// @param status The task status
    function canSetAssignee(uint256 status) external pure returns (bool) {
        if (status == TODO) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if admin can change deadline of a task
    /// @param status The task status
    function canSetDeadline(uint256 status) external pure returns (bool) {
        if (status == TODO || status == IN_PROGRESS) {
            return true;
        } else {
            return false;
        }
    }

    function canDropTask(uint256 status) external pure returns (bool) {
        if (status == TODO || status == IN_PROGRESS || status == WAITING_FOR_APPROVAL) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice check if user can change isAutoClaim property of a task
    /// @param status The task status
    function canSetAutoClaim(uint256 status) external pure returns (bool) {
        if (
            status == TODO ||
            status == IN_PROGRESS ||
            status == WAITING_FOR_APPROVAL
        ) {
            return true;
        } else {
            return false;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "../interface/task/IKPITaskControl.sol";
import "../interface/task/IKPITaskControlDeployer.sol";
import "../libraries/TaskStatus.sol";

contract KPITaskControl is IKPITaskControl {
    struct AssignTask {
        bool isOwned;
        bool isInProgress;
        bool isDone;
        bool isPenalized;
        bool isCanceled;
        bool isWaitingForApproval;
        bool isDropped;
    }
    mapping(address => uint256) public override tasksByUser;
    mapping(address => mapping(uint256 => uint256))
        public
        override mapIndexToTask;
    /// @inheritdoc IKPITaskControl
    mapping(address => mapping(uint256 => AssignTask))
        public
        override assignTask;
    /// @inheritdoc IKPITaskControl
    address public override taskContract;
    /// @inheritdoc IKPITaskControl
    address public override owner;
    /// @inheritdoc IKPITaskControl
    address public override factory;
    /// @inheritdoc IKPITaskControl
    uint256 public override taskCount;
    /// @dev task id array
    uint256[] public tasks;
    /// @dev use this mapping to get all completed tasks that not claimed yet
    mapping(address => uint256[]) public completedTasks;
    /// @inheritdoc IKPITaskControl
    mapping(address => uint256) public override inProgress;
    /// @inheritdoc IKPITaskControl
    mapping(address => uint256) public override late;
    /// @inheritdoc IKPITaskControl
    mapping(address => uint256) public override completed;
    /// @inheritdoc IKPITaskControl
    mapping(address => uint256) public override penalized;
    /// @inheritdoc IKPITaskControl
    mapping(address => mapping(uint256 => uint256))
        public
        override getCompleted;
    /// @inheritdoc IKPITaskControl
    mapping(address => mapping(uint256 => uint256))
        public
        override getPenalized;
    /// @inheritdoc IKPITaskControl
    mapping(address => mapping(uint256 => uint256)) public override getLate;
    /// @inheritdoc IKPITaskControl
    mapping(address => mapping(uint8 => uint256)) public override earned;
    /// @inheritdoc IKPITaskControl
    mapping(address => uint256) public override guarantee;

    constructor() {
        (factory, taskContract, owner) = IKPITaskControlDeployer(msg.sender)
            .controlParameters();
    }

    /// @inheritdoc IKPITaskControl
    function createTask(uint256 newTaskID) external override onlyTaskContract {
        taskCount = newTaskID;
        tasks.push(newTaskID);
    }

    /// @inheritdoc IKPITaskControl
    function receiveTask(
        address user,
        uint256 taskID
    ) external override onlyTaskContract {
        uint256 index = tasksByUser[user] + 1;
        tasksByUser[user] = index;
        mapIndexToTask[user][index] = taskID;
        assignTask[user][taskID].isOwned = true;
        assignTask[user][taskID].isInProgress = true;
        inProgress[user] = inProgress[user] + 1;
    }

    /// @inheritdoc IKPITaskControl
    function finishTask(
        address user,
        uint256 taskID
    ) external override onlyTaskContract {
        assignTask[user][taskID].isInProgress = false;
        assignTask[user][taskID].isWaitingForApproval = true;
    }

    /// @inheritdoc IKPITaskControl
    function penalizeTask(
        address user,
        uint256 taskID
    ) external override onlyTaskContract {
        assignTask[user][taskID].isInProgress = false;
        assignTask[user][taskID].isPenalized = true;
        inProgress[user] = inProgress[user] - 1;
    }

    /// @inheritdoc IKPITaskControl
    function cancelTask(
        address user,
        uint256 taskID
    ) external override onlyTaskContract {
        assignTask[user][taskID].isInProgress = false;
        assignTask[user][taskID].isWaitingForApproval = false;
        assignTask[user][taskID].isCanceled = true;
        inProgress[user] = inProgress[user] - 1;
    }

    /// @inheritdoc IKPITaskControl
    function resetTask(
        address user,
        uint256 taskID
    ) external override onlyTaskContract {
        assignTask[user][taskID].isCanceled = false;
        assignTask[user][taskID].isPenalized = false;
        assignTask[user][taskID].isOwned = false;
    }

    function dropTask(
        address user,
        uint256 taskID
    ) external override onlyTaskContract {
        assignTask[user][taskID].isInProgress = false;
        assignTask[user][taskID].isOwned = false;
        assignTask[user][taskID].isDropped = true;
    }

    /// @inheritdoc IKPITaskControl
    function increaseCompleted(
        address user
    ) external override onlyTaskContract returns (uint256) {
        uint256 index = completed[user] + 1;
        completed[user] = index;

        return index;
    }

    /// @inheritdoc IKPITaskControl
    function increasePenalized(
        address user
    ) external override onlyTaskContract returns (uint256) {
        uint256 index = penalized[user] + 1;
        penalized[user] = index;

        return index;
    }

    /// @inheritdoc IKPITaskControl
    function increaseInProgress(
        address user
    ) external override onlyTaskContract {
        require(inProgress[user] < 2);
        inProgress[user] = inProgress[user] + 1;
    }

    /// @inheritdoc IKPITaskControl
    function decreaseInProgress(
        address user
    ) external override onlyTaskContract {
        require(inProgress[user] > 0);
        inProgress[user] = inProgress[user] - 1;
    }

    /// @inheritdoc IKPITaskControl
    function mapIndexToCompletedTask(
        address user,
        uint256 taskID,
        uint256 amount1,
        uint256 amount2
    ) external override onlyTaskContract {
        uint256 index = completed[user] + 1;
        completed[user] = index;
        getCompleted[user][index] = taskID;
        inProgress[user] = inProgress[user] - 1;
        completedTasks[user].push(taskID);
        assignTask[user][taskID].isInProgress = false;
        assignTask[user][taskID].isDone = true;
        earned[user][0] = earned[user][0] + amount1;
        earned[user][1] = earned[user][1] + amount2;
    }

    /// @inheritdoc IKPITaskControl
    function mapIndexToPenalizedTask(
        address user,
        uint256 taskID
    ) external override onlyTaskContract {
        guarantee[user] = 0;
        uint256 index = penalized[user] + 1;
        penalized[user] = index;
        getPenalized[user][index] = taskID;
        assignTask[user][taskID].isInProgress = false;
        assignTask[user][taskID].isPenalized = true;
        inProgress[user] = inProgress[user] - 1;
    }

    /// @inheritdoc IKPITaskControl
    function changeMemberGuarantee(
        address user,
        uint256 amount
    ) external override onlyTaskContract {
        guarantee[user] = amount;
    }

    /// @inheritdoc IKPITaskControl
    function getTasksByUser(
        address user,
        uint256 cursor,
        uint256 quantity
    )
        external
        view
        override
        returns (uint256[] memory taskIDs, uint256 newCursor)
    {
        require(quantity <= 1000, "Exceeds 1000");
        uint256 index = tasksByUser[user];
        if (quantity > (index + 1) - cursor) {
            quantity = (index + 1) - cursor;
        }

        uint256[] memory values = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            values[i] = mapIndexToTask[user][cursor + i];
        }

        return (values, cursor + quantity);
    }

    /// @inheritdoc IKPITaskControl
    function getTasks(
        uint256 cursor,
        uint256 quantity
    )
        external
        view
        override
        returns (uint256[] memory taskIDs, uint256 nextCursor)
    {
        require(quantity <= 1000);
        require(cursor < taskCount && cursor != 0);

        if (quantity > (taskCount + 1) - cursor) {
            quantity = (taskCount + 1) - cursor;
        }
        uint256[] memory values = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            values[i] = tasks[cursor + i];
        }
        if (cursor + quantity > taskCount) {
            return (values, 0);
        } else {
            return (values, cursor + quantity);
        }
    }

    /// @inheritdoc IKPITaskControl
    function getCompletedTasks(
        address user
    ) external view override returns (uint256[] memory) {
        return completedTasks[user];
    }

    modifier onlyTaskContract() {
        require(msg.sender == taskContract || msg.sender == address(this));
        _;
    }
}