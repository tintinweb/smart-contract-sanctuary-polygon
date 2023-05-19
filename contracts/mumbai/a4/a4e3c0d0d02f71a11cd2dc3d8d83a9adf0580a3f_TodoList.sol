/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TodoList {
    struct Task {
        string description;
        bool completed;
    }

    Task[] public tasks;

    function createTask(string memory _description) public {
        Task memory newTask = Task(_description, false);
        tasks.push(newTask);
    }

    function completeTask(uint256 _taskIndex) public {
        require(_taskIndex < tasks.length, "Invalid task index");
        tasks[_taskIndex].completed = true;
    }

    function getTaskCount() public view returns (uint256) {
        return tasks.length;
    }
}