// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Simple{
    uint256 private counter;
   
    function getcounter () public view returns (uint256) {
        return counter;
    }
    function setcounter (uint256 _counter) public{
        counter = _counter;
    }
}