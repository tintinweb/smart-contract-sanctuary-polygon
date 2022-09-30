// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyImplementationV2 {
    uint public x;
    function inc() public{
        x+=1;
    }
    function des() public{
        x-=1;
    }
    function inc2() public{
        x+=2;
    }
}