/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Mycontract{
    uint public a;

    function set(uint _a) external {
        a = _a;
    }

    function inc() external{
        a++;
    }

    function dec() external{
        a--;
    }

}