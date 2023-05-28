/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract TaskContract {
    constructor() {}

    struct Task {
        uint id;
        string taskTitle;
        string taskText;
        bool isDeleted;
    }

    Task[] private tasks;

    mapping(uint => address) taskToOwner;

    event AddTask(address recepient, uint taskId);

    event DeleteTask(uint taskId, bool isDeleted);

    function addTask(
        string memory taskText,
        string memory taskTitle,
        bool isDeleted
    ) external {
        uint taskId = tasks.length;
        tasks.push(Task(taskId, taskTitle, taskText, isDeleted));
        taskToOwner[taskId] = msg.sender;
        emit AddTask(msg.sender, taskId);
    }

    function deleteTask(uint taskId) external {
        require(
            taskToOwner[taskId] == msg.sender,
            "You are not the owner of this task"
        );
        tasks[taskId].isDeleted = true;
        emit DeleteTask(taskId, tasks[taskId].isDeleted);
    }

    function getMyTask() public view returns (Task[] memory) {
        Task[] memory myTasks = new Task[](tasks.length);
        uint counter = 0;
        for (uint i = 0; i < tasks.length; i++) {
            if (taskToOwner[i] == msg.sender && tasks[i].isDeleted == false) {
                myTasks[counter] = tasks[i];
                counter++;
            }
        }
        Task[] memory result = new Task[](counter);
        for (uint i = 0; i < counter; i++) {
            result[i] = myTasks[i];
        }
        return result;
    }
}