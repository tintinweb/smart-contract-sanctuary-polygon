/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bloc {
    struct Task {
        uint256 id;
        string title;
        bool status;
        string desc;
        string priority;
        string date;
    }

    mapping(address => Task[]) private tasks;
    uint256 _id = 0;

    function addTask(
        string calldata _title,
        string calldata _desc,
        string calldata _priority,
        bool _status,
        string calldata _date
    ) external {
        tasks[msg.sender].push(
            Task({
                id: _id,
                title: _title,
                status: _status,
                desc: _desc,
                priority: _priority,
                date: _date
            })
        );
        _id++;
    }

    function getTask(uint256 id, address account) external view returns (Task memory) {
        Task storage task = tasks[account][id];
        return task;
    }

    function updateTask(
        uint256 id,
        string calldata _title,
        string calldata _desc,
        string calldata _priority,
        bool _status,
        string calldata _date
    ) external {
        tasks[msg.sender][id].title = _title;
        tasks[msg.sender][id].status = _status;
        tasks[msg.sender][id].desc = _desc;
        tasks[msg.sender][id].priority = _priority;
        tasks[msg.sender][id].date = _date;
    }

    function deleteTask(uint256 id) external {
        for (uint256 i = id; i < tasks[msg.sender].length - 1; i++) {
            tasks[msg.sender][i] = tasks[msg.sender][i + 1];
        }
        tasks[msg.sender].pop();
    }

    function getTaskCount(address account) external view returns (uint256) {
        return tasks[account].length;
    }
}