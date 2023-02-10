/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ToDoList
 * @dev Implements List of tasks that one needs or intends to accomplish
 */
contract ToDoList {
    //event for the completion status of the Task
    event TaskStatus(string task, bool status);

    // We will declare an array of strings called todos
    string[] public todos;

    /**
     * @dev Add new todo
     * @param _todo task to be performed
     */
    //
    function setTodo(string memory _todo) public {
        todos.push(_todo);
        emit TaskStatus(_todo, false);
    }

    /**
     * @dev get all todos
     * @return string array of todos
     */
    function getTodo() public view returns (string[] memory) {
        return todos;
    }

    /**
     * @dev Return todo based on index
     * @return todos of the given index
     */

    function getTodoByIndex(uint256 _index)
        public
        view
        returns (string memory)
    {
        require(_index <= todos.length, "invalid index");
        return todos[_index];
    }

    /**
     * @dev Return length of the todos array
     * @return todos length
     */
    function getTodosLength() public view returns (uint256) {
        uint256 todosLength = todos.length;
        return todosLength;
    }

    /**
     * @dev delete the todo once task is completed
     * @param _index of the todo to be deleted
     */
    function deleteToDo(uint256 _index) public {
        require(_index < todos.length, "This todo index does not exist.");
        emit TaskStatus(todos[_index], true);
        todos[_index] = todos[getTodosLength() - 1];
        todos.pop();
    }
}