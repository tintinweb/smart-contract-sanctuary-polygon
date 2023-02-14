/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ToDoList {
    struct ToDoItem {
        string description;
        bool isCompleted;
    }
    
    mapping (uint => ToDoItem) public todoItems;
    uint public todoItemCount;
    
    function addTodoItem(string memory _description) public {
        todoItemCount++;
        todoItems[todoItemCount] = ToDoItem(_description, false);
    }
    
    function markTodoItemAsComplete(uint _index) public {
        require(_index > 0 && _index <= todoItemCount, "Invalid index");
        todoItems[_index].isCompleted = true;
    }
    
    function editTodoItem(uint _index, string memory _description) public {
        require(_index > 0 && _index <= todoItemCount, "Invalid index");
        todoItems[_index].description = _description;
    }
    
    function deleteTodoItem(uint _index) public {
        require(_index > 0 && _index <= todoItemCount, "Invalid index");
        delete todoItems[_index];
    }
}