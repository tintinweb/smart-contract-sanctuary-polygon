/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TodoContract {
    // AddTodo event that emits todo properties
    event AddTodo (address user, uint256 todoId, string todoTask, bool isCompleted);
    // ToggleCompletedStatus event that emits todo's isCompleted value
    event ToggleCompletedStatus (uint256 todoId, bool isCompleted);

    // declare todoId
    uint256 public _idTodo;
    // Create a struct Todo
    struct Todo {
        uint256 todoId;
        string todoTask;
        address creator;
        bool isCompleted;
    }

    // mapping of id to todo
    mapping(uint256 => Todo) public idToTodo;
    // mapping of todo id to owner
    mapping(uint256 => address) todoToOwner;

    // func to increment todoID
    function inc() internal {
        _idTodo++;
    }

    function addTodo(string calldata  _todoTask) external {
        inc(); // increment ID

        uint256 todoId = _idTodo; // set ID
        bool _isCompleted = false; // set isCompleted to initial value of false

        // create a new Todo struct and adds it to the idToTodo mapping
        idToTodo[todoId] = Todo(todoId, _todoTask, msg.sender, _isCompleted);
        todoToOwner[todoId] = msg.sender;

        emit AddTodo(msg.sender , todoId, _todoTask, _isCompleted);
    }

    // toggle isCompleted
    function toggle (uint256 todoId) external {

        Todo storage todo = idToTodo[todoId]; // fetch todo by todoID
        
        // check if caller is creator of todoTask
        require(todoToOwner[todoId] == msg.sender, "NOT AUTHORIZED");
        todo.isCompleted = !todo.isCompleted; // toggle isCompleted value

        emit ToggleCompletedStatus (todoId, todo.isCompleted);
    }
}