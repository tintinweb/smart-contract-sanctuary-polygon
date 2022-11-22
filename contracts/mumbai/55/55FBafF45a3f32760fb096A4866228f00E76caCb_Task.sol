/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Task {
    mapping(address => uint) public value;
    address[] users;

    function saveNumber(uint _value) external {
        require(value[msg.sender] == 0, "Already added");
        value[msg.sender] = _value;
        users.push(msg.sender);
    }

    function getTotalValueAndUsers() external view returns(uint _totalValue, uint _totalUsers){
        _totalUsers = users.length;
        if(_totalUsers > 0){
          for(uint i = 0; i < _totalUsers; i++){
            _totalValue += value[users[i]];
          }
        }
    }
}