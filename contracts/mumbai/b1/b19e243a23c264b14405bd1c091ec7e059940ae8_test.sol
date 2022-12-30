/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.8.0;

contract test {
    uint num;

    function change(uint n) public {
        num =n;
    }
    function getNum() public view returns(uint){
        return num;
    }
    
}