// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Test{
    uint256 private counter;
   
    function getcounter () public view returns (uint256) {
        return counter;
    }

}