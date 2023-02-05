/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleTodo {
    struct Todo {
        string title;
        string description;
        bool status;
    }

    Todo [] todos;

    function addTodo(string memory _title, string memory _description) external {
        // todos.push(Todo({title: _title, description: _description, status: false}));
        Todo memory newTodo;
        newTodo.title = _title;
        newTodo.description = _description;
        todos.push(newTodo);
    }

    function getTodos() external view returns (Todo[] memory todosOut_) {
        todosOut_ = todos;
    }

    
}