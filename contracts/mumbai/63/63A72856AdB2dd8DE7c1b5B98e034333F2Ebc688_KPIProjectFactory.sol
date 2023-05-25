// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title An interface for a contract that is capable of deploying KPI Payment Contract for a Project
/// @notice A contract that constructs payment for a project
/// @author BARA
interface IKPIPaymentDeployer {
    /// @notice Get the parameters to be used in constructing a new payment contract.
    /// @dev Called by the task contract constructor to fetch the parameters of the new payment contract
    /// @return factory The factory contract, projectContract Project contract address, taskContract Task contract address, token1 Default token address, token2 Another token address, owner The owner address
    function paymentParameters()
        external
        view
        returns (
            address factory,
            address projectContract,
            address taskContract,
            address token1,
            address token2,
            address owner
        );

    /// @notice Function to deploys a new payment contract
    /// @dev This function is used from KPITask to deploy a new payment contract
    /// @param factory The factory contract
    /// @param projectContract The address of the project contract
    /// @param taskContract The address of the task contract
    /// @param token1 Main token address
    /// @param token2 Another token address
    /// @param owner The address of the owner
    /// @return payment The payment address
    function deploy(
        address factory,
        address projectContract,
        address taskContract,
        address token1,
        address token2,
        address owner
    ) external returns (address payment);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./IKPIProjectActions.sol";
import "./IKPIProjectImmutables.sol";
import "./IKPIProjectStates.sol";
import "./IKPIProjectEvents.sol";

/// @title The interface for the KPI Project
/// @notice This contract is used to control tasks, members, and payments in a project
/// @author BARA
interface IKPIProject is
    IKPIProjectActions,
    IKPIProjectImmutables,
    IKPIProjectStates,
    IKPIProjectEvents
{

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Permissionless KPI project actions
/// @notice Contains project methods that can be called by owner and admins
/// @author BARA
interface IKPIProjectActions {
    /// @notice Add a new member to the project
    /// @param user The address of the new member
    /// @dev This function is called by owner and admins to add new member to the project
    function addMember(address user, bytes32 name) external;

    /// @notice Remove a member from the project
    /// @param user The address of the member
    /// @dev This function is called by owner and admins to remove (actually set isMember to false)
    /// a member from the project, if this member is admin, remove admin role too
    function removeMember(address user) external;

    /// @notice Add a new admin to the project
    /// @param user The address of the new admin
    /// @dev If admin is already a member, this function will not add a new member and set role to admin
    /// else it will add a new member and set that member to admin role
    function addAdmin(address user, bytes32 name) external;

    /// @notice Remove an admin from the project
    /// @param user The address of the admin
    /// @dev Remove admin role from a member, that admin is still a member
    function removeAdmin(address user) external;

    /// @notice Change a member name
    /// @param user The address of the member
    /// @param name The new name of the member
    /// @dev This function is called by admins to change member name
    function changeMemberName(address user, bytes32 name) external;

    /// @notice Change the alternate address of a member
    /// @param user The address of the member
    /// @param alternateAddress The new alternate address of the member
    /// @dev This alternate address is can be set only by that user
    function changeAlternate(address user, address alternateAddress) external;

    /// @notice Set project name
    /// @param name The new project name
    /// @dev This function is called only by owner
    function setName(bytes32 name) external;

    /// @notice Set guarantee amount
    /// @param amount The new guarantee amount
    /// @dev This function is called only by owner
    function setGuaranteeAmount(uint256 amount) external;

    /// @notice Set repository link
    /// @param repository The new repository link
    /// @dev This function is called only by owner
    function setRepository(bytes32 repository) external;

    /// @notice Set project owner
    /// @param newOwner The new project owner
    /// @dev This function is called only by owner
    function setOwner(address newOwner) external;

    /// @notice Get this project states
    /// @dev This function is called by anyone to get project states
    /// @return factory The project factory address, token The project token address, createdAt The project created time, name The project name, guaranteeAmount The project guarantee amount for a user to be able to receive task,
    /// repository The project repository link, members The number of members in this project, taskContract The task contract address, owner The project owner address, penaltyPercentage The project penalty rate
    function getProject()
        external
        view
        returns (
            address factory,
            address token,
            address token2,
            uint256 createdAt,
            bytes32 name,
            uint256 guaranteeAmount,
            bytes32 repository,
            uint256 members,
            address taskContract,
            address owner,
            bool depositChecking,
            uint256 penaltyPercentage
        );

    /// @notice Check a user is an admin of the project
    /// @param user The address of user
    function isAdmin(address user) external view returns (bool);

    /// @notice Check a user is a member of the project
    /// @param user The address of user
    function isMember(address user) external view returns (bool);

    /// @notice Factory set task contract
    /// @param task The task contract address
    function setTaskContract(address task) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title An interface for a contract that is capable of deploying KPI Project contract
/// @notice A contract that constructs a project must implement this to pass arguments to the KPI project
/// @author BARA
interface IKPIProjectDeployer {
    /// @notice Get the parameters to be used in constructing a new project.
    /// @dev Called by the project factory contract constructor to fetch the parameters of the new project
    /// @return factory ProjectFactory address, token1 Default token address to be used in this project, token2 Another token, name Project name, guaranteeAmount Guarantee amount for a user to be able to receive task in this project,
    /// depositChecking check if this project must deposit first, owner address of project owner
    function parameters()
        external
        view
        returns (
            address factory,
            address token1,
            address token2,
            bytes32 name,
            uint256 guaranteeAmount,
            bool depositChecking,
            address owner
        );

    /// @notice Function to deploys a new project contract
    /// @dev This function is used from KPIProjectFactory to deploy a new project contract
    /// @param factory Address of Project factory
    /// @param token1 Default token address to be used in this project
    /// @param token2 Another token address
    /// @param name The name of project to be created
    /// @param guaranteeAmount The guarantee amount for a user to be able to receive task in this project
    /// @param depositChecking check if this project must deposit first
    /// @param owner The address of project owner
    /// @return project address of the project created
    function deploy(
        address factory,
        address token1,
        address token2,
        bytes32 name,
        uint256 guaranteeAmount,
        bool depositChecking,
        address owner
    ) external returns (address project);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title The interface for the KPI Project Events
/// @author BARA
interface IKPIProjectEvents {
    /// @notice Emitted when a new member is added to the project'
    /// @param project The project address
    /// @param member New member address
    /// @param name New member name
    event MemberAdded(
        address indexed project,
        address indexed member,
        bytes32 indexed name
    );

    /// @notice Emitted when a member is removed from the project
    /// @param project The project address
    /// @param member Removed member address
    event MemberRemoved(address indexed project, address indexed member);

    /// @notice Emitted when an admin is added
    /// @param project The project address
    /// @param admin New admin address
    /// @param name New admin name
    event AdminAdded(
        address indexed project,
        address indexed admin,
        bytes32 indexed name
    );

    /// @notice Emitted when an admin is removed
    /// @param project The project address
    /// @param admin Removed admin address
    event AdminRemoved(address indexed project, address indexed admin);

    /// @notice Emitted when guarantee amount of a project is changed by owner
    /// @param project The project address
    /// @param newAmount New guarantee amount
    event ProjectGuaranteeAmountChanged(
        address indexed project,
        uint256 indexed newAmount
    );

    /// @notice Emitted when project owner is changed
    /// @param project The project address
    /// @param oldOwner The old owner address
    /// @param newOwner The new owner address
    event OwnerChanged(
        address indexed project,
        address indexed oldOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title The interface for the KPI Project Factory
/// @notice The KPI Project Factory facilitates creation of KPI Projects and control connection to others contracts
/// @author BARA
interface IKPIProjectFactory {
    /// @notice Returns the current owner of the factory
    /// @dev Can be change by the current owner via setOwner
    function owner() external view returns (address);

    /// @notice Get amount of all the projects created by the factory
    /// @dev start with 1
    function projectsCount() external view returns (uint256);

    /// @notice Get the address of the project by its index
    /// @param index The index of the project
    function getProject(uint256 index) external view returns (address);

    /// @notice Get number of projects a user is keeping
    /// @param user User address
    function userProjects(address user) external view returns (uint256);

    /// @notice Get project of a user by index
    /// @dev always start with 1
    /// @param user User address
    /// @param index Index in mapping userProjects
    function userProjectByIndex(address user, uint256 index)
        external
        view
        returns (address);

    /// @notice Get Project deployer contract
    function projectDeployerContract() external view returns (address);

    /// @notice Get Task deployer contract
    function taskDeployerContract() external view returns (address);

    /// @notice Get Task Control deployer contract
    function taskControlDeployerContract() external view returns (address);

    /// @notice Get Payment deployer contract
    function paymentDeployerContract() external view returns (address);

    /// @notice Create a new KPI Project
    /// @dev notice that a user can create only under uint256 limit of projects (65535)
    /// @param name The name of the project
    /// @param token1 The token address used to pay for tasks in the project
    /// @param token2 Another token address
    /// @param guaranteeAmount The amount of guarantee deposit
    /// @param depositChecking A checking flag that can check if task is receive with or without guarantee
    function createProject(
        bytes32 name,
        address token1,
        address token2,
        uint256 guaranteeAmount,
        bool depositChecking
    ) external returns (address project);

    /// @notice onlyOwner call to set project deployer contract
    /// @param sender The address of the caller
    /// @param newAddress The address of the new project deployer contract
    function setProjectDeployerContract(address sender, address newAddress)
        external;

    /// @notice onlyOwner call to set task deployer contract
    /// @param sender The address of the caller
    /// @param newAddress The address of the new task deployer contract
    function setTaskDeployerContract(address sender, address newAddress)
        external;

    /// @notice onlyOwner call to set task control deployer contract
    /// @param sender The address of the caller
    /// @param newAddress The address of the new task control deployer contract
    function setTaskControlDeployerContract(address sender, address newAddress)
        external;

    /// @notice onlyOwner call to set payment deployer contract
    /// @param sender The address of the caller
    /// @param newAddress The address of the new payment deployer contract
    function setPaymentDeployerContract(address sender, address newAddress)
        external;

    /// @notice get projects of a user
    /// @param user user address
    /// @param cursor start at an index
    /// @param quantity amount to get
    function getProjectsByUser(
        address user,
        uint256 cursor,
        uint256 quantity
    )
        external
        view
        returns (address[] memory projectAddresses, uint256 newCursor);

    /// @notice add a user to a project to get projects of that user
    /// @param user User address
    /// @param project Project address
    function userAddedToProject(address user, address project) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Project state that never change
/// @notice These parameters are fixed for a project forever, i.e., the methods will always return the same values
/// @author BARA
interface IKPIProjectImmutables {
    /// @notice The contract that deployed the project
    function factory() external view returns (address);

    /// @notice The token address used to pay for tasks in the project
    function token1() external view returns (address);

    /// @notice Another token address, can be used like first token
    function token2() external view returns (address);

    /// @notice The project created time
    /// @dev Save this value with uint256 to minimize gas cost
    function createdAt() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Project states that can change
/// @author BARA
interface IKPIProjectStates {
    /// @notice Member struct
    /// @param user The address of member
    /// @dev get member by members index
    /// @return name Member name, isMember is active member, alternate The alternate address that user want to receive reward instead of the current user address
    function getMember(address user)
        external
        view
        returns (
            bytes32 name,
            bool isMember,
            address alternate
        );

    /// @notice Get task contract address
    function taskContract() external view returns (address);

    /// @notice get project info
    /// @param projectName The project name
    /// @param repository repository link to the project's repository
    /// @param guaranteeAmount Current guarantee amount for a user to be able to receive task in this project
    /// @param members Project's members count, always start with 1
    /// @param penaltyPercentage Project's penalty rate
    /// @param depositChecking Check if this project have to deposit or not
    /// @param owner Project's owner
    function projectInfo()
        external
        view
        returns (
            bytes32 projectName,
            bytes32 repository,
            uint256 guaranteeAmount,
            uint256 members,
            uint256 penaltyPercentage,
            bool depositChecking,
            address owner
        );
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./IKPITaskActions.sol";
import "./IKPITaskEvents.sol";
import "./IKPITaskStates.sol";

/// @title The interface for the KPI Task
/// @notice This contract is used to control tasks of a project
/// @author BARA
interface IKPITask is IKPITaskActions, IKPITaskEvents, IKPITaskStates {

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Permissionless KPI task actions
/// @notice Contains task methods that can be called by members, admins and owner
/// @author BARA
interface IKPITaskActions {
    /// @notice Create new task for the project
    /// @dev only project owner and admins can call this function
    /// @param name The name of the task
    /// @param description The description of the task
    /// @param reward1 The amount that member can claim when complete this task according to token default
    /// @param reward2 The amount that member can claim when complete this task according to token2
    /// @param deadline The deadline of the task
    /// @return newTaskID The ID of the new task
    function createTask(
        bytes32 name,
        bytes32 description,
        uint256 reward1,
        uint256 reward2,
        uint256 deadline
    ) external returns (uint256 newTaskID);

    /// @notice Receive a task to work on
    /// @dev only members can call this function
    /// @param taskID The ID of the task
    function receiveTask(uint256 taskID) external;

    /// @notice Finish a task
    /// @dev only assignee can call this function
    /// @param taskID The ID of the task
    function finishTask(uint256 taskID) external;

    /// @notice Penalize a delay task
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    function penalizeTask(uint256 taskID) external;

    /// @notice Cancel a task and claim back the reward
    /// @dev only project owner can call this function
    /// @param taskID The ID of the task
    function cancelTask(uint256 taskID) external;

    /// @notice Approve a task
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    function approveTask(uint256 taskID) external;

    /// @notice Reset/Reopen a task
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    /// @param newAmount1 The new amount that member can claim when complete this task
    /// @param newAmount2 The new amount according to token2
    /// @param deadline The new deadline of the task
    function resetTask(
        uint256 taskID,
        uint256 newAmount1,
        uint256 newAmount2,
        uint256 deadline
    ) external;

    /// @notice Force finish a task
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    function forceDone(uint256 taskID) external;

    /// @notice Claim reward for a task
    /// @dev only assignee can call this function
    /// @param taskID The ID of the task
    function claimTask(uint256 taskID) external;

    /// @notice Withdraw guarantee amount of a user from the project
    function withdrawGuarantee() external;

    /// @notice Deposit more for a task
    /// @dev only depositor of this task can re deposit
    /// @param taskID The ID of the task
    /// @param reward The reward amount
    /// @param whichToken choose token to be transfer, 0 is default token
    function depositTask(uint256 taskID, uint256 reward, uint8 whichToken) external;

    /// @notice Assign a task to a member
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    /// @param assignee The address of the member
    function assignTask(uint256 taskID, address assignee) external;

    /// @notice Change the total reward of the project
    /// @dev only payment contract can call this function
    /// @param taskID The ID of the task
    /// @param totalReward The new total reward of the project
    /// @param whichToken choose token to be transfer, 0 is default token
    function setTotalReward(uint256 taskID, uint256 totalReward, uint8 whichToken) external;

    /// @notice Change the remaining reward of the project
    /// @dev only payment contract and project contract can call this function
    /// @param taskID The ID of the task
    /// @param remaining The new remaining reward of the task
    /// @param whichToken choose token to be transfer, 0 is default token
    function setRemaining(uint256 taskID, uint256 remaining, uint8 whichToken) external;

    /// @notice Change task description
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    /// @param description The new description of the task
    function changeDescription(uint256 taskID, bytes32 description) external;

    /// @notice Change task deadline
    /// @dev only project owner and admins can call this function
    /// @param taskID The ID of the task
    /// @param deadline The new deadline of the task
    function changeDeadline(uint256 taskID, uint256 deadline) external;

    // /// @notice Change task auto claim status
    // /// @dev only assignee of the task can call this function
    // /// @param taskID The ID of the task
    // function changeAutoClaim(uint256 taskID, bool isAutoClaim) external;

    /// @notice Transfer money from task to another address
    /// @param to The address to transfer to
    /// @param amount The amount to transfer
    /// @param whichToken choose token to be transfer, 0 is default token
    function transfer(address to, uint256 amount, uint8 whichToken) external;

    // /// @notice remove all completed tasks of a member
    // /// @dev only this contract and payment can call, return remaning reward of all completed tasks
    // /// @param member The address of the member
    // function withdrawAllCompletedTasks(address member)
    //     external
    //     returns (uint256);

    /// @notice drop a task and get penalty for a task
    /// @dev only assignee of the task can call this function
    /// @param taskID The ID of the task
    function dropTask(uint256 taskID) external;

    /// @notice factory set payment contract address
    /// @dev only call when created
    /// @param payment payment contract
    function setPaymentContract(address payment) external;

    /// @notice factory set task control contract address
    /// @dev only call when created
    /// @param taskControl task control contract
    function setTaskControlContract(address taskControl) external;
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title An interface for a contract that is capable of deploying KPI Task Contract
/// @notice A contract that constructs tasks for a project must implement this to pass arguments to the KPI Task Contract
/// @author BARA
interface IKPITaskDeployer {
    /// @notice Get the parameters to be used in constructing a new task contract.
    /// @dev Called by the project contract constructor to fetch the parameters of the new task contract
    /// @return factory The factory contract, token default token address to be used in the project, token2 token address 2
    /// projectContract Project contract address, owner The owner address
    function parameters()
        external
        view
        returns (
            address factory,
            address token1,
            address token2,
            address projectContract,
            address owner
        );

    /// @notice Function to deploys a new task contract
    /// @dev This function is used from KPIProjectFactory to deploy a new task contract
    /// @param factory The factory contract
    /// @param token1 The default token address to be used in this project
    /// @param token2 The token number 2
    /// @param projectContract The address of the project contract
    /// @return task task address
    function deployTask(
        address factory,
        address token1,
        address token2,
        address projectContract,
        address owner
    ) external returns (address task);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title The interface for the KPI Task Events
/// @author BARA
interface IKPITaskEvents {
    /// @notice Emitted when the project owner create task
    /// @param projectContract address of the project contract
    /// @param taskID ID of the new created task
    /// @param reward Task reward
    event TaskCreated(
        address indexed projectContract,
        uint256 indexed taskID,
        uint256 indexed reward,
        uint256 reward2
    );

    /// @notice Emitted when task is assigned to someone
    /// @param taskID ID of the task
    /// @param assignee Address of assignee
    event TaskAssigned(uint256 indexed taskID, address indexed assignee);

    /// @notice Emitted when a task is waiting for approval
    /// @param projectContract Address of the project contract
    /// @param taskID ID of the task
    /// @param status Task status
    event WaitingForApproval(
        address indexed projectContract,
        uint256 indexed taskID,
        uint256 indexed status
    );

    /// @notice Emitted when a task is penalized
    /// @param taskID ID of the task
    /// @param amount1 Penalize amount with token1
    /// @param amount2 Penalize amount with token2
    /// @param assignee Task assignee
    event Penalized(
        uint256 indexed taskID,
        uint256 indexed amount1,
        uint256 indexed amount2,
        address assignee
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Task states that can change
interface IKPITaskStates {
    /// @notice get task by task id
    /// @param taskID The id of task
    /// @return name Task name, description Task description, status Task status, createdAt Task created time, updatedAt update time, submitAt Task submit time, deadline Task deadline,
    /// assignee Task assignee, totalReward Task total reward, remaining Task remaining reward, isExist Task is exist
    function getTask(uint256 taskID)
        external
        view
        returns (
            bytes32 name,
            bytes32 description,
            uint256 status,
            uint256 createdAt,
            uint256 startAt,
            uint256 updatedAt,
            uint256 submitAt,
            uint256 deadline,
            address assignee,
            bool isExist
        );

    /// @notice get task reward detail by id
    /// @param taskID The id of task
    /// @return totalReward1 total reward of default token, remaining remaining of default token, totalReward2 total reward of token2,
    /// remaining2 remaining of token2
    function getTaskReward(uint256 taskID) external view returns (
        uint256 totalReward1,
        uint256 remaining1,
        uint256 totalReward2,
        uint256 remaining2
    );

    /// @notice get task depositor address
    /// @dev get address of the task depositor to transfer remaining reward
    /// or penalty to this address
    /// @param taskID The id of task
    function getDepositor(uint256 taskID) external view returns (address);

    /// @notice get this task contract information
    function taskContractInfo()
        external
        view
        returns (
            address factory,
            address token1,
            address token2,
            address projectContract,
            address paymentContract,
            address controlContract,
            address owner,
            uint256 taskCount
        );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "../interface/project/IKPIProjectFactory.sol";
import "../interface/project/IKPIProject.sol";
import "../interface/project/IKPIProjectDeployer.sol";
import "../interface/project/IKPIProject.sol";
import "../interface/task/IKPITaskControlDeployer.sol";
import "../interface/task/IKPITaskDeployer.sol";
import "../interface/task/IKPITask.sol";
import "../interface/payment/IKPIPaymentDeployer.sol";
import "../libraries/NoDelegateCall.sol";

/// @title KPI Project Factory
/// @notice Deploys KPI projects and controls connection to other contracts
contract KPIProjectFactory is IKPIProjectFactory, NoDelegateCall {
    /// @inheritdoc IKPIProjectFactory
    address public override owner;
    /// @inheritdoc IKPIProjectFactory
    uint256 public override projectsCount;
    /// @inheritdoc IKPIProjectFactory
    mapping(uint256 => address) public override getProject;
    /// @inheritdoc IKPIProjectFactory
    mapping(address => uint256) public override userProjects;
    /// @notice mapping to check project exist
    mapping(address => bool) public projectExist;
    /// @inheritdoc IKPIProjectFactory
    mapping(address => mapping(uint256 => address))
        public
        override userProjectByIndex;

    constructor() {
        owner = msg.sender;
    }

    ///@inheritdoc IKPIProjectFactory
    address public override projectDeployerContract;
    ///@inheritdoc IKPIProjectFactory
    address public override taskDeployerContract;
    ///@inheritdoc IKPIProjectFactory
    address public override taskControlDeployerContract;
    ///@inheritdoc IKPIProjectFactory
    address public override paymentDeployerContract;

    ///@inheritdoc IKPIProjectFactory
    function createProject(
        bytes32 name,
        address token1,
        address token2,
        uint256 guaranteeAmount,
        bool depositChecking
    ) external override noDelegateCall returns (address project) {
        require(token1 != address(0));
        project = IKPIProjectDeployer(projectDeployerContract).deploy(
            address(this),
            token1,
            token2,
            name,
            guaranteeAmount,
            depositChecking,
            msg.sender
        );
        emit ProjectCreated(project, msg.sender);
        projectExist[project] = true;
        address task = IKPITaskDeployer(taskDeployerContract).deployTask(
            address(this),
            token1,
            token2,
            project,
            msg.sender
        );
        address taskControl = IKPITaskControlDeployer(
            taskControlDeployerContract
        ).deploy(address(this), task, msg.sender);
        address payment = IKPIPaymentDeployer(paymentDeployerContract).deploy(
            address(this),
            project,
            task,
            token1,
            token2,
            msg.sender
        );
        IKPIProject(project).setTaskContract(task);
        IKPITask(task).setTaskControlContract(taskControl);
        IKPITask(task).setPaymentContract(payment);

        projectsCount += 1;
        getProject[projectsCount] = project;
        uint256 index = userProjects[msg.sender] + 1;
        userProjects[msg.sender] = index;
        userProjectByIndex[msg.sender][index] = project;
    }

    /// @inheritdoc IKPIProjectFactory
    function userAddedToProject(address user, address project)
        external
        override
    {
        require(projectExist[project] && msg.sender == project, "0");
        uint256 index = userProjects[user] + 1;
        userProjects[user] = index;
        userProjectByIndex[user][index] = project;
    }

    ///@inheritdoc IKPIProjectFactory
    function setProjectDeployerContract(address sender, address newAddress)
        external
        override
    {
        require(sender == owner);
        projectDeployerContract = newAddress;
    }

    ///@inheritdoc IKPIProjectFactory
    function setTaskDeployerContract(address sender, address newAddress)
        external
        override
    {
        require(sender == owner);
        taskDeployerContract = newAddress;
    }

    ///@inheritdoc IKPIProjectFactory
    function setTaskControlDeployerContract(address sender, address newAddress)
        external
        override
    {
        require(sender == owner);
        taskControlDeployerContract = newAddress;
    }

    ///@inheritdoc IKPIProjectFactory
    function setPaymentDeployerContract(address sender, address newAddress)
        external
        override
    {
        require(sender == owner);
        paymentDeployerContract = newAddress;
    }

    /// @inheritdoc IKPIProjectFactory
    function getProjectsByUser(
        address user,
        uint256 cursor,
        uint256 quantity
    )
        external
        view
        override
        returns (address[] memory projectAddresses, uint256 newCursor)
    {
        require(cursor > 0, "Cursor start with 1");
        require(quantity <= 1000, "Exceeds 1000");
        if (quantity > (userProjects[user] + 1) - cursor) {
            quantity = (userProjects[user] + 1) - cursor;
        }

        address[] memory values = new address[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            values[i] = userProjectByIndex[user][i + cursor];
        }

        return (values, cursor + quantity);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event ProjectCreated(address project, address creator);
}