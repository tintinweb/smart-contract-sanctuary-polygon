// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TaskManager {

    // Array of tasks added
    string[] public tasks;

    // Adds the item and push to the array 
    function addItem(string memory _addItem) public {
        tasks.push(_addItem);
    }

    // Returns the array and lists the items
    function listItems() public view returns (string[] memory) {
        return tasks;
    }

    // Deletes item from the array with pop method. Only owner can call this function
    function deleteItem(uint _itemNumber) public {
        require(_itemNumber < tasks.length, "No task");
        tasks[_itemNumber] = tasks[getLength() - 1];
        tasks.pop();
    }

    // Returns the length of the array
    function getLength() public view returns (uint) {
        uint tasksLength = tasks.length;
        return tasksLength;
    } 
}