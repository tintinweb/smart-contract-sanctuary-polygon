// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TasksList {
    struct Task {
        string title;
        bool completed;
    }

    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;
    address public owner;
    uint256[] public taskIds;

    event TaskCreated(uint256 taskId, string title);
    event TaskCompleted(uint256 taskId, bool completed);
    event TaskRemoved(uint256 taskId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string memory _title) public onlyOwner {
        taskCount++;
        tasks[taskCount] = Task(_title, false);
        taskIds.push(taskCount);
        emit TaskCreated(taskCount, _title);
    }

    function toggleTaskCompleted(uint256 _taskId) public onlyOwner {
        require(_taskId <= taskCount, "Invalid task ID.");
        Task storage task = tasks[_taskId];
        task.completed = !task.completed;
        emit TaskCompleted(_taskId, task.completed);
    }

    function removeTask(uint256 _taskId) public onlyOwner {
        require(_taskId <= taskCount, "Invalid task ID.");
        delete tasks[_taskId];
        emit TaskRemoved(_taskId);
    }

    function getTaskIds() public view returns (uint256[] memory) {
        return taskIds;
    }
}