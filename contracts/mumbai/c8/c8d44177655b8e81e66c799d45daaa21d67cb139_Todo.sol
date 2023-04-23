/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ETH Taipei sample app
contract Todo {
    // a struct of Task
    struct Task {
        string name;
        bool completed;
    }

    // map of owner to tasks
    mapping(address => Task[]) listOf;

    // map of owner to list length
    mapping(address => uint256) listLengthOf;

    /// @dev Create a task and add it to the list
    function createTask(string calldata _name) external {
        // Add a new task to the caller's list
        listOf[msg.sender].push(Task(_name, false));
        listLengthOf[msg.sender]++;
    }

    // @dev Update a task's completeness
    function updateTask(uint256 _index) external {
        // Get the task by index as reference
        Task storage task = listOf[msg.sender][_index];
        // toggle 'completed'
        task.completed = !task.completed;
    }

    // @dev Retrieve a task by specified index
    function getTask(uint256 _index) external view returns (Task memory) {
        // Get the list by caller, and get the task by index
        return listOf[msg.sender][_index];
    }


    /// @dev Get the size of the list
    function getListSize() external view returns (uint256) {
        return listLengthOf[msg.sender];
    }

    // @dev Delete a task by specified index
    function deleteTask(uint index) external {
        uint listSize = listLengthOf[msg.sender];
        require(index < listSize, "invalid index");

        Task[] storage taskList = listOf[msg.sender];

        for (uint i = index; i < listSize - 1; i++) {
            taskList[i] = taskList[i + 1];
        }
        taskList.pop();
        listLengthOf[msg.sender]--;
    }
}