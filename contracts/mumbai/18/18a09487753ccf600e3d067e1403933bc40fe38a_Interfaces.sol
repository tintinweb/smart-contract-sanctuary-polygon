/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract A {
    uint public num;
    function inc() external {
        num += 1;
    }
}

interface ICounter {
    function num() external view returns(uint);
    function inc() external;
}

contract Interfaces {
    function foo(address _A) external {
        ICounter(_A).inc();
    }

    function get(address _A) external view returns(uint){
        return ICounter(_A).num();
    }
}