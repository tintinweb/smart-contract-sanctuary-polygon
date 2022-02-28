/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

pragma solidity ^0.5.17;
//SPDX-License-Identifier: SimPL-2.0

contract test1{
    uint public a = 100;

    function change(uint b) public{
        a = b;
    }
}