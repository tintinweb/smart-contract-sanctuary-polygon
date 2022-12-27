// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ToDo {
    struct Task {
        uint256 id;
        uint256 date;
        string content;
        bool done;
        uint256 dateComplete;
    }

    event TaskCreated(uint256 id, uint256 date, string content, bool done);

    event TaskStatusToggled(uint256 id, bool done, uint256 dateComplete);

    event TaskDeleted(uint256 id);

    // Task[] tasks;
    // this consume gas when loop through entries in getTask
    // so list should be avoided

    mapping(uint256 => Task) private tasks;

    // mapping default uint value is 0 when key missing
    // therefore avoid initialize with default value
    // (otherwise modifier taskExists will not work)
    uint256 private lastTaskId = 1;
    uint256[] private taskIds;

    function createTask(string memory _content) public {
        uint256 theNow = block.timestamp;

        tasks[lastTaskId] = Task(lastTaskId, theNow, _content, false, 0);
        taskIds.push(lastTaskId);

        emit TaskCreated(lastTaskId, theNow, _content, false);
        lastTaskId++;
    }

    function getTask(uint256 id)
        public
        view
        taskExists(id)
        returns (
            uint256,
            uint256,
            string memory,
            bool,
            uint256
        )
    {
        return (
            id,
            tasks[id].date,
            tasks[id].content,
            tasks[id].done,
            tasks[id].dateComplete
        );
    }

    // return dummy data for test
    function getTaskFixtures(uint256 id)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            bool
        )
    {
        return (id, block.timestamp, "Test Task", false);
    }

    function getTaskIds() public view returns (uint256[] memory) {
        return taskIds;
    }

    // function getTasks() public view returns (Task[] memory) {
    //     return tasks;
    // }

    function toggleDone(uint256 id) public taskExists(id) {
        Task storage task = tasks[id];
        task.done = !task.done;
        task.dateComplete = task.done ? block.timestamp : 0;

        emit TaskStatusToggled(id, task.done, task.dateComplete);
    }

    // clear each data (you cannot delete mapping in Solidity)
    // https://stackoverflow.com/questions/48515633
    function deleteTask(uint256 id) public taskExists(id) {
        delete tasks[id];

        for (uint256 i = 0; i < taskIds.length; i++) {
            if (taskIds[i] == id) {
                // this update the element to 0
                delete taskIds[i];
            }
        }

        emit TaskDeleted(id);
    }

    modifier taskExists(uint256 id) {
        if (tasks[id].id == 0) {
            revert("Revert: taskId not found");
        }
        _;
    }
}