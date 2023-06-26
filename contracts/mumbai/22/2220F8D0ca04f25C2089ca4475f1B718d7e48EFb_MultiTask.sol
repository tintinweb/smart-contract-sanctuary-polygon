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
    string public description;                           // clear details about the project, accepted by the owner and contractor.
    uint256 public prePayment;                           // An initial pre-payment to the contractor.
    Task[] _tasks;                                       // An array of tasks.
    Task performanceBond;
    User public owner;                                   // The owner of the tasks.
    User public contractor;                              // The contractor hired to complete the tasks.
    User public referee;                                 // The referee hired to mediate any disputes.
    uint256 public bonusPerDay;                          // Bonus rate for early completion of the project.
    uint256 public penaltyPerDay;                        // Penalty rate for late completion of the project.
    bool public signedByContractor;
    
    /**
     * @dev Constructor function for the MultiTask contract.
     * @param _projectName The name of the project.
     * @param _description clear details about the project.
     * @param _taskNames An array of task names.
     * @param _wages An array of task wages.
     * @param _durations An array of task durations in days.
     * @param _projectBonusRate The bonus rate for the project.
     * @param _projectPenaltyRate The penalty rate for the project.
     * @param _performanceBond The guarantee for project performance, paid after all payments.
     * @param _owner The user struct representing the owner of the tasks.
     * @param _contractor The user struct representing the contractor hired to complete the tasks.
     * @param _referee The user struct representing the referee hired to mediate any disputes.
     */
    constructor(
        string memory _projectName,
        string memory _description,
        string[] memory _taskNames,
        uint256[] memory _wages,
        uint256[] memory _durations,
        uint256 _projectBonusRate,
        uint256 _projectPenaltyRate,
        uint256 _performanceBond,
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
        description = _description;
        owner = _owner;
        contractor = _contractor;
        referee = _referee;
        bonusPerDay = _projectBonusRate;
        penaltyPerDay = _projectPenaltyRate;
        performanceBond = Task("Performance Bond", _performanceBond, 0, false, false);
        prePayment = msg.value;

        uint256 checkPoint = block.timestamp;
        for (uint256 i = 0; i < _taskNames.length; i++) {
            checkPoint += _durations[i] * 1 days;
            _tasks.push(Task(_taskNames[i], _wages[i], checkPoint, false, false));
        }
    }

    function signContract() public {
        require(msg.sender == contractor.account, "Only Contractor can sign the contract");
        require(!signedByContractor, "you have signed the contract before");
        signedByContractor = true;
        payable(contractor.account).transfer(prePayment);
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
     * @dev Function to fund PerformanceBond.
     */
    function fundPerformanceBond() external payable {
        require(msg.sender == owner.account, "Only the owner can fund.");
        require(msg.value >= performanceBond.wage);        
        
        performanceBond.funded = true;
    }

    /**
     * @dev Function to payUp a task.
     * @param _taskId The ID of the task to fund.
     */
    function payUpTask(uint256 _taskId) external payable {
        require(_taskId < _tasks.length, "Invalid task ID.");
        require(msg.sender == owner.account, "Only the owner can fund a task.");
        require(_tasks[_taskId].funded == true, "task has not fuded yet.");
        _tasks[_taskId].wage += msg.value;       
    }

    /**
     * @dev Function to payUp whole contract.
     */
    function payUpContract() external payable {
        require(msg.sender == owner.account, "Only the owner can pay up.");
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
        payable(owner.account).transfer(address(this).balance);
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

        if(_taskId == _tasks.length - 1) {
            payable(owner.account).transfer(address(this).balance);
        }
    }
    
    /**
     * @dev Function to release the funds for a completed task.
     */
    function releasePerformaceBond() external {
        require(msg.sender == owner.account || msg.sender == referee.account, "Only the owner or referee can release funds.");

        Task storage task = performanceBond;

        require(task.funded, "Funds are not allocated for this task.");
        require(!task.paid, "Funds already paid for this task.");

        task.paid = true;

        payable(contractor.account).transfer(task.wage);
    }
   
    /**
     * @dev Function to get the details of all tasks.
     * @return temp The tasks details.
     */
    function tasks() public view returns (Task[] memory temp) {
        temp = new Task[](_tasks.length);

        for(uint256 i; i < _tasks.length; i++) {
            temp[i] = _tasks[i];
        }

        temp[temp.length] = performanceBond;
    }

    function totalWage() public view returns (uint256 tw) {
        tw += prePayment;
        for(uint256 i; i < _tasks.length; i++) {
            tw += _tasks[i].wage;
        }
        tw += performanceBond.wage;
    }

    function getData() public view returns(
        string memory _projectName_,
        string memory _description_,
        uint256 _prePayment_,
        User memory _owner_,
        User memory _contractor_,
        User memory _referee_,
        uint256 _bonusPerDay_,
        uint256 _penaltyPerDay_,
        bool _signedByContractor_,
        Task[] memory _tasks_,
        uint256 _totalWage_
    ) {
        _projectName_ = projectName;
        _description_ = description;
        _prePayment_ = prePayment;
        _owner_ = owner;
        _contractor_ = contractor;
        _referee_ = referee;
        _bonusPerDay_ = bonusPerDay;
        _penaltyPerDay_ = penaltyPerDay;
        _signedByContractor_ = signedByContractor;
        _tasks_ = tasks();
        _totalWage_ = totalWage();
    }
}