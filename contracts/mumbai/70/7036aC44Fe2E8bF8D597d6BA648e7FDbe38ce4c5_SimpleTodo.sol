/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleTodo{
    struct Todos{
        string title;
        string description;
        bool status;
    }

    Todos[] todos;

    function addTodo(string memory _title, string memory _description) external {
        Todos memory newTodo;
        newTodo.title = _title;
        newTodo.description = _description;
        todos.push(newTodo);
    }
    function getTodos() external view returns (Todos[] memory todoOut_) {
        todoOut_ = todos;
    }
    function updateTodoStatus(uint _index) external {
        Todos storage updateTodo = todos[_index];
        updateTodo.status = !updateTodo.status;
    }

}