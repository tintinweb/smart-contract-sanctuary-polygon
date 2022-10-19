/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Storage {
    struct Value {
        address users;
        uint256 number;
    }

    Value[] public list;

   function store(uint256 _num) external {
    list.push(Value(msg.sender, _num));
   } 

   function get() view external  returns(Value[] memory) {
    return list;
   }

}