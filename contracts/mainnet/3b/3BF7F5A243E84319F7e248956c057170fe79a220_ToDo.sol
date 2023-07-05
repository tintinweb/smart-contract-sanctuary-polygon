/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ToDo {
    struct Task {
        string content;
        bool completed;
    }

    Task[] public tasks;

    function createTask(string memory _content) public {
        Task memory newTask = Task({
            content: _content,
            completed: false
        });
        tasks.push(newTask);
    }

    function toggleTaskCompleted(uint256 _taskIndex) public {
        require(_taskIndex < tasks.length, "Invalid task index");

        tasks[_taskIndex].completed = !tasks[_taskIndex].completed;
    }
}