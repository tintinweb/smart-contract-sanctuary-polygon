/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract number{

    int public num;

    function hello(int _num) public returns(int){
        num = _num;
        return num;
    }
}