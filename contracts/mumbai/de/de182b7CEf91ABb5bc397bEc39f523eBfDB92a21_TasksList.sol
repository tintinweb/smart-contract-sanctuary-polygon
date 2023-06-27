// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TasksList {
    struct Task {
        string title;
        bool isCompleted;
    }

    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;
    address public owner;

    event TaskCreated(uint256 taskId, string title);
    event TaskCompleted(uint256 taskId, bool isCompleted);
    event TaskRemoved(uint256 taskId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createTask(string memory _title) public onlyOwner {
        uint256 newTaskId = taskCount++;
        tasks[newTaskId] = Task(_title, false);
        emit TaskCreated(newTaskId, _title);
        taskCount++;
    }

    function toggleTaskCompleted(uint256 _taskId) public onlyOwner {
        Task storage task = tasks[_taskId];
        task.isCompleted = !task.isCompleted;
        emit TaskCompleted(_taskId, task.isCompleted);
    }

    function removeTask(uint256 _taskId) public onlyOwner {
        require(_taskId <= taskCount, "Invalid task id");
        delete tasks[_taskId];
        emit TaskRemoved(_taskId);
    }
}