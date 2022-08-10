/**
 *Submitted for verification at polygonscan.com on 2022-08-10
*/

// File: counter.sol

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract counter {
    uint public count =0;
    function increment() public returns (uint){
        return ++count;
    }

}