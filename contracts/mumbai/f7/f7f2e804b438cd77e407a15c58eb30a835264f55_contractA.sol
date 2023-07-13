/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface Icont {

    function eventFunc() external returns(bool);

    function calFunc() external returns(bool);

}

contract contractA{

    address public contractB;

    constructor(address _constB) { 
        contractB = _constB;
    }

    function callEventFunc() external {
        require(Icont(contractB).eventFunc(),"tx failed");
    }

    function callFunc() external {
        require(Icont(contractB).calFunc(),"tx failed");
    }

}