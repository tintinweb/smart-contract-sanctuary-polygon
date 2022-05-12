// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TodoContract {
    uint256 public taskCount = 0;

    struct Task {
        uint256 index;
        string taskName;
        bool isComplete;
    }

    mapping(uint256 => Task) public todos;
    //1.to-doを作成する機能
    event TaskCreated(string task, uint256 taskNumber);
    //2.to-doを更新する機能
    event TaskUpdated(string task, uint256 taskId);
    //3.to-doの完了・未完了を切り替える機能
    event TaskIsCompleteToggled(string task, uint256 taskId, bool isComplete);
    //4.to-doを削除する機能
    event TaskDeleted(uint256 taskNumber);

    function createTask(string memory _taskName) public {
        todos[taskCount] = Task(taskCount, _taskName, false);
        taskCount++;
        emit TaskCreated(_taskName, taskCount - 1);
    }

    function updateTask(uint256 _taskId, string memory _taskName) public {
        Task memory currTask = todos[_taskId];
        todos[_taskId] = Task(_taskId, _taskName, currTask.isComplete);
        emit TaskUpdated(_taskName, _taskId);
    }

    function toggleComplete(uint256 _taskId) public {
        Task memory currTask = todos[_taskId];
        todos[_taskId] = Task(_taskId, currTask.taskName, !currTask.isComplete);

        emit TaskIsCompleteToggled(
            currTask.taskName,
            _taskId,
            !currTask.isComplete
        );
    }

    function deleteTask(uint256 _taskId) public {
        delete todos[_taskId];
        emit TaskDeleted(_taskId);
    }
}