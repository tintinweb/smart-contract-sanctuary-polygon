/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract TasksContract {
    uint public taskCounter = 0;

    constructor() {
        initialize();
    }

    event TaskCreated(
        uint id,
        string title,
        string description,
        bool done,
        uint256 createdAt
    );

    event TaskToggledDone(
        uint id,
        bool done
    );

    struct Task {
        uint256 id;
        string title;
        string description;
        bool done;
        uint256 createdAt;
    }

    mapping(uint256 => Task) public tasks;

    function createTask(string memory _title, string memory _description) public {
        taskCounter++;
        tasks[taskCounter] = Task(taskCounter, _title, _description, false, block.timestamp);
        emit TaskCreated(taskCounter, _title, _description,  false, block.timestamp);
    }

    function toggleDone(uint _id) public {
        Task memory _task = tasks[_id];
        _task.done = !_task.done;
        tasks[_id] = _task;
        emit TaskToggledDone(_id, _task.done);
    }

    function initialize() public {
        createTask("My First Task", "My First Description");
    }
}