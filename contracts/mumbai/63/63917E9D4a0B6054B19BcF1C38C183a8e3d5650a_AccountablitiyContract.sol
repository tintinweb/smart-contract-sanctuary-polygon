// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AccountablitiyContract {
    struct Task {
        string description;
        bool completed;
    }

    Task[] public tasks;
    uint256 public deposit;
    address public owner;

    event TaskCreated(uint256 taskId, string description);
    event TaskCompleted(uint256 taskId);
    event DepositWithdrawn(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string memory _description) public onlyOwner {
        tasks.push(Task(_description, false));
        emit TaskCreated(tasks.length - 1, _description);
    }

    function completeTask(uint256 _taskId) public onlyOwner {
        require(_taskId < tasks.length, "Invalid task ID.");
        require(!tasks[_taskId].completed, "Task already completed.");

        tasks[_taskId].completed = true;
        emit TaskCompleted(_taskId);

        if (allTasksCompleted()) {
            withdrawDeposit();
            clearTasks();
        }
    }

    function depositFunds() public payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than 0.");
        deposit += msg.value;
    }

    function withdrawDeposit() public onlyOwner {
        uint256 withdrawalAmount = deposit;
        payable(owner).transfer(withdrawalAmount);
        deposit = 0;
        emit DepositWithdrawn(withdrawalAmount);
    }

    function withdrawDepositSafely() public onlyOwner {
        require(address(this).balance > 0, "No deposit available.");

        uint256 withdrawalAmount = deposit;
        payable(owner).transfer(withdrawalAmount);
        deposit = 0;
        emit DepositWithdrawn(withdrawalAmount);
    }

    function getDeposit() public view onlyOwner returns (uint256) {
        return deposit;
    }

    function getTaskCount() public view onlyOwner returns (uint256) {
        return tasks.length;
    }

    function allTasksCompleted() private view returns (bool) {
        for (uint256 i = 0; i < tasks.length; i++) {
            if (!tasks[i].completed) {
                return false;
            }
        }
        return true;
    }

    function clearTasks() private {
        delete tasks;
    }
}