// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Accountability {
    struct Task {
        string description;
        bool isCompleted;
    }

    Task[] public tasks;
    uint256 private i_deposit; // used for accountability by the host
    address public owner;

    event TaskCreated(uint256 taskId, string description);
    event TaskCompleted(uint256 taskId);
    event DepositSet(uint256 amount);
    event DepositWithdrawn(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender; 
    }

    function createTask(string memory _description) public onlyOwner {
        tasks.push(Task(_description, false));
        emit TaskCreated(tasks.length - 1, _description);
    }

    function depositFunds() public payable {
        require(msg.value > 0, "Must send some ether");
        i_deposit += msg.value;
        emit DepositSet(i_deposit);
    }

    function withdrawDepositSafely() public onlyOwner {
        require(i_deposit > 0, "No deposit to withdraw");
        uint256 amount = i_deposit;
        payable(owner).transfer(amount);
        i_deposit = 0;
        emit DepositWithdrawn(amount);
    }

    function allTasksCompleted() private view returns(bool) {
        for (uint256 i = 0; i < tasks.length; i++) {
            if (!tasks[i].isCompleted) {
                return false;
            }
        }
        return true;
    }

    function clearTask() private {
        delete tasks;
    }

    function completeTask(uint256 _taskId) public onlyOwner {
        require(_taskId < tasks.length, "Task does not exist");
        require(!tasks[_taskId].isCompleted, "Task is already completed");
        Task storage task = tasks[_taskId];
        task.isCompleted = true;
        emit TaskCompleted(_taskId);

        if (allTasksCompleted()) {
            withdrawDepositSafely();
            clearTask();
        }
    }

    function getTaskCount() public view returns(uint256) {
        return tasks.length;
    }

    function getDeposit() public view returns(uint256) {
        return i_deposit;
    }
    
    function getOwner() public view returns(address) {
        return owner;
    }

    function getTasks() public view returns(Task[] memory) {
        return tasks;
    }
}