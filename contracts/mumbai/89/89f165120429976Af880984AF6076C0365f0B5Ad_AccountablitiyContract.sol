// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AccountablitiyContract {
    struct Task {
        string description;
        bool completed;
    }

    mapping(address => Task[]) public userTasks;
    mapping(address => uint256) public userDeposits;
    address public owner;

    event TaskCreated(address indexed user, uint256 taskId, string description);
    event TaskCompleted(address indexed user, uint256 taskId);
    event DepositWithdrawn(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string memory _description) public onlyOwner {
        Task[] storage tasks = userTasks[owner];
        tasks.push(Task(_description, false));
        emit TaskCreated(owner, tasks.length - 1, _description);
    }

    function completeTask(uint256 _taskId) public onlyOwner {
        Task storage task = userTasks[owner][_taskId];
        require(!task.completed, "Task already completed.");

        task.completed = true;
        emit TaskCompleted(owner, _taskId);

        if (allTasksCompleted()) {
            uint256 depositAmount = userDeposits[owner];
            userDeposits[owner] = 0;
            emit DepositWithdrawn(owner, depositAmount);
            // Transfer the depositAmount to the owner's address
            // You should implement the transfer function accordingly
            // Example: owner.transfer(depositAmount);
        }
    }

    function deposit() public payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        userDeposits[owner] += msg.value;
    }

    function getDeposit() public view onlyOwner returns (uint256) {
        return userDeposits[owner];
    }

    function getTaskCount() public view onlyOwner returns (uint256) {
        return userTasks[owner].length;
    }

    function allTasksCompleted() private view returns (bool) {
        Task[] storage tasks = userTasks[owner];
        for (uint256 i = 0; i < tasks.length; i++) {
            if (!tasks[i].completed) {
                return false;
            }
        }
        return true;
    }
}