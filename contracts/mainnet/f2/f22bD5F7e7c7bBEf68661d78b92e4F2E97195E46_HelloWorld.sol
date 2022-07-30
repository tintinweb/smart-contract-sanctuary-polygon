/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract HelloWorld{
    function hello(string memory _test) public pure returns(uint a){
        a = bytes(_test).length;
    }
}