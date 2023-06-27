// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TasksList {
    struct Task {
        string title;
        bool completed;
    }

    mapping(uint256 => Task) public tasks;
    uint256[] public taskIds;
    address public owner;

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
        uint256 taskId = taskIds.length + 1;
        tasks[taskId] = Task(_title, false);
        taskIds.push(taskId);
        emit TaskCreated(taskId, _title);
    }

    function toggleTaskCompleted(uint256 _taskId) public onlyOwner {
        Task storage task = tasks[_taskId];
        task.completed = !task.completed;
        emit TaskCompleted(_taskId, task.completed);
    }

    function removeTask(uint256 _taskId) public onlyOwner {
        require(_taskId <= taskIds.length, "Invalid task ID.");
        delete tasks[_taskId];
        emit TaskRemoved(_taskId);
    }

    function getTaskIds() public view returns (uint256[] memory) {
        return taskIds;
    }
}