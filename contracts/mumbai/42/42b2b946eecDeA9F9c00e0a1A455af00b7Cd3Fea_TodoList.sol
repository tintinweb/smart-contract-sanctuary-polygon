// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//implements
// add task
// delete task
// view task

contract TodoList {
    event AddTask(address owner, uint id);
    event DeleteTask(uint id);

    struct Task {
        uint id;
        string text;
        bool isDeleted;
    }

    Task[] private tasks;
    mapping(uint => address) taskToOwner;

    function addTask(string memory _text) external {
        uint taskId = tasks.length;
        tasks.push(Task(taskId, _text, false));
        taskToOwner[taskId] = msg.sender;
        emit AddTask(msg.sender, taskId);
    }

    function getTasks() external view returns (Task[] memory) {
        return tasks;
    }

    function getOwnerTask() external view returns (Task[] memory) {
        Task[] memory tempTask = new Task[](tasks.length);
        uint counter = 0;

        for (uint i = 0; i < tasks.length; i++) {
            if (taskToOwner[i] == msg.sender && !tasks[i].isDeleted) {
                tempTask[counter] = tasks[i];
                counter++;
            }
        }

        Task[] memory results = new Task[](counter);
        for (uint i = 0; i < counter; i++) {
            results[i] = tempTask[i];
        }

        return results;
    }

    function deleteTask(uint _id) external {
        if (taskToOwner[_id] == msg.sender) {
            tasks[_id].isDeleted = true;
            emit DeleteTask(_id);
        }
    }
}