// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Todos {
    
    string[] public todos;

    function setTodo(string memory _todo) public {
        todos.push(_todo);
    }

    function getTodo() public view returns(string[] memory) {
        return todos;
    }

    function getTodosLength() public view returns(uint) {   
        uint todosLength = todos.length;
        return todosLength;
    }

    function deleteToDo(uint _index) public {
        require(_index < todos.length, "This todo index does not exist.");
        todos[_index] = todos[getTodosLength() - 1];
        // console.log('todos before deleting : ', todos[0], todos[1], todos[2]);
        todos.pop();
    }

}