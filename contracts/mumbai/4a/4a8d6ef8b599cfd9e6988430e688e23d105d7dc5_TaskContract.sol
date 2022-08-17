/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract TaskContract {
  event AddTask(address recipient, uint256 taskId);
  event DeleteTask(uint256 taskId, bool isDeleted);

  struct Task {
    uint256 taskId;
    string taskDescription;
    bool isDeleted;
  }
  Task[] private tasks;
  mapping(uint256 => address) taskToOwner;

  function addTask(string memory _taskDescription, bool isDeleted) external {
    uint256 taskId = tasks.length;
    tasks.push(Task(taskId, _taskDescription, isDeleted));
    taskToOwner[taskId] = msg.sender;
    emit AddTask(msg.sender, taskId);
  }

  function getTasks() external view returns (Task[] memory) {
    Task[] memory temp = new Task[](tasks.length);
    uint256 counter = 0;

    for (uint256 i = 0; i < tasks.length; i++) {
      if (taskToOwner[i] == msg.sender && !tasks[i].isDeleted) {
        temp[counter] = tasks[i];
        counter++;
      }
    }
    Task[] memory result = new Task[](counter);
    for (uint256 i = 0; i < counter; i++) {
      result[i] = temp[i];
    }
    return result;
  }

  function deleteTask(uint256 _taskId, bool isDeleted) external {
    if (taskToOwner[_taskId] != msg.sender) {
      revert("You are not the owner of this task");
    }
    tasks[_taskId].isDeleted = isDeleted;
    emit DeleteTask(_taskId, isDeleted);
  }
}