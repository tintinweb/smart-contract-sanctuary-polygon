// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract TaskContract {
    address public owner;
    string[] public tasksArray;

    constructor() {
        owner = msg.sender;
    }

    struct task {
        bool exists;
        uint256 increment;
        mapping(address => bool) Workers;
    }

    event taskUpdated(uint256 increment, address worker, string task);

    mapping(string => task) private Tasks;

    function addTask(string memory _task) public {
        require(msg.sender == owner, "Only the owner can create tasks.");
        task storage newTask = Tasks[_task];
        newTask.exists = true;
        tasksArray.push(_task);
    }

    function selectTask(string memory _task, bool _selected) public {
        require(Tasks[_task].exists, "Task does not exist");
        require(
            !Tasks[_task].Workers[msg.sender],
            "You have already selected this task"
        );

        task storage t = Tasks[_task];
        t.Workers[msg.sender] = true;

        if (_selected) {
            t.increment++;
        }

        emit taskUpdated(t.increment, msg.sender, _task);
    }

    function getVotes(string memory _task) public view returns (uint256 up) {
        require(Tasks[_task].exists, "Task does not exist");
        task storage t = Tasks[_task];
        return (t.increment);
    }
}