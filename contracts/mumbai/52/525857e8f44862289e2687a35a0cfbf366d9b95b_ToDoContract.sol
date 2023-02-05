/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract ToDoContract{

struct ToDo {
    string title;
    string description;
    bool status;
}

ToDo[] todos;

function addTodo(string memory _title , string memory _description) external {

ToDo memory userTodo;
userTodo.title = _title;
userTodo.description = _description;
todos.push(userTodo);
}


function getTodos() external view returns(ToDo[] memory allTodos){
    allTodos = todos;
}


function updateTodoStatus(uint _index) external {

 ToDo storage updateTodo = todos[_index];

updateTodo.status = !updateTodo.status;

}


}