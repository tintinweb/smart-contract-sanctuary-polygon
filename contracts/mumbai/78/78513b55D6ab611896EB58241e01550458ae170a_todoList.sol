/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.9.0;

contract todoList{
uint count=0;
struct TODO{
    uint count;
    string data;
}
TODO[10] public todos;

function addTodo(string memory _data)public{
    todos[count]=TODO(count,_data);
    count++;

}
}