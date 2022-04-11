/**
 *Submitted for verification at polygonscan.com on 2022-04-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Todo {
    struct TodoItem {
        string description;
        bool completed;
    }
    
    event AddTodo(address indexed _owner, uint _id, string _description);
    event UpdateTodo(uint _id, bool _completed);

    mapping(address => TodoItem[]) internal todos;

    function addTodo(string calldata _description) public returns(uint) {
        require(bytes(_description).length > 0,"hahah");
        todos[msg.sender].push(TodoItem(_description, false));
        uint id =todos[msg.sender].length - 1; 
        emit AddTodo(msg.sender, id, _description);
        return id;
    }

    function getTodos() public view returns (TodoItem[] memory) {
        return todos[msg.sender];
    }

    function upadteTodoStatus(uint _id, bool _completed) public {
        todos[msg.sender][_id].completed = _completed;
        emit UpdateTodo(_id, _completed);
    }

}