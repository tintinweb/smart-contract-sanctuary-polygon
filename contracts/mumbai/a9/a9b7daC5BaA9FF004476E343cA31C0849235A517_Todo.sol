/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Todo {

    address public sender_wallet;
    uint public sender_value;

    constructor() payable {
        sender_wallet =  payable(msg.sender);
        sender_value = msg.value;
        // owner = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
    }
  
    struct TaskStruct{
        uint timestamp;
        string  title;
        string  description;
        string  deadline;
    }

     TaskStruct[]  public task_array;

    function withdraw() public {
        uint amount = sender_wallet.balance;
        payable(msg.sender).transfer(amount);
    }

    function getBalance() public view returns(uint){
        return sender_wallet.balance;
    }

    function addTask(string memory _title,string memory _desc,string memory _deadline) public payable {
        require(sender_value > 0 wei);
        task_array.push(TaskStruct(block.timestamp,_title,_desc,_deadline));
         payable(msg.sender).transfer(500 wei);
    }
  
    function getTask(uint _taskIndex) public view returns(TaskStruct memory){
      return  task_array[_taskIndex];
    }

    function getTasks() public view returns(TaskStruct[] memory){
      return  task_array;
    }

}