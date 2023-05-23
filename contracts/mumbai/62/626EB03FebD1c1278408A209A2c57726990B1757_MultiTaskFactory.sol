// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiTask.sol";

/**
 * @title MultiTaskFactory
 * @dev Contract for creating instances of MultiTask contracts.
 */
contract MultiTaskFactory {

    MultiTask[] private _contracts;

    /**
     * @dev Creates a new instance of the MultiTask contract.
     * @param _projectName The name of the project.
     * @param _taskNames An array of task names.
     * @param _wages An array of task wages.
     * @param _durations An array of task durations in days.
     * @param _projectBonusRate The bonus rate for the project.
     * @param _projectPenaltyRate The penalty rate for the project.
     * @param _ownerName The string name of the owner.
     * @param _contractor The user struct representing the contractor hired to complete the tasks.
     * @param _referee The user struct representing the referee hired to mediate any disputes.
     * @return The newly created MultiTask contract.
     */
    function createMultiTask(
        string memory _projectName,
        string[] memory _taskNames,
        uint256[] memory _wages,
        uint256[] memory _durations,
        uint256 _projectBonusRate,
        uint256 _projectPenaltyRate,
        string memory _ownerName,
        MultiTask.User memory _contractor,
        MultiTask.User memory _referee
    ) external payable returns (MultiTask) {
        MultiTask newContract = new MultiTask
            {value : msg.value}
        (
            _projectName,
            _taskNames,
            _wages,
            _durations,
            _projectBonusRate,
            _projectPenaltyRate,
            MultiTask.User(_ownerName, msg.sender),
            _contractor,
            _referee
        );
        _contracts.push(newContract);
        return newContract;
    }

    /**
     * @dev Returns an array of all the MultiTask contracts created by this factory.
     * @return An array of all the MultiTask contracts created by this factory.
     */
    function contracts() public view returns(MultiTask[] memory) {
        return _contracts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultiTask Contract
 * @dev A contract for creating and managing multiple tasks with an owner, contractor, and referee.
 */
contract MultiTask {
    
    struct Task {
        string name;                // The name of the task.
        uint256 wage;               // The wage for completing the task.
        uint256 deadline;           // The deadline for completing the task.
        bool funded;                // Flag indicating if the task has been funded.
        bool paid;                  // Flag indicating if the task has been paid.
    }

    struct User {
        string name;                // The name of the user.
        address account;            // The Ethereum address of the user.
    }
    
    string public projectName;                           // The name of the project.
    uint256 public prePayment;                           // An initial pre-payment to the contractor.
    Task[] _tasks;                                       // An array of tasks.
    User public owner;                                   // The owner of the tasks.
    User public contractor;                              // The contractor hired to complete the tasks.
    User public referee;                                 // The referee hired to mediate any disputes.
    uint256 public bonusPerDay;                          // Bonus rate for early completion of the project.
    uint256 public penaltyPerDay;                        // Penalty rate for late completion of the project.
    
    /**
     * @dev Constructor function for the MultiTask contract.
     * @param _projectName The name of the project.
     * @param _taskNames An array of task names.
     * @param _wages An array of task wages.
     * @param _durations An array of task durations in days.
     * @param _projectBonusRate The bonus rate for the project.
     * @param _projectPenaltyRate The penalty rate for the project.
     * @param _owner The user struct representing the owner of the tasks.
     * @param _contractor The user struct representing the contractor hired to complete the tasks.
     * @param _referee The user struct representing the referee hired to mediate any disputes.
     */
    constructor(
        string memory _projectName,
        string[] memory _taskNames,
        uint256[] memory _wages,
        uint256[] memory _durations,
        uint256 _projectBonusRate,
        uint256 _projectPenaltyRate,
        User memory _owner,
        User memory _contractor,
        User memory _referee
    ) payable {      
        require(
            _taskNames.length == _wages.length && 
            _taskNames.length == _durations.length, 
            "Invalid task details."
        );
        require(
            _owner.account != address(0) &&
            _contractor.account != address(0) &&
            _referee.account != address(0),
            "Zero address not allowed"
        );
        projectName = _projectName;
        owner = _owner;
        contractor = _contractor;
        referee = _referee;
        bonusPerDay = _projectBonusRate;
        penaltyPerDay = _projectPenaltyRate;
        prePayment = msg.value;
        payable(_contractor.account).transfer(msg.value);

        uint256 checkPoint = block.timestamp;
        for (uint256 i = 0; i < _taskNames.length; i++) {
            checkPoint += _durations[i] * 1 days;
            _tasks.push(Task(_taskNames[i], _wages[i], checkPoint, false, false));
        }
    }

    /**
     * @dev Function to fund a task.
     * @param _taskId The ID of the task to fund.
     */
    function fundTask(uint256 _taskId) external payable {
        require(_taskId < _tasks.length, "Invalid task ID.");
        require(msg.sender == owner.account, "Only the owner can fund a task.");
        require(msg.value >= _tasks[_taskId].wage);        
        
        _tasks[_taskId].funded = true;
    }

    /**
     * @dev Function to refund the owner for a task that was not completed.
     * @param _taskId The ID of the task to refund.
     */
    function refundToOwner(uint256 _taskId) external {
        require(msg.sender == contractor.account || msg.sender == referee.account, "Only the contractor or referee can refund a task.");
        Task storage task = _tasks[_taskId];
        task.funded = false;
        task.paid = true;
        payable(owner.account).transfer(task.wage);
    }
    
    /**
     * @dev Function to release the funds for a completed task.
     * @param _taskId The ID of the task to release funds for.
     */
    function releaseFund(uint256 _taskId) external {
        require(_taskId < _tasks.length, "Invalid task ID.");
        require(msg.sender == owner.account || msg.sender == referee.account, "Only the owner or referee can release funds.");

        Task storage task = _tasks[_taskId];

        require(task.funded, "Funds are not allocated for this task.");
        require(!task.paid, "Funds already paid for this task.");

        uint256 totalAmount;

        if (_taskId == _tasks.length - 1) {
            uint256 taskCompletionTime = block.timestamp - task.deadline;
            uint256 bonusAmount;
            uint256 penaltyAmount;

            if (taskCompletionTime < 0) {
                bonusAmount = (bonusPerDay * taskCompletionTime) / 1 days;
            } else {
                penaltyAmount = (penaltyPerDay * taskCompletionTime) / 1 days;
            }

            totalAmount = task.wage + bonusAmount - penaltyAmount;
        } else {
            totalAmount = task.wage;
        }

        task.paid = true;

        payable(contractor.account).transfer(totalAmount);
    }
   
    /**
     * @dev Function to get the details of all tasks.
     * @return temp The tasks details.
     */
    function tasks() external view returns (Task[] memory temp) {
        temp = new Task[](_tasks.length);

        for(uint256 i; i < _tasks.length; i++) {
            temp[i] = _tasks[i];
        }
    }
}