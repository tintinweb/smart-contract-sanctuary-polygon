// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract Todo {
    address public owner;
    struct Todos {
        address creator;
        string title;
        string description;
        uint256 deadline;
        uint256 timeCreated;
        bool isCompleted;
    }
    uint256 public counter = 0;
    mapping(uint256 => Todos) public TodoList;

    constructor() {
        owner = msg.sender;
    }

    function createTodo(
        string memory _title,
        string memory _description,
        uint256 _deadline
    ) public {
        counter = counter + 1;
        TodoList[counter] = Todos(
            msg.sender,
            _title,
            _description,
            _deadline,
            block.timestamp,
            false
        );
    }

    function updateTodoStatus(uint256 _counter) public {
        require(
            TodoList[_counter].deadline > block.timestamp,
            "Deadline is over"
        );
        if (TodoList[_counter].isCompleted == false) {
            TodoList[_counter].isCompleted = true;
        } else {
            TodoList[_counter].isCompleted = false;
        }
    }

    function updateTodoTitle(string memory _title, uint256 _counter) public {
        require(
            TodoList[_counter].creator == msg.sender,
            "You are not authorized to make change"
        );
        require(
            TodoList[_counter].deadline > block.timestamp,
            "Deadline is over"
        );
        TodoList[_counter].title = _title;
    }

    function updateTodoDescription(string memory _description, uint256 _counter)
        public
    {
        require(
            TodoList[_counter].creator == msg.sender,
            "You are not authorized to make change"
        );
        require(
            TodoList[_counter].deadline > block.timestamp,
            "Deadline is over"
        );
        TodoList[_counter].description = _description;
    }

    function getTodos(uint256 _counter) public view returns (Todos memory) {
        return TodoList[_counter];
    }
}