/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleTodo {
    struct Todo {
        string title;
        string description;
        bool status;
    }

    Todo[] todos;

    function addTodo(string memory _title, string memory _description) external {
        Todo memory newTodo;
        newTodo.title = _title;
        newTodo.description = _description;
        todos.push(newTodo);
    }

    function getTodos() external view returns (Todo[] memory todosOut_) {
        todosOut_ = todos;
    }

    function updateTodoStatus(uint _index) external {
        Todo storage updateTodo = todos[_index];
        updateTodo.status = !updateTodo.status;
    }
}