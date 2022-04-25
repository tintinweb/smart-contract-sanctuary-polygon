/**
 *Submitted for verification at polygonscan.com on 2022-04-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract test{
    uint Test;
    function setTest(uint _test) public returns (uint){
        Test=_test;
        return Test;
    }
    function getTest() public view returns (uint){
        return Test;
    }
}